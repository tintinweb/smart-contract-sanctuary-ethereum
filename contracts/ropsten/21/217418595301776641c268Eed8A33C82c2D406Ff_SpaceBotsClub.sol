// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./ERC721A.sol";

/// @author zkWheat
contract SpaceBotsClub is ERC721A, Ownable {

    // metadata URI
    string public baseTokenURI;
    
    bool public publicSaleActive;
    bool public presaleActive;
    bool public freeMintActive;

    uint256 constant PRESALE_MAX_PLUS_ONE = 22;
    uint256 constant PUBLIC_MAX_TX_PLUS_ONE = 22;

    uint256 public presalePrice = 0.022 ether;
    

    uint256 public price = 0.04 ether;


    uint256 public MAX_SUPPLY_PLUS_ONE;

    mapping(address => uint256) public freeMintsPerAddress;
    mapping(address => uint256) public preMintsPerAddress;
    mapping(address => uint256) public publicMintsPerAddress;

    mapping(address => bool) private freeList;
    mapping(address => bool) private preList;

    //constructor(string memory uri, uint256 maxSupply) ERC721A("SpaceBotsClub", "SBC"){
        constructor(string memory uri, uint256 maxSupply) ERC721A("TestClub", "TC1"){
        baseTokenURI = uri;
        MAX_SUPPLY_PLUS_ONE = maxSupply;
        publicSaleActive = false;
        freeMintActive = false;
        presaleActive = false;

    }

    function publicMint(uint256 amount) public payable {
        require(publicSaleActive, "sale inactive");
        require(amount < PUBLIC_MAX_TX_PLUS_ONE, "only 21 per public mint");
        require(totalSupply() + amount < MAX_SUPPLY_PLUS_ONE, "exceeds max supply");
        require(msg.value >= amount * price, "ETH incorrect");

        publicMintsPerAddress[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

  

    function presale(uint256 amount) public payable {
        require(presaleActive, "presale inactive");
        require(totalSupply() + amount < MAX_SUPPLY_PLUS_ONE, "exceeds max supply");
        require(preList[msg.sender], "not preListed");
        require(preMintsPerAddress[msg.sender] + amount < PRESALE_MAX_PLUS_ONE, "only 21 per address");

        
        require(msg.value >= amount * presalePrice, "ETH incorrect");
        

        preMintsPerAddress[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function freeMint() public {
        uint256 amount = 1;
        require(freeMintActive, "free mint inactive");
        require(totalSupply() + amount < MAX_SUPPLY_PLUS_ONE, "exceeds max supply");
        require(freeList[msg.sender], "not freeListed");
        require(freeMintsPerAddress[msg.sender] == 0, "free mint claimed");

        freeMintsPerAddress[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    // For marketing etc.
    function devMint(uint256 amount) external onlyOwner {
        require(totalSupply() + amount < MAX_SUPPLY_PLUS_ONE, "exceeds max supply");
        _safeMint(msg.sender, amount);
    }

    function airdrop(address[] calldata receivers, uint256 mintNumber) external onlyOwner {
        require((totalSupply() + (receivers.length * mintNumber)) < MAX_SUPPLY_PLUS_ONE, "exceeds max supply");

        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], mintNumber);
        }
    }

   function isFreeListed(address _address) public view returns (bool){
        return freeList[_address];
    }
    
    function isPreListed(address _address) public view returns (bool){
        return preList[_address];
    }

     function isFreeMintActive() public view returns (bool){
        return freeMintActive;
    }
     function isPreMintActive() public view returns (bool){
        return presaleActive;
    }
     function isPublicMintActive() public view returns (bool){
        return publicSaleActive;
    }

  
    function addToFreeList(address[] calldata _addresses) external onlyOwner {
        for (uint256 i; i < _addresses.length; i++) {
            freeList[_addresses[i]] = true;
        }
    }

     function addToPreList(address[] calldata _addresses) external onlyOwner {
        for (uint256 i; i < _addresses.length; i++) {
            preList[_addresses[i]] = true;
        }
    }
    

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setPrice(uint256 _price) public onlyOwner() {
        price = _price;
    }

     function setPresalePrice(uint256 _presalePrice) public onlyOwner() {
        presalePrice = _presalePrice;
    }

    function flipPublicSale() public onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function flipPresale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    function flipFreeMintSale() public onlyOwner {
        freeMintActive = !freeMintActive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }
}