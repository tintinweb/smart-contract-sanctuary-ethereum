/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract DirtyContract {
    event LogEvent(uint256 number, bytes data);

    uint256 public number;

    function setNumber(uint256 newNumber) external {
        number = newNumber;
    }

    function increment() external {
        number++;
    }

    function log(bytes calldata data) external {
        emit LogEvent(number, data);
    }

    function noop() external payable {}

    receive() external payable {}

    function deploy() external returns (Dummy) {
        return new Dummy();
    }
}

contract Dummy {
    constructor() {
        assembly {
            mstore(0, 0x60006000F3)
            return(0x1B, 0x05)
        }
    }
}