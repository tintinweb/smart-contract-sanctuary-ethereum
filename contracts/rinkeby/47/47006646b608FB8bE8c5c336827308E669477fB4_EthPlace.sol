/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7.0;

/** @title Ethereum Place. 
  * @author twitter @codemaxwell
  */
contract EthPlace
{
    /** @dev Grid size */
    uint256 constant public MATRIX_SIZE = 500;
    uint256 constant public MATRIX_LINE_LENGTH = 25000;
    uint256 constant public MATRIX_LINE_COUNT = 10;

    /** @dev Required fee for placing a tile */
    uint256 public transactionFee; 

    /** @dev Grid of tileColors */ 
    bytes1[MATRIX_LINE_LENGTH][MATRIX_LINE_COUNT] public tileColors;

    /** @dev Grid of tileOwners */ 
    address[MATRIX_LINE_LENGTH][MATRIX_LINE_COUNT] public tileOwners;

    /** @dev List of administrators */
    mapping (address=>bool) private admin;

    /** @dev Event for notifying change of status of a tile */
    event ChangeTile(address indexed _from, bytes1 _color, uint256 indexed _x, uint256 indexed _y);

    constructor() public
    {
        transactionFee = 0; 
        admin[msg.sender] = true;
    }


    /** @dev Places a tile on the grid.
      * @param x X coordinate on the grid.
      * @param y Y coordinate on the grid.
      * @param color color hex value.
      */
    function placeTile(uint256 x, uint256 y, bytes1 color) public payable
    {
        require(x < MATRIX_SIZE && y < MATRIX_SIZE, "Invalid coordinates!");
        require(msg.value >= transactionFee, "Invalid ethereum value in transaction!");

        (uint256 line, uint256 number) = calculateCoordinateLocation(x, y);


        tileColors[line][number] = color;
        tileOwners[line][number] = msg.sender;

        emit ChangeTile(msg.sender, color, x, y);
    }

    /** @dev Places a tile on the grid without transaction fee requirement for admin only.
      * @param x X coordinate on the grid.
      * @param y Y coordinate on the grid.
      * @param color color hex value.
      */
    function resetTile(uint256 x, uint256 y, bytes1 color) public isAdmin
    {
        require(x < MATRIX_SIZE && y < MATRIX_SIZE, "Invalid coordinates!");

        (uint256 line, uint256 number) = calculateCoordinateLocation(x, y);

        tileColors[line][number] = color;
        tileOwners[line][number] = msg.sender;

        emit ChangeTile(msg.sender, color, x, y);
    }


    /** @dev Calculates the location of 2d coordinate on 1d array */
    function calculateCoordinateLocation(uint256 x, uint256 y) public pure returns(uint256 line, uint256 number)
    {
        uint256 index = x + MATRIX_SIZE * y;
        uint256 lineNumber = index / MATRIX_LINE_LENGTH;
        uint256 lineIndex = index - (lineNumber * MATRIX_LINE_LENGTH);
        return (lineNumber, lineIndex);
    }

    /** @dev Gets tile at provided coordinates.
      * @param x X coordinate.
      * @param y Y coordinate.
      */
    function getTileColor(uint256 x, uint256 y) public view returns(bytes1)
    {
        (uint256 line, uint256 number) = calculateCoordinateLocation(x, y);

        return tileColors[line][number];
    }

     /** @dev Changes tile placement fee.
      * @param fee new fee value.
      */
    function changeFee(uint256 fee) public isAdmin
    {
        transactionFee = fee;
    }

    /** @dev Get all tileColors */
    function getAllTileColors(uint256 index) public view returns(bytes1[MATRIX_LINE_LENGTH] memory)
    {
        return tileColors[index];
    }

    /** @dev Transfers collected fees to sender address. */
    function retrieveFunds() public isAdmin
    {
        payable(msg.sender).transfer(address(this).balance);
    }


    fallback() external payable {}

    modifier isAdmin(){
        require(admin[msg.sender]);
        _;
    }
}