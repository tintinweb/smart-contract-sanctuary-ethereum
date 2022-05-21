// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.6;

import "./FreeMoney.sol";

contract createTx {
    address payable public s;
    FreeMoney instanceFreeMoney;
    
    constructor(address payable addr) {
        s = addr;
        instanceFreeMoney = FreeMoney(s);
    }
    
    function getMembership() public returns (bool) {
        instanceFreeMoney.enterHallebarde();
        return true;
    }

    function getMoney(uint256 amount) public returns (bool) {
        instanceFreeMoney.getMoney(amount);
        return true;
    }
    
    function getMembershipStatus(address memberAddress) public view returns (bool) {
        return instanceFreeMoney.getMembershipStatus(memberAddress);
    }
}