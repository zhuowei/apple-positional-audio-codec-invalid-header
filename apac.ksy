meta:
  id: apac
  bit-endian: be
  endian: le
seq:
  - id: a
    type: b16
  - id: global_config
    type: apac_global_config
types:
  apac_global_config:
    seq:
      - id: f0_20
        type: b6
      - id: f1_22
        type: b4
      - id: f2_128
        type: b1
      - id: mp4_sample_rate_24
        type: b6
      - id: f4_29
        type: b6
      - id: f5_180
        type: b8
      - id: f6_12c
        type: b8
      - id: f7_129
        type: b1
      - id: asc_config_count
        type: b3 # varint: 6u, 12u - 3 bits, 6 bits, 12 bits respectively
      - id: asc_config
        type: apac_global_config_audio_scene_component_config
        repeat: expr
        repeat-expr: asc_config_count
      - id: f_179
        type: b1
      - id: f_148_count
        type: b3 # varint: 6u, 12u
        if: f_179
        # more stuff
  apac_global_config_audio_scene_component_config:
    seq:
      - id: f0_2a
        type: b8
      - id: asc_type
        type: b3
      - id: asc
        type:
          switch-on: asc_type
          cases:
            0: apac_chan_codec_config
            1: apac_obj_codec_config
            2: apac_hoa_codec_config
            3: apac_stic_codec_config
            4: apac_spch_codec_config
            5: apac_passthrough_codec_config
  apac_chan_codec_config:
    seq:
      - id: dummy
        type: b1
  apac_obj_codec_config:
    seq:
      - id: dummy
        type: b1
  apac_hoa_codec_config:
    seq:
      - id: write_num_hoa_coeffs_f_47
        type: b1
      - id: f_40
        type: b1
      - id: write_f_42_f_41
        type: b1
      - id: f_42
        type: b1
        if: write_f_42_f_41
      - id: f_43
        type: b1
      - id: f_45
        type: b1
      - id: f_46
        type: b1
      - id: write_fc_f_4c
        type: b1
      - id: f_fc
        type: b2
        if: write_fc_f_4c
      - id: f_100
        type: b4 # varint: <6u, 8u>
        if: write_fc_f_4c
      - id: f_50
        type: b2
      - id: f_f8
        type: b2
      - id: f_6c
        type: b2
      - id: num_hoa_coeffs_f_5c
        type: b7 # varint?
        if: write_num_hoa_coeffs_f_47 == false
      - id: some_other_thing_hoa_order
        type: b4 # varint: <6u, 8u>
        if: write_num_hoa_coeffs_f_47
      - id: num_subbands_4_sc_count_60
        type: b4 # varint: <6u, 8u>
      - id: fancy_num_coeffs_calc_100
        type: b2 # variable - this is 3,2...
      - id: num_subbands_4_sc
        type: apac_hoa_subband_4_sc
        repeat: expr
        repeat-expr: num_subbands_4_sc_count_60
      - id: f_44
        type: b1
      # these are tied to 100...
      - id: something_after_f44
        type: b1
        if: f_44 == false
      # also tied to write_f_42_f_41
      - id: tce_config_count
        type: b5 # varint: <10u, 16>
      - id: tce_config
        type: b3
        repeat: expr
        repeat-expr: tce_config_count
      - id: f_78
        type: b1
      - id: audio_channel_layout_tag_top
        type: b16
      - id: audio_channel_layout_tag_bottom
        type: b16
      - id: f_e0
        type: b1
        # if true there's a repeat here

  apac_hoa_subband_4_sc:
    seq:
      - id: f_90
        type: b4 # varint: <6u, 8u>
      - id: f_a8
        type: b4 # is it?
        if: _parent.write_num_hoa_coeffs_f_47
      # TODO

  apac_stic_codec_config:
    seq:
      - id: f0_50
        type: b1
      - id: f1_38
        type: b20
      - id: inner_count
        type: b5 # varint: 10u, 16u
      - id: inner
        type: apac_stic_codec_config_inner
        repeat: expr
        repeat-expr: inner_count
  apac_stic_codec_config_inner:
    seq:
      - id: length
        type: b8
      - id: entry_type
        type: b3
      - id: too_long_didn_t_write
        type: b1
        repeat: expr
        repeat-expr: length
  apac_spch_codec_config:
    seq:
      - id: dummy
        type: b1
  apac_passthrough_codec_config:
    seq:
      - id: dummy
        type: b1
