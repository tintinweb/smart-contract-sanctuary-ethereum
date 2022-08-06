/**
 *Submitted for verification at Etherscan.io on 2022-08-06
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
        return address(this).balance;
    }

    function donate() public payable {
        require(msg.value > 0.01 ether);
        donarList.push(msg.sender);
    }

    // function getplatformFee() public view returns(uint256){
    //     return 0.30;
    // }
    function fundTransferToProjectOwner(uint256 amount) public {
        // uint256 percentage=50;
        // uint256 platformFee=
        platformOwner.transfer(amount);
        //projectOwner.transfer(address(this).balance);
    }




}