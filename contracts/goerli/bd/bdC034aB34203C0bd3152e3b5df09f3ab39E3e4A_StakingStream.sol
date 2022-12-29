// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IERC20Token { //WBNB, ANN
    function transferFrom(address _from,address _to, uint _value) external returns (bool success);
    function balanceOf(address _owner) external returns (uint balance);
    function transfer(address _to, uint256 _amount) external returns (bool);
}

contract StakingStream is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private stakingId;
    
    /// @dev Staking token
    address public fiximToken;
    address public usdtToken;

    /// @dev Info about each stake by staking id
    mapping(uint256 => Stake) public stakings;
    mapping(uint256 => uint256[]) public usersStakings;
    mapping(uint256 => uint256) public dailyProfits;
    mapping(uint256 => uint256) public withdrawnProfit;

    /// @dev Events
    event Staked(uint256 stakeId);
    event Unstaked(uint256 stakeId, uint256 amount);
    event WithDrawnProfit(address user, uint256 amount);

    /// @dev Total shares
    uint256 public totalShares;
    // uint256 public secondsInDay = 86400;
    uint256 public secondsInDay = 10;

    struct Stake {
        bool unstaked;
        uint256 amount;
        uint48 stakedTimestamp;
        uint256 profit;
        address user;
        uint16 period;
        uint256 percentage;
        uint256 dailyProfit;
    }
    struct StakeData {
        uint256 amount;
        uint256 shares;
        uint16 period;
        uint256 percentage;
        uint256 userId;
    }
    struct UnstakeData {
        uint256 stakingId;
        address user;
    }
    struct WithdrawProfitData {
        uint256 userId;
        uint256 amount;
        address user;
        uint8 token;
        uint256 fiximAmount;
    }

    /**
     * @notice Initializer
     * @param _fiximToken Staking token address
     */
    constructor(address _fiximToken, address _usdtToken) {
        require(address(_fiximToken) != address(0) && address(_usdtToken) != address(0), "StakingStream: staking token is the zero address");
        fiximToken = _fiximToken;
    }

    /**
     * @notice Stake staking tokens
     * @param _stakeData amount to stake
     */
    function stake(StakeData memory _stakeData) external {
        require(_stakeData.amount > 0, "StakingStream: Staking amount is required");
        uint256 _stakingId = stakingId.current();
        stakingId.increment();
        transferFromERC20ToOwner(msg.sender, address(this), _stakeData.amount, fiximToken);
        uint256 profitValue = calculateProfitValue(_stakeData.amount, _stakeData.percentage);
        uint256 dailyProfitValue = calculateDailyProfitAmount(profitValue, _stakeData.period);
        uint256 mintAmount = _stakeData.amount+profitValue;
        totalShares += mintAmount;
        usersStakings[_stakeData.userId].push(_stakingId);
        dailyProfits[_stakingId] = dailyProfitValue;
        stakings[_stakingId] = Stake(
            false,
            _stakeData.amount,
            uint48(getCurrentTime()),
            profitValue,
            msg.sender,
            _stakeData.period,
            _stakeData.percentage,
            dailyProfitValue
        );
        emit Staked(_stakingId);
    }

    /**
     * @notice Unstake staking tokens + reward amount associated with staking
     * @notice If penalty period is not over grab penalty
     */
    function Unstake(UnstakeData memory _unstakeData) external onlyOwner {
        Stake storage stakeRef = stakings[_unstakeData.stakingId];
        require(stakeRef.stakedTimestamp != 0, "StakingStream: nothing is staked");
        require(stakeRef.stakedTimestamp + uint48(stakeRef.period) * secondsInDay < getCurrentTime(), "StakingStream: Can't unstake yet");
        require(!stakeRef.unstaked, "StakingStream: unstaked already");
        // _burn(_unstakeData.user, stakeRef.amount);
        totalShares -= stakeRef.amount;
        stakeRef.unstaked = true;
        transferERC20ToOwner(address(this), _unstakeData.user, stakeRef.amount, fiximToken);
        emit Unstaked(_unstakeData.stakingId, stakeRef.amount);
    }

    function withdrawProfit(WithdrawProfitData memory _withdrawProfitData) external onlyOwner {
        uint256 availableProfit = calculateAvailableProfit(_withdrawProfitData.userId);
        require(availableProfit >= _withdrawProfitData.amount, "StakingStream: This Much Profit Not Available");
        // _burn(_withdrawProfitData.user, _withdrawProfitData.amount);
        totalShares -= _withdrawProfitData.amount;
        uint256 onePercent = calculateProfitValue(_withdrawProfitData.amount, 1);
        uint256 profitToTransfer = _withdrawProfitData.amount - onePercent;
        address tokenAddress = address(0);
        if(_withdrawProfitData.token==2) {
            tokenAddress = fiximToken;
        } else {
            tokenAddress = usdtToken;
        }
        transferERC20ToOwner(address(this), _withdrawProfitData.user, profitToTransfer, tokenAddress);
        // fiximToken.safeTransfer(_withdrawProfitData.user, profitToTransfer);
        withdrawnProfit[_withdrawProfitData.userId] = withdrawnProfit[_withdrawProfitData.userId] + _withdrawProfitData.fiximAmount;
        emit WithDrawnProfit(_withdrawProfitData.user, _withdrawProfitData.fiximAmount);
    }

    /**
     * @dev calculate profile associated with any staking
     */
    function calculateProfitValue(uint256 total, uint256 percent) pure private returns(uint256) {
        uint256 division = total * percent;
        uint256 percentValue = division / 100;
        return percentValue;
    }

    /**
     * @dev calculate daily profile associated with any staking
     */
    function calculateDailyProfitAmount(uint256 total, uint16 period) pure private returns(uint256) {
        uint256 dailyProfit = total / period;
        return dailyProfit;
    }

    /**
     * @dev calculate current profile in accordance with days
     */
    function calculateAvailableProfit(uint256 user) public view returns(uint256) {
        uint256[] memory userCurrentstakings = usersStakings[user];
        uint256 currentWithdrawnProfit = withdrawnProfit[user];
        uint256 availableRewards = 0;
        Stake storage stakeRef;
        for(uint256 i= 0; i<userCurrentstakings.length; i++) {
            stakeRef = stakings[userCurrentstakings[i]];
            uint256 stakedDays = secondsIntoDays(getCurrentTime() - stakeRef.stakedTimestamp);
            if(stakedDays > stakeRef.period) {
                stakedDays = stakeRef.period;
            }
            availableRewards += ( stakeRef.dailyProfit * stakedDays);
        }
        return availableRewards - currentWithdrawnProfit;
    }

    /**
     * @dev claim referral rewards
     */
    function claimReferralReward(uint256 _amount) external {
        // fiximToken.safeTransfer(msg.sender, _amount);
        transferERC20ToOwner(address(this), msg.sender, _amount, fiximToken);
    }

    function transferFromERC20ToOwner(address from, address to, uint256 amount, address tokenAddress) private {
        IERC20Token token = IERC20Token(tokenAddress);
        uint256 balance = token.balanceOf(from);
        require(balance >= amount, "insufficient balance" );
        token.transferFrom(from, to, amount);
    }
    function transferERC20ToOwner(address from, address to, uint256 amount, address tokenAddress) private {
        IERC20Token token = IERC20Token(tokenAddress);
        uint256 balance = token.balanceOf(from);
        require(balance >= amount, "insufficient balance" );
        token.transfer(to, amount);
    }

    // ** ONLY OWNER **
    /**
     * @notice Set a new penalty base points value
     * @param _penaltyBP New penalty base points value
     */
    // function setPenaltyBP(uint16 _penaltyBP) external onlyOwner {
    //     require(_penaltyBP <= PENALTY_BP_LIMIT, "StakingStream: penalty BP exceeds limit");
    //     penaltyBP = _penaltyBP;
    //     emit SetPenaltyBP(_penaltyBP);
    // }
    

    // ** INTERNAL **

    /// @dev disable transfers
    // function _transfer(address _from, address _to, uint256 _amount) internal override {
    //     revert("StakingStream: NON_TRANSFERABLE");
    // }

    function getCurrentTime()
        internal
        virtual
        view
        returns(uint256){
        return block.timestamp;
    }

    function secondsIntoDays(uint256 _seconds)
        internal
        virtual
        view
        returns(uint256) {
        return _seconds/secondsInDay;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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