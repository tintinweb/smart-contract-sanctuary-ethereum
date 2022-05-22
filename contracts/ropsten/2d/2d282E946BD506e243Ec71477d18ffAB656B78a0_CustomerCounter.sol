/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

pragma solidity 0.8.14;

contract CustomerCounter {
    address private owner;

    mapping (address => bool) Access;
    mapping (address => uint) customCounter;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "You are not a Onwer!");
        _;
    }

    modifier havePermit {
        require(Access[msg.sender] == true, "You don't have access");
        _;
    }

    function registration() public {
        Access[msg.sender] = true;
    }

    function add(uint value) public havePermit {
        customCounter[msg.sender] += value;
    }

    function sub(uint value) public havePermit {
        customCounter[msg.sender] -= value;
    }

    function cancelPermit(address target) public onlyOwner {
        Access[target] = false;
    }

    function showMyValue() public havePermit view returns (uint) {
        return customCounter[msg.sender];
    }
}