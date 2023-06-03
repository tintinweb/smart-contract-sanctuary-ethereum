// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TrustVerify {
    address payable public owner;
    mapping (address => bool) public kycedAddresses;

    event KYCSuccess(address who);

    constructor() {
        owner = payable(msg.sender);
    }

    function hasKYC(address adr) public virtual returns (bool) {
        return kycedAddresses[adr];
    }

    function addAddress(address adr) public onlyOwner {
       require(kycedAddresses[adr] == false, "This address are already KYCed.");
        kycedAddresses[adr] = true;
        emit KYCSuccess(adr);

    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
}