// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./console.sol";
import "./ExternalContract.sol";

contract Staker {

  ExternalContract public externalContract;

    /**
*  @notice Contract Constructor
  * @param ExternalContractAddress Address of the external contract that will hold stacked funds
  */
    constructor(address ExternalContractAddress) public {
        externalContract = ExternalContract(ExternalContractAddress);
    }
    mapping ( address => uint256 ) public tests;
    //constants
    mapping ( address => uint256 ) public balances;
    uint256 public constant threshold = 0.1 ether;
    event Stake(
        address indexed _from,
        bytes32 indexed _id,
        uint _value
    );


    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake(bytes32 _id) public payable {
        balances[msg.sender]+=msg.value;
        emit Stake(msg.sender, _id,msg.value);
    }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value


  // if the `threshold` was not met, allow everyone to call a `withdraw()` function


  // Add a `withdraw()` function to let users withdraw their balance


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend


  // Add the `receive()` special function that receives eth and calls stake()


}