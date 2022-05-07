//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Color {
  
  struct Palette {
    string name;
    string[] backgroundColors;
    string[] emoticonColors;
    string[] textColors;
  }

  function getPalettes() public pure returns (Palette[] memory) {
    Palette[] memory palettes = new Palette[](9);
    palettes[0] = getPalette1();
    palettes[1] = getPalette2();
    palettes[2] = getPalette3();
    palettes[3] = getPalette4();
    palettes[4] = getPalette5();
    palettes[5] = getPalette6();
    palettes[6] = getPalette7();
    palettes[7] = getPalette8();
    palettes[8] = getPalette9();
    return palettes;
  }

  function getPalette1() public pure returns (Palette memory) {
    string[] memory backgroundColors = new string[](5);
    backgroundColors[0] = '#D9D161';
    backgroundColors[1] = '#FFC9ED';
    backgroundColors[2] = '#C9CAF7';
    backgroundColors[3] = '#F2FA7F';
    backgroundColors[4] = '#53B7F0';

    string[] memory textColors = new string[](5);
    textColors[0] = '#AFA1C7';
    textColors[1] = '#644A91';
    textColors[2] = '#6C637A';
    textColors[3] = '#CCB9ED';
    textColors[4] = '#3F3A47';

    return Palette('1', backgroundColors, textColors, textColors);
  }

  function getPalette2() public pure returns (Palette memory) {
    string[] memory backgroundColors = new string[](5);
    backgroundColors[0] = '#C25F4A';
    backgroundColors[1] = '#F5DDD7';
    backgroundColors[2] = '#8F4561';
    backgroundColors[3] = '#7D9C72';
    backgroundColors[4] = '#94C24A';

    string[] memory textColors = new string[](5);
    textColors[0] = '#3E7F8C';
    textColors[1] = '#425559';
    textColors[2] = '#1C3A40';
    textColors[3] = '#68868C';
    textColors[4] = '#998971';

    return Palette('2', backgroundColors, textColors, textColors);
  }

  function getPalette3() public pure returns (Palette memory) {
    string[] memory backgroundColors = new string[](5);
    backgroundColors[0] = '#885FBD';
    backgroundColors[1] = '#80788D';
    backgroundColors[2] = '#495AF0';
    backgroundColors[3] = '#F5F1DF';
    backgroundColors[4] = '#BD955C';

    string[] memory textColors = new string[](5);
    textColors[0] = '#3E3D54';
    textColors[1] = '#716BDB';
    textColors[2] = '#9D9BD4';
    textColors[3] = '#312E5E';
    textColors[4] = '#7775A1';

    return Palette('3', backgroundColors, textColors, textColors);
  }

  function getPalette4() public pure returns (Palette memory) {
    string[] memory backgroundColors = new string[](5);
    backgroundColors[0] = '#568F82';
    backgroundColors[1] = '#79DBC5';
    backgroundColors[2] = '#DBB36E';
    backgroundColors[3] = '#59478F';
    backgroundColors[4] = '#8163DB';

    string[] memory textColors = new string[](5);
    textColors[0] = '#5C441E';
    textColors[1] = '#E1C18E';
    textColors[2] = '#FFBE54';
    textColors[3] = '#574C3A';
    textColors[4] = '#A87D03';

    return Palette('4', backgroundColors, textColors, textColors);
  }

  function getPalette5() public pure returns (Palette memory) {
    string[] memory backgroundColors = new string[](5);
    backgroundColors[0] = '#D9A561';
    backgroundColors[1] = '#FFEFED';
    backgroundColors[2] = '#FACAF7';
    backgroundColors[3] = '#CBED2E';
    backgroundColors[4] = '#78C7AC';

    string[] memory textColors = new string[](5);
    textColors[0] = '#B8A561';
    textColors[1] = '#856F1E';
    textColors[2] = '#C21D3E';
    textColors[3] = '#D1EAED';
    textColors[4] = '#769C96';

    return Palette('5', backgroundColors, textColors, textColors);
  }

  function getPalette6() public pure returns (Palette memory) {
    string[] memory backgroundColors = new string[](5);
    backgroundColors[0] = '#D9D161';
    backgroundColors[1] = '#FFC9ED';
    backgroundColors[2] = '#C9CAF7';
    backgroundColors[3] = '#F2FA7F';
    backgroundColors[4] = '#53B7F0';

    string[] memory textColors = new string[](5);
    textColors[0] = '#AFA1C7';
    textColors[1] = '#644A91';
    textColors[2] = '#6C637A';
    textColors[3] = '#CCB9ED';
    textColors[4] = '#3F3A47';

    return Palette('6', backgroundColors, textColors, textColors);
  }

  function getPalette7() public pure returns (Palette memory) {
    string[] memory backgroundColors = new string[](5);
    backgroundColors[0] = '#F5E564';
    backgroundColors[1] = '#F5C971';
    backgroundColors[2] = '#F5595B';
    backgroundColors[3] = '#D0C6F5';
    backgroundColors[4] = '#95BAF5';

    string[] memory textColors = new string[](5);
    textColors[0] = '#FFEE00';
    textColors[1] = '#F5A318';
    textColors[2] = '#F50008';
    textColors[3] = '#4B00F5';
    textColors[4] = '#1685F5';

    return Palette('7', backgroundColors, textColors, textColors);
  }

  function getPalette8() public pure returns (Palette memory) {
    string[] memory backgroundColors = new string[](5);
    backgroundColors[0] = '#FDAD0E';
    backgroundColors[1] = '#F4671F';
    backgroundColors[2] = '#D60441';
    backgroundColors[3] = '#84265E';
    backgroundColors[4] = '#247D75';

    string[] memory textColors = new string[](5);
    textColors[0] = '#FFF6E1';
    textColors[1] = '#A01356';
    textColors[2] = '#4F516A';
    textColors[3] = '#F25322';
    textColors[4] = '#5B3486';

    return Palette('8', backgroundColors, textColors, textColors);
  }

  function getPalette9() public pure returns (Palette memory) {
    string[] memory backgroundColors = new string[](5);
    backgroundColors[0] = '#5E4D3D';
    backgroundColors[1] = '#FFFFE9';
    backgroundColors[2] = '#C1C9C3';
    backgroundColors[3] = '#F4F3F0';
    backgroundColors[4] = '#CFC9A5';

    string[] memory textColors = new string[](5);
    textColors[0] = '#85A383';
    textColors[1] = '#CCCCBA';
    textColors[2] = '#A6ADA8';
    textColors[3] = '#4A4A48';
    textColors[4] = '#D1D0CD';

    return Palette('9', backgroundColors, textColors, textColors);
  }
}