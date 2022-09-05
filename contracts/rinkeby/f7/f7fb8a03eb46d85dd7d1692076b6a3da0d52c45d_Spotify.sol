/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Spotify {
    uint public investmentTotal = 1 ether;
    uint public investmentAvailable = investmentTotal;
    uint public nrOfInvestors = 0;

    string public artistName;
    address payable public artistAddress;

    bool public investmentIsClosed = false;

    struct Investor {
        address payable investorAddress;
        uint investment;
        string name;
    }

    mapping(address => Investor) public investors;

    address payable[] public arrInvestors;

    constructor(string memory _name) {
        artistName = _name;
        artistAddress = payable(msg.sender);
    }

    function invest (string memory _investorName) payable public {
        require(msg.value <= investmentAvailable, "You can't invest more than what's still available.");
        require(msg.value >= 0.1 ether, "Invest at least 0.1 ETH");

        investors[msg.sender] = Investor({ investorAddress: payable(msg.sender), investment: msg.value, name: _investorName });
        arrInvestors.push(payable(msg.sender));
        nrOfInvestors++;
    }

    function payRoyalties() payable public {
        uint royalties = msg.value;
        uint royaltiesArtist = royalties * 50 / 100;
        uint royaltiesInvestors = royalties - royaltiesArtist;

        payable(artistAddress).transfer(royaltiesArtist);
        for(uint i=0; i < arrInvestors.length; i++){
            payable(arrInvestors[i]).transfer( royaltiesInvestors * investors[arrInvestors[i]].investment / investmentTotal );
        }
    }
}