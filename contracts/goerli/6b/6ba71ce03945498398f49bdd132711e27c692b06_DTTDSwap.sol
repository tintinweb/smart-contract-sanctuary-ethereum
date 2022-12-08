// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title A contract to facilitate private swaps of NFTs and fungible tokens between multipe wallets
 * @author irreverent.eth @ DTTD
 * @notice https://dttd.io/
 * @notice This contract is intended to be used in conjunction within the DTTD ecosystem, with its off-chain swaps
           tracking and signing system as essential components of completing a swap.
 */

//    ___    _____   _____    ___   
//   |   \  |_   _| |_   _|  |   \  
//   | |) |   | |     | |    | |) | 
//   |___/   _|_|_   _|_|_   |___/  
// _|"""""|_|"""""|_|"""""|_|"""""| 
// "`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-' 

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/cryptography/SignatureChecker.sol";
import "openzeppelin-contracts/security/Pausable.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/token/ERC1155/IERC1155.sol";

import { IDTTDSwap } from "./IDTTDSwap.sol";
import { Swap, Offer, OfferItem, SWAP_TYPEHASH, OFFER_TYPEHASH, OFFERITEM_TYPEHASH } from "./DTTDStructs.sol";
import { OfferItemType } from "./DTTDEnums.sol";


contract DTTDSwap is Ownable, Pausable, IDTTDSwap {

    constructor(address _authority) {
        if(_authority == address(0)) { revert("SetInvalidAuthority"); }
        authority = _authority;
    }


    /*//////////////////////////////////////////////////////////////
                        STORAGE MAPPINGS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev swapNonce is a global nonce for all swaps and their versions.  Not all will end up on chain as the
            negotiation process will result in some being skipped.  If swapNonce exists already, revert, because we
            want to perform the same Swap only once.
     */
    mapping (uint256 => bool) public executedSwapNonce;

    /**
     * @dev blockedSwapHash is a mapping of swapHashes that are blocked from being executed
     */
    mapping (bytes32 => bool) public blockedSwapHash;


    /*//////////////////////////////////////////////////////////////
                        AUTHORITY LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice The authority address for the last signature needed for a swap
     */
    address public authority;

    /**
     * @notice Sets a new authority to be used.
     * @dev Cannot be 0x0 and owner settable only
     */
    function setAuthority(address _authority) external onlyOwner {
        if(_authority == address(0)) { revert("SetInvalidAuthority"); }
        authority = _authority;
    }


    /*//////////////////////////////////////////////////////////////
                        PAUSIBLE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Pauses all swaps in case of emergencies
     */
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }


    /*//////////////////////////////////////////////////////////////
                        SIGNATURE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev The EIP712 domain separator for this contract, using predetermined hash values
     *      EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
     *      EIP721_DOMAIN_NAME_HASH = keccak256("DTTD Private Swap");
     */
    bytes32 public immutable domainSeparator = keccak256(abi.encode(
        0x8cad95687ba82c2ce50e74f7b754645e5117c3a5bec8151c0726d5857980a866, // EIP712_DOMAIN_TYPEHASH
        0x3ef8fd112a48aa32ffdc7138bdecf127ca9d363377cf6553bb738d49d484a699, // EIP721_DOMAIN_NAME_HASH
        block.chainid,
        address(this)
    ));

    /**
     * @dev Hash a Swap struct for EIP712 signing
     */
    function hashSwap(Swap calldata _swap) public view returns (bytes32) {
        bytes32[] memory offerHashes = new bytes32[](_swap.offer.length);
        for (uint i = 0; i < _swap.offer.length; i++) {
            offerHashes[i] = _hashOffer(_swap.offer[i]);
        }
        return keccak256(abi.encodePacked(
            "\x19\x01",
            domainSeparator,
            keccak256(abi.encode(
                SWAP_TYPEHASH,
                keccak256(abi.encodePacked(offerHashes)),
                _swap.endTime,
                _swap.swapNonce
            ))
        ));
    }

    /**
     * @dev Hash a Offer struct
     */
    function _hashOffer(Offer calldata _offer) internal pure returns (bytes32) {
        bytes32[] memory offerItemHashes = new bytes32[](_offer.offerItem.length);
        for (uint i = 0; i < _offer.offerItem.length; i++) {
            offerItemHashes[i] = _hashOfferItem(_offer.offerItem[i]);
        }
        return keccak256(abi.encode(
            OFFER_TYPEHASH,
            keccak256(abi.encodePacked(offerItemHashes)),
            _offer.from
        ));
    }

    /**
     * @dev Hash a OfferItem struct
     */
    function _hashOfferItem(
        OfferItem calldata _offerItem
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            OFFERITEM_TYPEHASH,
            _offerItem.to,
            _offerItem.offerItemType,
            _offerItem.token,
            _offerItem.identifier,
            _offerItem.amount
        ));
    }


    /*//////////////////////////////////////////////////////////////
                        MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Ensures that the swap nonce has yet been executed
     */
    modifier ensureUnusedSwapNonce(uint256 _swapNonce) {
        if (executedSwapNonce[_swapNonce]) { revert("SwapExecuted"); }
      _;
   }

    /**
     * @dev Ensures that the swap is not yet expired.  As the time limit of a
            swap is usually in hours and days, manipulated block.timestamp is
            not a concern.
     */
    modifier ensureNotExpired(uint256 _expiry) {
        if (block.timestamp > _expiry) { revert("SwapExpired"); }
      _;
   }


    /*//////////////////////////////////////////////////////////////
                        CORE SWAP LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Executes a swap by checking the signatures and performing the transfers.  Token approvals are required.
     * @dev the signature.length is expected to be 1+swap.offer.length
     */
    function performSwap(
        Swap calldata _swap,
        bytes[] calldata _signature
    ) external
      payable
      whenNotPaused
      ensureUnusedSwapNonce(_swap.swapNonce)
      ensureNotExpired(_swap.endTime)
    {

        uint256 totalOffers = _swap.offer.length;

        if (totalOffers < 1) { revert("TooFewOffers"); }

        if (_signature.length != totalOffers + 1) { revert("WrongSigCount"); }

        // Get the swap hash of a Swap
        bytes32 swapHash = hashSwap(_swap);

        // Check if the Swap has been blocked
        if (blockedSwapHash[swapHash]) {
            revert("SwapBlocked");
        }

        // Each offer has a signature at the corresponding index signed by the offerer
        // The extra and last signature should be the authority signature
        bool validAuthority = SignatureChecker.isValidSignatureNow(authority, swapHash, _signature[totalOffers]);
        if(!validAuthority) { revert("InvalidAuthSig"); }

        uint256 remainingFunds = msg.value;

        // set swapNonce so this Swap cannot happen again
        executedSwapNonce[_swap.swapNonce] = true;

        // Iterate over each offer to check the signature and perform the transfers
        for (uint256 i = 0; i < totalOffers; i++) {
            Offer calldata offer = _swap.offer[i];
            
            uint256 totalOfferItems = offer.offerItem.length;
            address from = offer.from;

            // Check signature unless the offerer is the msg.sender
            if (from != msg.sender) {
                bool validSignature = SignatureChecker.isValidSignatureNow(from, swapHash, _signature[i]);
                if(!validSignature) { revert("InvalidSig"); }
            }

            // Iterate over each offer item now that signature is ok
            for (uint256 j = 0; j < totalOfferItems; j++) {
                OfferItem calldata offerItem = offer.offerItem[j];

                // Check if the offer item value can be converted into the enum
                if (offerItem.offerItemType > 3) { revert("UnknownItemType"); }
                OfferItemType itemType = OfferItemType(offerItem.offerItemType);

                address to = offerItem.to;
                if (to == address(0x0)) { revert("InvalidRecipient"); }

                if (itemType == OfferItemType.ERC721) {
                    // Handle ERC721 transfers
                    IERC721 token = IERC721(offerItem.token);
                    uint256 identifier = offerItem.identifier;
                    
                    token.safeTransferFrom(from, to, identifier);
                } else if (itemType == OfferItemType.ERC1155) {
                    // Handle ERC1155 transfers
                    IERC1155 token = IERC1155(offerItem.token);
                    uint256 identifier = offerItem.identifier;
                    uint256 amount = offerItem.amount;

                    // disallow 0 amount
                    if (amount == 0) { revert("ZeroAmount"); }

                    token.safeTransferFrom(from, to, identifier, amount, "");
                } else if (itemType == OfferItemType.ERC20) {
                    // Handle ERC20 transfers
                    address token = offerItem.token;
                    uint256 amount = offerItem.amount;
                    if (amount == 0) { revert("ZeroAmount"); }

                    (bool ok, bytes memory data) = token.call(
                        abi.encodeWithSelector(
                            IERC20.transferFrom.selector,
                            from,
                            to,
                            amount
                        )
                    );

                    if (!ok || data.length != 32) {
                        revert("ERC20SendFail");
                    }
                } else if (itemType == OfferItemType.NATIVE) {
                    // Handle native token transfers

                    // if native token is involved, msg.sender must be the one sending it
                    if (from != msg.sender) { revert("NonSenderSendNative"); }

                    uint256 amount = offerItem.amount;

                    // disallow 0 amount
                    if (amount == 0) { revert("ZeroAmount"); }

                    // Ensure that sufficient Ether is still available from this tx
                    if (amount > remainingFunds) { revert("DTTDSwapError__InsufficiendNativeTokenSupplied()"); }

                    // reduce the remaining funds by the amount to be transferred in this offer item
                    remainingFunds -= amount;

                    // transfer the native token to the receiver
                    (bool sent, ) = to.call{value: amount}("");
                    if (!sent) { revert("InsufficientFunds"); }
                }
            }
        }

        if (remainingFunds > 0) {
            // transfer leftover native tokens back to msg.sender
            (bool sent, ) = msg.sender.call{value: remainingFunds}("");
            if (!sent) {
                revert("NativeSendFail");
            }
        }

        // emit LogSwap event
        emit LogSwap(_swap.swapNonce);
    }

    /**
     * @dev Blocks a swap from happening.  We store the hash of the swap in a mapping and check it while performing a
            swap.  If that hash is found, the swap is blocked.
     * @dev Any of the offerers can block a swap.
     */
    function blockSwap(
        Swap calldata _swap
    ) external ensureUnusedSwapNonce(_swap.swapNonce) ensureNotExpired(_swap.endTime) {
        for (uint256 i = 0; i < _swap.offer.length; i++) {
            Offer calldata offer = _swap.offer[i];

            // find if msg.sender is an offerer
            if (offer.from == msg.sender) {
                bytes32 swapHash = hashSwap(_swap);
                blockedSwapHash[swapHash] = true;
        
                // emit LogBlockSwap event
                emit LogBlockSwap(swapHash);
                return;
            }
        }

        // if we get here, we revert because the msg.sender is none of the offerers
        revert("NotAnOfferer");
    }

    /*//////////////////////////////////////////////////////////////
                        CONVENIENCE FUNCTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Convenience function to checks all offer item approval allowances and balance.  Returns two flattened
            arrays, one boolean array for sufficient approval and one uint256 array for available balance / amount.
            Please be aware that getting the call may revert if attempting to get approval or balance of invalid
            tokens, or including invalid parameters in the swap.  Handle those cases accordingly.
     */
    function checkApprovalAndBalance(
        Swap calldata _swap
    ) external
      view
      returns (bool[] memory, uint256[] memory)
    {
        // get flattened size
        uint256 totalOffersItems = 0;
        for (uint256 i = 0; i < _swap.offer.length; i++) {
            for (uint256 j = 0; j < _swap.offer[i].offerItem.length; j++) {
                totalOffersItems++;
            }
        }

        // approval array indicates if the offer item has sufficient approval
        bool[] memory approval = new bool[](totalOffersItems);
        // balance array returns available balance
        uint256[] memory balance = new uint256[](totalOffersItems);

        // for each item in the swap, check if the offerer has the required approval and balance
        uint256 currentOfferItem = 0;
        for (uint256 i = 0; i < _swap.offer.length; i++) {
            Offer calldata offer = _swap.offer[i];
            address from = offer.from;
            for (uint256 j = 0; j < offer.offerItem.length; j++) {
                OfferItem calldata item = offer.offerItem[j];
                // Check if the offer item value can be converted into the enum
                if (item.offerItemType > 3) { revert("UnknownItemType"); }
                OfferItemType itemType = OfferItemType(item.offerItemType);
                if (itemType == OfferItemType.ERC721) {
                    approval[currentOfferItem] = IERC721(item.token).isApprovedForAll(from, address(this));
                    balance[currentOfferItem] = (IERC721(item.token).ownerOf(item.identifier) == from)?1:0;
                } else if (itemType == OfferItemType.ERC1155) {
                    approval[currentOfferItem] = IERC1155(item.token).isApprovedForAll(from, address(this));
                    balance[currentOfferItem] = IERC1155(item.token).balanceOf(from, item.identifier);
                } else if (itemType == OfferItemType.ERC20) {
                    approval[currentOfferItem] = IERC20(item.token).allowance(from, address(this)) >= item.amount;
                    balance[currentOfferItem] = IERC20(item.token).balanceOf(from);
                } else if (itemType == OfferItemType.NATIVE) {
                    approval[currentOfferItem] = true;
                    balance[currentOfferItem] = from.balance;
                }
                currentOfferItem++;
            }
        }
        return (approval, balance);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length == 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
pragma solidity 0.8.17;

import { Swap, Offer, OfferItem, SWAP_TYPEHASH, OFFER_TYPEHASH, OFFERITEM_TYPEHASH } from "./DTTDStructs.sol";
import { OfferItemType } from "./DTTDEnums.sol";


interface IDTTDSwap {

    /*//////////////////////////////////////////////////////////////
                            ERROR: AUTHORITY
    //////////////////////////////////////////////////////////////*/

    // new authority is the zero address
    error DTTDAuthorityError__SetInvalidAuthority();

    /*//////////////////////////////////////////////////////////////
                            ERROR: SWAP
    //////////////////////////////////////////////////////////////*/

    // swap must have at least 1 offer
    error DTTDSwapError__InsufficientOffers();

    // incorrect number of signatures
    error DTTDSwapError__OfferSignatureLengthMismatch();

    // offer item to cannot be the zero address
    error DTTDSwapError__InvalidOfferItemTo();

    // offer item amount cannot be zero
    error DTTDSwapError__InvalidOfferItemAmount();

    // offer item insufficient native token supplied
    error DTTDSwapError__InsufficiendNativeTokenSupplied();

    // offer item insufficient native token supplied
    error DTTDSwapError__NativeTokenTransferNotSender();

    // transfer native token failed
    error DTTDSwapError__NativeTokenTransferFailed(address from, address to, uint256 amount);

    // transfer ERC20 failed
    error DTTDSwapError__ERC20TransferFailed(address token, address from, address to, uint256 amount);

    // swap executed
    error DTTDSwapError__SwapExecuted(uint256 _swapNonce);

    // swap expired
    error DTTDSwapError__SwapExpired();

    // unknown offer item type
    error DTTDSwapError__UnknownOfferItemType();

    // swap is blocked
    error DTTDSwapError__SwapBlocked(bytes32 _swapHash);

    // swap is blocked
    error DTTDSwapError__NotAnOfferer(address _addr);

    /*//////////////////////////////////////////////////////////////
                            ERROR: SIGNATURE
    //////////////////////////////////////////////////////////////*/

    // incorrect authority signature
    error DTTDSignatureError__InvalidAuthority();

    // incorrect authority signature
    error DTTDSignatureError__InvalidSignature();

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event LogSwap(uint256 _swapNonce);
    event LogBlockSwap(bytes32 _swapHash);

    /*//////////////////////////////////////////////////////////////
                            FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // EIP712 Domain Seperator
    function domainSeparator() external view returns (bytes32);

    // EIP712 hash for Swap struct
    function hashSwap(Swap calldata _swap) external view returns (bytes32);

    // Perform a swao with the given offers and signatures
    function performSwap(Swap calldata _swap, bytes[] calldata _signature) external payable;

    // Block a swap from being executed
    function blockSwap(Swap calldata _swap) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    OfferItemType
} from "./DTTDEnums.sol";

struct Swap {
    Offer[] offer;
    uint256 endTime;
    uint256 swapNonce;
}
// bytes32 constant SWAP_TYPEHASH = keccak256(
//     "Swap(Offer[] offer,uint256 endTime,uint256 swapNonce)"
//     "Offer(OfferItem[] offerItem,address from)"
//     "OfferItem(address to,uint8 offerItemType,address token,uint256 identifier,uint256 amount)"
// );
bytes32 constant SWAP_TYPEHASH = 0xe290609c8f553aa0c70e2b281e26afb435b47184686022e17fa2a505e19e51e2;


struct Offer {
    OfferItem[] offerItem;
    address from;
}
// bytes32 constant OFFER_TYPEHASH = keccak256(
//     "Offer(OfferItem[] offerItem,address from)"
//     "OfferItem(address to,uint8 offerItemType,address token,uint256 identifier,uint256 amount)"
// );
bytes32 constant OFFER_TYPEHASH = 0xf825b6e9e2bed18c730b3d709a3e36506e06d746be0813d0e476e624d41759a8;


struct OfferItem {
    address to;
    uint8 offerItemType; // we store as uint8 instead of enum to make it easier to support external signing
    address token;
    uint256 identifier;
    uint256 amount;
}
// bytes32 constant OFFERITEM_TYPEHASH = keccak256(
//     "OfferItem(address to,uint8 offerItemType,address token,uint256 identifier,uint256 amount)"
// );
bytes32 constant OFFERITEM_TYPEHASH = 0x8eca0abaaf13208f26a407164e441c3799b94efbfa2e91608e9c60aa9069302b;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

enum OfferItemType {
    // 0: native token
    NATIVE,

    // 1: ERC-20 token
    ERC20,

    // 2: ERC-721 token
    ERC721,

    // 3: ERC-1155 token
    ERC1155
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
        InvalidSignatureV // Deprecated in v4.8
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}