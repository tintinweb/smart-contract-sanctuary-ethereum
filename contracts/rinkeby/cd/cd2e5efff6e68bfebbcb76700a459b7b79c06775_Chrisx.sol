// SPDX-License-Identifier: MIT
// Create by 0xChrisx
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract Chrisx is Ownable, ERC721A {

    uint256 public publicMintActive = 1 ;
    uint256 public whitelistMintActive = 0 ;

    uint256 public mintPrice = 0.05 ether;
    uint256 public collectionSize_ = 10000 ;
    uint256 public maxPerAddress = 5 ;
    uint256 public amountForDev = 200 ;

    uint256 public devMinted ;

    string private baseURI = "url" ;

    struct WhitelistedUser {
        address walletAddress; 
        uint256 mintAmount;
    }

    mapping(address => WhitelistedUser) public whitelisted;  

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

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
//--------------------- END BaseURI
//--------------------- Set & Change anythings

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice ;
    }
    
    function setCollectionSize(uint256 newCollectionSize) public onlyOwner {
        collectionSize_ = newCollectionSize ;
    }

    function setMaxPerAddress(uint newMaxPerAddress) public onlyOwner {
        maxPerAddress = newMaxPerAddress ;
    }

    function setAmountForDev (uint newAmountForDev) public onlyOwner {
        amountForDev = newAmountForDev ;
    }

    //set whitelist
    function setWhitelistUser(address _walletAddress, uint256 _mintAmount) external onlyOwner {
        whitelisted[_walletAddress].walletAddress = _walletAddress;
        whitelisted[_walletAddress].mintAmount = _mintAmount;
        
    }

    //remove whitelist
    function removeWhitelistUser(address _user) external onlyOwner {
        delete whitelisted[_user];

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
    //whitelistMint
    function whitelistMint(uint256 _mintAmount)
    external
    payable
    callerIsUser
    {
        require(whitelistMintActive >= 1, "Must be active to mint");

        require(totalSupply() + _mintAmount <= collectionSize_ , "Exceeds maximum tokens available for purchase");
        require(numberMinted(msg.sender) + _mintAmount <= maxPerAddress, "can not mint this many"); // check max mint PerAddress ?

        require(whitelisted[msg.sender].mintAmount > 0, "There's no more you can mint, please wait for the public sale to mint more!");
        require(_mintAmount <= whitelisted[msg.sender].mintAmount, "You cannot mint more than that!");
        
        require(msg.value >= mintPrice * _mintAmount, "ETH amount is not sufficient");

        _safeMint(msg.sender, _mintAmount);

        whitelisted[msg.sender].mintAmount -= _mintAmount;

    }
//-------------------- END WhitelistMint
//--------------------------------------------- END Mint
//------------------------- Withdraw Money

        address private wallet1 = 0x75963B63D551Fc3723F3Ca40bc43c45201b35f33; // K.Pim
        address private wallet2 = 0x899005A4ecddcd5a880744229DA625c1b6124737; // K.Chris
        address private wallet3 = 0x542A7F54569685f357Da5B8a6106Fe3DDcDA996b; // K.Kung
        address private wallet4 = 0x75963B63D551Fc3723F3Ca40bc43c45201b35f33; // Team
        address private wallet5 = 0x899005A4ecddcd5a880744229DA625c1b6124737; // Community
        address private wallet6 = 0x542A7F54569685f357Da5B8a6106Fe3DDcDA996b; // Charity

    function withdrawMoney() public payable onlyOwner { 

        uint256 _paytoW1 = address(this).balance*25/100 ; // K.pim
        uint256 _paytoW2 = address(this).balance*15/100 ; // K.Chris
        uint256 _paytoW3 = address(this).balance*11/100 ; // K.Kung
        uint256 _paytoW4 = address(this).balance*9/100 ;  // Team
        uint256 _paytoW5 = address(this).balance*20/100 ; // Community
        uint256 _paytoW6 = address(this).balance*20/100 ; // Charity

        require(address(this).balance > 0, "No ETH left");

        require(payable(wallet1).send(_paytoW1));
        require(payable(wallet2).send(_paytoW2));
        require(payable(wallet3).send(_paytoW3));
        require(payable(wallet4).send(_paytoW4));
        require(payable(wallet5).send(_paytoW5));
        require(payable(wallet6).send(_paytoW6));

    }
//------------------------- END Withdraw Money
}