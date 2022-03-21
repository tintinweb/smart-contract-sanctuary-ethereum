pragma solidity ^0.8.1;


import "./lib/ERC20.sol";
import "./lib/SafeMath.sol";
import "./lib/Ownable.sol";
import "./lib/Address.sol";

// SPDX-License-Identifier: GPL-3.0

/**
 * Interface for DFP contract
 */
interface IDcashDFP {
    function getMonthlyGainsDistribution() external view returns (uint256);
}

contract StakingContract is Ownable {
    using SafeMath for uint;
    using Address for address;

    enum TransactionType { RECEIVE, CLAIM }

    struct StakeInfo {
        uint stakeAmount;
        uint stakeTime;
        uint lastStakeAmount;
        uint lastStakeTime;
        uint lastWithdrawAmount;
        uint lastWithdrawTime;
        bool registered;
        uint totreward;
        uint totclaim;
        uint stalkduration;
        uint stalkinterest;
     }

    struct Transaction {
        uint timestamp;
        TransactionType txType;
        uint amount;
    }

    ERC20 public token;
    ERC20 public daiToken;
 
    bool public isStakingAllowed;

    uint constant MONTH = 30 days;

    uint public DCASH_DECIMALS = 10;

    uint public DAI_DECIMALS = 18;

    uint public totalStakedAmount;

    uint public totalPreviousMonthlyStakedAmount =1;

    // this value should be fetched from DFP contract
    uint public totalMonthlyGain;
    uint public totalcumulatedMonthlyGain;

    // base timestamp that new month started
    uint public newMonthStartTime;

    address[] public stakersList;

    mapping (address => StakeInfo) public stakerLedger;
        
        
    mapping (address => StakeInfo[]) public stakerInfoLedger;
    mapping (address => uint256[]) public userStalk;
    mapping (uint256 => address) public stalkIdUser;
    uint public stalkTokenId;



    mapping (address => uint256) public stakeRewards;
    mapping (address => Transaction[]) public transactions;

    event RequestStake(address indexed _stakerAddress, uint indexed _amount, uint indexed _timestamp);
    event WithdrawStake(address indexed _stakerAddress, uint indexed _amount, uint indexed _timestamp);
    event WithdrawReward(address indexed _stakerAddress, uint indexed _amount);
    event StakingStopped();
    event StakingResumed();
    event WithdrawDcashByAdmin(uint _amount);
    event WithdrawDaiByAdmin(uint _amount);
    event SetMonthlyGainByAdmin(uint _amount);
    event UpdateTokenInfo();
 
    modifier isValidStaker() {
        require(stakerLedger[msg.sender].stakeAmount > 0, "Invalid staker");
        _;
    }

    modifier isStakeAllowed() {
        require(isStakingAllowed, "Staking is currently not allowed");
        _;
    }

    /**
     * Initialize the contract
     */
    constructor (address _token, address _daiAddress , uint _newMonthStartTime) public {
        token = ERC20(_token);
        daiToken = ERC20(_daiAddress);
 
        isStakingAllowed = true;
        newMonthStartTime = _newMonthStartTime;
    }

    /**
     * @dev Function to retrieve the staked DCASH token for the account
     */
    function getStakedAmount() public view returns (uint) {
        return stakerLedger[msg.sender].stakeAmount.add(stakerLedger[msg.sender].lastStakeAmount);
    }

    /**
     * @dev Function to retrieve the total DCASH token
     */
    function getTotalStakedAmount() public view returns (uint) {
        return totalStakedAmount;
    }

    /**
     * @dev Function to retrieve the reward DAI amount for the account
     */
    function getRewardAmount() public view returns (uint) {
        return stakeRewards[msg.sender];
    }

    /**
     * @dev Function to retrieve the history of rewards/claims for user
     */
    function getTransactions() public view returns (uint[] memory, uint[] memory, uint[] memory) {
        uint[] memory timestamps = new uint[](transactions[msg.sender].length);
        uint[] memory types = new uint[](transactions[msg.sender].length);
        uint[] memory amounts = new uint[](transactions[msg.sender].length);

        for (uint i = 0; i < transactions[msg.sender].length; i++) {
            Transaction storage transaction = transactions[msg.sender][i];
            timestamps[i] = transaction.timestamp;
            types[i] = uint(transaction.txType);
            amounts[i] = transaction.amount;
        }

        return (timestamps, types, amounts);
    }

    /**
     * @dev Function to accept stake request using DCASH token
     *
     * @param _stakeAmount uint Stake amount
     */
    


 function stakeToken(uint _stakeAmount, uint duaration) public isStakeAllowed returns (bool) {
        require(_stakeAmount > 0, "Invalid deposit amount");
        require(token.transferFrom(msg.sender, address(this), _stakeAmount  ), "Failed transferFrom for stake");

        uint stalkDuration = 90 days ;
        uint interest = 50;

        if (duaration == 90){
        stalkDuration = 90 days ;
        interest = 50;
        }else if (duaration == 180){
        stalkDuration = 180 days ;
        interest = 70;
        }else if (duaration == 360){
        stalkDuration = 360 days ;
        interest = 100;
        }
        
       stakerInfoLedger[msg.sender].push(StakeInfo(_stakeAmount,
                block.timestamp,
                0,
                0,
                0,
                0,
                true,
                0,
                0,stalkDuration,interest  
            ));

            stalkTokenId = stakerInfoLedger[msg.sender].length - 1;

            stalkIdUser[stalkTokenId] = msg.sender ;
            stakersList.push(msg.sender);
            userStalk[msg.sender].push(stalkTokenId);
            stalkTokenId++;
        // increase total staked amount
        totalStakedAmount += _stakeAmount;

        emit RequestStake(msg.sender, _stakeAmount, block.timestamp);

        return true;
    }

 function getStalkInfo() public view returns (uint[] memory, uint[] memory, uint[] memory, uint[] memory, uint[] memory, uint[] memory) {
     
        uint[] memory timestamps = new uint[](stakerInfoLedger[msg.sender].length);
        uint[] memory types = new uint[](stakerInfoLedger[msg.sender].length);
        uint[] memory amounts = new uint[](stakerInfoLedger[msg.sender].length);
        uint[] memory reward = new uint[](stakerInfoLedger[msg.sender].length);
        uint[] memory claim = new uint[](stakerInfoLedger[msg.sender].length);
        uint[] memory stalkToken = new uint[](stakerInfoLedger[msg.sender].length);

        for (uint i = 0; i < userStalk[msg.sender].length; i++) {

            uint stalkTokenID = userStalk[msg.sender][i];
            StakeInfo storage stalkerInfo = stakerInfoLedger[msg.sender][i];
            timestamps[i] = stalkerInfo.stakeTime;
            types[i] = stalkerInfo.stalkduration;
            amounts[i] = stalkerInfo.stakeAmount;
            reward[i] = stalkerInfo.totreward;
            claim[i] = stalkerInfo.totclaim;
            stalkToken[i] = stalkTokenID;
 
         }

        return (timestamps, types, amounts,reward,claim,stalkToken);
    }


    function withdrawStalkToken(uint _withdrawAmount, uint stalkTokId) public returns (bool) {
        require(_withdrawAmount > 0, "Invalid withdraw amount");
        require(_withdrawAmount <= stakerInfoLedger[msg.sender][stalkTokId].stakeAmount, "Requested withdraw amount exceed available amount");

        // update staking info
        stakerInfoLedger[msg.sender][stalkTokId].stakeAmount = stakerInfoLedger[msg.sender][stalkTokId].stakeAmount.sub(_withdrawAmount);
        stakerInfoLedger[msg.sender][stalkTokId].lastWithdrawAmount = _withdrawAmount;
        stakerInfoLedger[msg.sender][stalkTokId].lastWithdrawTime = block.timestamp;

        // reduce totalStakedAmount
        totalStakedAmount = totalStakedAmount.sub(_withdrawAmount);

        // transfer staked tokens back to owner
        token.transfer(msg.sender, _withdrawAmount);

        emit WithdrawStake(msg.sender, _withdrawAmount, block.timestamp);

        return true;
    }


    function withdrawStalkReward(uint _withdrawAmount, uint stalkTokId) public returns (bool) {
        require(_withdrawAmount > 0, "Invalid withdraw amount");
        require(_withdrawAmount <= stakerInfoLedger[msg.sender][stalkTokId].totreward, "Requested withdraw amount exceed available amount");

        // update staking info
        stakerInfoLedger[msg.sender][stalkTokId].totreward = stakerInfoLedger[msg.sender][stalkTokId].totreward.sub(_withdrawAmount);
        stakerInfoLedger[msg.sender][stalkTokId].totclaim = stakerInfoLedger[msg.sender][stalkTokId].totclaim.add(_withdrawAmount);

        // reduce totalStakedAmount
        stakeRewards[msg.sender] = stakeRewards[msg.sender].sub(_withdrawAmount);

        transactions[msg.sender].push(Transaction(block.timestamp, TransactionType.CLAIM, _withdrawAmount));

        // transfer staked tokens back to owner
        token.transfer(msg.sender, _withdrawAmount);

        emit WithdrawStake(msg.sender, _withdrawAmount, block.timestamp);

        return true;
    }


    function processStalkReward(uint _withdrawAmount, uint stalkTokId) public returns (bool) {

           for (uint i = 0; i < userStalk[msg.sender].length; i++) {

            uint stalkTokenID = userStalk[msg.sender][i];
            StakeInfo storage stalkerInfo = stakerInfoLedger[msg.sender][stalkTokenID];
            uint calreward=0;
            if (!_isRewardStakeLocked( stalkerInfo.stakeTime,stalkerInfo.stalkduration)){

                calreward =  stalkerInfo.stakeAmount.mul(stalkerInfo.stalkinterest).div(1000);
                stalkerInfo.totreward = stalkerInfo.totreward.add(calreward);
                transactions[msg.sender].push(Transaction(block.timestamp, TransactionType.RECEIVE, calreward));
                token.transferFrom(owner, address(this), calreward);

                }
          
            }

        return true;
    }


 function addRewardByAdmin(uint addReward, uint stalkTokId, address useradd) public onlyOwner returns (bool) {
        require(addReward > 0, "Invalid reward amount");
 
        // update staking info
        stakerInfoLedger[useradd][stalkTokId].totreward = stakerInfoLedger[useradd][stalkTokId].totreward.add(addReward);
 
        // reduce totalStakedAmount
        stakeRewards[useradd] = stakeRewards[useradd].add(addReward);

        transactions[useradd].push(Transaction(block.timestamp, TransactionType.RECEIVE, addReward));

        // transfer staked tokens back to owner
        token.transferFrom(owner, address(this), addReward);

        return true;
    }
    /**
     * @dev Function to withdraw staked token back to owner
     *
     * @param _withdrawAmount uint wothdrow amount
     */
     
 
    /**
     * @dev Function to iterate all staking DCASH and calculate rewards
     */


    function _processStake() internal {
        // iterate all stakers
        for (uint8 i = 0; i < stakersList.length; i++) {
            StakeInfo storage stakeInfo = stakerLedger[stakersList[i]];
            if (!_isStakeLocked(stakeInfo.stakeTime) && stakeInfo.stakeAmount > 0) {
                uint newReward = _calculateStakeReward(stakeInfo.stakeAmount);
                stakeRewards[stakersList[i]] = stakeRewards[stakersList[i]].add(newReward);

                // add to transactions
                transactions[stakersList[i]].push(Transaction(block.timestamp, TransactionType.RECEIVE, newReward));
            }

            // process DCASH staked last month
            if (!_isStakeLocked(stakeInfo.lastStakeTime) && stakeInfo.lastStakeAmount > 0) {
                stakeRewards[stakersList[i]] = stakeRewards[stakersList[i]].add(_calculateStakeReward(stakeInfo.lastStakeAmount));

                // upgrade lastStakeAmount
                stakerLedger[stakersList[i]].stakeAmount = stakerLedger[stakersList[i]].stakeAmount.add(stakeInfo.lastStakeAmount);
                stakerLedger[stakersList[i]].lastStakeAmount = 0;
                stakerLedger[stakersList[i]].lastStakeTime = 0;
            }
        }

        // reset newMonthStartTime
        newMonthStartTime = newMonthStartTime + MONTH;
        totalPreviousMonthlyStakedAmount = totalStakedAmount;
    }

    /**
     * @dev Internal function to calculate reward
     */
    function _calculateStakeReward(uint _stakeAmount) internal returns(uint) {
        // get total distribution amount from DFP contract
         totalcumulatedMonthlyGain = totalcumulatedMonthlyGain.add(totalMonthlyGain);


        return _stakeAmount.mul(totalMonthlyGain).div(totalPreviousMonthlyStakedAmount);
    }

    function _isStakeLocked(uint _stakedTime) internal view returns (bool) {
        return _stakedTime + MONTH >= block.timestamp;
    }

     function _isRewardStakeLocked(uint _stakedTime, uint duration) internal view returns (bool) {
        return _stakedTime + duration >= block.timestamp;
    }

    function _isGainedMonth() internal view returns (bool) {
        return totalMonthlyGain > 0;
    }

    /**
     * @dev Adminitstrative to calculate rewards
     */
    function processStake() public onlyOwner {
        require(isStakingAllowed, "Staking is not allowed");
        require(newMonthStartTime + MONTH < block.timestamp, "Earlier than monthly period");

        _processStake();
    }

    /**
     * @dev Adminitstrative to stop or pause staking in emergency case
     */
    function stopStaking() public onlyOwner {
        isStakingAllowed = false;

        emit StakingStopped();
    }

    /**
     * @dev Adminitstrative to resume staking
     */
    function resumeStaking() public onlyOwner {
        isStakingAllowed = true;

        emit StakingResumed();
    }

    /**
     * @dev Adminitstrative to withdraw all DCASH tokens in emergency case
     */
    function withdrawDcashByAdmin() public onlyOwner {
        uint balance = token.balanceOf(address(this));

        require(balance > 0, "No DCASH is left in contract");

        token.transfer(owner, balance * 10**DCASH_DECIMALS);

        emit WithdrawDcashByAdmin(balance);
    }

    /**
     * @dev Adminitstrative to withdraw all DAI stable coins in emergency case
     */
    function withdrawDaiByAdmin() public onlyOwner {
        uint balance = daiToken.balanceOf(address(this));
        require(balance > 0, "No DAI is left in contract");

        daiToken.transfer(owner, balance * 10**DAI_DECIMALS);

        emit WithdrawDaiByAdmin(balance);
    }

    /**
     * @dev Adminitstrative to set monthly gain manually
     *
     * @param _amount uint Amount gained from trading
     */
    function setMonthlyGainManually(uint _amount) public onlyOwner {
        totalMonthlyGain = _amount;
        emit SetMonthlyGainByAdmin(_amount);
    }

    /**
     * Update newMonthStartTime by admin
     */
    function setNewMonthStartTime(uint _newMonthStartTime) public onlyOwner {
        newMonthStartTime = _newMonthStartTime;
    }

    /**
     * @dev Administrative function to update Stablecoin addresses for TUSD/DAI
     *
     * @param _dcashToken address Token address of DCASH
     * @param _dcashDecimals uint Decimals of DCASH
     * @param _daiToken address Token address of DAI
     * @param _daiDecimals uint Decimals of DAI
     */
    function updateTokenInfo(address _dcashToken, uint _dcashDecimals, address _daiToken, uint _daiDecimals) public onlyOwner {
        require(_dcashToken.isContract());
        require(_daiToken.isContract());

        daiToken = ERC20(_daiToken);
        token = ERC20(_dcashToken);

        DCASH_DECIMALS = _dcashDecimals;
        DAI_DECIMALS = _daiDecimals;

        emit UpdateTokenInfo();
    }

    /**
     * @dev Admin function to update DFP contract address
     */
   

    /**
     * @dev Admin function to update totalPreviousMonthlyStakedAmount for the first monthly month.
     */
    function updatetotalPreviousMonthlyStakedAmount(uint _totalPreviousMonthlyStakedAmount) public onlyOwner {

        totalPreviousMonthlyStakedAmount = _totalPreviousMonthlyStakedAmount;

    }


}

pragma solidity ^0.8.1;

import "./SafeMath.sol";

/**
 * @dev Implementation of the `IERC20` interface.
 */

// SPDX-License-Identifier: GPL-3.0

contract ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
    * @dev Destoys `amount` tokens from `account`, reducing the
    * total supply.
    *
    * Emits a `Transfer` event with `to` set to the zero address.
    *
    * Requirements
    *
    * - `account` cannot be the zero address.
    * - `account` must have at least `amount` tokens.
    */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }


    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

pragma solidity ^0.8.1;

// SPDX-License-Identifier: GPL-3.0

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity ^0.8.1;

// SPDX-License-Identifier: GPL-3.0

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized operation");
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Address shouldn't be zero");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type,
 */

 // SPDX-License-Identifier: GPL-3.0

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}