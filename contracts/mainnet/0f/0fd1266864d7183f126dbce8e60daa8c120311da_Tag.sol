// SPDX-License-Identifier: none
pragma solidity ^0.8.7;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;}
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
contract Tag is Ownable {
    // event NewTaggedPerson(string name, string tagTime);
    struct tagPerson {
        string name;
        string tagTime;
        string taggedByWho;
    }
    tagPerson[] private tagList;

    function createPerson(string memory _name, string memory _tagTime) public onlyOwner {
        if(tagList.length > 0) {
            tagList.push(tagPerson(_name, _tagTime, tagList[tagList.length-1].name));
        } else {
            tagList.push(tagPerson(_name, _tagTime, "first"));
        }
        
    }
    function getPerson() public view returns (string memory) {
        return tagList[tagList.length-1].name;
    }
}