// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../Ownable.sol";

contract ibgPresale is Ownable {

    IERC20 public ibgToken = IERC20(0xF16CD087e1C2C747b2bDF6f9A5498AA400D99C24);
    bool public openStaked = false;        
    bool public openRedeemed = false;      
    uint256 public redeemedFee = 90;      

    mapping (address => uint256) public userInfos;

    function staked(uint256 _ibgAmount) public {
        require(openStaked && _ibgAmount > 0, "staked: error");
        ibgToken.transferFrom(msg.sender, address(this), _ibgAmount);
        userInfos[msg.sender] += _ibgAmount;
    }

    function redeemed() public {
        uint256 _stakedNumber = userInfos[msg.sender];
        require(openRedeemed && _stakedNumber > 0, "redeemed: error");
        uint256 _transferAmount = (_stakedNumber * redeemedFee)/100;
        ibgToken.transfer(msg.sender, _transferAmount);
        userInfos[msg.sender] = 0;
    }

    function setOpenStaked(bool _open) public onlyOwner {
        openStaked = _open;
    }

    function setOpenRedeemed(bool _open) public onlyOwner {
        openRedeemed = _open;
    }

    function transferToken (address _tokenAddress) public onlyOwner {
        IERC20(_tokenAddress).transfer(msg.sender, IERC20(_tokenAddress).balanceOf(address(this)));
    }

    function setRedeemedFee (uint256 _redeemedFee) public onlyOwner {
        redeemedFee = _redeemedFee;
    }

    function setIBGToken (IERC20 _ibgToken) public onlyOwner {
        ibgToken = _ibgToken;
    }
}