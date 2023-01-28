// SPDX-License-Identifier: MIT
/// @Creator @PaisanoDao

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNKkxkkKXNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNKxoooxKXl....lK0ollldKNNNNNNNNNNNNNNNN    //
//    XNNXNNNNNNNNNNNNNNNNXx'...,kXc....cKx'...,kNNNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNNNXkllokXx'...,kXc....cKx....,kNNNNNNNNNNXNNXNN    //
//    NNNNNNNNNNNNNN0;...cKx'...,kXc....cKx....,kNNNNNNNNNNNNNNNN    //
//    XNNXNNNNNNNNNN0;...cKx'...,kXc....cKx....,kNNNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNNN0;...c0x'...,kXc....cKx....,kNNNNNNNNNNXNNXNN    //
//    NNNNNNNNNNNNNN0:...lKx'...,kXl....cKx....,kNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNXOxxx0Xk'...,kXkc::ckX0o:::o0NNNNNNNNNNNNNNNN    //
//    XNNXNNNNNNNNKxlllllxKKxdodx0KK0000KKK00000KXNNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNO;.....,dOOOKNNk:''''''''''''',dXNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNO;..........lKXd'..............lXNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNO;..........:KN0xoooooooooo:...lXNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNO;..........;kOOO0KNNK0OO0Ol...lXNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNKo,..............'oXXo'........lXNNNNNNNNXNNXNN    //
//    NNNNNNNNNNNNNXO;..............:kO:.........lXNNNNNNNNNNNNNN    //
//    XNNXNNNNNNNNNN0;...........................lXNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNNN0:...........................oXNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNNNX0kkx;..................:xkkOKNNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNNNNNNNXl..................lXNNNNNNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNNNNNNNKl..................lXNNNNNNNNNNNNNXNNXNN    //
//    NNNNNNNNNNNNNNNNNNXd,'''''''''''''''',dXNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNXK0000000000000000KXNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.17;

contract Azkaban {
    string name;

    address owner;

    bool public locked;

    mapping(address => bool) admins;

    mapping(address => bool) blacklist;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }

    modifier noReentrancy() {
        require(!locked, "No reentrancy");

        locked = true;
        _;
        locked = false;
    }

    constructor(string memory _name) {
        owner = msg.sender;

        name = _name;

        admins[msg.sender] = true;
    }

    function changeOwner(address _newOwner)
        public
        onlyOwner
        noReentrancy
        validAddress(_newOwner)
    {
        owner = _newOwner;
    }

    function setAdmin(address newAdmin)
        public
        onlyOwner
        noReentrancy
        validAddress(newAdmin)
    {
        admins[newAdmin] = true;
    }

    function unsetAdmin(address oldAdmin)
        public
        onlyOwner
        noReentrancy
        validAddress(oldAdmin)
    {
        require(oldAdmin != owner, "Owner can't unset himself as Admin");

        admins[oldAdmin] = true;
    }

    function addAddress(address newPrisoner)
        public
        onlyAdmin
        noReentrancy
        validAddress(newPrisoner)
    {
        blacklist[newPrisoner] = true;
    }

    function removeAddress(address oldPrisoner)
        public
        onlyAdmin
        noReentrancy
        validAddress(oldPrisoner)
    {
        blacklist[oldPrisoner] = false;
    }

    function checkAddress(address prisoner)
        public
        view
        validAddress(prisoner)
        returns (bool)
    {
        return blacklist[prisoner];
    }
}