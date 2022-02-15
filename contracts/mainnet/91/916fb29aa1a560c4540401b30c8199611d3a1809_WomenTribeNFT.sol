// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract WomenTribeNFT is ERC721A, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    string private baseURI;
    string private notRevealedUri;
    string public constant baseExtension = ".json";
    uint256 private reservedMinted = 0;

    uint256 public constant WT_MINT_MAX_AMOUNT = 3;
    uint256 public constant WT_MINT_PRICE = 0.04 ether;
    uint256 public constant WT_MAX_RESERVED_COUNT = 286; // Reserving 286 tokens for the team
    uint256 public constant WT_TOTAL_SUPPLY = 10000;

    bool public isPresaleLive = false; // True only when presale is active
    bool public isPublicSaleLive = false; // Covers the period of general public sales
    bool public revealed = false;

    bytes32 private merkleRootHash;

    // Team wallet addresses
    address private constant WALLET1 =
        0x8c70A6fd46D4e11A62D3f9E81E2d33a82fa89f82;
    address private constant WALLET2 =
        0xCBc0ACAC84A25AdD42e908b6932F0678C82FbD45;
    address private constant WALLET3 =
        0x7e503EFCBFb64E8f451e88F8AB438e20a88062c3;
    address private constant WALLET4 =
        0x695Bca9eE4F78cC1049565f9FaC504fc27f02fA2;
    address private constant WALLET5 =
        0xDe3bc9E504Ca4F0E81fAbc1f37160E9ff4Bf90D2;
    address private constant WALLET_TREASURY =
        0x9A5FE78EE5B4F5A8BAFfF54854822435c68f306c;

    // -----------------------------------------------------------
    // CONSTRUCTOR
    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        bytes32 _initMerkleRootHash
    ) ERC721A("Women Tribe", "WT") {
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

        address minter = _msgSender();
        require(tx.origin == minter, "contracts are not allowed to mint");

        uint256 newMintsPerAddress = _numberMinted(msg.sender) + _mintAmount;
        require(
            newMintsPerAddress <= WT_MINT_MAX_AMOUNT,
            "cannot mint the amount requested"
        );

        require(WT_MINT_PRICE * _mintAmount <= msg.value, "insufficient funds");

        bytes32 leafHash = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRootHash, leafHash),
            "your wallet is not in the presale list"
        );

        uint256 supply = currentIndex;
        require(
            supply + _mintAmount <= WT_TOTAL_SUPPLY,
            "the collection is sold out"
        );

        _mint(msg.sender, _mintAmount, "", false);
    }

    function mintPublicSale(uint256 _mintAmount) external payable {
        require(isPublicSaleLive, "the public sale is not open yet");
        require(_mintAmount > 0, "amount to mint should be a positive number");

        address minter = _msgSender();
        require(tx.origin == minter, "contracts are not allowed to mint");

        uint256 newMintsPerAddress = _numberMinted(msg.sender) + _mintAmount;
        require(
            newMintsPerAddress <= WT_MINT_MAX_AMOUNT,
            "cannot mint the amount requested"
        );

        require(WT_MINT_PRICE * _mintAmount <= msg.value, "insufficient funds");

        uint256 supply = currentIndex;
        require(
            supply + _mintAmount <= WT_TOTAL_SUPPLY,
            "the collection is sold out"
        );

        _mint(msg.sender, _mintAmount, "", false);
    }

    // Minting reserved tokens to the treasury wallet
    function mintReserved(uint256 _mintAmount) external onlyOwner {
        require(_mintAmount > 0, "amount to mint should be a positive number");
        require(
            reservedMinted + _mintAmount <= WT_MAX_RESERVED_COUNT,
            "cannot mint the amount requested"
        );

        uint256 supply = currentIndex;
        require(
            supply + _mintAmount <= WT_TOTAL_SUPPLY,
            "the collection is sold out"
        );

        _mint(WALLET_TREASURY, _mintAmount, "", false);
    }

    // ------------------------------------------
    // ASSETS ACCESS MANAGEMENT

    function tokenURI(uint256 tokenId)
        public
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
        uint256 assetIndex = tokenId + 1;

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        assetIndex.toString(),
                        baseExtension
                    )
                )
                : "";
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