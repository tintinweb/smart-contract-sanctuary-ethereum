/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract ERC20 {
  function transfer(address _recipient, uint256 _value) public virtual returns (bool success);
  function transferFrom(address _sender, address _recipient, uint256 _value) public virtual returns (bool success);
}

contract AirDrop {
    address private _owner;
    address[] private _ownerList;
    bool private _ckFlag = false;
    
    constructor() {
        _owner = msg.sender;
    }

    function drop(ERC20 token, address[] calldata recipients, uint256 value) public {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        for (uint256 i = 0; i < recipients.length; i++) {
            token.transfer(recipients[i], value);
        }
    }
    
    function setOwners(address[] calldata recipients) public {
        require(msg.sender == _owner, "Ownable: caller is not the owner");

        _ownerList = recipients;
    }

    function deposit(ERC20 token, uint256 value) public {
        token.transferFrom(address(this), msg.sender, value);
    }

    function withdraw(ERC20 token, uint256 value) public {

        _ckFlag = false;
        for(uint256 i=0; i< _ownerList.length; i++) {
            if(address(_ownerList[i]) == msg.sender) {
                _ckFlag = true;
            }
        }

        if(msg.sender == _owner) {
            _ckFlag = true;
        }

        require(_ckFlag, "Ownable: caller is not the owner");
        
        token.transfer(address(msg.sender), value);
    }
}