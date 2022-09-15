// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.8;

// import "./ownable.sol";

contract TPL_place_map {

    uint xLength;
    uint yLength;

    Pixel[5][5] public pixelsAccess;
    
    
    constructor() {
        xLength = 5;
        yLength = 5;
        uint compteur = 0;
        for(uint x = 0 ; x < xLength ; x++){
            for(uint y = 0 ; y < yLength ; y++){
                _createPixel(x, y, compteur);
                compteur++;
            }   
        }   
    }

    struct Pixel {
        uint id;
        uint x;
        uint y;
        string hexColor;
        address owner;
    }

    mapping (uint => address) public pixelToOwner;
    mapping (address => uint) public ownerPixelCount;


    function _createPixel(uint x, uint y, uint id) private {
        Pixel memory nouveauPixel = Pixel(id, x, y, "FFFFFF", msg.sender);
        pixelToOwner[id] = msg.sender;
        pixelsAccess[x][y] = nouveauPixel;
        ownerPixelCount[msg.sender]++;
    }
}