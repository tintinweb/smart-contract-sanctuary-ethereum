// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ILenderVerifier {
    function isAllowed(
        address lender,
        uint256 amount,
        bytes memory signature
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IMerkleTreeVerifier {
    function verify(
        uint256 index,
        bytes32 leaf,
        bytes32[] calldata proof
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ILenderVerifier} from "ILenderVerifier.sol";
import {IMerkleTreeVerifier} from "IMerkleTreeVerifier.sol";

contract AllowListLenderVerifier is ILenderVerifier {
    IMerkleTreeVerifier public immutable verifier;
    uint256 public immutable allowListIndex;

    constructor(IMerkleTreeVerifier _verifier, uint256 _allowListIndex) {
        verifier = _verifier;
        allowListIndex = _allowListIndex;
    }

    function isAllowed(
        address lender,
        uint256,
        bytes memory merkleProof
    ) external view returns (bool) {
        return verifier.verify(allowListIndex, keccak256(abi.encodePacked(lender)), bytesToBytes32Array(merkleProof));
    }

    function bytesToBytes32Array(bytes memory data) public view returns (bytes32[] memory) {
        uint256 dataLength = data.length;
        bytes32[] memory dataList = new bytes32[](dataLength / 32);
        uint256 index = 0;
        bytes32 temp;

        for (uint256 i = 32; i <= dataLength; i += 32) {
            assembly {
                temp := mload(add(data, i))
            }
            dataList[index] = temp;
            index++;
        }

        return dataList;
    }
}