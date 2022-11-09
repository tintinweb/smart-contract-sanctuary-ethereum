// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "./Ownable.sol";
import {ERC721A} from "./ERC721A.sol";

contract Grimalkins is ERC721A, Ownable {

    enum MintState {
        Closed,
        Open
    }

    MintState public mintState;

    uint256 public MAX_SUPPLY = 347;
    uint256 public PRICE = 0.039 ether;
    uint256 public WALLET_LIMIT = 3;

    string public baseURI = "ipfs://";
    string public notRevealedURI = "ipfs://bafkreibk4i45n7ny4kuw226d23b27rwxvmptgugmdoamwgx4glqlvshnha";
    bool public revealed;

    constructor(
        address recipient,
        uint256 allocation
    ) ERC721A("Grimalkins by Chiho Aoshima", "GMK") {
        if (allocation < MAX_SUPPLY && allocation != 0)
            _mint(recipient, allocation);
    }

    // Modifiers

    modifier onlyExternallyOwnedAccount() {
        require(tx.origin == msg.sender, "Not externally owned account");
        _;
    }

    // Mint functions

    function remainingForAddress(address who) public view returns (uint256) {
        if (mintState == MintState.Open)
            return WALLET_LIMIT + _getAux(who) - _numberMinted(who);
        else revert("Invalid sale state");
    }

    function setMintState(uint256 newState) external onlyOwner {
        if (newState == 0) mintState = MintState.Closed;
        else if (newState == 1) mintState = MintState.Open;
        else revert("Invalid sale state");
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
        require(mintState == MintState.Open, "Invalid sale state");
        require(msg.value >= PRICE * quantity, "Insufficient value");
        require(remainingForAddress(msg.sender) >= quantity, "Limit for user reached");

        _mint(msg.sender, quantity);
    }

    // Token

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if(revealed == false) {
            return notRevealedURI;
        }

        string memory baseURIStr = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURIStr, _toString(tokenId), ".json")) : '';
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        PRICE = newPrice;
    }

    function reveal() external view onlyOwner {
        require(!revealed, "already revealed");
        revealed == true;
    }

    // Withdraw

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}