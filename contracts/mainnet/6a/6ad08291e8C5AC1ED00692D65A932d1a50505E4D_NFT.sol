// SPDX-License-Identifier: MIT
// Create by 0xChrisx
// 0xChrisx Version : NEW ERC721A 4.x + MerkleProof + Burn + Queryable

//* LISA 2
/*
    * Max 10 Per Wallet

    * GoldPass
    * Free 3
    * Additional 0.0033
    == Free 3 , mint 4 (Free 3), mint 5(Free 3), -- mint 10(Free 3)

    * Whitelist
    * Free 1
    * Additional 0.0033
    == Free 1 , mint 2 (Free 1), mint 2(Free 1), -- mint 10(Free 1)

    * Public
    * 0.0055 per 1 NFT
    == mint 1, mint 2 , -- mint 10

*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";

contract NFT is Ownable, ERC721A, ReentrancyGuard, ERC721AQueryable, ERC721ABurnable {

    event Received(address, uint);

    uint256 public collectionSize_ = 10000 ;

    uint256 public maxPerWallet = 10;

    uint256 public GoldPassFree = 3 ;
    uint256 public WhitelistFree = 1 ;

    uint256 public wlPrice = 0.0033 ether ;
    uint256 public publicPrice = 0.0055 ether ;

    bytes32 public WLroot ;
    bytes32 public GProot ;

    string private baseURI ;

    struct AddressDetail {
        uint256 BurnBalance ;  // data 0 
        uint256 BurnBalanceUsed ; // data 1
        uint256 GPBalance ; // Phase 1 // data 2  
        uint256 WLBalance ; // Phase 3 // data 3 
        uint256 PBBalance ; // Phase 5 // data 4
        uint256 WalletBalance ; // data 5

    }

    mapping(address => AddressDetail) public _addressDetail ;


    constructor() ERC721A("LISA EVO-X", "LISA") {
        
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
    
    function setCollectionSize (uint256 newCollectionSize) public onlyOwner {
        collectionSize_ = newCollectionSize ;
    }

    function setWLRoot (bytes32 newWLRoot) public onlyOwner {
        WLroot = newWLRoot ;
    }

    function setGPRoot (bytes32 newGPRoot) public onlyOwner {
        GProot = newGPRoot ;
    }

    function setWLMintPrice (uint256 newWlPrice) public onlyOwner {
        wlPrice = newWlPrice ;
    }

    function setPBMintPrice (uint256 newPublicPrice) public onlyOwner {
        publicPrice = newPublicPrice ;
    }

//--------------------- END Set & Change anythings
//--------------------------------------- Mint //////////////
//-------------------- DevMint
    function devMint(address _to ,uint256 _mintAmount) external onlyOwner {

        require(totalSupply() + _mintAmount <= collectionSize_ , "You can't mint more than collection size");

        _safeMint( _to,_mintAmount);
    }
//-------------------- END DevMint
//-------------------- GoldpassMint

    function mintGoldpass(uint256 _mintAmount , bytes32[] memory _Proof) external payable {

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_Proof, GProot, leaf),
            "You're not GoldPass Holder"
        );

        require(totalSupply() + _mintAmount <= collectionSize_, "Purchase would exceed max tokens");
        
        require(_addressDetail[msg.sender].WalletBalance + _mintAmount <= maxPerWallet, "reached max per wallet."); // Can't mint more than maxPerWallet

        // จำนวนที่มิ้นไปแล้ว < มีน้อยกว่า < จำนวนที่ฟรี = แสดงว่า เหลือสิทธ์ฟรี
        if (_addressDetail[msg.sender].GPBalance < GoldPassFree ) {

            // สิทธ์ที่ฟรี เหลือเท่าไหร่
            uint256 freeRight = GoldPassFree - _addressDetail[msg.sender].GPBalance ;

            uint256 paidAmount ;
            // if - จำนวนที่จะมิ้น <= น้อยกว่า หรือเท่ากับ <= จำนวนที่ฟรี --> ให้มิ้นได้เลย
            if(_mintAmount <= freeRight) {

                paidAmount = 0 ;

            }
            // else -  จำนวนมิ้น > มากกว่า > จำนวนที่ฟรี --> ให้หาจำนวนที่ไม่ฟรี แล้วจ่าย
            else {

                paidAmount = _mintAmount - freeRight ;
            
            }


            require(wlPrice * paidAmount <= msg.value, "Ether value sent is not correct"); // จ่ายเท่าที่ต้องจ่าย

            _safeMint(msg.sender, _mintAmount); // มิ้นเท่าจำนวนที่จะมิ้น
            _addressDetail[msg.sender].GPBalance += _mintAmount ;
            _addressDetail[msg.sender].WalletBalance += _mintAmount ;

        }
        // นอกจากนั้น คือ ถ้าไม่เหลือสิทธิ์ฟรี ||  จำนวนที่มิ้นไปแล้ว >= มีมากกว่ากว่า หรือ เท่ากับ >= จำนวนที่ฟรี = แสดงว่า ไม่เหลือสิทธ์ฟรี
        else {

            require(wlPrice * _mintAmount <= msg.value, "Ether value sent is not correct"); // จ่ายเท่าที่ต้องจ่าย
        
            _safeMint(msg.sender, _mintAmount); // มิ้นเท่าจำนวนที่จะมิ้น
            _addressDetail[msg.sender].GPBalance += _mintAmount ;
            _addressDetail[msg.sender].WalletBalance += _mintAmount ;

        }


    }

    function isValidGP(bytes32[] memory proof, address wallet) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(wallet));
        return MerkleProof.verify(proof, GProot, leaf);

    }

//-------------------- END GoldpassMint
//-------------------- WhitelistMint

    function mintWhiteList(uint256 _mintAmount , bytes32[] memory _Proof) external payable {

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_Proof, WLroot, leaf),
            "You're not whitelist."
        );
        
        require(totalSupply() + _mintAmount <= collectionSize_, "Purchase would exceed max tokens");

        require(_addressDetail[msg.sender].WalletBalance + _mintAmount <= maxPerWallet, "reached max per wallet."); // Can't mint more than maxPerWallet

            // จำนวนที่มิ้นไปแล้ว < มีน้อยกว่า < จำนวนที่ฟรี = แสดงว่า เหลือสิทธ์ฟรี
            if (_addressDetail[msg.sender].WLBalance < WhitelistFree ) {
                
                uint256 paidAmount ;

                // สิทธ์ที่ฟรี เหลือเท่าไหร่
                uint256 freeRight = WhitelistFree - _addressDetail[msg.sender].WLBalance ;

                // if - จำนวนที่จะมิ้น <= น้อยกว่า หรือเท่ากับ <= จำนวนที่ฟรี --> ให้มิ้นได้เลย
                if(_mintAmount <= freeRight) {

                    paidAmount = 0 ;

                }
                // else -  จำนวนมิ้น > มากกว่า > จำนวนที่ฟรี --> ให้หาจำนวนที่ไม่ฟรี แล้วจ่าย
                else {

                    paidAmount = _mintAmount - freeRight ;
                
                }

                require(wlPrice * paidAmount <= msg.value, "Ether value sent is not correct"); // จ่ายเท่าที่ต้องจ่าย

                _safeMint(msg.sender, _mintAmount); // มิ้นเท่าจำนวนที่จะมิ้น
                _addressDetail[msg.sender].WLBalance += _mintAmount ;
                _addressDetail[msg.sender].WalletBalance += _mintAmount ;

            }
            // นอกจากนั้น คือ ถ้าไม่เหลือสิทธิ์ฟรี || จำนวนที่มิ้นไปแล้ว >= มีมากกว่ากว่า หรือ เท่ากับ >= จำนวนที่ฟรี = แสดงว่า ไม่เหลือสิทธ์ฟรี
            else {

                require(wlPrice * _mintAmount <= msg.value, "Ether value sent is not correct"); // จ่ายเท่าที่ต้องจ่าย
            
                _safeMint(msg.sender, _mintAmount); // มิ้นเท่าจำนวนที่จะมิ้น
                _addressDetail[msg.sender].WLBalance += _mintAmount ;
                _addressDetail[msg.sender].WalletBalance += _mintAmount ;


            }


    }

    function isValidWL(bytes32[] memory proof, address wallet) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(wallet));
        return MerkleProof.verify(proof, WLroot, leaf);

    }

//-------------------- END WhitelistMint
//-------------------- PublicMint
    function publicMint(uint256 _mintAmount) external payable callerIsUser {

        require(totalSupply() + _mintAmount <= collectionSize_  , "reached max supply"); // must less than collction size
        
        require(_addressDetail[msg.sender].WalletBalance + _mintAmount <= maxPerWallet, "reached max per wallet."); // Can't mint more than maxPerWallet
        
        require(msg.value >= publicPrice * _mintAmount, "ETH amount is not sufficient");

        _safeMint(msg.sender, _mintAmount);
        _addressDetail[msg.sender].PBBalance += _mintAmount ;
        _addressDetail[msg.sender].WalletBalance += _mintAmount ;
    }

    function numberMinted(address owner) public view returns (uint256) { // check number Minted of that address จำนวนที่มิ้นไปแล้ว ใน address นั้น
        return _numberMinted(owner);
    }
//-------------------- END PublicMint
//--------------------------------------------- END Mint //////////////
//------------------------- Withdraw Money

        address private wallet1 = 0x7884A13d537D281568Ad7e9b9821b745eB8f1EDa; // K.Fulls
        address private wallet2 = 0x4B0A54D5529D34352048022a6e67BB6a26d91A7A; // K.Kayy
        address private wallet3 = 0x977EE6f3C17ECB90Ac5504ad92240D40a33ba129; // K.Chris
        address private wallet4 = 0x5350303b367FeA34bFb85Fd0da683eA9D8Ebd550; // VAULT

    function withdrawMoney() external payable nonReentrant { 

        uint256 _paytoW1 = address(this).balance*20/100 ; // K.Fulls
        uint256 _paytoW2 = address(this).balance*20/100 ; // K.Kayy
        uint256 _paytoW3 = address(this).balance*20/100 ; // K.Chris
        uint256 _paytoW4 = address(this).balance*40/100 ; // VAULT

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