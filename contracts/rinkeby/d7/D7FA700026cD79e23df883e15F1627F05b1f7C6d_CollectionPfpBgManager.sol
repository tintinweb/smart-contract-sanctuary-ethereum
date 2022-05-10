// SPDX-License-Identifier: UNLICENSED
/// @title CollectionPfpBgManager
/// @notice Collection Pfp Bg Manager
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

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CollectionPfpBg.sol";
// import "hardhat/console.sol";

contract CollectionPfpBgManager is Ownable {
    address public stringUtilsContract;
    address public pfpBgContract;
    
    mapping (address => address) public pfpToCollectionPfpBg;

    event CreateCollectionPfpBg(address indexed pfpContract, address indexed pfpAdapterContract);

    constructor(address _stringUtilsContract, address _pfpBgContract) {
        stringUtilsContract = _stringUtilsContract;
        pfpBgContract = _pfpBgContract;
    }

    function createCollectionPfpBgContract(address pfpContract, address pfpAdapterContract) external onlyOwner {
        CollectionPfpBg newContract = new CollectionPfpBg(stringUtilsContract, pfpBgContract, pfpAdapterContract);
        pfpToCollectionPfpBg[pfpContract] = address(newContract);
        emit CreateCollectionPfpBg(pfpContract, address(newContract));
    }

    function removeCollectionPfpBgContract(address pfpContract) external onlyOwner {
        pfpToCollectionPfpBg[pfpContract] = address(0);
        emit CreateCollectionPfpBg(pfpContract, address(0));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

    function getTokenURI(uint256 tokenId) external view returns (string memory) {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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