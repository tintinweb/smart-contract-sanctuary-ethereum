/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

// File: contracts/BgToken.sol



pragma solidity >=0.6.0 <0.9.0;


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event BuyToken(uint256 amount);
}

contract BGToken is IERC20{
    using SafeMath for uint256;

    address  immutable creator;

    string public constant name= "BGTOKEN";
    string public constant symbol="BGT";
    uint8 public constant decimals=18;
    


    mapping(address =>uint256) balances;//this hold the token balance of each address 

    mapping(address=>mapping(address=>uint256)) allowed;//this holds the addresses allowed to withdraw from an address and the amount allowed

    uint256 totalSupply_;
    
    //store the total amount of token supplied to the address that created the contract.
    constructor (){
         creator= msg.sender;
        totalSupply_=1000000;
        balances[msg.sender]=totalSupply_;
    }

    //this returns the total amount of token in circulation 
    function totalSupply() public override view  returns (uint256){
        return totalSupply_;
    }

    //this returns the amount of token in a particular address
    function balanceOf(address holder) public override view returns(uint256){
        require(holder != address(0));
        return balances[holder];
    }

    //this transfers a particular amount of token from the the address invoking the function to a receiver address
    function transfer(address recipient,uint256 amount) public override returns(bool){
        require(recipient != address(0));
        require(balances[msg.sender]>=amount,"Insufficent balance");
        require(recipient != address(0));
        balances[msg.sender]=balances[msg.sender].sub(amount);
        balances[recipient]=balances[recipient].add(amount);
        payable(recipient).transfer(amount);
        emit Transfer(msg.sender,recipient,amount);
        return true;
    }

    //Approve an address to withdraw tokens from  your address
    function approve(address intermediary, uint256 amount) public override returns(bool){
        require(msg.sender== creator);
        require(intermediary != address(0));
        require(balances[msg.sender]>=amount,"Insufficent balance");
        require(intermediary !=address(0));
        allowed[msg.sender][intermediary]=amount;
        emit Approval(msg.sender,intermediary,amount);
        return true;
    }

    //Get the amount token approved by an address owner for an intermediary address to withdraw from the owner's account
    function allowance(address owner,address intermediary) public override view returns(uint256){
        require(owner !=address(0));
        require(intermediary != address(0));
        require(owner!=address(0));
        require(intermediary!=address(0));
        return allowed[owner][intermediary];

    } 

    // It allows the intermediary approved for withdrawal to transfer owner funds to a third-party account.
    function transferFrom(address owner,address recipient,uint amount)public override returns(bool){
        require(owner!=address(0));
        require(recipient != address(0));
        require(balances[owner]>=amount);
        require(allowed[owner][msg.sender]>=amount,"Insufficent balance");
        balances[owner]=balances[owner]-amount;
        allowed[owner][msg.sender]=allowed[owner][msg.sender]-amount;
        balances[recipient]=balances[recipient]+1;
        emit Transfer(owner,recipient,amount);
        return true;
    }

    //This allows an address to buy token and increase the total tokens in circulation
    function buyToken(address receiver) public payable  returns(uint256){
        require(receiver != address(0));  
        uint256 amount= (msg.value/10**18)*1000; 
        require(balances[receiver]<= totalSupply_);
        totalSupply_+=amount;
        balances[receiver]+=amount;
        emit BuyToken(amount);
        return amount;
    }




}