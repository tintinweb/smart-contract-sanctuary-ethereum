/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVault {
	function token() external view returns (address);
}

interface IRegistry {
	function numVaults(address) external view returns (uint256);
	function vaults(address, uint256) external view returns (address);
    function isRegistered(address) external view returns (bool);
}

interface IAddressesProvider {
	function addressById(string memory) external view returns (address);
}

interface IRegistryAdapter {
	function registryAddress() external view returns (address);
}

contract AllowlistImplementationPartnerTracker {
	address constant public partnerTracker = 0x8ee392a4787397126C163Cb9844d7c447da419D8;
	address public addressesProviderAddress;

	constructor(address _addressesProviderAddress) {
		addressesProviderAddress = _addressesProviderAddress;
	}

	/**
	* @notice Determine whether the address is yearn's deployed partner tracker contract
	* @param _address the address to validate
	* @return returns true if the input is the partner tracker
	*/
	function isPartnerTracker(address _address) external view returns (bool) {
		return _address == partnerTracker;
	}

	/**
	* @notice Determine whether or not a vault address is a valid vault
	* @param vaultAddress The vault address to test
	* @return Returns true if the valid address is valid and false if not
	*/
	function isVault(address vaultAddress) public view returns (bool) {
		IVault vault = IVault(vaultAddress);
		address tokenAddress;
		try vault.token() returns (address _tokenAddress) {
			tokenAddress = _tokenAddress;
		} catch {
			return false;
		}
		uint256 numVaults = registry().numVaults(tokenAddress);
		for (uint256 vaultIdx; vaultIdx < numVaults; vaultIdx++) {
			address currentVaultAddress = registry().vaults(tokenAddress, vaultIdx);
			if (currentVaultAddress == vaultAddress) {
				return true;
			}
		}
		return false;
	}
	
	/**
	 * @notice Determine whether or not a vault address is a valid vault
	 * @param tokenAddress The vault token address to test
	 * @return Returns true if the valid address is valid and false if not
	 */
	function isVaultUnderlyingToken(address tokenAddress)
	  public
	  view
	  returns (bool)
	{
	  return registry().isRegistered(tokenAddress);
	}

	/**
	* @dev Fetch registry adapter address
	*/
	function registryAdapterAddress() public view returns (address) {
		return
			IAddressesProvider(addressesProviderAddress).addressById(
				"REGISTRY_ADAPTER_V2_VAULTS"
	  		);
  	}

	/**
	* @dev Fetch registry adapter interface
	*/
	function registryAdapter() internal view returns (IRegistryAdapter) {
		return IRegistryAdapter(registryAdapterAddress());
	}

	/**
	* @dev Fetch registry address
	*/
	function registryAddress() public view returns (address) {
		return registryAdapter().registryAddress();
	}

	/**
	* @dev Fetch registry interface
	*/
	function registry() internal view returns (IRegistry) {
		return IRegistry(registryAddress());
	}
}