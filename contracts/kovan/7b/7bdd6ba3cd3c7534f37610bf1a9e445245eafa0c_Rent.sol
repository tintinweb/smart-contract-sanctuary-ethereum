/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity^0.8.0;
contract Rent{
    uint age;
    string name;
    string occupation;
    address tenant_address;
    function tenant() public view returns(string memory Name,uint Age,string memory Occupation,address Address){
          Name=name;
          Age=age;
          Occupation=occupation;
          Address=tenant_address;
    }
    address payable admin;
    constructor(string memory _name,uint _age,string memory _occupation,address _tenant_address){
        require(_age>=18,"Tenant must be older than 18 year");
        require(bytes(_name).length>0,"Name field can't be empty");
        require(bytes(_occupation).length>0,"Name field can't be empty");
        require(_tenant_address!=msg.sender);
        age=_age;
        name=_name;
        occupation=_occupation;
        tenant_address=_tenant_address;
        admin=payable(msg.sender);
    }
    
    receive() external payable{
        require(msg.sender==tenant_address);
       admin.transfer(address(this).balance);
    }
}