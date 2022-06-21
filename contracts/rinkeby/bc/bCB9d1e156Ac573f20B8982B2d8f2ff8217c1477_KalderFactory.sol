// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import "../interface/IBrandTokenFactory.sol";
import "../interface/IMembershipNFTFactory.sol";
import "../interface/IMembershipTiers.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title   Kalder Factory
/// @notice  Factory contract that creates a ERC721 and ERC20 tokens for a brand
contract KalderFactory {
    /// ERRORS ///

    /// @notice Error for if user is not the needed owner
    error NotOwner();
    /// @notice Error for if address is the 0 address
    error ZeroAddress();
    /// @notice Error for if tiers are invalid
    error InvalidTiers();

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
    /// @notice Addess of token fee is taken in
    address public feeToken;
    /// @notice Amount of token for fee
    uint256 public feeAmount;
    /// @notice Amount that have been created
    uint256 public created;
    /// @notice Number created to details of creation
    mapping(uint256 => CreationDetails) public creationDetails;

    /// CONSTRUCTOR  ///

    /// @param owner_                 Owner of contract
    /// @param membershipNFTFactory_  Membership NFT factory address
    /// @param brandTokenFactory_     Brand token factory address
    constructor(
        address owner_,
        address membershipNFTFactory_,
        address brandTokenFactory_,
        address membershipTiers_
    ) {
        owner = owner_;
        membershipNFTFactory = membershipNFTFactory_;
        brandTokenFactory = brandTokenFactory_;
        membershipTiers = membershipTiers_;
    }

    /// OWNER FUNCTIONS ///

    /// @notice           Changing owner of contract to `newOwner_`
    /// @param newOwner_  Address of who will be the new owner of contract
    function transferOwnership(address newOwner_) external {
        if (msg.sender != owner) revert NotOwner();
        if (newOwner_ == address(0)) revert ZeroAddress();
        owner = newOwner_;
    }

    /// @notice  Setting ownership of contract to the 0 address
    function revertOwnership() external {
        if (msg.sender != owner) revert NotOwner();
        owner = address(0);
    }

    /// @notice            Updating details for fee
    /// @param feeToken_   Address of token fee will be taken in
    /// @param feeAmount_  Amount of `feeToken_` for fee
    function updateFeeDetails(address feeToken_, uint256 feeAmount_) external {
        if (msg.sender != owner) revert NotOwner();

        feeToken = feeToken_;
        feeAmount = feeAmount_;
    }

    /// @notice         Withdraw `amount_` of `token_` from contract to `to_`
    /// @param to_      Address of who will recieve `amount_` of `token_`
    /// @param token_   Token address to withdraw
    /// @param amount_  Amount of `token_` being withdrawn
    function withdraw(
        address to_,
        address token_,
        uint256 amount_
    ) external {
        if (msg.sender != owner) revert NotOwner();

        IERC20(token_).transfer(to_, amount_);
    }

    /// USER FUNCTIONS ///

    /// @notice                          Allows user to create a `brandToken_` and `membershipNFT_`
    /// @param nftMaxSupply_             Max supply of `brandToken_`
    /// @param pricePerToken_            Price to mint each `membershipNFT_`
    /// @param extraBurnCredit_          Amount of extra credit received towards tier for burning `brandToken_`
    /// @param renewalPriceAndLength_    Length of time renewing `membershipNFT_` will recieve and price to renew
    /// @param tokenTiers_               Array of tiers for `membershipNFT_`
    /// @param brandTokenMaxSupply_      Max supply of `brandToken_`
    /// @param nftNameAndSymbol_         Array for `membershipNFT_` name and symbol
    /// @param brandTokenNameAndSymbol_  Array of `brandToken_` name and symbol
    /// @return brandToken_              Address of dpeloyed brand ERC20 token
    /// @return membershipNFT_           Address of deployed membership NFT contract
    function create(
        uint256 nftMaxSupply_,
        uint256 pricePerToken_,
        uint256 extraBurnCredit_,
        uint256[2] memory renewalPriceAndLength_,
        uint256[] memory tokenTiers_,
        uint256 brandTokenMaxSupply_,
        string[2] memory nftNameAndSymbol_,
        string[2] memory brandTokenNameAndSymbol_
    ) external returns (address brandToken_, address membershipNFT_) {
        if (feeToken != address(0)) IERC20(feeToken).transferFrom(msg.sender, address(this), feeAmount);

        uint256 _previousTier;
        for (uint256 i; i < tokenTiers_.length; ++i) {
            if (tokenTiers_[i] <= _previousTier) revert InvalidTiers();
            _previousTier = tokenTiers_[i];
        }

        brandToken_ = IBrandTokenFactory(brandTokenFactory).createBrandToken(
            brandTokenMaxSupply_,
            msg.sender,
            membershipTiers,
            brandTokenNameAndSymbol_
        );
        membershipNFT_ = IMembershipNFTFactory(membershipNFTFactory).createNFT(
            nftMaxSupply_,
            pricePerToken_,
            msg.sender,
            membershipTiers,
            nftNameAndSymbol_
        );

        IMembershipTiers(membershipTiers).initializeTierDetails(
            membershipNFT_,
            brandToken_,
            renewalPriceAndLength_,
            extraBurnCredit_,
            tokenTiers_
        );

        CreationDetails storage _creationDetails = creationDetails[created];
        _creationDetails.membershipNFT = membershipNFT_;
        _creationDetails.brandToken = brandToken_;
        _creationDetails.creator = msg.sender;

        ++created;
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
        uint256[2] calldata renewalPriceAndLength_,
        uint256 extraBurnCredit_,
        uint256[] calldata tokenTiers_
    ) external;

    function tier(address nft_, uint256 id_) external view returns (uint256 tier_);

    function brandTokenCredit(address nft_, uint256 id_) external view returns (uint256 credit_);

    function renew(
        address nft_,
        uint256 periods_,
        uint256 id_
    ) external;
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