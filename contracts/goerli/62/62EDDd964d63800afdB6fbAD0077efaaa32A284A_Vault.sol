// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

//import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IVaultRewardToken.sol";
import "./interfaces/ICompoundEther.sol";
import "./interfaces/IComptroller.sol";

struct CheckmarkedReward {
    uint256 timestamp;
    uint256 etherReward;
}

contract Vault is Ownable {
    event Deposit(address owner, uint256 amount);
    event Withdrawal(address owner, uint256 amount, uint256 rewardAmount);
    event ClaimedCompReward(address caller, address recipient, uint256 amount);
    event SkimmedCompoundInterest(address caller, address recipient, uint256 amount);

    /**
     * @notice Reward APY of the Vault
     */
    uint256 public constant STAKING_APY = 0.1e18;
    /**
     * @notice Minimum staking amount of the Vault
     */
    uint256 public constant MINIMUM_STAKING_AMOUNT = 5 ether;
    /**
     * @notice Token in which the rewards of the Vault are paid
     */
    IVaultRewardToken public immutable rewardToken;
    /**
     * @notice Total amount that is staked in the Vault
     */
    uint256 public totalStakedBalance = 0;

    AggregatorV3Interface private immutable _ethUsdPriceFeed;
    ICompoundEther private immutable _compoundEther;
    mapping(address => uint256) private _stakedBalances;
    mapping(address => CheckmarkedReward) private _checkmarkedRewards;

    constructor(
        IVaultRewardToken rewardToken_,
        AggregatorV3Interface ethUsdPriceFeed_,
        ICompoundEther compoundEther_
    ) {
        rewardToken = rewardToken_;
        _ethUsdPriceFeed = ethUsdPriceFeed_;
        _compoundEther = compoundEther_;
    }

    // allow contract to receive ether: https://docs.soliditylang.org/en/v0.8.10/contracts.html#receive-ether-function
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /**
     * @notice Deposit the sent ether to the Vault. The ether will be deposited in Compound and can be withdrawn
     * by the caller at any time
     */
    function deposit() public payable {
        _checkmarkReward(msg.sender);
        uint256 amount = msg.value;

        _depositToCompound(amount);
        totalStakedBalance += amount;
        _stakedBalances[msg.sender] += amount;

        emit Deposit(msg.sender, amount);

        _assertMinimumStakingAmount(msg.sender);
    }

    /**
     * @notice Withdraw the given amount and all accrued rewards from the Vault. The amount is withdrawn from Compound
     * and sent to the caller
     * @param amount Amount of ether that is withdrawn from the Vault
     */
    function withdraw(uint256 amount) public {
        require(_stakedBalances[msg.sender] >= amount, "Amount exceeds account balance");
        uint256 rewardAmount = _accruedRewardAmount(msg.sender);

        totalStakedBalance -= amount;
        _stakedBalances[msg.sender] -= amount;
        _checkmarkedRewards[msg.sender].etherReward = 0;
        _checkmarkedRewards[msg.sender].timestamp = block.timestamp;

        _withdrawFromCompound(amount);
        payable(msg.sender).transfer(amount);
        rewardToken.mint(msg.sender, rewardAmount);

        emit Withdrawal(msg.sender, amount, rewardAmount);

        _assertMinimumStakingAmount(msg.sender);
    }

    /**
     * @notice Return the total amount tht was staked by the given owner
     * @param owner Owner of which the staked amount is returned
     * @return The total amount staked by the owner
     */
    function stakedBalance(address owner) public view returns (uint256) {
        return _stakedBalances[owner];
    }

    /**
     * @notice Return the total amount of reward tokens that can be withdrawn by the given owner
     * @param owner Owner of which the reward amount is returned
     * @return The total reward amount earned by the owner
     */
    function accruedRewardAmount(address owner) public view returns (uint256) {
        return _accruedRewardAmount(owner);
    }

    /**
     * @notice Return the total amount of reward tokens that can be withdrawn by the given owner
     * @param owner Owner of which the reward amount is returned
     * @return The total reward amount earned by the owner
     */
    function _accruedRewardAmount(address owner) internal view returns (uint256) {
        uint256 totalEtherReward = _checkmarkedRewards[owner].etherReward + _pendingEtherReward(owner);

        return _rewardTokenAmount(totalEtherReward);
    }

    /**
     * @notice Return the reward amount in ether that was already accrued but not yet checkmarked
     * @param owner Owner of which the reward amount is returned
     * @return The reward amount that was not yet checkmarked
     */
    function _pendingEtherReward(address owner) internal view returns (uint256) {
        uint256 etherRewardPerYear = (_stakedBalances[owner] * STAKING_APY) / 1e18;
        uint256 secondsSinceCheckmark = block.timestamp - _checkmarkedRewards[owner].timestamp;

        return (etherRewardPerYear * secondsSinceCheckmark) / 365 days;
    }

    /**
     * @notice Return the amount of reward tokens for the given ether amount based on the current
     * ether price fetched from the Chainlink price feed
     * @param etherAmount Amount for which the respective amount of reward tokens is calculated
     * @return The amount of reward tokens for the given ether amount
     */
    function _rewardTokenAmount(uint256 etherAmount) internal view returns (uint256) {
        (, int256 etherPrice, , , ) = _ethUsdPriceFeed.latestRoundData();
        uint256 denominator = 10**_ethUsdPriceFeed.decimals();

        return (etherAmount * uint256(etherPrice)) / denominator;
    }

    /**
     * @notice Update the checkmarked reward amount for the given owner
     * @dev This function must be called before the staked balance of an owner is changed to make sure that the
     * rewards for the previous balance are accounted correctly
     * @param owner Owner of which the reward amount is checkmarked

     */
    function _checkmarkReward(address owner) internal {
        _checkmarkedRewards[owner].etherReward += _pendingEtherReward(owner);
        _checkmarkedRewards[owner].timestamp = block.timestamp;
    }

    /**
     * @notice Deposit the given ether amount from the Vault to Compound
     * @param etherAmount Amount of ether that is deposited
     */
    function _depositToCompound(uint256 etherAmount) internal {
        _compoundEther.mint{value: etherAmount}();
    }

    /**
     * @notice Withdraw the given ether amount from Compound to the Vault
     * @param etherAmount Amount of ether that is withdrawn
     */
    function _withdrawFromCompound(uint256 etherAmount) internal {
        _compoundEther.redeemUnderlying(etherAmount);
    }

    /**
     * @notice Assert that the given owner fulfills the minimum staking requirements, revert if not
     * @dev This function must be called after the staked balance of an owner was changed
     * @param owner Owner of which the staking balance is checked
     */
    function _assertMinimumStakingAmount(address owner) internal view {
        require(
            _stakedBalances[owner] == 0 || _stakedBalances[owner] >= MINIMUM_STAKING_AMOUNT,
            "Below minimum staking amount"
        );
    }

    /**
     * @notice Claim the COMP rewards earned by the Vault from the Compount Comptroller and transfer them to the given recipient
     * @param recipient Address to which the claimed COMP reward is transferred
     */
    function claimCompReward(address recipient) public onlyOwner {
        IComptroller comptroller = IComptroller(_compoundEther.comptroller());
        IERC20 comp = IERC20(comptroller.getCompAddress());

        comptroller.claimComp(address(this));
        uint256 amount = comp.balanceOf(address(this));
        comp.transfer(recipient, amount);

        emit ClaimedCompReward(msg.sender, recipient, amount);
    }

    /**
     * @notice Skim the interest earned by the ether deposited in Compound and transfer them to the given recipient
     * @param recipient Address to which the earned interest is transferred
     */
    function skimCompoundInterest(address payable recipient) public onlyOwner {
        uint256 cEtherBalance = _compoundEther.balanceOf(address(this));
        _compoundEther.redeem(cEtherBalance);
        _compoundEther.mint{value: totalStakedBalance}();

        uint256 amount = address(this).balance;
        recipient.transfer(amount);

        emit SkimmedCompoundInterest(msg.sender, recipient, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVaultRewardToken is IERC20 {
    function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Extracted from: https://github.com/compound-finance/compound-protocol/blob/v2.8.1/contracts/CEther.sol
 */
interface ICompoundEther is IERC20 {
    /**
     * @notice Contract which oversees inter-cToken operations
     */
    function comptroller() external view returns (address);

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint256);

    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Reverts upon any failure
     */
    function mint() external payable;

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of cTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint256 redeemTokens) external returns (uint256);

    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @dev Extracted from: https://github.com/compound-finance/compound-protocol/blob/v2.8.1/contracts/Comptroller.sol
 */
interface IComptroller {
    /**
     * @notice Claim all the comp accrued by holder in all markets
     * @param holder The address to claim COMP for
     */
    function claimComp(address holder) external;

    /**
     * @notice Return the address of the COMP token
     * @return The address of COMP
     */
    function getCompAddress() external view returns (address);
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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