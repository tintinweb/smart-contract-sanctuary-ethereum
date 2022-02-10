// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC721B.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract WomenTribeNFT is ERC721B, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    string public baseURI;
    string public notRevealedUri;
    string public constant baseExtension = ".json";
    uint256 public reservedMinted = 0;

    uint256 public constant WT_MINT_MAX_AMOUNT = 3;
    uint256 public constant WT_MINT_PRICE = 0.04 ether;
    uint256 public constant WT_MAX_RESERVED_COUNT = 286; // Reserving 286 tokens for the team
    uint256 public constant WT_TOTAL_SUPPLY = 10000;

    bool public isPresaleLive = false; // True only when presale is active
    bool public isPublicSaleLive = false; // Covers the period of general public sales
    bool public revealed = false;

    // TODO: great a setter for this
    bytes32 public merkleRootHash;

    // Team wallet addresses
    // TODO: replace with real wallet address
    address private constant WALLET1 =
        0x6bD846d657Ab0b2CB060793726A9C612aCE870bB;
    address private constant WALLET2 =
        0xcEC4Fdd5580Db0cBe58d6177438F0A1D8E4Eb9E8;
    address private constant WALLET3 =
        0xe8390F4424D60685691CF23b2bCAffbbda9652Ec;
    address private constant WALLET4 =
        0x440b3b53431C336AEBEbBADa0DCfe3EB68491849;
    address private constant WALLET5 =
        0x1255543C09a9eE1CA7c7bd31f54081B3a6CAc3E4;
    address private constant WALLET_TREASURY =
        0x74C4aEF5810e16e508582E8AFcE0368347EB7db6;

    // -----------------------------------------------------------
    // CONSTRUCTOR
    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        bytes32 _initMerkleRootHash
    ) ERC721B("Women Tribe", "WT") {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        setMerkleRootHash(_initMerkleRootHash);
    }

    // ------------------------------------------
    // MINTING
    function mintPresale(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
    {
        require(isPresaleLive, "the presale is not open yet");
        require(_mintAmount > 0, "amount to mint should be a positive number");

        require(
            balanceOf(msg.sender) + _mintAmount <= WT_MINT_MAX_AMOUNT,
            "cannot mint the amount requested"
        );

        require(WT_MINT_PRICE * _mintAmount <= msg.value, "insufficient funds");

        bytes32 leafHash = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRootHash, leafHash),
            "your wallet is not in the presale list"
        );

        uint256 supply = _owners.length;
        require(
            supply + _mintAmount <= WT_TOTAL_SUPPLY,
            "max sale supply reached"
        );

        for (uint256 i = 0; i < _mintAmount; i++) {
            _mint(msg.sender, supply++);
        }
    }

    function mintPublicSale(uint256 _mintAmount) external payable {
        require(isPublicSaleLive, "the public sale is not open yet");
        require(_mintAmount > 0, "ammount to mint should be a positive number");
        require(
            balanceOf(msg.sender) + _mintAmount <= WT_MINT_MAX_AMOUNT,
            "cannot mint the amount requested"
        );
        require(WT_MINT_PRICE * _mintAmount <= msg.value, "insufficient funds");

        uint256 supply = _owners.length;
        require(
            supply + _mintAmount <= WT_TOTAL_SUPPLY,
            "max sale supply reached"
        );

        for (uint256 i = 0; i < _mintAmount; i++) {
            _mint(msg.sender, supply++);
        }
    }

    // Minting reserved tokens to the treasury wallet
    function mintReserved(uint256 _mintAmount) external onlyOwner {
        require(_mintAmount > 0, "ammount to mint should be a positive number");
        require(
            reservedMinted + _mintAmount <= WT_MAX_RESERVED_COUNT,
            "cannot mint the amount requested"
        );

        uint256 supply = _owners.length;
        require(
            supply + _mintAmount <= WT_TOTAL_SUPPLY,
            "max sale supply reached"
        );

        for (uint256 i = 0; i < _mintAmount; i++) {
            _mint(WALLET_TREASURY, supply++);
            reservedMinted++;
        }
    }

    // ------------------------------------------
    // ASSETS ACCESS MANAGEMENT

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function currentSupply() external view onlyOwner returns (uint256) {
        return _owners.length;
    }

    // -----------------------------------------------------------
    // HELPERS
    function cost(uint256 _count) public pure returns (uint256) {
        return WT_MINT_PRICE * _count;
    }

    // -----------------------------------------------------------
    // LAUNCH COTROLS
    function reveal(bool _state) external onlyOwner {
        revealed = _state;
    }

    function setPresaleStatus(bool _state) external onlyOwner {
        isPresaleLive = _state;
    }

    function setPublicSaleStatus(bool _state) external onlyOwner {
        isPublicSaleLive = _state;
    }

    // -----------------------------------------------------------
    // SETTERS

    function setMerkleRootHash(bytes32 _rootHash) public onlyOwner {
        merkleRootHash = _rootHash;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    // -----------------------------------------------------------
    // ADMINISTRATION
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No assets to withdraw");

        // TODO: Replace with real percetages
        uint256 withdrawal1 = balance.mul(60).div(100);
        uint256 withdrawal2 = balance.mul(5).div(100);
        uint256 withdrawal3 = balance.mul(10).div(100);
        uint256 withdrawal4 = balance.mul(5).div(100);
        uint256 withdrawal5 = balance.mul(3).div(100);

        _withdraw(WALLET1, withdrawal1);
        _withdraw(WALLET2, withdrawal2);
        _withdraw(WALLET3, withdrawal3);
        _withdraw(WALLET4, withdrawal4);
        _withdraw(WALLET5, withdrawal5);

        // Send the rest to the team vault
        _withdraw(WALLET_TREASURY, address(this).balance);
    }

    function contractBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function _withdraw(address _address, uint256 _amount) private {
        payable(_address).transfer(_amount);
    }

    function reservedCount() external view onlyOwner returns (uint256) {
        return reservedMinted;
    }
}