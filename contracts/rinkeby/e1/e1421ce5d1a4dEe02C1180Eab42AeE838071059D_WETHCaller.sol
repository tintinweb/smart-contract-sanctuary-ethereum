// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function withdraw(uint256) external;

}

interface IWETHTest {
    function withdraw() external;
}

contract WETHCaller {
//    address public WETHAddress = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address public WETHAddress = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    IWETH weth;
    uint256 public supply;

    constructor() {
        weth = IWETH(WETHAddress);
    }

    receive() external payable {
        
    }

    function WETHCallerTest1(address to) public payable {
        weth.deposit{value:100}();
        supply = weth.totalSupply();
        weth.transfer(to, 100);
        IWETHTest wethtest = IWETHTest(to);
        wethtest.withdraw();
        weth.withdraw(20);
        payable(msg.sender).transfer(20);
    }

    function getBalance() public view returns (uint256){
        return weth.balanceOf(address(this));
    }

    function getBalanceOf(address addr) public view returns (uint256) {
        return weth.balanceOf(addr);
    }


}