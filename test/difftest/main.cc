#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vsoc_top.h"
#include "verilated_dpi.h"
#include <svdpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <string>
#include <dlfcn.h>

#define RESET_VECTOR 0x80000000
#define CONFIG_MBASE 0x80000000
#define CONFIG_MSIZE 0x08000000
#define PG_ALIGN __attribute((aligned(4096)))

typedef uint32_t word_t;
typedef uint32_t paddr_t;
typedef uint32_t vaddr_t;

//! MEMORY

static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - RESET_VECTOR; }

//! CONTEXT

typedef struct {
    word_t gpr[32];
    word_t pc;
} CPU_state;

word_t* dut_gpr;
word_t* dut_pc;
word_t* dut_inst;
word_t* dut_mem;

CPU_state dut_state;
CPU_state ref_state;

//! VERILATOR ENVIRONMENT

const char* img_file = "/home/sgap/projects/riscv32/test/case/mult/mult.bin";
const char* lib_file = "/home/sgap/ysyx-workbench/nemu/tools/spike-diff/build/riscv32-spike-so";
uint64_t cycles = 0;
uint64_t times = 0;
bool finish = false;

char* uint32_to_binary_string(uint32_t n) {
    if (n > 0xFFFFFFFF) {
        return NULL; // 输入值必须是32位无符号整数
    }

    static char binary_string[33]; // 32位二进制字符串 + 1个终止符
    binary_string[32] = '\0'; // 设置字符串终止符

    for (int i = 31; i >= 0; i--) {
        binary_string[i] = (n & 1) ? '1' : '0'; // 从最低位到最高位逐位处理
        n >>= 1; // 右移一位
    }

    return binary_string;
}

void print_dut_gpr() {
    int i;
    for (i = 0; i < 32; i++) {
        printf("gpr[%d] = %08x\n", i, *(dut_gpr + i));
    }
}

void print_dut_pc() {
    printf("pc = %08x\n", *dut_pc);
}

void print_dut_inst() {
    printf("inst = %08x\n", dut_inst);
}

void print_ref_gpr() {
    int i;
    for (i = 0; i < 32; i++) {
        printf("r_gpr[%d] = %08x\n", i, ref_state.gpr[i]);
    }
}

void print_ref_pc() {
    printf("ref_pc_next = %08x\n", ref_state.pc);
}

//! DPI-C
extern "C" {
    void set_ptr_gpr(const svOpenArrayHandle r) {
        dut_gpr = (word_t*)(((VerilatedDpiOpenVar*)r)->datap());
    }

    void set_ptr_pc(const svOpenArrayHandle r) {
        dut_pc = (word_t*)(((VerilatedDpiOpenVar*)r)->datap());
    }

    void set_ptr_inst(const svOpenArrayHandle r) {
        dut_inst = (word_t*)(((VerilatedDpiOpenVar*)r)->datap());
    }

    void set_ptr_mem(const svOpenArrayHandle r) {
        dut_mem = (word_t*)(((VerilatedDpiOpenVar*)r)->datap());
    }

    void call_return() {
        finish = true;
    }
}

//! DIFF FUNCTIONS
extern "C" {
    void (*ref_difftest_memcpy)(paddr_t addr, void* buf, size_t n, bool direction) = NULL;
    void (*ref_difftest_regcpy)(void* dut, bool direction) = NULL;
    void (*ref_difftest_exec)(uint64_t n) = NULL;
    void (*ref_difftest_raise_intr)(uint64_t NO) = NULL;
    void (*ref_difftest_init)(int) = NULL;
}

//! INIT

enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };

long load_img(char* program) {
    std::string program_str(program);
    std::string program_file = "/home/sgap/projects/riscv32/test/case/" + program_str + "/" + program_str + ".bin";
    FILE* fp = fopen(program_file.c_str(), "rb");
    assert(fp);

    fseek(fp, 0, SEEK_END);
    long size = ftell(fp);

    printf("The image is %s, size = %ld\n", img_file, size);

    fseek(fp, 0, SEEK_SET);
    int ret = fread(guest_to_host(RESET_VECTOR), size, 1, fp);
    assert(ret == 1);

    fclose(fp);

    return size;
}

void init_difftest(const char* ref_so_file, long img_size, int port) {
    assert(ref_so_file != NULL);

    void* handle;
    handle = dlopen(ref_so_file, RTLD_LAZY);
    assert(handle);

    ref_difftest_memcpy = (void (*)(paddr_t, void*, size_t, bool))dlsym(handle, "difftest_memcpy");
    assert(ref_difftest_memcpy);

    ref_difftest_regcpy = (void (*)(void*, bool))dlsym(handle, "difftest_regcpy");
    assert(ref_difftest_regcpy);

    ref_difftest_exec = (void (*)(uint64_t))dlsym(handle, "difftest_exec");
    assert(ref_difftest_exec);

    ref_difftest_raise_intr = (void (*)(uint64_t))dlsym(handle, "difftest_raise_intr");
    assert(ref_difftest_raise_intr);

    ref_difftest_init = (void (*)(int))dlsym(handle, "difftest_init");
    assert(ref_difftest_init);

    // Log("Differential testing: %s", ANSI_FMT("ON", ANSI_FG_GREEN));
    printf("The result of every instruction will be compared with %s.\n\
            This will help you a lot for debugging, but also significantly reduce the performance.\n\
            If it is not necessary, you can turn it off in menuconfig.\n", ref_so_file);

    ref_difftest_init(port);
    ref_difftest_memcpy(RESET_VECTOR, guest_to_host(RESET_VECTOR), img_size, DIFFTEST_TO_REF);
    ref_difftest_regcpy(&dut_state, DIFFTEST_TO_REF);
}

// dump NPC state to struct
void dut_state_dump() {
    for (int i = 0;i < 32;i++) {
        dut_state.gpr[i] = *(dut_gpr + i);
    }
    dut_state.pc = *dut_pc;
}

//! EXEC REF

const char* reg_name[32] = {
    "zero","ra","sp","gp",
    "tp","t0","t1","t2",
    "s0","s1","a0","a1",
    "a2","a3","a4","a5",
    "a6","a7","s2","s3",
    "s4","s5","s6","s7",
    "s8","s9","s10","s11",
    "t3","t4","t5","t6"
};

bool difftest_check_reg(const char* name, vaddr_t pc, word_t ref, word_t dut) {
    if (ref != dut) {
        printf("%s is different after executing instruction at pc = %08x, right = %08x, wrong = %08x, diff = %08x\n",
            name, pc, ref, dut, ref ^ dut);
        return false;
    }
    else {
        return true;
    }

}

bool isa_difftest_checkregs(CPU_state* ref, vaddr_t pc) {
    for (int i = 0;i < 32;i++) {
        if (difftest_check_reg(reg_name[i], pc, ref->gpr[i], dut_state.gpr[i]) == false) {
            return false;
        }
    }
    if (difftest_check_reg("pc", pc, ref->pc, dut_state.pc) == false) {
        return false;
    }
    return true;
}

void checkregs(CPU_state * ref, vaddr_t pc) {
    if (!isa_difftest_checkregs(ref, pc)) {
        print_dut_gpr();
        print_dut_pc();
        finish = true;
    }
}

void difftest_step(vaddr_t pc, vaddr_t npc) {

    // if (skip_dut_nr_inst > 0) {
    //     ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);
    //     if (ref_r.pc == npc) {
    //         skip_dut_nr_inst = 0;
    //         checkregs(&ref_r, npc);
    //         return;
    //     }
    //     skip_dut_nr_inst--;
    //     if (skip_dut_nr_inst == 0)
    //         panic("can not catch up with ref.pc = " FMT_WORD " at pc = " FMT_WORD, ref_r.pc, pc);
    //     return;
    // }

    // if (is_skip_ref) {
    //     // to skip the checking of an instruction, just copy the reg state to reference design
    //     ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
    //     is_skip_ref = false;
    //     return;
    // }

    ref_difftest_exec(1);
    ref_difftest_regcpy(&ref_state, DIFFTEST_TO_DUT);
    print_ref_gpr();
    print_ref_pc();

    checkregs(&ref_state, pc);
}

int main(int argc, char** argv, char** env) {

    long img_size = load_img(argv[1]);

    Verilated::traceEverOn(true);
    VerilatedVcdC* m_tracep = new VerilatedVcdC;         // 波形
    Vsoc_top* m_dut = new Vsoc_top;

    m_dut->trace(m_tracep, 5);
    m_tracep->open("wave.vcd");

    //! Initial Assignment
    m_dut->clk = 0;
    m_dut->rstn = 0;
    printf("SYSTEM RESET\n");
    m_dut->eval(); // set pointers

    for (long i = 0;i < img_size;i += 4) {
        word_t value = 0;
        for (int j = 0; j < 4; j++) {
            value |= static_cast<word_t>(pmem[i + j]) << (j * 8);
        }
        assert(dut_mem);

        //! Due to restriction, hardware memory[0] refer to pmem[0x80000000] here
        *(dut_mem + (i + RESET_VECTOR - CONFIG_MBASE) / 4) = value;
        printf("0x%08x <= %08x\n", (i + RESET_VECTOR), *(dut_mem + (i + RESET_VECTOR - CONFIG_MBASE) / 4));
    }

    m_dut->clk = 1;
    m_dut->eval();
    m_tracep->dump(times++);

    m_dut->rstn = 1;
    m_dut->clk = 0;
    m_dut->eval();
    m_tracep->dump(times++);

    dut_state_dump();
    init_difftest(lib_file, img_size, 1234);

    while (!finish && cycles < 1000) {
        printf("\nCYCLE %ld\n", cycles);
        print_dut_pc();
        // print_dut_inst();
        print_dut_gpr();

        m_dut->clk = 1; // 0 -> 1
        m_dut->eval();
        m_tracep->dump(times++);
        m_dut->clk = 0; // 1 -> 0
        m_dut->eval();
        m_tracep->dump(times++);

        dut_state_dump();
        // difftest_step(dut_state.pc + RESET_VECTOR, 0);

        cycles++;
    }
    if (finish) {
        if (*(dut_gpr + 10) == 0)
            printf("\n\nProgram returned normally.\n");
        else {
            printf("\n\nProgram returned with error.\n");
            print_dut_gpr();
        }
    }
    printf("Program consumed %ld cycles.\n\n", cycles);

    m_tracep->close();
    delete m_dut;
    delete m_tracep;
    return 0;
}
