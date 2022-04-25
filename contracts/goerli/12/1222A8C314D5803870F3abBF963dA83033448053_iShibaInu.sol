/**
 *Submitted for verification at Etherscan.io on 2022-04-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(address(msg.sender));
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
        * @dev Initializes the contract setting the deployer as the initial owner.
        */
    constructor ()  {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

        /**
        * @dev Leaves the contract without owner. It will not be possible to call
        * `onlyOwner` functions anymore. Can only be called by the current owner.
        *
        * NOTE: Renouncing ownership will leave the contract without an owner,
        * thereby removing any functionality that is only available to the owner.
        */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
        * @dev Transfers ownership of the contract to a new account (`newOwner`).
        * Can only be called by the current owner.
        */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock the token contract");
        require(block.timestamp > _lockTime , "Contract is still locked");
        _lockTime = 0;
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


contract iShibaInu is Context, Ownable {
    using SafeMath for uint256;

    // iShibInu coin will have a total supply of 10 quadrillion
    uint256 public constant totalSupply = 10000000000000000000000000000000000;
    string public constant name = "iShibaInu";
    string public constant symbol = "iSHIB";
    string public constant standard = "iSHIB Coin Version 1.0";
    uint8 public constant decimals = 18;

    // balanceOf mapping
    mapping(address => uint256) public balanceOf;
    // allowance mapping
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(
        address indexed _from, 
        address indexed _to, 
        uint256 _value
        );

    event Transfer(
        address indexed _delegatedSpender,
        address indexed _from, 
        address indexed _to, 
        uint256 _value
        );

    event Approval(
        address indexed _owner,
        address indexed _delegatedSpender,
        uint256 _value
    );

    constructor() {
        balanceOf[msg.sender] = totalSupply; // assigns total supply to admin/creator
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool _success)
    {
        require(_to != address(0), "ERC20: transfer to zero address");
        require(
            balanceOf[msg.sender] >= _value,
            "=> because the sender's balance is less than the amount requested to be sent."
        );

        // Transfer the _value from the sender to the receiver
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        // Emit transfer event
        emit Transfer(msg.sender, _to, _value);

        // returns a Boolean
        return true;
    }

    // approve function - msg.sender should know what the approved value or remainder of the approved
    // value is.
    function approve (
        address _delegatedSpender,
        uint256 _value
    ) public returns (bool _success) {
       _approve(msg.sender, _delegatedSpender, _value);
        return true;
    }

    function _approve(address _owner, address _delegatedSpender, uint256 _amount) private {
        require(_owner != address(0), "ERC20: approve from zero address");
        require(_delegatedSpender != address(0), "ERC20: approve to zero address");

        allowance[_owner][_delegatedSpender] = _amount;
        emit Approval(_owner, _delegatedSpender, _amount);
    }

    function increaseAllowance(address _delegatedSpender, uint256 _addedValue) public virtual returns (bool) {
        _approve(msg.sender, _delegatedSpender, allowance[msg.sender][_delegatedSpender].add(_addedValue));
        return true;
    }

    function decreaseAllowance(address _delegatedSpender, uint256 _subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, _delegatedSpender, allowance[msg.sender][_delegatedSpender].sub(_subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    // transfer from function
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool _success) {
        // require _from has enough coins
        require(_value <= balanceOf[_from]);

        // require _value to be smaller than or equal to the allowance
        require(_value <= allowance[_from][msg.sender]);

        // changes the balances
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        // updates the allowance
        _approve(_from, msg.sender, allowance[_from][msg.sender].sub(_value, "ERC20: transfer amount exceeds allowance"));

        // Emit three-args transfer event
        emit Transfer(_from, _to, _value);
        // Emit four-args transfer event
        emit Transfer(msg.sender, _from, _to, _value);

        return true;
    }

    function destroyTokenContractByOwnerOnly (address payable _to) public onlyOwner {
        selfdestruct(_to);
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
        *
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
        *
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
        *
        * - Subtraction cannot overflow.
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
        *
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
        *
        * - The divisor cannot be zero.
        */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        *
        * - The divisor cannot be zero.
        */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract iShibaInuSale {

    address payable admin;
    address public addressOfThisSaleContract = address(this);
    uint256 public coinPrice;
    uint256 public coinsSold;
    iShibaInu public coinContract;
    event Sell(address _buyer, uint256 _amount);

    constructor(iShibaInu _coinContract, uint256 _coinPrice) {
        admin = payable(msg.sender);
        coinContract = _coinContract;
        coinPrice = _coinPrice;
    }

    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function buyCoins(uint256 _numberOfCoins) public payable {
        require(msg.value == multiply(_numberOfCoins, coinPrice));
        require(coinContract.balanceOf(addressOfThisSaleContract) >= _numberOfCoins);
        require(coinContract.transfer(msg.sender, _numberOfCoins * 1e18)); // decimals = 18

        coinsSold += _numberOfCoins;

        // Emit Sell event
        emit Sell(msg.sender, _numberOfCoins * 1e18); // decimals = 18
    }

    function endSale() public {
        require(msg.sender == admin);
        require(coinContract.transfer(admin, coinContract.balanceOf(addressOfThisSaleContract)));

        selfdestruct(admin);
    }
}