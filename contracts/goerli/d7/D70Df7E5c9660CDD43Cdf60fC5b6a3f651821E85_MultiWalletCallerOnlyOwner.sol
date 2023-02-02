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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IChildStorage {
    function setOperater(address _contract) external;
    function setKudasai(address _contract) external;
    function setDelegateRegistry(address _contract) external;
    function setSpaceId(string calldata _str) external;
    function addChildAddress(address _user, address _newChild) external;
    function setNFTId(address _user, uint256 _nftId) external;

    function operater(address) external view returns (bool);
    function childCount(address) external view returns (uint256);
    function child(address, uint256) external view returns (address);
    function ownedNFTId(address) external view returns (uint256);
    function kudasai() external view returns (address);
    function delegateRegistry() external view returns (address);
    function spaceId() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICloneFactory {
    function createClone(address) external returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMinterChaild {
    function initialize(address _deployer) external;
    function withdrawERC20(address _contract, address _to) external;
    function withdrawERC721(address _contract, uint256 _tokenId, address _to) external;
    function withdrawERC1155(address _contract, uint256 _tokenId, address _to) external;
    function withdrawETH(address _to) external;
    function run_jvZDWiar(address _callContract, bytes calldata _callData, uint256 _value) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IChildStorage.sol";
import "./interface/IMinterChaild.sol";
import "./interface/ICloneFactory.sol";

contract MultiWalletCallerOnlyOwner is Ownable, IERC721Receiver {
    address private immutable _minterChildContract;
    ICloneFactory private immutable _cloneContract;
    IChildStorage private immutable _childStorage;

    constructor (address minterChildContract_, address cloneContract_, address childStorage_) {
        _minterChildContract = minterChildContract_;
        _cloneContract = ICloneFactory(cloneContract_);
        _childStorage = IChildStorage(childStorage_);
    }
    receive() external payable {}

    modifier checkId(uint256 _startId, uint256 _endId) {
        require(_startId <= _endId && _startId < IChildStorage(_childStorage).childCount(msg.sender) && _endId < IChildStorage(_childStorage).childCount(msg.sender), "MultiWalletCaller: Invalid ID");
        _;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) public virtual returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    /**
     * @dev create multiple wallets for a user
     * @param _quantity number of wallets to be created
     */
    function createWallets(uint256 _quantity) external onlyOwner {
        for (uint256 i = 0; i < _quantity; i++) {
            address newChild = ICloneFactory(_cloneContract).createClone(_minterChildContract);
            IChildStorage(_childStorage).addChildAddress(msg.sender, newChild);
            IMinterChaild(payable(newChild)).initialize(msg.sender);
        }
    }

    /**
     * @dev send ETH to multiple wallets
     * @param _startId start index of wallet to send ETH to
     * @param _endId end index of wallet to send ETH to
     */
    function sendETH(uint256 _startId, uint256 _endId) external payable onlyOwner checkId(_startId, _endId) {
        uint256 value = msg.value / (_endId - _startId + 1);
        for (uint256 i = _startId; i <= _endId; i++) {
            (bool success,) = IChildStorage(_childStorage).child(msg.sender, i).call{value: value}(new bytes(0));
            require(success, "MultiWalletCaller: Transfer Failed");
        }
    }

    /**
     * @dev send ERC20 tokens to multiple wallets
     * @param _startId start index of wallet to send tokens to
     * @param _endId end index of wallet to send tokens to
     * @param _token address of the token contract
     * @param _amount amount of tokens to be sent
     */
    function sendERC20(uint256 _startId, uint256 _endId, address _token, uint256 _amount) external onlyOwner checkId(_startId, _endId) {
        require(IERC20(_token).balanceOf(msg.sender) != 0 && _amount != 0, 'MultiWalletCaller: Insufficient balance');
        IERC20(_token).transferFrom(msg.sender, address(this), _amount * (_endId - _startId + 1));
        for (uint256 i = _startId; i <= _endId; i++) {
            IERC20(_token).transfer(IChildStorage(_childStorage).child(msg.sender, i), _amount);
        }
    }

    /**
     * @dev Runs a function of a specified contract for multiple child wallets
     * @param _startId The start id of the wallet
     * @param _endId The end id of the wallet
     * @param _callContract The address of the contract to run the function
     * @param _callData The data of the function to run
     * @param _value The amount of ETH to send to the function
     */
    function run(uint256 _startId, uint256 _endId, address _callContract, bytes calldata _callData, uint256 _value) external onlyOwner checkId(_startId, _endId) {
        for (uint256 i = _startId; i <= _endId; i++) {
            IMinterChaild(payable(IChildStorage(_childStorage).child(msg.sender, i))).run_jvZDWiar(_callContract, _callData, _value);
        }
    }

    /**
     * @dev Runs a function of a specified contract for multiple child wallets, given the function signature
     * @param _startId The start id of the wallet
     * @param _endId The end id of the wallet
     * @param _callContract The address of the contract to run the function
     * @param _signature The signature of the function to run
     * @param _value The amount of ETH to send to the function
     */
    function runWithSelector(uint256 _startId, uint256 _endId, address _callContract, string calldata _signature, uint256 _value) external onlyOwner checkId(_startId, _endId) {
        bytes memory callData = abi.encodeWithSignature(_signature);
        for (uint256 i = _startId; i <= _endId; i++) {
            IMinterChaild(payable(IChildStorage(_childStorage).child(msg.sender, i))).run_jvZDWiar(_callContract, callData, _value);
        }
    }

    /**
     * @dev Withdraws ETH from multiple child wallets to the caller
     * @param _startId The start id of the wallet
     * @param _endId The end id of the wallet
     */
    function withdrawETH(uint256 _startId, uint256 _endId) external checkId(_startId, _endId) {
        uint256 beforeBalance = address(this).balance;
        for (uint256 i = _startId; i <= _endId; i++) {
            IMinterChaild(payable(IChildStorage(_childStorage).child(msg.sender, i))).withdrawETH(msg.sender);
        }
        payable(msg.sender).transfer(address(this).balance - beforeBalance);
    }

    /**
     * @dev Withdraws ERC20 tokens from multiple child wallets to the caller
     * @param _startId The start id of the wallet
     * @param _endId The end id of the wallet
     * @param _contract The address of the ERC20 contract
     */
    function withdrawERC20(uint256 _startId, uint256 _endId, address _contract) external checkId(_startId, _endId) {
        uint256 idx;
        for (uint256 i = _startId; i <= _endId; i++) {
            IMinterChaild(payable(IChildStorage(_childStorage).child(msg.sender, i))).withdrawERC20(_contract, msg.sender);
            idx++;
        }
    }

    /**
     * @dev Withdraw ERC721 tokens from child wallets with specified token ids.
     * @param _startId The start index of the child wallet.
     * @param _endId The end index of the child wallet.
     * @param _contract The contract address of the ERC721 token.
     * @param _tokenIds The ids of the tokens to be withdrawn.
     */
    function withdrawERC721(uint256 _startId, uint256 _endId, address _contract, uint256[] calldata _tokenIds) external checkId(_startId, _endId) {
        uint256 idx;
        for (uint256 i = _startId; i <= _endId; i++) {
            IMinterChaild(payable(IChildStorage(_childStorage).child(msg.sender, i))).withdrawERC721(_contract, _tokenIds[idx], msg.sender);
            idx++;
        }
    }

    /**
     * @dev Withdraw ERC1155 tokens from child wallets with specified token id.
     * @param _startId The start index of the child wallet.
     * @param _endId The end index of the child wallet.
     * @param _contract The contract address of the ERC1155 token.
     * @param _tokenId The id of the token to be withdrawn.
     */
    function withdrawERC1155(uint256 _startId, uint256 _endId, address _contract, uint256 _tokenId) external checkId(_startId, _endId) {
        uint256 idx;
        for (uint256 i = _startId; i <= _endId; i++) {
            IMinterChaild(payable(IChildStorage(_childStorage).child(msg.sender, i))).withdrawERC1155(_contract, _tokenId, msg.sender);
            idx++;
        }
    }

    /**
     * @dev Only Owner
     * @dev Recover the Ethereum balance to the owner's wallet.
     */
    function recoverETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Only Owner
     * @dev Recover the ERC20 token balance to the owner's wallet.
     * @param _contract The contract address of the ERC20 token.
     */
    function recoverERC20(address _contract) external onlyOwner {
        IERC20(_contract).transfer(msg.sender, IERC20(_contract).balanceOf(address(this)));
    }

    /**
     * @dev Only Owner
     * @dev Recover the ERC721 token to the owner's wallet.
     * @param _contract The contract address of the ERC721 token.
     * @param _tokenId The id of the token to be recovered.
     */
    function recoverERC721(address _contract, uint256 _tokenId) external onlyOwner {
        IERC721(_contract).safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    /**
     * @dev Only Owner
     * @dev Recover the ERC1155 token to the owner's wallet.
     * @param _contract Address of the ERC1155 contract
     * @param _tokenId ID of the token to be recovered
     * @param _amount Amount of the token to be recovered
     * @param _data Additional data for the transfer
     */
    function recoverERC1155(address _contract, uint256 _tokenId, uint256 _amount, bytes memory _data) external onlyOwner {
        IERC1155(_contract).safeTransferFrom(address(this), msg.sender, _tokenId, _amount, _data);
    }
}