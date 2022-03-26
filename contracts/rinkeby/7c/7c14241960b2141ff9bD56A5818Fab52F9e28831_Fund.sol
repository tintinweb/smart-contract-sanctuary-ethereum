/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Fund {
    address public owner; // nguoi deploy contract
    Member[] private arrayClient;

    struct Member {
        address _Address;
        uint _Money;
        string _Content;
    }

    // msg.sender: Address cua KHACH dang chay
    // msg.value: BNB(s) cua KHACH dang chay -----> GUI len Smart Contract
    // address(this): Address cua SM "NAY"
    // address(this).balance: tat ca tien trong contract
    // 1 ether = 10^18  1000000000000000000
    // 1 ether = 1000 Finney

    constructor() { // chi chay 1 lan
        owner = msg.sender; // khoi tao lan dau, tra ve dia chi nguoi xay SM (ADMIN)
    }

    // tạo event
    event Deposit_event(address _address, uint _sotien, string _loichuc);

    // function co tien gui len phai co payable
    // 0.001 10^15
    function Deposit(string memory _content) public payable {
        require(msg.value >= (10**18 * 0.001), "Sorry, minumum value must be 0.001 BNB");
        arrayClient.push(Member(msg.sender, msg.value, _content));
        // call emit
        emit Deposit_event(msg.sender, msg.value, _content);
    }

    modifier checkOwner() {
        require(msg.sender == owner, "Sorry, you are not allowed to process.");
        _;
    }

    // transfer func: lay tien trong contract chuyen di
    function Withdraw() public checkOwner {
        // require(msg.sender == owner, "Sorry, you are not allowed to process."); // can use modifier
        payable(owner).transfer(address(this).balance);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function count() public view returns(uint) {
        return arrayClient.length;
    }

    function getDetail(uint _ordering) public view returns(address, uint, string memory) {
        if (_ordering < arrayClient.length) {
            return (
                arrayClient[_ordering]._Address, 
                arrayClient[_ordering]._Money, 
                arrayClient[_ordering]._Content
            );
        } else { // tra ve vi DEAD
            return (
                0x000000000000000000000000000000000000dEaD, 0, ""
            );
        }
    }
}