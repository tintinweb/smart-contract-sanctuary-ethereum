//
//    |######   //###\\ #######   //\\
//    | |      //     \\  | |    //  \\
//    |###### ||       || | |   //####\\
//    | |      \\     //  | |  //      \\
//    | |       \\###//   | | //        \\
//     
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";

contract FOTA is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 10000;
    uint256 public limitedSupply = 1000;
    
    uint256 public maxPerTxPublic = 500;
    uint256 public maxPerWallet = 500;

    uint256 public pricePublic1 = 75000000000000000; //0.075 ETH
    uint256 public pricePublic5 = 350000000000000000; //0.35 ETH
    uint256 public pricePublic10 = 650000000000000000; //0.65 ETH

    string public baseURI = "";
    string public provenance = "";
    string public uriNotRevealed = "";
    
    bool public paused = true;
    bool public pausedfree = true;
    bool public isRevealed;

    address FOTA1 = 0x8f361613a24d63cE6673008019b844a7331184b6;
    address FOTA2 = 0xC8cEA6FBc38226582293c3B728B981e0473498de;
    address FOTA3 = 0x913C9441C542363e4CF45DA805E353F937E17bF6;
    address FOTA4 = 0xD09aED0CfE103ce03D9777Eb708DD60AF8183a01;

    event Minted(address caller);
    
    constructor() ERC721A("Forest Of The Apes", "FOTA", maxPerTxPublic) {}

    function reserve(address _to, uint256 _numa) external onlyOwner {
        require(_to != address(0), "Invalid address to reserve.");
        uint256 supply = totalSupply();
        require(supply + _numa <= limitedSupply, "Sorry, not enough left!");
        
        _safeMint(_to, _numa);

        emit Minted(msg.sender);
    }

    function _mintNBatch(uint256 _n, uint256 _batch) private {
        uint256 supply = totalSupply();
        require(balanceOf(msg.sender) < maxPerWallet, "Sorry, you already own the max allowed!");
        require(supply + (_n * _batch) <= limitedSupply, "Sorry, not enough left!");
        require(_n <= maxPerTxPublic, "Sorry, too many per transaction");

        for (uint i = 0; i < (_n * _batch); i++) {
            _safeMint(msg.sender, 1);
            emit Minted(msg.sender);
        }
    }

    function mint1(uint256 _n) external payable {
        require(!paused, "Minting is paused");
        require(msg.value >= pricePublic1 * _n, "Sorry, not enough amount sent!"); 

        _mintNBatch(_n, 1);
    }

    function mint5(uint256 _n) external payable {
        require(!paused, "Minting is paused");
        require(msg.value >= pricePublic5 * _n, "Sorry, not enough amount sent!"); 

        _mintNBatch(_n, 5);
    }

    function mint10(uint256 _n) external payable {
        require(!paused, "Minting is paused");
        require(msg.value >= pricePublic10 * _n, "Sorry, not enough amount sent!"); 

        _mintNBatch(_n, 10);
    }

    function mintFree(uint256 _n) external {
        require(!pausedfree, "Free mint function is paused");

        _mintNBatch(_n, 1);
    }
    
    function remaining() public view returns(uint256){
        uint256 left = maxSupply - totalSupply();
        return left;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (isRevealed == false) {
            return uriNotRevealed;
        }
        string memory base = baseURI;

        return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString(), ".json")) : "";
    }

    function getPricePublic1() public view returns (uint256){
        return pricePublic1;
    }

    function getPricePublic5() public view returns (uint256){
        return pricePublic5;
    }

    function getPricePublic10() public view returns (uint256){
        return pricePublic10;
    }

    // ADMIN FUNCTIONS 

    function flipPaused() public onlyOwner {
        paused = !paused;
    }

    function flipFreePaused() public onlyOwner {
        pausedfree = !pausedfree;
    }
    
    function flipRevealed(string memory _URI) public onlyOwner {
        baseURI = _URI;
        isRevealed = !isRevealed;
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }

    function setUriNotRevealed(string memory _URI) public onlyOwner {
        uriNotRevealed = _URI;
    }

    function setMaxPerTx(uint256 _newMax) public onlyOwner {
        maxPerTxPublic = _newMax;
    }

    function setLimitedSupply(uint256 _limitedSupply) public onlyOwner {
        require(_limitedSupply <= maxSupply, "Limited supply must be less or equal max supply");

        limitedSupply = _limitedSupply;
    }

    function setPricePublic(uint256 _newPrice) public onlyOwner {
        pricePublic1 = _newPrice;
        pricePublic5 = (_newPrice - 5000000000000000) * 5;
        pricePublic10 = (_newPrice - 10000000000000000) * 10;
    }

    function setProvenanceHash(string memory _provenance) public onlyOwner {
        provenance = _provenance;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;

        _withdraw(FOTA1, balance * 25 / 100);
        _withdraw(FOTA2, balance * 25 / 100);
        _withdraw(FOTA3, balance * 25 / 100);
        _withdraw(FOTA4, balance * 25 / 100);        
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    // helpers

    // list all the tokens ids of a wallet
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    receive() external payable {}
}