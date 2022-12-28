// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IEvalEIP712Buffer {
    function evalEIP712Buffer(bytes memory signature) external view returns (string[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "src/IEvalEIP712Buffer.sol";

contract SeaPortMock {
    address public immutable eip712TransalatorContract;

    constructor(address _translator) {
        eip712TransalatorContract = _translator;
    }

    // SeaPort logic

    function translateSig(bytes memory order) public view returns (string[] memory) {
        return IEvalEIP712Buffer(eip712TransalatorContract).evalEIP712Buffer(order);
    }
}