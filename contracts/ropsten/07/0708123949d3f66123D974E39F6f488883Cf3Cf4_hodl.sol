/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract hodl{
    event event_receive(address Donor,uint256 Value);

    string public Owner;
    address payable public Owner_address;
    address payable contract_address=payable (address(this));
    uint256 Deposit;
    uint256 Start_time;
    address[] all_address;
    mapping(address=>string)address_name;


    modifier IsOwner(){
       require(msg.sender==Owner_address,"You are not the Owner!");
       _; 
    }

    modifier Overyear(){
        require((block.timestamp-Start_time)/3600>265,"Your fixed depoits isn't over a year,so you cann't take your money back!");
        _;
    }

    constructor(string memory name){
        Owner=name;
        Owner_address = payable(msg.sender);
        Start_time=block.timestamp;
    }

    receive() external payable {
        emit event_receive(msg.sender,msg.value);
    }


    function CheckBalance() external view IsOwner() returns(uint256){
        return contract_address.balance;
    }


    function CheckContractTime() external view IsOwner() returns(uint256){    
        return (block.timestamp-Start_time)/3600;
    }



    function Destory() external IsOwner() Overyear(){
            selfdestruct(Owner_address);
    }

}