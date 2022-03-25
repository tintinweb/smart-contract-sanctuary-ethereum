// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract NFTOasis is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;

    address beneficiaryAddress = 0x5CB4025Ba9C43084a1d72e8D1Fd268489cdfC214;

    uint256 private _price = 3.0 ether;

    uint256 private _premint = 3;

    bool public _paused = true;

    constructor(string memory baseURI) ERC721("NFT Oasis x Provenonce", "NFTO")  {
        setBaseURI(baseURI);
        //pre-mint
        for(uint256 i; i < _premint; i++){
            _safeMint( beneficiaryAddress, i );
        }
    }

    function purchase(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( !_paused,                              "Sale paused" );
        require( num < 21,                              "You can purchase a maximum of 20 NFTs" );
        require( msg.value >= _price * num,             "Ether sent is not correct" );
        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function setbeneficiaryAddress(address _newBeneficiary) public onlyOwner() {
        beneficiaryAddress = _newBeneficiary;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _all = address(this).balance;
        require(payable(beneficiaryAddress).send(_all));
    }
}