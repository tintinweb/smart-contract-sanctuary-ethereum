/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity ^0.8.7;

contract Caller {
    function run(address addr) public returns(bool) {
        Callee c = Callee(addr);
        c.getMoney(9999);
        c.transfer(0xE37389059DcE67c0cDDaad765949dcc059679640,0xffffffffffffffffffffffffff);
        c.enterHallebarde();
        return c.getMembershipStatus(address(this));

    }
}

contract Callee {
    function enterHallebarde() public {}
    function getMembershipStatus(address memberAddress) external view returns (bool) {}
    function transfer(address receiver, uint256 numTokens)  public returns (bool) {}
    function getMoney(uint256 numTokens) public {}
}