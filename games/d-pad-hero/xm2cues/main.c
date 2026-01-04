#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "xm.h"
#include "xm2cues.h"

static char program_version[] = "xm2cues 1.0";

/* Prints usage message and exits. */
static void usage()
{
    printf(
        "Usage: xm2cues [--output=FILE]\n"
        "              [--verbose]\n"
        "              [--help] [--usage] [--version]\n"
        "              FILE\n");
    exit(0);
}

/* Prints help message and exits. */
static void help()
{
    printf("Usage: xm2cues [OPTION...] FILE\n"
           "xm2cues converts Fasttracker ][ eXtended Module (XM) files to D-pad Hero button data.\n\n"
           "Options:\n\n"
           "  --output=FILE                   Store output in FILE\n"
           "  --verbose                       Print progress information to standard output\n"  
           "  --help                          Give this help list\n"
           "  --usage                         Give a short usage message\n"
           "  --version                       Print program version\n");
    exit(0);
}

/* Prints version and exits. */
static void version()
{
    printf("%s\n", program_version);
    exit(0);
}

/**
  Program entrypoint.
*/
int main(int argc, char *argv[])
{
    int exit_code = 0;
    int verbose = 0;
    const char *input_filename = 0;
    const char *output_filename = 0;
    struct xm2cues_options options;
    options.label_prefix = 0;
    /* Process arguments. */
    {
        char *p;
        while ((p = *(++argv))) {
            if (!strncmp("--", p, 2)) {
                const char *opt = &p[2];
                if (!strncmp("output=", opt, 7)) {
                    output_filename = &opt[7];
                } else if (!strcmp("verbose", opt)) {
                    verbose = 1;
                } else if (!strcmp("help", opt)) {
                    help();
                } else if (!strcmp("usage", opt)) {
                    usage();
                } else if (!strcmp("version", opt)) {
                    version();
                } else {
                    fprintf(stderr, "xm2cues: unrecognized option `%s'\n"
			    "Try `xm2cues --help' or `xm2cues --usage' for more information.\n", p);
                    return(-1);
                }
            } else {
                input_filename = p;
            }
        }
    }

    if (!input_filename) {
        fprintf(stderr, "xm2cues: no filename given\n"
                        "Try `xm2cues --help' or `xm2cues --usage' for more information.\n");
        return(-1);
    }

    {
        struct xm xm;
        FILE *out;
        if (!output_filename)
            out = stdout;
        else {
            out = fopen(output_filename, "wt");
            if (!out) {
                fprintf(stderr, "xm2cues: failed to open `%s' for writing\n", output_filename);
                return(-1);
            }
        }

        {
            FILE *in;
            in = fopen(input_filename, "rb");
            if (!in) {
                fprintf(stderr, "xm2cues: failed to open `%s' for reading\n", input_filename);
                return(-1);
            }
            if (verbose)
                fprintf(stdout, "Reading `%s'...\n", input_filename);
            int ret = xm_read(in, &xm);
            if (ret != XM_NO_ERROR) {
                switch (ret) {
                    case XM_FORMAT_ERROR:
                        fprintf(stderr, "xm2cues: `%s' is not a valid XM file\n", input_filename);
                        break;
                    case XM_VERSION_ERROR:
                        fprintf(stderr, "xm2cues: `%s' has an unsupported XM version\n", input_filename);
                        break;
                    case XM_HEADER_SIZE_ERROR:
                        fprintf(stderr, "xm2cues: `%s' has an invalid XM header size\n", input_filename);
                        break;
                    default:
                        fprintf(stderr, "xm2cues: an unknown error occurred while reading `%s'\n", input_filename);
                        break;
                }
                fclose(in);
                return(-1);
            }
            if (verbose)
                fprintf(stdout, "OK.\n");
        }

        if (verbose)
            xm_print_header(&xm.header, stdout);

        if (verbose)
            fprintf(stdout, "Converting...\n");

        {
            const char *begin;
            char *prefix;
            int len;
            /* Use basename of input filename as prefix */
            char *last_dot;
            begin = strrchr(input_filename, '/');
            if (begin)
                ++begin;
            else
                begin = input_filename;
            last_dot = strrchr(begin, '.');
            if (!last_dot)
                len = strlen(begin);
            else
                len = last_dot - begin;
            prefix = (char *)malloc(len + 2);
            prefix[len] = '_';
            prefix[len+1] = '\0';
            strncpy(prefix, begin, len);

            options.label_prefix = prefix;
            options.input_filename = input_filename;
            options.program_version = program_version;
            exit_code = convert_xm_to_cues(&xm, &options, out) ? 0 : -1;

            free(prefix);
        }

        if (verbose)
            fprintf(stdout, "Done.\n");

        xm_destroy(&xm);
    }
    return exit_code;
}
