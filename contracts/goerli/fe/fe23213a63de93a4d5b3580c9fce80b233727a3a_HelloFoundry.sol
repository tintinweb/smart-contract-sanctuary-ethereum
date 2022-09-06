// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract HelloFoundry {
    uint256 public number;
    string private _hello;
    bool public _isYes;
    address private _owner;
    uint256 public _count = 0;

    mapping ( address => uint256 ) private _ownerOf;
    mapping ( uint256 => address ) private _tokenOf;

    modifier onlyOwner (){
        require( _owner == msg.sender, " You are not owner!! ");
        _;
    }
    constructor () {
        _owner = msg.sender;
    }

    function getCnt() public view returns (uint256) {
        return _count;
    }

    function ownerMint( address to, uint256 tokenID ) public onlyOwner {
        _ownerOf[ to ] = tokenID;
    }

    function getTokenIdOf( uint256 tokenID ) public view returns ( address ) {
        return _tokenOf[ tokenID ];
    }

    function mint( address to, uint256 tokenID ) internal {
        _ownerOf[ to ] = tokenID;
        _tokenOf[ tokenID ] = to;
    }

    function publicMint() public {
        mint( msg.sender, _count++ );
    } 

    function setOwner( address newOwner ) public onlyOwner {
        _owner = newOwner;
    }

    function getOwner() public view returns ( address ) {
        return _owner;
    }
    function isYes() public view returns (bool) {
        return _isYes;
    }

    function setYes( bool yesNO) public {
        _isYes = yesNO;
    }
    function getHello() public view returns( string memory ) {
        return _hello;
    }

    function setHello( string memory str ) public {
        _hello = str;
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}