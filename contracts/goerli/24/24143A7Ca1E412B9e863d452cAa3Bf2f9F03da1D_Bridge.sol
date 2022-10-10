/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

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

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

contract Bridge is Ownable {
    event BridgeEvent(address recievedFromAddress, uint256 recievedAmount, string sendChain, string sendToAddress, string grossRate, string maxSlippage);

    function withdrawTo(address payable reciever, uint256 amount) external onlyOwner returns(bool) {
        reciever.transfer(amount);
        return true;
    }

    function bridgeTo(string memory sendChain, string memory sendToAddress, string memory grossRate, string memory maxSlippage) external payable returns (bool){
        emit BridgeEvent(msg.sender, msg.value, sendChain, sendToAddress, grossRate, maxSlippage);
        return true;
    }
}