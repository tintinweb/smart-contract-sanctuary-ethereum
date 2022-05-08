/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

pragma solidity ^0.4.24;










contract WithCoffeeToken {
    /*name : 토큰이름 , symbol: 토큰기호 , decimals: 토큰소수자리수 , totalSupply : 총 토큰 공급량*/
    string public constant name = "aaa";
    string public constant symbol = "aaa";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 165e18;
    function a() public view returns (uint) {
        return block.number;
    }
    
}