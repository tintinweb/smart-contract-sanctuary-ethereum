/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

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


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() public view returns (address) {
        return owner;
    }
}


contract PGX_Vesting is Ownable{
    using SafeMath for uint;
    IERC20 _token;

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
        
    struct TransctionHistory {
        uint datetime;
        uint amount;
    }

    struct TokenBalanceInfo {
        uint locked;
        uint unlocked;
        uint withdrawn;
    }

    struct Beneficiary{
        uint interval;
        uint startDTTM;
        uint endDTTM;
        uint clifAmount;
        uint totalAmount;
        uint duration;
        uint balance;  
        uint withdrawnAmount; 
        uint lastWithdrawnDTTM;
        TransctionHistory [] _transactionHistory;
    }


    mapping(address => Beneficiary) public BeneficiaryDetails;

    constructor(address token_addr){
        _token  = IERC20(token_addr);
    }

    function addBeneficiary(
        address _beneficiaryWalletAddress,
        uint _interval, // uint seconds, will be converted to days later
        uint _vestingDuration, // no of days
        uint _startDTTM,
        uint _endDTTM,
        uint _cliffAmount,
        uint _totalAmount
    ) external onlyOwner {
        require(_interval % SECONDS_PER_DAY == 0, "Interval can only be multiple of 86400 seconds.");
        require(_startDTTM < _endDTTM, "End datetime must be greater than start datetime.");
        require(_cliffAmount > 0, "Cliff amount cannot be zero!");
        require(_vestingDuration > 0, "Vesting duration cannot be zero!");
        uint TotalVestingIntervals = (_interval/SECONDS_PER_DAY) * _vestingDuration;
        require(_cliffAmount * TotalVestingIntervals <= _totalAmount, "cliff_amount * TotalVestingIntervals should be equal to the total vesting amount");
        require(fundThisContract(_totalAmount) == true, 
        "error in funding this contract, approve tokens for this contract or debug the transaction");


        Beneficiary storage _beneficiary = BeneficiaryDetails[_beneficiaryWalletAddress];
        _beneficiary.endDTTM = _endDTTM;
        _beneficiary.withdrawnAmount = 0;
        _beneficiary.startDTTM = _startDTTM;
        _beneficiary.balance = _totalAmount;
        _beneficiary.clifAmount = _cliffAmount;
        _beneficiary.interval = _interval;
        _beneficiary.totalAmount = _totalAmount;
        _beneficiary.lastWithdrawnDTTM = _startDTTM;
        _beneficiary.duration =  _endDTTM - _startDTTM;

    }
    

    function tokensAvailableForWithDraw(address _beneficiaryWalletAddress) private view returns(uint){
        uint _lastWithdrawDTTM =  BeneficiaryDetails[_beneficiaryWalletAddress].lastWithdrawnDTTM;
        uint _endDTTM =  BeneficiaryDetails[_beneficiaryWalletAddress].endDTTM;
        uint _cliffAmount =  BeneficiaryDetails[_beneficiaryWalletAddress].clifAmount;
        uint _balance = BeneficiaryDetails[_beneficiaryWalletAddress].balance;

        require(_cliffAmount > 0 , "Beneficiary account doesnot exists." );
        require(_lastWithdrawDTTM < block.timestamp, "Vesting cycle is not started yet!");

        if (block.timestamp < _endDTTM){
            //calculate number of days elapsed
            uint noOfDays = diffDays(_lastWithdrawDTTM,block.timestamp);
            uint availableTokens = noOfDays * _cliffAmount;
            if(availableTokens >= _balance){
                return _balance;
            }else{
                return availableTokens;
            }
        }else{
            // release all balance tokens
            return  BeneficiaryDetails[_beneficiaryWalletAddress].balance;
        }
    }

    function withdrawTokens() public returns(bool){
        require(beneficiaryAccountExists(msg.sender) == true , "Beneficiary account doesnot exists.");
        uint _availableForWithDraw = tokensAvailableForWithDraw(msg.sender);
        require(_availableForWithDraw > 0 , "No Tokens available to withdraw.");

        // transfer tokens
        _token.transfer(msg.sender,_availableForWithDraw);

        // update lastWithdrawnDTTM to block.timestamp
        uint _bts = block.timestamp;
        BeneficiaryDetails[msg.sender].lastWithdrawnDTTM = _bts - (_bts % SECONDS_PER_DAY);
        
        // update balance 
        BeneficiaryDetails[msg.sender].balance = BeneficiaryDetails[msg.sender].balance.sub(_availableForWithDraw);
        
        // update withdrawnAmount
        BeneficiaryDetails[msg.sender].withdrawnAmount = BeneficiaryDetails[msg.sender].withdrawnAmount.add(_availableForWithDraw);

        // need to create a data-structure to maintain transaction history for every beneficiary

        TransctionHistory memory _th;
        _th.datetime = _bts;
        _th.amount = _availableForWithDraw;

        BeneficiaryDetails[msg.sender]._transactionHistory.push(_th);

        return true;

    }

    function beneficiaryAccountExists(address _beneficiaryWalletAddress) public view returns (bool) {
        uint _cliffAmount =  BeneficiaryDetails[_beneficiaryWalletAddress].clifAmount;
        if(_cliffAmount > 0){
            return true;
        }else{
            return false;
        }
    }

    // Only Beneficiary can view their transaction history
    function getWithdrawHistory(address _walletAddress) public view returns (TransctionHistory[] memory){
        require(beneficiaryAccountExists(_walletAddress) ,"Beneficiary account doesnot exists.");
        require(beneficiaryAccountExists(msg.sender) || msg.sender == getOwner() ,"Caller can only be Owner of the beneficiary itself.");

        return BeneficiaryDetails[_walletAddress]._transactionHistory;
    }

    // Only Beneficiary can view their TokenBalanceInfo
    function getNumberOfLockedUnlockedTokens() public view returns (TokenBalanceInfo memory){
        require(beneficiaryAccountExists(msg.sender) == true,"Beneficiary account doesnot exists");
        TokenBalanceInfo memory _info;
        _info.locked = BeneficiaryDetails[msg.sender].balance;
        _info.unlocked = tokensAvailableForWithDraw(msg.sender);
        _info.withdrawn = BeneficiaryDetails[msg.sender].withdrawnAmount;

        return _info;
    }


    function diffDays(uint fromTimestamp, uint toTimestamp) private pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }



    function getContractBalance() view public returns (uint){
        return _token.balanceOf(address(this));
    }
        
    function fundThisContract (uint256 _amount)  public returns(bool) {
        return _token.transferFrom(msg.sender,address(this),_amount);
    }

}