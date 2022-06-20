/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract donation {

    address private owner;
    address private admin;
    constructor(){
        owner = msg.sender;
        admin = msg.sender;
    }

    modifier isOwner {
        require(msg.sender == owner, "Ups!");
        _;
    }

    modifier isAdmin {
        require(msg.sender == owner || msg.sender == admin, "Sorry");
        _;
    }

    function donate() public payable{
        //Thanks
    }

    function collect() public isAdmin{
        (bool callSuccess, ) = payable(owner).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function changeAdmin(address newAdmin) public isOwner{
        admin = newAdmin;
    }

    function viewAdmin() public view isOwner returns(address){
        return admin;
    }
}