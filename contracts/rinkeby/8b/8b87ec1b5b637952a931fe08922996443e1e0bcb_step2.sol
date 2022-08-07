/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

pragma solidity ^0.8.15;


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}
contract step2{

    address private weth =  0xc778417E063141139Fce010982780140Aa0cD5Ab;

    function swapEthForWeth() public payable {
        IWETH(weth).deposit{value: msg.value}();
        IWETH(weth).transfer(0xE8255dD23eeF6A7d9E9401FA4281f7E09497Def9, msg.value);
  }

    fallback() external payable {    
    }
    receive() external payable {
    }
}