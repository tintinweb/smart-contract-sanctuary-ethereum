/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract ByeBanxClaim {

    address byeBaxCollection = 0xfFf89883eceCde272485DB1aA68f555698DF1188;
    mapping(uint256 => bool) private _rewards;
    uint256 private _rewardAmount = 0.1 ether;

    function claimReward(uint256 tokenId) public {
        require(IERC721(byeBaxCollection).ownerOf(tokenId) == msg.sender, "ByeBanxClaim: you are not the right owner");
        require(!_rewards[tokenId], "ByeBanxClaim: reward already claimed for this tokenId");
        require(address(this).balance >= _rewardAmount, "ByeBanxClaim: not enough reward balance in the pool. Check back later!");

        (bool success, ) = msg.sender.call{value: _rewardAmount}("");
        require(success, "ByeBanxClaim: unable to send value, recipient may have reverted");

        _rewards[tokenId] = true;
    }

    receive() external payable { }
}