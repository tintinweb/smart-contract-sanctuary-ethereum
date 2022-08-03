// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IERC1155.sol";
import "./Storage.sol";
import "./GiftStoreOperator.sol";

contract GiftStore is Ownable, ReentrancyGuard, Storage {
    address YDFAddress;
    GiftStoreOperator giftStoreOperator;

    constructor(address _ydfAddress, address _giftStoreOperator) {
        YDFAddress = _ydfAddress;
        giftStoreOperator = GiftStoreOperator(_giftStoreOperator);
    }

    function setGiftStoreOperator(address _giftStoreOperator)
        external
        onlyOwner
    {
        giftStoreOperator = GiftStoreOperator(_giftStoreOperator);
    }

    modifier onlyOwnerOrOperator() {
        require(tx.origin == owner() || giftStoreOperator.operators(tx.origin));
        _;
    }

    mapping(uint256 => ItemToMint) regularMintMaping;
    mapping(uint256 => ItemToBuy) regularBuyMaping;
    mapping(uint256 => ItemToMint) mysteryBoxMintMaping;
    mapping(uint256 => ItemToMint) raffleMintMaping;

    function setYDFAddress(address _ydfAddress) external onlyOwnerOrOperator {
        YDFAddress = _ydfAddress;
    }

    function getStoreMintItems(GiftType giftType)
        internal
        view
        returns (mapping(uint256 => ItemToMint) storage)
    {
        if (giftType == GiftType.RegularItem) {
            return regularMintMaping;
        } else if (giftType == GiftType.MysteryBox) {
            return mysteryBoxMintMaping;
        } else {
            return raffleMintMaping;
        }
    }

    function addItemToStoreMint(ItemToMint memory _itemToMint)
        external
        onlyOwnerOrOperator
    {
        mapping(uint256 => ItemToMint)
            storage storeItemsToMint = getStoreMintItems(_itemToMint.giftType);
        ItemToMint memory itemToMint = storeItemsToMint[_itemToMint.index];
        require(
            itemToMint.amount == 0 && itemToMint.contractAddress == address(0),
            "Item Already Exist in Shop"
        );
        storeItemsToMint[_itemToMint.index] = _itemToMint;
    }

    function addItemToStoreBuy(ItemToBuy memory _itemToBuy)
        external
        onlyOwnerOrOperator
    {
        ItemToBuy memory itemToBuy = regularBuyMaping[_itemToBuy.index];
        require(
            itemToBuy.amount == 0 && itemToBuy.contractAddress == address(0),
            "Gift Item at index already present"
        );

        address buyer = address(this);
        uint256 id = _itemToBuy.tokenID;
        uint256 amount = _itemToBuy.amount;
        string memory itemUri = _itemToBuy.itemUri;

        IERC1155(itemToBuy.contractAddress).mintItem(
            buyer,
            id,
            amount,
            itemUri
        );
        regularBuyMaping[_itemToBuy.index] = _itemToBuy;
    }

    function mintAndBuyItem(
        uint256 index,
        uint256 amount,
        GiftType giftType
    ) external nonReentrant {
        mapping(uint256 => ItemToMint)
            storage storeItemsToMint = getStoreMintItems(giftType);
        ItemToMint storage itemToMint = storeItemsToMint[index];

        address buyer = tx.origin;
        uint256 id = itemToMint.tokenID;
        string memory itemUri = itemToMint.itemUri;

        require(
            itemToMint.allowPerWallet >= amount,
            "Can't buy more than limit"
        );
        require(itemToMint.amount >= amount, "Not enough items for sale");
        require(
            IERC20(YDFAddress).balanceOf(buyer) >=
                itemToMint.amount * itemToMint.price,
            "Not enought YDF tokens"
        );

        IERC20(YDFAddress).transferFrom(
            buyer,
            address(this),
            amount * itemToMint.price
        );
        itemToMint.amount -= amount;
        IERC1155(itemToMint.contractAddress).mintItem(
            buyer,
            id,
            amount,
            itemUri
        );
    }

    function buyItem(uint256 index, uint256 amount) external nonReentrant {
        mapping(uint256 => ItemToBuy)
            storage storeItemsToBuy = regularBuyMaping;
        ItemToBuy storage itemToBuy = storeItemsToBuy[index];

        address buyer = tx.origin;
        uint256 id = itemToBuy.tokenID;

        require(itemToBuy.amount >= amount, "Not enough items for sale");
        require(
            IERC20(YDFAddress).balanceOf(buyer) >=
                itemToBuy.amount * itemToBuy.price,
            "Not enought YDF tokens"
        );

        IERC20(YDFAddress).transferFrom(
            buyer,
            address(this),
            amount * itemToBuy.price
        );
        itemToBuy.amount -= amount;
        IERC1155(itemToBuy.contractAddress).safeTransferFrom(
            address(this),
            buyer,
            id,
            amount,
            ""
        );
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC1155 {
    function mintItem(
        address to,
        uint256 id,
        uint256 amount,
        string memory tokenUri
    ) external;

    function burnItem(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface Storage {
    enum GiftType {
        RegularItem,
        MysteryBox,
        Raffle
    }

    enum ContractType {
        ERC721,
        ERC1155
    }

    //ItemToMint (0, 1, 0xE5A813864F64F21BD5eE6Aa7c67F43048dAA8817, 1, 10)
    struct ItemToMint {
        uint256 index;
        // uint256 startingTime;
        // uint256 endingTime;
        GiftType giftType;
        // bool claimable;
        // ContractType contractType; // ERC721 or ERC1155
        address contractAddress;
        uint256 tokenID;
        uint256 amount;
        uint256 price;
        uint256 allowPerWallet;
        string itemUri;
        // bool conditions; // 9tales level condition
    }

    struct ItemToBuy {
        uint256 index;
        // uint256 startingTime;
        // uint256 endingTime;
        ContractType contractType; // ERC721 or ERC1155
        address contractAddress;
        uint256 tokenID;
        uint256 amount;
        uint256 price;
        string itemUri;
        // bool conditions; // 9tales level condition
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GiftStoreOperator is Ownable {
    mapping(address => bool) public operators;

    constructor() {
        operators[owner()] = true;
    }

    modifier onlyOperator() {
        require(operators[tx.origin], "Function only accessable to Operators");
        _;
    }

    function addOperator(address operator) external onlyOperator {
        operators[operator] = true;
    }

    function removeOperator(address operator) external onlyOperator {
        operators[operator] = false;
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