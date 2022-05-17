/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;



// File: SetGet.sol

contract SetGet4 {
    mapping(address => uint256) balances;
    string value;
    address payable public owner;
    uint256 public creationTime = now;

    constructor() public {
        value = "myValue";
        owner = msg.sender;
    }

    function fund() public payable {
        balances[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint256 ETH) {
        return address(this).balance / 10**18;
    }

    function get() public view returns (string memory) {
        return value;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function set(string memory _value) public onlyOwner {
        value = _value;
    }

    modifier onlyBy(address _account) {
        require(msg.sender == _account, "Sender not authorized.");
        _;
    }

    modifier onlyAfter(uint256 _time) {
        require(now >= _time, "Function called too early.");
        _;
    }

    function disown() public onlyBy(owner) onlyAfter(creationTime + 5 minutes) {
        delete owner;
    }

    function close() external {
        selfdestruct(msg.sender);
    }
}