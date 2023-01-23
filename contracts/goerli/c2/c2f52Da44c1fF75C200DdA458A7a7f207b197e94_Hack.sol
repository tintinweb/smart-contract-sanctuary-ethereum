// SPDX-License-Identifier: WTFPL
pragma solidity 0.8.7;

contract Hack {
    address public contractAddress;

    function attack() external {
        // The creation bytecode, you can find in README.md
        bytes memory bytecode = hex"69602a60005260206000f3600052600a6016f3";
        address deployAddress;
        assembly {
            deployAddress := create(0, add(bytecode, 0x20), 0x13)
            /** The first argument is the amount, in our case equal to zero
             * Second argument is we ignore the first 32 bytes  in hex 20
             * third argument  is the size 19 bytes in hex is 13
             */
        }
        contractAddress = contractAddress;
    }
}

interface IMagicNum {
    function whatIsTheMeaningOfLife() external view returns (uint);
}