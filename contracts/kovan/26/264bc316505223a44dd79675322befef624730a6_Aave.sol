/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

   interface AaveInterface {
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
    function setUserUseReserveAsCollateral(address _asset, bool _useAsCollateral) external;
    function swapBorrowRateMode(address _asset, uint256 _rateMode) external;
}
interface TokenInterface {
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

    address constant weth = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
 
    function deposit(
        // address token,
        uint256 amt
    ) external payable {
        LendingPoolAddressesProvider aaveProvider = LendingPoolAddressesProvider(0x88757f2f99175387aB4C6a4b3067c77A695b0349);
        AaveInterface aave = AaveInterface(0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe);
        aave = AaveInterface(aaveProvider.getLendingPool());

        address _token = weth;

        TokenInterface tokenContract = TokenInterface(_token);

        // if (isEth) {
        //     _amt = _amt == uint(-1) ? address(this).balance : _amt;
        //     convertEthToWeth(isEth, tokenContract, _amt);
        // } else {
        //     _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
        // }

        tokenContract.approve(address(aave), amt);
        tokenContract.deposit{value: amt}();
        aave.deposit(_token, amt, address(this), 0);

        // if (!getIsColl(_token)) {
        //     aave.setUserUseReserveAsCollateral(_token, true);
        // }

    }
}