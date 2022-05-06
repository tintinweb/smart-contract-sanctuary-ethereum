// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

// SPDX-License-Identifier: MIT

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


// File @openzeppelin/contracts/token/ERC721/[email protected]


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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File contracts/rentAdapters/libraries/LibLandworks.sol

pragma solidity 0.8.0;

library LibLandworks {
    enum AssetStatus {
        Listed,
        Delisted
    }

    struct Asset {
        uint256 metaverseId;
        address metaverseRegistry;
        uint256 metaverseAssetId;
        address paymentToken;
        uint256 minPeriod;
        uint256 maxPeriod;
        uint256 maxFutureTime;
        uint256 pricePerSecond;
        uint256 totalRents;
        AssetStatus status;
    }

    struct Rent {
        address renter;
        uint256 start;
        uint256 end;
    }
}


// File contracts/rentAdapters/interfaces/ILandworks.sol

pragma solidity 0.8.0;
interface ILandworks {
    // MarketplaceFacet
    function list(
        uint256 _metaverseId,
        address _metaverseRegistry,
        uint256 _metaverseAssetId,
        uint256 _minPeriod,
        uint256 _maxPeriod,
        uint256 _maxFutureTime,
        address _paymentToken,
        uint256 _pricePerSecond
    ) external returns (uint256);

    function changeConsumer(address _consumer, uint256 _tokenId) external;

    function delist(uint256 _assetId) external;

    function withdraw(uint256 _assetId) external;

    function rentAt(uint256 _assetId, uint256 _rentId) external view returns (LibLandworks.Rent memory);

    function assetAt(uint256 _assetId) external view returns (LibLandworks.Asset memory);

    // ERC721 functions
    function ownerOf(uint256 tokenId) external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    // FeeFacet functions
    function assetRentFeesFor(uint256 _assetId, address _token) external view returns (uint256);

    function claimRentFee(uint256 _assetId) external;
}


// File @openzeppelin/contracts/token/ERC721/[email protected]


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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


// File @openzeppelin/contracts/token/ERC721/utils/[email protected]


pragma solidity ^0.8.0;

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
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


// File @openzeppelin/contracts/security/[email protected]


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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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


// File contracts/rentAdapters/interfaces/IBaseRentAdapter.sol

pragma solidity 0.8.0;
interface IBaseRentAdapter {
    function withdrawNFTFromRent(uint256 loanId) external;
}


// File contracts/rentAdapters/BaseRentAdapter.sol

pragma solidity 0.8.0;
contract BaseRentAdapter is ERC721Holder, ReentrancyGuard {
    using Address for address;

    address public immutable TRIBE_ONE_ADDRESS;

    address public devWallet;

    constructor(address _TRIBE_ONE_ADDRESS, address _devWallet) {
        require(_TRIBE_ONE_ADDRESS.isContract(), "BRA: Only contract address is available");
        TRIBE_ONE_ADDRESS = _TRIBE_ONE_ADDRESS;
        devWallet = _devWallet;
    }

    modifier onlyTribeOne() {
        require(msg.sender == TRIBE_ONE_ADDRESS, "BRA: Only TribeOne is allowed");
        _;
    }

    function setDevWallet(address _devWallet) external {
        require(msg.sender == _devWallet, "Only dev can change dev wallet");
        devWallet = _devWallet;
    }

    // function listNFTForRent(uint256 loandId) external virtual {}

    // function withdrawNFTFromRent(uint256 loanId) external virtual override {}

    // function claimRentFee(uint256 loanId) external virtual {}

    // function adjustRentFee(uint256 loanId) external virtual {}
}


// File contracts/libraries/DataTypes.sol

pragma solidity 0.8.0;

library DataTypes {
    enum Status {
        AVOID_ZERO, // just for avoid zero
        LISTED, // after the loan has been created --> the next status will be APPROVED
        APPROVED, // in this status the loan has a lender -- will be set after approveLoan(). loan fund => borrower
        LOANACTIVED, // NFT was brought from opensea by agent and staked in TribeOne - relayNFT()
        LOANPAID, // loan was paid fully but still in TribeOne
        WITHDRAWN, // the final status, the collateral returned to the borrower or to the lender withdrawNFT()
        FAILED, // NFT buying order was failed in partner's platform such as opensea...
        CANCELLED, // only if loan is LISTED - cancelLoan()
        DEFAULTED, // Grace period = 15 days were passed from the last payment schedule
        LIQUIDATION, // NFT was put in marketplace
        POSTLIQUIDATION, /// NFT was sold
        RESTWITHDRAWN, // user get back the rest of money from the money which NFT set is sold in marketplace
        RESTLOCKED, // Rest amount was forcely locked because he did not request to get back with in 2 weeks (GRACE PERIODS)
        REJECTED // Loan should be rejected when requested loan amount is less than fund amount because of some issues such as big fluctuation in marketplace
    }

    struct Asset {
        uint256 amount;
        address currency; // address(0) is ETH native coin
    }

    struct LoanRules {
        uint16 tenor;
        uint16 LTV; // 10000 - 100%
        uint16 interest; // 10000 - 100%
    }

    struct NFTItem {
        address nftAddress;
        bool isERC721;
        uint256 nftId;
    }

    struct Loan {
        uint256 fundAmount; // the amount which user put in TribeOne to buy NFT
        uint256 paidAmount; // the amount that has been paid back to the lender to date
        uint256 loanStart; // the point when the loan is approved
        uint256 postTime; // the time when NFT set was sold in marketplace and that money was put in TribeOne
        uint256 restAmount; // rest amount after sending loan debt(+interest) and 5% penalty
        address borrower; // the address who receives the loan
        uint8 nrOfPenalty;
        uint8 passedTenors; // the number of tenors which we can consider user passed - paid tenor
        Asset loanAsset;
        Asset collateralAsset;
        Status status; // the loan status
        LoanRules loanRules;
        NFTItem nftItem;
    }
}


// File contracts/interfaces/ITribeOne.sol

pragma solidity 0.8.0;
interface ITribeOne {
    event LoanCreated(uint256 indexed loanId, address indexed owner, address nftAddress, uint256 nftTokenId, bool isERC721);
    event LoanApproved(uint256 indexed _loanId, address indexed _to, address _fundCurreny, uint256 _fundAmount);
    event LoanCanceled(uint256 indexed _loanId, address _sender);
    event NFTRelayed(uint256 indexed _loanId, address indexed _sender, bool _accepted);
    event InstallmentPaid(uint256 indexed _loanId, address _sender, address _currency, uint256 _amount);
    event NFTWithdrew(uint256 indexed _loanId, address _to);
    event LoanDefaulted(uint256 indexed _loandId);
    event LoanLiquidation(uint256 indexed _loanId, address _salesManager);
    event LoanPostLiquidation(uint256 indexed _loanId, uint256 _soldAmount, uint256 _finalDebt);
    event RestWithdrew(uint256 indexed _loanId, uint256 _amount);
    event SettingsUpdate(address _feeTo, uint256 _lateFee, uint256 _penaltyFee, address _salesManager, address _assetManager);
    event LoanRejected(uint256 indexed _loanId, address _agent);
    event LoanRented(uint256 indexed _loanId, address indexed _adapter);
    event LoanWithdrawFromRent(uint256 indexed _loanId, address _adapter);

    function approveLoan(
        uint256 _loanId,
        uint256 _amount,
        address _agent
    ) external;

    function relayNFT(
        uint256 _loanId,
        address _agent,
        bool _accepted
    ) external payable;

    function payInstallment(uint256 _loanId, uint256 _amount) external payable;

    function getLoans(uint256 _loanId) external view returns (DataTypes.Loan memory);

    function getLoanNFTItem(uint256 _loanId) external view returns (DataTypes.NFTItem memory);

    function getLoanAsset(uint256 _loanId) external view returns (uint256, address);

    function getCollateralAsset(uint256 _loanId) external view returns (uint256, address);

    function getLoanRent(uint256 _loanId) external view returns (address);

    function totalDebt(uint256 _loanId) external view returns (uint256);

    function currentDebt(uint256 _loanId) external view returns (uint256);

    function listNFTForRent(uint256 loanId, address borrower) external;

    function withdrawNFTFromRent(uint256 loanId) external;

    function isAvailableRentalAction(uint256 loanId, address user) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC1155/[email protected]


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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}


// File contracts/libraries/TribeOneHelper.sol


pragma solidity 0.8.0;
library TribeOneHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeApprove: approve failed");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TribeOneHelper::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TribeOneHelper::transferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TribeOneHelper::safeTransferETH: ETH transfer failed");
    }

    function safeTransferAsset(
        address token,
        address to,
        uint256 value
    ) internal {
        if (token == address(0)) {
            safeTransferETH(to, value);
        } else {
            safeTransfer(token, to, value);
        }
    }

    function safeNFTApproveForAll(
        address nft,
        address operator,
        bool approved
    ) internal {
        // bytes4(keccak256(bytes('setApprovalForAll(address,bool)')));
        (bool success, ) = nft.call(abi.encodeWithSelector(0xa22cb465, operator, approved));
        require(success, "TribeOneHelper::safeNFTApproveForAll: Failed");
    }

    function safeTransferNFT(
        address _nft,
        address _from,
        address _to,
        bool isERC721,
        uint256 _tokenId
    ) internal {
        if (isERC721) {
            IERC721(_nft).safeTransferFrom(_from, _to, _tokenId);
        } else {
            IERC1155(_nft).safeTransferFrom(_from, _to, _tokenId, 1, "0x00");
        }
    }

    /**
     * @dev this function calculates expected price of NFT based on created LTV and fund amount,
     * LTV: 10000 = 100%; _slippage: 10000 = 100%
     */
    function getExpectedPrice(
        uint256 _fundAmount,
        uint256 _percentage,
        uint256 _slippage
    ) internal pure returns (uint256) {
        require(_percentage != 0, "TribeOneHelper: percentage should not be 0");
        return (_fundAmount * (10000 + _slippage)) / _percentage;
    }
}


// File contracts/rentAdapters/LandworksAdapter.sol

pragma solidity 0.8.0;
contract LandworksAdapter is BaseRentAdapter {
    using Address for address;
    enum RentStatus {
        NONE,
        RENTAL,
        DELISTED,
        WITHDRAWN
    }

    address constant LANDWORKS_ETHEREUM_PAYMENT_TOKEN = address(1);
    address constant TRIBEONE_ETHEREUM_PAYMENT_TOKEN = address(0);
    address public immutable LAND_WORKS_ADDRESS;
    // loanId => assetId
    mapping(uint256 => uint256) public rentAssetIdMap;
    mapping(uint256 => RentStatus) public rentStatusMap;

    bytes4 public constant ERC721_Interface = bytes4(0x80ac58cd);

    event LoanRented(uint256 indexed loanId, uint256 indexed assetId);
    event RentDelisted(uint256 indexed loanId, uint256 indexed assetId);
    event RentWithdraw(uint256 indexed loanId, uint256 indexed assetId);
    event ClaimRentFee(uint256 indexed loanId, address token, uint256 amount);
    event AdjustRentFee(uint256 indexed loanId, address token, uint256 totalRentFee, uint256 paidDebt);
    event ForceWithdraw(uint256 indexed loanId, bool isWithdraw);

    constructor(
        address _LAND_WORKS_ADDRESS,
        address _TRIBE_ONE_ADDRESS,
        address __devWallet
    ) BaseRentAdapter(_TRIBE_ONE_ADDRESS, __devWallet) {
        LAND_WORKS_ADDRESS = _LAND_WORKS_ADDRESS;
    }

    receive() external payable {}

    function listNFTforRenting(
        uint256 _metaverseId,
        uint256 _minPeriod,
        uint256 _maxPeriod,
        uint256 _maxFutureTime,
        address _paymentToken,
        uint256 _pricePerSecond,
        uint256 _loanId
    ) external {
        // Validate Listing
        DataTypes.NFTItem memory nftItem = ITribeOne(TRIBE_ONE_ADDRESS).getLoanNFTItem(_loanId);

        ITribeOne(TRIBE_ONE_ADDRESS).listNFTForRent(_loanId, msg.sender);

        _requireERC721(nftItem.nftAddress);

        IERC721(nftItem.nftAddress).approve(LAND_WORKS_ADDRESS, nftItem.nftId);

        // call list function in Landworks smart contract
        uint256 assetId = ILandworks(LAND_WORKS_ADDRESS).list(
            _metaverseId,
            nftItem.nftAddress, // _metaverseRegistry
            nftItem.nftId, // _metaverseAssetId
            _minPeriod,
            _maxPeriod,
            _maxFutureTime,
            _paymentToken,
            _pricePerSecond
        );

        rentAssetIdMap[_loanId] = assetId;
        rentStatusMap[_loanId] = RentStatus.RENTAL;

        emit LoanRented(_loanId, assetId);
    }

    function delistNFTFromRenting(uint256 _loanId) external nonReentrant {
        _delistNFTFromRenting(_loanId, false);
    }

    function _delistNFTFromRenting(uint256 _loanId, bool isForce) private {
        DataTypes.NFTItem memory nftItem = ITribeOne(TRIBE_ONE_ADDRESS).getLoanNFTItem(_loanId);

        require(
            ITribeOne(TRIBE_ONE_ADDRESS).isAvailableRentalAction(_loanId, msg.sender) || isForce,
            "Only loan borrower or T1 can delist."
        );

        uint256 assetId = rentAssetIdMap[_loanId];

        address paymentToken = ILandworks(LAND_WORKS_ADDRESS).assetAt(assetId).paymentToken;
        uint256 feeAmount = _getRentFeeAmount(assetId, paymentToken);

        ILandworks(LAND_WORKS_ADDRESS).delist(assetId);
        if (IERC721(nftItem.nftAddress).ownerOf(nftItem.nftId) == address(this)) {
            // NFT was withdrawn
            IERC721(nftItem.nftAddress).approve(TRIBE_ONE_ADDRESS, nftItem.nftId);
            ITribeOne(TRIBE_ONE_ADDRESS).withdrawNFTFromRent(_loanId);
            rentStatusMap[_loanId] = RentStatus.WITHDRAWN;

            if (feeAmount > 0) {
                isForce
                    ? _safeTransferAsset(paymentToken, devWallet, feeAmount)
                    : _safeTransferAsset(paymentToken, msg.sender, feeAmount);
            }
            emit RentWithdraw(_loanId, assetId);
            if (!isForce) {
                emit ClaimRentFee(_loanId, paymentToken, feeAmount);
            }
        } else {
            // remain NFT in Landworks because someone is leasing it now
            rentStatusMap[_loanId] = RentStatus.DELISTED;

            emit RentDelisted(_loanId, assetId);
        }
    }

    function withdrawNFTFromRenting(uint256 _loanId) external nonReentrant {
        _withdraw(_loanId, false);
    }

    function _withdraw(uint256 _loanId, bool isForce) private {
        require(rentStatusMap[_loanId] == RentStatus.DELISTED, "LandworksAdapter: NFT shoud be delisted first");
        // DataTypes.Loan memory _loan = ITribeOne(TRIBE_ONE_ADDRESS).getLoans(_loanId);
        DataTypes.NFTItem memory nftItem = ITribeOne(TRIBE_ONE_ADDRESS).getLoanNFTItem(_loanId);

        require(
            ITribeOne(TRIBE_ONE_ADDRESS).isAvailableRentalAction(_loanId, msg.sender) || isForce,
            "Only loan borrower or T1 can withdraw"
        );

        uint256 assetId = rentAssetIdMap[_loanId];

        address paymentToken = ILandworks(LAND_WORKS_ADDRESS).assetAt(assetId).paymentToken;
        uint256 feeAmount = _getRentFeeAmount(assetId, paymentToken);

        ILandworks(LAND_WORKS_ADDRESS).withdraw(assetId);

        require(IERC721(nftItem.nftAddress).ownerOf(nftItem.nftId) == address(this), "LandworksAdapter: Withdraw was failed");

        if (feeAmount > 0) {
            isForce
                ? _safeTransferAsset(paymentToken, devWallet, feeAmount)
                : _safeTransferAsset(paymentToken, msg.sender, feeAmount);
        }
        IERC721(nftItem.nftAddress).approve(TRIBE_ONE_ADDRESS, nftItem.nftId);

        ITribeOne(TRIBE_ONE_ADDRESS).withdrawNFTFromRent(_loanId);

        rentStatusMap[_loanId] = RentStatus.WITHDRAWN;

        emit RentWithdraw(_loanId, assetId);
        if (!isForce) {
            emit ClaimRentFee(_loanId, paymentToken, feeAmount);
        }
    }

    function forceWithdrawNFTFromRent(uint256 loanId) external onlyTribeOne {
        if (rentStatusMap[loanId] == RentStatus.RENTAL) {
            _delistNFTFromRenting(loanId, true);
            emit ForceWithdraw(loanId, false);
        } else if (rentStatusMap[loanId] == RentStatus.DELISTED) {
            _withdraw(loanId, true);
            emit ForceWithdraw(loanId, true);
        }
    }

    function claimRentFee(uint256 loanId) external nonReentrant {
        require(
            ITribeOne(TRIBE_ONE_ADDRESS).isAvailableRentalAction(loanId, msg.sender),
            "Only loan borrower or T1 can withdraw"
        );

        uint256 assetId = rentAssetIdMap[loanId];

        address paymentToken = ILandworks(LAND_WORKS_ADDRESS).assetAt(assetId).paymentToken;

        uint256 feeAmount = _getRentFeeAmount(assetId, paymentToken);

        if (feeAmount > 0) {
            _claimFeeFromRental(assetId);

            _safeTransferAsset(paymentToken, msg.sender, feeAmount);

            emit ClaimRentFee(loanId, paymentToken, feeAmount);
        }
    }

    function adjustRentFee(uint256 loanId) external nonReentrant {
        // DataTypes.Loan memory _loan = ITribeOne(TRIBE_ONE_ADDRESS).getLoans(loanId);
        require(ITribeOne(TRIBE_ONE_ADDRESS).isAvailableRentalAction(loanId, msg.sender), "Only loan borrower can withdraw");

        uint256 assetId = rentAssetIdMap[loanId];
        address paymentToken = ILandworks(LAND_WORKS_ADDRESS).assetAt(assetId).paymentToken;

        (, address loanCurrency) = ITribeOne(TRIBE_ONE_ADDRESS).getLoanAsset(loanId);

        require(
            (paymentToken == LANDWORKS_ETHEREUM_PAYMENT_TOKEN && loanCurrency == TRIBEONE_ETHEREUM_PAYMENT_TOKEN) ||
                paymentToken == loanCurrency,
            "Rent payment token is not same as loan asset"
        );

        uint256 feeAmount = _getRentFeeAmount(assetId, paymentToken);

        if (feeAmount > 0) {
            _claimFeeFromRental(assetId);

            uint256 debtAmount = ITribeOne(TRIBE_ONE_ADDRESS).currentDebt(loanId);

            if (feeAmount > debtAmount) {
                TribeOneHelper.safeTransferAsset(loanCurrency, msg.sender, feeAmount - debtAmount);
            } else {
                debtAmount = feeAmount;
            }

            if (paymentToken == LANDWORKS_ETHEREUM_PAYMENT_TOKEN) {
                ITribeOne(TRIBE_ONE_ADDRESS).payInstallment{value: debtAmount}(loanId, debtAmount);
            } else {
                TribeOneHelper.safeApprove(paymentToken, TRIBE_ONE_ADDRESS, debtAmount);
                ITribeOne(TRIBE_ONE_ADDRESS).payInstallment(loanId, debtAmount);
            }

            emit AdjustRentFee(loanId, paymentToken, feeAmount, debtAmount);
        }
    }

    function _claimFeeFromRental(uint256 assetId) private {
        ILandworks(LAND_WORKS_ADDRESS).claimRentFee(assetId);
    }

    function getRentFeeAmount(uint256 loanId) external view returns (uint256) {
        uint256 assetId = rentAssetIdMap[loanId];
        address paymentToken = ILandworks(LAND_WORKS_ADDRESS).assetAt(assetId).paymentToken;

        return _getRentFeeAmount(assetId, paymentToken);
    }

    function _getRentFeeAmount(uint256 assetId, address paymentToken) private view returns (uint256) {
        return ILandworks(LAND_WORKS_ADDRESS).assetRentFeesFor(assetId, paymentToken);
    }

    function _safeTransferAsset(
        address token,
        address to,
        uint256 amount
    ) private {
        if (token == LANDWORKS_ETHEREUM_PAYMENT_TOKEN) {
            TribeOneHelper.safeTransferETH(to, amount);
        } else {
            TribeOneHelper.safeTransfer(token, to, amount);
        }
    }

    function _requireERC721(address nftAddress) internal view {
        require(nftAddress.isContract(), "The NFT Address should be a contract");

        // ERC721Interface nftRegistry = ERC721Interface(nftAddress);
        require(IERC165(nftAddress).supportsInterface(ERC721_Interface), "The NFT contract has an invalid ERC721 implementation");
    }
}