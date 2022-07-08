// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

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

contract AddCollectionAddOn is Ownable {
    event AddCollection(address add_);
    mapping(address => bool) public addressAdded;

    function addCollection(address add_) external onlyOwner returns(bool) {
        require(!addressAdded[add_]);
        addressAdded[add_] = true;
        emit AddCollection(add_);
        return true;
    }

    function removeCollection(address add_) external onlyOwner returns(bool) {
        require(addressAdded[add_]);
        addressAdded[add_] = false;
        return true;
    }

    function isAddedCollection(address add_) external view returns(bool) {
        return addressAdded[add_];
    }
}