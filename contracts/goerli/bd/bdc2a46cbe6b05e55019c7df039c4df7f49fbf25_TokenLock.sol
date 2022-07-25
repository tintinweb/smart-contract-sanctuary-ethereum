/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: Newss.sol


pragma solidity ^0.8.0;





error notTime();
error notYours();
error lengthsNotEqual();
error NoTokenIdSelected();
error ContractIsPaused();
error NotEnoughAllowance();
error insufficientBalance();
error NotAnERC721Contract();
error ContractNotApproved();
error NotAnERC1155Contract();
error LockPeriodCannotBeZero();

contract TokenLock is Ownable {
    /*
     This smart contract is used to lock tokens for specific time,
     It doesnt come with reward,
     It supports Any ERC20,ERC721,ERC1155 token
     */
    bool private paused = false;

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                                  Token INFO's                                          //
    ////////////////////////////////////////////////////////////////////////////////////////////

    struct MyERC721 {
        address owner;
        uint128 lockTime;
        uint128 lockPeriod;
    }
    // Mapping from the token Contract to its token, the then to its info
    mapping(address => mapping(uint256 => MyERC721)) private ERC721Info;

    struct MyERC20 {
        uint256 tokenBalance;
        uint128 lockTime;
        uint128 lockPeriod;
    }
    // Mapping from the token Contract to its owner, the then to its info
    mapping(address => mapping(address => MyERC20)) private ERC20Info;

    struct MyERC1155 {
        uint256 tokenBal;
        uint128 lockPeriod;
        uint128 lockTime;
    }
    // Mapping from the CA -> TokenID -> TokenNft Infp
    mapping(address => mapping(address => mapping(uint256 => MyERC1155)))
        private ERC1155Info;

    modifier contractStatus() {
        if (paused) revert ContractIsPaused();
        _;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                             ERC20-Deposite-Withdrawal                                  //
    ////////////////////////////////////////////////////////////////////////////////////////////

    /** Withdraws the an ERC72 token of the caller
     *  throws if the token address is not an ERC721 contract address
     *  throws if the caller tries to withdraw before time
     *  throws if callers is not the owner of the token
     *  lockTime updates whenever a token of same types is deposited after certain time
     *  or before the previous lockPeriod elapse
     */

    function depositeERC20(
        address _token,
        uint256 amount,
        uint128 lockPeriod
    ) public contractStatus {
        IERC20Metadata token = IERC20Metadata(_token);
        uint256 decimal = 10**token.decimals();
        if (lockPeriod == 0) revert LockPeriodCannotBeZero();
        if (amount * decimal > token.allowance(msg.sender, address(this)))
            revert NotEnoughAllowance();
        MyERC20 storage erc20 = ERC20Info[_token][msg.sender];
        if (token.balanceOf(msg.sender) < amount * decimal)
            revert insufficientBalance();
        token.transferFrom(msg.sender, address(this), amount * decimal);
        erc20.tokenBalance += amount * decimal;
        erc20.lockTime = uint128(block.timestamp);
        erc20.lockPeriod = lockPeriod;
        emit ERC20Deposite(
            _token,
            msg.sender,
            amount * decimal,
            block.timestamp
        );
    }

    function depositeBulkERC20(
        address[] calldata token,
        uint256[] calldata amount,
        uint128 lockPeriod
    ) external {
        if (token.length != amount.length) revert lengthsNotEqual();
        uint256 i;
        for (; i < token.length; ) {
            depositeERC20(token[i], amount[i], lockPeriod);
            unchecked {
                ++i;
            }
        }
    }

    /** Withdraws ERC20 token of the caller 
        throws if the caller tries to withdraw before time
        throws if callers balance is less that the amount
     */
    function withdrawErc20(address token, uint256 amount) public {
        MyERC20 storage erc20 = ERC20Info[token][msg.sender];
        uint256 balance = erc20.tokenBalance;
        uint256 decimal = 10**IERC20Metadata(token).decimals();
        if (block.timestamp - erc20.lockTime < erc20.lockPeriod)
            revert notTime();
        if (balance < amount * decimal) revert insufficientBalance();
        unchecked {
            erc20.tokenBalance -= amount * decimal;
            if (erc20.tokenBalance == 0) {
                erc20.lockPeriod = 0;
                erc20.lockTime = 0;
            }
        }
        IERC20(token).transfer(msg.sender, amount * decimal);
        emit ERC20Withdrawal(token, msg.sender, amount * decimal);
    }

    function erc20BulkWithdrawal(
        address[] calldata token,
        uint256[] calldata amount
    ) external {
        if (amount.length != token.length) revert lengthsNotEqual();
        uint256 i;
        for (; i < token.length; ) {
            withdrawErc20(token[i], amount[i]);
            unchecked {
                ++i;
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                           ERC721-Deposite-Withdrawal                                   //
    ////////////////////////////////////////////////////////////////////////////////////////////
    /** Deposite the an ERC721 token of the caller
     *  throws if the token address is not an ERC721 contract address
     *  lockTime updates whenever a token of same types is deposited after certain time
     *  or before the previous lockPeriod elapse
     */
    function depositeERC721(
        address _token,
        uint256 tokenID,
        uint256 _lockPeriod
    ) public contractStatus {
        IERC721 token = IERC721(_token);
        if (!token.isApprovedForAll(msg.sender, address(this)))
            revert ContractNotApproved();
        if (_lockPeriod == 0) revert LockPeriodCannotBeZero();
        if (token.ownerOf(tokenID) != msg.sender) revert notYours();
        IERC721(token).transferFrom(msg.sender, address(this), tokenID);
        ERC721Info[_token][tokenID] = MyERC721({
            owner: msg.sender,
            lockTime: uint128(block.timestamp),
            lockPeriod: uint128(_lockPeriod)
        });
        emit ERC721Deposite(_token, msg.sender, tokenID, block.timestamp);
    }

    function depositeBulkERC721(
        address token,
        uint256[] calldata tokenID,
        uint128 lockPeriod
    ) external {
        uint i;
        for (; i < tokenID.length; ) {
            depositeERC721(token, tokenID[i], lockPeriod);
            unchecked {
                ++i;
            }
        }
    }

    /** Withdraws the an ERC721 token of the caller
     *  throws if the token address is not an ERC721 contract address
     *  throws if the caller tries to withdraw before time
     *  throws if callers is not the owner of the token
     */

    function withdrawERC721(address token, uint256 tokenID) public {
        MyERC721 storage erc721 = ERC721Info[token][tokenID];
        if (erc721.owner != msg.sender) revert notYours();
        if (block.timestamp - erc721.lockTime < erc721.lockPeriod)
            revert notTime();
        IERC721(token).transferFrom(address(this), msg.sender, tokenID);
        ERC721Info[token][tokenID] = MyERC721({
            owner: address(0),
            lockTime: 0,
            lockPeriod: 0
        });
        emit ERC721Withdrawal(token, msg.sender, tokenID);
    }

    function bulkWithdrawERC721(address token, uint256[] calldata tokenID)
        external
    {
        if (tokenID.length == 0) revert NoTokenIdSelected();
        uint j;
        for (; j < tokenID.length; ) {
            withdrawERC721(token, tokenID[j]);
            unchecked {
                ++j;
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                          ERC1155-Deposite-Withdrawal                                   //
    ////////////////////////////////////////////////////////////////////////////////////////////

    /** Deposite the an ERC1155 token of the caller
     *  throws if the token address is not an ERC1155 contract address
     *  lockTime updates whenever a token of same types is deposited after certain time
     *  or before the previous lockPeriod elapse
     */

    function depositeERC1155(
        address _token,
        uint256 tokenID,
        uint256 amount,
        uint128 _lockPeriod
    ) public contractStatus {
        IERC1155 token = IERC1155(_token);
        if (!token.isApprovedForAll(msg.sender, address(this)))
            revert ContractNotApproved();
        if (_lockPeriod == 0) revert LockPeriodCannotBeZero();
        MyERC1155 storage erc1155 = ERC1155Info[_token][msg.sender][tokenID];
        IERC1155(token).safeTransferFrom(
            msg.sender,
            address(this),
            tokenID,
            amount,
            ""
        );
        erc1155.tokenBal += amount;
        erc1155.lockPeriod = _lockPeriod;
        erc1155.lockTime = uint128(block.timestamp);
        emit ERC1155Deposite(
            _token,
            msg.sender,
            tokenID,
            amount,
            block.timestamp
        );
    }

    function depositeBulkERC11155(
        address token,
        uint256[] calldata tokenID,
        uint256[] calldata amount,
        uint128 lockPeriod
    ) external {
        if (amount.length != tokenID.length) revert lengthsNotEqual();
        uint256 k;
        for (; k < tokenID.length; ) {
            depositeERC1155(token, tokenID[k], amount[k], lockPeriod);
            unchecked {
                ++k;
            }
        }
    }

    /** Withdraws the ERC1155 token of the caller
     *  throws if the caller tries to withdraw before time
     *  throws if callers tries withdrawing an amount greater than that of token id it own
     */

    function withdrawERC1155(
        address token,
        uint256 tokenID,
        uint256 amount
    ) public {
        MyERC1155 storage erc1155 = ERC1155Info[token][msg.sender][tokenID];
        uint256 _lockTime = erc1155.lockTime;
        if (block.timestamp - _lockTime < erc1155.lockPeriod) revert notTime();
        if (erc1155.tokenBal < amount) revert insufficientBalance();
        unchecked {
            erc1155.tokenBal -= amount;
        }
        if (erc1155.tokenBal == 0) {
            erc1155.lockPeriod = 0;
            erc1155.lockTime = 0;
        }

        IERC1155(token).safeTransferFrom(
            address(this),
            msg.sender,
            tokenID,
            amount,
            ""
        );
        emit ERC1155Withdrawal(token, msg.sender, tokenID, amount);
    }

    function erc1155BulkWithdrawal(
        address token,
        uint256[] calldata tokenID,
        uint256[] calldata amount
    ) external {
        if (amount.length != tokenID.length) revert lengthsNotEqual();
        uint256 i;
        for (; i < tokenID.length; ) {
            withdrawERC1155(token, tokenID[i], amount[i]);
            unchecked {
                ++i;
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                                CONTRACT-STATUS                                         //
    ////////////////////////////////////////////////////////////////////////////////////////////

    function flipContractStatus(bool _status) external onlyOwner {
        paused = _status;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                                ON-RECEIVED-FUNCTIONS                                   //
    ////////////////////////////////////////////////////////////////////////////////////////////

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                                  VIEW-PURE-FUNCTIONS                                   //
    ////////////////////////////////////////////////////////////////////////////////////////////
    function getERC20Info(address contractAddress, address account)
        external
        view
        returns (MyERC20 memory)
    {
        return ERC20Info[contractAddress][account];
    }

    function getERC721Info(address contractAddress, uint256 token)
        external
        view
        returns (MyERC721 memory)
    {
        return ERC721Info[contractAddress][token];
    }

    function getERC1155Info(
        address contractAddress,
        address account,
        uint256 tokenID
    ) external view returns (MyERC1155 memory) {
        return ERC1155Info[contractAddress][account][tokenID];
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                                  EVENTS                                                //
    ////////////////////////////////////////////////////////////////////////////////////////////
    event ERC20Deposite(
        address token,
        address owner,
        uint256 amount,
        uint256 timestamp
    );

    event ERC721Deposite(
        address token,
        address owner,
        uint256 tokenID,
        uint256 timestamp
    );

    event ERC1155Deposite(
        address token,
        address owner,
        uint256 tokenID,
        uint256 amount,
        uint256 timestamp
    );
    event ERC20Withdrawal(address token, address owner, uint256 amount);

    event ERC721Withdrawal(address token, address owner, uint256 tokenID);

    event ERC1155Withdrawal(
        address token,
        address owner,
        uint256 tokenID,
        uint256 amount
    );
}