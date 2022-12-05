/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IVaultProxyManager {
    struct VaultInfo {
        address org; // org
        address token; // token
        uint256 vid; // Vault Id
        string name; // Vault name
    }

    event VaultCreated(
        string name,
        address org,
        address vault,
        address token,
        uint256 vid
    );

    event FactorySet(address factory);

    event FeeRateSet(uint256 feeRate);

    event AdminSet(address admin);

    event NewOrgSet(string orgName, address curOrg, address newOrg);

    event TokenAdded(address token);

    event TokenRemoved(address token);

    function createVault(
        string memory name,
        address org,
        address vault,
        address token,
        uint256 vid
    ) external;

    function setFeeRate(uint256 feeRate) external;

    function transferOwnership(address vault, address newOrg) external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);

    function admin() external view returns (address);

    function token(address vault) external view returns (address);

    function org(address vault) external view returns (address);

    function feeRate() external view returns (uint256);

    function factory() external view returns (address);

    function getDepositAmountAtVault(
        address account,
        string memory vaultName
    ) external view returns (uint256 amount);

    function getVaultByName(string memory name) external view returns (address);

    function getVaultInfo(
        address vault
    ) external view returns (VaultInfo memory);

    function getDefaultToken() external view returns (address);

    function isTokenSupported(address token) external view returns (bool);

    function supportedTokens() external view returns (address[] memory);

    function addToken(address token) external;

    function removeToken(address token) external;

    function getVaultsByOrg(
        address _orgAddress
    ) external view returns (address[] memory);
}

interface IGuildAdapter {
    function getDepositAmountAtVault(
        address account,
        string memory vaultName
    ) external view returns (uint256 amount);
}

contract GuildAdapter is IGuildAdapter {
    address public constant SUBSTAKE_VAULT_MANAGER =
        0xF69a3A6D99F4e9cd94792164389A1c71962b5DcC;

    function getDepositAmountAtVault(
        address account,
        string memory vaultName
    ) external view override returns (uint256 amount) {
        return
            IVaultProxyManager(SUBSTAKE_VAULT_MANAGER).getDepositAmountAtVault(
                account,
                vaultName
            );
    }
}