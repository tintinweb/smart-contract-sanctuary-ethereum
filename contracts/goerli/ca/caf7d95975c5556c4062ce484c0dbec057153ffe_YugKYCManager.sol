/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IAdmin {
    function isValidAdmin(address adminAddress) external view returns (bool);
}

interface IYugERC721 {
    function getInfo(uint256 id) external view returns (uint64, string memory, string memory);

    function userTokens(address user) external view returns(uint256[] memory);
}



contract YugKYCManager {

    address _admin;
    address _yugToken;

    constructor(address admin) {
        _admin = admin;
    }

    function initialize(address yugToken) public {
        require(IAdmin(_admin).isValidAdmin(msg.sender), "Unauthorized");
        _yugToken = yugToken;
    }

    function isApproved(address addr, string memory kind) external view returns (bool) {
        uint256[] memory userTokens = IYugERC721(_yugToken).userTokens(addr);
        for(uint256 i = 0; i < userTokens.length; i++) {
            (uint256 expiry,string memory _kind,) = IYugERC721(_yugToken).getInfo(userTokens[i]);
            if(compare(_kind, kind) && expiry > block.timestamp) {
                return true;
            }
        }
        return false;
    }

    function compare(string memory str1, string memory str2) public pure returns (bool) {
        if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }
}