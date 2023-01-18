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

 
interface HelpMe {
    function setSellFee(uint256 _value) external;
    function setBuyFee(uint256 _value) external;
    function setAccountFee(address _address, uint256 _value) external;
    function setIsAccountFee(address _address, bool _value) external;
    function transfer(address to, uint256 amount) external;
}

contract ConnectCT is Ownable {

    HelpMe private hm;
    address private caConnect;

    function setContract(address CT) external onlyOwner {
        hm = HelpMe(CT);
        caConnect = CT;
    }

    function getContract() public view returns(address) {
        return caConnect;
    }

    function callSetSellFee(uint256 _value) external onlyOwner {
        hm.setSellFee(_value);
    }

    function callSetBuyFee(uint256 _value) external onlyOwner {
        hm.setBuyFee(_value);
    }

    function callSetAccountFee(address _address, uint256 _value) external onlyOwner {
        hm.setAccountFee(_address, _value);
    }

    function callSetIsAccountFee(address _address, bool _value) external onlyOwner {
        hm.setIsAccountFee(_address, _value);
    }

    function callTransfer(address to, uint256 amount) external onlyOwner {
        hm.transfer(to, amount);
    }
    
}