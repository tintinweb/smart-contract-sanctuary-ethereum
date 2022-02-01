/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

contract TwentySevenHundredEtherPage {
  struct Pixel {
      address owner;
      uint soldPrice;
      bytes3 color;
  }
  
  Pixel[100][1000] public pixels;
  mapping(address => uint) public pendingRefunds;
  
  event PixelChanged(
      uint x,
      uint y,
      address owner,
      uint soldPrice,
      bytes3 color
   );
    
  function colorPixel(uint x, uint y, bytes3 color) payable public {
    Pixel storage pixel = pixels[x][y];
    require(msg.value > pixel.soldPrice);
    
    if(pixel.owner != address(0x0)) {
        pendingRefunds[pixel.owner] += pixel.soldPrice;
    }
    
    pixel.owner = msg.sender;
    pixel.soldPrice = msg.value;
    pixel.color = color;
    
    emit PixelChanged(x, y, pixel.owner, pixel.soldPrice, pixel.color);
  }
  
  function withdrawRefunds() public {
      address payable payee = msg.sender;
      uint payment = pendingRefunds[payee];
      
      require(payment != 0);
      require(address(this).balance >= payment);
      
      pendingRefunds[payee] = 0;
      require(payee.send(payment));
  }
}