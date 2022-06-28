// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title   Membership Tiers
/// @notice  Tier details for membership NFTs
contract MembershipTiers {
    /// ERRORS ///

    /// @notice Error for if user is not the needed owner
    error NotOwner();
    /// @notice Error for if id does not exisit
    error DoesNotExisit();
    /// @notice Error for if id does not have enough brand tokens deposited
    error NotEnoughDeposited();
    /// @notice Error for if balance is too low
    error BalanceTooLow();
    /// @notice Error for if address is not factory
    error NotFactory();
    /// @notice Error for if address has already been set
    error AddressAlreadySet();
    /// @notice Error for if Ether value is too low
    error EtherValueTooLow();

    /// STRUCTS ///

    /// @notice                 Info for token id
    /// @param tokensSpent      Amount of brand tokens spent towards tiers
    /// @param tokensDeposited  Amount of tokens deposited into NFT
    /// @param activeTill       Timestamp token is active till
    struct IdInfo {
        uint256 tokensSpent;
        uint256 tokensDeposited;
        uint256 activeTill;
    }

    /// @notice                 Info for membership NFT
    /// @param brandToken       Address of brand token of NFT
    /// @param spendAddress     Address where spent tokens get sent to
    /// @param renewalLength    Time added for renewing NFT
    /// @param renewalPrice     Renewal price for NFT
    /// @param extraBurnCredit  Extra credit recieved for burning NFT
    /// @param tokenTiers       Array of credits needed for each tier
    struct NFTInfo {
        address brandToken;
        address spendAddress;
        uint256 renewalLength;
        uint256 renewalPrice;
        uint256 extraBurnCredit;
        uint256[] tokenTiers;
    }

    /// STATE VARIABLES ///
    
    /// @notice Address of kalder factory
    address public kalderFactory;
    /// @notice Owner of contract
    address public immutable owner;

    /// @notice NFT info for nft address
    mapping(address => NFTInfo) public nftInfo;
    /// @notice Id info for id of nft address
    mapping(address => mapping (uint256 => IdInfo)) public idInfo;


    /// CONSTRUCTOR ///

    constructor() { owner = msg.sender; }

    /// OWNER FUNCTION ///

    /// @notice                Sets address of kalder factory
    /// @param kalderFactory_  Address of kalder factory
    function setKalderFactory(address kalderFactory_) external {
        if (msg.sender != owner) revert NotOwner();
        if (kalderFactory != address(0)) revert AddressAlreadySet();
        kalderFactory = kalderFactory_;
    }

    /// FACTORY FUNCTION ///

    /// @notice                        Initialize tier details for `nft_`
    /// @param nft_                    Address of NFT to initialize tier details for
    /// @param brandToken_             Address of brand token of `nft_`
    /// @param spendAddress_           Address where spent brand tokens go
    /// @param renewalPriceAndLength_  Renewal price and length for `nft_`
    /// @param extraBurnCredit_        Extra burn credit received for burning `brandToken_` to `nft_`
    /// @param tokenTiers_             Array of tiers of `brandToken_` for `nft_`
    function initializeTierDetails(
        address nft_,
        address brandToken_,
        address spendAddress_,
        uint256[2] calldata renewalPriceAndLength_,
        uint256 extraBurnCredit_,
        uint256[] calldata tokenTiers_
    ) external {
        if (msg.sender != kalderFactory) revert NotFactory();
        NFTInfo storage _nftInfo = nftInfo[nft_];

        _nftInfo.brandToken = brandToken_;
        _nftInfo.spendAddress = spendAddress_;
        _nftInfo.renewalPrice = renewalPriceAndLength_[0];
        _nftInfo.renewalLength = renewalPriceAndLength_[1];
        _nftInfo.extraBurnCredit = extraBurnCredit_;
        _nftInfo.tokenTiers = tokenTiers_;
    }

    /// USER FUNCTIONS ///

    /// @notice          Recieve credit for either depositing or burning brand token of `nft_`
    /// @param nft_      Address of NFT to look at `id_` from
    /// @param amount_   Amount of brand token to deposit or burn
    /// @param id_       Id of `nft_` add credit of deposited or burned brand tokens
    /// @param spend_    Bool whether or not to deposit or spend brand tokens
    function recieveCredit(
        address nft_,
        uint256 amount_,
        uint256 id_,
        bool spend_
    ) external {
        if (!_exists(nft_, id_)) revert DoesNotExisit();
        NFTInfo memory _nftInfo = nftInfo[nft_];
        IdInfo memory _idInfo = idInfo[nft_][id_];
        if (IERC20(_nftInfo.brandToken).balanceOf(msg.sender) < amount_) revert BalanceTooLow();

        if (spend_) {
            IERC20(_nftInfo.brandToken).transferFrom(msg.sender, _nftInfo.spendAddress, amount_);
            _idInfo.tokensSpent += amount_;
        } else {
            IERC20(_nftInfo.brandToken).transferFrom(msg.sender, address(this), amount_);
            _idInfo.tokensDeposited += amount_;
        }

        idInfo[nft_][id_] = _idInfo;
    }

    /// @notice         Withdraw `amount_` of brand token from `id_` of `nft_`
    /// @param nft_     Address of NFT to look at `id_` from
    /// @param amount_  Amount of brand token to withdraw
    /// @param id_      Id to withdraw brand tokens from
    function withdrawBrandToken(
        address nft_,
        uint256 amount_,
        uint256 id_
    ) external {
        if (IERC721(nft_).ownerOf(id_) != msg.sender) revert NotOwner();
        NFTInfo memory _nftInfo = nftInfo[nft_];
        IdInfo memory _idInfo = idInfo[nft_][id_];
        if (_idInfo.tokensDeposited < amount_) revert NotEnoughDeposited();

        _idInfo.tokensDeposited -= amount_;

        IERC20(_nftInfo.brandToken).transfer(msg.sender, amount_);

        idInfo[nft_][id_] = _idInfo;
    }

    /// @notice          Renew for `periods_` for `id_`
    /// @param nft_      Address of NFT to look at `id_` from
    /// @param periods_  Amount of periods to renew
    /// @param id_       Id of `nft_` to renew
    function renew(
        address nft_,
        uint256 periods_,
        uint256 id_
    ) external payable {
        if (!_exists(nft_, id_)) revert DoesNotExisit();
        NFTInfo memory _nftInfo = nftInfo[nft_];
        IdInfo memory _idInfo = idInfo[nft_][id_];
        if(nft_ != msg.sender) {
            if (_nftInfo.renewalPrice * periods_ > msg.value ) revert EtherValueTooLow();
            _idInfo.activeTill += _nftInfo.renewalLength * periods_;
            payable(nft_).transfer(msg.value);
        } else {
           _idInfo.activeTill = block.timestamp + _nftInfo.renewalLength;
        }

        idInfo[nft_][id_] = _idInfo;
    }

    /// EXTERNAL VIEW FUNCTIONS ///

    /// @notice        Returns amount `tier_` of `id_` of `nft_`
    /// @param nft_    Address of NFT to view `tier_` of `id_`
    /// @param id_     Id that is having tier being checked
    /// @return tier_  Current tier token `id_` is on
    function tier(address nft_, uint256 id_) external view returns (uint256 tier_) {
        NFTInfo memory _nftInfo = nftInfo[nft_];
        IdInfo memory _idInfo = idInfo[nft_][id_];
        if (_idInfo.activeTill < block.timestamp) return 0;
        ++tier_;
        uint256 _brandTokenCredits = brandTokenCredit(nft_, id_);
        for (uint256 i; i < _nftInfo.tokenTiers.length; ++i) {
            if (_brandTokenCredits >= _nftInfo.tokenTiers[i]) ++tier_;
        }
    }

    /// @notice          Returns amount `credit_` token `id_` has
    /// @param nft_      Address of NFT to look at `id_` from
    /// @param id_       Id that is having credit being checked
    /// @return credit_  Amount of creit `id_` has
    function brandTokenCredit(address nft_, uint256 id_) public view returns (uint256 credit_) {
        NFTInfo memory _nftInfo = nftInfo[nft_];
        IdInfo memory _idInfo = idInfo[nft_][id_];
        credit_ +=
            _idInfo.tokensDeposited +
            (_idInfo.tokensSpent +
                ((_idInfo.tokensSpent * _nftInfo.extraBurnCredit) / 100));
    }

    /// INTERNAL VIEW FUNCTIONS ///

    /// @notice       Returns bool of `id_` of `nft_` exisits
    /// @param nft_   Address of NFT to look at `id_` from
    /// @param id_    Id that is being checked if exisits
    /// @return bool  If `id_` of `nft_` exisits
    function _exists(address nft_, uint256 id_) internal view virtual returns (bool) {
        return IERC721(nft_).ownerOf(id_) != address(0);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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