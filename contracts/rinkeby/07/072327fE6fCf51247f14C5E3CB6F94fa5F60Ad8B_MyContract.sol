/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract {

//private
string _name; //ข้อความ
uint _balance; //จำนวนเต็มบวกเท่านั้น

constructor(string memory name,uint balance){  //constructorจ่ายค่าgas
    _name = name;
    _balance = balance;


}
function getBalance() public view returns(uint balance){  //functionไม่จ่ายค่าgas
    return _balance;
}

}