/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// File: contracts/RaisinCore.sol



//Copyright (C) 2022 Raisin <> Crypdough Labs



pragma solidity 0.8.17;






contract RaisinCore is Ownable {

   using SafeMath for uint256;



                                                            

    event FundStarted (uint32 indexed id);

    event TokenDonated (address indexed adr, IERC20 token, uint indexed amount, uint32 indexed id);

    event TokenAdded (IERC20  indexed token);

    event FundEnded (uint32 indexed id);





    // address => raisins[index]._id => amount 

    mapping (address => mapping(uint32 => uint)) public donorBal;

    mapping (IERC20 => bool) public tokenWhitelist;



    //incrementing id

    uint32 id;



    //withdraw address

    address vault;

    uint fe;

    //expiry time for all projects

    uint expiry;



    struct Raisin  {

        //raise goal amount in native token 

        uint _amount;

        uint _fundBal;

        //cause id

        uint32 _id;

        //balance of fund

        //token to raise in 

        IERC20 _token; 

        //address of wallet raising funds

        address _raiser;

        //timestamp expiry 

        uint _expires;        

    }



    Raisin [] public raisins; 





    constructor () {

        expiry = block.timestamp + 180 days;

        vault = msg.sender;

        fe = 200; 

    }





    function getRaisinsLength () public view returns (uint){

        return raisins.length;

    }







   //starts fund for user

   //@param amount: amount of tokens being raised

   //@param token: token raised in

   

    function initFund (uint amount, IERC20 token) external {

        require (amount > 0, "Amount = 0");

        require(tokenWhitelist[token] = true, "Token Not Whitelisted");

        ++id;

        raisins.push(Raisin(amount, 0, id, token, msg.sender, expiry));

        emit FundStarted(id);

    }



    function endFund (uint32 index) external {

        require (msg.sender == raisins[index]._raiser || msg.sender == owner());

        raisins[index]._expires = block.timestamp;

        if(raisins[index]._fundBal == 0){

            deleteFund(index);

        }

    }



    function donateToken (

        IERC20 token,

        address sender,

        uint32 index,

        uint amount

    ) external payable {

        require (block.timestamp < raisins[index]._expires, "Fund Not Active"); 

        require (token == raisins[index]._token, "Token Not Accepted"); 

        uint fee = amount.mul(fe).div(10000);

        donorBal[msg.sender][raisins[index]._id] += amount.sub(fee);

        raisins[index]._fundBal += amount.sub(fee); 

        emit TokenDonated (sender, token, amount, raisins[index]._id);

        erc20Transfer(token, sender, vault, fee); 

        erc20Transfer(token, sender, address(this), amount.sub(fee)); 

    }







    function fundWithdraw (IERC20 token, uint32 index) external payable{

        require (msg.sender == raisins[index]._raiser, "Not Your Fund");

        require(raisins[index]._fundBal >= raisins[index]._amount, "Goal Not Reached");

        require (block.timestamp >= raisins[index]._expires, "Fund Still Active");

        uint bal = raisins[index]._fundBal;

        raisins[index]._fundBal -= bal;

        deleteFund(index);

        approveTokenForContract(token, bal);

        erc20Transfer(token, address(this), msg.sender, bal);

    }



    function refund (IERC20 token, uint32 index) external payable{

        require (block.timestamp >= raisins[index]._expires, "Fund Still Active"); 

        require(raisins[index]._fundBal < raisins[index]._amount, "Goal reached");

        uint bal = donorBal[msg.sender][raisins[index]._id];

        donorBal[msg.sender][raisins[index]._id] -= bal;

        raisins[index]._fundBal -= bal;

        if (raisins[index]._fundBal == 0) {

            deleteFund(index);

        }

        approveTokenForContract(token, bal);

        erc20Transfer(token, address(this), msg.sender, bal);

    }



    // call this function before donateToken();

    function approveTokenForContract (

        IERC20 token,

        uint amount

    ) private {

        bool sent = token.approve(address(this), amount);

        require(sent, "approval failed");

    }



    function erc20Transfer (

        IERC20 token,

        address sender,

        address recipient,

        uint amount

        ) private {

        bool sent = token.transferFrom(sender, recipient, amount); 

        require(sent, "Token transfer failed"); 

    }





    function deleteFund (uint32 index) internal {

       //delete array element by ID 

       //strat: mix and match

       //rationale: maximizes order preservation and cost eff. 

       // del [1]:[1,2,3,4] => [1, NULL, 3, 4] =>  [1, 4, 3, NULL] 

       raisins[index] = raisins[raisins.length - 1];

       raisins.pop();

       emit FundEnded(index);

    }

    function changeFee(uint32 newFee) external onlyOwner {

        require (newFee != 0 && newFee != fe);

        fe = newFee; 

    }

    function whitelistToken (IERC20 token) external onlyOwner {

        tokenWhitelist[token] = true; 

        emit TokenAdded(token); 

    }



    function removeWhitelist(IERC20 token) external onlyOwner {

        tokenWhitelist[token] = false; 

    }



    function changeVault(address newAddress) external onlyOwner {

        require(newAddress != address(0));

        vault = newAddress;

    }

}