/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

contract GSNContext {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
   
    function totalSupply() external view returns (uint256);
    function getBalance(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);



    event Transfer(address indexed _sender, address indexed _too, uint256 _amount);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Pausable is Ownable {
    
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused  {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
  
}

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        return div(a, b, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract ERC20 is GSNContext, IERC20, Pausable {
    
    using SafeMath for uint256;
    
    uint private _decimals = 18;
    uint private _totalsupply;
    
    string private _name;
    string private _ticker;
    
    address public _owner;
    
    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;


    constructor () {
        _totalsupply = 1000000000 * (10 ** _decimals);
        _name = "TheFohimNuesburgToken";
        _ticker = "FNT";
        _owner = msg.sender;
        _balances[_owner] = _balances[_owner].add(_totalsupply);
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function ticker() public view returns (string memory) {
        return _ticker;
    }
    
    function totalSupply() public view override returns (uint) {
        return _totalsupply;
    }
    
    function getBalance(address _key) public view override returns (uint) {
        return _balances[_key];
    }
    
    function allowance(address _from, address _spender) public view override returns (uint) {
        return _allowances[_from][_spender];
    }
    
    function approve(address _spender, uint _amount) public override whenNotPaused() returns (bool) {
        require (_balances[msg.sender] >= _amount, "ERC20: Amount is lower than requested from transfer");
        _allowances[msg.sender][_spender] = _allowances[msg.sender][_spender].add(_amount);
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function decreaseApproval(address _from, address _spender, uint _amount) public whenNotPaused() returns (bool) {
        require (_allowances[_from][_spender] >= _amount, "ERC20: Amount is lower than requested from transfer");
        _allowances[_from][_spender] = _allowances[_from][_spender].sub(_amount);
        return true;
    }
    
    function transfer(address _too, uint _amount) public override whenNotPaused() returns (bool) {
        _transfer(_msgSender(), _too, _amount);
        return true;
    }
    
    function _transfer(address _from, address _too, uint _amount) internal returns (bool) {
        require (_balances[_from] >=_amount, "ERC20: Amount is lower than requested from transfer");
        require (_from != address(0), "ERC20: Is not the zero address");
        require (_too != address(0), "ERC20: Is not the zero address");
        _beforeTokenTransfer(_msgSender(),  _too, _amount);
        _balances[_from] = _balances[_from].sub(_amount);
        _balances[_too] = _balances[_too].add(_amount);
        emit Transfer(msg.sender, _too, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _spender, uint _amount) public override whenNotPaused() returns (bool) {
        require (_allowances[_from][_spender] >= _amount, "ERC20: Amount is lower than requested from transfer");
        require (_balances[_from] >= _amount, "ERC20: Amount is lower than requested from transfer");
        _transfer(_from, _msgSender(), _amount);
        _allowances[_from][_spender] = _allowances[_from][_spender].sub(_amount);
        emit Approval(_from, _msgSender(), _amount);
        return true;
    }
    
    function mint(uint _amount) public whenPaused() onlyOwner() {
        require (msg.sender == _owner);
        require (_amount > 0);
        _beforeTokenTransfer(address(0), _owner, _amount);
        _totalsupply = _totalsupply.add(_amount);
        _balances[_owner] = _balances[_owner].add(_amount);
        emit Transfer(address(0), _owner, _amount);
    }
    
    function burn(uint _amount) public whenPaused() onlyOwner() {
        require (_totalsupply >= _amount);
        require (_amount > 0);
        _totalsupply = _totalsupply.sub(_amount);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
}