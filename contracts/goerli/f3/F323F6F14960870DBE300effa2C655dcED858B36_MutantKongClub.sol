// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";

import "./ERC721A.sol";
import "./ERC721ANamable.sol";
import "./IVamirToken.sol";


contract MutantKongClub is ERC721ANamable, Ownable {  
    using Address for address;
    using SafeMath for uint256;
    using Strings for uint128;

    // Sale Controls
    bool public presaleActive = false;
    bool public saleActive = false;
    bool public freeActive = false;

    // Mint Price
    uint256 public public_price = 0.03 ether;
    uint256 public pre_price = 0.02 ether;

    uint public MAX_SUPPLY = 10000;

    address private signer_wl;
    address private signer_free;

    mapping(address => bool) public FreeCap;
    mapping(address => uint256) public PreCap;
    mapping(address => uint256) public PublicCap;

    IVamirToken public vamirtoken;

    // Create New TokenURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }


    // Base Link That Leads To Metadata
    string public baseTokenURI;

    // Contract Construction
    constructor ( ) 
    ERC721ANamable ("Mutant Kong Club", "MKC", 10, 10000) {}
    //constructor ( ) 
    //ERC721ANamable ("TEST", "TEST", 10, 10000) {}
    // ================ Mint Functions ================ //

    // Minting Function
    function MintPublic(uint256 _amount) external payable {
        uint256 supply = totalSupply();
        require(saleActive, "PublicSale Not Activated");
        require(supply+_amount<=MAX_SUPPLY);
        require(PublicCap[msg.sender]+_amount<=10, "Exceed Max 10 mints");
        if(public_price > 0) require(msg.value >= _amount*public_price, "Not Enough ETH");
        PublicCap[msg.sender] += _amount;
        _safeMint( msg.sender, _amount);
    }

    // Presale Minting
    function MintPresale(uint256 _amount, bytes memory _signature) public payable {
        uint256 supply = totalSupply();
        address rarity = rarityCheck(msg.sender, _signature);
        require(rarity == signer_free || rarity == signer_wl,"Not Whitelisted");
        require(supply+_amount<=MAX_SUPPLY);
        if(rarity == signer_wl){
            require(presaleActive, "Presale Not Activated");
            require(PreCap[msg.sender]+_amount<=5, "Exceed Max 5 mints");
            require(msg.value >= _amount*pre_price, "Not Enough ETH");
            PreCap[msg.sender] += _amount;
            _safeMint( msg.sender, _amount);
        }else if(rarity == signer_free){
            require(freeActive, "Free Not Activated");
            require(!FreeCap[msg.sender], "Already Free Minted");
            require(_amount==1,"Only 1 Free Mint Possible");
            FreeCap[msg.sender] = true;
            _safeMint( msg.sender, _amount);
        }
        
    }



    // ================ Only Owner Functions ================ //

    // Gift Function - Collabs & Giveaways
    function gift(address _to, uint256 _amount) external onlyOwner() {
        uint256 supply = totalSupply();
        require( supply + _amount <= MAX_SUPPLY+15, "Not Enough Supply" );
        _safeMint( _to, _amount );
    }

     // Incase ETH Price Rises Rapidly
    function setPrice(uint256 newPrice) public onlyOwner() {
        public_price = newPrice;
    }

    // Set New baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    // ================ Sale Controls ================ //


    // Pre Sale On/Off
    function setPresaleActive(bool val) public onlyOwner {
        presaleActive = val;
    }


    // Public Sale On/Off
    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    // Free Sale On/Off
    function setFreeActive(bool val) public onlyOwner {
        freeActive = val;
    }

    // Vamir Token

    function setVamirToken(address _vamir) external onlyOwner {
		vamirtoken = IVamirToken(_vamir);
	}


    // Change Name

    function changeName(uint256 tokenId, string memory newName) public override {
        require(nameChangePrice<= vamirtoken.balanceOf(msg.sender), "low balance");
        require(nameChangePrice <= vamirtoken.allowance(msg.sender, address(this)), "low allowance");
		vamirtoken.burn(msg.sender, nameChangePrice);
		super.changeName(tokenId, newName);
	}

    function changeBio(uint256 tokenId, string memory _bio) public override {
        require(BIO_CHANGE_PRICE<= vamirtoken.balanceOf(msg.sender), "low balance");
        require(BIO_CHANGE_PRICE <= vamirtoken.allowance(msg.sender, address(this)), "low allowance");
		vamirtoken.burn(msg.sender, BIO_CHANGE_PRICE);
		super.changeBio(tokenId, _bio);
	}

    function changeNamePrice(uint256 _price) external onlyOwner {
		nameChangePrice = _price;
	}

    // ================ Signer ================ //

    function setSigners(address _free, address _wl) public onlyOwner{
        signer_free = _free;
        signer_wl = _wl;
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
        keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
        );
    }

    function rarityCheck(address user, bytes memory signature) public view returns (address) {
      bytes32 messageHash = keccak256(abi.encode(user));
      bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

      return recoverSigner(ethSignedMessageHash, signature);
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "sig invalid");

        assembly {
        /*
        First 32 bytes stores the length of the signature

        add(sig, 32) = pointer of sig + 32
        effectively, skips first 32 bytes of signature

        mload(p) loads next 32 bytes starting at the memory address p into memory
        */

        // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
        // second 32 bytes
            s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    // ================ Withdraw Functions ================ //

    function withdraw() public onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }


}