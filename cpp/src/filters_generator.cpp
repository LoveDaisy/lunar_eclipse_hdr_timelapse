#include "filters.h"

namespace {

const int PYR_LAYERS = 8;
const int TYPICAL_WIDTH = 5400;
const int TYPICAL_HEIGHT = 3600;


class Blend2Images : public Halide::Generator<Blend2Images> {
public:
    Input<Buffer<uint16_t>>     img1{"img1", 3};
    Input<Buffer<uint16_t>>     img2{"img2", 3};

    Output<Buffer<uint16_t>>    output{"output", 3};

    Var x, y, c;

    void generate() {
        Func img1_repeat = Halide::BoundaryConditions::repeat_edge(img1);
        Func img2_repeat = Halide::BoundaryConditions::repeat_edge(img2);
        
        Func img1_gauss_pyr[PYR_LAYERS], img2_gauss_pyr[PYR_LAYERS],
             img1_gray, img2_gray,
             w1_gauss_pyr[PYR_LAYERS], w2_gauss_pyr[PYR_LAYERS],
             out_lap_pyr[PYR_LAYERS];
        
        img1_gauss_pyr[0](x, y, c) = cast<float>(img1_repeat(x, y, c)) / 65535.0f;
        img2_gauss_pyr[0](x, y, c) = cast<float>(img2_repeat(x, y, c)) / 65535.0f;
        img1_gray = rgb_to_gray(img1_gauss_pyr[0]);
        img2_gray = rgb_to_gray(img2_gauss_pyr[0]);
        w1_gauss_pyr[0](x, y) = exp(-(img1_gray(x, y) - 0.52f) * (img1_gray(x, y) - 0.52f) / 0.25f);
        w2_gauss_pyr[0](x, y) = exp(-(img2_gray(x, y) - 0.52f) * (img2_gray(x, y) - 0.52f) / 0.25f);
        for (int i = 1; i < PYR_LAYERS; i++) {
            img1_gauss_pyr[i](x, y, c) = downsample(img1_gauss_pyr[i-1])(x, y, c);
            img2_gauss_pyr[i](x, y, c) = downsample(img2_gauss_pyr[i-1])(x, y, c);
            w1_gauss_pyr[i](x, y) = downsample(w1_gauss_pyr[i-1])(x, y);
            w2_gauss_pyr[i](x, y) = downsample(w2_gauss_pyr[i-1])(x, y);
        }
        out_lap_pyr[PYR_LAYERS-1](x, y, c) = (img1_gauss_pyr[PYR_LAYERS-1](x, y, c) * w1_gauss_pyr[PYR_LAYERS-1](x, y) + 
                                             img2_gauss_pyr[PYR_LAYERS-1](x, y, c) * w2_gauss_pyr[PYR_LAYERS-1](x, y)) / 
                                             (w1_gauss_pyr[PYR_LAYERS-1](x, y) + w2_gauss_pyr[PYR_LAYERS-1](x, y));
        for (int i = PYR_LAYERS-2; i >= 0; i--) {
            out_lap_pyr[i](x, y, c) = ((img1_gauss_pyr[i](x, y, c) - upsample(img1_gauss_pyr[i+1])(x, y, c)) * w1_gauss_pyr[i](x, y) +
                                      (img2_gauss_pyr[i](x, y, c) - upsample(img2_gauss_pyr[i+1])(x, y, c)) * w2_gauss_pyr[i](x, y)) / 
                                      (w1_gauss_pyr[i](x, y) + w2_gauss_pyr[i](x, y)) +
                                      upsample(out_lap_pyr[i+1])(x, y, c);
        }

        output(x, y, c) = cast<uint16_t>(clamp(out_lap_pyr[0](x, y, c), 0.0f, 1.0f) * 65535.0f);
    }

    void schedule() {
        img1.dim(0).set_bounds_estimate(0, TYPICAL_WIDTH);
        img1.dim(1).set_bounds_estimate(0, TYPICAL_HEIGHT);
        img1.dim(2).set_bounds_estimate(0, 3);

        img2.dim(0).set_bounds_estimate(0, TYPICAL_WIDTH);
        img2.dim(1).set_bounds_estimate(0, TYPICAL_HEIGHT);
        img2.dim(2).set_bounds_estimate(0, 3);

        output.estimate(x, 0, TYPICAL_WIDTH).estimate(y, 0, TYPICAL_HEIGHT).estimate(c, 0, 3);
    }
};


}

HALIDE_REGISTER_GENERATOR(Blend2Images, blend2)