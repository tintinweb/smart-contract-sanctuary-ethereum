/**
 *Submitted for verification at Etherscan.io on 2022-01-29
*/

/*
 * SPDX-License-Identifier: MIT
 */
 
pragma solidity ^0.8.1;

interface IERC20 {
    function totalSupply() external view  returns (uint256 supply);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract marginHolding {

    bool isSet = false;
    address IRSContract;

    function returnFunds (address address_, address token, uint256 amount) public returns (bool success) {
        require(msg.sender == IRSContract);
        IERC20(token).transferFrom(address(this), address_, amount);
        return true;
    }

    function setIRS (address addr) public {
        require(isSet == false);
        IRSContract = addr;
        isSet = true;
    }
}