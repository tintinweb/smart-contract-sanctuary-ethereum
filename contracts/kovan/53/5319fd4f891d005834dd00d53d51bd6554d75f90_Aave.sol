/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

   interface IAave {
    function deposit(address _asset, uint256 _amount, address _onBehalfOf, uint16 _referralCode) external;
    function withdraw(address _asset, uint256 _amount, address _to) external;
    function borrow(
        address _asset,
        uint256 _amount,
        uint256 _interestRateMode,
        uint16 _referralCode,
        address _onBehalfOf
    ) external;
    function repay(address _asset, uint256 _amount, uint256 _rateMode, address _onBehalfOf) external;
}
interface Itoken {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface LendingPoolAddressesProvider {
    function getLendingPool() external returns (address);
}

contract Aave{

    address constant weth = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
 
    function deposit(
        uint256 amt
    ) external payable {
        LendingPoolAddressesProvider provider = LendingPoolAddressesProvider(0x88757f2f99175387aB4C6a4b3067c77A695b0349);
        // IAave aave = IAave(0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe);
        IAave aave = IAave(provider.getLendingPool());

        address tokenaddr = weth;

        Itoken token = Itoken(tokenaddr);
        token.deposit{value: amt}();
        token.approve(address(aave), amt);
        aave.deposit(tokenaddr, amt, address(this), 0);
    }
}