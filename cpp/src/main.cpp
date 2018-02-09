#include <chrono>

#include "utils.h"

#include "HalideBuffer.h"
#include "halide_image_io.h"

#include "blend2.h"


using namespace Halide::Runtime;
using namespace Halide::Tools;

int main(int argc, char **argv) {
    if (argc != 3) {
        printf("USAGE: %s input_path output_path\n", argv[0]);
        printf("e.g. %s ~/Desktop/raw/ ~/Desktop/tiff/\n", argv[0]);
        return 1;
    }

    std::string input_path(argv[1]);
    std::vector<std::string> files;
    getdir(input_path, files);

    char cmd_buffer[512];
    auto start = std::chrono::system_clock::now();

    // Read first image
    sprintf(cmd_buffer, "%s %s \"%s/%s\"",
        "/usr/local/Cellar/dcraw/9.27.0_2/bin/dcraw",
        "-v -r 1.95 1.0 1.63 1.0 -k 2047 -S 15490 -6 -q 0",
        input_path.c_str(), files[1].c_str());

    printf("cmd: %s\n", cmd_buffer);
    int rv = system(cmd_buffer);

    char buf[512];
    memset(buf, 0, sizeof(buf));
    strncpy(buf, files[1].c_str(), files[1].length()-4);
    strcat(buf, ".ppm");
    sprintf(cmd_buffer, "%s/%s", input_path.c_str(), buf);

    printf("Reading file: %s\n", cmd_buffer);
    auto t0 = std::chrono::system_clock::now();
    Buffer<uint16_t> img1 = load_and_convert_image(cmd_buffer);
    auto t1 = std::chrono::system_clock::now();
    printf("Reading image: %.2fms\n", (t1 - t0).count() / 1000.0);

    // sprintf(cmd_buffer, "rm \"%s/%s\"", input_path.c_str(), buf);
    // printf("cmd: %s\n", cmd_buffer);
    // rv = system(cmd_buffer);

    // Read second image
    sprintf(cmd_buffer, "%s %s \"%s/%s\"",
        "/usr/local/Cellar/dcraw/9.27.0_2/bin/dcraw",
        "-v -r 1.95 1.0 1.63 1.0 -k 2047 -S 15490 -6 -q 0",
        input_path.c_str(), files[2].c_str());

    printf("cmd: %s\n", cmd_buffer);
    rv = system(cmd_buffer);

    memset(buf, 0, sizeof(buf));
    strncpy(buf, files[2].c_str(), files[2].length()-4);
    strcat(buf, ".ppm");
    sprintf(cmd_buffer, "%s/%s", input_path.c_str(), buf);

    printf("Reading file: %s\n", cmd_buffer);
    t0 = std::chrono::system_clock::now();
    Buffer<uint16_t> img2 = load_and_convert_image(cmd_buffer);
    t1 = std::chrono::system_clock::now();
    printf("Reading image: %.2fms\n", (t1 - t0).count() / 1000.0);

    // sprintf(cmd_buffer, "rm \"%s/%s\"", input_path.c_str(), buf);
    // printf("cmd: %s\n", cmd_buffer);
    // rv = system(cmd_buffer);

    // Processing
    Buffer<uint16_t> out(img1.width(), img1.height(), 3);
    blend2(img1, img2, out);

    // Save output image
    sprintf(cmd_buffer, "%s/%s", input_path.c_str(), "img1.ppm");
    t0 = std::chrono::system_clock::now();
    convert_and_save_image(img1, cmd_buffer);
    t1 = std::chrono::system_clock::now();
    printf("Saving image: %.2fms\n", (t1 - t0).count() / 1000.0);

    sprintf(cmd_buffer, "%s/%s", input_path.c_str(), "img2.ppm");
    t0 = std::chrono::system_clock::now();
    convert_and_save_image(img2, cmd_buffer);
    t1 = std::chrono::system_clock::now();
    printf("Saving image: %.2fms\n", (t1 - t0).count() / 1000.0);

    sprintf(cmd_buffer, "%s/%s", input_path.c_str(), "result.ppm");
    t0 = std::chrono::system_clock::now();
    convert_and_save_image(out, cmd_buffer);
    t1 = std::chrono::system_clock::now();
    printf("Saving image: %.2fms\n", (t1 - t0).count() / 1000.0);
    printf("Total: %.2fms\n", (t1 - start).count() / 1000.0);

    return 0;
}