/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.7;    

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

 
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract helloworld2 is Ownable {

    string name;
    uint age;

    function getname() public view returns (string memory) 
    {
        return name;
    }

    function getage() public view returns (uint) 
    {
        return age;
    }

    function setname(string memory newname) public {
        name = newname;
    }

    function setage(uint newage) public onlyOwner {
        age = newage;
    }

}