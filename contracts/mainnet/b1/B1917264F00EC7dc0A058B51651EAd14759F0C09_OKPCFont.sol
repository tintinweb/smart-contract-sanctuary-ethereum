/*
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░░░█████░░░█████░░█████░░░█████░░░░░░░███░░░░░█████░░█████░░░█████░░█████░░░░░
  ░░░░░░░░░░███░░░░░░░░░░░░███░░░░░░░░░░█████░░░░░░░░░░██░░░░░░░░░░░░░██░░░░░░░░░░
  ░░░░░█████░░░█████░░█████░░░█████░░░░░██░░░░░░░░█████░░█████░░░█████░░█████░░░░░
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ████████████████████████████████████████████████████████████████████████████████
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░██░░░░░                                                            ░░░░░███░░
  ░░░░░███░░          ██████████                    ██████████          ░░░██░░░░░
  ░░░██░░░░░        ██          ███               ██          ███       ░░░█████░░
  ░░░░░░░░░░     ███               ██          ███               ██     ░░░░░░░░░░
  ░░░░░███░░     ███  █████        ██          ███  █████        ██     ░░░██░░░░░
  ░░░██░░░░░     ███  ███          ██   █████  ███  ███          ██     ░░░░░███░░
  ░░░░░███░░     ███  █████        ██          ███  █████        ██     ░░░█████░░
  ░░░░░░░░░░     ███  █████        ██   █████  ███  █████        ██     ░░░░░░░░░░
  ░░░██░░░░░     ███               ██          ███               ██     ░░░█████░░
  ░░░░░███░░        ██          ███     █████     ██          ███       ░░░░░███░░
  ░░░██░░░░░          ██████████                    ██████████          ░░░██░░░░░
  ░░░░░░░░░░                                                            ░░░░░░░░░░
  ░░░░░███░░     █████   █████  █████   █████  █████   █████  █████     ░░░█████░░
  ░░░██░░░░░     █████   █████  █████   █████     ██   █████  █████     ░░░██░░░░░
  ░░░░░███░░                                                            ░░░░░███░░
  ░░░░░░░░░░                                                            ░░░░░░░░░░
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ████████████████████████████████████████████████████████████████████████████████
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░░░████████░░████████░░████████░░████████░░░░░██░░░██░░░██░░░██░░░██░░░██░░░░░
  ░░░░░█████░░░░░███░░███░░███░░███░░░░░██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░░░███░░░░░░░████████░░███░░███░░░░░██░░░░░░░░██░░░██░░░██░░░██░░░██░░░██░░░░░
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import {IOKPCFont} from './interfaces/IOKPCFont.sol';

contract OKPCFont is IOKPCFont {
  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                   STORAGE                                  */
  /* -------------------------------------------------------------------------- */
  mapping(bytes1 => string) public font;

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                               INITIALIZATION                               */
  /* -------------------------------------------------------------------------- */
  constructor() {
    _initFont();
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                    FONT                                    */
  /* -------------------------------------------------------------------------- */

  /// @notice Gets the font for a specified character
  /// @param char The character to get the SVG path for.
  function getChar(bytes1 char) public view override returns (string memory) {
    uint8 index = uint8(char);
    if (index >= 65 && index <= 90) index += 32;
    bytes1 c = bytes1(index);

    if (bytes(font[c]).length == 0) revert CharacterNotFound();

    return font[c];
  }

  /// @notice Gets the font for a specified character using a string
  /// @param char The character to get the SVG path for.
  function getChar(string memory char)
    public
    view
    override
    returns (string memory)
  {
    if (bytes(char).length > 1) revert NotSingleCharacter();

    bytes1 b = bytes(char)[0];
    return getChar(b);
  }

  /// @notice Initializes font data during deploy.
  function _initFont() internal {
    font['a'] = 'M2 0H1V1H0V2V3H1V2H2V3H3V2V1H2V0Z';
    font['b'] = 'M2 0V1H3V2V3H2H1H0V2V1V0H1H2Z';
    font['c'] = 'M2 1H1V2H2H3V3H2H1H0V2V1V0H1H2H3V1H2Z';
    font['d'] = 'M2 1H1V2H2V3H1H0V2V1V0H1H2V1ZM2 1V2H3V1H2Z';
    font['e'] = 'M1 0H2H3V1H2V2H3V3H2H1H0V2V1V0H1Z';
    font['f'] = 'M1 0H2H3V1H2V2H1V3H0V2V1V0H1Z';
    font['g'] = 'M2 1H1V2H2V1ZM3 2V1H2V0H1H0V1V2V3H1H2H3V2Z';
    font['h'] = 'M3 0V1V2V3H2V2H1V3H0V2V1V0H1V1H2V0H3Z';
    font['i'] = 'M3 1H2V2H3V3H2H1H0V2H1V1H0V0H1H2H3V1Z';
    font['j'] = 'M3 0V1V2V3H2H1H0V2V1H1V2H2V1V0H3Z';
    font['k'] = 'M1 0V1H2V2H1V3H0V2V1V0H1ZM2 2V3H3V2H2ZM2 1V0H3V1H2Z';
    font['l'] = 'M1 0V1V2H2H3V3H2H1H0V2V1V0H1Z';
    font['m'] = 'M0 0H1H2H3V1V2V3H2V2H1V3H0V2V1V0Z';
    font['n'] = 'M0 0H1H2H3V1V2V3H2V2V1H1V2V3H0V2V1V0Z';
    font['o'] = 'M0 0H1H2H3V1V2V3H2H1H0V2V1V0ZM1 1V2H2V1H1Z';
    font['p'] = 'M0 0H1H2H3V1V2H2H1V3H0V2V1V0Z';
    font['q'] = 'M0 0H1H2H3V1V2V3H2V2H1H0V1V0Z';
    font['r'] = 'M0 0H1H2H3V1H2H1V2V3H0V2V1V0Z';
    font['s'] = 'M3 1H2V2V3H1H0V2H1V1V0H2H3V1Z';
    font['t'] = 'M1 0H2H3V1H2V2V3H1V2V1H0V0H1Z';
    font['u'] = 'M1 0V1V2H2V1V0H3V1V2V3H2H1H0V2V1V0H1Z';
    font['v'] = 'M1 0V1V2H0V1V0H1ZM2 2H1V3H2V2ZM2 2V1V0H3V1V2H2Z';
    font['w'] = 'M1 0V1H2V0H3V1V2V3H2H1H0V2V1V0H1Z';
    font['x'] = 'M1 1H0V0H1V1ZM2 1H1V2H0V3H1V2H2V3H3V2H2V1ZM2 1V0H3V1H2Z';
    font['y'] = 'M1 1H0V0H1V1ZM2 1H1V2V3H2V2V1ZM2 1V0H3V1H2Z';
    font['z'] = 'M1 1H0V0H1H2V1V2H3V3H2H1V2V1Z';
    font['1'] = 'M1 1H0V0H1H2V1V2H3V3H2H1H0V2H1V1Z';
    font['2'] = 'M1 1H0V0H1H2V1V2H3V3H2H1V2V1Z';
    font['3'] = 'M1 1H0V0H1H2H3V1V2V3H2H1H0V2H1V1Z';
    font['4'] = 'M1 0V1H2V0H3V1V2V3H2V2H1H0V1V0H1Z';
    font['5'] = 'M3 1H2V2V3H1H0V2H1V1V0H2H3V1Z';
    font['6'] = 'M1 0V1H2H3V2V3H2H1H0V2V1V0H1Z';
    font['7'] = 'M1 1H0V0H1H2H3V1V2V3H2V2V1H1Z';
    font['8'] = 'M3 0V1V2V3H2H1H0V2V1H1V0H2H3Z';
    font['9'] = 'M0 0H1H2H3V1V2V3H2V2H1H0V1V0Z';
    font['0'] = 'M0 0H1H2H3V1V2V3H2H1H0V2V1V0ZM1 1V2H2V1H1Z';
    font[' '] = ' ';
    font[
      '%'
    ] = 'M0 1H1V0H0V1ZM1 2H2V1H1V2ZM2 1H3V0H2V1ZM2 2H3V1H2V2ZM2 3H3V2H2V3ZM1 3H2V2H1V3ZM0 3H1V2H0V3Z';
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

interface IOKPCFont {
  error CharacterNotFound();
  error NotSingleCharacter();

  function getChar(string memory char) external view returns (string memory);

  function getChar(bytes1) external view returns (string memory);
}