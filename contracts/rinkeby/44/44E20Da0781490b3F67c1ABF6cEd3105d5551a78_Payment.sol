// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./NestToken.sol";

contract Payment is Ownable {
    event SendToken(address recipient, uint256 amount);
    event BuyTicket(address recipient, uint256 amount, string name);

    mapping(address => uint256) public Payments;
    mapping(address => bool) public adminAddresses;

    NestedToken public nestedToken;

    constructor(address tokenAddress) {
        nestedToken = NestedToken(tokenAddress);
    }

    modifier onlyAdmin() {
        require(adminAddresses[msg.sender] == true, "Not an admin");
        _;
    }

    // ToDo: add address to admin list:
    function addAdmin(address addr) public onlyOwner returns (bool) {
        adminAddresses[addr] = true;
        nestedToken.approve(addr, 100 * 10 * 18);
        return true;
    }

    // ToDo: remove address from admin list:
    function removeAdmin(address addr) public onlyOwner returns (bool) {
        adminAddresses[addr] = false;
        nestedToken.approve(addr, 0);
        return true;
    }

    // ToDo: create a payable buyTicket() function:
    function buyTicket(string memory name) public payable {
        require(msg.value > 0, "Insufficient Ether provided");
        Payments[msg.sender] = Payments[msg.sender] + msg.value;
        emit BuyTicket(msg.sender, msg.value, name);
    }

    // ToDo: create a sendToken() function:
    function sendToken(address addr, uint256 amount) public returns (bool) {
        nestedToken.transfer(addr, amount);
        emit SendToken(addr, amount);
        return true;
    }

    // Todo: create a sendToMultiple() function:
    function sendToMultiple(address[] memory arrOfAddresses, uint256 amount)
        external
        onlyAdmin
        returns (bool)
    {
        for (uint256 i = 0; i < 10; i++) {
            sendToken(arrOfAddresses[i], amount);
        }
        return true;
    }

    // ToDo: create a withdraw() function that lets the owner withdraw ETH
    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to withdraw money");
    }

    // Add the `receive()` special function that receives eth and calls ()
    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        buyTicket("anonymous");
    }
}