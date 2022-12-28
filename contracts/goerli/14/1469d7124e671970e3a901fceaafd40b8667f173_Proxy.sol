// SPDX-License-Identifier: No Liscense
pragma solidity >=0.8.0;

contract Proxy {
    address public owner;
    address public implementation;

    constructor(address _owner, address _implementation) {
        owner = _owner;
        implementation = _implementation;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "not allowed");
        _;
    }

    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function upgrade(address newImplementation) external onlyOwner{
        implementation = newImplementation;
    }

    fallback(bytes calldata data) external payable returns(bytes memory) {
       (bool ok, bytes memory res) = implementation.delegatecall(data);
        require(ok, string(res));
        return res;
    }
}