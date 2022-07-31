// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import './ERC721A.sol';
import './Ownable.sol';

contract TamboHouses is ERC721A, Ownable {
    using Strings for uint256;
    string public _tambohouseURI;
    uint256 public tambohouse = 6000;
    uint256 public price = 0.05 ether;
    uint256 public max_per_wallet = 50;

    constructor() ERC721A("TamboHouses", "PPQH") {
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return _tambohouseURI;
    }

    function tambohouseLink(string memory parts) external onlyOwner {
        _tambohouseURI = parts;
    }

    function morePerWallet(uint256 newMax ) external onlyOwner {
        max_per_wallet = newMax;
    }


     function UpdatePrice(uint256 nowprice) external onlyOwner {
        price = nowprice;
    }

    function updatePrices(uint256 supply) public pure returns(uint256 _cost){
        if (supply >= 0 && supply <= 999) {
            return 0.055 ether;
        } else if (supply > 999 && supply <= 2999) {
            return 0.06 ether;
        } else if (supply > 2999 && supply <= 4999) {
           return 0.065 ether;
        } else if (supply > 4999) {
           return 0.07 ether;
        }
    }


    function HouseofOwner(address addr) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }


    function getHouse(uint256 _amount) public payable {
        uint256 supply = totalSupply();
        uint256 price = updatePrices(supply);
        require((balanceOf(msg.sender) + _amount) <= max_per_wallet, "You exceed the Tambo minting per wallet");
        require( _amount > 0 && _amount <= max_per_wallet, "Too many mints at once" );
        require( supply + _amount <= tambohouse,  "Can't mint more than max supply" );
        require( msg.value == price * _amount, "Wrong amount of ETH sent" );
        require( msg.value >= updatePrices(supply) * _amount, "Not enough funds to mint ");
        _safeMint(msg.sender, _amount);
    }
}