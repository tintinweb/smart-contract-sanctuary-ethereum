/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

/* 
 *
 * SPDX-License-Identifier:SimPL-2.0
 *
*/
pragma solidity = 0.7.3;


/* 极简的代理合约 Spin.sol，
 * 用于 保存 和 获取 某个方法要调用的合约的地址。 
 */
contract Spin {

    address public addr;

    address owner;

    constructor(){
        owner = msg.sender;
    }

    function changeOwner(address newowner) public {
        require (msg.sender != owner, "error------You aren't the owner !");
        owner = newowner;
    }

    function getAddress() public view returns (address oaddr){
        return addr;
    }

    function setAddr(address newaddr) public {
        require (msg.sender != owner, "error------You aren't the owner !");
        addr = newaddr;
    }

}