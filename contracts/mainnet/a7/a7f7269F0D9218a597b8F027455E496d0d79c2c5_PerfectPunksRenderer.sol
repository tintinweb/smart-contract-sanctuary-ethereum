// SPDX-License-Identifier: UNLICENSED
/// @title PerfectPunksRenderer
/// @notice Renders Perfect Punks
/// @author CyberPnk <[email protected]>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     

pragma solidity ^0.8.2;

import "@cyberpnk/solidity-library/contracts/IStringUtilsV1.sol";
import "./ICryptoPunksData.sol";
// import "hardhat/console.sol";

contract PerfectPunksRenderer {
    IStringUtilsV1 stringUtils;
    ICryptoPunksData cryptoPunksData;

    constructor(address stringUtilsContract, address cryptoPunksDataContract) {
        stringUtils = IStringUtilsV1(stringUtilsContract);
        cryptoPunksData = ICryptoPunksData(cryptoPunksDataContract);
    }

    function getImage(uint16 punkId) public view returns(bytes memory) {
        string memory strPunkId = stringUtils.numberToString(punkId);
        string memory punkSvg = cryptoPunksData.punkImageSvg(punkId);

        return abi.encodePacked(
'<svg width="640" height="640" version="1.1" viewBox="0 0 640 640" xmlns="http://www.w3.org/2000/svg">'
  '<defs><linearGradient id="bg" spreadMethod="repeat" x1="0" y1="0" x2="100%" y2="0"><stop offset="0%" stop-color="#ae95fb"/><stop stop-color="#6c8395" offset="70%"/></linearGradient></defs>'
  '<rect y="0" height="640" x="0" width="640" fill="url(#bg)"/>'
   '<style>text {font-family: monospace; fill: black; font-weight: bold;font-size:2em;}</style>',
   punkSvg,
   '<rect y="590" height="40" fill="white" opacity="0.5" stroke="black" x="100" width="460"/>'
   '<text x="50%" text-anchor="middle" y="620">Perfect Punk #', strPunkId, ' V1+V2</text>'
'</svg>'
        );
    }


    function getTokenURI(uint256 punkId) public view returns (string memory) {
        string memory strPunkId = stringUtils.numberToString(punkId);

        bytes memory imageBytes = getImage(uint16(punkId));

        string memory image = stringUtils.base64EncodeSvg(abi.encodePacked(imageBytes));

        bytes memory json = abi.encodePacked(string(abi.encodePacked(
            '{'
                '"title": "Perfect Punk # ', strPunkId, '",'
                '"name": "Perfect Punk # ', strPunkId, '",'
                '"image": "', image, '",'
                '"traits": [ ',
                    '{"trait_type":"Perfect","value":"Yes"}'
                '],'
                '"description": "Contains both v1 (wrapped) and v2 (wrapped) versions of punk #.  ', strPunkId,' inside it.  You can unwrap it to get the wrappers out, and unwrap again at their respective wrappers to get the original v1 and v2 punks out."'
            '}'
        )));

        return stringUtils.base64EncodeJson(json);
    }

    function getContractURI(address) public view returns(string memory) {
        return stringUtils.base64EncodeJson(abi.encodePacked(
        '{'
            '"name": "Perfect Punks",'
            '"description": "Joins together a wrapped v1 punk and a wrapped v2 punk with the same ID so they can be traded in a single unit.  It can be unwrapped into their respective wrapped v1 and v2 punks.",'
            '"image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAMAAAD04JH5AAAABGdBTUEAALGPC%2FxhBQAAAAFzUkdCAK7OHOkAAAAJcEhZcwAADsIAAA7CARUoSoAAAABXUExURW6DmZGNz6qU9q2V%2BgAAAKaT73WHop%2BR5ZiP2duxgH6JsoiLwei9iS4xQU8%2FKvfIkUdRYl5Zh8MaC6%2Bj96puLGyDldOhYotxUcZ%2BUqBmIv%2FiJaKJF4NoRpSkKygAAAWjSURBVHja7VuLdqMgEMUkKr4Ss3l2m%2F%2F%2FzhVEGHAQVNA9PZ2mPWlJyvVy58EEyfF4PHSW9paneW80p8ISmgirkkpZWZXKsjKTRjLS2cPXyACgh5ALBBRAEAgqjiCR0%2FdfYn4GoQTzzwJwUAxIArTpqWIgwRjIAAVEQHiQhQykAwN0wGDMn4jpAQHi%2BsulSzCHAUkBmB4SwKefhcBgIEU0QAEBUgI2DRD2vUiEmgYhA8oLLBIQXlBqFCzVgGJAakB5QTWSYTUIwFiE5RpAGNA1oHkhwgCZ64duDSRSAxoBbH5NAsoT%2BRIEZABGQuUElkAwMBBBA7obglXI4BqQbH4k9PSCyozEmgSgBrMgDIxygcGAEYtCRUKXFyCBcJwLAscBbQlwT8zMSBTJCwwCKp2BaHHAWAIQCbVVMJcgkhcgYWhQYKmH4hhxYByJKo2BMkBFNOEF1URFBJ0weBzQi9IEKQnH%2BTh%2BLqiMegxmw0AVEV4PWDKytgRbVERYHNApiJULWFUwVZuVEXOBWIL2Cr4Qi5cLegj05LAyi%2BYFnILcDYCQWPUAA%2BDFQMxc4MvAyjhwuElTDFA2cnMBSLgvqPnBxt1fA4dG%2FcPboAHanrytlZNl6o9N5s3ADQBIBwbodQEA4gPAxYBQ4CIAQRgY1iAaA5oX5Lfu1xtY7hv3idkMMEdgwisBgBJTosnAsWnaBsqtbTp7Fc9n8fEH8Hl29mLvBFye%2BO%2BZQwO4m33%2F7ezbH8DE6zMHA3sA0HpEuzHQITh0T4%2FRAZTGtkEA6K7%2BkFw7I%2Bi7zt%2Bdnf0BTLyeFw1XgjBwnOFma60liAb2AyC84JeBvQHYGLix6GSWAq%2BL1YzYX61mgBUkeWMCqAuLXbTsR2A6XqiBrh6giwE8vABMM5CuYUCrB5YzMAbw2YSBhoXmKzUYeHX2edrmL%2BoPe0EjARAeepd5QSOKIR3Ape6ssBsbvpxVCcYro2YZA%2BmwMdIAFG6rz3oN6ABg00CbDrvjyAD%2BWwaagYEBwJlZvTkD0gvOLv2tA2DVgFwCr4uPqYFoAKY1QKUG9mEg4ekYAKiloTGoNgMRn8SLgfTIGxL8BYQ94wTcVP7v5%2F%2BS9jbmf8qRuwHgwXeJfUCueDMR3xkd5M7oyrapFABQl%2Ft1v9%2B%2F2AMBIEbuIwAPVhm0YmOi92%2BIcYJCAqB9l8gEULP%2Fzw0F0I8gAFhamrE3lAwkGADxwAHwH%2FMAILvjCQbERWIakEMogMyPgQMvAireKMQAXHhA%2Frw7M4qC%2BsWGTk82ggF49J1dFwMpx8IXIMcByAbEGACzgo2gAB5o%2F3DUI5KNShsDywHM6ZTSGAzM6RUPDEgvGCLfBIDPUgAHNwNnVom%2B%2BzDP7DWevyjefIgBKMIxQEHHRMsFtnq0xpLRegZO67JhUAaiAfhPGUi2ADCpAar6A%2FtoIEhNuIoBtTP6uQxMeoETABaWtmSgD83v%2FTRwwTomWzJwwXpGQRnYAEAABkIswUINiPpgxziAlQdbauA3F%2BzKQK3b5rng%2FUe3%2B8YM1CaA99YaMAH8%2BaEMAABGoxJnAGtSrWaAEtY0aI1WLesEQHuq0Nyf6iLBckHCnuRXs1ldd5c7PIoaJid%2BoszvKJGbAXmU6%2BrTLb8Yh1gCeIE8xxQNgIuBhI4ZsHZKIzBgHGTiAN6foV8Au2T951XMgjKQjDXQ%2B7kZFz6qFZutPk0HGRhrAAfw0o7zkZgamAYQ5GT1tAZcAMIyYNeA8cH9K%2BSZUocX1GpC8AFHUvGzjEHOlHpEwnoEAB7wD%2BgFtkhoAUCCnCl1RsJJAFl8DYDAYwAIdafVtBfA0NvPzc9nyXvNAjNgzYYg%2BXD9yxWIHgnH6VfeYrL8tt%2FZGjAAGHfbkUd8DVgYCHO%2FoZcGphjYTQMk2yIbTjAQ6n7DFRoI7wUzNRC8HogcB%2F4B1DmZr%2BQdUsQAAAAASUVORK5CYII%3D",'
            '"seller_fee_basis_points": 0,'
            '"external_link": "https://perfectpunks.eth.link"'
        '}'));
    }
}

// SPDX-License-Identifier: MIT
/// [MIT License]
/// @title StringUtilsV1

pragma solidity ^0.8.0;

interface IStringUtilsV1 {
    function base64Encode(bytes memory data) external pure returns (string memory);

    function base64EncodeJson(bytes memory data) external pure returns (string memory);

    function base64EncodeSvg(bytes memory data) external pure returns (string memory);

    function numberToString(uint256 value) external pure returns (string memory);

    function addressToString(address account) external pure returns(string memory);

    function split(string calldata str, string calldata delim) external pure returns(string[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface ICryptoPunksData {
    function punkImageSvg(uint16 punkId) external view returns (string memory);
    function punkAttributes(uint16 punkId) external view returns (string memory);
}