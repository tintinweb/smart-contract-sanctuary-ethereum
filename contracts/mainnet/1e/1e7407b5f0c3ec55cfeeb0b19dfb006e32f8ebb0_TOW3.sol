/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.11.2 https://hardhat.org

// File contracts/Base64.sol

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}


// File contracts/Trigonometry.sol

// Thanks to https://github.com/mds1/solidity-trigonometry
pragma solidity ^0.8.0;

library Trigonometry {
  // Table index into the trigonometric table
  uint256 constant INDEX_WIDTH        = 8;
  // Interpolation between successive entries in the table
  uint256 constant INTERP_WIDTH       = 16;
  uint256 constant INDEX_OFFSET       = 28 - INDEX_WIDTH;
  uint256 constant INTERP_OFFSET      = INDEX_OFFSET - INTERP_WIDTH;
  uint32  constant ANGLES_IN_CYCLE    = 1073741824;
  uint32  constant QUADRANT_HIGH_MASK = 536870912;
  uint32  constant QUADRANT_LOW_MASK  = 268435456;
  uint256 constant SINE_TABLE_SIZE    = 256;
  uint256 internal constant PI          = 3141592653589793238;
  uint256 constant TWO_PI      = 2 * PI;
  uint256 constant PI_OVER_TWO = PI / 2;
  uint8   constant entry_bytes = 4; // each entry in the lookup table is 4 bytes
  uint256 constant entry_mask  = ((1 << 8*entry_bytes) - 1); // mask used to cast bytes32 -> lookup table entry
  bytes   constant sin_table   = hex"00_00_00_00_00_c9_0f_88_01_92_1d_20_02_5b_26_d7_03_24_2a_bf_03_ed_26_e6_04_b6_19_5d_05_7f_00_35_06_47_d9_7c_07_10_a3_45_07_d9_5b_9e_08_a2_00_9a_09_6a_90_49_0a_33_08_bc_0a_fb_68_05_0b_c3_ac_35_0c_8b_d3_5e_0d_53_db_92_0e_1b_c2_e4_0e_e3_87_66_0f_ab_27_2b_10_72_a0_48_11_39_f0_cf_12_01_16_d5_12_c8_10_6e_13_8e_db_b1_14_55_76_b1_15_1b_df_85_15_e2_14_44_16_a8_13_05_17_6d_d9_de_18_33_66_e8_18_f8_b8_3c_19_bd_cb_f3_1a_82_a0_25_1b_47_32_ef_1c_0b_82_6a_1c_cf_8c_b3_1d_93_4f_e5_1e_56_ca_1e_1f_19_f9_7b_1f_dc_dc_1b_20_9f_70_1c_21_61_b3_9f_22_23_a4_c5_22_e5_41_af_23_a6_88_7e_24_67_77_57_25_28_0c_5d_25_e8_45_b6_26_a8_21_85_27_67_9d_f4_28_26_b9_28_28_e5_71_4a_29_a3_c4_85_2a_61_b1_01_2b_1f_34_eb_2b_dc_4e_6f_2c_98_fb_ba_2d_55_3a_fb_2e_11_0a_62_2e_cc_68_1e_2f_87_52_62_30_41_c7_60_30_fb_c5_4d_31_b5_4a_5d_32_6e_54_c7_33_26_e2_c2_33_de_f2_87_34_96_82_4f_35_4d_90_56_36_04_1a_d9_36_ba_20_13_37_6f_9e_46_38_24_93_b0_38_d8_fe_93_39_8c_dd_32_3a_40_2d_d1_3a_f2_ee_b7_3b_a5_1e_29_3c_56_ba_70_3d_07_c1_d5_3d_b8_32_a5_3e_68_0b_2c_3f_17_49_b7_3f_c5_ec_97_40_73_f2_1d_41_21_58_9a_41_ce_1e_64_42_7a_41_d0_43_25_c1_35_43_d0_9a_ec_44_7a_cd_50_45_24_56_bc_45_cd_35_8f_46_75_68_27_47_1c_ec_e6_47_c3_c2_2e_48_69_e6_64_49_0f_57_ee_49_b4_15_33_4a_58_1c_9d_4a_fb_6c_97_4b_9e_03_8f_4c_3f_df_f3_4c_e1_00_34_4d_81_62_c3_4e_21_06_17_4e_bf_e8_a4_4f_5e_08_e2_4f_fb_65_4c_50_97_fc_5e_51_33_cc_94_51_ce_d4_6e_52_69_12_6e_53_02_85_17_53_9b_2a_ef_54_33_02_7d_54_ca_0a_4a_55_60_40_e2_55_f5_a4_d2_56_8a_34_a9_57_1d_ee_f9_57_b0_d2_55_58_42_dd_54_58_d4_0e_8c_59_64_64_97_59_f3_de_12_5a_82_79_99_5b_10_35_ce_5b_9d_11_53_5c_29_0a_cc_5c_b4_20_df_5d_3e_52_36_5d_c7_9d_7b_5e_50_01_5d_5e_d7_7c_89_5f_5e_0d_b2_5f_e3_b3_8d_60_68_6c_ce_60_ec_38_2f_61_6f_14_6b_61_f1_00_3e_62_71_fa_68_62_f2_01_ac_63_71_14_cc_63_ef_32_8f_64_6c_59_bf_64_e8_89_25_65_63_bf_91_65_dd_fb_d2_66_57_3c_bb_66_cf_81_1f_67_46_c7_d7_67_bd_0f_bc_68_32_57_aa_68_a6_9e_80_69_19_e3_1f_69_8c_24_6b_69_fd_61_4a_6a_6d_98_a3_6a_dc_c9_64_6b_4a_f2_78_6b_b8_12_d0_6c_24_29_5f_6c_8f_35_1b_6c_f9_34_fb_6d_62_27_f9_6d_ca_0d_14_6e_30_e3_49_6e_96_a9_9c_6e_fb_5f_11_6f_5f_02_b1_6f_c1_93_84_70_23_10_99_70_83_78_fe_70_e2_cb_c5_71_41_08_04_71_9e_2c_d1_71_fa_39_48_72_55_2c_84_72_af_05_a6_73_07_c3_cf_73_5f_66_25_73_b5_eb_d0_74_0b_53_fa_74_5f_9d_d0_74_b2_c8_83_75_04_d3_44_75_55_bd_4b_75_a5_85_ce_75_f4_2c_0a_76_41_af_3c_76_8e_0e_a5_76_d9_49_88_77_23_5f_2c_77_6c_4e_da_77_b4_17_df_77_fa_b9_88_78_40_33_28_78_84_84_13_78_c7_ab_a1_79_09_a9_2c_79_4a_7c_11_79_8a_23_b0_79_c8_9f_6d_7a_05_ee_ac_7a_42_10_d8_7a_7d_05_5a_7a_b6_cb_a3_7a_ef_63_23_7b_26_cb_4e_7b_5d_03_9d_7b_92_0b_88_7b_c5_e2_8f_7b_f8_88_2f_7c_29_fb_ed_7c_5a_3d_4f_7c_89_4b_dd_7c_b7_27_23_7c_e3_ce_b1_7d_0f_42_17_7d_39_80_eb_7d_62_8a_c5_7d_8a_5f_3f_7d_b0_fd_f7_7d_d6_66_8e_7d_fa_98_a7_7e_1d_93_e9_7e_3f_57_fe_7e_5f_e4_92_7e_7f_39_56_7e_9d_55_fb_7e_ba_3a_38_7e_d5_e5_c5_7e_f0_58_5f_7f_09_91_c3_7f_21_91_b3_7f_38_57_f5_7f_4d_e4_50_7f_62_36_8e_7f_75_4e_7f_7f_87_2b_f2_7f_97_ce_bc_7f_a7_36_b3_7f_b5_63_b2_7f_c2_55_95_7f_ce_0c_3d_7f_d8_87_8d_7f_e1_c7_6a_7f_e9_cb_bf_7f_f0_94_77_7f_f6_21_81_7f_fa_72_d0_7f_fd_88_59_7f_ff_62_15_7f_ff_ff_ff";

  function sin(uint256 _angle) internal pure returns (int256) {
    unchecked {
      _angle = ANGLES_IN_CYCLE * (_angle % TWO_PI) / TWO_PI;
      uint256 interp = (_angle >> INTERP_OFFSET) & ((1 << INTERP_WIDTH) - 1);
      uint256 index  = (_angle >> INDEX_OFFSET)  & ((1 << INDEX_WIDTH)  - 1);
      
      bool is_odd_quadrant      = (_angle & QUADRANT_LOW_MASK)  == 0;
      bool is_negative_quadrant = (_angle & QUADRANT_HIGH_MASK) != 0;

      if (!is_odd_quadrant) {
        index = SINE_TABLE_SIZE - 1 - index;
      }

      bytes memory table = sin_table;
      uint256 offset1_2 = (index + 2) * entry_bytes;

      uint256 x1_2; assembly {
        x1_2 := mload(add(table, offset1_2))
      }

      uint256 x1 = x1_2 >> 8*entry_bytes & entry_mask;
      uint256 x2 = x1_2 & entry_mask;

      uint256 approximation = ((x2 - x1) * interp) >> INTERP_WIDTH;
      int256 sine = is_odd_quadrant ? int256(x1) + int256(approximation) : int256(x2) - int256(approximation);
      if (is_negative_quadrant) {
        sine *= -1;
      }
      
      return sine * 1e18 / 2_147_483_647;
    }
  }

  function cos(uint256 _angle) internal pure returns (int256) {
    unchecked {
      return sin(_angle + PI_OVER_TWO);
    }
  }
}


// File contracts/Strings.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}


// File contracts/Images.sol

//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)

pragma solidity ^0.8.12;



library Images {
  using Strings for uint256;

  function getToWMetadata() internal pure returns(string memory) {
    return b64(abi.encodePacked(
      '{"name":"The Tree","description":"The Tree will spread wealth to whoever may have ever owned it."',
      ',"image":"', getSVG(getToWSVG()),
      '","attributes":[',
      getTrait(0, "Infinity"), ",",
      getTrait(1, "All"), ",",
      getTrait(2, "All"), "]}"
    ));
  }

  function getHostTokenMetadata(uint tokenId) internal pure returns(string memory){
    string memory color1;
    string memory color2;
    string memory wealth;
    (color1, color2, wealth) = getColors(tokenId);

    return b64(abi.encodePacked(
      '{"name":"Host token #', tokenId.toString(),
      '","description":"Honor to the ', tokenId.toString(), getOrdinal(tokenId), ' host of The Tree of Wealth"',
      ',"image":"', getSVG(getHostSVG(tokenId, color1, color2)),
      '", "attributes":[',
      getTrait(0, wealth ), ",",
      getTrait(1, color1), ",",
      getTrait(2, color2), ']}'
    ));
  }

  function b64(bytes memory meta) private pure returns(string memory) {
    return string.concat(
      "data:application/json;base64,",
      Base64.encode(meta)
    );
  }

  function getTrait(uint t, string memory v) private pure returns(string memory){
    string memory tt = t == 0 ?
      'Wealth' : (t == 1 ? 'Primary Color' : 'Secondary Color')
    ;

    return string.concat(
      '{"trait_type":"', tt,
      '","value":"', v,
      '"}'
    );
  }

  function getSVG( bytes memory content ) private pure returns(string memory){
    return string.concat(
      "data:image/svg+xml;base64,",
      Base64.encode(content)
    );
  }

  function getToWSVG() private pure returns(bytes memory){
    return abi.encodePacked(
      openDefsSVG(),
      getCoinSVG("#fd6", "#db5"),
      getCoinsSVG(),
      getHalfTree(),
      getGradientSVG(),
      getTreeSVG('url(#c)'),
      getWaveSVG(),
      closeDefsSVG(),
      "<path fill='#412' d='M0 0h1000v698H0z'/><use xlink:href='#e' fill='#825' transform='rotate(-2 27339 -14967.1) scale(7)'/><use xlink:href='#e' fill='#938' transform='rotate(-10 4026 -2573.2) scale(4)'/><use xlink:href='#e' fill='#d8b' transform='rotate(10 -3082.2 3145.6) scale(2.2)'/><circle fill='#023' cx='500' cy='1365' r='714'/><use xlink:href='#f'/></svg>"
    );
  }

  function getHostSVG( uint tokenId, string memory color1, string memory color2 ) private pure returns(bytes memory) {
    return abi.encodePacked(
        // We need to call 2 nested encodePacked in order to avoid
        // the Stack too deep error
        string(abi.encodePacked(
            openDefsSVG(),
            getCoinSVG(color1, color2),
            getCoinsSVG(),
            getHalfTree(),
            getTreeSVG(color1),
            getNumberDefinitions(tokenId),
            closeDefsSVG()
        )),
        string(abi.encodePacked(
            "<circle cx='500' cy='500' r='500' fill='", color1, "'/>", // external circle
            "<circle cx='500' cy='500' r='370' fill='", color2, "'/>", // private circle
            "<use xlink:href='#f' transform='matrix(.68 0 0 .68 160.5 183)'/>", // tree
            "<g fill='", color2, "' transform='translate(476 32)'><path d='m-79 82-6-30 28-6 6 31 11-3-15-69-11 2 6 30-27 6-6-30-11 2 15 70z'/><use xlink:href='#0' transform='scale(1.3 1) rotate(-3 -11.5 440.6)'/><path d='M64 73c31 4 37-36 7-41-26-3-20-22-6-20 7 0 12 2 18 6l6-9a40 40 0 0 0-23-8c-34 0-31 38-2 41 22 2 21 21 0 21a31 31 0 0 1-20-8l-7 8a46 46 0 0 0 27 10Zm60 10 13-60 19 5 3-10-49-11-2 9 19 5-14 60z'/></g>", // HOST
            getHostNumberSVG(tokenId, color2),
            "</svg>"
        ))
    );
  }

  // #f
  function getTreeSVG(string memory treeColor ) private pure returns(string memory){
    return string.concat(
      "<g id='f'><use xlink:href='#b' fill='",
      treeColor,
      "'/><use xlink:href='#b' fill='",
      treeColor,
      "' transform='matrix(-1 0 0 1 992 0)'/><use xlink:href='#d' transform='matrix(-1 0 0 1 1021 -25)'/><use xlink:href='#d' transform='translate(-25 -25)'/></g>"
    );
  }

  // #b
  function getHalfTree() private pure returns(string memory){
    return "<path d='M424 219c32 29 61 70 74 134v306c-15 0-41 9-45 17-46 84-62 161-62 264 0 19 1 41 3 60H275c5-130 47-239 130-328 8-9-15-9-28-7a786 786 0 0 0-34 7 518 518 0 0 0-219 328H3a519 519 0 0 1 246-300C157 735 64 798-6 865v-11l2-2a732 732 0 0 1 345-212c29-8 49-59 49-90 0-53-20-103-93-103-72 0-129 103-77 148-88-32-15-167 85-167 62 0 98 19 116 49v-1c3-16 3-33 3-39-1-44-27-88-84-93s-146 13-192 94c27-99 133-128 192-125 54 2 108 37 125 92-4-72-34-135-59-164-29-33-106-54-181 7 21-56 133-90 199-29Z' id='b'/>";
  }

  // #c
  function getGradientSVG() private pure returns(string memory) {
    return "<radialGradient cx='50%' cy='26.4%' fx='50%' fy='26.4%' r='83.3%' gradientTransform='matrix(-.20706 .96593 -1.08184 -.36235 .9 -.1)' id='c'><stop stop-color='#FFF' offset='0%'/><stop stop-color='#FFF' offset='60%'/><stop stop-color='#023' offset='100%'/></radialGradient>";
  }

  // #a
  function getCoinSVG( string memory color1, string memory color2 ) private pure returns(string memory) {
    return string.concat(
      "<g id='a'><circle fill='",
      color1,
      "' cx='25' cy='25' r='25'/><circle fill='",
      color2,
      "' cx='25' cy='25' r='19'/><path d='m30 36-5-5-4 5c-2 2-8-5-7-6l5-5-5-4c-1-2 5-8 7-7l4 5 5-5c1-1 8 5 6 7l-5 4 5 5c2 1-5 8-6 6Z' fill='",
      color1, 
      "'/></g>"
    );
  }

  // #d
  function getCoinsSVG() private pure returns(string memory) {
    return "<g id='d'><use xlink:href='#a' transform='translate(498 279)'/><use xlink:href='#a' transform='translate(528 227)'/><use xlink:href='#a' transform='translate(572 186)'/><use xlink:href='#a' transform='translate(629 163)'/><use xlink:href='#a' transform='translate(688 164)'/><use xlink:href='#a' transform='translate(749 186)'/><use xlink:href='#a' transform='translate(683 235)'/><use xlink:href='#a' transform='translate(623 246)'/><use xlink:href='#a' transform='translate(742 257)'/><use xlink:href='#a' transform='translate(585 296)'/><use xlink:href='#a' transform='translate(649 370)'/><use xlink:href='#a' transform='translate(714 373)'/><use xlink:href='#a' transform='translate(774 397)'/><use xlink:href='#a' transform='translate(844 374)'/><use xlink:href='#a' transform='translate(786 321)'/><use xlink:href='#a' transform='translate(823 447)'/><use xlink:href='#a' transform='translate(694 472)'/><use xlink:href='#a' transform='translate(750 499)'/><use xlink:href='#a' transform='translate(771 553)'/><use xlink:href='#a' transform='translate(838 524)'/></g>";
  }

  // #e
  function getWaveSVG() private pure returns(string memory)  {
    return "<path id='e' d='M0 150c57 0 52-30 86-65 35-34 64-33 64-85s-30-52-64-86c-34-33-32-64-86-64s-52 31-86 64c-33 34-64 27-64 86s31 52 64 86c34 34 29 64 86 64Z'/>";
  }

  function openDefsSVG() private pure returns(string memory){
    return "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='1000' height='1000'><defs>";
  }
  function closeDefsSVG() private pure returns(string memory){
    return "</defs>";
  }

  function getOrdinal( uint n ) private pure returns(string memory){
    if( n % 10 == 1 && n != 11 ) return 'st';
    if( n % 10 == 2 && n != 12 ) return 'nd';
    if( n % 10 == 3 && n != 13 ) return 'rd';
    return 'th';
  }

  function getColors( uint n ) private pure returns(string memory, string memory, string memory) {
    uint h = n*41 % 360;
    uint s = (n*n+69) % 100;
    uint l = n*61 % 100;
    
    uint factor = ((n+150) * 3 % 100);
    uint diff = l < 50 ? 
      (100 - (l + 50)) * factor / 100 : 
      (l - 50) * factor / 100
    ;

    uint altL = l < 50 ?
      l + 50 + diff :
      l - 50 - diff
    ;

    return (
      getColorCode( h, s, l ),
      getColorCode( h, s, altL),
      diff.toString()
    );
  }

  function getColorCode( uint h, uint s, uint l ) private pure returns (string memory) {
    return string.concat(
      'hsl(', h.toString(), ",", s.toString(), '%,', l.toString(), '%)'
    );
  }

  function getNumberDefinitions( uint n ) private pure returns (string memory) {
    bytes memory b = bytes(n.toString());

    // 0 is always defined as the O from HOST
    string memory definitions = getNumberSVG(0);
    uint isDefined = 0;

    for(uint i; i < b.length; i++){
      uint digit = uint(uint8(b[i])) - 48;
      if( digit != 0 ){
        // 9 image will just be 6 upside down
        uint position = digit == 9 ? 6 : digit;
        bool alreadyDefined = ((isDefined >> position) & 1) == 1;
        if( !alreadyDefined ){
          definitions = string.concat( definitions, getNumberSVG(position));
          isDefined = isDefined | uint(1) << position;
        }
      }
    }
  
    return definitions;
  }

  function getNumberSVG(uint n) private pure returns (string memory) {
    if( n == 0 ){
      return "<path id='0' d='M20 72c17 0 20-14 20-20V21c0-7-3-21-20-21S0 14 0 21v31c0 6 3 21 20 20Z'/>";
    }
    if( n == 1 ){
      return "<path id='1' d='M20 71V0H0l10 11v60z'/>";
    }
    if( n == 2 ){
      return "<path id='2' d='M41 70V60H14l23-28C58-2 0-13 0 19h10c0-17 32-8 18 7C8 48-2 63 0 70h41Z'/>";
    }
    if( n == 3 ){
      return "<path id='3' d='M33 34C58-5 0-10 0 18h11c-1-16 39-8 5 16 34 14 2 40-6 19H0c1 30 62 19 33-19Z'/>";
    }
    if( n == 4 ){
      return "<path id='4' d='M40 71V46l-29 5L35 0H24L0 51v10h30v10z'/>";
    }
    if( n == 5 ){
      return "<path id='5' d='M41 47c0-3 2-32-30-21V10h28V0H1v40c20-11 30-9 29 6 0 23-20 17-20 7H0c0 25 41 27 41-6Z'/>";
    }
    if( n == 6 ){
      return "<path id='6' d='M33 0H21L5 33l-1 3-1 1c-3 8-6 18 1 27 3 6 17 13 30 2 10-8 8-24 5-29-8-11-20-8-21-7v-1L33 0Z'/>";
    }
    if( n == 7 ){
      return "<path id='7' d='M16 71 45 0H0l10 10h19L5 71z'/>";
    }
    if( n == 8 ){
      return "<path id='8' d='M21 72c22 0 27-27 13-37 8-6 10-35-13-35C-3 0-1 29 7 35-6 45-2 72 21 72Z'/>";
    }
    
    return string.concat("<g id='error", n.toString(), "'/>" );
  }

  function getDigit(bytes1 b) private pure returns(uint) {
    return uint(uint8(b)) - 48;
  }

  function getHostNumberSVG(uint n, string memory color) private pure returns(string memory) {
    bytes memory b = bytes(n.toString());

    uint angle = 0;
    //int r = 424; // We are going to replace this to save one var

    // We always need the # symbol
    string memory output = "<path d='m14 71 3-22h10l-3 22h7l4-22h10v-6H35l2-15h10v-6h-9l3-22h-8l-3 22h-9l3-22h-8l-3 22H3v6h9l-2 15H0v6h9L6 71z'/>";

    for(uint i; i < b.length; i++){
      // uint digit = uint(uint8(b[i])) - 48;
     
      if( i > 0 && getDigit(b[i-1]) == 1 ){
        angle += Trigonometry.PI / 32;
      }
      else {
        angle += Trigonometry.PI / 25;
      }

      string memory translateX = uint( 424 * Trigonometry.sin(angle) / 1 ether).toString();
      int y = ((424 * Trigonometry.cos(angle)) - (424 * 1 ether)) / 1 ether;

      string memory translateY = y < 0 ? 
        string.concat( "-", uint(y * -1).toString() ) :
        uint(y).toString()
      ;
      if( getDigit(b[i]) == 9 ){
        output = string.concat(
          output,
          "<use xlink:href='#6' transform='translate(",
            translateX, " ",
            translateY, ") rotate(-", toDegrees( angle + Trigonometry.PI ), 
            ") translate(-40 -70)'/>"
        );
      }
      else {
        output = string.concat(
          output, 
          "<use xlink:href='#", getDigit(b[i]).toString(), 
          "' transform='translate(", translateX, " ", translateY,
          ") rotate(-", toDegrees(angle), ")'/>"
        );
      }
    }

    return string.concat(
      getNumberGroupSVG(angle, color),
      output,
      "</g>"
    );
  }

  function getNumberGroupSVG(uint angle, string memory color) private pure returns (string memory) {
    uint idAngle = (angle + (Trigonometry.PI/32)) / 2;
    //int r = 424; // We are going to replace this to save one var

    uint x = uint( (500 * 1 ether) - Trigonometry.sin(idAngle) * 424);
    uint y = uint( (476 * 1 ether) + Trigonometry.cos(idAngle) * 424);

    return string.concat(
      "<g fill='", color, "' transform='translate(",
        ( x / 1 ether ).toString(), ",",
        ( y / 1 ether ).toString(), ") rotate(",
        toDegrees(idAngle), ")'>"
    );
  }

  function toDegrees(uint angle) private pure returns ( string memory ) {
    return (angle * 180 / Trigonometry.PI).toString();
  }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File contracts/TOW_ERC721.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;






/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId; // Use IERC165 directly
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
       /* Overriden by the TOW contract */
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * _burn removed :)
     */

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    
    /* Removed _beforeTokenTransfer _afterTokenTransfer as they are not used */
}


// File contracts/TOW3.sol

//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)

pragma solidity ^0.8.12;


contract TOW3 is ERC721 {

  // Number of tokens minted
  // It will be used to calculate the current price
  // and also as token id of the next token
  uint256 private tokensMinted;

  // Different type of NFTs within our collection
  // type 0 is none, so we can detect unexistant tokens
  enum TokenType {
      NONE,
      TOW,
      HOST
  }

  // The Tree token metadata and id
  string private towMetadata;

  // How much to pay more on each buy
  uint256 public priceRaise;

  // At what transfer number when last withdrawal was made by a former host
  // Needed to calculated the amount to refund
  mapping(address => uint256) private lastWithdrawAt;

  // amount already withdrawn by addresses
  mapping(address => uint256) private alreadyWithdrawn;

  constructor(uint256 _priceRaise) ERC721("The Tree of Wealth", "TTOW") {
      priceRaise = _priceRaise;
      // First mint would be The Tree
      // And it's for the contract
      mint(address(this));
  }

  function mint(address _owner) private {
      uint256 newItemId = tokensMinted;

      // now mint
      _safeMint(_owner, newItemId);

      // Increase the token ids
      tokensMinted = tokensMinted + 1;
  }

  function getTokenType(uint256 tokenId) public view returns (TokenType) {
      if (tokenId == 0) return TokenType.TOW;
      if (tokenId >= tokensMinted) return TokenType.NONE;
      return TokenType.HOST;
  }

  function tokenURI(uint256 tokenId)
      public
      view
      override
      returns (string memory)
  {
    _requireMinted(tokenId);
      if (getTokenType(tokenId) == TokenType.TOW) {
          return Images.getToWMetadata();
      }

      return Images.getHostTokenMetadata(tokenId);
  }

  /**
    * @dev See {IERC721-transferFrom}.
    */
  function transferFrom( address from, address to, uint256 tokenId ) public onlyNotToW(tokenId) override {
    return super.transferFrom(from, to, tokenId);
  }

  /**
    * @dev See {IERC721-safeTransferFrom}.
    */
  function safeTransferFrom( address from, address to, uint256 tokenId, bytes memory _data ) public onlyNotToW(tokenId) override {
    return super.safeTransferFrom(from, to, tokenId, _data);
  }

  /**
    * Modifier to check that a token is not the ToW
    */
  modifier onlyNotToW(uint256 tokenId) {
    require(tokenId != 0,  "ToW: Can only transfer by using the host method");
    _;
  }

  /**
    * @dev See {IERC721-approve}.
    */
  function approve(address to, uint256 tokenId) public override {
    require(tokenId != 0, "ToW: Can't approve transactions for The Tree");
    super.approve(to, tokenId);
  }

  /**
    * Transfers the token to the caller, if it's sending the correct value
    */
  function host() public payable {
    address currentHost = ownerOf(0);

    // Always need to pay one ether more than the previous owner
    require(lastWithdrawAt[msg.sender] == 0, "ToW: You've already hosted The Tree" );

    // Always need to pay one ether more than the previous owner
    require(msg.value == currentPrice(), "ToW: The price is not right" );
    
    // Mint the token
    mint(msg.sender);

    // Set up the last withdraw for the sender to this token.
    lastWithdrawAt[msg.sender] = tokensMinted;

    // now transfer The Tree
    _transfer(currentHost, msg.sender, 0);
  }


  /**
    * Any holder might have some value hold in the contract
    * call withdraw to get that value
    */
  function withdraw() public {
    uint256 toWithdraw = availableToWithdraw();

    require( toWithdraw > 0, "ToW: No funds to withdraw");

    // Set the last withdraw to the current transfer
    lastWithdrawAt[msg.sender] = tokensMinted;

    // Update the value already withdrawn
    alreadyWithdrawn[msg.sender] += toWithdraw;

    // Transfer the funds
    payable(msg.sender).transfer(toWithdraw);

    // Emit event
    emit Withdraw(msg.sender, toWithdraw);
  }

  ////////////////////
  // Info methods
  ////////////////////
  function availableToWithdraw() public view returns(uint256) {
    uint256 lastWithdraw = lastWithdrawAt[msg.sender];

    require( lastWithdraw != 0,  "ToW: You've never been a host");
    

    return (tokensMinted - lastWithdraw) * priceRaise;
  }

  function currentPrice() public view returns(uint256) {
    if( tokensMinted == 1 ) return (priceRaise / 10);
    return (tokensMinted - 1) * priceRaise;
  }

  function hasBeenHost( address addr ) public view returns(bool) {
    return lastWithdrawAt[addr] > 0;
  }

  function getWithdrawnValue() public view returns(uint256) {
    return alreadyWithdrawn[msg.sender];
  }


  // Events
  event Withdraw(address owner, uint256 value);
}