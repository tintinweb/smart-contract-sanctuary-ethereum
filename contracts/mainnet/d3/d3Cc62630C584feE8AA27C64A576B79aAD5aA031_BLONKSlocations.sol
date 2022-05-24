// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

/// @title BLONKS Locations Contract
/// @author Matto
/// @notice This contract is determines where (almost) everything is placed in the final image.
/// @dev Locations are saved in a single array so it's easy to pass values between functions.
/// @custom:security-contact [email protected]
contract BLONKSlocations {

  function eM(uint256 _ent, uint256 _mod)
    internal
    pure
    returns (uint16) 
  {
    return uint16(_ent % _mod);
  }

  function p(uint16 _val, uint256 _ent, uint16 _delta)
    internal
    pure
    returns (uint16)
  {
    uint16 t = uint16(_ent % 3);
    if (t == 0) {
      t = _val - _delta;
    } else {
      t -= 1;
      t = _val + t * _delta;
    }
    return t;
  }


  function calculateLocatsArray(uint256 eO, uint256 eT, uint8[11] memory tA)
    external
    pure
    returns (uint16[110] memory)
  {
    uint16[110] memory loc;

    // Neck
    loc[1] = 250 + (eM(eO,10) * 10);
    eO /= 10;
    loc[0] = (1000 - loc[1]) / 2;

    // Head
    loc[4] = 480 + (eM(eO,10) * 10); 
    eO /= 10;
    loc[5] = 500 + (eM(eO,10) * 10); 
    eO /= 10;
    loc[2] = (1000 - loc[4]) / 2; 
    loc[3] = (1000 - loc[5]) / 2; 

    // Eye Colors
    eO /= 10;

    // Right Eye
    loc[8] = loc[4] / 6 + eM(eO,10) * 5;
    eO /= 10;
    loc[9] = loc[5] / 6 + eM(eO,10) * 5;
    eO /= 10;
    loc[6] = loc[2] - 10 + (loc[4] / 2 - loc[8]) - eM(eO,10) * 4;
    eO /= 10;
    loc[7] = loc[3] + (loc[5] / 2 - loc[9]) + eM(eO,10) * 2;
    eO /= 10;

    // Left Eye
    loc[12] = loc[4] / 6 + eM(eO,10) * 5;
    eO /= 10;
    loc[13] = loc[5] / 6 + eM(eO,10) * 5;
    eO /= 10;
    loc[10] = loc[2] + 10 + loc[4] - (loc[4] / 2 - loc[12]) - loc[12] + eM(eO,10) * 4;
    eO /= 10;
    loc[11] = loc[3] + (loc[5] / 2 - loc[13]) + eM(eO,10) * 2;
    eO /= 10;

    // Right Pupil
    loc[18] = loc[8] / 2 - eM(eT,10) * 2;
    eT /= 10;
    loc[19] = loc[9] / 2 - eM(eT,10) * 2;
    eT /= 10;
    loc[14] = eM(eT,3);
    eT /= 10;
    loc[15] = eM(eT,3);
    eT /= 10;
    if (loc[14] == 0) {
      loc[16] = loc[6];
    } else if (loc[14] == 1) {
      loc[16] = p(loc[6] + loc[8] / 2 - loc[18] / 2, eT, 10);
    } else {
      loc[16] = loc[6] + loc[8] - loc[18];
    }
    eT /= 10;
    if (loc[15] == 0) {
      loc[17] = loc[7];
    } else if (loc[15] == 1) {
      loc[17] = p(loc[7] + loc[9] / 2 - loc[19] / 2, eT, 10);
    } else {
      loc[17] = loc[7] + loc[9] - loc[19];
    }
    eT /= 10;

    // Left Pupil
    loc[22] = loc[12] / 2 - eM(eT,10) * 2;
    eT /= 10;
    loc[23] = loc[13] / 2 - eM(eT,10) * 2;
    eT /= 10;
    if (loc[14] == 0) {
      loc[20] = loc[10];
    } else if (loc[14] == 1) {
      loc[20] = p(loc[10] + loc[12] / 2 - loc[22] / 2, eT, 10);
    } else {
      loc[20] = loc[10] + loc[12] - loc[22];
    }
    eT /= 10;
    if (loc[15] == 0) {
      loc[21] = loc[11];
    } else if (loc[15] == 1) {
      loc[21] = p(loc[11] + loc[13] / 2 - loc[23] / 2, eT, 10);
    } else {
      loc[21] = loc[11] + loc[13] - loc[23];
    }

    // Nose
    eO /= 10;
    loc[26] = (loc[10] - (loc[6] + loc[8])) / 2;
    loc[27] = loc[5] / 8 + eM(eO,10) * 4;
    eO /= 10;
    loc[24] = p(loc[2] + (loc[4] - loc[26]) / 2, eO, 5);
    eO /= 10;
    loc[25] = p(loc[3] + (loc[5] - loc[27]) / 2 + loc[27] / 2, eO, 3);

    // Ears
    eO /= 10;
    loc[31] = loc[4] / 12 + eM(eO,10) * 2;
    eO /= 10;
    loc[32] = loc[5] / 4 + eM(eO,10) * 4;
    eO /= 10;
    loc[28] = loc[2] - loc[31];
    loc[29] = loc[2] + loc[4];
    loc[30] = loc[3] + loc[32] + 30 + eM(eO,10) * 3;
    eO /= 10;

    // Right Eyebrow
    loc[39] = loc[8] + eM(eO,7) * 10;
    eO /= 10;
    loc[40] = (2 + eM(eO,5)) * 5;
    eO /= 10;
    loc[37] = loc[6] + 6 - eM(eO,10) * 5;
    eO /= 10;
    loc[38] = loc[7] - 6 - loc[40] - eM(eO,10) * 4;
    eO /= 10;

    // Left Eyebrow
    loc[43] = loc[12] + eM(eO,7) * 10;
    eO /= 10;
    loc[44] = (2 + eM(eO,5)) * 5;
    eO /= 10;
    loc[41] = loc[10] + 6 - eM(eO,10) * 5;
    eO /= 10;
    loc[42] = loc[11] - 6 - loc[44] - eM(eO,10) * 4;

    // Mouth
    eT /= 10;
    loc[35] = loc[4] - 150 - eM(eT,10) * 27;
    eT /= 10;
    loc[36] = loc[5] / 12 + eM(eT,10) * 5;
    eT /= 10;
    loc[33] = p(loc[2] + (loc[4] - loc[35]) / 2, eT, 20);
    eT /= 10;
    loc[34] = p(loc[3] + loc[27] + loc[36] + (loc[5] - loc[36]) / 2, eT, 3);
    eT /= 10;

    // Mole
    if (eM(eO,10) < 2) { 
      eO /= 10;
      if (eM(eO,10) < 5) {
        loc[45] = loc[2] + loc[27] + loc[27] / 2 - eM(eO,10) * 4;
      } else {
        loc[45] = loc[2] + loc[4] - loc[27] - loc[27] / 2  + eM(eO,10) * 4;
      }
      eO /= 10;
      loc[106] = loc[34] - 2 * (loc[5] / 25) - eM(eO,10) * 3;
      loc[107] = loc[4] / 25;
      loc[108] = loc[5] / 25;
    } 
    eO /= 10;

    // Lens pt 1
    loc[13] >= loc[9] ? loc[46] = loc[13] + 40 : loc[46] = loc[9] + 40;
    loc[12] > loc[8] ? loc[47] = loc[12] + 30: loc[47] = loc[8] + 30;

    // Teeth 
    if (tA[2] == 1) {
      loc[50] = loc[33] + loc[35] / 16;
      loc[51] = loc[34] + 3;
      loc[52] = loc[35] - loc[35] / 8;
      loc[53] = loc[36] - 6;
    } else if (tA[2] == 2) {
      loc[50] = loc[33] + (loc[35] / 3);
      loc[51] = loc[34] + 3;
      loc[52] = loc[35] / 3;
      loc[53] = 2 * (loc[36] - 6) / 3;
    } else if (tA[2] == 3) {
      loc[50] = loc[33] + loc[35] / 16;
      loc[51] = loc[34] + 3 + loc[36] / 4;
      loc[52] = loc[35] - loc[35] / 8;
      loc[53] = loc[36] -6 - loc[36] / 4;
      loc[93] = loc[33] + loc[35] / 16 + loc[35] / 8;
      loc[94] = loc[34] + 5;
      loc[95] = 5 * (loc[35] / 8);
      loc[96] = loc[36] - 8;
    }

    // Extra Detail
    if (tA[3] == 1) {
      loc[56] = loc[4] / 30;
      loc[57] = 3 * loc[56];
      loc[54] = loc[33] + loc[35] - loc[56] - 3;
      loc[55] = loc[34] + loc[36] - 4;  
      loc[58] = loc[54] - loc[56];
      loc[60] = 2 * loc[56];
      loc[61] = (3 * loc[60]) / 4;
      loc[59] = loc[55];
    } else if (tA[3] == 2) {
      loc[56] = loc[26] / 2;
      loc[57] = loc[56];
      loc[54] = loc[24];
      loc[55] = loc[25] + loc[27] + 3;
      loc[59] = loc[55] + loc[57] - 2; 
      loc[60] = loc[56] - loc[56] / 5;
      loc[61] = loc[57] + loc[57] / 4;
      loc[58] = loc[54];     
    } else if (tA[3] == 3) {
      loc[56] = loc[4] / 30;
      loc[57] = loc[56] + loc[56] / 2;
      loc[54] = loc[2] + loc[4] - (loc[2] + loc[4] - (loc[10] + loc[12])) / 2;
      loc[55] = loc[11] - loc[5] / 10;
      loc[59] = loc[55] + loc[57] - 1; 
      loc[60] = 2 * loc[56];
      loc[61] = loc[57] + loc[57] / 2;
      loc[58] = loc[54] - loc[60] / 4;
    } else if (tA[3] == 4) {
      loc[56] = loc[4] / 40;
      loc[57] = loc[56] + loc[56] / 2;
      loc[54] = loc[6] - loc[56];
      loc[55] = loc[7] + loc[9] + 8;
      loc[59] = loc[55] + loc[57]; 
      loc[58] = loc[54] - loc[56] / 4;
      loc[60] = loc[56] + loc[56] / 2;
      loc[61] = loc[60];
    }

    // Glasses
    if (tA[4] != 0) {
      loc[62] = loc[24] - 10;
      loc[63] = loc[25] - 23;
      loc[64] = loc[26] + 20;
      loc[65] = 20;
      loc[66] = loc[24] - 10 - loc[47];
      loc[67] = loc[25] - loc[46] + 27;
      loc[68] = loc[24] + loc[26] + 10;
      loc[69] = loc[28] - 3;
      loc[70] = loc[30] - 15;
      loc[71] = loc[24] - loc[47] - loc[28];
      loc[72] = loc[24] + loc[26] + 3 + loc[47];
      loc[73] = loc[30] - 15;
      loc[74] = loc[29]  + loc[31] - loc[24] - loc[26] - loc[47];
    }

    // Hair
    if (tA[5] == 1) {
      loc[78] = (loc[30] - loc[3]) - 60;
      loc[75] = loc[2] - 30;
      loc[76] = loc[3] - loc[78] / 2 + 10;
      loc[77] = loc[4] + 60;
    } else if (tA[5] == 2) {
      loc[78] = (loc[30] - loc[3]) / 2;
      loc[75] = loc[2] + loc[31] / 2;
      loc[76] = loc[3] - loc[78];
      loc[77] = loc[4] - loc[31];
    } else if (tA[5] == 3) {
      loc[78] = (loc[30] - loc[3]) / 4;
      loc[75] = loc[2];
      loc[76] = loc[3] - loc[78];
      loc[77] = loc[4];
      loc[82] = loc[78] * 2;
      loc[79] = loc[2] + loc[4] / 4;
      loc[80] = loc[3] - loc[82];
      loc[81] = loc[4] / 2;
    } else if (tA[5] == 4) {
      loc[75] = loc[2] + (5 * loc[4]) / 12;
      loc[76] = loc[3] - loc[32];
      loc[77] = loc[4] / 6;
      loc[78] = loc[32];
    }
    if (tA[6] > 0) {
      loc[89] = loc[4] + 40;
      loc[90] = (loc[30] - loc[3]) / 3;
      loc[87] = loc[2] - 20;
      loc[88] = loc[3] + loc[90] / 2;
    } 
    if (tA[6] == 2) {
      loc[91] = loc[88] + loc[90] / 5;
      loc[92] = (3 * loc[90]) / 5;
    }
    if (tA[5] == 3) {
      loc[83] = loc[2];
      loc[84] = loc[3] - 2;
      loc[85] = loc[31];
      loc[86] = (3 * loc[5]) / 4 - eM(eT,10) * 7;
    }

    // Ear rings pt 1
    loc[48] = 15;
    loc[49] = loc[32] + loc[30] - 35;

    // Other
    if (tA[9] == 0) {
      loc[98] = loc[0] - 15;
      loc[99] = 950;
      loc[100] = loc[1] + 30;
      loc[101] = 60; 
    } else if (tA[9] == 1) {
      loc[98] = loc[2] - loc[27] / 2;
      loc[99] = loc[3] + loc[5];
      loc[100] = loc[4] + loc[27];
      loc[101] = loc[27];
      loc[104] = loc[27] / 2;
      loc[103] = loc[32] + loc[30] + 20;
      loc[105] = loc[3] + loc[5] - loc[103] + 10;
      loc[102] = loc[2] - loc[104];
      loc[97] = loc[2] + loc[4];
    } else if (tA[9] == 2 || tA[9] == 3) {
      loc[98] = loc[0] - 10;
      loc[99] = loc[3] + loc[5] + loc[27];
      loc[100] = loc[1] + 20;
      loc[101] = loc[27];
    } else if (tA[9] == 4) {
      loc[99] = loc[3] + loc[5] + loc[19];
      loc[98] = loc[0] - 20;
      loc[100] = loc[1] + 40;
      loc[101] = 1000 - loc[99];
    } else if (tA[9] == 5) {
      loc[98] = loc[0] - 60;
      loc[99] = 1000 - loc[27];
      loc[100] = loc[1] + 120;
      loc[101] = loc[27];
      loc[102] = loc[98] + 30;
      loc[104] = loc[100] - 60;
    }
    return loc;
  }
}