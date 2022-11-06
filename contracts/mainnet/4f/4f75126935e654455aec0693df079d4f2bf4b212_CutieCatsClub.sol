// SPDX-License-Identifier: MIT
// Create by 0xChrisx

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract CutieCatsClub is Ownable, ERC721A, ReentrancyGuard {

    event Received(address, uint);

    uint256 public mintPhase ;

    uint256 public mintPrice = 0 ether;

    uint256 public collectionSize_ = 999 ;
    uint256 public maxWlRound =  925 ;

    uint256 public maxPerPublic = 5;
    uint256 public maxPerWhitelist = 2;
    uint256 public maxPerAllowlist = 2;

    bytes32 public WLroot ;
    bytes32 public ALroot ;

    string private baseURI ;

    constructor() ERC721A("CutieCatsClub", "CTC", maxPerPublic , collectionSize_ ) {
        
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
    _;
    }

//------------------ BaseURI 
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI (string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

//--------------------- END BaseURI
//--------------------- Set & Change anythings

    function setMintPrice (uint256 newPrice) public onlyOwner {
        mintPrice = newPrice ;
    }
    
    function setCollectionSize (uint256 newCollectionSize) public onlyOwner {
        collectionSize_ = newCollectionSize ;
    }

    function setMaxWlRound (uint256 newMaxWlRound) public onlyOwner {
        maxWlRound = newMaxWlRound ;
    }

    function setMaxPerAddress (uint256 newMaxPerAddress) public onlyOwner {
        maxPerPublic = newMaxPerAddress ;
    }

    function setMaxPerWhitelist (uint256 newMaxPerWhitelist ) public onlyOwner {
        maxPerWhitelist = newMaxPerWhitelist;
    }

    function setMaxPerAllowlist (uint256 newMaxPerAllowlist ) public onlyOwner {
        maxPerAllowlist = newMaxPerAllowlist;
    }

    function setWLRoot (bytes32 newWLRoot) public onlyOwner {
        WLroot = newWLRoot ;
    }

    function setALRoot (bytes32 newALRoot) public onlyOwner {
        ALroot = newALRoot ;
    }

    function setPhase (uint256 newPhase) public onlyOwner {
        mintPhase = newPhase ;
    }

//--------------------- END Set & Change anythings
//--------------------------------------- Mint
//-------------------- PublicMint
    function publicMint(uint256 _mintAmount) external payable callerIsUser {

        require(mintPhase == 5, "public sale hasn't begun yet");
        require(totalSupply() + _mintAmount <= collectionSize_  , "reached max supply"); // must less than collction size
        require(numberMinted(msg.sender) + _mintAmount <= maxPerPublic, "can not mint this many"); // check max mint PerAddress ?
        require(msg.value >= mintPrice * _mintAmount, "ETH amount is not sufficient");

        _safeMint(msg.sender, _mintAmount);
    }

    function numberMinted(address owner) public view returns (uint256) { // check number Minted of that address จำนวนที่มิ้นไปแล้ว ใน address นั้น
        return _numberMinted(owner);
    }
//-------------------- END PublicMint
//-------------------- DevMint
    function devMint(address _to ,uint256 _mintAmount) external onlyOwner {

        require(totalSupply() + _mintAmount <= collectionSize_ , "You can't mint more than collection size");

        _safeMint( _to,_mintAmount);
    }
//-------------------- END DevMint
//-------------------- WhitelistMint

    function mintWhiteList(uint256 _mintAmount , bytes32[] memory _Proof) external payable {
        require(mintPhase == 1, "Whitelist round hasn't open yet");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_Proof, WLroot, leaf),
            "You're not whitelist."
        );

        require(totalSupply() + _mintAmount <= maxWlRound , "Purchase would exceed max tokens");
        
        require(numberMinted(msg.sender) + _mintAmount <= maxPerWhitelist, "Max per address for whitelist. Please try lower.");

        require(mintPrice * _mintAmount <= msg.value, "Ether value sent is not correct");

        _safeMint(msg.sender, _mintAmount);

    }

    function isValidWL(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        
        return MerkleProof.verify(proof, WLroot, leaf);

    }

//-------------------- END WhitelistMint
//-------------------- AllowlistMint

    function mintAllowList(uint256 _mintAmount , bytes32[] memory _Proof) external payable {
        require(mintPhase == 3, "Allowlist round hasn't open yet");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_Proof, ALroot, leaf),
            "You're not Allowlist"
        );

        require(totalSupply() + _mintAmount <= collectionSize_, "Purchase would exceed max tokens");
        
        require(numberMinted(msg.sender) + _mintAmount <= maxPerAllowlist, "Max per address for allowlist. Please try lower.");

        require(mintPrice * _mintAmount <= msg.value, "Ether value sent is not correct");

        _safeMint(msg.sender, _mintAmount);

    }

    function isValidAL(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        
        return MerkleProof.verify(proof, ALroot, leaf);

    }

//-------------------- END AllowlistMint
//--------------------------------------------- END Mint
//------------------------- Withdraw Money

        address private wallet1 = 0xb4Eb727F3420005955045ACE103E3B260645DEE3; // K.Pim
        address private wallet2 = 0x8D5532c04f37A60F6E60b5F28D72b4E9013F938C; // K.Chris
        address private wallet3 = 0x031633884306abAF5d5003Ca5A631Aec9Ef258AA; // K.Kung
        address private wallet4 = 0xf9265783c26866FBC183a8dEB8F891C3c1cEF16b; // VAULT

    function withdrawMoney() external payable nonReentrant { 

        uint256 _paytoW1 = address(this).balance*37/100 ; // K.pim
        uint256 _paytoW2 = address(this).balance*27/100 ; // K.Chris
        uint256 _paytoW3 = address(this).balance*27/100 ; // K.Kung
        uint256 _paytoW4 = address(this).balance*9/100 ; // VAULT

        require(address(this).balance > 0, "No ETH left");

        require(payable(wallet1).send(_paytoW1));
        require(payable(wallet2).send(_paytoW2));
        require(payable(wallet3).send(_paytoW3));
        require(payable(wallet4).send(_paytoW4));

    }
//------------------------- END Withdraw Money

//-------------------- START Fallback Receive Ether Function
    receive() external payable {
            emit Received(msg.sender, msg.value);
    }
//-------------------- END Fallback Receive Ether Function

}