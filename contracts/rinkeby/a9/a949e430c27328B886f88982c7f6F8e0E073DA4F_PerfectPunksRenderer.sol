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

pragma solidity ^0.8.0;

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

        return abi.encodePacked(abi.encodePacked(
"<svg width='640' height='640' version='1.1' viewBox='0 0 640 640' xmlns='http://www.w3.org/2000/svg'>"
  "<style>text {font-family: monospace; fill: black; font-weight: bold;font-size:6em;}</style>",
  "<text x='120' y='240'>Punk #", strPunkId, "</text>"
  "<text x='180' y='380'>V1 + V2</text>"
"</svg>"
        ));
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
            '"description": "Joins together a wrapped v1 punk and a wrapped v2 punk so they can be traded in a single unit.  It can be unwrapped into their respective wrapped v1 and v2 punks.",'
            '"image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAJYAAACMBAMAAABsYk0sAAAABGdBTUEAALGPC%2FxhBQAAAAFzUkdCAK7OHOkAAAAJcEhZcwAADsIAAA7CARUoSoAAAAAtUExURf%2F%2F%2FwAAACgoKIKCgoyMjBISEmRkZJ%2Bfnzk5Oc3NzfT09E9PT%2BTk5HNzc7W1tcgb3MgAAAGmSURBVGje7ZQxS0JRFMePqZml4t%2FUlHTwDhG0GLQFUeQH0OoL2NAW2Ba0aLQEDUlbQ9jYECgNrQ4F0dTsZN%2Bke7WevuLdHCP%2BP3i887jn%2FTzvnHsVIYQQQgghhBBCCCGE%2FBlmJ0h5ncgUOdn9NSfcwJ5leV8tt%2FxKXQQqmHct3I3CF6WKcqpW5AhA27tovVrzAXl9uV2NvhNuAfGYTpxF8qaw4F3XMR4kVkUv8PjsduHNCe%2BR7ss6zqLoylTC8pHmHZ%2FRBD1dcpQT8UNCaX1LWVyduEg1bnf5FvWVEenqLJurqRswaOh31%2BYonoauLTv86aTFNZWSkO6D2xU7OMTSQc%2FZLyhKoWyiGdQtrhAuh3WPu%2FRUNenRUMth1ExQyFg3INrNhe%2BuqFLYUefO83t2Dub%2BbNlehtW4af%2FPfhXHHoIZnykyjLz9YNymhyOzufyo5gabtmZ3zQCtgSvp7dLHo27GqYXX1gOLzGDsmqyXSzrof04kYW9%2B9mty492ouD6nCWe6VteVqSCyViptj7%2F%2B5MoJbJiulQz8oyeEEEIIIYQQQsh%2F5QM7yD2dutIcjAAAAABJRU5ErkJggg%3D%3D",'
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