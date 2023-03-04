/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ScavengerHuntSeriesOne {


    function ChallengeOne(uint256 _tokenId) public {

    }

    function ChallengeTwo(address _theSleepMinter) public {

    }


    function ChallengeThree(uint256 _firstSecret, uint256 _secondSecret) public {

    }

    function ChallengeFour(uint256 _theBaseFee) public {

    }

    function ChallengeFive(address helloWorldContractAddress) public {

    }

    function getCompletedChallenges(address _user) public view returns (uint256 [5] memory){
        uint256 [5] memory completed;

        completed[0] = 1;
        completed[1] = 0;
        completed[2] = 1;
        completed[3] = 1;
        completed[4] = 1;
        
        return completed;
    }

    function completedAllChallenges(address _user) public view returns (bool){        
        return true;
    }

}