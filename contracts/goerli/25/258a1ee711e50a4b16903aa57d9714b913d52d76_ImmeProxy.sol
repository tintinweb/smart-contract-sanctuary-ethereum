/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

abstract contract Ownable {

    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownership Assertion: Caller of the function is not the owner.");
      _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        _owner = newOwner;
    }
}

contract ImmeProxy is Ownable {

    address payable feeWallet;
    uint256 fee;

    event ImmeProxySend(address indexed from, address indexed to, uint256 value);
    event TransferedOwnership(address indexed from, address indexed to);
    event SetNewFee(uint256 indexed value);

    constructor(address payable _feeWallet, uint256 _fee) {
        feeWallet = _feeWallet;
        fee = _fee;
    }

    // Set Fee for transactions. 
    function setFee(uint256 _fee) public onlyOwner returns (bool){
        fee = _fee;
        emit SetNewFee(fee);
        return true;
    }

    // Get Transaction Fee
    function getFee() public view returns (uint256) {
        return fee;
    }

    // Set fee wallet address
    function setFeeWallet(address payable _newFeeWallet) public onlyOwner returns (bool){
        feeWallet = _newFeeWallet;
        emit TransferedOwnership(msg.sender, feeWallet);
        return true;
    }

    // Get Fee wallet address
    function getFeeWallet() public view returns (address) {
        return feeWallet;
    }

    function secureSendEther(address payable _to, uint256 _amount, uint256 _fee) external payable {

        (bool success,) = _to.call{value: _amount}("");
        if (success) {
            (bool successFee,) = feeWallet.call{value: _fee}("");
            require(successFee, "Failed to send Ether");
        }
        require(success, "Failed to send Ether");
        emit ImmeProxySend(msg.sender, _to, _amount);
    }

    function secureSendToken(address tokenAddress, address payable _to, uint256 _value) external payable{        
        (bool successFee,) = feeWallet.call{value: msg.value}("");
        require(successFee, "Failed to send Ether");

        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(msg.sender) >= _value, "Address: insufficient token balance for call");
        require(token.transferFrom(msg.sender, address(this), _value));
        require(token.transfer(_to, _value));
    }
}