/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

//SPDX-License-Identifier: OSL-3.0
pragma solidity ^0.8.0;

contract Primary{
    address primary;
    address crawler;

    constructor(address crawlerAddress){
        primary = msg.sender;
        crawler = crawlerAddress;
    }

    function primarypermission() public view returns(bool){
        require(tx.origin == primary);
        return true;
    }

    function crawlerpermission() external view returns(bool){
        require(tx.origin == crawler);
        return true;
    }

    function updateprimary(address _primary) external{
        require(_primary != address(0));
        require(primarypermission() == true,'only primary owner');
        primary = _primary;
    }
}