// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract Renderer {
  uint256[2][8] public weapons;
  uint256[2][8] public armor;
  uint256[2][8] public health;
  uint256[2][8] public celerity;
  uint256[2][8][32] public assets;

  uint64[8] weaponNames;
  uint64[8] armorNames;
  uint64[8] healthNames;
  uint64[8] celerityNames;
  uint64[8][4] gearNames;

  uint8[3][6] public rarityColors;

  uint8[6] public rarityToVariationMod;

  constructor() {
    rarityToVariationMod[0] = 2;
    rarityToVariationMod[1] = 3;
    rarityToVariationMod[2] = 4;
    rarityToVariationMod[3] = 6;
    rarityToVariationMod[4] = 8;
    rarityToVariationMod[5] = 8;

    rarityColors[0] = [107, 125, 125];
    rarityColors[1] = [79, 178, 134];
    rarityColors[2] = [37, 110, 255];
    rarityColors[3] = [255, 230, 109];
    rarityColors[4] = [233, 128, 252];
    rarityColors[5] = [135, 245, 251];

    //GUARD

    //shirt
  armor[0] = [
   0x244a40000249240092244a52409249249016a6db568140000028,
   0x036db60000492480000249240000244a400002492400
    ];
    armorNames[0] = 0x0491d11980000000;
    
    //helmet
    armor[1] = [
   0x02209050001344a68002a44a54016d693b68168000168a00000005,
   0x020000100022000500022120500022090500
    ];
    armorNames[1] = 0x053916c24c000000;

    //buckler
    armor[2] = [
   0x6924498930d245249801a5124c002b49274002d693b400000d8000,
   0xd800002d693b4002b49274001a4a24c00d248a49869424a493
    ];
    armorNames[2] = 0x060d04a592200000;
    
    //robes
    armor[3] = [
   0x04920006d844a0dbb128944a516444a92802c492940000b6d000,
   0xb6db6db6d6db6db6db1125224a002289450000449280000044a000
    ];
    armorNames[3] = 0x048b824900000000;

    //straps
    armor[4] = [
   0x0a200000050040000124924000036db000000000000000000000,
   0x2492000004005000000828000000040000
    ];
    armorNames[4] = 0x0594e207c8000000;

    //chainmail
    armor[5] = [
   0x1694515681222da3200514d9450a8a28a28d151401468028000140,
   0x492480000228a20000145140000228a20000145140000228a200
    ];
    armorNames[5] = 0x0811c086b0085800;

    //kiteshield
    armor[6] = [
   0xb2244a500b6c69350002c89294002db14000000b14000000164000,
   0x0249200059124a00044926a09226934a089244a4a0
    ];
    armorNames[6] = 0x095226491d0458c0;

    //platebody
    armor[7] = [
   0x9126db4a48934926946da0004db6e800015b74000002ba00000005,
   0x56dba0000349260000244a40000244a40000244a4006d244a49b
    ];
    armorNames[7] = 0x087ac13205c3c000;
    

//DESTRUCTION

    //dagger
    weapons[0] = [
   0x0880000000400000002000000010000000080000000000000000,
   0x0280c0000158600000001000000120740000110a00
    ];
    weaponNames[0] = 0x05180c6244000000;
    //bow
    weapons[1] = [
   0xa10008000a80040000a80200000881000000808000000840000000,
   0x2db240000024810000d000800068004000340020001a001000
    ];
     weaponNames[1] = 0x020bac0000000000;
    //staff
    weapons[2] = [
   0x0180800000c0400000b5c0000006dd00000065d0000006dd000000,
   0x40000000100000000800000004000000020000c0010000
    ];
     weaponNames[2] = 0x0494c05280000000;
    //scimitar
    weapons[3] = [
   0x024890000122480000112a000000950000000a80000000a8000000,
   0x1490000036d900000301d0000030c0000022600000112000
    ];
    weaponNames[3] = 0x079090c44c110000;
    //katana
    weapons[4] = [
   0x0880000004400000022000000110000000080000000400000000,
   0x01b0001680d80001492c000000a200000012340000110b40
    ];
    weaponNames[4] = 0x0550260680000000;
    //bowstaff
    weapons[5] = [
   0x540680000aa44c0000009818000109803000120540600000a92800,
   0x90000000090000000808c0000400418002000403010000
    ];
    weaponNames[5] = 0x070bad2980a50000;
    //axe
    weapons[6] = [
   0x6dd080000692400000689540000a894c0000b524c000016b6c0000,
   0x024000000024000000080000000400000004000000020000
    ];
    weaponNames[6] = 0x0205c80000000000;
    //muramasa
    weapons[7] = [
   0x069042c0034c002d01b6000000db0000000d8000000600000000,
   0x0b00004000b6002000000248000008228000001148000008a020
    ];
    weaponNames[7] = 0x0765220602400000;
    
    

  //CELERITY

    //boots
    celerity[0] = [
   0x0d292500004936800004920000016da00000000000000000000000,
   0xdb6db6c00d24925000d2914800
    ];
    celerityNames[0] = 0x040b9d3900000000;
    //pants
    celerity[1] = [
   0x0224025000224025000226db50002364b70001b64b6c002db6db40,
   0x01b6036c0024804900022402500022402500022402500022402500
    ];
    celerityNames[1] = 0x04781b3900000000;
    //cape
    celerity[2] = [
   0x550c5400054a2540000a92a000000db000000600600000000000,
   0x50001400056db7400054925400054925400054925400054a2540
    ];
    celerityNames[2] = 0x03101e4000000000;
    //specs
    celerity[3] = [
   0x0806e84dd800004000000000000000000000000000000000000000,
   0x056c0ad800325c64b01325864b
    ];
    celerityNames[3] = 0x0493c82900000000;
    //crystal
    celerity[4] = [
   0x14289942800249940002a6db400003924600000894140000090000,
   0x01200000006db1400032d26000022d44000022ca42802a459405
    ];
    celerityNames[4] = 0x0614712981600000;
    //hat
    celerity[5] = [
   0x09244a48000344aa0001b4921400d80000006c0000000600000000,
   0x0124924920
    ];
    celerityNames[5] = 0x0238260000000000;
    //sandals
    celerity[6] = [
   0x0d92480006d92480006e8000000740000000a00000000000000000,
   0x492492402c01041015c0104100dc010400
    ];
    celerityNames[6] = 0x06901a302e400000;
    //wings
    celerity[7] = [
   0x012400490011482450012482490012800890004000100000000000,
   0x280000280180000180130000d0012000090012400490
    ];
    celerityNames[7] = 0x04b21a6900000000;
 
    //VIGOR

    //ring
    health[0] = [
   0x3000600000894000000a4d000000048000000000000000000000,
   0x0894000003000600002000400002000400
    ];
    healthNames[0] = 0x038a1a6000000000;
    //trinket
    health[1] = [
   0x48000000803600000003600000000140000000000000000000,
   0x028000000002400000002404000000048000
    ];
    healthNames[1] = 0x069c50d512600000;
    //amulet
    health[2] = [
   0x2010000012080000080080000080480000012000000000000000,
   0x1680000237280000192c00000192c0000493700002410000
    ];
    healthNames[2] = 0x050328b24c000000;
    //gauntlets
    health[3] = [
   0x1094042500898022600a24028900db6036d8000000000000000000,
   0x16da05b680db6036d8a92402495a94402515
    ];
    healthNames[3] = 0x083028d9ac939000;
    //orb
    health[4] = [
   0x02a45454001d88aa000c0a950c0018168600000000000000000000,
   0x03000000000768000003a95600005454a1802a88a540
    ];
    healthNames[4] = 0x0274420000000000;
    //crown
    health[5] = [
   0x09464b89009a4da4d0115090aa0068000148000000000000000000,
   0x024924000124da48009264b490
    ];
    healthNames[5] = 0x04145d6680000000;
    //heart
    health[6] = [
   0x71244a4a37124924a3ae252251d15c8dc8e802b76b740000000000,
   0x0168000000add000005723a0002b89474001c4928c00e244a518
    ];
    healthNames[6] = 0x0439011980000000;
    //artifact
    health[7] = [
   0x0d244a498600492003a09090245900201024928048164000000000,
   0x0b250000001200000002010000010902000c049201861244a483
    ];
    healthNames[7] = 0x0704668280530000;

  assets[0] = weapons;
  assets[1] = armor;
  assets[2] = health;
  assets[3] = celerity;

  gearNames[0] = weaponNames;
  gearNames[1] = armorNames;
  gearNames[2] = healthNames;
  gearNames[3] = celerityNames;

  }

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

  function getRarity(uint256 mgear) public pure returns (uint8) {
    return uint8(mgear & 0x7) % 6;
  }

  function getBonusMod(uint256 mgear) public pure returns (uint8) {
    if(getRarity(mgear) > 3) return 0;
    if(uint8((mgear >> 17) & 0x3) == 0) {
      return 2;
    }
    return 0;
  }

  function getVariation(uint256 mgear) public view returns (uint8) {
    return uint8((mgear >> 3) & 0x7) % (rarityToVariationMod[getRarity(mgear)] + getBonusMod(mgear));
  }

 function getGearType(uint256 mgear) public pure returns (uint8) {
    return uint8((mgear >> 19) & 0x3);
  }

  function getGearName(uint256 mgear) public view returns (uint64) {
    return gearNames[getGearType(mgear)][getVariation(mgear)];
  }

  function getAugmented(uint256 mgear) public pure returns (bool) {
    return (mgear >> 6 & 0x7) == 0;
  }

  function render(uint256 mgear) external view returns (string memory svg) {
    svg = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 12 12">'));
    uint8[15] memory colors;
    uint8 colorMask = 0xFF;
    uint8 rarity = getRarity(mgear);
    uint8 gearType = getGearType(mgear);
    uint8 variation = getVariation(mgear);
    bool isAugmented = getAugmented(mgear);

    colors[0] = rarityColors[rarity][0];
    colors[1] = rarityColors[rarity][1];
    colors[2] = rarityColors[rarity][2];

    colors[3] = (uint8((mgear >> 36) & colorMask));
    colors[4] = (uint8((mgear >> 44) & colorMask));
    colors[5] = (uint8((mgear >> 52) & colorMask));

    colors[6] = (uint8((mgear >> 60) & colorMask));
    colors[7] = (uint8((mgear >> 68) & colorMask));
    colors[8] = (uint8((mgear >> 76) & colorMask));

    colors[9] = (uint8((mgear >> 84) & colorMask));
    colors[10] = (uint8((mgear >> 92) & colorMask));
    colors[11] = (uint8((mgear >> 100) & colorMask));

    colors[12] = (uint8((mgear >> 108) & colorMask));
    colors[13] = (uint8((mgear >> 116) & colorMask));
    colors[14] = (uint8((mgear >> 124) & colorMask));

    if(rarity < 4) {
      colors[9] = colors[3];
      colors[10] = colors[4];
      colors[11] = colors[5];
    }
    if(rarity < 2) {
      colors[6] = colors[3];
      colors[7] = colors[4];
      colors[8] = colors[5];
    }

    for (uint256 y = 0; y < 12; y++) {
      for (uint256 x = 0; x < 12; x++) {
        uint256 p = (y * 12 + x);
        uint8 layer = uint8(p / 72);
        uint8 pixel = uint8(assets[gearType][variation][layer] >> ((p % 72) * 3) & 0x7);
        if (uint8(pixel) > 0) {
          if(!(!isAugmented && pixel == 5)) {
            uint8 r = colors[(pixel - 1) * 3];
            uint8 g = colors[(pixel - 1) * 3 + 1];
            uint8 b = colors[(pixel - 1) * 3 + 2];

            svg = string(
              abi.encodePacked(
                svg,
                '<rect x="',
                toString(x),
                '" y="',
                toString(y),
                '" width="1" height="1" shape-rendering="crispEdges" fill="rgb(',
                toString(r),
                ",",
                toString(g),
                ",",
                toString(b),
                ')" />'
              )
            );
          }
        }
      }
    }

    svg = string(abi.encodePacked(svg, "</svg>"));
  }
}