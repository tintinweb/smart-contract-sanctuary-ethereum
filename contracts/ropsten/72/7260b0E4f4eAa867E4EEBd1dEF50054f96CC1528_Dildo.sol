pragma solidity ^0.6.1;


import "./ERC20/StandardToken.sol";

contract Dildo is StandardToken {
    uint256 public decimals = 8;
    uint256 public totalSupply = 100e14;
    string public name = "Dildo Company Unlimited";
    string public symbol = "DIL";
    address public owner;

    uint256 public minimumBalanceForAccounts;
    uint256 public sellPrice;
    uint256 public buyPrice;

    modifier onlyOwner() {
        require(msg.sender == owner, "owner must be set");
        _;
    }

    constructor() public {
        owner = msg.sender;
        balances[owner] = totalSupply;
        minimumBalanceForAccounts = 5 finney;
        buyPrice = 100e14;
        sellPrice = 100e14;
    }

    // Change the owner of the contract
    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Address is empty");
        owner = newOwner;
    }

    // Burn and Mint
    event Burn(address indexed burner, uint256 value);

    function burn(address target, uint256 amount) external onlyOwner {
        require(amount <= balances[target], "burn require");
        balances[target] = balances[target].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Burn(target, amount);
        emit Transfer(target, address(0), amount);
    }

    function mint(address target, uint256 mintedAmount) external onlyOwner {
        balances[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
    }

    // Buy and Sell
    // this is 0.001 ether for 1 token
    // https://www.etherchain.org/tools/unitConverter
    // uint256 public coinPrice = 1000000000000000;

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice)
        external
        onlyOwner
    {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function getSellPrice() public view onlyOwner returns (uint256) {
        return sellPrice;
    }

    function getBuyPrice() public view onlyOwner returns (uint256) {
        return buyPrice;
    }

    function getAmountBuyPrice(uint256 amount)
        public
        view
        onlyOwner
        returns (uint256)
    {
        return amount / buyPrice;
    }

    function buy() public payable returns (uint256 amount) {
        amount = msg.value / buyPrice;
        require(balances[owner] >= amount, "buy require");
        balances[owner] -= amount;
        balances[address(this)] += amount;
        emit Transfer(owner, address(this), amount);
        return amount;
    }

    function sell(uint256 amount) public returns (uint256 revenue) {
        require(balances[address(this)] >= amount, "sell require");
        balances[address(this)] = -amount;
        balances[owner] += amount;
        revenue = amount * sellPrice;
        //require(owner.send(revenue), "sell require 2");
        emit Transfer(address(this), owner, amount);
        return revenue;
    }
}

pragma solidity ^0.6.1;

library SafeMath {
    /**
  * @dev Multiplies two numbers, throws on overflow.
  */

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522

        if (_a == 0) {
            return 0;
        }
        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
        return _a / _b;
    }

    /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    /**
  * @dev Adds two numbers, throws on overflow.
  */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}

pragma solidity ^0.6.1;

import "./BasicToken.sol";
import "./Main/ERC20.sol";

/**
 * @title Standard ERC20 token
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;

    /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */

    function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool)
    {
        require(_value <= balances[_from], "balance is lower than balance of owner");
        require(_value <= allowed[_from][msg.sender], "balance is lower than allowance balance of owner");
        require(_to != address(0), "balance need address");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
    function approve(address _spender, uint256 _value) public virtual override returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
    function allowance(address _owner, address _spender) public virtual override view returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool)
    {
        allowed[msg.sender][_spender] = (
            allowed[msg.sender][_spender].add(_addedValue)
        );
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];

        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;

        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

pragma solidity ^0.6.1;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
  abstract contract ERC20Basic {
    function balanceOf(address _who) public virtual view returns (uint256);
    function transfer(address _to, uint256 _value) public virtual returns (bool) ;
    event Transfer(address indexed from, address indexed to, uint256 value);
}

pragma solidity ^0.6.1;

import "./ERC20Basic.sol";

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
abstract contract ERC20 is ERC20Basic {
    function allowance(address _owner, address _spender) public virtual view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool);
    function approve(address _spender, uint256 _value) public virtual returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.1;

import "./Main/ERC20Basic.sol";
import "./../Helpers/SafeMath.sol";

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {

    using SafeMath for uint256;

    mapping(address => uint256) internal balances;

    /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
    function transfer(address _to, uint256 _value) public virtual override returns (bool) {
        require(_value <= balances[msg.sender], "Not enough tokens left");
        require(_to != address(0), "Address is empty");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
    function balanceOf(address _owner) public virtual override view returns (uint256) {
        return balances[_owner];
    }

}