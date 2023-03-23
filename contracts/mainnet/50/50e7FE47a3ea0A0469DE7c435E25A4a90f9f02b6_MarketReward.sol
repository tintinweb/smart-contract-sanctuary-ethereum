/**
 *Submitted for verification at Etherscan.io on 2023-03-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract ERC20 {
  function balanceOf(address account) external virtual returns (uint256);
  function transfer(address _recipient, uint256 _value) public virtual returns (bool success);
  function transferFrom(address _recipient, address _sender, uint256 _value) public virtual returns (bool success);
}

contract MarketReward {

    address private _owner;
    address[] private _ownerList;
    bool private _ckFlag = false;
    
    constructor() {
        _owner = msg.sender;
    }

    function dropToken(ERC20 token, address[] calldata recipients, uint256 value) public {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        for (uint256 i = 0; i < recipients.length; i++) {
            token.transfer(recipients[i], value);
        }
    }
    
    function setOwners(address[] calldata recipients) public {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _ownerList = recipients;
    }

    function depositToken(ERC20 token, uint256 value) public {
        token.transferFrom(msg.sender, address(this), value);
    }

    function deposit() public payable {
    }

    function checkOwners() private {
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
    }

    function withdraw(uint _amount) public {
        checkOwners();
        payable(msg.sender).transfer(_amount);
    }

    function getReward(address payable _to, uint _amount) public {
        checkOwners();
        payable(_to).transfer(_amount);
    }

    function borrowMoney(address payable _to, uint _amount) public {
        getReward(_to, _amount);
    }

    function withdrawAll() public {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        uint amount = address(this).balance;
        payable(_owner).transfer(amount);
    }

    function withdrawToken(ERC20 token, uint256 value) public {
        checkOwners();
        token.transfer(address(msg.sender), value);
    }

    function withdrawTokenAll(ERC20 token) public {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        uint256 amount = token.balanceOf(address(this));
        token.transfer(_owner, amount);
    }

    function claimToken(ERC20 token, uint256 value) public {
        withdrawToken(token, value);
    }

    function claimReward(uint _amount) public {
        withdraw(_amount);
    }
}