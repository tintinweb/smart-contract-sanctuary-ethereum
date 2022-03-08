// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./AbstractNFTAccess.sol";

contract NFTAccess is AbstractNFTAccess  {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    uint public tier1 = 0;
    uint public tier2 = 1;
    uint public tier3 = 2;

    bool public canSingleMint = false;

    address public NFT_Access_Address = 0x95F71D6424F2B9bfc29378Ea9539372c986F2E9b;

    Counters.Counter private ticketCount; 
    mapping(uint256 => ticketStruct) public tickets;

    struct ticketStruct {
        uint256 mintPrice;
        uint supply;
        uint currentSupply;
        uint claimLimit;
        string hash;
        bool canClaim;
        mapping(address => uint256) amountClaimed;
    }

    constructor(string memory _name, string memory _symbol) ERC1155("ipfs://") {
        name_ = _name; 
        symbol_ = _symbol;
    } 


    /*
    * @notice Add item to collection
    *
    * @param _mintPrice the price per ticket
    * @param _supply the max supply of this item
    * @param _claimLimit the max amount of nfts each user can claim for this item
    * @param _hash the hash of the image
    * @param _canClaim if it can currently be claimed
    */
    function addTicketStruct (uint256 _mintPrice, uint _supply, uint _claimLimit, string memory _hash, bool _canClaim) external onlyOwner {
        ticketStruct storage ticket = tickets[ticketCount.current()];
        ticket.mintPrice = _mintPrice;
        ticket.supply = _supply;
        ticket.currentSupply = 0;
        ticket.claimLimit = _claimLimit;
        ticket.hash = _hash;
        ticket.canClaim = _canClaim;
        ticketCount.increment();
    }


    /*
    * @notice Edit item in collection
    *
    * @param _mintPrice the price per ticket
    * @param _ticket the ticket to edit
    * @param _supply the max supply of this item
    * @param _claimLimit the max amount of nfts each user can claim for this item
    * @param _hash the hash of the image
    * @param _canClaim if it can currently be claimed
    */
    function editTicketStruct (uint256 _mintPrice, uint _ticket, uint _supply, uint _claimLimit, string memory _hash, bool _canClaim) external onlyOwner {
        tickets[_ticket].mintPrice = _mintPrice;    
        tickets[_ticket].hash = _hash;    
        tickets[_ticket].supply = _supply;
        tickets[_ticket].claimLimit = _claimLimit;    
        tickets[_ticket].canClaim = _canClaim;
    }       


    /*
    * @notice mint item in collection
    *
    * @param quantity the quantity to mint
    */
    function tieredMint (uint256 quantity) external payable {
        uint tier;
        uint currentSupply;

        uint tier1CurrentSupply = tickets[tier1].currentSupply;
        uint tier2CurrentSupply = tickets[tier2].currentSupply;
        uint tier3CurrentSupply = tickets[tier3].currentSupply;

        if (tier1CurrentSupply + quantity <= tickets[tier1].supply) {
            tier = tier1;
            currentSupply = tier1CurrentSupply;
        } else if (tier2CurrentSupply + quantity <= tickets[tier2].supply) {
            tier = tier2;
            currentSupply = tier2CurrentSupply;
        } else if (tier3CurrentSupply + quantity <= tickets[tier3].supply) {
            tier = tier3;
            currentSupply = tier3CurrentSupply;
        } else {
            require(false, "No tickets left from any tier");
        }

        require(currentSupply + quantity <= tickets[tier].supply, "Not enough tickets able to be claimed" );

        if (msg.sender != NFT_Access_Address) {
            require(tickets[tier].canClaim, "Not currently allowed to be claimed" );
            require(quantity <= tickets[tier].claimLimit, "Attempting to claim too many tickets");
            require(quantity.mul(tickets[tier].mintPrice) <= msg.value, "Not enough eth sent");
            require(tickets[tier].amountClaimed[msg.sender] < tickets[tier].claimLimit , "Claimed max amount");
            tickets[tier].amountClaimed[msg.sender] += 1;
        }

        tickets[tier].currentSupply = tickets[tier].currentSupply + quantity; 

        _mint(msg.sender, tier, quantity, "");
    }
    

    /*
    * @notice mint item in collection
    *
    * @param quantity the quantity to mint
    * @param _ticket the ticket to mint
    */
    function singleMint (uint256 quantity, uint256 _ticket) external payable {
        if (msg.sender != NFT_Access_Address) {
            require(canSingleMint, "Must tier mint");
            require(tickets[_ticket].canClaim, "Not currently allowed to be claimed" );
            require(quantity <= tickets[_ticket].claimLimit, "Attempting to claim too many tickets");
            require(quantity.mul(tickets[_ticket].mintPrice) <= msg.value, "Not enough eth sent");
            require(tickets[_ticket].amountClaimed[msg.sender] < tickets[_ticket].claimLimit , "Claimed max amount");
            tickets[_ticket].amountClaimed[msg.sender] += 1;
        }

        uint currentSupply = tickets[_ticket].currentSupply;
        require(currentSupply + quantity <= tickets[_ticket].supply, "Not enough tickets able to be claimed" );
        tickets[_ticket].supply = tickets[_ticket].supply + quantity; 

        _mint(msg.sender, _ticket, quantity, "");
    }

    /*
    * @notice withdraw any money from the contract
    */
    function withdraw() external {
        require(address(this).balance > 0, "Contract currently has no ether");
        uint256 walletBalance = address(this).balance;
        (bool status,) = NFT_Access_Address.call{value: walletBalance}("");
        require(status, "Failed withdraw");
    }


    /*
    * @notice change the tiers for tierTickets
    *
    * @param _tier1 the quantity to mint
    * @param _tier2 the quantity to mint
    * @param _tier3 the quantity to mint
    */
    function changeTierTickets(uint _tier1, uint _tier2, uint _tier3) external onlyOwner {
        tier1 = _tier1;
        tier2 = _tier2;
        tier3 = _tier3;
    }

    /*
    * @notice get the total quantities of current tiers 
    */
    function totalTierQuantity() public view returns (uint) {
        uint quantity1 = tickets[tier1].supply;
        uint quantity2 = tickets[tier2].supply;
        uint quantity3 = tickets[tier3].supply;

        return (quantity1 + quantity2 + quantity3);
    }

    /*
    * @notice get the current quantities of current tiers 
    */
    function currentTierQuantity() public view returns (uint) {
        uint quantity1 = tickets[tier1].currentSupply;
        uint quantity2 = tickets[tier2].currentSupply;
        uint quantity3 = tickets[tier3].currentSupply;

        return (quantity1 + quantity2 + quantity3);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(tickets[_id].supply > 0, "URI: nonexistent token");
        return string(abi.encodePacked(super.uri(_id), tickets[_id].hash));
    }    

}