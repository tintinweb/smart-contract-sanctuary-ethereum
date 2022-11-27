/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

/*
* SPDX-License-Identifier : MIT
*/
pragma solidity ^0.8.5;

contract DonationDapp{
    address public immutable Distributor;           // Distributor of dapp and exclusive content.
    uint public immutable Donation;                 // The Donation ammout.
    string public DappCID;                          // CID of the dapp.
    string public ContentCID;                       // CID of the exclusive content for donators.
    uint public ContentTime;                        // Time at which ContentCID is expected to be set for Donator interaction.
    uint public immutable MaxDonators;              // Max number of Donators.
    uint public DonatorID;                          // Number of Donators. 
    mapping (address => bool) public DonatorsMap;   // Mapping of Donators.
    address[] public DonatorsArr;                   // Array of Donators.

    modifier onlyDistributor{
        require(msg.sender == Distributor, "Invalid Distributor Address.");
        _;
    }

    constructor(uint _donation, uint _maxDonators, uint _contentTime){
        Distributor = msg.sender;
        Donation = _donation;
        MaxDonators = _maxDonators;
        ContentTime = _contentTime;
    }

    function _baseURI() internal pure returns(string memory){
        return "ipfs://";
    }

    function tokenURI(uint _donatorId) public view returns(string memory){
        require(DonatorID < _donatorId, "Invalid DonatorID");
        return string(abi.encodePacked(_baseURI(), DappCID));
    }

    function distributeDapp(string memory _dappCID) public onlyDistributor{
        require(compare(DappCID, ""), "Dapp CID has already been set."); // all or nothing condition.
        DappCID = _dappCID;
    }

    function setContentCID(string memory _contentCID) public onlyDistributor{
        require(compare(ContentCID, ""), "ContentCID has already been set."); // all or nothing condition.
        ContentCID = _contentCID;
    }

     // Compare string _a and _b equality
    function compare(string memory _a, string memory _b) internal pure returns(bool){
        return keccak256( abi.encodePacked( bytes(_a) ) )  == keccak256( abi.encodePacked( bytes(_b) ) );
    }

    function claim() public onlyDistributor{
        (bool sent, ) = Distributor.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function donate() public payable{
        require(!DonatorsMap[msg.sender], "You have already donated to this public goods project.");
        require(DonatorID < MaxDonators, "The donation maximum has been reached");
        require(msg.value >= Donation, "You must donate the contract donation value to participate.");
        DonatorID++;
        DonatorsMap[msg.sender] = true;
        DonatorsArr.push(msg.sender);
    }
}