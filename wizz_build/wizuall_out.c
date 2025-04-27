#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main() {
    // Variable declarations:
    double *x = NULL;
    int len_x = 0;
    double *y = NULL;
    int len_y = 0;

    // Statements:
    len_x = 10;
    x = realloc(x, sizeof(double)*10);
    x[0] = 15.000000;
    x[1] = 3.500000;
    x[2] = 4.000000;
    x[3] = 5.100000;
    x[4] = 6.000000;
    x[5] = 7.000000;
    x[6] = 8.800000;
    x[7] = 9.000000;
    x[8] = 10.000000;
    x[9] = 1.000000;
    len_y = 10;
    y = realloc(y, sizeof(double)*10);
    y[0] = 28.000000;
    y[1] = 12.000000;
    y[2] = 10.000000;
    y[3] = 15.000000;
    y[4] = 18.000000;
    y[5] = 14.000000;
    y[6] = 22.000000;
    y[7] = 20.000000;
    y[8] = 25.000000;
    y[9] = 1.000000;
    {
        FILE *gp = popen("gnuplot -persist", "w");
        fprintf(gp, "plot '-' using 1:2 with points pt 7 lc rgb 'red' title 'Scatter'\n");
        for(int i=0; i < len_x && i < len_y; ++i) {
            fprintf(gp, "%g %g\n", x[i], y[i]);
        }
        fprintf(gp, "e\n");
        pclose(gp);
    }
    return 0;
}
