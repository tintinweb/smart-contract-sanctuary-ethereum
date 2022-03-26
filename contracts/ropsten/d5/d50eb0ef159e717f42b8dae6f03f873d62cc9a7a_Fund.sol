/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct Member{
    address member;
    uint money;
    string content;
}

contract Fund{
    // msg là con trỏ, trỏ tới người đang chạy.
    // msg.sender: Address của khách đang chạy
    // msg.value: BNB ($) của khách đang chạy -> Gửi lên smart contract
    // address(this): Address của smart contract Này
    
    address public owner;
    Member[] private arrayClient;

    event SmVuaNhanDuocTien(address _address, uint amount, string message);

    constructor(){
        owner = msg.sender;
    }

    modifier checkOwner(){
        require(msg.sender == owner, "Ban khong duoc phep rut tien");
        _;
        // ý nghĩa của dấu "_" là đại diện cho phần kế tiếp sẽ chạy
    }

    // function nào có tiền gửi tiên bắt buộc phải có từ khoá "payable"
    // 1ehter = 10^18
    // 1ether = 1000 Finney
    // 0.001=10^15
    function deposit(string memory content) public payable {
        // dùng require để test và chặn những trường hợp lỗi, trả tiền về cho khách
        require(msg.value >= 10**15, "Sorry, min is 0.001 BNB");
        arrayClient.push(Member(msg.sender, msg.value, content));
        emit SmVuaNhanDuocTien(msg.sender, msg.value, content);
    }

    function withdraw() public checkOwner{
        // hàm transfer là lấy tiền trong contract chuyển đi nơi khác
        payable(owner).transfer(address(this).balance);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function countMember() public view returns(uint) {
        return arrayClient.length;
    }

    function getDetail(uint odering) public view returns(address, uint, string memory){
        if(odering < arrayClient.length) {
            return (
                arrayClient[odering].member,
                arrayClient[odering].money,
                arrayClient[odering].content
                );
        } else {
            return (0x000000000000000000000000000000000000dEaD, 0, "");
        }
    }
}