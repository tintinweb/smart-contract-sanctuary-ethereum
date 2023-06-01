pragma solidity ^0.8.9;


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

interface IMemberList {
    event MemberAdded(address indexed account);
    event MemberRemoved(address indexed account);

    function addMember(address account) external;

    function removeMember(address account) external;

    function member(address account) external view returns (bool);
}

contract MemberList is IMemberList, Ownable {
  mapping(address => bool) public member;

  function addMember(address account) external onlyOwner {
    require(!member[account], "MemberList: Address is a member");
    member[account] = true;
    emit MemberAdded(account);
  }

  function removeMember(address account) external onlyOwner {
    require(member[account], "MemberList: Address is not a member");
    member[account] = false;
    emit MemberRemoved(account);
  }
}