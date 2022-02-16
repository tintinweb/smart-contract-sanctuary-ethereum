// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import './ISetup.sol';
import './BitMania.sol';

contract Setup is ISetup {
    BitMania public instance;

    constructor() {

        instance = new BitMania();
        emit Deployed(address(instance));
    }

    function isSolved() external override view returns (bool) {
        return instance.isSolved();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ISetup {
    event Deployed(address instance);

    function isSolved() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract BitMania {
    bool public isSolved;
    bytes public constant encFlag =
        bytes(hex"6e3c5b0f722c430e6d324c0d6f67173d4b1565345915753504211f");

    // following function was used to encrypt the given string
    // when a particular string is passed, encrypted output is `encFlag`
    // reverse `encFlag` to input stirng to solve CTF
    function encryptFlag(string memory stringFlag)
        public
        pure
        returns (bytes memory)
    {
        bytes memory flag = bytes(stringFlag);
        for (uint256 i; i < flag.length; i++) {
            if (i > 0) flag[i] ^= flag[i - 1];
            flag[i] ^= flag[i] >> 4;
            flag[i] ^= flag[i] >> 3;
            flag[i] ^= flag[i] >> 2;
            flag[i] ^= flag[i] >> 1;
        }

        return flag;
    }

    // solve the ctf by calling this function
    function solveIt(string memory flag) external {
        bytes memory output = encryptFlag(flag);
        if (keccak256(output) == keccak256(encFlag)) isSolved = true;
    }
}