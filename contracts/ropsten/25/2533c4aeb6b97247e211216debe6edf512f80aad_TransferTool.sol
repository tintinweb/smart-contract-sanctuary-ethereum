/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

pragma solidity ^0.4.24;
contract TransferTool {
 
    address owner = 0x0;
    function TransferTool () public  payable{ 
        owner = msg.sender;
    } 
    function () payable public {
    } 
 
    function transferTokens(address from,address caddress,address[] _tos,uint[] values)public returns (bool){ 
        bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
        for(uint i=0;i<_tos.length;i++){
            caddress.call(id,from,_tos[i],values[i]);
        }
        return true;
    }
}