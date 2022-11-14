// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract serviceContract {

    event Finalised(bool finished);
    mapping(address => bool) public setServiceProvider;
    mapping(address => uint256) public provSetFee;
    mapping(address => bool) public customerPay;

    constructor(){
    }

    function providerSetFee(uint256 fee) public {
        require(setServiceProvider[msg.sender]==false,"You can only create 1 contract per address");
        provSetFee[msg.sender]=fee;
        setServiceProvider[msg.sender]=true;
    }

    function payProvider(address provider)public payable {
        require(setServiceProvider[provider]==true,"Fee hasn't been set");
        require(uint256(msg.value) == provSetFee[provider],"Invalid fee value");
        customerPay[msg.sender]=true;
    }

    function completion(bool finish, address provider) public {
        require(customerPay[msg.sender]==true,"Customer hasn't paid");
        if (finish == true){
        payable(provider).transfer(provSetFee[provider]);
        emit Finalised(finish);
         delete setServiceProvider[provider];
         delete provSetFee[provider];
         delete customerPay[msg.sender];
        }else{
           revert("Invalid parameter");
        }
    }

    function queryBalance() public view returns(uint256){
        return address(this).balance;
    }
}