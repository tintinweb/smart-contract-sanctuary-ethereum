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

    // msg.sender: Address cua KHACH dang chay
    // msg.value:  BNB($) cua KHACH dang chay ----> GUI len Smart Contract
    // address(this): Address cua SM "NAY"
    // 1 ether = 10^18  
    // 1 ether = 1000 Finn

    constructor(){
        owner = msg.sender;
    }

    event SM_vua_nhan_duoc_Tien_nha(address _address, uint _sotien, string _loichuc);

    // 0.001   10^15
    function Deposit(string memory _content) public payable{
        require(msg.value>=10**15, "Sorry, minimum value must be 0.001 BNB");
        arrayClient.push(Member(msg.sender, msg.value, _content));
        emit SM_vua_nhan_duoc_Tien_nha(msg.sender, msg.value, _content);
    }

    modifier checkOwner(){
        require(msg.sender==owner, "Sorry, you are not allowed to process.");
        _;
    }    

    function Withdraw() public checkOwner{
        payable(owner).transfer( address(this).balance );
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function counter() public view returns(uint){
        return arrayClient.length;
    }

    function getDetail(uint _ordering) public view returns(address, uint, string memory){
        if(_ordering<arrayClient.length){
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