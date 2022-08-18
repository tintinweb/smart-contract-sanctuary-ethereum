/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

//SPDX-License-Identifier:MIT
// File: contracts/Ownable.sol


pragma solidity >=0.7.0 <0.9.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: contracts/1_Storage.sol



pragma solidity >=0.7.0 <0.9.0;


/**
 * @title Storage
 */
contract StorageV8 is Ownable {

    struct Num1 {
        uint a; // uint256 takes 32 bytes storage, 2 slots of storage
        uint b;
    }

    struct Num2 {
        uint32 a; // These are packed and stored in 1 storage slot
        uint32 b;
    }

// You can declare an array as public, and Solidity will automatically create a getter method for it. The syntax looks like:
    uint256 public number;
    Num1 public num1;
    Num2 public num2;
    uint lastUpdated;

    uint[5] numbers = [1,2,3,4,5];

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public onlyOwner {
        number = num;
    }

    function storeNum1 (uint _a, uint _b) public {
        num1 = Num1(_a, _b);
    }

    function checkIfNumberIsEven() public view returns (bool) {
        return (number % 2 == 0);
    }

    function notFreeViewCallV1(uint _num) public {
        number = _num;
    }

    function notFreeViewCallV2(uint _num) public {
        if(checkIfNumberIsEven()) {
            number = _num;
        } else {
            number = 0;
        }  
    }

    function storeNum2 (uint32 _a, uint32 _b) public {
        num2 = Num2(_a, _b);
    }

    // Set `lastUpdated` to `now`
    function updateTimestamp() public {
        lastUpdated = block.timestamp;
    }

    // Will return `true` if 5 minutes have passed since `updateTimestamp` was 
    // called, `false` if 5 minutes have not passed
    function fiveMinutesHavePassed() public view returns (bool) {
        return (block.timestamp >= (lastUpdated + 5 minutes));
    }

    function evenNos() external view returns (uint[] memory evenNumbers) {
        uint length = numbers.length;
        evenNumbers = new uint[](length);
        uint index = 0;

        for(uint i  = 0; i < length; i++) {
            if (numbers[i] %2 == 0) {
                evenNumbers[index] = numbers[i];
                index++;
            }
        }

        // return evenNumbers
    }

    function bytes32ToUint256(bytes32 a) external pure returns (uint256) {
        return uint256(a);
    }

    function uint256ToBytes32(uint256 a) external pure returns (bytes32) {
        return bytes32(a);
    }

    // uint8 can store values from 0 to 255
    function uint8Overflows(uint8 n1, uint8 n2) external pure returns (uint8) {
        return (n1 + n2);
    }

    
}