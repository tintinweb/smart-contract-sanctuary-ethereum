///SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.13;

contract BankV1 {
    mapping(address => uint256) balance;
    mapping(address => address) implementation;
    address admin;

    function version() external pure returns(string memory){
        return "BANKV1";
    }

    function deposit() external payable {
        balance[implementationAddress()]+=msg.value;
    }

    function changeImplementation(address newImplementation) external {
        implementation[msg.sender] = newImplementation;
    }

    function implementationAddress() public view returns (address) {
        return
            implementation[msg.sender] == address(0)
                ? msg.sender
                : implementation[msg.sender];
    }

    function adminAddress() external view returns(address){
        return admin;
    } 

    function balanceOf(address account) external view returns(uint){
        return balance[account];
    }

    function changeAdmin(address newAdmin) external {
        require(msg.sender == admin,"only admin");
        admin = newAdmin;
    }

    function withdraw(uint amount) external {
        balance[msg.sender]-=amount;
        payable(msg.sender).transfer(amount); 
    }

    function withdrawAll() external  {
        uint _balance = balance[msg.sender];
        delete balance[msg.sender];
        payable(msg.sender).transfer(_balance);
    }

    function _constructor() external {
        require(admin == address(0),"called");
        admin=msg.sender;
    }

}