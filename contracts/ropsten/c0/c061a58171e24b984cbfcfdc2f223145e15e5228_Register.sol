/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract Register{
    uint256 userId;

    uint256[] Admin;
    uint256[] Invester;
    uint256[] BSA;

    mapping(uint256=>bool) IsAdmin;
    mapping(uint256=>bool) IsInvester;
    mapping(uint256=>bool) IsBSA;

    constructor(){

    }

    function UserHasAdmin(uint256 _id)  public{
        Admin.push(_id);
        IsAdmin[_id]=true;
    }
    function CheckAdmin(uint256 _id) view public returns(bool) {
        return(IsAdmin[_id]);
    }
    function UserHasInvester(uint256 _id) public{
        Invester.push(_id);
        IsInvester[_id]=true;
    }

    function CheckInvester(uint256 _id) view public returns(bool) {
        return(IsInvester[_id]);
    }

    function UserHasBSA(uint256 _id)  public{
        BSA.push(_id);
        IsBSA[_id]=true;
    }
    function CheckHasBSA(uint256 _id) view public returns(bool) {
        return(IsBSA[_id]);
    }
}