pragma solidity 0.8.13;

import "../models/Staker.sol";
import "../models/Entry.sol";
import { IGoldIo } from "../interfaces/IGoldIo.sol";
import { IUSDG } from "../interfaces/IUSDG.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StakeVaultTwoYear is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    uint public constant DISTRIBUTION_PERIOD = 28 days;
    uint public constant STAKING_PERIOD = 730 days;
    uint public constant TOTAL_PERCENTAGE = 100 ether; // 100%
    uint public constant ONE_ETH = 1 ether;
    address public PORTAL_GUARD; // Web3 Dapp Portal guard
    address public GOLD_GUARD; // GoldIo contract guard
    address public FEE_GUARD; // Fee Distribution contract guard
    address public FEE_VAULT;

    IUSDG public rewardsToken; // USDG
    IGoldIo public stakingToken; // GOLDIO
    uint public periodFinish = 0;
    uint public rewardRate = 0;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;

    mapping(address => uint) public UserRewardPerTokenPaid;
    mapping(address => uint) public Rewards;
    mapping(address => Staker) public Stakers;

    uint private _totalStakers;
    uint private _totalSupply;
    mapping(address => uint) private _balances;

    event RewardAdded(uint reward);
    event Staked(address indexed user, uint amount);
    event StakedForOwner(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event WithdrawnWithFee(address indexed user, uint stakedAmount, uint fee);
    event UnStaked(address indexed user, uint amount);
    event UnStakedWithFee(address indexed user, uint stakedAmount, uint fee);
    event RewardPaid(address indexed user, uint reward);
    event Recovered(address token, uint amount);

    constructor(address _portalGuard, address _feeVault, address _rewardToken, address _stakeToken) public {
        PORTAL_GUARD = _portalGuard;
        FEE_VAULT = _feeVault;
        rewardsToken = IUSDG(_rewardToken);
        stakingToken = IGoldIo(_stakeToken);
        GOLD_GUARD = _stakeToken;
    }

    /**
    * @dev Only the owner of our FeeDistribution contract can call this function.
    */
    modifier onlyOwnerOrFeeDistributor {
        require(owner() == _msgSender() || FEE_GUARD == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
    * @dev Only our portal guard has permission to call this functions
    */
    modifier onlyGuard {
        require(_msgSender() == PORTAL_GUARD, "Error: Only portal guard can call this function.");
        _;
    }

    /**
    * @dev Only GoldIo contract has permission to call this functions
    */
    modifier onlyGoldContract {
        require(_msgSender() == GOLD_GUARD, "Error: Only gold contract can call this function.");
        _;
    }

    /**
    * @dev Update reward for account
    */
    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_account != address(0)) {
            Rewards[_account] = earned(_account);
            UserRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    /**
    * @notice get number of total stakers;
    */
    function totalStakers() external view returns (uint) {
        return _totalStakers;
    }

    /**
    * @notice get totalSupply of GIO staked. This amount
    * represents the total GOLD in the vault
    */
    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }

    /**
    * @notice get GIO staked for an account
    * @param _account the account
    */
    function balanceOf(address _account) external view returns (uint) {
        return _balances[_account];
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    /**
    * @notice Get USDG reward for user, set to 0 and transfer the USDG
    */
    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + ((((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate) * ONE_ETH) / _totalSupply);
    }

    /**
    * @notice earned rewards based on account
    * @param _account the account
    */
    function earned(address _account) public view returns (uint) {
        return ((_balances[_account] * (rewardPerToken() - UserRewardPerTokenPaid[_account])) / ONE_ETH) + Rewards[_account];
    }

    /**
    * @notice get rewards for the reward duration
    */
    function getRewardForDuration() public view returns (uint) {
        return rewardRate * DISTRIBUTION_PERIOD;
    }

    /**
     * @dev returns list of stake entries for sender
     * @notice when user unstake an entry is set to 0. To exclude this entry
     * from the list, we need to check if the entry is 0 or not.
     * then it's added to a new list and returned.
     */
    function getEntryIndexer() public view returns(uint[] memory) {
        return Stakers[_msgSender()].entryIndexer;
    }

    /**
     * @dev returns list of stake entries for sender
     * @notice when user unstake an entry is set to 0. To exclude this entry
     * from the list, we need to check if the entry is 0 or not.
     * then it's added to a new list and returned.
     * @param _goldOwner the owner of the gold
     */
    function getEntryIndexerForAddress(address _goldOwner) onlyGuard public view returns(uint[] memory) {
        return Stakers[_goldOwner].entryIndexer;
    }

    /**
     * @dev returns the stake entry for sender
     * @param _entryId id of the entry
     */
    function getStakeEntry(uint _entryId) nonReentrant external returns(Entry memory) {
        _validEntry(_msgSender(), _entryId);
        return Stakers[_msgSender()].entries[_entryId];
    }

    /**
     * @dev returns the stake entry for sender
     * @param _goldOwner the owner of the gold
     * @param _entryId id of the entry
     */
    function getStakeEntryForAddress(address _goldOwner, uint _entryId) onlyGuard nonReentrant external returns(Entry memory) {
        _validEntry(_goldOwner, _entryId);
        return Stakers[_goldOwner].entries[_entryId];
    }

    /**
    * @dev this function is called by the GoldIo contract
    * @notice when a user brings in gold, the GIO token get staked for 1 year
    * @param _goldContract address of the GoldIo token contract
    * @param _goldOwner address of the GoldIo owner
    * @param _amount the amount
    * @param _usdgAmount the amount of USDG
    */
    function portalGuardStake(
        address _goldContract,
        address _goldOwner,
        uint _amount,
        uint _usdgAmount
    ) external nonReentrant onlyGoldContract updateReward(_goldOwner) returns (bool) {
        require(_amount > 0, "Error: Amount must be > 0");
        require(stakingToken.allowance(_goldContract, address(this)) >= _amount,
            "Error: Transfer of token has not been approved");

        if (_balances[_goldOwner] == 0 && Stakers[_goldOwner].totalStaked == 0) {
            _totalStakers++;
        }

        // Add Stake Entry
        uint entryId = Stakers[_goldOwner].entryIndexer.length + 1;
        Stakers[_goldOwner].totalStaked += _amount;
        Stakers[_goldOwner].entryIndexer.push(entryId);
        Stakers[_goldOwner].entries[entryId].amount += _amount;
        Stakers[_goldOwner].entries[entryId].startDate = block.timestamp;
        Stakers[_goldOwner].entries[entryId].endDate = block.timestamp + STAKING_PERIOD;

        _totalSupply += _amount;
        _balances[_goldOwner] += _amount;

        stakingToken.transferFrom(_goldContract, address(this), _amount);
        rewardsToken.portalMint(owner(), _usdgAmount);

        emit StakedForOwner(_goldOwner, _amount);
        return true;
    }

    /**
    * @dev GIO holders can stake their GIO tokens for the staking period
    * @notice when users has GIO in their wallet and want to restake their GIO tokens
    * @param _amount the amount
    */
    function stake(uint _amount) external nonReentrant updateReward(_msgSender()) {
        require(_amount > 0, "Error: Amount must be > 0");
        require(stakingToken.allowance(_msgSender(), address(this)) >= _amount , "Error: Transfer of token has not been approved");

        if (_balances[_msgSender()] == 0 && Stakers[_msgSender()].totalStaked == 0) {
            _totalStakers++;
        }

        uint entryId = Stakers[_msgSender()].entryIndexer.length + 1;
        Stakers[_msgSender()].totalStaked += _amount;
        Stakers[_msgSender()].entryIndexer.push(entryId);
        Stakers[_msgSender()].entries[entryId].amount += _amount;
        Stakers[_msgSender()].entries[entryId].startDate = block.timestamp;
        Stakers[_msgSender()].entries[entryId].endDate = block.timestamp + STAKING_PERIOD;

        _totalSupply += _amount;
        _balances[_msgSender()] += _amount;

        stakingToken.transferFrom(_msgSender(), address(this), _amount);
        emit Staked(_msgSender(), _amount);
    }

    /**
    * @dev this function is only callable by the portal guard
    * @notice when user withdraws their gold from the vault, we burn the GIO tokens
    * @param _goldOwner address of the gold owner
    * @param _usdgAmount the amount of usdg tokens
    * @param _entryId id of the entry
    */
    function portalGuardWithdraw(
        address _goldOwner,
        uint _usdgAmount,
        uint _entryId
    ) external nonReentrant onlyGuard updateReward(_goldOwner) returns(bool) {
        _validEntry(_goldOwner, _entryId);
        require(Stakers[_goldOwner].entries[_entryId].amount > 0, "Error: Empty entry");
        require(Stakers[_goldOwner].totalStaked >= Stakers[_goldOwner].entries[_entryId].amount, "Error: Cannot withdraw more than staked");

        uint gioAmount = Stakers[_goldOwner].entries[_entryId].amount;
        Stakers[_goldOwner].entries[_entryId].amount = 0;

        bool takeEarlyUnstakeFee = false;
        if (Stakers[_goldOwner].entries[_entryId].endDate > block.timestamp) {
            takeEarlyUnstakeFee = true;
        }

        // When owner withdraws the gold before the entry end date, we take a the rewards the owner has earned as a fee
        uint userRewardsAsFee = 0;
        if (takeEarlyUnstakeFee) {
            userRewardsAsFee = Rewards[_goldOwner];
            Rewards[_goldOwner] = 0;
        }
        _totalSupply -= gioAmount;
        _balances[_goldOwner] -= gioAmount;

        Stakers[_goldOwner].totalStaked -= gioAmount;

        if (_balances[_goldOwner] == 0 && Stakers[_goldOwner].totalStaked == 0) {
            _totalStakers--;
        }

        if (Rewards[_goldOwner] > 0) {
            // transfer USDG reward to goldOwner
            _getRewardForGoldOwner(_goldOwner);
        }

        // transfer GIO to the goldOwner and burn them afterwards
        // TODO: check if this is correct
        //        stakingToken.transfer(_goldOwner, tokensReturned);
        stakingToken.stakeBurn(address(this), gioAmount);
        rewardsToken.stakeBurn(owner(), _usdgAmount);

        if (userRewardsAsFee > 0) {
            rewardsToken.transfer(FEE_VAULT, userRewardsAsFee);
            emit WithdrawnWithFee(_goldOwner, gioAmount, userRewardsAsFee);
        } else {
            emit Withdrawn(_goldOwner, gioAmount);
        }

        return true;
    }

    /**
    * @dev User unstaked their GIO tokens
    * @notice when user unstake GIO and endDate is not reached, we take the rewards as fee
    * the gold of the user is still in our vault
    * @param _entryId entry id
    */
    function unStake(uint _entryId) external nonReentrant updateReward(_msgSender()) {
        _validEntry(_msgSender(), _entryId);
        require(Stakers[_msgSender()].entries[_entryId].amount > 0, "Error: Empty entry");
        require(Stakers[_msgSender()].totalStaked >= Stakers[_msgSender()].entries[_entryId].amount, "Error: Cannot withdraw more than staked");

        uint gioAmount = Stakers[_msgSender()].entries[_entryId].amount;
        Stakers[_msgSender()].entries[_entryId].amount = 0;

        bool takeEarlyUnstakeFee = false;
        if (Stakers[_msgSender()].entries[_entryId].endDate > block.timestamp) {
            takeEarlyUnstakeFee = true;
        }

        uint userRewardsAsFee = 0;
        if (takeEarlyUnstakeFee) {
            userRewardsAsFee = Rewards[_msgSender()];
            Rewards[_msgSender()] = 0;
        }

        _totalSupply -= gioAmount;
        _balances[_msgSender()] -= gioAmount;

        Stakers[_msgSender()].totalStaked -= gioAmount;

        if (_balances[_msgSender()] == 0 && Stakers[_msgSender()].totalStaked == 0) {
            _totalStakers--;
        }

        // transfer back goldio tokens to gold owner
        stakingToken.transfer(_msgSender(), gioAmount);

        if (Rewards[_msgSender()] > 0) {
            // transfer USDG reward to goldOwner
            _getRewardForCaller();
        }

        if (userRewardsAsFee > 0) {
            rewardsToken.transfer(FEE_VAULT, userRewardsAsFee);
            emit UnStakedWithFee(_msgSender(), gioAmount, userRewardsAsFee);
        } else {
            emit UnStaked(_msgSender(), gioAmount);
        }
    }

    /**
     * @dev Only owner function to notifyRewardAmount
     * @notice notifyRewardAmount
     * @param _reward the reward amount
    */
    function notifyRewardAmount(uint _reward) external onlyOwnerOrFeeDistributor updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = _reward / DISTRIBUTION_PERIOD;
        } else {
            uint remaining = periodFinish - block.timestamp;
            uint leftover = remaining * rewardRate;
            rewardRate = (_reward + leftover) / DISTRIBUTION_PERIOD;
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance / DISTRIBUTION_PERIOD, "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + DISTRIBUTION_PERIOD;
        emit RewardAdded(_reward);
    }

    /**
     * @dev Only owner function to set new feeGuard
     * @notice Set a new feeGuard address
     * @param feeGuard the wallet address of the feeGuard
    */
    function setFeeGuard(address feeGuard) external onlyOwner {
        FEE_GUARD = feeGuard;
    }

    /**
     * @dev Only owner function to set new PortalGuard
     * @notice Set a new portalGuard address
     * @param newPortalGuard the wallet address of the portalGuard
    */
    function setPortalGuard(address newPortalGuard) external onlyOwner {
        PORTAL_GUARD = newPortalGuard;
    }

    /**
     * @dev Only owner function to transfer ERC20 tokens to owner
     * @notice When someone transfers random ERC20 token to this contract, the owner can recover it and
     * sends back to ERC20 token to the user.
     * @param _tokenAddress token address
     * @param _tokenAmount the amount of tokens
    */
    function recoverERC20(address _tokenAddress, uint _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(stakingToken), "Cannot withdraw the staking token");
        IERC20(_tokenAddress).transfer(owner(), _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    /**
     * @dev Only portal guard function
     * @notice When user withdraws gold from the vault, we transfer the USDG reward to the user
     * @param goldOwner address of the goldOwner
    */
    function _getRewardForGoldOwner(address goldOwner) private updateReward(goldOwner) {
        uint reward = Rewards[goldOwner];
        if (reward > 0) {
            Rewards[goldOwner] = 0;
            rewardsToken.transfer(goldOwner, reward);
            emit RewardPaid(goldOwner, reward);
        }
    }

    /**
     * @dev private function called in unStake
     * @notice When user unstakes goldio, we transfer the USDG reward to the user
    */
    function _getRewardForCaller() private updateReward(_msgSender()) {
        uint reward = Rewards[_msgSender()];
        if (reward > 0) {
            Rewards[_msgSender()] = 0;
            rewardsToken.transfer(_msgSender(), reward);
            emit RewardPaid(_msgSender(), reward);
        }
    }

    /**
     * @dev private function to check if the entry is valid
     * @notice When user unstakes or withdraw gold, we check if startDate is set
    */
    function _validEntry(address _goldOwner, uint _entryId) private {
        require(Stakers[_goldOwner].entries[_entryId].startDate <= block.timestamp, "Error: Entry does not exist");
    }
}

pragma solidity 0.8.13;

import "./Entry.sol";

struct Staker {
    uint totalStaked; // total amount of tokens staked
    uint[] entryIndexer; // list of stake entries id
    mapping(uint => Entry) entries; // staking entries
}

pragma solidity 0.8.13;

struct Entry {
    uint amount;
    uint startDate;
    uint endDate;
}

pragma solidity 0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGoldIo is IERC20 {
    function portalBurn(address _from, uint _amount) external;
    function stakeBurn(address _from, uint _amount) external;
}

pragma solidity 0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUSDG is IERC20 {
    function stakeBurn(address from, uint amount) external;
    function portalMint(address to, uint amount) external;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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