/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

/**
 *Submitted for verification at BscScan.com on 2022-07-26
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File contracts/NFTCreator/interfaces/INFTCreatorFactory.sol

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface INFTCreatorFactory {
    event TokenDeployed(address indexed _token, bool _isERC1155, bool _is2FA);

    function deploy721(
        bool _is2FA,
        uint96 _royalty,
        address _minter,
        uint256 _maxSupply,
        string memory _uri,
        string memory _name,
        string memory _symbol
    ) external returns (address);

    function deploy1155(
        bool _is2FA,
        uint96 _royalty,
        address _minter,
        uint256 _maxSupply,
        string memory _uri
    ) external returns (address);
}


// File @openzeppelin/contracts/proxy/[email protected]


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


// File contracts/NFTCreator/tokens/NFTFairTokenProxy.sol



pragma solidity ^0.8.0;

contract NFTFairTokenProxy is Proxy {
    address private _impl;

    constructor(address _tokenImpl, bytes memory _data) {
        (bool success, ) = _tokenImpl.delegatecall(_data);
        require(success, "Token initialization failed");
        _impl = _tokenImpl;
    }

    function _implementation() internal view override returns (address) {
        return _impl;
    }

    function implementation() external view returns (address) {
        return _impl;
    }
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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


// File contracts/NFTCreator/NFTCreatorFactory.sol



pragma solidity ^0.8.0;



contract NFTCreatorFactory is INFTCreatorFactory, Ownable {
    enum TokenType {
        ERC1155,
        ERC721
    }

    mapping(TokenType => mapping(bool => address)) public implementations;

    event ImplSet(TokenType tokenType, bool is2FA, address impl);

    function deploy721(
        bool _is2FA,
        uint96 _royalty,
        address _minter,
        uint256 _maxSupply,
        string memory _uri,
        string memory _name,
        string memory _symbol
    ) external override returns (address) {
        address impl = implementations[TokenType.ERC721][_is2FA];
        require(impl != address(0), "NFTCreator: Token impl not configured");
        bytes memory constructorArgs = abi.encode(_royalty, msg.sender, _minter, _maxSupply, _name, _symbol, _uri);
        return _deploy(impl, false, _is2FA, constructorArgs);
    }

    function deploy1155(
        bool _is2FA,
        uint96 _royalty,
        address _minter,
        uint256 _maxSupply,
        string memory _uri
    ) external override returns (address) {
        address impl = implementations[TokenType.ERC1155][_is2FA];
        require(impl != address(0), "NFTCreator: Token impl not configured");
        bytes memory constructorArgs = abi.encode(_royalty, msg.sender, _minter, _maxSupply, _uri);
        return _deploy(impl, true, _is2FA, constructorArgs);
    }

    // === RESTRICTED ===
    function setImplementation(
        TokenType tokenType,
        bool is2FA,
        address impl
    ) external onlyOwner {
        implementations[tokenType][is2FA] = impl;
        emit ImplSet(tokenType, is2FA, impl);
    }

    // === INTERNAL ===
    function _deploy(
        address impl,
        bool isERC1155,
        bool is2FA,
        bytes memory data
    ) private returns (address) {
        address token;
        bytes memory initData = _generateInitData(isERC1155, data);
        bytes memory paramData = abi.encode(impl, initData);
        bytes memory bytecode = abi.encodePacked(type(NFTFairTokenProxy).creationCode, paramData);
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, data));
        assembly {
            token := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(token != address(0), "NFTCreator: Token creation failed");
        emit TokenDeployed(token, isERC1155, is2FA);
        return token;
    }

    function _generateInitData(bool isERC1155, bytes memory data) private pure returns (bytes memory res) {
        bytes4 selector;
        if (isERC1155) {
            selector = 0xca6b4cf4;
        } else {
            selector = 0x2158707b;
        }
        res = abi.encodePacked(selector, data);
    }
}