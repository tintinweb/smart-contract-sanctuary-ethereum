/**
 *Submitted for verification at Etherscan.io on 2023-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);
}

contract NewDistribution  {
  
    IERC20 public token;
    mapping(address =>uint256) public userTotalClaimed;
    mapping(address => uint256) public userClaimAmountGold;
    mapping(address => uint256) public userClaimAmountSilver;
    mapping(address => uint256) public userClaimAmountBronze;

    constructor(address _token){
        token = IERC20(_token);
    }

    function updateGoldTierInfo(
    
        address[] memory recipients,
        uint256[] memory values
    ) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) total += values[i];
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < recipients.length; i++)
        {
            userClaimAmountGold[recipients[i]] = userClaimAmountGold[recipients[i]] + values[i];
        }
    }
  
    function updateSilverTierInfo(
        address[] memory recipients,
        uint256[] memory values
    ) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) total += values[i];
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < recipients.length; i++)
        {
            userClaimAmountSilver[recipients[i]] = userClaimAmountSilver[recipients[i]] + values[i];
        }
    }

    function updateBronzeTierInfo(
        address[] memory recipients,
        uint256[] memory values
    ) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) total += values[i];
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < recipients.length; i++)
        {
            userClaimAmountBronze[recipients[i]] = userClaimAmountBronze[recipients[i]] + values[i];
        }
    }

    function goldTierClaim() external{
        userTotalClaimed[msg.sender] = userTotalClaimed[msg.sender] + userClaimAmountGold[msg.sender];
        token.transfer(msg.sender, userClaimAmountGold[msg.sender]);
        userClaimAmountGold[msg.sender] = 0;
    }

    function silverTierClaim() external{
        userTotalClaimed[msg.sender] = userTotalClaimed[msg.sender] + userClaimAmountSilver[msg.sender];
        token.transfer(msg.sender, userClaimAmountSilver[msg.sender]);
        userClaimAmountSilver[msg.sender] = 0;
    }

    function bronzeTierClaim() external{
        userTotalClaimed[msg.sender] = userTotalClaimed[msg.sender] + userClaimAmountBronze[msg.sender];
        token.transfer(msg.sender, userClaimAmountBronze[msg.sender]);
        userClaimAmountBronze[msg.sender] = 0;
    }

}