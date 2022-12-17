/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract MultiSender {
  /// @notice Send equal ERC20 tokens amount to multiple contracts
  ///
  /// @param _token The token to send
  /// @param _addresses Array of addresses to send to
  /// @param _amount Tokens amount to send to each address
  function multiTransferTokenEqual2(
    address _token,
    address[] calldata _addresses,
    uint256 _amount
  ) external
  {
    // assert(_addresses.length <= 255);
    // console.log("args %s, address %s, _addresses %s, amountSum %s", msg.sender, address(this), _addresses, _amountSum);

    IERC20 token = IERC20(_token);    
    for (uint8 i; i < _addresses.length; i++) {
      token.transferFrom(msg.sender, _addresses[i], _amount);
    }
  } 
}