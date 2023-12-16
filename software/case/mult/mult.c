int c = 0;

int add(int, int);
int sub(int, int);
int mult(int, int);

int main() {
    int a = 32;
    int b = 108;
    int d = 3;
    while (b >= a) {
        b = sub(b, a);
        c++;
        d = mult(d, 2);
    }
    if (c == 3 && d == 24) return 0;
    else return 1;
}

int add(int a, int b) {
    return a + b;
}

int sub(int a, int b) {
    return a - b;
}

int mult(int a, int b) {
    int result = 0;
    while (b != 0) {
        if (b & 1) {
            result += a;
        }
        a <<= 1;
        b >>= 1;
    }
    return result;
}