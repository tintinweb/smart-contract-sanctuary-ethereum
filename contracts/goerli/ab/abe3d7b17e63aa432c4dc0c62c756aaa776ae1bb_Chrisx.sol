// SPDX-License-Identifier: MIT
// Create by 0xChrisx - v.0.8.0

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./MerkleProof.sol";


contract Chrisx is Ownable, ERC721A, ReentrancyGuard {

    event Received(address, uint);

    uint256 public publicMintActive = 0 ;
    uint256 public whitelistMintActive = 1 ;

    uint256 public mintPrice = 0.001 ether;
    uint256 public collectionSize_ = 3333 ;
    uint256 public maxPerAddress = 10;
    uint256 public amountForDev = 200 ;

    uint256 public maxPerWhitelist = 5;

    uint256 public devMinted ;

    bytes32 public root = 0 ;

    string private baseURI = "url" ;

    constructor() ERC721A("Chirsx", "CX", maxPerAddress , collectionSize_ ) {

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

    function setMaxPerAddress (uint newMaxPerAddress) public onlyOwner {
        maxPerAddress = newMaxPerAddress ;
    }

    function setAmountForDev (uint newAmountForDev) public onlyOwner {
        amountForDev = newAmountForDev ;
    }

    function setMaxPerWhitelist (uint newMaxPerWhitelist ) public onlyOwner {
        maxPerWhitelist = newMaxPerWhitelist;
    }

    function setRoot (bytes32 newRoot) public onlyOwner {
        root = newRoot ;
    }

//--------------------- END Set & Change anythings
//--------------------- MintStatusActive
    function toggleWhitelistMintActive() public onlyOwner {
        if(whitelistMintActive == 0) {
            whitelistMintActive = 1;
        } else {
            whitelistMintActive = 0;
        }

    }

    function togglePublicMintActive() public onlyOwner {
        
        if(publicMintActive == 0) {
            publicMintActive = 1;
        } else {
            publicMintActive = 0;
        }
    }

    function pauseAllMint() public onlyOwner {
        // pause everything
        whitelistMintActive = 0; 
        publicMintActive = 0;
    }

    function toggleBetweenWhitelistAndPublicActive() public onlyOwner {
        // pre and public will always be oppsite
        if(whitelistMintActive >= 1) {
            whitelistMintActive = 0;
            publicMintActive = 1;
        } else {
            publicMintActive = 0;
            whitelistMintActive = 1;
        }

    }

//--------------------- END MintStatusActive
//--------------------------------------- Mint
//-------------------- PublicMint
    function publicMint(uint _mintAmount) external payable callerIsUser {

        require(publicMintActive >= 1, "public sale has not begun yet");
        require(totalSupply() + _mintAmount <= collectionSize_  , "reached max supply"); // must less than collction size
        require(numberMinted(msg.sender) + _mintAmount <= maxPerAddress, "can not mint this many"); // check max mint PerAddress ?
        require(msg.value >= mintPrice * _mintAmount, "ETH amount is not sufficient");

        _safeMint(msg.sender, _mintAmount);
    }

    function numberMinted(address owner) public view returns (uint256) { // check number Minted of that address จำนวนที่มิ้นไปแล้ว ใน address นั้น
        return _numberMinted(owner);
    }
//-------------------- END PublicMint
//-------------------- DevMint
    function devMint(address _to ,uint _mintAmount) external onlyOwner {

        require(totalSupply() + _mintAmount <= collectionSize_ , "You can't mint more than collection size");
        require(_mintAmount + devMinted <= amountForDev , "You can't mint more than amountForDev");

        _safeMint( _to,_mintAmount);
        devMinted += _mintAmount ;
    }
//-------------------- END DevMint
//-------------------- WhitelistMint

    function mintWhiteList(uint8 _mintAmount , bytes32[] memory _Proof) external payable {
        require(whitelistMintActive >= 1, "Whitelist status, must be active to mint");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_Proof, root, leaf), "You are not whitelist.");

        require(totalSupply() + _mintAmount <= collectionSize_, "Purchase would exceed max tokens");
        
        require(numberMinted(msg.sender) + _mintAmount <= maxPerWhitelist, "It's max per address for whitelist. Please try lower amount to mint");

        require(numberMinted(msg.sender) + _mintAmount <= maxPerAddress, "It's max per address , Please try lower amount to mint"); 

        require(mintPrice * _mintAmount <= msg.value, "Ether value sent is not correct");


        _safeMint(msg.sender, _mintAmount);

    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        
        return MerkleProof.verify(proof, root, leaf);
    }

//-------------------- END WhitelistMint
//--------------------------------------------- END Mint
//------------------------- Withdraw Money

        address private wallet1 = 0x542A7F54569685f357Da5B8a6106Fe3DDcDA996b; // K.Chris
        address private wallet2 = 0x542A7F54569685f357Da5B8a6106Fe3DDcDA996b; // K.Chris

    function withdrawMoney() external payable nonReentrant { 

        uint256 _paytoW1 = address(this).balance*50/100 ; // K.Chris
        uint256 _paytoW2 = address(this).balance*50/100 ; // K.Chris


        require(address(this).balance > 0, "No ETH left");

        require(payable(wallet1).send(_paytoW1));
        require(payable(wallet2).send(_paytoW2));

    }
//------------------------- END Withdraw Money

//-------------------- START Fallback Receive Ether Function
    receive() external payable {
            emit Received(msg.sender, msg.value);
    }
//-------------------- END Fallback Receive Ether Function

}