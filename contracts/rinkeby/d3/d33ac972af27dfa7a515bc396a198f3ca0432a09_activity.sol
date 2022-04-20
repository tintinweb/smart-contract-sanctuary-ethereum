/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

pragma solidity ^0.4.23;
contract activity {
    uint256 public people;
    address public manager;

    function activity(address _manager) public {
        manager = _manager;
    }

    function payAll () public {
        manager.transfer(this.balance);
    }
}