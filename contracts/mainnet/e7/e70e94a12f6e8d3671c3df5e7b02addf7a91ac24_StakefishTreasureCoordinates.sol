pragma solidity 0.8.11;


/*
 * Congratulations on solving the first level of the puzzle!
 */
contract StakefishTreasureCoordinates {
    uint256 private _x;
    uint256 private _y;
    address private owner;

    constructor() public {
        owner = msg.sender;
        _x = 616;
        _y = 107;
    }

    function getTreasureCoordinates() public view returns (uint256, uint256) {
        return (_x, _y);
    }

    function setTreasureCoordinates(uint256 x, uint256 y) public onlyOwner {
      _x = x;
      _y = y;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner allowed.");
        _;
    }
}