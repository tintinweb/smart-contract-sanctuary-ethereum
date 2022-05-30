/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

pragma solidity ^0.8.7;

contract ForceAttack {
    address delegateAddress;

    constructor(address _delegateAddr) {
        delegateAddress = _delegateAddr;
    }

    fallback() external payable {
        (bool success,) = delegateAddress.call{value: msg.value}("");
        require(success);
    }
}