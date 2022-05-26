// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


contract FoundationV2 {
    string public name;
    address public owner;
    uint256 public balance;
    bool isInitialized;

    function initialize(
        string memory _name,
        address _owner
    ) public {
        require(!isInitialized, "Initialized already");
        name = _name;
        owner = _owner;
        isInitialized = true;
    }

    function replenish() payable public{
        balance += msg.value;
    }

    function withdraw() public {
        (bool result,) = owner.call{value: balance}(""); 
        require(result, "Transfer eth failed");
    }

}