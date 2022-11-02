/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

pragma solidity 0.8.10;

contract Factory {
    struct Recipient {
        address recipient;
        string title;
    }

    struct PaymentsLimitsConfig {
        uint256 limit;
        uint256 spentAmount;
        uint256 periodDurationMonths;
    }

    struct DeployConfig {
        address trustedCaller;
        Recipient[] recipients;
        PaymentsLimitsConfig paymentsLimitsConfig;
    }

    struct Deployment {
        address allowedRecipientsRegistry;
        address topUpAllowedRecipientEVMScriptFactory;
        address addUpAllowedRecipientEVMScriptFactory;
        address removeUpAllowedRecipientEVMScriptFactory;
    }

    function deploy(DeployConfig memory config) external pure returns (Deployment memory) {}
}