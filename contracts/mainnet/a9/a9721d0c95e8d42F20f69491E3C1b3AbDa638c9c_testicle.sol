// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract NFTProxy {
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}

    function balanceOf(address owner) public view virtual returns (uint256) {}

    function howManyBorp() public view virtual returns (uint256) {}
}

contract testicle {

    address private constant borpacassoAddress =
        0x370108CF39555e561353B20ECF1eAae89bEb72ce;
    address private constant borpiAddress =
        0xeEABfab26ad5c650765b124C685A13800e52B9d2;

    constructor() {
    }

  function borpaInventory(address owner, bool borp, bool page)
        external
        view
        returns (uint256[] memory, uint256)
    {
        //false for Borpacasso, true for Borpi
        address nft;
        borp ? nft = borpiAddress : nft = borpacassoAddress;

        NFTProxy sd = NFTProxy(nft);
        uint256 _loopThrough;
        uint256 _loopFrom;

        if(!page){ //page0
            _loopFrom=1;
                _loopThrough = sd.howManyBorp()/2;
        }else{//page1
        _loopFrom=sd.howManyBorp()/2;
           _loopThrough = sd.howManyBorp();
        }

        uint256 _balance = sd.balanceOf(owner);
        uint256[] memory _tokens = new uint256[](_balance);
        uint256 _index;        

        for (uint256 i = _loopFrom; i < _loopThrough; i++) {            
            if (sd.ownerOf(i) == owner) {
                _tokens[_index] = i;
                _index++;
            }
        }
        return (_tokens, _index);
    }
}