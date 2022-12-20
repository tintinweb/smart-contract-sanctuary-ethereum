// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

// 邀请关系合约
contract Invitation {
    event Invite(address indexed user, address indexed upper, uint256 time);

    struct UserInvitation {
        address upper;          // 邀请人
        address[] lowers;       // 被邀请人
        uint256 startTime;
    }

    mapping(address => UserInvitation) public userInvitations;

    // 接受邀请
    // Allow: A invite B, then B invite C, then C invite A
    // Forbidden: A invite B, then B invite A
    function acceptInvitation(address inviter) external returns (bool) {
        // 被邀请人不能是邀请者自己
        require(msg.sender != inviter, "FORBID_INVITE_YOURSLEF");
        // 被邀请人的邀请关系
        UserInvitation storage sender = userInvitations[msg.sender];
        // 邀请人的邀请关系
        UserInvitation storage upper = userInvitations[inviter];

        require(sender.upper == address(0), "ALREADY_HAS_UPPER");
        require(upper.upper != msg.sender, "FORBID_CIRCLE_INVITE");

        sender.upper = inviter;
        upper.lowers.push(msg.sender);

        if (sender.startTime == 0) {
            sender.startTime = block.timestamp;
        }
        if (upper.startTime == 0) {
            upper.startTime = block.timestamp;
        }

        emit Invite(msg.sender, sender.upper, sender.startTime);
        return true;
    }
    // 获取指定地址的上一级地址
    function getUpper1(address user) external view returns (address) {
        return userInvitations[user].upper;
    }
    // 获取指定地址的上两级地址 upper1上一级 upper2上二级
    function getUpper2(address user) external view returns (address, address) {
        address upper1 = userInvitations[user].upper;
        address upper2 = address(0);
        if (address(0) != upper1) {
            upper2 = userInvitations[upper1].upper;
        }

        return (upper1, upper2);
    }

    // 指定用户的下一级
    function getLowers1(address user) external view returns (address[] memory) {
        return userInvitations[user].lowers;
    }
    // 指定用户的下二级 lowers1下一级 lowers2下二级
    function getLowers2(address user) external view returns (address[] memory, address[] memory) {
        address[] memory lowers1 = userInvitations[user].lowers;
        uint256 count = 0;
        uint256 lowers1Len = lowers1.length;
        // get the  total count;
        for (uint256 i = 0; i < lowers1Len; i++) {
            count += userInvitations[lowers1[i]].lowers.length;
        }
        address[] memory lowers;
        address[] memory lowers2 = new address[](count);
        count = 0;
        for (uint256 i = 0; i < lowers1Len; i++) {
            lowers = userInvitations[lowers1[i]].lowers;
            for (uint256 j = 0; j < lowers.length; j++) {
                lowers2[count] = lowers[j];
                count++;
            }
        }

        return (lowers1, lowers2);
    }

    function getLowers2Count(address user) external view returns (uint256, uint256) {
        address[] memory lowers1 = userInvitations[user].lowers;
        uint256 lowers2Len = 0;
        uint256 len = lowers1.length;
        for (uint256 i = 0; i < len; i++) {
            lowers2Len += userInvitations[lowers1[i]].lowers.length;
        }

        return (lowers1.length, lowers2Len);
    }
}