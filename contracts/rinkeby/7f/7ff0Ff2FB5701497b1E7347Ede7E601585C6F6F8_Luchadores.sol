// SPDX-License-Identifier: UNLICENSED
/// @title Luchadores
/// @notice Luchadores Mock
/// @author CyberPnk <[email protected]>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     

pragma solidity ^0.8.13;

// To test in testnets
contract Luchadores {
    address maker;
    constructor() {
        maker = msg.sender;
    }

    function imageData(uint256) external pure returns (string memory) {
        return "<svg id='luchador2439' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'><style>#luchador2439 .lucha-base { fill: #cc0d3d; } #luchador2439 .lucha-alt { fill: #e0369f; } #luchador2439 .lucha-eyes { fill: #a5823b; } #luchador2439 .lucha-skin { fill: #f9d1b7; } #luchador2439 .lucha-breathe { animation: 0.5s lucha-breathe infinite alternate ease-in-out; } @keyframes lucha-breathe { from { transform: translateY(0px); } to { transform: translateY(1%); } }</style><g class='lucha-breathe'><path fill='#A9A18A' d='M21 2V1h-1V0h-1v2h1v1h-3v2h2v1h2V5h1V2zM5 3H4V2h1V0H4v1H3v1H2v3h1v1h2V5h2V3H6z'/><g fill='#000' opacity='.15'><path d='M21 4h1v1h-1zM19 5h-1v1h3V5h-1z'/><path d='M2 4h1v1H2zM4 5H3v1h3V5H5z'/></g><path class='lucha-skin' d='M22 12v-1h-1v-1h-1V9h-1V5h-1V3h-1V2h-1V1h-1V0H9v1H8v1H7v1H6v2H5v4H4v1H3v1H2v1H1v8h4v-1h1v-2H5v-3h1v1h1v1h1v2h8v-2h1v-1h1v-1h1v3h-1v2h1v1h4v-8z'/><path class='lucha-base' d='M10 9H4v1H3v1H2v1H1v3h4v-1h1v1h1v1h1v2h3V9zM22 12v-1h-1v-1h-1V9h-7v9h3v-2h1v-1h1v-1h1v1h4v-3z'/><path d='M10 9H4v1H3v1H2v1H1v3h4v-1h1v1h1v1h1v2h3V9zM22 12v-1h-1v-1h-1V9h-7v9h3v-2h1v-1h1v-1h1v1h4v-3z' fill='#000' opacity='.15'/><path class='lucha-alt' d='M4 14H1v1h4v-1z'/><path class='lucha-base' d='M18 5V3h-1V2h-1V1h-1V0H9v1H8v1H7v1H6v2H5v5h1v2h1v1h1v1h1v1h6v-1h1v-1h1v-1h1v-2h1V5z'/><g class='lucha-alt'><path d='M11 2h2V1h1V0h-4v1h1zM6 10v2h1v-1h1v-1H7zM17 10h-1v1h1v1h1v-2z'/><path d='M16 3h1V2h-1V1h-1v1h-1v1h-1v1h-2V3h-1V2H9V1H8v1H7v1h1v1h1v1h1v1h1v9h2V6h1V5h1V4h1z'/></g><path fill='#FFF' d='M9 6H6v3h4V6zM17 6h-3v3h4V6z'/><path class='lucha-eyes' d='M16 6h-2v3h3V6zM8 6H7v3h3V6H9z'/><path fill='#FFF' d='M7 6h1v1H7zM16 6h1v1h-1z' opacity='.4'/><path fill='#000' d='M15 7h1v1h-1zM8 7h1v1H8z'/><path class='lucha-skin' d='M14 10H9v3h6v-3z'/><path fill='#000' opacity='.9' d='M13 11h-3v1h4v-1z'/></g><path class='lucha-skin' d='M16 23v-6H8v6H7v1h4v-4h2v4h4v-1z'/><path class='lucha-base' d='M15 17H8v1h1v1h2v1h2v-1h2v-1h1v-1z'/><path class='lucha-base' d='M9 21H8v2H7v1h4v-3h-1zM16 23v-2h-3v3h4v-1z'/></svg>";
    }
    function metadata(uint256) external pure returns (string memory) {
        return '{"name": "Luchador #2439","description": "Luchadores are randomly generated using Chainlink VRF and have 100% on-chain art and metadata - Only 10000 will ever exist!","image_data": "<svg id=\'luchador2439\' xmlns=\'http://www.w3.org/2000/svg\' viewBox=\'0 0 24 24\'><style>#luchador2439 .lucha-base { fill: #cc0d3d; } #luchador2439 .lucha-alt { fill: #e0369f; } #luchador2439 .lucha-eyes { fill: #a5823b; } #luchador2439 .lucha-skin { fill: #f9d1b7; } #luchador2439 .lucha-breathe { animation: 0.5s lucha-breathe infinite alternate ease-in-out; } @keyframes lucha-breathe { from { transform: translateY(0px); } to { transform: translateY(1%); } }</style><g class=\'lucha-breathe\'><path fill=\'#A9A18A\' d=\'M21 2V1h-1V0h-1v2h1v1h-3v2h2v1h2V5h1V2zM5 3H4V2h1V0H4v1H3v1H2v3h1v1h2V5h2V3H6z\'/><g fill=\'#000\' opacity=\'.15\'><path d=\'M21 4h1v1h-1zM19 5h-1v1h3V5h-1z\'/><path d=\'M2 4h1v1H2zM4 5H3v1h3V5H5z\'/></g><path class=\'lucha-skin\' d=\'M22 12v-1h-1v-1h-1V9h-1V5h-1V3h-1V2h-1V1h-1V0H9v1H8v1H7v1H6v2H5v4H4v1H3v1H2v1H1v8h4v-1h1v-2H5v-3h1v1h1v1h1v2h8v-2h1v-1h1v-1h1v3h-1v2h1v1h4v-8z\'/><path class=\'lucha-base\' d=\'M10 9H4v1H3v1H2v1H1v3h4v-1h1v1h1v1h1v2h3V9zM22 12v-1h-1v-1h-1V9h-7v9h3v-2h1v-1h1v-1h1v1h4v-3z\'/><path d=\'M10 9H4v1H3v1H2v1H1v3h4v-1h1v1h1v1h1v2h3V9zM22 12v-1h-1v-1h-1V9h-7v9h3v-2h1v-1h1v-1h1v1h4v-3z\' fill=\'#000\' opacity=\'.15\'/><path class=\'lucha-alt\' d=\'M4 14H1v1h4v-1z\'/><path class=\'lucha-base\' d=\'M18 5V3h-1V2h-1V1h-1V0H9v1H8v1H7v1H6v2H5v5h1v2h1v1h1v1h1v1h6v-1h1v-1h1v-1h1v-2h1V5z\'/><g class=\'lucha-alt\'><path d=\'M11 2h2V1h1V0h-4v1h1zM6 10v2h1v-1h1v-1H7zM17 10h-1v1h1v1h1v-2z\'/><path d=\'M16 3h1V2h-1V1h-1v1h-1v1h-1v1h-2V3h-1V2H9V1H8v1H7v1h1v1h1v1h1v1h1v9h2V6h1V5h1V4h1z\'/></g><path fill=\'#FFF\' d=\'M9 6H6v3h4V6zM17 6h-3v3h4V6z\'/><path class=\'lucha-eyes\' d=\'M16 6h-2v3h3V6zM8 6H7v3h3V6H9z\'/><path fill=\'#FFF\' d=\'M7 6h1v1H7zM16 6h1v1h-1z\' opacity=\'.4\'/><path fill=\'#000\' d=\'M15 7h1v1h-1zM8 7h1v1H8z\'/><path class=\'lucha-skin\' d=\'M14 10H9v3h6v-3z\'/><path fill=\'#000\' opacity=\'.9\' d=\'M13 11h-3v1h4v-1z\'/></g><path class=\'lucha-skin\' d=\'M16 23v-6H8v6H7v1h4v-4h2v4h4v-1z\'/><path class=\'lucha-base\' d=\'M15 17H8v1h1v1h2v1h2v-1h2v-1h1v-1z\'/><path class=\'lucha-base\' d=\'M9 21H8v2H7v1h4v-3h-1zM16 23v-2h-3v3h4v-1z\'/></svg>","external_url": "https://luchadores.io/luchador/2439","attributes": [{"trait_type": "Spirit","value": "Bull"}, {"trait_type": "Torso","value": "Open Shirt"}, {"trait_type": "Arms","value": "Right Band"}, {"trait_type": "Mask","value": "Striped"}]}';
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return tokenId % 5 == 0 ? maker : address(this);
    }

}