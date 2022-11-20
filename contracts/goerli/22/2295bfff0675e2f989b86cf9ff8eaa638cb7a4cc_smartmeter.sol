/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.0;

contract smartmeter {
    uint256 lastS;
    uint256 randnum1=1;
    uint256 randnum2=2;
    uint256 randnum3=3;
    uint256 randnum4=4;
    uint256 randnum5=5;

    function importSeedFromThird() public view returns (uint8) {
            
            return uint8(  uint256( keccak256(  abi.encodePacked(  keccak256(abi.encodePacked(block.timestamp, block.difficulty))   ,randnum1   )    ) )         )%200;
            

    }
    function importSeedFromThird2() public view returns (uint8) {
            
            return uint8(  uint256( keccak256(  abi.encodePacked(  keccak256(abi.encodePacked(block.timestamp, block.difficulty))   ,randnum2   )    ) )         )%200;
            

    }
    function importSeedFromThird3() public view returns (uint8) {
            
            return uint8(  uint256( keccak256(  abi.encodePacked(  keccak256(abi.encodePacked(block.timestamp, block.difficulty))   ,randnum3   )    ) )         )%200;
            

    }
    function importSeedFromThird4() public view returns (uint8) {
            
            return uint8(  uint256( keccak256(  abi.encodePacked(  keccak256(abi.encodePacked(block.timestamp, block.difficulty))   ,randnum4   )    ) )         )%200;
            

    }
    function importSeedFromThird5() public view returns (uint8) {
            
            return uint8(  uint256( keccak256(  abi.encodePacked(  keccak256(abi.encodePacked(block.timestamp, block.difficulty))   ,randnum5   )    ) )         )%200;
            

    }
        
        function selct() public view returns (uint8 one,uint8 two,uint8 three,uint8 four,uint8 five){
            if(now - lastS >= 10 minutes){
                one = importSeedFromThird();
                two = importSeedFromThird2();
                three = importSeedFromThird3();
                four = importSeedFromThird4();
                five = importSeedFromThird5();
                if(one != two && one != three && one != four && one != five &&  two != three && two != four && two != five && three != four && three != five && four != five){
                     return (one,two,three,four,five);   
                }
                else{
                selct();
                }
            }
            lastS = now;
        }
}