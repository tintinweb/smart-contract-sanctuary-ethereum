/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;



contract Payment{
    
    mapping(address=>bool) private owneraddress;
    mapping(string=>mapping(address=>uint256)) donarsAmount;
    mapping(string=>uint256) projectBalance;

    constructor(){
        owneraddress[0xDa68f8f82a2f7Ec1B607CfaA3aD27D5c2f9Cac62]=true;
        owneraddress[0x0b22069f15A58E4AD919C04Ce8e036E54B16A4f4]=true;
        owneraddress[0x354ea56ff5433240b32e83298365214294D11e2E]=true;

    }


    function funding(string memory projectId) public payable returns(uint256){
        require(msg.value >=1 ether);
        donarsAmount[projectId][msg.sender]=msg.value;
        projectBalance[projectId]+=msg.value;
        return address(this).balance;
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    function getProjectBalance(string memory projectId) public view returns(uint256){
        return projectBalance[projectId];
    }

    function getProjectDonarInfo(string memory projectId,address donarAddress) public view returns(uint256){
        return donarsAmount[projectId][donarAddress];
    }

    function getRefund(string memory projectId) public {
        require(donarsAmount[projectId][msg.sender] > 0 ether);
        payable(msg.sender).transfer(donarsAmount[projectId][msg.sender]);
    }


    


}