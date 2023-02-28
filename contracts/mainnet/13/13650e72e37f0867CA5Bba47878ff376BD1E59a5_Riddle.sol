// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../ICTF.sol";

contract Riddle is ICTF {
    mapping(address => bool) public solved;

    function markSolved(address contractAddress) external {
        if (
            getContractCodeHash(contractAddress) ==
            0x03068c1cff991c5288d2f1790e7c9c13435769c63c6917d68ba15ae3f070ed25
        ) {
            solved[msg.sender] = true;
        }
    }

    function getContractCodeHash(address contractAddress)
        public
        view
        returns (bytes32 contractCodeHash)
    {
        assembly {
            contractCodeHash := extcodehash(contractAddress)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICTF {
    function solved(address student) external view returns (bool);
}