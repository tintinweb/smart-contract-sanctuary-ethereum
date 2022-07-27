// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./interfaces/ICryptoPunksMarket.sol";
import "./UsdbLendingCore.sol";

/// @notice liqd lending and borrowing contract
contract UsdbLending is Ownable, ReentrancyGuard, ERC721Holder, ERC1155Holder, LendingCore {

    address public DAO;
    uint256 public id;
    uint256 internal durationUnit = 86400; // Unit: 1 day
    bool internal onlyExitLoan;
    bool internal canChangeDurationUnit;
    mapping(bytes => bool) internal usedSignatures;

    constructor(address _DAO, bool _canChangeDurationUnit) {
        require(_DAO != address(0), "ZERO_ADDRESS");
        DAO = _DAO;
        canChangeDurationUnit = _canChangeDurationUnit;
    }

    /// @notice Borrowers transfer their nft as collateral to Vault and get paid from the lenders.
    /// @param _payload structure LoanPayload
    /// @param _sig user's signed message
    /// @return loanId the id of loans
    function createLoan(
        LoanPayload memory _payload,
        bytes memory _sig
    ) external payable nonReentrant returns (uint256) {
        require(!onlyExitLoan, "ONLY_EXIT_LOAN");
        require(!usedSignatures[_sig], "This signature is already used");
        require(_payload.expiration >= block.timestamp, "EXPIRED_SIGNATURE");
        bytes32 _payloadHash = keccak256(abi.encode(_payload.borrower, _payload.nftAddress,
            _payload.currency, _payload.nftTokenId, _payload.duration, _payload.expiration,
            _payload.loanAmount, _payload.apr, _payload.nftTokenType));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
            _payloadHash));
        if (msg.sender == _payload.borrower) {
            require(recoverSigner(messageHash, _sig) == _payload.lender, "INVALID_SIGNATURE");
        } else {
            require(recoverSigner(messageHash, _sig) == _payload.borrower, "INVALID_SIGNATURE");
        }
        require(availableCurrencies[_payload.currency], "NOT_ALLOWED_CURRENCY");
        require(_payload.duration != 0, "ZERO_DURATION");
        uint256 currentId = id;
        loans[currentId] = Loan({
        nftAddress : _payload.nftAddress,
        nftTokenId : _payload.nftTokenId,
        startTime : block.timestamp,
        endTime : block.timestamp + (_payload.duration * durationUnit),
        currency : _payload.currency,
        loanAmount : _payload.loanAmount,
        amountDue : calculateDueAmount(_payload.loanAmount, _payload.apr, _payload.duration),
        status : Status.CREATED,
        borrower : _payload.borrower,
        lender : _payload.lender,
        nftTokenType : _payload.nftTokenType
        });

        transferNFT(_payload.borrower, address(this), _payload.nftAddress, _payload.nftTokenId,
            _payload.nftTokenType, false);
        uint256 platformFee = calculatePlatformFee(_payload.loanAmount, platformFees[_payload.currency]);
        if (_payload.currency != address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            require(IERC20(_payload.currency).transferFrom(_payload.lender, _payload.borrower,
                _payload.loanAmount), "Transfer token to receiver failed.");
            if (platformFee > 0) {
                require(IERC20(_payload.currency).transferFrom(_payload.lender, DAO, platformFee),
                    "Transfer token to receiver failed.");
            }
        } else {
            require(msg.value >= _payload.loanAmount + platformFee, "ETH value is not enough.");
            (bool toSuccess,) = _payload.borrower.call{value : _payload.loanAmount}("");
            require(toSuccess, "Transfer failed");
            if (platformFee > 0) {
                (bool daoSuccess,) = DAO.call{value : platformFee}("");
                require(daoSuccess, "Transfer failed to DAO");
            }
        }
        emit LoanCreated(
            _payload.lender,
            _payload.borrower,
            _payload.nftAddress,
            _payload.nftTokenId,
            currentId
        );
        ++id;
        usedSignatures[_sig] = true;
        return currentId;
    }


    /// @notice Borrower pays back for loan
    /// @param _loanId the id of loans
    /// @param _amountDue amount is needed to pay
    function repayLoan(uint256 _loanId, uint256 _amountDue) external payable nonReentrant {
        Loan storage loan = loans[_loanId];
        address loanCurrency = loan.currency;
        require(loan.borrower == msg.sender, "WRONG_MSG_SENDER");
        require(loan.status == Status.CREATED, "NOT_LOAN_CREATED");
        require(block.timestamp <= loan.endTime, "EXPIRED_LOAN");
        require((msg.value > 0 && loanCurrency == address(0)
        && msg.value == _amountDue && _amountDue >= loan.amountDue) || (loanCurrency != address(0)
        && msg.value == 0 && _amountDue >= loan.amountDue), "Pay back amount is not enough.");

        loan.status = Status.REPAID;

        transferNFT(address(this), loan.borrower, loan.nftAddress, loan.nftTokenId,
            loan.nftTokenType, true);
        if (loan.currency != address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            require(IERC20(loan.currency).transferFrom(msg.sender, loan.lender, _amountDue),
                "Transfer token to receiver failed.");
        } else {
            require(msg.value >= _amountDue, "ETH value is not enough.");
            (bool toSuccess,) = loan.lender.call{value : _amountDue}("");
            require(toSuccess, "Transfer failed");
        }
        emit LoanLiquidated(
            loan.lender,
            loan.borrower,
            loan.nftAddress,
            loan.nftTokenId,
            _loanId
        );
    }

    /// @notice Lender can liquidate loan item if loan is not paid
    /// @param _loanId the id of loans
    function liquidateLoan(uint256 _loanId) external nonReentrant {
        Loan storage loan = loans[_loanId];
        require(loan.status == Status.CREATED, "LOAN_FINISHED");
        require(block.timestamp >= loan.endTime, "NOT_EXPIRED_LOAN");

        loan.status = Status.LIQUIDATED;
        transferNFT(address(this), loan.lender, loan.nftAddress, loan.nftTokenId,
            loan.nftTokenType, true);

        emit LoanTerminated(
            loan.lender,
            loan.borrower,
            loan.nftAddress,
            loan.nftTokenId,
            _loanId
        );
    }

    /// @notice Set onlyExistLoan by owner
    /// @param _value value
    function setOnlyExitLoan(bool _value) external onlyOwner {
        onlyExitLoan = _value;
    }

    /// @notice Change durationUnit by owner
    /// @param _value value
    function changeDurationUnit(uint256 _value) external onlyOwner {
        require(canChangeDurationUnit, "NOT_CHANGE_DURATION_UNIT");
        durationUnit = _value;
    }

    /// @notice Standard method to send nft from an account to another
    function transferNFT(
        address _from,
        address _to,
        address _nftAddress,
        uint256 _nftTokenId,
        uint8 _nftTokenType,
        bool _punkTransfer
    ) internal {
        if (_nftTokenType == 0) {
            IERC721(_nftAddress).safeTransferFrom(_from, _to, _nftTokenId);
        } else if (_nftTokenType == 1) {
            IERC1155(_nftAddress).safeTransferFrom(
                _from,
                _to,
                _nftTokenId,
                1,
                '0x00'
            );
        } else if (_nftTokenType == 2) {
            if (_punkTransfer) {
                ICryptoPunksMarket(_nftAddress).transferPunk(_to, _nftTokenId);
            } else {
                ICryptoPunksMarket(_nftAddress).buyPunk(_nftTokenId);
            }
        } else {
            revert("UNKNOWN_TOKEN_TYPE");
        }
    }

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
pragma solidity 0.8.14;

interface ICryptoPunksMarket {
    function buyPunk(uint punkIndex) external payable;
    function transferPunk(address to, uint punkIndex) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Core contract for liqd lending and borrowing
contract LendingCore is Ownable {

    enum Status {
        CREATED,
        REPAID,
        LIQUIDATED
    }

    struct Loan {
        address nftAddress; // address of nft
        address borrower; // address of borrower
        address lender; // address of lender
        address currency; // address of loans' currency
        Status status; // loan status
        uint256 nftTokenId; // unique identifier of NFT that the borrower uses as collateral
        uint256 startTime; // loan start date
        uint256 endTime; // loan end date
        uint256 loanAmount; // amount lender gives borrower
        uint256 amountDue; // loanAmount + interest that needs to be paid back by borrower
        uint8 nftTokenType; // token type ERC721: 0, ERC1155: 1, Other like CryptoPunk: 2
    }

    struct LoanPayload {
        address lender;
        address borrower;
        address nftAddress;
        address currency;
        uint256 nftTokenId;
        uint256 duration;
        uint256 expiration;
        uint256 loanAmount;
        uint256 apr; // 100 = 1%
        uint8 nftTokenType;
    }

    mapping(uint256 => Loan) public loans;
    mapping(address => bool) public availableCurrencies;
    mapping(address => uint256) public platformFees; // 100 = 1%
    uint256 internal constant secondsForYear = 31540000;

    ///
    /// events
    ///

    event LoanCreated(
        address indexed lender,
        address indexed borrower,
        address indexed nftAddress,
        uint256 nftTokenId,
        uint256 loanId
    );

    event LoanLiquidated(
        address indexed lender,
        address indexed borrower,
        address indexed nftAddress,
        uint256 nftTokenId,
        uint256 loanId
    );

    event LoanTerminated(
        address indexed lender,
        address indexed borrower,
        address indexed nftAddress,
        uint256 nftTokenId,
        uint256 loanId
    );

    ///
    /// management
    ///

    /// @notice Set platform fee by owner
    /// @param _currency the currency of loan
    /// @param _platformFee platform fee for each currency
    function setPlatformFee(address _currency, uint256 _platformFee) external onlyOwner {
        require(_platformFee < 1000, "TOO_HIGH_PLATFORM_FEE");
        availableCurrencies[_currency] = true;
        platformFees[_currency] = _platformFee;
    }

    /// @notice Remove currency
    /// @param _currency the currency of loan
    function removeCurrency(address _currency) external onlyOwner {
        require(availableCurrencies[_currency] == true, "CURRENCY_NOT_EXIST");
        availableCurrencies[_currency] = false;
        platformFees[_currency] = 0;
    }

    ///
    /// business logic
    ///

    /// @notice Split signature
    function splitSignature(bytes memory _sig) internal pure returns (uint8, bytes32, bytes32) {
        require(_sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
        // first 32 bytes, after the length prefix
            r := mload(add(_sig, 32))
        // second 32 bytes
            s := mload(add(_sig, 64))
        // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_sig, 96)))
        }
        return (v, r, s);
    }

    /// @notice Recover signer
    function recoverSigner(bytes32 _message, bytes memory _sig) internal pure returns (address) {
        if (_sig.length != 65) {
            return (address(0));
        }

        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(_sig);

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return (address(0));
        }

        return ecrecover(_message, v, r, s);
    }

    /// @notice Calculate dueAmount
    /// @param _loanAmount amount of loan
    /// @param _apr apr of loan
    /// @param _duration duration of loan
    function calculateDueAmount(
        uint256 _loanAmount,
        uint256 _apr,
        uint256 _duration
    ) internal pure returns (uint256) {
        return _loanAmount + (_loanAmount * _apr * _duration * 86400 / secondsForYear / 10000);
    }

    /// @notice Calculate platform fee
    /// @param _loanAmount amount of loan
    /// @param _platformFee platform fee for each currency
    function calculatePlatformFee(
        uint256 _loanAmount,
        uint256 _platformFee
    ) internal pure returns (uint256) {
        return _loanAmount * _platformFee / 10000;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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