/**
 *Submitted for verification at Etherscan.io on 2022-05-06
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
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

interface ERC20Interface {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  //indexed修饰代表 日志以后面参数名称保存
  event Transfer(address  from, address  to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract YXToken is ERC20Interface{
     using SafeMath for uint;

     string public symbol;
     string public name;
     uint8 public decimal;
     uint public _totalSupply;
     mapping(address => uint) balances;
     //某账户授权某账户多少金额
     mapping(address => mapping(address => uint)) allowed;
     address owner;

     constructor() public{
         symbol = "YXToken";
         name="YuXiang Token";
         decimal = 18;
         owner = msg.sender;
         _totalSupply = 10000 * 10 ** 18;
         balances[owner] = _totalSupply;

         //发送事件 初始一般0x0000黑洞地址创建合约 以及 对合约创建者发币
         emit Transfer(address(0), owner, _totalSupply);
     }
     
       
   function totalSupply() external override view returns (uint256){
       return _totalSupply;
   }

  function balanceOf(address account) external override view returns (uint256){
        return balances[account];
  }

  function transfer(address recipient, uint256 amount) external override returns (bool){
      balances[msg.sender] = balances[msg.sender].sub(amount);
      balances[recipient] = balances[recipient].add(amount);

      emit Transfer(msg.sender,recipient,amount);
      return true;
  }

  function allowance(address _owner, address spender) external override view returns (uint256){
      
  }

  function approve(address spender, uint256 amount) external override returns (bool){
      allowed[msg.sender][spender] = amount;
      emit Approval(msg.sender,spender,amount);
      return true;
  }
  

  function transferFrom(address from, address to, uint256 amount) external  override returns (bool){
      //代理 授权金额减少
      allowed[from][to] = allowed[from][to].sub(amount);
      balances[from] = balances[from].sub(amount);
      balances[to] = balances[to].add(amount);
      emit Transfer(from,to,amount);

      return true;
  }

 uint public  a = 1;
 function pay() external payable{
      emit Transfer(msg.sender,address(this),msg.value);
  }

  fallback () payable external {
     //向合约转账回退
     revert();
  }

}