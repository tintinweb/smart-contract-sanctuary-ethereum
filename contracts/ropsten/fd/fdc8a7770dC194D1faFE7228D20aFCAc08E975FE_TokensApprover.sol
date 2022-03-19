//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@plasma-fi/contracts/interfaces/ITokensApprover.sol";

contract TokensApprover is ITokensApprover, Ownable {
    // Contains data for issuing permissions for the token
    mapping(uint256 => ApproveConfig) private _configs;
    uint256 private _configsLength = 0;
    // Contains methods for issuing permissions for tokens
    mapping(address => uint256) private _tokens;

    constructor(ApproveConfig[] memory configs) {
        for (uint256 i = 0; i < configs.length; i++) {
            _addConfig(configs[i]);
        }
    }

    function addConfig(ApproveConfig calldata config) external onlyOwner returns (uint256) {
        return _addConfig(config);
    }

    function setConfig(uint256 id, ApproveConfig calldata config) external onlyOwner returns (uint256) {
        return _setConfig(id, config);
    }

    function setToken(uint256 id, address token) external onlyOwner {
        _setToken(id, token);
    }

    function getConfig(address token) view external returns (ApproveConfig memory) {
        return _getConfig(token);
    }

    function getConfigById(uint256 id) view external returns (ApproveConfig memory) {
        require(id < _configsLength, "Approve config not found");
        return _configs[id];
    }

    function configsLength() view external returns (uint256) {
        return _configsLength;
    }

    function hasConfigured(address token) view external returns (bool) {
        return _tokens[token] > 0;
    }

    function callPermit(address token, bytes calldata permitCallData) external returns (bool, bytes memory) {
        ApproveConfig storage config = _getConfig(token);
        bytes4 selector = _getSelector(permitCallData);

        require(config.permitMethodSelector == selector, "Wrong permit method");

        return token.call(permitCallData);
    }

    function _addConfig(ApproveConfig memory config) internal returns (uint256) {
        _configs[_configsLength++] = config;
        return _configsLength;
    }

    function _setConfig(uint256 id, ApproveConfig memory config) internal returns (uint256) {
        require(id <= _configsLength, "Approve config not found");
        _configs[id] = config;
        return _configsLength;
    }

    function _setToken(uint256 id, address token) internal {
        require(token != address(0), "Invalid token address");
        require(id <= _configsLength, "Approve config not found");

        _tokens[token] = id + 1;
    }

    function _getConfig(address token) view internal returns (ApproveConfig storage) {
        require(_tokens[token] > 0, "Approve config not found");
        return _configs[_tokens[token] - 1];
    }

    function _getSelector(bytes memory data) pure private returns (bytes4 selector) {
        require(data.length >= 4, "Data to short");

        assembly {
            selector := mload(add(data, add(0, 32)))
            // Clean the trailing bytes.
            selector := and(selector, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ITokensApprover {
    /**
     * @notice Data for issuing permissions for the token
     */
    struct ApproveConfig {
        string name;
        string version;
        string domainType;
        string primaryType;
        string noncesMethod;
        string permitMethod;
        bytes4 permitMethodSelector;
    }

    function addConfig(ApproveConfig calldata config) external returns (uint256);

    function setConfig(uint256 id, ApproveConfig calldata config) external returns (uint256);

    function setToken(uint256 id, address token) external;

    function getConfig(address token) view external returns (ApproveConfig memory);

    function getConfigById(uint256 id) view external returns (ApproveConfig memory);

    function configsLength() view external returns (uint256);

    function hasConfigured(address token) view external returns (bool);

    function callPermit(address token, bytes calldata permitCallData) external returns (bool, bytes memory);
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