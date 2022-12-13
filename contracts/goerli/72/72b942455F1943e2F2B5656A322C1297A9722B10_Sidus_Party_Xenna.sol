// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Sidus_Party_Xenna is Ownable, Pausable {
    address payable public beneficiary;
    uint256 public activeAfter; // date of start presale
    uint256 public closedAfter; // date of end presalr
    bool public whitelistMode;
    mapping(address => bool) public userWhiteList;
    // mapping erc20 to 1155 tokenId to card price in this erc20
    uint public priceForCard;

    event Purchase(
        address indexed user,
        address indexed destinationAddress,
        uint amount
    );

    struct GiftStruct {
        address sender;
        uint amount;
    }

    mapping(address => uint) public userBalances;
    // reveiver -> gifts
    mapping(address => GiftStruct[]) public gifts;
    // receiver -> count of gifts
    mapping(address => uint) public giftsSendersCount;

    //  mapping(address => Gift[]) public userGifts;

    constructor(
        address _beneficiary,
        uint256 _activeAfter,
        uint256 _closedAfter
    ) {
        require(_beneficiary != address(0), "No zero addess");
        beneficiary = payable(_beneficiary);
        activeAfter = _activeAfter;
        closedAfter = _closedAfter;
    }

    function registerForPreSale(address destinationAddress, uint amount)
        external
        payable
        whenNotPaused
    {
        require(block.timestamp >= activeAfter, "Cant buy before start");
        require(block.timestamp <= closedAfter, "Cant buy after closed");
        if (whitelistMode) {
            require(userWhiteList[msg.sender], "you are not in whitelist");
        }
        uint userDebt = amount * priceForCard;
        emit Purchase(msg.sender, destinationAddress, amount);

        require(msg.value == userDebt, "not enought eth");
        beneficiary.transfer(msg.value);
        if (destinationAddress == msg.sender) {
            userBalances[msg.sender] += amount;
        } else {
            uint sendersLen = giftsSendersCount[destinationAddress];
            uint foundSender;
            for (uint i; i < sendersLen; ) {
                if (gifts[destinationAddress][i].sender == msg.sender) {
                    gifts[destinationAddress][i].amount += amount;
                    foundSender = 1;
                    break;
                }
                unchecked {
                    i++;
                }
            }
            if (foundSender == 0) {
                // new gift
                GiftStruct memory newGift = GiftStruct(msg.sender, amount);
                gifts[destinationAddress].push(newGift);
                giftsSendersCount[destinationAddress] += 1;
            }
        }
    }

    ///////////////////////////////////////////////////////////////////
    /////  Owners Functions ///////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////

    function setStartStop(uint256 _activeAfter, uint256 _closedAfter)
        external
        onlyOwner
    {
        activeAfter = _activeAfter;
        closedAfter = _closedAfter;
    }

    function setBeneficiary(address payable _beneficiary) external onlyOwner {
        require(_beneficiary != address(0), "No zero addess");
        beneficiary = _beneficiary;
    }

    function setETHPrice(uint256 _newPriceValue) external onlyOwner {
        priceForCard = _newPriceValue;
    }

    function setWhitelist(address user, bool value) external onlyOwner {
        userWhiteList[user] = value;
    }

    function addToWhitelist(address[] calldata _user) external onlyOwner {
        uint arrLen = _user.length;
        for (uint i = 0; i < arrLen; ) {
            userWhiteList[_user[i]] = true;
            unchecked {
                i++;
            }
        }
    }

    function deleteFromWhitelist(address[] calldata _user) external onlyOwner {
        uint arrLen = _user.length;
        for (uint i = 0; i < arrLen; ) {
            unchecked {
                i++;
            }
            userWhiteList[_user[i]] = false;
        }
    }

    function whitelistChangeMode(bool _newValue) external onlyOwner {
        whitelistMode = _newValue;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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