/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

struct Pixel {
    uint256 x;
    uint256 y;
    uint256 lockedUntil;
    uint256 colorCode;
    address rentedBy;
}

contract PixelsToRent {
    uint256 public maxX;
    uint256 public maxY;
    address owner;
    uint256 cost;
    bool rentingStart;
    mapping(uint256 => mapping(uint256 => Pixel)) public pixels;

    constructor
    () {
        owner = msg.sender;
        setX(100);
        setY(100);
        rentingStart = false;
    }

    function mint(uint256[] memory _x, uint256[] memory _y) public {
        require (_x.length == _y.length);
        for (uint256 x = 0; x < _x.length; x++) {
            for (uint256 y = 0; x < _y.length; y++) {
                pixels[x][y] = Pixel(x, y, 0, 0, msg.sender);
            }
        }
    }

    function setX(uint256 _x) public {
        maxX = _x;
    }
    function setY(uint256 _y) public {
        maxY = _y;
    }
}