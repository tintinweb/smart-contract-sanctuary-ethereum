// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

library factory {

  function draw(uint256 background, uint256 checkerPattern, uint256 color, uint256 eight) public pure returns (string memory) {
    
    string[4] memory backgrounds = [        
        ".bg{fill:#131016}",
        ".bg{fill:#ffaa31}",
        ".bg{fill:#b42c41}",
        ".bg{fill:#007fff}"
    ];

    string[4] memory  colors = [
        ".l{fill:#1d1036}.r{fill:#39206a}",
        ".l{fill:#202237}.r{fill:#242e5d}",
        ".l{fill:#334e74}.r{fill:#39987b}",
        ".l{fill:#18226d}.r{fill:#b42c41}"
    ];

    string[2]  memory eights = [
        ".B{fill:#131016}.C{fill:#ee2073}.D{fill:#ffaa31}.E{fill:#39206a}",
        ".B{fill:#131016}.C{fill:#fd9d35}.D{fill:#fcea44}.E{fill:#fc6340}"
    ];
    
    string memory bg = backgrounds[background];
    string memory c = colors[color];
    string memory e = eights[eight];
    
    string memory eightDraw = _getEights();
    string memory outline = _getOutline();
    string memory backgroundDraw = _getBackground();
    string memory closeStyle = ']]></style><g id="image" transform="scale(4 4)">';     
    string memory s = _getShield(checkerPattern);

    return string(abi.encodePacked('<svg version="1.1" width="160" height="160" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges"><style><![CDATA[',bg,c,e,closeStyle,backgroundDraw,s,eightDraw,outline,'</g></svg>'));
    
  }

  function _getShield(uint256 checkerPattern) internal pure returns (string memory) {      
     if (checkerPattern == 0) {
       return _getBigShield();
     } else {       
       return _getSmallShield();
     }
  }

  function _getBackground() internal pure returns (string memory) {
    string memory background = '<rect x="0" y="0" width="40" height="40" class="bg"/>';
      return background;
  }
  function _getBigShield() internal pure returns (string memory) {
    string memory shield = '<rect x="7" y="4" width="13" height="15" class="l" />'
            '<rect x="8" y="3" width="12" height="1" class="l" />'
            '<rect x="6" y="5" width="1" height="14" class="l" />'
            '<rect x="20" y="19" width="14" height="9" class="l" />'
            '<rect x="20" y="28" width="13" height="1" class="l" />'
            '<rect x="20" y="29" width="12" height="1" class="l" />'
            '<rect x="20" y="30" width="11" height="1" class="l" />'
            '<rect x="20" y="31" width="10" height="1" class="l" />'
            '<rect x="20" y="32" width="9" height="1" class="l" />'
            '<rect x="20" y="33" width="8" height="1" class="l" />'
            '<rect x="20" y="34" width="7" height="1" class="l" />'
            '<rect x="20" y="35" width="6" height="1" class="l" />'
            '<rect x="20" y="36" width="5" height="1" class="l" />'
            '<rect x="20" y="37" width="4" height="1" class="l" />'
            '<rect x="20" y="3" width="12" height="1" class="r" />'
            '<rect x="20" y="4" width="13" height="15" class="r" />'
            '<rect x="33" y="5" width="1" height="14" class="r" />'
            '<rect x="6" y="19" width="14" height="9" class="r" />'
            '<rect x="7" y="28" width="13" height="1" class="r" />'
            '<rect x="8" y="29" width="12" height="1" class="r" />'
            '<rect x="9" y="30" width="11" height="1" class="r" />'
            '<rect x="10" y="31" width="10" height="1" class="r" />'
            '<rect x="11" y="32" width="9" height="1" class="r" />'
            '<rect x="12" y="33" width="8" height="1" class="r" />'
            '<rect x="13" y="34" width="7" height="1" class="r" />'
            '<rect x="14" y="35" width="6" height="1" class="r" />'
            '<rect x="15" y="36" width="5" height="1" class="r" />'
            '<rect x="16" y="37" width="4" height="1" class="r" />';
      return shield;
  }

    function _getSmallShield() internal pure returns (string memory) {
    string memory shield = '<rect x="7" y="4" width="13" height="15" class="l" />'
            '<rect x="8" y="3" width="12" height="1" class="l" />'
            '<rect x="6" y="5" width="1" height="14" class="l" />'
            '<rect x="20" y="19" width="14" height="9" class="l" />'
            '<rect x="20" y="28" width="13" height="1" class="l" />'
            '<rect x="20" y="29" width="12" height="1" class="l" />'
            '<rect x="20" y="30" width="11" height="1" class="l" />'
            '<rect x="20" y="31" width="10" height="1" class="l" />'
            '<rect x="20" y="32" width="9" height="1" class="l" />'
            '<rect x="20" y="33" width="8" height="1" class="l" />'
            '<rect x="20" y="34" width="7" height="1" class="l" />'
            '<rect x="20" y="35" width="6" height="1" class="l" />'
            '<rect x="20" y="36" width="5" height="1" class="l" />'
            '<rect x="20" y="37" width="4" height="1" class="l" />'
            '<rect x="20" y="3" width="12" height="1" class="l" />'
            '<rect x="20" y="4" width="13" height="15" class="l" />'
            '<rect x="33" y="5" width="1" height="14" class="l" />'
            '<rect x="6" y="19" width="14" height="9" class="l" />'
            '<rect x="7" y="28" width="13" height="1" class="l" />'
            '<rect x="8" y="29" width="12" height="1" class="l" />'
            '<rect x="9" y="30" width="11" height="1" class="l" />'
            '<rect x="10" y="31" width="10" height="1" class="l" />'
            '<rect x="11" y="32" width="9" height="1" class="l" />'
            '<rect x="12" y="33" width="8" height="1" class="l" />'
            '<rect x="13" y="34" width="7" height="1" class="l" />'
            '<rect x="14" y="35" width="6" height="1" class="l" />'
            '<rect x="15" y="36" width="6" height="1" class="l" />'
            '<rect x="16" y="37" width="4" height="1" class="l" />'
            '<rect x="10" y="3" width="4" height="4" class="r" />'
            '<rect x="18" y="3" width="4" height="4" class="r" />'
            '<rect x="26" y="3" width="4" height="4" class="r" />'
            '<rect x="14" y="7" width="4" height="4" class="r" />'
            '<rect x="22" y="7" width="4" height="4" class="r" />'
            '<rect x="30" y="7" width="4" height="4" class="r" />'
            '<rect x="10" y="11" width="4" height="4" class="r" />'
            '<rect x="18" y="11" width="4" height="4" class="r" />'
            '<rect x="26" y="11" width="4" height="4" class="r" />'
            '<rect x="6" y="15" width="4" height="4" class="r" />'
            '<rect x="14" y="15" width="4" height="4" class="r" />'
            '<rect x="22" y="15" width="4" height="4" class="r" />'
            '<rect x="30" y="15" width="4" height="4" class="r" />'
            '<rect x="10" y="19" width="4" height="4" class="r" />'
            '<rect x="18" y="19" width="4" height="4" class="r" />'
            '<rect x="26" y="19" width="4" height="4" class="r" />'
            '<rect x="6" y="23" width="4" height="4" class="r" />'
            '<rect x="14" y="23" width="4" height="4" class="r" />'
            '<rect x="22" y="23" width="4" height="4" class="r" />'
            '<rect x="30" y="23" width="4" height="4" class="r" />'
            '<rect x="10" y="27" width="4" height="4" class="r" />'
            '<rect x="18" y="27" width="4" height="4" class="r" />'
            '<rect x="26" y="27" width="4" height="4" class="r" />'
            '<rect x="14" y="31" width="4" height="4" class="r" />'
            '<rect x="22" y="31" width="4" height="4" class="r" />'
            '<rect x="18" y="35" width="4" height="3" class="r" />';

      return shield;
  }

    function _getOutline() internal pure returns (string memory) {
    string memory outline = '<rect x="8" y="2" width="24" height="1" fill="#202237" />'
        '<rect x="7" y="3" width="1" height="1" fill="#202237" />'
        '<rect x="32" y="3" width="1" height="1" fill="#202237" />'
        '<rect x="6" y="4" width="1" height="1" fill="#202237" />'
        '<rect x="33" y="4" width="1" height="1" fill="#202237" />'
        '<rect x="5" y="5" width="1" height="23" fill="#202237" />'
        '<rect x="34" y="5" width="1" height="23" fill="#202237" />'
        '<rect x="6" y="28" width="1" height="1" fill="#202237" />'
        '<rect x="33" y="28" width="1" height="1" fill="#202237" />'
        '<rect x="7" y="29" width="1" height="1" fill="#202237" />'
        '<rect x="32" y="29" width="1" height="1" fill="#202237" />'
        '<rect x="8" y="30" width="1" height="1" fill="#202237" />'
        '<rect x="31" y="30" width="1" height="1" fill="#202237" />'
        '<rect x="9" y="31" width="1" height="1" fill="#202237" />'
        '<rect x="30" y="31" width="1" height="1" fill="#202237" />'
        '<rect x="10" y="32" width="1" height="1" fill="#202237" />'
        '<rect x="29" y="32" width="1" height="1" fill="#202237" />'
        '<rect x="11" y="33" width="1" height="1" fill="#202237" />'
        '<rect x="28" y="33" width="1" height="1" fill="#202237" />'
        '<rect x="12" y="34" width="1" height="1" fill="#202237" />'
        '<rect x="27" y="34" width="1" height="1" fill="#202237" />'
        '<rect x="13" y="35" width="1" height="1" fill="#202237" />'
        '<rect x="26" y="35" width="1" height="1" fill="#202237" />'
        '<rect x="14" y="36" width="1" height="1" fill="#202237" />'
        '<rect x="25" y="36" width="1" height="1" fill="#202237" />'
        '<rect x="15" y="37" width="1" height="1" fill="#202237" />'
        '<rect x="24" y="37" width="1" height="1" fill="#202237" />'
        '<rect x="16" y="38" width="8" height="1" fill="#202237" />';
      return outline;
  }

  function _getEights() internal pure returns (string memory) {
    string memory eight = '<path d="M15 3h1v1h-1z" class="B"/><g class="D"><path d="M16 3h1v1h-1z"/><path d="M17 3h1v1h-1z"/><path d="M18 3h1v1h-1z"/></g><g class="B"><path d="M19 3h1v1h-1z"/><path d="M20 3h1v1h-1z"/></g><g class="D"><path d="M21 3h1v1h-1z"/><path d="M22 3h1v1h-1z"/><path d="M23 3h1v1h-1z"/></g><path d="M24 3h1v1h-1zm-9 1h1v1h-1z" class="B"/><path d="M16 4h1v1h-1z" class="C"/><path d="M17 4h1v1h-1z" class="D"/><path d="M18 4h1v1h-1z" class="C"/><g class="B"><path d="M19 4h1v1h-1z"/><path d="M20 4h1v1h-1z"/></g><path d="M21 4h1v1h-1z" class="C"/><path d="M22 4h1v1h-1z" class="D"/><path d="M23 4h1v1h-1z" class="C"/><path d="M24 4h1v1h-1zm-8 1h1v1h-1z" class="B"/><path d="M17 5h1v1h-1z" class="C"/><path d="M18 5h1v1h-1z" class="D"/><g class="C"><path d="M19 5h1v1h-1z"/><path d="M20 5h1v1h-1z"/></g><path d="M21 5h1v1h-1z" class="D"/><path d="M22 5h1v1h-1z" class="C"/><path d="M23 5h1v1h-1zm-6 1h1v1h-1z" class="B"/><g class="C"><path d="M18 6h1v1h-1z"/><path d="M19 6h1v1h-1z"/><path d="M20 6h1v1h-1z"/><path d="M21 6h1v1h-1z"/></g><path d="M22 6h1v1h-1zm-6 1h1v1h-1z" class="B"/><path d="M17 7h1v1h-1z" class="C"/><path d="M18 7h1v1h-1z" class="E"/><g class="C"><path d="M19 7h1v1h-1z"/><path d="M20 7h1v1h-1z"/></g><path d="M21 7h1v1h-1z" class="E"/><path d="M22 7h1v1h-1z" class="C"/><path d="M23 7h1v1h-1zm-8 1h1v1h-1z" class="B"/><path d="M16 8h1v1h-1z" class="C"/><path d="M17 8h1v1h-1z" class="E"/><path d="M18 8h1v1h-1z" class="C"/><g class="B"><path d="M19 8h1v1h-1z"/><path d="M20 8h1v1h-1z"/></g><path d="M21 8h1v1h-1z" class="C"/><path d="M22 8h1v1h-1z" class="E"/><path d="M23 8h1v1h-1z" class="C"/><path d="M24 8h1v1h-1zm-9 1h1v1h-1z" class="B"/><g class="E"><path d="M16 9h1v1h-1z"/><path d="M17 9h1v1h-1z"/><path d="M18 9h1v1h-1z"/></g><g class="B"><path d="M19 9h1v1h-1z"/><path d="M20 9h1v1h-1z"/></g><g class="E"><path d="M21 9h1v1h-1z"/><path d="M22 9h1v1h-1z"/><path d="M23 9h1v1h-1z"/></g><path d="M24 9h1v1h-1zm-9 1h1v1h-1z" class="B"/><g class="E"><path d="M16 10h1v1h-1z"/><path d="M17 10h1v1h-1z"/><path d="M18 10h1v1h-1z"/></g><g class="B"><path d="M19 10h1v1h-1z"/><path d="M20 10h1v1h-1z"/></g><g class="E"><path d="M21 10h1v1h-1z"/><path d="M22 10h1v1h-1z"/><path d="M23 10h1v1h-1z"/></g><path d="M24 10h1v1h-1zm-8 1h1v1h-1z" class="B"/><g class="E"><path d="M17 11h1v1h-1z"/><path d="M18 11h1v1h-1z"/><path d="M19 11h1v1h-1z"/><path d="M20 11h1v1h-1z"/><path d="M21 11h1v1h-1z"/><path d="M22 11h1v1h-1z"/></g><path d="M23 11h1v1h-1zm-6 1h1v1h-1z" class="B"/><g class="E"><path d="M18 12h1v1h-1z"/><path d="M19 12h1v1h-1z"/><path d="M20 12h1v1h-1z"/><path d="M21 12h1v1h-1z"/></g><g class="B"><path d="M22 12h1v1h-1zm-4 1h1v1h-1z"/><path d="M19 13h1v1h-1z"/><path d="M20 13h1v1h-1z"/><path d="M21 13h1v1h-1zm-4 1h1v1h-1z"/></g><g class="D"><path d="M18 14h1v1h-1z"/><path d="M19 14h1v1h-1z"/><path d="M20 14h1v1h-1z"/><path d="M21 14h1v1h-1z"/></g><path d="M22 14h1v1h-1zm-6 1h1v1h-1z" class="B"/><g class="D"><path d="M17 15h1v1h-1z"/><path d="M18 15h1v1h-1z"/><path d="M19 15h1v1h-1z"/><path d="M20 15h1v1h-1z"/><path d="M21 15h1v1h-1z"/><path d="M22 15h1v1h-1z"/></g><path d="M23 15h1v1h-1zm-8 1h1v1h-1z" class="B"/><g class="D"><path d="M16 16h1v1h-1z"/><path d="M17 16h1v1h-1z"/><path d="M18 16h1v1h-1z"/></g><g class="B"><path d="M19 16h1v1h-1z"/><path d="M20 16h1v1h-1z"/></g><g class="D"><path d="M21 16h1v1h-1z"/><path d="M22 16h1v1h-1z"/><path d="M23 16h1v1h-1z"/></g><path d="M24 16h1v1h-1zm-9 1h1v1h-1z" class="B"/><g class="D"><path d="M16 17h1v1h-1z"/><path d="M17 17h1v1h-1z"/><path d="M18 17h1v1h-1z"/></g><g class="B"><path d="M19 17h1v1h-1z"/><path d="M20 17h1v1h-1z"/></g><g class="D"><path d="M21 17h1v1h-1z"/><path d="M22 17h1v1h-1z"/><path d="M23 17h1v1h-1z"/></g><path d="M24 17h1v1h-1zm-9 1h1v1h-1z" class="B"/><path d="M16 18h1v1h-1z" class="C"/><path d="M17 18h1v1h-1z" class="D"/><path d="M18 18h1v1h-1z" class="C"/><g class="B"><path d="M19 18h1v1h-1z"/><path d="M20 18h1v1h-1z"/></g><path d="M21 18h1v1h-1z" class="C"/><path d="M22 18h1v1h-1z" class="D"/><path d="M23 18h1v1h-1z" class="C"/><path d="M24 18h1v1h-1zm-8 1h1v1h-1z" class="B"/><path d="M17 19h1v1h-1z" class="C"/><path d="M18 19h1v1h-1z" class="D"/><g class="C"><path d="M19 19h1v1h-1z"/><path d="M20 19h1v1h-1z"/></g><path d="M21 19h1v1h-1z" class="D"/><path d="M22 19h1v1h-1z" class="C"/><path d="M23 19h1v1h-1zm-6 1h1v1h-1z" class="B"/><g class="C"><path d="M18 20h1v1h-1z"/><path d="M19 20h1v1h-1z"/><path d="M20 20h1v1h-1z"/><path d="M21 20h1v1h-1z"/></g><path d="M22 20h1v1h-1zm-6 1h1v1h-1z" class="B"/><path d="M17 21h1v1h-1z" class="C"/><path d="M18 21h1v1h-1z" class="E"/><g class="C"><path d="M19 21h1v1h-1z"/><path d="M20 21h1v1h-1z"/></g><path d="M21 21h1v1h-1z" class="E"/><path d="M22 21h1v1h-1z" class="C"/><path d="M23 21h1v1h-1zm-8 1h1v1h-1z" class="B"/><path d="M16 22h1v1h-1z" class="C"/><path d="M17 22h1v1h-1z" class="E"/><path d="M18 22h1v1h-1z" class="C"/><g class="B"><path d="M19 22h1v1h-1z"/><path d="M20 22h1v1h-1z"/></g><path d="M21 22h1v1h-1z" class="C"/><path d="M22 22h1v1h-1z" class="E"/><path d="M23 22h1v1h-1z" class="C"/><path d="M24 22h1v1h-1zm-9 1h1v1h-1z" class="B"/><g class="E"><path d="M16 23h1v1h-1z"/><path d="M17 23h1v1h-1z"/><path d="M18 23h1v1h-1z"/></g><g class="B"><path d="M19 23h1v1h-1z"/><path d="M20 23h1v1h-1z"/></g><g class="E"><path d="M21 23h1v1h-1z"/><path d="M22 23h1v1h-1z"/><path d="M23 23h1v1h-1z"/></g><path d="M24 23h1v1h-1zm-9 1h1v1h-1z" class="B"/><g class="E"><path d="M16 24h1v1h-1z"/><path d="M17 24h1v1h-1z"/><path d="M18 24h1v1h-1z"/></g><g class="B"><path d="M19 24h1v1h-1z"/><path d="M20 24h1v1h-1z"/></g><g class="E"><path d="M21 24h1v1h-1z"/><path d="M22 24h1v1h-1z"/><path d="M23 24h1v1h-1z"/></g><path d="M24 24h1v1h-1zm-8 1h1v1h-1z" class="B"/><g class="E"><path d="M17 25h1v1h-1z"/><path d="M18 25h1v1h-1z"/><path d="M19 25h1v1h-1z"/><path d="M20 25h1v1h-1z"/><path d="M21 25h1v1h-1z"/><path d="M22 25h1v1h-1z"/></g><path d="M23 25h1v1h-1zm-6 1h1v1h-1z" class="B"/><g class="E"><path d="M18 26h1v1h-1z"/><path d="M19 26h1v1h-1z"/><path d="M20 26h1v1h-1z"/><path d="M21 26h1v1h-1z"/></g><g class="B"><path d="M22 26h1v1h-1zm-4 1h1v1h-1z"/><path d="M19 27h1v1h-1z"/><path d="M20 27h1v1h-1z"/><path d="M21 27h1v1h-1zm-4 1h1v1h-1z"/></g><g class="D"><path d="M18 28h1v1h-1z"/><path d="M19 28h1v1h-1z"/><path d="M20 28h1v1h-1z"/><path d="M21 28h1v1h-1z"/></g><path d="M22 28h1v1h-1zm-6 1h1v1h-1z" class="B"/><g class="D"><path d="M17 29h1v1h-1z"/><path d="M18 29h1v1h-1z"/><path d="M19 29h1v1h-1z"/><path d="M20 29h1v1h-1z"/><path d="M21 29h1v1h-1z"/><path d="M22 29h1v1h-1z"/></g><path d="M23 29h1v1h-1zm-8 1h1v1h-1z" class="B"/><g class="D"><path d="M16 30h1v1h-1z"/><path d="M17 30h1v1h-1z"/><path d="M18 30h1v1h-1z"/></g><g class="B"><path d="M19 30h1v1h-1z"/><path d="M20 30h1v1h-1z"/></g><g class="D"><path d="M21 30h1v1h-1z"/><path d="M22 30h1v1h-1z"/><path d="M23 30h1v1h-1z"/></g><path d="M24 30h1v1h-1zm-9 1h1v1h-1z" class="B"/><g class="D"><path d="M16 31h1v1h-1z"/><path d="M17 31h1v1h-1z"/><path d="M18 31h1v1h-1z"/></g><g class="B"><path d="M19 31h1v1h-1z"/><path d="M20 31h1v1h-1z"/></g><g class="D"><path d="M21 31h1v1h-1z"/><path d="M22 31h1v1h-1z"/><path d="M23 31h1v1h-1z"/></g><path d="M24 31h1v1h-1zm-9 1h1v1h-1z" class="B"/><path d="M16 32h1v1h-1z" class="C"/><path d="M17 32h1v1h-1z" class="D"/><path d="M18 32h1v1h-1z" class="C"/><g class="B"><path d="M19 32h1v1h-1z"/><path d="M20 32h1v1h-1z"/></g><path d="M21 32h1v1h-1z" class="C"/><path d="M22 32h1v1h-1z" class="D"/><path d="M23 32h1v1h-1z" class="C"/><path d="M24 32h1v1h-1zm-8 1h1v1h-1z" class="B"/><path d="M17 33h1v1h-1z" class="C"/><path d="M18 33h1v1h-1z" class="D"/><g class="C"><path d="M19 33h1v1h-1z"/><path d="M20 33h1v1h-1z"/></g><path d="M21 33h1v1h-1z" class="D"/><path d="M22 33h1v1h-1z" class="C"/><path d="M23 33h1v1h-1zm-6 1h1v1h-1z" class="B"/><g class="C"><path d="M18 34h1v1h-1z"/><path d="M19 34h1v1h-1z"/><path d="M20 34h1v1h-1z"/><path d="M21 34h1v1h-1z"/></g><path d="M22 34h1v1h-1zm-6 1h1v1h-1z" class="B"/><path d="M17 35h1v1h-1z" class="C"/><path d="M18 35h1v1h-1z" class="E"/><g class="C"><path d="M19 35h1v1h-1z"/><path d="M20 35h1v1h-1z"/></g><path d="M21 35h1v1h-1z" class="E"/><path d="M22 35h1v1h-1z" class="C"/><path d="M23 35h1v1h-1zm-8 1h1v1h-1z" class="B"/><path d="M16 36h1v1h-1z" class="C"/><path d="M17 36h1v1h-1z" class="E"/><path d="M18 36h1v1h-1z" class="C"/><g class="B"><path d="M19 36h1v1h-1z"/><path d="M20 36h1v1h-1z"/></g><path d="M21 36h1v1h-1z" class="C"/><path d="M22 36h1v1h-1z" class="E"/><path d="M23 36h1v1h-1z" class="C"/><path d="M24 36h1v1h-1zm-9 1h1v1h-1z" class="B"/><g class="E"><path d="M16 37h1v1h-1z"/><path d="M17 37h1v1h-1z"/><path d="M18 37h1v1h-1z"/></g><g class="B"><path d="M19 37h1v1h-1z"/><path d="M20 37h1v1h-1z"/></g><g class="E"><path d="M21 37h1v1h-1z"/><path d="M22 37h1v1h-1z"/><path d="M23 37h1v1h-1z"/></g><path d="M24 37h1v1h-1z" class="B"/>';
      return eight;
  }
  
}