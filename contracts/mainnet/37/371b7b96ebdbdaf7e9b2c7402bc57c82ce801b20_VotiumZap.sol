// SPDX-License-Identifier: MIT
// Votium

pragma solidity ^0.8.7;

import "./SafeERC20.sol";

interface Voti {
  function depositBribe(address, uint256, bytes32, uint256) external;
}

contract VotiumZap {

  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

    Voti public voti = Voti(0x19BBC3463Dd8d07f55438014b021Fb457EBD4595);


  /* ========== PUBLIC FUNCTIONS ========== */

    // Deposit zap
    function depositMulti(address _token, bytes32 _proposal, uint256[] calldata _amounts, uint256[] calldata _choiceIndices) public {
      require(_amounts.length == _choiceIndices.length, "Uneven sides");
      uint256 total;
      for(uint256 i; i<_amounts.length; ++i) {
        total += _amounts[i];
      }
      IERC20(_token).safeTransferFrom(msg.sender, address(this), total);
      IERC20(_token).approve(address(voti), total);
      for(uint256 i; i<_amounts.length; ++i) {
        voti.depositBribe(_token, _amounts[i], _proposal, _choiceIndices[i]);
      }
    }


}