/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// File: IterableMapping.sol

/**
    
*/

contract IterableMapping
{
    // array containing 10 elements
    bytes32[10] transaction_hashes;
    uint8 control;
    bool locked;

    // map the hashes to the receiver
    mapping(bytes32 => address) map;

    receive() payable external {}
    fallback() payable external {}

    modifier NoReentrance()
    {
        require(!locked, "You cannot redo this action.");
        locked = true;
        _;
        locked = false;
    }

    // write a transaction function
    function Transact(address to, uint amount) public NoReentrance
    {
        require(control < 10, "Transaction records are full.");
        payable(to).call{value: amount}("");

        bytes32 tx_hash = keccak256(abi.encodePacked(msg.sender, to, amount));
        
        transaction_hashes[control] = tx_hash;
        control = control + 1;
        map[tx_hash] = to;
    }

    function Get_Hash_Receiver(uint8 index) public view returns(address)
    {
        require(index < control, "Index not recorded");
        
        address receiver = map[transaction_hashes[index]];
        
        // return string(abi.encodePacked("Address of receceiver with hash ", transaction_hashes[index], " is ", receiver));
        return receiver;
    }
}