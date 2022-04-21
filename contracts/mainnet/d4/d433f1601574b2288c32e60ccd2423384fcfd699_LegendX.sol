// SPDX-License-Identifier: GPL-3.0

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
        1650636000,
        1650679200,
        1650679200,
        1650754800,
        1650765600,
        1650852000
    );

    PurchaseConfig public purchaseConfig = PurchaseConfig(
        4,
        2,
        2,
        0.088 ether
    );

    address[] private _splitterAddressList = [
        0x492EFaAE6bd47AC479DA908f91ff6f15Bc395371, 
        0x471f1FFD0cAe3B116d80C7d4fe002861F8FAe36a, 
        0x3E7B68c3896b45808A0dA50B48Cb2A44D11342EF, 
        0x342b68aDe2384aE1e61A65758d2Af49138dB5224,
        0x4Cc1bF50E741Cc7e5A152bB9e5b9D5071cE9f402
    ];

    uint256[] private _shareList = [8, 10, 10, 15, 57];


    string private _baseTokenURI = "ipfs://QmPfmyyK51og3BtbThZgfdR3S4tgCEc79VDa9f6fSwugAM/";
    bool public isPaused = true;

    bytes32 public allowlistMerkleRoot;
    mapping(address => uint256) public allowlistBalance;

    bytes32 public claimlistMerkleRoot;
    mapping(address => bool) public claimlistClaimed;

    modifier isAllowlistOpen
    {
        require(block.timestamp > uint256(saleConfig.allowlistStartTime) && block.timestamp < uint256(saleConfig.allowlistEndTime), "Allowlist window is closed!");
        _;
    }

    modifier isClaimOpen
    {
        require(block.timestamp > uint256(saleConfig.claimlistStartTime) && block.timestamp < uint256(saleConfig.claimlistEndTime), "Claim window is closed!");
        _;
    }

    modifier isPublicOpen
    {
        require(block.timestamp > uint256(saleConfig.publicStartTime) && block.timestamp < uint256(saleConfig.publicEndTime), "Public window is closed!");
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
        callerIsUser 
        isClaimOpen
    {
        uint256 collectionSize = uint256(saleConfig.collectionSize);
        bytes32 leaf = keccak256(abi.encode(msg.sender,Strings.toString(allowance)));
        require(MerkleProof.verify(_merkleProof, claimlistMerkleRoot, leaf), "Proof not on claimlist!");
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