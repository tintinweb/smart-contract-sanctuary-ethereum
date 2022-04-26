/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

pragma solidity ^0.8.0;

contract LabVoting {
    uint256 public yes;
    uint256 public no;

    mapping(address => bool) public voters;

    function vote(bool _iHaveBeenOnCampusBefore22) public {
        require(voters[msg.sender] == false, "Voters can only vote once!");

        if(_iHaveBeenOnCampusBefore22)
            yes = yes + 1;
        else
            no = no + 1;

        voters[msg.sender] = true;
    }
}