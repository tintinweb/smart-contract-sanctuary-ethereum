/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//Paint Ethereum is a collaborative piece of artwork 

contract PaintEthereum {
    //mapping of pixels, pixels are packed, each pixel is 4 bits representing index
    //of color in colorPalette
    mapping(uint256 => uint256) public pixels;
    //canvas is a square
    uint256 public constant canvasSide = 1000; 
    uint256[16] public colorPalette = [0xffffff, 0xc9c9c9, 0x595959, 0x060606, 0xfcb6d1, 0xff0000, 0xff9100, 0xb55917, 0xffdd00, 0x23db4b, 0x49a800, 0x00cde0, 0x006eeb, 0x0009ff, 0xff61f7, 0xa1008e];

    address public owner;

    uint256 public pixelCost = .0001 ether;

    event PixelChanged(uint256 indexed pixel, uint256 indexed color, address indexed changer);
    event OwnerChanged(address indexed newOwner, address indexed oldOwner);

    constructor() {
        owner = msg.sender;
    }

    function changePixel(uint256 pixel, uint256 colorIndex) public payable {
        require(msg.value >= pixelCost, "Not enough funds");
        require(pixel < canvasSide**2, "Pixel < canvasSide^2");
        require(colorIndex < 16, "0 <= colorIndex < 16");
        unchecked {
            uint256 index = pixel/64;
            uint256 offset = (pixel % 64) * 4;
            pixels[index] =  (pixels[index] & ((2**256-1)  ^ (2**4-1 << offset))) | (colorIndex << offset);
        }
        emit PixelChanged(pixel, colorPalette[colorIndex], msg.sender);
    }

    function getPixelColor(uint256 pixel) public view returns(uint256) {
        uint256 index = pixel / 64;
        uint256 offset = (pixel % 64) * 4;
        uint256 colorIndex = (pixels[index] & (2**4-1 << offset)) >> offset;
        return colorPalette[colorIndex];
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function changePixelCost(uint256 _newCost) public onlyOwner {
        pixelCost = _newCost;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        address _oldOwner = owner; 
        owner = _newOwner;
        emit OwnerChanged(_newOwner, _oldOwner);
    }

    function withdraw() public payable onlyOwner {
        require(payable(owner).send(address(this).balance), "Not Payable");
    }

    function renounceOwnership() public onlyOwner {
        withdraw();
        changePixelCost(0);
        address _oldOwner = owner;
        owner = address(0);
        emit OwnerChanged(owner, _oldOwner);
    }
}