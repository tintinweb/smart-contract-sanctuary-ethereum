//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAssetRegistry.sol";

contract AssetsRegistry is Ownable, IAssetRegistry {
    // asset type -> count of assets
    //TODO Delete?
    mapping(uint256 => uint256) public assetsTotalAmount;
    // asset type -> set of weights
    mapping(uint256 => uint256[]) public assetsUniqueWeights;
    
    mapping(uint256 => mapping(uint256 => uint256)) public assetsUniqueWeightsIndexes;
    // asset type -> total weight
    mapping(uint256 => uint256) public assetsTotalWeight;
    // asset type -> array of assets
    mapping(uint256 => Asset[]) public assets;


    constructor() {
    }

    function setAssets(uint _assetId, string[] memory _assets, uint256[] memory _weightSum, uint256[] memory _weights, string[] memory _names) external onlyOwner {
        require(_assets.length == _weights.length && _names.length == _assets.length && _weightSum.length == _assets.length);
        assetsTotalAmount[_assetId] = 0;
        uint _previousWeight;
        for(uint256 i; i < _assets.length; i++) {
            assets[_assetId].push(Asset(false, _assets[i], _weightSum[i], _weights[i], _names[i], i));
            assetsTotalAmount[_assetId]++;

            if(_weights[i] != _previousWeight) {
                _previousWeight = _weights[i];
                assetsUniqueWeightsIndexes[_assetId][_weights[i]] = assetsUniqueWeights[_assetId].length;
                assetsUniqueWeights[_assetId].push(_weights[i]);
            }
        }
        assetsTotalWeight[_assetId] = _weightSum[_assets.length-1];
    }

    function uniqueWeightsForTypeIndexes(uint _assetId, uint _weights) public view override returns (uint256) {
        return assetsUniqueWeightsIndexes[_assetId][_weights];
    }

    function uniqueWeightsForType(uint _assetId) public view override returns (uint256[] memory){
        return assetsUniqueWeights[_assetId];
    }

    function assetsForType(uint _assetId) public view override returns (Asset[] memory){
        return assets[_assetId];
    }

    function totalWeightForType(uint _assetId) public view override returns (uint256){
        return assetsTotalWeight[_assetId];
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface IAssetRegistry {

    struct Asset {
        bool hasIt;
        string asset;
        uint256 weightSum;
        uint256 weight;
        string name;
        uint256 assetIndex;
    }

    function uniqueWeightsForType(uint _assetId) external view returns (uint256[] memory);
    
    function uniqueWeightsForTypeIndexes(uint _assetId, uint _weights) external view returns (uint256);

    function assetsForType(uint _assetId) external view returns (Asset[] memory);

    function totalWeightForType(uint _assetId) external view returns (uint256);
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