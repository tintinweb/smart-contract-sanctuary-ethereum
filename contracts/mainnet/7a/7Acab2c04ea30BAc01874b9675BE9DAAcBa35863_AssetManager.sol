// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AssetManager is Ownable {
    uint256 public totalEmpAssets;
    mapping(uint256 => Asset) public idToVerifiedEmps;

    uint256 public totalSwapPairAssets;
    mapping(uint256 => Asset) public idToVerifiedSwapPairs;

    uint256 public totalStakingRewardAssets;
    mapping(uint256 => Asset) public idToVerifiedStakingRewards;

    enum Type {
        Emp,
        SwapPair,
        StakingReward
    }

    enum Status {
        Closed,
        Paused,
        Open
    }

    struct Asset {
        address addr;
        Status status;
    }

    // EMPs
    function addEmp(address _asset) external onlyOwner {
        require(_asset != address(0), "AssetManager: ZERO_ADDRESS");
        totalEmpAssets = totalEmpAssets + 1;
        idToVerifiedEmps[totalEmpAssets] = Asset(_asset, Status.Open);
        emit Added(Type.Emp, _asset, totalEmpAssets);
    }

    function pauseEmp(uint256 id) external onlyOwner {
        require(
            idToVerifiedEmps[id].status == Status.Open,
            "AssetManager: ASSET_NOT_OPEN"
        );
        idToVerifiedEmps[id].status = Status.Paused;
        emit Paused(Type.Emp, idToVerifiedEmps[id].addr, id);
    }

    function unpauseEmp(uint256 id) external onlyOwner {
        require(
            idToVerifiedEmps[id].status == Status.Paused,
            "AssetManager: ASSET_NOT_PAUSED"
        );
        idToVerifiedEmps[id].status = Status.Open;
        emit Unpaused(Type.Emp, idToVerifiedEmps[id].addr, id);
    }

    function closeEmp(uint256 id) external onlyOwner {
        require(
            idToVerifiedEmps[id].addr != address(0),
            "AssetManager: ZERO_ADDRESS"
        );
        require(
            idToVerifiedEmps[id].status != Status.Closed,
            "AssetManager: ASSET_ALREADY_CLOSED"
        );
        idToVerifiedEmps[id].status = Status.Closed;
        emit Closed(Type.Emp, idToVerifiedEmps[id].addr, id);
    }

    // Swap Pairs
    function addSwapPair(address _asset) external onlyOwner {
        require(_asset != address(0), "AssetManager: ZERO_ADDRESS");
        totalSwapPairAssets = totalSwapPairAssets + 1;
        idToVerifiedSwapPairs[totalSwapPairAssets] = Asset(_asset, Status.Open);
        emit Added(Type.SwapPair, _asset, totalSwapPairAssets);
    }

    function pauseSwapPair(uint256 id) external onlyOwner {
        require(
            idToVerifiedSwapPairs[id].status == Status.Open,
            "AssetManager: ASSET_NOT_OPEN"
        );
        idToVerifiedSwapPairs[id].status = Status.Paused;
        emit Paused(Type.SwapPair, idToVerifiedSwapPairs[id].addr, id);
    }

    function unpauseSwapPair(uint256 id) external onlyOwner {
        require(
            idToVerifiedSwapPairs[id].status == Status.Paused,
            "AssetManager: ASSET_NOT_PAUSED"
        );
        idToVerifiedSwapPairs[id].status = Status.Open;
        emit Unpaused(Type.SwapPair, idToVerifiedSwapPairs[id].addr, id);
    }

    function closeSwapPair(uint256 id) external onlyOwner {
        require(
            idToVerifiedSwapPairs[id].addr != address(0),
            "AssetManager: ZERO_ADDRESS"
        );
        require(
            idToVerifiedSwapPairs[id].status != Status.Closed,
            "AssetManager: ASSET_ALREADY_CLOSED"
        );
        idToVerifiedSwapPairs[id].status = Status.Closed;
        emit Closed(Type.SwapPair, idToVerifiedSwapPairs[id].addr, id);
    }

    // Staking Rewards
    function addStakingReward(address _asset) external onlyOwner {
        require(_asset != address(0), "AssetManager: ZERO_ADDRESS");
        totalStakingRewardAssets = totalStakingRewardAssets + 1;
        idToVerifiedStakingRewards[totalStakingRewardAssets] = Asset(
            _asset,
            Status.Open
        );
        emit Added(Type.StakingReward, _asset, totalStakingRewardAssets);
    }

    function pauseStakingReward(uint256 id) external onlyOwner {
        require(
            idToVerifiedStakingRewards[id].status == Status.Open,
            "AssetManager: ASSET_NOT_OPEN"
        );
        idToVerifiedStakingRewards[id].status = Status.Paused;
        emit Paused(
            Type.StakingReward,
            idToVerifiedStakingRewards[id].addr,
            id
        );
    }

    function unpauseStakingReward(uint256 id) external onlyOwner {
        require(
            idToVerifiedStakingRewards[id].status == Status.Paused,
            "AssetManager: ASSET_NOT_PAUSED"
        );
        idToVerifiedStakingRewards[id].status = Status.Open;
        emit Unpaused(
            Type.StakingReward,
            idToVerifiedStakingRewards[id].addr,
            id
        );
    }

    function closeStakingReward(uint256 id) external onlyOwner {
        require(
            idToVerifiedStakingRewards[id].addr != address(0),
            "AssetManager: ZERO_ADDRESS"
        );
        require(
            idToVerifiedStakingRewards[id].status != Status.Closed,
            "AssetManager: ASSET_ALREADY_CLOSED"
        );
        idToVerifiedStakingRewards[id].status = Status.Closed;
        emit Closed(
            Type.StakingReward,
            idToVerifiedStakingRewards[id].addr,
            id
        );
    }

    /* ========== EVENTS ========== */

    event Added(
        Type indexed assetType,
        address indexed assetAddress,
        uint256 assetId
    );
    event Paused(
        Type indexed assetType,
        address indexed assetAddress,
        uint256 assetId
    );
    event Unpaused(
        Type indexed assetType,
        address indexed assetAddress,
        uint256 assetId
    );
    event Closed(
        Type indexed assetType,
        address indexed assetAddress,
        uint256 assetId
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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