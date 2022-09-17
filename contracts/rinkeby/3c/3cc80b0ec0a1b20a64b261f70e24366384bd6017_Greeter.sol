/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

// contract Greeter is Ownable {
contract Greeter {
    string private _greeting = "Hello, World!";
    address private _owner;

    modifier onlyOwner() { 
        require (
            msg.sender == _owner,
            "Ownable: caller is not the owner"
        ); 
        _; 
    }
    

    constructor() {
        _owner = msg.sender;
    }

    function greet() external view returns(string memory) {
        return _greeting;
    }

    function setGreeting(string calldata greeting) external onlyOwner {
        _greeting = greeting;
    }

    function owner() external view returns(address) {
        return _owner;
    }
}