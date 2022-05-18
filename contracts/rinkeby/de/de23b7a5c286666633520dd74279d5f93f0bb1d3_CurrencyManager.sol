// SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../ICurrencyManager.sol";
import "./ITokenTransferProcessor.sol";
import "./ICurrencyRegistry.sol";

contract CurrencyManager is ICurrencyManager, Ownable {
    ICurrencyRegistry public currencyRegistry;

    address immutable public ERC20TransferProcessor;
    address public exchangeContractAddress;

    event UpdateExchangeContractAddress(
        address indexed account,
        address indexed exchangeContractAddress
    );

    constructor(
        address _ERC20TransferProcessor,
        address _currencyRegistry
    ) {
        ERC20TransferProcessor = _ERC20TransferProcessor;
        currencyRegistry = ICurrencyRegistry(_currencyRegistry);
    }

    function updateExchangeContractAddress(address _exchangeContractAddress) external onlyOwner {
        exchangeContractAddress = _exchangeContractAddress;
    }

    function currencyIsAllowedForCollection(
        address currencyAddress,
        address collectionAddress
    ) external override view returns(bool) {
        return currencyRegistry.currencyIsAllowedForCollection(currencyAddress, collectionAddress);
    }

    function transferFrom(
        address sender,
        address target,
        uint256 amount,
        address currencyAddress
    ) external override {
        require(msg.sender == exchangeContractAddress, "Only Exchange Contract Can Execute Transfer");

        ITokenTransferProcessor(ERC20TransferProcessor).transferFrom(sender, target, amount, currencyAddress);
    }
}

// SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.7;

interface ICurrencyRegistry {
    /**
     * @notice See collections allowed currency.
     * @param cursor cursor (should start at 0 for first request)
     * @param size size of the response (e.g., 50)
     */
    function viewCollectionAllowedCurrencies(
        address collectionAddress,
        uint256 cursor,
        uint256 size
    ) external view returns(address[] memory, uint256);

    function addCurrencyToCollection(
        address collectionAddress,
        address currencyAddress
    ) external;

    function removeCurrencyFromCollection(
        address collectionAddress,
        address currencyAddress
    ) external;

    function currencyIsAllowedForCollection(
        address currencyAddress,
        address collectionAddress
    ) external view returns(bool);
}

// SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.7;

interface ITokenTransferProcessor {
    function transferFrom(
        address sender,
        address target,
        uint256 amount,
        address currencyAddress
    ) external;
}

// SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.7;

interface ICurrencyManager {
    function currencyIsAllowedForCollection(
        address currencyAddress,
        address collectionAddress
    ) external view returns(bool);

    function transferFrom(
        address sender,
        address target,
        uint256 amount,
        address currencyAddress
    ) external;
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