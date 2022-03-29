/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

pragma solidity ^0.5.12;

interface ERC20{


    function transfer(address recipient, uint amount) external returns (bool);
}

contract test{
    function safeTransfer(address a,address b,uint256 amount) public{

        ERC20(a).transfer(b,amount);


    }



}