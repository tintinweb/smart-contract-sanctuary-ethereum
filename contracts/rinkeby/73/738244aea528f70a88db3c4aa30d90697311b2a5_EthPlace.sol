/**
 *Submitted for verification at Etherscan.io on 2022-05-13
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

    /** @dev Array of validated colors */
    uint256[] public validatedColors;

    /** @dev Required fee for placing a tile */
    uint256 public transactionFee; 

    /** @dev Grid of tileColors */ 
    bytes2[MATRIX_SIZE][MATRIX_SIZE] public tileColors;

    /** @dev Grid of tileOwners */ 
    address[MATRIX_SIZE][MATRIX_SIZE] public tileOwners;

    /** @dev List of administrators */
    mapping (address=>bool) private admin;

    /** @dev Event for notifying change of status of a tile */
    event ChangeTile(address _from, bytes2 _color, uint256 _x, uint256 _y);

    constructor() public
    {
        transactionFee = 0; 
        admin[msg.sender] = true;

        // Validate initial color set
        validatedColors.push(7143450); // HEX: #6D001A
        validatedColors.push(12451897); // HEX: BE0039
        validatedColors.push(16729344); // HEX: #FF4500
        validatedColors.push(16754688); // HEX: #FFA800
        validatedColors.push(16766517); // HEX: #FFD635
        validatedColors.push(16775352); // HEX: #FFF8B8
        validatedColors.push(41832); // HEX: #00A368
        validatedColors.push(52344); // HEX: #00CC78
        validatedColors.push(8318294); // HEX: #7EED56
        validatedColors.push(30063); // HEX: #00756F
        validatedColors.push(40618); // HEX: #009EAA
        validatedColors.push(52416); // HEX: #00CCC0
        validatedColors.push(2379940); // HEX: #2450A4
        validatedColors.push(3576042); // HEX: #3690EA
        validatedColors.push(5368308); // HEX: #51E9F4
        validatedColors.push(4799169); // HEX: #493AC1
        validatedColors.push(6970623); // HEX: #6A5CFF
        validatedColors.push(9745407); // HEX: #94B3FF
        validatedColors.push(8461983); // HEX: #811E9F
        validatedColors.push(11815616); // HEX: #B44AC0
        validatedColors.push(14986239); // HEX: #E4ABFF
        validatedColors.push(14553215); // HEX: #DE107F
        validatedColors.push(16726145); // HEX: #FF3881
        validatedColors.push(16751018); // HEX: #FF99AA
        validatedColors.push(7161903); // HEX: #6D482F
        validatedColors.push(10250534); // HEX: #9C6926
        validatedColors.push(16757872); // HEX: #FFB470
        validatedColors.push(0); // HEX: #000000
        validatedColors.push(5329490); // HEX: #515252
        validatedColors.push(9014672); // HEX: #898D90
        validatedColors.push(13948889); // HEX: #D4D7D9
        validatedColors.push(16777215); // HEX: #FFFFFF
    }


    /** @dev Places a tile on the grid.
      * @param x X coordinate on the grid.
      * @param y Y coordinate on the grid.
      * @param color color hex value.
      */
    function placeTile(uint256 x, uint256 y, bytes2 color) public payable
    {
        require(x < MATRIX_SIZE && y < MATRIX_SIZE, "Invalid coordinates!");
        require(msg.value >= transactionFee, "Invalid ethereum value in transaction!");
        require(isColorValid(color), "Invalid color!");

        tileColors[x][y] = color;

        emit ChangeTile(msg.sender, color, x, y);

       // currentTile.owner = msg.sender; 
    }

    /** @dev Places a tile on the grid without transaction fee requirement for admin only.
      * @param x X coordinate on the grid.
      * @param y Y coordinate on the grid.
      * @param color color hex value.
      */
    function resetTile(uint256 x, uint256 y, bytes2 color) public isAdmin
    {
        require(x < MATRIX_SIZE && y < MATRIX_SIZE, "Invalid coordinates!");
        require(isColorValid(color), "Invalid color!");

        tileColors[x][y] = color;
        emit ChangeTile(msg.sender, color, x, y);
        //currentTile.owner = msg.sender; 
    }

    function bytesToUint(bytes2 b) internal pure returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(uint8(b[i]))*(2**(8*(b.length-(i+1))));
        }
        return number;
    }

    /** @dev Checks if color values are allowed by the contract.
      * @param color color hex value.
      */
    function isColorValid(bytes2 color) public view returns(bool)
    {
        for(uint256 i = 0; i < validatedColors.length; i++)
        {
            if(validatedColors[i] == bytesToUint(color))
            {
                return true;
            }
        }

        return false;
    }

    /** @dev Gets tile at provided coordinates.
      * @param x X coordinate.
      * @param y Y coordinate.
      */
    function getTileColor(uint256 x, uint256 y) public view returns(bytes2)
    {
        require(x < MATRIX_SIZE && y < MATRIX_SIZE, "Invalid coordinates!");

        return tileColors[x][y];
    }

     /** @dev Changes tile placement fee.
      * @param fee new fee value.
      */
    function changeFee(uint256 fee) public isAdmin
    {
        transactionFee = fee;
    }

    /** @dev Get all tileColors */
    function getAllTileColors() public view returns(bytes1[62500] memory)
    {
        bytes1[62500] memory toSend;



 
        return toSend;
    }

      /** @dev Get all valid colors */
    function getAllColors() public view returns(uint256[] memory) {
        return validatedColors;
    }

    /** @dev Adds a new color to validated color array.
      * @param color color hex value.
      */
    function addColor(uint256 color) public isAdmin
    {
        validatedColors.push(color);
    }

     /** @dev Removes a color from validated color array.
      * @param color color hex value.
      */
    function removeColor(uint256 color) public isAdmin
    {
         for(uint256 i = 0; i < validatedColors.length; i++)
        {
            if(validatedColors[i] == color)
            {
                delete validatedColors[i];
                return;
            }
        }
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