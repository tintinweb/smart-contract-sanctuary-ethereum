// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol"; 
import "./IERC20.sol";

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract RockstarApes is ERC721A, Ownable{
    using Strings for uint256;

    uint256 MAX_SUPPLY = 7777;
    uint256 MAX_MINTS_WHITELIST = 4;
    uint256 MAX_MINTS_TEAM = 2;
    uint256 public mintRate_Public = 0.11 ether;
    uint256 public mintRate_WhiteList = 0.077 ether;

    bool public isPublicSale = false; 
    bool public isWhiteListSale = false;
    bool public isTeamSale = true;
    bool public isRevealed = false; 
    bool public paused = true;

    string public baseURI = "ipfs://QmbgQtFdVBygJr9LaN2LmoC5dvgUPYfJkhXcokp4xkRKds/";  //change
    string public unrevealedBaseURI = "ipfs://QmToazxEuJ1xkpTbf1oKhPf9o1AivmSmkRZTUjbQJPGvAi"; // change
    IERC20 public tokenAddress;

    bytes32 public whitelistMerkleRoot = 0xc5cf254329d8aec70ea742e534bbaf2133a90c4b4a38d577560977f4b83cdc34;
    mapping(address => bool) public teamAddresses;


    constructor() ERC721A("RockstarApes", "RockStarApe"){
        addTeamAddress(0x7C9Ada7B2605b91796A121156Fe03f71E7596ebB);
    }

    modifier callerIsUser(){
        require(tx.origin == _msgSender(), "Only users can interact with this contract!");
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    function publicMint(uint256 quantity) external payable callerIsUser{
        require(!paused);
        require(isPublicSale);
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Tokens");
        require(msg.value >= (mintRate_Public * quantity), "Not enough ether sent");

        _safeMint(_msgSender(), quantity);

        uint256 tokenQuantity = (777 * quantity) * (10**18);
        tokenAddress.transfer(_msgSender(), tokenQuantity);
        _safeMint(_msgSender(), quantity);
    }

    function whiteListMint(uint256 quantity, bytes32[] calldata merkleProof) external payable callerIsUser 
    isValidMerkleProof(merkleProof, whitelistMerkleRoot)
    {
        require(!paused);
        require(isWhiteListSale);
        require(quantity + _numberMinted(_msgSender()) <= MAX_MINTS_WHITELIST, "Exceeded max mints");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Tokens");
        require(msg.value >= (mintRate_WhiteList * quantity), "Not enough ether sent");

        uint256 tokenQuantity = (777 * quantity) * (10**18);
        tokenAddress.transfer(_msgSender(), tokenQuantity);
        _safeMint(_msgSender(), quantity);
    }

    function teamMint(uint256 quantity) external{
        require(isTeamSale);
        
        require(teamAddresses[_msgSender()], "You are not on the team!");
        require(quantity + _numberMinted(_msgSender()) <= MAX_MINTS_TEAM, "Exceeded max mints");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Tokens");

        uint256 tokenQuantity = (777 * quantity) * (10**18);
        tokenAddress.transfer(_msgSender(), tokenQuantity);
        _safeMint(_msgSender(), quantity);
    }

    function promoMint(uint256 quantity, address addy) external onlyOwner{
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Tokens");

        uint256 tokenQuantity = (777 * quantity) * (10**18);
        tokenAddress.transfer(addy, tokenQuantity);
        _safeMint(addy, quantity);
    }

    function withdraw() public onlyOwner{
        address address1 = 0x7C9Ada7B2605b91796A121156Fe03f71E7596ebB;
        address address2 = 0x1fB815a6E03E380b5770320c899Ba66BBAf55BF4;

        (bool payer1, ) = payable(address1).call{value: address(this).balance * 3 / 200}("");
        (bool payer2, ) = payable(address2).call{value: (address(this).balance)}("");
        require(payer1 && payer2, "Nope");
    }

    function _baseURI() internal view virtual override returns(string memory){
        return baseURI;
    }

    function setBaseURI(string memory newURI) public onlyOwner{
        baseURI = newURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory){
        require(_exists(tokenId), "Non-existant token URI Query");
        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return unrevealedBaseURI;
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, trueId.toString(), ".json")) : "";
    }
    
    function addTeamAddress(address teamAddress) public onlyOwner{
        teamAddresses[teamAddress] = true;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function reveal(bool shouldReveal) public onlyOwner{
        isRevealed = shouldReveal;
    }
    
    function pause(bool shouldPause) public onlyOwner{
        paused = shouldPause;
    }

    function setPublicSale(bool shouldStartPublicSale) public onlyOwner{
        isPublicSale = shouldStartPublicSale;
    }

    function setWhiteListSale(bool shouldStartWhiteListSale) public onlyOwner{
        isWhiteListSale = shouldStartWhiteListSale;
    }

    function setTeamSale(bool shouldStartTeamSale) public onlyOwner{
        isTeamSale = shouldStartTeamSale;
    }

    function burnToken(uint256 tokenId) public onlyOwner{
        _burn(tokenId - 1);
    }

    function setTokenAddress(address addy) public onlyOwner{
        tokenAddress = IERC20(addy);
    }
}