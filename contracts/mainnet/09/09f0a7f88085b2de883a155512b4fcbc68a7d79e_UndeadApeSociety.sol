// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract UndeadApeSociety is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    string baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 60000000000000000; // 0.06 eth
    uint256 public maxSupply = 6666; //setter to be change
    uint256 public maxMintAmount = 30; //max mint amount
    bool public paused = true;
    bool public revealed;
    bool public whitelistEnabled = true;
    string public notRevealedUri;
    address public withdrawalAccountOne =
        0x518cc602D0C0951D4AF8A7dc22C5B3fa8353E436; //founder
    address public withdrawalAccountTwo =
        0x5792b1026e98bbf32fABC6C97dAE53Cc5fC26957; //withdrawer with owner

    bytes32 public merkleRoot =
        0xb36927fe3be17449e5c2895e2f5a1c2b468156a3480e211ee66b3b34ae46342a; //will be change as we change whitelist

    mapping(address => bool) public approvalMap;

    address public founder = 0x518cc602D0C0951D4AF8A7dc22C5B3fa8353E436; //57%
    address public communityWallet = 0x509AEFfe3A4Ae8eD8D2bcfB31382b5Aee63d5f8c; //Community Wallet 10%
    address public partnerA = 0x5792b1026e98bbf32fABC6C97dAE53Cc5fC26957; //Partner10A 10%
    address public partnerB = 0xD1d48370ddE640a9e58728c235364612352F58a1; //Partner10B 10%
    address public partnerC = 0x23c9B8896A13194B2B97848B6299Ab997D2D38ba; //Partner10C 10%
    address public partnerD = 0x8Adf8482C0B7F2676405240060F668AC9aFe7d9C; //Partner10D 3%

    modifier withdrawers() {
        require(
            msg.sender == withdrawalAccountOne ||
                msg.sender == withdrawalAccountTwo
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    // Minting for whitelist and public
    function mint(bytes32[] calldata _merkleProof, uint256 _mintAmount)
        public
        payable
    {
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0, "Quantity cannot be zero");
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);
        require(msg.value >= cost * _mintAmount);

        if (whitelistEnabled == true) {
            //verify the provided _merkleProof given to us through the API call on our website
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(
                MerkleProof.verify(_merkleProof, merkleRoot, leaf),
                "Invalid Proof!!"
            );
            _safeMint(msg.sender, _mintAmount);
        } else {
            _safeMint(msg.sender, _mintAmount);
        }
    }

    // Minting for ownerOnly
    function reserveMint(uint256 _mintAmount) public payable onlyOwner {
        uint256 supply = totalSupply();
        require(_mintAmount > 0);
        require(supply + _mintAmount <= maxSupply);
        _safeMint(msg.sender, _mintAmount);
    }

    // Reserve for community and send to community wallet
    function reserveForCommunity(uint256 _mintAmount) public payable onlyOwner {
        uint256 supply = totalSupply();
        require(_mintAmount > 0);
        require(supply + _mintAmount <= maxSupply);
        _safeMint(communityWallet, _mintAmount);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //Returns URI of the particular token
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

        if (!revealed) {
            return notRevealedUri;
        }
        string memory currentBaseURI = _baseURI();
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

    //only owner
    function reveal(bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    function setWithdrawalAccountOne(address _withdrawalAccountOne)
        public
        onlyOwner
    {
        withdrawalAccountOne = _withdrawalAccountOne;
    }

    function setWithdrawalAccountTwo(address _withdrawalAccountTwo)
        public
        onlyOwner
    {
        withdrawalAccountTwo = _withdrawalAccountTwo;
    }

    function setFounderAddress(address _founder) public onlyOwner {
        founder = _founder;
    }

    function setCommunityWallet(address _comWallet) public onlyOwner {
        communityWallet = _comWallet;
    }

    function setPartnerA(address _partnerA) public onlyOwner {
        partnerA = _partnerA;
    }

    function setPartnerB(address _partnerB) public onlyOwner {
        partnerB = _partnerB;
    }

    function setPartnerC(address _partnerC) public onlyOwner {
        partnerC = _partnerC;
    }

    function setPartnerD(address _partnerD) public onlyOwner {
        partnerD = _partnerD;
    }

    function setwhitelistEnabled(bool _whitelistEnabled) public onlyOwner {
        whitelistEnabled = _whitelistEnabled;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function sendGifts(address[] memory _wallets) public onlyOwner {
        uint256 supply = totalSupply();
        require(
            supply + _wallets.length <= maxSupply,
            "not enough tokens left"
        );
        for (uint256 i = 0; i < _wallets.length; i++) {
            _safeMint(_wallets[i], 1);
        }
    }

    function approveTransaction(bool _approvalOn) public withdrawers {
        approvalMap[msg.sender] = _approvalOn;
    }

    function withdraw() public payable withdrawers {
        require(
            approvalMap[withdrawalAccountOne],
            "First owner did not approve"
        );
        require(
            approvalMap[withdrawalAccountTwo],
            "Second owner did not approve"
        );
        uint256 hundredPercent = address(this).balance;
        uint256 fiftysevenPercent = (hundredPercent * 57) / 100;
        uint256 tenPercent = (hundredPercent * 10) / 100;
        uint256 threePercent = (hundredPercent * 3) / 100;
        payable(founder).transfer(fiftysevenPercent);
        payable(communityWallet).transfer(tenPercent);
        payable(partnerA).transfer(tenPercent);
        payable(partnerB).transfer(tenPercent);
        payable(partnerC).transfer(tenPercent);
        payable(partnerD).transfer(threePercent);
        approvalMap[withdrawalAccountOne] = false;
        approvalMap[withdrawalAccountTwo] = false;
    }
}