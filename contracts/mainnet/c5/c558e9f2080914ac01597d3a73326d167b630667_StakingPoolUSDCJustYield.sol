/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

// 
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// 
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// 
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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


interface IBEP20Mintable {

    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address _to, uint256 _amount) external returns (bool);
    function burnFrom(address who, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// 
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
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
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
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

contract StakingPoolUSDCJustYield is Ownable, ReentrancyGuard{
    
    using SafeMath for uint256;
    bool public fundsAreSafu = true; // always 
    uint256 public minInvestment = 1000000;
    IBEP20 public poolToken;
    IBEP20 public returnPoolToken;
    uint256 public totalStaked; // keeps track of ALL TIME staked USDC amounts
    uint256 public totalWithdrawn; // keeps track of ALL TIME withdrawn USDC amounts

    event Deposit(uint256 _amount, uint256 _time);
    event BoosterDeposit(uint256 _amount, uint256 _time);
    event WithdrawalRequest(address indexed user, uint256 _amount, uint256 _time);

    struct Account {
        uint256 balance;
        uint256 timestampDeposited;
        uint256 blockWithdrawal;
    }

    struct HistoricalDeposit{
        address user;
        uint256 depositAmount;
        uint256 depositTime;
    }
    struct HistoricalWithdrawal{
        address user;
        uint256 withdrawalAmount;
        uint256 withdrawalTime;
    }

    mapping(address => Account) public deposits;
    HistoricalDeposit[] public historicalDeposits;
    HistoricalWithdrawal[] public historicalWithdrawals;


    mapping(address => bool) public whitelist;
    mapping(address => uint256) public requests;
    mapping(address => uint256) public requestTime;

    address[] public kycdAccounts;
    address[] public requestList; 
    address public secondAdmin;
    address public fireblocksWallet; 

    constructor(IBEP20 _usdc, IBEP20 _yieldUSDC, address _secondAdmin, address _fireblocksWallet) public {
        poolToken = _usdc;
        returnPoolToken = _yieldUSDC;
        secondAdmin = _secondAdmin;
        fireblocksWallet = _fireblocksWallet;
    }


    function changeFireblocksWallet(address _newallet) public onlyAdmins {
        fireblocksWallet = _newallet; 
    }

    // check if owner is admin
    modifier onlyAdmins() {
        require(msg.sender == owner() || msg.sender == secondAdmin, 'Admins: caller is not the admin');
        _;
    }

    function changeSecondAdmin(address _newadmin) public {
        require(msg.sender == secondAdmin, 'invalid address');
        secondAdmin = _newadmin;
    }

    function whitelistBlacklist(address _addr, bool _status) public onlyAdmins{
        whitelist[_addr] = _status;
        if(_status == true){
            kycdAccounts.push(_addr);
        }
    }

    function getKycdWithPagination(uint256 cursor, uint256 howMany) public view returns(address[] memory values, uint256 newCursor){
        uint256 length = howMany;
        if (length > kycdAccounts.length - cursor) {
            length = kycdAccounts.length - cursor;
        }

        values = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = kycdAccounts[cursor + i];
        }

        return (values, cursor + length);
    }

    function getRequestsOpenWithPagination(uint256 cursor, uint256 howMany) public view returns(address[] memory values, uint256 newCursor){
        uint256 length = howMany;
        if (length > requestList.length - cursor) {
            length = requestList.length - cursor;
        }
        values = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = requestList[cursor + i];
        }

        return (values, cursor + length);
    }

    function getHistoricalDeposits(uint256 cursor, uint256 howMany) public view returns(HistoricalDeposit[] memory values, uint256 newCursor){
        uint256 length = howMany;
        if (length > historicalDeposits.length - cursor) {
            length = historicalDeposits.length - cursor;
        }
        values = new HistoricalDeposit[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = historicalDeposits[cursor + i];
        }

        return (values, cursor + length);
    }

    function getHistoricalWithdrawals(uint256 cursor, uint256 howMany) public view returns(HistoricalWithdrawal[] memory values, uint256 newCursor){
        uint256 length = howMany;
        if (length > historicalWithdrawals.length - cursor) {
            length = historicalWithdrawals.length - cursor;
        }
        values = new HistoricalWithdrawal[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = historicalWithdrawals[cursor + i];
        }

        return (values, cursor + length);
    }


    function remove(uint index) internal  returns(bool) {
        if (index >= requestList.length) return false;
        delete requestList[index];
        return true;
    }


    function changeMinInvestment(uint256 _newAmount) public onlyAdmins {
        minInvestment = _newAmount;
    }

    function deposit(uint256 _amount) public nonReentrant {
        require(whitelist[msg.sender] == true, "JustYield: not whitelisted. If you KYCd, contact us");
        require(poolToken.allowance(msg.sender, address(this)) >= _amount, "erc20 not allowed");
        require(_amount >= minInvestment, "min investment not met");
        require(deposits[msg.sender].blockWithdrawal == 0, 'you have already deposited, withdraw first');
        deposits[msg.sender].timestampDeposited = block.timestamp;

        deposits[msg.sender].blockWithdrawal = block.timestamp.add(31560000); // 31,560,000 is 12 months in seconds
        poolToken.transferFrom(msg.sender, fireblocksWallet, _amount); // FIREBLOCKS  0xE5560922cD3A7445067623eDb5c61913E92437B6
        deposits[msg.sender].balance = deposits[msg.sender].balance.add(_amount);
        returnPoolToken.transfer(msg.sender, _amount);
        totalStaked = totalStaked.add(_amount);
        HistoricalDeposit memory info; 
        info.user = msg.sender;
        info.depositAmount = _amount;
        info.depositTime = block.timestamp;
        historicalDeposits.push(info);

        emit Deposit(_amount, block.timestamp);
    }


    // _time block withdrawal time, _time2 block deposit time
    // function changeTime(uint256 _time, uint256 _time2, address _user) public onlyOwner {
    //     deposits[_user].blockWithdrawal = _time;
    //     deposits[_user].timestampDeposited =  _time2;
    // }

    function satisfyRequest(address _user, uint256 _usdcReturn, uint256 _afiAmount, uint256 _requestId) public onlyAdmins {
        uint256 _amount = requests[_user];
        // uint256 _original = deposits[_user]
        requests[_user] = 0;
        requestTime[_user] = 0;
        poolToken.transferFrom(msg.sender, _user, _usdcReturn);
        // afitoken.transferFrom(msg.sender, _user, _afiAmount);
        deposits[_user].blockWithdrawal = 0;
        // totalStaked = totalStaked.sub(_original);
        totalWithdrawn = totalWithdrawn.add(_usdcReturn);
        if(deposits[_user].balance <= _usdcReturn){
            deposits[_user].balance = 0;
        } else {
            deposits[_user].balance = deposits[_user].balance.sub(_amount);
        }

        HistoricalWithdrawal memory info; 
        info.user = _user;
        info.withdrawalAmount = _usdcReturn;
        info.withdrawalTime = block.timestamp;
        historicalWithdrawals.push(info);

        remove(_requestId);
    }

    function satisfyRequestAndReturnRebase(address _user, uint256 _usdcReturn, uint256 _afiAmount, uint256 _requestId) public onlyAdmins {
        uint256 _amount = requests[_user];
        require(_usdcReturn <= _amount, 'invalid');
        uint256 difference = _amount - _usdcReturn;
        // uint256 _original = deposits[_user]
        requests[_user] = 0;
        requestTime[_user] = 0;
        poolToken.transferFrom(msg.sender, _user, _usdcReturn);
        returnPoolToken.transfer(_user, difference);
        // afitoken.transferFrom(msg.sender, _user, _afiAmount);
        deposits[_user].blockWithdrawal = 0;
        // totalStaked = totalStaked.sub(_original);
        totalWithdrawn = totalWithdrawn.add(_usdcReturn);
        if(deposits[_user].balance <= _usdcReturn){
            deposits[_user].balance = 0;
        } else {
            deposits[_user].balance = deposits[_user].balance.sub(_amount);
        }

        HistoricalWithdrawal memory info; 
        info.user = _user;
        info.withdrawalAmount = _usdcReturn;
        info.withdrawalTime = block.timestamp;
        historicalWithdrawals.push(info);

        remove(_requestId);
    }

    function withdraw(uint256 _amount) public nonReentrant {
        require(requests[msg.sender] == 0, "JustYield: request in progress");
        require(whitelist[msg.sender] == true, "JustYield: not whitelisted. If you KYCd contact us");
        require(returnPoolToken.allowance(msg.sender, address(this)) >= _amount, "not allowed");
        require(returnPoolToken.balanceOf(msg.sender) >= _amount, 'you do not have enough jytUSDT balance');
        returnPoolToken.transferFrom(msg.sender, address(this), _amount);
        requests[msg.sender] = requests[msg.sender].add(_amount);
        requestTime[msg.sender] = block.timestamp;
        requestList.push(msg.sender);
        emit WithdrawalRequest(msg.sender, _amount, block.timestamp);

    }

    function adminWithdrawAnyLostFunds(uint256 _amount) public onlyOwner {
        poolToken.transfer(msg.sender, _amount);
    }




}