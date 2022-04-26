/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17;

contract CounterFork {

    // Public variable of type unsigned int to keep the number of counts
    address private baseContract;
    address private owner;
    
    constructor(address _baseContract, address _owner) {
        baseContract = _baseContract;
        owner = _owner;
    }

    modifier isOwner() {
        require(owner == msg.sender, "Invalid caller");
        _;
    }

    function compareStrings(string memory a, string memory b) private view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // Function that increments our counter
    function increment(string memory _role) public isOwner {
        require(compareStrings(_role, "role1"), "invalid role");
        (bool _success,) = baseContract.call(msg.data);
        require(_success, "Calling failed");
    }

    // Not necessary getter to get the count value
    function getCount(string memory _role) public isOwner returns (uint256) {
        require(compareStrings(_role, "role2"), "invalid role");
        (bool _success, bytes memory _memory) = baseContract.call(msg.data);
        require(_success, "Calling failed");
        (uint256 _value) = abi.decode(_memory, (uint256));
        return _value;
    }

}