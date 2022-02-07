/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAave {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external;

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external;
}

interface Itoken {
    function approve(address, uint256) external;

    function transfer(address, uint256) external;

    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address) external view returns (uint256);
}

interface LendingPoolAddressesProvider {
    function getLendingPool() external returns (address);
}

contract Aave {
    address constant weth = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;

    function deposit(uint256 amt) external payable {
        LendingPoolAddressesProvider provider = LendingPoolAddressesProvider(
            0x88757f2f99175387aB4C6a4b3067c77A695b0349
        );
        // IAave aave = IAave(0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe);
        IAave aave = IAave(provider.getLendingPool());

        address tokenaddr = weth;

        Itoken token = Itoken(tokenaddr);
        token.deposit{value: amt}();
        token.approve(address(aave), amt);
        aave.deposit(tokenaddr, amt, address(this), 0);
    }
}