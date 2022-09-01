// SPDX-License-Identifier: UNLICENSED
/// @title PunksWrapperProxyCollectionRenderer
/// @notice Renders PunksWrapperProxyCollection
/// @author CyberPnk <[email protected]>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     

pragma solidity ^0.8.16;

import "@cyberpnk/solidity-library/contracts/IStringUtilsV3.sol";
import "./ICryptoPunksData.sol";
// import "hardhat/console.sol";

contract PunksWrapperProxyCollectionRenderer {
    IStringUtilsV3 stringUtils;
    ICryptoPunksData cryptoPunksData;

    constructor(address stringUtilsContract, address cryptoPunksDataContract) {
        stringUtils = IStringUtilsV3(stringUtilsContract);
        cryptoPunksData = ICryptoPunksData(cryptoPunksDataContract);
    }

    function getEmptyWrapperImage(uint16) public pure returns(bytes memory) {
        return abi.encodePacked('<svg width="640" height="640" version="1.1" viewBox="0 0 640 640" xmlns="http://www.w3.org/2000/svg"></svg>');
    }

    function getImage(uint16 punkId) public view returns(bytes memory) {
        bytes memory imageBytes = bytes(cryptoPunksData.punkImageSvg(punkId));
        string memory imageBytesNoHeader = stringUtils.substr(imageBytes, 24, imageBytes.length);

        return abi.encodePacked('<svg width="640" height="640" version="1.1" viewBox="0 0 640 640" xmlns="http://www.w3.org/2000/svg">' , 
            imageBytesNoHeader, 
        '</svg>');
    }

    function getTraitsJsonValue(uint256 tokenId, bool isEmptyWrapper) internal view returns(string memory) {
        string memory traitsBytes = cryptoPunksData.punkAttributes(uint16(tokenId));

        string[] memory traits = stringUtils.split(traitsBytes, ",");
        bytes memory traitsStr = "";
        uint len = traits.length;
        string memory wrapperTrait = isEmptyWrapper ? '{"trait_type":"Wrapper","value":"Empty"},' : '{"trait_type":"Wrapper","value":"Full"},';
        for (uint i = 0; i < len; i++) {
            bytes memory trait = bytes(traits[i]);
             string memory traitToUse = i == 0 ? string(trait) : stringUtils.substr(trait, 1, trait.length);
            traitsStr = abi.encodePacked(traitsStr, 
                '{'
                    '"trait_type":"', traitToUse, '",'
                    '"value":"', traitToUse, '"'
                '}', 
                i == len - 1 ? '' : ','
            );
        }

        return string(abi.encodePacked('[', wrapperTrait, traitsStr, ']'));
    }


    function getTokenURI(uint256 punkId, bool isEmptyWrapper) public view returns (string memory) {
        string memory strTokenId = stringUtils.numberToString(punkId);

        bytes memory imageBytes = isEmptyWrapper ? getEmptyWrapperImage(uint16(punkId)) : getImage(uint16(punkId));
        string memory image = stringUtils.base64EncodeSvg(abi.encodePacked(imageBytes));

        string memory traitsJsonValue = getTraitsJsonValue(punkId, isEmptyWrapper);

        string memory emptyWrapperText = isEmptyWrapper ? " (Empty wrapper, cannot transfer)" : "";

        string memory emptyWrapperDescription = isEmptyWrapper ? " Empty wrappers are created when the underlying punk is sold separately from the wrapper. Empty wrappers can be safely discarded, and the punk can then be wrapped again." : "";

        bytes memory description = abi.encodePacked('"Wrapped Punk #',
            strTokenId, 
            emptyWrapperText,
            '. that proxies calls to the CryptoPunksMarket contract.', 
            emptyWrapperDescription, 
            '"');

        bytes memory json = abi.encodePacked(string(abi.encodePacked(
            '{'
                '"title": "PWP #', strTokenId, emptyWrapperText, '",'
                '"name": "Proxying Wrapped Punk #', strTokenId, emptyWrapperText, '",'
                '"image": "', image, '",'
                '"traits":', traitsJsonValue, ','
                '"description": ', description, 
            '}'
        )));

        return stringUtils.base64EncodeJson(json);
    }

    function getContractURI() public view returns(string memory) {
        return stringUtils.base64EncodeJson(abi.encodePacked(
        '{'
            '"name": "Proxying Wrapped Punks",'
            '"description": "Wrapped Punks that proxy calls to the CryptoPunksMarket contract.  This allows you to offer for sale the same punk in the punks market at the same time as in any other ERC721 market.  Empty wrappers are created when the underlying punk is sold separately from the wrapper. Empty wrappers can be safely discarded, and the punk can then be wrapped again to reactivate the proxy.",'
            '"image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYBAMAAAASWSDLAAAAGFBMVEUAAAAAAADbsYCmbizFIRDSnWD/2SanbiweKgy5AAAAAXRSTlMAQObYZgAAAGNJREFUGNOtzbENgDAMBEB7A78l6PNCoocVmIAN2H8JQmJcgOj4KpeXbfklClg8IagR9O/xwtFKZBoUZLEOUydpGmBCxeeFq0nf7mXnkIdYc0Mf8K9m2hLiZJFEjMQhSKYWb5zIrArsT3XnIAAAAABJRU5ErkJggg==",'
            '"seller_fee_basis_points": 0,'
            '"external_link": "https://pwp.cyberpnk.win"'
        '}'));
    }
}

// SPDX-License-Identifier: UNLICENSED
/// @title IStringUtilsV3
/// @notice IStringUtilsV3
/// @author CyberPnk <[email protected]>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____
//  __________________/\/\/\/\________________________________________________________________________________
// __________________________________________________________________________________________________________

import "./IStringUtilsV2.sol";

pragma solidity ^0.8.13;

interface IStringUtilsV3 is IStringUtilsV2 {
    function base64Decode(bytes memory data) external pure returns (bytes memory);
    function extractFromTo(string memory str, string memory needleStart, string memory needleEnd) external pure returns(string memory);
    function extractFrom(string memory str, string memory needleStart) external pure returns(string memory);
    function removeSuffix(string memory str, string memory suffix) external pure returns(string memory);
    function removePrefix(string memory str, string memory prefix) external pure returns(string memory);
}

// SPDX-License-Identifier: MIT
/// @title ICryptoPunksData
/// @notice ICryptoPunksData
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

interface ICryptoPunksData {
    function punkImageSvg(uint16 punkId) external view returns (string memory);
    function punkAttributes(uint16 punkId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
/// [MIT License]
/// @title StringUtilsV2

pragma solidity ^0.8.13;

interface IStringUtilsV2 {
    function base64Encode(bytes memory data) external pure returns (string memory);

    function base64EncodeJson(bytes memory data) external pure returns (string memory);

    function base64EncodeSvg(bytes memory data) external pure returns (string memory);

    function numberToString(uint256 value) external pure returns (string memory);

    function addressToString(address account) external pure returns(string memory);

    function split(string calldata str, string calldata delim) external pure returns(string[] memory);

    function substr(bytes calldata str, uint startIndexInclusive, uint endIndexExclusive) external pure returns(string memory);

    function substrStart(bytes calldata str, uint endIndexExclusive) external pure returns(string memory);
}