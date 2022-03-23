/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// File: contracts/Test.sol


pragma solidity ^0.8.9;


contract Test {

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function search(address _address) external payable {

        uint8 n = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))));

        (bool success, ) =_address.call{value: 1 ether}(
            abi.encodeWithSignature("guess(uint8)", n)
        );

        require(success, "call failed");
    }

    receive() external payable { }


     // destroys the contract. Only to be called by owner
    function destory() external {
       require(msg.sender == owner);
       selfdestruct(payable(owner)); 
    }

}