// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./Interfaces/IWeMintDefi.sol";
import "./Interfaces/IRWeMintNft.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title WeMintDefi
/// @author Bounyavong
/// @dev WeMintDefi is a simple lending/borrowing NFT contract
contract WeMintDefi is IWeMintDefi, IERC721Receiver, Ownable, Pausable {
    // map index -> ListingNftInfo
    mapping(uint256 => ListingNftInfo) public mapNftLists;
    uint256 public countNftLists;

    // map lender address => index => listingId
    mapping(address => mapping(uint256 => uint256)) public mapLenderListingIds;
    // map lender address => count of listed Nft
    mapping(address => uint256) public mapLenderCountNfts;
    // map listingId => lender's nft index
    mapping(uint256 => uint256) public mapLenderIndex;

    // map address -> usdt amount
    mapping(address => uint256) public mapUserBalance;

    // constant struct
    struct Constants {
        address USDT_address;
        address RWeMintNft_address;
        bytes4 ERC721_interfaceId;
        uint16 FEE_defi;
        uint16 PENALTY_lender_weeks;
        uint16 PENALTY_borrower_weeks;
    }

    Constants public CONSTANT_VAR;

    // Events
    event NftListed(uint256 listingId);
    event NftLended(uint256 listingId);
    event NftRefunded(uint256 listingId);
    event NftDeleted(uint256 listingId);

    constructor(
        address usdtAddress,
        address rWeMintNftAddress,
        uint256 feeDefi,
        uint256 lenderPenalty,
        uint256 borrowerPenalty
    ) {
        CONSTANT_VAR.USDT_address = usdtAddress;
        CONSTANT_VAR.RWeMintNft_address = rWeMintNftAddress;
        CONSTANT_VAR.ERC721_interfaceId = 0x80ac58cd;
        CONSTANT_VAR.FEE_defi = uint16(feeDefi); // % (10,000 = 100%)
        CONSTANT_VAR.PENALTY_lender_weeks = uint16(lenderPenalty); // pay money for 2 weeks to the borrower;
        CONSTANT_VAR.PENALTY_borrower_weeks = uint16(borrowerPenalty);
    }

    /** USER */

    /**
     * @dev list NFT token in the Defi to lend. After calling approve()
     */
    function listNft(
        address tokenAddress,
        uint256 tokenId,
        uint256 weeklyRentFee
    ) external whenNotPaused {
        require(
            IERC721(tokenAddress).supportsInterface(
                CONSTANT_VAR.ERC721_interfaceId
            ) == true,
            "NOT_ERC721"
        );
        IERC721(tokenAddress).transferFrom(
            _msgSender(),
            address(this), // smart contract address
            tokenId
        );

        mapNftLists[countNftLists] = ListingNftInfo(
            tokenAddress,
            tokenId,
            _msgSender(),
            address(0),
            weeklyRentFee,
            0,
            0,
            0
        );
        mapLenderIndex[countNftLists] = mapLenderCountNfts[_msgSender()];
        mapLenderListingIds[_msgSender()][
            mapLenderCountNfts[_msgSender()]++
        ] = countNftLists;
        countNftLists++;

        emit NftListed(countNftLists);
    }

    /**
     * @dev deposit USDT to this Defi for Collateral
     */
    function depositCollateral(uint256 amount) external whenNotPaused {
        IERC20(CONSTANT_VAR.USDT_address).transferFrom(
            _msgSender(),
            address(this),
            amount
        );
        mapUserBalance[_msgSender()] += amount;
    }

    /**
     * @dev borrow NFT
     */
    function borrowNft(uint256 listingId, uint256 durationWeeks)
        external
        whenNotPaused
    {
        uint256 requiredCollateral = mapNftLists[listingId].weekly_rent_fee *
            (durationWeeks + CONSTANT_VAR.PENALTY_borrower_weeks);
        require(
            mapUserBalance[_msgSender()] >= requiredCollateral,
            "NOT_ENOUGH_COLLATERAL"
        );
        require(mapNftLists[listingId].start_time == 0, "ALREADY_LENT");
        mapNftLists[listingId].start_time = block.timestamp;
        mapNftLists[listingId].duration_weeks = uint16(durationWeeks);

        mapNftLists[listingId].borrower_address = _msgSender();

        mapUserBalance[_msgSender()] -= requiredCollateral;

        mapNftLists[listingId].r_token_id = IRWeMintNft(
            CONSTANT_VAR.RWeMintNft_address
        ).mint(
                _msgSender(),
                mapNftLists[listingId].token_address,
                mapNftLists[listingId].token_id,
                getExpectedEndTime(listingId)
            );

        emit NftLended(listingId);
    }

    /**
     * @dev end lending for the lender
     */
    function endLending(uint256 listingId)
        external
        whenNotPaused
        whenDealStarted(listingId)
    {
        require(
            mapNftLists[listingId].creator_address == _msgSender(),
            "NOT_LENDER"
        );

        if (block.timestamp < getExpectedEndTime(listingId)) {
            // if the current time is less then the expected end time. expected end time = start time + duration of weeks.
            _payRentFee(listingId, block.timestamp);
            // it pays the current rent fee to the lender.
            _payPenalty(
                mapNftLists[listingId].weekly_rent_fee *
                    CONSTANT_VAR.PENALTY_lender_weeks,
                mapNftLists[listingId].creator_address,
                mapNftLists[listingId].borrower_address
            );
            // it pays the penalty to the borrower because it ends too early.
        } else {
            // this is the normal status. So just pay the rent.
            _payRentFee(listingId, getExpectedEndTime(listingId));
        }

        _cleanListingNft(listingId); // the token is refunded idealy.

        emit NftRefunded(listingId);
    }

    /**
     * @dev end borrowing for the borrower
     */
    function endBorrowing(uint256 listingId)
        external
        whenNotPaused
        whenDealStarted(listingId)
    {
        require(
            mapNftLists[listingId].borrower_address == _msgSender(),
            "NOT_BORROWER"
        );

        if (block.timestamp < getExpectedEndTime(listingId)) {
            // if the current time is less then the expected end time. expected end time = start time + duration of weeks.
            _payRentFee(listingId, block.timestamp);
            // the borrower pays the rent fee to the lender first.
            _payPenalty(
                mapNftLists[listingId].weekly_rent_fee *
                    CONSTANT_VAR.PENALTY_borrower_weeks,
                mapNftLists[listingId].borrower_address,
                mapNftLists[listingId].creator_address
            );
            // the borrower pays the penalty to the lender, because he wants to end the contract too early.
        } else {
            _payRentFee(listingId, getExpectedEndTime(listingId));
        }

        _cleanListingNft(listingId);

        emit NftRefunded(listingId);
    }

    /**
     * @dev withdraw Nft
     */
    function withdrawNft(uint256 listingId) external whenNotPaused {
        require(mapNftLists[listingId].start_time == 0, "ALREADY_LENT");
        require(
            mapNftLists[listingId].creator_address == _msgSender(),
            "NOT_CREATOR"
        );
        IERC721(mapNftLists[listingId].token_address).transferFrom(
            address(this),
            _msgSender(),
            mapNftLists[listingId].token_id
        );
        // transfers the NFT to lender's wallet.

        countNftLists--;
        if (listingId < countNftLists) {
            mapNftLists[listingId] = mapNftLists[countNftLists];
        }

        mapLenderCountNfts[_msgSender()]--;

        uint256 _lenderIndex = mapLenderIndex[listingId];
        if (_lenderIndex < mapLenderCountNfts[_msgSender()]) {
            mapLenderListingIds[_msgSender()][
                _lenderIndex
            ] = mapLenderListingIds[_msgSender()][
                mapLenderCountNfts[_msgSender()]
            ];
            mapLenderIndex[
                mapLenderListingIds[_msgSender()][_lenderIndex]
            ] = _lenderIndex;
        }
        delete mapNftLists[countNftLists];
        delete mapLenderListingIds[_msgSender()][
            mapLenderCountNfts[_msgSender()]
        ];
        delete mapLenderIndex[listingId];

        emit NftDeleted(listingId);
    }

    /**
     * @dev withdraw Balance
     */
    function withdrawBalance() external whenNotPaused {
        IERC20(CONSTANT_VAR.USDT_address).transferFrom(
            address(this),
            _msgSender(),
            mapUserBalance[_msgSender()]
        );
    }

    /** PRIVATE */

    /**
     * @dev end the lending deal
     */
    function _payRentFee(uint256 listingId, uint256 endTime) private {
        address _brAddr = mapNftLists[listingId].borrower_address; // borrower address
        uint256 requiredCollateral = mapNftLists[listingId].weekly_rent_fee *
            (mapNftLists[listingId].duration_weeks +
                CONSTANT_VAR.PENALTY_borrower_weeks);
        // total rent fee + penalty fee
        uint256 rentFee = (mapNftLists[listingId].weekly_rent_fee *
            (endTime - mapNftLists[listingId].start_time)) / 1 weeks;
        // real rent fee
        mapUserBalance[mapNftLists[listingId].creator_address] += ((rentFee *
            (10000 - CONSTANT_VAR.FEE_defi)) / 10000);
        // lender gets the rent fee except the defi fee.
        mapUserBalance[_brAddr] =
            (mapUserBalance[_brAddr] + requiredCollateral) -
            rentFee;
        // the rest of the collateral goes to the borrower's balance

        IRWeMintNft(CONSTANT_VAR.RWeMintNft_address).burn(
            mapNftLists[listingId].r_token_id
        );
        // burn the new copy of the original NFT token.
    }

    /**
     * @dev pay penalty
     */
    function _payPenalty(
        uint256 penaltyAmount,
        address payerAddress,
        address receiverAddress
    ) private {
        require(
            mapUserBalance[payerAddress] >= penaltyAmount,
            "NOT_ENOUGH_BALANCE"
        ); // lender can't end the contract
        mapUserBalance[payerAddress] -= penaltyAmount;
        mapUserBalance[receiverAddress] += penaltyAmount;
    }

    /**
     * @dev clean listing Nft
     */
    function _cleanListingNft(uint256 listingId) private {
        mapNftLists[listingId].start_time = 0;
    }

    /** VIEW */

    /**
     * @dev calc the remaining collateral of the borrower
     * @return remaining collateral amount
     */
    function getExpectedEndTime(uint256 listingId)
        public
        view
        returns (uint256)
    {
        return
            mapNftLists[listingId].start_time +
            mapNftLists[listingId].duration_weeks *
            1 weeks;
        // expected end time = contract start time + duration weeks
    }

    /** ADMIN */

    /**
     * @dev withdraw the fee of the Defi service
     */
    function withdrawFee(uint256 amount) external onlyOwner {
        IERC20(CONSTANT_VAR.USDT_address).transfer(owner(), amount);
    }

    /**
     * @dev pause/unpause the Defi service
     */
    function setPause() external onlyOwner {
        if (paused() == true) {
            _unpause();
        } else {
            _pause();
        }
    }

    /**
     * @dev set constants
     */
    function setConstants(Constants calldata constantVar) external onlyOwner {
        CONSTANT_VAR = constantVar;
    }

    /** MODIFIER */

    modifier whenDealStarted(uint256 listingId) {
        require(mapNftLists[listingId].start_time > 0, "NOT_LENT");
        _;
    }

    /** OVERRIDE */

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface IWeMintDefi {
    // Listing Nft Info
    struct ListingNftInfo {
        address token_address;
        uint256 token_id;
        address creator_address;
        address borrower_address;
        uint256 weekly_rent_fee; // weekly rent fee
        uint256 r_token_id; // tokenId of the RWeMintNft
        uint256 start_time;
        uint16 duration_weeks; // weeks for lending
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface IRWeMintNft {
    // Combined NFT Token Info
    struct TokenInfo {
        address parent_token_address;
        uint256 parent_token_id;
        uint256 expiration_time;
    }

    /**
     * @dev mint a token
     * @param to the address of the token holder
     * @param parentTokenAddress the parent Nft token address
     * @param parentTokenId the parent Nft token id
     * @param expirationTime this Nft will be burned after this time
     */
    function mint(
        address to,
        address parentTokenAddress,
        uint256 parentTokenId,
        uint256 expirationTime
    ) external returns (uint256);

    /**
     * @dev burn a token
     */
    function burn(uint256 tokenId) external;
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