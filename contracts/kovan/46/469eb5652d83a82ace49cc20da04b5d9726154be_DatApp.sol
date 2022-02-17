/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract DatApp {
    uint256 storedData = 0;

    function transferToMe(
        address _owner,
        address _token,
        uint256 _amount
    ) public {
        ERC20(_token).transferFrom(_owner, address(this), _amount);
    }

    function getBalanceOfToken(address _address) public view returns (uint256) {
        return ERC20(_address).balanceOf(address(this));
    }

    //testing that works

    function set(uint256 _setData) public {
        storedData = _setData;
    }

    function get() public view returns (uint256) {
        return storedData;
    }
}