// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

//import "scaffold-eth/node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";

contract ExampleExternalContract is Ownable {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

  //inherit onlyOwner from Ownable and swap functions below
  function withdraw() public onlyOwner payable {
    payable(msg.sender).transfer(address(this).balance);
    //msg.sender().sendValue(address(this).balance);
  }
  
  /*function withdraw (address _baller) public payable {
    payable(_baller).transfer(address(this).balance);
  }*/
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

//import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping (address => uint256) public balances;
  uint public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 30 seconds;
  event Stake(address indexed _staker, uint _amount);
  event Withdraw(address indexed _staker, uint _amount);

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  modifier stakeNotCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "staking process already completed");
    _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable stakeNotCompleted {
    balances[msg.sender] = balances[msg.sender] + msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public stakeNotCompleted {
    uint256 contractBalance = address(this).balance;
    require(block.timestamp >= deadline, "Deadline Not Met");
    require(contractBalance >= threshold, "Threshold Not Met");
      exampleExternalContract.complete{value: address(this).balance}();
    }

  // Add a `withdraw()` function to let users withdraw their balance
  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  function withdraw() public stakeNotCompleted {
    require(address(this).balance < threshold);
    uint amount = balances[msg.sender]; 
    balances[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
    emit Withdraw(msg.sender, balances[msg.sender]);
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256 timeleft) {
    if( block.timestamp >= deadline ) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    balances[msg.sender] = balances[msg.sender] + msg.value;
    emit Stake(msg.sender, msg.value);
  }

}