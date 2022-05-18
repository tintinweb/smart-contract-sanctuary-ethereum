// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./LendingPoolToken.sol";
import "./libraries/PeriodStaking.sol";
import "./libraries/LinearStaking.sol";
import "./libraries/Funding.sol";

/// @title LendingPool
/// @dev
contract LendingPool is Initializable, OwnableUpgradeable, PausableUpgradeable {
    event LendingPoolInitialized(address _address, string id, address lendingPoolToken);

    /// @dev unique identifier
    string public id;

    /// @dev LendingPoolToken of the pool
    LendingPoolToken public lendingPoolToken;

    /// @dev Storage for funding logic
    mapping(uint256 => Funding.FundingStorage) private fundingStorage;

    /// @dev Storage for linear staking logic
    mapping(uint256 => LinearStaking.LinearStakingStorage) private linearStakingStorage;

    /// @dev Storage for period staking logic
    mapping(uint256 => PeriodStaking.PeriodStakingStorage) private periodStakingStorage;

    /// @dev initialization of the lendingPool (required since upgradable contracts can not be initialized via constructor)
    /// @param _lendingPoolId unique identifier
    /// @param _lendingPoolTokenSymbol symbol of the LendingPoolToken
    function initialize(string memory _lendingPoolId, string memory _lendingPoolTokenSymbol) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();

        pause();

        id = _lendingPoolId;

        lendingPoolToken = new LendingPoolToken(_lendingPoolId, _lendingPoolTokenSymbol);

        emit LendingPoolInitialized(address(this), _lendingPoolId, address(lendingPoolToken));
    }

    /////////////////////////////////////////////////////////////////////////
    /////////////////////////////////GENERAL/////////////////////////////////
    /////////////////////////////////////////////////////////////////////////

    /// @dev pauses the lendingPool. Only affects function with pausable related modifiers
    function pause() public onlyOwner {
        super._pause();
    }

    /// @dev unpauses the lendingPool. In order to unpause the configuration must be consistent. Only affects function with pausable related modifiers
    function unpause() public onlyOwner {
        super._unpause();
    }

    /// @dev returns the current version of this smart contract
    /// @return the current version of this smart contract
    function getVersion() public pure virtual returns (string memory) {
        return "V1";
    }

    /////////////////////////////////////////////////////////////////////////
    /////////////////////////////////FUNDING/////////////////////////////////
    /////////////////////////////////////////////////////////////////////////

    /// @dev Set whether a token should be accepted for funding the pool
    /// @param fundingToken the funding token
    /// @param accepted whether it is accepted
    function setFundingToken(IERC20 fundingToken, bool accepted) public onlyOwner {
        Funding.setFundingToken(fundingStorage[0], fundingToken, accepted);
    }

    /// @dev returns the accepted funding tokens
    function getFundingTokens() external view returns (IERC20[] memory) {
        return fundingStorage[0]._fundingTokens;
    }

    /// @dev returns true if wallet is whitelisted (primary funder wallet)
    function isPrimaryFunder(address wallet) public view returns (bool) {
        return fundingStorage[0].primaryFunders[wallet] || fundingStorage[0].disablePrimaryFunderCheck;
    }

    /// @dev Change primaryFunder status of an address
    /// @param primaryFunder the address
    /// @param accepted whether its accepted as primaryFunder
    function setPrimaryFunder(address primaryFunder, bool accepted) public onlyOwner {
        Funding.setPrimaryFunder(fundingStorage[0], primaryFunder, accepted);
    }

    /// @dev returns true if wallet is borrower wallet
    function isBorrower(address wallet) external view returns (bool) {
        return fundingStorage[0].borrowers[wallet];
    }

    /// @dev Change borrower status of an address
    /// @param borrower the address
    /// @param accepted whether its accepted as primaryFunder
    function setBorrower(address borrower, bool accepted) public {
        require(_msgSender() == owner() || fundingStorage[0].borrowers[_msgSender()], "caller address is no borrower or owner");
        Funding.setBorrower(fundingStorage[0], borrower, accepted);
    }

    /// @dev returns current and last IDs of funding requests (linked list)
    function getFundingRequestIDs() external view returns (uint256, uint256) {
        return (fundingStorage[0].currentFundingRequestId, fundingStorage[0].lastFundingRequestId);
    }

    /// @dev Borrower adds funding request
    /// @param amount funding request amount
    /// @param durationDays days that funding request is open
    /// @param interestRate interest rate for funding request
    function addFundingRequest(
        uint256 amount,
        uint256 durationDays,
        uint256 interestRate
    ) public whenNotPaused {
        Funding.addFundingRequest(fundingStorage[0], amount, durationDays, interestRate);
    }

    /// @dev Borrower cancels funding request
    /// @param fundingRequestId funding request id to cancel
    function cancelFundingRequest(uint256 fundingRequestId) public whenNotPaused {
        Funding.cancelFundingRequest(fundingStorage[0], fundingRequestId);
    }

    /// @dev Get information about the funding Request with the funding request ID
    /// @param fundingRequestId the funding request ID
    /// @return the FundingRequest structure selected with _fundingRequestID
    function getFundingRequest(uint256 fundingRequestId) public view whenNotPaused returns (Funding.FundingRequest memory) {
        return fundingStorage[0].fundingRequests[fundingRequestId];
    }

    /// @dev Allows primary funders to fund the pool
    /// @param fundingToken token used for the funding
    /// @param fundingTokenAmount funding amount (funding token decimals)
    function fund(IERC20 fundingToken, uint256 fundingTokenAmount) public whenNotPaused {
        Funding.fund(fundingStorage[0], fundingToken, fundingTokenAmount, lendingPoolToken);
    }

    /// @dev Get an exchange rate for an ERC20<>Currnecy conversion
    /// @param token the token
    /// @return the exchange rate and the decimals of the exchange rate
    function getExchangeRate(IERC20 token) public view returns (uint256, uint8) {
        return Funding.getExchangeRate(fundingStorage[0], token);
    }

    /// @dev Adds a mapping between a token, currency and ChainLink price feed
    /// @param token the token
    /// @param chainLinkFeed the ChainLink price feed
    /// @param invertChainLinkFeedAnswer whether the rate returned by the chainLinkFeed needs to be inverted to match the token-currency pair order
    function setFundingTokenChainLinkFeed(
        IERC20 token,
        AggregatorV3Interface chainLinkFeed,
        bool invertChainLinkFeedAnswer
    ) external onlyOwner {
        Funding.setFundingTokenChainLinkFeed(fundingStorage[0], token, chainLinkFeed, invertChainLinkFeedAnswer);
    }

    /// @dev Get a ChainLink price feed for a token-currency pair
    /// @param token the token
    /// @return the ChainLink price feed
    function getFundingTokenChainLinkFeeds(IERC20 token) public view returns (AggregatorV3Interface) {
        return fundingStorage[0].fundingTokenChainLinkFeeds[token];
    }

    function setDisablePrimaryFunderCheck(bool disable) public onlyOwner {
        fundingStorage[0].disablePrimaryFunderCheck = disable;
    }

    /////////////////////////////////////////////////////////////////////////
    /////////////////////////////LINEAR STAKING//////////////////////////////
    /////////////////////////////////////////////////////////////////////////

    /// @dev Sets the rewardTokensPerBlock for a stakedToken-rewardToken pair
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @param rewardTokensPerBlock rewardTokens per rewardToken per block (rewardToken decimals)
    function setRewardTokensPerBlockLinear(
        IERC20 stakedToken,
        IERC20 rewardToken,
        uint256 rewardTokensPerBlock
    ) public onlyOwner {
        LinearStaking.setRewardTokensPerBlockLinear(linearStakingStorage[0], stakedToken, rewardToken, rewardTokensPerBlock);
    }

    /// @dev Get tokens that can be staked in linear staking
    function getStakableTokens() external view returns (IERC20[] memory) {
        return linearStakingStorage[0].stakableTokens;
    }

    /// @dev Get available rewards for linear staking
    /// @param rewardToken the reward token
    function getAvailableLinearStakingRewards(IERC20 rewardToken) external view returns (uint256) {
        return linearStakingStorage[0].availableRewards[rewardToken];
    }

    /// @dev Lock or unlock the rewards for a staked token during linear staking
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @param rewardsLocked true = lock; false = unlock
    function setRewardsLockedLinear(
        IERC20 stakedToken,
        IERC20 rewardToken,
        bool rewardsLocked
    ) public onlyOwner {
        LinearStaking.setRewardsLockedLinear(linearStakingStorage[0], stakedToken, rewardToken, rewardsLocked);
    }

    /// @dev Staking of a stakable token
    /// @param stakableToken the stakeable token
    /// @param amount the amount to stake (stakableToken decimals)
    function stakeLinear(IERC20 stakableToken, uint256 amount) public whenNotPaused {
        LinearStaking.stakeLinear(linearStakingStorage[0], stakableToken, amount);
    }

    /// @dev Get the staked balance for a specific token and wallet
    /// @param wallet the wallet
    /// @param stakableToken the staked token
    /// @return the staked balance (stakableToken decimals)
    function getStakedBalanceLinear(address wallet, IERC20 stakableToken) public view returns (uint256) {
        return LinearStaking.getStakedBalanceLinear(linearStakingStorage[0], wallet, stakableToken);
    }

    /// @dev Unstaking of a staked token
    /// @param stakedToken the staked token
    /// @param amount the amount to unstake
    function unstakeLinear(IERC20 stakedToken, uint256 amount) public whenNotPaused {
        LinearStaking.unstakeLinear(linearStakingStorage[0], stakedToken, amount);
    }

    /// @dev Calculates the outstanding rewards for a wallet, staked token and reward token
    /// @param wallet the wallet
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @return the outstading rewards (rewardToken decimals)
    function calculateRewardsLinear(
        address wallet,
        IERC20 stakedToken,
        IERC20 rewardToken
    ) public view returns (uint256) {
        return LinearStaking.calculateRewardsLinear(linearStakingStorage[0], wallet, stakedToken, rewardToken);
    }

    /// @dev Claims all rewards for a staked tokens
    /// @param stakedToken the staked token
    function claimRewardsLinear(IERC20 stakedToken) public whenNotPaused {
        LinearStaking.claimRewardsLinear(linearStakingStorage[0], stakedToken);
    }

    /// @dev Check if rewards for a staked token are locked or not
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @return true = locked; false = unlocked
    function getRewardsLocked(IERC20 stakedToken, IERC20 rewardToken) public view returns (bool) {
        return linearStakingStorage[0].rewardConfigurations[stakedToken].rewardsLocked[rewardToken];
    }

    /// @dev Allows the deposit of reward funds. This is usually used by the borrower or treasury
    /// @param rewardToken the reward token
    /// @param amount the amount of tokens (rewardToken decimals)
    function depositRewardsLinear(IERC20 rewardToken, uint256 amount) public {
        LinearStaking.depositRewardsLinear(linearStakingStorage[0], rewardToken, amount);
    }

    function getRewardTokens(IERC20 stakedToken) public view returns (IERC20[] memory) {
        return linearStakingStorage[0].rewardConfigurations[stakedToken].rewardTokens;
        // return LinearStaking.getRewardTokens(linearStakingStorage[0], stakedToken);
    }

    /// @dev Allows owner to withdraw tokens for maintenance / recovery purposes
    /// @param token the token
    /// @param amount the amount to be withdrawn
    /// @param to the address to withdraw to
    function withdrawTokens(
        IERC20 token,
        uint256 amount,
        address to
    ) public onlyOwner {
        Util.checkedTransfer(token, to, amount);
    }

    /////////////////////////////////////////////////////////////////////////
    /////////////////////////////PERIOD STAKING//////////////////////////////
    /////////////////////////////////////////////////////////////////////////

    /// @dev Set the duration of the reward period
    /// @param duration duration in blocks of the reward period
    function setRewardPeriodDuration(uint256 duration) external onlyOwner {
        periodStakingStorage[0].duration = duration;
    }

    function setEndRewardPeriod(uint256 periodEnd) external onlyOwner {
        PeriodStaking.setEndRewardPeriod(periodStakingStorage[0], periodEnd);
    }

    /// @dev Get variables of the period staking
    /// @return returns the id, duration and the rward token of the current reward period
    function getPeriodStakingInfo()
        external
        view
        returns (
            uint256,
            uint256,
            IERC20
        )
    {
        return (periodStakingStorage[0].currentRewardPeriodId, periodStakingStorage[0].duration, periodStakingStorage[0].rewardToken);
    }

    /// @dev Set the reward token of the reward period
    /// @param rewardToken the rward token of the reward period
    function setRewardPeriodRewardToken(IERC20 rewardToken) external onlyOwner {
        periodStakingStorage[0].rewardToken = rewardToken;
    }

    /// @dev Get the reward period
    /// @return returns the struct of the reward period
    function getRewardPeriod(uint256 rewardPeriodId) external view returns (PeriodStaking.RewardPeriod memory) {
        return periodStakingStorage[0].rewardPeriods[rewardPeriodId];
    }

    /// @dev Get all reward periods
    /// @return returns an array including the structs of all reward periods
    function getRewardPeriods() external view returns (PeriodStaking.RewardPeriod[] memory) {
        return PeriodStaking.getRewardPeriods(periodStakingStorage[0]);
    }

    /// @dev Get all open FundingRequests
    /// @return all open FundingRequests
    function getOpenFundingRequests() external view returns (Funding.FundingRequest[] memory) {
        return Funding.getOpenFundingRequests(fundingStorage[0]);
    }

    /// @dev Start next reward period
    function startNextRewardPeriod() external {
        PeriodStaking.startNextRewardPeriod(periodStakingStorage[0], 0);
    }

    /// @dev Start the next reward period
    /// @param periodStart start block of the period, 0 == follow previous period, 1 == start at current block, >1 use passed value
    function startNextRewardPeriodCustom(uint256 periodStart) external onlyOwner {
        PeriodStaking.startNextRewardPeriod(periodStakingStorage[0], periodStart);
    }

    /// @dev deposit rewards for staking period
    /// @param rewardPeriodId staking period id
    /// @param totalRewards total rewards to be deposited
    function depositRewardPeriodRewards(uint256 rewardPeriodId, uint256 totalRewards) public onlyOwner {
        PeriodStaking.depositRewardPeriodRewards(periodStakingStorage[0], rewardPeriodId, totalRewards);
    }

    /// @dev Get staking score of a wallet for a certain staking period
    /// @param wallet wallet address
    /// @param period staking period id
    function getWalletRewardPeriodStakingScore(address wallet, uint256 period) public view returns (uint256) {
        return PeriodStaking.getWalletRewardPeriodStakingScore(periodStakingStorage[0], wallet, period);
    }

    /// @dev Get the amount of lendingPoolTokens staked with period staking for a wallet
    /// @param wallet wallet address
    function getWalletStakedAmountRewardPeriod(address wallet) public view returns (uint256) {
        return periodStakingStorage[0].walletStakedAmounts[wallet].stakedBalance;
    }

    /// @dev stake Lending Pool Token during reward period
    /// @param amount amount of Lending Pool Token to stake
    function stakeRewardPeriod(uint256 amount) external {
        PeriodStaking.stakeRewardPeriod(periodStakingStorage[0], amount, lendingPoolToken);
    }

    /// @dev unstake Lending Pool Token during reward period
    /// @param amount amount of Lending Pool Token to unstake
    function unstakeRewardPeriod(uint256 amount) external {
        PeriodStaking.unstakeRewardPeriod(periodStakingStorage[0], amount, lendingPoolToken);
    }

    /// @dev claim rewards of staking period
    /// @param rewardPeriodId staking period id
    function claimRewardPeriod(uint256 rewardPeriodId) external {
        PeriodStaking.claimRewardPeriod(periodStakingStorage[0], rewardPeriodId, lendingPoolToken);
    }

    /// @dev calculate rewards for a wallet of a certain staking period
    /// @param wallet wallet address
    /// @param rewardPeriodId staking period id
    /// @param projectedTotalRewards projected total rewards for staking period
    function calculateWalletRewardsPeriod(
        address wallet,
        uint256 rewardPeriodId,
        uint256 projectedTotalRewards
    ) public view returns (uint256) {
        return PeriodStaking.calculateWalletRewardsPeriod(periodStakingStorage[0], wallet, rewardPeriodId, projectedTotalRewards);
    }
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title LendingPoolToken
/// @author Florence Finance
/// @dev Every LendingPool has its own LendingPoolToken which can be minted and burned by the LendingPool
contract LendingPoolToken is ERC20, Ownable {
    /// @dev
    /// @param _lendingPoolId (uint256) id of the LendingPool this token belongs to
    /// @param _name (string) name of the token (see ERC20)
    /// @param _symbol (string) symbol of the token (see ERC20)
    // solhint-disable-next-line
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    /// @dev Allows owner to mint tokens.
    /// @param _receiver (address) receiver of the minted tokens
    /// @param _amount (uint256) the amount to mint (18 decimals)
    function mint(address _receiver, uint256 _amount) external onlyOwner {
        require(_amount > 0, "LendingPoolToken: invalidAmount");
        _mint(_receiver, _amount);
    }

    /// @dev Allows owner to burn tokens.
    /// @param _amount (uint256) the amount to burn (18 decimals)
    function burn(uint256 _amount) external {
        require(_amount > 0, "LendingPoolToken: invalidAmount");
        _burn(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "./Util.sol";

/// @title Period staking contract
/// @dev this library contains all funcionality related to the period staking mechanism
/// Lending Pool Token (LPT) owner stake their LPTs within an active staking period (e.g. staking period could be three months)
/// The LPTs can remain staked over several consecutive periods while accumulating staking rewards (currently USDC token).
/// The amount of staking rewards depends on the total staking score per staking period of the LPT owner address and
/// on the total amount of rewards distrubuted for this staking period
/// E.g. Staking period is 90 days and total staking rewards is 900 USDC
/// LPT staker 1 stakes 100 LPTs during the whole 90 days
/// LPT staker 2 starts staking after 45 days and stakes 100 LPTs until the end of the staking period
/// staker 1 staking score is 600 and staker 2 staking score is 300
/// staker 1 claims 600 USDC after staking period is completed
/// staker 2 claims 300 USDC after staking period is completed
/// the staking rewards need to be claimed actively after each staking period is completed and the total rewards have been deposited to the contract by the Borrower

library PeriodStaking {
    event StakedPeriod(address indexed staker, IERC20 indexed stakableToken, uint256 amount);
    event UnstakedPeriod(address indexed unstaker, IERC20 indexed stakedToken, uint256 amount, uint256 totalStakedBalance);
    event ClaimedRewardsPeriod(address indexed claimer, IERC20 stakedToken, IERC20 rewardToken, uint256 amount);
    event ChangedEndRewardPeriod(uint256 indexed _periodId, uint256 _periodStart, uint256 _periodEnd);

    struct PeriodStakingStorage {
        mapping(uint256 => RewardPeriod) rewardPeriods;
        mapping(address => WalletStakingState) walletStakedAmounts;
        mapping(uint256 => mapping(address => uint256)) walletStakingScores;
        uint256 currentRewardPeriodId;
        uint256 duration;
        IERC20 rewardToken;
    }

    struct RewardPeriod {
        uint256 id;
        uint256 start;
        uint256 end;
        uint256 totalRewards;
        uint256 totalStakingScore;
        uint256 finalStakedAmount;
        IERC20 rewardToken;
    }

    struct WalletStakingState {
        uint256 stakedBalance;
        uint256 lastUpdate;
        mapping(IERC20 => uint256) outstandingRewards;
    }

    /// @dev Get the struct/info of all reward periods
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @return returns the array including all reward period structs
    function getRewardPeriods(PeriodStakingStorage storage periodStakingStorage) external view returns (RewardPeriod[] memory) {
        RewardPeriod[] memory rewardPeriodsArray = new RewardPeriod[](periodStakingStorage.currentRewardPeriodId);

        for (uint256 i = 1; i <= periodStakingStorage.currentRewardPeriodId; i++) {
            RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[i];
            rewardPeriodsArray[i - 1] = rewardPeriod;
        }
        return rewardPeriodsArray;
    }

    /// @dev End the current reward period
    /// @param periodEnd block number of new end of the current reward period
    /// periodEnd == 0 sets current reward period end to current block number
    function setEndRewardPeriod(PeriodStakingStorage storage periodStakingStorage, uint256 periodEnd) external {
        RewardPeriod storage currentRewardPeriod = periodStakingStorage.rewardPeriods[periodStakingStorage.currentRewardPeriodId];
        require(currentRewardPeriod.id > 0, "no reward periods");
        require(currentRewardPeriod.start < block.number && currentRewardPeriod.end > block.number, "not inside any reward period");

        if (periodEnd == 0) {
            currentRewardPeriod.end = block.number;
        } else {
            require(periodEnd >= block.number, "end of period in the past");
            currentRewardPeriod.end = periodEnd;
        }
        emit ChangedEndRewardPeriod(currentRewardPeriod.id, currentRewardPeriod.start, currentRewardPeriod.end);
    }

    /// @dev Start the next reward period
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param periodStart start block of the period, 0 == follow previous period, 1 == start at current block, >1 use passed value
    function startNextRewardPeriod(PeriodStakingStorage storage periodStakingStorage, uint256 periodStart) external {
        require(periodStakingStorage.duration > 0 && address(periodStakingStorage.rewardToken) != address(0), "duration and/or rewardToken not configured");

        RewardPeriod storage currentRewardPeriod = periodStakingStorage.rewardPeriods[periodStakingStorage.currentRewardPeriodId];
        if (periodStakingStorage.currentRewardPeriodId > 0) {
            require(currentRewardPeriod.end > 0 && currentRewardPeriod.end < block.number, "current period has not ended yet");
        }

        periodStakingStorage.currentRewardPeriodId += 1;
        RewardPeriod storage nextRewardPeriod = periodStakingStorage.rewardPeriods[periodStakingStorage.currentRewardPeriodId];
        nextRewardPeriod.rewardToken = periodStakingStorage.rewardToken;

        nextRewardPeriod.id = periodStakingStorage.currentRewardPeriodId;

        if (periodStart == 0) {
            nextRewardPeriod.start = currentRewardPeriod.end != 0 ? currentRewardPeriod.end : block.number;
        } else if (periodStart == 1) {
            nextRewardPeriod.start = block.number;
        } else {
            nextRewardPeriod.start = periodStart;
        }

        nextRewardPeriod.end = nextRewardPeriod.start + periodStakingStorage.duration;
        nextRewardPeriod.finalStakedAmount = currentRewardPeriod.finalStakedAmount;
        nextRewardPeriod.totalStakingScore = currentRewardPeriod.finalStakedAmount * (nextRewardPeriod.end - nextRewardPeriod.start);
    }

    /// @dev Deposit the rewards (USDC token) for a reward period
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param rewardPeriodId The ID of the reward period
    /// @param _totalRewards total amount of period rewards to deposit
    function depositRewardPeriodRewards(
        PeriodStakingStorage storage periodStakingStorage,
        uint256 rewardPeriodId,
        uint256 _totalRewards
    ) public {
        RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[rewardPeriodId];

        require(rewardPeriod.end > 0 && rewardPeriod.end < block.number, "period has not ended");

        periodStakingStorage.rewardPeriods[rewardPeriodId].totalRewards = Util.checkedTransferFrom(rewardPeriod.rewardToken, msg.sender, address(this), _totalRewards);
    }

    /// @dev Updates the staking score for a wallet over all staking periods
    /// @param periodStakingStorage pointer to period staking storage struct
    function updatePeriod(PeriodStakingStorage storage periodStakingStorage) internal {
        WalletStakingState storage walletStakedAmount = periodStakingStorage.walletStakedAmounts[msg.sender];
        if (walletStakedAmount.stakedBalance > 0 && walletStakedAmount.lastUpdate < periodStakingStorage.currentRewardPeriodId && walletStakedAmount.lastUpdate > 0) {
            uint256 i = walletStakedAmount.lastUpdate + 1;
            for (; i <= periodStakingStorage.currentRewardPeriodId; i++) {
                RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[i];
                periodStakingStorage.walletStakingScores[i][msg.sender] = walletStakedAmount.stakedBalance * (rewardPeriod.end - rewardPeriod.start);
            }
        }
        walletStakedAmount.lastUpdate = periodStakingStorage.currentRewardPeriodId;
    }

    /// @dev Calculate the staking score for a wallet for a given rewards period
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param wallet wallet address
    /// @param period period ID for which to calculate the staking rewards
    /// @return wallet staking score for a given rewards period
    function getWalletRewardPeriodStakingScore(
        PeriodStakingStorage storage periodStakingStorage,
        address wallet,
        uint256 period
    ) public view returns (uint256) {
        WalletStakingState storage walletStakedAmount = periodStakingStorage.walletStakedAmounts[wallet];
        RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[period];
        if (walletStakedAmount.lastUpdate > 0 && walletStakedAmount.lastUpdate < period) {
            return walletStakedAmount.stakedBalance * (rewardPeriod.end - rewardPeriod.start);
        } else {
            return periodStakingStorage.walletStakingScores[period][wallet];
        }
    }

    /// @dev Stake Lending Pool Token in current rewards period
    /// @notice emits event StakedPeriod
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param amount amount of LPT to stake
    /// @param lendingPoolToken Lending Pool Token address
    function stakeRewardPeriod(
        PeriodStakingStorage storage periodStakingStorage,
        uint256 amount,
        IERC20 lendingPoolToken
    ) external {
        RewardPeriod storage currentRewardPeriod = periodStakingStorage.rewardPeriods[periodStakingStorage.currentRewardPeriodId];
        require(currentRewardPeriod.start <= block.number && currentRewardPeriod.end > block.number, "no active period");

        updatePeriod(periodStakingStorage);

        amount = Util.checkedTransferFrom(lendingPoolToken, msg.sender, address(this), amount);

        emit StakedPeriod(msg.sender, lendingPoolToken, amount);

        periodStakingStorage.walletStakedAmounts[msg.sender].stakedBalance += amount;

        currentRewardPeriod.finalStakedAmount += amount;

        currentRewardPeriod.totalStakingScore += (currentRewardPeriod.end - block.number) * amount;

        periodStakingStorage.walletStakingScores[periodStakingStorage.currentRewardPeriodId][msg.sender] += (currentRewardPeriod.end - block.number) * amount;
    }

    /// @dev Unstake Lending Pool Token
    /// @notice emits event UnstakedPeriod
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param amount amount of LPT to unstake
    /// @param lendingPoolToken Lending Pool Token address
    function unstakeRewardPeriod(
        PeriodStakingStorage storage periodStakingStorage,
        uint256 amount,
        IERC20 lendingPoolToken
    ) external {
        require(amount <= periodStakingStorage.walletStakedAmounts[msg.sender].stakedBalance, "amount greater than staked amount");
        updatePeriod(periodStakingStorage);

        RewardPeriod storage currentRewardPeriod = periodStakingStorage.rewardPeriods[periodStakingStorage.currentRewardPeriodId];

        periodStakingStorage.walletStakedAmounts[msg.sender].stakedBalance -= amount;
        currentRewardPeriod.finalStakedAmount -= amount;
        if (currentRewardPeriod.end > block.number) {
            currentRewardPeriod.totalStakingScore -= (currentRewardPeriod.end - block.number) * amount;
            periodStakingStorage.walletStakingScores[periodStakingStorage.currentRewardPeriodId][msg.sender] -= (currentRewardPeriod.end - block.number) * amount;
        }

        lendingPoolToken.transfer(msg.sender, amount);
        emit UnstakedPeriod(msg.sender, lendingPoolToken, amount, periodStakingStorage.walletStakedAmounts[msg.sender].stakedBalance);
    }

    /// @dev Claim rewards (USDC) for a certain staking period
    /// @notice emits event ClaimedRewardsPeriod
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param rewardPeriodId period ID of which to claim staking rewards
    /// @param lendingPoolToken Lending Pool Token address
    function claimRewardPeriod(
        PeriodStakingStorage storage periodStakingStorage,
        uint256 rewardPeriodId,
        IERC20 lendingPoolToken
    ) external {
        RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[rewardPeriodId];
        require(rewardPeriod.end > 0 && rewardPeriod.end < block.number && rewardPeriod.totalRewards > 0, "period not ready for claiming");
        updatePeriod(periodStakingStorage);

        require(periodStakingStorage.walletStakingScores[rewardPeriodId][msg.sender] > 0, "no rewards to claim");

        uint256 payableRewardAmount = calculatePeriodRewards(
            rewardPeriod.rewardToken,
            rewardPeriod.totalRewards,
            rewardPeriod.totalStakingScore,
            periodStakingStorage.walletStakingScores[rewardPeriodId][msg.sender]
        );
        periodStakingStorage.walletStakingScores[rewardPeriodId][msg.sender] = 0;

        // This condition can never be true, because:
        // calculateRewardsPeriod can never have a walletStakingScore > totalPeriodStakingScore
        // require(payableRewardAmount > 0, "no rewards to claim");

        rewardPeriod.rewardToken.transfer(msg.sender, payableRewardAmount);
        emit ClaimedRewardsPeriod(msg.sender, lendingPoolToken, rewardPeriod.rewardToken, payableRewardAmount);
    }

    /// @dev Calculate the staking rewards of a staking period for a wallet address
    /// @param periodStakingStorage pointer to period staking storage struct
    /// @param rewardPeriodId period ID for which to calculate the rewards
    /// @param projectedTotalRewards The amount of total rewards which is planned to be deposited at the end of the staking period
    /// @return returns the amount of staking rewards for a wallet address for a certain staking period
    function calculateWalletRewardsPeriod(
        PeriodStakingStorage storage periodStakingStorage,
        address wallet,
        uint256 rewardPeriodId,
        uint256 projectedTotalRewards
    ) public view returns (uint256) {
        RewardPeriod storage rewardPeriod = periodStakingStorage.rewardPeriods[rewardPeriodId];
        if (projectedTotalRewards == 0) {
            projectedTotalRewards = rewardPeriod.totalRewards;
        }
        return
            calculatePeriodRewards(
                rewardPeriod.rewardToken,
                projectedTotalRewards,
                rewardPeriod.totalStakingScore,
                getWalletRewardPeriodStakingScore(periodStakingStorage, wallet, rewardPeriodId)
            );
    }

    /// @dev Calculate the total amount of payable rewards
    /// @param rewardToken The reward token (e.g. USDC)
    /// @param totalPeriodRewards The total amount of rewards for a certain period
    /// @param totalPeriodStakingScore The total staking score (of all wallet addresses during a certain staking period)
    /// @param walletStakingScore The total staking score (of one wallet address during a certain staking period)
    /// @return returns the total payable amount of staking rewards
    function calculatePeriodRewards(
        IERC20 rewardToken,
        uint256 totalPeriodRewards,
        uint256 totalPeriodStakingScore,
        uint256 walletStakingScore
    ) public view returns (uint256) {
        if (totalPeriodStakingScore == 0) {
            return 0;
        }
        uint256 rewardTokenDecimals = Util.getERC20Decimals(rewardToken);
        // uint256 payableRewardAmount = Util.percent(walletStakingScore * totalPeriodRewards, totalPeriodStakingScore, rewardTokenDecimals);
        // We need to devide after the calculation, so that the 'rest' is cut off

        uint256 _numerator = (walletStakingScore * totalPeriodRewards) * 10**(rewardTokenDecimals + 1);
        // with rounding of last digit
        uint256 payableRewardAmount = ((_numerator / totalPeriodStakingScore) + 5) / 10;

        return payableRewardAmount / (uint256(10)**rewardTokenDecimals);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Util.sol";

/// @title Linear staking contract
/// @dev this library contains all funcionality related to the linear staking mechanism
/// Curve Token owner stake their curve token and receive Medici (MDC) token as rewards.
/// The amount of reward token (MDC) is calculated based on:
/// - the number of staked curve token
/// - the number of blocks the curve tokens are beig staked
/// - the amount of MDC rewards per Block per staked curve token
/// E.g. 10 MDC reward token per block per staked curve token
/// staker 1 stakes 100 curve token and claims rewards (MDC) after 200 Blocks
/// staker 1 recieves 200000 MDC reward tokens (200 blocks * 10 MDC/Block/CurveToken * 100 CurveToken)

library LinearStaking {
    event RewardTokensPerBlockUpdated(IERC20 stakedToken, IERC20 rewardToken, uint256 oldRewardTokensPerBlock, uint256 newRewardTokensPerBlock);
    event RewardsLockedUpdated(IERC20 stakedToken, IERC20 rewardToken, bool rewardsLocked);
    event StakedLinear(address indexed staker, IERC20 indexed stakableToken, uint256 amount);
    event UnstakedLinear(address indexed unstaker, IERC20 indexed stakedToken, uint256 amount, uint256 totalStakedBalance);
    event ClaimedRewardsLinear(address indexed claimer, IERC20 stakedToken, IERC20 rewardToken, uint256 amount);
    event RewardsDeposited(address depositor, IERC20 rewardToken, uint256 amount);

    struct LinearStakingStorage {
        IERC20[] stakableTokens;
        /// @dev configuration of rewards for particular stakable tokens
        mapping(IERC20 => RewardConfiguration) rewardConfigurations;
        /// @dev storage of accumulated staking rewards for the pool participants addresses
        mapping(address => mapping(IERC20 => WalletStakingState)) walletStakingStates;
        /// @dev amount of tokens available to be distributed as staking rewards
        mapping(IERC20 => uint256) availableRewards;
    }

    struct RewardConfiguration {
        bool isStakable;
        IERC20[] rewardTokens;
        // mapping(IERC20 => uint256) rewardTokensPerBlock; //Old, should be removed when new algorithm is implemented

        // RewardToken => BlockNumber => RewardTokensPerBlock
        mapping(IERC20 => mapping(uint256 => uint256)) rewardTokensPerBlockHistory;
        // RewardToken => BlockNumbers/Keys of rewardTokensPerBlockHistory[RewardToken][BlockNumbers]
        mapping(IERC20 => uint256[]) rewardTokensPerBlockHistoryBlocks;
        mapping(IERC20 => bool) rewardsLocked;
    }

    struct WalletStakingState {
        uint256 stakedBalance;
        uint256 lastUpdate;
        mapping(IERC20 => uint256) outstandingRewards;
    }

    /// @dev Sets the rewardTokensPerBlock for a stakedToken-rewardToken pair
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @param rewardTokensPerBlock rewardTokens per rewardToken per block (rewardToken decimals)
    function setRewardTokensPerBlockLinear(
        LinearStakingStorage storage linearStakingStorage,
        IERC20 stakedToken,
        IERC20 rewardToken,
        uint256 rewardTokensPerBlock
    ) public {
        require(address(stakedToken) != address(0) && address(rewardToken) != address(0), "token adress cannot be zero");

        RewardConfiguration storage rewardConfiguration = linearStakingStorage.rewardConfigurations[stakedToken];

        uint256[] storage rewardTokensPerBlockHistoryBlocks = rewardConfiguration.rewardTokensPerBlockHistoryBlocks[rewardToken];

        uint256 currentRewardTokensPerBlock = 0;

        if (rewardTokensPerBlockHistoryBlocks.length > 0) {
            uint256 lastRewardTokensPerBlockBlock = rewardTokensPerBlockHistoryBlocks[rewardTokensPerBlockHistoryBlocks.length - 1];
            currentRewardTokensPerBlock = rewardConfiguration.rewardTokensPerBlockHistory[rewardToken][lastRewardTokensPerBlockBlock];
        }

        require(rewardTokensPerBlock != currentRewardTokensPerBlock, "rewardTokensPerBlock already set to expected value");

        if (rewardTokensPerBlock != 0 && currentRewardTokensPerBlock == 0) {
            rewardConfiguration.rewardTokens.push(rewardToken);
            if (rewardConfiguration.rewardTokens.length == 1) {
                linearStakingStorage.stakableTokens.push(stakedToken);
            }
        }

        if (rewardTokensPerBlock == 0 && currentRewardTokensPerBlock != 0) {
            Util.removeValueFromArray(rewardToken, rewardConfiguration.rewardTokens);
            if (rewardConfiguration.rewardTokens.length == 0) {
                Util.removeValueFromArray(stakedToken, linearStakingStorage.stakableTokens);
            }
        }

        rewardConfiguration.isStakable = rewardTokensPerBlock != 0;

        rewardConfiguration.rewardTokensPerBlockHistory[rewardToken][block.number] = rewardTokensPerBlock;
        rewardTokensPerBlockHistoryBlocks.push(block.number);

        emit RewardTokensPerBlockUpdated(stakedToken, rewardToken, currentRewardTokensPerBlock, rewardTokensPerBlock);
    }

    /// @dev Locks/Unlocks the reward token (MDC) for a certain staking token (Curve Token)
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @param rewardsLocked true = lock rewards; false = unlock rewards
    function setRewardsLockedLinear(
        LinearStakingStorage storage linearStakingStorage,
        IERC20 stakedToken,
        IERC20 rewardToken,
        bool rewardsLocked
    ) public {
        require(address(stakedToken) != address(0) && address(rewardToken) != address(0), "token adress cannot be zero");

        if (linearStakingStorage.rewardConfigurations[stakedToken].rewardsLocked[rewardToken] != rewardsLocked) {
            linearStakingStorage.rewardConfigurations[stakedToken].rewardsLocked[rewardToken] = rewardsLocked;
            emit RewardsLockedUpdated(stakedToken, rewardToken, rewardsLocked);
        }
    }

    /// @dev Staking of a stakable token
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param stakableToken the stakeable token
    /// @param amount the amount to stake (stakableToken decimals)
    function stakeLinear(
        LinearStakingStorage storage linearStakingStorage,
        IERC20 stakableToken,
        uint256 amount
    ) public {
        require(amount > 0, "amount must be greater zero");
        require(linearStakingStorage.rewardConfigurations[stakableToken].isStakable, "token is not stakable");
        updateRewardSnapshotLinear(linearStakingStorage, msg.sender, stakableToken);
        linearStakingStorage.walletStakingStates[msg.sender][stakableToken].stakedBalance += Util.checkedTransferFrom(stakableToken, msg.sender, address(this), amount);
        emit StakedLinear(msg.sender, stakableToken, amount);
    }

    /// @dev Unstaking of a staked token
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param stakedToken the staked token
    /// @param amount the amount to unstake
    function unstakeLinear(
        LinearStakingStorage storage linearStakingStorage,
        IERC20 stakedToken,
        uint256 amount
    ) public {
        amount = Math.min(amount, linearStakingStorage.walletStakingStates[msg.sender][stakedToken].stakedBalance);
        require(amount > 0, "amount must be greater zero");
        updateRewardSnapshotLinear(linearStakingStorage, msg.sender, stakedToken);
        linearStakingStorage.walletStakingStates[msg.sender][stakedToken].stakedBalance -= amount;
        stakedToken.transfer(msg.sender, amount);
        uint256 totalStakedBalance = linearStakingStorage.walletStakingStates[msg.sender][stakedToken].stakedBalance;
        emit UnstakedLinear(msg.sender, stakedToken, amount, totalStakedBalance);
        // emit UnstakedLinear(msg.sender, stakedToken, amount);
    }

    /// @dev Updates the outstanding rewards for a specific wallet and staked token. This needs to be called every time before any changes to staked balances are made
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param wallet the wallet
    /// @param stakedToken the staked token
    function updateRewardSnapshotLinear(
        LinearStakingStorage storage linearStakingStorage,
        address wallet,
        IERC20 stakedToken
    ) internal {
        uint256 lastUpdate = linearStakingStorage.walletStakingStates[wallet][stakedToken].lastUpdate;

        if (lastUpdate != 0) {
            IERC20[] memory rewardTokens = linearStakingStorage.rewardConfigurations[stakedToken].rewardTokens;
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                IERC20 rewardToken = rewardTokens[i];
                uint256 newOutstandingRewards = calculateRewardsLinear(linearStakingStorage, wallet, stakedToken, rewardToken);
                linearStakingStorage.walletStakingStates[wallet][stakedToken].outstandingRewards[rewardToken] = newOutstandingRewards;
            }
        }
        linearStakingStorage.walletStakingStates[wallet][stakedToken].lastUpdate = block.number;
    }

    /// @dev Calculates the outstanding rewards for a wallet, staked token and reward token
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param wallet the wallet
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @return the outstading rewards (rewardToken decimals)
    function calculateRewardsLinear(
        LinearStakingStorage storage linearStakingStorage,
        address wallet,
        IERC20 stakedToken,
        IERC20 rewardToken
    ) public view returns (uint256) {
        uint256 lastUpdate = linearStakingStorage.walletStakingStates[wallet][stakedToken].lastUpdate;

        if (lastUpdate != 0) {
            uint256 stakedBalance = linearStakingStorage.walletStakingStates[wallet][stakedToken].stakedBalance / 10**Util.getERC20Decimals(stakedToken);

            uint256 accumulatedRewards; // = 0
            uint256 rewardRangeStart;
            uint256 rewardRangeStop = block.number;
            uint256 rewardRangeTokensPerBlock;
            uint256 rewardRangeBlocks;

            uint256[] memory fullHistory = linearStakingStorage.rewardConfigurations[stakedToken].rewardTokensPerBlockHistoryBlocks[rewardToken];
            uint256 i = fullHistory.length - 1;
            for (; i >= 0; i--) {
                rewardRangeStart = fullHistory[i];

                rewardRangeTokensPerBlock = linearStakingStorage.rewardConfigurations[stakedToken].rewardTokensPerBlockHistory[rewardToken][fullHistory[i]];

                if (rewardRangeStart < lastUpdate) {
                    rewardRangeStart = lastUpdate;
                }

                rewardRangeBlocks = rewardRangeStop - rewardRangeStart;

                accumulatedRewards += stakedBalance * rewardRangeBlocks * rewardRangeTokensPerBlock;

                if (rewardRangeStart == lastUpdate) break;

                rewardRangeStop = rewardRangeStart;
            }

            uint256 outStandingRewards = linearStakingStorage.walletStakingStates[wallet][stakedToken].outstandingRewards[rewardToken];

            return (outStandingRewards + accumulatedRewards);
        }
        return 0;
    }

    /// @dev Claims all rewards for a staked tokens
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param stakedToken the staked token
    function claimRewardsLinear(LinearStakingStorage storage linearStakingStorage, IERC20 stakedToken) public {
        updateRewardSnapshotLinear(linearStakingStorage, msg.sender, stakedToken);

        IERC20[] memory rewardTokens = linearStakingStorage.rewardConfigurations[stakedToken].rewardTokens;
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            IERC20 rewardToken = rewardTokens[i];

            if (linearStakingStorage.rewardConfigurations[stakedToken].rewardsLocked[rewardToken]) {
                //rewards for the token are not claimable yet
                continue;
            }

            uint256 rewardAmount = linearStakingStorage.walletStakingStates[msg.sender][stakedToken].outstandingRewards[rewardToken];
            uint256 payableRewardAmount = Math.min(rewardAmount, linearStakingStorage.availableRewards[rewardToken]);
            require(payableRewardAmount > 0, "no rewards available for payout");

            linearStakingStorage.walletStakingStates[msg.sender][stakedToken].outstandingRewards[rewardToken] -= payableRewardAmount;
            linearStakingStorage.availableRewards[rewardToken] -= payableRewardAmount;

            rewardToken.transfer(msg.sender, payableRewardAmount);
            emit ClaimedRewardsLinear(msg.sender, stakedToken, rewardToken, payableRewardAmount);
        }
    }

    /// @dev Allows the deposit of reward funds. This is usually used by the borrower or treasury
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param rewardToken the reward token
    /// @param amount the amount of tokens (rewardToken decimals)
    function depositRewardsLinear(
        LinearStakingStorage storage linearStakingStorage,
        IERC20 rewardToken,
        uint256 amount
    ) public {
        linearStakingStorage.availableRewards[rewardToken] += Util.checkedTransferFrom(rewardToken, msg.sender, address(this), amount);
        emit RewardsDeposited(msg.sender, rewardToken, amount);
    }

    /// @dev Get the staked balance for a specific token and wallet
    /// @param linearStakingStorage pointer to linear staking storage struct
    /// @param wallet the wallet
    /// @param stakableToken the staked token
    /// @return the staked balance (stakableToken decimals)
    function getStakedBalanceLinear(
        LinearStakingStorage storage linearStakingStorage,
        address wallet,
        IERC20 stakableToken
    ) public view returns (uint256) {
        return linearStakingStorage.walletStakingStates[wallet][stakableToken].stakedBalance;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../LendingPoolToken.sol";
import "./Util.sol";

/// @title Funding contract
/// @dev this library contains all funcionality related to the funding mechanism
/// A borrower creates a new funding request to fund an amount of Lending Pool Token (LPT)
/// A whitelisted primary funder buys LPT from the open funding request with own USDC
/// The treasury wallet is a MultiSig wallet
/// The funding request can be cancelled by the borrower

library Funding {
    /// @dev Emitted when a funding request is added
    /// @param fundingRequestId id of the funding request
    /// @param borrower borrower / creator of the funding request
    /// @param amount amount raised in LendingPoolTokens
    /// @param durationDays duration of the underlying loan
    /// @param interestRate interest rate of the underlying loan
    event FundingRequestAdded(uint256 fundingRequestId, address borrower, uint256 amount, uint256 durationDays, uint256 interestRate);

    /// @dev Emitted when a funding request is cancelled
    /// @param fundingRequestId id of the funding request
    event FundingRequestCancelled(uint256 fundingRequestId);

    /// @dev Emitted when a funding request is (partially) filled
    /// @param funder the funder
    /// @param fundingToken the token used to fund
    /// @param fundingTokenAmount the amount funded
    /// @param lendingPoolTokenAmount the amount of LendingPoolTokens the funder received
    event Funded(address indexed funder, IERC20 fundingToken, uint256 fundingTokenAmount, uint256 lendingPoolTokenAmount);

    /// @dev Emitted when a token is added or removed as funding token
    /// @param token the token
    /// @param accepted whether it can be used to fund
    event FundingTokenUpdated(IERC20 token, bool accepted);

    /// @dev Emitted when an address primaryFunder status changes
    /// @param primaryFunder the address
    /// @param accepted whether the address can fund loans
    event PrimaryFunderUpdated(address primaryFunder, bool accepted);

    /// @dev Emitted when an address borrower status changes
    /// @param borrower the address
    /// @param accepted whether the address can borrow from the pool
    event BorrowerUpdated(address borrower, bool accepted);

    /// @dev Contains all state data pertaining to funding
    struct FundingStorage {
        mapping(uint256 => FundingRequest) fundingRequests; //FundingRequest.id => FundingRequest
        uint256 currentFundingRequestId; //id of the next FundingRequest to be proccessed
        uint256 lastFundingRequestId; //id of the last FundingRequest in the
        mapping(address => bool) primaryFunders; //address => whether its allowed to fund loans
        mapping(IERC20 => bool) fundingTokens; //token => whether it can be used to fund loans
        IERC20[] _fundingTokens; //all fundingTokens that can be used to fund loans
        mapping(address => bool) borrowers; //address => whether its allowed to act as borrower / create FundingRequests
        mapping(IERC20 => AggregatorV3Interface) fundingTokenChainLinkFeeds; //fudingToken => ChainLink feed which provides a conversion rate for the fundingToken to the pools loans base currency (e.g. USDC => EURSUD)
        mapping(IERC20 => bool) invertChainLinkFeedAnswer; //fudingToken => whether the data provided by the ChainLink feed should be inverted (not all ChainLink feeds are Token->BaseCurrency, some could be BaseCurrency->Token)
        bool disablePrimaryFunderCheck;
    }
    /// @dev A FundingRequest represents a borrowers desire to raise funds for a loan. (Double linked list)
    struct FundingRequest {
        uint256 id; //id of the funding request
        address borrower; //the borrower who created the funding request
        uint256 amount; //the amount to be raised denominated in LendingPoolTokens
        uint256 durationDays; //duration of the underlying loan in days
        uint256 interestRate; //interest rate of the underlying  loan (2 decimals)
        uint256 amountFilled; //amount that has already been filled by primary funders
        FundingRequestState state; //state of the funding request
        uint256 next; //id of the next funding request
        uint256 prev; //id of the previous funding request
    }

    /// @dev State of a FundingRequest
    enum FundingRequestState {
        OPEN, //the funding request is open and ready to be filled
        FILLED, //the funding request has been filled completely
        CANCELLED //the funding request has been cancelled
    }

    /// @dev modifier to make function callable by borrower only
    modifier onlyBorrower(FundingStorage storage fundingStorage) {
        require(fundingStorage.borrowers[msg.sender], "caller address is no borrower");
        _;
    }

    /// @dev Get all open FundingRequests
    /// @param fundingStorage FundingStorage
    /// @return all open FundingRequests
    function getOpenFundingRequests(FundingStorage storage fundingStorage) external view returns (FundingRequest[] memory) {
        FundingRequest[] memory fundingRequests = new FundingRequest[](fundingStorage.lastFundingRequestId - fundingStorage.currentFundingRequestId + 1);
        uint256 i = fundingStorage.currentFundingRequestId;
        for (; i <= fundingStorage.lastFundingRequestId; i++) {
            fundingRequests[i - fundingStorage.currentFundingRequestId] = fundingStorage.fundingRequests[i];
        }
        return fundingRequests;
    }

    /// @dev Allows borrowers to submit a FundingRequest
    /// @param fundingStorage FundingStorage
    /// @param amount the amount to be raised denominated in LendingPoolTokens
    /// @param durationDays duration of the underlying loan in days
    /// @param interestRate interest rate of the underlying loan (2 decimals)
    function addFundingRequest(
        FundingStorage storage fundingStorage,
        uint256 amount,
        uint256 durationDays,
        uint256 interestRate
    ) public onlyBorrower(fundingStorage) {
        require(amount > 0 && durationDays > 0 && interestRate > 0, "invalid funding request data");

        uint256 previousFundingRequestId = fundingStorage.lastFundingRequestId;

        uint256 fundingRequestId = ++fundingStorage.lastFundingRequestId;

        if (previousFundingRequestId != 0) {
            fundingStorage.fundingRequests[previousFundingRequestId].next = fundingRequestId;
        }

        emit FundingRequestAdded(fundingRequestId, msg.sender, amount, durationDays, interestRate);

        fundingStorage.fundingRequests[fundingRequestId] = FundingRequest(
            fundingRequestId,
            msg.sender,
            amount,
            durationDays,
            interestRate,
            0,
            FundingRequestState.OPEN,
            0,
            previousFundingRequestId
        );

        if (fundingStorage.currentFundingRequestId == 0) {
            fundingStorage.currentFundingRequestId = fundingStorage.lastFundingRequestId;
        }
    }

    /// @dev Allows borrowers to cancel their own funding request as long as it has not been partially or fully filled
    /// @param fundingStorage FundingStorage
    /// @param fundingRequestId the id of the funding request to cancel
    function cancelFundingRequest(FundingStorage storage fundingStorage, uint256 fundingRequestId) public onlyBorrower(fundingStorage) {
        require(fundingStorage.fundingRequests[fundingRequestId].id != 0, "funding request not found");
        require(fundingStorage.fundingRequests[fundingRequestId].state == FundingRequestState.OPEN, "funding request already processing");

        emit FundingRequestCancelled(fundingRequestId);

        fundingStorage.fundingRequests[fundingRequestId].state = FundingRequestState.CANCELLED;

        FundingRequest storage currentRequest = fundingStorage.fundingRequests[fundingRequestId];

        if (currentRequest.prev != 0) {
            fundingStorage.fundingRequests[currentRequest.prev].next = currentRequest.next;
        }

        if (currentRequest.next != 0) {
            fundingStorage.fundingRequests[currentRequest.next].prev = currentRequest.prev;
        }

        uint256 saveNext = fundingStorage.fundingRequests[fundingRequestId].next;
        fundingStorage.fundingRequests[fundingRequestId].prev = 0;
        fundingStorage.fundingRequests[fundingRequestId].next = 0;

        if (fundingStorage.currentFundingRequestId == fundingRequestId) {
            fundingStorage.currentFundingRequestId = saveNext; // can be zero which is fine
        }
    }

    /// @dev Allows primary funders to fund borrowers fundingRequests. In return for their
    ///      funding they receive LendingPoolTokens based on the rate provided by the configured ChainLinkFeed
    /// @param fundingStorage FundingStorage
    /// @param fundingToken token used for the funding (e.g. USDC)
    /// @param fundingTokenAmount funding amount
    /// @param lendingPoolToken the LendingPoolToken which will be minted to the funders wallet in return
    function fund(
        FundingStorage storage fundingStorage,
        IERC20 fundingToken,
        uint256 fundingTokenAmount,
        LendingPoolToken lendingPoolToken
    ) public {
        require(fundingStorage.primaryFunders[msg.sender] || fundingStorage.disablePrimaryFunderCheck, "address is not primary funder");
        require(fundingStorage.fundingTokens[fundingToken], "unrecognized funding token");
        require(fundingStorage.currentFundingRequestId != 0, "no active funding request");

        (uint256 exchangeRate, uint256 exchangeRateDecimals) = getExchangeRate(fundingStorage, fundingToken);
        uint256 lendingPoolTokenAmount = ((Util.convertDecimalsERC20(fundingTokenAmount, fundingToken, lendingPoolToken) * (uint256(10)**exchangeRateDecimals)) / exchangeRate);

        FundingRequest storage currentFundingRequest = fundingStorage.fundingRequests[fundingStorage.currentFundingRequestId];
        uint256 currentFundingNeed = currentFundingRequest.amount - currentFundingRequest.amountFilled;

        require(lendingPoolTokenAmount <= currentFundingNeed, "amount exceeds requested funding");
        Util.checkedTransferFrom(fundingToken, msg.sender, currentFundingRequest.borrower, fundingTokenAmount);
        currentFundingRequest.amountFilled += lendingPoolTokenAmount;

        if (currentFundingRequest.amount == currentFundingRequest.amountFilled) {
            currentFundingRequest.state = FundingRequestState.FILLED;

            fundingStorage.currentFundingRequestId = currentFundingRequest.next; // this can be zero which is ok
        }

        lendingPoolToken.mint(msg.sender, lendingPoolTokenAmount);
        emit Funded(msg.sender, fundingToken, fundingTokenAmount, lendingPoolTokenAmount);
    }

    /// @dev Returns an exchange rate to convert from a funding token to the pools underlying loan currency
    /// @param fundingStorage FundingStorage
    /// @param fundingToken the fundingToken
    /// @return the exchange rate and the decimals of the exchange rate
    function getExchangeRate(FundingStorage storage fundingStorage, IERC20 fundingToken) public view returns (uint256, uint8) {
        require(address(fundingStorage.fundingTokenChainLinkFeeds[fundingToken]) != address(0), "no exchange rate available");

        (, int256 exchangeRate, , , ) = fundingStorage.fundingTokenChainLinkFeeds[fundingToken].latestRoundData();
        require(exchangeRate != 0, "zero exchange rate");

        uint8 exchangeRateDecimals = fundingStorage.fundingTokenChainLinkFeeds[fundingToken].decimals();

        if (fundingStorage.invertChainLinkFeedAnswer[fundingToken]) {
            exchangeRate = int256(10**(exchangeRateDecimals * 2)) / exchangeRate;
        }

        return (uint256(exchangeRate), exchangeRateDecimals);
    }

    /// @dev Maps a funding token to a ChainLinkFeed
    /// @param fundingStorage FundingStorage
    /// @param fundingToken the fundingToken
    /// @param fundingTokenChainLinkFeed the ChainLink price feed
    /// @param invertChainLinkFeedAnswer whether the rate returned by the chainLinkFeed needs to be inverted to match the token-currency pair order
    function setFundingTokenChainLinkFeed(
        FundingStorage storage fundingStorage,
        IERC20 fundingToken,
        AggregatorV3Interface fundingTokenChainLinkFeed,
        bool invertChainLinkFeedAnswer
    ) external {
        fundingStorage.fundingTokenChainLinkFeeds[fundingToken] = fundingTokenChainLinkFeed;
        fundingStorage.invertChainLinkFeedAnswer[fundingToken] = invertChainLinkFeedAnswer;
    }

    /// @dev Set whether a token should be accepted for funding the pool
    /// @param fundingStorage FundingStorage
    /// @param fundingToken the token
    /// @param accepted whether it is accepted
    function setFundingToken(
        FundingStorage storage fundingStorage,
        IERC20 fundingToken,
        bool accepted
    ) public {
        if (fundingStorage.fundingTokens[fundingToken] != accepted) {
            fundingStorage.fundingTokens[fundingToken] = accepted;
            emit FundingTokenUpdated(fundingToken, accepted);
            if (accepted) {
                fundingStorage._fundingTokens.push(fundingToken);
            } else {
                Util.removeValueFromArray(fundingToken, fundingStorage._fundingTokens);
            }
        }
    }

    /// @dev Change primaryFunder status of an address
    /// @param fundingStorage FundingStorage
    /// @param primaryFunder the address
    /// @param accepted whether its accepted as primaryFunder
    function setPrimaryFunder(
        FundingStorage storage fundingStorage,
        address primaryFunder,
        bool accepted
    ) public {
        if (fundingStorage.primaryFunders[primaryFunder] != accepted) {
            fundingStorage.primaryFunders[primaryFunder] = accepted;
            emit PrimaryFunderUpdated(primaryFunder, accepted);
        }
    }

    /// @dev Change borrower status of an address
    /// @param fundingStorage FundingStorage
    /// @param borrower the borrower address
    /// @param accepted whether the address is a borrower
    function setBorrower(
        FundingStorage storage fundingStorage,
        address borrower,
        bool accepted
    ) public {
        if (fundingStorage.borrowers[borrower] != accepted) {
            fundingStorage.borrowers[borrower] = accepted;
            emit BorrowerUpdated(borrower, accepted);
            if (fundingStorage.borrowers[msg.sender]) {
                fundingStorage.borrowers[msg.sender] = false;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

library Util {
    /// @dev Return the decimals of an ERC20 token (if the implementations offers it)
    /// @param _token (IERC20) the ERC20 token
    /// @return  (uint8) the decimals
    function getERC20Decimals(IERC20 _token) internal view returns (uint8) {
        return IERC20Metadata(address(_token)).decimals();
    }

    function checkedTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        require(amount > 0, "checkedTransferFrom: amount zero");
        uint256 balanceBefore = token.balanceOf(to);
        token.transferFrom(from, to, amount);
        uint256 receivedAmount = token.balanceOf(to) - balanceBefore;
        require(receivedAmount == amount, "checkedTransferFrom: not amount");
        return receivedAmount;
    }

    /// @dev A checked Token transfer; raises if the token transfer amount is not equal to the transferred amount
    /// this might happen if the token ERC20 contract is hacked
    /// @param token (address) the address of the ERC20 token to transfer
    /// @param to (address) receiver address
    /// @param amount (uint256) the desired amount to transfer
    /// @return  (uint256) the received amount that was transferred
    /// IMPORTANT: the return value will only be returned to another smart contract,
    /// but never to the testing environment, because if the transaction goes through,
    /// a receipt is returned and not a (uint256)
    function checkedTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        require(amount > 0, "checkedTransfer: amount zero");
        uint256 balanceBefore = token.balanceOf(to);
        token.transfer(to, amount);
        uint256 receivedAmount = token.balanceOf(to) - balanceBefore;
        require(receivedAmount == amount, "checkedTransfer: not amount");
        return receivedAmount;
    }

    /// @dev Converts a number from one decimal precision to the other
    /// @param _number (uint256) the number
    /// @param _currentDecimals (uint256) the current decimals of the number
    /// @param _targetDecimals (uint256) the desired decimals for the number
    /// @return  (uint256) the number with _targetDecimals decimals
    function convertDecimals(
        uint256 _number,
        uint256 _currentDecimals,
        uint256 _targetDecimals
    ) internal pure returns (uint256) {
        uint256 diffDecimals;

        uint256 amountCorrected = _number;

        if (_targetDecimals < _currentDecimals) {
            diffDecimals = _currentDecimals - _targetDecimals;
            amountCorrected = _number / (uint256(10)**diffDecimals);
        } else if (_targetDecimals > _currentDecimals) {
            diffDecimals = _targetDecimals - _currentDecimals;
            amountCorrected = _number * (uint256(10)**diffDecimals);
        }

        return (amountCorrected);
    }

    /// @dev Converts a number from one decimal precision to the other based on two ERC20 Tokens
    /// @param _number (uint256) the number
    /// @param _sourceToken (address) the source ERC20 Token
    /// @param _targetToken (address) the target ERC20 Token
    /// @return  (uint256) the number with _targetDecimals decimals
    function convertDecimalsERC20(
        uint256 _number,
        IERC20 _sourceToken,
        IERC20 _targetToken
    ) internal view returns (uint256) {
        return convertDecimals(_number, getERC20Decimals(_sourceToken), getERC20Decimals(_targetToken));
    }

    function removeValueFromArray(IERC20 value, IERC20[] storage array) internal {
        bool shift = false;
        uint256 i = 0;
        while (i < array.length - 1) {
            if (array[i] == value) shift = true;
            if (shift) {
                array[i] = array[i + 1];
            }
            i++;
        }
        array.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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