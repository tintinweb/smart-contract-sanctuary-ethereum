// File: BudgetArtBlocks.sol

/// SPDX-License-Identifier: MIT

// The poor mans art blocks, all stored in a single slot!

// Instructions: 
// No front end so you have to interact raw sorry 

// 1) Call generateArt(uint256 seed) with a random number to produce your artwork
// 2) Then call viewGallery(address artist) to download the artwork by the artist specified
// 3) run this python code with the result as from 2) as out to display your plot:
//     import numpy as np
//     import matplotlib.pyplot as plt 
//     encoded = list(map(int, list(bin(int(out))[2:].zfill(256))))
//     art = np.reshape(binary, (16,16), 'C') 
//     plt.imshow(plot, cmap="plasma")
//     plt.axis("off")
//     plt.show()


pragma solidity ^0.8.12;

contract BudgetArtBlocks {

    mapping(address => uint256) public gallery; 
    uint256 constant internal ONE = uint(1);

    function generateArt(uint256 seed) public {
        uint256 base = uint256(keccak256(abi.encode(seed)));
        uint256 out = complexAIQuantumGenerativeAlgorithm(base);
        gallery[msg.sender] = out;
    }
    function viewGallery(address artist) public view returns (uint256) {
        return gallery[artist];
    }
    function complexAIQuantumGenerativeAlgorithm(uint256 input) internal pure returns (uint256) {
        uint256 n = 16;
        uint256 out = 0;
        for (uint256 i=1; i<15; i++) {
            for (uint256 j=1; j<15; j++) {
                uint256 b = bit(input,j+n*i)+
                            bit(input,j+1+n*i)+
                            bit(input,j-1+n*i)+
                            bit(input,j+n*(i+1))+
                            bit(input,j+n*(i-1))+
                            bit(input,j+1+n*(i+1))+
                            bit(input,j+1+n*(i-1))+
                            bit(input,j-1+n*(i+1))+
                            bit(input,j+1+n*(i-1));
                if (b>4) {
                    out = setBit(out, j+n*i);
                }
            }
        }
        return out;
    }
    function bit(uint256 self, uint256 index) internal pure returns (uint256) {
        return self >> index & 1;
    }
    function setBit(uint256 self, uint256 index) internal pure returns (uint256) {
        return self | ONE << index;
    } 
}