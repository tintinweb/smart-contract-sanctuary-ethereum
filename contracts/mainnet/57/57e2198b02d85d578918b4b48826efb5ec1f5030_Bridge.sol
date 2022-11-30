/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

// SPDX-License-Identifier: MIT
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

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Bridge is Ownable {
    event BridgeEvent(address recievedFromAddress, uint256 recievedAmount, string sendChain, string sendToAddress, string grossRate, string maxSlippage);

    function withdrawTo(address payable reciever, uint256 amount) external onlyOwner returns(bool) {
        reciever.transfer(amount);
        return true;
    }

    function withdrawTokenTo(address contractAddress, address payable reciever, uint256 amount) external onlyOwner returns(bool) {
        IERC20 tokenContract = IERC20(contractAddress);
        tokenContract.transfer(reciever, amount);
        return true;
    }

    function bridgeTo(string memory sendChain, string memory sendToAddress, string memory grossRate, string memory maxSlippage) external payable returns (bool){
        emit BridgeEvent(msg.sender, msg.value, sendChain, sendToAddress, grossRate, maxSlippage);
        return true;
    }
}