/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
struct Customer {
    address account;
    uint amount;
}
contract Simple {
    address owner;
    uint balance;
    Customer customer;
    mapping (address => Customer) customerStructs;
    address[] private userAddresses;
    uint[] private userAmount;
    uint private fee = 0;

    constructor() {
        //เจ้าของ contract
        owner = msg.sender;
        balance = 0;
    }

    //ดูเจ้าของ contract
    function getOwnerContranct() public view returns(address) {
        return owner;
    }

    //ดูจำนวนทั้งหมดใน contract
    function getBalanceContract() public view returns(uint) {
        return address(this).balance;
    }

    //ดูจำนวนค่าธรรมเนียม
    function getfeeContranct() public view returns(uint) {
        return fee;
    }

    //ดูจำนวนของตัวเองที่ฝากใน contract
    function getAmountSelf() public view returns(uint) {
        // return customer.amount[msg.sender];
        return customerStructs[msg.sender].amount;
    }

    //ดูจำนวนบัญชีทั้งหมด
    function getAllUsers() public view returns(address[] memory) {
        return userAddresses;
    }

    //ดูจำนวนเหรียญในบัญชีทั้งหมด
    function getAllAmount() public view returns(uint[] memory) {
        return userAmount;
    }

    //การฝากเข้า contract
    function deposit() payable public {
        require(msg.value > 1 ether, 'More than 1 ETH must be sent.');
        require(msg.sender != owner, 'Can \'t open deposit');
        if (msg.sender != owner) {
            //คนฝากเข้า contract
            if (customerStructs[msg.sender].account == msg.sender) {
                //เคยฝาก
                customerStructs[msg.sender].amount = customerStructs[msg.sender].amount + (msg.value - 1000000000000000000);
                for (uint index = 0; index < userAddresses.length; index++) {
                    if (userAddresses[index] == msg.sender) {
                        userAmount[index] = customerStructs[msg.sender].amount;
                    }
                }
            } else {
                //ไม่เคยฝาก
                customerStructs[msg.sender].account = msg.sender;
                customerStructs[msg.sender].amount = msg.value - 1000000000000000000;
                userAddresses.push(msg.sender);
                userAmount.push(customerStructs[msg.sender].amount);
            }
            //จำนวนเพิ่มขึ้นใน contract
            balance = getBalanceContract();
            fee = fee + 1000000000000000000;
        }
    }

    //การถอน ตัวอย่าง
    function witdraw(uint quantity) public {
        require(getBalanceContract() >= quantity*1000000000000000000, 'balance is not enough');
        //เจ้าของ contract ถอนออก
        if (owner == msg.sender) {
            require(fee >= quantity*1000000000000000000, 'amount is not enough');
            if (fee >= quantity*1000000000000000000) {
                payable(owner).transfer(quantity*1000000000000000000);
                fee = fee - quantity*1000000000000000000;
            }
        } else {
            //คนอื่นถอนออก contract 
            require(customerStructs[msg.sender].amount >= quantity*1000000000000000000, 'amount is not enough');
            if (customerStructs[msg.sender].amount >= quantity*1000000000000000000) {
                customerStructs[msg.sender].amount = customerStructs[msg.sender].amount - (quantity*1000000000000000000);
                payable(msg.sender).transfer(quantity*1000000000000000000);
                for (uint index = 0; index < userAddresses.length; index++) {
                    if (userAddresses[index] == msg.sender) {
                        userAmount[index] = customerStructs[msg.sender].amount;
                    }
                }
            }
        }
        //จำนวนลดลงใน contract
        balance = getBalanceContract();
    }
}