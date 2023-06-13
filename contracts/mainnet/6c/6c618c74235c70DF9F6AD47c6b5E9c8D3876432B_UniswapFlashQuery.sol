/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

//SPDX-License-Identifier: UNLICENSED
// Author: Emile Amajar
// Code details: https://medium.com/@emileamajar/building-an-arbitrage-bot-efficient-reading-of-pool-prices-166c83c17a69

pragma solidity ^0.8;

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// Batch query contract
contract UniswapFlashQuery {
    function getReservesByPairs(IUniswapV2Pair[] calldata _pairs) external view returns (uint256[3][] memory) {
        uint256[3][] memory result = new uint256[3][](_pairs.length);
        for (uint i = 0; i < _pairs.length; i++) {
            (result[i][0], result[i][1], result[i][2]) = _pairs[i].getReserves();
        }
        return result;
    }
    function getReservesByPairsAsm(address[] calldata _pairs) external view returns (bytes32[] memory) {
        bytes32[] memory result = new bytes32[](_pairs.length * 3);

        assembly {
            let size := 0x60 // Size of the return data (reserve0, reserve1, blockTimestampLast)
            let callData := mload(0x40) // Allocate memory for the function selector
            mstore(callData, 0x0902f1ac00000000000000000000000000000000000000000000000000000000) // 4-byte function selector of the getReserves() function
            
            // Update the free memory pointer
            mstore(0x40, add(callData, 0x04))
            
            // let pairsCount := shr(0xe0, calldataload(sub(_pairs.offset, 0x20))) // Get the length of the _pairs array
            let pairsCount := _pairs.length

            for { let i := 0 } lt(i, pairsCount) { i := add(i, 1) } {
                // Load the pair address from the calldata
                let pair := calldataload(add(_pairs.offset, mul(i, 0x20)))
                    
                // Call the getReserves() function with preallocated memory for function selector
                let success := staticcall(gas(), pair, callData, 0x04, add(add(result, 0x20),mul(i, size)), size)
                if iszero(success) {
                    revert(0x00, 0x00)
                }
            }

            // Update the free memory pointer
            mstore(0x40, add(mload(0x40), mul(pairsCount, size)))
        }

        return result;
    }
}