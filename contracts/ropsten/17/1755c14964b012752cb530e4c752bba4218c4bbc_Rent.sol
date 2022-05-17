/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;
contract Rent{
    struct Tenant{
        string name;
        uint age;
        string occupation; }
        Tenant public tenant;
        address payable Landowner;
        constructor(string memory _name,uint _age,string memory _occup){
            Landowner =payable(msg.sender);
            tenant.name= _name;
            tenant.age = _age;
            tenant.occupation = _occup;
        }
        receive( )external payable{
            Landowner.transfer(msg.value);
        }
}