// SPDX-License-Identifier: MIT
// HoYoverse gen coll - 1

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract AdachiRen is ERC721A, Ownable {

    bool public paused = true;
    uint256 public MAX_SUPPLY = 335;
    uint256 public PRICE = 0.029 ether;
    uint256 public WALLET_LIMIT = 3;

    string public baseURI = "ipfs://";
    address public OwnerWallet;
    string public notRevealedURI = "ipfs://bafkreicj5udlihsdbu22au7fon3zgiedvtcle6ufs7tchasw4xnqszgkvq";
    bool public revealed;

    constructor(
        address recipient,
        uint256 allocation
    ) ERC721A("Adachi Ren", "AR") {
        if (allocation < MAX_SUPPLY && allocation != 0) {
            _mint(recipient, allocation);
        }
        OwnerWallet = msg.sender;
    }

    modifier onlyExternallyOwnedAccount() {
        require(tx.origin == msg.sender, "Not externally owned account");
        _;
    }

    function remainingForAddress(address who) public view returns (uint256) {
        if (!paused) {
            return WALLET_LIMIT + _getAux(who) - _numberMinted(who);
        } else {
            revert("Invalid sale state");
        }
    }

    function batchMint(
        address[] calldata recipients,
        uint256[] calldata quantities
    ) external onlyOwner {
        require(recipients.length == quantities.length, "Arguments length mismatch");

        uint256 supply = this.totalSupply();
        for (uint256 i; i < recipients.length; i++) {
            supply += quantities[i];
            require(supply <= MAX_SUPPLY, "Mint exceeds max supply");
            _mint(recipients[i], quantities[i]);
        }
    }

    function mint(uint256 quantity) external payable onlyExternallyOwnedAccount {
        require(this.totalSupply() + quantity <= MAX_SUPPLY, "Mint exceeds max supply");
        require(!paused, "Invalid sale state");
        require(msg.value >= PRICE * quantity, "Insufficient value");
        require(remainingForAddress(msg.sender) >= quantity, "Limit for user reached");

        _mint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        
        if(revealed == false) {
            return notRevealedURI;
        }

        string memory baseURIStr = _baseURI();
        return bytes(baseURI).length != 0 
        ? string(abi.encodePacked(baseURIStr, _toString(tokenId), ".json")) 
        : '';
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function reveal() external view onlyOwner {
        require(!revealed, "already revealed");
        revealed == true;
    }

    function withdraw() external onlyOwner returns (bool) {
        address wallet = ownerWallet();
        payable(wallet).transfer(address(this).balance);
        return true;
    }
}