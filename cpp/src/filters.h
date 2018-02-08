#include "Halide.h"

namespace {

constexpr int maxJ = 20;


// Downsample with a 1 3 3 1 filter
Halide::Func downsample(Halide::Func f) {
    using Halide::_;
    Halide::Func downx, downy;
    Halide::Var x, y;
    downx(x, y, _) = (f(2*x-1, y, _) + 3.0f * (f(2*x, y, _) + f(2*x+1, y, _)) + f(2*x+2, y, _)) / 8.0f;
    downy(x, y, _) = (downx(x, 2*y-1, _) + 3.0f * (downx(x, 2*y, _) + downx(x, 2*y+1, _)) + downx(x, 2*y+2, _)) / 8.0f;
    return downy;
}


// Upsample using bilinear interpolation
Halide::Func upsample(Halide::Func f) {
    using Halide::_;
    Halide::Func upx, upy;
    Halide::Var x, y;
    upx(x, y, _) = 0.25f * f((x/2) - 1 + 2*(x % 2), y, _) + 0.75f * f(x/2, y, _);
    upy(x, y, _) = 0.25f * upx(x, (y/2) - 1 + 2*(y % 2), _) + 0.75f * upx(x, y/2, _);
    return upy;
}

}