// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./MerkleProof.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract FootballApeYachtClub is ERC721Enumerable, Ownable, ReentrancyGuard {

    //To increment the id of the NFTs
    using Counters for Counters.Counter;

    //To concatenate the URL of an NFT
    using Strings for uint256;

    //To check the addresses in the whitelist
    bytes32 public merkleRoot;

    //Id of the next NFT to mint
    Counters.Counter private _nftIdCounter;

    //Number of NFTs in the collection
    uint public constant MAX_SUPPLY = 10000;
    //Maximum number of NFTs an address can mint
    uint public max_mint_allowed = 20;
    //Price of one NFT in presale
    uint public pricePresale = 0.045 ether;
    //Price of one NFT in sale
    uint public priceSale = 0.1 ether;

    //URI of the NFTs when revealed
    string public baseURI;
    //URI of the NFTs when not revealed
    string public notRevealedURI;
    //The extension of the file containing the Metadatas of the NFTs
    string public baseExtension = ".json";

    //Are the NFTs revealed yet ?
    bool public revealed = false;

    //Is the contract paused ?
    bool public paused = false;

    //The different stages of selling the collection
    enum Steps {
        Before,
        Presale,
        Sale,
        SoldOut,
        Reveal
    }

    Steps public sellingStep;
    
    //Owner of the smart contract
    address private _owner;

    //Keep a track of the number of tokens per address
    mapping(address => uint) nftsPerWallet;


    //Constructor of the collection
    constructor(string memory _theBaseURI, string memory _notRevealedURI, bytes32 _merkleRoot) ERC721("FootballApeYachtClub", "FAYC") {
        _nftIdCounter.increment();
        transferOwnership(msg.sender);
        sellingStep = Steps.Before;
        baseURI = _theBaseURI;
        notRevealedURI = _notRevealedURI;
        merkleRoot = _merkleRoot;
    }

    /**
    * @notice Edit the Merkle Root 
    *
    * @param _newMerkleRoot The new Merkle Root
    **/
    function changeMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    /** 
    * @notice Set pause to true or false
    *
    * @param _paused True or false if you want the contract to be paused or not
    **/
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    /** 
    * @notice Change the number of NFTs that an address can mint
    *
    * @param _maxMintAllowed The number of NFTs that an address can mint
    **/
    function changeMaxMintAllowed(uint _maxMintAllowed) external onlyOwner {
        max_mint_allowed = _maxMintAllowed;
    }

    /**
    * @notice Change the price of one NFT for the presale
    *
    * @param _pricePresale The new price of one NFT for the presale
    **/
    function changePricePresale(uint _pricePresale) external onlyOwner {
        pricePresale = _pricePresale;
    }

    /**
    * @notice Change the price of one NFT for the sale
    *
    * @param _priceSale The new price of one NFT for the sale
    **/
    function changePriceSale(uint _priceSale) external onlyOwner {
        priceSale = _priceSale;
    }

    /**
    * @notice Change the base URI
    *
    * @param _newBaseURI The new base URI
    **/
    function setBaseUri(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
    * @notice Change the not revealed URI
    *
    * @param _notRevealedURI The new not revealed URI
    **/
    function setNotRevealURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    /**
    * @notice Allows to set the revealed variable to true
    **/
    function reveal() external onlyOwner{
        revealed = true;
    }

    /**
    * @notice Return URI of the NFTs when revealed
    *
    * @return The URI of the NFTs when revealed
    **/
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
    * @notice Allows to change the base extension of the metadatas files
    *
    * @param _baseExtension the new extension of the metadatas files
    **/
    function setBaseExtension(string memory _baseExtension) external onlyOwner {
        baseExtension = _baseExtension;
    }

    /** 
    * @notice Allows to change the sellinStep to Presale
    **/
    function setUpPresale() external onlyOwner {
        sellingStep = Steps.Presale;
    }

    /** 
    * @notice Allows to change the sellinStep to Sale
    **/
    function setUpSale() external onlyOwner {
        require(sellingStep == Steps.Presale, "First the presale, then the sale.");
        sellingStep = Steps.Sale;
    }

    /**
    * @notice Allows to mint one NFT if whitelisted
    *
    * @param _account The account of the user minting the NFT
    * @param _proof The Merkle Proof
    **/
    function presaleMint(address _account, bytes32[] calldata _proof) external payable nonReentrant {
        //Are we in Presale ?
        require(sellingStep == Steps.Presale, "Presale has not started yet.");
        //Did this account already mint an NFT ?
        require(nftsPerWallet[_account] < 1, "You can only get 1 NFT on the Presale");
        //Is this user on the whitelist ?
        require(isWhiteListed(_account, _proof), "Not on the whitelist");
        //Get the price of one NFT during the Presale
        uint price = pricePresale;
        //Did the user send enought Ethers ?
        require(msg.value >= price, "Not enought funds.");
        //Increment the number of NFTs this user minted
        nftsPerWallet[_account]++;
        //Mint the user NFT
        _safeMint(_account, _nftIdCounter.current());
        //Increment the Id of the next NFT to mint
        _nftIdCounter.increment();
    }

    /**
    * @notice Allows to mint NFTs
    *
    * @param _ammount The ammount of NFTs the user wants to mint
    **/
    function saleMint(uint256 _ammount) external payable nonReentrant {
        //Get the number of NFT sold
        uint numberNftSold = totalSupply();
        //Get the price of one NFT in Sale
        uint price = priceSale;
        //If everything has been bought
        require(sellingStep != Steps.SoldOut, "Sorry, no NFTs left.");
        //If Sale didn't start yet
        require(sellingStep == Steps.Sale, "Sorry, sale has not started yet.");
        //Did the user then enought Ethers to buy ammount NFTs ?
        require(msg.value >= price * _ammount, "Not enought funds.");
        //The user can only mint max 3 NFTs
        require(_ammount <= max_mint_allowed, "You can't mint more than 3 tokens");
        //If the user try to mint any non-existent token
        require(numberNftSold + _ammount <= MAX_SUPPLY, "Sale is almost done and we don't have enought NFTs left.");
        //Add the ammount of NFTs minted by the user to the total he minted
        nftsPerWallet[msg.sender] += _ammount;
        //If this account minted the last NFTs available
        if(numberNftSold + _ammount == MAX_SUPPLY) {
            sellingStep = Steps.SoldOut;   
        }
        //Minting all the account NFTs
        for(uint i = 1 ; i <= _ammount ; i++) {
            _safeMint(msg.sender, numberNftSold + i);
        }
    }

    /**
    * @notice Return true or false if the account is whitelisted or not
    *
    * @param account The account of the user
    * @param proof The Merkle Proof
    *
    * @return true or false if the account is whitelisted or not
    **/
    function isWhiteListed(address account, bytes32[] calldata proof) internal view returns(bool) {
        return _verify(_leaf(account), proof);
    }

    /**
    * @notice Return the account hashed
    *
    * @param account The account to hash
    *
    * @return The account hashed
    **/
    function _leaf(address account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    /** 
    * @notice Returns true if a leaf can be proved to be a part of a Merkle tree defined by root
    *
    * @param leaf The leaf
    * @param proof The Merkle Proof
    *
    * @return True if a leaf can be provded to be a part of a Merkle tree defined by root
    **/
    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns(bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    /**
    * @notice Allows to get the complete URI of a specific NFT by his ID
    *
    * @param _nftId The id of the NFT
    *
    * @return The token URI of the NFT which has _nftId Id
    **/
    function tokenURI(uint _nftId) public view override(ERC721) returns (string memory) {
        require(_exists(_nftId), "This NFT doesn't exist.");
        if(revealed == false) {
            return notRevealedURI;
        }
        
        string memory currentBaseURI = _baseURI();
        return 
            bytes(currentBaseURI).length > 0 
            ? string(abi.encodePacked(currentBaseURI, _nftId.toString(), baseExtension))
            : "";
    }

      function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }

}