/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

pragma solidity ^0.4.24;


interface IERC20 {
    function balanceOf() external view returns (uint);
}





contract WithCoffeeToken is IERC20{
    /*name : 토큰이름 , symbol: 토큰기호 , decimals: 토큰소수자리수 , totalSupply : 총 토큰 공급량*/
    string public constant name = "aaa";
    string public constant symbol = "aaa";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 165e18;
    function balanceOf() public view returns (uint) {
        return block.number;
    }
}