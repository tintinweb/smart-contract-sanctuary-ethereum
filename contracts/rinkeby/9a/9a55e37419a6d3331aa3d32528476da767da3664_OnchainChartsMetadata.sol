/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.13;

contract OnchainChartsMetadata 
{
    function metadata(uint token) public pure returns(uint16[32] memory colors, uint8[32] memory heights)
    {        
        bytes32 r_c1 = keccak256(abi.encodePacked("c1", token));                
        bytes32 r_c2 = keccak256(abi.encodePacked("c2", token));                
        bytes32 r_a = keccak256(abi.encodePacked("a", token));        

        for (uint8 x = 0; x < 32; ++x)
        {            
            colors[x] = (uint16(uint8(r_c1[x])) << 8) | uint16(uint8(r_c2[x]));                 
            heights[x] = uint8(r_a[x]);
        }
    }    
}