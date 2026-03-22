#include <yaml-cpp/yaml.h>
#include <iostream>
#include <string>
#include <vector>
#include <cstring>

extern "C" {
    typedef struct {
        char* name;
        char* mesh_file;
        char* lev_dimname;
        char* tax_mode;
        char* time_interp;
        char* map_algo;
        char* read_mode;
        double dt_limit;
        int year_first;
        int year_last;
        int year_align;
        int offset;
        char** input_files;
        int num_files;
        char** file_vars;
        char** model_vars;
        int num_fields;
    } tide_stream_config_t;

    typedef struct {
        tide_stream_config_t* streams;
        int num_streams;
    } tide_config_t;

    tide_config_t* tide_parse_yaml(const char* filename) {
        try {
            YAML::Node config = YAML::LoadFile(filename);
            if (!config["streams"]) return nullptr;

            auto streams_node = config["streams"];
            int num_streams = streams_node.size();

            tide_config_t* cfg = new tide_config_t();
            cfg->num_streams = num_streams;
            cfg->streams = new tide_stream_config_t[num_streams];

            for (int i = 0; i < num_streams; ++i) {
                auto s = streams_node[i];
                tide_stream_config_t& sc = cfg->streams[i];

                sc.name = strdup(s["name"].as<std::string>().c_str());
                sc.mesh_file = strdup(s["mesh_file"].as<std::string>().c_str());
                sc.lev_dimname = s["lev_dimname"] ? strdup(s["lev_dimname"].as<std::string>().c_str()) : strdup("null");
                sc.tax_mode = s["tax_mode"] ? strdup(s["tax_mode"].as<std::string>().c_str()) : strdup("cycle");
                sc.time_interp = s["time_interp"] ? strdup(s["time_interp"].as<std::string>().c_str()) : strdup("linear");
                sc.map_algo = s["map_algo"] ? strdup(s["map_algo"].as<std::string>().c_str()) : strdup("bilinear");
                sc.read_mode = s["read_mode"] ? strdup(s["read_mode"].as<std::string>().c_str()) : strdup("single");
                sc.dt_limit = s["dt_limit"] ? s["dt_limit"].as<double>() : 1.5;
                sc.year_first = s["year_first"].as<int>();
                sc.year_last = s["year_last"].as<int>();
                sc.year_align = s["year_align"].as<int>();
                sc.offset = s["offset"] ? s["offset"].as<int>() : 0;

                auto files = s["input_files"];
                sc.num_files = files.size();
                sc.input_files = new char*[sc.num_files];
                for (int j = 0; j < sc.num_files; ++j) {
                    sc.input_files[j] = strdup(files[j].as<std::string>().c_str());
                }

                auto fields = s["field_maps"];
                sc.num_fields = fields.size();
                sc.file_vars = new char*[sc.num_fields];
                sc.model_vars = new char*[sc.num_fields];
                for (int j = 0; j < sc.num_fields; ++j) {
                    sc.file_vars[j] = strdup(fields[j]["file_var"].as<std::string>().c_str());
                    sc.model_vars[j] = strdup(fields[j]["model_var"].as<std::string>().c_str());
                }
            }
            return cfg;
        } catch (const std::exception& e) {
            std::cerr << "TIDE YAML Error: " << e.what() << std::endl;
            return nullptr;
        }
    }

    void tide_free_config(tide_config_t* cfg) {
        if (!cfg) return;
        for (int i = 0; i < cfg->num_streams; ++i) {
            tide_stream_config_t& sc = cfg->streams[i];
            free(sc.name); free(sc.mesh_file); free(sc.lev_dimname);
            free(sc.tax_mode); free(sc.time_interp); free(sc.map_algo); free(sc.read_mode);
            for (int j = 0; j < sc.num_files; ++j) free(sc.input_files[j]);
            delete[] sc.input_files;
            for (int j = 0; j < sc.num_fields; ++j) {
                free(sc.file_vars[j]); free(sc.model_vars[j]);
            }
            delete[] sc.file_vars; delete[] sc.model_vars;
        }
        delete[] cfg->streams;
        delete cfg;
    }
}
