// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "Ownable.sol";
import "Version.sol";

/*
@@author Satish Terala
Registry service to hold assets registered with tcap
*/

contract AssetRegistry is Ownable, Version {
    //capture the basic information required for the asset.
    struct Asset {
        address issuer;
        string assetSymbol;
        string assetShortURL;
        string assetId;
    }

    uint[] private assetIds;
    mapping(string => Asset) private records;

    event AssetDeletedFromRegistry(address indexed owner, string indexed assetSymbol);
    event AssetAddedToRegistry(string indexed assetId, string indexed assetSymbol, address owner);

    function addAsset(string calldata _assetSymbol, string calldata _assetShortURL, address _issuer, string calldata _assetId) assetNotExists(_assetId) external onlyOwner returns (bool){
        records[_assetId].assetId = _assetId;
        records[_assetId].issuer = _issuer;
        records[_assetId].assetSymbol = _assetSymbol;
        records[_assetId].assetShortURL = _assetShortURL;
        emit AssetAddedToRegistry(_assetId, _assetSymbol, _issuer);
        return true;

    }

    function removeAsset(string calldata _assetId) assetExists(_assetId) external onlyOwner {
        bytes memory assetSymBytes = bytes(records[_assetId].assetSymbol);
        if (assetSymBytes.length != 0) {
            address owner = records[_assetId].issuer;
            string memory symbol = records[_assetId].assetSymbol;
            delete records[_assetId];
            emit AssetDeletedFromRegistry(owner, symbol);
        }

    }

    function getAssetIssuer(string calldata _assetId) assetExists(_assetId) public view returns (address){
        return records[_assetId].issuer;
    }

    function getAssetSymbol(string calldata _assetId) assetExists(_assetId) public view returns (string memory){
        return records[_assetId].assetSymbol;
    }

    function getAssetShortURL(string calldata _assetId) assetExists(_assetId) public view returns (string memory){
        return records[_assetId].assetShortURL;
    }

    function assetIdExists(string calldata _assetId) view public returns (bool){
        bytes memory assetSymBytes = bytes(records[_assetId].assetSymbol);
        return assetSymBytes.length > 0;
    }



    modifier assetExists(string calldata _assetId) {
        bytes memory assetSymBytes = bytes(records[_assetId].assetSymbol);
        require(assetSymBytes.length > 0, "Invalid asset id");
        _;
    }

    modifier assetNotExists(string calldata _assetId) {
        bytes memory assetSymBytes = bytes(records[_assetId].assetSymbol);
        require(assetSymBytes.length == 0, "Duplicate asset Id");
        _;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "Ownable.sol";

contract Version is Ownable {

    string private  version = "0.0.1";

    function setContractVersion(string calldata _version) public onlyOwner {
        version = _version;
    }

    function getContractVersion() public returns (string memory){
        return version;
    }


}