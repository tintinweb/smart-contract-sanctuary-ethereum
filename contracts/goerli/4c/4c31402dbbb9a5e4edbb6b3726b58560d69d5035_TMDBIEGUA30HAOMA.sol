// SPDX-License-Identifier: MIT

/*
 **************************************************************************

 Please don't list this like 0.001ETH or I'd be very sad.
 
 Now most free mint NFTs are occupied by several kinds of bots.
 Creators of the bots are the smartest people in the world.
 But some of those bot users are so fking stupid.
 They sniped some great project, then list them at 0.001 ETH.
 That makes no fking sense. Why don't these dumbass directly send their ETH to miners?

 So this project is supposed to be used as a poor-designed OpenSea banner
    to prove yourselves smart enough to list your free mint NFT higher.

 Btw, no official website, no twitter, no discord, no cost, and absolutely CC0.

 **************************************************************************

 --- Waiting for construction ---

 **************************************************************************
 */

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract TMDBIEGUA30HAOMA is ERC721A, Ownable {

    uint256 public headMax = 999; // can be lowered but not raised

    mapping(address => bool) public addressHasMinted;

    string public baseURI;
    string public baseExtension = ".png";

    bool public publicSaleActive; 
    bool public specialPeriodActive;

    uint256 lastMintTimestamp;

    constructor(string memory _baseURI) ERC721A("TMD BIE GUA 30 HAO MA?", "Unjuanable banner") {
        baseURI = _baseURI;
        lastMintTimestamp = block.timestamp + 2 hours;
    }

    function mint() external { // free, 1 per wallet
        require(_totalMinted() < headMax, "gg");
        require(publicSaleActive, "public sale inactive");
        // require that the last mint was less than 2 hours ago
        uint256 _currentTimestamp = block.timestamp;
        if(lastMintTimestamp != _currentTimestamp) {
            require(lastMintTimestamp + 2 hours > _currentTimestamp, "Nobody want this, gg");
            lastMintTimestamp = _currentTimestamp;
        }
        require(!addressHasMinted[_msgSender()], "Go gem.xyz to get more");
        addressHasMinted[_msgSender()] = true;
        _safeMint(_msgSender(), 1);
    }

    function mintGift(address _addr, uint256 _amount) external onlyOwner {
        require(_totalMinted() < headMax, "no more");
        _safeMint(_addr, _amount);
    }

    function setPublicSaleActive(bool _intended) external onlyOwner {
        require(publicSaleActive != _intended, "This is already the value");
        publicSaleActive = _intended;
        lastMintTimestamp = block.timestamp;
    }

    function setSpecialPeriodActive(bool _intended) external onlyOwner {
        require(specialPeriodActive != _intended, "This is already the value");
        specialPeriodActive = _intended;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setBaseExtension(string calldata _baseExtension) external onlyOwner {
        baseExtension = _baseExtension;
    }

    function setHeadsMax(uint256 _newHeadMax) external onlyOwner { 
        require(_newHeadMax < headMax, "supply cap can only be lowered");
        headMax = _newHeadMax;
    }

    // Talk some shit
    string public lettuceTalk = "check back soon"; // view API for most recent alpha
    function setLettuceWords(string memory _newWords) external onlyOwner {
        lettuceTalk = _newWords;
    }
  
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(baseURI, _toString(_tokenId), baseExtension));
    }

    function withdraw(address _to) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _to.call{value: balance}("");
        require(success, "Failed to send ether");
    }

    function donate() public payable {
        (bool thanks, ) = owner().call{value: address(this).balance}("");
        require(thanks);
	}
}