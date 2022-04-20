// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

//import "erc721a/contracts/ERC721A.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";

contract OGCB is ERC721A, Ownable{
    using Strings for uint256;

    uint256 MAX_SUPPLY = 5555;
    uint256 MAX_MINTS_PUBLIC = 5;
    uint256 MAX_MINTS_TEAM = 10;
    uint256 public mintRate_Public = 0.042 ether;

    bool public isPublicSale = false; 
    bool public isTeamSale = false;
    bool public paused = true;

    string public baseURI = "ipfs://QmVJgoLdneFGghYsaGJvR9yuZH9fpgUsXBVxRH7XWMPwyG/";  //change

    mapping(address => bool) public teamAddresses;


    constructor() ERC721A("OG Crypto Buddies", "OGCB"){
        addTeamAddress(0x7C9Ada7B2605b91796A121156Fe03f71E7596ebB);
        addTeamAddress(0x7ac69d0fF1C262540dA39f52963B035B68860A06);
        addTeamAddress(0xc5F51d4276D3DdF56796F53fD69868E7b089a782);
    }

    modifier callerIsUser(){
        require(tx.origin == _msgSender(), "Only users can interact with this contract!");
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

    function ownerMint(uint256 quantity) external onlyOwner{
        require(totalSupply() + quantity <= MAX_SUPPLY, "not enough left");
        _safeMint(owner(), quantity);
    }

    function teamMint(uint256 quantity) external{
        require(!paused);
        require(isTeamSale);
        
        require(teamAddresses[_msgSender()], "You are not on the team!");
        require(quantity + _numberMinted(_msgSender()) <= MAX_MINTS_TEAM, "Exceeded max mints");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Tokens");
        _safeMint(_msgSender(), quantity);
    }

    function withdraw() public onlyOwner{
        address address1 = 0x7C9Ada7B2605b91796A121156Fe03f71E7596ebB;
        address address2 = 0x7ac69d0fF1C262540dA39f52963B035B68860A06;
        address address3 = 0xc5F51d4276D3DdF56796F53fD69868E7b089a782;

        (bool payer1, ) = payable(address1).call{value: address(this).balance * 2 / 100}("");
        (bool payer2, ) = payable(address2).call{value: address(this).balance * 32 / 98}("");
        (bool payer3, ) = payable(address3).call{value: address(this).balance * 33 / 66}("");
        (bool payer4, ) = payable(owner()).call{value: (address(this).balance) / 33}("");
        require(payer1 && payer2 && payer3 && payer4, "Nope");
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

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, trueId.toString(), ".json")) : "";
    }
    
    function addTeamAddress(address teamAddress) public onlyOwner{
        teamAddresses[teamAddress] = true;
    }

    function removeTeamAddress(address existingAddress) public onlyOwner{
        require(teamAddresses[existingAddress], "Not an existing address");
        teamAddresses[existingAddress] = false;
    }
    
    function pause(bool shouldPause) public onlyOwner{
        paused = shouldPause;
    }

    function setPublicSale(bool shouldStartPublicSale) public onlyOwner{
        isPublicSale = shouldStartPublicSale;
    }

    function setTeamSale(bool shouldStartTeamSale) public onlyOwner{
        isTeamSale = shouldStartTeamSale;
    }

    function burnToken(uint256 tokenId) public onlyOwner{
        _burn(tokenId);
    }
}