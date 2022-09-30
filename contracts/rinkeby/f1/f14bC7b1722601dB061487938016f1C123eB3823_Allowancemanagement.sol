//SPDX-License-Identifier:MIT
pragma solidity 0.8.8;

contract Allowancemanagement {
    receive() external payable {}

    function checkbalance() public view returns (uint) {
        return address(this).balance;
    }

    mapping(address => uint) public allowance;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function addallowances(address to, uint amount) public {
        require(owner == msg.sender, " you are not owner");
        allowance[to] += amount;
    }

    function isowner() internal view returns (bool) {
        return owner == msg.sender;
    }

    modifier ownerallowed(uint amount) {
        require(isowner() || allowance[msg.sender] >= amount, "not allowed");

        _;
    }
    event moka(string _name, address _to, uint amount);

    function withdrawmoney(
        string memory _name,
        address payable _to,
        uint amount
    ) public ownerallowed(amount) {
        require(address(this).balance >= amount, " not enough fund");
        if (isowner() == false) {
            allowance[msg.sender] -= amount;
        }
        emit moka(_name, _to, amount);

        _to.transfer(amount);
    }
}