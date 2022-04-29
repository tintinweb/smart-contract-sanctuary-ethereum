/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract FediMedini {
    address public owner = 0x96ef6E86a364F60cD233905D328eBB831FA94BEf;
    mapping(address => bool) public isVoter;
    address public claimer;
    uint256 public numVoters;
    uint256 public forClaim;
    uint256 public againstClaim;

    function editVoter(address[] memory _voter, bool _value) public{
        require(msg.sender == owner, "Caller is not owner");

        for(uint256 i; i< _voter.length; i++){
            if(!isVoter[_voter[i]] && _value){
                numVoters++;
            }else if(isVoter[_voter[i]] && !_value){
                numVoters--;
            }
            isVoter[_voter[i]] = _value;
        }
    }

    function claim() public{
        forClaim = 0;
        againstClaim = 0;
        claimer = msg.sender;
    } 

    function vote(bool _vote) public{
        require(isVoter[msg.sender] || msg.sender == owner, "Caller not a voter");
        if(_vote){
            forClaim++;
        }else{
            againstClaim++;
        }
    }

    function withdraw() public{
        require(msg.sender == claimer, "!Claimer");
        require(forClaim > numVoters/2, "Claim not accepted");
       payable(msg.sender).transfer(address(this).balance);
    }

    function reinitialize() public{
        require(msg.sender == owner, "Caller is not owner");
        claimer = address(0);
        forClaim = 0;
        againstClaim = 0;
    }
}