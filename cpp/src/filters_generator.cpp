#include "filters.h"

namespace {

const int PYR_LAYERS = 8;
const int WIDTH = 5400;
const int HEIGHT = 3600;


class BuildGaussPyramidFilter : public Halide::Generator<BuildGaussPyramidFilter> {
public:
    Input<Buffer<float>>            input{"input", 2};

    Output<Func[PYR_LAYERS]>    gPyramid{"gPyramid", Float(32), 2};

    Var x, y;

    void generate() {
        Func clamped = Halide::BoundaryConditions::repeat_edge(input);
        
        gPyramid[0](x, y, c) = clamped(x, y, c);
        for (int i = 1; i < PYR_LAYERS; i++) {
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

    Output<Func[PYR_LAYERS]>    lPyramid{"lPyramid", Float(32), 3};

    Var x, y, c;

    void generate() {
        Func clamped = Halide::BoundaryConditions::repeat_edge(input);
        
        Func gPyramid[PYR_LAYERS];
        gPyramid[0](x, y, c) = clamped(x, y, c);
        for (int i = 1; i < PYR_LAYERS; i++) {
            gPyramid[i](x, y) = downsample(gPyramid[i-1])(x, y);
        }

        for (int i = 0; i < PYR_LAYERS-1; i++) {
            lPyramid[i](x, y) = gPyramid[i](x, y) - upsample(gPyramid[i+1])(x, y);
        }
        lPyramid[PYR_LAYERS-1](x, y) = gPyramid[PYR_LAYERS-1](x, y);
    }


    void schedule() {
        ;
    }
};


class PyramidMulti : public Halide::Generator<PyramidMulti> {
public:
    Input<Func[PYR_LAYERS]>     imgPyr{"imgPyr", Float(32), 3};
    Input<Func[PYR_LAYERS]>     wPyr{"wPyr", Float(32), 2};

    Output<Func[PYR_LAYERS]>    outPyr{"outPyr", Float(32), 3};

    Var x, y, c;

    void generate() {
        for (int i = 0; i < PYR_LAYERS; i++) {
            outPyr[i](x, y, c) = imgPyr[i](x, y, c) * wPyr[i](x, y);
        }
    }

    void schedule() {
        ;
    }
};


class PyramidAdd : public Halide:Generator<PyramidAdd> {
public:
    Input<Func[PYR_LAYERS]>     pyr1{"pyr1", Float(32), 3};
    Input<Func[PYR_LAYERS]>     pyr2{"pyr2", Float(32), 3};

    Output<Func[PYR_LAYERS]>    outPyr{"outPyr", Float(32), 3};

    Var x, y, c;

    void generate() {
        for (int i = 0; i < PYR_LAYERS; i++) {
            outPyr[i](x, y, c) = pyr1[i](x, y, c) + pyr2[i](x, y, c);
        }
    }

    void schedule() {
        ;
    }
};


}

HALIDE_REGISTER_GENERATOR(BuildLaplacianPyramidFilter, build_pyramid_filter)