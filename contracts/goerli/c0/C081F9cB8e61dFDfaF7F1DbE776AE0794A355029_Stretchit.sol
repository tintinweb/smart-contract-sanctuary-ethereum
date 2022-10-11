/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract UserNotes {
    address public owner;
    address public parentContract;
    string private data;

    constructor() {
        owner = tx.origin;
        parentContract = msg.sender;
    }

    modifier onlyUser() {
        require(msg.sender == owner, "youre not allowed to do this!");
        _;
    }

    bool public allowance;

    event Pushed(address indexed user);

    function pushData(string calldata _newData) external onlyUser {
        data = _newData;
        emit Pushed(msg.sender);
    }

    function setAllowance() external payable {
        require(msg.sender == parentContract, "not allowed");
        allowance = true;
    }

    function getData() external view onlyUser returns (string memory) {
        return data;
    }
}

contract Stretchit {
    address payable public owner;

    constructor() {
        owner = payable(address(msg.sender));
    }

    event Created(address userContractAddress);
    event Allowed(address userAddress);

    mapping(address => address) users;

    function createNewUser() external {
        require(
            users[msg.sender] == address(0),
            "you already have an account!"
        );
        UserNotes newUser = new UserNotes();
        users[msg.sender] = address(newUser);
        emit Created(address(newUser));
    }

    function allow() public payable {
        require(
            UserNotes(users[msg.sender]).allowance() == false,
            "youre already allowed"
        );
        require(msg.value == 1 ether, "wrong amount");
        UserNotes(users[msg.sender]);
        UserNotes(users[msg.sender]).setAllowance();

        emit Allowed(msg.sender);
    }

    function widthdraw() external {
        require(msg.sender == owner, "not allowed");
        owner.transfer(address(this).balance);
    }

    receive() external payable {
        require(users[msg.sender] != address(0), "not a user");
        allow();
    }

    function balanceOf() external view returns (uint48) {
        return uint48(address(this).balance);
    }

    function viewUsersContracts(address _user) public view returns (address) {
        return users[_user];
    }
}