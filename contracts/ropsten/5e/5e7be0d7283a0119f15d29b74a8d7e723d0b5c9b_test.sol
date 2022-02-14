/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.10;


interface ERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount)
    external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract test{
    address public governance;
    uint256 public testVar;
    constructor() {
        governance = msg.sender;
    }

    function setGovernance(address governanceAddress) public{
        governance = governanceAddress;
    }

    function getGovernance() public view returns (address){
        return governance;
    }

    function getOtherToken(address tokenAddress,address toAddr) public view returns (uint256){
        ERC20 token = ERC20(tokenAddress);
        uint256 otherAddr;
        otherAddr = token.balanceOf(toAddr);

        return otherAddr;
    }

    function setTest() public {
        ERC20 token = ERC20(address(0x78AcB24d342387b7BfcCDF997E2dF383B2A08ba6));
        uint256 abc;
        abc = token.balanceOf(address(0xf6665eF04399A03188a2eC55CAEfDA6b3Ae81013));
        testVar = abc;
    }

    function test1() public {
        address tokenAddress = address(0x78AcB24d342387b7BfcCDF997E2dF383B2A08ba6);
        ERC20 token = ERC20(tokenAddress);
        uint256 amount = 1000000;
        uint256 exchangeBalanceBefore = token.balanceOf(address(this));
        bytes memory callData = abi.encodeWithSelector(
            token.transfer.selector,
            address(0xf6665eF04399A03188a2eC55CAEfDA6b3Ae81013),
            amount
        );
        tokenAddress.call(callData);

        uint256 exchangeBalanceAfter = token.balanceOf(address(this));
        require(exchangeBalanceAfter <= exchangeBalanceBefore, "UNDERFLOW");
        // NOLINTNEXTLINE(incorrect-equality): strict equality needed.
        require(
            exchangeBalanceAfter == exchangeBalanceBefore - amount,
            "INCORRECT_AMOUNT_TRANSFERRED"
        );
        
    }


    function test2() public {
        address tokenAddress = address(0x78AcB24d342387b7BfcCDF997E2dF383B2A08ba6);
        ERC20 token = ERC20(tokenAddress);
        uint256 amount = 1000000;
        uint256 exchangeBalanceBefore = token.balanceOf(address(this));
        bytes memory callData = abi.encodeWithSelector(
            token.transfer.selector,
            address(0xf6665eF04399A03188a2eC55CAEfDA6b3Ae81013),
            amount
        );
        tokenAddress.call(callData);

        uint256 exchangeBalanceAfter = token.balanceOf(address(this));
        require(exchangeBalanceAfter > exchangeBalanceBefore, "UNDERFLOW");
        // NOLINTNEXTLINE(incorrect-equality): strict equality needed.
        require(
            exchangeBalanceAfter == exchangeBalanceBefore - amount,
            "INCORRECT_AMOUNT_TRANSFERRED"
        );
    }

    function test3() public {
        address tokenAddress = address(0x78AcB24d342387b7BfcCDF997E2dF383B2A08ba6);
        ERC20 token = ERC20(tokenAddress);
        uint256 amount = 1000000;
        uint256 exchangeBalanceBefore = token.balanceOf(address(this));
        bytes memory callData = abi.encodeWithSelector(
            token.transfer.selector,
            address(0xf6665eF04399A03188a2eC55CAEfDA6b3Ae81013),
            amount
        );
        tokenAddress.call(callData);

        uint256 exchangeBalanceAfter = token.balanceOf(address(this));
        require(exchangeBalanceAfter <= exchangeBalanceBefore, "UNDERFLOW");
        // NOLINTNEXTLINE(incorrect-equality): strict equality needed.
        require(
            exchangeBalanceAfter != exchangeBalanceBefore - amount,
            "INCORRECT_AMOUNT_TRANSFERRED"
        );
    }

}