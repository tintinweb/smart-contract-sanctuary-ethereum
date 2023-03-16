/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

pragma solidity ^0.4.23;

contract NewImplementation {
    address public owner;

    constructor(address _owner) public {
        owner = _owner;
    }

    function withdraw(address _to, uint256 _amount) external {
        require(msg.sender == owner, "Only owner can withdraw");
        _to.transfer(_amount);
    }

    function () external payable {}
}