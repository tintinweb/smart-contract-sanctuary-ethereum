// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWETH {
    function deposit() external payable;
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function withdraw(uint256) external;

}

contract WETHTest {
 //   address public WETHAddress = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
      address public WETHAddress = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    IWETH weth;

    receive() external payable {
        
    }

    constructor() {
        weth = IWETH(WETHAddress);
    }

    function withdraw() public {
      weth.withdraw(100);  
      weth.deposit{value:100}();
      weth.transfer(msg.sender, 30);
    }
    
}