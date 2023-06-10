// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Crowdsale.sol";
import "./Kyc.sol";

contract FluwixTokenSale is Crowdsale {
    Kyc kyc;

    constructor(
        uint256 rate, // rate in TKNbits
        address payable wallet,
        IERC20 token,
        Kyc _kyc
    ) Crowdsale(rate, wallet, token) {
        kyc = _kyc;
    }

    function _preValidatePurchase(
        address beneficiary,
        uint256 weiAmount
    ) internal view override {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(
            kyc.isKycCompleted(msg.sender),
            "KYC not completed, token purchase not allowed."
        );
    }
}