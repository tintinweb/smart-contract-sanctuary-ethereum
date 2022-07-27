/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

pragma solidity ^0.4.21;

interface IFuzzyIdentityChallenge {
    function authenticate() public;
}

contract CTFFuzzyIdentityChallenge {
    function CTFFuzzyIdentityChallenge() public {
        
    }

    function name() external view returns (bytes32) {
        bytes32 name = bytes32("smarx");
        return name;
    }

    function attack(address _address) public {
        IFuzzyIdentityChallenge fuzzy = IFuzzyIdentityChallenge(_address);
        fuzzy.authenticate();
    }
}