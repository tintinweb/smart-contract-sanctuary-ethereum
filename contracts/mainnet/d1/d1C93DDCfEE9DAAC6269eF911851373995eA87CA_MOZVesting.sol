// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";

interface Token {
    function decimals() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function totalsupply() external view returns (uint256);

    function mint(address to, uint256 value) external returns (bool success);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

contract MOZVesting is Ownable, ReentrancyGuard {
    address public teamAllocationAddress =
        0xAf806721C80fF71EEebA33e9Ceb81e1facD7c63b;
    address public mozTokenAddress;
    struct UserInfo {
        uint256 totalTokens;
        uint256 claimedAmount;
    }
    mapping(address => UserInfo) public userMapping;

    //teamAllocation Time
    uint64 vestingPoint1 = 1644451200; //10-02-2022
    uint64 vestingPoint2 = 1675987200; //10-02-2023
    uint64 vestingPoint3 = 1707523200; //10-02-2024
    uint64 vestingPoint4 = 1739145600; //10-02-2025

    constructor(address _mozTokenAddress) {
        mozTokenAddress = _mozTokenAddress;
        updateInfo(2_000_000_000, teamAllocationAddress);
    }

    function updateInfo(uint256 _totalTokens, address _userAddress) internal {
        UserInfo memory uInfo = UserInfo({
            totalTokens: _totalTokens * (10**Token(mozTokenAddress).decimals()),
            claimedAmount: 0
        });
        userMapping[_userAddress] = uInfo;
    }

    function claimTokens() external {
        require((msg.sender == teamAllocationAddress), "Invalid Address");
        UserInfo storage uInfo = userMapping[msg.sender];
        uint256 userTokens = calculateTokens();
        require(userTokens != 0, "Cannot Claim");
        TransferHelper.safeTransfer(mozTokenAddress, msg.sender, userTokens);
        uInfo.claimedAmount = uInfo.claimedAmount + userTokens;
    }

    function calculateTokens() public view returns (uint256) {
        UserInfo memory uInfo = userMapping[teamAllocationAddress];
        uint256 tokenAmount;
        if (uint64(block.timestamp) > vestingPoint4) {
            tokenAmount = uInfo.totalTokens - uInfo.claimedAmount;
        } else if (uint64(block.timestamp) > vestingPoint3) {
            tokenAmount =
                ((70 * uInfo.totalTokens) / 100) -
                uInfo.claimedAmount;
        } else if (uint64(block.timestamp) > vestingPoint2) {
            tokenAmount =
                ((40 * uInfo.totalTokens) / 100) -
                uInfo.claimedAmount;
        } else if (uint64(block.timestamp) > vestingPoint1) {
            tokenAmount =
                ((10 * uInfo.totalTokens) / 100) -
                uInfo.claimedAmount;
        }
        return (tokenAmount);
    }

    function updateMozAddress(address _mozTokenAddress) external onlyOwner {
        mozTokenAddress = _mozTokenAddress;
    }

    function updateTeamAllocationAddress(address _teamAllocationAddress)
        external
        onlyOwner
    {
        teamAllocationAddress = _teamAllocationAddress;
    }
}