#ifndef XM2CUES_H
#define XM2CUES_H

struct xm2cues_options {
    const char *label_prefix;
    const char *input_filename;
    const char *program_version;
};

int convert_xm_to_cues(const struct xm *, const struct xm2cues_options *, FILE *);

#endif
