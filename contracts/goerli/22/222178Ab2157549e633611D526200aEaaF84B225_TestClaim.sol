/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

/**
 *Submitted for verification at BscScan.com on 2022-04-01
*/
pragma solidity 0.8.11;

// SPDX-License-Identifier: MIT

contract TestClaim {

    address public owner;
    address public conAddress;

    event log(address addr, uint flag);

    constructor()  {
        owner = msg.sender;
        conAddress = address(this);
    }

    //trigger recevier function
    //纯转账调用receiver回退函数，例如对每个空empty calldata的调用
    function transderToContract() payable public {
        payable(address(this)).transfer(msg.value);
    } 

    function claim(address addr,uint256 amont) external{
        require(msg.sender == owner);
        emit log(addr , amont);
        payable(addr).transfer(amont); 
    }



    function batchClaim(address[] memory addrs,uint256 amont) external{
        require(msg.sender == owner);
        for(uint i = 0; i < addrs.length; i++){
            emit log(addrs[i] , amont);
            payable(addrs[i] ).transfer(amont); 
        }
    }

    fallback() external payable {
        emit log(address(this),1);
    }
    receive() external payable {
        emit log(address(this),2);
    } 
}