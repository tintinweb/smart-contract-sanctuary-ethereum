// SPDX-License-Identifier: unlicensed ;
pragma solidity 0.8.7;

contract GetterSetter {
    string private name;
    uint256 private age;
    uint256 public fees = 1 * 10**16;
    address payable public admin;

    constructor() {
        admin = payable(msg.sender);
    }

    function getName() public view returns (string memory) {
        return name;
    }

    function getAge() public view returns (uint256) {
        return age;
    }

    function setName (string memory _name) public payable {
        require(msg.value >= fees, "Insufficient Ethers sent");
        name = _name;
        admin.transfer(msg.value);
    }

    function setAge (uint256 _age) public {
        age = _age;
    }
}