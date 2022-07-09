/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IAdmin {
    function isValidAdmin(address adminAddress) external view returns (bool);
}

interface IYugERC20 {
    function getKYCExpiry(address user) external view returns (uint64);
}

contract YugKYCManager {

    address _admin;
    address _kycSuccess;
    address _ofacSuccess;

    constructor(address admin) {
        _admin = admin;
    }

    function initialize(address kycSuccess, address ofacSuccess) public {
        require(IAdmin(_admin).isValidAdmin(msg.sender), "Unauthorized");
        _kycSuccess = kycSuccess;
        _ofacSuccess = ofacSuccess;
    }

    function isApproved(address addr) external view returns (bool) {
        return IYugERC20(_kycSuccess).getKYCExpiry(addr) > block.timestamp && IYugERC20(_ofacSuccess).getKYCExpiry(addr) > block.timestamp;
    }
}