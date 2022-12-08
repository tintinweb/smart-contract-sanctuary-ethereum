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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "./FeeDistributor.sol";

contract ETHFeeDistributor is FeeDistributor {
    constructor(
        address _hubBridge,
        address _treasury,
        address _publicGoods,
        uint256 _minPublicGoodsBps,
        uint256 _fullPoolSize,
        uint256 _maxBundleFee,
        uint256 _maxBundleFeeBPS
    )
        FeeDistributor(
            _hubBridge,
            _treasury,
            _publicGoods,
            _minPublicGoodsBps,
            _fullPoolSize,
            _maxBundleFee,
            _maxBundleFeeBPS
        )
    {}

    function transfer(address to, uint256 amount) internal override {
        (bool success, ) = to.call{value: amount}("");
        if (!success) revert TransferFailed(to, amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

// Each Spoke has its own FeeDistributor instance
abstract contract FeeDistributor is Ownable {
    /* errors */
    error TransferFailed(address to, uint256 amount);
    error OnlyHubBridge(address msgSender);
    error PendingFeesTooHigh(uint256 pendingAmount, uint256 pendingFeeBatchSize);
    error NoZeroAddress();
    error InvalidPublicGoodsBps(uint256 publicGoodsBps);
    error PendingFeeBatchSizeTooLow(uint256 pendingFeeBatchSize);
    error PoolNotFull(uint256 poolSize, uint256 fullPoolSize);
    error NoZeroRelayWindow();

    /* events */
    event FeePaid(address indexed to, uint256 amount, uint256 feesCollected);
    event ExcessFeesSkimmed(uint256 publicGoodsAmount, uint256 treasuryAmount);
    event TreasurySet(address indexed treasury);
    event PublicGoodsSet(address indexed publicGoods);
    event FullPoolSizeSet(uint256 fullPoolSize);
    event PublicGoodsBpsSet(uint256 publicGoodsBps);
    event PendingFeeBatchSizeSet(uint256 pendingFeeBatchSize);
    event RelayWindowSet(uint256 relayWindow);
    event MaxBundleFeeSet(uint256 maxBundleFee);
    event MaxBundleFeeBPSSet(uint256 maxBundleFeeBPS);

    /* constants */
    uint256 constant BASIS_POINTS = 10_000;
    uint256 constant ONE_HUNDRED_PERCENT_BPS = 1_000_000;
    address public immutable hubBridge;
    uint256 public immutable minPublicGoodsBps;

    /* config */
    address public treasury;
    address public publicGoods;
    uint256 public fullPoolSize;
    uint256 public publicGoodsBps;
    uint256 public pendingFeeBatchSize;
    uint256 public relayWindow = 12 hours;
    uint256 public maxBundleFee;
    uint256 public maxBundleFeeBPS;

    /* state */
    uint256 public virtualBalance;

    modifier onlyHubBridge() {
        if (msg.sender != hubBridge) {
            revert OnlyHubBridge(msg.sender);
        }
        _;
    }

    constructor(
        address _hubBridge,
        address _treasury,
        address _publicGoods,
        uint256 _minPublicGoodsBps,
        uint256 _fullPoolSize,
        uint256 _maxBundleFee,
        uint256 _maxBundleFeeBPS
    ) {
        hubBridge = _hubBridge;
        treasury = _treasury;
        publicGoods = _publicGoods;
        minPublicGoodsBps = _minPublicGoodsBps;
        publicGoodsBps = _minPublicGoodsBps;
        fullPoolSize = _fullPoolSize;
        maxBundleFee = _maxBundleFee;
        maxBundleFeeBPS = _maxBundleFeeBPS;
    }

    receive() external payable {}

    function transfer(address to, uint256 amount) internal virtual;

    function getBalance() private view returns (uint256) {
        return address(this).balance;
    }

    function payFee(address to, uint256 relayWindowStart, uint256 feesCollected) external onlyHubBridge {
        uint256 relayReward = 0;
        if (block.timestamp >= relayWindowStart) {
            relayReward = getRelayReward(relayWindowStart, feesCollected);
        } else {
            return;
        }

        uint256 maxFee = feesCollected * maxBundleFeeBPS / BASIS_POINTS;
        if (maxFee > maxBundleFee) maxFee = maxBundleFee;
        if (relayReward > maxFee) relayReward = maxFee;

        uint256 balance = getBalance();
        uint256 pendingAmount = virtualBalance + feesCollected - balance;
        if (pendingAmount > pendingFeeBatchSize) {
            revert PendingFeesTooHigh(pendingAmount, pendingFeeBatchSize);
        }

        virtualBalance = virtualBalance + feesCollected - relayReward;

        emit FeePaid(to, relayReward, feesCollected);

        transfer(to, relayReward);
    }

    function getRelayReward(uint256 relayWindowStart, uint256 feesCollected) public view returns (uint256) {
        return (block.timestamp - relayWindowStart) * feesCollected / relayWindow;
    }

    function skimExcessFees() external onlyOwner {
        uint256 poolSize = getBalance();
        if (poolSize < fullPoolSize) revert PoolNotFull(poolSize, fullPoolSize);
        uint256 excessAmount = poolSize - fullPoolSize;
        uint256 publicGoodsAmount = excessAmount * publicGoodsBps / BASIS_POINTS;
        uint256 treasuryAmount = excessAmount - publicGoodsAmount;

        virtualBalance -= excessAmount;

        emit ExcessFeesSkimmed(publicGoodsAmount, treasuryAmount);

        transfer(publicGoods, publicGoodsAmount);
        transfer(treasury, treasuryAmount);
    }

    /**
     * Setters
     */

    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert NoZeroAddress();

        treasury = _treasury;

        emit TreasurySet(_treasury);
    }

    function setPublicGoods(address _publicGoods) external onlyOwner {
        if (_publicGoods == address(0)) revert NoZeroAddress();

        publicGoods = _publicGoods;

        emit PublicGoodsSet(_publicGoods);
    }

    function setFullPoolSize(uint256 _fullPoolSize) external onlyOwner {
        fullPoolSize = _fullPoolSize;

        emit FullPoolSizeSet(_fullPoolSize);
    }

    function setPublicGoodsBps(uint256 _publicGoodsBps) external onlyOwner {
        if (_publicGoodsBps < minPublicGoodsBps || _publicGoodsBps > ONE_HUNDRED_PERCENT_BPS) {
            revert InvalidPublicGoodsBps(_publicGoodsBps);
        }
        publicGoodsBps = _publicGoodsBps;

        emit PublicGoodsBpsSet(_publicGoodsBps);
    }

    // @notice When lowering pendingFeeBatchSize, the Spoke pendingFeeBatchSize should be lowered first and
    // all fees should be exited before lowering pendingFeeBatchSize on the Hub.
    // @notice When raising pendingFeeBatchSize, both the Hub and Spoke pendingFeeBatchSize can be set at the
    // same time.
    function setPendingFeeBatchSize(uint256 _pendingFeeBatchSize) external onlyOwner {
        uint256 balance = getBalance();
        uint256 pendingAmount = virtualBalance - balance; // ToDo: Handle balance greater than fee pool
        if (_pendingFeeBatchSize < pendingAmount) revert PendingFeeBatchSizeTooLow(_pendingFeeBatchSize);

        pendingFeeBatchSize = _pendingFeeBatchSize;

        emit PendingFeeBatchSizeSet(_pendingFeeBatchSize);
    }

    function setRelayWindow(uint256 _relayWindow) external onlyOwner {
        if (_relayWindow == 0) revert NoZeroRelayWindow();
        relayWindow = _relayWindow;
        emit RelayWindowSet(_relayWindow);
    }

    function setMaxBundleFee(uint256 _maxBundleFee) external onlyOwner {
        maxBundleFee = _maxBundleFee;
        emit MaxBundleFeeSet(_maxBundleFee);
    }

    function setMaxBundleFeeBPS(uint256 _maxBundleFeeBPS) external onlyOwner {
        maxBundleFeeBPS = _maxBundleFeeBPS;
        emit MaxBundleFeeBPSSet(_maxBundleFeeBPS);
    }
}