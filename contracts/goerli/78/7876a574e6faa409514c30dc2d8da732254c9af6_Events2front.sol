/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

contract Events2front {

    uint public largestContribution;
    uint public contributionDate;
    address public largestContributor;

    event Contribute(address indexed contributorSearch, address contributor, uint contribution);
    event NewLargestContributor(address contributor, uint contribution);
    event WithdrawMoney(address contributor, uint balance);

    modifier mainContributor {
	        require(msg.sender == largestContributor, 
            "You are not the largest Contributor" );

	        require(contributionDate < block.timestamp, 
            "please wait your time" );
	        _;
	    }

    function contribute() public payable {
        
        emit Contribute(msg.sender, msg.sender, msg.value);

        if(largestContribution < msg.value)
        {
            largestContributor = msg.sender;
            largestContribution= msg.value;
            contributionDate = block.timestamp + 5 minutes;
            emit NewLargestContributor(msg.sender, msg.value);
        }
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

     function withdrawMoneyTo(address payable _to) mainContributor public {
        largestContribution =0;
        largestContributor=address(0);

         uint balance=getBalance();
        _to.transfer(balance);
        emit WithdrawMoney(msg.sender, balance);
    }
}