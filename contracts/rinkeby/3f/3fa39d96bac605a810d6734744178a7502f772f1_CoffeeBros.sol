// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol"; 

// import "erc721a/contracts/ERC721A.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CoffeeBros is ERC721A, Ownable{
    using Strings for uint256;

    uint256 MAX_SUPPLY = 1500;
    uint256 MAX_MINTS_PUBLIC = 5;
    uint256 MAX_MINTS_WHITELIST = 5;
    uint256 MAX_MINTS_TEAM = 1;
    uint256 public mintRate_Public = 0.01 ether;
    uint256 public mintRate_WhiteList = 0.03 ether;
    uint256 public mintRate_Team = 0 ether;

    bool public isPublicSale = false; 
    bool public isWhiteListSale = false;
    bool public isTeamSale = false;
    bool public isRevealed = false; 
    bool public paused = true;

    string public baseURI = "";  //change
    string public unrevealedBaseURI = ""; // change

    bytes32 public whitelistMerkleRoot; // change
    mapping(address => bool) public teamAddresses; //add

    constructor() ERC721A("CoffeeBros", "Coffee Bro"){
        addTeamAddress(0x7C9Ada7B2605b91796A121156Fe03f71E7596ebB); // addresses
        addTeamAddress(0xAE396C605ee799Ab6dA5b275fcbBb684F71F8539);
        addTeamAddress(0x921b5C089a3E7b80c596d7eB2fd3771e456D1aC6);
        addTeamAddress(0xEd8AB1210954bE324A02565a9EBf77853f9a9eE5);
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
        require(quantity + _numberMinted(_msgSender()) <= MAX_MINTS_PUBLIC, "Exceeded max mints");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Tokens");
        require(msg.value >= (mintRate_Public * quantity), "Not enough ether sent");
        _safeMint(_msgSender(), quantity);
    }

    function whiteListMint(uint256 quantity, bytes32[] calldata merkleProof) external payable callerIsUser 
    isValidMerkleProof(merkleProof, whitelistMerkleRoot)
    {
        require(!paused);
        require(isWhiteListSale);

        //require(whiteListAddresses[_msgSender()], "You are not whitelisted!");
        require(quantity + _numberMinted(_msgSender()) <= MAX_MINTS_WHITELIST, "Exceeded max mints");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Tokens");
        require(msg.value >= (mintRate_WhiteList * quantity), "Not enough ether sent");
        _safeMint(_msgSender(), quantity);
    }

    function teamMint(uint256 quantity) external payable{
        require(!paused);
        require(isTeamSale);
        
        require(teamAddresses[_msgSender()], "You are not on the team!");
        require(quantity + _numberMinted(_msgSender()) <= MAX_MINTS_TEAM, "Exceeded max mints");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Tokens");
        require(msg.value >= (mintRate_Team * quantity), "Not enough ether sent");
        _safeMint(_msgSender(), quantity);
    }

    function withdraw() external onlyOwner{
        uint256 pay1 = (address(this).balance * 5) / 200; // 2.5%
        address address1 = 0x7C9Ada7B2605b91796A121156Fe03f71E7596ebB;
        // change and add team members + pays
        uint256 pay2 = (address(this).balance * 6) / 200; //3%
        address address2 = 0xAE396C605ee799Ab6dA5b275fcbBb684F71F8539;

        uint256 pay3 = (address(this).balance * 2) / 200; //1%
        address address3 = 0x921b5C089a3E7b80c596d7eB2fd3771e456D1aC6;

        uint256 pay4 = (address(this).balance * 30) / 200; //15%
        address address4 = 0xEd8AB1210954bE324A02565a9EBf77853f9a9eE5;

        uint256 ownerPay = (address(this).balance * (200 - pay1 - pay2 - pay3 - pay4)) / 200; //(200 - (DevPay) - (ManagerPay * 2)) don't * devPay by 2 cus its already done
        
        payable(0x7C9Ada7B2605b91796A121156Fe03f71E7596ebB).transfer((address(this).balance * 5) / 200);
        payable(0x68507D72842431889fcb463954e80AbD78bf2E4e).transfer((address(this).balance * 6) / 200);
        payable(0xFaB4A50e705058C642149E1824bFd857291Fccc5).transfer((address(this).balance * 2) / 200);
        //payable(address4).transfer(pay4);
        payable(owner()).transfer(ownerPay);
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

    // mint price has to be 100x what you want to set it as
    function setPublicMint(uint256 _maxMint, uint256 _mintPrice ) public onlyOwner{
        MAX_MINTS_PUBLIC = _maxMint;
        mintRate_Public = (_mintPrice / 100);
    }

    // mint price has to be 100x what you want to set it as
    function setWhiteListMint(uint256 _maxMint, uint256 _mintPrice) public onlyOwner{
        MAX_MINTS_WHITELIST = _maxMint;
        mintRate_WhiteList = (_mintPrice / 100);
    }

    // mint price has to be 100x what you want to set it as
    function setTeamMint(uint256 _maxMint, uint256 _mintPrice) public onlyOwner{
        MAX_MINTS_TEAM = _maxMint;
        mintRate_Team = (_mintPrice / 100);
    }
    
    function addTeamAddress(address teamAddress) public onlyOwner{
        teamAddresses[teamAddress] = true;
    }

    function removeTeamAddress(address existingAddress) public onlyOwner{
        require(teamAddresses[existingAddress], "Not an existing address");
        teamAddresses[existingAddress] = false;
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

    function burnToken(uint256 tokenId) public{
        _burn(tokenId);
    }
}