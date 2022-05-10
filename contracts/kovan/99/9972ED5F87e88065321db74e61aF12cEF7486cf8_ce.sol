/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

pragma solidity ^0.8.0;

contract ce{
    bytes me;
    function main(address sushi,address [] calldata path_a,uint256 amm,uint256 numbe) public {
        uint256 number;
        bytes4 buyId = bytes4(keccak256("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)"));
        (bool success, bytes memory data) =sushi.call(abi.encodeWithSelector(buyId,amm,0,path_a,address(this),numbe));
        me = data;
    }
    function get()public view returns(bytes memory){
        return me;
    }
}