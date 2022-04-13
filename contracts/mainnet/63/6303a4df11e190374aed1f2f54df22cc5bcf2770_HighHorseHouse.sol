// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

//import "@openzeppelin/contracts/access/Ownable.sol";

contract HighHorseHouse is ERC721A, Ownable{
    using Strings for uint256;

    uint256 MAX_SUPPLY = 500;
    uint256 MAX_MINTS_PUBLIC = 6;
    uint256 public mintRate_Public = 0.06 ether;

    bool public isPublicSale = true; 
    bool public isHolderSale = true;
    bool public paused = false;

    string public baseURI = "ipfs://Qmf73emC6hK6y9b3uBySYT4iMkk4FzY58KX4UPVCFxyok7/";  //change

    mapping(uint256 => bool) public tokenHasBeenClaimed;

    constructor() ERC721A("High Horse House", "HORS"){
    }


    function publicMint(uint256 quantity) external payable{
        require(!paused);
        require(isPublicSale);
        require(quantity + _numberMinted(_msgSender()) <= MAX_MINTS_PUBLIC, "Exceeded max mints");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Tokens");
        require(msg.value >= (mintRate_Public * quantity), "Not enough ether sent");

        _safeMint(_msgSender(), quantity);
    }

    function holderMint(uint256 tokenId) external{
        require(!paused);
        require(isHolderSale);
        require(totalSupply() + 1 <= MAX_SUPPLY, "Not enough Tokens");
        require(!tokenHasBeenClaimed[tokenId], "already claimed!");
        _safeMint(_msgSender(), 1);

        tokenHasBeenClaimed[tokenId] = true;
    }

    function ownerMint(uint256 quantity) external onlyOwner{
        _safeMint(owner(), quantity);
    }

    function withdraw() public onlyOwner{
        (bool payer5, ) = payable(owner()).call{value: (address(this).balance)}("");
        require(payer5, "Something went wrong");
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

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, trueId.toString())) : "";
    }
    
    function pause(bool shouldPause) public onlyOwner{
        paused = shouldPause;
    }

    function setPublicSale(bool shouldStartPublicSale) public onlyOwner{
        isPublicSale = shouldStartPublicSale;
    }

    function setHolderSale(bool shouldStart) public onlyOwner{
        isHolderSale = shouldStart;
    }

    function burnToken(uint256 tokenId) public onlyOwner{
        _burn(tokenId);
    }

    function u() public{

    }
}