// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import { ERC721A } from "./ERC721A.sol";
import { ERC721ALowCap } from "./ERC721ALowCap.sol";
import { Ownable } from "./Ownable.sol";
import { ECDSA } from "./ECDSA.sol";
import { Strings } from "./Strings.sol";
import { PaymentSplitter } from "./PaymentSplitter.sol";

contract MendelExoodus is Ownable, ERC721A, ERC721ALowCap, PaymentSplitter {
    // To concatenate the URL of an NFT
    using Strings for uint;
    // To verify mint signatures
    using ECDSA for bytes32;

    enum SaleDay { CLOSED, PRESALE_DAY_1, PRESALE_DAY_2, PUBLIC }

    // Used to disallow contracts from sending multiple mint transactions in one tx
    modifier directOnly {
        require(msg.sender == tx.origin);
        _;
    }

    // Constants

    uint constant public cost = 0.1 ether;
    uint constant public maxMintSupply = 7770;
    uint public FreeMintMaxSupply = 940; // Free mint for Genesis + for team + for giveaways
    uint public publicMaxSupply = maxMintSupply - FreeMintMaxSupply;  // Used for public and whitelist mints
    uint constant public maxTxMintAmount = 7;

    address constant signer = 0x6a6b0c3D0c9123777eA2bF2e6344071a18da3c42;

    // Storage Variables

    uint public FreeMintSupplyMinted = 0;

    string public baseURI;

    bool public isFreeMintActive;

    /*
     * Values go in the order they are defined in the Enum
     * 0: CLOSED
     * 1: PRESALE_DAY_1
     * 2: PRESALE_DAY_2
     * 3: PUBLIC
     */
    SaleDay public saleDay;


    constructor(string memory _theBaseURI, address[] memory payees, uint[] memory shares)
        Ownable()
        ERC721A(unicode"MendelEx∞dus", "MNDLXODUS")
        PaymentSplitter(payees, shares)
    {
        baseURI = _theBaseURI;
    }

    // Minting

    function freeMint(address to, uint32 amountToMint, uint maxMintsFree, uint8 v, bytes32 r, bytes32 s) external directOnly {
        require(isFreeMintActive, "Free mint is not active");

        // Mint amount limits
        require(amountToMint > 0 && _addToMintFree(msg.sender, amountToMint) <= maxMintsFree, "Sorry, invalid amount");
        require((FreeMintSupplyMinted += amountToMint) <= FreeMintMaxSupply, "Sorry, not enough NFTs remaining to mint");

        // Signature verification
        require(_verifySignature(keccak256(abi.encodePacked("free", msg.sender, maxMintsFree)), v, r, s), "Invalid sig");

        // Split mints in batches of `maxTxMintAmount` to avoid having large gas-consuming loops when transfering or selling tokens
        uint mintedSoFar = 0;
        do {
            uint batchAmount = min(amountToMint - mintedSoFar, maxTxMintAmount);
            mintedSoFar += batchAmount;
            _mint(to, batchAmount);
        } while(mintedSoFar < amountToMint);
    }

    function presaleMint(uint32 amountToMint, uint maxAmountDay1, uint maxAmountDay2, uint8 v, bytes32 r, bytes32 s) external payable directOnly {
        require(saleDay == SaleDay.PRESALE_DAY_1 || saleDay == SaleDay.PRESALE_DAY_2, "Sorry, presale is not active");

        // Mint amount limits
        require(_totalMinted() + amountToMint <= publicMaxSupply + FreeMintSupplyMinted, "Sorry, not enough NFTs remaining to mint");

        if(saleDay == SaleDay.PRESALE_DAY_1) {
            require(_addToMintDay1(msg.sender, amountToMint) <= maxAmountDay1, "Sorry, can't mint that many");
        } else { // saleDay == SaleDay.PRESALE_DAY_2
            require(_addToMintDay2(msg.sender, amountToMint) <= maxAmountDay2, "Sorry, can't mint that many");
        }

        // Signature verification
        require(_verifySignature(keccak256(abi.encodePacked("presale", msg.sender, maxAmountDay1, maxAmountDay2)), v, r, s), "Invalid sig");

        // ETH sent verification
        require(msg.value >= cost * amountToMint);

        // Split mints in batches of `maxTxMintAmount` to avoid having large gas-consuming loops when transfering or selling tokens
        uint mintedSoFar = 0;
        do {
            uint batchAmount = min(amountToMint - mintedSoFar, maxTxMintAmount);
            mintedSoFar += batchAmount;
            _mint(msg.sender, batchAmount);
        } while(mintedSoFar < amountToMint);
    }

    function publicMint(uint amountToMint) external payable directOnly {
        require(saleDay == SaleDay.PUBLIC, "Sorry, public sale is not active");

        // Mint amount limits
        require(_totalMinted() + amountToMint <= publicMaxSupply + FreeMintSupplyMinted, "Sorry, not enough NFTs remaining to mint");
        require(amountToMint > 0 && amountToMint <= maxTxMintAmount, "Sorry, invalid mint amount");

        // ETH sent verification
        require(msg.value >= cost * amountToMint);

        _mint(msg.sender, amountToMint);
    }

    // View Only

    function tokenURI(uint _nftId) public view override returns (string memory) {
        require(_exists(_nftId), "This NFT doesn't exist");

        return string(abi.encodePacked(baseURI, _nftId.toString(), ".json"));
    }

    // Only Owner Functions

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setFreeMintMaxSupply(uint _freeMintMaxSupply) external onlyOwner {
        FreeMintMaxSupply = _freeMintMaxSupply;
    }

    function setMintDay(SaleDay day) external onlyOwner {
        saleDay = day;
    }

    function toggleFreeMintStatus() external onlyOwner {
        isFreeMintActive = !isFreeMintActive;
    }

    // Internal utils

    function _verifySignature(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns(bool) {
        return hash.toEthSignedMessageHash().recover(v, r, s) == signer;
    }

    function min(uint a,uint b) internal pure returns(uint) {
        return a < b ? a : b;
    }
}