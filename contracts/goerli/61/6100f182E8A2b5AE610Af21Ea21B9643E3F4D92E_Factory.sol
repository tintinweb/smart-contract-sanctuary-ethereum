// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./StaticInit.sol";

contract Factory {
    function deploy() external {
        // use CREATE2 to deploy. salt can be any random number
        new StaticInit{salt: bytes32(uint256(0x1))}( /* constructor args */);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface CodeSpitter {
    function getRuntimeBytecode() external view returns (bytes memory);
}

contract StaticInit {
    constructor() {
        bytes memory bytecode = CodeSpitter(
            0x35EC9790AE972499480576C17fE6E3f924438F0a
        ).getRuntimeBytecode();
        assembly {
            return(add(bytecode, 0x20), mload(bytecode))
        }
    }
}