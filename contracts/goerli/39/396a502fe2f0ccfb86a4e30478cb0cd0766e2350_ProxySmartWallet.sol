/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Proxy {

	receive()  external payable {}
	fallback () payable external {
		_fallback();
	}

	function _implementation() virtual internal view returns (address);

	function _delegate(address implementation) internal {
		assembly {
			calldatacopy(0, 0, calldatasize())
			let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
			returndatacopy(0, 0, returndatasize())
			switch result
			case 0 { revert(0, returndatasize()) }
			default { return(0, returndatasize()) }
		}
	}

	function _willFallback() virtual internal {
	}

	function _fallback() internal {
		_willFallback();
		_delegate(_implementation());
	}
}

library AddressUtils {

	function isContract(address addr) internal view returns (bool) {
		uint256 size;
		assembly { size := extcodesize(addr) }
		return size > 0;
	}

}

contract UpgradeabilityProxy is Proxy {

	event Upgraded(address implementation);

	bytes32 private constant IMPLEMENTATION_SLOT = 0x132950415ed136b703a9e56119e2b16770f7b2f77770b3ab15e4552628b57713;

	constructor(address _implementation_addr) {
		assert(IMPLEMENTATION_SLOT == keccak256("excryp.proxy.implementation.address"));

		_setImplementation(_implementation_addr);
	}

	function _implementation() internal override view returns (address impl) {
		bytes32 slot = IMPLEMENTATION_SLOT;
		assembly {
			impl := sload(slot)
		}
	}

	function _upgradeTo(address newImplementation) internal {
		_setImplementation(newImplementation);
		emit Upgraded(newImplementation);
	}

	function _setImplementation(address newImplementation) private {
		require(AddressUtils.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

		bytes32 slot = IMPLEMENTATION_SLOT;

		assembly {
			sstore(slot, newImplementation)
		}
	}
}

contract AdminUpgradeabilityProxy is UpgradeabilityProxy {

	event AdminChanged(address previousAdmin, address newAdmin);

	bytes32 private constant ADMIN_SLOT = 0x6c1cd3c81f3419599797d14388804eac1727cb843ebe0ab5b33351c8a02893a4;

	modifier ifAdmin() {
		if (msg.sender == _admin()) {
			_;
		} else {
			_fallback();
		}
	}

	constructor(address _implementation_addr) UpgradeabilityProxy(_implementation_addr) {
		assert(ADMIN_SLOT == keccak256("excryp.proxy.admin.address"));

		_setAdmin(msg.sender);
	}

	function admin() external ifAdmin returns (address) {
		return _admin();
	}

	function implementation() external ifAdmin returns (address) {
		return _implementation();
	}

	function changeAdmin(address newAdmin) external ifAdmin {
		require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
		emit AdminChanged(_admin(), newAdmin);
		_setAdmin(newAdmin);
	}

	function upgradeTo(address newImplementation) external ifAdmin {
		_upgradeTo(newImplementation);
	}

	function upgradeToAndCall(address newImplementation, bytes calldata data) payable external ifAdmin {
		_upgradeTo(newImplementation);
		(bool sent,) = address(this).call{value: msg.value}(data);
		require(sent);
	}

	function _admin() internal view returns (address adm) {
		bytes32 slot = ADMIN_SLOT;
		assembly {
			adm := sload(slot)
		}
	}

	function _setAdmin(address newAdmin) internal {
		bytes32 slot = ADMIN_SLOT;

		assembly {
			sstore(slot, newAdmin)
		}
	}

	function _willFallback() internal override {
		require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
		super._willFallback();
	}
}

contract ProxySmartWallet is AdminUpgradeabilityProxy {
	constructor(address _implementation) AdminUpgradeabilityProxy(_implementation) {
	}
}