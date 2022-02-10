/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

contract ResearchIntern {

    string public resume = "Blast off you evil!";

    function KaijuCheck(int _kaijucheck) public {

        if (_kaijucheck == 1234) {
            resume = "https://drive.google.com/file/d/15WIXA0itWoADYxaWPfZLB97KD43mJMV5/view?usp=sharing";
        }
        else{
            resume = "Initiating Self Destruct!";
        }


    }

}