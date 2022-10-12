/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Receiver {
    address public owner;
    event Received(address caller, uint amount, string message);
  
    constructor(address _owner) {
        owner = _owner;
    }


    function execute(address _addr, bytes memory _message) public payable  {
        require(owner== msg.sender,"not owner");
        (bool success, bytes memory data) = _addr.call(_message);

    }

    receive() payable  external {

    }
}

contract Caller {

    address public owner;
    Receiver [] public Receivers;
    event Response(bool success, bytes data);

    // Let's imagine that contract Caller does not have the source code for the
    // contract Receiver, but we do know the address of contract Receiver and the function to call.
    constructor() {
        owner = msg.sender;
    }

    function createReceiver(uint _n) external {

        for (uint256 i = 0; i < _n; i++) {
        // create with salt
        Receiver receiver = new Receiver{salt: bytes32(uint256(i))}(address(this));
        // append to proxies
        Receivers.push(receiver);
        }
        

    } 
    function testCallFoo(address payable _addr) public payable {
        // You can send ether and specify a custom gas amount
        (bool success, bytes memory data) = _addr.delegatecall(
            abi.encodeWithSignature("foo(string,uint256)", "call foo", 123)
        );

        emit Response(success, data);
    }

    function testBatch(address _target, bytes memory _message) public payable {
        // You can send ether and specify a custom gas amount

        for(uint i=0;i<Receivers.length;i++){
            address receiver = address(Receivers[i]);
            (bool success, bytes memory data) = receiver.delegatecall(abi.encodeWithSignature("execute(address,bytes)", _message, _target)
            );
            emit Response(success, data);

      
        }  
    }

    // Calling a function that does not exist triggers the fallback function.
    function testCallDoesNotExist(address _addr) public {
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("doesNotExist()")
        );

        emit Response(success, data);
    }
}