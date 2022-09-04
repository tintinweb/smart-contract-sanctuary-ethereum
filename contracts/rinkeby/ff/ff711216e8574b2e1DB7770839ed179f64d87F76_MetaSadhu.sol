// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";

/**
 * @title MetaSadhu
 * @dev Create a sample ERC721 standard token
 */
contract MetaSadhu is ERC721, Ownable {
    using Strings for uint256;

    string _baseTokenURI;
    uint256 public _cardPrice = 10800000000000000;   // .05 ETH
    bool public _saleIsActive = true;
    // Reserve units for team - Giveaways/Prizes/Presales etc
    uint public _cardReserve = 1000;
    uint public _mainCardCnt = 8108;

    constructor(string memory baseURI) ERC721("Meta Sadhu", "SADHU") {
        setBaseURI(baseURI);
    }
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    /** 
     * Mint a number of cards straight in target wallet.
     * @param _to: The target wallet address, make sure it's the correct wallet.
     * @param _numberOfTokens: The number of tokens to mint.
     * @dev This function can only be called by the contract owner as it is a free mint.
     */
    function mintFree(address _to, uint _numberOfTokens) public onlyOwner {
        uint supply = totalSupply();
        require(_numberOfTokens < 21, "Can only mint 20 tokens at a time");
        require(_numberOfTokens <= _cardReserve, "Not enough cards left in reserve");
        require(supply + _numberOfTokens <= _mainCardCnt, "Purchase would exceed max supply of cards");
        for(uint i = 0; i < _numberOfTokens; i++) {
            uint mintIndex = supply + i;
            _safeMint(_to, mintIndex);
        }
        _cardReserve -= _numberOfTokens;
    }
    /** 
     * Mint a number of cards straight in the caller's wallet.
     * @param _numberOfTokens: The number of tokens to mint.
     */
    function mint(uint _numberOfTokens) public payable {
        uint supply = totalSupply();
        require(_saleIsActive, "Sale must be active to mint a Card");
        require(_numberOfTokens < 21, "Can only mint 20 tokens at a time");
        require(supply + _numberOfTokens <= _mainCardCnt, "Purchase would exceed max supply of cards");
        require(msg.value >= _cardPrice * _numberOfTokens, "Ether value sent is not correct");
        for(uint i = 0; i < _numberOfTokens; i++) {
            uint mintIndex = supply + i;
            _safeMint(msg.sender, mintIndex);
        }
    }
    function flipSaleState() public onlyOwner {
        _saleIsActive = !_saleIsActive;
    }
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    // Might wanna adjust price later on.
    function setPrice(uint256 _newPrice) public onlyOwner() {
        _cardPrice = _newPrice;
    }
    
    function getBaseURI() public view returns(string memory) {
        return _baseTokenURI;
    }
    function getPrice() public view returns(uint256){
        return _cardPrice;
    }
    function tokenURI(uint256 tokenId) public override view returns(string memory) {
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json"));
    }
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint i = 0; i < tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }
    function setCardCnt(uint _cnt) public onlyOwner() {
        require(totalSupply() <= _cnt, "Cant set count less than current cnt");
        _mainCardCnt = _cnt;
    }

}