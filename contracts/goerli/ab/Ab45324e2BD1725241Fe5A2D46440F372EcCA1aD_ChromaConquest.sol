// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract ChromaConquest {

  //maximum number of hex tiles in the game
  uint256 constant public totalHexes = 124;
  
  //struct storing data for each hex tile
  struct Hex {
    string hexId;
    string row;
    string col;
    uint256 valueOfRed;
    uint256 valueOfGreen;
    uint256 valueOfBlue;
    uint8[3] rgbOfHex;
  }

//array storing sructs for all hex tiles
  Hex[] hexes;

//mapping of hex structs to strings for easier user interfacing via hex tile ID as a string
  mapping(string => Hex) public tile;

//enum identifying each color channel of the RGB color space
  enum Channel{
    Red,
    Green,
    Blue
  }

//enum identifying which direction users will push a particular color value
  enum Direction{
    Increment,
    Decrement
  }

  constructor () {

    //adds Hex structs to the array
    hexes.push(Hex('A0', 'A', '0', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('A1', 'A', '1', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('A2', 'A', '2', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('A3', 'A', '3', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('A4', 'A', '4', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('A5', 'A', '5', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('A6', 'A', '6', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('B0', 'A', '0', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('B1', 'B', '1', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('B2', 'B', '2', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('B3', 'B', '3', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('B4', 'B', '4', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('B5', 'B', '5', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('B6', 'B', '6', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('B7', 'B', '7', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('C0', 'C', '0', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('C1', 'C', '1', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('C2', 'C', '2', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('C3', 'C', '3', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('C4', 'C', '4', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('C5', 'C', '5', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('C6', 'C', '6', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('C7', 'C', '7', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('C8', 'C', '8', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('D0', 'D', '0', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('D1', 'D', '1', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('D2', 'D', '2', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('D3', 'D', '3', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('D4', 'D', '4', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('D5', 'D', '5', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('D6', 'D', '6', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('D7', 'D', '7', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('D8', 'D', '8', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('D9', 'D', '9', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('E0', 'E', '0', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('E1', 'E', '1', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('E2', 'E', '2', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('E3', 'E', '3', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('E4', 'E', '4', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('E5', 'E', '5', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('E6', 'E', '6', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('E7', 'E', '7', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('E8', 'E', '8', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('E9', 'E', '9', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('E10', 'E', '10', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('F0', 'F', '0', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('F1', 'F', '1', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('F2', 'F', '2', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('F3', 'F', '3', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('F4', 'F', '4', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('F5', 'F', '5', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('F6', 'F', '6', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('F7', 'F', '7', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('F8', 'F', '8', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('F9', 'F', '9', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('F10', 'F', '10', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('F11', 'F', '11', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('G0', 'G', '0', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('G1', 'G', '1', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('G2', 'G', '2', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('G3', 'G', '3', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('G4', 'G', '4', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('G5', 'G', '5', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('G6', 'G', '6', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('G7', 'G', '7', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('G8', 'G', '8', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('G9', 'G', '9', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('G10', 'G', '10', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('G11', 'G', '11', 127, 127, 127, [127, 127, 127]));
    hexes.push(Hex('G12', 'G', '12', 127, 127, 127, [127, 127, 127]));

    //maps all of the hex tile structs in the array to the hexes string mapping
    initializeMap();

  }

  function initializeMap () public {
      for (uint i = 0; i < hexes.length; i++) {
        // Set the value in the tile mapping for the current hex ID to the current hex object
        tile[hexes[i].hexId] = hexes[i];
      }
  }
  
  //helper function to check the values within the struct of any specific hex tile via its hexId
  function getHex (string memory _tile) public view returns (string memory, string memory, string memory, uint, uint, uint) {
    
    return (
      tile[_tile].hexId, 
      tile[_tile].row, 
      tile[_tile].col, 
      tile[_tile].valueOfRed, 
      tile[_tile].valueOfGreen, 
      tile[_tile].valueOfBlue);
  }

  /*The primary gameplay function for the game.
  Needs to be tokengated with an onlyOwner function modifier which checks 
  if the caller own a player NFT.  Will also add a cooldown function modifier to 
  prevent spamming the function.
  Finally, need to add event emitters so the results sync with the user interface and game map.
  */ 
  function changeRGB(string memory _tile, Channel _channel, Direction _direction) public {
    Channel channel = _channel;
    Direction direction = _direction;
    Hex storage Tile = tile[_tile];

    if (channel == Channel.Red) {
      if (direction == Direction.Increment) {
        // increment red
        ++Tile.valueOfRed;
        ++Tile.rgbOfHex[0];
      } else {
        // decrement red
        --Tile.valueOfRed;
        --Tile.rgbOfHex[0];
      }
    } else if (channel == Channel.Green) {
      if (direction == Direction.Increment) {
        // increment green
        ++Tile.valueOfGreen;
        ++Tile.rgbOfHex[1];
      } else {
        // decrement green
        --Tile.valueOfGreen;
        --Tile.rgbOfHex[1];
      }
    } else if (channel == Channel.Blue) {
      if (direction == Direction.Increment) {
        // increment blue
        ++Tile.valueOfBlue;
        ++Tile.rgbOfHex[2];
      } else {
        // decrement blue
        --Tile.valueOfBlue;
        --Tile.rgbOfHex[2];
      }
    }
  }
}