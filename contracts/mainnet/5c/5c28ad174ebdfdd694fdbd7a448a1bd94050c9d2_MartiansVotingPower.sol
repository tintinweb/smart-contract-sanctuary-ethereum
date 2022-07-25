/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ERC721Compliant is not an ERC721 token. It is the bare minimum that 
// can be accepted in the standard and does not represent an actual ERC721.

contract ERC721Compliant {
    // Name and Symbol
    string public name;
    string public symbol;

    // Constructor
    constructor(string memory name_, string memory symbol_) {
        name = name_; symbol = symbol_; }

    // Magic Events 
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    // Magic Logic (Override These)
    function totalSupply() public virtual view returns (uint256) {}
    function ownerOf(uint256 tokenId_) public virtual view returns (address) {}
    function balanceOf(address address_) public virtual view returns (uint256) {}

    // Magic Compliance
    function supportsInterface(bytes4 iid_) public virtual view returns (bool) {
        return iid_ == 0x01ffc9a7 || iid_ == 0x80ac58cd || iid_ == 0x5b5e139f; 
    }

    // Magic TokenURI
    function tokenURI(uint256 tokenId_) public view virtual returns (string memory) {}
}

abstract contract Ownable {
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Ownable: NO"); _; }
    function transferOwnership(address newOwner_) public virtual onlyOwner {
        owner = newOwner_; 
    }
}

interface iMartians {
    function walletOfOwner(address address_) external view returns (uint256[] memory);
}

interface iCS {
    // The Character Struct
    struct Character {
        uint8  race_;
        uint8  renderType_;
        uint16 transponderId_;
        uint16 spaceCapsuleId_;
        uint8  augments_;
        uint16 basePoints_;
        uint16 totalEquipmentBonus_;
    }

    function characters(uint256 tokenId_) external view returns (Character memory);
}

// Todo: 
/*
    Augments to Voting Power configuration
*/

// Using ERC721Compliant, we can Override functions that we want from above
contract MartiansVotingPower is ERC721Compliant("Martians", "MARTIANS"), Ownable {

    // Interfaces
    iMartians public Martians = iMartians(0x075854b315F2cd7eC490853Bc5589B09E546449f);
    iCS public CS = iCS(0xC7C40032E952F52F1ce7472913CDd8EeC89521c4);

    // Augments to Voting Power Configuration
    mapping(uint8 => uint256) public augmentsToVotingPower;

    // Augments to Voting Power Owner Function
    function setAugmentsToVotingPower(uint8[] calldata augments_, 
    uint256[] calldata power_) external onlyOwner {
        require(augments_.length == power_.length, "!= length");
        for (uint256 i = 0; i < augments_.length; i++) {
            augmentsToVotingPower[augments_[i]] = power_[i];
        }
    }

    // BalanceOf which acts as Voting Power
    function balanceOf(address address_) public view override returns (uint256) {
        // First, grab the wallet using walletOfOwner
        uint256[] memory _wallet = Martians.walletOfOwner(address_);
        
        // Instantiate local power tracker and then loop CS to get powers
        uint256 _votingPower;
        for (uint256 i = 0; i < _wallet.length; i++) {
            _votingPower += (CS.characters(_wallet[i]).augments_ + 1);
        }

        // Return the voting power
        return _votingPower;
    }
}