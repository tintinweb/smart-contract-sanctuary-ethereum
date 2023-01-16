/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

pragma solidity ^0.8.0;

contract CarbonCredit {
    address walletMarketOwner;

    struct CarbonCreditStruct {
        string CarbonCreditTokenId;
        string OwnerAddress;
        bool IsTokenRetired;
    }

    mapping(string => CarbonCreditStruct) carbonCredits;

    constructor() public {
        walletMarketOwner = msg.sender;
    }

    function saveCarbonCredit(string memory _carbonCreditTokenId, string memory _ownerAddress) public {
        require(msg.sender == walletMarketOwner, "Only the owner of the market wallet address can save carbon credits.");
        carbonCredits[_carbonCreditTokenId] = CarbonCreditStruct(_carbonCreditTokenId, _ownerAddress, false);
    }

    function retireCarbonCredit(string memory _carbonCreditTokenId) public {
        require(msg.sender == walletMarketOwner && !carbonCredits[_carbonCreditTokenId].IsTokenRetired, "Only the owner of the market wallet can retire carbon credits.");
        carbonCredits[_carbonCreditTokenId].IsTokenRetired = true;
    }

    function viewCarbonCredit(string memory _carbonCreditTokenId) public view returns (string memory, string memory, bool) {
        CarbonCreditStruct storage carbonCredit = carbonCredits[_carbonCreditTokenId];
        return (carbonCredit.CarbonCreditTokenId, carbonCredit.OwnerAddress, carbonCredit.IsTokenRetired);
    }

    function changeOwnerOfCarbonCreditToken(string memory _carbonCreditTokenId, string memory _newOwnerAddress) public {
        require(carbonCredits[_carbonCreditTokenId].IsTokenRetired == false && msg.sender == walletMarketOwner, "Can't change the owner of a retired token. Either the token is retired or you are not the owner of the market");
        carbonCredits[_carbonCreditTokenId].OwnerAddress = _newOwnerAddress;
    }

}