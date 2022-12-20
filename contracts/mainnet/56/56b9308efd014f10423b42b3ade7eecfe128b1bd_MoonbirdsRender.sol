/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenURIGenerator {
   function artworkURI(uint256 tokenId, uint32 scaleupFactor) external view returns (string memory);
}

abstract contract Ownable {
    address private _owner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
}

// https://etherscan.io/address/0xb1bEfc9E7B76C1e846EBBf3e6E1Ab029C86e7435#readContract
contract MoonbirdsRender is Ownable{

    ITokenURIGenerator public moonbirdGenerator;
    uint32 internal _bmpScale;

    constructor(ITokenURIGenerator _moonbirdGenerator) {
        moonbirdGenerator = _moonbirdGenerator;
        _bmpScale = 12;
    }

    function setBmpScale(uint32 bmpScale_) external onlyOwner {
        _bmpScale = bmpScale_;
    }

    function render(uint256 tokenId) external view returns (bytes memory) {
        string memory img = moonbirdGenerator.artworkURI(tokenId, _bmpScale);
        return abi.encodePacked(
            '<!DOCTYPE html>',
            '<html lang="">',
                '<body>',
                    '<img src="', img, '"/>',
                '</body>',
            '</html>'
        );
    }
}