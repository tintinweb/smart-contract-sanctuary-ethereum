pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

library BackgroundMetadataLibrary {
     function GetBackgroundColorMetadata(uint256 colorInt) public pure returns(string memory){ 
       string memory colorProperty = '{"trait_type":"Background Color", "value":"' ;
       if(colorInt == 0 ) {
            // WHITE
          return string(abi.encodePacked(colorProperty, 'White"}'));
       }
       else if (colorInt == 1) {
            // GRAY
           return string(abi.encodePacked(colorProperty, 'Gray"}'));
       }
       else if(colorInt == 2) {
          //Orange
         return string(abi.encodePacked(colorProperty, 'Orange"}'));
       } 
       else if(colorInt == 3) {
         //Pink
        return string(abi.encodePacked(colorProperty, 'Pink"}'));
       }
       else if(colorInt == 4) {
         //YELLOW
        return string(abi.encodePacked(colorProperty, 'Yellow"}'));
       }
       else if(colorInt == 5) {
         //BRIGHT YELLOW
        return string(abi.encodePacked(colorProperty, 'Bright Yellow"}'));
       }
       else if(colorInt == 6) {
         //Green
        return string(abi.encodePacked(colorProperty, 'Green"}'));
       }
       else if(colorInt == 7) {
         //Blue
        return string(abi.encodePacked(colorProperty, 'Blue"}'));
       }
       else if(colorInt == 8) {
         //Dark Blue
        return string(abi.encodePacked(colorProperty, 'Dark Blue"}'));
       }
       else if(colorInt == 9) {
         //Dark Pink
        return string(abi.encodePacked(colorProperty, 'Dark Pink"}'));
       }
       else if(colorInt == 10) {
         // Black
        return string(abi.encodePacked(colorProperty, 'Black"}'));
       }

      return string(abi.encodePacked(colorProperty, 'None"}'));
     }

     function GetBackgroundTypeMetadata(uint256 backgroundType) public pure returns(string memory){ 
       string memory backgroundTypeProperty = '{"trait_type": "Background Type", "value":"' ;
      // NATURAL WOOD
        if (backgroundType == 10) {
          return string(abi.encodePacked(backgroundTypeProperty, 'Natural Wood"}'));
        }
        else if (backgroundType == 15) {
          //Grey Wood
          return string(abi.encodePacked(backgroundTypeProperty, 'Gray Wood"}'));
        }
        else if (backgroundType == 20) {
          // Basic  Tile
          return string(abi.encodePacked(backgroundTypeProperty, 'Basic Tile"}'));
       }
        else  if (backgroundType == 25) {
          // Cold Alps
          return string(abi.encodePacked(backgroundTypeProperty, 'Cold Alps"}',',{"trait_type": "Hanged", "value":"True"}'));
        }
        else if(backgroundType == 30 ){
            // Alps
          return string(abi.encodePacked(backgroundTypeProperty,'Alps"}',',{"trait_type": "Hanged", "value":"True"}'));
        }
        else if(backgroundType == 3) {
          return string(abi.encodePacked(backgroundTypeProperty, 'Flower"}'));
        }
        else if(backgroundType == 6) {
           return string(abi.encodePacked(backgroundTypeProperty, 'Leaves"}'));
        }
        else if(backgroundType == 12) {
            return string(abi.encodePacked(backgroundTypeProperty, 'Pillow"}'));
        }
        else if(backgroundType == 18) {
            return string(abi.encodePacked(backgroundTypeProperty, 'Rug"}'));
        }
        else if(backgroundType == 24) {
           return string(abi.encodePacked(backgroundTypeProperty, 'Water"}'));
        }
     
        return string(abi.encodePacked(backgroundTypeProperty,'Plain"}'));
     }
}