/**
 *Submitted for verification at Etherscan.io on 2022-10-04
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;


contract Extractor {

    function extract(bytes calldata _compressed) public pure returns (bytes memory) {
        uint256 resultLength = 0;

        for (uint256 index; index < _compressed.length; index++) {
            resultLength++;

            if (_compressed[index] == 0) {
                index++;

                resultLength += uint8(_compressed[index]);
            }
        }

        bytes memory result = new bytes(resultLength);

        uint256 resultIndex;

        for (uint256 index; index < _compressed.length; index++) {
            bytes1 value = _compressed[index];

            if (value == 0) {
                index++;

                uint8 extraLength = uint8(_compressed[index]);

                for (uint256 extraIndex; extraIndex < extraLength; extraIndex++) {
                    result[resultIndex + extraIndex] = 0;
                }

                resultIndex += extraLength;
            } else {
                result[resultIndex] = value;
            }

            resultIndex++;
        }

        return result;
    }

    function test(bytes calldata _compressed) external {
        extract(_compressed);
    }

}