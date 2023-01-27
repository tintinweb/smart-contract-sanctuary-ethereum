// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

// We import the contract so truffle compiles it, and we have the ABI
// available when working from truffle console.
import "@gnosis.pm/mock-contract/contracts/MockContract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2ERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol" as ISushiswapV2Router;
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol" as ISushiswapV2Factory;
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2ERC20.sol" as ISushiswapV2ERC20;
import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/ProxyAdmin.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

pragma solidity ^0.6.0;

interface MockInterface {
	/**
	 * @dev After calling this method, the mock will return `response` when it is called
	 * with any calldata that is not mocked more specifically below
	 * (e.g. using givenMethodReturn).
	 * @param response ABI encoded response that will be returned if method is invoked
	 */
	function givenAnyReturn(bytes calldata response) external;
	function givenAnyReturnBool(bool response) external;
	function givenAnyReturnUint(uint response) external;
	function givenAnyReturnAddress(address response) external;

	function givenAnyRevert() external;
	function givenAnyRevertWithMessage(string calldata message) external;
	function givenAnyRunOutOfGas() external;

	/**
	 * @dev After calling this method, the mock will return `response` when the given
	 * methodId is called regardless of arguments. If the methodId and arguments
	 * are mocked more specifically (using `givenMethodAndArguments`) the latter
	 * will take precedence.
	 * @param method ABI encoded methodId. It is valid to pass full calldata (including arguments). The mock will extract the methodId from it
	 * @param response ABI encoded response that will be returned if method is invoked
	 */
	function givenMethodReturn(bytes calldata method, bytes calldata response) external;
	function givenMethodReturnBool(bytes calldata method, bool response) external;
	function givenMethodReturnUint(bytes calldata method, uint response) external;
	function givenMethodReturnAddress(bytes calldata method, address response) external;

	function givenMethodRevert(bytes calldata method) external;
	function givenMethodRevertWithMessage(bytes calldata method, string calldata message) external;
	function givenMethodRunOutOfGas(bytes calldata method) external;

	/**
	 * @dev After calling this method, the mock will return `response` when the given
	 * methodId is called with matching arguments. These exact calldataMocks will take
	 * precedence over all other calldataMocks.
	 * @param call ABI encoded calldata (methodId and arguments)
	 * @param response ABI encoded response that will be returned if contract is invoked with calldata
	 */
	function givenCalldataReturn(bytes calldata call, bytes calldata response) external;
	function givenCalldataReturnBool(bytes calldata call, bool response) external;
	function givenCalldataReturnUint(bytes calldata call, uint response) external;
	function givenCalldataReturnAddress(bytes calldata call, address response) external;

	function givenCalldataRevert(bytes calldata call) external;
	function givenCalldataRevertWithMessage(bytes calldata call, string calldata message) external;
	function givenCalldataRunOutOfGas(bytes calldata call) external;

	/**
	 * @dev Returns the number of times anything has been called on this mock since last reset
	 */
	function invocationCount() external returns (uint);

	/**
	 * @dev Returns the number of times the given method has been called on this mock since last reset
	 * @param method ABI encoded methodId. It is valid to pass full calldata (including arguments). The mock will extract the methodId from it
	 */
	function invocationCountForMethod(bytes calldata method) external returns (uint);

	/**
	 * @dev Returns the number of times this mock has been called with the exact calldata since last reset.
	 * @param call ABI encoded calldata (methodId and arguments)
	 */
	function invocationCountForCalldata(bytes calldata call) external returns (uint);

	/**
	 * @dev Resets all mocked methods and invocation counts.
	 */
	 function reset() external;
}

/**
 * Implementation of the MockInterface.
 */
contract MockContract is MockInterface {
	enum MockType { Return, Revert, OutOfGas }
	
	bytes32 public constant MOCKS_LIST_START = hex"01";
	bytes public constant MOCKS_LIST_END = "0xff";
	bytes32 public constant MOCKS_LIST_END_HASH = keccak256(MOCKS_LIST_END);
	bytes4 public constant SENTINEL_ANY_MOCKS = hex"01";
	bytes public constant DEFAULT_FALLBACK_VALUE = abi.encode(false);

	// A linked list allows easy iteration and inclusion checks
	mapping(bytes32 => bytes) calldataMocks;
	mapping(bytes => MockType) calldataMockTypes;
	mapping(bytes => bytes) calldataExpectations;
	mapping(bytes => string) calldataRevertMessage;
	mapping(bytes32 => uint) calldataInvocations;

	mapping(bytes4 => bytes4) methodIdMocks;
	mapping(bytes4 => MockType) methodIdMockTypes;
	mapping(bytes4 => bytes) methodIdExpectations;
	mapping(bytes4 => string) methodIdRevertMessages;
	mapping(bytes32 => uint) methodIdInvocations;

	MockType fallbackMockType;
	bytes fallbackExpectation = DEFAULT_FALLBACK_VALUE;
	string fallbackRevertMessage;
	uint invocations;
	uint resetCount;

	constructor() public {
		calldataMocks[MOCKS_LIST_START] = MOCKS_LIST_END;
		methodIdMocks[SENTINEL_ANY_MOCKS] = SENTINEL_ANY_MOCKS;
	}

	function trackCalldataMock(bytes memory call) private {
		bytes32 callHash = keccak256(call);
		if (calldataMocks[callHash].length == 0) {
			calldataMocks[callHash] = calldataMocks[MOCKS_LIST_START];
			calldataMocks[MOCKS_LIST_START] = call;
		}
	}

	function trackMethodIdMock(bytes4 methodId) private {
		if (methodIdMocks[methodId] == 0x0) {
			methodIdMocks[methodId] = methodIdMocks[SENTINEL_ANY_MOCKS];
			methodIdMocks[SENTINEL_ANY_MOCKS] = methodId;
		}
	}

	function _givenAnyReturn(bytes memory response) internal {
		fallbackMockType = MockType.Return;
		fallbackExpectation = response;
	}

	function givenAnyReturn(bytes calldata response) override external {
		_givenAnyReturn(response);
	}

	function givenAnyReturnBool(bool response) override external {
		uint flag = response ? 1 : 0;
		_givenAnyReturn(uintToBytes(flag));
	}

	function givenAnyReturnUint(uint response) override external {
		_givenAnyReturn(uintToBytes(response));	
	}

	function givenAnyReturnAddress(address response) override external {
		_givenAnyReturn(uintToBytes(uint(response)));
	}

	function givenAnyRevert() override external {
		fallbackMockType = MockType.Revert;
		fallbackRevertMessage = "";
	}

	function givenAnyRevertWithMessage(string calldata message) override external {
		fallbackMockType = MockType.Revert;
		fallbackRevertMessage = message;
	}

	function givenAnyRunOutOfGas() override external {
		fallbackMockType = MockType.OutOfGas;
	}

	function _givenCalldataReturn(bytes memory call, bytes memory response) private  {
		calldataMockTypes[call] = MockType.Return;
		calldataExpectations[call] = response;
		trackCalldataMock(call);
	}

	function givenCalldataReturn(bytes calldata call, bytes calldata response) override external  {
		_givenCalldataReturn(call, response);
	}

	function givenCalldataReturnBool(bytes calldata call, bool response) override external {
		uint flag = response ? 1 : 0;
		_givenCalldataReturn(call, uintToBytes(flag));
	}

	function givenCalldataReturnUint(bytes calldata call, uint response) override external {
		_givenCalldataReturn(call, uintToBytes(response));
	}

	function givenCalldataReturnAddress(bytes calldata call, address response) override external {
		_givenCalldataReturn(call, uintToBytes(uint(response)));
	}

	function _givenMethodReturn(bytes memory call, bytes memory response) private {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.Return;
		methodIdExpectations[method] = response;
		trackMethodIdMock(method);		
	}

	function givenMethodReturn(bytes calldata call, bytes calldata response) override external {
		_givenMethodReturn(call, response);
	}

	function givenMethodReturnBool(bytes calldata call, bool response) override external {
		uint flag = response ? 1 : 0;
		_givenMethodReturn(call, uintToBytes(flag));
	}

	function givenMethodReturnUint(bytes calldata call, uint response) override external {
		_givenMethodReturn(call, uintToBytes(response));
	}

	function givenMethodReturnAddress(bytes calldata call, address response) override external {
		_givenMethodReturn(call, uintToBytes(uint(response)));
	}

	function givenCalldataRevert(bytes calldata call) override external {
		calldataMockTypes[call] = MockType.Revert;
		calldataRevertMessage[call] = "";
		trackCalldataMock(call);
	}

	function givenMethodRevert(bytes calldata call) override external {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.Revert;
		trackMethodIdMock(method);		
	}

	function givenCalldataRevertWithMessage(bytes calldata call, string calldata message) override external {
		calldataMockTypes[call] = MockType.Revert;
		calldataRevertMessage[call] = message;
		trackCalldataMock(call);
	}

	function givenMethodRevertWithMessage(bytes calldata call, string calldata message) override external {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.Revert;
		methodIdRevertMessages[method] = message;
		trackMethodIdMock(method);		
	}

	function givenCalldataRunOutOfGas(bytes calldata call) override external {
		calldataMockTypes[call] = MockType.OutOfGas;
		trackCalldataMock(call);
	}

	function givenMethodRunOutOfGas(bytes calldata call) override external {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.OutOfGas;
		trackMethodIdMock(method);	
	}

	function invocationCount() override external returns (uint) {
		return invocations;
	}

	function invocationCountForMethod(bytes calldata call) override external returns (uint) {
		bytes4 method = bytesToBytes4(call);
		return methodIdInvocations[keccak256(abi.encodePacked(resetCount, method))];
	}

	function invocationCountForCalldata(bytes calldata call) override external returns (uint) {
		return calldataInvocations[keccak256(abi.encodePacked(resetCount, call))];
	}

	function reset() override external {
		// Reset all exact calldataMocks
		bytes memory nextMock = calldataMocks[MOCKS_LIST_START];
		bytes32 mockHash = keccak256(nextMock);
		// We cannot compary bytes
		while(mockHash != MOCKS_LIST_END_HASH) {
			// Reset all mock maps
			calldataMockTypes[nextMock] = MockType.Return;
			calldataExpectations[nextMock] = hex"";
			calldataRevertMessage[nextMock] = "";
			// Set next mock to remove
			nextMock = calldataMocks[mockHash];
			// Remove from linked list
			calldataMocks[mockHash] = "";
			// Update mock hash
			mockHash = keccak256(nextMock);
		}
		// Clear list
		calldataMocks[MOCKS_LIST_START] = MOCKS_LIST_END;

		// Reset all any calldataMocks
		bytes4 nextAnyMock = methodIdMocks[SENTINEL_ANY_MOCKS];
		while(nextAnyMock != SENTINEL_ANY_MOCKS) {
			bytes4 currentAnyMock = nextAnyMock;
			methodIdMockTypes[currentAnyMock] = MockType.Return;
			methodIdExpectations[currentAnyMock] = hex"";
			methodIdRevertMessages[currentAnyMock] = "";
			nextAnyMock = methodIdMocks[currentAnyMock];
			// Remove from linked list
			methodIdMocks[currentAnyMock] = 0x0;
		}
		// Clear list
		methodIdMocks[SENTINEL_ANY_MOCKS] = SENTINEL_ANY_MOCKS;

		fallbackExpectation = DEFAULT_FALLBACK_VALUE;
		fallbackMockType = MockType.Return;
		invocations = 0;
		resetCount += 1;
	}

	function useAllGas() private {
		while(true) {
			bool s;
			assembly {
				//expensive call to EC multiply contract
				s := call(sub(gas(), 2000), 6, 0, 0x0, 0xc0, 0x0, 0x60)
			}
		}
	}

	function bytesToBytes4(bytes memory b) private pure returns (bytes4) {
		bytes4 out;
		for (uint i = 0; i < 4; i++) {
			out |= bytes4(b[i] & 0xFF) >> (i * 8);
		}
		return out;
	}

	function uintToBytes(uint256 x) private pure returns (bytes memory b) {
		b = new bytes(32);
		assembly { mstore(add(b, 32), x) }
	}

	function updateInvocationCount(bytes4 methodId, bytes memory originalMsgData) public {
		require(msg.sender == address(this), "Can only be called from the contract itself");
		invocations += 1;
		methodIdInvocations[keccak256(abi.encodePacked(resetCount, methodId))] += 1;
		calldataInvocations[keccak256(abi.encodePacked(resetCount, originalMsgData))] += 1;
	}

	fallback () payable external {
		bytes4 methodId;
		assembly {
			methodId := calldataload(0)
		}

		// First, check exact matching overrides
		if (calldataMockTypes[msg.data] == MockType.Revert) {
			revert(calldataRevertMessage[msg.data]);
		}
		if (calldataMockTypes[msg.data] == MockType.OutOfGas) {
			useAllGas();
		}
		bytes memory result = calldataExpectations[msg.data];

		// Then check method Id overrides
		if (result.length == 0) {
			if (methodIdMockTypes[methodId] == MockType.Revert) {
				revert(methodIdRevertMessages[methodId]);
			}
			if (methodIdMockTypes[methodId] == MockType.OutOfGas) {
				useAllGas();
			}
			result = methodIdExpectations[methodId];
		}

		// Last, use the fallback override
		if (result.length == 0) {
			if (fallbackMockType == MockType.Revert) {
				revert(fallbackRevertMessage);
			}
			if (fallbackMockType == MockType.OutOfGas) {
				useAllGas();
			}
			result = fallbackExpectation;
		}

		// Record invocation as separate call so we don't rollback in case we are called with STATICCALL
		(, bytes memory r) = address(this).call{gas: 100000}(abi.encodeWithSignature("updateInvocationCount(bytes4,bytes)", methodId, msg.data));
		assert(r.length == 0);
		
		assembly {
			return(add(0x20, result), mload(result))
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../access/AccessControl.sol";
import "../utils/Context.sol";
import "../token/ERC20/ERC20.sol";
import "../token/ERC20/ERC20Burnable.sol";
import "../token/ERC20/ERC20Pausable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC20PresetMinterPauser is Context, AccessControl, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) public ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../access/Ownable.sol";
import "./TransparentUpgradeableProxy.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {

    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(TransparentUpgradeableProxy proxy, address implementation, bytes memory data) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external virtual ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable virtual ifAdmin {
        _upgradeTo(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "../../utils/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IStaking.sol";

/// @title Tokemak Redeem Contract
/// @notice Converts PreToke to Toke
/// @dev Can only be used when fromToken has been unpaused
contract Redeem is Ownable {
	using SafeERC20 for IERC20;

	address public immutable fromToken;
	address public immutable toToken;
	address public immutable stakingContract;
	uint256 public immutable expirationBlock;
	uint256 public immutable stakingSchedule;

	/// @notice Redeem Constructor
	/// @dev approves max uint256 on creation for the toToken against the staking contract
	/// @param _fromToken the token users will convert from
	/// @param _toToken the token users will convert to
	/// @param _stakingContract the staking contract
	/// @param _expirationBlock a block number at which the owner can withdraw the full balance of toToken
	constructor(
		address _fromToken,
		address _toToken,
		address _stakingContract,
		uint256 _expirationBlock,
		uint256 _stakingSchedule
	) public {
		require(_fromToken != address(0), "INVALID_FROMTOKEN");
		require(_toToken != address(0), "INVALID_TOTOKEN");
		require(_stakingContract != address(0), "INVALID_STAKING");

		fromToken = _fromToken;
		toToken = _toToken;
		stakingContract = _stakingContract;
		expirationBlock = _expirationBlock;
		stakingSchedule = _stakingSchedule;

		//Approve staking contract for toToken to allow for staking within convert()
		IERC20(_toToken).safeApprove(_stakingContract, type(uint256).max);
	}

	/// @notice Allows a holder of fromToken to convert into toToken and simultaneously stake within the stakingContract
	/// @dev a user must approve this contract in order for it to burnFrom()
	function convert() external {
		uint256 fromBal = IERC20(fromToken).balanceOf(msg.sender);
		require(fromBal > 0, "INSUFFICIENT_BALANCE");
		ERC20Burnable(fromToken).burnFrom(msg.sender, fromBal);
		IStaking(stakingContract).depositFor(msg.sender, fromBal, stakingSchedule);
	}

	/// @notice Allows the claim on the toToken balance after the expiration has passed
	/// @dev callable only by owner
	function recoupRemaining() external onlyOwner {
		require(block.number >= expirationBlock, "EXPIRATION_NOT_PASSED");
		uint256 bal = IERC20(toToken).balanceOf(address(this));
		IERC20(toToken).safeTransfer(msg.sender, bal);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

/**
 *  @title Allows for the staking and vesting of TOKE for
 *  liquidity directors. Schedules can be added to enable various
 *  cliff+duration/interval unlock periods for vesting tokens.
 */
interface IStaking {
	struct StakingSchedule {
		uint256 cliff; // Duration in seconds before staking starts
		uint256 duration; // Seconds it takes for entire amount to stake
		uint256 interval; // Seconds it takes for a chunk to stake
		bool setup; //Just so we know its there
		bool isActive; //Whether we can setup new stakes with the schedule
		uint256 hardStart; //Stakings will always start at this timestamp if set
		bool isPublic; //Schedule can be written to by any account
	}

	struct StakingScheduleInfo {
		StakingSchedule schedule;
		uint256 index;
	}

	struct StakingDetails {
		uint256 initial; //Initial amount of asset when stake was created, total amount to be staked before slashing
		uint256 withdrawn; //Amount that was staked and subsequently withdrawn
		uint256 slashed; //Amount that has been slashed
		uint256 started; //Timestamp at which the stake started
		uint256 scheduleIx;
	}

	struct WithdrawalInfo {
		uint256 minCycleIndex;
		uint256 amount;
	}

	struct QueuedTransfer {
		address from;
		uint256 scheduleIdxFrom;
		uint256 scheduleIdxTo;
		uint256 amount;
		address to;
		uint256 minCycle;
	}

	event ScheduleAdded(
		uint256 scheduleIndex,
		uint256 cliff,
		uint256 duration,
		uint256 interval,
		bool setup,
		bool isActive,
		uint256 hardStart,
		address notional
	);
	event ScheduleRemoved(uint256 scheduleIndex);
	event WithdrawalRequested(address account, uint256 scheduleIdx, uint256 amount);
	event WithdrawCompleted(address account, uint256 scheduleIdx, uint256 amount);
	event Deposited(address account, uint256 amount, uint256 scheduleIx);
	event Slashed(address account, uint256 amount, uint256 scheduleIx);
	event PermissionedDepositorSet(address depositor, bool allowed);
	event UserSchedulesSet(address account, uint256[] userSchedulesIdxs);
	event NotionalAddressesSet(uint256[] scheduleIdxs, address[] addresses);
	event ScheduleStatusSet(uint256 scheduleId, bool isActive);
	event ScheduleHardStartSet(uint256 scheduleId, uint256 hardStart);
	event StakeTransferred(address from, uint256 scheduleFrom, uint256 scheduleTo, uint256 amount, address to);
	event ZeroSweep(address user, uint256 amount, uint256 scheduleFrom);
	event TransferApproverSet(address approverAddress);
	event TransferQueued(
		address from,
		uint256 scheduleFrom,
		uint256 scheduleTo,
		uint256 amount,
		address to,
		uint256 minCycle
	);
	event QueuedTransferRemoved(
		address from,
		uint256 scheduleFrom,
		uint256 scheduleTo,
		uint256 amount,
		address to,
		uint256 minCycle
	);
	event QueuedTransferRejected(
		address from,
		uint256 scheduleFrom,
		uint256 scheduleTo,
		uint256 amount,
		address to,
		uint256 minCycle,
		address rejectedBy
	);
	event Migrated(address from, uint256 amount, uint256 scheduleId);
	event AccTokeUpdated(address accToke);

	/// @notice Get a queued higher level schedule transfers
	/// @param fromAddress Account that initiated the transfer
	/// @param fromScheduleId Schedule they are transferring out of
	/// @return Details about the transfer
	function getQueuedTransfer(
		address fromAddress,
		uint256 fromScheduleId
	) external view returns (QueuedTransfer memory);

	/// @notice Get the current transfer approver
	/// @return Transfer approver address
	function transferApprover() external returns (address);

	///@notice Allows for checking of user address in permissionedDepositors mapping
	///@param account Address of account being checked
	///@return Boolean, true if address exists in mapping
	function permissionedDepositors(address account) external returns (bool);

	///@notice Allows owner to set a multitude of schedules that an address has access to
	///@param account User address
	///@param userSchedulesIdxs Array of schedule indexes
	function setUserSchedules(address account, uint256[] calldata userSchedulesIdxs) external;

	///@notice Allows owner to add schedule
	///@param schedule A StakingSchedule struct that contains all info needed to make a schedule
	///@param notional Notional addrss for schedule, used to send balances to L2 for voting purposes
	function addSchedule(StakingSchedule memory schedule, address notional) external;

	///@notice Gets all info on all schedules
	///@return retSchedules An array of StakingScheduleInfo struct
	function getSchedules() external view returns (StakingScheduleInfo[] memory retSchedules);

	///@notice Allows owner to set a permissioned depositor
	///@param account User address
	///@param canDeposit Boolean representing whether user can deposit
	function setPermissionedDepositor(address account, bool canDeposit) external;

	///@notice Allows a user to get the stakes of an account
	///@param account Address that is being checked for stakes
	///@return stakes StakingDetails array containing info about account's stakes
	function getStakes(address account) external view returns (StakingDetails[] memory stakes);

	///@notice Gets total value staked for an address across all schedules
	///@param account Address for which total stake is being calculated
	///@return value uint256 total of account
	function balanceOf(address account) external view returns (uint256 value);

	///@notice Returns amount available to withdraw for an account and schedule Index
	///@param account Address that is being checked for withdrawals
	///@param scheduleIndex Index of schedule that is being checked for withdrawals
	function availableForWithdrawal(address account, uint256 scheduleIndex) external view returns (uint256);

	///@notice Returns unvested amount for certain address and schedule index
	///@param account Address being checked for unvested amount
	///@param scheduleIndex Schedule index being checked for unvested amount
	///@return value Uint256 representing unvested amount
	function unvested(address account, uint256 scheduleIndex) external view returns (uint256 value);

	///@notice Returns vested amount for address and schedule index
	///@param account Address being checked for vested amount
	///@param scheduleIndex Schedule index being checked for vested amount
	///@return value Uint256 vested
	function vested(address account, uint256 scheduleIndex) external view returns (uint256 value);

	///@notice Allows user to deposit token to specific vesting / staking schedule
	///@param amount Uint256 amount to be deposited
	///@param scheduleIndex Uint256 representing schedule to user
	function deposit(uint256 amount, uint256 scheduleIndex) external;

	/// @notice Allows users to deposit into 0 schedule
	/// @param amount Deposit amount
	function deposit(uint256 amount) external;

	///@notice Allows account to deposit on behalf of other account
	///@param account Account to be deposited for
	///@param amount Amount to be deposited
	///@param scheduleIndex Index of schedule to be used for deposit
	function depositFor(address account, uint256 amount, uint256 scheduleIndex) external;

	///@notice User can request withdrawal from staking contract at end of cycle
	///@notice Performs checks to make sure amount <= amount available
	///@param amount Amount to withdraw
	///@param scheduleIdx Schedule index for withdrawal Request
	function requestWithdrawal(uint256 amount, uint256 scheduleIdx) external;

	///@notice Allows for withdrawal after successful withdraw request and proper amount of cycles passed
	///@param amount Amount to withdraw
	///@param scheduleIdx Schedule to withdraw from
	function withdraw(uint256 amount, uint256 scheduleIdx) external;

	///@notice Allows for withdrawal and migration to AccToke
	///@param amount Amount to withdraw
	///@param numOfCycles Number of cycles to lock for
	function withdrawAndMigrate(uint256 amount, uint256 numOfCycles) external;

	/// @notice Allows owner to set schedule to active or not
	/// @param scheduleIndex Schedule index to set isActive boolean
	/// @param activeBoolean Bool to set schedule active or not
	function setScheduleStatus(uint256 scheduleIndex, bool activeBoolean) external;

	/// @notice Allows owner to set the AccToke address
	/// @param _accToke Address of AccToke
	function setAccToke(address _accToke) external;

	/// @notice Allows owner to update schedule hard start
	/// @param scheduleIdx Schedule index to update
	/// @param hardStart new hardStart value
	function setScheduleHardStart(uint256 scheduleIdx, uint256 hardStart) external;

	/// @notice Allows owner to update users schedules start
	/// @param accounts Accounts to update
	/// @param scheduleIdx Schedule index to update
	function updateScheduleStart(address[] calldata accounts, uint256 scheduleIdx) external;

	/// @notice Pause deposits on the pool. Withdraws still allowed
	function pause() external;

	/// @notice Unpause deposits on the pool.
	function unpause() external;

	/// @notice Used to slash user funds when needed
	/// @notice accounts and amounts arrays must be same length
	/// @notice Only one scheduleIndex can be slashed at a time
	/// @dev Implementation must be restructed to owner account
	/// @param accounts Array of accounts to slash
	/// @param amounts Array of amounts that corresponds with accounts
	/// @param scheduleIndex scheduleIndex of users that are being slashed
	function slash(address[] calldata accounts, uint256[] calldata amounts, uint256 scheduleIndex) external;

	/// @notice Allows user to transfer stake to another address
	/// @param scheduleFrom, schedule stake being transferred from
	/// @param scheduleTo, schedule stake being transferred to
	/// @param amount, Amount to be transferred to new address and schedule
	/// @param to, Address to be transferred to
	function queueTransfer(uint256 scheduleFrom, uint256 scheduleTo, uint256 amount, address to) external;

	/// @notice Allows user to remove queued transfer
	/// @param scheduleIdxFrom scheduleIdx being transferred from
	function removeQueuedTransfer(uint256 scheduleIdxFrom) external;

	/// @notice Set the address used to denote the token amount for a particular schedule
	/// @dev Relates to the Balance Tracker tracking of tokens and balances. Each schedule is tracked separately
	function setNotionalAddresses(uint256[] calldata scheduleIdxArr, address[] calldata addresses) external;

	/// @notice For tokens in higher level schedules, move vested amounts to the default schedule
	/// @notice Allows for full voting weight to be applied when tokens have vested
	/// @param scheduleIdx Schedule to sweep tokens from
	/// @param amount Amount to sweep to default schedule
	function sweepToScheduleZero(uint256 scheduleIdx, uint256 amount) external;

	/// @notice Set the approver for higher schedule transfers
	/// @param approver New transfer approver
	function setTransferApprover(address approver) external;

	/// @notice Withdraw from the default schedule. Must have a request in previously
	/// @param amount Amount to withdraw
	function withdraw(uint256 amount) external;

	/// @notice Allows transfeApprover to reject a submitted transfer
	/// @param from address queued transfer is from
	/// @param scheduleIdxFrom Schedule index of queued transfer
	function rejectQueuedTransfer(address from, uint256 scheduleIdxFrom) external;

	/// @notice Approve a queued transfer from a higher level schedule
	/// @param from address that queued the transfer
	/// @param scheduleIdxFrom Schedule index of queued transfer
	/// @param scheduleIdxTo Schedule index of destination
	/// @param amount Amount being transferred
	/// @param to Destination account
	function approveQueuedTransfer(
		address from,
		uint256 scheduleIdxFrom,
		uint256 scheduleIdxTo,
		uint256 amount,
		address to
	) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "../interfaces/IDelegateFunction.sol";
import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IStaking.sol";
import "../interfaces/structs/DelegateMapView.sol";

contract SnapshotToke is IERC20, Ownable {
	using EnumerableSet for EnumerableSet.AddressSet;
	using SafeMath for uint256;

	uint256 private constant SUPPLY = 100_000_000e18;
	uint8 private constant DECIMALS = 18;
	string private constant NAME = "Tokemak Snapshot Vote";
	string private constant SYMBOL = "vTOKE";
	bytes32 private constant VOTING_FUNCTION = "voting";

	IERC20 private immutable sushiLPPool;
	IStaking private immutable staking;
	IDelegateFunction private immutable delegation;
	IERC20 private immutable toke;

	IERC20 private immutable sushiLP;

	/// @dev to => from[]
	mapping(address => EnumerableSet.AddressSet) private delegationsTo;

	/// @dev from => true/false
	mapping(address => bool) private delegatedAway;

	constructor(address _sushiLPPool, address _staking, address _delegation, address _toke) public {
		require(_sushiLPPool != address(0), "ZERO_ADDRESS_SUSHILP");
		require(_staking != address(0), "ZERO_ADDRESS_STAKING");
		require(_delegation != address(0), "ZERO_ADDRESS_DELEGATION");
		require(_toke != address(0), "ZERO_ADDRESS_TOKE");

		sushiLPPool = IERC20(_sushiLPPool);
		staking = IStaking(_staking);
		delegation = IDelegateFunction(_delegation);
		toke = IERC20(_toke);

		sushiLP = IERC20(address(ILiquidityPool(_sushiLPPool).underlyer()));
	}

	event DelegationSetup(address indexed from, address indexed to, address indexed sender);
	event DelegationRemoved(address indexed from, address indexed to, address indexed sender);

	/**
	 * @dev Returns the amount of tokens owned by `account`.
	 */
	function balanceOf(address account) external view override returns (uint256 bal) {
		// See if they've setup a delegation locally
		bool delegatedAway = delegatedAway[account];

		if (delegatedAway) {
			// Ensure the delegate away is still valid
			DelegateMapView memory delegationFrom = delegation.getDelegation(account, VOTING_FUNCTION);
			delegatedAway = delegationFrom.otherParty != address(0) && !delegationFrom.pending;
		}

		if (!delegatedAway) {
			// Get TOKE directly assigned to this wallet
			bal = getBalance(account);

			// Get TOKE balance from delegated accounts
			EnumerableSet.AddressSet storage delegations = delegationsTo[account];
			uint256 length = delegations.length();
			for (uint256 i = 0; i < length; ++i) {
				address delegatedFrom = delegations.at(i);

				//Ensure the delegation to account is still valid
				DelegateMapView memory queriedDelegation = delegation.getDelegation(delegatedFrom, VOTING_FUNCTION);
				if (queriedDelegation.otherParty == account && !queriedDelegation.pending) {
					bal = bal.add(getBalance(delegatedFrom));
				}
			}
		}
	}

	function addDelegations(address[] memory from, address[] memory to) external onlyOwner {
		uint256 length = from.length;
		require(length > 0, "ZERO_LENGTH");
		require(length == to.length, "MISMATCH_LENGTH");
		for (uint256 i = 0; i < length; ++i) {
			_addDelegation(from[i], to[i]);
		}
	}

	function removeDelegations(address[] memory from, address[] memory to) external onlyOwner {
		uint256 length = from.length;
		require(length > 0, "ZERO_LENGTH");
		require(length == to.length, "MISMATCH_LENGTH");
		for (uint256 i = 0; i < length; ++i) {
			_removeDelegation(from[i], to[i]);
		}
	}

	function addDelegation(address from, address to) external onlyOwner {
		_addDelegation(from, to);
	}

	function removeDelegation(address from, address to) external onlyOwner {
		_removeDelegation(from, to);
	}

	function name() public view virtual returns (string memory) {
		return NAME;
	}

	function symbol() public view virtual returns (string memory) {
		return SYMBOL;
	}

	function decimals() public view virtual returns (uint8) {
		return DECIMALS;
	}

	function totalSupply() external view override returns (uint256) {
		return SUPPLY;
	}

	/**
	 * @dev Moves `amount` tokens from the caller's account to `recipient`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 */
	function transfer(address, uint256) external override returns (bool) {
		revert("NO_TRANSFERS_ALLOWED");
	}

	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 * allowed to spend on behalf of `owner` through {transferFrom}. This is
	 * zero by default.
	 */
	function allowance(address, address) external view override returns (uint256) {
		return 0;
	}

	/**
	 * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 */
	function approve(address, uint256) external override returns (bool) {
		revert("NO_TRANSFERS_ALLOWED");
	}

	/**
	 * @dev Moves `amount` tokens from `sender` to `recipient` using the
	 * allowance mechanism. `amount` is then deducted from the caller's
	 * allowance.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 */
	function transferFrom(address, address, uint256) external override returns (bool) {
		revert("NO_TRANSFERS_ALLOWED");
	}

	/// @notice Returns straight balance of the account. No delegations considered
	/// @param account Account to check
	/// @return bal Balance across all valid areas
	function getBalance(address account) private view returns (uint256 bal) {
		// Get TOKE sitting in their wallet
		bal = toke.balanceOf(account);

		// Get staked TOKE either liquid or vesting
		bal = bal.add(staking.balanceOf(account));

		// Get TOKE from SUSHI LP
		uint256 stakedSushiLP = sushiLPPool.balanceOf(account);
		if (stakedSushiLP > 0) {
			uint256 sushiLPTotalSupply = sushiLP.totalSupply();
			uint256 tokeInSushiPool = toke.balanceOf(address(sushiLP));
			bal = bal.add(stakedSushiLP.mul(tokeInSushiPool).div(sushiLPTotalSupply));
		}
	}

	function _addDelegation(address from, address to) private {
		DelegateMapView memory queriedDelegation = delegation.getDelegation(from, VOTING_FUNCTION);
		require(from != address(0), "INVALID_FROM");
		require(to != address(0), "INVALID_TO");
		require(queriedDelegation.otherParty == to, "INVALID_DELEGATION");
		require(queriedDelegation.pending == false, "DELEGATION_PENDING");
		require(delegationsTo[to].add(from), "ALREADY_ADDED");
		require(delegatedAway[from] == false, "ALREADY_DELEGATED");

		delegatedAway[from] = true;

		emit DelegationSetup(from, to, msg.sender);
	}

	function _removeDelegation(address from, address to) private {
		require(from != address(0), "INVALID_FROM");
		require(to != address(0), "INVALID_TO");
		require(delegationsTo[to].remove(from), "DOES_NOT_EXIST");
		require(delegatedAway[from], "NOT_DELEGATED_FROM");

		delegatedAway[from] = false;

		emit DelegationRemoved(from, to, msg.sender);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./structs/DelegateMapView.sol";
import "./structs/Signature.sol";

/**
 *   @title Manages the state of an accounts delegation settings.
 *   Allows for various methods of validation as well as enabling
 *   different system functions to be delegated to different accounts
 */
interface IDelegateFunction {
	struct AllowedFunctionSet {
		bytes32 id;
	}

	struct FunctionsListPayload {
		bytes32[] sets;
		uint256 nonce;
	}

	struct DelegatePayload {
		DelegateMap[] sets;
		uint256 nonce;
	}

	struct DelegateMap {
		bytes32 functionId;
		address otherParty;
		bool mustRelinquish;
	}

	struct Destination {
		address otherParty;
		bool mustRelinquish;
		bool pending;
	}

	struct DelegatedTo {
		address originalParty;
		bytes32 functionId;
	}

	event AllowedFunctionsSet(AllowedFunctionSet[] functions);
	event PendingDelegationAdded(address from, address to, bytes32 functionId, bool mustRelinquish);
	event PendingDelegationRemoved(address from, address to, bytes32 functionId, bool mustRelinquish);
	event DelegationRemoved(address from, address to, bytes32 functionId, bool mustRelinquish);
	event DelegationRelinquished(address from, address to, bytes32 functionId, bool mustRelinquish);
	event DelegationAccepted(address from, address to, bytes32 functionId, bool mustRelinquish);
	event DelegationRejected(address from, address to, bytes32 functionId, bool mustRelinquish);

	/// @notice Pause all delegating operations
	function pause() external;

	/// @notice Unpause all delegating operations
	function unpause() external;

	/// @notice Get the current nonce a contract wallet should use
	/// @param account Account to query
	/// @return nonce Nonce that should be used for next call
	function contractWalletNonces(address account) external returns (uint256 nonce);

	/// @notice Get an accounts current delegations
	/// @dev These may be in a pending state
	/// @param from Account that is delegating functions away
	/// @return maps List of delegations in various states of approval
	function getDelegations(address from) external view returns (DelegateMapView[] memory maps);

	/// @notice Get an accounts delegation of a specific function
	/// @dev These may be in a pending state
	/// @param from Account that is the delegation functions away
	/// @return map Delegation info
	function getDelegation(address from, bytes32 functionId) external view returns (DelegateMapView memory map);

	/// @notice Initiate delegation of one or more system functions to different account(s)
	/// @param sets Delegation instructions for the contract to initiate
	function delegate(DelegateMap[] memory sets) external;

	/// @notice Initiate delegation on behalf of a contract that supports ERC1271
	/// @param contractAddress Address of the ERC1271 contract used to verify the given signature
	/// @param delegatePayload Sets of DelegateMap objects
	/// @param signature Signature data
	/// @param signatureType Type of signature used (EIP712|EthSign)
	function delegateWithEIP1271(
		address contractAddress,
		DelegatePayload memory delegatePayload,
		bytes memory signature,
		SignatureType signatureType
	) external;

	/// @notice Accept one or more delegations from another account
	/// @param incoming Delegation details being accepted
	function acceptDelegation(DelegatedTo[] calldata incoming) external;

	/// @notice Remove one or more delegation that you have previously setup
	function removeDelegation(bytes32[] calldata functionIds) external;

	/// @notice Remove one or more delegations that you have previously setup on behalf of a contract supporting EIP1271
	/// @param contractAddress Address of the ERC1271 contract used to verify the given signature
	/// @param functionsListPayload Sets of FunctionListPayload objects ({sets: bytes32[]})
	/// @param signature Signature data
	/// @param signatureType Type of signature used (EIP712|EthSign)
	function removeDelegationWithEIP1271(
		address contractAddress,
		FunctionsListPayload calldata functionsListPayload,
		bytes memory signature,
		SignatureType signatureType
	) external;

	/// @notice Reject one or more delegations being sent to you
	/// @param rejections Delegations to reject
	function rejectDelegation(DelegatedTo[] calldata rejections) external;

	/// @notice Remove one or more delegations that you have previously accepted
	function relinquishDelegation(DelegatedTo[] calldata relinquish) external;

	/// @notice Cancel one or more delegations you have setup but that has not yet been accepted
	/// @param functionIds System functions you wish to retain control of
	function cancelPendingDelegation(bytes32[] calldata functionIds) external;

	/// @notice Cancel one or more delegations you have setup on behalf of a contract that supported EIP1271, but that has not yet been accepted
	/// @param contractAddress Address of the ERC1271 contract used to verify the given signature
	/// @param functionsListPayload Sets of FunctionListPayload objects ({sets: bytes32[]})
	/// @param signature Signature data
	/// @param signatureType Type of signature used (EIP712|EthSign)
	function cancelPendingDelegationWithEIP1271(
		address contractAddress,
		FunctionsListPayload calldata functionsListPayload,
		bytes memory signature,
		SignatureType signatureType
	) external;

	/// @notice Add to the list of system functions that are allowed to be delegated
	/// @param functions New system function ids
	function setAllowedFunctions(AllowedFunctionSet[] calldata functions) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../interfaces/IManager.sol";

/// @title Interface for Pool
/// @notice Allows users to deposit ERC-20 tokens to be deployed to market makers.
/// @notice Mints 1:1 tAsset on deposit, represeting an IOU for the undelrying token that is freely transferable.
/// @notice Holders of tAsset earn rewards based on duration their tokens were deployed and the demand for that asset.
/// @notice Holders of tAsset can redeem for underlying asset after issuing requestWithdrawal and waiting for the next cycle.
interface ILiquidityPool {
	struct WithdrawalInfo {
		uint256 minCycle;
		uint256 amount;
	}

	event WithdrawalRequested(address requestor, uint256 amount);
	event DepositsPaused();
	event DepositsUnpaused();
	event BurnerRegistered(address burner, bool allowed);
	event Burned(address indexed account, address indexed burner, uint256 amount);
	event RebalancerSet(address rebalancer);

	/// @notice Transfers amount of underlying token from user to this pool and mints fToken to the msg.sender.
	/// @notice Depositor must have previously granted transfer approval to the pool via underlying token contract.
	/// @notice Liquidity deposited is deployed on the next cycle - unless a withdrawal request is submitted, in which case the liquidity will be withheld.
	function deposit(uint256 amount) external;

	/// @notice Transfers amount of underlying token from user to this pool and mints fToken to the account.
	/// @notice Depositor must have previously granted transfer approval to the pool via underlying token contract.
	/// @notice Liquidity deposited is deployed on the next cycle - unless a withdrawal request is submitted, in which case the liquidity will be withheld.
	function depositFor(address account, uint256 amount) external;

	/// @notice Requests that the manager prepare funds for withdrawal next cycle
	/// @notice Invoking this function when sender already has a currently pending request will overwrite that requested amount and reset the cycle timer
	/// @param amount Amount of fTokens requested to be redeemed
	function requestWithdrawal(uint256 amount) external;

	function approveManager(uint256 amount) external;

	/// @notice Approves rebalancer contract to withdraw pool tokens
	/// @param amount Number of pool tokens to be approved
	function approveRebalancer(uint256 amount) external;

	/// @notice Sender must first invoke requestWithdrawal in a previous cycle
	/// @notice This function will burn the fAsset and transfers underlying asset back to sender
	/// @notice Will execute a partial withdrawal if either available liquidity or previously requested amount is insufficient
	/// @param amount Amount of fTokens to redeem, value can be in excess of available tokens, operation will be reduced to maximum permissible
	function withdraw(uint256 amount) external;

	/// @return Reference to the underlying ERC-20 contract
	function underlyer() external view returns (ERC20Upgradeable);

	/// @return Amount of liquidity that should not be deployed for market making (this liquidity will be used for completing requested withdrawals)
	function withheldLiquidity() external view returns (uint256);

	/// @notice Get withdraw requests for an account
	/// @param account User account to check
	/// @return minCycle Cycle - block number - that must be active before withdraw is allowed, amount Token amount requested
	function requestedWithdrawals(address account) external view returns (uint256, uint256);

	/// @notice Pause deposits on the pool. Withdraws still allowed
	function pause() external;

	/// @notice Unpause deposits on the pool.
	function unpause() external;

	// @notice Pause deposits only on the pool.
	function pauseDeposit() external;

	// @notice Unpause deposits only on the pool.
	function unpauseDeposit() external;

	///@notice Registers address that is allowed or not allowed to burn
	///@dev Address registered as 'true' will be able to burn tAssets in its possession or that it has an allowance to
	///@param burner Address that will be able / not able to burn tAssets
	///@param allowedBurner Boolean that will register burner address as able to burn or not
	function registerBurner(address burner, bool allowedBurner) external;

	/// @notice Used to set rebalancer address
	/// @dev Purpose is to set rebalancer on proxy state
	/// @param rebalancer address of rebalancer
	function setRebalancer(address rebalancer) external;

	///@notice Function allows address to burn tAssets in its posession
	///@dev Address can burn all tAssets in its posession
	///@dev Overages are prevented by interited functionality from _burn()
	///@param amount Amount of tAsset to be burned
	///@param account Address to be burned from
	function controlledBurn(uint256 amount, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

/// @notice Stores votes and rewards delegation mapping in DelegateFunction
struct DelegateMapView {
	bytes32 functionId;
	address otherParty;
	bool mustRelinquish;
	bool pending;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

/// @notice Denotes the type of signature being submitted to contracts that support multiple
enum SignatureType {
	INVALID,
	// Specifically signTypedData_v4
	EIP712,
	// Specifically personal_sign
	ETHSIGN
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

/**
 *  @title Controls the transition and execution of liquidity deployment cycles.
 *  Accepts instructions that can move assets from the Pools to the Exchanges
 *  and back. Can also move assets to the treasury when appropriate.
 */
interface IManager {
	// bytes can take on the form of deploying or recovering liquidity
	struct ControllerTransferData {
		bytes32 controllerId; // controller to target
		bytes data; // data the controller will pass
	}

	struct PoolTransferData {
		address pool; // pool to target
		uint256 amount; // amount to transfer
	}

	struct MaintenanceExecution {
		ControllerTransferData[] cycleSteps;
	}

	struct RolloverExecution {
		PoolTransferData[] poolData;
		ControllerTransferData[] cycleSteps;
		address[] poolsForWithdraw; //Pools to target for manager -> pool transfer
		bool complete; //Whether to mark the rollover complete
		string rewardsIpfsHash;
	}

	event ControllerRegistered(bytes32 id, address controller);
	event ControllerUnregistered(bytes32 id, address controller);
	event PoolRegistered(address pool);
	event PoolUnregistered(address pool);
	event CycleDurationSet(uint256 duration);
	event LiquidityMovedToManager(address pool, uint256 amount);
	event DeploymentStepExecuted(bytes32 controller, address adapaterAddress, bytes data);
	event LiquidityMovedToPool(address pool, uint256 amount);
	event CycleRolloverStarted(uint256 timestamp);
	event CycleRolloverComplete(uint256 timestamp);
	event NextCycleStartSet(uint256 nextCycleStartTime);
	event ManagerSwept(address[] addresses, uint256[] amounts);

	/// @notice Registers controller
	/// @param id Bytes32 id of controller
	/// @param controller Address of controller
	function registerController(bytes32 id, address controller) external;

	/// @notice Registers pool
	/// @param pool Address of pool
	function registerPool(address pool) external;

	/// @notice Unregisters controller
	/// @param id Bytes32 controller id
	function unRegisterController(bytes32 id) external;

	/// @notice Unregisters pool
	/// @param pool Address of pool
	function unRegisterPool(address pool) external;

	///@notice Gets addresses of all pools registered
	///@return Memory array of pool addresses
	function getPools() external view returns (address[] memory);

	///@notice Gets ids of all controllers registered
	///@return Memory array of Bytes32 controller ids
	function getControllers() external view returns (bytes32[] memory);

	///@notice Allows for owner to set cycle duration
	///@param duration Block durtation of cycle
	function setCycleDuration(uint256 duration) external;

	///@notice Starts cycle rollover
	///@dev Sets rolloverStarted state boolean to true
	function startCycleRollover() external;

	///@notice Allows for controller commands to be executed midcycle
	///@param params Contains data for controllers and params
	function executeMaintenance(MaintenanceExecution calldata params) external;

	///@notice Allows for withdrawals and deposits for pools along with liq deployment
	///@param params Contains various data for executing against pools and controllers
	function executeRollover(RolloverExecution calldata params) external;

	///@notice Completes cycle rollover, publishes rewards hash to ipfs
	///@param rewardsIpfsHash rewards hash uploaded to ipfs
	function completeRollover(string calldata rewardsIpfsHash) external;

	///@notice Gets reward hash by cycle index
	///@param index Cycle index to retrieve rewards hash
	///@return String memory hash
	function cycleRewardsHashes(uint256 index) external view returns (string memory);

	///@notice Gets current starting block
	///@return uint256 with block number
	function getCurrentCycle() external view returns (uint256);

	///@notice Gets current cycle index
	///@return uint256 current cycle number
	function getCurrentCycleIndex() external view returns (uint256);

	///@notice Gets current cycle duration
	///@return uint256 in block of cycle duration
	function getCycleDuration() external view returns (uint256);

	///@notice Gets cycle rollover status, true for rolling false for not
	///@return Bool representing whether cycle is rolling over or not
	function getRolloverStatus() external view returns (bool);

	/// @notice Sets next cycle start time manually
	/// @param nextCycleStartTime uint256 that represents start of next cycle
	function setNextCycleStartTime(uint256 nextCycleStartTime) external;

	/// @notice Sweeps amanager contract for any leftover funds
	/// @param addresses array of addresses of pools to sweep funds into
	function sweep(address[] calldata addresses) external;

	/// @notice Setup a role using internal function _setupRole
	/// @param role keccak256 of the role keccak256("MY_ROLE");
	function setupRole(bytes32 role) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@0x/contracts-zero-ex/contracts/src/features/interfaces/INativeOrdersFeature.sol";
import "../interfaces/IWallet.sol";

contract ZeroExTradeWallet is IWallet, Ownable, ReentrancyGuard {
	using SafeERC20 for IERC20;
	using Address for address;
	using Address for address payable;
	using SafeMath for uint256;
	using EnumerableSet for EnumerableSet.AddressSet;

	INativeOrdersFeature public immutable zeroExRouter;
	address public immutable manager;
	EnumerableSet.AddressSet internal tokens;

	modifier onlyManager() {
		require(msg.sender == manager, "INVALID_MANAGER");
		_;
	}

	constructor(address newRouter, address newManager) public {
		require(newRouter != address(0), "INVALID_ROUTER");
		require(newManager != address(0), "INVALID_MANAGER");
		zeroExRouter = INativeOrdersFeature(newRouter);
		manager = newManager;
	}

	function getTokens() external view returns (address[] memory) {
		address[] memory returnData = new address[](tokens.length());
		for (uint256 i = 0; i < tokens.length(); ++i) {
			returnData[i] = tokens.at(i);
		}
		return returnData;
	}

	// solhint-disable-next-line no-empty-blocks
	function registerAllowedOrderSigner(address signer, bool allowed) external override onlyOwner {
		require(signer != address(0), "INVALID_SIGNER");
		zeroExRouter.registerAllowedOrderSigner(signer, allowed);
	}

	function deposit(
		address[] calldata depositTokens,
		uint256[] calldata amounts
	) external override onlyManager nonReentrant {
		uint256 tokensLength = depositTokens.length;
		uint256 amountsLength = amounts.length;

		require(tokensLength > 0, "EMPTY_TOKEN_LIST");
		require(tokensLength == amountsLength, "LENGTH_MISMATCH");
		for (uint256 i = 0; i < tokensLength; ++i) {
			require(tokens.contains(depositTokens[i]), "ADDRESS_NOT_WHITELISTED");
			IERC20(depositTokens[i]).safeTransferFrom(msg.sender, address(this), amounts[i]);
			// NOTE: approval must be done after transferFrom; balance is checked in the approval
			_approve(IERC20(depositTokens[i]));
		}
	}

	function withdraw(
		address[] calldata tokensToWithdraw,
		uint256[] calldata amounts
	) external override onlyManager nonReentrant {
		uint256 tokensLength = tokensToWithdraw.length;
		uint256 amountsLength = amounts.length;

		require(tokensLength > 0, "EMPTY_TOKEN_LIST");
		require(tokensLength == amountsLength, "LENGTH_MISMATCH");

		for (uint256 i = 0; i < tokensLength; ++i) {
			require(tokens.contains(tokensToWithdraw[i]), "ADDRESS_NOT_WHITELISTED");
			IERC20(tokensToWithdraw[i]).safeTransfer(msg.sender, amounts[i]);
		}
	}

	function whitelistTokens(address[] calldata tokensToAdd) external onlyOwner {
		for (uint256 i = 0; i < tokensToAdd.length; ++i) {
			require(tokens.add(tokensToAdd[i]), "ADD_FAIL");
		}
	}

	function removeWhitelistedTokens(address[] calldata tokensToRemove) external onlyOwner {
		for (uint256 i = 0; i < tokensToRemove.length; ++i) {
			require(tokens.remove(tokensToRemove[i]), "REMOVE_FAIL");
		}
	}

	function _approve(IERC20 token) internal {
		// Approve the zeroExRouter's allowance to max if the allowance ever drops below the balance of the token held
		uint256 allowance = token.allowance(address(this), address(zeroExRouter));
		if (allowance < token.balanceOf(address(this))) {
			uint256 amount = token.balanceOf(address(this)).sub(allowance);
			token.safeIncreaseAllowance(address(zeroExRouter), amount);
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

/**
 *  @title 0x trade wallet used to hold funds and fullfil orders submitted by Pricers
 */
interface IWallet {
	/// @notice Register with 0x an address that is allowed to sign on behalf of this contract
	/// @param signer EOA that is signing RFQ orders
	function registerAllowedOrderSigner(address signer, bool allowed) external;

	/// @notice Add the supplied amounts to the wallet to fullfill order with
	function deposit(address[] calldata tokens, uint256[] calldata amounts) external;

	/// @notice Withdraw assets from the wallet
	function withdraw(address[] calldata tokens, uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../libs/LibSignature.sol";
import "../libs/LibNativeOrder.sol";
import "./INativeOrdersEvents.sol";


/// @dev Feature for interacting with limit orders.
interface INativeOrdersFeature is
    INativeOrdersEvents
{

    /// @dev Transfers protocol fees from the `FeeCollector` pools into
    ///      the staking contract.
    /// @param poolIds Staking pool IDs
    function transferProtocolFeesForPools(bytes32[] calldata poolIds)
        external;

    /// @dev Fill a limit order. The taker and sender will be the caller.
    /// @param order The limit order. ETH protocol fees can be
    ///      attached to this call. Any unspent ETH will be refunded to
    ///      the caller.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this order with.
    /// @return takerTokenFilledAmount How much maker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillLimitOrder(
        LibNativeOrder.LimitOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount
    )
        external
        payable
        returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Fill an RFQ order for up to `takerTokenFillAmount` taker tokens.
    ///      The taker will be the caller.
    /// @param order The RFQ order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this order with.
    /// @return takerTokenFilledAmount How much maker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillRfqOrder(
        LibNativeOrder.RfqOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount
    )
        external
        returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Fill an RFQ order for exactly `takerTokenFillAmount` taker tokens.
    ///      The taker will be the caller. ETH protocol fees can be
    ///      attached to this call. Any unspent ETH will be refunded to
    ///      the caller.
    /// @param order The limit order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount How much taker token to fill this order with.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOrKillLimitOrder(
        LibNativeOrder.LimitOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount
    )
        external
        payable
        returns (uint128 makerTokenFilledAmount);

    /// @dev Fill an RFQ order for exactly `takerTokenFillAmount` taker tokens.
    ///      The taker will be the caller.
    /// @param order The RFQ order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount How much taker token to fill this order with.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOrKillRfqOrder(
        LibNativeOrder.RfqOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount
    )
        external
        returns (uint128 makerTokenFilledAmount);

    /// @dev Fill a limit order. Internal variant. ETH protocol fees can be
    ///      attached to this call. Any unspent ETH will be refunded to
    ///      `msg.sender` (not `sender`).
    /// @param order The limit order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount Maximum taker token to fill this order with.
    /// @param taker The order taker.
    /// @param sender The order sender.
    /// @return takerTokenFilledAmount How much maker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function _fillLimitOrder(
        LibNativeOrder.LimitOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount,
        address taker,
        address sender
    )
        external
        payable
        returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Fill an RFQ order. Internal variant.
    /// @param order The RFQ order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount Maximum taker token to fill this order with.
    /// @param taker The order taker.
    /// @return takerTokenFilledAmount How much maker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function _fillRfqOrder(
        LibNativeOrder.RfqOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount,
        address taker
    )
        external
        returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Cancel a single limit order. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param order The limit order.
    function cancelLimitOrder(LibNativeOrder.LimitOrder calldata order)
        external;

    /// @dev Cancel a single RFQ order. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param order The RFQ order.
    function cancelRfqOrder(LibNativeOrder.RfqOrder calldata order)
        external;

    /// @dev Mark what tx.origin addresses are allowed to fill an order that
    ///      specifies the message sender as its txOrigin.
    /// @param origins An array of origin addresses to update.
    /// @param allowed True to register, false to unregister.
    function registerAllowedRfqOrigins(address[] memory origins, bool allowed)
        external;

    /// @dev Cancel multiple limit orders. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param orders The limit orders.
    function batchCancelLimitOrders(LibNativeOrder.LimitOrder[] calldata orders)
        external;

    /// @dev Cancel multiple RFQ orders. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param orders The RFQ orders.
    function batchCancelRfqOrders(LibNativeOrder.RfqOrder[] calldata orders)
        external;

    /// @dev Cancel all limit orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairLimitOrders(
        IERC20TokenV06 makerToken,
        IERC20TokenV06 takerToken,
        uint256 minValidSalt
    )
        external;

    /// @dev Cancel all limit orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same maker and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker The maker for which to cancel.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairLimitOrdersWithSigner(
        address maker,
        IERC20TokenV06 makerToken,
        IERC20TokenV06 takerToken,
        uint256 minValidSalt
    )
        external;

    /// @dev Cancel all limit orders for a given maker and pairs with salts less
    ///      than the values provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairLimitOrders(
        IERC20TokenV06[] calldata makerTokens,
        IERC20TokenV06[] calldata takerTokens,
        uint256[] calldata minValidSalts
    )
        external;

    /// @dev Cancel all limit orders for a given maker and pairs with salts less
    ///      than the values provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same maker and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker The maker for which to cancel.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairLimitOrdersWithSigner(
        address maker,
        IERC20TokenV06[] memory makerTokens,
        IERC20TokenV06[] memory takerTokens,
        uint256[] memory minValidSalts
    )
        external;

    /// @dev Cancel all RFQ orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairRfqOrders(
        IERC20TokenV06 makerToken,
        IERC20TokenV06 takerToken,
        uint256 minValidSalt
    )
        external;

    /// @dev Cancel all RFQ orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same maker and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker The maker for which to cancel.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairRfqOrdersWithSigner(
        address maker,
        IERC20TokenV06 makerToken,
        IERC20TokenV06 takerToken,
        uint256 minValidSalt
    )
        external;

    /// @dev Cancel all RFQ orders for a given maker and pairs with salts less
    ///      than the values provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairRfqOrders(
        IERC20TokenV06[] calldata makerTokens,
        IERC20TokenV06[] calldata takerTokens,
        uint256[] calldata minValidSalts
    )
        external;

    /// @dev Cancel all RFQ orders for a given maker and pairs with salts less
    ///      than the values provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same maker and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker The maker for which to cancel.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairRfqOrdersWithSigner(
        address maker,
        IERC20TokenV06[] memory makerTokens,
        IERC20TokenV06[] memory takerTokens,
        uint256[] memory minValidSalts
    )
        external;

    /// @dev Get the order info for a limit order.
    /// @param order The limit order.
    /// @return orderInfo Info about the order.
    function getLimitOrderInfo(LibNativeOrder.LimitOrder calldata order)
        external
        view
        returns (LibNativeOrder.OrderInfo memory orderInfo);

    /// @dev Get the order info for an RFQ order.
    /// @param order The RFQ order.
    /// @return orderInfo Info about the order.
    function getRfqOrderInfo(LibNativeOrder.RfqOrder calldata order)
        external
        view
        returns (LibNativeOrder.OrderInfo memory orderInfo);

    /// @dev Get the canonical hash of a limit order.
    /// @param order The limit order.
    /// @return orderHash The order hash.
    function getLimitOrderHash(LibNativeOrder.LimitOrder calldata order)
        external
        view
        returns (bytes32 orderHash);

    /// @dev Get the canonical hash of an RFQ order.
    /// @param order The RFQ order.
    /// @return orderHash The order hash.
    function getRfqOrderHash(LibNativeOrder.RfqOrder calldata order)
        external
        view
        returns (bytes32 orderHash);

    /// @dev Get the protocol fee multiplier. This should be multiplied by the
    ///      gas price to arrive at the required protocol fee to fill a native order.
    /// @return multiplier The protocol fee multiplier.
    function getProtocolFeeMultiplier()
        external
        view
        returns (uint32 multiplier);

    /// @dev Get order info, fillable amount, and signature validity for a limit order.
    ///      Fillable amount is determined using balances and allowances of the maker.
    /// @param order The limit order.
    /// @param signature The order signature.
    /// @return orderInfo Info about the order.
    /// @return actualFillableTakerTokenAmount How much of the order is fillable
    ///         based on maker funds, in taker tokens.
    /// @return isSignatureValid Whether the signature is valid.
    function getLimitOrderRelevantState(
        LibNativeOrder.LimitOrder calldata order,
        LibSignature.Signature calldata signature
    )
        external
        view
        returns (
            LibNativeOrder.OrderInfo memory orderInfo,
            uint128 actualFillableTakerTokenAmount,
            bool isSignatureValid
        );

    /// @dev Get order info, fillable amount, and signature validity for an RFQ order.
    ///      Fillable amount is determined using balances and allowances of the maker.
    /// @param order The RFQ order.
    /// @param signature The order signature.
    /// @return orderInfo Info about the order.
    /// @return actualFillableTakerTokenAmount How much of the order is fillable
    ///         based on maker funds, in taker tokens.
    /// @return isSignatureValid Whether the signature is valid.
    function getRfqOrderRelevantState(
        LibNativeOrder.RfqOrder calldata order,
        LibSignature.Signature calldata signature
    )
        external
        view
        returns (
            LibNativeOrder.OrderInfo memory orderInfo,
            uint128 actualFillableTakerTokenAmount,
            bool isSignatureValid
        );

    /// @dev Batch version of `getLimitOrderRelevantState()`, without reverting.
    ///      Orders that would normally cause `getLimitOrderRelevantState()`
    ///      to revert will have empty results.
    /// @param orders The limit orders.
    /// @param signatures The order signatures.
    /// @return orderInfos Info about the orders.
    /// @return actualFillableTakerTokenAmounts How much of each order is fillable
    ///         based on maker funds, in taker tokens.
    /// @return isSignatureValids Whether each signature is valid for the order.
    function batchGetLimitOrderRelevantStates(
        LibNativeOrder.LimitOrder[] calldata orders,
        LibSignature.Signature[] calldata signatures
    )
        external
        view
        returns (
            LibNativeOrder.OrderInfo[] memory orderInfos,
            uint128[] memory actualFillableTakerTokenAmounts,
            bool[] memory isSignatureValids
        );

    /// @dev Batch version of `getRfqOrderRelevantState()`, without reverting.
    ///      Orders that would normally cause `getRfqOrderRelevantState()`
    ///      to revert will have empty results.
    /// @param orders The RFQ orders.
    /// @param signatures The order signatures.
    /// @return orderInfos Info about the orders.
    /// @return actualFillableTakerTokenAmounts How much of each order is fillable
    ///         based on maker funds, in taker tokens.
    /// @return isSignatureValids Whether each signature is valid for the order.
    function batchGetRfqOrderRelevantStates(
        LibNativeOrder.RfqOrder[] calldata orders,
        LibSignature.Signature[] calldata signatures
    )
        external
        view
        returns (
            LibNativeOrder.OrderInfo[] memory orderInfos,
            uint128[] memory actualFillableTakerTokenAmounts,
            bool[] memory isSignatureValids
        );

    /// @dev Register a signer who can sign on behalf of msg.sender
    ///      This allows one to sign on behalf of a contract that calls this function
    /// @param signer The address from which you plan to generate signatures
    /// @param allowed True to register, false to unregister.
    function registerAllowedOrderSigner(
        address signer,
        bool allowed
    )
        external;

    /// @dev checks if a given address is registered to sign on behalf of a maker address
    /// @param maker The maker address encoded in an order (can be a contract)
    /// @param signer The address that is providing a signature
    function isValidOrderSigner(
        address maker,
        address signer
    )
        external
        view
        returns (bool isAllowed);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

interface IERC20TokenV06 {
    // solhint-disable no-simple-event-func-name
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @dev send `value` token to `to` from `msg.sender`
    /// @param to The address of the recipient
    /// @param value The amount of token to be transferred
    /// @return True if transfer was successful
    function transfer(address to, uint256 value) external returns (bool);

    /// @dev send `value` token to `to` from `from` on the condition it is approved by `from`
    /// @param from The address of the sender
    /// @param to The address of the recipient
    /// @param value The amount of token to be transferred
    /// @return True if transfer was successful
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    /// @dev `msg.sender` approves `spender` to spend `value` tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @param value The amount of wei to be approved for transfer
    /// @return Always true if the call has enough gas to complete execution
    function approve(address spender, uint256 value) external returns (bool);

    /// @dev Query total supply of token
    /// @return Total supply of token
    function totalSupply() external view returns (uint256);

    /// @dev Get the balance of `owner`.
    /// @param owner The address from which the balance will be retrieved
    /// @return Balance of owner
    function balanceOf(address owner) external view returns (uint256);

    /// @dev Get the allowance for `spender` to spend from `owner`.
    /// @param owner The address of the account owning tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address owner, address spender) external view returns (uint256);

    /// @dev Get the number of decimals this token has.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../../errors/LibSignatureRichErrors.sol";


/// @dev A library for validating signatures.
library LibSignature {
    using LibRichErrorsV06 for bytes;

    // '\x19Ethereum Signed Message:\n32\x00\x00\x00\x00' in a word.
    uint256 private constant ETH_SIGN_HASH_PREFIX =
        0x19457468657265756d205369676e6564204d6573736167653a0a333200000000;
    /// @dev Exclusive upper limit on ECDSA signatures 'R' values.
    ///      The valid range is given by fig (282) of the yellow paper.
    uint256 private constant ECDSA_SIGNATURE_R_LIMIT =
        uint256(0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141);
    /// @dev Exclusive upper limit on ECDSA signatures 'S' values.
    ///      The valid range is given by fig (283) of the yellow paper.
    uint256 private constant ECDSA_SIGNATURE_S_LIMIT = ECDSA_SIGNATURE_R_LIMIT / 2 + 1;

    /// @dev Allowed signature types.
    enum SignatureType {
        ILLEGAL,
        INVALID,
        EIP712,
        ETHSIGN
    }

    /// @dev Encoded EC signature.
    struct Signature {
        // How to validate the signature.
        SignatureType signatureType;
        // EC Signature data.
        uint8 v;
        // EC Signature data.
        bytes32 r;
        // EC Signature data.
        bytes32 s;
    }

    /// @dev Retrieve the signer of a signature.
    ///      Throws if the signature can't be validated.
    /// @param hash The hash that was signed.
    /// @param signature The signature.
    /// @return recovered The recovered signer address.
    function getSignerOfHash(
        bytes32 hash,
        Signature memory signature
    )
        internal
        pure
        returns (address recovered)
    {
        // Ensure this is a signature type that can be validated against a hash.
        _validateHashCompatibleSignature(hash, signature);

        if (signature.signatureType == SignatureType.EIP712) {
            // Signed using EIP712
            recovered = ecrecover(
                hash,
                signature.v,
                signature.r,
                signature.s
            );
        } else if (signature.signatureType == SignatureType.ETHSIGN) {
            // Signed using `eth_sign`
            // Need to hash `hash` with "\x19Ethereum Signed Message:\n32" prefix
            // in packed encoding.
            bytes32 ethSignHash;
            assembly {
                // Use scratch space
                mstore(0, ETH_SIGN_HASH_PREFIX) // length of 28 bytes
                mstore(28, hash) // length of 32 bytes
                ethSignHash := keccak256(0, 60)
            }
            recovered = ecrecover(
                ethSignHash,
                signature.v,
                signature.r,
                signature.s
            );
        }
        // `recovered` can be null if the signature values are out of range.
        if (recovered == address(0)) {
            LibSignatureRichErrors.SignatureValidationError(
                LibSignatureRichErrors.SignatureValidationErrorCodes.BAD_SIGNATURE_DATA,
                hash
            ).rrevert();
        }
    }

    /// @dev Validates that a signature is compatible with a hash signee.
    /// @param hash The hash that was signed.
    /// @param signature The signature.
    function _validateHashCompatibleSignature(
        bytes32 hash,
        Signature memory signature
    )
        private
        pure
    {
        // Ensure the r and s are within malleability limits.
        if (uint256(signature.r) >= ECDSA_SIGNATURE_R_LIMIT ||
            uint256(signature.s) >= ECDSA_SIGNATURE_S_LIMIT)
        {
            LibSignatureRichErrors.SignatureValidationError(
                LibSignatureRichErrors.SignatureValidationErrorCodes.BAD_SIGNATURE_DATA,
                hash
            ).rrevert();
        }

        // Always illegal signature.
        if (signature.signatureType == SignatureType.ILLEGAL) {
            LibSignatureRichErrors.SignatureValidationError(
                LibSignatureRichErrors.SignatureValidationErrorCodes.ILLEGAL,
                hash
            ).rrevert();
        }

        // Always invalid.
        if (signature.signatureType == SignatureType.INVALID) {
            LibSignatureRichErrors.SignatureValidationError(
                LibSignatureRichErrors.SignatureValidationErrorCodes.ALWAYS_INVALID,
                hash
            ).rrevert();
        }

        // Solidity should check that the signature type is within enum range for us
        // when abi-decoding.
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../errors/LibNativeOrdersRichErrors.sol";


/// @dev A library for common native order operations.
library LibNativeOrder {
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    enum OrderStatus {
        INVALID,
        FILLABLE,
        FILLED,
        CANCELLED,
        EXPIRED
    }

    /// @dev A standard OTC or OO limit order.
    struct LimitOrder {
        IERC20TokenV06 makerToken;
        IERC20TokenV06 takerToken;
        uint128 makerAmount;
        uint128 takerAmount;
        uint128 takerTokenFeeAmount;
        address maker;
        address taker;
        address sender;
        address feeRecipient;
        bytes32 pool;
        uint64 expiry;
        uint256 salt;
    }

    /// @dev An RFQ limit order.
    struct RfqOrder {
        IERC20TokenV06 makerToken;
        IERC20TokenV06 takerToken;
        uint128 makerAmount;
        uint128 takerAmount;
        address maker;
        address taker;
        address txOrigin;
        bytes32 pool;
        uint64 expiry;
        uint256 salt;
    }

    /// @dev An OTC limit order.
    struct OtcOrder {
        IERC20TokenV06 makerToken;
        IERC20TokenV06 takerToken;
        uint128 makerAmount;
        uint128 takerAmount;
        address maker;
        address taker;
        address txOrigin;
        uint256 expiryAndNonce; // [uint64 expiry, uint64 nonceBucket, uint128 nonce]
    }

    /// @dev Info on a limit or RFQ order.
    struct OrderInfo {
        bytes32 orderHash;
        OrderStatus status;
        uint128 takerTokenFilledAmount;
    }

    /// @dev Info on an OTC order.
    struct OtcOrderInfo {
        bytes32 orderHash;
        OrderStatus status;
    }

    uint256 private constant UINT_128_MASK = (1 << 128) - 1;
    uint256 private constant UINT_64_MASK = (1 << 64) - 1;
    uint256 private constant ADDRESS_MASK = (1 << 160) - 1;

    // The type hash for limit orders, which is:
    // keccak256(abi.encodePacked(
    //     "LimitOrder(",
    //       "address makerToken,",
    //       "address takerToken,",
    //       "uint128 makerAmount,",
    //       "uint128 takerAmount,",
    //       "uint128 takerTokenFeeAmount,",
    //       "address maker,",
    //       "address taker,",
    //       "address sender,",
    //       "address feeRecipient,",
    //       "bytes32 pool,",
    //       "uint64 expiry,",
    //       "uint256 salt"
    //     ")"
    // ))
    uint256 private constant _LIMIT_ORDER_TYPEHASH =
        0xce918627cb55462ddbb85e73de69a8b322f2bc88f4507c52fcad6d4c33c29d49;

    // The type hash for RFQ orders, which is:
    // keccak256(abi.encodePacked(
    //     "RfqOrder(",
    //       "address makerToken,",
    //       "address takerToken,",
    //       "uint128 makerAmount,",
    //       "uint128 takerAmount,",
    //       "address maker,",
    //       "address taker,",
    //       "address txOrigin,",
    //       "bytes32 pool,",
    //       "uint64 expiry,",
    //       "uint256 salt"
    //     ")"
    // ))
    uint256 private constant _RFQ_ORDER_TYPEHASH =
        0xe593d3fdfa8b60e5e17a1b2204662ecbe15c23f2084b9ad5bae40359540a7da9;

    // The type hash for OTC orders, which is:
    // keccak256(abi.encodePacked(
    //     "OtcOrder(",
    //       "address makerToken,",
    //       "address takerToken,",
    //       "uint128 makerAmount,",
    //       "uint128 takerAmount,",
    //       "address maker,",
    //       "address taker,",
    //       "address txOrigin,",
    //       "uint256 expiryAndNonce"
    //     ")"
    // ))
    uint256 private constant _OTC_ORDER_TYPEHASH =
        0x2f754524de756ae72459efbe1ec88c19a745639821de528ac3fb88f9e65e35c8;

    /// @dev Get the struct hash of a limit order.
    /// @param order The limit order.
    /// @return structHash The struct hash of the order.
    function getLimitOrderStructHash(LimitOrder memory order)
        internal
        pure
        returns (bytes32 structHash)
    {
        // The struct hash is:
        // keccak256(abi.encode(
        //   TYPE_HASH,
        //   order.makerToken,
        //   order.takerToken,
        //   order.makerAmount,
        //   order.takerAmount,
        //   order.takerTokenFeeAmount,
        //   order.maker,
        //   order.taker,
        //   order.sender,
        //   order.feeRecipient,
        //   order.pool,
        //   order.expiry,
        //   order.salt,
        // ))
        assembly {
            let mem := mload(0x40)
            mstore(mem, _LIMIT_ORDER_TYPEHASH)
            // order.makerToken;
            mstore(add(mem, 0x20), and(ADDRESS_MASK, mload(order)))
            // order.takerToken;
            mstore(add(mem, 0x40), and(ADDRESS_MASK, mload(add(order, 0x20))))
            // order.makerAmount;
            mstore(add(mem, 0x60), and(UINT_128_MASK, mload(add(order, 0x40))))
            // order.takerAmount;
            mstore(add(mem, 0x80), and(UINT_128_MASK, mload(add(order, 0x60))))
            // order.takerTokenFeeAmount;
            mstore(add(mem, 0xA0), and(UINT_128_MASK, mload(add(order, 0x80))))
            // order.maker;
            mstore(add(mem, 0xC0), and(ADDRESS_MASK, mload(add(order, 0xA0))))
            // order.taker;
            mstore(add(mem, 0xE0), and(ADDRESS_MASK, mload(add(order, 0xC0))))
            // order.sender;
            mstore(add(mem, 0x100), and(ADDRESS_MASK, mload(add(order, 0xE0))))
            // order.feeRecipient;
            mstore(add(mem, 0x120), and(ADDRESS_MASK, mload(add(order, 0x100))))
            // order.pool;
            mstore(add(mem, 0x140), mload(add(order, 0x120)))
            // order.expiry;
            mstore(add(mem, 0x160), and(UINT_64_MASK, mload(add(order, 0x140))))
            // order.salt;
            mstore(add(mem, 0x180), mload(add(order, 0x160)))
            structHash := keccak256(mem, 0x1A0)
        }
    }

    /// @dev Get the struct hash of a RFQ order.
    /// @param order The RFQ order.
    /// @return structHash The struct hash of the order.
    function getRfqOrderStructHash(RfqOrder memory order)
        internal
        pure
        returns (bytes32 structHash)
    {
        // The struct hash is:
        // keccak256(abi.encode(
        //   TYPE_HASH,
        //   order.makerToken,
        //   order.takerToken,
        //   order.makerAmount,
        //   order.takerAmount,
        //   order.maker,
        //   order.taker,
        //   order.txOrigin,
        //   order.pool,
        //   order.expiry,
        //   order.salt,
        // ))
        assembly {
            let mem := mload(0x40)
            mstore(mem, _RFQ_ORDER_TYPEHASH)
            // order.makerToken;
            mstore(add(mem, 0x20), and(ADDRESS_MASK, mload(order)))
            // order.takerToken;
            mstore(add(mem, 0x40), and(ADDRESS_MASK, mload(add(order, 0x20))))
            // order.makerAmount;
            mstore(add(mem, 0x60), and(UINT_128_MASK, mload(add(order, 0x40))))
            // order.takerAmount;
            mstore(add(mem, 0x80), and(UINT_128_MASK, mload(add(order, 0x60))))
            // order.maker;
            mstore(add(mem, 0xA0), and(ADDRESS_MASK, mload(add(order, 0x80))))
            // order.taker;
            mstore(add(mem, 0xC0), and(ADDRESS_MASK, mload(add(order, 0xA0))))
            // order.txOrigin;
            mstore(add(mem, 0xE0), and(ADDRESS_MASK, mload(add(order, 0xC0))))
            // order.pool;
            mstore(add(mem, 0x100), mload(add(order, 0xE0)))
            // order.expiry;
            mstore(add(mem, 0x120), and(UINT_64_MASK, mload(add(order, 0x100))))
            // order.salt;
            mstore(add(mem, 0x140), mload(add(order, 0x120)))
            structHash := keccak256(mem, 0x160)
        }
    }

    /// @dev Get the struct hash of an OTC order.
    /// @param order The OTC order.
    /// @return structHash The struct hash of the order.
    function getOtcOrderStructHash(OtcOrder memory order)
        internal
        pure
        returns (bytes32 structHash)
    {
        // The struct hash is:
        // keccak256(abi.encode(
        //   TYPE_HASH,
        //   order.makerToken,
        //   order.takerToken,
        //   order.makerAmount,
        //   order.takerAmount,
        //   order.maker,
        //   order.taker,
        //   order.txOrigin,
        //   order.expiryAndNonce,
        // ))
        assembly {
            let mem := mload(0x40)
            mstore(mem, _OTC_ORDER_TYPEHASH)
            // order.makerToken;
            mstore(add(mem, 0x20), and(ADDRESS_MASK, mload(order)))
            // order.takerToken;
            mstore(add(mem, 0x40), and(ADDRESS_MASK, mload(add(order, 0x20))))
            // order.makerAmount;
            mstore(add(mem, 0x60), and(UINT_128_MASK, mload(add(order, 0x40))))
            // order.takerAmount;
            mstore(add(mem, 0x80), and(UINT_128_MASK, mload(add(order, 0x60))))
            // order.maker;
            mstore(add(mem, 0xA0), and(ADDRESS_MASK, mload(add(order, 0x80))))
            // order.taker;
            mstore(add(mem, 0xC0), and(ADDRESS_MASK, mload(add(order, 0xA0))))
            // order.txOrigin;
            mstore(add(mem, 0xE0), and(ADDRESS_MASK, mload(add(order, 0xC0))))
            // order.expiryAndNonce;
            mstore(add(mem, 0x100), mload(add(order, 0xE0)))
            structHash := keccak256(mem, 0x120)
        }
    }

    /// @dev Refund any leftover protocol fees in `msg.value` to `msg.sender`.
    /// @param ethProtocolFeePaid How much ETH was paid in protocol fees.
    function refundExcessProtocolFeeToSender(uint256 ethProtocolFeePaid)
        internal
    {
        if (msg.value > ethProtocolFeePaid && msg.sender != address(this)) {
            uint256 refundAmount = msg.value.safeSub(ethProtocolFeePaid);
            (bool success,) = msg
                .sender
                .call{value: refundAmount}("");
            if (!success) {
                LibNativeOrdersRichErrors.ProtocolFeeRefundFailed(
                    msg.sender,
                    refundAmount
                ).rrevert();
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../libs/LibSignature.sol";
import "../libs/LibNativeOrder.sol";


/// @dev Events emitted by NativeOrdersFeature.
interface INativeOrdersEvents {

    /// @dev Emitted whenever a `LimitOrder` is filled.
    /// @param orderHash The canonical hash of the order.
    /// @param maker The maker of the order.
    /// @param taker The taker of the order.
    /// @param feeRecipient Fee recipient of the order.
    /// @param takerTokenFilledAmount How much taker token was filled.
    /// @param makerTokenFilledAmount How much maker token was filled.
    /// @param protocolFeePaid How much protocol fee was paid.
    /// @param pool The fee pool associated with this order.
    event LimitOrderFilled(
        bytes32 orderHash,
        address maker,
        address taker,
        address feeRecipient,
        address makerToken,
        address takerToken,
        uint128 takerTokenFilledAmount,
        uint128 makerTokenFilledAmount,
        uint128 takerTokenFeeFilledAmount,
        uint256 protocolFeePaid,
        bytes32 pool
    );

    /// @dev Emitted whenever an `RfqOrder` is filled.
    /// @param orderHash The canonical hash of the order.
    /// @param maker The maker of the order.
    /// @param taker The taker of the order.
    /// @param takerTokenFilledAmount How much taker token was filled.
    /// @param makerTokenFilledAmount How much maker token was filled.
    /// @param pool The fee pool associated with this order.
    event RfqOrderFilled(
        bytes32 orderHash,
        address maker,
        address taker,
        address makerToken,
        address takerToken,
        uint128 takerTokenFilledAmount,
        uint128 makerTokenFilledAmount,
        bytes32 pool
    );

    /// @dev Emitted whenever a limit or RFQ order is cancelled.
    /// @param orderHash The canonical hash of the order.
    /// @param maker The order maker.
    event OrderCancelled(
        bytes32 orderHash,
        address maker
    );

    /// @dev Emitted whenever Limit orders are cancelled by pair by a maker.
    /// @param maker The maker of the order.
    /// @param makerToken The maker token in a pair for the orders cancelled.
    /// @param takerToken The taker token in a pair for the orders cancelled.
    /// @param minValidSalt The new minimum valid salt an order with this pair must
    ///        have.
    event PairCancelledLimitOrders(
        address maker,
        address makerToken,
        address takerToken,
        uint256 minValidSalt
    );

    /// @dev Emitted whenever RFQ orders are cancelled by pair by a maker.
    /// @param maker The maker of the order.
    /// @param makerToken The maker token in a pair for the orders cancelled.
    /// @param takerToken The taker token in a pair for the orders cancelled.
    /// @param minValidSalt The new minimum valid salt an order with this pair must
    ///        have.
    event PairCancelledRfqOrders(
        address maker,
        address makerToken,
        address takerToken,
        uint256 minValidSalt
    );

    /// @dev Emitted when new addresses are allowed or disallowed to fill
    ///      orders with a given txOrigin.
    /// @param origin The address doing the allowing.
    /// @param addrs The address being allowed/disallowed.
    /// @param allowed Indicates whether the address should be allowed.
    event RfqOrderOriginsAllowed(
        address origin,
        address[] addrs,
        bool allowed
    );

    /// @dev Emitted when new order signers are registered
    /// @param maker The maker address that is registering a designated signer.
    /// @param signer The address that will sign on behalf of maker.
    /// @param allowed Indicates whether the address should be allowed.
    event OrderSignerRegistered(
        address maker,
        address signer,
        bool allowed
    );
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;


library LibSignatureRichErrors {

    enum SignatureValidationErrorCodes {
        ALWAYS_INVALID,
        INVALID_LENGTH,
        UNSUPPORTED,
        ILLEGAL,
        WRONG_SIGNER,
        BAD_SIGNATURE_DATA
    }

    // solhint-disable func-name-mixedcase

    function SignatureValidationError(
        SignatureValidationErrorCodes code,
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("SignatureValidationError(uint8,bytes32,address,bytes)")),
            code,
            hash,
            signerAddress,
            signature
        );
    }

    function SignatureValidationError(
        SignatureValidationErrorCodes code,
        bytes32 hash
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("SignatureValidationError(uint8,bytes32)")),
            code,
            hash
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

library LibRichErrorsV06 {
    // bytes4(keccak256("Error(string)"))
    bytes4 internal constant STANDARD_ERROR_SELECTOR = 0x08c379a0;

    // solhint-disable func-name-mixedcase
    /// @dev ABI encode a standard, string revert error payload.
    ///      This is the same payload that would be included by a `revert(string)`
    ///      solidity statement. It has the function signature `Error(string)`.
    /// @param message The error string.
    /// @return The ABI encoded error.
    function StandardError(string memory message) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(STANDARD_ERROR_SELECTOR, bytes(message));
    }

    // solhint-enable func-name-mixedcase

    /// @dev Reverts an encoded rich revert reason `errorData`.
    /// @param errorData ABI encoded error data.
    function rrevert(bytes memory errorData) internal pure {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

import "./errors/LibRichErrorsV06.sol";
import "./errors/LibSafeMathRichErrorsV06.sol";

library LibSafeMathV06 {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        if (c / a != b) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                    a,
                    b
                )
            );
        }
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.DIVISION_BY_ZERO,
                    a,
                    b
                )
            );
        }
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b > a) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.SUBTRACTION_UNDERFLOW,
                    a,
                    b
                )
            );
        }
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        if (c < a) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.ADDITION_OVERFLOW,
                    a,
                    b
                )
            );
        }
        return c;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function safeMul128(uint128 a, uint128 b) internal pure returns (uint128) {
        if (a == 0) {
            return 0;
        }
        uint128 c = a * b;
        if (c / a != b) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                    a,
                    b
                )
            );
        }
        return c;
    }

    function safeDiv128(uint128 a, uint128 b) internal pure returns (uint128) {
        if (b == 0) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.DIVISION_BY_ZERO,
                    a,
                    b
                )
            );
        }
        uint128 c = a / b;
        return c;
    }

    function safeSub128(uint128 a, uint128 b) internal pure returns (uint128) {
        if (b > a) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.SUBTRACTION_UNDERFLOW,
                    a,
                    b
                )
            );
        }
        return a - b;
    }

    function safeAdd128(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        if (c < a) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.ADDITION_OVERFLOW,
                    a,
                    b
                )
            );
        }
        return c;
    }

    function max128(uint128 a, uint128 b) internal pure returns (uint128) {
        return a >= b ? a : b;
    }

    function min128(uint128 a, uint128 b) internal pure returns (uint128) {
        return a < b ? a : b;
    }

    function safeDowncastToUint128(uint256 a) internal pure returns (uint128) {
        if (a > type(uint128).max) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256DowncastError(
                    LibSafeMathRichErrorsV06.DowncastErrorCodes.VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT128,
                    a
                )
            );
        }
        return uint128(a);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;


library LibNativeOrdersRichErrors {

    // solhint-disable func-name-mixedcase

    function ProtocolFeeRefundFailed(
        address receiver,
        uint256 refundAmount
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("ProtocolFeeRefundFailed(address,uint256)")),
            receiver,
            refundAmount
        );
    }

    function OrderNotFillableByOriginError(
        bytes32 orderHash,
        address txOrigin,
        address orderTxOrigin
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OrderNotFillableByOriginError(bytes32,address,address)")),
            orderHash,
            txOrigin,
            orderTxOrigin
        );
    }

    function OrderNotFillableError(
        bytes32 orderHash,
        uint8 orderStatus
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OrderNotFillableError(bytes32,uint8)")),
            orderHash,
            orderStatus
        );
    }

    function OrderNotSignedByMakerError(
        bytes32 orderHash,
        address signer,
        address maker
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OrderNotSignedByMakerError(bytes32,address,address)")),
            orderHash,
            signer,
            maker
        );
    }

    function OrderNotSignedByTakerError(
        bytes32 orderHash,
        address signer,
        address taker
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OrderNotSignedByTakerError(bytes32,address,address)")),
            orderHash,
            signer,
            taker
        );
    }

    function InvalidSignerError(
        address maker,
        address signer
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidSignerError(address,address)")),
            maker,
            signer
        );
    }

    function OrderNotFillableBySenderError(
        bytes32 orderHash,
        address sender,
        address orderSender
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OrderNotFillableBySenderError(bytes32,address,address)")),
            orderHash,
            sender,
            orderSender
        );
    }

    function OrderNotFillableByTakerError(
        bytes32 orderHash,
        address taker,
        address orderTaker
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OrderNotFillableByTakerError(bytes32,address,address)")),
            orderHash,
            taker,
            orderTaker
        );
    }

    function CancelSaltTooLowError(
        uint256 minValidSalt,
        uint256 oldMinValidSalt
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("CancelSaltTooLowError(uint256,uint256)")),
            minValidSalt,
            oldMinValidSalt
        );
    }

    function FillOrKillFailedError(
        bytes32 orderHash,
        uint256 takerTokenFilledAmount,
        uint256 takerTokenFillAmount
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("FillOrKillFailedError(bytes32,uint256,uint256)")),
            orderHash,
            takerTokenFilledAmount,
            takerTokenFillAmount
        );
    }

    function OnlyOrderMakerAllowed(
        bytes32 orderHash,
        address sender,
        address maker
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OnlyOrderMakerAllowed(bytes32,address,address)")),
            orderHash,
            sender,
            maker
        );
    }

    function BatchFillIncompleteError(
        bytes32 orderHash,
        uint256 takerTokenFilledAmount,
        uint256 takerTokenFillAmount
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("BatchFillIncompleteError(bytes32,uint256,uint256)")),
            orderHash,
            takerTokenFilledAmount,
            takerTokenFillAmount
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

library LibSafeMathRichErrorsV06 {
    // bytes4(keccak256("Uint256BinOpError(uint8,uint256,uint256)"))
    bytes4 internal constant UINT256_BINOP_ERROR_SELECTOR = 0xe946c1bb;

    // bytes4(keccak256("Uint256DowncastError(uint8,uint256)"))
    bytes4 internal constant UINT256_DOWNCAST_ERROR_SELECTOR = 0xc996af7b;

    enum BinOpErrorCodes {
        ADDITION_OVERFLOW,
        MULTIPLICATION_OVERFLOW,
        SUBTRACTION_UNDERFLOW,
        DIVISION_BY_ZERO
    }

    enum DowncastErrorCodes {
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT32,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT64,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT96,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT128
    }

    // solhint-disable func-name-mixedcase
    function Uint256BinOpError(
        BinOpErrorCodes errorCode,
        uint256 a,
        uint256 b
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(UINT256_BINOP_ERROR_SELECTOR, errorCode, a, b);
    }

    function Uint256DowncastError(DowncastErrorCodes errorCode, uint256 a) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(UINT256_DOWNCAST_ERROR_SELECTOR, errorCode, a);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../interfaces/curve/ICryptoSwapPool.sol";
import "../../interfaces/curve/IRegistry.sol";
import "../../interfaces/curve/IAddressProvider.sol";
import "../BaseController.sol";

/* solhint-disable func-name-mixedcase, var-name-mixedcase */
contract CurveControllerV2Template is BaseController {
	event AddLiquidity(
		address indexed provider,
		uint256[N_COINS] token_amounts,
		uint256 token_supply,
		uint256 lp_token_amount
	);

	event RemoveLiquidity(
		address indexed provider,
		uint256[N_COINS] token_amounts,
		uint256 token_supply,
		uint256[N_COINS] amounts
	);

	event RemoveLiquidityOne(
		address indexed provider,
		uint256 token_amount,
		uint256 coin_index,
		uint256 coin_amount,
		address coin_address
	);

	using SafeERC20 for IERC20;
	using Address for address;
	using SafeMath for uint256;

	IAddressProvider public immutable addressProvider;

	uint256 public constant N_COINS = 2;

	constructor(
		address _manager,
		address _accessControl,
		address _addressRegistry,
		IAddressProvider _curveAddressProvider
	) public BaseController(_manager, _accessControl, _addressRegistry) {
		require(address(_curveAddressProvider) != address(0), "INVALID_CURVE_ADDRESS_PROVIDER");
		addressProvider = _curveAddressProvider;
	}

	/// @notice Deploy liquidity to Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amounts List of amounts of coins to deposit
	/// @param poolAddress Minimum amount of LP tokens to mint from the deposit
	function deploy(
		address poolAddress,
		uint256[N_COINS] calldata amounts,
		uint256 minMintAmount
	) external onlyManager onlyAddLiquidity {
		address lpTokenAddress = _getLPToken(poolAddress);
		uint256 amountsLength = amounts.length;

		for (uint256 i = 0; i < amountsLength; ++i) {
			if (amounts[i] > 0) {
				address coin = ICryptoSwapPool(poolAddress).coins(i);

				require(addressRegistry.checkAddress(coin, 0), "INVALID_COIN");

				uint256 balance = IERC20(coin).balanceOf(address(this));

				require(balance >= amounts[i], "INSUFFICIENT_BALANCE");

				_approve(IERC20(coin), poolAddress, amounts[i]);
			}
		}

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		ICryptoSwapPool(poolAddress).add_liquidity(amounts, minMintAmount);
		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));

		uint256 lpTokenAmount = lpTokenBalanceAfter.sub(lpTokenBalanceBefore);

		require(lpTokenAmount >= minMintAmount, "LP_AMT_TOO_LOW");

		emit AddLiquidity(msg.sender, amounts, IERC20(lpTokenAddress).totalSupply(), lpTokenAmount);
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amount Quantity of LP tokens to burn in the withdrawal
	/// @param minAmounts Minimum amounts of underlying coins to receive
	function withdraw(
		address poolAddress,
		uint256 amount,
		uint256[N_COINS] memory minAmounts
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, amount);

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(poolAddress);

		ICryptoSwapPool(poolAddress).remove_liquidity(amount, minAmounts);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

		_compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, minAmounts);

		require(lpTokenBalanceBefore.sub(amount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");

		emit RemoveLiquidity(msg.sender, coinsBalancesAfter, IERC20(lpTokenAddress).totalSupply(), minAmounts);
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress token addresses
	/// @param tokenAmount Amount of LP tokens to burn in the withdrawal
	/// @param i Index value of the coin to withdraw
	/// @param minAmount Minimum amount of coin to receive
	function withdrawOneCoin(
		address poolAddress,
		uint256 tokenAmount,
		uint256 i,
		uint256 minAmount
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, tokenAmount);
		address coin = ICryptoSwapPool(poolAddress).coins(uint256(i));

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256 coinBalanceBefore = IERC20(coin).balanceOf(address(this));

		ICryptoSwapPool(poolAddress).remove_liquidity_one_coin(tokenAmount, i, minAmount);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256 coinBalanceAfter = IERC20(coin).balanceOf(address(this));

		require(coinBalanceBefore < coinBalanceAfter, "BALANCE_MUST_INCREASE");
		require(lpTokenBalanceBefore.sub(tokenAmount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");

		uint256 coin_amount = ICryptoSwapPool(poolAddress).calc_withdraw_one_coin(minAmount, i);

		emit RemoveLiquidityOne(msg.sender, tokenAmount, i, coin_amount, coin);
	}

	function _getLPToken(address poolAddress) internal returns (address) {
		require(poolAddress != address(0), "INVALID_POOL_ADDRESS");

		address registryAddress = addressProvider.get_registry();
		address lpTokenAddress = IRegistry(registryAddress).get_lp_token(poolAddress);

		// If it's not registered in curve registry that should mean it's a factory pool (pool is also the LP Token)
		// https://curve.readthedocs.io/factory-pools.html?highlight=factory%20pools%20differ#lp-tokens
		if (lpTokenAddress == address(0)) {
			lpTokenAddress = poolAddress;
		}

		require(addressRegistry.checkAddress(lpTokenAddress, 0), "INVALID_LP_TOKEN");

		return lpTokenAddress;
	}

	function _getCoinsBalances(address poolAddress) internal returns (uint256[N_COINS] memory coinsBalances) {
		for (uint256 i = 0; i < N_COINS; ++i) {
			address coin = ICryptoSwapPool(poolAddress).coins(i);
			uint256 balance = IERC20(coin).balanceOf(address(this));
			coinsBalances[i] = balance;
		}
		return coinsBalances;
	}

	function _compareCoinsBalances(
		uint256[N_COINS] memory balancesBefore,
		uint256[N_COINS] memory balancesAfter,
		uint256[N_COINS] memory amounts
	) internal pure {
		for (uint256 i = 0; i < N_COINS; ++i) {
			uint256 minAmount = amounts[i];
			require(balancesAfter[i].sub(balancesBefore[i]) >= minAmount, "INVALID_BALANCE_CHANGE");
		}
	}

	function _getLPTokenAndApprove(address poolAddress, uint256 amount) internal returns (address) {
		address lpTokenAddress = _getLPToken(poolAddress);
		if (lpTokenAddress != poolAddress) {
			_approve(IERC20(lpTokenAddress), poolAddress, amount);
		}
		return lpTokenAddress;
	}

	function _approve(IERC20 token, address spender, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), spender);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(spender, currentAllowance);
		}
		token.safeIncreaseAllowance(spender, amount);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface ICryptoSwapPool {
	/* solhint-disable func-name-mixedcase, var-name-mixedcase */

	function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external;

	function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;

	function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount) external;

	function remove_liquidity(uint256 amount, uint256[2] memory min_amounts) external;

	function remove_liquidity(uint256 amount, uint256[3] memory min_amounts) external;

	function remove_liquidity(uint256 amount, uint256[4] memory min_amounts) external;

	function remove_liquidity_one_coin(uint256 token_amount, uint256 i, uint256 min_amount) external;

	function calc_withdraw_one_coin(uint256 token_amount, uint256 i) external returns (uint256);

	function coins(uint256 i) external returns (address);

	function balanceOf(address account) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IRegistry {
	/* solhint-disable func-name-mixedcase, var-name-mixedcase */
	function get_lp_token(address pool) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IAddressProvider {
	/* solhint-disable func-name-mixedcase, var-name-mixedcase */
	function get_registry() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <=0.6.12;

import "../interfaces/IAddressRegistry.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

//solhint-disable var-name-mixedcase
contract BaseController {
	address public immutable manager;
	address public immutable accessControl;
	IAddressRegistry public immutable addressRegistry;

	bytes32 public immutable ADD_LIQUIDITY_ROLE = keccak256("ADD_LIQUIDITY_ROLE");
	bytes32 public immutable REMOVE_LIQUIDITY_ROLE = keccak256("REMOVE_LIQUIDITY_ROLE");
	bytes32 public immutable MISC_OPERATION_ROLE = keccak256("MISC_OPERATION_ROLE");

	constructor(address _manager, address _accessControl, address _addressRegistry) public {
		require(_manager != address(0), "INVALID_ADDRESS");
		require(_accessControl != address(0), "INVALID_ADDRESS");
		require(_addressRegistry != address(0), "INVALID_ADDRESS");

		manager = _manager;
		accessControl = _accessControl;
		addressRegistry = IAddressRegistry(_addressRegistry);
	}

	modifier onlyManager() {
		require(address(this) == manager, "NOT_MANAGER_ADDRESS");
		_;
	}

	modifier onlyAddLiquidity() {
		require(AccessControl(accessControl).hasRole(ADD_LIQUIDITY_ROLE, msg.sender), "NOT_ADD_LIQUIDITY_ROLE");
		_;
	}

	modifier onlyRemoveLiquidity() {
		require(AccessControl(accessControl).hasRole(REMOVE_LIQUIDITY_ROLE, msg.sender), "NOT_REMOVE_LIQUIDITY_ROLE");
		_;
	}

	modifier onlyMiscOperation() {
		require(AccessControl(accessControl).hasRole(MISC_OPERATION_ROLE, msg.sender), "NOT_MISC_OPERATION_ROLE");
		_;
	}
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <=0.6.12;
pragma experimental ABIEncoderV2;

/**
 *   @title Track addresses to be used in liquidity deployment
 *   Any controller used, asset deployed, or pool tracked within the
 *   system should be registered here
 */
interface IAddressRegistry {
	enum AddressTypes {
		Token,
		Controller,
		Pool
	}

	event RegisteredAddressAdded(address added);
	event RegisteredAddressRemoved(address removed);
	event AddedToRegistry(address[] addresses, AddressTypes);
	event RemovedFromRegistry(address[] addresses, AddressTypes);

	/// @notice Allows address with REGISTERED_ROLE to add a registered address
	/// @param _addr address to be added
	function addRegistrar(address _addr) external;

	/// @notice Allows address with REGISTERED_ROLE to remove a registered address
	/// @param _addr address to be removed
	function removeRegistrar(address _addr) external;

	/// @notice Allows array of addresses to be added to registry for certain index
	/// @param _addresses calldata array of addresses to be added to registry
	/// @param _index AddressTypes enum of index to add addresses to
	function addToRegistry(address[] calldata _addresses, AddressTypes _index) external;

	/// @notice Allows array of addresses to be removed from registry for certain index
	/// @param _addresses calldata array of addresses to be removed from registry
	/// @param _index AddressTypes enum of index to remove addresses from
	function removeFromRegistry(address[] calldata _addresses, AddressTypes _index) external;

	/// @notice Allows array of all addresses for certain index to be returned
	/// @param _index AddressTypes enum of index to be returned
	/// @return address[] memory of addresses from index
	function getAddressForType(AddressTypes _index) external view returns (address[] memory);

	/// @notice Allows checking that one address exists in certain index
	/// @param _addr address to be checked
	/// @param _index AddressTypes index to check address against
	/// @return bool tells whether address exists or not
	function checkAddress(address _addr, uint256 _index) external view returns (bool);

	/// @notice Returns weth address
	/// @return address weth address
	function weth() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../interfaces/curve/ICryptoSwapPool.sol";
import "../../interfaces/curve/IRegistry.sol";
import "../../interfaces/curve/IAddressProvider.sol";
import "../BaseController.sol";

/* solhint-disable func-name-mixedcase, var-name-mixedcase */
contract CurveControllerV2Pool4 is BaseController {
	event AddLiquidity(
		address indexed provider,
		uint256[N_COINS] token_amounts,
		uint256 token_supply,
		uint256 lp_token_amount
	);

	event RemoveLiquidity(
		address indexed provider,
		uint256[N_COINS] token_amounts,
		uint256 token_supply,
		uint256[N_COINS] amounts
	);

	event RemoveLiquidityOne(
		address indexed provider,
		uint256 token_amount,
		uint256 coin_index,
		uint256 coin_amount,
		address coin_address
	);

	using SafeERC20 for IERC20;
	using Address for address;
	using SafeMath for uint256;

	IAddressProvider public immutable addressProvider;

	uint256 public constant N_COINS = 4;

	constructor(
		address _manager,
		address _accessControl,
		address _addressRegistry,
		IAddressProvider _curveAddressProvider
	) public BaseController(_manager, _accessControl, _addressRegistry) {
		require(address(_curveAddressProvider) != address(0), "INVALID_CURVE_ADDRESS_PROVIDER");
		addressProvider = _curveAddressProvider;
	}

	/// @notice Deploy liquidity to Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amounts List of amounts of coins to deposit
	/// @param poolAddress Minimum amount of LP tokens to mint from the deposit
	function deploy(
		address poolAddress,
		uint256[N_COINS] calldata amounts,
		uint256 minMintAmount
	) external onlyManager onlyAddLiquidity {
		address lpTokenAddress = _getLPToken(poolAddress);
		uint256 amountsLength = amounts.length;

		for (uint256 i = 0; i < amountsLength; ++i) {
			if (amounts[i] > 0) {
				address coin = ICryptoSwapPool(poolAddress).coins(i);

				require(addressRegistry.checkAddress(coin, 0), "INVALID_COIN");

				uint256 balance = IERC20(coin).balanceOf(address(this));

				require(balance >= amounts[i], "INSUFFICIENT_BALANCE");

				_approve(IERC20(coin), poolAddress, amounts[i]);
			}
		}

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		ICryptoSwapPool(poolAddress).add_liquidity(amounts, minMintAmount);
		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));

		uint256 lpTokenAmount = lpTokenBalanceAfter.sub(lpTokenBalanceBefore);

		require(lpTokenAmount >= minMintAmount, "LP_AMT_TOO_LOW");

		emit AddLiquidity(msg.sender, amounts, IERC20(lpTokenAddress).totalSupply(), lpTokenAmount);
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amount Quantity of LP tokens to burn in the withdrawal
	/// @param minAmounts Minimum amounts of underlying coins to receive
	function withdraw(
		address poolAddress,
		uint256 amount,
		uint256[N_COINS] memory minAmounts
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, amount);

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(poolAddress);

		ICryptoSwapPool(poolAddress).remove_liquidity(amount, minAmounts);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

		_compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, minAmounts);

		require(lpTokenBalanceBefore.sub(amount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");

		emit RemoveLiquidity(msg.sender, coinsBalancesAfter, IERC20(lpTokenAddress).totalSupply(), minAmounts);
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress token addresses
	/// @param tokenAmount Amount of LP tokens to burn in the withdrawal
	/// @param i Index value of the coin to withdraw
	/// @param minAmount Minimum amount of coin to receive
	function withdrawOneCoin(
		address poolAddress,
		uint256 tokenAmount,
		uint256 i,
		uint256 minAmount
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, tokenAmount);
		address coin = ICryptoSwapPool(poolAddress).coins(uint256(i));

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256 coinBalanceBefore = IERC20(coin).balanceOf(address(this));

		ICryptoSwapPool(poolAddress).remove_liquidity_one_coin(tokenAmount, i, minAmount);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256 coinBalanceAfter = IERC20(coin).balanceOf(address(this));

		require(coinBalanceBefore < coinBalanceAfter, "BALANCE_MUST_INCREASE");
		require(lpTokenBalanceBefore.sub(tokenAmount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");

		uint256 coin_amount = ICryptoSwapPool(poolAddress).calc_withdraw_one_coin(minAmount, i);

		emit RemoveLiquidityOne(msg.sender, tokenAmount, i, coin_amount, coin);
	}

	function _getLPToken(address poolAddress) internal returns (address) {
		require(poolAddress != address(0), "INVALID_POOL_ADDRESS");

		address registryAddress = addressProvider.get_registry();
		address lpTokenAddress = IRegistry(registryAddress).get_lp_token(poolAddress);

		// If it's not registered in curve registry that should mean it's a factory pool (pool is also the LP Token)
		// https://curve.readthedocs.io/factory-pools.html?highlight=factory%20pools%20differ#lp-tokens
		if (lpTokenAddress == address(0)) {
			lpTokenAddress = poolAddress;
		}

		require(addressRegistry.checkAddress(lpTokenAddress, 0), "INVALID_LP_TOKEN");

		return lpTokenAddress;
	}

	function _getCoinsBalances(address poolAddress) internal returns (uint256[N_COINS] memory coinsBalances) {
		for (uint256 i = 0; i < N_COINS; ++i) {
			address coin = ICryptoSwapPool(poolAddress).coins(i);
			uint256 balance = IERC20(coin).balanceOf(address(this));
			coinsBalances[i] = balance;
		}
		return coinsBalances;
	}

	function _compareCoinsBalances(
		uint256[N_COINS] memory balancesBefore,
		uint256[N_COINS] memory balancesAfter,
		uint256[N_COINS] memory amounts
	) internal pure {
		for (uint256 i = 0; i < N_COINS; ++i) {
			uint256 minAmount = amounts[i];
			require(balancesAfter[i].sub(balancesBefore[i]) >= minAmount, "INVALID_BALANCE_CHANGE");
		}
	}

	function _getLPTokenAndApprove(address poolAddress, uint256 amount) internal returns (address) {
		address lpTokenAddress = _getLPToken(poolAddress);
		if (lpTokenAddress != poolAddress) {
			_approve(IERC20(lpTokenAddress), poolAddress, amount);
		}
		return lpTokenAddress;
	}

	function _approve(IERC20 token, address spender, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), spender);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(spender, currentAllowance);
		}
		token.safeIncreaseAllowance(spender, amount);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../interfaces/curve/ICryptoSwapPool.sol";
import "../../interfaces/curve/IRegistry.sol";
import "../../interfaces/curve/IAddressProvider.sol";
import "../BaseController.sol";

/* solhint-disable func-name-mixedcase, var-name-mixedcase */
contract CurveControllerV2Pool3 is BaseController {
	event AddLiquidity(
		address indexed provider,
		uint256[N_COINS] token_amounts,
		uint256 token_supply,
		uint256 lp_token_amount
	);

	event RemoveLiquidity(
		address indexed provider,
		uint256[N_COINS] token_amounts,
		uint256 token_supply,
		uint256[N_COINS] amounts
	);

	event RemoveLiquidityOne(
		address indexed provider,
		uint256 token_amount,
		uint256 coin_index,
		uint256 coin_amount,
		address coin_address
	);

	using SafeERC20 for IERC20;
	using Address for address;
	using SafeMath for uint256;

	IAddressProvider public immutable addressProvider;

	uint256 public constant N_COINS = 3;

	constructor(
		address _manager,
		address _accessControl,
		address _addressRegistry,
		IAddressProvider _curveAddressProvider
	) public BaseController(_manager, _accessControl, _addressRegistry) {
		require(address(_curveAddressProvider) != address(0), "INVALID_CURVE_ADDRESS_PROVIDER");
		addressProvider = _curveAddressProvider;
	}

	/// @notice Deploy liquidity to Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amounts List of amounts of coins to deposit
	/// @param poolAddress Minimum amount of LP tokens to mint from the deposit
	function deploy(
		address poolAddress,
		uint256[N_COINS] calldata amounts,
		uint256 minMintAmount
	) external onlyManager onlyAddLiquidity {
		address lpTokenAddress = _getLPToken(poolAddress);
		uint256 amountsLength = amounts.length;

		for (uint256 i = 0; i < amountsLength; ++i) {
			if (amounts[i] > 0) {
				address coin = ICryptoSwapPool(poolAddress).coins(i);

				require(addressRegistry.checkAddress(coin, 0), "INVALID_COIN");

				uint256 balance = IERC20(coin).balanceOf(address(this));

				require(balance >= amounts[i], "INSUFFICIENT_BALANCE");

				_approve(IERC20(coin), poolAddress, amounts[i]);
			}
		}

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		ICryptoSwapPool(poolAddress).add_liquidity(amounts, minMintAmount);
		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));

		uint256 lpTokenAmount = lpTokenBalanceAfter.sub(lpTokenBalanceBefore);

		require(lpTokenAmount >= minMintAmount, "LP_AMT_TOO_LOW");

		emit AddLiquidity(msg.sender, amounts, IERC20(lpTokenAddress).totalSupply(), lpTokenAmount);
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amount Quantity of LP tokens to burn in the withdrawal
	/// @param minAmounts Minimum amounts of underlying coins to receive
	function withdraw(
		address poolAddress,
		uint256 amount,
		uint256[N_COINS] memory minAmounts
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, amount);

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(poolAddress);

		ICryptoSwapPool(poolAddress).remove_liquidity(amount, minAmounts);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

		_compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, minAmounts);

		require(lpTokenBalanceBefore.sub(amount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");

		emit RemoveLiquidity(msg.sender, coinsBalancesAfter, IERC20(lpTokenAddress).totalSupply(), minAmounts);
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress token addresses
	/// @param tokenAmount Amount of LP tokens to burn in the withdrawal
	/// @param i Index value of the coin to withdraw
	/// @param minAmount Minimum amount of coin to receive
	function withdrawOneCoin(
		address poolAddress,
		uint256 tokenAmount,
		uint256 i,
		uint256 minAmount
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, tokenAmount);
		address coin = ICryptoSwapPool(poolAddress).coins(uint256(i));

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256 coinBalanceBefore = IERC20(coin).balanceOf(address(this));

		ICryptoSwapPool(poolAddress).remove_liquidity_one_coin(tokenAmount, i, minAmount);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256 coinBalanceAfter = IERC20(coin).balanceOf(address(this));

		require(coinBalanceBefore < coinBalanceAfter, "BALANCE_MUST_INCREASE");
		require(lpTokenBalanceBefore.sub(tokenAmount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");

		uint256 coin_amount = ICryptoSwapPool(poolAddress).calc_withdraw_one_coin(minAmount, i);

		emit RemoveLiquidityOne(msg.sender, tokenAmount, i, coin_amount, coin);
	}

	function _getLPToken(address poolAddress) internal returns (address) {
		require(poolAddress != address(0), "INVALID_POOL_ADDRESS");

		address registryAddress = addressProvider.get_registry();
		address lpTokenAddress = IRegistry(registryAddress).get_lp_token(poolAddress);

		// If it's not registered in curve registry that should mean it's a factory pool (pool is also the LP Token)
		// https://curve.readthedocs.io/factory-pools.html?highlight=factory%20pools%20differ#lp-tokens
		if (lpTokenAddress == address(0)) {
			lpTokenAddress = poolAddress;
		}

		require(addressRegistry.checkAddress(lpTokenAddress, 0), "INVALID_LP_TOKEN");

		return lpTokenAddress;
	}

	function _getCoinsBalances(address poolAddress) internal returns (uint256[N_COINS] memory coinsBalances) {
		for (uint256 i = 0; i < N_COINS; ++i) {
			address coin = ICryptoSwapPool(poolAddress).coins(i);
			uint256 balance = IERC20(coin).balanceOf(address(this));
			coinsBalances[i] = balance;
		}
		return coinsBalances;
	}

	function _compareCoinsBalances(
		uint256[N_COINS] memory balancesBefore,
		uint256[N_COINS] memory balancesAfter,
		uint256[N_COINS] memory amounts
	) internal pure {
		for (uint256 i = 0; i < N_COINS; ++i) {
			uint256 minAmount = amounts[i];
			require(balancesAfter[i].sub(balancesBefore[i]) >= minAmount, "INVALID_BALANCE_CHANGE");
		}
	}

	function _getLPTokenAndApprove(address poolAddress, uint256 amount) internal returns (address) {
		address lpTokenAddress = _getLPToken(poolAddress);
		if (lpTokenAddress != poolAddress) {
			_approve(IERC20(lpTokenAddress), poolAddress, amount);
		}
		return lpTokenAddress;
	}

	function _approve(IERC20 token, address spender, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), spender);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(spender, currentAllowance);
		}
		token.safeIncreaseAllowance(spender, amount);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../interfaces/curve/ICryptoSwapPool.sol";
import "../../interfaces/curve/IRegistry.sol";
import "../../interfaces/curve/IAddressProvider.sol";
import "../BaseController.sol";

/* solhint-disable func-name-mixedcase, var-name-mixedcase */
contract CurveControllerV2Pool2 is BaseController {
	event AddLiquidity(
		address indexed provider,
		uint256[N_COINS] token_amounts,
		uint256 token_supply,
		uint256 lp_token_amount
	);

	event RemoveLiquidity(
		address indexed provider,
		uint256[N_COINS] token_amounts,
		uint256 token_supply,
		uint256[N_COINS] amounts
	);

	event RemoveLiquidityOne(
		address indexed provider,
		uint256 token_amount,
		uint256 coin_index,
		uint256 coin_amount,
		address coin_address
	);

	using SafeERC20 for IERC20;
	using Address for address;
	using SafeMath for uint256;

	IAddressProvider public immutable addressProvider;

	uint256 public constant N_COINS = 2;

	constructor(
		address _manager,
		address _accessControl,
		address _addressRegistry,
		IAddressProvider _curveAddressProvider
	) public BaseController(_manager, _accessControl, _addressRegistry) {
		require(address(_curveAddressProvider) != address(0), "INVALID_CURVE_ADDRESS_PROVIDER");
		addressProvider = _curveAddressProvider;
	}

	/// @notice Deploy liquidity to Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amounts List of amounts of coins to deposit
	/// @param poolAddress Minimum amount of LP tokens to mint from the deposit
	function deploy(
		address poolAddress,
		uint256[N_COINS] calldata amounts,
		uint256 minMintAmount
	) external onlyManager onlyAddLiquidity {
		address lpTokenAddress = _getLPToken(poolAddress);
		uint256 amountsLength = amounts.length;

		for (uint256 i = 0; i < amountsLength; ++i) {
			if (amounts[i] > 0) {
				address coin = ICryptoSwapPool(poolAddress).coins(i);

				require(addressRegistry.checkAddress(coin, 0), "INVALID_COIN");

				uint256 balance = IERC20(coin).balanceOf(address(this));

				require(balance >= amounts[i], "INSUFFICIENT_BALANCE");

				_approve(IERC20(coin), poolAddress, amounts[i]);
			}
		}

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		ICryptoSwapPool(poolAddress).add_liquidity(amounts, minMintAmount);
		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));

		uint256 lpTokenAmount = lpTokenBalanceAfter.sub(lpTokenBalanceBefore);

		require(lpTokenAmount >= minMintAmount, "LP_AMT_TOO_LOW");

		emit AddLiquidity(msg.sender, amounts, IERC20(lpTokenAddress).totalSupply(), lpTokenAmount);
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amount Quantity of LP tokens to burn in the withdrawal
	/// @param minAmounts Minimum amounts of underlying coins to receive
	function withdraw(
		address poolAddress,
		uint256 amount,
		uint256[N_COINS] memory minAmounts
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, amount);

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(poolAddress);

		ICryptoSwapPool(poolAddress).remove_liquidity(amount, minAmounts);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

		_compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, minAmounts);

		require(lpTokenBalanceBefore.sub(amount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");

		emit RemoveLiquidity(msg.sender, coinsBalancesAfter, IERC20(lpTokenAddress).totalSupply(), minAmounts);
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress token addresses
	/// @param tokenAmount Amount of LP tokens to burn in the withdrawal
	/// @param i Index value of the coin to withdraw
	/// @param minAmount Minimum amount of coin to receive
	function withdrawOneCoin(
		address poolAddress,
		uint256 tokenAmount,
		uint256 i,
		uint256 minAmount
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, tokenAmount);
		address coin = ICryptoSwapPool(poolAddress).coins(uint256(i));

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256 coinBalanceBefore = IERC20(coin).balanceOf(address(this));

		ICryptoSwapPool(poolAddress).remove_liquidity_one_coin(tokenAmount, i, minAmount);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256 coinBalanceAfter = IERC20(coin).balanceOf(address(this));

		require(coinBalanceBefore < coinBalanceAfter, "BALANCE_MUST_INCREASE");
		require(lpTokenBalanceBefore.sub(tokenAmount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");

		uint256 coin_amount = ICryptoSwapPool(poolAddress).calc_withdraw_one_coin(minAmount, i);

		emit RemoveLiquidityOne(msg.sender, tokenAmount, i, coin_amount, coin);
	}

	function _getLPToken(address poolAddress) internal returns (address) {
		require(poolAddress != address(0), "INVALID_POOL_ADDRESS");

		address registryAddress = addressProvider.get_registry();
		address lpTokenAddress = IRegistry(registryAddress).get_lp_token(poolAddress);

		// If it's not registered in curve registry that should mean it's a factory pool (pool is also the LP Token)
		// https://curve.readthedocs.io/factory-pools.html?highlight=factory%20pools%20differ#lp-tokens
		if (lpTokenAddress == address(0)) {
			lpTokenAddress = poolAddress;
		}

		require(addressRegistry.checkAddress(lpTokenAddress, 0), "INVALID_LP_TOKEN");

		return lpTokenAddress;
	}

	function _getCoinsBalances(address poolAddress) internal returns (uint256[N_COINS] memory coinsBalances) {
		for (uint256 i = 0; i < N_COINS; ++i) {
			address coin = ICryptoSwapPool(poolAddress).coins(i);
			uint256 balance = IERC20(coin).balanceOf(address(this));
			coinsBalances[i] = balance;
		}
		return coinsBalances;
	}

	function _compareCoinsBalances(
		uint256[N_COINS] memory balancesBefore,
		uint256[N_COINS] memory balancesAfter,
		uint256[N_COINS] memory amounts
	) internal pure {
		for (uint256 i = 0; i < N_COINS; ++i) {
			uint256 minAmount = amounts[i];
			require(balancesAfter[i].sub(balancesBefore[i]) >= minAmount, "INVALID_BALANCE_CHANGE");
		}
	}

	function _getLPTokenAndApprove(address poolAddress, uint256 amount) internal returns (address) {
		address lpTokenAddress = _getLPToken(poolAddress);
		if (lpTokenAddress != poolAddress) {
			_approve(IERC20(lpTokenAddress), poolAddress, amount);
		}
		return lpTokenAddress;
	}

	function _approve(IERC20 token, address spender, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), spender);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(spender, currentAllowance);
		}
		token.safeIncreaseAllowance(spender, amount);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../interfaces/curve/IStableSwapPool.sol";
import "../../interfaces/curve/IRegistry.sol";
import "../../interfaces/curve/IAddressProvider.sol";
import "../BaseController.sol";

contract CurveControllerTemplate is BaseController {
	using SafeERC20 for IERC20;
	using Address for address;
	using SafeMath for uint256;

	IAddressProvider public immutable addressProvider;

	uint256 public constant N_COINS = 2;

	constructor(
		address _manager,
		address _accessControl,
		address _addressRegistry,
		IAddressProvider _curveAddressProvider
	) public BaseController(_manager, _accessControl, _addressRegistry) {
		require(address(_curveAddressProvider) != address(0), "INVALID_CURVE_ADDRESS_PROVIDER");
		addressProvider = _curveAddressProvider;
	}

	/// @notice Deploy liquidity to Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amounts List of amounts of coins to deposit
	/// @param poolAddress Minimum amount of LP tokens to mint from the deposit
	function deploy(
		address poolAddress,
		uint256[N_COINS] calldata amounts,
		uint256 minMintAmount
	) external onlyManager onlyAddLiquidity {
		address lpTokenAddress = _getLPToken(poolAddress);
		uint256 amountsLength = amounts.length;

		for (uint256 i = 0; i < amountsLength; ++i) {
			if (amounts[i] > 0) {
				address coin = IStableSwapPool(poolAddress).coins(i);

				require(addressRegistry.checkAddress(coin, 0), "INVALID_COIN");

				uint256 balance = IERC20(coin).balanceOf(address(this));

				require(balance >= amounts[i], "INSUFFICIENT_BALANCE");

				_approve(IERC20(coin), poolAddress, amounts[i]);
			}
		}

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		IStableSwapPool(poolAddress).add_liquidity(amounts, minMintAmount);
		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));

		require(lpTokenBalanceAfter.sub(lpTokenBalanceBefore) >= minMintAmount, "LP_AMT_TOO_LOW");
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amounts List of amounts of underlying coins to withdraw
	/// @param maxBurnAmount Maximum amount of LP token to burn in the withdrawal
	function withdrawImbalance(
		address poolAddress,
		uint256[N_COINS] memory amounts,
		uint256 maxBurnAmount
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, maxBurnAmount);

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(poolAddress);

		IStableSwapPool(poolAddress).remove_liquidity_imbalance(amounts, maxBurnAmount);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

		_compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, amounts);

		require(lpTokenBalanceBefore.sub(lpTokenBalanceAfter) <= maxBurnAmount, "LP_COST_TOO_HIGH");
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amount Quantity of LP tokens to burn in the withdrawal
	/// @param minAmounts Minimum amounts of underlying coins to receive
	function withdraw(
		address poolAddress,
		uint256 amount,
		uint256[N_COINS] memory minAmounts
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, amount);

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(poolAddress);

		IStableSwapPool(poolAddress).remove_liquidity(amount, minAmounts);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

		_compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, minAmounts);

		require(lpTokenBalanceBefore.sub(amount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress token addresses
	/// @param tokenAmount Amount of LP tokens to burn in the withdrawal
	/// @param i Index value of the coin to withdraw
	/// @param minAmount Minimum amount of coin to receive
	function withdrawOneCoin(
		address poolAddress,
		uint256 tokenAmount,
		int128 i,
		uint256 minAmount
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, tokenAmount);
		address coin = IStableSwapPool(poolAddress).coins(uint256(i));

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256 coinBalanceBefore = IERC20(coin).balanceOf(address(this));

		IStableSwapPool(poolAddress).remove_liquidity_one_coin(tokenAmount, i, minAmount);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256 coinBalanceAfter = IERC20(coin).balanceOf(address(this));

		require(coinBalanceBefore < coinBalanceAfter, "BALANCE_MUST_INCREASE");
		require(lpTokenBalanceBefore.sub(tokenAmount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
	}

	function _getLPToken(address poolAddress) internal returns (address) {
		require(poolAddress != address(0), "INVALID_POOL_ADDRESS");

		address registryAddress = addressProvider.get_registry();
		address lpTokenAddress = IRegistry(registryAddress).get_lp_token(poolAddress);

		// If it's not registered in curve registry that should mean it's a factory pool (pool is also the LP Token)
		// https://curve.readthedocs.io/factory-pools.html?highlight=factory%20pools%20differ#lp-tokens
		if (lpTokenAddress == address(0)) {
			lpTokenAddress = poolAddress;
		}

		require(addressRegistry.checkAddress(lpTokenAddress, 0), "INVALID_LP_TOKEN");

		return lpTokenAddress;
	}

	function _getCoinsBalances(address poolAddress) internal returns (uint256[N_COINS] memory coinsBalances) {
		for (uint256 i = 0; i < N_COINS; ++i) {
			address coin = IStableSwapPool(poolAddress).coins(i);
			uint256 balance = IERC20(coin).balanceOf(address(this));
			coinsBalances[i] = balance;
		}
		return coinsBalances;
	}

	function _compareCoinsBalances(
		uint256[N_COINS] memory balancesBefore,
		uint256[N_COINS] memory balancesAfter,
		uint256[N_COINS] memory amounts
	) internal pure {
		for (uint256 i = 0; i < N_COINS; ++i) {
			uint256 minAmount = amounts[i];
			require(balancesAfter[i].sub(balancesBefore[i]) >= minAmount, "INVALID_BALANCE_CHANGE");
		}
	}

	function _getLPTokenAndApprove(address poolAddress, uint256 amount) internal returns (address) {
		address lpTokenAddress = _getLPToken(poolAddress);
		if (lpTokenAddress != poolAddress) {
			_approve(IERC20(lpTokenAddress), poolAddress, amount);
		}
		return lpTokenAddress;
	}

	function _approve(IERC20 token, address spender, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), spender);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(spender, currentAllowance);
		}
		token.safeIncreaseAllowance(spender, amount);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IStableSwapPool {
	/* solhint-disable func-name-mixedcase, var-name-mixedcase */

	function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external;

	function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;

	function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount) external;

	function remove_liquidity_imbalance(uint256[2] memory amounts, uint256 max_burn_amount) external;

	function remove_liquidity_imbalance(uint256[3] memory amounts, uint256 max_burn_amount) external;

	function remove_liquidity_imbalance(uint256[4] memory amounts, uint256 max_burn_amount) external;

	function remove_liquidity(uint256 amount, uint256[2] memory min_amounts) external;

	function remove_liquidity(uint256 amount, uint256[3] memory min_amounts) external;

	function remove_liquidity(uint256 amount, uint256[4] memory min_amounts) external;

	function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external;

	function coins(uint256 i) external returns (address);

	function balanceOf(address account) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../interfaces/curve/IStableSwapPool.sol";
import "../../interfaces/curve/IRegistry.sol";
import "../../interfaces/curve/IAddressProvider.sol";
import "../BaseController.sol";

contract CurveControllerPool4 is BaseController {
	using SafeERC20 for IERC20;
	using Address for address;
	using SafeMath for uint256;

	IAddressProvider public immutable addressProvider;

	uint256 public constant N_COINS = 4;

	constructor(
		address _manager,
		address _accessControl,
		address _addressRegistry,
		IAddressProvider _curveAddressProvider
	) public BaseController(_manager, _accessControl, _addressRegistry) {
		require(address(_curveAddressProvider) != address(0), "INVALID_CURVE_ADDRESS_PROVIDER");
		addressProvider = _curveAddressProvider;
	}

	/// @notice Deploy liquidity to Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amounts List of amounts of coins to deposit
	/// @param poolAddress Minimum amount of LP tokens to mint from the deposit
	function deploy(
		address poolAddress,
		uint256[N_COINS] calldata amounts,
		uint256 minMintAmount
	) external onlyManager onlyAddLiquidity {
		address lpTokenAddress = _getLPToken(poolAddress);
		uint256 amountsLength = amounts.length;

		for (uint256 i = 0; i < amountsLength; ++i) {
			if (amounts[i] > 0) {
				address coin = IStableSwapPool(poolAddress).coins(i);

				require(addressRegistry.checkAddress(coin, 0), "INVALID_COIN");

				uint256 balance = IERC20(coin).balanceOf(address(this));

				require(balance >= amounts[i], "INSUFFICIENT_BALANCE");

				_approve(IERC20(coin), poolAddress, amounts[i]);
			}
		}

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		IStableSwapPool(poolAddress).add_liquidity(amounts, minMintAmount);
		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));

		require(lpTokenBalanceAfter.sub(lpTokenBalanceBefore) >= minMintAmount, "LP_AMT_TOO_LOW");
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amounts List of amounts of underlying coins to withdraw
	/// @param maxBurnAmount Maximum amount of LP token to burn in the withdrawal
	function withdrawImbalance(
		address poolAddress,
		uint256[N_COINS] memory amounts,
		uint256 maxBurnAmount
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, maxBurnAmount);

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(poolAddress);

		IStableSwapPool(poolAddress).remove_liquidity_imbalance(amounts, maxBurnAmount);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

		_compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, amounts);

		require(lpTokenBalanceBefore.sub(lpTokenBalanceAfter) <= maxBurnAmount, "LP_COST_TOO_HIGH");
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amount Quantity of LP tokens to burn in the withdrawal
	/// @param minAmounts Minimum amounts of underlying coins to receive
	function withdraw(
		address poolAddress,
		uint256 amount,
		uint256[N_COINS] memory minAmounts
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, amount);

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(poolAddress);

		IStableSwapPool(poolAddress).remove_liquidity(amount, minAmounts);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

		_compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, minAmounts);

		require(lpTokenBalanceBefore.sub(amount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress token addresses
	/// @param tokenAmount Amount of LP tokens to burn in the withdrawal
	/// @param i Index value of the coin to withdraw
	/// @param minAmount Minimum amount of coin to receive
	function withdrawOneCoin(
		address poolAddress,
		uint256 tokenAmount,
		int128 i,
		uint256 minAmount
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, tokenAmount);
		address coin = IStableSwapPool(poolAddress).coins(uint256(i));

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256 coinBalanceBefore = IERC20(coin).balanceOf(address(this));

		IStableSwapPool(poolAddress).remove_liquidity_one_coin(tokenAmount, i, minAmount);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256 coinBalanceAfter = IERC20(coin).balanceOf(address(this));

		require(coinBalanceBefore < coinBalanceAfter, "BALANCE_MUST_INCREASE");
		require(lpTokenBalanceBefore.sub(tokenAmount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
	}

	function _getLPToken(address poolAddress) internal returns (address) {
		require(poolAddress != address(0), "INVALID_POOL_ADDRESS");

		address registryAddress = addressProvider.get_registry();
		address lpTokenAddress = IRegistry(registryAddress).get_lp_token(poolAddress);

		// If it's not registered in curve registry that should mean it's a factory pool (pool is also the LP Token)
		// https://curve.readthedocs.io/factory-pools.html?highlight=factory%20pools%20differ#lp-tokens
		if (lpTokenAddress == address(0)) {
			lpTokenAddress = poolAddress;
		}

		require(addressRegistry.checkAddress(lpTokenAddress, 0), "INVALID_LP_TOKEN");

		return lpTokenAddress;
	}

	function _getCoinsBalances(address poolAddress) internal returns (uint256[N_COINS] memory coinsBalances) {
		for (uint256 i = 0; i < N_COINS; ++i) {
			address coin = IStableSwapPool(poolAddress).coins(i);
			uint256 balance = IERC20(coin).balanceOf(address(this));
			coinsBalances[i] = balance;
		}
		return coinsBalances;
	}

	function _compareCoinsBalances(
		uint256[N_COINS] memory balancesBefore,
		uint256[N_COINS] memory balancesAfter,
		uint256[N_COINS] memory amounts
	) internal pure {
		for (uint256 i = 0; i < N_COINS; ++i) {
			uint256 minAmount = amounts[i];
			require(balancesAfter[i].sub(balancesBefore[i]) >= minAmount, "INVALID_BALANCE_CHANGE");
		}
	}

	function _getLPTokenAndApprove(address poolAddress, uint256 amount) internal returns (address) {
		address lpTokenAddress = _getLPToken(poolAddress);
		if (lpTokenAddress != poolAddress) {
			_approve(IERC20(lpTokenAddress), poolAddress, amount);
		}
		return lpTokenAddress;
	}

	function _approve(IERC20 token, address spender, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), spender);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(spender, currentAllowance);
		}
		token.safeIncreaseAllowance(spender, amount);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../interfaces/curve/IStableSwapPool.sol";
import "../../interfaces/curve/IRegistry.sol";
import "../../interfaces/curve/IAddressProvider.sol";
import "../BaseController.sol";

contract CurveControllerPool3 is BaseController {
	using SafeERC20 for IERC20;
	using Address for address;
	using SafeMath for uint256;

	IAddressProvider public immutable addressProvider;

	uint256 public constant N_COINS = 3;

	constructor(
		address _manager,
		address _accessControl,
		address _addressRegistry,
		IAddressProvider _curveAddressProvider
	) public BaseController(_manager, _accessControl, _addressRegistry) {
		require(address(_curveAddressProvider) != address(0), "INVALID_CURVE_ADDRESS_PROVIDER");
		addressProvider = _curveAddressProvider;
	}

	/// @notice Deploy liquidity to Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amounts List of amounts of coins to deposit
	/// @param poolAddress Minimum amount of LP tokens to mint from the deposit
	function deploy(
		address poolAddress,
		uint256[N_COINS] calldata amounts,
		uint256 minMintAmount
	) external onlyManager onlyAddLiquidity {
		address lpTokenAddress = _getLPToken(poolAddress);
		uint256 amountsLength = amounts.length;

		for (uint256 i = 0; i < amountsLength; ++i) {
			if (amounts[i] > 0) {
				address coin = IStableSwapPool(poolAddress).coins(i);

				require(addressRegistry.checkAddress(coin, 0), "INVALID_COIN");

				uint256 balance = IERC20(coin).balanceOf(address(this));

				require(balance >= amounts[i], "INSUFFICIENT_BALANCE");

				_approve(IERC20(coin), poolAddress, amounts[i]);
			}
		}

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		IStableSwapPool(poolAddress).add_liquidity(amounts, minMintAmount);
		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));

		require(lpTokenBalanceAfter.sub(lpTokenBalanceBefore) >= minMintAmount, "LP_AMT_TOO_LOW");
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amounts List of amounts of underlying coins to withdraw
	/// @param maxBurnAmount Maximum amount of LP token to burn in the withdrawal
	function withdrawImbalance(
		address poolAddress,
		uint256[N_COINS] memory amounts,
		uint256 maxBurnAmount
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, maxBurnAmount);

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(poolAddress);

		IStableSwapPool(poolAddress).remove_liquidity_imbalance(amounts, maxBurnAmount);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

		_compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, amounts);

		require(lpTokenBalanceBefore.sub(lpTokenBalanceAfter) <= maxBurnAmount, "LP_COST_TOO_HIGH");
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amount Quantity of LP tokens to burn in the withdrawal
	/// @param minAmounts Minimum amounts of underlying coins to receive
	function withdraw(
		address poolAddress,
		uint256 amount,
		uint256[N_COINS] memory minAmounts
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, amount);

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(poolAddress);

		IStableSwapPool(poolAddress).remove_liquidity(amount, minAmounts);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

		_compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, minAmounts);

		require(lpTokenBalanceBefore.sub(amount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress token addresses
	/// @param tokenAmount Amount of LP tokens to burn in the withdrawal
	/// @param i Index value of the coin to withdraw
	/// @param minAmount Minimum amount of coin to receive
	function withdrawOneCoin(
		address poolAddress,
		uint256 tokenAmount,
		int128 i,
		uint256 minAmount
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, tokenAmount);
		address coin = IStableSwapPool(poolAddress).coins(uint256(i));

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256 coinBalanceBefore = IERC20(coin).balanceOf(address(this));

		IStableSwapPool(poolAddress).remove_liquidity_one_coin(tokenAmount, i, minAmount);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256 coinBalanceAfter = IERC20(coin).balanceOf(address(this));

		require(coinBalanceBefore < coinBalanceAfter, "BALANCE_MUST_INCREASE");
		require(lpTokenBalanceBefore.sub(tokenAmount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
	}

	function _getLPToken(address poolAddress) internal returns (address) {
		require(poolAddress != address(0), "INVALID_POOL_ADDRESS");

		address registryAddress = addressProvider.get_registry();
		address lpTokenAddress = IRegistry(registryAddress).get_lp_token(poolAddress);

		// If it's not registered in curve registry that should mean it's a factory pool (pool is also the LP Token)
		// https://curve.readthedocs.io/factory-pools.html?highlight=factory%20pools%20differ#lp-tokens
		if (lpTokenAddress == address(0)) {
			lpTokenAddress = poolAddress;
		}

		require(addressRegistry.checkAddress(lpTokenAddress, 0), "INVALID_LP_TOKEN");

		return lpTokenAddress;
	}

	function _getCoinsBalances(address poolAddress) internal returns (uint256[N_COINS] memory coinsBalances) {
		for (uint256 i = 0; i < N_COINS; ++i) {
			address coin = IStableSwapPool(poolAddress).coins(i);
			uint256 balance = IERC20(coin).balanceOf(address(this));
			coinsBalances[i] = balance;
		}
		return coinsBalances;
	}

	function _compareCoinsBalances(
		uint256[N_COINS] memory balancesBefore,
		uint256[N_COINS] memory balancesAfter,
		uint256[N_COINS] memory amounts
	) internal pure {
		for (uint256 i = 0; i < N_COINS; ++i) {
			uint256 minAmount = amounts[i];
			require(balancesAfter[i].sub(balancesBefore[i]) >= minAmount, "INVALID_BALANCE_CHANGE");
		}
	}

	function _getLPTokenAndApprove(address poolAddress, uint256 amount) internal returns (address) {
		address lpTokenAddress = _getLPToken(poolAddress);
		if (lpTokenAddress != poolAddress) {
			_approve(IERC20(lpTokenAddress), poolAddress, amount);
		}
		return lpTokenAddress;
	}

	function _approve(IERC20 token, address spender, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), spender);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(spender, currentAllowance);
		}
		token.safeIncreaseAllowance(spender, amount);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../interfaces/curve/IStableSwapPool.sol";
import "../../interfaces/curve/IRegistry.sol";
import "../../interfaces/curve/IAddressProvider.sol";
import "../BaseController.sol";

contract CurveControllerPool2 is BaseController {
	using SafeERC20 for IERC20;
	using Address for address;
	using SafeMath for uint256;

	IAddressProvider public immutable addressProvider;

	uint256 public constant N_COINS = 2;

	constructor(
		address _manager,
		address _accessControl,
		address _addressRegistry,
		IAddressProvider _curveAddressProvider
	) public BaseController(_manager, _accessControl, _addressRegistry) {
		require(address(_curveAddressProvider) != address(0), "INVALID_CURVE_ADDRESS_PROVIDER");
		addressProvider = _curveAddressProvider;
	}

	/// @notice Deploy liquidity to Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amounts List of amounts of coins to deposit
	/// @param poolAddress Minimum amount of LP tokens to mint from the deposit
	function deploy(
		address poolAddress,
		uint256[N_COINS] calldata amounts,
		uint256 minMintAmount
	) external onlyManager onlyAddLiquidity {
		address lpTokenAddress = _getLPToken(poolAddress);
		uint256 amountsLength = amounts.length;

		for (uint256 i = 0; i < amountsLength; ++i) {
			if (amounts[i] > 0) {
				address coin = IStableSwapPool(poolAddress).coins(i);

				require(addressRegistry.checkAddress(coin, 0), "INVALID_COIN");

				uint256 balance = IERC20(coin).balanceOf(address(this));

				require(balance >= amounts[i], "INSUFFICIENT_BALANCE");

				_approve(IERC20(coin), poolAddress, amounts[i]);
			}
		}

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		IStableSwapPool(poolAddress).add_liquidity(amounts, minMintAmount);
		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));

		require(lpTokenBalanceAfter.sub(lpTokenBalanceBefore) >= minMintAmount, "LP_AMT_TOO_LOW");
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amounts List of amounts of underlying coins to withdraw
	/// @param maxBurnAmount Maximum amount of LP token to burn in the withdrawal
	function withdrawImbalance(
		address poolAddress,
		uint256[N_COINS] memory amounts,
		uint256 maxBurnAmount
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, maxBurnAmount);

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(poolAddress);

		IStableSwapPool(poolAddress).remove_liquidity_imbalance(amounts, maxBurnAmount);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

		_compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, amounts);

		require(lpTokenBalanceBefore.sub(lpTokenBalanceAfter) <= maxBurnAmount, "LP_COST_TOO_HIGH");
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amount Quantity of LP tokens to burn in the withdrawal
	/// @param minAmounts Minimum amounts of underlying coins to receive
	function withdraw(
		address poolAddress,
		uint256 amount,
		uint256[N_COINS] memory minAmounts
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, amount);

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(poolAddress);

		IStableSwapPool(poolAddress).remove_liquidity(amount, minAmounts);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

		_compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, minAmounts);

		require(lpTokenBalanceBefore.sub(amount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress token addresses
	/// @param tokenAmount Amount of LP tokens to burn in the withdrawal
	/// @param i Index value of the coin to withdraw
	/// @param minAmount Minimum amount of coin to receive
	function withdrawOneCoin(
		address poolAddress,
		uint256 tokenAmount,
		int128 i,
		uint256 minAmount
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, tokenAmount);
		address coin = IStableSwapPool(poolAddress).coins(uint256(i));

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256 coinBalanceBefore = IERC20(coin).balanceOf(address(this));

		IStableSwapPool(poolAddress).remove_liquidity_one_coin(tokenAmount, i, minAmount);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256 coinBalanceAfter = IERC20(coin).balanceOf(address(this));

		require(coinBalanceBefore < coinBalanceAfter, "BALANCE_MUST_INCREASE");
		require(lpTokenBalanceBefore.sub(tokenAmount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
	}

	function _getLPToken(address poolAddress) internal returns (address) {
		require(poolAddress != address(0), "INVALID_POOL_ADDRESS");

		address registryAddress = addressProvider.get_registry();
		address lpTokenAddress = IRegistry(registryAddress).get_lp_token(poolAddress);

		// If it's not registered in curve registry that should mean it's a factory pool (pool is also the LP Token)
		// https://curve.readthedocs.io/factory-pools.html?highlight=factory%20pools%20differ#lp-tokens
		if (lpTokenAddress == address(0)) {
			lpTokenAddress = poolAddress;
		}

		require(addressRegistry.checkAddress(lpTokenAddress, 0), "INVALID_LP_TOKEN");

		return lpTokenAddress;
	}

	function _getCoinsBalances(address poolAddress) internal returns (uint256[N_COINS] memory coinsBalances) {
		for (uint256 i = 0; i < N_COINS; ++i) {
			address coin = IStableSwapPool(poolAddress).coins(i);
			uint256 balance = IERC20(coin).balanceOf(address(this));
			coinsBalances[i] = balance;
		}
		return coinsBalances;
	}

	function _compareCoinsBalances(
		uint256[N_COINS] memory balancesBefore,
		uint256[N_COINS] memory balancesAfter,
		uint256[N_COINS] memory amounts
	) internal pure {
		for (uint256 i = 0; i < N_COINS; ++i) {
			uint256 minAmount = amounts[i];
			require(balancesAfter[i].sub(balancesBefore[i]) >= minAmount, "INVALID_BALANCE_CHANGE");
		}
	}

	function _getLPTokenAndApprove(address poolAddress, uint256 amount) internal returns (address) {
		address lpTokenAddress = _getLPToken(poolAddress);
		if (lpTokenAddress != poolAddress) {
			_approve(IERC20(lpTokenAddress), poolAddress, amount);
		}
		return lpTokenAddress;
	}

	function _approve(IERC20 token, address spender, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), spender);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(spender, currentAllowance);
		}
		token.safeIncreaseAllowance(spender, amount);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../interfaces/curve/IDepositZap.sol";
import "../../interfaces/curve/IStableSwapPool.sol";
import "../../interfaces/curve/IRegistry.sol";
import "../../interfaces/curve/IAddressProvider.sol";
import "../BaseController.sol";

contract CurveControllerMetaTemplate is BaseController {
	using SafeERC20 for IERC20;
	using Address for address;
	using SafeMath for uint256;

	// Underlying pool of meta pool
	address public immutable basePoolAddress;

	/*
	 * Deposit zap used to operate both meta pool and underlying tokens
	 * https://curve.readthedocs.io/exchange-deposits.html
	 */
	address public immutable zapAddress;

	uint256 public constant N_COINS = 4;

	constructor(
		address _manager,
		address _accessControl,
		address _addressRegistry,
		address _basePoolAddress,
		address _zapAddress
	) public BaseController(_manager, _accessControl, _addressRegistry) {
		require(address(_basePoolAddress) != address(0), "INVALID_CURVE_BASE_POOL_ADDRESS");
		require(address(_zapAddress) != address(0), "INVALID_CURVE_DEPOSIT_ZAP_ADDRESS");
		basePoolAddress = _basePoolAddress;
		zapAddress = _zapAddress;
	}

	/// @notice Deploy liquidity to Curve pool using Deposit Zap
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve metaPoolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param metaPoolAddress Meta pool address
	/// @param amounts List of amounts of coins to deposit
	/// @param minMintAmount Minimum amount of LP tokens to mint from the deposit
	function deploy(
		address metaPoolAddress,
		uint256[N_COINS] calldata amounts,
		uint256 minMintAmount
	) external onlyManager onlyAddLiquidity {
		address lpTokenAddress = metaPoolAddress;

		for (uint256 i = 0; i < N_COINS; ++i) {
			if (amounts[i] > 0) {
				address poolAddress;
				uint256 coinIndex;

				if (i == 0) {
					// The first coin is a coin from meta pool
					poolAddress = metaPoolAddress;
					coinIndex = 0;
				} else {
					// Coins from underlying base pool
					poolAddress = basePoolAddress;
					coinIndex = i - 1;
				}
				address coin = IStableSwapPool(poolAddress).coins(coinIndex);

				_validateCoin(coin, amounts[i]);

				_approve(IERC20(coin), amounts[i]);
			}
		}
		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		IDepositZap(zapAddress).add_liquidity(metaPoolAddress, amounts, minMintAmount);
		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));

		require(lpTokenBalanceAfter.sub(lpTokenBalanceBefore) >= minMintAmount, "LP_AMT_TOO_LOW");
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve metaPoolAddress. If it's not the case it will fail in the remove_liquidity_imbalance part.
	/// @param metaPoolAddress Meta pool address
	/// @param amounts List of amounts of underlying coins to withdraw
	/// @param maxBurnAmount Maximum amount of LP token to burn in the withdrawal
	function withdrawImbalance(
		address metaPoolAddress,
		uint256[N_COINS] memory amounts,
		uint256 maxBurnAmount
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(metaPoolAddress, maxBurnAmount);

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(metaPoolAddress);

		IDepositZap(zapAddress).remove_liquidity_imbalance(metaPoolAddress, amounts, maxBurnAmount);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(metaPoolAddress);

		_compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, amounts);

		require(lpTokenBalanceBefore.sub(lpTokenBalanceAfter) <= maxBurnAmount, "LP_COST_TOO_HIGH");
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve metaPoolAddress. If it's not the case it will fail in the remove_liquidity part.
	/// @param metaPoolAddress Meta pool address
	/// @param amount Quantity of LP tokens to burn in the withdrawal
	/// @param minAmounts Minimum amounts of underlying coins to receive
	function withdraw(
		address metaPoolAddress,
		uint256 amount,
		uint256[N_COINS] memory minAmounts
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(metaPoolAddress, amount);

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(metaPoolAddress);

		IDepositZap(zapAddress).remove_liquidity(metaPoolAddress, amount, minAmounts);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(metaPoolAddress);

		_compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, minAmounts);

		require(lpTokenBalanceBefore.sub(amount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
	}

	function _validateCoin(address coin, uint256 amount) internal {
		require(addressRegistry.checkAddress(coin, 0), "INVALID_COIN");

		uint256 balance = IERC20(coin).balanceOf(address(this));

		require(balance >= amount, "INSUFFICIENT_BALANCE");
	}

	function _getCoinsBalances(address metaPoolAddress) internal returns (uint256[N_COINS] memory coinsBalances) {
		// Coin from meta pool
		address firstCoin = IStableSwapPool(metaPoolAddress).coins(0);
		coinsBalances[0] = IERC20(firstCoin).balanceOf(address(this));

		// Coins from underlying pool
		for (uint256 i = 1; i < N_COINS; ++i) {
			address coin = IStableSwapPool(basePoolAddress).coins(i - 1);
			uint256 balance = IERC20(coin).balanceOf(address(this));
			coinsBalances[i] = balance;
		}
		return coinsBalances;
	}

	function _compareCoinsBalances(
		uint256[N_COINS] memory balancesBefore,
		uint256[N_COINS] memory balancesAfter,
		uint256[N_COINS] memory amounts
	) internal pure {
		for (uint256 i = 0; i < N_COINS; ++i) {
			uint256 minAmount = amounts[i];
			require(balancesAfter[i].sub(balancesBefore[i]) >= minAmount, "INVALID_BALANCE_CHANGE");
		}
	}

	function _getLPTokenAndApprove(address metaPoolAddress, uint256 amount) internal returns (address) {
		// Meta pool is an ERC20 LP token of that pool at the same time
		address lpTokenAddress = metaPoolAddress;

		_approve(IERC20(lpTokenAddress), amount);

		return lpTokenAddress;
	}

	function _approve(IERC20 token, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), zapAddress);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(zapAddress, currentAllowance);
		}
		token.safeIncreaseAllowance(zapAddress, amount);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IDepositZap {
	/* solhint-disable func-name-mixedcase, var-name-mixedcase */

	function add_liquidity(address metaPoolAddress, uint256[3] memory amounts, uint256 min_mint_amount) external;

	function add_liquidity(address metaPoolAddress, uint256[4] memory amounts, uint256 min_mint_amount) external;

	function remove_liquidity_imbalance(
		address metaPoolAddress,
		uint256[3] memory amounts,
		uint256 max_burn_amount
	) external;

	function remove_liquidity_imbalance(
		address metaPoolAddress,
		uint256[4] memory amounts,
		uint256 max_burn_amount
	) external;

	function remove_liquidity(address metaPoolAddress, uint256 amount, uint256[3] memory min_amounts) external;

	function remove_liquidity(address metaPoolAddress, uint256 amount, uint256[4] memory min_amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../interfaces/curve/IDepositZap.sol";
import "../../interfaces/curve/IStableSwapPool.sol";
import "../../interfaces/curve/IRegistry.sol";
import "../../interfaces/curve/IAddressProvider.sol";
import "../BaseController.sol";

contract CurveControllerMetaPool4 is BaseController {
	using SafeERC20 for IERC20;
	using Address for address;
	using SafeMath for uint256;

	// Underlying pool of meta pool
	address public immutable basePoolAddress;

	/*
	 * Deposit zap used to operate both meta pool and underlying tokens
	 * https://curve.readthedocs.io/exchange-deposits.html
	 */
	address public immutable zapAddress;

	uint256 public constant N_COINS = 4;

	constructor(
		address _manager,
		address _accessControl,
		address _addressRegistry,
		address _basePoolAddress,
		address _zapAddress
	) public BaseController(_manager, _accessControl, _addressRegistry) {
		require(address(_basePoolAddress) != address(0), "INVALID_CURVE_BASE_POOL_ADDRESS");
		require(address(_zapAddress) != address(0), "INVALID_CURVE_DEPOSIT_ZAP_ADDRESS");
		basePoolAddress = _basePoolAddress;
		zapAddress = _zapAddress;
	}

	/// @notice Deploy liquidity to Curve pool using Deposit Zap
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve metaPoolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param metaPoolAddress Meta pool address
	/// @param amounts List of amounts of coins to deposit
	/// @param minMintAmount Minimum amount of LP tokens to mint from the deposit
	function deploy(
		address metaPoolAddress,
		uint256[N_COINS] calldata amounts,
		uint256 minMintAmount
	) external onlyManager onlyAddLiquidity {
		address lpTokenAddress = metaPoolAddress;

		for (uint256 i = 0; i < N_COINS; ++i) {
			if (amounts[i] > 0) {
				address poolAddress;
				uint256 coinIndex;

				if (i == 0) {
					// The first coin is a coin from meta pool
					poolAddress = metaPoolAddress;
					coinIndex = 0;
				} else {
					// Coins from underlying base pool
					poolAddress = basePoolAddress;
					coinIndex = i - 1;
				}
				address coin = IStableSwapPool(poolAddress).coins(coinIndex);

				_validateCoin(coin, amounts[i]);

				_approve(IERC20(coin), amounts[i]);
			}
		}
		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		IDepositZap(zapAddress).add_liquidity(metaPoolAddress, amounts, minMintAmount);
		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));

		require(lpTokenBalanceAfter.sub(lpTokenBalanceBefore) >= minMintAmount, "LP_AMT_TOO_LOW");
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve metaPoolAddress. If it's not the case it will fail in the remove_liquidity_imbalance part.
	/// @param metaPoolAddress Meta pool address
	/// @param amounts List of amounts of underlying coins to withdraw
	/// @param maxBurnAmount Maximum amount of LP token to burn in the withdrawal
	function withdrawImbalance(
		address metaPoolAddress,
		uint256[N_COINS] memory amounts,
		uint256 maxBurnAmount
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(metaPoolAddress, maxBurnAmount);

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(metaPoolAddress);

		IDepositZap(zapAddress).remove_liquidity_imbalance(metaPoolAddress, amounts, maxBurnAmount);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(metaPoolAddress);

		_compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, amounts);

		require(lpTokenBalanceBefore.sub(lpTokenBalanceAfter) <= maxBurnAmount, "LP_COST_TOO_HIGH");
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve metaPoolAddress. If it's not the case it will fail in the remove_liquidity part.
	/// @param metaPoolAddress Meta pool address
	/// @param amount Quantity of LP tokens to burn in the withdrawal
	/// @param minAmounts Minimum amounts of underlying coins to receive
	function withdraw(
		address metaPoolAddress,
		uint256 amount,
		uint256[N_COINS] memory minAmounts
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(metaPoolAddress, amount);

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(metaPoolAddress);

		IDepositZap(zapAddress).remove_liquidity(metaPoolAddress, amount, minAmounts);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(metaPoolAddress);

		_compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, minAmounts);

		require(lpTokenBalanceBefore.sub(amount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
	}

	function _validateCoin(address coin, uint256 amount) internal {
		require(addressRegistry.checkAddress(coin, 0), "INVALID_COIN");

		uint256 balance = IERC20(coin).balanceOf(address(this));

		require(balance >= amount, "INSUFFICIENT_BALANCE");
	}

	function _getCoinsBalances(address metaPoolAddress) internal returns (uint256[N_COINS] memory coinsBalances) {
		// Coin from meta pool
		address firstCoin = IStableSwapPool(metaPoolAddress).coins(0);
		coinsBalances[0] = IERC20(firstCoin).balanceOf(address(this));

		// Coins from underlying pool
		for (uint256 i = 1; i < N_COINS; ++i) {
			address coin = IStableSwapPool(basePoolAddress).coins(i - 1);
			uint256 balance = IERC20(coin).balanceOf(address(this));
			coinsBalances[i] = balance;
		}
		return coinsBalances;
	}

	function _compareCoinsBalances(
		uint256[N_COINS] memory balancesBefore,
		uint256[N_COINS] memory balancesAfter,
		uint256[N_COINS] memory amounts
	) internal pure {
		for (uint256 i = 0; i < N_COINS; ++i) {
			uint256 minAmount = amounts[i];
			require(balancesAfter[i].sub(balancesBefore[i]) >= minAmount, "INVALID_BALANCE_CHANGE");
		}
	}

	function _getLPTokenAndApprove(address metaPoolAddress, uint256 amount) internal returns (address) {
		// Meta pool is an ERC20 LP token of that pool at the same time
		address lpTokenAddress = metaPoolAddress;

		_approve(IERC20(lpTokenAddress), amount);

		return lpTokenAddress;
	}

	function _approve(IERC20 token, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), zapAddress);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(zapAddress, currentAllowance);
		}
		token.safeIncreaseAllowance(zapAddress, amount);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../interfaces/curve/IDepositZap.sol";
import "../../interfaces/curve/IStableSwapPool.sol";
import "../../interfaces/curve/IRegistry.sol";
import "../../interfaces/curve/IAddressProvider.sol";
import "../BaseController.sol";

contract CurveControllerMetaPool3 is BaseController {
	using SafeERC20 for IERC20;
	using Address for address;
	using SafeMath for uint256;

	// Underlying pool of meta pool
	address public immutable basePoolAddress;

	/*
	 * Deposit zap used to operate both meta pool and underlying tokens
	 * https://curve.readthedocs.io/exchange-deposits.html
	 */
	address public immutable zapAddress;

	uint256 public constant N_COINS = 3;

	constructor(
		address _manager,
		address _accessControl,
		address _addressRegistry,
		address _basePoolAddress,
		address _zapAddress
	) public BaseController(_manager, _accessControl, _addressRegistry) {
		require(address(_basePoolAddress) != address(0), "INVALID_CURVE_BASE_POOL_ADDRESS");
		require(address(_zapAddress) != address(0), "INVALID_CURVE_DEPOSIT_ZAP_ADDRESS");
		basePoolAddress = _basePoolAddress;
		zapAddress = _zapAddress;
	}

	/// @notice Deploy liquidity to Curve pool using Deposit Zap
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve metaPoolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param metaPoolAddress Meta pool address
	/// @param amounts List of amounts of coins to deposit
	/// @param minMintAmount Minimum amount of LP tokens to mint from the deposit
	function deploy(
		address metaPoolAddress,
		uint256[N_COINS] calldata amounts,
		uint256 minMintAmount
	) external onlyManager onlyAddLiquidity {
		address lpTokenAddress = metaPoolAddress;

		for (uint256 i = 0; i < N_COINS; ++i) {
			if (amounts[i] > 0) {
				address poolAddress;
				uint256 coinIndex;

				if (i == 0) {
					// The first coin is a coin from meta pool
					poolAddress = metaPoolAddress;
					coinIndex = 0;
				} else {
					// Coins from underlying base pool
					poolAddress = basePoolAddress;
					coinIndex = i - 1;
				}
				address coin = IStableSwapPool(poolAddress).coins(coinIndex);

				_validateCoin(coin, amounts[i]);

				_approve(IERC20(coin), amounts[i]);
			}
		}
		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		IDepositZap(zapAddress).add_liquidity(metaPoolAddress, amounts, minMintAmount);
		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));

		require(lpTokenBalanceAfter.sub(lpTokenBalanceBefore) >= minMintAmount, "LP_AMT_TOO_LOW");
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve metaPoolAddress. If it's not the case it will fail in the remove_liquidity_imbalance part.
	/// @param metaPoolAddress Meta pool address
	/// @param amounts List of amounts of underlying coins to withdraw
	/// @param maxBurnAmount Maximum amount of LP token to burn in the withdrawal
	function withdrawImbalance(
		address metaPoolAddress,
		uint256[N_COINS] memory amounts,
		uint256 maxBurnAmount
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(metaPoolAddress, maxBurnAmount);

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(metaPoolAddress);

		IDepositZap(zapAddress).remove_liquidity_imbalance(metaPoolAddress, amounts, maxBurnAmount);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(metaPoolAddress);

		_compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, amounts);

		require(lpTokenBalanceBefore.sub(lpTokenBalanceAfter) <= maxBurnAmount, "LP_COST_TOO_HIGH");
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve metaPoolAddress. If it's not the case it will fail in the remove_liquidity part.
	/// @param metaPoolAddress Meta pool address
	/// @param amount Quantity of LP tokens to burn in the withdrawal
	/// @param minAmounts Minimum amounts of underlying coins to receive
	function withdraw(
		address metaPoolAddress,
		uint256 amount,
		uint256[N_COINS] memory minAmounts
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(metaPoolAddress, amount);

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(metaPoolAddress);

		IDepositZap(zapAddress).remove_liquidity(metaPoolAddress, amount, minAmounts);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(metaPoolAddress);

		_compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, minAmounts);

		require(lpTokenBalanceBefore.sub(amount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
	}

	function _validateCoin(address coin, uint256 amount) internal {
		require(addressRegistry.checkAddress(coin, 0), "INVALID_COIN");

		uint256 balance = IERC20(coin).balanceOf(address(this));

		require(balance >= amount, "INSUFFICIENT_BALANCE");
	}

	function _getCoinsBalances(address metaPoolAddress) internal returns (uint256[N_COINS] memory coinsBalances) {
		// Coin from meta pool
		address firstCoin = IStableSwapPool(metaPoolAddress).coins(0);
		coinsBalances[0] = IERC20(firstCoin).balanceOf(address(this));

		// Coins from underlying pool
		for (uint256 i = 1; i < N_COINS; ++i) {
			address coin = IStableSwapPool(basePoolAddress).coins(i - 1);
			uint256 balance = IERC20(coin).balanceOf(address(this));
			coinsBalances[i] = balance;
		}
		return coinsBalances;
	}

	function _compareCoinsBalances(
		uint256[N_COINS] memory balancesBefore,
		uint256[N_COINS] memory balancesAfter,
		uint256[N_COINS] memory amounts
	) internal pure {
		for (uint256 i = 0; i < N_COINS; ++i) {
			uint256 minAmount = amounts[i];
			require(balancesAfter[i].sub(balancesBefore[i]) >= minAmount, "INVALID_BALANCE_CHANGE");
		}
	}

	function _getLPTokenAndApprove(address metaPoolAddress, uint256 amount) internal returns (address) {
		// Meta pool is an ERC20 LP token of that pool at the same time
		address lpTokenAddress = metaPoolAddress;

		_approve(IERC20(lpTokenAddress), amount);

		return lpTokenAddress;
	}

	function _approve(IERC20 token, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), zapAddress);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(zapAddress, currentAllowance);
		}
		token.safeIncreaseAllowance(zapAddress, amount);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../interfaces/curve/IStableSwapPoolETH.sol";
import "../../interfaces/curve/IRegistry.sol";
import "../../interfaces/curve/IAddressProvider.sol";
import "../BaseController.sol";

contract CurveControllerETH is BaseController {
	using SafeERC20 for IERC20;
	using Address for address;
	using SafeMath for uint256;

	IAddressProvider public immutable addressProvider;

	uint256 public constant N_COINS = 2;
	address public constant ETH_REGISTRY_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

	constructor(
		address _manager,
		address _accessControl,
		address _addressRegistry,
		IAddressProvider _curveAddressProvider
	) public BaseController(_manager, _accessControl, _addressRegistry) {
		require(address(_curveAddressProvider) != address(0), "INVALID_CURVE_ADDRESS_PROVIDER");
		addressProvider = _curveAddressProvider;
	}

	/// @dev Necessary to withdraw ETH
	// solhint-disable-next-line no-empty-blocks
	receive() external payable {}

	/// @notice Deploy liquidity to Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amounts List of amounts of coins to deposit
	/// @param minMintAmount Minimum amount of LP tokens to mint from the deposit
	function deploy(
		address poolAddress,
		uint256[N_COINS] calldata amounts,
		uint256 minMintAmount
	) external payable onlyManager onlyAddLiquidity {
		address lpTokenAddress = _getLPToken(poolAddress);
		uint256 amountsLength = amounts.length;

		for (uint256 i = 0; i < amountsLength; ++i) {
			if (amounts[i] > 0) {
				address coin = IStableSwapPoolETH(poolAddress).coins(i);

				require(addressRegistry.checkAddress(coin, 0), "INVALID_COIN");

				uint256 balance = _getBalance(coin);

				require(balance >= amounts[i], "INSUFFICIENT_BALANCE");

				if (coin != ETH_REGISTRY_ADDRESS) {
					_approve(IERC20(coin), poolAddress, amounts[i]);
				}
			}
		}

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		IStableSwapPoolETH(poolAddress).add_liquidity{ value: amounts[0] }(amounts, minMintAmount);
		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));

		require(lpTokenBalanceAfter.sub(lpTokenBalanceBefore) >= minMintAmount, "LP_AMT_TOO_LOW");
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the remove_liquidity_imbalance part.
	/// @param poolAddress Token addresses
	/// @param amounts List of amounts of underlying coins to withdraw
	/// @param maxBurnAmount Maximum amount of LP token to burn in the withdrawal
	function withdrawImbalance(
		address poolAddress,
		uint256[N_COINS] memory amounts,
		uint256 maxBurnAmount
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, maxBurnAmount);

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(poolAddress);

		IStableSwapPoolETH(poolAddress).remove_liquidity_imbalance(amounts, maxBurnAmount);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

		_compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, amounts);

		require(lpTokenBalanceBefore.sub(lpTokenBalanceAfter) <= maxBurnAmount, "LP_COST_TOO_HIGH");
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the remove_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amount Quantity of LP tokens to burn in the withdrawal
	/// @param minAmounts Minimum amounts of underlying coins to receive
	function withdraw(
		address poolAddress,
		uint256 amount,
		uint256[N_COINS] memory minAmounts
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, amount);

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(poolAddress);

		IStableSwapPoolETH(poolAddress).remove_liquidity(amount, minAmounts);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

		_compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, minAmounts);

		require(lpTokenBalanceBefore.sub(amount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the remove_liquidity_one_coin part.
	/// @param poolAddress token addresses
	/// @param tokenAmount Amount of LP tokens to burn in the withdrawal
	/// @param i Index value of the coin to withdraw
	/// @param minAmount Minimum amount of coin to receive
	function withdrawOneCoin(
		address poolAddress,
		uint256 tokenAmount,
		int128 i,
		uint256 minAmount
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, tokenAmount);
		address coin = IStableSwapPoolETH(poolAddress).coins(uint256(i));

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256 coinBalanceBefore = _getBalance(coin);

		IStableSwapPoolETH(poolAddress).remove_liquidity_one_coin(tokenAmount, i, minAmount);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256 coinBalanceAfter = _getBalance(coin);

		require(coinBalanceBefore < coinBalanceAfter, "BALANCE_MUST_INCREASE");
		require(lpTokenBalanceBefore.sub(tokenAmount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
	}

	function _getLPToken(address poolAddress) internal returns (address) {
		require(poolAddress != address(0), "INVALID_POOL_ADDRESS");

		address registryAddress = addressProvider.get_registry();
		address lpTokenAddress = IRegistry(registryAddress).get_lp_token(poolAddress);

		// If it's not registered in curve registry that should mean it's a factory pool (pool is also the LP Token)
		// https://curve.readthedocs.io/factory-pools.html?highlight=factory%20pools%20differ#lp-tokens
		if (lpTokenAddress == address(0)) {
			lpTokenAddress = poolAddress;
		}

		require(addressRegistry.checkAddress(lpTokenAddress, 0), "INVALID_LP_TOKEN");

		return lpTokenAddress;
	}

	function _getBalance(address coin) internal returns (uint256) {
		uint256 balance;
		if (coin == ETH_REGISTRY_ADDRESS) {
			balance = address(this).balance;
		} else {
			balance = IERC20(coin).balanceOf(address(this));
		}
		return balance;
	}

	function _getCoinsBalances(address poolAddress) internal returns (uint256[N_COINS] memory coinsBalances) {
		for (uint256 i = 0; i < N_COINS; ++i) {
			address coin = IStableSwapPoolETH(poolAddress).coins(i);
			coinsBalances[i] = _getBalance(coin);
		}
		return coinsBalances;
	}

	function _compareCoinsBalances(
		uint256[N_COINS] memory balancesBefore,
		uint256[N_COINS] memory balancesAfter,
		uint256[N_COINS] memory amounts
	) internal pure {
		for (uint256 i = 0; i < N_COINS; ++i) {
			uint256 minAmount = amounts[i];
			require(balancesAfter[i].sub(balancesBefore[i]) >= minAmount, "INVALID_BALANCE_CHANGE");
		}
	}

	function _getLPTokenAndApprove(address poolAddress, uint256 amount) internal returns (address) {
		address lpTokenAddress = _getLPToken(poolAddress);
		if (lpTokenAddress != poolAddress) {
			_approve(IERC20(lpTokenAddress), poolAddress, amount);
		}
		return lpTokenAddress;
	}

	function _approve(IERC20 token, address spender, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), spender);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(spender, currentAllowance);
		}
		token.safeIncreaseAllowance(spender, amount);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IStableSwapPoolETH {
	/* solhint-disable func-name-mixedcase, var-name-mixedcase */

	function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external payable;

	function remove_liquidity_imbalance(uint256[2] memory amounts, uint256 max_burn_amount) external;

	function remove_liquidity(uint256 amount, uint256[2] memory min_amounts) external;

	function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external;

	function coins(uint256 i) external returns (address);

	function balanceOf(address account) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IWallet.sol";
import "./BaseController.sol";

contract ZeroExController is BaseController {
	using SafeERC20 for IERC20;
	using Address for address;
	using Address for address payable;
	using SafeMath for uint256;

	// solhint-disable-next-line
	IWallet public immutable WALLET;

	constructor(
		IWallet wallet,
		address manager,
		address accessControl,
		address addressRegistry
	) public BaseController(manager, accessControl, addressRegistry) {
		require(address(wallet) != address(0), "INVALID_WALLET");
		WALLET = wallet;
	}

	/// @notice Deposits tokens into WALLET
	/// @dev Call to external contract via _approve functions
	/// @param data Bytes containing an array of token addresses and token accounts
	function deploy(bytes calldata data) external onlyManager onlyAddLiquidity {
		(address[] memory tokens, uint256[] memory amounts) = abi.decode(data, (address[], uint256[]));
		uint256 tokensLength = tokens.length;
		for (uint256 i = 0; i < tokensLength; ++i) {
			require(addressRegistry.checkAddress(tokens[i], 0), "INVALID_TOKEN");
			_approve(IERC20(tokens[i]), amounts[i]);
		}
		WALLET.deposit(tokens, amounts);
	}

	/// @notice Withdraws tokens from WALLET
	/// @param data Bytes containing address and uint256 array
	function withdraw(bytes calldata data) external onlyManager onlyRemoveLiquidity {
		(address[] memory tokens, uint256[] memory amounts) = abi.decode(data, (address[], uint256[]));
		for (uint256 i = 0; i < tokens.length; ++i) {
			require(addressRegistry.checkAddress(tokens[i], 0), "INVALID_TOKEN");
		}
		WALLET.withdraw(tokens, amounts);
	}

	function _approve(IERC20 token, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), address(WALLET));
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(address(WALLET), currentAllowance);
		}
		token.safeIncreaseAllowance(address(WALLET), amount);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "./BaseController.sol";
import "../interfaces/IWETH.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract WethController is BaseController {
	using SafeMath for uint256;

	IWETH public immutable weth;

	constructor(
		address manager,
		address accessControl,
		address registry
	) public BaseController(manager, accessControl, registry) {
		weth = IWETH(IAddressRegistry(registry).weth());
	}

	/// @notice Allows Manager contract to wrap ether
	/// @dev Interacts with Weth contract
	/// @param amount Amount of Ether to wrap
	function wrap(uint256 amount) external payable onlyManager onlyMiscOperation {
		require(amount > 0, "INVALID_VALUE");
		// weth contract reverts without message when value > balance of caller
		require(address(this).balance >= amount, "NOT_ENOUGH_ETH");

		uint256 balanceBefore = weth.balanceOf(address(this));
		weth.deposit{ value: amount }();
		uint256 balanceAfter = weth.balanceOf(address(this));

		require(balanceBefore.add(amount) == balanceAfter, "INCORRECT_WETH_AMOUNT");
	}

	/// @notice Allows manager to unwrap weth to eth
	/// @dev Interacts with Weth contract
	/// @param amount Amount of weth to unwrap
	function unwrap(uint256 amount) external onlyManager onlyMiscOperation {
		require(amount > 0, "INVALID_AMOUNT");

		uint256 balanceBeforeWeth = weth.balanceOf(address(this));
		uint256 balanceBeforeEther = address(this).balance;

		// weth contract fails silently on withdrawal overage
		require(balanceBeforeWeth >= amount, "EXCESS_WITHDRAWAL");
		weth.withdraw(amount);
		uint256 balanceAfterEther = address(this).balance;

		require(balanceBeforeEther.add(amount) == balanceAfterEther, "INCORRECT_ETH_AMOUNT");
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 *  @title Interface for the WETH token
 */
interface IWETH is IERC20Upgradeable {
	event Deposit(address, uint256);
	event Withdrawal(address, uint256);

	function deposit() external payable;

	function withdraw(uint256) external;
}

// SPDX-License-identifier: MIT
pragma solidity 0.6.11;

import "../interfaces/IWETH.sol";
import "../interfaces/IAddressRegistry.sol";
import "../interfaces/IPCAEthPool.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import { ERC20PausableUpgradeable as PauseableERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20PausableUpgradeable.sol";
import { ERC20Upgradeable as ERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { OwnableUpgradeable as Ownable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import { ReentrancyGuardUpgradeable as NonReentrant } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { SafeMathUpgradeable as SafeMath } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

contract PCAEthPool is IPCAEthPool, Initializable, Ownable, PauseableERC20, NonReentrant {
	using SafeERC20 for ERC20;
	using SafeMath for uint256;

	ILiquidityEthPool public pool;
	ERC20 public weth;

	//@custom:oz-upgrades-unsafe-allow constructor
	//solhint-disable-next-line no-empty-blocks
	constructor() public initializer {}

	function initialize(
		address _addressRegistry,
		ILiquidityEthPool _pool,
		string memory _name,
		string memory _symbol
	) external initializer {
		require(address(_pool) != address(0), "ZERO_ADDRESS");

		__Context_init_unchained();
		__Ownable_init_unchained();
		__Pausable_init_unchained();
		__ReentrancyGuard_init_unchained();
		__ERC20_init_unchained(_name, _symbol);
		__ERC20Pausable_init_unchained();

		pool = _pool;
		weth = ERC20(pool.underlyer());
		require(address(weth) != address(0), "POOL_DNE");
		require(address(weth) == IAddressRegistry(_addressRegistry).weth(), "INVALID_WETH_ADDRESS");
	}

	///@dev Handles funds in case of direct ether tx
	receive() external payable {
		depositAsset(msg.sender, 0);
	}

	function decimals() public view override returns (uint8) {
		return weth.decimals();
	}

	function depositAsset(address account, uint256 amount) public payable override whenNotPaused {
		uint256 value = msg.value;
		require(account != address(0), "INVALID_ADDRESS");
		require(amount > 0 || value > 0, "INVALID_AMOUNT");
		_mint(account, amount.add(value));
		if (amount > 0) {
			weth.safeTransferFrom(msg.sender, address(pool), amount);
		}
		_etherCheckAndTransfer(value);
	}

	function depositPoolAsset(address account, uint256 amount) external payable override whenNotPaused {
		uint256 value = msg.value;
		require(account != address(0), "INVALID_ADDRESS");
		require(amount > 0 || value > 0, "INVALID_AMOUNT");
		_mint(account, amount.add(value));
		if (amount > 0) {
			pool.controlledBurn(amount, msg.sender);
		}
		_etherCheckAndTransfer(value);
	}

	function updatePool(ILiquidityEthPool newPool) external override onlyOwner {
		address poolAddress = address(newPool);
		require(poolAddress != address(0), "INVALID_ADDRESS");
		require(address(newPool.underlyer()) == address(weth), "UNDERLYER_MISMATCH");
		pool = newPool;

		emit PoolUpdated(poolAddress);
	}

	function pause() external override onlyOwner {
		_pause();
	}

	function unpause() external override onlyOwner {
		_unpause();
	}

	function _etherCheckAndTransfer(uint256 value) private nonReentrant {
		if (value > 0) {
			IWETH(address(weth)).deposit{ value: value }();
			weth.safeTransfer(address(pool), value);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

import "../interfaces/ILiquidityEthPool.sol";

interface IPCAEthPool {
	event PoolUpdated(address newPool);

	///@notice Allows an address to deposit for itself or on behalf of another address
	///@dev Mints pAsset at 1:1 ratio of asset deposited
	///@dev Sends assets deposited to Tokemak pool contract
	///@dev Can be paused
	///@param account Account to be deposited for
	///@param amount Amount of asset to be deposited
	function depositAsset(address account, uint256 amount) external payable;

	///@notice Allows an address to deposit Tokemak tAsset for itself or on behalf of another address
	///@dev Mints pAsset at 1:1 ratio
	///@dev Burns tAssets via controlledBurn() function in Tokemak reactor pool
	///@dev Can be paused
	///@param account Account to be deposited for
	///@param amount Amount of asset to be deposited
	function depositPoolAsset(address account, uint256 amount) external payable;

	///@notice Allows for updating of tokemak reactor pool
	///@dev old pool and new pool must have matching underlying tokens
	///@dev Restriced access - onlyOwner
	///@param newPool New pool to be registered
	function updatePool(ILiquidityEthPool newPool) external;

	///@notice Allows some pool functionalities to be paused
	///@dev Burn, deposit functionalities are currently pausable
	function pause() external;

	///@notice Allows some pool functionalities to be unpaused
	function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20Upgradeable.sol";
import "../../utils/PausableUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20PausableUpgradeable is Initializable, ERC20Upgradeable, PausableUpgradeable {
    function __ERC20Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal initializer {
    }
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "../interfaces/IWETH.sol";
import "../interfaces/IManager.sol";

/// @title Interface for Pool
/// @notice Allows users to deposit Eth to be deployed to market makers.
/// @notice Mints 1:1 tAsset on deposit, represeting an IOU for the undelrying token that is freely transferable.
/// @notice Holders of tAsset earn rewards based on duration their tokens were deployed and the demand for that asset.
/// @notice Holders of tAsset can redeem for underlying asset after issuing requestWithdrawal and waiting for the next cycle.
interface ILiquidityEthPool {
	struct WithdrawalInfo {
		uint256 minCycle;
		uint256 amount;
	}

	event WithdrawalRequested(address requestor, uint256 amount);
	event BurnerRegistered(address burner, bool allowed);
	event Burned(address indexed account, address indexed burner, uint256 amount);
	event RebalancerSet(address rebalancer);

	/// @notice Transfers amount of underlying token from user to this pool and mints fToken to the msg.sender.
	/// @notice Depositor must have previously granted transfer approval to the pool via underlying token contract.
	/// @notice Liquidity deposited is deployed on the next cycle - unless a withdrawal request is submitted, in which case the liquidity will be withheld.
	function deposit(uint256 amount) external payable;

	/// @notice Transfers amount of underlying token from user to this pool and mints fToken to the account.
	/// @notice Depositor must have previously granted transfer approval to the pool via underlying token contract.
	/// @notice Liquidity deposited is deployed on the next cycle - unless a withdrawal request is submitted, in which case the liquidity will be withheld.
	function depositFor(address account, uint256 amount) external payable;

	/// @notice Requests that the manager prepare funds for withdrawal next cycle
	/// @notice Invoking this function when sender already has a currently pending request will overwrite that requested amount and reset the cycle timer
	/// @param amount Amount of fTokens requested to be redeemed
	function requestWithdrawal(uint256 amount) external;

	function approveManager(uint256 amount) external;

	/// @notice Approves rebalancer contract to withdraw pool tokens
	/// @param amount Number of pool tokens to be approved
	function approveRebalancer(uint256 amount) external;

	/// @notice Sender must first invoke requestWithdrawal in a previous cycle
	/// @notice This function will burn the fAsset and transfers underlying asset back to sender
	/// @notice Will execute a partial withdrawal if either available liquidity or previously requested amount is insufficient
	/// @param amount Amount of fTokens to redeem, value can be in excess of available tokens, operation will be reduced to maximum permissible
	function withdraw(uint256 amount, bool asEth) external;

	/// @return Reference to the underlying ERC-20 contract
	function weth() external view returns (IWETH);

	/// @return Reference to the underlying ERC-20 contract
	function underlyer() external view returns (address);

	/// @return Amount of liquidity that should not be deployed for market making (this liquidity will be used for completing requested withdrawals)
	function withheldLiquidity() external view returns (uint256);

	/// @notice Get withdraw requests for an account
	/// @param account User account to check
	/// @return minCycle Cycle - block number - that must be active before withdraw is allowed, amount Token amount requested
	function requestedWithdrawals(address account) external view returns (uint256, uint256);

	/// @notice Pause deposits on the pool. Withdraws still allowed
	function pause() external;

	/// @notice Unpause deposits on the pool.
	function unpause() external;

	///@notice Registers address that is allowed or not allowed to burn
	///@dev Address registered as 'true' will be able to burn tAssets in its possession or that it has an allowance to
	///@param burner Address that will be able / not able to burn tAssets
	///@param allowedBurner Boolean that will register burner address as able to burn or not
	function registerBurner(address burner, bool allowedBurner) external;

	/// @notice Used to set rebalancer address
	/// @dev Purpose is to set rebalancer on proxy state
	/// @param rebalancer address of rebalancer
	function setRebalancer(address rebalancer) external;

	///@notice Function allows address to burn tAssets in its posession
	///@dev Address can burn all tAssets in its posession
	///@dev Overages are prevented by interited functionality from _burn()
	///@param amount Amount of tAsset to be burned
	///@param account Address to be burned from
	function controlledBurn(uint256 amount, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// solhint-disable max-states-count

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/IStaking.sol";
import "../interfaces/IManager.sol";
import "../acctoke/interfaces/IAccToke.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import { SafeMathUpgradeable as SafeMath } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { MathUpgradeable as Math } from "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import { OwnableUpgradeable as Ownable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { EnumerableSetUpgradeable as EnumerableSet } from "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import { PausableUpgradeable as Pausable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable as ReentrancyGuard } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "../interfaces/events/Destinations.sol";
import "../interfaces/events/BalanceUpdateEvent.sol";
import "../interfaces/IDelegateFunction.sol";
import "../interfaces/events/IEventSender.sol";

contract Staking is IStaking, Initializable, Ownable, Pausable, ReentrancyGuard, IEventSender {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	using EnumerableSet for EnumerableSet.UintSet;

	IERC20 public tokeToken;
	IManager public manager;

	address public treasury;

	uint256 public withheldLiquidity; // DEPRECATED
	//userAddress -> withdrawalInfo
	mapping(address => WithdrawalInfo) public requestedWithdrawals; // DEPRECATED

	//userAddress -> -> scheduleIndex -> staking detail
	mapping(address => mapping(uint256 => StakingDetails)) public userStakings;

	//userAddress -> scheduleIdx[]
	mapping(address => uint256[]) public userStakingSchedules;

	// We originally had the ability to remove schedules.
	// Reason for the extra tracking here around schedules

	//Schedule id/index counter
	uint256 public nextScheduleIndex;
	//scheduleIndex/id -> schedule
	mapping(uint256 => StakingSchedule) public schedules;
	//scheduleIndex/id[]
	EnumerableSet.UintSet private scheduleIdxs;

	//Can deposit into a non-public schedule
	mapping(address => bool) public override permissionedDepositors;

	bool public _eventSend;
	Destinations public destinations;

	IDelegateFunction public delegateFunction; //DEPRECATED

	// ScheduleIdx => notional address
	mapping(uint256 => address) public notionalAddresses;
	// address -> scheduleIdx -> WithdrawalInfo
	mapping(address => mapping(uint256 => WithdrawalInfo)) public withdrawalRequestsByIndex;

	address public override transferApprover;

	mapping(address => mapping(uint256 => QueuedTransfer)) public queuedTransfers;

	address public accToke;

	modifier onlyPermissionedDepositors() {
		require(_isAllowedPermissionedDeposit(), "CALLER_NOT_PERMISSIONED");
		_;
	}

	modifier onEventSend() {
		if (_eventSend) {
			_;
		}
	}

	//@custom:oz-upgrades-unsafe-allow constructor
	//solhint-disable-next-line no-empty-blocks
	constructor() public initializer {}

	function initialize(
		IERC20 _tokeToken,
		IManager _manager,
		address _treasury,
		address _scheduleZeroNotional
	) public initializer {
		__Context_init_unchained();
		__Ownable_init_unchained();
		__Pausable_init_unchained();

		require(address(_tokeToken) != address(0), "INVALID_TOKETOKEN");
		require(address(_manager) != address(0), "INVALID_MANAGER");
		require(_treasury != address(0), "INVALID_TREASURY");

		tokeToken = _tokeToken;
		manager = _manager;
		treasury = _treasury;

		//We want to be sure the schedule used for LP staking is first
		//because the order in which withdraws happen need to start with LP stakes
		_addSchedule(
			StakingSchedule({
				cliff: 0,
				duration: 1,
				interval: 1,
				setup: true,
				isActive: true,
				hardStart: 0,
				isPublic: true
			}),
			_scheduleZeroNotional
		);
	}

	function renounceOwnership() public override onlyOwner {
		revert("RENOUNCING_DISABLED");
	}

	function addSchedule(StakingSchedule memory schedule, address notional) external override onlyOwner {
		_addSchedule(schedule, notional);
	}

	function setPermissionedDepositor(address account, bool canDeposit) external override onlyOwner {
		permissionedDepositors[account] = canDeposit;

		emit PermissionedDepositorSet(account, canDeposit);
	}

	function setUserSchedules(address account, uint256[] calldata userSchedulesIdxs) external override onlyOwner {
		uint256 userScheduleLength = userSchedulesIdxs.length;
		for (uint256 i = 0; i < userScheduleLength; ++i) {
			require(scheduleIdxs.contains(userSchedulesIdxs[i]), "INVALID_SCHEDULE");
		}

		userStakingSchedules[account] = userSchedulesIdxs;

		emit UserSchedulesSet(account, userSchedulesIdxs);
	}

	function getSchedules() external view override returns (StakingScheduleInfo[] memory retSchedules) {
		uint256 length = scheduleIdxs.length();
		retSchedules = new StakingScheduleInfo[](length);
		for (uint256 i = 0; i < length; ++i) {
			retSchedules[i] = StakingScheduleInfo(schedules[scheduleIdxs.at(i)], scheduleIdxs.at(i));
		}
	}

	function getStakes(address account) external view override returns (StakingDetails[] memory stakes) {
		stakes = _getStakes(account);
	}

	function setNotionalAddresses(
		uint256[] calldata scheduleIdxArr,
		address[] calldata addresses
	) external override onlyOwner {
		uint256 length = scheduleIdxArr.length;
		require(length == addresses.length, "MISMATCH_LENGTH");
		for (uint256 i = 0; i < length; ++i) {
			uint256 currentScheduleIdx = scheduleIdxArr[i];
			address currentAddress = addresses[i];
			require(scheduleIdxs.contains(currentScheduleIdx), "INDEX_DOESNT_EXIST");
			require(currentAddress != address(0), "INVALID_ADDRESS");

			notionalAddresses[currentScheduleIdx] = currentAddress;
		}
		emit NotionalAddressesSet(scheduleIdxArr, addresses);
	}

	function balanceOf(address account) public view override returns (uint256 value) {
		value = 0;
		uint256 length = userStakingSchedules[account].length;
		for (uint256 i = 0; i < length; ++i) {
			StakingDetails memory details = userStakings[account][userStakingSchedules[account][i]];
			uint256 remaining = details.initial.sub(details.withdrawn);
			if (remaining > details.slashed) {
				value = value.add(remaining.sub(details.slashed));
			}
		}
	}

	function sweepToScheduleZero(uint256 scheduleIdx, uint256 amount) external override whenNotPaused nonReentrant {
		require(amount > 0, "INVALID_AMOUNT");
		require(scheduleIdx != 0, "NOT_ZERO");
		require(scheduleIdxs.contains(scheduleIdx), "INVALID_INDEX");

		StakingDetails storage stakeFrom = userStakings[msg.sender][scheduleIdx];
		uint256 amountAvailableToSweep = _vested(msg.sender, scheduleIdx).sub(stakeFrom.withdrawn);
		if (stakeFrom.slashed > 0) {
			if (stakeFrom.slashed > amountAvailableToSweep) {
				amountAvailableToSweep = 0;
			} else {
				amountAvailableToSweep = amountAvailableToSweep - stakeFrom.slashed; // Checked above, it'll be lte, no overflow risk
			}
		}

		require(amountAvailableToSweep >= amount, "INSUFFICIENT_BALANCE");

		StakingDetails storage stakeTo = userStakings[msg.sender][0];

		// Add 0 to userStakingSchedules
		if (stakeTo.started == 0) {
			userStakingSchedules[msg.sender].push(0);
			//solhint-disable-next-line not-rely-on-time
			stakeTo.started = block.timestamp;
		}
		stakeFrom.withdrawn = stakeFrom.withdrawn.add(amount);
		stakeTo.initial = stakeTo.initial.add(amount);

		uint256 remainingAmountWithdraw = stakeFrom.initial.sub((stakeFrom.withdrawn.add(stakeFrom.slashed)));

		if (withdrawalRequestsByIndex[msg.sender][scheduleIdx].amount > remainingAmountWithdraw) {
			withdrawalRequestsByIndex[msg.sender][scheduleIdx].amount = remainingAmountWithdraw;
		}

		uint256 voteAmountWithdraw = remainingAmountWithdraw
			.sub(withdrawalRequestsByIndex[msg.sender][scheduleIdx].amount)
			.sub(queuedTransfers[msg.sender][scheduleIdx].amount);

		uint256 voteAmountDeposit = (stakeTo.initial.sub((stakeTo.withdrawn.add(stakeTo.slashed))))
			.sub(withdrawalRequestsByIndex[msg.sender][0].amount)
			.sub(queuedTransfers[msg.sender][0].amount);

		depositWithdrawEvent(msg.sender, voteAmountWithdraw, scheduleIdx, msg.sender, voteAmountDeposit, 0);

		emit ZeroSweep(msg.sender, amount, scheduleIdx);
	}

	function availableForWithdrawal(address account, uint256 scheduleIndex) external view override returns (uint256) {
		return _availableForWithdrawal(account, scheduleIndex);
	}

	function unvested(address account, uint256 scheduleIndex) external view override returns (uint256 value) {
		value = 0;
		StakingDetails memory stake = userStakings[account][scheduleIndex];

		value = stake.initial.sub(_vested(account, scheduleIndex));
	}

	function vested(address account, uint256 scheduleIndex) external view override returns (uint256 value) {
		return _vested(account, scheduleIndex);
	}

	function deposit(uint256 amount, uint256 scheduleIndex) external override {
		_depositFor(msg.sender, amount, scheduleIndex);
	}

	function deposit(uint256 amount) external override {
		_depositFor(msg.sender, amount, 0);
	}

	function depositFor(
		address account,
		uint256 amount,
		uint256 scheduleIndex
	) external override onlyPermissionedDepositors {
		_depositFor(account, amount, scheduleIndex);
	}

	function requestWithdrawal(uint256 amount, uint256 scheduleIdx) external override {
		require(amount > 0, "INVALID_AMOUNT");
		require(scheduleIdxs.contains(scheduleIdx), "INVALID_SCHEDULE");
		uint256 availableAmount = _availableForWithdrawal(msg.sender, scheduleIdx);
		require(availableAmount >= amount, "INSUFFICIENT_AVAILABLE");

		withdrawalRequestsByIndex[msg.sender][scheduleIdx].amount = amount;
		if (manager.getRolloverStatus()) {
			withdrawalRequestsByIndex[msg.sender][scheduleIdx].minCycleIndex = manager.getCurrentCycleIndex().add(2);
		} else {
			withdrawalRequestsByIndex[msg.sender][scheduleIdx].minCycleIndex = manager.getCurrentCycleIndex().add(1);
		}

		bytes32 eventSig = "Withdrawal Request";
		StakingDetails memory userStake = userStakings[msg.sender][scheduleIdx];
		uint256 voteTotal = userStake.initial.sub((userStake.slashed.add(userStake.withdrawn))).sub(amount).sub(
			queuedTransfers[msg.sender][scheduleIdx].amount
		);

		encodeAndSendData(eventSig, msg.sender, scheduleIdx, voteTotal);

		emit WithdrawalRequested(msg.sender, scheduleIdx, amount);
	}

	function withdraw(uint256 amount, uint256 scheduleIdx) external override nonReentrant whenNotPaused {
		require(amount > 0, "NO_WITHDRAWAL");
		require(scheduleIdxs.contains(scheduleIdx), "INVALID_SCHEDULE");
		_withdraw(amount, scheduleIdx);
	}

	function withdraw(uint256 amount) external override whenNotPaused nonReentrant {
		require(amount > 0, "INVALID_AMOUNT");
		_withdraw(amount, 0);
	}

	function withdrawAndMigrate(uint256 amount, uint256 numOfCycles) external override nonReentrant whenNotPaused {
		require(accToke != address(0), "ACC_TOKE_NOT_SET");
		require(amount > 0, "INVALID_AMOUNT");
		require(numOfCycles > 0, "INVALID_NB_CYCLES");

		uint256 scheduleIdx = 0;

		uint256 queuedTransfersAmount = queuedTransfers[msg.sender][scheduleIdx].amount;
		require(queuedTransfersAmount == 0, "CANT_HAVE_TRANSFER_QUEUED");

		uint256 availableToBeRequestedToBeWithdrawn = _availableForWithdrawal(msg.sender, scheduleIdx);
		require(availableToBeRequestedToBeWithdrawn >= amount, "INSUFFICIENT_AVAILABLE");

		WithdrawalInfo storage request = withdrawalRequestsByIndex[msg.sender][scheduleIdx];
		uint256 availableAmount = availableToBeRequestedToBeWithdrawn.sub(request.amount);

		if (availableAmount < amount) {
			// we need to take from withdrawalRequests too
			uint256 toRemoveFromWithdrawalRequests = amount.sub(availableAmount);
			request.amount = request.amount.sub(toRemoveFromWithdrawalRequests);

			if (request.amount == 0) {
				request.minCycleIndex = 0;
			}
		}

		StakingDetails storage userStake = userStakings[msg.sender][scheduleIdx];
		userStake.withdrawn = userStake.withdrawn.add(amount);

		tokeToken.safeIncreaseAllowance(accToke, amount);
		IAccToke(accToke).lockTokeFor(amount, numOfCycles, msg.sender);

		bytes32 eventSig = "Withdraw";

		uint256 voteTotal = userStake.initial.sub((userStake.slashed.add(userStake.withdrawn))).sub(request.amount);

		encodeAndSendData(eventSig, msg.sender, scheduleIdx, voteTotal);

		emit Migrated(msg.sender, amount, scheduleIdx);
	}

	function slash(
		address[] calldata accounts,
		uint256[] calldata amounts,
		uint256 scheduleIndex
	) external override onlyOwner whenNotPaused {
		require(accounts.length == amounts.length, "LENGTH_MISMATCH");
		StakingSchedule storage schedule = schedules[scheduleIndex];
		require(schedule.setup, "INVALID_SCHEDULE");

		uint256 treasuryAmt = 0;

		for (uint256 i = 0; i < accounts.length; ++i) {
			address account = accounts[i];
			uint256 amount = amounts[i];

			require(amount > 0, "INVALID_AMOUNT");
			require(account != address(0), "INVALID_ADDRESS");

			StakingDetails memory userStake = userStakings[account][scheduleIndex];
			require(userStake.initial > 0, "NO_VESTING");

			uint256 availableToSlash = 0;
			uint256 remaining = userStake.initial.sub(userStake.withdrawn);
			if (remaining > userStake.slashed) {
				availableToSlash = remaining.sub(userStake.slashed);
			}

			require(availableToSlash >= amount, "INSUFFICIENT_AVAILABLE");

			userStake.slashed = userStake.slashed.add(amount);
			userStakings[account][scheduleIndex] = userStake;

			uint256 totalLeft = userStake.initial.sub((userStake.slashed.add(userStake.withdrawn)));

			if (withdrawalRequestsByIndex[account][scheduleIndex].amount > totalLeft) {
				withdrawalRequestsByIndex[account][scheduleIndex].amount = totalLeft;
			}

			uint256 voteAmount = totalLeft.sub(withdrawalRequestsByIndex[account][scheduleIndex].amount);

			// voteAmount is now the current total they have voteable. If a transfer
			// is also queued, we need to be sure the queued amount is still valid
			uint256 queuedTransfer = queuedTransfers[account][scheduleIndex].amount;
			if (queuedTransfer > 0 && queuedTransfer > voteAmount) {
				queuedTransfer = voteAmount;
				if (queuedTransfer == 0) {
					_removeQueuedTransfer(account, scheduleIndex);
				} else {
					queuedTransfers[account][scheduleIndex].amount = queuedTransfer;
				}
			}

			// An amount queued for transfer cannot be voted with.
			voteAmount = voteAmount.sub(queuedTransfer);

			bytes32 eventSig = "Slash";

			encodeAndSendData(eventSig, account, scheduleIndex, voteAmount);

			treasuryAmt = treasuryAmt.add(amount);

			emit Slashed(account, amount, scheduleIndex);
		}

		tokeToken.safeTransfer(treasury, treasuryAmt);
	}

	function queueTransfer(
		uint256 scheduleIdxFrom,
		uint256 scheduleIdxTo,
		uint256 amount,
		address to
	) external override whenNotPaused {
		require(queuedTransfers[msg.sender][scheduleIdxFrom].amount == 0, "TRANSFER_QUEUED");

		uint256 minCycle;
		if (manager.getRolloverStatus()) {
			minCycle = manager.getCurrentCycleIndex().add(2);
		} else {
			minCycle = manager.getCurrentCycleIndex().add(1);
		}

		_validateStakeTransfer(msg.sender, scheduleIdxFrom, scheduleIdxTo, amount, to);

		queuedTransfers[msg.sender][scheduleIdxFrom] = QueuedTransfer({
			from: msg.sender,
			scheduleIdxFrom: scheduleIdxFrom,
			scheduleIdxTo: scheduleIdxTo,
			amount: amount,
			to: to,
			minCycle: minCycle
		});

		emit TransferQueued(msg.sender, scheduleIdxFrom, scheduleIdxTo, amount, to, minCycle);

		StakingDetails storage userStake = userStakings[msg.sender][scheduleIdxFrom];

		// Remove the queued transfer amounts from the user's vote total
		bytes32 eventSig = "Transfer";
		uint256 voteTotal = userStake
			.initial
			.sub((userStake.slashed.add(userStake.withdrawn)))
			.sub(withdrawalRequestsByIndex[msg.sender][scheduleIdxFrom].amount)
			.sub(amount);

		encodeAndSendData(eventSig, msg.sender, scheduleIdxFrom, voteTotal);
	}

	function removeQueuedTransfer(uint256 scheduleIdxFrom) external override whenNotPaused {
		_removeQueuedTransfer(msg.sender, scheduleIdxFrom);

		StakingDetails storage userStake = userStakings[msg.sender][scheduleIdxFrom];

		// Add the removed queued transfer amount to the user's vote total
		bytes32 eventSig = "Transfer";
		uint256 voteTotal = userStake.initial.sub((userStake.slashed.add(userStake.withdrawn))).sub(
			withdrawalRequestsByIndex[msg.sender][scheduleIdxFrom].amount
		);

		encodeAndSendData(eventSig, msg.sender, scheduleIdxFrom, voteTotal);
	}

	function _removeQueuedTransfer(address account, uint256 scheduleIdxFrom) private {
		QueuedTransfer memory queuedTransfer = queuedTransfers[account][scheduleIdxFrom];
		delete queuedTransfers[account][scheduleIdxFrom];

		emit QueuedTransferRemoved(
			account,
			queuedTransfer.scheduleIdxFrom,
			queuedTransfer.scheduleIdxTo,
			queuedTransfer.amount,
			queuedTransfer.to,
			queuedTransfer.minCycle
		);
	}

	function rejectQueuedTransfer(address from, uint256 scheduleIdxFrom) external override whenNotPaused {
		require(msg.sender == transferApprover, "NOT_APPROVER");

		QueuedTransfer memory queuedTransfer = queuedTransfers[from][scheduleIdxFrom];
		require(queuedTransfer.amount != 0, "NO_TRANSFER_QUEUED");

		delete queuedTransfers[from][scheduleIdxFrom];

		emit QueuedTransferRejected(
			from,
			scheduleIdxFrom,
			queuedTransfer.scheduleIdxTo,
			queuedTransfer.amount,
			queuedTransfer.to,
			queuedTransfer.minCycle,
			msg.sender
		);

		StakingDetails storage userStake = userStakings[from][scheduleIdxFrom];

		// Add the rejected queued transfer amount to the user's vote total
		bytes32 eventSig = "Transfer";
		uint256 voteTotal = userStake.initial.sub((userStake.slashed.add(userStake.withdrawn))).sub(
			withdrawalRequestsByIndex[from][scheduleIdxFrom].amount
		);

		encodeAndSendData(eventSig, from, scheduleIdxFrom, voteTotal);
	}

	function setAccToke(address _accToke) external override onlyOwner {
		require(_accToke != address(0), "INVALID_ADDRESS");
		accToke = _accToke;
		emit AccTokeUpdated(accToke);
	}

	function approveQueuedTransfer(
		address from,
		uint256 scheduleIdxFrom,
		uint256 scheduleIdxTo,
		uint256 amount,
		address to
	) external override whenNotPaused nonReentrant {
		QueuedTransfer memory queuedTransfer = queuedTransfers[from][scheduleIdxFrom];

		require(msg.sender == transferApprover, "NOT_APPROVER");
		require(queuedTransfer.scheduleIdxTo == scheduleIdxTo, "MISMATCH_SCHEDULE_TO");
		require(queuedTransfer.amount == amount, "MISMATCH_AMOUNT");
		require(queuedTransfer.to == to, "MISMATCH_TO");
		require(manager.getCurrentCycleIndex() >= queuedTransfer.minCycle, "INVALID_CYCLE");

		delete queuedTransfers[from][scheduleIdxFrom];

		_validateStakeTransfer(from, scheduleIdxFrom, scheduleIdxTo, amount, to);

		StakingDetails storage stake = userStakings[from][scheduleIdxFrom];

		stake.initial = stake.initial.sub(amount);

		StakingDetails memory newStake = _updateStakingDetails(scheduleIdxTo, to, amount);

		uint256 voteAmountWithdraw = (stake.initial.sub((stake.withdrawn.add(stake.slashed)))).sub(
			withdrawalRequestsByIndex[from][scheduleIdxFrom].amount
		);

		uint256 voteAmountDeposit = (newStake.initial.sub((newStake.withdrawn.add(newStake.slashed))))
			.sub(withdrawalRequestsByIndex[to][scheduleIdxTo].amount)
			.sub(queuedTransfers[to][scheduleIdxTo].amount);

		depositWithdrawEvent(from, voteAmountWithdraw, scheduleIdxFrom, to, voteAmountDeposit, scheduleIdxTo);

		emit StakeTransferred(from, scheduleIdxFrom, scheduleIdxTo, amount, to);
	}

	function getQueuedTransfer(
		address fromAddress,
		uint256 fromScheduleId
	) external view override returns (QueuedTransfer memory) {
		return queuedTransfers[fromAddress][fromScheduleId];
	}

	function setScheduleStatus(uint256 scheduleId, bool activeBool) external override onlyOwner {
		require(scheduleIdxs.contains(scheduleId), "INVALID_SCHEDULE");

		StakingSchedule storage schedule = schedules[scheduleId];
		schedule.isActive = activeBool;

		emit ScheduleStatusSet(scheduleId, activeBool);
	}

	function setScheduleHardStart(uint256 scheduleIdx, uint256 hardStart) external override onlyOwner {
		require(scheduleIdxs.contains(scheduleIdx), "INVALID_SCHEDULE");

		StakingSchedule storage schedule = schedules[scheduleIdx];

		require(schedule.hardStart > 0, "HARDSTART_NOT_SET");
		require(schedule.hardStart < hardStart, "HARDSTART_MUST_BE_GT");

		schedule.hardStart = hardStart;

		emit ScheduleHardStartSet(scheduleIdx, hardStart);
	}

	function updateScheduleStart(address[] calldata accounts, uint256 scheduleIdx) external override onlyOwner {
		require(scheduleIdxs.contains(scheduleIdx), "INVALID_SCHEDULE");

		uint256 hardStart = schedules[scheduleIdx].hardStart;
		require(hardStart > 0, "HARDSTART_NOT_SET");
		for (uint256 i = 0; i < accounts.length; ++i) {
			StakingDetails storage stake = userStakings[accounts[i]][scheduleIdx];
			require(stake.started != 0);
			stake.started = hardStart;
		}
	}

	function pause() external override onlyOwner {
		_pause();
	}

	function unpause() external override onlyOwner {
		_unpause();
	}

	function setDestinations(address _fxStateSender, address _destinationOnL2) external override onlyOwner {
		require(_fxStateSender != address(0), "INVALID_ADDRESS");
		require(_destinationOnL2 != address(0), "INVALID_ADDRESS");

		destinations.fxStateSender = IFxStateSender(_fxStateSender);
		destinations.destinationOnL2 = _destinationOnL2;

		emit DestinationsSet(_fxStateSender, _destinationOnL2);
	}

	function setEventSend(bool _eventSendSet) external override onlyOwner {
		require(destinations.destinationOnL2 != address(0), "DESTINATIONS_NOT_SET");

		_eventSend = _eventSendSet;

		emit EventSendSet(_eventSendSet);
	}

	function setTransferApprover(address approver) external override onlyOwner {
		require(approver != address(0), "INVALID_ADDRESS");
		transferApprover = approver;

		emit TransferApproverSet(approver);
	}

	function _availableForWithdrawal(address account, uint256 scheduleIndex) private view returns (uint256) {
		StakingDetails memory stake = userStakings[account][scheduleIndex];
		uint256 vestedWoWithdrawn = _vested(account, scheduleIndex).sub(stake.withdrawn);
		if (stake.slashed > vestedWoWithdrawn) {
			return 0;
		}
		uint256 woSlashed = vestedWoWithdrawn - stake.slashed; // Checked above, it'll be lte, no overflow risk

		// Transfer amounts can be for unvested amts so we need to handle carefully
		uint256 requestedTransfer = queuedTransfers[account][scheduleIndex].amount;
		if (requestedTransfer > woSlashed) {
			return 0;
		}
		return woSlashed - requestedTransfer; // Checked above, it'll be lte, no overflow risk
	}

	function _validateStakeTransfer(
		address from,
		uint256 scheduleIdxFrom,
		uint256 scheduleIdxTo,
		uint256 amount,
		address to
	) private {
		require(amount > 0, "INVALID_AMOUNT");
		require(to != address(0), "INVALID_ADDRESS");

		if (to == from) {
			require(scheduleIdxFrom != scheduleIdxTo, "NO_SELF_SAME_SCHEDULE");
		}

		StakingSchedule memory scheduleTo = schedules[scheduleIdxTo];

		if (scheduleIdxFrom != scheduleIdxTo) {
			require(scheduleTo.setup, "MUST_BE_SETUP");
			require(scheduleTo.isActive, "MUST_BE_ACTIVE");

			StakingSchedule memory scheduleFrom = schedules[scheduleIdxFrom];
			require(
				scheduleTo.hardStart.add(scheduleTo.cliff) >= scheduleFrom.hardStart.add(scheduleFrom.cliff),
				"CLIFF_MUST_BE_GTE"
			);
			require(
				scheduleTo.hardStart.add(scheduleTo.cliff).add(scheduleTo.duration) >=
					scheduleFrom.hardStart.add(scheduleFrom.cliff).add(scheduleFrom.duration),
				"SCHEDULE_MUST_BE_GTE"
			);
		}

		StakingDetails memory stake = userStakings[from][scheduleIdxFrom];
		require(
			amount <=
				stake.initial.sub((stake.withdrawn.add(stake.slashed))).sub(
					withdrawalRequestsByIndex[from][scheduleIdxFrom].amount
				),
			"INSUFFICIENT_AVAILABLE"
		);
	}

	function _depositFor(address account, uint256 amount, uint256 scheduleIndex) private nonReentrant whenNotPaused {
		StakingSchedule memory schedule = schedules[scheduleIndex];
		require(amount > 0, "INVALID_AMOUNT");
		require(schedule.setup, "INVALID_SCHEDULE");
		require(schedule.isActive, "INACTIVE_SCHEDULE");
		require(account != address(0), "INVALID_ADDRESS");
		require(schedule.isPublic || _isAllowedPermissionedDeposit(), "PERMISSIONED_SCHEDULE");

		StakingDetails memory userStake = _updateStakingDetails(scheduleIndex, account, amount);

		bytes32 eventSig = "Deposit";
		uint256 voteTotal = userStake
			.initial
			.sub((userStake.slashed.add(userStake.withdrawn)))
			.sub(withdrawalRequestsByIndex[account][scheduleIndex].amount)
			.sub(queuedTransfers[account][scheduleIndex].amount);

		encodeAndSendData(eventSig, account, scheduleIndex, voteTotal);

		tokeToken.safeTransferFrom(msg.sender, address(this), amount);

		emit Deposited(account, amount, scheduleIndex);
	}

	function _withdraw(uint256 amount, uint256 scheduleIdx) private {
		WithdrawalInfo storage request = withdrawalRequestsByIndex[msg.sender][scheduleIdx];
		require(amount <= request.amount, "INSUFFICIENT_AVAILABLE");
		require(request.minCycleIndex <= manager.getCurrentCycleIndex(), "INVALID_CYCLE");

		StakingDetails storage userStake = userStakings[msg.sender][scheduleIdx];
		userStake.withdrawn = userStake.withdrawn.add(amount);

		request.amount = request.amount.sub(amount);

		if (request.amount == 0) {
			request.minCycleIndex = 0;
		}

		tokeToken.safeTransfer(msg.sender, amount);

		emit WithdrawCompleted(msg.sender, scheduleIdx, amount);
	}

	function _vested(address account, uint256 scheduleIndex) private view returns (uint256) {
		// solhint-disable-next-line not-rely-on-time
		uint256 timestamp = block.timestamp;
		uint256 value = 0;
		StakingDetails memory stake = userStakings[account][scheduleIndex];
		StakingSchedule memory schedule = schedules[scheduleIndex];

		uint256 cliffTimestamp = stake.started.add(schedule.cliff);
		if (cliffTimestamp <= timestamp) {
			if (cliffTimestamp.add(schedule.duration) <= timestamp) {
				value = stake.initial;
			} else {
				uint256 secondsStaked = Math.max(timestamp.sub(cliffTimestamp), 1);
				//Precision loss is intentional. Enables the interval buckets
				uint256 effectiveSecondsStaked = (secondsStaked.div(schedule.interval)).mul(schedule.interval);
				value = stake.initial.mul(effectiveSecondsStaked).div(schedule.duration);
			}
		}

		return value;
	}

	function _addSchedule(StakingSchedule memory schedule, address notional) private {
		require(schedule.duration > 0, "INVALID_DURATION");
		require(schedule.interval > 0, "INVALID_INTERVAL");
		require(notional != address(0), "INVALID_ADDRESS");

		schedule.setup = true;
		uint256 index = nextScheduleIndex;
		require(scheduleIdxs.add(index), "ADD_FAIL");
		schedules[index] = schedule;
		notionalAddresses[index] = notional;
		nextScheduleIndex = nextScheduleIndex.add(1);

		emit ScheduleAdded(
			index,
			schedule.cliff,
			schedule.duration,
			schedule.interval,
			schedule.setup,
			schedule.isActive,
			schedule.hardStart,
			notional
		);
	}

	function _getStakes(address account) private view returns (StakingDetails[] memory stakes) {
		uint256 length = userStakingSchedules[account].length;
		stakes = new StakingDetails[](length);

		for (uint256 i = 0; i < length; ++i) {
			stakes[i] = userStakings[account][userStakingSchedules[account][i]];
		}
	}

	function _isAllowedPermissionedDeposit() private view returns (bool) {
		return permissionedDepositors[msg.sender] || msg.sender == owner();
	}

	function encodeAndSendData(
		bytes32 _eventSig,
		address _user,
		uint256 _scheduleIdx,
		uint256 _userBalance
	) private onEventSend {
		require(address(destinations.fxStateSender) != address(0), "ADDRESS_NOT_SET");
		require(destinations.destinationOnL2 != address(0), "ADDRESS_NOT_SET");
		address notionalAddress = notionalAddresses[_scheduleIdx];

		bytes memory data = abi.encode(
			BalanceUpdateEvent({ eventSig: _eventSig, account: _user, token: notionalAddress, amount: _userBalance })
		);

		destinations.fxStateSender.sendMessageToChild(destinations.destinationOnL2, data);
	}

	function _updateStakingDetails(
		uint256 scheduleIdx,
		address account,
		uint256 amount
	) private returns (StakingDetails memory) {
		StakingDetails storage stake = userStakings[account][scheduleIdx];
		if (stake.started == 0) {
			userStakingSchedules[account].push(scheduleIdx);
			uint256 hardStart = schedules[scheduleIdx].hardStart;
			if (hardStart > 0) {
				stake.started = hardStart;
			} else {
				//solhint-disable-next-line not-rely-on-time
				stake.started = block.timestamp;
			}
		}
		stake.initial = stake.initial.add(amount);
		stake.scheduleIx = scheduleIdx;

		return stake;
	}

	function depositWithdrawEvent(
		address withdrawUser,
		uint256 totalFromWithdrawAccount,
		uint256 withdrawScheduleIdx,
		address depositUser,
		uint256 totalFromDepositAccount,
		uint256 depositScheduleIdx
	) private {
		bytes32 withdrawEvent = "Withdraw";
		bytes32 depositEvent = "Deposit";
		encodeAndSendData(withdrawEvent, withdrawUser, withdrawScheduleIdx, totalFromWithdrawAccount);
		encodeAndSendData(depositEvent, depositUser, depositScheduleIdx, totalFromDepositAccount);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.9;

import "./IERC20NonTransferable.sol";

interface IAccToke is IERC20NonTransferable {
	struct WithdrawalInfo {
		uint256 minCycle;
		uint256 amount;
	}

	struct DepositInfo {
		uint256 lockCycle;
		uint256 lockDuration;
	}

	//////////////////////////
	// Events
	event TokeLockedEvent(
		address indexed tokeSource,
		address indexed account,
		uint256 numCycles,
		uint256 indexed currentCycle,
		uint256 amount
	);
	event WithdrawalRequestedEvent(address indexed account, uint256 amount);
	event WithdrawalRequestCancelledEvent(address indexed account);
	event WithdrawalEvent(address indexed account, uint256 amount);

	event MinLockCyclesSetEvent(uint256 minLockCycles);
	event MaxLockCyclesSetEvent(uint256 maxLockCycles);
	event MaxCapSetEvent(uint256 maxCap);

	//////////////////////////
	// Methods

	/// @notice Lock Toke for `numOfCycles` cycles -> get accToke
	/// @param tokeAmount Amount of TOKE to lock up
	/// @param numOfCycles Number of cycles to lock for
	function lockToke(uint256 tokeAmount, uint256 numOfCycles) external;

	/// @notice Lock Toke for a different account for `numOfCycles` cycles -> that account gets resulting accTOKE
	/// @param tokeAmount Amount of TOKE to lock up
	/// @param numOfCycles Number of cycles to lock for
	/// @param account Account to lock TOKE for
	function lockTokeFor(uint256 tokeAmount, uint256 numOfCycles, address account) external;

	/// @notice Request to withdraw TOKE from accToke
	/// @param amount Amount of accTOKE to return
	function requestWithdrawal(uint256 amount) external;

	/// @notice Cancel pending withdraw request (frees up accToke for rewards/voting)
	function cancelWithdrawalRequest() external;

	/// @notice Withdraw previously requested funds
	/// @param amount Amount of TOKE to withdraw
	function withdraw(uint256 amount) external;

	/// @return Amount of liquidity that should not be deployed for market making (this liquidity is set aside for completing requested withdrawals)
	function withheldLiquidity() external view returns (uint256);

	function minLockCycles() external view returns (uint256);

	function maxLockCycles() external view returns (uint256);

	function maxCap() external view returns (uint256);

	function setMaxCap(uint256 totalAmount) external;

	function setMaxLockCycles(uint256 _maxLockCycles) external;

	function setMinLockCycles(uint256 _minLockCycles) external;

	//////////////////////////////////////////////////
	//												//
	//			   	  Enumeration					//
	//												//
	//////////////////////////////////////////////////

	/// @notice Get current cycle
	function getCurrentCycleID() external view returns (uint256);

	/// @notice Get all the deposit information for a specified account
	/// @param account Account to get deposit info for
	/// @return lockCycle Cycle Index when deposit was made
	/// @return lockDuration Number of cycles deposit is locked for
	/// @return amount Amount of TOKE deposited
	function getDepositInfo(
		address account
	) external view returns (uint256 lockCycle, uint256 lockDuration, uint256 amount);

	/// @notice Get withdrawal request info for a specified account
	/// @param account User to get withdrawal request info for
	/// @return minCycle Minimum cycle ID when withdrawal can be processed
	/// @return amount Amount of TOKE requested for withdrawal
	function getWithdrawalInfo(address account) external view returns (uint256 minCycle, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

import "../../fxPortal/IFxStateSender.sol";

/// @notice Configuration entity for sending events to Governance layer
struct Destinations {
	IFxStateSender fxStateSender;
	address destinationOnL2;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/// @notice Event sent to Governance layer when a users balance changes
struct BalanceUpdateEvent {
	bytes32 eventSig;
	address account;
	address token;
	uint256 amount;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;

import "./Destinations.sol";

interface IEventSender {
	event DestinationsSet(address fxStateSender, address destinationOnL2);
	event EventSendSet(bool eventSendSet);

	/// @notice Configure the Polygon state sender root and destination for messages sent
	/// @param fxStateSender Address of Polygon State Sender Root contract
	/// @param destinationOnL2 Destination address of events sent. Should be our Event Proxy
	function setDestinations(address fxStateSender, address destinationOnL2) external;

	/// @notice Enables or disables the sending of events
	function setEventSend(bool eventSendSet) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.9;

interface IERC20NonTransferable {
	function name() external view returns (string memory);

	function symbol() external view returns (string memory);

	function decimals() external view returns (uint8);

	function totalSupply() external view returns (uint256);

	function balanceOf(address _owner) external view returns (uint256 balance);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IFxStateSender {
	function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IManager.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import { SafeMathUpgradeable as SafeMath } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { MathUpgradeable as Math } from "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import { OwnableUpgradeable as Ownable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ERC20Upgradeable as ERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import { PausableUpgradeable as Pausable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "../interfaces/events/BalanceUpdateEvent.sol";
import "../interfaces/events/Destinations.sol";
import "../fxPortal/IFxStateSender.sol";
import "../interfaces/events/IEventSender.sol";

contract Pool is ILiquidityPool, Initializable, ERC20, Ownable, Pausable, IEventSender {
	using SafeMath for uint256;
	using SafeERC20 for ERC20;

	ERC20 public override underlyer; // Underlying ERC20 token
	IManager public manager;

	// implied: deployableLiquidity = underlyer.balanceOf(this) - withheldLiquidity
	uint256 public override withheldLiquidity;

	// fAsset holder -> WithdrawalInfo
	mapping(address => WithdrawalInfo) public override requestedWithdrawals;

	// NonReentrant
	bool private _entered;
	bool public _eventSend;
	Destinations public destinations;

	bool public depositsPaused;

	mapping(address => bool) public registeredBurners;

	address public rebalancer;

	modifier nonReentrant() {
		require(!_entered, "ReentrancyGuard: reentrant call");
		_entered = true;
		_;
		_entered = false;
	}

	modifier onEventSend() {
		if (_eventSend) {
			_;
		}
	}

	modifier whenDepositsNotPaused() {
		require(!paused(), "Pausable: paused");
		require(!depositsPaused, "DEPOSITS_PAUSED");
		_;
	}

	modifier onlyRegisteredBurner() {
		require(registeredBurners[msg.sender], "NOT_REGISTERED_BURNER");
		_;
	}

	//@custom:oz-upgrades-unsafe-allow constructor
	//solhint-disable-next-line no-empty-blocks
	constructor() public initializer {}

	function initialize(
		ERC20 _underlyer,
		IManager _manager,
		string memory _name,
		string memory _symbol,
		address _rebalancer
	) external initializer {
		require(address(_underlyer) != address(0), "ZERO_ADDRESS");
		require(address(_manager) != address(0), "ZERO_ADDRESS");

		__Context_init_unchained();
		__Ownable_init_unchained();
		__Pausable_init_unchained();
		__ERC20_init_unchained(_name, _symbol);
		setRebalancer(_rebalancer);

		underlyer = _underlyer;
		manager = _manager;
	}

	///@notice Gets decimals of underlyer so that tAsset decimals will match
	function decimals() public view override returns (uint8) {
		return underlyer.decimals();
	}

	function registerBurner(address burner, bool allowedBurner) external override onlyOwner {
		require(burner != address(0), "INVALID_ADDRESS");
		registeredBurners[burner] = allowedBurner;

		emit BurnerRegistered(burner, allowedBurner);
	}

	function setRebalancer(address _rebalancer) public override onlyOwner {
		require(_rebalancer != address(0), "ZERO_ADDRESS");
		rebalancer = _rebalancer;

		emit RebalancerSet(_rebalancer);
	}

	function deposit(uint256 amount) external override whenDepositsNotPaused {
		_deposit(msg.sender, msg.sender, amount);
	}

	function depositFor(address account, uint256 amount) external override whenDepositsNotPaused {
		_deposit(msg.sender, account, amount);
	}

	/// @dev References the WithdrawalInfo for how much the user is permitted to withdraw
	/// @dev No withdrawal permitted unless currentCycle >= minCycle
	/// @dev Decrements withheldLiquidity by the withdrawn amount
	function withdraw(uint256 requestedAmount) external override whenNotPaused nonReentrant {
		require(requestedAmount <= requestedWithdrawals[msg.sender].amount, "WITHDRAW_INSUFFICIENT_BALANCE");
		require(requestedAmount > 0, "NO_WITHDRAWAL");
		require(underlyer.balanceOf(address(this)) >= requestedAmount, "INSUFFICIENT_POOL_BALANCE");

		// Checks for manager cycle and if user is allowed to withdraw based on their minimum withdrawal cycle
		require(requestedWithdrawals[msg.sender].minCycle <= manager.getCurrentCycleIndex(), "INVALID_CYCLE");

		requestedWithdrawals[msg.sender].amount = requestedWithdrawals[msg.sender].amount.sub(requestedAmount);

		// If full amount withdrawn delete from mapping
		if (requestedWithdrawals[msg.sender].amount == 0) {
			delete requestedWithdrawals[msg.sender];
		}

		withheldLiquidity = withheldLiquidity.sub(requestedAmount);

		_burn(msg.sender, requestedAmount);
		underlyer.safeTransfer(msg.sender, requestedAmount);

		bytes32 eventSig = "Withdraw";
		encodeAndSendData(eventSig, msg.sender);
	}

	/// @dev Adjusts the withheldLiquidity as necessary
	/// @dev Updates the WithdrawalInfo for when a user can withdraw and for what requested amount
	function requestWithdrawal(uint256 amount) external override {
		require(amount > 0, "INVALID_AMOUNT");
		require(amount <= balanceOf(msg.sender), "INSUFFICIENT_BALANCE");

		//adjust withheld liquidity by removing the original withheld amount and adding the new amount
		withheldLiquidity = withheldLiquidity.sub(requestedWithdrawals[msg.sender].amount).add(amount);
		requestedWithdrawals[msg.sender].amount = amount;
		if (manager.getRolloverStatus()) {
			// If manger is currently rolling over add two to min withdrawal cycle
			requestedWithdrawals[msg.sender].minCycle = manager.getCurrentCycleIndex().add(2);
		} else {
			// If manager is not rolling over add one to minimum withdrawal cycle
			requestedWithdrawals[msg.sender].minCycle = manager.getCurrentCycleIndex().add(1);
		}

		emit WithdrawalRequested(msg.sender, amount);
	}

	function preTransferAdjustWithheldLiquidity(address sender, uint256 amount) internal {
		if (requestedWithdrawals[sender].amount > 0) {
			//reduce requested withdraw amount by transferred amount;
			uint256 newRequestedWithdrawl = requestedWithdrawals[sender].amount.sub(
				Math.min(amount, requestedWithdrawals[sender].amount)
			);

			//subtract from global withheld liquidity (reduce) by removing the delta of (requestedAmount - newRequestedAmount)
			withheldLiquidity = withheldLiquidity.sub(requestedWithdrawals[sender].amount.sub(newRequestedWithdrawl));

			//update the requested withdraw for user
			requestedWithdrawals[sender].amount = newRequestedWithdrawl;

			//if the withdraw request is 0, empty it out
			if (requestedWithdrawals[sender].amount == 0) {
				delete requestedWithdrawals[sender];
			}
		}
	}

	function approveManager(uint256 amount) external override onlyOwner {
		approve(amount, address(manager));
	}

	function approveRebalancer(uint256 amount) external override onlyOwner {
		require(rebalancer != address(0), "ZERO_ADDRESS");
		approve(amount, rebalancer);
	}

	/// @dev Adjust withheldLiquidity and requestedWithdrawal if sender does not have sufficient unlocked balance for the transfer
	function transfer(address recipient, uint256 amount) public override whenNotPaused nonReentrant returns (bool) {
		preTransferAdjustWithheldLiquidity(msg.sender, amount);
		bool success = super.transfer(recipient, amount);

		bytes32 eventSig = "Transfer";
		encodeAndSendData(eventSig, msg.sender);
		encodeAndSendData(eventSig, recipient);

		return success;
	}

	/// @dev Adjust withheldLiquidity and requestedWithdrawal if sender does not have sufficient unlocked balance for the transfer
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public override whenNotPaused nonReentrant returns (bool) {
		preTransferAdjustWithheldLiquidity(sender, amount);
		bool success = super.transferFrom(sender, recipient, amount);

		bytes32 eventSig = "Transfer";
		encodeAndSendData(eventSig, sender);
		encodeAndSendData(eventSig, recipient);

		return success;
	}

	function controlledBurn(uint256 amount, address account) external override onlyRegisteredBurner whenNotPaused {
		require(account != address(0), "INVALID_ADDRESS");
		require(amount > 0, "INVALID_AMOUNT");
		if (account != msg.sender) {
			uint256 currentAllowance = allowance(account, msg.sender);
			require(currentAllowance >= amount, "INSUFFICIENT_ALLOWANCE");
			_approve(account, msg.sender, currentAllowance.sub(amount));
		}

		// Updating withdrawal requests only if currentBalance - burn amount is
		// Less than requested withdrawal
		uint256 requestedAmount = requestedWithdrawals[account].amount;
		uint256 balance = balanceOf(account);
		require(amount <= balance, "INSUFFICIENT_BALANCE");
		uint256 currentBalance = balance.sub(amount);
		if (requestedAmount > currentBalance) {
			if (currentBalance == 0) {
				delete requestedWithdrawals[account];
				withheldLiquidity = withheldLiquidity.sub(requestedAmount);
			} else {
				requestedWithdrawals[account].amount = currentBalance;
				withheldLiquidity = withheldLiquidity.sub(requestedAmount.sub(currentBalance));
			}
		}
		_burn(account, amount);

		emit Burned(account, msg.sender, amount);
	}

	function pauseDeposit() external override onlyOwner {
		depositsPaused = true;

		emit DepositsPaused();
	}

	function unpauseDeposit() external override onlyOwner {
		depositsPaused = false;

		emit DepositsUnpaused();
	}

	function pause() external override onlyOwner {
		_pause();
	}

	function unpause() external override onlyOwner {
		_unpause();
	}

	function setDestinations(address _fxStateSender, address _destinationOnL2) external override onlyOwner {
		require(_fxStateSender != address(0), "INVALID_ADDRESS");
		require(_destinationOnL2 != address(0), "INVALID_ADDRESS");

		destinations.fxStateSender = IFxStateSender(_fxStateSender);
		destinations.destinationOnL2 = _destinationOnL2;

		emit DestinationsSet(_fxStateSender, _destinationOnL2);
	}

	function setEventSend(bool _eventSendSet) external override onlyOwner {
		require(destinations.destinationOnL2 != address(0), "DESTINATIONS_NOT_SET");

		_eventSend = _eventSendSet;

		emit EventSendSet(_eventSendSet);
	}

	function _deposit(address fromAccount, address toAccount, uint256 amount) internal {
		require(amount > 0, "INVALID_AMOUNT");
		require(toAccount != address(0), "INVALID_ADDRESS");

		_mint(toAccount, amount);
		underlyer.safeTransferFrom(fromAccount, address(this), amount);

		bytes32 eventSig = "Deposit";
		encodeAndSendData(eventSig, toAccount);
	}

	function encodeAndSendData(bytes32 _eventSig, address _user) private onEventSend {
		require(address(destinations.fxStateSender) != address(0), "ADDRESS_NOT_SET");
		require(destinations.destinationOnL2 != address(0), "ADDRESS_NOT_SET");

		uint256 userBalance = balanceOf(_user);
		bytes memory data = abi.encode(
			BalanceUpdateEvent({ eventSig: _eventSig, account: _user, token: address(this), amount: userBalance })
		);

		destinations.fxStateSender.sendMessageToChild(destinations.destinationOnL2, data);
	}

	function approve(uint256 amount, address approvee) private {
		uint256 currentAllowance = underlyer.allowance(address(this), approvee);
		if (currentAllowance < amount) {
			uint256 delta = amount.sub(currentAllowance);
			underlyer.safeIncreaseAllowance(approvee, delta);
		} else {
			uint256 delta = currentAllowance.sub(amount);
			underlyer.safeDecreaseAllowance(approvee, delta);
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/ILiquidityEthPool.sol";
import "../interfaces/IManager.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IAddressRegistry.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import { AddressUpgradeable as Address } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { MathUpgradeable as Math } from "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import { SafeMathUpgradeable as SafeMath } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { OwnableUpgradeable as Ownable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ERC20Upgradeable as ERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import { PausableUpgradeable as Pausable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "../interfaces/events/BalanceUpdateEvent.sol";
import "../interfaces/events/Destinations.sol";
import "../interfaces/events/IEventSender.sol";

contract EthPool is ILiquidityEthPool, Initializable, ERC20, Ownable, Pausable, IEventSender {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	using Address for address;
	using Address for address payable;

	/// @dev TODO: Hardcode addresses, make immuatable, remove from initializer
	IWETH public override weth;
	IManager public manager;

	// implied: deployableLiquidity = underlyer.balanceOf(this) - withheldLiquidity
	uint256 public override withheldLiquidity;

	// fAsset holder -> WithdrawalInfo
	mapping(address => WithdrawalInfo) public override requestedWithdrawals;

	// NonReentrant
	bool private _entered;

	bool public _eventSend;
	Destinations public destinations;

	mapping(address => bool) public registeredBurners;

	address public rebalancer;

	modifier nonReentrant() {
		require(!_entered, "ReentrancyGuard: reentrant call");
		_entered = true;
		_;
		_entered = false;
	}

	modifier onEventSend() {
		if (_eventSend) {
			_;
		}
	}

	modifier onlyRegisteredBurner() {
		require(registeredBurners[msg.sender], "NOT_REGISTERED_BURNER");
		_;
	}

	/// @dev necessary to receive ETH
	// solhint-disable-next-line no-empty-blocks
	receive() external payable {}

	//@custom:oz-upgrades-unsafe-allow constructor
	//solhint-disable-next-line no-empty-blocks
	constructor() public initializer {}

	function initialize(
		IManager _manager,
		address _addressRegistry,
		string memory _name,
		string memory _symbol,
		address _rebalancer
	) public initializer {
		require(address(_manager) != address(0), "ZERO_ADDRESS");
		require(_addressRegistry != address(0), "ZERO_ADDRESS");

		__Context_init_unchained();
		__Ownable_init_unchained();
		__Pausable_init_unchained();
		__ERC20_init_unchained(_name, _symbol);
		weth = IWETH(IAddressRegistry(_addressRegistry).weth());

		setRebalancer(_rebalancer);
		manager = _manager;
		withheldLiquidity = 0;
	}

	function registerBurner(address burner, bool allowedBurner) external override onlyOwner {
		require(burner != address(0), "INVALID_ADDRESS");
		registeredBurners[burner] = allowedBurner;

		emit BurnerRegistered(burner, allowedBurner);
	}

	function setRebalancer(address _rebalancer) public override onlyOwner {
		require(_rebalancer != address(0), "ZERO_ADDRESS");
		rebalancer = _rebalancer;

		emit RebalancerSet(_rebalancer);
	}

	function deposit(uint256 amount) external payable override whenNotPaused {
		_deposit(msg.sender, msg.sender, amount, msg.value);
	}

	function depositFor(address account, uint256 amount) external payable override whenNotPaused {
		_deposit(msg.sender, account, amount, msg.value);
	}

	function underlyer() external view override returns (address) {
		return address(weth);
	}

	/// @dev References the WithdrawalInfo for how much the user is permitted to withdraw
	/// @dev No withdrawal permitted unless currentCycle >= minCycle
	/// @dev Decrements withheldLiquidity by the withdrawn amount
	function withdraw(uint256 requestedAmount, bool asEth) external override whenNotPaused nonReentrant {
		require(requestedAmount <= requestedWithdrawals[msg.sender].amount, "WITHDRAW_INSUFFICIENT_BALANCE");
		require(requestedAmount > 0, "NO_WITHDRAWAL");
		require(weth.balanceOf(address(this)) >= requestedAmount, "INSUFFICIENT_POOL_BALANCE");

		require(requestedWithdrawals[msg.sender].minCycle <= manager.getCurrentCycleIndex(), "INVALID_CYCLE");

		requestedWithdrawals[msg.sender].amount = requestedWithdrawals[msg.sender].amount.sub(requestedAmount);

		// Delete if all assets withdrawn
		if (requestedWithdrawals[msg.sender].amount == 0) {
			delete requestedWithdrawals[msg.sender];
		}

		withheldLiquidity = withheldLiquidity.sub(requestedAmount);
		_burn(msg.sender, requestedAmount);

		bytes32 eventSig = "Withdraw";
		encodeAndSendData(eventSig, msg.sender);

		if (asEth) {
			// Convert to eth
			weth.withdraw(requestedAmount);
			msg.sender.sendValue(requestedAmount);
		} else {
			// Send as WETH
			IERC20(weth).safeTransfer(msg.sender, requestedAmount);
		}
	}

	/// @dev Adjusts the withheldLiquidity as necessary
	/// @dev Updates the WithdrawalInfo for when a user can withdraw and for what requested amount
	function requestWithdrawal(uint256 amount) external override {
		require(amount > 0, "INVALID_AMOUNT");
		require(amount <= balanceOf(msg.sender), "INSUFFICIENT_BALANCE");

		//adjust withheld liquidity by removing the original withheld amount and adding the new amount
		withheldLiquidity = withheldLiquidity.sub(requestedWithdrawals[msg.sender].amount).add(amount);
		requestedWithdrawals[msg.sender].amount = amount;
		if (manager.getRolloverStatus()) {
			// If manager is in the middle of a cycle rollover, add two cycles
			requestedWithdrawals[msg.sender].minCycle = manager.getCurrentCycleIndex().add(2);
		} else {
			// If the manager is not in the middle of a rollover, add one cycle
			requestedWithdrawals[msg.sender].minCycle = manager.getCurrentCycleIndex().add(1);
		}

		emit WithdrawalRequested(msg.sender, amount);
	}

	function preTransferAdjustWithheldLiquidity(address sender, uint256 amount) internal {
		if (requestedWithdrawals[sender].amount > 0) {
			//reduce requested withdraw amount by transferred amount;
			uint256 newRequestedWithdrawl = requestedWithdrawals[sender].amount.sub(
				Math.min(amount, requestedWithdrawals[sender].amount)
			);

			//subtract from global withheld liquidity (reduce) by removing the delta of (requestedAmount - newRequestedAmount)
			withheldLiquidity = withheldLiquidity.sub(requestedWithdrawals[sender].amount.sub(newRequestedWithdrawl));

			//update the requested withdraw for user
			requestedWithdrawals[sender].amount = newRequestedWithdrawl;

			//if the withdraw request is 0, empty it out
			if (requestedWithdrawals[sender].amount == 0) {
				delete requestedWithdrawals[sender];
			}
		}
	}

	function approveManager(uint256 amount) external override onlyOwner {
		approve(amount, address(manager));
	}

	function approveRebalancer(uint256 amount) external override onlyOwner {
		require(rebalancer != address(0), "ZERO_ADDRESS");
		approve(amount, rebalancer);
	}

	/// @dev Adjust withheldLiquidity and requestedWithdrawal if sender does not have sufficient unlocked balance for the transfer
	function transfer(address recipient, uint256 amount) public override whenNotPaused nonReentrant returns (bool) {
		preTransferAdjustWithheldLiquidity(msg.sender, amount);
		bool success = super.transfer(recipient, amount);

		bytes32 eventSig = "Transfer";
		encodeAndSendData(eventSig, msg.sender);
		encodeAndSendData(eventSig, recipient);

		return success;
	}

	/// @dev Adjust withheldLiquidity and requestedWithdrawal if sender does not have sufficient unlocked balance for the transfer
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public override whenNotPaused nonReentrant returns (bool) {
		preTransferAdjustWithheldLiquidity(sender, amount);
		bool success = super.transferFrom(sender, recipient, amount);

		bytes32 eventSig = "Transfer";
		encodeAndSendData(eventSig, sender);
		encodeAndSendData(eventSig, recipient);

		return success;
	}

	function controlledBurn(uint256 amount, address account) external override onlyRegisteredBurner whenNotPaused {
		require(account != address(0), "INVALID_ADDRESS");
		require(amount > 0, "INVALID_AMOUNT");
		if (account != msg.sender) {
			uint256 currentAllowance = allowance(account, msg.sender);
			require(currentAllowance >= amount, "INSUFFICIENT_ALLOWANCE");
			_approve(account, msg.sender, currentAllowance.sub(amount));
		}

		// Updating withdrawal requests only if currentBalance - burn amount is
		// Less than requested withdrawal
		uint256 requestedAmount = requestedWithdrawals[account].amount;
		uint256 balance = balanceOf(account);
		require(amount <= balance, "INSUFFICIENT_BALANCE");
		uint256 currentBalance = balance.sub(amount);
		if (requestedAmount > currentBalance) {
			if (currentBalance == 0) {
				delete requestedWithdrawals[account];
				withheldLiquidity = withheldLiquidity.sub(requestedAmount);
			} else {
				requestedWithdrawals[account].amount = currentBalance;
				withheldLiquidity = withheldLiquidity.sub(requestedAmount.sub(currentBalance));
			}
		}

		_burn(account, amount);

		emit Burned(account, msg.sender, amount);
	}

	function pause() external override onlyOwner {
		_pause();
	}

	function unpause() external override onlyOwner {
		_unpause();
	}

	function setDestinations(address _fxStateSender, address _destinationOnL2) external override onlyOwner {
		require(_fxStateSender != address(0), "INVALID_ADDRESS");
		require(_destinationOnL2 != address(0), "INVALID_ADDRESS");

		destinations.fxStateSender = IFxStateSender(_fxStateSender);
		destinations.destinationOnL2 = _destinationOnL2;

		emit DestinationsSet(_fxStateSender, _destinationOnL2);
	}

	function setEventSend(bool _eventSendSet) external override onlyOwner {
		require(destinations.destinationOnL2 != address(0), "DESTINATIONS_NOT_SET");

		_eventSend = _eventSendSet;

		emit EventSendSet(_eventSendSet);
	}

	function _deposit(address fromAccount, address toAccount, uint256 amount, uint256 msgValue) internal {
		require(amount > 0, "INVALID_AMOUNT");
		require(toAccount != address(0), "INVALID_ADDRESS");

		_mint(toAccount, amount);
		if (msgValue > 0) {
			// If ether get weth
			require(msgValue == amount, "AMT_VALUE_MISMATCH");
			weth.deposit{ value: amount }();
		} else {
			// Else go ahead and transfer weth from account to pool
			IERC20(weth).safeTransferFrom(fromAccount, address(this), amount);
		}

		bytes32 eventSig = "Deposit";
		encodeAndSendData(eventSig, toAccount);
	}

	function encodeAndSendData(bytes32 _eventSig, address _user) private onEventSend {
		require(address(destinations.fxStateSender) != address(0), "ADDRESS_NOT_SET");
		require(destinations.destinationOnL2 != address(0), "ADDRESS_NOT_SET");

		uint256 userBalance = balanceOf(_user);
		bytes memory data = abi.encode(
			BalanceUpdateEvent({ eventSig: _eventSig, account: _user, token: address(this), amount: userBalance })
		);

		destinations.fxStateSender.sendMessageToChild(destinations.destinationOnL2, data);
	}

	function approve(uint256 amount, address approvee) private {
		uint256 currentAllowance = IERC20(weth).allowance(address(this), approvee);
		if (currentAllowance < amount) {
			uint256 delta = amount.sub(currentAllowance);
			IERC20(weth).safeIncreaseAllowance(approvee, delta);
		} else {
			uint256 delta = currentAllowance.sub(amount);
			IERC20(weth).safeDecreaseAllowance(approvee, delta);
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/IManager.sol";
import "../interfaces/ILiquidityPool.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import { EnumerableSetUpgradeable as EnumerableSet } from "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import { SafeMathUpgradeable as SafeMath } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { AccessControlUpgradeable as AccessControl } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../interfaces/events/Destinations.sol";
import "../interfaces/events/CycleRolloverEvent.sol";
import "../interfaces/events/IEventSender.sol";

//solhint-disable not-rely-on-time
//solhint-disable var-name-mixedcase
contract Manager is IManager, Initializable, AccessControl, IEventSender {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	using Address for address;
	using EnumerableSet for EnumerableSet.AddressSet;
	using EnumerableSet for EnumerableSet.Bytes32Set;

	bytes32 public immutable ADMIN_ROLE = keccak256("ADMIN_ROLE");
	bytes32 public immutable ROLLOVER_ROLE = keccak256("ROLLOVER_ROLE");
	bytes32 public immutable MID_CYCLE_ROLE = keccak256("MID_CYCLE_ROLE");
	bytes32 public immutable START_ROLLOVER_ROLE = keccak256("START_ROLLOVER_ROLE");
	bytes32 public immutable ADD_LIQUIDITY_ROLE = keccak256("ADD_LIQUIDITY_ROLE");
	bytes32 public immutable REMOVE_LIQUIDITY_ROLE = keccak256("REMOVE_LIQUIDITY_ROLE");
	bytes32 public immutable MISC_OPERATION_ROLE = keccak256("MISC_OPERATION_ROLE");

	uint256 public currentCycle; // Start timestamp of current cycle
	uint256 public currentCycleIndex; // Uint representing current cycle
	uint256 public cycleDuration; // Cycle duration in seconds

	bool public rolloverStarted;

	// Bytes32 controller id => controller address
	mapping(bytes32 => address) public registeredControllers;
	// Cycle index => ipfs rewards hash
	mapping(uint256 => string) public override cycleRewardsHashes;
	EnumerableSet.AddressSet private pools;
	EnumerableSet.Bytes32Set private controllerIds;

	// Reentrancy Guard
	bool private _entered;

	bool public _eventSend;
	Destinations public destinations;

	uint256 public nextCycleStartTime;

	bool private isLogicContract;

	modifier onlyAdmin() {
		require(hasRole(ADMIN_ROLE, _msgSender()), "NOT_ADMIN_ROLE");
		_;
	}

	modifier onlyRollover() {
		require(hasRole(ROLLOVER_ROLE, _msgSender()), "NOT_ROLLOVER_ROLE");
		_;
	}

	modifier onlyMidCycle() {
		require(hasRole(MID_CYCLE_ROLE, _msgSender()), "NOT_MID_CYCLE_ROLE");
		_;
	}

	modifier nonReentrant() {
		require(!_entered, "ReentrancyGuard: reentrant call");
		_entered = true;
		_;
		_entered = false;
	}

	modifier onEventSend() {
		if (_eventSend) {
			_;
		}
	}

	modifier onlyStartRollover() {
		require(hasRole(START_ROLLOVER_ROLE, _msgSender()), "NOT_START_ROLLOVER_ROLE");
		_;
	}

	constructor() public {
		isLogicContract = true;
	}

	function initialize(uint256 _cycleDuration, uint256 _nextCycleStartTime) public initializer {
		__Context_init_unchained();
		__AccessControl_init_unchained();

		cycleDuration = _cycleDuration;

		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

		_setupRole(ADMIN_ROLE, _msgSender());
		_setupRole(ROLLOVER_ROLE, _msgSender());
		_setupRole(MID_CYCLE_ROLE, _msgSender());
		_setupRole(START_ROLLOVER_ROLE, _msgSender());
		_setupRole(ADD_LIQUIDITY_ROLE, _msgSender());
		_setupRole(REMOVE_LIQUIDITY_ROLE, _msgSender());
		_setupRole(MISC_OPERATION_ROLE, _msgSender());

		setNextCycleStartTime(_nextCycleStartTime);
	}

	function registerController(bytes32 id, address controller) external override onlyAdmin {
		registeredControllers[id] = controller;
		require(controllerIds.add(id), "ADD_FAIL");
		emit ControllerRegistered(id, controller);
	}

	function unRegisterController(bytes32 id) external override onlyAdmin {
		emit ControllerUnregistered(id, registeredControllers[id]);
		delete registeredControllers[id];
		require(controllerIds.remove(id), "REMOVE_FAIL");
	}

	function registerPool(address pool) external override onlyAdmin {
		require(pools.add(pool), "ADD_FAIL");
		emit PoolRegistered(pool);
	}

	function unRegisterPool(address pool) external override onlyAdmin {
		require(pools.remove(pool), "REMOVE_FAIL");
		emit PoolUnregistered(pool);
	}

	function setCycleDuration(uint256 duration) external override onlyAdmin {
		require(duration > 60, "CYCLE_TOO_SHORT");
		cycleDuration = duration;
		emit CycleDurationSet(duration);
	}

	function setNextCycleStartTime(uint256 _nextCycleStartTime) public override onlyAdmin {
		// We are aware of the possibility of timestamp manipulation.  It does not pose any
		// risk based on the design of our system
		require(_nextCycleStartTime > block.timestamp, "MUST_BE_FUTURE");
		nextCycleStartTime = _nextCycleStartTime;
		emit NextCycleStartSet(_nextCycleStartTime);
	}

	function getPools() external view override returns (address[] memory) {
		uint256 poolsLength = pools.length();
		address[] memory returnData = new address[](poolsLength);
		for (uint256 i = 0; i < poolsLength; ++i) {
			returnData[i] = pools.at(i);
		}
		return returnData;
	}

	function getControllers() external view override returns (bytes32[] memory) {
		uint256 controllerIdsLength = controllerIds.length();
		bytes32[] memory returnData = new bytes32[](controllerIdsLength);
		for (uint256 i = 0; i < controllerIdsLength; ++i) {
			returnData[i] = controllerIds.at(i);
		}
		return returnData;
	}

	function completeRollover(string calldata rewardsIpfsHash) external override onlyRollover {
		// Can't be hit via test cases, going to leave in anyways in case we ever change code
		require(nextCycleStartTime > 0, "SET_BEFORE_ROLLOVER");
		// We are aware of the possibility of timestamp manipulation.  It does not pose any
		// risk based on the design of our system
		require(block.timestamp > nextCycleStartTime, "PREMATURE_EXECUTION");
		_completeRollover(rewardsIpfsHash);
	}

	/// @notice Used for mid-cycle adjustments
	function executeMaintenance(MaintenanceExecution calldata params) external override onlyMidCycle nonReentrant {
		for (uint256 x = 0; x < params.cycleSteps.length; ++x) {
			_executeControllerCommand(params.cycleSteps[x]);
		}
	}

	function executeRollover(RolloverExecution calldata params) external override onlyRollover nonReentrant {
		// We are aware of the possibility of timestamp manipulation.  It does not pose any
		// risk based on the design of our system
		require(block.timestamp > nextCycleStartTime, "PREMATURE_EXECUTION");

		// Transfer deployable liquidity out of the pools and into the manager
		for (uint256 i = 0; i < params.poolData.length; ++i) {
			require(pools.contains(params.poolData[i].pool), "INVALID_POOL");
			ILiquidityPool pool = ILiquidityPool(params.poolData[i].pool);
			IERC20 underlyingToken = pool.underlyer();
			underlyingToken.safeTransferFrom(address(pool), address(this), params.poolData[i].amount);
			emit LiquidityMovedToManager(params.poolData[i].pool, params.poolData[i].amount);
		}

		// Deploy or withdraw liquidity
		for (uint256 x = 0; x < params.cycleSteps.length; ++x) {
			_executeControllerCommand(params.cycleSteps[x]);
		}

		// Transfer recovered liquidity back into the pools; leave no funds in the manager
		for (uint256 y = 0; y < params.poolsForWithdraw.length; ++y) {
			require(pools.contains(params.poolsForWithdraw[y]), "INVALID_POOL");
			ILiquidityPool pool = ILiquidityPool(params.poolsForWithdraw[y]);
			IERC20 underlyingToken = pool.underlyer();

			uint256 managerBalance = underlyingToken.balanceOf(address(this));

			// transfer funds back to the pool if there are funds
			if (managerBalance > 0) {
				underlyingToken.safeTransfer(address(pool), managerBalance);
			}
			emit LiquidityMovedToPool(params.poolsForWithdraw[y], managerBalance);
		}

		if (params.complete) {
			_completeRollover(params.rewardsIpfsHash);
		}
	}

	function sweep(address[] calldata poolAddresses) external override onlyRollover {
		uint256 length = poolAddresses.length;
		uint256[] memory amounts = new uint256[](length);

		for (uint256 i = 0; i < length; ++i) {
			address currentPoolAddress = poolAddresses[i];
			require(pools.contains(currentPoolAddress), "INVALID_ADDRESS");
			IERC20 underlyer = IERC20(ILiquidityPool(currentPoolAddress).underlyer());
			uint256 amount = underlyer.balanceOf(address(this));
			amounts[i] = amount;

			if (amount > 0) {
				underlyer.safeTransfer(currentPoolAddress, amount);
			}
		}
		emit ManagerSwept(poolAddresses, amounts);
	}

	function _executeControllerCommand(ControllerTransferData calldata transfer) private {
		require(!isLogicContract, "FORBIDDEN_CALL");

		address controllerAddress = registeredControllers[transfer.controllerId];
		require(controllerAddress != address(0), "INVALID_CONTROLLER");
		controllerAddress.functionDelegateCall(transfer.data, "CYCLE_STEP_EXECUTE_FAILED");
		emit DeploymentStepExecuted(transfer.controllerId, controllerAddress, transfer.data);
	}

	function startCycleRollover() external override onlyStartRollover {
		// We are aware of the possibility of timestamp manipulation.  It does not pose any
		// risk based on the design of our system
		require(block.timestamp > nextCycleStartTime, "PREMATURE_EXECUTION");
		rolloverStarted = true;

		bytes32 eventSig = "Cycle Rollover Start";
		encodeAndSendData(eventSig);

		emit CycleRolloverStarted(block.timestamp);
	}

	function _completeRollover(string calldata rewardsIpfsHash) private {
		currentCycle = nextCycleStartTime;
		nextCycleStartTime = nextCycleStartTime.add(cycleDuration);
		cycleRewardsHashes[currentCycleIndex] = rewardsIpfsHash;
		currentCycleIndex = currentCycleIndex.add(1);
		rolloverStarted = false;

		bytes32 eventSig = "Cycle Complete";
		encodeAndSendData(eventSig);

		emit CycleRolloverComplete(block.timestamp);
	}

	function getCurrentCycle() external view override returns (uint256) {
		return currentCycle;
	}

	function getCycleDuration() external view override returns (uint256) {
		return cycleDuration;
	}

	function getCurrentCycleIndex() external view override returns (uint256) {
		return currentCycleIndex;
	}

	function getRolloverStatus() external view override returns (bool) {
		return rolloverStarted;
	}

	function setDestinations(address _fxStateSender, address _destinationOnL2) external override onlyAdmin {
		require(_fxStateSender != address(0), "INVALID_ADDRESS");
		require(_destinationOnL2 != address(0), "INVALID_ADDRESS");

		destinations.fxStateSender = IFxStateSender(_fxStateSender);
		destinations.destinationOnL2 = _destinationOnL2;

		emit DestinationsSet(_fxStateSender, _destinationOnL2);
	}

	function setEventSend(bool _eventSendSet) external override onlyAdmin {
		require(destinations.destinationOnL2 != address(0), "DESTINATIONS_NOT_SET");

		_eventSend = _eventSendSet;

		emit EventSendSet(_eventSendSet);
	}

	function setupRole(bytes32 role) external override onlyAdmin {
		_setupRole(role, _msgSender());
	}

	function encodeAndSendData(bytes32 _eventSig) private onEventSend {
		require(address(destinations.fxStateSender) != address(0), "ADDRESS_NOT_SET");
		require(destinations.destinationOnL2 != address(0), "ADDRESS_NOT_SET");

		bytes memory data = abi.encode(
			CycleRolloverEvent({ eventSig: _eventSig, cycleIndex: currentCycleIndex, timestamp: currentCycle })
		);

		destinations.fxStateSender.sendMessageToChild(destinations.destinationOnL2, data);
	}

	// solhint-disable-next-line no-empty-blocks
	receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/// @notice Event sent to Governance layer when a cycle rollover is complete
struct CycleRolloverEvent {
	bytes32 eventSig;
	uint256 cycleIndex;
	uint256 timestamp;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/IAddressRegistry.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import { SafeMathUpgradeable as SafeMath } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { EnumerableSetUpgradeable as EnumerableSet } from "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import { AccessControlUpgradeable as AccessControl } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract AddressRegistry is IAddressRegistry, Initializable, AccessControl {
	using SafeMath for uint256;
	using EnumerableSet for EnumerableSet.AddressSet;

	mapping(AddressTypes => EnumerableSet.AddressSet) private addressSets;

	// solhint-disable-next-line var-name-mixedcase
	bytes32 public immutable REGISTERED_ADDRESS = keccak256("REGISTERED_ROLE");

	address public immutable override weth;

	modifier onlyRegistered() {
		require(hasRole(REGISTERED_ADDRESS, msg.sender), "NOT_REGISTERED");
		_;
	}

	//@custom:oz-upgrades-unsafe-allow constructor
	//solhint-disable-next-line no-empty-blocks
	constructor(address wethAddress) public initializer {
		require(wethAddress != address(0), "INVALID_ADDRESS");

		weth = wethAddress;
	}

	function initialize() public initializer {
		__Context_init_unchained();
		__AccessControl_init_unchained();

		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setupRole(REGISTERED_ADDRESS, _msgSender());
	}

	function addRegistrar(address _addr) external override {
		require(_addr != address(0), "INVALID_ADDRESS");
		grantRole(REGISTERED_ADDRESS, _addr);

		emit RegisteredAddressAdded(_addr);
	}

	function removeRegistrar(address _addr) external override {
		require(_addr != address(0), "INVALID_ADDRESS");
		revokeRole(REGISTERED_ADDRESS, _addr);

		emit RegisteredAddressRemoved(_addr);
	}

	function addToRegistry(address[] calldata _addresses, AddressTypes _index) external override onlyRegistered {
		uint256 arrayLength = _addresses.length;
		require(arrayLength > 0, "NO_ADDRESSES");
		EnumerableSet.AddressSet storage structToAddTo = addressSets[_index];

		for (uint256 i = 0; i < arrayLength; ++i) {
			require(_addresses[i] != address(0), "INVALID_ADDRESS");
			require(structToAddTo.add(_addresses[i]), "ADD_FAIL");
		}

		emit AddedToRegistry(_addresses, _index);
	}

	function removeFromRegistry(address[] calldata _addresses, AddressTypes _index) external override onlyRegistered {
		EnumerableSet.AddressSet storage structToRemoveFrom = addressSets[_index];
		uint256 arrayLength = _addresses.length;
		require(arrayLength > 0, "NO_ADDRESSES");
		require(arrayLength <= structToRemoveFrom.length(), "TOO_MANY_ADDRESSES");

		for (uint256 i = 0; i < arrayLength; ++i) {
			address currentAddress = _addresses[i];
			require(structToRemoveFrom.remove(currentAddress), "REMOVE_FAIL");
		}

		emit RemovedFromRegistry(_addresses, _index);
	}

	function getAddressForType(AddressTypes _index) external view override returns (address[] memory) {
		EnumerableSet.AddressSet storage structToReturn = addressSets[_index];
		uint256 arrayLength = structToReturn.length();

		address[] memory registryAddresses = new address[](arrayLength);
		for (uint256 i = 0; i < arrayLength; ++i) {
			registryAddresses[i] = structToReturn.at(i);
		}
		return registryAddresses;
	}

	function checkAddress(address _addr, uint256 _index) external view override returns (bool) {
		EnumerableSet.AddressSet storage structToCheck = addressSets[AddressTypes(_index)];
		return structToCheck.contains(_addr);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/IDelegateFunction.sol";
import "../interfaces/events/EventSender.sol";
import "../interfaces/events/DelegationDisabled.sol";
import "../interfaces/events/DelegationEnabled.sol";
import "../interfaces/IERC1271.sol";

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

// solhint-disable var-name-mixedcase
contract DelegateFunction is IDelegateFunction, Initializable, OwnableUpgradeable, PausableUpgradeable, EventSender {
	using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
	using SafeMathUpgradeable for uint256;
	using ECDSA for bytes32;

	bytes4 public constant EIP1271_MAGICVALUE = 0x1626ba7e;

	string public constant EIP191_HEADER = "\x19\x01";

	bytes32 public immutable EIP712_DOMAIN_TYPEHASH =
		keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

	bytes32 public immutable DELEGATE_PAYLOAD_TYPEHASH =
		keccak256(
			"DelegatePayload(uint256 nonce,DelegateMap[] sets)DelegateMap(bytes32 functionId,address otherParty,bool mustRelinquish)"
		);

	bytes32 public immutable DELEGATE_MAP_TYPEHASH =
		keccak256("DelegateMap(bytes32 functionId,address otherParty,bool mustRelinquish)");

	bytes32 public immutable FUNCTIONS_LIST_PAYLOAD_TYPEHASH =
		keccak256("FunctionsListPayload(uint256 nonce,bytes32[] sets)");

	/* solhint-disable var-name-mixedcase */
	// Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
	// invalidate the cached domain separator if the chain id changes.
	bytes32 private CACHED_EIP712_DOMAIN_SEPARATOR;
	uint256 private CACHED_CHAIN_ID;

	bytes32 public constant DOMAIN_NAME = keccak256("Tokemak Delegate Function");
	bytes32 public constant DOMAIN_VERSION = keccak256("1");

	/// @dev Stores the users next valid vote nonce
	mapping(address => uint256) public override contractWalletNonces;

	EnumerableSetUpgradeable.Bytes32Set private allowedFunctions;

	//from => functionId => (otherParty, mustRelinquish, functionId)
	mapping(address => mapping(bytes32 => Destination)) private delegations;

	// account => functionId => number of delegations
	mapping(address => mapping(bytes32 => uint256)) public numDelegationsTo;

	function initialize() public initializer {
		__Context_init_unchained();
		__Ownable_init_unchained();
		__Pausable_init_unchained();

		CACHED_CHAIN_ID = _getChainID();
		CACHED_EIP712_DOMAIN_SEPARATOR = _buildDomainSeparator();
	}

	function getDelegations(address from) external view override returns (DelegateMapView[] memory maps) {
		uint256 numOfFunctions = allowedFunctions.length();
		maps = new DelegateMapView[](numOfFunctions);
		for (uint256 ix = 0; ix < numOfFunctions; ++ix) {
			bytes32 functionId = allowedFunctions.at(ix);
			Destination memory existingDestination = delegations[from][functionId];
			if (existingDestination.otherParty != address(0)) {
				maps[ix] = DelegateMapView({
					functionId: functionId,
					otherParty: existingDestination.otherParty,
					mustRelinquish: existingDestination.mustRelinquish,
					pending: existingDestination.pending
				});
			}
		}
	}

	function getDelegation(
		address from,
		bytes32 functionId
	) external view override returns (DelegateMapView memory map) {
		Destination memory existingDestination = delegations[from][functionId];
		map = DelegateMapView({
			functionId: functionId,
			otherParty: existingDestination.otherParty,
			mustRelinquish: existingDestination.mustRelinquish,
			pending: existingDestination.pending
		});
	}

	function pause() external override onlyOwner {
		_pause();
	}

	function unpause() external override onlyOwner {
		_unpause();
	}

	function delegate(DelegateMap[] memory sets) external override whenNotPaused {
		_delegate(msg.sender, sets);
	}

	function delegateWithEIP1271(
		address contractAddress,
		DelegatePayload memory delegatePayload,
		bytes memory signature,
		SignatureType signatureType
	) external override whenNotPaused {
		bytes32 delegatePayloadHash = _hashDelegate(delegatePayload, signatureType);
		_verifyNonce(contractAddress, delegatePayload.nonce);

		_verifyIERC1271Signature(contractAddress, delegatePayloadHash, signature);

		_delegate(contractAddress, delegatePayload.sets);
	}

	function acceptDelegation(DelegatedTo[] calldata incoming) external override whenNotPaused {
		_acceptDelegation(msg.sender, incoming);
	}

	function acceptDelegationOnBehalfOf(
		address[] calldata froms,
		DelegatedTo[][] calldata incomings
	) external onlyOwner whenNotPaused {
		uint256 length = froms.length;
		require(length > 0, "NO_RECORDS");
		require(length == incomings.length, "LENGTH_MISMATCH");

		for (uint256 i = 0; i < length; ++i) {
			_acceptDelegation(froms[i], incomings[i]);
		}
	}

	function removeDelegationWithEIP1271(
		address contractAddress,
		FunctionsListPayload calldata functionsListPayload,
		bytes memory signature,
		SignatureType signatureType
	) external override whenNotPaused {
		bytes32 functionsListPayloadHash = _hashFunctionsList(functionsListPayload, signatureType);

		_verifyNonce(contractAddress, functionsListPayload.nonce);

		_verifyIERC1271Signature(contractAddress, functionsListPayloadHash, signature);

		_removeDelegations(contractAddress, functionsListPayload.sets);
	}

	function removeDelegation(bytes32[] calldata functionIds) external override whenNotPaused {
		_removeDelegations(msg.sender, functionIds);
	}

	function rejectDelegation(DelegatedTo[] calldata rejections) external override whenNotPaused {
		uint256 length = rejections.length;
		require(length > 0, "NO_DATA");

		for (uint256 ix = 0; ix < length; ++ix) {
			DelegatedTo memory pending = rejections[ix];
			_rejectDelegation(msg.sender, pending);
		}
	}

	function relinquishDelegation(DelegatedTo[] calldata relinquish) external override whenNotPaused {
		uint256 length = relinquish.length;
		require(length > 0, "NO_DATA");

		for (uint256 ix = 0; ix < length; ++ix) {
			_relinquishDelegation(msg.sender, relinquish[ix]);
		}
	}

	function cancelPendingDelegation(bytes32[] calldata functionIds) external override whenNotPaused {
		_cancelPendingDelegations(msg.sender, functionIds);
	}

	function cancelPendingDelegationWithEIP1271(
		address contractAddress,
		FunctionsListPayload calldata functionsListPayload,
		bytes memory signature,
		SignatureType signatureType
	) external override whenNotPaused {
		bytes32 functionsListPayloadHash = _hashFunctionsList(functionsListPayload, signatureType);

		_verifyNonce(contractAddress, functionsListPayload.nonce);

		_verifyIERC1271Signature(contractAddress, functionsListPayloadHash, signature);

		_cancelPendingDelegations(contractAddress, functionsListPayload.sets);
	}

	function setAllowedFunctions(AllowedFunctionSet[] calldata functions) external override onlyOwner {
		uint256 length = functions.length;
		require(functions.length > 0, "NO_DATA");

		for (uint256 ix = 0; ix < length; ++ix) {
			require(allowedFunctions.add(functions[ix].id), "ADD_FAIL");
		}

		emit AllowedFunctionsSet(functions);
	}

	function canControlEventSend() internal view override returns (bool) {
		return msg.sender == owner();
	}

	function _acceptDelegation(address delegatee, DelegatedTo[] calldata incoming) private {
		uint256 length = incoming.length;
		require(length > 0, "NO_DATA");
		require(delegatee != address(0), "INVALID_ADDRESS");

		for (uint256 ix = 0; ix < length; ++ix) {
			DelegatedTo calldata deleg = incoming[ix];
			Destination storage destination = delegations[deleg.originalParty][deleg.functionId];
			require(destination.otherParty == delegatee, "NOT_ASSIGNED");
			require(destination.pending, "ALREADY_ACCEPTED");
			require(delegations[delegatee][deleg.functionId].otherParty == address(0), "ALREADY_DELEGATOR");

			destination.pending = false;
			numDelegationsTo[destination.otherParty][deleg.functionId] = numDelegationsTo[destination.otherParty][
				deleg.functionId
			].add(1);

			bytes memory data = abi.encode(
				DelegationEnabled({
					eventSig: "DelegationEnabled",
					from: deleg.originalParty,
					to: delegatee,
					functionId: deleg.functionId
				})
			);

			sendEvent(data);

			emit DelegationAccepted(deleg.originalParty, delegatee, deleg.functionId, destination.mustRelinquish);
		}
	}

	function _delegate(address from, DelegateMap[] memory sets) internal {
		uint256 length = sets.length;
		require(length > 0, "NO_DATA");

		for (uint256 ix = 0; ix < length; ++ix) {
			DelegateMap memory set = sets[ix];

			require(allowedFunctions.contains(set.functionId), "INVALID_FUNCTION");
			require(set.otherParty != address(0), "INVALID_DESTINATION");
			require(set.otherParty != from, "NO_SELF");
			require(numDelegationsTo[from][set.functionId] == 0, "ALREADY_DELEGATEE");

			//Remove any existing delegation
			Destination memory existingDestination = delegations[from][set.functionId];
			if (existingDestination.otherParty != address(0)) {
				_removeDelegation(from, set.functionId, existingDestination);
			}

			delegations[from][set.functionId] = Destination({
				otherParty: set.otherParty,
				mustRelinquish: set.mustRelinquish,
				pending: true
			});

			emit PendingDelegationAdded(from, set.otherParty, set.functionId, set.mustRelinquish);
		}
	}

	function _rejectDelegation(address to, DelegatedTo memory pending) private {
		Destination memory existingDestination = delegations[pending.originalParty][pending.functionId];
		require(existingDestination.otherParty != address(0), "NOT_SETUP");
		require(existingDestination.otherParty == to, "NOT_OTHER_PARTIES");
		require(existingDestination.pending, "ALREADY_ACCEPTED");

		delete delegations[pending.originalParty][pending.functionId];

		emit DelegationRejected(pending.originalParty, to, pending.functionId, existingDestination.mustRelinquish);
	}

	function _removeDelegations(address from, bytes32[] calldata functionIds) private {
		uint256 length = functionIds.length;
		require(length > 0, "NO_DATA");

		for (uint256 ix = 0; ix < length; ++ix) {
			Destination memory existingDestination = delegations[from][functionIds[ix]];
			_removeDelegation(from, functionIds[ix], existingDestination);
		}
	}

	function _removeDelegation(address from, bytes32 functionId, Destination memory existingDestination) private {
		require(existingDestination.otherParty != address(0), "NOT_SETUP");
		require(!existingDestination.mustRelinquish, "EXISTING_MUST_RELINQUISH");

		delete delegations[from][functionId];

		if (existingDestination.pending) {
			emit PendingDelegationRemoved(
				from,
				existingDestination.otherParty,
				functionId,
				existingDestination.mustRelinquish
			);
		} else {
			numDelegationsTo[existingDestination.otherParty][functionId] = numDelegationsTo[
				existingDestination.otherParty
			][functionId].sub(1);
			_sendDisabledEvent(from, existingDestination.otherParty, functionId);

			emit DelegationRemoved(
				from,
				existingDestination.otherParty,
				functionId,
				existingDestination.mustRelinquish
			);
		}
	}

	function _relinquishDelegation(address to, DelegatedTo calldata relinquish) private {
		Destination memory existingDestination = delegations[relinquish.originalParty][relinquish.functionId];
		require(existingDestination.otherParty != address(0), "NOT_SETUP");
		require(existingDestination.otherParty == to, "NOT_OTHER_PARTIES");
		require(!existingDestination.pending, "NOT_YET_ACCEPTED");

		numDelegationsTo[existingDestination.otherParty][relinquish.functionId] = numDelegationsTo[
			existingDestination.otherParty
		][relinquish.functionId].sub(1);
		delete delegations[relinquish.originalParty][relinquish.functionId];

		_sendDisabledEvent(relinquish.originalParty, to, relinquish.functionId);

		emit DelegationRelinquished(
			relinquish.originalParty,
			to,
			relinquish.functionId,
			existingDestination.mustRelinquish
		);
	}

	function _sendDisabledEvent(address from, address to, bytes32 functionId) private {
		bytes memory data = abi.encode(
			DelegationDisabled({ eventSig: "DelegationDisabled", from: from, to: to, functionId: functionId })
		);

		sendEvent(data);
	}

	function _cancelPendingDelegations(address from, bytes32[] calldata functionIds) private {
		uint256 length = functionIds.length;
		require(length > 0, "NO_DATA");

		for (uint256 ix = 0; ix < length; ++ix) {
			_cancelPendingDelegation(from, functionIds[ix]);
		}
	}

	function _cancelPendingDelegation(address from, bytes32 functionId) private {
		require(allowedFunctions.contains(functionId), "INVALID_FUNCTION");

		Destination memory existingDestination = delegations[from][functionId];
		require(existingDestination.otherParty != address(0), "NO_PENDING");
		require(existingDestination.pending, "NOT_PENDING");

		delete delegations[from][functionId];

		emit PendingDelegationRemoved(
			from,
			existingDestination.otherParty,
			functionId,
			existingDestination.mustRelinquish
		);
	}

	function _hashDelegate(
		DelegatePayload memory delegatePayload,
		SignatureType signatureType
	) private view returns (bytes32) {
		bytes32 x = keccak256(
			abi.encodePacked(EIP191_HEADER, _domainSeparatorV4(), _hashDelegatePayload(delegatePayload))
		);

		if (signatureType == SignatureType.ETHSIGN) {
			x = x.toEthSignedMessageHash();
		}

		return x;
	}

	function _hashDelegatePayload(DelegatePayload memory delegatePayload) private view returns (bytes32) {
		bytes32[] memory encodedSets = new bytes32[](delegatePayload.sets.length);
		for (uint256 ix = 0; ix < delegatePayload.sets.length; ++ix) {
			encodedSets[ix] = _hashDelegateMap(delegatePayload.sets[ix]);
		}

		return
			keccak256(
				abi.encode(DELEGATE_PAYLOAD_TYPEHASH, delegatePayload.nonce, keccak256(abi.encodePacked(encodedSets)))
			);
	}

	function _hashDelegateMap(DelegateMap memory delegateMap) private view returns (bytes32) {
		return
			keccak256(
				abi.encode(
					DELEGATE_MAP_TYPEHASH,
					delegateMap.functionId,
					delegateMap.otherParty,
					delegateMap.mustRelinquish
				)
			);
	}

	function _hashFunctionsList(
		FunctionsListPayload calldata functionsListPayload,
		SignatureType signatureType
	) private view returns (bytes32) {
		bytes32 x = keccak256(
			abi.encodePacked(
				EIP191_HEADER,
				_domainSeparatorV4(),
				keccak256(
					abi.encode(
						FUNCTIONS_LIST_PAYLOAD_TYPEHASH,
						functionsListPayload.nonce,
						keccak256(abi.encodePacked(functionsListPayload.sets))
					)
				)
			)
		);

		if (signatureType == SignatureType.ETHSIGN) {
			x = x.toEthSignedMessageHash();
		}

		return x;
	}

	function _verifyIERC1271Signature(
		address contractAddress,
		bytes32 payloadHash,
		bytes memory signature
	) private view {
		try IERC1271(contractAddress).isValidSignature(payloadHash, signature) returns (bytes4 result) {
			require(result == EIP1271_MAGICVALUE, "INVALID_SIGNATURE");
		} catch {
			revert("INVALID_SIGNATURE_VALIDATION");
		}
	}

	function _verifyNonce(address account, uint256 nonce) private {
		require(contractWalletNonces[account] == nonce, "INVALID_NONCE");
		// Ensure the message cannot be replayed
		contractWalletNonces[account] = nonce.add(1);
	}

	function _getChainID() private pure returns (uint256) {
		uint256 id;
		// solhint-disable-next-line no-inline-assembly
		assembly {
			id := chainid()
		}
		return id;
	}

	/**
	 * @dev Returns the domain separator for the current chain.
	 */
	function _domainSeparatorV4() internal view returns (bytes32) {
		if (_getChainID() == CACHED_CHAIN_ID) {
			return CACHED_EIP712_DOMAIN_SEPARATOR;
		} else {
			return _buildDomainSeparator();
		}
	}

	function _buildDomainSeparator() private view returns (bytes32) {
		return keccak256(abi.encode(EIP712_DOMAIN_TYPEHASH, DOMAIN_NAME, DOMAIN_VERSION, _getChainID(), address(this)));
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./Destinations.sol";
import "./IEventSender.sol";

/// @title Base contract for sending events to our Governance layer
abstract contract EventSender is IEventSender {
	bool public eventSend;
	Destinations public destinations;

	modifier onEventSend() {
		// Only send the event when enabled
		if (eventSend) {
			_;
		}
	}

	modifier onlyEventSendControl() {
		// Give the implementing contract control over permissioning
		require(canControlEventSend(), "CANNOT_CONTROL_EVENTS");
		_;
	}

	/// @notice Configure the Polygon state sender root and destination for messages sent
	/// @param fxStateSender Address of Polygon State Sender Root contract
	/// @param destinationOnL2 Destination address of events sent. Should be our Event Proxy
	function setDestinations(
		address fxStateSender,
		address destinationOnL2
	) external virtual override onlyEventSendControl {
		require(fxStateSender != address(0), "INVALID_FX_ADDRESS");
		require(destinationOnL2 != address(0), "INVALID_DESTINATION_ADDRESS");

		destinations.fxStateSender = IFxStateSender(fxStateSender);
		destinations.destinationOnL2 = destinationOnL2;

		emit DestinationsSet(fxStateSender, destinationOnL2);
	}

	/// @notice Enables or disables the sending of events
	function setEventSend(bool eventSendSet) external virtual override onlyEventSendControl {
		eventSend = eventSendSet;

		emit EventSendSet(eventSendSet);
	}

	/// @notice Determine permissions for controlling event sending
	/// @dev Should not revert, just return false
	function canControlEventSend() internal view virtual returns (bool);

	/// @notice Send event data to Governance layer
	function sendEvent(bytes memory data) internal virtual {
		require(address(destinations.fxStateSender) != address(0), "ADDRESS_NOT_SET");
		require(destinations.destinationOnL2 != address(0), "ADDRESS_NOT_SET");

		destinations.fxStateSender.sendMessageToChild(destinations.destinationOnL2, data);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/// @notice Event sent to Governance layer when a user has disabled their delegation for voting or rewards
struct DelegationDisabled {
	bytes32 eventSig;
	address from;
	address to;
	bytes32 functionId;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/// @notice Event sent to Governance layer when a user has enabled delegation for voting or rewards
struct DelegationEnabled {
	bytes32 eventSig;
	address from;
	address to;
	bytes32 functionId;
}

// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts v4.4.0 (interfaces/IERC1271.sol)

pragma solidity 0.6.11;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
	/**
	 * @dev Should return whether the signature provided is valid for the provided data
	 * @param hash      Hash of the data to be signed
	 * @param signature Signature byte array associated with _data
	 */
	function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

// Based on OpenZeppelin ERC1271WalletMock.sol
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/7f6a1666fac8ecff5dd467d0938069bc221ea9e0/contracts/mocks/ERC1271WalletMock.sol
pragma solidity 0.6.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IERC1271.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";

contract ERC1271WalletMock is Ownable, IERC1271 {
	constructor(address originalOwner) public {
		transferOwnership(originalOwner);
	}

	function isValidSignature(bytes32 hash, bytes memory signature) public view override returns (bytes4 magicValue) {
		return ECDSA.recover(hash, signature) == owner() ? this.isValidSignature.selector : bytes4(0);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

import "../interfaces/ILiquidityPool.sol";

interface IPCAPool {
	event PoolUpdated(address newPool);

	///@notice Allows an address to deposit for itself or on behalf of another address
	///@dev Mints pAsset at 1:1 ratio of asset deposited
	///@dev Sends assets deposited to Tokemak pool contract
	///@dev Can be paused
	///@param account Account to be deposited for
	///@param amount Amount of asset to be deposited
	function depositAsset(address account, uint256 amount) external;

	///@notice Allows an address to deposit Tokemak tAsset for itself or on behalf of another address
	///@dev Mints pAsset at 1:1 ratio
	///@dev Burns tAssets via controlledBurn() function in Tokemak reactor pool
	///@dev Can be paused
	///@param account Account to be deposited for
	///@param amount Amount of asset to be deposited
	function depositPoolAsset(address account, uint256 amount) external;

	///@notice Allows for updating of tokemak reactor pool
	///@dev old pool and new pool must have matching underlying tokens
	///@dev Restriced access - onlyOwner
	///@param newPool New pool to be registered
	function updatePool(ILiquidityPool newPool) external;

	///@notice Allows some pool functionalities to be paused
	///@dev Burn, deposit functionalities are currently pausable
	function pause() external;

	///@notice Allows some pool functionalities to be unpaused
	function unpause() external;
}

// SPDX-License-identifier: MIT
pragma solidity 0.6.11;

import "../interfaces/IPCAPool.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import { ERC20PausableUpgradeable as PauseableERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20PausableUpgradeable.sol";
import { ERC20Upgradeable as ERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { OwnableUpgradeable as Ownable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import { ReentrancyGuardUpgradeable as NonReentrant } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract PCAPool is IPCAPool, Initializable, Ownable, PauseableERC20, NonReentrant {
	using SafeERC20 for ERC20;

	ILiquidityPool public pool;
	ERC20 public underlyer;

	//@custom:oz-upgrades-unsafe-allow constructor
	//solhint-disable-next-line no-empty-blocks
	constructor() public initializer {}

	function initialize(ILiquidityPool _pool, string memory _name, string memory _symbol) external initializer {
		require(address(_pool) != address(0), "ZERO_ADDRESS");

		__Context_init_unchained();
		__Ownable_init_unchained();
		__Pausable_init_unchained();
		__ReentrancyGuard_init_unchained();
		__ERC20_init_unchained(_name, _symbol);
		__ERC20Pausable_init_unchained();

		pool = _pool;
		underlyer = pool.underlyer();
		require(address(underlyer) != address(0), "POOL_DNE");
	}

	function decimals() public view override returns (uint8) {
		return underlyer.decimals();
	}

	function depositAsset(address account, uint256 amount) external override whenNotPaused {
		require(account != address(0), "INVALID_ADDRESS");
		require(amount > 0, "INVALID_AMOUNT");
		_mint(account, amount);
		underlyer.safeTransferFrom(msg.sender, address(pool), amount);
	}

	function depositPoolAsset(address account, uint256 amount) external override whenNotPaused nonReentrant {
		require(account != address(0), "INVALID_ADDRESS");
		require(amount > 0, "INVALID_AMOUNT");
		_mint(account, amount);
		pool.controlledBurn(amount, msg.sender);
	}

	function updatePool(ILiquidityPool newPool) external override onlyOwner {
		address poolAddress = address(newPool);
		require(poolAddress != address(0), "INVALID_ADDRESS");
		require(address(newPool.underlyer()) == address(underlyer), "UNDERLYER_MISMATCH");
		pool = newPool;

		emit PoolUpdated(poolAddress);
	}

	function pause() external override onlyOwner {
		_pause();
	}

	function unpause() external override onlyOwner {
		_unpause();
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "../interfaces/IManager.sol";
import "../interfaces/ILiquidityPool.sol";
import "./BaseController.sol";

contract PoolTransferController is BaseController {
	using SafeERC20 for IERC20;

	/* solhint-disable no-empty-blocks */
	constructor(
		address manager,
		address accessControl,
		address registry
	) public BaseController(manager, accessControl, registry) {}

	/* solhint-enable no-empty-blocks */

	/// @notice transfers assets from Manager contract back to Pool contracts
	/// @param pools Array of pool addresses to be transferred to
	/// @param amounts Corresponding array of amounts to transfer to pools
	function transferToPool(
		address[] calldata pools,
		uint256[] calldata amounts
	) external onlyManager onlyMiscOperation {
		uint256 length = pools.length;
		require(length > 0, "NO_POOLS");
		require(length == amounts.length, "MISMATCH_ARRAY_LENGTH");
		for (uint256 i = 0; i < length; ++i) {
			address currentPoolAddress = pools[i];
			uint256 currentAmount = amounts[i];

			require(currentAmount != 0, "INVALID_AMOUNT");
			require(addressRegistry.checkAddress(currentPoolAddress, 2), "INVALID_POOL");

			ILiquidityPool pool = ILiquidityPool(currentPoolAddress);
			IERC20 token = IERC20(pool.underlyer());
			require(addressRegistry.checkAddress(address(token), 0), "INVALID_TOKEN");

			token.safeTransfer(currentPoolAddress, currentAmount);
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IDefiRound.sol";
import "../interfaces/IWETH.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

contract DefiRound is IDefiRound, Ownable {
	using SafeMath for uint256;
	using SafeCast for int256;
	using SafeERC20 for IERC20;
	using Address for address;
	using Address for address payable;
	using EnumerableSet for EnumerableSet.AddressSet;

	// solhint-disable-next-line
	address public immutable WETH;
	address public immutable override treasury;
	OversubscriptionRate public overSubscriptionRate;
	mapping(address => uint256) public override totalSupply;
	// account -> accountData
	mapping(address => AccountData) private accountData;
	mapping(address => RateData) private tokenRates;

	//Token -> oracle, genesis
	mapping(address => SupportedTokenData) private tokenSettings;

	EnumerableSet.AddressSet private supportedTokens;
	EnumerableSet.AddressSet private configuredTokenRates;
	STAGES public override currentStage;

	WhitelistSettings public whitelistSettings;
	uint256 public lastLookExpiration = type(uint256).max;
	uint256 private immutable maxTotalValue;
	bool private stage1Locked;

	constructor(
		// solhint-disable-next-line
		address _WETH,
		address _treasury,
		uint256 _maxTotalValue
	) public {
		require(_WETH != address(0), "INVALID_WETH");
		require(_treasury != address(0), "INVALID_TREASURY");
		require(_maxTotalValue > 0, "INVALID_MAXTOTAL");

		WETH = _WETH;
		treasury = _treasury;
		currentStage = STAGES.STAGE_1;

		maxTotalValue = _maxTotalValue;
	}

	function deposit(TokenData calldata tokenInfo, bytes32[] memory proof) external payable override {
		require(currentStage == STAGES.STAGE_1, "DEPOSITS_NOT_ACCEPTED");
		require(!stage1Locked, "DEPOSITS_LOCKED");

		if (whitelistSettings.enabled) {
			require(verifyDepositor(msg.sender, whitelistSettings.root, proof), "PROOF_INVALID");
		}

		TokenData memory data = tokenInfo;
		address token = data.token;
		uint256 tokenAmount = data.amount;
		require(supportedTokens.contains(token), "UNSUPPORTED_TOKEN");
		require(tokenAmount > 0, "INVALID_AMOUNT");

		// Convert ETH to WETH if ETH is passed in, otherwise treat WETH as a regular ERC20
		if (token == WETH && msg.value > 0) {
			require(tokenAmount == msg.value, "INVALID_MSG_VALUE");
			IWETH(WETH).deposit{ value: tokenAmount }();
		} else {
			require(msg.value == 0, "NO_ETH");
		}

		AccountData storage tokenAccountData = accountData[msg.sender];

		if (tokenAccountData.token == address(0)) {
			tokenAccountData.token = token;
		}

		require(tokenAccountData.token == token, "SINGLE_ASSET_DEPOSITS");

		tokenAccountData.initialDeposit = tokenAccountData.initialDeposit.add(tokenAmount);
		tokenAccountData.currentBalance = tokenAccountData.currentBalance.add(tokenAmount);

		require(tokenAccountData.currentBalance <= tokenSettings[token].maxLimit, "MAX_LIMIT_EXCEEDED");

		// No need to transfer from msg.sender since is ETH was converted to WETH
		if (!(token == WETH && msg.value > 0)) {
			IERC20(token).safeTransferFrom(msg.sender, address(this), tokenAmount);
		}

		if (_totalValue() > maxTotalValue) {
			stage1Locked = true;
		}

		emit Deposited(msg.sender, tokenInfo);
	}

	// solhint-disable-next-line no-empty-blocks
	receive() external payable {
		require(msg.sender == WETH);
	}

	function withdraw(TokenData calldata tokenInfo, bool asETH) external override {
		require(currentStage == STAGES.STAGE_2, "WITHDRAWS_NOT_ACCEPTED");
		require(!_isLastLookComplete(), "WITHDRAWS_EXPIRED");

		TokenData memory data = tokenInfo;
		address token = data.token;
		uint256 tokenAmount = data.amount;
		require(supportedTokens.contains(token), "UNSUPPORTED_TOKEN");
		require(tokenAmount > 0, "INVALID_AMOUNT");
		AccountData storage tokenAccountData = accountData[msg.sender];
		require(token == tokenAccountData.token, "INVALID_TOKEN");
		tokenAccountData.currentBalance = tokenAccountData.currentBalance.sub(tokenAmount);
		// set the data back in the mapping, otherwise updates are not saved
		accountData[msg.sender] = tokenAccountData;

		// Don't transfer WETH, WETH is converted to ETH and sent to the recipient
		if (token == WETH && asETH) {
			IWETH(WETH).withdraw(tokenAmount);
			msg.sender.sendValue(tokenAmount);
		} else {
			IERC20(token).safeTransfer(msg.sender, tokenAmount);
		}

		emit Withdrawn(msg.sender, tokenInfo, asETH);
	}

	function configureWhitelist(WhitelistSettings memory settings) external override onlyOwner {
		whitelistSettings = settings;
		emit WhitelistConfigured(settings);
	}

	function addSupportedTokens(SupportedTokenData[] calldata tokensToSupport) external override onlyOwner {
		uint256 tokensLength = tokensToSupport.length;
		for (uint256 i = 0; i < tokensLength; ++i) {
			SupportedTokenData memory data = tokensToSupport[i];
			require(supportedTokens.add(data.token), "ADD_FAIL");

			tokenSettings[data.token] = data;
		}
		emit SupportedTokensAdded(tokensToSupport);
	}

	function getSupportedTokens() external view override returns (address[] memory tokens) {
		uint256 tokensLength = supportedTokens.length();
		tokens = new address[](tokensLength);
		for (uint256 i = 0; i < tokensLength; ++i) {
			tokens[i] = supportedTokens.at(i);
		}
	}

	function publishRates(
		RateData[] calldata ratesData,
		OversubscriptionRate memory oversubRate,
		uint256 lastLookDuration
	) external override onlyOwner {
		// check rates havent been published before
		require(currentStage == STAGES.STAGE_1, "RATES_ALREADY_SET");
		require(lastLookDuration > 0, "INVALID_DURATION");
		require(oversubRate.overDenominator > 0, "INVALID_DENOMINATOR");
		require(oversubRate.overNumerator > 0, "INVALID_NUMERATOR");

		uint256 ratesLength = ratesData.length;
		for (uint256 i = 0; i < ratesLength; ++i) {
			RateData memory data = ratesData[i];
			require(data.numerator > 0, "INVALID_NUMERATOR");
			require(data.denominator > 0, "INVALID_DENOMINATOR");
			require(tokenRates[data.token].token == address(0), "RATE_ALREADY_SET");
			require(configuredTokenRates.add(data.token), "ADD_FAIL");
			tokenRates[data.token] = data;
		}

		require(configuredTokenRates.length() == supportedTokens.length(), "MISSING_RATE");

		// Stage only moves forward when prices are published
		currentStage = STAGES.STAGE_2;
		lastLookExpiration = block.number + lastLookDuration;
		overSubscriptionRate = oversubRate;

		emit RatesPublished(ratesData);
	}

	function getRates(address[] calldata tokens) external view override returns (RateData[] memory rates) {
		uint256 tokensLength = tokens.length;
		rates = new RateData[](tokensLength);
		for (uint256 i = 0; i < tokensLength; ++i) {
			rates[i] = tokenRates[tokens[i]];
		}
	}

	function getTokenValue(address token, uint256 balance) internal view returns (uint256 value) {
		uint256 tokenDecimals = ERC20(token).decimals();
		(, int256 tokenRate, , , ) = AggregatorV3Interface(tokenSettings[token].oracle).latestRoundData();
		uint256 rate = tokenRate.toUint256();
		value = (balance.mul(rate)).div(10**tokenDecimals); //Chainlink USD prices are always to 8
	}

	function totalValue() external view override returns (uint256) {
		return _totalValue();
	}

	function _totalValue() internal view returns (uint256 value) {
		uint256 tokensLength = supportedTokens.length();
		for (uint256 i = 0; i < tokensLength; ++i) {
			address token = supportedTokens.at(i);
			uint256 tokenBalance = IERC20(token).balanceOf(address(this));
			value = value.add(getTokenValue(token, tokenBalance));
		}
	}

	function accountBalance(address account) external view override returns (uint256 value) {
		uint256 tokenBalance = accountData[account].currentBalance;
		value = value.add(getTokenValue(accountData[account].token, tokenBalance));
	}

	function finalizeAssets(bool depositToGenesis) external override {
		require(currentStage == STAGES.STAGE_3, "NOT_SYSTEM_FINAL");

		AccountData storage data = accountData[msg.sender];
		address token = data.token;

		require(token != address(0), "NO_DATA");

		(, uint256 ineffective, ) = _getRateAdjustedAmounts(data.currentBalance, token);

		require(ineffective > 0, "NOTHING_TO_MOVE");

		// zero out balance
		data.currentBalance = 0;
		accountData[msg.sender] = data;

		if (depositToGenesis) {
			address pool = tokenSettings[token].genesis;
			uint256 currentAllowance = IERC20(token).allowance(address(this), pool);
			if (currentAllowance < ineffective) {
				IERC20(token).safeIncreaseAllowance(pool, ineffective.sub(currentAllowance));
			}
			ILiquidityPool(pool).depositFor(msg.sender, ineffective);
			emit GenesisTransfer(msg.sender, ineffective);
		} else {
			// transfer ineffectiveTokenBalance back to user
			IERC20(token).safeTransfer(msg.sender, ineffective);
		}

		emit AssetsFinalized(msg.sender, token, ineffective);
	}

	function getGenesisPools(
		address[] calldata tokens
	) external view override returns (address[] memory genesisAddresses) {
		uint256 tokensLength = tokens.length;
		genesisAddresses = new address[](tokensLength);
		for (uint256 i = 0; i < tokensLength; ++i) {
			require(supportedTokens.contains(tokens[i]), "TOKEN_UNSUPPORTED");
			genesisAddresses[i] = tokenSettings[supportedTokens.at(i)].genesis;
		}
	}

	function getTokenOracles(
		address[] calldata tokens
	) external view override returns (address[] memory oracleAddresses) {
		uint256 tokensLength = tokens.length;
		oracleAddresses = new address[](tokensLength);
		for (uint256 i = 0; i < tokensLength; ++i) {
			require(supportedTokens.contains(tokens[i]), "TOKEN_UNSUPPORTED");
			oracleAddresses[i] = tokenSettings[tokens[i]].oracle;
		}
	}

	function getAccountData(address account) external view override returns (AccountDataDetails[] memory data) {
		uint256 supportedTokensLength = supportedTokens.length();
		data = new AccountDataDetails[](supportedTokensLength);
		for (uint256 i = 0; i < supportedTokensLength; ++i) {
			address token = supportedTokens.at(i);
			AccountData memory accountTokenInfo = accountData[account];
			if (currentStage >= STAGES.STAGE_2 && accountTokenInfo.token != address(0)) {
				(uint256 effective, uint256 ineffective, uint256 actual) = _getRateAdjustedAmounts(
					accountTokenInfo.currentBalance,
					token
				);
				AccountDataDetails memory details = AccountDataDetails(
					token,
					accountTokenInfo.initialDeposit,
					accountTokenInfo.currentBalance,
					effective,
					ineffective,
					actual
				);
				data[i] = details;
			} else {
				data[i] = AccountDataDetails(
					token,
					accountTokenInfo.initialDeposit,
					accountTokenInfo.currentBalance,
					0,
					0,
					0
				);
			}
		}
	}

	function transferToTreasury() external override onlyOwner {
		require(_isLastLookComplete(), "CURRENT_STAGE_INVALID");
		require(currentStage == STAGES.STAGE_2, "ONLY_TRANSFER_ONCE");

		uint256 supportedTokensLength = supportedTokens.length();
		TokenData[] memory tokens = new TokenData[](supportedTokensLength);
		for (uint256 i = 0; i < supportedTokensLength; ++i) {
			address token = supportedTokens.at(i);
			uint256 balance = IERC20(token).balanceOf(address(this));
			(uint256 effective, , ) = _getRateAdjustedAmounts(balance, token);
			tokens[i].token = token;
			tokens[i].amount = effective;
			IERC20(token).safeTransfer(treasury, effective);
		}

		currentStage = STAGES.STAGE_3;

		emit TreasuryTransfer(tokens);
	}

	function getRateAdjustedAmounts(
		uint256 balance,
		address token
	) external view override returns (uint256, uint256, uint256) {
		return _getRateAdjustedAmounts(balance, token);
	}

	function getMaxTotalValue() external view override returns (uint256) {
		return maxTotalValue;
	}

	function _getRateAdjustedAmounts(uint256 balance, address token) internal view returns (uint256, uint256, uint256) {
		require(currentStage >= STAGES.STAGE_2, "RATES_NOT_PUBLISHED");

		RateData memory rateInfo = tokenRates[token];
		uint256 effectiveTokenBalance = balance.mul(overSubscriptionRate.overNumerator).div(
			overSubscriptionRate.overDenominator
		);
		uint256 ineffectiveTokenBalance = balance
			.mul(overSubscriptionRate.overDenominator.sub(overSubscriptionRate.overNumerator))
			.div(overSubscriptionRate.overDenominator);

		uint256 actualReceived = effectiveTokenBalance.mul(rateInfo.denominator).div(rateInfo.numerator);

		return (effectiveTokenBalance, ineffectiveTokenBalance, actualReceived);
	}

	function verifyDepositor(address participant, bytes32 root, bytes32[] memory proof) internal pure returns (bool) {
		bytes32 leaf = keccak256((abi.encodePacked((participant))));
		return MerkleProof.verify(proof, root, leaf);
	}

	function _isLastLookComplete() internal view returns (bool) {
		return block.number >= lastLookExpiration;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface IDefiRound {
	enum STAGES {
		STAGE_1,
		STAGE_2,
		STAGE_3
	}

	struct AccountData {
		address token; // address of the allowed token deposited
		uint256 initialDeposit; // initial amount deposited of the token
		uint256 currentBalance; // current balance of the token that can be used to claim TOKE
	}

	struct AccountDataDetails {
		address token; // address of the allowed token deposited
		uint256 initialDeposit; // initial amount deposited of the token
		uint256 currentBalance; // current balance of the token that can be used to claim TOKE
		uint256 effectiveAmt; //Amount deposited that will be used towards TOKE
		uint256 ineffectiveAmt; //Amount deposited that will be either refunded or go to farming
		uint256 actualTokeReceived; //Amount of TOKE that will be received
	}

	struct TokenData {
		address token;
		uint256 amount;
	}

	struct SupportedTokenData {
		address token;
		address oracle;
		address genesis;
		uint256 maxLimit;
	}

	struct RateData {
		address token;
		uint256 numerator;
		uint256 denominator;
	}

	struct OversubscriptionRate {
		uint256 overNumerator;
		uint256 overDenominator;
	}

	event Deposited(address depositor, TokenData tokenInfo);
	event Withdrawn(address withdrawer, TokenData tokenInfo, bool asETH);
	event SupportedTokensAdded(SupportedTokenData[] tokenData);
	event RatesPublished(RateData[] ratesData);
	event GenesisTransfer(address user, uint256 amountTransferred);
	event AssetsFinalized(address claimer, address token, uint256 assetsMoved);
	event WhitelistConfigured(WhitelistSettings settings);
	event TreasuryTransfer(TokenData[] tokens);

	struct TokenValues {
		uint256 effectiveTokenValue;
		uint256 ineffectiveTokenValue;
	}

	struct WhitelistSettings {
		bool enabled;
		bytes32 root;
	}

	/// @notice Enable or disable the whitelist
	/// @param settings The root to use and whether to check the whitelist at all
	function configureWhitelist(WhitelistSettings calldata settings) external;

	/// @notice returns the current stage the contract is in
	/// @return stage the current stage the round contract is in
	function currentStage() external returns (STAGES stage);

	/// @notice deposits tokens into the round contract
	/// @param tokenData an array of token structs
	function deposit(TokenData calldata tokenData, bytes32[] memory proof) external payable;

	/// @notice total value held in the entire contract amongst all the assets
	/// @return value the value of all assets held
	function totalValue() external view returns (uint256 value);

	/// @notice Current Max Total Value
	/// @return value the max total value
	function getMaxTotalValue() external view returns (uint256 value);

	/// @notice returns the address of the treasury, when users claim this is where funds that are <= maxClaimableValue go
	/// @return treasuryAddress address of the treasury
	function treasury() external returns (address treasuryAddress);

	/// @notice the total supply held for a given token
	/// @param token the token to get the supply for
	/// @return amount the total supply for a given token
	function totalSupply(address token) external returns (uint256 amount);

	/// @notice withdraws tokens from the round contract. only callable when round 2 starts
	/// @param tokenData an array of token structs
	/// @param asEth flag to determine if provided WETH, that it should be withdrawn as ETH
	function withdraw(TokenData calldata tokenData, bool asEth) external;

	// /// @notice adds tokens to support
	// /// @param tokensToSupport an array of supported token structs
	function addSupportedTokens(SupportedTokenData[] calldata tokensToSupport) external;

	// /// @notice returns which tokens can be deposited
	// /// @return tokens tokens that are supported for deposit
	function getSupportedTokens() external view returns (address[] calldata tokens);

	/// @notice the oracle that will be used to denote how much the amounts deposited are worth in USD
	/// @param tokens an array of tokens
	/// @return oracleAddresses the an array of oracles corresponding to supported tokens
	function getTokenOracles(address[] calldata tokens) external view returns (address[] calldata oracleAddresses);

	/// @notice publishes rates for the tokens. Rates are always relative to 1 TOKE. Can only be called once within Stage 1
	// prices can be published at any time
	/// @param ratesData an array of rate info structs
	function publishRates(
		RateData[] calldata ratesData,
		OversubscriptionRate memory overSubRate,
		uint256 lastLookDuration
	) external;

	/// @notice return the published rates for the tokens
	/// @param tokens an array of tokens to get rates for
	/// @return rates an array of rates for the provided tokens
	function getRates(address[] calldata tokens) external view returns (RateData[] calldata rates);

	/// @notice determines the account value in USD amongst all the assets the user is invovled in
	/// @param account the account to look up
	/// @return value the value of the account in USD
	function accountBalance(address account) external view returns (uint256 value);

	/// @notice Moves excess assets to private farming or refunds them
	/// @dev uses the publishedRates, selected tokens, and amounts to determine what amount of TOKE is claimed
	/// @param depositToGenesis applies only if oversubscribedMultiplier < 1;
	/// when true oversubscribed amount will deposit to genesis, else oversubscribed amount is sent back to user
	function finalizeAssets(bool depositToGenesis) external;

	//// @notice returns what gensis pool a supported token is mapped to
	/// @param tokens array of addresses of supported tokens
	/// @return genesisAddresses array of genesis pools corresponding to supported tokens
	function getGenesisPools(address[] calldata tokens) external view returns (address[] memory genesisAddresses);

	/// @notice returns a list of AccountData for a provided account
	/// @param account the address of the account
	/// @return data an array of AccountData denoting what the status is for each of the tokens deposited (if any)
	function getAccountData(address account) external view returns (AccountDataDetails[] calldata data);

	/// @notice Allows the owner to transfer all swapped assets to the treasury
	/// @dev only callable by owner and if last look period is complete
	function transferToTreasury() external;

	/// @notice Given a balance, calculates how the the amount will be allocated between TOKE and Farming
	/// @dev Only allowed at stage 3
	/// @param balance balance to divy up
	/// @param token token to pull the rates for
	function getRateAdjustedAmounts(uint256 balance, address token) external view returns (uint256, uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/ICoreEvent.sol";
import "../interfaces/ILiquidityPool.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

contract CoreEvent is Ownable, ICoreEvent {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	using Address for address;
	using EnumerableSet for EnumerableSet.AddressSet;

	// Contains start block and duration
	DurationInfo public durationInfo;

	address public immutable treasuryAddress;

	EnumerableSet.AddressSet private supportedTokenAddresses;

	// token address -> SupportedTokenData
	mapping(address => SupportedTokenData) public supportedTokens;

	// user -> token -> AccountData
	mapping(address => mapping(address => AccountData)) public accountData;
	mapping(address => RateData) public tokenRates;

	WhitelistSettings public whitelistSettings;

	bool public stage1Locked;

	modifier hasEnded() {
		require(_hasEnded(), "TOO_EARLY");
		_;
	}

	constructor(address treasury, SupportedTokenData[] memory tokensToSupport) public {
		treasuryAddress = treasury;
		addSupportedTokens(tokensToSupport);
	}

	function configureWhitelist(WhitelistSettings memory settings) external override onlyOwner {
		whitelistSettings = settings;
		emit WhitelistConfigured(settings);
	}

	function setDuration(uint256 _blockDuration) external override onlyOwner {
		require(durationInfo.startingBlock == 0, "ALREADY_STARTED");

		durationInfo.startingBlock = block.number;
		durationInfo.blockDuration = _blockDuration;

		emit DurationSet(durationInfo);
	}

	function addSupportedTokens(SupportedTokenData[] memory tokensToSupport) public override onlyOwner {
		require(tokensToSupport.length > 0, "NO_TOKENS");

		for (uint256 i = 0; i < tokensToSupport.length; ++i) {
			require(!supportedTokenAddresses.contains(tokensToSupport[i].token), "DUPLICATE_TOKEN");
			require(tokensToSupport[i].token != address(0), "ZERO_ADDRESS");
			require(!tokensToSupport[i].systemFinalized, "FINALIZED_MUST_BE_FALSE");

			require(supportedTokenAddresses.add(tokensToSupport[i].token), "ADD_FAIL");
			supportedTokens[tokensToSupport[i].token] = tokensToSupport[i];
		}
		emit SupportedTokensAdded(tokensToSupport);
	}

	function deposit(TokenData[] calldata tokenData, bytes32[] calldata proof) external override {
		require(durationInfo.startingBlock > 0, "NOT_STARTED");
		require(!_hasEnded(), "RATES_LOCKED");
		require(tokenData.length > 0, "NO_TOKENS");

		if (whitelistSettings.enabled) {
			require(verifyDepositor(msg.sender, whitelistSettings.root, proof), "PROOF_INVALID");
		}

		for (uint256 i = 0; i < tokenData.length; ++i) {
			uint256 amount = tokenData[i].amount;
			require(amount > 0, "0_BALANCE");
			address token = tokenData[i].token;
			require(supportedTokenAddresses.contains(token), "NOT_SUPPORTED");
			IERC20 erc20Token = IERC20(token);

			AccountData storage data = accountData[msg.sender][token];

			/// Check that total user deposits do not exceed token limit
			require(data.depositedBalance.add(amount) <= supportedTokens[token].maxUserLimit, "OVER_LIMIT");

			data.depositedBalance = data.depositedBalance.add(amount);

			data.token = token;

			erc20Token.safeTransferFrom(msg.sender, address(this), amount);
		}

		emit Deposited(msg.sender, tokenData);
	}

	function withdraw(TokenData[] calldata tokenData) external override {
		require(!_hasEnded(), "RATES_LOCKED");
		require(tokenData.length > 0, "NO_TOKENS");

		for (uint256 i = 0; i < tokenData.length; ++i) {
			uint256 amount = tokenData[i].amount;
			require(amount > 0, "ZERO_BALANCE");
			address token = tokenData[i].token;
			IERC20 erc20Token = IERC20(token);

			AccountData storage data = accountData[msg.sender][token];

			require(data.token != address(0), "ZERO_ADDRESS");
			require(amount <= data.depositedBalance, "INSUFFICIENT_FUNDS");

			data.depositedBalance = data.depositedBalance.sub(amount);

			if (data.depositedBalance == 0) {
				delete accountData[msg.sender][token];
			}
			erc20Token.safeTransfer(msg.sender, amount);
		}

		emit Withdrawn(msg.sender, tokenData);
	}

	function increaseDuration(uint256 _blockDuration) external override onlyOwner {
		require(durationInfo.startingBlock > 0, "NOT_STARTED");
		require(_blockDuration > durationInfo.blockDuration, "INCREASE_ONLY");
		require(!stage1Locked, "STAGE1_LOCKED");

		durationInfo.blockDuration = _blockDuration;

		emit DurationIncreased(durationInfo);
	}

	function setRates(RateData[] calldata rates) external override onlyOwner hasEnded {
		//Rates are settable multiple times, but only until they are finalized.
		//They are set to finalized by either performing the transferToTreasury
		//Or, by marking them as no-swap tokens
		//Users cannot begin their next set of actions before a token finalized.

		uint256 length = rates.length;
		for (uint256 i = 0; i < length; ++i) {
			RateData memory data = rates[i];
			require(supportedTokenAddresses.contains(data.token), "UNSUPPORTED_ADDRESS");
			require(!supportedTokens[data.token].systemFinalized, "ALREADY_FINALIZED");

			if (data.tokeNumerator > 0) {
				//We are allowing an address(0) pool, it means it was a winning reactor
				//but there wasn't enough to enable private farming
				require(data.tokeDenominator > 0, "INVALID_TOKE_DENOMINATOR");
				require(data.overNumerator > 0, "INVALID_OVER_NUMERATOR");
				require(data.overDenominator > 0, "INVALID_OVER_DENOMINATOR");

				tokenRates[data.token] = data;
			} else {
				delete tokenRates[data.token];
			}
		}

		stage1Locked = true;

		emit RatesPublished(rates);
	}

	function transferToTreasury(address[] calldata tokens) external override onlyOwner hasEnded {
		uint256 length = tokens.length;
		TokenData[] memory transfers = new TokenData[](length);
		for (uint256 i = 0; i < length; ++i) {
			address token = tokens[i];
			require(tokenRates[token].tokeNumerator > 0, "NO_SWAP_TOKEN");
			require(!supportedTokens[token].systemFinalized, "ALREADY_FINALIZED");
			uint256 balance = IERC20(token).balanceOf(address(this));
			(uint256 effective, , ) = getRateAdjustedAmounts(balance, token);
			transfers[i].token = token;
			transfers[i].amount = effective;
			supportedTokens[token].systemFinalized = true;

			IERC20(token).safeTransfer(treasuryAddress, effective);
		}

		emit TreasuryTransfer(transfers);
	}

	function setNoSwap(address[] calldata tokens) external override onlyOwner hasEnded {
		uint256 length = tokens.length;

		for (uint256 i = 0; i < length; ++i) {
			address token = tokens[i];
			require(supportedTokenAddresses.contains(token), "UNSUPPORTED_ADDRESS");
			require(tokenRates[token].tokeNumerator == 0, "ALREADY_SET_TO_SWAP");
			require(!supportedTokens[token].systemFinalized, "ALREADY_FINALIZED");

			supportedTokens[token].systemFinalized = true;
		}

		stage1Locked = true;

		emit SetNoSwap(tokens);
	}

	function finalize(TokenFarming[] calldata tokens) external override hasEnded {
		require(tokens.length > 0, "NO_TOKENS");

		uint256 length = tokens.length;
		FinalizedAccountData[] memory results = new FinalizedAccountData[](length);
		for (uint256 i = 0; i < length; ++i) {
			TokenFarming calldata farm = tokens[i];
			AccountData storage account = accountData[msg.sender][farm.token];

			require(!account.finalized, "ALREADY_FINALIZED");
			require(farm.token != address(0), "ZERO_ADDRESS");
			require(supportedTokens[farm.token].systemFinalized, "NOT_SYSTEM_FINALIZED");
			require(account.depositedBalance > 0, "INSUFFICIENT_FUNDS");

			RateData storage rate = tokenRates[farm.token];

			uint256 amtToTransfer = 0;
			if (rate.tokeNumerator > 0) {
				//We have set a rate, which means its a winning reactor
				//which means only the ineffective amount, the amount
				//not spent on TOKE, can leave the contract.
				//Leaving to either the farm or back to the user

				//In the event there is no farming, an oversubscription rate of 1/1
				//will be provided for the token. That will ensure the ineffective
				//amount is 0 and caught by the below require() as only assets with
				//an oversubscription can be moved
				(, uint256 ineffectiveAmt, ) = getRateAdjustedAmounts(account.depositedBalance, farm.token);
				amtToTransfer = ineffectiveAmt;
			} else {
				amtToTransfer = account.depositedBalance;
			}
			require(amtToTransfer > 0, "NOTHING_TO_MOVE");
			account.finalized = true;

			if (farm.sendToFarming) {
				require(rate.pool != address(0), "NO_FARMING");
				uint256 currentAllowance = IERC20(farm.token).allowance(address(this), rate.pool);
				if (currentAllowance < amtToTransfer) {
					IERC20(farm.token).safeIncreaseAllowance(rate.pool, amtToTransfer.sub(currentAllowance));
				}
				// Deposit to pool
				ILiquidityPool(rate.pool).depositFor(msg.sender, amtToTransfer);
				results[i] = FinalizedAccountData({ token: farm.token, transferredToFarm: amtToTransfer, refunded: 0 });
			} else {
				// If user wants withdrawn and no private farming
				IERC20(farm.token).safeTransfer(msg.sender, amtToTransfer);
				results[i] = FinalizedAccountData({ token: farm.token, transferredToFarm: 0, refunded: amtToTransfer });
			}
		}

		emit AssetsFinalized(msg.sender, results);
	}

	function getRateAdjustedAmounts(
		uint256 balance,
		address token
	) public view override returns (uint256 effectiveAmt, uint256 ineffectiveAmt, uint256 actualReceived) {
		RateData memory rateInfo = tokenRates[token];
		// Amount eligible to be transferred for Toke
		uint256 effectiveTokenBalance = balance.mul(rateInfo.overNumerator).div(rateInfo.overDenominator);
		// Amount to be withdrawn or sent to private farming
		uint256 ineffectiveTokenBalance = balance.mul(rateInfo.overDenominator.sub(rateInfo.overNumerator)).div(
			rateInfo.overDenominator
		);

		uint256 actual = effectiveTokenBalance.mul(rateInfo.tokeDenominator).div(rateInfo.tokeNumerator);

		return (effectiveTokenBalance, ineffectiveTokenBalance, actual);
	}

	function getRates() external view override returns (RateData[] memory rates) {
		uint256 length = supportedTokenAddresses.length();
		rates = new RateData[](length);
		for (uint256 i = 0; i < length; ++i) {
			address token = supportedTokenAddresses.at(i);
			rates[i] = tokenRates[token];
		}
	}

	function getAccountData(address account) external view override returns (AccountData[] memory data) {
		uint256 length = supportedTokenAddresses.length();
		data = new AccountData[](length);
		for (uint256 i = 0; i < length; ++i) {
			address token = supportedTokenAddresses.at(i);
			data[i] = accountData[account][token];
			data[i].token = token;
		}
	}

	function getSupportedTokens() external view override returns (SupportedTokenData[] memory supportedTokensArray) {
		uint256 supportedTokensLength = supportedTokenAddresses.length();
		supportedTokensArray = new SupportedTokenData[](supportedTokensLength);

		for (uint256 i = 0; i < supportedTokensLength; ++i) {
			supportedTokensArray[i] = supportedTokens[supportedTokenAddresses.at(i)];
		}
		return supportedTokensArray;
	}

	function _hasEnded() private view returns (bool) {
		return
			durationInfo.startingBlock > 0 && block.number >= durationInfo.blockDuration + durationInfo.startingBlock;
	}

	function verifyDepositor(address participant, bytes32 root, bytes32[] memory proof) internal pure returns (bool) {
		bytes32 leaf = keccak256((abi.encodePacked((participant))));
		return MerkleProof.verify(proof, root, leaf);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface ICoreEvent {
	struct SupportedTokenData {
		address token;
		uint256 maxUserLimit;
		bool systemFinalized; // Whether or not the system is done setting rates, doing transfers, for this token
	}

	struct DurationInfo {
		uint256 startingBlock;
		uint256 blockDuration; // Block duration of the deposit/withdraw stage
	}

	struct RateData {
		address token;
		uint256 tokeNumerator;
		uint256 tokeDenominator;
		uint256 overNumerator;
		uint256 overDenominator;
		address pool;
	}

	struct TokenData {
		address token;
		uint256 amount;
	}

	struct AccountData {
		address token; // Address of the allowed token deposited
		uint256 depositedBalance;
		bool finalized; // Has the user either taken their refund or sent to farming. Will not be set on swapped but undersubscribed tokens.
	}

	struct FinalizedAccountData {
		address token;
		uint256 transferredToFarm;
		uint256 refunded;
	}

	struct TokenFarming {
		address token; // address of the allowed token deposited
		bool sendToFarming; // Refund is default
	}

	struct WhitelistSettings {
		bool enabled;
		bytes32 root;
	}

	event SupportedTokensAdded(SupportedTokenData[] tokenData);
	event TreasurySet(address treasury);
	event DurationSet(DurationInfo duration);
	event DurationIncreased(DurationInfo duration);
	event Deposited(address depositor, TokenData[] tokenInfo);
	event Withdrawn(address withdrawer, TokenData[] tokenInfo);
	event RatesPublished(RateData[] ratesData);
	event AssetsFinalized(address user, FinalizedAccountData[] data);
	event TreasuryTransfer(TokenData[] tokens);
	event WhitelistConfigured(WhitelistSettings settings);
	event SetNoSwap(address[] tokens);

	//==========================================
	// Initial setup operations
	//==========================================

	/// @notice Enable or disable the whitelist
	/// @param settings The root to use and whether to check the whitelist at all
	function configureWhitelist(WhitelistSettings memory settings) external;

	/// @notice defines the length in blocks the round will run for
	/// @notice round is started via this call and it is only callable one time
	/// @param blockDuration Duration in blocks the deposit/withdraw portion will run for
	function setDuration(uint256 blockDuration) external;

	/// @notice adds tokens to support
	/// @param tokensToSupport an array of supported token structs
	function addSupportedTokens(SupportedTokenData[] memory tokensToSupport) external;

	//==========================================
	// Stage 1 timeframe operations
	//==========================================

	/// @notice deposits tokens into the round contract
	/// @param tokenData an array of token structs
	/// @param proof Merkle proof for the user. Only required if whitelistSettings.enabled
	function deposit(TokenData[] calldata tokenData, bytes32[] calldata proof) external;

	/// @notice withdraws tokens from the round contract
	/// @param tokenData an array of token structs
	function withdraw(TokenData[] calldata tokenData) external;

	/// @notice extends the deposit/withdraw stage
	/// @notice Only extendable if no tokens have been finalized and no rates set
	/// @param blockDuration Duration in blocks the deposit/withdraw portion will run for. Must be greater than original
	function increaseDuration(uint256 blockDuration) external;

	//==========================================
	// Stage 1 -> 2 transition operations
	//==========================================

	/// @notice once the expected duration has passed, publish the Toke and over subscription rates
	/// @notice tokens which do not have a published rate will have their users forced to withdraw all funds
	/// @dev pass a tokeNumerator of 0 to delete a set rate
	/// @dev Cannot be called for a token once transferToTreasury/setNoSwap has been called for that token
	function setRates(RateData[] calldata rates) external;

	/// @notice Allows the owner to transfer the effective balance of a token based on the set rate to the treasury
	/// @dev only callable by owner and if rates have been set
	/// @dev is only callable one time for a token
	function transferToTreasury(address[] calldata tokens) external;

	/// @notice Marks a token as finalized but not swapping
	/// @dev complement to transferToTreasury which is for tokens that will be swapped, this one for ones that won't
	function setNoSwap(address[] calldata tokens) external;

	//==========================================
	// Stage 2 operations
	//==========================================

	/// @notice Once rates have been published, and the token finalized via transferToTreasury/setNoSwap, either refunds or sends to private farming
	/// @param tokens an array of tokens and whether to send them to private farming. False on farming will send back to user.
	function finalize(TokenFarming[] calldata tokens) external;

	//==========================================
	// View operations
	//==========================================

	/// @notice Breaks down the balance according to the published rates
	/// @dev only callable after rates have been set
	function getRateAdjustedAmounts(
		uint256 balance,
		address token
	) external view returns (uint256 effectiveAmt, uint256 ineffectiveAmt, uint256 actualReceived);

	/// @notice return the published rates for the tokens
	/// @return rates an array of rates for the provided tokens
	function getRates() external view returns (RateData[] memory rates);

	/// @notice returns a list of AccountData for a provided account
	/// @param account the address of the account
	/// @return data an array of AccountData denoting what the status is for each of the tokens deposited (if any)
	function getAccountData(address account) external view returns (AccountData[] calldata data);

	/// @notice get all tokens currently supported by the contract
	/// @return supportedTokensArray an array of supported token structs
	function getSupportedTokens() external view returns (SupportedTokenData[] memory supportedTokensArray);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./BaseController.sol";

contract UniswapController is BaseController {
	using SafeERC20 for IERC20;
	using Address for address;
	using Address for address payable;
	using SafeMath for uint256;

	// solhint-disable-next-line var-name-mixedcase
	IUniswapV2Router02 public immutable UNISWAP_ROUTER;
	// solhint-disable-next-line var-name-mixedcase
	IUniswapV2Factory public immutable UNISWAP_FACTORY;

	constructor(
		IUniswapV2Router02 router,
		IUniswapV2Factory factory,
		address manager,
		address accessControl,
		address addressRegistry
	) public BaseController(manager, accessControl, addressRegistry) {
		require(address(router) != address(0), "INVALID_ROUTER");
		require(address(factory) != address(0), "INVALID_FACTORY");
		UNISWAP_ROUTER = router;
		UNISWAP_FACTORY = factory;
	}

	/// @notice Deploys liq to Uniswap LP pool
	/// @dev Calls to external contract
	/// @param data Bytes containing token addrs, amounts, pool addr, dealine to interact with Uni router
	function deploy(bytes calldata data) external onlyManager onlyAddLiquidity {
		(
			address tokenA,
			address tokenB,
			uint256 amountADesired,
			uint256 amountBDesired,
			uint256 amountAMin,
			uint256 amountBMin,
			address to,
			uint256 deadline
		) = abi.decode(data, (address, address, uint256, uint256, uint256, uint256, address, uint256));

		require(to == manager, "MUST_BE_MANAGER");
		require(addressRegistry.checkAddress(tokenA, 0), "INVALID_TOKEN");
		require(addressRegistry.checkAddress(tokenB, 0), "INVALID_TOKEN");

		_approve(IERC20(tokenA), amountADesired);
		_approve(IERC20(tokenB), amountBDesired);

		IERC20 pair = IERC20(UNISWAP_FACTORY.getPair(tokenA, tokenB));
		uint256 balanceBefore = pair.balanceOf(address(this));

		//(uint256 amountA, uint256 amountB, uint256 liquidity) =
		UNISWAP_ROUTER.addLiquidity(
			tokenA,
			tokenB,
			amountADesired,
			amountBDesired,
			amountAMin,
			amountBMin,
			to,
			deadline
		);

		uint256 balanceAfter = pair.balanceOf(address(this));
		require(balanceAfter > balanceBefore, "MUST_INCREASE");
	}

	/// @notice Withdraws liq from Uni LP pool
	/// @dev Calls to external contract
	/// @param data Bytes contains tokens addrs, amounts, liq, pool addr, dealine for Uni router
	function withdraw(bytes calldata data) external onlyManager onlyRemoveLiquidity {
		(
			address tokenA,
			address tokenB,
			uint256 liquidity,
			uint256 amountAMin,
			uint256 amountBMin,
			address to,
			uint256 deadline
		) = abi.decode(data, (address, address, uint256, uint256, uint256, address, uint256));

		require(to == manager, "MUST_BE_MANAGER");
		require(addressRegistry.checkAddress(tokenA, 0), "INVALID_TOKEN");
		require(addressRegistry.checkAddress(tokenB, 0), "INVALID_TOKEN");

		address pair = UNISWAP_FACTORY.getPair(tokenA, tokenB);
		require(pair != address(0), "pair doesn't exist");
		_approve(IERC20(pair), liquidity);

		IERC20 tokenAInterface = IERC20(tokenA);
		IERC20 tokenBInterface = IERC20(tokenB);
		uint256 tokenABalanceBefore = tokenAInterface.balanceOf(address(this));
		uint256 tokenBBalanceBefore = tokenBInterface.balanceOf(address(this));

		//(uint256 amountA, uint256 amountB) =
		UNISWAP_ROUTER.removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);

		uint256 tokenABalanceAfter = tokenAInterface.balanceOf(address(this));
		uint256 tokenBBalanceAfter = tokenBInterface.balanceOf(address(this));
		require(tokenABalanceAfter > tokenABalanceBefore, "MUST_INCREASE");
		require(tokenBBalanceAfter > tokenBBalanceBefore, "MUST_INCREASE");
	}

	function _approve(IERC20 token, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), address(UNISWAP_ROUTER));
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(address(UNISWAP_ROUTER), currentAllowance);
		}
		token.safeIncreaseAllowance(address(UNISWAP_ROUTER), amount);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./BaseController.sol";

contract TransferController is BaseController {
	using SafeERC20 for IERC20;

	address public immutable treasuryAddress;

	constructor(
		address manager,
		address accessControl,
		address addressRegistry,
		address treasury
	) public BaseController(manager, accessControl, addressRegistry) {
		require(treasury != address(0), "INVALID_TREASURY_ADDRESS");
		treasuryAddress = treasury;
	}

	/// @notice Used to transfer funds to our treasury
	/// @dev Calls into external contract
	/// @param tokenAddress Address of IERC20 token
	/// @param amount amount of funds to transfer
	function transferFunds(address tokenAddress, uint256 amount) external onlyManager onlyMiscOperation {
		require(tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");
		require(amount > 0, "INVALID_AMOUNT");
		require(addressRegistry.checkAddress(tokenAddress, 0), "INVALID_TOKEN");

		IERC20(tokenAddress).safeTransfer(treasuryAddress, amount);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./BaseController.sol";
import "../interfaces/convex/IFraxBooster.sol";
import "../interfaces/convex/IFraxVoteProxy.sol";
import "../interfaces/convex/IFraxPoolRegistry.sol";
import "../interfaces/convex/IStakingProxyConvex.sol";
import "../interfaces/convex/IConvexStakingWrapperFrax.sol";
import "../interfaces/convex/IFraxUnifiedFarm.sol";

contract ConvexFraxController is BaseController {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	struct ExpectedReward {
		address token;
		uint256 minAmount;
	}

	event StakeLocked(bytes32 indexed kekId, uint256 pid, uint256 liquidity, uint256 secs);

	event VaultCreated(address indexed vault, uint256 pid);

	// solhint-disable-next-line var-name-mixedcase
	IFraxVoteProxy public immutable VOTER_PROXY;

	constructor(
		address _manager,
		address _accessControl,
		address _addressRegistry,
		address _fraxVoterProxy
	) public BaseController(_manager, _accessControl, _addressRegistry) {
		require(_fraxVoterProxy != address(0), "INVALID_FRAX_SYSTEM_BOOSTER_ADDRESS");

		VOTER_PROXY = IFraxVoteProxy(_fraxVoterProxy);
	}

	// @notice return pool informations
	/// @param pid Convex pool id
	function getPoolInfo(
		uint256 pid
	)
		external
		returns (
			address implementation,
			address stakingAddress,
			address stakingToken,
			address rewardsAddress,
			bool active
		)
	{
		return _getPoolInfo(pid);
	}

	function _getPoolInfo(
		uint256 pid
	)
		private
		returns (
			address implementation,
			address stakingAddress,
			address stakingToken,
			address rewardsAddress,
			bool active
		)
	{
		IFraxBooster operator = _getOperator();

		address poolRegistryAddress = operator.poolRegistry();
		(implementation, stakingAddress, stakingToken, rewardsAddress, active) = IFraxPoolRegistry(poolRegistryAddress)
			.poolInfo(pid);
	}

	/// @notice create a vault if none already exists and then deposits and stakes Curve LP tokens to Frax Convex
	/// @param pid Convex pool id
	/// @param lpToken LP token to deposit
	/// @param staking Convex reward contract associated with the Curve LP token
	/// @param amount Quantity of Curve LP token to deposit and stake
	function depositAndStakeLockedCurveLp(
		uint256 pid,
		address lpToken,
		address staking,
		uint256 amount,
		uint256 secs // Seconds it takes for entire amount to stake
	) external onlyManager onlyAddLiquidity returns (bytes32 kekId) {
		require(addressRegistry.checkAddress(lpToken, 0), "INVALID_LP_TOKEN");
		require(staking != address(0), "INVALID_STAKING_ADDRESS");
		require(amount > 0, "INVALID_AMOUNT");

		IFraxBooster operator = _getOperator();

		address poolRegistryAddress = operator.poolRegistry();
		(, address stakingAddress, address stakingToken, , ) = IFraxPoolRegistry(poolRegistryAddress).poolInfo(pid);
		address curveToken = IConvexStakingWrapperFrax(stakingToken).curveToken();
		require(lpToken == curveToken, "POOL_ID_LP_TOKEN_MISMATCH");
		require(staking == stakingAddress, "POOL_ID_STAKING_MISMATCH");

		address vaultAddress = _getVault(pid, address(this), false);
		if (vaultAddress == address(0)) {
			vaultAddress = operator.createVault(pid);
			emit VaultCreated(vaultAddress, pid);
		}

		_approve(vaultAddress, IERC20(lpToken), amount);

		uint256 balanceBefore = IFraxUnifiedFarm(stakingAddress).lockedLiquidityOf(vaultAddress);

		kekId = IStakingProxyConvex(vaultAddress).stakeLockedCurveLp(amount, secs);

		uint256 balanceChange = IFraxUnifiedFarm(stakingAddress).lockedLiquidityOf(vaultAddress).sub(balanceBefore);
		require(balanceChange == amount, "BALANCE_MUST_INCREASE");

		emit StakeLocked(kekId, pid, amount, secs);
	}

	/// @notice claims all Convex rewards associated with the target Curve LP token
	/// @param pid Convex pool id
	/// @param expectedRewards List of expected reward tokens and min amounts to receive on claim
	function claimRewards(
		uint256 pid,
		ExpectedReward[] calldata expectedRewards
	) external onlyManager onlyMiscOperation {
		address vaultAddress = _getVault(pid, address(this), true);
		require(expectedRewards.length > 0, "INVALID_EXPECTED_REWARDS");

		uint256 expectedRewardsLength = expectedRewards.length;
		uint256[] memory balancesBefore = new uint256[](expectedRewardsLength);

		for (uint256 i = 0; i < expectedRewardsLength; ++i) {
			ExpectedReward memory expectedReward = expectedRewards[i];
			require(expectedReward.token != address(0), "INVALID_REWARD_TOKEN_ADDRESS");
			require(expectedReward.minAmount > 0, "INVALID_MIN_REWARD_AMOUNT");
			balancesBefore[i] = IERC20(expectedReward.token).balanceOf(address(this));
		}

		IStakingProxyConvex(vaultAddress).getReward();

		for (uint256 i = 0; i < expectedRewardsLength; ++i) {
			ExpectedReward memory expectedReward = expectedRewards[i];
			uint256 balanceChange = IERC20(expectedReward.token).balanceOf(address(this)).sub(balancesBefore[i]);
			require(balanceChange >= expectedReward.minAmount, "BALANCE_MUST_INCREASE");
		}
	}

	/// @notice withdraws a Curve LP token from a Vault
	/// @dev does not claim available rewards
	/// @param kekId Vesting object id
	/// @param pid Convex pool id
	/// @param minAmount Minimum expected amount
	function withdrawLockedAndUnwrap(
		bytes32 kekId,
		uint256 pid,
		uint256 minAmount
	) external onlyManager onlyRemoveLiquidity {
		address vaultAddress = _getVault(pid, address(this), true);

		(, , address stakingToken, , ) = _getPoolInfo(pid);
		address curveToken = IConvexStakingWrapperFrax(stakingToken).curveToken();

		IFraxUnifiedFarm.LockedStake memory lockedStake = _getLockedStake(pid, address(this), kekId);

		uint256 balanceBefore = IERC20(curveToken).balanceOf(address(this));

		IStakingProxyConvex(vaultAddress).withdrawLockedAndUnwrap(kekId);

		uint256 balanceChange = IERC20(curveToken).balanceOf(address(this)).sub(balanceBefore);
		require(balanceChange == lockedStake.liquidity, "WITHDRAWN_AMT_MISMATCH");
		require(balanceChange >= minAmount, "BALANCE_MUST_INCREASE");
	}

	/// @notice returns list of vesting objects
	/// @param pid Convex pool id
	function lockedStakesOf(
		uint256 pid,
		address account
	) external returns (IFraxUnifiedFarm.LockedStake[] memory lockedStakes) {
		return _lockedStakesOf(pid, account);
	}

	/// @dev Make sure vault has our approval for given token (reset prev approval)
	function _approve(address spender, IERC20 token, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), spender);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(spender, currentAllowance);
		}
		token.safeIncreaseAllowance(spender, amount);
	}

	/// @notice returns current operator
	function _getOperator() private returns (IFraxBooster operator) {
		address operatorAddress = VOTER_PROXY.operator();
		operator = IFraxBooster(operatorAddress);
	}

	/// @notice returns vault for a given pool
	/// @param pid Convex pool id
	/// @param account Owner of the vault
	/// @param throwRequire Whether an error should be thrown if no vault has been found
	function _getVault(uint256 pid, address account, bool throwRequire) private returns (address vaultAddress) {
		IFraxBooster operator = _getOperator();
		address poolRegistryAddress = operator.poolRegistry();

		vaultAddress = IFraxPoolRegistry(poolRegistryAddress).vaultMap(pid, account);

		if (throwRequire) {
			require(vaultAddress != address(0), "VAULT_NOT_EXISTS");
		}
	}

	function _lockedStakesOf(
		uint256 pid,
		address account
	) private returns (IFraxUnifiedFarm.LockedStake[] memory lockedStakes) {
		address vaultAddress = _getVault(pid, account, true);

		(, address stakingAddress, , , ) = _getPoolInfo(pid);

		lockedStakes = IFraxUnifiedFarm(stakingAddress).lockedStakesOf(vaultAddress);
	}

	function _getLockedStake(
		uint256 pid,
		address account,
		bytes32 kekId
	) private returns (IFraxUnifiedFarm.LockedStake memory lockedStake) {
		IFraxUnifiedFarm.LockedStake[] memory lockedStakes = _lockedStakesOf(pid, account);

		for (uint256 i = 0; i < lockedStakes.length; ++i) {
			if (lockedStakes[i].kek_id == kekId) {
				return lockedStakes[i];
			}
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

interface IFraxBooster {
	// Create a vault for the given pool id
	function createVault(uint256 _pid) external returns (address);

	// Pool registry address
	function poolRegistry() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

interface IFraxVoteProxy {
	// Current Frax booster address
	function operator() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

interface IFraxPoolRegistry {
	// Pool informations
	function poolInfo(
		uint256 _pid
	)
		external
		returns (
			address implementation,
			address stakingAddress,
			address stakingToken,
			address rewardsAddress,
			bool active
		);

	//pool -> user -> vault
	function vaultMap(uint256 _pid, address _acccount) external returns (address vault);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

// solhint-disable var-name-mixedcase
interface IStakingProxyConvex {
	//create a new locked state of _secs timelength with a Curve LP token
	function stakeLockedCurveLp(uint256 _liquidity, uint256 _secs) external returns (bytes32 kek_id);

	//withdraw a staked position
	//frax farm transfers first before updating farm state so will checkpoint during transfer
	function withdrawLockedAndUnwrap(bytes32 _kek_id) external;

	/*
    claim flow:
        claim rewards directly to the vault
        calculate fees to send to fee deposit
        send fxs to a holder contract for fees
        get reward list of tokens that were received
        send all remaining tokens to owner

    A slightly less gas intensive approach could be to send rewards directly to a holder contract and have it sort everything out.
    However that makes the logic a bit more complex as well as runs a few future proofing risks
    */
	function getReward() external;

	function curveLpToken() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

interface IConvexStakingWrapperFrax {
	function curveToken() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

// solhint-disable var-name-mixedcase
interface IFraxUnifiedFarm {
	// Struct for the stake
	struct LockedStake {
		bytes32 kek_id;
		uint256 start_timestamp;
		uint256 liquidity;
		uint256 ending_timestamp;
		uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
	}

	// Total locked liquidity / LP tokens
	function lockedLiquidityOf(address account) external view returns (uint256);

	// All the locked stakes for a given account
	function lockedStakesOf(address account) external view returns (LockedStake[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./BaseController.sol";
import "../interfaces/convex/IConvexBooster.sol";
import "../interfaces/convex/IConvexBaseReward.sol";

contract ConvexController is BaseController {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	// solhint-disable-next-line var-name-mixedcase
	IConvexBooster public immutable BOOSTER;

	struct ExpectedReward {
		address token;
		uint256 minAmount;
	}

	constructor(
		address _manager,
		address _accessControl,
		address _addressRegistry,
		address _convexBooster
	) public BaseController(_manager, _accessControl, _addressRegistry) {
		require(_convexBooster != address(0), "INVALID_BOOSTER_ADDRESS");

		BOOSTER = IConvexBooster(_convexBooster);
	}

	/// @notice deposits and stakes Curve LP tokens to Convex
	/// @param lpToken Curve LP token to deposit
	/// @param staking Convex reward contract associated with the Curve LP token
	/// @param poolId Convex poolId for the associated Curve LP token
	/// @param amount Quantity of Curve LP token to deposit and stake
	function depositAndStake(
		address lpToken,
		address staking,
		uint256 poolId,
		uint256 amount
	) external onlyManager onlyAddLiquidity {
		require(addressRegistry.checkAddress(lpToken, 0), "INVALID_LP_TOKEN");
		require(staking != address(0), "INVALID_STAKING_ADDRESS");
		require(amount > 0, "INVALID_AMOUNT");

		(address poolLpToken, , , address crvRewards, , ) = BOOSTER.poolInfo(poolId);
		require(lpToken == poolLpToken, "POOL_ID_LP_TOKEN_MISMATCH");
		require(staking == crvRewards, "POOL_ID_STAKING_MISMATCH");

		_approve(IERC20(lpToken), amount);

		uint256 beforeBalance = IConvexBaseRewards(staking).balanceOf(address(this));

		bool success = BOOSTER.deposit(poolId, amount, true);
		require(success, "DEPOSIT_AND_STAKE_FAILED");

		uint256 balanceChange = IConvexBaseRewards(staking).balanceOf(address(this)).sub(beforeBalance);
		require(balanceChange == amount, "BALANCE_MUST_INCREASE");
	}

	/// @notice withdraws a Curve LP token from Convex
	/// @dev does not claim available rewards
	/// @param lpToken Curve LP token to withdraw
	/// @param staking Convex reward contract associated with the Curve LP token
	/// @param amount Quantity of Curve LP token to withdraw
	function withdrawStake(address lpToken, address staking, uint256 amount) external onlyManager onlyRemoveLiquidity {
		require(addressRegistry.checkAddress(lpToken, 0), "INVALID_LP_TOKEN");
		require(staking != address(0), "INVALID_STAKING_ADDRESS");
		require(amount > 0, "INVALID_AMOUNT");

		uint256 beforeBalance = IERC20(lpToken).balanceOf(address(this));

		bool success = IConvexBaseRewards(staking).withdrawAndUnwrap(amount, false);
		require(success, "WITHDRAW_STAKE_FAILED");

		uint256 balanceChange = IERC20(lpToken).balanceOf(address(this)).sub(beforeBalance);
		require(balanceChange == amount, "BALANCE_MUST_INCREASE");
	}

	/// @notice claims all Convex rewards associated with the target Curve LP token
	/// @param staking Convex reward contract associated with the Curve LP token
	/// @param expectedRewards List of expected reward tokens and min amounts to receive on claim
	function claimRewards(
		address staking,
		ExpectedReward[] calldata expectedRewards
	) external onlyManager onlyMiscOperation {
		require(staking != address(0), "INVALID_STAKING_ADDRESS");
		require(expectedRewards.length > 0, "INVALID_EXPECTED_REWARDS");

		uint256[] memory beforeBalances = new uint256[](expectedRewards.length);

		for (uint256 i = 0; i < expectedRewards.length; ++i) {
			require(expectedRewards[i].token != address(0), "INVALID_REWARD_TOKEN_ADDRESS");
			require(expectedRewards[i].minAmount > 0, "INVALID_MIN_REWARD_AMOUNT");
			beforeBalances[i] = IERC20(expectedRewards[i].token).balanceOf(address(this));
		}

		require(IConvexBaseRewards(staking).getReward(), "CLAIM_REWARD_FAILED");

		for (uint256 i = 0; i < expectedRewards.length; ++i) {
			uint256 balanceChange = IERC20(expectedRewards[i].token).balanceOf(address(this)).sub(beforeBalances[i]);
			require(balanceChange >= expectedRewards[i].minAmount, "BALANCE_MUST_INCREASE");
		}
	}

	function _approve(IERC20 token, uint256 amount) internal {
		address spender = address(BOOSTER);
		uint256 currentAllowance = token.allowance(address(this), spender);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(spender, currentAllowance);
		}
		token.safeIncreaseAllowance(spender, amount);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

//main Convex contract(booster.sol) basic interface
interface IConvexBooster {
	//deposit into convex, receive a tokenized deposit.  parameter to stake immediately
	function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns (bool);

	//get poolInfo for a poolId
	function poolInfo(
		uint256 _pid
	)
		external
		returns (address lptoken, address token, address gauge, address crvRewards, address stash, bool shutdown);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

interface IConvexBaseRewards {
	//get balance of an address
	function balanceOf(address _account) external returns (uint256);

	//withdraw directly to curve LP token
	function withdrawAndUnwrap(uint256 _amount, bool _claim) external returns (bool);

	//claim rewards
	function getReward() external returns (bool);
}

// // SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/balancer/IVault.sol";
import "./BaseController.sol";

import "../interfaces/balancer/WeightedPoolUserData.sol";

contract BalancerControllerV2 is BaseController {
	using SafeERC20 for IERC20;
	using Address for address;
	using Address for address payable;
	using SafeMath for uint256;

	IVault public immutable vault;

	constructor(
		IVault _vault,
		address manager,
		address _accessControl,
		address _addressRegistry
	) public BaseController(manager, _accessControl, _addressRegistry) {
		require(address(_vault) != address(0), "!vault");

		vault = _vault;
	}

	/// @notice Used to deploy liquidity to a Balancer V2 weighted pool
	/// @dev Calls into external contract
	/// @param poolId Balancer's ID of the pool to have liquidity added to
	/// @param tokens Array of ERC20 tokens to be added to pool
	/// @param amounts Corresponding array of amounts of tokens to be added to a pool
	/// @param poolAmountOut Amount of LP tokens to be received from the pool
	function deploy(
		bytes32 poolId,
		IERC20[] calldata tokens,
		uint256[] calldata amounts,
		uint256 poolAmountOut
	) external onlyManager onlyAddLiquidity {
		uint256 nTokens = tokens.length;
		require(nTokens == amounts.length, "TOKEN_AMOUNTS_COUNT_MISMATCH");
		require(nTokens > 0, "!TOKENS");
		require(poolAmountOut > 0, "!POOL_AMOUNT_OUT");

		// get bpt address of the pool (for later balance checks)
		(address poolAddress, ) = vault.getPool(poolId);

		// verify that we're passing correct pool tokens
		// (two part verification: total number checked here, and individual match check below)
		(IERC20[] memory poolAssets, , ) = vault.getPoolTokens(poolId);
		require(poolAssets.length == nTokens, "!(tokensIn==poolTokens");

		uint256[] memory assetBalancesBefore = new uint256[](nTokens);

		// run through tokens and make sure we have approvals (and correct token order)
		for (uint256 i = 0; i < nTokens; ++i) {
			// as per new requirements, 0 amounts are not allowed even though balancer supports it
			require(amounts[i] > 0, "!AMOUNTS[i]");

			// make sure asset is supported (and matches the pool's assets)
			require(addressRegistry.checkAddress(address(tokens[i]), 0), "INVALID_TOKEN");
			require(tokens[i] == poolAssets[i], "tokens[i]!=poolAssets[i]");

			// record previous balance for this asset
			assetBalancesBefore[i] = tokens[i].balanceOf(address(this));

			// grant spending approval to balancer's Vault
			_approve(tokens[i], amounts[i]);
		}

		// record balances before deposit
		uint256 bptBalanceBefore = IERC20(poolAddress).balanceOf(address(this));

		// encode pool entrance custom userData
		bytes memory userData = abi.encode(
			WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
			amounts, //maxAmountsIn,
			poolAmountOut
		);

		IVault.JoinPoolRequest memory joinRequest = IVault.JoinPoolRequest({
			assets: _convertERC20sToAssets(tokens),
			maxAmountsIn: amounts, // maxAmountsIn,
			userData: userData,
			fromInternalBalance: false // vault will pull the tokens from contoller instead of internal balances
		});

		vault.joinPool(
			poolId,
			address(this), // sender
			address(this), // recipient of BPT token
			joinRequest
		);

		// make sure we received bpt
		uint256 bptBalanceAfter = IERC20(poolAddress).balanceOf(address(this));
		require(bptBalanceAfter >= bptBalanceBefore.add(poolAmountOut), "BPT_MUST_INCREASE_BY_MIN_POOLAMOUNTOUT");
		// make sure assets were taken out
		for (uint256 i = 0; i < nTokens; ++i) {
			require(
				tokens[i].balanceOf(address(this)) == assetBalancesBefore[i].sub(amounts[i]),
				"ASSET_MUST_DECREASE"
			);
		}
	}

	/// @notice Withdraw liquidity from Balancer V2 pool (specifying exact asset token amounts to get)
	/// @dev Calls into external contract
	/// @param poolId Balancer's ID of the pool to have liquidity withdrawn from
	/// @param maxBurnAmount Max amount of LP tokens to burn in the withdrawal
	/// @param exactAmountsOut Array of exact amounts of tokens to be withdrawn from pool
	function withdraw(
		bytes32 poolId,
		uint256 maxBurnAmount,
		IERC20[] calldata tokens,
		uint256[] calldata exactAmountsOut
	) external onlyManager onlyRemoveLiquidity {
		// encode withdraw request
		bytes memory userData = abi.encode(
			WeightedPoolUserData.ExitKind.BPT_IN_FOR_EXACT_TOKENS_OUT,
			exactAmountsOut,
			maxBurnAmount
		);

		_withdraw(poolId, maxBurnAmount, tokens, exactAmountsOut, userData);
	}

	/// @notice Withdraw liquidity from Balancer V2 pool (specifying exact LP tokens to burn)
	/// @dev Calls into external contract
	/// @param poolId Balancer's ID of the pool to have liquidity withdrawn from
	/// @param poolAmountIn Amount of LP tokens to burn in the withdrawal
	/// @param minAmountsOut Array of minimum amounts of tokens to be withdrawn from pool
	function withdrawImbalance(
		bytes32 poolId,
		uint256 poolAmountIn,
		IERC20[] calldata tokens,
		uint256[] calldata minAmountsOut
	) external onlyManager onlyRemoveLiquidity {
		// encode withdraw request
		bytes memory userData = abi.encode(WeightedPoolUserData.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, poolAmountIn);

		_withdraw(poolId, poolAmountIn, tokens, minAmountsOut, userData);
	}

	function _withdraw(
		bytes32 poolId,
		uint256 bptAmount,
		IERC20[] calldata tokens,
		uint256[] calldata amountsOut,
		bytes memory userData
	) internal {
		uint256 nTokens = tokens.length;
		require(nTokens == amountsOut.length, "IN_TOKEN_AMOUNTS_COUNT_MISMATCH");
		require(nTokens > 0, "!TOKENS");

		(IERC20[] memory poolTokens, , ) = vault.getPoolTokens(poolId);
		uint256 numTokens = poolTokens.length;
		require(numTokens == amountsOut.length, "TOKEN_AMOUNTS_LENGTH_MISMATCH");

		// run through tokens and make sure it matches the pool's assets
		for (uint256 i = 0; i < nTokens; ++i) {
			require(addressRegistry.checkAddress(address(tokens[i]), 0), "INVALID_TOKEN");
			require(tokens[i] == poolTokens[i], "tokens[i]!=poolTokens[i]");
		}

		// grant erc20 approval for vault to spend our tokens
		(address poolAddress, ) = vault.getPool(poolId);
		_approve(IERC20(poolAddress), bptAmount);

		// record balance before withdraw
		uint256 bptBalanceBefore = IERC20(poolAddress).balanceOf(address(this));
		uint256[] memory assetBalancesBefore = new uint256[](poolTokens.length);
		for (uint256 i = 0; i < numTokens; ++i) {
			assetBalancesBefore[i] = poolTokens[i].balanceOf(address(this));
		}

		// As we're exiting the pool we need to make an ExitPoolRequest instead
		IVault.ExitPoolRequest memory request = IVault.ExitPoolRequest({
			assets: _convertERC20sToAssets(poolTokens),
			minAmountsOut: amountsOut,
			userData: userData,
			toInternalBalance: false // send tokens back to us vs keeping inside vault for later use
		});

		vault.exitPool(
			poolId,
			address(this), // sender,
			payable(address(this)), // recipient,
			request
		);

		// make sure we burned bpt, and assets were received
		require(IERC20(poolAddress).balanceOf(address(this)) < bptBalanceBefore, "BPT_MUST_DECREASE");
		for (uint256 i = 0; i < numTokens; ++i) {
			require(
				poolTokens[i].balanceOf(address(this)) >= assetBalancesBefore[i].add(amountsOut[i]),
				"ASSET_MUST_INCREASE"
			);
		}
	}

	/// @dev Make sure vault has our approval for given token (reset prev approval)
	function _approve(IERC20 token, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), address(vault));
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(address(vault), currentAllowance);
		}
		token.safeIncreaseAllowance(address(vault), amount);
	}

	/**
	 * @dev This helper function is a fast and cheap way to convert between IERC20[] and IAsset[] types
	 */
	function _convertERC20sToAssets(IERC20[] memory tokens) internal pure returns (IAsset[] memory assets) {
		// solhint-disable-next-line no-inline-assembly
		assembly {
			assets := tokens
		}
	}
}

/* forked from balancer monorepo / had to be adjusted due to mismatch in needed compiler version */
// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/IERC20.sol";
// import "@balancer-labs/v2-solidity-utils/contracts/helpers/ISignaturesValidator.sol";
// import "@balancer-labs/v2-solidity-utils/contracts/helpers/ITemporarilyPausable.sol";
// import "@balancer-labs/v2-solidity-utils/contracts/misc/IWETH.sol";

import "./IAsset.sol";
// import "./IAuthorizer.sol";
// import "./IFlashLoanRecipient.sol";
// import "./IProtocolFeesCollector.sol";

pragma solidity >=0.6.11 <=0.6.12;

/**
 * @dev Full external interface for the Vault core contract - no external or public methods exist in the contract that
 * don't override one of these declarations.
 */
interface IVault {
	// is ISignaturesValidator, ITemporarilyPausable {
	// Generalities about the Vault:
	//
	// - Whenever documentation refers to 'tokens', it strictly refers to ERC20-compliant token contracts. Tokens are
	// transferred out of the Vault by calling the `IERC20.transfer` function, and transferred in by calling
	// `IERC20.transferFrom`. In these cases, the sender must have previously allowed the Vault to use their tokens by
	// calling `IERC20.approve`. The only deviation from the ERC20 standard that is supported is functions not returning
	// a boolean value: in these scenarios, a non-reverting call is assumed to be successful.
	//
	// - All non-view functions in the Vault are non-reentrant: calling them while another one is mid-execution (e.g.
	// while execution control is transferred to a token contract during a swap) will result in a revert. View
	// functions can be called in a re-reentrant way, but doing so might cause them to return inconsistent results.
	// Contracts calling view functions in the Vault must make sure the Vault has not already been entered.
	//
	// - View functions revert if referring to either unregistered Pools, or unregistered tokens for registered Pools.

	// Authorizer
	//
	// Some system actions are permissioned, like setting and collecting protocol fees. This permissioning system exists
	// outside of the Vault in the Authorizer contract: the Vault simply calls the Authorizer to check if the caller
	// can perform a given action.

	/**
	 * @dev Returns the Vault's Authorizer.
	 */
	// function getAuthorizer() external view returns (IAuthorizer);

	/**
	 * @dev Sets a new Authorizer for the Vault. The caller must be allowed by the current Authorizer to do this.
	 *
	 * Emits an `AuthorizerChanged` event.
	 */
	// function setAuthorizer(IAuthorizer newAuthorizer) external;

	/**
	 * @dev Emitted when a new authorizer is set by `setAuthorizer`.
	 */
	// event AuthorizerChanged(IAuthorizer indexed newAuthorizer);

	// Relayers
	//
	// Additionally, it is possible for an account to perform certain actions on behalf of another one, using their
	// Vault ERC20 allowance and Internal Balance. These accounts are said to be 'relayers' for these Vault functions,
	// and are expected to be smart contracts with sound authentication mechanisms. For an account to be able to wield
	// this power, two things must occur:
	//  - The Authorizer must grant the account the permission to be a relayer for the relevant Vault function. This
	//    means that Balancer governance must approve each individual contract to act as a relayer for the intended
	//    functions.
	//  - Each user must approve the relayer to act on their behalf.
	// This double protection means users cannot be tricked into approving malicious relayers (because they will not
	// have been allowed by the Authorizer via governance), nor can malicious relayers approved by a compromised
	// Authorizer or governance drain user funds, since they would also need to be approved by each individual user.

	/**
	 * @dev Returns true if `user` has approved `relayer` to act as a relayer for them.
	 */
	// function hasApprovedRelayer(address user, address relayer) external view returns (bool);

	/**
	 * @dev Allows `relayer` to act as a relayer for `sender` if `approved` is true, and disallows it otherwise.
	 *
	 * Emits a `RelayerApprovalChanged` event.
	 */
	// function setRelayerApproval(
	//     address sender,
	//     address relayer,
	//     bool approved
	// ) external;

	/**
	 * @dev Emitted every time a relayer is approved or disapproved by `setRelayerApproval`.
	 */
	// event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);

	// Internal Balance
	//
	// Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
	// transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
	// when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
	// gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
	//
	// Internal Balance management features batching, which means a single contract call can be used to perform multiple
	// operations of different kinds, with different senders and recipients, at once.

	/**
	 * @dev Returns `user`'s Internal Balance for a set of tokens.
	 */
	// function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

	/**
	 * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
	 * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
	 * it lets integrators reuse a user's Vault allowance.
	 *
	 * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
	 */
	// function manageUserBalance(UserBalanceOp[] memory ops) external payable;

	/**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
	// struct UserBalanceOp {
	//     UserBalanceOpKind kind;
	//     IAsset asset;
	//     uint256 amount;
	//     address sender;
	//     address payable recipient;
	// }

	// There are four possible operations in `manageUserBalance`:
	//
	// - DEPOSIT_INTERNAL
	// Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
	// `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
	//
	// ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
	// and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
	// relevant for relayers).
	//
	// Emits an `InternalBalanceChanged` event.
	//
	//
	// - WITHDRAW_INTERNAL
	// Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
	//
	// ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
	// it to the recipient as ETH.
	//
	// Emits an `InternalBalanceChanged` event.
	//
	//
	// - TRANSFER_INTERNAL
	// Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
	//
	// Reverts if the ETH sentinel value is passed.
	//
	// Emits an `InternalBalanceChanged` event.
	//
	//
	// - TRANSFER_EXTERNAL
	// Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
	// relayers, as it lets them reuse a user's Vault allowance.
	//
	// Reverts if the ETH sentinel value is passed.
	//
	// Emits an `ExternalBalanceTransfer` event.

	// enum UserBalanceOpKind { DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL }

	/**
	 * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
	 * interacting with Pools using Internal Balance.
	 *
	 * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
	 * address.
	 */
	// event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

	/**
	 * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
	 */
	// event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

	// Pools
	//
	// There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
	// functionality:
	//
	//  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
	// balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
	// which increase with the number of registered tokens.
	//
	//  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
	// balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
	// constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
	// independent of the number of registered tokens.
	//
	//  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
	// minimal swap info Pools, these are called via IMinimalSwapInfoPool.

	enum PoolSpecialization {
		GENERAL,
		MINIMAL_SWAP_INFO,
		TWO_TOKEN
	}

	/**
	 * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
	 * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
	 * changed.
	 *
	 * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
	 * depending on the chosen specialization setting. This contract is known as the Pool's contract.
	 *
	 * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
	 * multiple Pools may share the same contract.
	 *
	 * Emits a `PoolRegistered` event.
	 */
	// function registerPool(PoolSpecialization specialization) external returns (bytes32);

	/**
	 * @dev Emitted when a Pool is registered by calling `registerPool`.
	 */
	// event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

	/**
	 * @dev Returns a Pool's contract address and specialization setting.
	 */
	function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

	/**
	 * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
	 *
	 * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
	 * exit by receiving registered tokens, and can only swap registered tokens.
	 *
	 * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
	 * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
	 * ascending order.
	 *
	 * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
	 * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
	 * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
	 * expected to be highly secured smart contracts with sound design principles, and the decision to register an
	 * Asset Manager should not be made lightly.
	 *
	 * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
	 * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
	 * different Asset Manager.
	 *
	 * Emits a `TokensRegistered` event.
	 */
	// function registerTokens(
	//     bytes32 poolId,
	//     IERC20[] memory tokens,
	//     address[] memory assetManagers
	// ) external;

	/**
	 * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
	 */
	// event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

	/**
	 * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
	 *
	 * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
	 * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
	 * must be deregistered in the same `deregisterTokens` call.
	 *
	 * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
	 *
	 * Emits a `TokensDeregistered` event.
	 */
	// function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

	/**
	 * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
	 */
	// event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

	/**
	 * @dev Returns detailed information for a Pool's registered token.
	 *
	 * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
	 * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
	 * equals the sum of `cash` and `managed`.
	 *
	 * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
	 * `managed` or `total` balance to be greater than 2^112 - 1.
	 *
	 * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
	 * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
	 * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
	 * change for this purpose, and will update `lastChangeBlock`.
	 *
	 * `assetManager` is the Pool's token Asset Manager.
	 */
	// function getPoolTokenInfo(bytes32 poolId, IERC20 token)
	//     external
	//     view
	//     returns (
	//         uint256 cash,
	//         uint256 managed,
	//         uint256 lastChangeBlock,
	//         address assetManager
	//     );

	/**
	 * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
	 * the tokens' `balances` changed.
	 *
	 * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
	 * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
	 *
	 * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
	 * order as passed to `registerTokens`.
	 *
	 * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
	 * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
	 * instead.
	 */
	function getPoolTokens(
		bytes32 poolId
	) external view returns (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

	/**
	 * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
	 * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
	 * Pool shares.
	 *
	 * If the caller is not `sender`, it must be an authorized relayer for them.
	 *
	 * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
	 * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
	 * these maximums.
	 *
	 * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
	 * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
	 * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
	 * back to the caller (not the sender, which is important for relayers).
	 *
	 * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
	 * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
	 * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
	 * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
	 *
	 * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
	 * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
	 * withdrawn from Internal Balance: attempting to do so will trigger a revert.
	 *
	 * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
	 * their own custom logic. This typically requires additional information from the user (such as the expected number
	 * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
	 * directly to the Pool's contract, as is `recipient`.
	 *
	 * Emits a `PoolBalanceChanged` event.
	 */
	function joinPool(
		bytes32 poolId,
		address sender,
		address recipient,
		JoinPoolRequest memory request
	) external payable;

	struct JoinPoolRequest {
		IAsset[] assets;
		uint256[] maxAmountsIn;
		bytes userData;
		bool fromInternalBalance;
	}

	/**
	 * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
	 * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
	 * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
	 * `getPoolTokenInfo`).
	 *
	 * If the caller is not `sender`, it must be an authorized relayer for them.
	 *
	 * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
	 * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
	 * it just enforces these minimums.
	 *
	 * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
	 * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
	 * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
	 *
	 * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
	 * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
	 * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
	 * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
	 *
	 * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
	 * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
	 * do so will trigger a revert.
	 *
	 * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
	 * `tokens` array. This array must match the Pool's registered tokens.
	 *
	 * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
	 * their own custom logic. This typically requires additional information from the user (such as the expected number
	 * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
	 * passed directly to the Pool's contract.
	 *
	 * Emits a `PoolBalanceChanged` event.
	 */
	function exitPool(
		bytes32 poolId,
		address sender,
		address payable recipient,
		ExitPoolRequest memory request
	) external;

	struct ExitPoolRequest {
		IAsset[] assets;
		uint256[] minAmountsOut;
		bytes userData;
		bool toInternalBalance;
	}

	/**
	 * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
	 */
	// event PoolBalanceChanged(
	//     bytes32 indexed poolId,
	//     address indexed liquidityProvider,
	//     IERC20[] tokens,
	//     int256[] deltas,
	//     uint256[] protocolFeeAmounts
	// );

	// enum PoolBalanceChangeKind { JOIN, EXIT }

	// Swaps
	//
	// Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
	// they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
	// aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
	//
	// The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
	// In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
	// and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
	// More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
	// individual swaps.
	//
	// There are two swap kinds:
	//  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
	// `onSwap` hook) the amount of tokens out (to send to the recipient).
	//  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
	// (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
	//
	// Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
	// the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
	// tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
	// swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
	// the final intended token.
	//
	// In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
	// Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
	// certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
	// much less gas than they would otherwise.
	//
	// It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
	// Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
	// updating the Pool's internal accounting).
	//
	// To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
	// involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
	// minimum amount of tokens to receive (by passing a negative value) is specified.
	//
	// Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
	// this point in time (e.g. if the transaction failed to be included in a block promptly).
	//
	// If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
	// the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
	// passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
	// same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
	//
	// Finally, Internal Balance can be used when either sending or receiving tokens.

	// enum SwapKind { GIVEN_IN, GIVEN_OUT }

	/**
	 * @dev Performs a swap with a single Pool.
	 *
	 * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
	 * taken from the Pool, which must be greater than or equal to `limit`.
	 *
	 * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
	 * sent to the Pool, which must be less than or equal to `limit`.
	 *
	 * Internal Balance usage and the recipient are determined by the `funds` struct.
	 *
	 * Emits a `Swap` event.
	 */
	// function swap(
	//     SingleSwap memory singleSwap,
	//     FundManagement memory funds,
	//     uint256 limit,
	//     uint256 deadline
	// ) external payable returns (uint256);

	/**
	 * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
	 * the `kind` value.
	 *
	 * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
	 * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
	 *
	 * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
	 * used to extend swap behavior.
	 */
	// struct SingleSwap {
	//     bytes32 poolId;
	//     SwapKind kind;
	//     IAsset assetIn;
	//     IAsset assetOut;
	//     uint256 amount;
	//     bytes userData;
	// }

	/**
	 * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
	 * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
	 *
	 * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
	 * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
	 * the same index in the `assets` array.
	 *
	 * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
	 * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
	 * `amountOut` depending on the swap kind.
	 *
	 * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
	 * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
	 * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
	 *
	 * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
	 * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
	 * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
	 * or unwrapped from WETH by the Vault.
	 *
	 * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
	 * the minimum or maximum amount of each token the vault is allowed to transfer.
	 *
	 * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
	 * equivalent `swap` call.
	 *
	 * Emits `Swap` events.
	 */
	// function batchSwap(
	//     SwapKind kind,
	//     BatchSwapStep[] memory swaps,
	//     IAsset[] memory assets,
	//     FundManagement memory funds,
	//     int256[] memory limits,
	//     uint256 deadline
	// ) external payable returns (int256[] memory);

	/**
	 * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
	 * `assets` array passed to that function, and ETH assets are converted to WETH.
	 *
	 * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
	 * from the previous swap, depending on the swap kind.
	 *
	 * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
	 * used to extend swap behavior.
	 */
	struct BatchSwapStep {
		bytes32 poolId;
		uint256 assetInIndex;
		uint256 assetOutIndex;
		uint256 amount;
		bytes userData;
	}

	/**
	 * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
	 */
	event Swap(
		bytes32 indexed poolId,
		IERC20 indexed tokenIn,
		IERC20 indexed tokenOut,
		uint256 amountIn,
		uint256 amountOut
	);

	/**
	 * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
	 * `recipient` account.
	 *
	 * If the caller is not `sender`, it must be an authorized relayer for them.
	 *
	 * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
	 * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
	 * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
	 * `joinPool`.
	 *
	 * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
	 * transferred. This matches the behavior of `exitPool`.
	 *
	 * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
	 * revert.
	 */
	// struct FundManagement {
	//     address sender;
	//     bool fromInternalBalance;
	//     address payable recipient;
	//     bool toInternalBalance;
	// }

	/**
	 * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
	 * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
	 *
	 * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
	 * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
	 * receives are the same that an equivalent `batchSwap` call would receive.
	 *
	 * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
	 * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
	 * approve them for the Vault, or even know a user's address.
	 *
	 * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
	 * eth_call instead of eth_sendTransaction.
	 */
	// function queryBatchSwap(
	//     SwapKind kind,
	//     BatchSwapStep[] memory swaps,
	//     IAsset[] memory assets,
	//     FundManagement memory funds
	// ) external returns (int256[] memory assetDeltas);

	// Flash Loans

	/**
	 * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
	 * and then reverting unless the tokens plus a proportional protocol fee have been returned.
	 *
	 * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
	 * for each token contract. `tokens` must be sorted in ascending order.
	 *
	 * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
	 * `receiveFlashLoan` call.
	 *
	 * Emits `FlashLoan` events.
	 */
	// function flashLoan(
	//     IFlashLoanRecipient recipient,
	//     IERC20[] memory tokens,
	//     uint256[] memory amounts,
	//     bytes memory userData
	// ) external;

	/**
	 * @dev Emitted for each individual flash loan performed by `flashLoan`.
	 */
	// event FlashLoan(IFlashLoanRecipient indexed recipient, IERC20 indexed token, uint256 amount, uint256 feeAmount);

	// Asset Management
	//
	// Each token registered for a Pool can be assigned an Asset Manager, which is able to freely withdraw the Pool's
	// tokens from the Vault, deposit them, or assign arbitrary values to its `managed` balance (see
	// `getPoolTokenInfo`). This makes them extremely powerful and dangerous. Even if an Asset Manager only directly
	// controls one of the tokens in a Pool, a malicious manager could set that token's balance to manipulate the
	// prices of the other tokens, and then drain the Pool with swaps. The risk of using Asset Managers is therefore
	// not constrained to the tokens they are managing, but extends to the entire Pool's holdings.
	//
	// However, a properly designed Asset Manager smart contract can be safely used for the Pool's benefit,
	// for example by lending unused tokens out for interest, or using them to participate in voting protocols.
	//
	// This concept is unrelated to the IAsset interface.

	/**
	 * @dev Performs a set of Pool balance operations, which may be either withdrawals, deposits or updates.
	 *
	 * Pool Balance management features batching, which means a single contract call can be used to perform multiple
	 * operations of different kinds, with different Pools and tokens, at once.
	 *
	 * For each operation, the caller must be registered as the Asset Manager for `token` in `poolId`.
	 */
	// function managePoolBalance(PoolBalanceOp[] memory ops) external;

	// struct PoolBalanceOp {
	//     PoolBalanceOpKind kind;
	//     bytes32 poolId;
	//     IERC20 token;
	//     uint256 amount;
	// }

	/**
	 * Withdrawals decrease the Pool's cash, but increase its managed balance, leaving the total balance unchanged.
	 *
	 * Deposits increase the Pool's cash, but decrease its managed balance, leaving the total balance unchanged.
	 *
	 * Updates don't affect the Pool's cash balance, but because the managed balance changes, it does alter the total.
	 * The external amount can be either increased or decreased by this call (i.e., reporting a gain or a loss).
	 */
	// enum PoolBalanceOpKind { WITHDRAW, DEPOSIT, UPDATE }

	/**
	 * @dev Emitted when a Pool's token Asset Manager alters its balance via `managePoolBalance`.
	 */
	// event PoolBalanceManaged(
	//     bytes32 indexed poolId,
	//     address indexed assetManager,
	//     IERC20 indexed token,
	//     int256 cashDelta,
	//     int256 managedDelta
	// );

	// Protocol Fees
	//
	// Some operations cause the Vault to collect tokens in the form of protocol fees, which can then be withdrawn by
	// permissioned accounts.
	//
	// There are two kinds of protocol fees:
	//
	//  - flash loan fees: charged on all flash loans, as a percentage of the amounts lent.
	//
	//  - swap fees: a percentage of the fees charged by Pools when performing swaps. For a number of reasons, including
	// swap gas costs and interface simplicity, protocol swap fees are not charged on each individual swap. Rather,
	// Pools are expected to keep track of how much they have charged in swap fees, and pay any outstanding debts to the
	// Vault when they are joined or exited. This prevents users from joining a Pool with unpaid debt, as well as
	// exiting a Pool in debt without first paying their share.

	/**
	 * @dev Returns the current protocol fee module.
	 */
	// function getProtocolFeesCollector() external view returns (IProtocolFeesCollector);

	/**
	 * @dev Safety mechanism to pause most Vault operations in the event of an emergency - typically detection of an
	 * error in some part of the system.
	 *
	 * The Vault can only be paused during an initial time period, after which pausing is forever disabled.
	 *
	 * While the contract is paused, the following features are disabled:
	 * - depositing and transferring internal balance
	 * - transferring external balance (using the Vault's allowance)
	 * - swaps
	 * - joining Pools
	 * - Asset Manager interactions
	 *
	 * Internal Balance can still be withdrawn, and Pools exited.
	 */
	// function setPaused(bool paused) external;

	/**
	 * @dev Returns the Vault's WETH instance.
	 */
	// function WETH() external view returns (IWETH);
	// solhint-disable-previous-line func-name-mixedcase
}

/*
    forked from balancer monorepo (had to be adjusted due to mismatch in needed compiler version):
    https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/interfaces/contracts/pool-weighted/WeightedPoolUserData.sol
*/
// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.6.11 <=0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library WeightedPoolUserData {
	enum JoinKind {
		INIT,
		EXACT_TOKENS_IN_FOR_BPT_OUT,
		TOKEN_IN_FOR_EXACT_BPT_OUT,
		ALL_TOKENS_IN_FOR_EXACT_BPT_OUT,
		ADD_TOKEN
	}
	enum ExitKind {
		EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
		EXACT_BPT_IN_FOR_TOKENS_OUT,
		BPT_IN_FOR_EXACT_TOKENS_OUT,
		REMOVE_TOKEN
	}
}

/* forked from balancer monorepo / had to be adjusted due to mismatch in needed compiler version */
// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.6.11 <=0.6.12;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
	// solhint-disable-previous-line no-empty-blocks
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/balancer/IBalancerPool.sol";
import "./BaseController.sol";

contract BalancerController is BaseController {
	using SafeERC20 for IERC20;
	using Address for address;
	using Address for address payable;
	using SafeMath for uint256;

	/* solhint-disable no-empty-blocks */
	constructor(
		address manager,
		address _accessControl,
		address _addressRegistry
	) public BaseController(manager, _accessControl, _addressRegistry) {}

	/* solhint-enable no-empty-blocks */

	/// @notice Used to deploy liquidity to a Balancer pool
	/// @dev Calls into external contract
	/// @param poolAddress Address of pool to have liquidity added
	/// @param tokens Array of ERC20 tokens to be added to pool
	/// @param amounts Corresponding array of amounts of tokens to be added to a pool
	/// @param data Bytes data passed from manager containing information to be passed to the balancer pool
	function deploy(
		address poolAddress,
		IERC20[] calldata tokens,
		uint256[] calldata amounts,
		bytes calldata data
	) external onlyManager onlyAddLiquidity {
		require(tokens.length == amounts.length, "TOKEN_AMOUNTS_COUNT_MISMATCH");
		require(tokens.length > 0, "TOKENS_AMOUNTS_NOT_PROVIDED");

		for (uint256 i = 0; i < tokens.length; ++i) {
			require(addressRegistry.checkAddress(address(tokens[i]), 0), "INVALID_TOKEN");
			_approve(tokens[i], poolAddress, amounts[i]);
		}

		IBalancerPool pool = IBalancerPool(poolAddress);
		uint256 balanceBefore = pool.balanceOf(address(this));

		//Notes:
		// - If your pool is eligible for weekly BAL rewards, they will be distributed to your LPs automatically
		// - If you contribute significant long-term liquidity to the platform, you can apply to have smart contract deployment gas costs reimbursed from the Balancer Ecosystem fund
		// - The pool is the LP token, All pools in Balancer are also ERC20 tokens known as BPTs \(Balancer Pool Tokens\)
		(uint256 poolAmountOut, uint256[] memory maxAmountsIn) = abi.decode(data, (uint256, uint256[]));
		pool.joinPool(poolAmountOut, maxAmountsIn);

		uint256 balanceAfter = pool.balanceOf(address(this));
		require(balanceAfter > balanceBefore, "MUST_INCREASE");
	}

	/// @notice Used to withdraw liquidity from balancer pools
	/// @dev Calls into external contract
	/// @param poolAddress Address of pool to have liquidity withdrawn
	/// @param data Data to be decoded and passed to pool
	function withdraw(address poolAddress, bytes calldata data) external onlyManager onlyRemoveLiquidity {
		(uint256 poolAmountIn, uint256[] memory minAmountsOut) = abi.decode(data, (uint256, uint256[]));

		IBalancerPool pool = IBalancerPool(poolAddress);
		address[] memory tokens = pool.getFinalTokens();
		uint256[] memory balancesBefore = new uint256[](tokens.length);

		for (uint256 i = 0; i < tokens.length; ++i) {
			balancesBefore[i] = IERC20(tokens[i]).balanceOf(address(this));
		}

		_approve(IERC20(poolAddress), poolAddress, poolAmountIn);
		pool.exitPool(poolAmountIn, minAmountsOut);

		for (uint256 i = 0; i < tokens.length; ++i) {
			uint256 balanceAfter = IERC20(tokens[i]).balanceOf(address(this));
			require(balanceAfter > balancesBefore[i], "MUST_INCREASE");
		}
	}

	function _approve(IERC20 token, address poolAddress, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), poolAddress);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(poolAddress, currentAllowance);
		}
		token.safeIncreaseAllowance(poolAddress, amount);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

/// @title Interface for a Balancer Labs BPool
/// @dev https://docs.balancer.fi/v/v1/smart-contracts/interfaces
interface IBalancerPool {
	event Approval(address indexed src, address indexed dst, uint256 amt);
	event Transfer(address indexed src, address indexed dst, uint256 amt);

	function totalSupply() external view returns (uint256);

	function balanceOf(address whom) external view returns (uint256);

	function allowance(address src, address dst) external view returns (uint256);

	function approve(address dst, uint256 amt) external returns (bool);

	function transfer(address dst, uint256 amt) external returns (bool);

	function transferFrom(address src, address dst, uint256 amt) external returns (bool);

	function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

	function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

	function getBalance(address token) external view returns (uint256);

	function decimals() external view returns (uint8);

	function isFinalized() external view returns (bool);

	function getFinalTokens() external view returns (address[] memory tokens);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IRewardHash.sol";

contract RewardHash is IRewardHash, Ownable {
	using SafeMath for uint256;

	mapping(uint256 => CycleHashTuple) public override cycleHashes;
	uint256 public latestCycleIndex;

	function setCycleHashes(
		uint256 index,
		string calldata latestClaimableIpfsHash,
		string calldata cycleIpfsHash
	) external override onlyOwner {
		require(bytes(latestClaimableIpfsHash).length > 0, "Invalid latestClaimableIpfsHash");
		require(bytes(cycleIpfsHash).length > 0, "Invalid cycleIpfsHash");

		cycleHashes[index] = CycleHashTuple(latestClaimableIpfsHash, cycleIpfsHash);

		if (index >= latestCycleIndex) {
			latestCycleIndex = index;
		}

		emit CycleHashAdded(index, latestClaimableIpfsHash, cycleIpfsHash);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

/**
 *  @title Tracks the IPFS hashes that are generated for rewards
 */
interface IRewardHash {
	struct CycleHashTuple {
		string latestClaimable; // hash of last claimable cycle before/including this cycle
		string cycle; // cycleHash of this cycle
	}

	event CycleHashAdded(uint256 cycleIndex, string latestClaimableHash, string cycleHash);

	/// @notice Sets a new (claimable, cycle) hash tuple for the specified cycle
	/// @param index Cycle index to set. If index >= LatestCycleIndex, CycleHashAdded is emitted
	/// @param latestClaimableIpfsHash IPFS hash of last claimable cycle before/including this cycle
	/// @param cycleIpfsHash IPFS hash of this cycle
	function setCycleHashes(
		uint256 index,
		string calldata latestClaimableIpfsHash,
		string calldata cycleIpfsHash
	) external;

	///@notice Gets hashes for the specified cycle
	///@return latestClaimable lastest claimable hash for specified cycle, cycle latest hash (possibly non-claimable) for specified cycle
	function cycleHashes(uint256 index) external view returns (string memory latestClaimable, string memory cycle);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";

// solhint-disable-next-line
contract PreToke is ERC20PresetMinterPauser("PreToke", "PTOKE") {

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Toke is ERC20Pausable, Ownable {
	uint256 private constant SUPPLY = 100_000_000e18;

	constructor() public ERC20("Tokemak", "TOKE") {
		_mint(msg.sender, SUPPLY); // 100M
	}

	function pause() external onlyOwner {
		_pause();
	}

	function unpause() external onlyOwner {
		_unpause();
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestnetToken is ERC20Pausable, Ownable {
	//solhint-disable-next-line no-empty-blocks
	constructor(string memory name, string memory symbol, uint8 decimals) public ERC20(name, symbol) {
		_setupDecimals(decimals);
	}

	function mint(address to, uint256 amount) external onlyOwner {
		_mint(to, amount);
	}

	function burn(address from, uint256 amount) external onlyOwner {
		_burn(from, amount);
	}

	function pause() external onlyOwner {
		_pause();
	}

	function unpause() external onlyOwner {
		_unpause();
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestOracle is Ownable {
	//solhint-disable-next-line no-empty-blocks
	constructor() public Ownable() {}

	uint80 public _roundId = 92233720368547768165;
	int256 public _answer = 344698605527;
	uint256 public _startedAt = 1631220008;
	uint256 public _updatedAt = 1631220008;
	uint80 public _answeredInRound = 92233720368547768165;

	function setLatestRoundData(
		uint80 roundId,
		int256 answer,
		uint256 startedAt,
		uint256 updatedAt,
		uint80 answeredInRound
	) external onlyOwner {
		_roundId = roundId;
		_answer = answer;
		_startedAt = startedAt;
		_updatedAt = updatedAt;
		_answeredInRound = answeredInRound;
	}

	function latestRoundData()
		public
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
	{
		return (_roundId, _answer, _startedAt, _updatedAt, _answeredInRound);
	}
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.11;
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AirdropPush {
	using SafeERC20 for IERC20;

	/// @notice Used to distribute preToke to seed investors.  Can be used for any ERC20 airdrop
	/// @param token IERC20 interface connected to distrubuted token contract
	/// @param accounts Account addresses to distribute tokens to
	/// @param amounts Amounts to be sent to corresponding addresses
	function distribute(IERC20 token, address[] calldata accounts, uint256[] calldata amounts) external {
		require(accounts.length == amounts.length, "LENGTH_MISMATCH");
		for (uint256 i = 0; i < accounts.length; ++i) {
			token.safeTransferFrom(msg.sender, accounts[i], amounts[i]);
		}
	}
}