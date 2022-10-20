// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../OwnableExt.sol";
import "./ExchangeDomainV1.sol";

contract ExchangeStateV1 is OwnableExt {
    // keccak256(OrderKey) => completed
    mapping(bytes32 => uint256) public completed;

    address public previousStateAddress;

    /// @notice Get the amount of selled tokens.
    /// @param key - the `OrderKey` struct.
    /// @return Selled tokens count for the order.
    function getCompleted(ExchangeDomainV1.OrderKey calldata key)
        external
        view
        returns (uint256)
    {
        uint256 result = completed[getCompletedKey(key)];
        if (previousStateAddress != address(0)) {
            result += ExchangeStateV1(previousStateAddress).getCompleted(key);
        }
        return result;
    }

    /// @notice Sets the new amount of selled tokens. Can be called only by the contract operator.
    /// @param key - the `OrderKey` struct.
    /// @param newCompleted - The new value to set.
    function setCompleted(
        ExchangeDomainV1.OrderKey calldata key,
        uint256 newCompleted
    ) external onlyAdmin {
        completed[getCompletedKey(key)] = newCompleted;
    }

    /// @notice Encode order key to use as the mapping key.
    /// @param key - the `OrderKey` struct.
    /// @return Encoded order key.
    function getCompletedKey(ExchangeDomainV1.OrderKey memory key)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    key.owner,
                    key.sellAsset.token,
                    key.sellAsset.tokenId,
                    key.buyAsset.token,
                    key.buyAsset.tokenId,
                    key.salt
                )
            );
    }

    function setPreviousState(address _previousStateAddress)
        external
        onlyOwner
    {
        previousStateAddress = _previousStateAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnableExt is Ownable {
    mapping(address => bool) public admins;

    modifier onlyAdmin() {
        require(
            admins[msg.sender] || msg.sender == owner(),
            "The sender is not an admin!"
        );
        _;
    }

    modifier checkExistAdmin(address _account) {
        require(
            admins[_account],
            "There is no such administrator in the list!"
        );
        _;
    }

    function addAdmin(address _account) external onlyOwner {
        admins[_account] = true;
    }

    function deleteAdmin(address _account)
        external
        onlyOwner
        checkExistAdmin(_account)
    {
        delete admins[_account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/// @title ExchangeDomainV1
/// @notice Describes all the structs that are used in exchnages.
contract ExchangeDomainV1 {
    enum AssetType {
        ETH,
        ERC20,
        ERC1155,
        ERC721,
        ERC721A
    }

    struct Asset {
        address token;
        uint256 tokenId;
        AssetType assetType;
    }

    struct OrderKey {
        /* who signed the order */
        address owner;
        /* random number */
        uint256 salt;
        /* what has owner */
        Asset sellAsset;
        /* what wants owner */
        Asset buyAsset;
    }

    struct Order {
        OrderKey key;
        /* how much has owner (in wei, or UINT256_MAX if ERC-721) */
        uint256 selling;
        /* how much wants owner (in wei, or UINT256_MAX if ERC-721) */
        uint256 buying;
        /* fee for selling. Represented as percents * 100 (100% - 10000. 1% - 100)*/
        uint256 sellerFee;
    }

    /* An ECDSA signature. */
    struct ECDSASig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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