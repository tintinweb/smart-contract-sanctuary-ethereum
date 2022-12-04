/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract Temple {
    uint128 public entrance;
    address public mainHall;
    mapping(uint8 => mapping(uint8 => address)) public gardens;
    bytes20[] public chambers;

    /// Write data to the contract's ith storage slot
    function write(uint256 i, bytes32 data) public {
        assembly {
            sstore(i, data)
        }
    }
}


contract Mycontract {
    function write(address _addr) public {
        Temple t = Temple(_addr);
        uint x = uint(keccak256(abi.encode(20, 2)));
        t.write(
            uint(keccak256(abi.encode(22, x))),
            bytes32(abi.encode(msg.sender))
        );
    }
}