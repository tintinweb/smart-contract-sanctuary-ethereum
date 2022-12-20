/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CrowdFund {

    address public owner;
    mapping(address=>uint256) public contributions;
    uint256 public allTimeContributions;
    string public fundName;

    constructor(string memory _fundName){
        owner = msg.sender;
        fundName = _fundName;
    }

    modifier onlyOwner{
        require( msg.sender == owner);
        _;
    }

    function withdraw() public onlyOwner{
        payable(owner).transfer(address(this).balance);   
    }

    function contribute() public payable{
        contributions[msg.sender] = contributions[msg.sender] + msg.value;
        allTimeContributions = allTimeContributions + msg.value;
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
}