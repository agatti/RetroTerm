/*
 * Copyright 2017-2018 Alessandro Gatti - frob.it
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include <metal_stdlib>

using namespace metal;

constant half4 PALETTE[16] = {half4(0.000000, 0.000000, 0.000000, 1.000000),
                              half4(1.000000, 1.000000, 1.000000, 1.000000),
                              half4(0.533333, 0.000000, 0.000000, 1.000000),
                              half4(0.666667, 1.000000, 0.933333, 1.000000),
                              half4(0.800000, 0.266667, 0.800000, 1.000000),
                              half4(0.000000, 0.800000, 0.333333, 1.000000),
                              half4(0.000000, 0.000000, 0.666667, 1.000000),
                              half4(0.933333, 0.933333, 0.466667, 1.000000),
                              half4(0.866667, 0.533333, 0.333333, 1.000000),
                              half4(0.400000, 0.266667, 0.000000, 1.000000),
                              half4(1.000000, 0.466667, 0.466667, 1.000000),
                              half4(0.200000, 0.200000, 0.200000, 1.000000),
                              half4(0.466667, 0.466667, 0.466667, 1.000000),
                              half4(0.666667, 1.000000, 0.400000, 1.000000),
                              half4(0.000000, 0.533333, 1.000000, 1.000000),
                              half4(0.733333, 0.733333, 0.733333, 1.000000)};

struct vertex_in_t {
  float4 position;
  float2 texture;
};

struct vertex_out_t {
  float4 position[[position]];
  float2 texture;
};

struct context_t {
  float screen_width;
  float screen_height;
  ushort cells_wide;
  ushort cells_tall;
  ushort selection_start;
  ushort selection_end;
  ushort cursor_row;
  ushort cursor_column;
  uchar flags;
};

vertex vertex_out_t vertex_terminal(
    constant vertex_in_t *vtx_array[[buffer(0)]], uint vtx_id[[vertex_id]]) {
  vertex_out_t vtx_out;

  vtx_out.position = vtx_array[vtx_id].position;
  vtx_out.texture = vtx_array[vtx_id].texture;

  return vtx_out;
}

fragment half4 fragment_terminal(
    vertex_out_t vtx[[stage_in]], constant context_t &ctx[[buffer(0)]],
    constant uint *content[[buffer(1)]],
    texture2d<half, access::sample> charset[[texture(0)]]) {

  constexpr sampler charset_sampler(coord::normalized, address::clamp_to_zero,
                                    filter::nearest);

  float2 normalised = float2(vtx.texture.x, 1.0 - vtx.texture.y);
  float2 scaled = normalised * float2(ctx.cells_wide, ctx.cells_tall);
  uint2 current = uint2(scaled);
  ushort index = (current.y * ctx.cells_wide) + current.x;
  uint data = content[index];

  uint character = extract_bits(data, 0, 8);
  uint foreground = extract_bits(data, 8, 4);
  uint background = extract_bits(data, 12, 4);
  uint reverse = extract_bits(data, 16, 1);

  if (reverse != 0) {
    character += 128;
  }

  uint character_du = int(fract(scaled.x) * 8.0);
  uint character_dv = 1 + int(fract(scaled.y) * 8.0); // + 1 ?

  float character_u = (character_du + ((character % 32) * 8)) / 256.0;
  float character_v = 1.0 - ((character_dv + ((character / 32) * 8)) / 128.0);

  if (extract_bits(ctx.flags, 1, 1) != 0) {
    character_v -= 0.5;
  }

  half4 texel =
      charset.sample(charset_sampler, float2(character_u, character_v));

  bool reversed =
      ((ctx.selection_end >= index) && (ctx.selection_start <= index)) &&
      ((ctx.selection_end - ctx.selection_start) > 0);

  if ((extract_bits(ctx.flags, 0, 1) != 0) &&
      (current.x == ctx.cursor_column) && (current.y == ctx.cursor_row)) {
    reversed = !reversed;
  }

  return reversed ? (sign(texel.r) > 0.0 ? half4(texel) * PALETTE[background]
                                         : PALETTE[foreground])
                  : (sign(texel.r) > 0.0 ? half4(texel) * PALETTE[foreground]
                                         : PALETTE[background]);
}
