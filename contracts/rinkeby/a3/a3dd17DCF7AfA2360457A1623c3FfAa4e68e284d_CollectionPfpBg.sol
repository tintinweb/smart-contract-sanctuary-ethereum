// SPDX-License-Identifier: UNLICENSED
/// @title CollectionPfpBg
/// @notice Collection Pfp Bg
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

import "@cyberpnk/solidity-library/contracts/IStringUtilsV2.sol";
import "./INftAdapter.sol";
import "./IPfpBg.sol";
// import "hardhat/console.sol";

contract CollectionPfpBg {
    IStringUtilsV2 stringUtils;
    address public pfpBgContract;
    address public pfpAdapterContract;
    IPfpBg pfpBg;
    INftAdapter pfpAdapter;

    constructor(address stringUtilsContract, address _pfpBgContract, address _pfpAdapterContract) {
        stringUtils = IStringUtilsV2(stringUtilsContract);
        pfpBg = IPfpBg(_pfpBgContract);
        pfpBgContract = _pfpBgContract;
        pfpAdapter = INftAdapter(_pfpAdapterContract);
        pfpAdapterContract = _pfpAdapterContract;
    }

    function getImage(uint256 tokenId) public view returns(bytes memory) {
        string memory pfpSvg = pfpAdapter.getEmbeddableSvg(tokenId);
        address pfpOwner = ownerOf(tokenId);
        string memory bg = pfpBg.getBgSvg(pfpOwner);

        return abi.encodePacked(
'<svg width="640" height="640" version="1.1" viewBox="0 0 640 640" xmlns="http://www.w3.org/2000/svg">',
  bg,
  pfpSvg,
'</svg>'
        );
    }

    function getSvg(uint256 tokenId) public view returns (string memory) {
        return string(getImage(tokenId));
    }

    function getDataUriSvg(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked("data:image/svg+xml;utf8,", getImage(tokenId)));
    }

    function getDataUriBase64(uint256 tokenId) external view returns (string memory) {
        return stringUtils.base64EncodeSvg(getImage(tokenId));
    }

    function getEmbeddableSvg(uint256 tokenId) external view returns (string memory) {
        return getSvg(tokenId);
    }

    function getTraitsJsonValue(uint256 tokenId) external view returns(string memory) {
        return pfpAdapter.getTraitsJsonValue(tokenId);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        string memory strTokenId = stringUtils.numberToString(tokenId);

        bytes memory imageBytes = getImage(tokenId);
        string memory image = stringUtils.base64EncodeSvg(abi.encodePacked(imageBytes));

        string memory traitsJsonValue = pfpAdapter.getTraitsJsonValue(tokenId);
        string memory name = pfpAdapter.name();

        bytes memory json = abi.encodePacked(
            '{'
                '"title": "PfpBg for ',name,' #', strTokenId, '",'
                '"name": "PfpBg for ', name,' #', strTokenId, '",'
                '"image": "', image, '",'
                '"traits":', traitsJsonValue, ','
                '"description": "PfpBg for ', name,' #', strTokenId,'."'
            '}'
        );

        return stringUtils.base64EncodeJson(json);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return pfpAdapter.ownerOf(tokenId);
    }
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

// SPDX-License-Identifier: UNLICENSED
/// @title INftAdapter
/// @notice INftAdapter
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

interface INftAdapter {
    function getSvg(uint256 tokenId) external view returns(string memory);
    function getDataUriSvg(uint256 tokenId) external view returns(string memory);
    function getDataUriBase64(uint256 tokenId) external view returns(string memory);
    function getEmbeddableSvg(uint256 tokenId) external view returns(string memory);
    function ownerOf(uint256 tokenId) external view returns (address);
    function getTraitsJsonValue(uint256 tokenId) external view returns(string memory);
    function name() external view returns(string memory);
}

// SPDX-License-Identifier: UNLICENSED
/// @title IPfpBg
/// @notice IPfpBg
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

interface IPfpBg {
    function getBgSvg(address pfpOwner) external view returns(string memory);
}