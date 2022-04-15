// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./ERC721A.sol";

//    _/        _/_/_/_/    _/_/_/  _/_/_/_/  _/      _/  _/_/_/    _/      _/
//   _/        _/        _/        _/        _/_/    _/  _/    _/    _/  _/   
//  _/        _/_/_/    _/  _/_/  _/_/_/    _/  _/  _/  _/    _/      _/      
// _/        _/        _/    _/  _/        _/    _/_/  _/    _/    _/  _/     
//_/_/_/_/  _/_/_/_/    _/_/_/  _/_/_/_/  _/      _/  _/_/_/    _/      _/ 
//Developed by RosieX - @RosieX_eth

contract LegendX is Ownable, ERC721A, PaymentSplitter {
    constructor() ERC721A("Legend-X", "LEGENDX") PaymentSplitter(_splitterAddressList, _shareList) {}

    struct SaleConfig {
        uint32 collectionSize;
        uint32 claimSize;
        uint32 allowlistStartTime;
        uint32 allowlistEndTime;
        uint32 publicStartTime;
        uint32 publicEndTime;
        uint32 claimlistStartTime;
        uint32 claimlistEndTime;
    }

    struct PurchaseConfig {
        uint64 maxPublicTxn;
        uint64 maxAllowlistTxn;
        uint64 allowlistMaxBalance;
        uint64 price;
    }

    SaleConfig public saleConfig = SaleConfig(
        10000,
        4200,
        1650060000,
        1650103200,
        1650103200,
        1650146400,
        1650146400,
        1650362400
    );

    PurchaseConfig public purchaseConfig = PurchaseConfig(
        4,
        2,
        2,
        0.088 ether
    );

    address[] private _splitterAddressList = [
        0x693065F2e132E9A8B70AA4D43120EAef7f8f2685, 
        0x8627912B6ec8bD7A204Ea46026E11efBB290df3b, 
        0xdf1fa21aaD71C50E642FcA3Aa4332da17BbEA409, 
        0x0F8aAC3F77668f6053cFF816713EE891F8B4B161 
    ];

    uint256[] private _shareList = [25, 25, 25, 25];


    string private _baseTokenURI;
    bool public isPaused = true;

    bytes32 public allowlistMerkleRoot;
    mapping(address => uint256) public allowlistBalance;

    bytes32 public claimlistMerkleRoot;
    mapping(address => bool) public claimlistClaimed;

    modifier isAllowlistOpen
    {
        require(block.timestamp > uint256(saleConfig.allowlistStartTime) && block.timestamp < uint256(saleConfig.allowlistEndTime), "Window is closed!");
        _;
    }

    modifier isClaimOpen
    {
        require(block.timestamp > uint256(saleConfig.claimlistStartTime) && block.timestamp < uint256(saleConfig.claimlistEndTime), "Window is closed!");
        _;
    }

    modifier isPublicOpen
    {
        require(block.timestamp > uint256(saleConfig.publicStartTime) && block.timestamp < uint256(saleConfig.publicEndTime), "Window is closed!");
        _;
    }


    modifier callerIsUser 
    {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier isValidMint(uint256 mintAmount) 
    {
        uint256 price = uint256(purchaseConfig.price);
        uint256 collectionSize = uint256(saleConfig.collectionSize);
        uint256 claimSize = uint256(saleConfig.claimSize);
        require(mintAmount > 0, "Mint Amount Incorrect");
        require(msg.value >= price * mintAmount, "Incorrect payment amount!");
        require(totalSupply() + mintAmount < collectionSize - claimSize + 1, "Reached max supply");
        require(!isPaused, "Mint paused");
        _;
    }

    // PUBLIC AND EXTERNAL FUNCTIONS

    function publicSaleMint(uint256 mintAmount)
        public
        payable
        callerIsUser
        isPublicOpen
        isValidMint(mintAmount)
    {
        
        uint256 maxPublicTxn = uint256(purchaseConfig.maxPublicTxn);
        require(mintAmount < maxPublicTxn + 1, "Mint Amount Incorrect");
        _safeMint(msg.sender, mintAmount);
    }

    function allowlistMint(uint256 mintAmount, bytes32[] calldata _merkleProof) 
        external 
        payable 
        callerIsUser 
        isAllowlistOpen
        isValidMint(mintAmount)
    {
        uint256 allowlistMaxBalance = uint256(purchaseConfig.allowlistMaxBalance);
        uint256 maxAllowlistTxn = uint256(purchaseConfig.maxAllowlistTxn);
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, allowlistMerkleRoot, leaf), "Proof not on allowlist!");
        require(mintAmount < maxAllowlistTxn + 1, "Mint Amount Incorrect");
        require(allowlistBalance[msg.sender] + mintAmount < allowlistMaxBalance + 1, "Exceeds max mint amount!");

        allowlistBalance[msg.sender] += mintAmount;
        _safeMint(msg.sender, mintAmount);
    }

    function claimMint(uint256 allowance, bytes32[] calldata _merkleProof) 
        external 
        payable 
        callerIsUser 
        isClaimOpen
    {
        uint256 collectionSize = uint256(saleConfig.collectionSize);
        bytes32 leaf = keccak256(abi.encode(msg.sender,Strings.toString(allowance)));
        require(MerkleProof.verify(_merkleProof, claimlistMerkleRoot, leaf), "Proof not on allowlist!");
        require(totalSupply() + allowance < collectionSize + 1, "Reached max supply");
        require(!claimlistClaimed[msg.sender], "Already claimed!");
        require(!isPaused, "Mint paused");

        claimlistClaimed[msg.sender] = true;
        _safeMint(msg.sender, allowance);
    }

    // VIEW FUNCTIONS

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // ADMIN FUNCTIONS

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function devMint(address[] memory addresses, uint256[] memory numMints)
        external
        onlyOwner
    {
        uint256 collectionSize = uint256(saleConfig.collectionSize);
        require(addresses.length == numMints.length, "Arrays dont match");

        for (uint i = 0; i < addresses.length; i++) {
            require(totalSupply() + numMints[i] < collectionSize + 1, "Reached max supply");
            require(numMints[i] > 0, "Cannot mint 0!");

            _safeMint(addresses[i], numMints[i]);
        }
    }

    function setAllowlistMerkleRoot(bytes32 root) external onlyOwner {
        allowlistMerkleRoot = root;
    }

    function setClaimlistMerkleRoot(bytes32 root) external onlyOwner {
        claimlistMerkleRoot = root;
    }

    function setMaxSupply(uint32 size, uint32 claimSize) external onlyOwner {
        saleConfig.collectionSize = size;
        saleConfig.claimSize = claimSize;
    }

    function setPaused(bool paused) external onlyOwner {
        isPaused = paused;
    }

    function setAllowlistSaleTime(uint32 startTimestamp, uint32 endTimestamp) external onlyOwner {
        saleConfig.allowlistStartTime = startTimestamp;
        saleConfig.allowlistEndTime = endTimestamp;
    }

    function setClaimlistSaleTime(uint32 startTimestamp, uint32 endTimestamp) external onlyOwner {
        saleConfig.claimlistStartTime = startTimestamp;
        saleConfig.claimlistEndTime = endTimestamp;
    }

    function setPublicSaleTime(uint32 startTimestamp, uint32 endTimestamp) external onlyOwner {
        saleConfig.publicStartTime = startTimestamp;
        saleConfig.publicEndTime = endTimestamp;
    }
}