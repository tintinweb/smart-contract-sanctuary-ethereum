/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

pragma solidity ^0.8.4;






contract MoneyTransferSystem{

struct bankDetails{
    string name;
    uint panCardId ;
    }

    address _todeposite;
    uint amount;

    modifier onlyOwner{
        require(msg.sender == _todeposite);
        _;
    }

mapping ( address => bankDetails)public userAcc;
mapping (address => bool) public userExist;
mapping(address => uint) Amount;

function createAcc(address walletId,string memory _name,uint _panCardId)public payable returns(string memory){

require(userExist[msg.sender] == false,"account already created");

userAcc[walletId].name =_name;
userAcc[walletId].panCardId=_panCardId;



if(msg.value == 0){
    
    userExist[msg.sender]=true;
    return "account created" ;

}}


function deposit(uint amount)public payable returns(string memory){
require(userExist[msg.sender] == true,"account exit is true so u dont have account here");

require(amount> 0,"amount should be non-zero numbers");

Amount[msg.sender] += amount;

return "amount has deposited";
}

function withdrawal(uint amount)public payable onlyOwner returns(string memory){
    require(userExist[msg.sender] ==true,"u dont have account plz create it");
    require(amount > Amount[msg.sender], "enter the valid amount or check the balance");

    Amount[_todeposite] -= amount;
    payable (msg.sender).transfer(amount);
    return "withdrawal done sucessfully";

}

function transferAmount(address reciver,uint amount)payable public returns(string memory){
    require(userExist[msg.sender] ==true,"u dont have account plz create it");
require(amount > Amount[msg.sender],"insufficient balance check your account balance");
require (userExist[msg.sender]==true);
Amount[msg.sender] -= amount;
Amount[reciver] += amount;
return "sussesfully the amount as been transfered buddy..";


}



function checkBalance()public  view returns(uint){
    
    return Amount[msg.sender];

}



function existAcc()public view returns(bool){
    return userExist[msg.sender];
}

}