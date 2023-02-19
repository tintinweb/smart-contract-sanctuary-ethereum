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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./Temple.sol";

contract TempleQuests {
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

    Temple immutable temple;

    constructor (Temple _temple) {
        temple = _temple;
    }

    function part1() external {
        temple.write(1, bytes32(abi.encode(msg.sender)));
    }

    function part2() external {
        uint x = uint(keccak256(abi.encode(20, 2)));
        temple.write(
            uint(keccak256(abi.encode(22, x))),
            bytes32(abi.encode(msg.sender))
        );
    }

    function part3() external {
        temple.write(3, bytes32(uint256(6))); // Updates length
        temple.write(
            uint(keccak256(abi.encode(3))) + 5, 
            bytes32(abi.encode(msg.sender))
        ); // Updates chambers[5]
    }
}