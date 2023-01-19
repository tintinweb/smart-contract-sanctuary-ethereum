/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
interface ID4AProtocolClaim{
  function claimProjectERC20Reward(bytes32 _project_id) external returns(uint256);
  function claimProjectERC20RewardWithETH(bytes32 _project_id) external returns(uint256);
  function claimCanvasReward(bytes32 _canvas_id) external returns(uint256);
  function claimCanvasRewardWithETH(bytes32 _canvas_id) external returns(uint256);
}

contract D4AClaimer{
    ID4AProtocolClaim protocol;
    constructor(address _protocol){
      protocol = ID4AProtocolClaim(_protocol);
    }

    function claimMultiReward(bytes32[] memory canvas, bytes32[] memory projects) public returns (uint256){
      uint256 amount;
      if (canvas.length > 0){
        for (uint i = 0; i < canvas.length; i++){
          amount += protocol.claimCanvasReward(canvas[i]);
        }
      }
      if (projects.length > 0){
        for (uint i = 0; i < projects.length; i++){
          amount += protocol.claimProjectERC20Reward(projects[i]);
        }
      }
      return amount;
    }

    function claimMultiRewardWithETH(bytes32[] memory canvas, bytes32[] memory projects) public returns (uint256){
      uint256 amount;
      if (canvas.length > 0){
        for (uint i = 0; i < canvas.length; i++){
          amount += protocol.claimCanvasRewardWithETH(canvas[i]);
        }
      }
      if (projects.length > 0){
        for (uint i = 0; i < projects.length; i++){
          amount += protocol.claimProjectERC20RewardWithETH(projects[i]);
        }
      }
      return amount;
    }


}