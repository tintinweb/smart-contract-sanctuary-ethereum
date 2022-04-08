/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File interfaces/tokenomics/IMultiplier.sol

pragma solidity ^0.8.13;

interface IMultiplier {
    function getMultiplier() external view returns (uint256);
}


// File interfaces/tokenomics/IInflationManager.sol

pragma solidity ^0.8.13;

interface IInflationManager {
    event TokensClaimed(address indexed pool, uint256 crvAmount, uint256 cncAmount);

    /// @notice allows anyone to claim the CNC tokens for a given pool
    function claimPoolRewards(address pool) external;

    function multiplier() external view returns (IMultiplier);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File interfaces/pools/ILpToken.sol

pragma solidity ^0.8.13;

interface ILpToken is IERC20Metadata {
    function mint(address account, uint256 amount) external returns (uint256);

    function burn(address _owner, uint256 _amount) external returns (uint256);
}


// File interfaces/pools/IRewardManager.sol

pragma solidity ^0.8.13;

interface IRewardManager {
    event ClaimedRewards(uint256 claimedCrv, uint256 claimedCvx);

    struct RewardMeta {
        uint256 earnedIntegral;
        uint256 lastEarned;
        mapping(address => uint256) accountIntegral;
        mapping(address => uint256) accountShare;
    }

    function accountCheckpoint(address account) external;

    function poolCheckpoint() external;

    function addExtraReward(address reward) external returns (bool);

    function addBatchExtraRewards(address[] memory rewards) external;

    function totalCRVClaimed() external view returns (uint256);

    function getClaimableRewards(address account)
        external
        view
        returns (
            uint256 cncRewards,
            uint256 crvRewards,
            uint256 cvxRewards
        );

    function claimEarnings() external returns (uint256);

    function claimPoolEarnings() external;
}


// File interfaces/pools/IConicPool.sol

pragma solidity ^0.8.13;


interface IConicPool {
    event Deposit(address account, uint256 amount);
    event DepositToCurve(uint256 amunt);
    event Withdraw(address account, uint256 amount);
    event NewWeight(address indexed curvePool, uint256 newWeight);
    event NewMaxIdleRatio(uint256 newRatio);
    event TotalUnderlyingUpdated(uint256 oldTotalUnderlying, uint256 newTotalUnderlying);
    event ClaimedRewards(uint256 claimedCrv, uint256 claimedCvx);

    struct PoolWeight {
        address poolAddress;
        uint256 weight;
    }

    function underlying() external view returns (IERC20);

    function lpToken() external view returns (ILpToken);

    function rewardManager() external view returns (IRewardManager);

    function depositFor(address _account, uint256 _amount) external;

    function deposit(uint256 _amount) external;

    function updateTotalUnderlying() external;

    function rebalance() external;

    function exchangeRate() external view returns (uint256);

    function allCurvePools() external view returns (address[] memory);

    function withdraw(uint256 _amount, uint256 _minAmount) external returns (uint256);

    function updateWeights(PoolWeight[] memory poolWeights) external;

    function getWeights() external view returns (PoolWeight[] memory);

    function getAllocatedUnderlying() external view returns (PoolWeight[] memory);

    function renewPenaltyDelay(address account) external;
}


// File interfaces/IController.sol

pragma solidity ^0.8.13;

interface IController {
    event PoolAdded(address indexed pool);
    event PoolRemoved(address indexed pool);
    event NewCurvePoolVerifier(address indexed curvePoolVerifier);

    struct WeightUpdate {
        address conicPoolAddress;
        IConicPool.PoolWeight[] weights;
    }

    function inflationManager() external view returns (address);

    function setInflationManager(address manager) external;

    // pool functions

    function listPools() external view returns (address[] memory);

    function isPool(address poolAddress) external view returns (bool);

    function addPool(address poolAddress) external;

    function removePool(address poolAddress) external;

    function cncToken() external view returns (address);

    function updateWeights(WeightUpdate memory update) external;

    function updateAllWeights(WeightUpdate[] memory weights) external;

    // handler functions

    function convexBooster() external view returns (address);

    function curveHandler() external view returns (address);

    function convexHandler() external view returns (address);

    function curvePoolVerifier() external view returns (address);

    function setConvexBooster(address _convexBooster) external;

    function setCurveHandler(address _curveHandler) external;

    function setConvexHandler(address _convexHandler) external;

    function setCurvePoolVerifier(address _curvePoolVerifier) external;
}


// File interfaces/tokenomics/ICNCToken.sol

pragma solidity ^0.8.13;

interface ICNCToken is IERC20 {
    event MinterAdded(address minter);
    event MinterRemoved(address minter);
    event InitialDistributionMinted(uint256 amount);
    event AirdropMinted(uint256 amount);
    event AMMRewardsMinted(uint256 amount);
    event TreasuryRewardsMinted(uint256 amount);
    event SeedShareMinted(uint256 amount);

    /// @notice mints the initial distribution amount to the distribution contract
    function mintInitialDistribution(address distribution) external;

    /// @notice mints the airdrop amount to the airdrop contract
    function mintAirdrop(address airdropHandler) external;

    /// @notice mints the amm rewards
    function mintAMMRewards(address ammGauge) external;

    /// @notice mints `amount` to `account`
    function mint(address account, uint256 amount) external returns (uint256);

    /// @notice returns a list of all authorized minters
    function listMinters() external view returns (address[] memory);

    /// @notice returns the ratio of inflation already minted
    function inflationMintedRatio() external view returns (uint256);
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File libraries/ScaledMath.sol

pragma solidity ^0.8.13;

library ScaledMath {
    uint256 internal constant DECIMALS = 18;
    uint256 internal constant ONE = 10**DECIMALS;

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / ONE;
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * ONE) / b;
    }
}


// File contracts/tokenomics/InflationManager.sol

pragma solidity ^0.8.13;






contract InflationManager is IInflationManager, Ownable {
    using ScaledMath for uint256;

    IController public controller;
    ICNCToken public immutable cncToken;
    IMultiplier public multiplier;

    /// @dev mapping from pool address to the total amount of CRV tokens that the pool has claimed
    mapping(address => uint256) internal _poolCRVClaimed;

    constructor(address _cncToken) Ownable() {
        cncToken = ICNCToken(_cncToken);
    }

    function initialize(address _multiplier, IController _controller) external onlyOwner {
        require(address(multiplier) == address(0), "Multiplier already set");
        require(_multiplier != address(0), "Cannot use zero address for multiplier");
        require(address(_controller) != address(0), "Cannot use zero address for controller");
        multiplier = IMultiplier(_multiplier);
        controller = _controller;
    }

    /// @inheritdoc IInflationManager
    /// @dev the pool needs to be registered in the address provider
    function claimPoolRewards(address pool) external {
        require(controller.isPool(pool), "not a pool");
        require(address(multiplier) != address(0), "Multiplier not set");

        uint256 previousCRVClaimed = _poolCRVClaimed[pool];
        IRewardManager rewardManager = IConicPool(pool).rewardManager();
        uint256 totalCRVClaimed = rewardManager.totalCRVClaimed();
        uint256 claimedCRVDelta = totalCRVClaimed - previousCRVClaimed;
        if (claimedCRVDelta == 0) return;

        uint256 currentMultiplier = multiplier.getMultiplier();
        uint256 cncToMint = claimedCRVDelta.mulDown(currentMultiplier);
        cncToken.mint(address(rewardManager), cncToMint);

        _poolCRVClaimed[pool] = totalCRVClaimed;

        emit TokensClaimed(pool, claimedCRVDelta, cncToMint);
    }
}