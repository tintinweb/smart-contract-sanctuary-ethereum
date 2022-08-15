/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract AAAAA{
    uint256[100] public randomBoxProbability =  [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
                                                    ,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
                                                    ,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,5,5,5,6,6,7
                                                ];

    function set() public view returns(uint256){
        uint256 randomNo = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.number, blockhash(block.number -1), randomBoxProbability.length)));
        uint256 randomId = randomNo % randomBoxProbability.length;
        return randomId;
    }

    function setOdds(uint256 _cash, uint256 _common, uint256 _uncommon, uint256 _rare
    , uint256 _epic, uint256 _legendary, uint256 _mythic
    ) 
    public 
    {
        uint256 total1 = _cash + _common;
        uint256 total2 = total1 + _uncommon;
        uint256 total3 = total2 + _rare;
        uint256 total4 = total3 + _epic;
        uint256 total5 = total4 + _legendary;
        uint256 total6 = total5 + _mythic;

        for(uint256 c = 0; c< _cash; c++){
            randomBoxProbability[c] = 1;
        }
        for(uint256 cmn = _cash; cmn < total1; cmn++){    // commonOdd
            randomBoxProbability[cmn] = 2;
        }
        for(uint256 ucmn = total1; ucmn< total2; ucmn++){        // uncommonOdd
            randomBoxProbability[ucmn] = 3;
        }
        for(uint256 rare_ = total2; rare_ < total3; rare_++){      // rareOdd
            randomBoxProbability[rare_] = 4;
        }
        for(uint256 epc = total3; epc < total4; epc++){          //  epic
            randomBoxProbability[epc] = 5;
        }
        for(uint256 legand = total4; legand < total5; legand++){   // legandary
            randomBoxProbability[legand] = 6;
        }
        for(uint256 myth = total5; myth < total6; myth++){
            randomBoxProbability[myth] = 7;
        }
    }

    function getRandomBoxProb() public view returns(uint256[100] memory){
        return randomBoxProbability;
    }
}