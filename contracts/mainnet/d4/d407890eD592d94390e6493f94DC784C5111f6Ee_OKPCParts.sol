/*
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░░░███░░████████░░███░░████████░░███░░░░░███░░███████░░███░░████████░░███░░░░░
  ░░░░░███░░░░░░░███░░███░░░░░░░███░░███░░░░░███░░███░░░░░░███░░███░░░░░░░███░░░░░
  ░░░░░████████░░███░░████████░░███░░███████████░░███░░███████░░███░░████████░░░░░
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ████████████████████████████████████████████████████████████████████████████████
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░░░░░░░░                                                            ░░░░░░░░░░
  ░░░░░███░░          ██████████                    ██████████          ░░░░░███░░
  ░░░█████░░        ██          ███               ██          ███       ░░░██░░░░░
  ░░░░░░░░░░     ███  █████        ██          ███               ██     ░░░░░░░░░░
  ░░░░░░░░░░     ███  ███          ██          ███       █████   ██     ░░░░░░░░░░
  ░░░░░███░░     ███  █████        ██   █████  ███          ██   ██     ░░░░░███░░
  ░░░█████░░     ███  █████        ██          ███       █████   ██     ░░░██░░░░░
  ░░░░░░░░░░     ███               ██   █████  ███       █████   ██     ░░░░░░░░░░
  ░░░░░░░░░░        ██          ███               ██          ███       ░░░░░░░░░░
  ░░░█████░░          ██████████        █████       ██████████          ░░░░░███░░
  ░░░░░███░░                                                            ░░░██░░░░░
  ░░░░░░░░░░     █████          █████          █████          █████     ░░░░░░░░░░
  ░░░░░░░░░░     █████   █████  █████   █████     ██   █████  █████     ░░░░░░░░░░
  ░░░█████░░             █████          █████          █████            ░░░░░███░░
  ░░░░░███░░                                                            ░░░██░░░░░
  ░░░░░░░░░░                                                            ░░░░░░░░░░
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ████████████████████████████████████████████████████████████████████████████████
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░░░████████░░████████░░████████░░░░░░░░░░░░░░░██░░░██░░░██░░░██░░░██░░░██░░░░░
  ░░░░░███░░░░░░░███░░███░░████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░░░███░░░░░░░████████░░███░░███░░░░░░░░░░░░░░░██░░░██░░░██░░░██░░░██░░░██░░░░░
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import {IOKPCParts} from './interfaces/IOKPCParts.sol';
import '@0xsequence/sstore2/contracts/SSTORE2.sol';

contract OKPCParts is IOKPCParts {
  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                   CONFIG                                   */
  /* -------------------------------------------------------------------------- */
  uint256 public constant NUM_COLORS = 6;
  uint256 public constant NUM_HEADBANDS = 8;
  uint256 public constant NUM_SPEAKERS = 8;
  uint256 public constant NUM_WORDS = 128;

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                   STORAGE                                  */
  /* -------------------------------------------------------------------------- */
  Color[NUM_COLORS] public colors;
  Vector[NUM_HEADBANDS] public headbands;
  Vector[NUM_SPEAKERS] public speakers;
  bytes4[NUM_WORDS] public words;

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                               INITIALIZATION                               */
  /* -------------------------------------------------------------------------- */
  constructor() {
    _initColors();
    _initHeadbands();
    _initSpeakers();
    _initWords();
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                    PARTS                                   */
  /* -------------------------------------------------------------------------- */
  /// @notice Gets the Color by index. Accepts values between 0 and 5.
  function getColor(uint256 index) public view override returns (Color memory) {
    if (index > NUM_COLORS - 1) revert IndexOutOfBounds(index, NUM_COLORS - 1);
    return colors[index];
  }

  /// @notice Gets the Headband by index. Accepts values between 0 and 7.
  function getHeadband(uint256 index)
    public
    view
    override
    returns (Vector memory)
  {
    if (index > NUM_HEADBANDS - 1)
      revert IndexOutOfBounds(index, NUM_HEADBANDS - 1);
    return headbands[index];
  }

  /// @notice Gets the Speaker by index. Accepts values between 0 and 7.
  function getSpeaker(uint256 index)
    public
    view
    override
    returns (Vector memory)
  {
    if (index > NUM_SPEAKERS - 1)
      revert IndexOutOfBounds(index, NUM_SPEAKERS - 1);
    return speakers[index];
  }

  /// @notice Gets the Word by index. Accepts values between 0 and 127.
  function getWord(uint256 index) public view override returns (string memory) {
    if (index > NUM_WORDS - 1) revert IndexOutOfBounds(index, NUM_WORDS - 1);
    return _toString(words[index]);
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                               INITIALIZATION                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Initializes the stored Colors.
  function _initColors() internal {
    // gray
    colors[0] = Color(
      bytes6('CCCCCC'),
      bytes6('838383'),
      bytes6('4D4D4D'),
      'Gray'
    );
    // green
    colors[1] = Color(
      bytes6('54F8B5'),
      bytes6('00DC82'),
      bytes6('037245'),
      'Green'
    );
    // blue
    colors[2] = Color(
      bytes6('80B3FF'),
      bytes6('2E82FF'),
      bytes6('003D99'),
      'Blue'
    );
    // purple
    colors[3] = Color(
      bytes6('DF99FF'),
      bytes6('C13CFF'),
      bytes6('750DA5'),
      'Purple'
    );
    // yellow
    colors[4] = Color(
      bytes6('FBDA9D'),
      bytes6('F8B73E'),
      bytes6('795106'),
      'Yellow'
    );
    // pink
    colors[5] = Color(
      bytes6('FF99D8'),
      bytes6('FF44B7'),
      bytes6('99005E'),
      'Pink'
    );
  }

  /// @notice Initializes the stored Headbands.
  function _initHeadbands() internal {
    headbands[0] = Vector(
      'M2 3H1V0H2V2H4V3H2ZM3 0H5H6V3H5V1H3V0ZM11 0H9V1H11V3H12V0H11ZM14 0H13V3H14H16H17V0H16V2H14V0ZM19 0H21V1H19V3H18V0H19ZM27 0H25H24V3H25V1H27V0ZM20 3V2H22V0H23V3H22H20ZM26 2V3H28H29V0H28V2H26ZM8 3H10V2H8V0H7V3H8Z',
      'Crest'
    );
    headbands[1] = Vector(
      'M11 1H12V0H11V1ZM11 2H10V1H11V2ZM13 2H11V3H13V2ZM14 1H13V2H14V1ZM16 1V0H14V1H16ZM17 2H16V1H17V2ZM19 2V3H17V2H19ZM19 1H20V2H19V1ZM19 1V0H18V1H19ZM0 1H1V2H0V1ZM1 2H2V3H1V2ZM3 1V0H1V1H3ZM4 2V1H3V2H4ZM5 2H4V3H5V2ZM6 1H5V2H6V1ZM8 1V0H6V1H8ZM8 2H9V1H8V2ZM8 2H7V3H8V2ZM24 1H25V2H24V1ZM22 1V0H24V1H22ZM22 2H21V1H22V2ZM22 2H23V3H22V2ZM26 2V3H25V2H26ZM27 1V2H26V1H27ZM29 1H27V0H29V1ZM29 2V1H30V2H29ZM29 2V3H28V2H29Z',
      'Ornate'
    );
    headbands[2] = Vector(
      'M3 0H1V1H3V2H1V3H3V2H4V3H6V2H4V1H6V0H4V1H3V0ZM27 0H29V1H27V0ZM27 2V1H26V0H24V1H26V2H24V3H26V2H27ZM27 2H29V3H27V2ZM10 0H12V1H10V0ZM10 2V1H9V0H7V1H9V2H7V3H9V2H10ZM10 2H12V3H10V2ZM18 0H20V1H18V0ZM21 1H20V2H18V3H20V2H21V3H23V2H21V1ZM21 1V0H23V1H21ZM16 0H15V1H14V3H15V2H16V0Z',
      'Power'
    );
    headbands[3] = Vector(
      'M1 3H2H3V2H2V1H4V3H5H7H8V1H10V3H11H14V2V1H16V2V3H19H20V1H22V3H23H25H26V1H28V2H27V3H28H29V0H28H26H25V2H23V0H22H20H19V2H17V1H18V0H12V1H13V2H11V0H10H8H7V2H5V0H4H2H1V3Z',
      'Temple'
    );
    headbands[4] = Vector(
      'M2 1H1V0H2V1ZM2 2V1H3V2H2ZM2 2V3H1V2H2ZM28 1H29V0H28V1ZM28 2V1H27V2H28ZM28 2H29V3H28V2ZM4 1H5V2H4V3H5V2H6V1H5V0H4V1ZM25 1H26V0H25V1ZM25 2V1H24V2H25ZM25 2H26V3H25V2ZM7 1H8V2H7V3H8V2H9V1H8V0H7V1ZM22 1H23V0H22V1ZM22 2V1H21V2H22ZM22 2H23V3H22V2ZM10 1H11V2H10V3H11V2H12V1H11V0H10V1ZM16 1H14V0H16V1ZM16 2V1H17V2H16ZM14 2H16V3H14V2ZM14 2V1H13V2H14ZM19 1H20V0H19V1ZM19 2V1H18V2H19ZM19 2H20V3H19V2Z',
      'Wreath'
    );
    headbands[5] = Vector(
      'M1 1H10V0H1V1ZM12 1H13V2H14V3H16V2H17V1H18V0H16V1V2H14V1V0H12V1ZM11 3H1V2H11V3ZM29 1H20V0H29V1ZM19 3H29V2H19V3Z',
      'Valiant'
    );
    headbands[6] = Vector(
      'M2 1H3V2H2V1ZM2 1H1V2H2V3H3V2H4V1H3V0H2V1ZM6 1H7V2H6V1ZM6 1H5V2H6V3H7V2H8V1H7V0H6V1ZM11 1H10V0H11V1ZM11 2V1H12V2H11ZM10 2H11V3H10V2ZM10 2V1H9V2H10ZM28 1H27V0H28V1ZM28 2V1H29V2H28ZM27 2H28V3H27V2ZM27 2V1H26V2H27ZM24 1H23V0H24V1ZM24 2V1H25V2H24ZM23 2H24V3H23V2ZM23 2V1H22V2H23ZM20 1H19V0H20V1ZM20 2V1H21V2H20ZM19 2H20V3H19V2ZM19 2V1H18V2H19ZM16 2H14V1H16V2ZM16 2V3H17V2H16ZM16 1V0H17V1H16ZM14 1H13V0H14V1ZM14 2V3H13V2H14Z',
      'Tainia'
    );
    headbands[7] = Vector(
      'M10 0H14V1H13V2H17V1H16V0H20V1H18V2H19V3H11V2H12V1H10V0ZM3 2H5V3H1V2H2V1H1V0H9V1H8V2H10V3H6V2H7V1H3V2ZM25 2H27V1H23V2H24V3H20V2H22V1H21V0H29V1H28V2H29V3H25V2Z',
      'Colossus'
    );
  }

  /// @notice Initializes the stored Speakers.
  function _initSpeakers() internal {
    speakers[0] = Vector(
      'M1 1H0V2H1V3H2V2H1V1ZM1 5H0V6H1V7H2V6H1V5ZM0 9H1V10H0V9ZM1 10H2V11H1V10ZM1 13H0V14H1V15H2V14H1V13Z',
      'Piezo'
    );
    speakers[1] = Vector(
      'M1 1L1 0H0V1H1ZM1 2H2V1H1V2ZM1 2H0V3H1V2ZM1 10L1 11H0V10H1ZM1 9H2V10H1L1 9ZM1 9H0V8H1L1 9ZM1 4L1 5H0V6H1L1 7H2L2 6H1L1 5H2L2 4H1ZM1 13L1 12H2L2 13H1ZM1 14L1 13H0V14H1ZM1 14H2L2 15H1L1 14Z',
      'Ambient'
    );
    speakers[2] = Vector(
      'M0 2H1V3H2L2 1H1L1 0H0V2ZM1 5H2L2 7H1V6H0V4H1L1 5ZM2 14H1L1 15H0V13H1V12H2L2 14ZM2 10L2 8H1V9H0V11H1L1 10H2Z',
      'Hyper'
    );
    speakers[3] = Vector(
      'M1 1L1 0H0V1H1ZM1 1H2V2V3H1H0V2H1V1ZM1 5L1 4H2V5H1ZM1 5L1 6H2V7H1H0V6V5H1ZM1 13H0V12H1H2V13V14H1L1 13ZM1 14L1 15H0V14H1ZM2 9V8H1H0V9V10H1V11H2V10H1V9H2Z',
      'Crystal'
    );
    speakers[4] = Vector(
      'M2 0H1V1H0V2H1V3H2V0ZM2 5H1V4H0V7H1V6H2V5ZM2 9H1V8H0V11H1V10H2V9ZM0 13H1V12H2V15H1V14H0V13Z',
      'Taser'
    );
    speakers[5] = Vector(
      'M2 0V1V2V3H0V2H1V1V0H2ZM0 4V5V6V7H2V6H1L1 5H2V4H0ZM2 10V11H0V10H1V9H0V8H2V9V10ZM0 12V13H1V14V15H2V14L2 13V12H0Z',
      'Buster'
    );
    speakers[6] = Vector(
      'M0 0V1L2 1V0H0ZM1 3V2H2V3H1ZM2 5V4H0V5H2ZM1 11V10H2V11H1ZM2 13V12H0V13H2ZM2 15V14H1V15H2ZM2 7V6H1V7H2ZM0 8V9H2V8H0Z',
      'Tower'
    );
    speakers[7] = Vector(
      'M2 1V2V3H0V2L1 2V1H2ZM1 11V10H0V9H2L2 10V11H1ZM2 14V13H0V14H1V15H2V14ZM1 5V6H0V7H2L2 6V5H1Z',
      'Blaster'
    );
  }

  /// @notice Initializes the stored Words.
  function _initWords() internal {
    words = [
      bytes4('WAIT'),
      'OK',
      'INFO',
      'HELP',
      'WARN',
      'ERR',
      'OOF',
      'WHAT',
      'RARE',
      '200%',
      'GATO',
      'ABRA',
      'POOF',
      'FUN',
      'BYTE',
      'POLY',
      'FANG',
      'PAIN',
      'BOOT',
      'DRAW',
      'MINT',
      'WORM',
      'PUP',
      'PLUS',
      'DOC',
      'QUIT',
      'BEAT',
      'MIDI',
      'UPUP',
      'HUSH',
      'ACK',
      'MOON',
      'GHST',
      'UFO',
      'SEE',
      'MON',
      'TRIP',
      'NICE',
      'YUP',
      'EXIT',
      'CUTE',
      'OHNO',
      'GROW',
      'DEAD',
      'OPEN',
      'THEM',
      'DRIP',
      'ESC',
      '404',
      'PSA',
      'BGS',
      'BOMB',
      'NOUN',
      'SKY',
      'SK8',
      'CATS',
      'CT',
      'GAME',
      'DAO',
      'BRAP',
      'LOOK',
      'MYTH',
      'ZERO',
      'QI',
      '5000',
      'LORD',
      'DUEL',
      'SWRD',
      'MEME',
      'SAD',
      'ORB',
      'LIFE',
      'PRTY',
      'DEF',
      'AIR',
      'ISLE',
      'ROSE',
      'ANON',
      'OKOK',
      'MEOW',
      'KING',
      'WISE',
      'ROZE',
      'NOBU',
      'DAMN',
      'HUNT',
      'BETA',
      'FORT',
      'SWIM',
      'HALO',
      'UP',
      'YUM',
      'SNAP',
      'APES',
      'BIRD',
      'NOON',
      'VIBE',
      'MAKE',
      'CRWN',
      'PLAY',
      'JOY',
      'FREN',
      'DING',
      'GAZE',
      'HACK',
      'CRY',
      'SEER',
      'OWL',
      'LOUD',
      'RISE',
      'LOVE',
      'SKRT',
      'QTPI',
      'WAND',
      'REKT',
      'BEAR',
      'CODA',
      'ILY',
      'SNKE',
      'FLY',
      'ZKP',
      'LUSH',
      'SUP',
      'GOWN',
      'BAG',
      'BALM',
      'LIVE',
      'LVL'
    ];
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                   HELPERS                                  */
  /* -------------------------------------------------------------------------- */
  /// @notice Convert a bytes4 to a string.
  function _toString(bytes4 b) private pure returns (string memory) {
    uint256 numChars = 0;

    for (uint256 i; i < 4; i++) {
      if (b[i] == bytes1(0)) break;
      numChars++;
    }

    bytes memory result = new bytes(numChars);
    for (uint256 i; i < numChars; i++) result[i] = b[i];

    return string(abi.encodePacked(result));
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

interface IOKPCParts {
  // errors
  error IndexOutOfBounds(uint256 index, uint256 maxIndex);

  // structures
  struct Color {
    bytes6 light;
    bytes6 regular;
    bytes6 dark;
    string name;
  }

  struct Vector {
    string data;
    string name;
  }

  // functions
  function getColor(uint256 index) external view returns (Color memory);

  function getHeadband(uint256 index) external view returns (Vector memory);

  function getSpeaker(uint256 index) external view returns (Vector memory);

  function getWord(uint256 index) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
  error WriteError();

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
  function write(bytes memory _data) internal returns (address pointer) {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(
        hex'00',
        _data
      )
    );

    // Deploy contract using create
    assembly { pointer := create(0, add(code, 32), mload(code)) }

    // Address MUST be non-zero
    if (pointer == address(0)) revert WriteError();
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
  function read(address _pointer) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
  function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes("");

    if (_start > csize) return bytes("");
    if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end); 

    unchecked {
      uint256 reqSize = _end - _start;
      uint256 maxSize = csize - _start;

      uint256 size = maxSize < reqSize ? maxSize : reqSize;

      assembly {
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        oCode := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(oCode, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(oCode, 0x20), _start, size)
      }
    }
  }
}