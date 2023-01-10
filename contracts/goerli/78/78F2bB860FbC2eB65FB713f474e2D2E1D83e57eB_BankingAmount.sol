// SPDX-License-Identifier: MIT LICENSED
pragma solidity ^0.8.8;

/* This contract is about sending your ETH to the BANK(contract) and retieve when you need or 
   you can send to someone
   function:
   payment
   withdraw
   send_to
   View_deposited amount
*/
contract BankingAmount{
    address public contractOwner;
    struct Custmers{
        address CustmerAddress;
        uint256 amount;
    }
    constructor(){
       contractOwner= msg.sender;
    }
    Custmers[] public people;
    mapping(address => uint256) public Balance;

    function payment() public payable{
        people.push(Custmers(msg.sender,msg.value));
        Balance[msg.sender]= Balance[msg.sender]+ msg.value;
    }
    function ViewAmount(address USER_ADDRESS) public view returns(uint256){
        return Balance[USER_ADDRESS];
    }
    function send_to(address payable to_receiever) public payable{
        address from_user=msg.sender;
        (bool sent,) = to_receiever.call{value: Balance[from_user]}("");
        require(sent, "Failed to send Ether");
        Balance[to_receiever]=Balance[to_receiever]+Balance[from_user];
        Balance[from_user]=0;
    }
    function withDraw() public payable{
        address withdraw=msg.sender;
        (bool sent,)=withdraw.call{value:Balance[withdraw]}("");
        require(sent, "Failed to withdraw Ether");
        Balance[withdraw]=0;
    }
    
}