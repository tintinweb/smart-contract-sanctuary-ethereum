/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Register {

    string public github;
    address public owner;
    struct Referral{
        address add;
        string name;
    }
    Referral[] public referrals;


    constructor(string memory _github) {
        github = _github;
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function addReferral(address _wallet, string calldata _user) external onlyOwner(){
        referrals.push(Referral({add: _wallet, name: _user}));
    }


}