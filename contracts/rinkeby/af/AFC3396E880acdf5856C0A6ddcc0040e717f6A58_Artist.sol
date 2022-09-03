/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Artist {
    uint public investmentTotal = 1 ether;
    uint public investmentDone = 0 ether;
    uint public investmentOpen = investmentTotal;

    string public artistName;
    address public artistAddress; // set when deploying = owner

    bool public investmentClosed = false;
    uint public investmentNumber = 0;

    struct Investor {
        address payable investorAddress;
        uint investmentAmount;
        string name;
    }

    mapping (address => Investor) public investors;
    address payable[] public arrInvestors;

    constructor(string memory _name) {
        artistName = _name;
        artistAddress = payable(msg.sender);
    }

    function invest (string memory _name) payable public {
        require(msg.value > 0.1 ether, "Invest at least 0.2 ether");
        require(investmentClosed != true, "Sorry, investments are closed");
        require(msg.value <= investmentOpen, "sorry, invest no more than what is still open");

        investors[msg.sender] = Investor({ investorAddress: payable(msg.sender), investmentAmount: msg.value, name: _name });
        arrInvestors.push(payable(msg.sender));

        investmentOpen = investmentOpen - msg.value;
        if(investmentOpen == 0){
            investmentClosed = true;
        }
        investmentNumber++;
    }


    function payRoyalties() payable public {
        uint royalties = msg.value;
        uint royaltiesForArtist = msg.value * 50/100;
        uint royaltiesForInvestors = royalties - royaltiesForArtist;

        payable(artistAddress).transfer(royaltiesForArtist);        
        for(uint counter = 0; counter < arrInvestors.length; counter++) {
            payable(arrInvestors[counter]).transfer(royaltiesForInvestors * investors[arrInvestors[counter]].investmentAmount / investmentTotal);
        }
    }



}