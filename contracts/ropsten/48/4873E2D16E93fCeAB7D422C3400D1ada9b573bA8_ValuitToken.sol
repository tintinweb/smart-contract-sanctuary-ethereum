// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import './Ownable.sol';
import './tokens/MintableToken.sol';
import './tokens/PausableToken.sol';
import './libraries/SafeMath.sol';

contract ValuitToken is MintableToken, PausableToken {
    using SafeMath for uint;

    string public constant override name = 'Valuit Token';
    string public constant override symbol = 'VALU';
    uint8 public constant override decimals = 18;

    function approve(address _spender, uint256 _value) public override(BasicToken, PausableToken) returns (bool) {
       return PausableToken.approve(_spender, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public override(BasicToken, PausableToken) returns (bool) {
        return PausableToken.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public override(BasicToken, PausableToken) returns (bool) {
        return PausableToken.transfer(_to, _value);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import '../Ownable.sol';
import './BasicToken.sol';
import "../libraries/SafeMath.sol";

abstract contract MintableToken is BasicToken, Ownable {
  using SafeMath for uint;

  event Mint(address indexed to, uint amount);
  event Burn(address indexed burner, uint value);
  
  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint _amount) external onlyOwner returns (bool) {
    require(_amount <= MAX - totalSupply, "Total supply exceeded max limit.");
    totalSupply = totalSupply.add(_amount);
    require(_amount <= MAX - balanceOf[_to], "Balance of owner exceeded max limit.");
    balanceOf[_to] = balanceOf[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Burns a specific amount of tokens.
   * @param _holder The address from which tokens to be burned.
   * @param _value The amount of token to be burned.
   */
  function burn(address _holder, uint _value) external onlyOwner returns (bool) {
    require(_holder != address(0), "Burn from the zero address");
    require(_value <= balanceOf[_holder], 'Burn amount exceeds balance of holder');

    balanceOf[_holder] = balanceOf[_holder].sub(_value);
    require(_value <= totalSupply, "Insufficient total supply.");
    totalSupply = totalSupply.sub(_value);
    emit Burn(_holder, _value);
    emit Transfer(_holder, address(0), _value);
    return true;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import "./BasicToken.sol";
import '../Ownable.sol';

abstract contract PausableToken is BasicToken, Ownable {

    event Pause();
    event Unpause();
    bool public paused = false;

    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!isPaused(), 'Token Paused');
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(isPaused(), 'Token Not Paused');
        _;
    }
    /**
     * @dev Returns true if the Token is paused.
     */
    function isPaused() public view returns (bool) {
        return paused;
    }
    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() onlyOwner whenNotPaused external {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner whenPaused external {
        paused = false;
        emit Unpause();
    }

    function transfer(address _to, uint _value) public override virtual whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public override virtual whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public override virtual whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a / b;
        return c;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import '../interfaces/IERC20.sol';
import "../libraries/SafeMath.sol";

abstract contract BasicToken is IERC20 {
    using SafeMath for uint;

    uint constant MAX = ~uint256(0);

    uint public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;
   
   /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint _value) public override virtual returns (bool) {
        require(_spender != address(0), "Approve to the invalid or zero address");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

   /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) public override virtual returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

   /**
    * The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf. 
    * This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies. 
    * The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism.
    * @param _from address which you want to send tokens from
    * @param _to address which you want to transfer to
    * @param _value uint the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint _value) public override virtual returns (bool success) {
        require(_from != address(0), "Invalid Sender Address");
        require(allowance[_from][_to] >= _value, "Transfer amount exceeds allowance");
        _transfer(_from, _to, _value);
        allowance[_from][_to] = allowance[_from][_to].sub(_value);
        return true;
    }

   /**
    * Internal method that does transfer token from one account to another
    */
    function _transfer(address _sender, address _recipient, uint _amount) internal {
        require(_sender != address(0), "Invalid Sender Address");
        require(_recipient != address(0), "Invalid Recipient Address");
        
        uint balanceAmt = balanceOf[_sender];
        require(balanceAmt >= _amount, "Transfer amount exceeds balance of sender");
        require(_amount <= MAX - balanceOf[_recipient], "Balance limit exceeded for Recipient.");
        
        balanceOf[_sender] = balanceAmt.sub(_amount);
        balanceOf[_recipient] = balanceOf[_recipient].add(_amount);
        
        emit Transfer(_sender, _recipient, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}