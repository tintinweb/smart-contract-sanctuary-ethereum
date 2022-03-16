/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract UniCaskRandomArray {

    event ShowRandomNum(uint8 drawTimes, uint8 random);
    event ShowRandomArray(uint8[]);

    struct RandomInfo {
        uint8 arrayMax;
        uint8 drawTimes;
        mapping(uint8 => bool) drawedNums;
    }

    mapping(uint256 => RandomInfo) public _randomInfos;

    function random(string memory randomName,uint8 index) internal returns(uint8) {

        RandomInfo storage randomInfo = _randomInfos[uint256(keccak256(abi.encodePacked(randomName)))];
        require(randomInfo.drawTimes < randomInfo.arrayMax, "you have draw too many times");
        uint8 randomNo = uint8(uint256(keccak256(abi.encodePacked(index, randomInfo.drawTimes, msg.sender, block.timestamp, block.difficulty, block.coinbase))) % (randomInfo.arrayMax - randomInfo.drawTimes)) + 1;

        for (uint8 i = 1; i <= randomInfo.arrayMax; i++) {
            if (randomInfo.drawedNums[i] == true) {
                randomNo++;
            }
            if (i >= randomNo) {
                break;
            }
        }

        randomInfo.drawedNums[randomNo] = true;
        randomInfo.drawTimes = randomInfo.drawTimes + 1;
        // emit ShowRandomNum(randomInfo.drawTimes, randomNo);
        return randomNo;
    }

    function randomArr(string memory randomName, uint8 count) public {
        RandomInfo storage randomInfo = _randomInfos[uint256(keccak256(abi.encodePacked(randomName)))];
        require(randomInfo.drawTimes < 1, "you have get the random array for this randomName yet.");

        randomInfo.arrayMax = count;
        randomInfo.drawTimes = 0;

        uint8[] memory randomArray = new uint8[](count);
        for (uint8 i = 0; i < count; i++) {
            randomArray[i] = random(randomName, i);
        }
        
        emit ShowRandomArray(randomArray);
    }

}