// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol"; 

contract TATERTOWN is ERC721A, Ownable {
    using SafeMath for uint256;

    uint256 MAX_MINTS = 10;
    uint256 MAX_ELEMENTS = 5555;
    uint256 public mintRate = 0.0007 ether;
    uint256 public privateMintPrice = 0.0005 ether;
    uint256 public MAX_MINT_WHITELIST = 20;

    bool public saleIsActive = false;
    bool public privateSaleIsActive = true;

    struct Whitelist {
        address addr;
        uint256 claimAmount;
        uint256 hasMinted;
    }

    mapping(address => Whitelist) public whitelist;

    address[] whitelistAddr;


    string public baseURI = "mandox.mypinata.cloud/ipfs/QmUxabT7q1DDp6JtokS6cybo7KVFREB9AFTFSv4nwdR5gu/";

    constructor() ERC721A("Taters", "TATER") {}

        /**
     * Set presell price to mint
     */
    function setPrivateMintPrice(uint256 _price) external onlyOwner {
        privateMintPrice = _price;
    }

    /**
     * Set publicsell price to mint
     */
    function setPublicMintPrice(uint256 _price) external onlyOwner {
        mintRate = _price;
    }
/*
    function mint(uint256 quantity) external payable {
        require(saleIsActive, "Sale must be active to mint");
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_ELEMENTS, "Not enough tokens left");
        require(msg.value >= (mintRate * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }
*/

    
    function mint(uint256 quantity) external payable {
        require(saleIsActive, "Sale must be active to mint");
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_ELEMENTS, "Not enough tokens left");

        if(privateSaleIsActive) {
           require(msg.value >= (mintRate * quantity), "Not enough ether sent");
           require(quantity <= MAX_MINT_WHITELIST, "Above max Mint Whitelist count");
           require(isWhitelisted(msg.sender), "Is not whitelisted");
           require(
                whitelist[msg.sender].hasMinted.add(quantity) <=
                    MAX_MINT_WHITELIST,
                "Can only mint 20 while whitelisted"
            );
            whitelist[msg.sender].hasMinted = whitelist[msg.sender]
                .hasMinted
                .add(quantity);
        } else {
        if (isWhitelisted(msg.sender)) {}
            require(
                (mintRate * quantity) <= msg.value,
                "Value below price"
            );
        }

        if (totalSupply() < MAX_ELEMENTS){
        _safeMint(msg.sender, quantity);
        }
    }



    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function maxSupply() external view returns (uint256) {
        return MAX_ELEMENTS;
    }

    function publicmintPrice() external view returns (uint256) {
    return mintRate;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setPublicRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }

     /*
     * Pause sale if active, make active if paused
     */

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPrivateSaleState() public onlyOwner {
        privateSaleIsActive = !privateSaleIsActive;
    }

    function setWhitelistAddr(address[] memory addrs) public onlyOwner {
        whitelistAddr = addrs;
        for (uint256 i = 0; i < whitelistAddr.length; i++) {
            addAddressToWhitelist(whitelistAddr[i]);
        }
    }

    function partialWithdraw(uint256 _amount, address payable _to)
        external
        onlyOwner
    {
        require(_amount > 0, "Withdraw must be greater than 0");
        require(_amount <= address(this).balance, "Amount too high");
        (bool success, ) = _to.call{value: _amount}("");
        require(success);
    }

    function addAddressToWhitelist(address addr)
        public
        onlyOwner
        returns (bool success)
    {
        require(!isWhitelisted(addr), "Already whitelisted");
        whitelist[addr].addr = addr;
        success = true;
    }

    function isWhitelisted(address addr)
        public
        view
        returns (bool isWhiteListed)
    {
        return whitelist[addr].addr == addr;
    }

}