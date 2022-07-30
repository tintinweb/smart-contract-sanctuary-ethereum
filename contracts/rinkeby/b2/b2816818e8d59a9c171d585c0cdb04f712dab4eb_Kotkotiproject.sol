/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.17 < 0.9.0;


contract Kotkotiproject{
    address payable public platformOwner;
    address[] public donarList;
    address payable public projectOwner; 

    constructor(address payable projectOwnerAddress){
        platformOwner=payable(msg.sender);
        projectOwner=projectOwnerAddress;
    }


    function getDonars() public view returns (address[] memory) {
        return donarList;
    }

    function contractBalance() public view returns(uint256){
        require(msg.sender==platformOwner);
        return address(this).balance;
    }

    function donate() public payable {
        require(msg.value > 0.01 ether);
        donarList.push(msg.sender);
    }

    function fundTransferToPlatformOwner() public {
        require(msg.sender==platformOwner);
        platformOwner.transfer(address(this).balance);
    }
    function fundTransferToProjectOwner() public {
        require(msg.sender==platformOwner);
        projectOwner.transfer(25000000000000000000);

    }




}