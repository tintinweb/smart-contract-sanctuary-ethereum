/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// library GetCode {
//     function at(address addr) public view returns (bytes memory code) {
//         assembly {
//             // retrieve the size of code, this needs assembly
//             let size := extcodesize(addr)
            
//             // allocate output byte array - this could also be done without assembly by using code = new bytes(size).
//             code := mload(0x40)

//             // new "memory end" including padding.
//             mstore(0x40, add(code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            
//             // store length in memory
//             mstore(code, size)

//             // actually retrieve the code, this needs assembly.
//             extcodecopy(addr, add(code, 0x20), 0, size)

//         }
//     } 
// }

library VectorSum {
    // This function is less efficient because the optimizer currently fails to remove the bounds checks in array access.
    function sumSolidity(uint256[] memory data) internal pure returns (uint256 sum) {
        for (uint256 i = 0; i < data.length; ++i) {
            sum += data[i];
        }
    }

    /**
        We know that we only access the array in bounds, so we can avoid the check.
        0x20 needs to be added to an array because the first slot contain the array length.
    */
    function sumAsm(uint256[] memory data) internal pure returns (uint256 sum) {
        for (uint256 i = 0; i < data.length; i++) {
            assembly {
                sum := add(sum, mload(add(add(data, 0x20), mul(i, 0x20))))
            }
        }
    }

    // Same as above, but accomplish the entire code within inline assembly.
    function sumPureAsm(uint256[] memory data) internal pure returns (uint256 sum) {
        assembly {
            // Load the length (first 32 bytes)
            let len := mload(data)

            // Skip over the length field
            // 
            // Keep temporary variable so it can be incremented in place.
            // NOTE: incrementing data would result in an unusable data variable after this assembly block.
            let dataElementLocation := add(data, 0x20)

            // Iterate until the bound is not met.
            for 
                { let end := add(dataElementLocation, mul(len, 0x20)) }
                lt(dataElementLocation, end)
                { dataElementLocation := add(dataElementLocation, 0x20) }
            {
                sum := add(sum, mload(dataElementLocation))
            }
        }
    }
}

contract Mock {
    function sumSolidity(uint256[] memory data) public returns (uint256 sum) {
        return VectorSum.sumSolidity(data);
    }

    function sumAsm(uint256[] memory data) public returns (uint256 sum) {
        return VectorSum.sumAsm(data);
    }

    function sumPureAsm(uint256[] memory data) public returns (uint256 sum) {
        return VectorSum.sumPureAsm(data);
    }

    function testCalldata(uint256[] calldata input) public pure returns (uint256 length, bytes memory offset) {
        assembly {
            length := input.length
            offset := input.offset
        }
    }
}