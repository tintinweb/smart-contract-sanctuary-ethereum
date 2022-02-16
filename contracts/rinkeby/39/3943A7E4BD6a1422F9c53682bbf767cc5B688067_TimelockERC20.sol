pragma solidity ^0.4.23;
import "../abstract/TimeMachine/TimeMachineP.sol";
import "../abstract/Cassette/ERC20Cassette.sol";
import "../abstract/Timelock/Timelock.sol";




contract TimelockERC20 is ERC20Cassette, TimeMachineP, Timelock {
  constructor (address _utilityToken) public {
    utilityToken = _utilityToken;
  }

}

pragma solidity ^0.4.23;

import "./ITimeMachine.sol";

/**
* @dev TimeMachine implementation for production
*/
  
contract TimeMachineP is ITimeMachine {
  /**
  * @dev get current real timestamp
  * @return current real timestamp
  */
  function getTimestamp_() internal view returns(uint) {
    return block.timestamp;
  }
}

pragma solidity ^0.4.24;

import "./ICassette.sol";
import "../../libs/token/ERC20/IERC20.sol";

contract ERC20Cassette is ICassette {

  address public utilityToken;

  function getCassetteSize_() internal view returns(uint) {
    return IERC20(utilityToken).balanceOf(address(this));
  }

  function acceptAbstractToken_(uint _value) internal returns(bool){
    return IERC20(utilityToken).transferFrom(msg.sender, address(this), _value);
  }
  function releaseAbstractToken_(address _for, uint _value) internal returns(bool){
    return IERC20(utilityToken).transfer(_for, _value);
  }

  function getCassetteType_() internal pure returns(uint8){
    return CT_TOKEN;
  }

}

pragma solidity ^0.4.23;
import "../../libs/math/SafeMath.sol";
import "../../libs/ownership/Ownable.sol";
import "../TimeMachine/ITimeMachine.sol";
import "../Cassette/ICassette.sol";



contract Timelock is ICassette, ITimeMachine, Ownable {
  using SafeMath for uint;

  event Lock(address indexed _from, address indexed _for, uint indexed timestamp, uint value);
  event Withdraw(address indexed _for, uint indexed timestamp, uint value);



  mapping (address => mapping(uint => uint)) public balance;



  /**
  * @dev accept token into timelock
  * @param _for address of future tokenholder
  * @param _timestamp lock timestamp
  * @return result of operation: true if success
  */
  function accept(address _for, uint _timestamp, uint _tvalue) public payable returns(bool){
    uint _value;
    if(getCassetteType_()==CT_ETHER) {
      _value = msg.value;
    } else if (getCassetteType_()==CT_TOKEN) {
      require(msg.value == 0);
      _value = _tvalue;
      require(acceptAbstractToken_(_value));
    } else revert();
    uint _balance = balance[_for][_timestamp];
    emit Lock(msg.sender, _for, _timestamp, _value);
    balance[_for][_timestamp] = _balance.add(_value);
    return true;
  }


  /**
  * @dev release timelock tokens
  * @param _for address of future tokenholder
  * @param _timestamp array of timestamps to unlock
  * @param _value array of amounts to unlock
  * @return result of operation: true if success
  */
  function release_(address _for, uint[] _timestamp, uint[] _value) internal returns(bool) {
    uint _len = _timestamp.length;
    require(_timestamp.length == _value.length);
    uint _totalValue;
    uint _curValue;
    uint _curTimestamp;
    uint _subValue;
    uint _now = getTimestamp_();
    for (uint i = 0; i < _len; i++){
      _curTimestamp = _timestamp[i];
      _curValue = balance[_for][_curTimestamp];
      _subValue = _value[i];
      require(_curValue >= _subValue);
      require(_curTimestamp <= _now);
      balance[_for][_curTimestamp] = _curValue.sub(_subValue);
      _totalValue = _totalValue.add(_subValue);
      emit Withdraw(_for, _curTimestamp, _subValue);
    }
    releaseAbstractToken_(_for, _totalValue);
    return true;
  }


  /**
  * @dev release timelock tokens
  * @param _timestamp array of timestamps to unlock
  * @param _value array of amounts to unlock
  * @return result of operation: true if success
  */
  function release(uint[] _timestamp, uint[] _value) external returns(bool) {
    return release_(msg.sender, _timestamp, _value);
  }

  /**
  * @dev release timelock tokens by force
  * @param _for address of future tokenholder
  * @param _timestamp array of timestamps to unlock
  * @param _value array of amounts to unlock
  * @return result of operation: true if success
  */
  function releaseForce(address _for, uint[] _timestamp, uint[] _value) onlyOwner external returns(bool) {
    return release_(_for, _timestamp, _value);
  }

}

pragma solidity ^0.4.23;

contract ITimeMachine {
  function getTimestamp_() internal view returns (uint);
}

pragma solidity ^0.4.24;
contract ICassette {
  uint8 constant CT_ETHER = 0x01;
  uint8 constant CT_TOKEN = 0x02;
  

  function getCassetteSize_() internal view returns(uint);
  function acceptAbstractToken_(uint _value) internal returns(bool);
  function releaseAbstractToken_(address _for, uint _value) internal returns(bool);
  function getCassetteType_() internal pure returns(uint8);

}

pragma solidity ^0.4.23;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract IERC20{
  function allowance(address owner, address spender) external view returns (uint);
  function transferFrom(address from, address to, uint value) external returns (bool);
  function approve(address spender, uint value) external returns (bool);
  function totalSupply() external view returns (uint);
  function balanceOf(address who) external view returns (uint);
  function transfer(address to, uint value) external returns (bool);
  
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

pragma solidity ^0.4.23;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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