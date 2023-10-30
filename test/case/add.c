int c = 1;

int main() {
    int a = 0;
    int b = 0;
    while (b < 10) {
        a++;
        b++;
        c++;
    }
    if (a == (c - 1)) return 0;
    else return 1;
}