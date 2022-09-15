/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract TPL_place_map {

    event CreatePixel(uint x, uint y);

    uint xLength;
    uint yLength;

    // Pixel[100][100] private pixels;
    
    
    constructor() {
        xLength = 5;
        yLength = 5;
        for(uint x = 0 ; x < xLength ; x++){
            for(uint y = 0 ; y < yLength ; y++){
                _createPixel(x, y);
            }   
        }   
    }

    struct Pixel {
        uint x;
        uint y;
        string hexColor;
    }

    mapping(address => Pixel[]) public ownedPixels;
    mapping (address => uint) ownerPixelCount;


    function _createPixel(uint x, uint y) private {
        Pixel memory nouveauPixel = Pixel(x, y, "FFFFFF");
        // pixelToOwner.push(nouveauPixel);
        ownedPixels[msg.sender].push(nouveauPixel);
        ownerPixelCount[msg.sender]++;
        emit CreatePixel(x, y);
    }

 
    function getOwnedPixel(address id) public view returns (Pixel[] memory) {
        Pixel[] memory pixelsArray = ownedPixels[id];
        return pixelsArray;
    }

    function isOwnedBy(uint _x, uint _y, address id) public view returns (bool) {
        Pixel[] memory pixelsArray = ownedPixels[id];
        bool isOwned = false;
        for(uint i ; i < pixelsArray.length ; i++){
            if(pixelsArray[i].x == _x && pixelsArray[i].y == _y){
                isOwned = true;
            }
        }
        return isOwned;
    }


    function _buyPixel(uint x, uint y, address sender, address receiver, uint price) private {
        // Pixel _pixel = pixels[x, y]
    }


    function buyPixel(uint x, uint y, address sender, address receiver) public {
        require(isOwnedBy(x, y, msg.sender) == true);
        uint price = 1;
        _buyPixel(x, y, sender, receiver, price);
    }


    // /**
    //  * @dev Store value in variable
    //  * @param num value to store
    //  */
    // function store(uint256 num) public {
    //     number = num;
    // }

    // /**
    //  * @dev Return value 
    //  * @return value of 'number'
    //  */
    // function retrieve() public view returns (uint256){
    //     return number;
    // }
}