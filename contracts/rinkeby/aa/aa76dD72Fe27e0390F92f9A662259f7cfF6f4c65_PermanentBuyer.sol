// SPDX-License-Identifier: MIT
// File: contracts/PermanentBuyer.sol



pragma solidity ^0.8.4;


//This contract buys permanent pixels from PPfinance.
//Since if transaction to previous owner fails that pixel is never be buyable. Therefore, if last owner is a contract which has no fallback function or selfdestruct()ed. Pixel will never be buyable.
//Also owner of the pixel can use it as bank. He can transfer token to contract in that time it will not buyable and transfer himself again and sell it. User can control state of buyability of the token.
//I can transfer back tokens and remove perm word pixels if you want. You can use message function to say something.
//I liked the project by the way. I was wanting to build something like this too.
//Have a nice day!

interface PixelContract {
        function purchasePixel(uint tokenId, Color memory userColor) external payable;
        function transferFrom(address from, address to, uint256 tokenId) external;
        function calculatePixelPrice(uint tokenId) external view returns(uint);
}

 struct Color {
    uint8 r;
    uint8 g;
    uint8 b;
  }


contract PermanentBuyer {

    address owner = msg.sender;
    PixelContract pixelC;
    string[] public messages;

    function message( string calldata messageData ) external {
        messages.push( messageData );
    }

    modifier onlyOwner {
        require( msg.sender == owner );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addContractBalance() external payable {

    }

    function setContractAddress( address contractAddress ) external onlyOwner {
        pixelC = PixelContract( contractAddress );
    }

    function buyPixels() public onlyOwner {
        uint16[45] memory pixels = [5120, 5121, 5122, 5124, 5125, 5126, 5128, 5129, 5130, 5132, 5136, 5220, 5222, 5224, 5228, 5230, 5232, 5233, 5235, 5236, 5320, 5321, 5322, 5324, 5325, 5326, 5328, 5329, 5332, 5334, 5336, 5420, 5424, 5428, 5429, 5432, 5436, 5520, 5524, 5525, 5526, 5528, 5530, 5532, 5536];
        uint length = pixels.length;
        Color memory color = Color( 128, 128, 128 );
        for( uint i = 1; i < length; i++ ) {
            uint current = pixels[i];
            uint price = pixelC.calculatePixelPrice( current );
            pixelC.purchasePixel{value: price}( current, color );
        }
    }

    function buyPixelTest() external onlyOwner {

        Color memory color = Color( 128, 128, 128 );
        uint current = 5120;
        uint price = pixelC.calculatePixelPrice( current );
        pixelC.purchasePixel{value: price}( current, color );
        

    }

    function transferAllPixelsToOwner() external onlyOwner {
        uint16[45] memory pixels = [5120, 5121, 5122, 5124, 5125, 5126, 5128, 5129, 5130, 5132, 5136, 5220, 5222, 5224, 5228, 5230, 5232, 5233, 5235, 5236, 5320, 5321, 5322, 5324, 5325, 5326, 5328, 5329, 5332, 5334, 5336, 5420, 5424, 5428, 5429, 5432, 5436, 5520, 5524, 5525, 5526, 5528, 5530, 5532, 5536];
        uint length = pixels.length;
        for( uint i = 1; i < length; i++ ) { // index 0 is for test
            uint current = pixels[i];
            pixelC.transferFrom( address(this), owner, current );
        }
    }

    function transferPixel( uint id ) external onlyOwner {
        pixelC.transferFrom( address(this), owner, id );
    }
    



    

}