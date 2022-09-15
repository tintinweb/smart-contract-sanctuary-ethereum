/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.8;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract TPL_place_map {

    event CreatePixel(uint x, uint y);

    uint xLength;
    uint yLength;

    Pixel[5][5] private pixelsAccess;
    
    
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
        string id;
        uint x;
        uint y;
        string hexColor;
        address owner;
    }

    mapping(address => Pixel[]) public ownedPixels;
    mapping (address => uint) ownerPixelCount;


    function _createPixel(uint x, uint y) private {
        // string memory tiret = "-";
        string memory stringId = string(abi.encodePacked(x,' ',y));
        // string memory stringId = Strings.toString(x) + tiret + Strings.toString(y);
        Pixel memory nouveauPixel = Pixel(stringId, x, y, "FFFFFF", msg.sender);
        // pixelToOwner.push(nouveauPixel);
        pixelsAccess[x][y] = nouveauPixel;
        ownedPixels[msg.sender].push(nouveauPixel);
        ownerPixelCount[msg.sender]++;
        emit CreatePixel(x, y);
    }

 
    function getOwnedPixel(address id) public view returns (Pixel[] memory) {
        Pixel[] memory pixelsArray = ownedPixels[id];
        return pixelsArray;
    }

    function isOwnedBy(uint _x, uint _y, address id) public view returns (bool) {
        // Pixel[] memory pixelsArray = ownedPixels[id];
        bool isOwned = false;
        // for(uint i ; i < pixelsArray.length ; i++){
        //     if(pixelsArray[i].x == _x && pixelsArray[i].y == _y){
        //         isOwned = true;
        //     }
        // }
        // return isOwned;
        address owner = pixelsAccess[_x][_y].owner;
        if(owner == id){
            isOwned = true;
        }
        return isOwned;
    }

     function getOwner(uint _x, uint _y) public view returns (address) {
        address owner = pixelsAccess[_x][_y].owner;
        return owner;
    }


    function _buyPixel(uint x, uint y, uint price) internal {
        address buyer = msg.sender;
        address proprietaire = getOwner(x, y); // a effacer
        Pixel memory lePixel = pixelsAccess[x][y];
        // uint index = 9999999;
        Pixel[] memory pixelsArray = ownedPixels[proprietaire];
        // Pixel[] memory newproprietairePixelArray = new Pixel[](pixelsArray.length-1);
        Pixel[] memory newproprietairePixelArray;
        uint compteur = 0;
        for(uint i ; i < pixelsArray.length ; i++){
            // Assert.equal(keccak256(array1)), keccak256(array2));
            // if(pixelsArray[i].id == lePixel.id){
            if(compareStrings(pixelsArray[i].id,lePixel.id) == false){
                newproprietairePixelArray[compteur] = pixelsArray[i];
                compteur++;
            }else{
                delete pixelsArray[i];
            }
        }

        // Proprietaire
        
        // ownedPixels[proprietaire] = newproprietairePixelArray;
        ownerPixelCount[proprietaire]++;

        // Receiver
        ownedPixels[buyer].push(lePixel);
        ownerPixelCount[buyer]++;
    }


    function buyPixel(uint x, uint y) public {
        require(isOwnedBy(x, y, msg.sender) == true);
        uint price = 1;
        _buyPixel(x, y, price);
    }

    function compareStrings(string memory a, string memory b) public view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}