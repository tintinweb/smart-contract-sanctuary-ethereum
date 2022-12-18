// SPDX-License-Identifier: MIT
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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


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

contract GameController is Ownable {
    mapping(address => address) private operators;
    mapping(address => uint256) private payed;

    event TransferedERC721(
        address indexed ERC721,
        uint256 tokenId, 
        address sender,
        address indexed recipient
    );

    event TransferedERC20(
        address indexed ERC20,
        uint256 amount, 
        address sender,
        address indexed recipient
    );

    event Payed(address indexed user, uint256 value);

    receive() external payable {
        payed[msg.sender] += msg.value;
        emit Payed(msg.sender, msg.value);
    }

    function withdraw() onlyOwner public {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getPayed(address user) public view returns (uint256) {
        return payed[user];
    }

    constructor() {
    }

    function SetOperator(address operator) public {
        operators[_msgSender()] = operator;
    }

    function GetOperator(address sender) public view returns (address) {
        return operators[sender];
    }

    function TransferERC721(
        address ERC721,
        uint256 tokenId, 
        address sender,
        address recipient   
    ) public {
        require(IERC721(ERC721).isApprovedForAll(sender, address(this)) && (msg.sender == operators[sender] || sender == msg.sender), "You're not an sender");

        IERC721Enumerable(ERC721).safeTransferFrom(sender, recipient, tokenId);

        emit TransferedERC721(ERC721, tokenId, sender, recipient);
    }

    function TransferERC721Batch(
        address[] calldata ERC721,
        uint256[] calldata tokenId,
        address sender,
        address recipient
    ) public {
        require(
            ERC721.length == tokenId.length
        , "All arrays must be have the same length");
        require(ERC721.length <= 20, "Length must be less or equal 20");

        for (uint256 i = 0; i < ERC721.length; i++) {
            TransferERC721(ERC721[i], tokenId[i], sender, recipient);
        }
    }

    function TransferERC20(
        address ERC20,
        uint256 amount,
        address sender,
        address recipient
    ) public {
        require(IERC20(ERC20).allowance(sender, address(this)) >= amount && (msg.sender == operators[sender] || sender == msg.sender), "You're not an sender");

        IERC20(ERC20).transferFrom(sender, recipient, amount);

        emit TransferedERC20(ERC20, amount, sender, recipient);
    }

    function TransferERC20Batch(
        address[] calldata ERC20, 
        uint256[] calldata amount, 
        address sender,
        address recipient
    ) public {
        require(
            ERC20.length == amount.length
        , "All arrays must be have the same length");
        require(ERC20.length <= 20, "Length must be less or equal 20");

        for (uint256 i = 0; i < ERC20.length; i++) {
            TransferERC20(ERC20[i], amount[i], sender, recipient);
        }
    }                                                              

    function MultiTransfer(
        address ERC721,
        uint256 tokenId, 
        address ERC20,
        uint256 amount, 
        address sender,
        address recipient
    ) public {
        TransferERC721(ERC721, tokenId, sender, recipient);
        TransferERC20(ERC20, amount, sender, recipient);
    }

    function MultiTransferBatch( 
        address[] calldata ERC721, 
        uint256[] calldata tokenId, 
        address[] calldata ERC20, 
        uint256[] calldata amount,
        address sender,
        address recipient
    ) public {
        require(ERC721.length == tokenId.length, "All arrays must be have the same length");
        require(ERC20.length == amount.length, "All arrays must be have the same length");
        require(ERC20.length <= 10 && ERC721.length <= 10, "Length must be less or equal 20");

        for (uint256 i = 0; i < ERC20.length; i++) {
            TransferERC20(ERC20[i], amount[i], sender, recipient);
        }

        for (uint256 i = 0; i < ERC20.length; i++) {
            TransferERC20(ERC20[i], amount[i], sender, recipient);
        }
    }

    function GetERC721BalanceByOwner(
        address[] calldata ERC721,
        address owner
    ) view public returns (uint256[] memory) {
        uint256[] memory result = new uint256[](ERC721.length);

        for (uint256 i = 0; i < ERC721.length; i++) {
            result[i] = IERC721(ERC721[i]).balanceOf(owner);
        }

        return result;
    }

    function GetERC721TokenByOwner(
        address ERC721,
        uint256 startIndex,
        uint256 finishIndex,
        address owner
    ) view public returns (uint256[] memory) {
        uint256[] memory result = new uint256[](finishIndex - startIndex);

        for (uint256 i = startIndex; i < finishIndex; i++) {
            result[i] = IERC721Enumerable(ERC721).tokenOfOwnerByIndex(owner, i);
        }

        return result;
    }

    function GetERC20AllowedByOwner(
        address[] calldata ERC20, 
        address owner
    ) view public returns (uint256[] memory) {
        uint256[] memory result = new uint256[](ERC20.length);

        for (uint256 i = 0; i < ERC20.length; i++) {
            result[i] = IERC20(ERC20[i]).allowance(owner, address(this));
        }

        return result;
    }

    function GetERC20BalanceByOwner(
        address[] calldata ERC20, 
        address owner
    ) view public returns (uint256[] memory) {
        uint256[] memory result = new uint256[](ERC20.length);

        for (uint256 i = 0; i < ERC20.length; i++) {
            result[i] = IERC20(ERC20[i]).balanceOf(owner);
        }

        return result;
    }
}