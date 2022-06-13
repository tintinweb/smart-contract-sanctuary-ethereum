//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";



// import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
//AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
// import "./ERC721.sol";
// import "./ERC721Enumerable.sol";
//AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

// import "./ERC721URIStorage.sol";

// contract nft721_1 is ERC721URIStorage, Ownable {
//     using Counters for Counters.Counter;
//     Counters.Counter private _tokenIds;

//     constructor() public ERC721("MyNFT", "NFT") {}

//     function mintNFT(address recipient, string memory tokenURI)
//         public onlyOwner
//         returns (uint256)
//     {
//         _tokenIds.increment();

//         uint256 newItemId = _tokenIds.current();
//         _mint(recipient, newItemId);
//         _setTokenURI(newItemId, tokenURI);

//         return newItemId;
//     }
// }


//AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
// contract nft721_1 is Ownable, ERC721, ERC721Enumerable {
//AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

contract nft721_1 is Ownable, ERC721A, ReentrancyGuard {

    using Strings for uint256;

// contract nft721_1 is ERC721URIStorage, Ownable {
    // using Counters for Counters.Counter;
    // Counters.Counter private _tokenIds;

    // bool public saleIsActive = false;
    bool public paused = true;
    bool public revealed = false;
    string public notRevealedUri;
    address public owner_address;
    address public admin_address;
    address public sysadm_address;
    string public baseExtension = ".json";
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PUBLIC_MINT = 5;
    // uint256 public constant PRICE_PER_TOKEN = 0.01 ether;
    uint256 public price_per_token = 0.001 ether;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        address ownerAddress,
        address adminAddress,
        address sysadmAddress
    ) ERC721A(_name,  _symbol, MAX_SUPPLY) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        owner_address = ownerAddress;
        admin_address = adminAddress;
        sysadm_address = sysadmAddress;
    }

    // ) public ERC721("MyNFT", "NFT") {}

    // function mintNFT(address recipient, string memory tokenURI)
    //     public onlyOwner
    //     returns (uint256)
    // {
    //     _tokenIds.increment();

    //     uint256 newItemId = _tokenIds.current();
    //     _mint(recipient, newItemId);
    //     _setTokenURI(newItemId, tokenURI);

    //     return newItemId;
    // }

    function mint(uint numberOfTokens) public payable callerIsUser {
        uint256 ts = totalSupply();
        // require(saleIsActive, "Sale must be active to mint tokens");
        require(!paused, 'Contract is paused');
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(price_per_token * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    //AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }
    //AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

    function pause(bool _state) public  {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");

        paused = _state;
    }

    function reveal() public {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {    
        notRevealedUri = _notRevealedURI;
    }

    function setNotRevealedURIExternal(string memory _notRevealedURI) external {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        notRevealedUri = _notRevealedURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();

        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setNewCost(uint256 _newCost) public {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        price_per_token = _newCost;
    }

    function setBaseExtension(string memory _newBaseExtension) public {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        baseExtension = _newBaseExtension;
    }


    // // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // function setBaseURI(string calldata baseURI) external onlyOwner {
    function setBaseURI(string memory baseURI_) public onlyOwner {
        // _baseTokenURI = baseURI;
        _baseTokenURI = baseURI_;
    }


    function setBaseURIExternal(string memory baseURI_) external {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        _baseTokenURI = baseURI_;
    }


    function withdrawContractBalance() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }


}

/*
@openzeppelin/contracts/token/ERC721/ERC721.sol contains the 
implementation of the ERC-721 standard, 
which our NFT smart contract will inherit. 
(To be a valid NFT, your smart contract must implement all 
the methods of the ERC-721 standard.) 
To learn more about the inherited ERC-721 functions, check out the interface definition

*/