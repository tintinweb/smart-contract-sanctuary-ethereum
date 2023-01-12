// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IVaultsRegistryHelper {
    function registry() external view returns (address _registry);

    function getVaults() external view returns (address[] memory _vaults);

    function getVaultStrategies(address _vault) external view returns (address[] memory _strategies);

    function getVaultsAndStrategies() external view returns (address[] memory _vaults, address[] memory _strategies);
}

interface IV2Registry {
    function getVault(uint256 index) external view returns (address vault);

    function getVaults() external view returns (address[] memory);

    function numTokens() external view returns (uint256 _numTokens);

    function tokens(uint256 _index) external view returns (address _token);

    function vaults(address _token, uint256 _index) external view returns (address _vault);
}

contract VaultsRegistryHelper2 {
    // using Address for address;

    address public immutable registry;
    address public immutable newRegistry;

    constructor(address _registry, address _newRegistry) {
        registry = _registry;
        newRegistry = _newRegistry;
    }

    function getVaults() public view returns (address[] memory _vaults) {
        uint256 _tokensLength = IV2Registry(registry).numTokens();
        // vaults = [];
        address[] memory _vaultsArray = new address[](_tokensLength * 20); // MAX length
        uint256 _vaultIndex = 0;
        for (uint256 i; i < _tokensLength; i++) {
            address _token = IV2Registry(registry).tokens(i);
            for (uint256 j; j < 20; j++) {
                address _vault = IV2Registry(registry).vaults(_token, j);
                if (_vault == address(0)) break;
                _vaultsArray[_vaultIndex] = _vault;
                _vaultIndex++;
            }
        }

        _tokensLength = IV2Registry(newRegistry).numTokens();
        for (uint i; i < _tokensLength; i++) {
            address _token = IV2Registry(newRegistry).tokens(i);
            for (uint j; j < 20; j++) {
                try IV2Registry(newRegistry).vaults(_token, j) {
                    address _vault = IV2Registry(newRegistry).vaults(_token, j);
                    _vaultsArray[_vaultIndex] = _vault;
                    _vaultIndex++;
                } catch {
                    break;
                }
            }
        }

        _vaults = new address[](_vaultIndex);
        for (uint256 i; i < _vaultIndex; i++) {
            _vaults[i] = _vaultsArray[i];
        }
    }
}