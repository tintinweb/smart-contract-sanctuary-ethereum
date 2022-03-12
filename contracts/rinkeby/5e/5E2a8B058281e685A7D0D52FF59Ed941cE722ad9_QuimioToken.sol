/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// File: @chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol


pragma solidity ^0.6.0;

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
library SafeMathChainlink {
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

// File: erc20/QMO.sol



pragma solidity >=0.5.5<0.8.0;



interface IERC20{
  function totalsupply()external view returns (uint256);
  function balanceOf(address account)external view returns (uint256);
  function allowance(address owner, address spender)external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);




  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);


}

contract QuimioToken is IERC20{
  string public constant name = "QuimioToken";
  string public constant symbol = "QMO";
  uint public constant decimals= 9;

  event Transfer(address indexed from, address indexed to, uint256 tokens);
  event Approval(address indexed owner, address indexed spender, uint256 tokens);   
  using SafeMathChainlink for uint256;
  
  mapping(address=>uint) balances;
  mapping (address => mapping (address => uint)) allowed;
  uint256 totalSupply_;

  constructor (uint256 initialSupply) public{
    totalSupply_ = initialSupply;
    balances[msg.sender]=totalSupply_;
}
function totalsupply() public override view returns (uint256){
 return totalSupply_;
}

function increaseTotalSupply(uint newTokensAmount) public {
    totalSupply_+=newTokensAmount;
    balances[msg.sender]+= newTokensAmount;
}

function balanceOf(address tokenOwner) public override view returns (uint256){
    return balances[tokenOwner];
    }

function allowance(address owner, address delegate) public override view returns (uint256){
    return allowed[owner][delegate];
}

function transfer(address recipient, uint256 numTokens) public override returns (bool){
    require(numTokens <=balances[msg.sender]);
    balances[msg.sender]=balances[msg.sender]. sub(numTokens);
    balances[recipient]=balances[recipient].add(numTokens);
    emit Transfer(msg.sender, recipient, numTokens);
    return true;
}

function approve(address delegate, uint256 numTokens) public override returns (bool){
    allowed[msg.sender][delegate]=numTokens;
    emit Approval(msg.sender, delegate, numTokens);
    return true;
} 

function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool){
    require(numTokens <= balances[owner]);
    require(numTokens <= allowed[owner][msg.sender]);
    balances[owner] = balances[owner].sub(numTokens);
    allowed[owner][msg.sender]=allowed[owner][msg.sender].sub(numTokens);
    balances[buyer]=balances[buyer].add(numTokens);
    emit Transfer (owner, buyer, numTokens);
    return true;
}



}