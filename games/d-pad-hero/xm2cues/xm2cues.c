#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "xm.h"
#include "xm2cues.h"

#define NUM_LANES 4

struct output_stream {
    FILE *fp;
    int bit_index;
    unsigned char bits;
    int column;
};

static void output_stream_init(struct output_stream *stream, FILE *fp)
{
    stream->fp = fp;
    stream->bit_index = 0;
    stream->bits = 0;
    stream->column = 0;
}

static void output_stream_put_helper(struct output_stream *stream)
{
    if (stream->column == 16) {
        if (stream->fp)
            fprintf(stream->fp, "\n");
        stream->column = 0;
    }
    if (stream->fp)
        fprintf(stream->fp, "%s$%.2X", (stream->column == 0) ? "db " : ",", stream->bits);
    ++stream->column;
    stream->bits = 0;
}

static void output_stream_put_bits(struct output_stream *stream, int n, int v)
{
    int i;
    /*    fprintf(stdout, "output %d %X\n", n, v); */
    for (i = n-1; i >= 0; --i) {
        if (!(stream->bit_index & 7) && stream->bit_index)
            output_stream_put_helper(stream);
        stream->bits |= ((v & (1 << i)) >> i) << (7 - (stream->bit_index & 7));
        ++stream->bit_index;
    }
}

static void output_stream_flush(struct output_stream *stream)
{
    if (!stream->bit_index)
        return;
    output_stream_put_helper(stream);
}

static void output_delay(struct output_stream *stream, int delay)
{
    int buf[256];
    int pos = 0;
    assert(delay);
    while (delay) {
        static int factors[8] = { 1, 2, 4, 8, 12, 16, 24, 32 };
        int i;
        for (i = 7; i >= 0; --i) {
            int rem = delay % factors[i];
            if (!rem) {
                assert(pos < 256);
                buf[pos++] = i;
                delay -= factors[i];
                break;
            }
        }
    }

    {
        int i;
        for (i = pos-1; i > 0; --i) {
            output_stream_put_bits(stream, 3, buf[i]);
            /* Insert empty cue (effectively extending the delay) */
            output_stream_put_bits(stream, 4, 0);
        }
        output_stream_put_bits(stream, 3, buf[0]);
    }
}


struct lane_event {
    int start_row;
    int end_row;
    const struct xm_pattern_slot *slot;
    int order_index;
    int row_in_pattern;
    int channel;
};

struct lane_event_vector {
    struct lane_event *data;
    int count;
    int capacity;
};

void lane_event_vector_init(struct lane_event_vector *vector)
{
    vector->data = 0;
    vector->count = 0;
    vector->capacity = 0;
}

#define LANE_EVENT_VECTOR_GROWTH 100

struct lane_event *lane_event_vector_push(struct lane_event_vector *vector)
{
    if (vector->count >= vector->capacity) {
        vector->capacity += LANE_EVENT_VECTOR_GROWTH;
        vector->data = (struct lane_event *)realloc(vector->data, vector->capacity * sizeof(struct lane_event));
        assert(vector->data);
    }
    return &vector->data[vector->count++];
}

void lane_event_vector_destroy(struct lane_event_vector *vector)
{
    if (vector->data)
        free(vector->data);
    vector->data = 0;
    vector->count = 0;
    vector->capacity = 0;
}


struct cue {
    int row;
    unsigned char deterministic_lanes_mask;
    unsigned char candidate_lanes_mask;
    unsigned char hold_lanes_mask;
    unsigned char intensity_lanes_mask;
    int hold_durations[NUM_LANES];
    unsigned char intensities[NUM_LANES];
    unsigned char levels[NUM_LANES];
    int order_index;
    int row_in_pattern;
};

struct cue_vector {
    struct cue *data;
    int count;
    int capacity;
};

void cue_vector_init(struct cue_vector *vector)
{
    vector->data = 0;
    vector->count = 0;
    vector->capacity = 0;
}

#define CUE_VECTOR_GROWTH 100

struct cue *cue_vector_push(struct cue_vector *vector)
{
    if (vector->count >= vector->capacity) {
        vector->capacity += CUE_VECTOR_GROWTH;
        vector->data = (struct cue *)realloc(vector->data, vector->capacity * sizeof(struct cue));
        assert(vector->data);
    }
    return &vector->data[vector->count++];
}

void cue_vector_destroy(struct cue_vector *vector)
{
    if (vector->data)
        free(vector->data);
    vector->data = 0;
    vector->count = 0;
    vector->capacity = 0;
}


typedef enum { DIAGNOSTIC_WARNING, DIAGNOSTIC_ERROR } DiagnosticSeverity;

struct diagnostic {
    DiagnosticSeverity severity;
    int order_index;
    int row_in_pattern;
    int channel;
    struct lane_event *context;
    char message[256];
};

struct diagnostic_vector {
    struct diagnostic *data;
    int count;
    int capacity;
};

void diagnostic_vector_init(struct diagnostic_vector *vector)
{
    vector->data = 0;
    vector->count = 0;
    vector->capacity = 0;
}

#define DIAGNOSTIC_VECTOR_GROWTH 100

struct diagnostic *diagnostic_vector_push(struct diagnostic_vector *vector)
{
    if (vector->count >= vector->capacity) {
        vector->capacity += DIAGNOSTIC_VECTOR_GROWTH;
        vector->data = (struct diagnostic *)realloc(vector->data, vector->capacity * sizeof(struct diagnostic));
        assert(vector->data);
    }
    return &vector->data[vector->count++];
}

void diagnostic_emit(struct diagnostic_vector *vector, DiagnosticSeverity severity,
                     int order_index, int row_in_pattern, int channel,
                     struct lane_event *context, const char *message)
{
    struct diagnostic *diag = diagnostic_vector_push(vector);
    diag->severity = severity;
    diag->order_index = order_index;
    diag->row_in_pattern = row_in_pattern;
    diag->channel = channel;
    diag->context = context;
    strncpy(diag->message, message, sizeof(diag->message)-1);
    diag->message[sizeof(diag->message)-1] = '\0';
}

void diagnostic_print(const struct diagnostic *diag, FILE *fp)
{
    const char *severity_str = (diag->severity == DIAGNOSTIC_ERROR) ? "error" : "warning";
    if (diag->channel == -1) {
        fprintf(fp, "O%.2X:R%.2X: %s: %s\n",
            diag->order_index, diag->row_in_pattern,
            severity_str, diag->message);
    } else {
        fprintf(fp, "O%.2X:R%.2X:CH%d: %s: %s\n",
            diag->order_index, diag->row_in_pattern, diag->channel + 1,
            severity_str, diag->message);
    }
}

void diagnostic_print_all(const struct diagnostic_vector *vector, FILE *fp)
{
    for (int i = 0; i < vector->count; ++i) {
        diagnostic_print(&vector->data[i], fp);
    }
}

void diagnostic_vector_destroy(struct diagnostic_vector *vector)
{
    if (vector->data)
        free(vector->data);
    vector->data = 0;
    vector->count = 0;
    vector->capacity = 0;
}

int diagnostic_has_errors(const struct diagnostic_vector *vector)
{
    for (int i = 0; i < vector->count; ++i) {
        if (vector->data[i].severity == DIAGNOSTIC_ERROR)
            return 1;
    }
    return 0;
}


#define EFFECT_TYPE_I 18 /* Intensity */

void extract_lane_events(const struct xm *xm, int channel,
                         struct lane_event_vector *events,
                         struct diagnostic_vector *diagnostics)
{
    int abs_row;
    int order_index;
    struct lane_event *previous_note_event = 0;
    for (order_index = 0, abs_row = 0; order_index < xm->header.song_length; ++order_index) {
        int row_in_pattern;
        int pattern_index = xm->header.pattern_order_table[order_index];
        const struct xm_pattern *pattern = &xm->patterns[pattern_index];
        for (row_in_pattern = 0; row_in_pattern < pattern->row_count; ++row_in_pattern, ++abs_row) {
            const struct xm_pattern_slot *row_data = &pattern->data[row_in_pattern * xm->header.channel_count];
            const struct xm_pattern_slot *slot = &row_data[channel];
            if (slot->effect_type && slot->effect_type != EFFECT_TYPE_I) {
                diagnostic_emit(diagnostics, DIAGNOSTIC_ERROR, order_index, row_in_pattern, channel, 0,
                                "unsupported effect type (only IXX is supported)");
            }
            if (slot->note == 0x61) {   /* Release */
                if (!previous_note_event) {
                    diagnostic_emit(diagnostics, DIAGNOSTIC_ERROR, order_index, row_in_pattern, channel, 0,
                                    "release without prior note");
                } else {
                    if (slot->instrument && slot->instrument != 0x41) {
                        diagnostic_emit(diagnostics, DIAGNOSTIC_ERROR, order_index, row_in_pattern, channel, previous_note_event,
                                        "release note has invalid instrument (only no instrument or 41 is supported)");
                    }
                    previous_note_event->end_row = abs_row;
                    if (((abs_row - previous_note_event->start_row) % 4) != 0) {
                        /* Round up to nearest multiple of 4 rows */
                        previous_note_event->end_row += 4 - ((abs_row - previous_note_event->start_row) % 4);
                    }
                    previous_note_event = 0;
                }
            } else if (slot->note) { /* Note on */
                struct lane_event *event = lane_event_vector_push(events);
                event->start_row = abs_row;
                event->end_row = -1;
                event->slot = slot;
                event->order_index = order_index;
                event->row_in_pattern = row_in_pattern;
                event->channel = channel;
                previous_note_event = event;
                if (slot->instrument != 0x41 && slot->instrument != 0x42) {
                    diagnostic_emit(diagnostics, DIAGNOSTIC_ERROR, order_index, row_in_pattern, channel, event,
                                    "unsupported instrument (only 41 and 42 are supported)");
                }
            } else {
                /* No note */
                if (slot->effect_type == EFFECT_TYPE_I) { /* Intensity effect */
                    diagnostic_emit(diagnostics, DIAGNOSTIC_ERROR, order_index, row_in_pattern, channel, 0,
                                    "intensity effect (IXX) requires a note to be present");
                }
            }
        }
    }
}

static int any_lane_events_remaining(const struct lane_event_vector *lane_events,
                                     const int *lane_indices)
{
    for (int lane = 0; lane < NUM_LANES; ++lane) {
        const struct lane_event_vector *vector = &lane_events[lane];
        int index = lane_indices[lane];
        if (index < vector->count)
            return 1;
    }
    return 0;
}

static int find_next_event_start_row(const struct lane_event_vector *lane_events,
                                    const int *lane_indices)
{
    int min_start_row = -1;
    for (int lane = 0; lane < NUM_LANES; ++lane) {
        const struct lane_event_vector *vector = &lane_events[lane];
        int index = lane_indices[lane];
        if (index < vector->count) {
            struct lane_event *event = &vector->data[index];
            if (min_start_row == -1 || event->start_row < min_start_row) {
                min_start_row = event->start_row;
            }
        }
    }
    return min_start_row;
}

int convert_lanes_mask_to_chord_id(unsigned char lanes_mask)
{
    switch (lanes_mask) {
        case 0x01: return 1; /* Left */
        case 0x02: return 2; /* Right */
        case 0x04: return 3; /* B */
        case 0x08: return 4; /* A */
        case 0x05: return 5; /* Left + B */
        case 0x09: return 6; /* Left + A */
        case 0x06: return 7; /* Right + B */
        case 0x0A: return 8; /* Right + A */
        case 0x0C: return 9; /* B + A */
        case 0x0D: return 10; /* Left + B + A */
        case 0x0E: return 11; /* Right + B + A */
        default:
            return -1; /* Invalid lanes combination */
    }
}

int get_num_lanes_in_mask(unsigned char lanes_mask)
{
    int count = 0;
    for (int lane = 0; lane < NUM_LANES; ++lane) {
        if (lanes_mask & (1 << lane))
            ++count;
    }
    return count;
}

void combine_lane_events_into_cues(const struct lane_event_vector *lane_events,
                                   struct cue_vector *cues,
                                   struct diagnostic_vector *diagnostics)
{
    int lane_indices[NUM_LANES];
    memset(lane_indices, 0, sizeof(lane_indices));
    while (any_lane_events_remaining(lane_events, lane_indices)) {
        struct cue *cue = cue_vector_push(cues);
        memset(cue, 0, sizeof(struct cue));
        int min_start_row = find_next_event_start_row(lane_events, lane_indices);
        cue->row = min_start_row;
        for (int lane = 0; lane < NUM_LANES; ++lane) {
            const struct lane_event_vector *vector = &lane_events[lane];
            int index = lane_indices[lane];
            if (index < vector->count) {
                struct lane_event *event = &vector->data[index];
                if (event->start_row == min_start_row) {
                    /* This lane has an event starting now */
                    cue->order_index = event->order_index;
                    cue->row_in_pattern = event->row_in_pattern;
                    assert(event->slot->note);
                    if (event->slot->instrument == 0x41) {
                        cue->deterministic_lanes_mask |= (1 << lane);
                    }
                    else if (event->slot->instrument == 0x42) {
                        cue->candidate_lanes_mask |= (1 << lane);
                    }
                    int hold_duration = event->end_row - event->start_row;
                    if (hold_duration > 0) {
                        cue->hold_lanes_mask |= (1 << lane);
                        cue->hold_durations[lane] = (hold_duration - 1) / 4;
                    }
                    if (event->slot->effect_type == EFFECT_TYPE_I) { /* Intensity */
                        cue->intensity_lanes_mask |= (1 << lane);
                        cue->intensities[lane] = event->slot->effect_param;
                    }
                    /* Advance to next event in this lane */
                    lane_indices[lane]++;
                }
            }
        }
        int chord_id = convert_lanes_mask_to_chord_id(cue->deterministic_lanes_mask | cue->candidate_lanes_mask);
        if (chord_id == -1) {
            diagnostic_emit(diagnostics, DIAGNOSTIC_ERROR, cue->order_index, cue->row_in_pattern, -1, 0,
                            "invalid lanes combination in cue");
        } else {
            int num_lanes = get_num_lanes_in_mask(cue->deterministic_lanes_mask | cue->candidate_lanes_mask);
            if (num_lanes > 1) {
                /* For multi-lane chords, ensure all lanes have intensities */
                int has_intensities_count = 0;
                for (int lane = 0; lane < NUM_LANES; ++lane) {
                    if (cue->intensity_lanes_mask & (1 << lane)) {
                        ++has_intensities_count;
                    }
                }
                if (num_lanes - has_intensities_count > 1) {
                    diagnostic_emit(diagnostics, DIAGNOSTIC_WARNING, cue->order_index, cue->row_in_pattern, -1, 0,
                                    "one or more lanes lack intensity (IXX)");
                }
            }
        }
    }
}

void output_cues_assembly_code(struct output_stream *stream,
                               const struct cue_vector *cues,
                               const struct xm2cues_options *options,
                               const struct xm *xm)
{
    FILE *out = stream->fp;
    fprintf(out, "; Generated from %s by %s\n", options->input_filename, options->program_version);

    /* Output the header */
    int progress_inc;
    static const int progress_max = 96;
    progress_inc = (progress_max << 8) / cues->count;
    assert(progress_inc < 65536);
    fprintf(out, "%scues:\n", options->label_prefix);
    fprintf(out, "db $%.2X,$%.2X\n", progress_inc >> 8, progress_inc & 0xFF);

    /* Output cues */
    int previous_row = 0;
    if (cues->count > 0) {
        /* The first payload is an empty cue (followed by the initial delay) */
        output_stream_put_bits(stream, 4, 0);
    }
    for (int i = 0; i < cues->count; ++i) {
        const struct cue *cue = &cues->data[i];
        int delay = cue->row - previous_row;
        output_delay(stream, delay);
        previous_row = cue->row;
        /* Output base payload */
        if (cue->hold_lanes_mask || cue->candidate_lanes_mask || cue->intensity_lanes_mask) {
            int chord_id = convert_lanes_mask_to_chord_id(cue->deterministic_lanes_mask | cue->candidate_lanes_mask);
            output_stream_put_bits(stream, 4, 0xC | (chord_id & 0x3));
            output_stream_put_bits(stream, 2, (chord_id >> 2) & 0x3);
            /* Output extensions */
            output_stream_put_bits(stream, 1, (cue->intensity_lanes_mask ? 1 : 0));
            if (cue->intensity_lanes_mask) {
                for (int lane = 0; lane < NUM_LANES; ++lane) {
                    if ((cue->deterministic_lanes_mask | cue->candidate_lanes_mask) & (1 << lane)) {
                        if (get_num_lanes_in_mask(cue->deterministic_lanes_mask | cue->candidate_lanes_mask) > 1) {
                            output_stream_put_bits(stream, 1, (cue->intensity_lanes_mask & (1 << lane)) ? 1 : 0);
                        }
                        if (cue->intensity_lanes_mask & (1 << lane)) {
                            output_stream_put_bits(stream, 4, cue->intensities[lane] >> 4);
                        }
                    }
                }
            }

            output_stream_put_bits(stream, 1, (cue->candidate_lanes_mask ? 1 : 0));
            if (cue->candidate_lanes_mask) {
                for (int lane = 0; lane < NUM_LANES; ++lane) {
                    if ((cue->deterministic_lanes_mask | cue->candidate_lanes_mask) & (1 << lane)) {
                        if (get_num_lanes_in_mask(cue->deterministic_lanes_mask | cue->candidate_lanes_mask) > 1) {
                            output_stream_put_bits(stream, 1, (cue->candidate_lanes_mask & (1 << lane)) ? 1 : 0);
                        }
                    }
                }
            }

            output_stream_put_bits(stream, 1, (cue->hold_lanes_mask ? 1 : 0));
            if (cue->hold_lanes_mask) {
                for (int lane = 0; lane < NUM_LANES; ++lane) {
                    if ((cue->deterministic_lanes_mask | cue->candidate_lanes_mask) & (1 << lane)) {
                        if (get_num_lanes_in_mask(cue->deterministic_lanes_mask | cue->candidate_lanes_mask) > 1) {
                            output_stream_put_bits(stream, 1, (cue->hold_lanes_mask & (1 << lane)) ? 1 : 0);
                        }
                        if (cue->hold_lanes_mask & (1 << lane)) {
                            output_stream_put_bits(stream, 4, cue->hold_durations[lane]);
                        }
                    }
                }
            }
        } else {
            /* A chord without extensions */
            assert(cue->deterministic_lanes_mask);
            int chord_id = convert_lanes_mask_to_chord_id(cue->deterministic_lanes_mask);
            output_stream_put_bits(stream, 4, chord_id);
        }
    }

    /* Terminate data: delay=0, end-of-data-marker=0x0F */
    output_stream_put_bits(stream, 3, 0);
    output_stream_put_bits(stream, 6, 0x3F);
    output_stream_flush(stream);
    fprintf(out, "\n");
}

/**
  Converts the given \a xm to a D-Pad Hero cue stream; writes the 6502
  assembly language representation of the cue stream to \a out.
*/
int convert_xm_to_cues(const struct xm *xm, const struct xm2cues_options *options, FILE *out)
{
    static const int channel_base = 4; /* Cues are in channels 4-7 (channels 0-3 contain the music) */
    struct output_stream stream;
    struct lane_event_vector lane_events[NUM_LANES];
    struct diagnostic_vector diagnostics;
    struct cue_vector cues;

    diagnostic_vector_init(&diagnostics);

    /* First pass: Extract lane events */
    for (int lane = 0; lane < NUM_LANES; ++lane) {
        struct lane_event_vector *vector = &lane_events[lane];
        lane_event_vector_init(vector);
        extract_lane_events(xm, channel_base + lane, vector, &diagnostics);
    }

    /* Second pass: Combine lane events into cues */
    cue_vector_init(&cues);
    combine_lane_events_into_cues(lane_events, &cues, &diagnostics);

    diagnostic_print_all(&diagnostics, stderr);
    int has_errors = diagnostic_has_errors(&diagnostics);

    if (!has_errors) {
        /* Third pass: Output the data */
        output_stream_init(&stream, out);
        output_cues_assembly_code(&stream, &cues, options, xm);
    }

    /* Cleanup */
    diagnostic_vector_destroy(&diagnostics);
    cue_vector_destroy(&cues);
    for (int lane = 0; lane < NUM_LANES; ++lane) {
        struct lane_event_vector *vector = &lane_events[lane];
        lane_event_vector_destroy(vector);
    }

    return has_errors ? 0 : 1;
}
