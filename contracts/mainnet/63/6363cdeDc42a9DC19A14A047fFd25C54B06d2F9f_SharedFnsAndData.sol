//SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

// Mainnet 1

contract SharedFnsAndData {

  // Divide by 10000 and use as an interpolation factor
  uint8 internal constant INTERP_LEN = 6;
  uint16[INTERP_LEN] internal interpolationCurve10k = [0,0,5000,10000,10000,0];

  uint16[32] internal durations = [31,53,73,103,137,167,197,233,37,59,79,107,139,173,199,239,41,61,83,109,149,179,211,241,43,67,89,113,151,181,223,253];

  // Control colour randomisations (4 colours are used throughout)
  uint8[4] internal sectionColStartBits = [24, 30, 36, 42]; // 4 sections, each uses 3 bits for colour, 3 bits for duration

  // Control colours that are used in the NFT
  uint8[32] internal colsR = [0,26,80,0,0,40,0,40,76,102,230,0,0,170,0,85,153,179,230,0,230,160,80,240,230,255,255,196,196,255,128,255];
  uint8[32] internal colsG = [0,26,0,70,0,35,35,0,76,102,0,200,0,80,160,0,153,179,200,200,0,230,150,75,230,255,196,255,196,255,255,128];
  uint8[32] internal colsB = [0,26,0,0,90,0,45,45,76,102,0,0,255,0,90,180,153,179,0,255,255,90,255,170,230,255,196,196,255,128,255,255];

  bytes16 internal constant ALPHABET = '0123456789abcdef';
  string internal constant linesPath = ' d="M 11 1145 L 11 855 M 32 1251 L 32 749 M 53 1322 L 53 678 M 74 1379 L 74 621 M 96 1427 L 96 573 M 117 1469 L 117 531 M 138 1507 L 138 493 M 160 1542 L 160 458 M 181 1574 L 181 426 M 202 1603 L 202 397 M 223 1630 L 223 370 M 245 1655 L 245 345 M 266 1679 L 266 321 M 287 1701 L 287 299 M 309 1722 L 309 278 M 330 1742 L 330 258 M 351 1761 L 351 239 M 372 1778 L 372 222 M 394 1795 L 394 205 M 415 1811 L 415 189 M 436 1826 L 436 174 M 457 1840 L 457 160 M 479 1853 L 479 147 M 500 1866 L 500 134 M 521 1878 L 521 122 M 543 1889 L 543 111 M 564 1900 L 564 100 M 585 1910 L 585 90 M 606 1919 L 606 81 M 628 1928 L 628 72 M 649 1936 L 649 64 M 670 1944 L 670 56 M 691 1951 L 691 49 M 713 1958 L 713 42 M 734 1964 L 734 36 M 755 1970 L 755 30 M 777 1975 L 777 25 M 798 1979 L 798 21 M 819 1984 L 819 16 M 840 1987 L 840 13 M 862 1990 L 862 10 M 883 1993 L 883 7 M 904 1995 L 904 5 M 926 1997 L 926 3 M 947 1999 L 947 1 M 968 1999 L 968 1 M 989 2000 L 989 0 M 1011 2000 L 1011 0 M 1032 1999 L 1032 1 M 1053 1999 L 1053 1 M 1074 1997 L 1074 3 M 1096 1995 L 1096 5 M 1117 1993 L 1117 7 M 1138 1990 L 1138 10 M 1160 1987 L 1160 13 M 1181 1984 L 1181 16 M 1202 1979 L 1202 21 M 1223 1975 L 1223 25 M 1245 1970 L 1245 30 M 1266 1964 L 1266 36 M 1287 1958 L 1287 42 M 1309 1951 L 1309 49 M 1330 1944 L 1330 56 M 1351 1936 L 1351 64 M 1372 1928 L 1372 72 M 1394 1919 L 1394 81 M 1415 1910 L 1415 90 M 1436 1900 L 1436 100 M 1457 1889 L 1457 111 M 1479 1878 L 1479 122 M 1500 1866 L 1500 134 M 1521 1853 L 1521 147 M 1543 1840 L 1543 160 M 1564 1826 L 1564 174 M 1585 1811 L 1585 189 M 1606 1795 L 1606 205 M 1628 1778 L 1628 222 M 1649 1761 L 1649 239 M 1670 1742 L 1670 258 M 1691 1722 L 1691 278 M 1713 1701 L 1713 299 M 1734 1679 L 1734 321 M 1755 1655 L 1755 345 M 1777 1630 L 1777 370 M 1798 1603 L 1798 397 M 1819 1574 L 1819 426 M 1840 1542 L 1840 458 M 1862 1507 L 1862 493 M 1883 1469 L 1883 531 M 1904 1427 L 1904 573 M 1926 1379 L 1926 621 M 1947 1322 L 1947 678 M 1968 1251 L 1968 749 M 1989 1145 L 1989 855 "';
  uint8 internal constant CORE_DEV_ARRAY_LEN = 120;
  string[CORE_DEV_ARRAY_LEN] internal coreDevNames = ['Vitalik Buterin','0xSplits','Artem Vorotnikov','Parithosh Jayanthi','Rafael Matias','Guillaume Ballet','Jared Wasinger','Marius van der Wijden','Matt Garnett','Peter Szilagyi','Andrei Maiboroda','Jose Hugo de la cruz Romero','Paweł Bylica','Andrew Day','Gabriel','Holger Drewes','Jochem','Scotty Poi','Jacob Kaufmann','Jason Carver','Mike Ferris','Ognyan Genev','Piper Merriam','Danny Ryan','Tim Beiko','Trenton Van Epps','Aditya Asgaonkar','Alex Stokes','Ansgar Dietrichs','Antonio Sanso','Carl Beekhuizen','Dankrad Feist','Dmitry Khovratovich','Francesco d’Amato','George Kadianakis','Hsiao Wei Wang','Justin Drake','Mark Simkin','Proto','Zhenfei Zhang','Anders','Barnabé Monnot','Caspar Schwarz-Schilling','David Theodore','Fredrik Svantes','Justin Traglia','Tyler Holmes','Yoav Weiss','Alex Beregszaszi','Harikrishnan Mulackal','Kaan Uzdogan','Kamil Sliwak','Leonardo de Sa Alt','Mario Vega','Andrey Ashikhmin','Enrique Avila Asapche','Giulio Rebuffo','Michelangelo Riccobene','Tullio Canepa','Pooja Ranjan','Daniel Lehrner','Danno Ferrin','Gary Schulte','Jiri Peinlich','Justin Florentine','Karim Taam','Guru','Jim McDonald','Peter Davies','Adrian Manning','Diva Martínez','Mac Ladson','Mark Mackey','Mehdi Zerouali','Michael Sproul','Paul Hauner','Pawan Dhananjay Ravi','Sean Anderson','Cayman Nava','Dadepo Aderemi','dapplion','Gajinder Singh','Phil Ngo','Tuyen Nguyen','Daniel Caleda','Jorge Mederos','Łukasz Rozmej','Marcin Sobczak','Marek Moraczyński','Mateusz Jędrzejewski','Tanishq','Tomasz Stanzeck','James He','Kasey Kirkham','Nishant Das','potuz','Preston Van Loon','Radosław Kapka','Raul Jordan','Taran Singh','Terence Tsao','Sam Wilson','Dustin Brody','Etan Kissling','Eugene Kabanov','Jacek Sieka','Jordan Hrycaj','Kim De Mey','Konrad Staniec','Mamy Ratsimbazafy','Zahary Karadzhov','Adrian Sutton','Ben Edgington','Courtney Hunter','Dmitry Shmatko','Enrico Del Fante','Paul Harris','Alex Vlasov','Anton Nashatyrev','Mikhail Kalinin'];
  uint8[CORE_DEV_ARRAY_LEN] internal coreDevTeamIndices = [0,1,2,3,3,4,4,4,4,4,5,5,5,6,6,6,6,6,7,7,7,7,7,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,9,9,10,10,10,11,11,11,11,11,12,12,12,12,12,13,14,14,14,14,14,15,16,16,16,16,16,16,0,0,0,17,17,17,17,17,17,17,17,17,18,18,18,18,18,18,19,19,19,19,19,19,19,19,20,20,20,20,20,20,20,20,20,21,22,22,22,22,22,22,22,22,22,23,23,23,23,23,23,24,24,24];

  function getLinesPath() public pure returns (string memory) {
    return linesPath;
  }

  function getCoreDevArrayLen() public pure returns (uint8) {
    return CORE_DEV_ARRAY_LEN;
  }

  function getCoreDevName(uint8 idx) public view returns (string memory) {
    return coreDevNames[idx % CORE_DEV_ARRAY_LEN];
  }

  function getCoreDevTeamIndex(uint8 idx) public view returns (uint8) {
    return coreDevTeamIndices[idx % CORE_DEV_ARRAY_LEN];
  }

  function toHexString(uint256 value, uint256 length) public pure returns (string memory) {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = '0';
    buffer[1] = 'x';
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = ALPHABET[value & 0xf];
      value >>= 4;
    }
    return string(buffer);
  }

  function uint2str(uint _i) public pure returns (string memory _uintAsString) {
    if (_i == 0) {
        return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
        k = k-1;
        uint8 temp = (48 + uint8(_i - _i / 10 * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
    }
    return string(bstr);
  }

  function int2str(int _i) public pure returns (string memory _uintAsString) {
    if (_i < 0) {
      return string(abi.encodePacked('-', uint2str(uint(0 - _i))));
    } else {
      return uint2str(uint(_i));
    }
  }

  // Get up to 8 bits from the 256-bit pseudorandom number gen (= generator[id])
  function getUint8(uint256 gen, uint8 startBit, uint8 bits) public pure returns (uint8) {
    uint8 gen8bits = uint8(gen >> startBit);
    if (bits >= 8) return gen8bits;
    return gen8bits % 2 ** bits;
  }

  function isMonochrome(uint256 gen) public pure returns (bool) {
    return getUint8(gen, 200, 4) == 0;
  }

  function getRGBA(uint256 gen, uint8 arraySection, string memory alpha) public view returns (string memory) {
    // Array section values are 0, 1, 2 or 3 (0 is darkest, 3 is lightest)
    // These sections give colours 0-7, 8-15, 16-23, 24-31
    uint8 bits = isMonochrome(gen) ? 1 : 3;
    uint8 idx = 8 * arraySection + getUint8(gen, sectionColStartBits[arraySection], bits); // First 2 out of 8 colours are monochrome, so 1 bit is monochrome, 3 bits is colour
    return string(abi.encodePacked(
      'rgba(',
      uint2str(colsR[idx]),
      ',',
      uint2str(colsG[idx]),
      ',',
      uint2str(colsB[idx]),
      ',',
      alpha,
      ')'
    ));
  }

  function getDurText(uint256 gen, uint8 arraySection) public view returns (string memory) {
    uint8 idx = 8 * arraySection + getUint8(gen, sectionColStartBits[arraySection] + 3, 3); // 3 bits = 8 duration choices
    return string(abi.encodePacked(
      ' dur="',
      uint2str(3 * durations[idx]), // It was rotating too fast! Extra factor here
      's"'
    ));
  }

  // Typical output: ' values="  0 200 200;  360 200 200;"' (with a lot more than 2 entries)
  // In this example output, prefix = ' ' and suffix = ' 200 200'
  // Note - this function only does whole-numbered interpolation
  function calcValues(int64 startVal, int64 endVal, string memory prefix, string memory suffix) public view returns (string memory) {
    string memory result = ' values="';
    for (uint8 idx = 0; idx < INTERP_LEN; idx++) {
      int64 a = int64(interpolationCurve10k[idx]);
      result = string(abi.encodePacked(
        result,
        prefix,
        int2str(((-a + 10000) * startVal + a * endVal) / 10000),
        suffix,
        idx == INTERP_LEN - 1 ? '"' : ';'
      ));      
    }
    return result;
  }
}