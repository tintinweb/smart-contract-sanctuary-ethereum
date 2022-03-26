/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Fund{

    address public owner;

    Member[] private arrayClient;


    struct Member{
        address _Address;
        uint _Money;
        string _Content;
    }

    //msg.sender : address cua Khach dang chay
    //msg.value : BNB($) cua Khach dang chay ---->Gui len smartcontract
    //address(this) :address cua SM "NAY"
    //1 ether = 10 ^18 
    // 1ther = 1000  finn

    constructor(){
        owner = msg.sender;
    }

    event Sm_vua_nhan_duoc_tien_nha(address _address,uint _sotien,string _loichuc);

    function Deposit(string memory _content) public payable{
        require(msg.value>=10**15,"Sorry,minimum value must be 0.001 BNB");
        arrayClient.push(Member(msg.sender,msg.value, _content));
        emit Sm_vua_nhan_duoc_tien_nha(msg.sender,msg.value,_content);
    }

    modifier checkOwner(){
        require(msg.sender==owner,"sorry, you are not allowed to process");
        _;
    }

    function Withdraw() public checkOwner{       
        payable(owner).transfer(address(this).balance);
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function counter() public view returns(uint){
        return arrayClient.length;
    }

    function getDetail(uint _ordering) public view returns(address,uint,string memory){
        if(_ordering<arrayClient.length){
            return(
                 arrayClient[_ordering]._Address,
            arrayClient[_ordering]._Money,
            arrayClient[_ordering]._Content
            );
        }else{
            return(0x000000000000000000000000000000000000dEaD,0,"");
        }
    }

   

}