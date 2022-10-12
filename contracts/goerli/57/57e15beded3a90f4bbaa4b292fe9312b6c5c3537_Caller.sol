/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract Receiver {
    address public owner;
    event Received(address caller, uint amount, string message);
    event Response(bool success, bytes data);
  
    constructor(address _owner) {
        owner = _owner;
    }


    function delegateExecute(address _addr, bytes memory _message) public payable  {
        require(owner== msg.sender,"Ownable: caller is not the owner");
        (bool success, bytes memory data) = _addr.delegatecall(_message);
        emit Response(success, data);


    }

    function execute(address _addr, bytes memory _message) public payable  {
        require(owner== msg.sender,"Ownable: caller is not the owner");
        (bool success, bytes memory data) = _addr.call{value: msg.value}(_message);
        emit Response(success, data);


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
        require(owner== msg.sender,"Ownable: caller is not the ownerr");

        for (uint256 i = 0; i < _n; i++) {
        // create with salt
        Receiver receiver = new Receiver{salt: bytes32(uint256(i))}(address(this));
        // append to proxies
        Receivers.push(receiver);
        }
        

    } 


    function testBatch(address _target, bytes memory _message) public payable {
        require(owner== msg.sender,"Ownable: caller is not the ownerr");
        // You can send ether and specify a custom gas amount

        for(uint i=0;i<Receivers.length;i++){
            address receiver = address(Receivers[i]);
            (bool success, bytes memory data) = receiver.call{value: msg.value}(abi.encodeWithSignature("execute(address,bytes)", _target,_message)
            );
            emit Response(success, data);

      
        }  
    }


    function testDelegateBatch(address _target, bytes memory _message) public payable {
        require(owner== msg.sender,"Ownable: caller is not the ownerr");
        // You can send ether and specify a custom gas amount delegateExecute

        for(uint i=0;i<Receivers.length;i++){
            address receiver = address(Receivers[i]);
            (bool success, bytes memory data) = receiver.call{value: msg.value}(abi.encodeWithSignature("delegateExecute(address,bytes)", _target,_message)
            );
            emit Response(success, data);

      
        }  
    }

    receive() external payable {

    }
}