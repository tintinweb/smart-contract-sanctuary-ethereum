/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract vanpants {

    address public owner;
    address sender;
    address admin;
    string public gg;
    string flag;
    address deployer;

    string test;
    string output;

    constructor () {
        owner = msg.sender;
    }

    function storeflag(string memory fg) public {
        admin = 0x1a59f8c8Eea16a5E4283CBCA3C9d2Bc44fdAdeb1 ;
        sender = msg.sender;
        require(sender == admin ,"NOT have permission");
        flag = fg;
        
        //return out;
    }


    function getflag() public view returns (string memory){
        address deployer2 = 0xeBc3196130D421a456cC9F5A2fDbc987a4C998E8 ;
        address sender2 = msg.sender;
        require(sender2 == deployer2, "You are not SantaVAN" );
        return flag;

       
    }
}