// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract GirlsNFT is Ownable, ERC721Enumerable {
    string public provenance;
    uint16 public maxSupply; 
    uint8 public reserved_token;
    uint8 public mintedReservedToken;
    uint public publicMintPrice;
    uint public presaleMintPrice;
    uint public extraChancePrice;
    uint public totalMinted;

    bool public isPresale;
    bool public isPublic;
    bool public isPaused;

    mapping(address => bool) public presalerList;
    mapping(address => uint256) public presalerListPurchases;
    mapping(uint256 => uint8) public extraChances;

    constructor() ERC721("X-Malden Lab", "XML") {
        maxSupply = 2222;
        reserved_token = 200;
        publicMintPrice = 5*10**16;
        presaleMintPrice = 4*10**16;
        extraChancePrice = 10**16;
    }

    function togglePresale() external onlyOwner {
        isPresale = !isPresale;
    }

    function togglePublic() external onlyOwner {
        isPublic = !isPublic;
    }

    function togglePaused() external onlyOwner {
        isPaused = !isPaused;
    }

    function addToPresaleList(address[] calldata users) external onlyOwner {
        for(uint i = 0; i < users.length; i++) {
            require(users[i] != address(0));
            if(presalerList[users[i]] != true)
                presalerList[users[i]] = true;
        }
    }

    function removeFromPresaleList(address[] calldata users) external onlyOwner {
        for(uint i = 0; i < users.length; i++) {
            require(users[i] != address(0));
            if(presalerList[users[i]] != false)
                presalerList[users[i]] = false;
        }
    }

    function buy(uint16 tokenQuantity) external payable {
        require(isPublic, "current is not allowed for public buy!");
        require(msg.value == (publicMintPrice * tokenQuantity), "payed value is not equal to the price");
        require(totalSupply()+tokenQuantity <= (maxSupply - reserved_token + mintedReservedToken), "nft supply is full");
        require(!isPresale, "presale is starting");
        require(!isPaused, "the contract is now paused");

        for(uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply());
            // totalMinted++;
        }
    }

    function presaleBuy(uint16 tokenQuantity) external payable {
        require(isPresale, "current is not allowed for presale buy!");
        require(presalerList[msg.sender], "you are not allowed for presale buy!");
        require(msg.value == (presaleMintPrice * tokenQuantity), "paid value is not equal to the price");
        require(totalSupply()+tokenQuantity <= (maxSupply - reserved_token + mintedReservedToken), "nft supply is full");
        require(!isPaused, "the contract is now paused");

        for(uint i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply());
        }

        presalerListPurchases[msg.sender] = tokenQuantity;
    }

    function giveaway(address[] calldata addressList, uint8[] calldata tokenQuantity) external onlyOwner {
        uint8 totalGive;
        for(uint i = 0; i < tokenQuantity.length; i++) {
            totalGive += tokenQuantity[i];
        }
        require((totalGive + mintedReservedToken) <= reserved_token, "owner mint is full");

        for(uint i = 0; i < addressList.length; i++) {
            for(uint j = 0; j < tokenQuantity[i]; j++) {
                 _safeMint(addressList[i], totalSupply());
            }
        }

        mintedReservedToken += totalGive;
    }

    function addExtraChance(uint256 tokenId) external payable {
        require(ownerOf(tokenId) == msg.sender, "you are not the owner of the token");
        require(msg.value == extraChancePrice, "paid value is not equal to the price");
        require(extraChances[tokenId] < 3, "token chance is not enough");

        extraChances[tokenId]++;
    }

    function setProvenance(string calldata newProvenance) external onlyOwner {
        provenance = newProvenance;
    }

    function withdraw() external onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }

    function updatePublicMintPrice(uint newMintPrice) external onlyOwner {
        publicMintPrice = newMintPrice;
    }

    function updatePresaleMintPrice(uint newMintPrice) external onlyOwner {
        presaleMintPrice = newMintPrice;
    }

    function updateExtraChancePrice(uint newExtraChancePrice) external onlyOwner {
        extraChancePrice = newExtraChancePrice;
    }

    function setBaseURI(string memory _baseURI_) external onlyOwner {
        baseURI = _baseURI_;
    }

    function setTokenURI(string memory _URI, uint256 tokenId) external onlyOwner {
        _tokenUri[tokenId] = _URI;
    }

    //////////////////for test///////////////////////

    function pplPresale(address ppl) external view returns (bool) {
        return presalerList[ppl];
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}