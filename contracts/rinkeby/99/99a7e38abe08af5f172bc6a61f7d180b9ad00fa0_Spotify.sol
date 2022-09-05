/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0; // versie van een compiler

// array => dure structuur
contract Spotify {
    // ----------
    // Properties 
    // ----------
    uint public investmentTotal = 1 ether; // onzichtbaar een getter gemaakt 
    uint public investmentAvailable = investmentTotal;
    uint public nrOfInvestors = 0;

    string public artistName;
    address payable public artistAddress; // wallet of naar een ander contract

    bool public investmentIsClosed = false;

    // puur intern + intern use 
    struct Investor {
        address payable investorAddress;
        uint investment;
        string name;
    }

    mapping(address => Investor) public investors;

    address payable[] public arrInvestors;

    //
    // 1 maal met de deploy
    // geeft tijdelijk 
    // msg.sender => wie
    // msg.value => hoeveel
    //
    constructor(string memory _name) {
        artistName = _name;
        artistAddress = payable(msg.sender); // artist address, enkel voor de persoon die het contract maakt, payable() cast
    }

    function invest(string memory _investorName) payable public {
        require(msg.value <= investmentAvailable, "You can't invest more then what's still available.");
        require(msg.value >= 0.1 ether, "Invest at least 0.1 ETH");

        investors[msg.sender] = Investor({
            investorAddress: payable(msg.sender),
            investment: msg.value,
            name: _investorName
        });

        arrInvestors.push(payable(msg.sender));
        nrOfInvestors++;
    }

    function payRoyalties() payable public {
        uint royalties = msg.value;
        uint royaltiesArtist = royalties * 50 / 100;
        uint royaltiesInvestors = royalties - royaltiesArtist;

        payable(artistAddress).transfer(royaltiesArtist); // method van Etherum

        for (uint i=0; i < arrInvestors.length; i++) {
            payable(arrInvestors[i]).transfer( royaltiesInvestors * (investors[arrInvestors[i]].investment /  investmentTotal));
        }
    }
}