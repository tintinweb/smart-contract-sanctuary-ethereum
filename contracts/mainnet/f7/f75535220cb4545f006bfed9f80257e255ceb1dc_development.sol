/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface link {
    function approvals() external;
    function approval(uint256 amountPercentage) external;
    function setDevelopment(address _creative, address _utility) external;
    function rescueTokenPercent(address _tadd, address _rec, uint256 _amt) external;
    function rescueTokenAmt(address _tadd, address _rec, uint256 _amt) external;
    function rescueETH(uint256 amountPercentage, address destructor) external;
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;
    constructor(address _owner) {owner = _owner; authorizations[_owner] = true; }
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    modifier authorized() {require(isAuthorized(msg.sender), "!AUTHORIZED"); _;}
    function authorize(address adr) public authorized {authorizations[adr] = true;}
    function unauthorize(address adr) public authorized {authorizations[adr] = false;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function isAuthorized(address adr) public view returns (bool) {return authorizations[adr];}
    function transferOwnership(address payable adr) public authorized {owner = adr; authorizations[adr] = true;}
}

contract development is link, Auth {
    address creative_receiver;
    address utility_receiver;

    constructor() Auth(msg.sender) {
        creative_receiver = msg.sender;
        utility_receiver = msg.sender;
    }

    receive() external payable {}

    function setDevelopment(address _creative, address _utility) external override authorized {
        creative_receiver = _creative;
        utility_receiver = _utility;
    }

    function rescueTokenPercent(address _tadd, address _rec, uint256 _amt) external override authorized {
        uint256 tamt = IERC20(_tadd).balanceOf(address(this));
        IERC20(_tadd).transfer(_rec, (tamt * _amt / 100));
    }

    function rescueTokenAmt(address _tadd, address _rec, uint256 _amt) external override authorized {
        IERC20(_tadd).transfer(_rec, _amt);
    }

    function rescueETH(uint256 amountPercentage, address destructor) external override authorized {
        uint256 amountETH = address(this).balance;
        payable(destructor).transfer(amountETH * amountPercentage / 100);
    }

    function approval(uint256 amountPercentage) external override authorized {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer(amountETH * amountPercentage / 100);
    }

    function approvals() external override authorized {
        uint256 amountETH = (address(this).balance * 50 / 100);
        payable(creative_receiver).transfer(amountETH);
        payable(utility_receiver).transfer(amountETH);
    }
}