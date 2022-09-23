// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./CommonStorage.sol";

/// @title FamiliarProxy
/// @notice Proxy implementation handling contract call forwarding,
/// @notice access controls, and upgradability logic for Familiar dApp.
/// @dev Logic implementation or base contracts other 
/// @dev than CommonStorage must not declare any state variables
contract FamiliarProxy is Proxy, CommonStorage {

    //----------------------- EVENTS -------------------------------------------

    event contractUpgraded(string indexed version, address target);
    event adminChanged(address indexed prevAdmin, address newAdmin);
    event routingUpdated(address indexed role, address target);
    event currentVersion(string indexed version, address target);
    event currentRouting(address role, address target);

    //--------------------  CONSTRUCTOR ----------------------------------------

    /// @notice Sets up the initial routing configuration for the different roles.
    /// @dev Maintains routes for special roles Admin and IMX.
    /// @param _routingConfig   is address of special roles and target implementations 
    constructor(address[] memory _routingConfig) {
        admin = _routingConfig[0]; callRouting[_routingConfig[0]] = _routingConfig[1];
        imx = _routingConfig[2]; callRouting[_routingConfig[2]] = _routingConfig[3];
    }

    /// Access control for proxy functions in line with transparent proxy pattern
    modifier ifAdmin() {
        if (msg.sender == admin) {
            _;
        } else {
            _fallback();
        }
    }

    //------------------- VIEW FUNCTIONS ----------------------------------------

    /// @notice Returns version of current NFT implementation via event
    function getVersion() external ifAdmin {
        address impl = callRouting[address(0)];
        emit currentVersion(version[impl], impl);
    }

    function _implementation() internal view override returns (address) {
        address route = callRouting[msg.sender];
        if(route == address(0)) return callRouting[address(0)];
        return route;
    }

    /// @notice Returns route for given role via event
    function getRouting(address _role) external ifAdmin {
        emit currentRouting(_role, callRouting[_role]);
    }

    //-------------------- MUTATIVE FUNCTIONS ----------------------------------

    /// @notice Starts upgrade and initialization process for new NFT implementation
    /// @dev New NFT contract must be valid (implements ERC721, ERC721Metadata, ERC165, and Initializable).
    /// @dev First index of initData provide version information.
    /// @param _impl        new ERC165-compliant NFT implementation
    /// @param _initData    data to be passed to new contract for initialization.
    function upgradeInit(IERC165 _impl, bytes[] calldata _initData) external ifAdmin {
        require(!initializing, "Proxy: Initialization in progress");
        require(!initialized[address(_impl)], "Proxy: Contract already initialized");
        bool validTarget = 
            _impl.supportsInterface(0x80ac58cd) &&      // IERC721
            _impl.supportsInterface(0x5b5e139f) &&      // IERC721Metadata
            _impl.supportsInterface(0x2a55205a) &&      // IERC2981
            _impl.supportsInterface(0x459fb2ad);        // IInitializable
        require(validTarget, "Proxy: Invalid upgrade target");

        initializing = true;
        callRouting[address(0)] = address(_impl);
        version[address(_impl)] = string(_initData[0]);

        (bool success, ) = address(_impl).delegatecall(abi.encodeWithSignature("init(bytes[])", _initData));
        require(success, "Proxy: Initialization failed");

        initialized[address(_impl)] = true;
        initializing = false;
        emit contractUpgraded(string(_initData[0]), address(_impl));
    }

    /// @notice Transfer administrator to new address
    /// @param _newAdmin    address of new administrator. Cannot be address 0
    function changeAdmin(address _newAdmin) external ifAdmin {
        require(_newAdmin != address(0), "Proxy: Invalid admin address");
        address oldAdmin = admin;
        admin = _newAdmin;
        emit adminChanged(oldAdmin, _newAdmin);
    }  

    /// @notice Renounces administrator rights forever
    function renounceAdmin() external ifAdmin {
        address oldAdmin = admin;
        admin = address(0);
        callRouting[oldAdmin] = address(0);
        emit adminChanged(oldAdmin, address(0));
    }  
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

/// @title CommonStorage
/// @notice Defines all state variables to be maintained by proxy and
/// @notice implementation contracts.
abstract contract CommonStorage {

    //------------------ STATE VARIABLES ---------------------------------------
    
    // Maintain IMX integration data
    address internal imx;
    mapping(uint256 => bytes) internal blueprints;

    // Maintain ERC721 NFT and royalty data
    string internal names;
    string internal symbols;
    string internal rootURI;
    mapping(uint256 => address) internal owners;
    mapping(address => uint256) internal balances;
    mapping(uint256 => address) internal tokenApprovals;
    mapping(address => mapping(address => bool)) internal operatorApprovals;
    struct RoyaltyInfo { address receiver; uint96 royaltyFraction; }
    RoyaltyInfo internal defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) internal tokenRoyaltyInfo;

    // Maintain proxy administration and routing data
    address internal admin;
    bool internal initializing;
    mapping(address => bool) internal initialized;
    mapping(address => address) internal callRouting;
    mapping(address => string) internal version;

    // Maintain generic state variables
    // Pattern to allow expansion of state variables in future implementations
    // without risking storage-collision
    mapping(string => address) internal address_;
    mapping(string => uint) internal uint_;
    mapping(string => int) internal int_;
    mapping(string => bytes) internal bytes_;
    mapping(string => string) internal string_;
    mapping(string => bool) internal bool_;
    mapping(string => bytes[]) internal array_;
    mapping(string => mapping(string => bytes[])) internal mapping_;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

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
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
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
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}