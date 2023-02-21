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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./Signature.sol";

contract NutsStaking is Ownable, IERC721Receiver {
    struct StakedItem {
        uint id;
        address owner;
        uint stakedAt;
        uint expiresAt;
    }

    address public unstakeSigner;
    IERC721 public immutable parentNft;

    mapping(uint => StakedItem) public stakedItems;
    mapping(address => uint[]) public stakedItemsByOwner;

    event Stake(uint id, address owner, uint timestamp);
    event Unstake(uint id, address owner, uint timestamp);
    event UnstakeWithSignature(uint id, address owner, uint timestamp);
    event UnstakeToAdmin(uint id, address owner, uint timestamp);
    event SetSigner(address signer);

    constructor(address _unstakeSigner, address _parentContract) payable {
        unstakeSigner = _unstakeSigner;
        parentNft = IERC721(_parentContract);
    }

    function stake(uint _id) public {
        parentNft.safeTransferFrom(msg.sender, address(this), _id);

        address owner = msg.sender;
        uint stakedAt = block.timestamp;
        uint expiresAt = block.timestamp + 180 days;

        stakedItems[_id] = StakedItem({
            id: _id,
            owner: owner,
            stakedAt: stakedAt,
            expiresAt: expiresAt
        });
        stakedItemsByOwner[owner].push(_id);

        emit Stake(_id, owner, stakedAt);
    }

    function unstake(uint _id) public {
        StakedItem storage stakedItem = stakedItems[_id];
        require(stakedItem.owner == msg.sender, "Not owner");
        require(
            stakedItem.expiresAt <= block.timestamp,
            "Not ready for unstake"
        );

        parentNft.safeTransferFrom(address(this), msg.sender, _id);

        delete stakedItems[_id];

        uint[] storage stakedIds = stakedItemsByOwner[msg.sender];
        for (uint i = 0; i < stakedIds.length; i++) {
            if (stakedIds[i] == _id) {
                stakedIds[i] = stakedIds[stakedIds.length - 1];
                stakedIds.pop();
                break;
            }
        }

        emit Unstake(_id, msg.sender, block.timestamp);
    }

    function unstakeWithSignature(uint _id, bytes memory _signature) public {
        StakedItem storage stakedItem = stakedItems[_id];
        require(stakedItem.owner == msg.sender, "Not owner");

        bool isSignatureValid = Signature.verify(
            unstakeSigner,
            stakedItem.owner,
            stakedItem.id,
            stakedItem.stakedAt,
            stakedItem.expiresAt,
            _signature
        );
        require(isSignatureValid, "Invalid signature");

        delete stakedItems[_id];

        uint[] storage stakedIds = stakedItemsByOwner[msg.sender];
        for (uint i = 0; i < stakedIds.length; i++) {
            if (stakedIds[i] == _id) {
                stakedIds[i] = stakedIds[stakedIds.length - 1];
                stakedIds.pop();
                break;
            }
        }

        emit UnstakeWithSignature(_id, msg.sender, block.timestamp);
    }

    function withdrawToAdmin(uint _id) public onlyOwner {
        StakedItem storage stakedItem = stakedItems[_id];
        require(stakedItem.owner != address(0), "Not staked");

        parentNft.safeTransferFrom(address(this), msg.sender, _id);

        address originalOwner = stakedItem.owner;
        delete stakedItems[_id];

        uint[] storage stakedIds = stakedItemsByOwner[stakedItem.owner];
        for (uint i = 0; i < stakedIds.length; i++) {
            if (stakedIds[i] == _id) {
                stakedIds[i] = stakedIds[stakedIds.length - 1];
                stakedIds.pop();
                break;
            }
        }

        emit UnstakeToAdmin(_id, originalOwner, block.timestamp);
    }

    function getMessageHash(
        address _owner,
        uint _id,
        uint _stakedAt,
        uint _expiresAt
    ) public pure returns (bytes32) {
        return Signature.getMessageHash(_owner, _id, _stakedAt, _expiresAt);
    }

    function getStakesByOwner(
        address _owner
    ) public view returns (StakedItem[] memory) {
        uint[] memory stakedIds = stakedItemsByOwner[_owner];

        StakedItem[] memory stakes = new StakedItem[](stakedIds.length);
        for (uint i = 0; i < stakedIds.length; i++) {
            uint id = stakedIds[i];
            StakedItem storage stakedItem = stakedItems[id];
            stakes[i] = stakedItem;
        }

        return stakes;
    }

    function setSigner(address _signer) public onlyOwner {
        unstakeSigner = _signer;

        emit SetSigner(_signer);
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Signature {
    function getMessageHash(
        address _owner,
        uint _id,
        uint _stakedAt,
        uint _expiresAt
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_owner, _id, _stakedAt, _expiresAt));
    }

    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verify(
        address _signer,
        address _owner,
        uint _id,
        uint _stakedAt,
        uint _expiresAt,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(
            _owner,
            _id,
            _stakedAt,
            _expiresAt
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }
}