// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


contract FoundationV2 {
    string public name;
    address public owner;
    uint256 public balance;

    function initialize(
        string memory _name,
        address _owner
    ) public {
        name = _name;
        owner = _owner;
    }

    function replenish() payable public{
        balance += msg.value;
    }

    function withdraw() public {
        (bool result,) = owner.call{value: balance}(""); 
        require(result, "Transfer eth failed");
    }

}