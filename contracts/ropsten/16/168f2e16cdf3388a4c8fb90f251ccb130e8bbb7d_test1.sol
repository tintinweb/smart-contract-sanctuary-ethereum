/**
 *Submitted for verification at Etherscan.io on 2022-09-13
*/

pragma solidity >=0.7.0 <0.9.0;

contract test1{

    mapping(address =>uint) idmapping;
    mapping(uint =>string) namemapping;
    uint public sum=0;

    function zhuce(string memory name) public{
        address account = msg.sender;
        sum++;
        idmapping[account]=sum;
        namemapping[sum]=name;
    }

    function getNameById(uint id) public view returns(string memory){
        return namemapping[id];
    }
}