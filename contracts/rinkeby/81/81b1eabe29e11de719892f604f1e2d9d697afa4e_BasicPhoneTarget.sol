// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "PhoneManager.sol";
import "RandomMintNft.sol";

contract BasicPhoneTarget is RandomMintNft {
    PhoneManager _phone;
    
    function setPhoneAddress(PhoneManager phone) public virtual onlyOwner {
        _phone = phone;
    }

    /**
     */
    function safeContractRandomMint(uint256 random, address to) public virtual override {
        super.safeContractRandomMint(random, to);
        require(address(_phone) != address(0), "BasicPhoneTarget: Phone contract is not set");
        // TODO 利用 random 计算铸造等级
        uint256 level = random % 2;
        _phone.setMintPhoneLevel(level);
        _phone.safeContractRandomMint(random, to);
    }
}