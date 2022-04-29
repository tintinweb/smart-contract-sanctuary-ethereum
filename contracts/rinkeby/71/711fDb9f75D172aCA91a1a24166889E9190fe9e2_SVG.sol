// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
          _____                    _____                _____                _____          
         /\    \                  /\    \              /\    \              |\    \         
        /::\    \                /::\    \            /::\    \             |:\____\        
       /::::\    \               \:::\    \           \:::\    \            |::|   |        
      /::::::\    \               \:::\    \           \:::\    \           |::|   |        
     /:::/\:::\    \               \:::\    \           \:::\    \          |::|   |        
    /:::/  \:::\    \               \:::\    \           \:::\    \         |::|   |        
   /:::/    \:::\    \              /::::\    \          /::::\    \        |::|   |        
  /:::/    / \:::\    \    ____    /::::::\    \        /::::::\    \       |::|___|______  
 /:::/    /   \:::\    \  /\   \  /:::/\:::\    \      /:::/\:::\    \      /::::::::\    \ 
/:::/____/     \:::\____\/::\   \/:::/  \:::\____\    /:::/  \:::\____\    /::::::::::\____\
\:::\    \      \::/    /\:::\  /:::/    \::/    /   /:::/    \::/    /   /:::/~~~~/~~      
 \:::\    \      \/____/  \:::\/:::/    / \/____/   /:::/    / \/____/   /:::/    /         
  \:::\    \               \::::::/    /           /:::/    /           /:::/    /          
   \:::\    \               \::::/____/           /:::/    /           /:::/    /           
    \:::\    \               \:::\    \           \::/    /            \::/    /            
     \:::\    \               \:::\    \           \/____/              \/____/             
      \:::\    \               \:::\    \                                                   
       \:::\____\               \:::\____\                                                  
        \::/    /                \::/    /                                                  
         \/____/                  \/____/                                                   
                                                                                            
*/

library SVG {
    function head(string calldata fontFamily, string calldata fontWeight) public pure returns (bytes memory) {
        return abi.encodePacked('<svg baseProfile="tiny" height="500" width="500" xmlns="http://www.w3.org/2000/svg"><style>text {font-family:',
                    fontFamily, 
                    ';font-weight:',
                    fontWeight,
                    '}</style>');
    }

    function tail() public pure returns (bytes memory){
        return '</svg>';
    }

    function rect(string calldata hsl) public pure returns (bytes memory){
        return abi.encodePacked('<rect fill="hsl(',
                                hsl,
                                ')" height="500" width="500" x="0" y="0"/>');
    }
    function text(string calldata hsl, 
                    string calldata fontSize, 
                    string calldata pos,
                    string calldata text_content) public pure returns (bytes memory){
        return abi.encodePacked('<text fill="hsl(',
                                hsl,
                                ')" font-size="',
                                fontSize,
                                '" ',
                                pos,
                                '>',
                                text_content,
                                '</text>');   
    }

    function textMiddle(string calldata hsl, 
                    string calldata fontSize, 
                    string calldata pos,
                    string calldata text_content) public pure returns (bytes memory){
        return abi.encodePacked('<text fill="hsl(',
                                hsl,
                                ')" font-size="',
                                fontSize,
                                '" ',
                                pos,
                                ' style="text-anchor: middle">',
                                text_content,
                                '</text>');   
    }
}