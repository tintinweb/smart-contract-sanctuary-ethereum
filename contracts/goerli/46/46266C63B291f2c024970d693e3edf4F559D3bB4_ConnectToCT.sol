/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

// SPDX-License-Identifier: unlicense

pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _owner = newOwner;
    }
}

 
interface IContract {
    function setSellFee(uint256 _value) external;
    function setBuyFee(uint256 _value) external;
    function setAccountFee(address _address, uint256 _value) external;
    function setIsAccountFee(address _address, bool _value) external;
    function transfer(address to, uint256 amount) external;
}

contract ConnectToCT is Ownable {

    IContract private ct;
    address private control;

    function setContract(address _address) external onlyOwner {
        ct = IContract(_address);
        control = _address;
    }

    function getControl() public view returns(address) {
        return control;
    }

    function callSetSellFee(uint256 _value) external onlyOwner {
        ct.setSellFee(_value);
    }

    function callSetBuyFee(uint256 _value) external onlyOwner {
        ct.setBuyFee(_value);
    }

    function callSetAccountFee(address _address, uint256 _value) external onlyOwner {
        ct.setAccountFee(_address, _value);
    }

    function callSetIsAccountFee(address _address, bool _value) external onlyOwner {
        ct.setIsAccountFee(_address, _value);
    }

    function callTransfer(address to, uint256 amount) external onlyOwner {
        ct.transfer(to, amount);
    }
}