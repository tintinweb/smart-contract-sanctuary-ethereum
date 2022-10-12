/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// SPDX-License-Identifier: Joe Mama License

pragma solidity >=0.7.0 <0.9.0;

/*
 * Position storage. Wassup? Now with signed INTS!
 * Store & retrieve an x, y position for... some reason... now with ROTATION!
 */
contract StructStyleArrayStorage {
    uint public constant NUM_WORDS = 7;

    struct Word {
        int256 xPos;
        int256 yPos;
        int256 rotVal;
    }

    mapping (address => Word[]) public wordsByAddress;
    // Word[5] words;

    // Store some freakin' values, man. 
    function store(int256[] calldata _xPos, int256[] calldata _yPos, int256[] calldata _rotVal) public {
        // if (wordsByAddress[msg.sender][0].xPos == 0) {
        //     for (uint256 i = 0; i < NUM_WORDS; i++) {
        //         wordsByAddress[msg.sender][i] = Word(
        //             {
        //                  xPos: _xPos[i],
        //                 yPos: _yPos[i],
        //                 rotVal: _rotVal[i]
        //             }
        //         );
        //     }
        // }
        // else {
            for (uint256 i = 0; i < NUM_WORDS; i++) {
                wordsByAddress[msg.sender][i].xPos = _xPos[i];
                wordsByAddress[msg.sender][i].yPos = _yPos[i];
                wordsByAddress[msg.sender][i].rotVal = _rotVal[i];
            }
        // }
    }

    // Return some freakin' values, man. 
    function retrieve() public view returns (Word[] memory){
        return(wordsByAddress[msg.sender]);
    }
}