/**
 *Submitted for verification at Etherscan.io on 2023-01-25
*/

pragma solidity ^0.8.17;
//SPDX-License-Identifier: MIT

interface IERC20{
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value)external returns(bool);
}


contract DispersE42{
    function dispersE(address payable[] calldata recipients, uint256[] calldata values) external payable{
        for(uint256 i = 0; i<recipients.length;i++){
            recipients[i].transfer(values[i]);
        }
        uint256 balance = address(this).balance;
        if(balance > 0){
            payable(msg.sender).transfer(balance);
        }
    }

    function dispersET(IERC20 token, address[] calldata recipients, uint256[] calldata values)external{
        uint256 total=0;
        for(uint256 i = 0;i<recipients.length;i++){
            total += values[i];
        }
        require(token.transferFrom(msg.sender, address(this), total));
        for(uint256 i = 0;i<recipients.length;i++){
            require(token.transfer(recipients[i], values[i]));
        }
    }

    function dispersETS(IERC20 token, address[] calldata recipients, uint256[] calldata values) external{
        for(uint256 i = 0;i < recipients.length; i++){
            require(token.transferFrom(msg.sender, recipients[i], values[i]));
        }
    }
}