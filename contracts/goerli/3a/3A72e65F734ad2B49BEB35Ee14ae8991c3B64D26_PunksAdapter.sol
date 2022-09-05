// SPDX-License-Identifier: UNLICENSED
/// @title PunksAdapter
/// @notice Punks Adapter
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
import "@cyberpnk/solidity-library/contracts/DestroyLockable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@cyberpnk/solidity-library/contracts/ICryptoPunksData.sol";
import "@cyberpnk/solidity-library/contracts/ICryptoPunksMarket.sol";
// import "hardhat/console.sol";

contract PunksAdapter is Ownable, DestroyLockable {
    IStringUtilsV2 public stringUtils;
    ICryptoPunksData public cryptoPunksData;
    ICryptoPunksMarket public cryptoPunksMarket;
    address public cryptoPunksDataContract;
    address public cryptoPunksMarketContract;
    string public name = "Punks";

    constructor(address stringUtilsContract, address _cryptoPunksDataContract, address _cryptoPunksMarketContract) {
        stringUtils = IStringUtilsV2(stringUtilsContract);
        cryptoPunksData = ICryptoPunksData(_cryptoPunksDataContract);
        cryptoPunksMarket = ICryptoPunksMarket(_cryptoPunksMarketContract);
        cryptoPunksDataContract = _cryptoPunksDataContract;
        cryptoPunksMarketContract = _cryptoPunksMarketContract;
    }

    function getSvg(uint256 tokenId) public view returns (string memory) {
        bytes memory imageBytes = bytes(cryptoPunksData.punkImageSvg(uint16(tokenId)));
        return stringUtils.substr(imageBytes, 24, imageBytes.length);
    }

    function getDataUriSvg(uint256 tokenId) external view returns (string memory) {
        return cryptoPunksData.punkImageSvg(uint16(tokenId));
    }

    function getDataUriBase64(uint256 tokenId) external view returns (string memory) {
        return stringUtils.base64EncodeSvg(bytes(getSvg(tokenId)));
    }

    function getEmbeddableSvg(uint256 tokenId) external view returns (string memory) {
        return getSvg(tokenId);
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return cryptoPunksMarket.punkIndexToAddress(uint16(tokenId));
    }

    function getTraitsJsonValue(uint256 tokenId) external view returns(string memory) {
        string memory traitsBytes = cryptoPunksData.punkAttributes(uint16(tokenId));

        string[] memory traits = stringUtils.split(traitsBytes, ",");
        bytes memory traitsStr = "";
        uint len = traits.length;
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

        return string(abi.encodePacked('[', traitsStr, ']'));
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
/// @title ICryptoPunksMarket
/// @notice ICryptoPunksMarket

pragma solidity ^0.8.13;

interface ICryptoPunksMarket {
    function punkIndexToAddress(uint) external view returns(address);

    function name() external view returns (string memory);

    function punksOfferedForSale(uint id) external view returns (bool isForSale, uint punkIndex, address seller, uint minValue, address onlySellTo);

    function totalSupply() external view returns (uint);

    function decimals() external view returns (uint8);

    function imageHash() external view returns (string memory);

    function nextPunkIndexToAssign() external view returns (uint);

    function standard() external view returns (string memory);

    function balanceOf(address) external view returns (uint);

    function symbol() external view returns (string memory);

    function numberOfPunksToReserve() external view returns (uint);

    function numberOfPunksReserved() external view returns (uint);

    function punksRemainingToAssign() external view returns (uint);

    function pendingWithdrawals(address) external view returns (uint);

    function reservePunksForOwner(uint maxForThisRun) external;

    function withdraw() external;

    function buyPunk(uint id) external payable;

    function transferPunk(address to, uint id) external;

    function offerPunkForSaleToAddress(uint id, uint minSalePriceInWei, address to) external;

    function offerPunkForSale(uint id, uint minSalePriceInWei) external;

    function getPunk(uint id) external;

    function punkNoLongerForSale(uint id) external;

    function enterBidForPunk(uint punkIndex) external payable;

    function acceptBidForPunk(uint punkIndex, uint minPrice) external;

}

// SPDX-License-Identifier: UNLICENSED
/// @title DestroyLockable
/// @notice Contract can be destroyed, but destroy can be disabled (but not re-enabled).
/// @author CyberPnk <[email protected]>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____
//  __________________/\/\/\/\________________________________________________________________________________
// __________________________________________________________________________________________________________

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract DestroyLockable is Ownable {
    bool public isDestroyDisabled = false;

    // Irreversible.
    function disableDestroy() public onlyOwner {
        isDestroyDisabled = true;
    }

    // In case there's a really bad mistake, but eventually disabled
    function destroy() public onlyOwner {
        require(!isDestroyDisabled, "Disabled");
        selfdestruct(payable(owner()));
    }

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