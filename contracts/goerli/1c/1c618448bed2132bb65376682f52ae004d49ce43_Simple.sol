// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Simple {
    struct Information {
        string name;
        bool isAllow;
        uint256 balance;
        mapping(uint256 => uint256) tokenId;
    }

    uint256 public s_openNumber = 999;
    uint256 private s_number = 1000;
    address private s_owner = address(0x123456789abcdef);
    mapping(address => uint256) private s_balances;
    Information private s_singleUserInfo;
    Information[] private s_userInfo;

    function setNumber(uint256 number) public {
        s_number = number;
    }

    function setUserBalance(address user, uint256 balance) public {
        s_balances[user] = balance;
    }

    // function setUserInfo(Information memory userInfo) public {
    //     Information memory xxx = Information({ name: name, isAllow: isAllow, balance: balance  });
    // }

    function getNumber() public view returns (uint256) {
        return s_number;
    }

    function getOwner() public view returns (address) {
        return s_owner;
    }

    function getUserBalance(address user) external view returns (uint256) {
        return s_balances[user];
    }

    function setSingleUserInfo()
        internal
        returns (
            string memory,
            bool,
            uint256,
            uint256
        )
    {
        Information storage singleUserInfo = s_singleUserInfo;
        singleUserInfo.name = "John";
        singleUserInfo.isAllow = true;
        singleUserInfo.balance = 1000;
        singleUserInfo.tokenId[77755211] = 123;

        return (
            singleUserInfo.name,
            singleUserInfo.isAllow,
            singleUserInfo.balance,
            singleUserInfo.tokenId[123]
        );
    }

    function setUserInfo()
        internal
        returns (
            string memory,
            bool,
            uint256,
            uint256
        )
    {
        Information storage singleUserInfo = s_userInfo.push();
        singleUserInfo.name = "John";
        singleUserInfo.isAllow = true;
        singleUserInfo.balance = 1000;
        singleUserInfo.tokenId[77755211] = 123;

        return (
            singleUserInfo.name,
            singleUserInfo.isAllow,
            singleUserInfo.balance,
            singleUserInfo.tokenId[123]
        );
    }
}