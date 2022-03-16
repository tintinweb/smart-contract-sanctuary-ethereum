/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

pragma solidity ^0.8.0;


contract A {
/*
    constructor(
        string memory _bName,
        uint256 _bQuantity
    ) public {
        B contractB = new B(_bName, _bQuantity);
    }
*/
    uint256 public user;

    function setUser(uint256 _user) public {
        user  =_user;
    }

    function createChildContract(string memory _name, uint256 _quantity, bool _isERC721) public returns(B newContract){
        return new B(_name, _quantity, _isERC721);
    }
}


contract B {
    string public name;
    uint256 public quantity;
    bool public isERC721;
    uint256 public testValue = 123;

    constructor (
        string memory _name,
        uint256 _quantity,
        bool _isERC721
    ) public {
        name = _name;
        quantity = _quantity;
        isERC721 = _isERC721;
    }
}