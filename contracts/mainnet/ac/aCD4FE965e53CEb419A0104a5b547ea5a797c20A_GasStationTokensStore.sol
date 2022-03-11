//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGasStationTokensStore.sol";

contract GasStationTokensStore is IGasStationTokensStore, Ownable {
    // Fee Tokens Storage
    mapping(address => bool) private feeAllowedTokens;
    address[] private feeTokensAddresses;
    mapping(address => uint256) private feeTokensAddressesIndexes;

    constructor(address[] memory _feeTokens) {
        for (uint256 i = 0; i < _feeTokens.length; i++) {
            _addFeeToken(_feeTokens[i]);
        }
    }

    function feeTokens() external view returns (address[] memory) {
        return feeTokensAddresses;
    }

    function isAllowedToken(address _token) external view returns (bool) {
        return feeAllowedTokens[_token];
    }

    function addFeeToken(address _token) external onlyOwner {
        require(_token != address(0), 'Cannot use zero address');
        require(!feeAllowedTokens[_token], 'Token already allowed');

        _addFeeToken(_token);
    }

    function removeFeeToken(address _token) external onlyOwner {
        require(_token != address(0), 'Cannot use zero address');
        require(feeAllowedTokens[_token], 'Token already deny');

        _removeFeeToken(_token);
    }

    function _addFeeToken(address _token) internal {
        if (_token != address(0) && !feeAllowedTokens[_token]) {
            feeAllowedTokens[_token] = true;
            feeTokensAddresses.push(_token);
            feeTokensAddressesIndexes[_token] = feeTokensAddresses.length;
        }
    }

    function _removeFeeToken(address _token) internal {
        if (_token != address(0) && feeAllowedTokens[_token]) {
            feeAllowedTokens[_token] = false;

            // Search indexes
            uint256 feeTokenIndex = feeTokensAddressesIndexes[_token];
            uint256 toDeleteIndex = feeTokenIndex - 1;
            uint256 lastIndex = feeTokensAddresses.length - 1;

            // Swapping the last and deleted token address
            address lastFeeTokenAddress = feeTokensAddresses[lastIndex];
            feeTokensAddresses[toDeleteIndex] = lastFeeTokenAddress;
            feeTokensAddressesIndexes[lastFeeTokenAddress] = toDeleteIndex + 1;

            // Remove last token address
            feeTokensAddresses.pop();
            delete feeTokensAddressesIndexes[_token];
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IGasStationTokensStore {
    function feeTokens() external view returns (address[] memory);
    function addFeeToken(address _token) external;
    function removeFeeToken(address _token) external;
    function isAllowedToken(address _token) external view returns (bool);
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