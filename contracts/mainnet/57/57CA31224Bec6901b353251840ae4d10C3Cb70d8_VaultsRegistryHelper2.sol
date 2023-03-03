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

    function vaultType(address) external view returns (uint);

    function getVaults() external view returns (address[] memory);

    function numTokens() external view returns (uint256 _numTokens);

    function tokens(uint256 _index) external view returns (address _token);

    function vaults(address _token, uint256 _index) external view returns (address _vault);
}

contract VaultsRegistryHelper2 {

    address public registry;
    address public newRegistry;

    function init(address _registry, address _newRegistry) external {
        require(registry == address(0));
        registry = _registry;
        newRegistry = _newRegistry;
    }

    function getVaults() external view returns (address[] memory _vaults) {
        return _getVaults();
    }

    function getVaultsOfType(uint typeID) external view returns (address[] memory _vaults) {
        address[] memory allVaults = _getVaults();
        uint idx;
        address[] memory _vaultsArray = new address[](allVaults.length); // MAX length
        
        for (uint256 i; i < allVaults.length; i++) {
            uint t = IV2Registry(newRegistry).vaultType(allVaults[i]);
            if (typeID == t) _vaultsArray[idx++] = allVaults[i];
        }
        _vaults = new address[](idx);
        for (uint256 i; i < idx; i++) {
            _vaults[i] = _vaultsArray[i];
        }
    }

    function _getVaults() internal view returns (address[] memory _vaults) {
        uint256 _tokensLength = IV2Registry(registry).numTokens();
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