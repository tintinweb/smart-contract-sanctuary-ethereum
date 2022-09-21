// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./GiftStore1155.sol";
import "./Storage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./GiftStoreOperator/IGiftStoreOperator.sol";

contract GiftStore is Ownable, ReentrancyGuard, Storage, ERC1155Holder {
    
    event AddItemToStoreMint(ItemToMint itemToMint);
    event RemoveItemToStoreMint(ItemToMint itemToMint);
    event UpdateStoreMintItem(ItemToMint itemToMint, uint256 index);
    event RemoveStoreMintItem(ItemToMint itemToMint, uint256 index);

    event AddItemToStoreBuy(ItemToBuy itemToBuy);
    event UpdateStoreBuyItem(ItemToBuy itemToBuy, uint256 index);
    event RemoveStoreBuyItem(ItemToBuy itemToBuy, uint256 index);
    
    event MintedAndBuyItem(ItemToMint itemToMint, uint256 amount);
    event MintedAndBuyItemUsingSignature(ItemToMint itemToMint, uint256 amount, string timeStamp);
    event BuyItem(ItemToBuy itemToBuy, uint256 amount, uint256 index);
    event BuyItemUsingSignature(ItemToBuy itemToBuy, uint256 amount, string timeStamp);
    event ClaimItem(ItemToBuy itemToBuy, uint256 amount, uint256 index);

    using ECDSA for bytes;
    IERC20 ydfToken;
    IGiftStoreOperator giftStoreOperator;
    bool public signatureRequired;

    mapping(address => uint256) public nonceMapping;
    address signatureAddress;

    constructor(address _ydfAddress, address _giftStoreOperator) {
        ydfToken = IERC20(_ydfAddress);
        giftStoreOperator = IGiftStoreOperator(_giftStoreOperator);
        signatureRequired = true;
    }

    function setGiftStoreOperator(address _giftStoreOperator)
        external
        onlyOwnerOrOperator
    {
        giftStoreOperator = IGiftStoreOperator(_giftStoreOperator);
    }

    function setSignatureRequired(bool _signatureRequired)
        external
        onlyOwnerOrOperator
    {
        signatureRequired = _signatureRequired;
    }

    function getSignatureAddress() external view returns (address) {
        return signatureAddress;
    }

    function setSignatureAddress(address _address)
        external
        onlyOwnerOrOperator
    {
        signatureAddress = _address;
    }

    function setYDFAddress(address _ydfAddress) external onlyOwnerOrOperator {
        ydfToken = IERC20(_ydfAddress);
    }

    modifier onlyOwnerOrOperator() {
        require(tx.origin == owner() || giftStoreOperator.operators(tx.origin));
        _;
    }

    mapping(uint256 => ItemToMint) public regularMintMaping;
    ItemToMint[] regularMintPool;
    mapping(uint256 => ItemToBuy) public regularBuyMaping;
    ItemToBuy[] regularBuyPool;
    mapping(uint256 => ItemToMint) public mysteryBoxMintMaping;
    ItemToMint[] mysteryBoxMintPool;
    mapping(uint256 => ItemToMint) public raffleMintMaping;
    ItemToMint[] raffleMintPool;

    mapping(uint256 => ItemClaimers) public claimerMapping;

    function getStoreMintItems(GiftType giftType)
        internal
        view
        returns (mapping(uint256 => ItemToMint) storage, ItemToMint[] storage)
    {
        if (giftType == GiftType.RegularItem) {
            return (regularMintMaping, regularMintPool);
        } else if (giftType == GiftType.MysteryBox) {
            return (mysteryBoxMintMaping, mysteryBoxMintPool);
        } else {
            return (raffleMintMaping, raffleMintPool);
        }
    }

    function addItemToStoreMint(ItemToMint memory _itemToMint)
        external
        onlyOwnerOrOperator
    {
        (mapping(uint256 => ItemToMint)
            storage storeItemsToMint, ItemToMint[] storage mintPool) = getStoreMintItems(_itemToMint.giftType);
        ItemToMint memory itemToMint = storeItemsToMint[_itemToMint.index];
        require(
            itemToMint.amount == 0 && itemToMint.contractAddress == address(0),
            "Item Already Exist in Shop"
        );
        storeItemsToMint[_itemToMint.index] = _itemToMint;
        mintPool[_itemToMint.index] = _itemToMint;
        emit AddItemToStoreMint(_itemToMint);
    }

    function updateItemToStoreMint(ItemToMint memory _itemToMint)
        external
        onlyOwnerOrOperator
    {
        (mapping(uint256 => ItemToMint)
            storage storeItemsToMint, ItemToMint[] storage mintPool) = getStoreMintItems(_itemToMint.giftType);
        storeItemsToMint[_itemToMint.index] = _itemToMint;
        mintPool[_itemToMint.index] = _itemToMint;
        emit UpdateStoreMintItem(_itemToMint, _itemToMint.index);
    }

    function removeItemToStoreMint(ItemToMint memory _itemToMint)
        external
        onlyOwnerOrOperator
    {
        (mapping(uint256 => ItemToMint)
            storage storeItemsToMint, ItemToMint[] storage mintPool) = getStoreMintItems(_itemToMint.giftType);
        delete storeItemsToMint[_itemToMint.index];
        delete mintPool[_itemToMint.index];
        emit RemoveStoreMintItem(_itemToMint, _itemToMint.index);
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

        GiftStore1155(_itemToBuy.contractAddress).mintItem(
            buyer,
            id,
            amount,
            itemUri
        );
        regularBuyMaping[_itemToBuy.index] = _itemToBuy;
        regularBuyPool[_itemToBuy.index] = _itemToBuy;
        emit AddItemToStoreBuy(_itemToBuy);
    }

    function updateItemToStoreBuy(ItemToBuy memory _itemToBuy)
        external
        onlyOwnerOrOperator
    {
        regularBuyMaping[_itemToBuy.index] = _itemToBuy;
        regularBuyPool[_itemToBuy.index] = _itemToBuy;
        emit UpdateStoreBuyItem(_itemToBuy, _itemToBuy.index);
    }

    function removeItemToStoreBuy(ItemToBuy memory _itemToBuy)
        external
        onlyOwnerOrOperator
    {
        delete regularBuyMaping[_itemToBuy.index];
        delete regularBuyPool[_itemToBuy.index];
        emit RemoveStoreBuyItem(_itemToBuy, _itemToBuy.index);
    }

    function mintAndBuyItem(
        uint256 index,
        uint256 amount,
        GiftType giftType
    ) external nonReentrant {
        require(!signatureRequired, "Signature Required");
        (mapping(uint256 => ItemToMint)
            storage storeItemsToMint, ItemToMint[] storage itemsToMint) = getStoreMintItems(giftType);
        ItemToMint storage itemToMint = storeItemsToMint[index];
        ItemToMint storage item = itemsToMint[index];

        address buyer = tx.origin;
        uint256 id = itemToMint.tokenID;
        string memory itemUri = itemToMint.itemUri;

        require(
            itemToMint.allowPerWallet >= amount,
            "Can't buy more than limit"
        );
        require(itemToMint.amount >= amount, "Not enough items for sale");
        require(
            ydfToken.balanceOf(buyer) >= amount * itemToMint.price,
            "Not enought YDF tokens"
        );

        ydfToken.transferFrom(buyer, address(this), amount * itemToMint.price);
        itemToMint.amount = itemToMint.amount - amount;
        item.amount = item.amount - amount;
        GiftStore1155(itemToMint.contractAddress).mintItem(
            buyer,
            id,
            amount,
            itemUri
        );
        emit MintedAndBuyItem(itemToMint, amount);
    }

    function buyItem(uint256 index, uint256 amount) external nonReentrant {
        require(!signatureRequired, "Signature Required");
        mapping(uint256 => ItemToBuy)
            storage storeItemsToBuy = regularBuyMaping;
        ItemToBuy storage itemToBuy = storeItemsToBuy[index];
        ItemToBuy storage item = regularBuyPool[index];

        address buyer = tx.origin;
        uint256 id = itemToBuy.tokenID;

        require(itemToBuy.amount >= amount, "Not enough items for sale");
        require(
            ydfToken.balanceOf(buyer) >= amount * itemToBuy.price,
            "Not enought YDF tokens"
        );

        ydfToken.transferFrom(buyer, address(this), amount * itemToBuy.price);
        itemToBuy.amount = itemToBuy.amount - amount;
        item.amount = item.amount - amount;
        GiftStore1155(itemToBuy.contractAddress).safeTransferFrom(
            address(this),
            buyer,
            id,
            amount,
            ""
        );
        emit BuyItem(itemToBuy, amount, index);
    }

    function mintAndBuyItemUsingSignature(
        ItemToMint memory itemToMint,
        uint256 amount,
        string memory timeStamp,
        bytes32 hash,
        bytes memory signature
    ) external nonReentrant {
        address buyer = msg.sender;
        uint256 id = itemToMint.tokenID;
        string memory itemUri = itemToMint.itemUri;

        string memory nonce = Strings.toString(nonceMapping[buyer]);
        bytes memory message = abi.encodePacked(
            nonce,
            timeStamp,
            Strings.toHexString(buyer)
        );
        bytes32 checkingHash = message.toEthSignedMessageHash();
        require(hash == checkingHash, "Invalid hash");
        require(ECDSA.recover(hash, signature) == signatureAddress);
        nonceMapping[buyer]++;

        ydfToken.transferFrom(buyer, address(this), amount * itemToMint.price);
        itemToMint.amount = itemToMint.amount - amount;
        GiftStore1155(itemToMint.contractAddress).mintItem(
            buyer,
            id,
            amount,
            itemUri
        );
        emit MintedAndBuyItemUsingSignature(itemToMint, amount, timeStamp);
    }

    function buyItemUsingSignature(
        ItemToBuy memory itemToBuy,
        uint256 amount,
        string memory timeStamp,
        bytes32 hash,
        bytes memory signature
    ) external nonReentrant {
        address buyer = tx.origin;
        uint256 id = itemToBuy.tokenID;

        string memory nonce = Strings.toString(nonceMapping[buyer]);
        bytes memory message = abi.encodePacked(
            nonce,
            timeStamp,
            Strings.toHexString(buyer)
        );
        bytes32 checkingHash = message.toEthSignedMessageHash();
        require(hash == checkingHash, "Invalid hash");
        require(ECDSA.recover(hash, signature) == signatureAddress);
        nonceMapping[buyer]++;

        ydfToken.transferFrom(buyer, address(this), amount * itemToBuy.price);
        itemToBuy.amount = itemToBuy.amount - amount;
        GiftStore1155(itemToBuy.contractAddress).safeTransferFrom(
            address(this),
            buyer,
            id,
            amount,
            ""
        );
        emit BuyItemUsingSignature(itemToBuy, amount, timeStamp);
    }

    function claimItem(uint256 index, uint256 amount) external nonReentrant {
        ItemToBuy storage itemToClaim = regularBuyMaping[index];

        require(
            itemToClaim.amount != 0 &&
                itemToClaim.contractAddress != address(0),
            "Claimable item not found"
        );
        address claimer = tx.origin;
        uint256 id = itemToClaim.tokenID;

        require(
            GiftStore1155(itemToClaim.contractAddress).balanceOf(claimer, id) >=
                amount,
            "Not enough tokens owned"
        );

        GiftStore1155(itemToClaim.contractAddress).burnItem(
            claimer,
            id,
            amount
        );
        claimerMapping[index].claimers.push(claimer);
        emit ClaimItem(itemToClaim, amount, index);
    }
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

    struct ItemClaimers {
        uint256 index;
        // uint256 startingTime;
        // uint256 endingTime;
        address contractAddress;
        uint256 tokenID;
        uint256 price;
        // bool conditions;
        address[] claimers;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface GiftStore1155 is IERC1155 {
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IGiftStoreOperator {
    function operators(address _address) external returns (bool);

    function addOperator(address _address) external;

    function removeOperator(address _address) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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