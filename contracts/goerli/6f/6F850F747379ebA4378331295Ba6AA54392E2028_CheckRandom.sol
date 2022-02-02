// contracts/CheckRandom.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CheckRandom{
    bytes32 internal ketchup;

    constructor(){
    }

    //Modifiers but as functions. Less Gas
    function isPlayer() internal {    
        uint256 size = 0;
        address acc = msg.sender;
        assembly { size := extcodesize(acc)}
        require((msg.sender == tx.origin && size == 0));
        ketchup = keccak256(abi.encodePacked(acc, block.coinbase));
    }

    function checkRoll(uint256 level) public{
        isPlayer();
        uint256 levelTier = level == 100 ? 5 : uint256((level/20) + 1);
        uint16  chance = uint16(_randomize(_rand(), "Weapon", levelTier)) % 100;
        require(chance > 80, "Did not hit desired outcome outcome");
    }

    function _randomize(uint256 ran, string memory dom, uint256 ness) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(ran,dom,ness)));}

    function _rand() internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp, block.basefee, ketchup)));}
    

}