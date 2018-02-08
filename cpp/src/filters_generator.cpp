#include "filters.h"

namespace {

const int pyramid_layers = 8;


class BuildGaussPyramidFilter : public Halide::Generator<BuildGaussPyramidFilter> {
public:
    Input<Buffer<float>>            input{"input", 2};

    Output<Func[pyramid_layers]>    gPyramid{"gPyramid", Float(32), 2};

    void generate() {
        Func clamped = Halide::BoundaryConditions::repeat_edge(input);
        
        gPyramid[0](x, y, c) = clamped(x, y, c);
        for (int i = 1; i < pyramid_layers; i++) {
            gPyramid[i](x, y) = downsample(gPyramid[i-1])(x, y);
        }
    }

    void schedule() {
        ;
    }
};


class BuildLaplacianPyramidFilter : public Halide::Generator<BuildLaplacianPyramidFilter> {
public:
    Input<Buffer<float>>         input{"input", 3};

    Output<Func[pyramid_layers]>    lPyramid{"lPyramid", Float(32), 3};

    void generate() {
        Func clamped = Halide::BoundaryConditions::repeat_edge(input);
        
        Func gPyramid[pyramid_layers];
        gPyramid[0](x, y, c) = clamped(x, y, c);
        for (int i = 1; i < pyramid_layers; i++) {
            gPyramid[i](x, y) = downsample(gPyramid[i-1])(x, y);
        }

        for (int i = 0; i < pyramid_layers-1; i++) {
            lPyramid[i](x, y) = gPyramid[i](x, y) - upsample(gPyramid[i+1])(x, y);
        }
        lPyramid[pyramid_layers-1](x, y) = gPyramid[pyramid_layers-1](x, y);
    }


    void schedule() {
        ;
    }
};


class PyramidMulti : public Halide::Generator<PyramidMulti> {
public:
    ;
};


class PyramidAdd : public Halide:Generator<PyramidAdd> {
public:
    ;
};


}

HALIDE_REGISTER_GENERATOR(BuildLaplacianPyramidFilter, build_pyramid_filter)