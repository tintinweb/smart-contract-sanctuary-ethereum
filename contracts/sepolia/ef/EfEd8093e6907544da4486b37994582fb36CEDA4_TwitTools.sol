/**
 *Submitted for verification at Etherscan.io on 2023-06-03
*/

/*
    TWIT.TOOLS SUBCRIPTION CONTRACT
    https://twit.tools/
*/


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

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

abstract contract Subscription is Ownable {
    uint256 public ethFee = 1000000000000000000; // 1 ETH
    uint256 public ethFeeLifetime = 1000000000000000000; // 1 ETH
    mapping (address => uint256) public paymentExpire;

    address public feeCollector;

    error FailedEthTransfer();

    constructor() {
        _transferOwnership(_msgSender());
        feeCollector = _msgSender();
    }

 
    function paySubscription(uint256 _period) external payable virtual { 
        if(msg.value != ethFee * _period) revert FailedEthTransfer();
        if(paymentExpire[msg.sender] == 0){
           paymentExpire[msg.sender] = (block.timestamp) + (_period * 30 days); 
        } else {
            paymentExpire[msg.sender] += _period * 30 days;
        }
        
    }

    function paySubscriptionLifetime() external payable virtual { 
        if(msg.value != ethFeeLifetime) revert FailedEthTransfer();
            paymentExpire[msg.sender] = 2000000000; 
    }


    function setEthFee(uint256 _newEthFee) external virtual onlyOwner {
        ethFee = _newEthFee;
    }

    function setEthFeeLifetime(uint256 _newEthFee) external virtual onlyOwner {
        ethFeeLifetime = _newEthFee;
    }

    function setNewPaymentCollector(address _feeCollector) external virtual onlyOwner {
        feeCollector = _feeCollector;
    }

    function withdrawEth() external virtual onlyOwner {
        uint256 _amount = address(this).balance;

        (bool sent, ) = feeCollector.call{value: _amount}("");
        if(sent == false) revert FailedEthTransfer();
    }

}


contract TwitTools is Subscription {
}