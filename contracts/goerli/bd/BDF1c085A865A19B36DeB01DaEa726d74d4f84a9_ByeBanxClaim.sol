/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface IByeBanX {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

contract ByeBanxClaim {

    address byeBaxCollection = 0xFe1Ff921C327c7DAC5d72031a090EFC93b943B7f;
    mapping(uint256 => bool) private _rewards;
    uint256 private _rewardAmount = 0.1 ether;

    // claim reward for a speific token ID
    function claimReward(uint256 tokenId) public {
        require(IByeBanX(byeBaxCollection).ownerOf(tokenId) == msg.sender, "ByeBanxClaim: you are not the right owner");
        require(!_rewards[tokenId], "ByeBanxClaim: reward already claimed for this tokenId");
        // require(address(this).balance >= _rewardAmount, "ByeBanxClaim: not enough reward balance in the pool. Check back later!");

        (bool success, ) = msg.sender.call{value: _rewardAmount}("");
        require(success, "ByeBanxClaim: unable to send value, recipient may have reverted or not enought balance in the pool");

        _rewards[tokenId] = true;
    }

    function claimRewardforAll() public {

        IByeBanX ByeBanX = IByeBanX(byeBaxCollection);
        address userAddress = msg.sender;
        uint256 balance = ByeBanX.balanceOf(userAddress);

        uint256 rewardAmount;

        for(uint index = 0; index < balance; index++) {
            uint256 tokenId = ByeBanX.tokenOfOwnerByIndex(userAddress, index);
            if(!_rewards[tokenId]) {
                _rewards[tokenId] = true;
                rewardAmount = rewardAmount + _rewardAmount;
            }
        }

        require(rewardAmount > 0, "No reward to claim");

        (bool success, ) = msg.sender.call{value: rewardAmount}("");
        require(success, "ByeBanxClaim: unable to send value, recipient may have reverted or not enought balance in the pool");

    }

    receive() external payable { }
}