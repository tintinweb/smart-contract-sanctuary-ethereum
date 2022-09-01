// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import "../interface/IBrandTokenFactory.sol";
import "../interface/IMembershipNFTFactory.sol";
import "../interface/IMembershipTiers.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title   Kalder Factory
/// @notice  Factory contract that creates a ERC721 and ERC20 tokens for a brand
/// @author  JeffX
contract KalderFactory {
    /// ERRORS ///

    /// @notice Error for if user is not the needed owner
    error NotOwner();
    /// @notice Error for if address is the 0 address
    error ZeroAddress();
    /// @notice Error for if token tiers are invalid
    error InvalidTokenTiers();
    /// @notice Error for if price tiers are invalid
    error InvalidPriceTiers();
    /// @notice Error for if tier length is invalid
    error InvalidTierLength();
    /// @notice Error for if creation is not public
    error CreationNotPublic();
    /// @notice Error for if address is not a brand token
    error NotBrandToken();

    /// STRUCTS ///

    /// @notice               Creation details for brand
    /// @param membershipNFT  Address of membership NFT
    /// @param brandToken     Address of brand token
    /// @param creator        Address of creator
    struct CreationDetails {
        address membershipNFT;
        address brandToken;
        address creator;
    }

    /// STATE VARIABLES ///

    /// @notice Address of membership NFT factory
    address public immutable membershipNFTFactory;
    /// @notice Address of brand token factory
    address public immutable brandTokenFactory;
    /// @notice Address of membership tier logic
    address public immutable membershipTiers;

    /// @notice Address of owner
    address public owner;
    /// @notice Address where fees will be sent to
    address public kalderWallet;
    /// @notice Percent fee taken
    uint256 public feePercent;
    /// @notice Amount that have been created
    uint256 public created;
    /// @notice Max supply of brand tokens
    uint256 public brandTokenMaxSupply;

    /// @notice Bool if create is open to public
    bool public creationPublic;

    /// @notice Number created to details of creation
    mapping(uint256 => CreationDetails) public creationDetails;
    /// @notice Bool if address can create brand
    mapping(address => bool) public brandCreator;
    /// @notice Bool if address is brand token
    mapping(address => bool) public brandToken;

    /// CONSTRUCTOR  ///

    /// @param brandTokenMaxSupply_   Max supply of brand tokens
    /// @param owner_                 Owner of contract
    /// @param kalderWallet_          Address of kalder wallet
    /// @param membershipNFTFactory_  Membership NFT factory address
    /// @param brandTokenFactory_     Brand token factory address
    /// @param membershipTiers_       Address of membership tiers contract
    constructor(
        uint256 brandTokenMaxSupply_,
        address owner_,
        address kalderWallet_,
        address membershipNFTFactory_,
        address brandTokenFactory_,
        address membershipTiers_
    ) {
        brandTokenMaxSupply = brandTokenMaxSupply_;
        owner = owner_;
        kalderWallet = kalderWallet_;
        membershipNFTFactory = membershipNFTFactory_;
        brandTokenFactory = brandTokenFactory_;
        membershipTiers = membershipTiers_;
    }

    /// OWNER FUNCTIONS ///

    /// @notice           Changing owner of contract to `newOwner_`
    /// @param newOwner_  Address of new owner of contract
    function transferOwnership(address newOwner_) external {
        if (msg.sender != owner) revert NotOwner();
        if (newOwner_ == address(0)) revert ZeroAddress();
        owner = newOwner_;
    }

    /// @notice               Changing kalder wallet to `kalderWallet_`
    /// @param kalderWallet_  Address of kalder wallet
    function setKalderWallet(address kalderWallet_) external {
        if (msg.sender != owner) revert NotOwner();
        if (kalderWallet_ == address(0)) revert ZeroAddress();
        kalderWallet = kalderWallet_;
    }

    /// @notice        Add address to be able to create brand
    /// @param brand_  Address to add as brand creator
    function addBrandCreator(address brand_) external {
        if (msg.sender != owner) revert NotOwner();
        brandCreator[brand_] = true;
    }

    /// @notice        Remove address from being able to create brand
    /// @param brand_  Address to remove as brand creator
    function removeBrandCreator(address brand_) external {
        if (msg.sender != owner) revert NotOwner();
        brandCreator[brand_] = false;
    }

    /// @notice  Setting create function public
    function setCreatePublic() external {
        if (msg.sender != owner) revert NotOwner();
        creationPublic = true;
    }

    /// @notice  Setting create function private
    function setCreatePrivate() external {
        if (msg.sender != owner) revert NotOwner();
        creationPublic = false;
    }

    /// @notice            Setting brand token max supply
    /// @param maxSupply_  Max supply of brand token
    function setBrandTokenMaxSupply_(uint256 maxSupply_) external {
        if (msg.sender != owner) revert NotOwner();
        brandTokenMaxSupply = maxSupply_;
    }

    /// @notice             Updating details for fee
    /// @param feePercent_  Percent fee taken
    function updateFeeDetails(uint256 feePercent_) external {
        if (msg.sender != owner) revert NotOwner();
        feePercent = feePercent_;
    }

    /// USER FUNCTIONS ///

    /// @notice                          Allows user to create a `brandToken_` and `membershipNFT_`
    /// @param nftMaxSupply_             Max supply of `membershipNFT_`
    /// @param pricePerToken_            Price to mint each `membershipNFT_`
    /// @param extraSpendCredit_         Amount of extra credit received towards tier for spending `brandToken_`
    /// @param renewalPriceAndLength_    Length of time renewing `membershipNFT_` will receive and price to renew
    /// @param tokenTiers_               Array of tiers for `membershipNFT_`
    /// @param tierPrices_               Prices if can purchase certain tiers upon minting
    /// @param nftNameAndSymbol_         Array for `membershipNFT_` name and symbol
    /// @param brandTokenNameAndSymbol_  Array of `brandToken_` name and symbol
    /// @return brandToken_              Address of deployed brand ERC20 token
    /// @return membershipNFT_           Address of deployed membership NFT contract
    function create(
        uint256 nftMaxSupply_,
        uint256 pricePerToken_,
        uint256 extraSpendCredit_,
        uint256[2] calldata renewalPriceAndLength_,
        uint256[] calldata tokenTiers_,
        uint256[] calldata tierPrices_,
        string[2] calldata nftNameAndSymbol_,
        string[2] calldata brandTokenNameAndSymbol_
    ) external returns (address brandToken_, address membershipNFT_) {
        if (!creationPublic && !brandCreator[msg.sender]) revert CreationNotPublic();
        if (tokenTiers_.length != tierPrices_.length) revert InvalidTierLength();

        uint256 previousTokenTier_;
        uint256 previousTierPrice_;
        for (uint256 i; i < tokenTiers_.length; ++i) {
            if (tokenTiers_[i] <= previousTokenTier_) revert InvalidTokenTiers();
            if (
                (tierPrices_[i] <= pricePerToken_ && tierPrices_[i] != 0) ||
                (tierPrices_[i] <= previousTierPrice_ && tierPrices_[i] != 0) ||
                (i != 0 && previousTierPrice_ == 0 && tierPrices_[i] != 0)
            ) revert InvalidPriceTiers();
            previousTokenTier_ = tokenTiers_[i];
            previousTierPrice_ = tierPrices_[i];
        }

        brandToken_ = _createBrandToken(brandTokenNameAndSymbol_);

        membershipNFT_ = _createNFT(
            brandToken_,
            nftMaxSupply_,
            pricePerToken_,
            extraSpendCredit_,
            renewalPriceAndLength_,
            tokenTiers_,
            tierPrices_,
            nftNameAndSymbol_
        );
    }

    /// @notice                        Allows user to create a `membershipNFT_`
    /// @param brandToken_             Address of brand token
    /// @param nftMaxSupply_           Max supply of `membershipNFT_`
    /// @param pricePerToken_          Price to mint each `membershipNFT_`
    /// @param extraSpendCredit_       Amount of extra credit received towards tier for spending `brandToken_`
    /// @param renewalPriceAndLength_  Length of time renewing `membershipNFT_` will receive and price to renew
    /// @param tokenTiers_             Array of tiers for `membershipNFT_`
    /// @param tierPrices_             Prices if can purchase certain tiers upon minting
    /// @param nftNameAndSymbol_       Array for `membershipNFT_` name and symbol
    /// @return membershipNFT_         Address of deployed membership NFT contract
    function createNFT(
        address brandToken_,
        uint256 nftMaxSupply_,
        uint256 pricePerToken_,
        uint256 extraSpendCredit_,
        uint256[2] calldata renewalPriceAndLength_,
        uint256[] calldata tokenTiers_,
        uint256[] calldata tierPrices_,
        string[2] calldata nftNameAndSymbol_
    ) external returns (address membershipNFT_) {
        if (!creationPublic && !brandCreator[msg.sender]) revert CreationNotPublic();
        if (!brandToken[brandToken_]) revert NotBrandToken();
        uint256 previousTier_;
        for (uint256 i; i < tokenTiers_.length; ++i) {
            if (tokenTiers_[i] <= previousTier_) revert InvalidTokenTiers();
            previousTier_ = tokenTiers_[i];
        }

        return
            _createNFT(
                brandToken_,
                nftMaxSupply_,
                pricePerToken_,
                extraSpendCredit_,
                renewalPriceAndLength_,
                tokenTiers_,
                tierPrices_,
                nftNameAndSymbol_
            );
    }

    /// INTERNAL FUNCTION ///

    function _createNFT(
        address brandToken_,
        uint256 nftMaxSupply_,
        uint256 pricePerToken_,
        uint256 extraSpendCredit_,
        uint256[2] calldata renewalPriceAndLength_,
        uint256[] calldata tokenTiers_,
        uint256[] calldata tierPrices_,
        string[2] calldata nftNameAndSymbol_
    ) internal returns (address membershipNFT_) {
        membershipNFT_ = IMembershipNFTFactory(membershipNFTFactory).createNFT(
            nftMaxSupply_,
            pricePerToken_,
            feePercent,
            tierPrices_,
            msg.sender,
            membershipTiers,
            nftNameAndSymbol_
        );

        IMembershipTiers(membershipTiers).initializeTierDetails(
            membershipNFT_,
            brandToken_,
            msg.sender,
            renewalPriceAndLength_,
            extraSpendCredit_,
            tokenTiers_
        );

        CreationDetails storage creationDetails_ = creationDetails[created];
        creationDetails_.membershipNFT = membershipNFT_;
        creationDetails_.brandToken = brandToken_;
        creationDetails_.creator = msg.sender;

        ++created;
    }

    function _createBrandToken(string[2] calldata brandTokenNameAndSymbol_) internal returns (address brandToken_) {
        brandToken_ = IBrandTokenFactory(brandTokenFactory).createBrandToken(
            brandTokenMaxSupply,
            msg.sender,
            membershipTiers,
            brandTokenNameAndSymbol_
        );

        brandToken[brandToken_] = true;
    }

    /// EXTERNAL VIEW FUNCTIONS ///

    /// @notice               Returns array of memberships held and ids associated with each
    /// @param user_          Address of user checking memberships
    /// @return memberships_  Array of addresses of memebrships nfts `user_` holds
    /// @return ids_          Array of ids held for `memberships_` of `user_`
    function heldMemberships(address user_)
        external
        view
        returns (address[] memory memberships_, uint256[][] memory ids_)
    {
        CreationDetails memory creationDetails_;
        uint256 activeMemberships_;

        for (uint256 i = 0; i < created; ++i) {
            creationDetails_ = creationDetails[i];
            address nft_ = creationDetails_.membershipNFT;
            uint256 balance_ = IERC721Enumerable(nft_).balanceOf(user_);
            if (balance_ > 0) {
                ++activeMemberships_;
            }
        }

        memberships_ = new address[](activeMemberships_);
        ids_ = new uint256[][](activeMemberships_);

        uint256 membershipOn_;
        for (uint256 i = 0; i < created; ++i) {
            creationDetails_ = creationDetails[i];
            address nft_ = creationDetails_.membershipNFT;
            uint256 balance_ = IERC721Enumerable(nft_).balanceOf(user_);
            uint256[] memory currentIds_ = new uint256[](balance_);
            for (uint256 t = 0; t < balance_; ++t) {
                uint256 id_ = IERC721Enumerable(nft_).tokenOfOwnerByIndex(user_, t);
                currentIds_[t] = id_;

                if (balance_ == t + 1) ids_[membershipOn_] = currentIds_;
            }

            if (balance_ > 0) {
                memberships_[membershipOn_] = nft_;
                ++membershipOn_;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBrandTokenFactory {
    function createBrandToken(
        uint256 maxSupply_,
        address owner_,
        address membershipTiers_,
        string[2] memory brandTokenNameAndSymbol_
    ) external returns (address brandToken_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMembershipNFTFactory {
    function createNFT(
        uint256 maxSupply_,
        uint256 pricePerToken_,
        uint256 kalderFee_,
        uint256[] memory tierPrices_,
        address owner_,
        address membershipTiers_,
        string[2] memory nftNameAndSymbol_
    ) external returns (address membershipNFT_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMembershipTiers {
    function initializeTierDetails(
        address nft_,
        address brandToken_,
        address brandAddress,
        uint256[2] calldata renewalPriceAndLength_,
        uint256 extraSpendCredit_,
        uint256[] calldata tokenTiers_
    ) external;

    function tier(address nft_, uint256 id_) external view returns (uint256 tier_, uint256 creditNeeded_);

    function brandTokenCredit(address nft_, uint256 id_) external view returns (uint256 credit_);

    function renew(
        address nft_,
        uint256 periods_,
        uint256 id_
    ) external;

    function mint(uint256 tiersUp_, uint256 id_) external returns (uint256 activeTill_, uint256 credit_);

    function renewalFees(address nft_) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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