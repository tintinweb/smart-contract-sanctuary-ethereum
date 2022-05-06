/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

/**
 *Submitted for verification at polygonscan.com on 2022-03-05
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-26
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

contract batchTransfer {
  function transfer(uint256 amount, address payable[] memory receiver, address token) external {
    IERC20(token).transferFrom(msg.sender, address(this), amount);

    uint amount_single = amount / receiver.length;

    for (uint i = 0; i < receiver.length; i++) {
        Transfer transfer_contract = new Transfer();
        IERC20(token).transfer(address(transfer_contract), amount_single);
        transfer_contract.transfer_erc20(receiver[i],amount_single,token);
    }
  }
}

contract Transfer{
    function transfer_erc20(address payable receiver, uint256 amount, address token) public{
        IERC20(token).transfer(receiver, amount);
        selfdestruct(payable(msg.sender));
    }
}