//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "./UnstructuredProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract portfolioFactory is Ownable{

    uint totalEventsCreated;
    mapping (string => uint) private tokenTracker;
    address public tokenGlobalImplementation;
    address public buyerGlobalImplementation;
    address[] public tokenCollector;
    address[] public buyerCollector;
    event NewProxyDeploymentAddress (address indexed buyerAddress, address indexed tokenAddress, uint indexed proxyNumber);
    mapping (uint => address) public tokenDeployedInfo;
    mapping (uint => address) public buyerDeployedInfo;
    function showIndexes (string memory _name) external view returns (uint) {
        return tokenTracker[_name];
    }
    constructor(address tokenImplementation, address buyerImplementation){
        tokenGlobalImplementation = tokenImplementation;
        buyerGlobalImplementation = buyerImplementation;
    }

    function create_portfolio(string memory name, string memory symbol) external onlyOwner {
        bytes memory bytecode = type(UnstructuredProxy).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(name,symbol,msg.sender));
        address newTokenProxyAddress;
        address newBuyerProxyAddress;
        assembly {
            newBuyerProxyAddress := create2(0,add(bytecode,32),mload(bytecode),salt)
            newTokenProxyAddress := create2(0,add(bytecode,32),mload(bytecode),salt)
        }
        tokenCollector.push(newTokenProxyAddress);
        buyerCollector.push(newBuyerProxyAddress);
        tokenDeployedInfo[tokenCollector.length] = newTokenProxyAddress;
        buyerDeployedInfo[buyerCollector.length] = newBuyerProxyAddress;
        UnstructuredProxy(payable(newBuyerProxyAddress)).upgradeTo(buyerGlobalImplementation);
        UnstructuredProxy(payable(newTokenProxyAddress)).upgradeTo(tokenGlobalImplementation);
        emit NewProxyDeploymentAddress(newBuyerProxyAddress,newTokenProxyAddress,tokenCollector.length);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Proxy.sol";

contract UnstructuredProxy is Proxy {

    // Storage position of the address of the current implementation
    bytes32 private constant implementationPosition =
    keccak256("org.smartdefi.implementation.address");

    // Storage position of the owner of the contract
    bytes32 private constant proxyOwnerPosition =
    keccak256("org.smartdefi.proxy.owner");

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyProxyOwner() {
        require (msg.sender == proxyOwner(), "Not Proxy owner");
        _;
    }

    /**
    * @dev the constructor sets owner
    */
    constructor() {
        _setUpgradeabilityOwner(msg.sender);
    }

    /**
     * @dev Allows the current owner to transfer ownership
     * @param _newOwner The address to transfer ownership to
     */
    function transferProxyOwnership(address _newOwner)
    public onlyProxyOwner
    {
        require(_newOwner != address(0));
        _setUpgradeabilityOwner(_newOwner);
    }

    /**
     * @dev Allows the proxy owner to upgrade the implementation
     * @param _impl address of the new implementation
     */
    function upgradeTo(address _impl)
    public onlyProxyOwner
    {
        _upgradeTo(_impl);
    }

    /**
     * @dev Tells the address of the current implementation
     * @return impl address of the current implementation
     */
    function _implementation()
    internal
    view
    override
    returns (address impl)
    {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

    function implementation() external view returns (address) {
        return _implementation();
    }

    /**
     * @dev Tells the address of the owner
     * @return owner the address of the owner
     */
    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }

    /**
     * @dev Sets the address of the current implementation
     * @param _newImplementation address of the new implementation
     */
    function _setImplementation(address _newImplementation)
    internal
    {
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, _newImplementation)
        }
    }

    /**
     * @dev Upgrades the implementation address
     * @param _newImplementation address of the new implementation
     */
    function _upgradeTo(address _newImplementation) internal {
        address currentImplementation = _implementation();
        require(currentImplementation != _newImplementation);
        _setImplementation(_newImplementation);
    }

    /**
     * @dev Sets the address of the owner
     */
    function _setUpgradeabilityOwner(address _newProxyOwner)
    internal
    {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

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
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}