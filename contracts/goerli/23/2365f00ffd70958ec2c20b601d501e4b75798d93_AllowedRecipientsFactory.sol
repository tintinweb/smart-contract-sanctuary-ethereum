/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

pragma solidity 0.8.10;

contract AllowedRecipientsFactory {
    /// @notice Data with funds recipient info
    /// @param title_ Label of the funds recipient
    /// @param recipient Address of the funds recipient
    struct RecipientInfo {
        string title;
        address recipient;
    }

    function finance() external view returns (address) {}
    function daoAgent() external view returns (address) {}
    function easyTrack() external view returns (address) {}
    function evmScriptExecutor() external view returns (address) {}
    function bokkyPooBahsDateTimeContract() external view returns (address) {}
    
    /// @notice Deploys instance of the AllowedRecipientsRegistry and setup it to use with EasyTracks
    /// @param limit_ Amount of the funds to spent in the period
    /// @param spentAmount_ Amount of the funds spent in current period
    /// @param periodDurationMonths_ The length of the period
    /// @param _recipients The recipients info to add into the deployed AllowedRecipientsRegistry
    /// @return allowedRecipientsRegistry_ Address of newly deployed AllowedRecipientsRegistry
    function deployAllowedRecipientsRegistry(
        uint256 limit_,
        uint256 spentAmount_,
        uint256 periodDurationMonths_,
        RecipientInfo[] calldata _recipients
    ) external returns (address allowedRecipientsRegistry_) {}
    
    function deployAddAllowedRecipientEVMScriptFactory(
        address trustedCaller_,
        address registry_
    ) external returns (address) {}
    
    function deployRemoveAllowedRecipientEVMScriptFactory(
        address trustedCaller_,
        address registry_
    ) external returns (address) {}
    
    function deployTopUpAllowedRecipientEVMScriptFactory(
        address trustedCaller_,
        address registry_,
        address token_
    ) external returns (address) {}
    
}