/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Fund{

    address public owner;
    // mang kieu data member
    Member[] public arrayClient;

    struct Member{
        address _Address;
        uint _Money;
        string _Content;
    }
   //  1BNB = 10^18;
   // 1 BNB = 1000FINM
    // msg.sender : address khach dang chay;
    // msg.value : BNB (TIEN) khach dang chay => gui len smart contrac;
    // address(this): address cua chinh smart contract nay;
    
    // chay 1 lan dau tien duy nhat, nguoi chay dau tien
    // xac dinh luon la chu;
    // sau do owner se la vi chu admin;
    constructor(){
        owner = msg.sender;
    }

    modifier checkOwner(){
      require(msg.sender == owner, "ban khong co quyen");
      _; // _; co nghia la check true tai ham nao goi no thi no se chay cac lenh con lai;
    }

    // khach hang chay dc khong? => co => public;
    // khach phai gui them tien vao smart contract => payable;
    // so tien BNB k dc < 0.001;
    // require(if else)
    function Deposit(string memory _content) public payable{
       require(msg.value>=10**15, "Sorry minimum value must be 0.001 BNB");
       arrayClient.push(Member(msg.sender, msg.value, _content));
    }

   // rut tien owner can co payable bao boc;
    function withddraw() public checkOwner{
        payable(owner).transfer(address(this).balance); 
    }

    // kiem tra balance bat ky (address.balance);
    // this la cua chinh smartcontract;
    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function counter() public view returns(uint){
        return arrayClient.length;
    }
     
    //kiem tra chi tiet (_ordering la so phan tu bao nhieu (0? 1); => tra ve chi tiet va loi chuc;
    function getDetail(uint _ordering) public view returns(address, uint, string memory){
        if(_ordering > arrayClient.length || _ordering < 0){
            return(
                arrayClient[_ordering]._Address,
                arrayClient[_ordering]._Money,
                arrayClient[_ordering]._Content
            );
        }else{
            return(0x000000000000000000000000000000000000dEaD, 0, "");
        }
    } 

}