/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

pragma solidity ^0.8.0;

contract CarbonCredit {
    address walletMarketOwner;
    mapping(string => string) carbonCredits;

    event CarbonCreditCreated(string carbonCreditTokenId, string ownerAddress);
    event CarbonCreditRetired(string carbonCreditTokenId);
    event CarbonCreditChanged(string carbonCreditTokenId, string oldOwner, string newOwner);

    constructor() public {
        walletMarketOwner = msg.sender;
    }

    function saveCarbonCredit(string memory _carbonCreditTokenId, string memory _ownerAddress) public {
        require(msg.sender == walletMarketOwner, "Only the owner of the market wallet address can save carbon credits.");
        carbonCredits[_carbonCreditTokenId] = _ownerAddress;
        emit CarbonCreditCreated(_carbonCreditTokenId, _ownerAddress);
    }

    function retireCarbonCredit(string memory _carbonCreditTokenId) public {
        require(msg.sender == walletMarketOwner, "Only the owner of the market wallet can retire carbon credits.");
        delete carbonCredits[_carbonCreditTokenId];
        emit CarbonCreditRetired(_carbonCreditTokenId);
    }

    function changeOwnerOfCarbonCreditToken(string memory _carbonCreditTokenId, string memory _newOwnerAddress) public {
        require(msg.sender == walletMarketOwner, "Can't change the owner of a retired token. Either the token is retired or you are not the owner of the market");
        string memory oldOwner = carbonCredits[_carbonCreditTokenId];
        carbonCredits[_carbonCreditTokenId] = _newOwnerAddress;
        emit CarbonCreditChanged(_carbonCreditTokenId, oldOwner, _newOwnerAddress);
    }
}