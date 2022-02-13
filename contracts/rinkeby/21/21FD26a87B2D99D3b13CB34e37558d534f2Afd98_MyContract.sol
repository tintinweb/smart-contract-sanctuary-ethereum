/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;



// Part: IERC20

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
}

// File: payable.sol

contract MyContract {
    event Deposited(address indexed payee, uint256 weiAmount);

    function deposit() public payable {
        emit Deposited(msg.sender, msg.value);
    }

    function withdrawToken(address _tokenContract, uint256 _amount) external {
        IERC20 tokenContract = IERC20(_tokenContract);

        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, _amount);
    }
}