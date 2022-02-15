/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  
}

contract SplitPayments {
    address[] public collaborators;
    uint256[] public splits;

    constructor(address[] memory collaborators_, uint256[] memory splits_) {
        for(uint8 i=0; i<collaborators_.length; i++) {
            collaborators.push(collaborators_[i]);
            splits.push(splits_[i]);
        }
    }

    function buy1(address token_, address user_, uint256 amount_) external returns(bool) {
        uint256 allowance = IERC20(token_).allowance(user_, address(this));
        require(allowance >= amount_, "Not enough allowance");
        IERC20(token_).transferFrom(user_, address(this), amount_);
        for(uint8 i=0; i<collaborators.length; i++) {
            uint256 currentAmount = amount_ * splits[i] / 100;
            IERC20(token_).transfer(collaborators[i], currentAmount);
        }
        return true;
    }

    function buy2(address token_, address user_, uint256 amount_) external returns(bool) {
        uint256 allowance = IERC20(token_).allowance(user_, address(this));
        require(allowance >= amount_, "Not enough allowance");
        IERC20(token_).transferFrom(user_, address(this), amount_);
        return true;
    }
}