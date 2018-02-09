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