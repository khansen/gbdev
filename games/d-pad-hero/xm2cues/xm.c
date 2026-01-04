#include "xm.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>

#define read_byte(fp) (unsigned char)fgetc(fp)

/* Reads a short (little-endian) */
static unsigned short read_ushort(FILE *fp)
{
    unsigned short result;
    result = read_byte(fp);        /* Low byte */
    result |= read_byte(fp) << 8;  /* High byte */
    return result;
}
/* Reads an int (little-endian) */
static unsigned int read_uint(FILE *fp)
{
    unsigned int result;
    result = read_byte(fp);        /* Low byte */
    result |= read_byte(fp) << 8;
    result |= read_byte(fp) << 16;
    result |= read_byte(fp) << 24;  /* High byte */
    return result;
}

static int xm_read_header(FILE *fp, struct xm_header *out)
{
    fread(&out->id_text, 1, 17, fp);
    if (strncmp(out->id_text, "Extended Module: ", 17) != 0) {
        return XM_FORMAT_ERROR;
    }
    fread(&out->module_name, 1, 20, fp);
    out->pad1a = read_byte(fp);
    if (out->pad1a != 0x1A)
        return XM_FORMAT_ERROR;
    fread(&out->tracker_name, 1, 20, fp);
    out->version = read_ushort(fp);
    if (out->version < 0x0104)
        return XM_VERSION_ERROR;
    out->header_size = read_uint(fp);
    if (out->header_size != 0x0114)
        return XM_HEADER_SIZE_ERROR;
    out->song_length = read_ushort(fp);
    out->restart_position = read_ushort(fp);
    out->channel_count = read_ushort(fp);
    out->pattern_count = read_ushort(fp);
    out->instrument_count = read_ushort(fp);
    out->flags = read_ushort(fp);
    out->default_tempo = read_ushort(fp);
    out->default_bpm = read_ushort(fp);
    fread(&out->pattern_order_table, 1, 256, fp);
    assert(ftell(fp) == 0x150);
    assert(ftell(fp)-0x3C == out->header_size);
    return XM_NO_ERROR;
}

static int xm_read_pattern(FILE *fp, int channel_count, struct xm_pattern *out)
{
    unsigned int header_length;
    unsigned char packing_type;
    unsigned short row_count;
    unsigned short packed_data_size;
    long pos_before;
    header_length = read_uint(fp);
    assert(header_length == 9);
    packing_type = read_byte(fp);
    assert(packing_type == 0);
    row_count = read_ushort(fp);
    packed_data_size = read_ushort(fp);
    pos_before = ftell(fp);
    out->row_count = row_count;
    out->data = (struct xm_pattern_slot*)malloc(channel_count * row_count * sizeof(struct xm_pattern_slot));
    memset(out->data, 0, channel_count * row_count * sizeof(struct xm_pattern_slot));
    if (packed_data_size != 0) {
        /* unpack pattern data */
        int row, column;
        struct xm_pattern_slot *slot;
        slot = out->data;
        for (row = 0; row < row_count; ++row) {
	    for (column = 0; column < channel_count; ++column) {
	        unsigned char pattern_byte;
                unsigned char note = 0, instrument = 0, volume = 0, effect_type = 0, effect_param = 0;
	        pattern_byte = read_byte(fp);
                if (pattern_byte & 0x80) {
                    /* compressed */
                    if (pattern_byte & 0x01)
		        note = read_byte(fp);
		    if (pattern_byte & 0x02)
		        instrument = read_byte(fp);
		    if (pattern_byte & 0x04)
		        volume = read_byte(fp);
		    if (pattern_byte & 0x08)
		        effect_type = read_byte(fp);
		    if (pattern_byte & 0x10)
		        effect_param = read_byte(fp);
	        } else {
		    /* uncompressed */
		    note = pattern_byte;
		    instrument = read_byte(fp);
		    volume = read_byte(fp);
		    effect_type = read_byte(fp);
		    effect_param = read_byte(fp);
	        }
	        slot->note = note;
	        slot->instrument = instrument;
	        slot->volume = volume;
	        /* ### hackensack */
	        if ((effect_type == 0) && (effect_param != 0)) effect_type = 5; /* arpeggio */
	        slot->effect_type = effect_type;
	        slot->effect_param = effect_param;
                ++slot;
	    }
        }
        assert(ftell(fp) == pos_before + packed_data_size);
    }
    return XM_NO_ERROR;
}

int xm_read(FILE *fp, struct xm *xm)
{
    /* read header */
    int ret = xm_read_header(fp, &xm->header);
    if (ret)
        return ret;
    /* read patterns */
    xm->patterns = (struct xm_pattern*)malloc(xm->header.pattern_count * sizeof(struct xm_pattern));
    memset(xm->patterns, 0, xm->header.pattern_count * sizeof(struct xm_pattern));
    {
        int i;
        for (i = 0; i < xm->header.pattern_count; ++i) {
            ret = xm_read_pattern(fp, xm->header.channel_count, &xm->patterns[i]);
            if (ret)
                return ret;
        }
    }
    return XM_NO_ERROR;
}

void xm_print_header(const struct xm_header *head, FILE *fp)
{
    {
        char tmp[21];
        tmp[20] = '\0';
        strncpy(tmp, head->module_name, 20);
        fprintf(fp, "Module name: '%s'\n", tmp);
        strncpy(tmp, head->tracker_name, 20);
        fprintf(fp, "Tracker name: '%s'\n", tmp);
    }
    fprintf(fp, "Version: %.4X\n", head->version);
    fprintf(fp, "Song length: %d\n", head->song_length);
    fprintf(fp, "Restart position: %d\n", head->restart_position);
    fprintf(fp, "Number of channels: %d\n", head->channel_count);
    fprintf(fp, "Number of patterns: %d\n", head->pattern_count);
    fprintf(fp, "Number of instruments: %d\n", head->instrument_count);
    fprintf(fp, "Flags: %d\n", head->flags);
    fprintf(fp, "Default tempo: %d\n", head->default_tempo);
    fprintf(fp, "Default BPM: %d\n", head->default_bpm);
}

void xm_print_pattern(const struct xm *xm, int pindex, FILE *fp)
{
    int row;
    const struct xm_pattern *pat = &xm->patterns[pindex];
    for (row = 0; row < pat->row_count; ++row) {
        const struct xm_pattern_slot *slot = &pat->data[row * xm->header.channel_count];
        fprintf(fp, "%.2x: %.2x %.2x %.2x %.2x %.2x\n",
                row, slot->note, slot->instrument, slot->volume,
                slot->effect_type, slot->effect_param);
    }
}

void xm_destroy(struct xm *xm)
{
    int i;
    for (i = 0; i < xm->header.pattern_count; ++i)
        free(xm->patterns[i].data);
    free(xm->patterns);
}
