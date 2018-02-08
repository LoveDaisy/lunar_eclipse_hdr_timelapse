#include <sys/types.h>
#include <dirent.h>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <cstring>
#include <vector>

bool endsWith(const std::string &mainStr, const std::string &toMatch) {
    if(mainStr.size() >= toMatch.size() &&
            mainStr.compare(mainStr.size() - toMatch.size(), toMatch.size(), toMatch) == 0)
            return true;
        else
            return false;
}


int getdir (std::string dir, std::vector<std::string> &files) {
    DIR *dp;
    struct dirent *dirp;
    if((dp  = opendir(dir.c_str())) == NULL) {
        printf("Error on opending dir: %s\n", dir.c_str());
        return -1;
    }

    while ((dirp = readdir(dp)) != NULL) {
        std::string f(dirp->d_name);
        if (endsWith(f, ".CR2")) {
            files.push_back(f);
        }
    }
    closedir(dp);
    return 0;
}


int main(int argc, char **argv) {
    if (argc != 3) {
        printf("USAGE: %s input_path output_path\n", argv[0]);
        printf("e.g. %s ~/Desktop/raw/ ~/Desktop/jpg/\n", argv[0]);
        return 1;
    }

    std::string input_path(argv[1]);
    std::vector<std::string> files;
    getdir(input_path, files);

    char cmd_buffer[512];
    std::memset(cmd_buffer, 0, sizeof cmd_buffer);
    sprintf(cmd_buffer, "%s %s \"%s/%s\"",
        "/usr/local/Cellar/dcraw/9.27.0_2/bin/dcraw",
        "-v -r 1.95 1.0 1.63 1.0 -k 2047 -S 15490 -g 1 1 -4 -T -q 0",
        input_path.c_str(), files[8].c_str());

    printf("cmd: %s\n", cmd_buffer);
    int rv = system(cmd_buffer);
    return 0;
}