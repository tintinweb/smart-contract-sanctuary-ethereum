// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {ERC20} from './ERC20.sol';
import {SafeTransferLib} from "./SafeTransferLib.sol";

contract TokenTypeSplitter {
    /// -------------------------------------------------------------------
    /// libraries
    /// -------------------------------------------------------------------

    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    /// -------------------------------------------------------------------
    /// storage
    /// -------------------------------------------------------------------

    /// Address to receive funds eth funds
    address public immutable ethBeneficiary;
    /// Address to receive funds eth funds
    address public immutable erc20Beneficiary;

    /// -------------------------------------------------------------------
    /// constructor
    /// -------------------------------------------------------------------

    constructor(address _ethBeneficiary, address _erc20Beneficiary) {
        ethBeneficiary = _ethBeneficiary;
        erc20Beneficiary = _erc20Beneficiary;
    }

    /// -------------------------------------------------------------------
    /// functions
    /// -------------------------------------------------------------------

    /// -------------------------------------------------------------------
    /// functions - public & external
    /// -------------------------------------------------------------------

    /// @notice receive ETH
    receive() external payable {}

    /// pay eth in contract to `ethBeneficiary`
    function payETHBeneficiary() external {
        ethBeneficiary.safeTransferETH(address(this).balance);
    }

    /// pay erc20 `token` in contract to `ethBeneficiary`
    function payERC20Beneficiary(ERC20 token) external {
        token.safeTransfer(erc20Beneficiary, token.balanceOf(address(this)));
    }
}