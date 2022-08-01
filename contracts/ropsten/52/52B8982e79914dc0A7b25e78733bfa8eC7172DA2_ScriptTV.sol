// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// OZ helper
import "@openzeppelin/contracts/access/Ownable.sol";

// ERC-721 and ERC-20 interfaces
import "./ScriptPay/IScriptPay.sol";
import "./ScriptGlasses/IScriptGlasses.sol";
import "./ScriptGem/IScriptGem.sol";

/// Amount cannot be zero
error ZeroAmount();

/// Balance cannot be zero
error ZeroBalance();

/// Insufficient asset supply, current `supply`
error InsufficientSupply(uint24 supply);

/// User has insufficient balance, Needed `required` but has `balance`
error InsufficientFunds(uint256 balance, uint256 required);

/// User does not own asset, Needed `owner` but has `caller`
error AssetNotOwned(address caller, address owner);

/// Gem to be equipped is not compatible with the glasses, Needed `glassesType` but has `gemType`
error GemNotCompatible(uint8 gemType, uint8 glassesType);

/// @title Script TV
/// @author @n4beel
/// @notice Contract for Script TV - watch to earn platform
contract ScriptTV is Ownable {
    // Address of the SPAY Token
    IScriptPay public immutable spay;

    // Address of Glasses contract
    IScriptGlasses public immutable scriptGlasses;

    // Address of Gem contract
    IScriptGem public immutable gem;

    // Amount of SPAY tokens locked by an address
    mapping(address => uint256) public lockedBalance;

    // Glass struct for storing data about different glasses types
    // maxSupply - max number of glasses that can be minted
    // mintedSupply - number of glasses already minted
    // collateral - amount of spay locked when minting a pair of glasses
    // cost - amount of spay burnt when minting a pair of glasses
    struct Glass {
        uint24 maxSupply;
        uint24 mintedSupply;
        uint256 collateral;
        uint256 glassCost;
        uint256 gemCost;
    }

    mapping(uint256 => Glass) glasses;

    /**
     * @notice Emitted when user receives a payout
     * @param to address of the receiver
     * @param value amount of spay to be paid out
     */
    event EarningPayout(address indexed to, uint256 value);

    /**
     * @notice Emitted when user receives a payout
     * @param to address of the receiver
     * @param value amount of spay to be paid out
     * @param referral id of the referral
     */
    event ReferralPayout(
        address indexed to,
        uint256 value,
        string indexed referral
    );

    /**
     * @notice Emitted when the user pays SPAY
     * @param from address of the spender
     * @param value amount of spay paid
     * @param glassId id of glasses being recharged
     */
    event RechargeGlasses(
        address indexed from,
        uint256 value,
        uint256 indexed glassId
    );

    /**
     * @notice Emitted when the user pays SPAY
     * @param from address of the spender
     * @param value amount of spay paid
     * @param lootBox id of loot box
     */
    event OpenLootBox(
        address indexed from,
        uint256 value,
        string indexed lootBox
    );

    /**
     * @notice Emitted when the user locks SPAY
     * @param user address of the user locking SPAY
     * @param value amount of spay locked
     */
    event LockSPAY(address indexed user, uint256 indexed value);

    /**
     * @notice Emitted when the user unlocks SPAY
     * @param user address of the user unlocking SPAY
     * @param value amount of spay unlocked
     */
    event UnlockSPAY(address indexed user, uint256 indexed value);

    /**
     * @notice Emitted when the user mints a pair of glasses
     * @param user address of the user minting the glasses
     * @param tokenID ID of glass being minted
     * @param glassType type of glasses being minted
     */
    event GlassMinted(
        address indexed user,
        uint256 indexed tokenID,
        uint8 indexed glassType
    );

    /**
     * @notice Emitted when a pair of glasses are confiscated
     * @param user address of the user
     * @param tokenID ID of glass being confiscated
     */
    event GlassConfiscated(address indexed user, uint256 indexed tokenID);

    /**
     * @notice Emitted when the user mints gems
     * @param user address of the user minting the gems
     * @param tokenID ID of gem being minted
     * @param gemType type of gem minted
     */
    event GemMinted(
        address indexed user,
        uint256 indexed tokenID,
        uint8 indexed gemType
    );

    /**
     * @notice Emitted when the user equips a gem into a glasses' socket
     * @param glassID ID of the glasses
     * @param gemID ID of the gem
     * @param gemType type of gem equipped
     */
    event GemEquipped(
        uint256 indexed glassID,
        uint256 indexed gemID,
        uint8 gemType
    );

    /**
     * @notice Constructor
     * @param _spay spay contract address
     * @param _scriptGlasses glasses contract address
     * @param _scriptGem gem contract address
     */
    constructor(
        IScriptPay _spay,
        IScriptGlasses _scriptGlasses,
        IScriptGem _scriptGem
    ) {
        spay = _spay;
        scriptGlasses = _scriptGlasses;
        gem = _scriptGem;

        // data of common glasses
        glasses[0] = Glass(750000, 0, 20e18, 10e18, 10e18);

        // data of rare glasses
        glasses[1] = Glass(200000, 0, 30e18, 20e18, 20e18);

        // data of superscript glasses
        glasses[2] = Glass(50000, 0, 40e18, 30e18, 30e18);
    }

    /**
     * @notice Locks caller's tokens as investment
     * @param _amount amount of SPAY being locked
     */
    function _lockTokens(uint256 _amount) private {
        if (_amount == 0) {
            revert ZeroAmount();
        }

        spay.transferFrom(msg.sender, address(this), _amount);
        lockedBalance[msg.sender] += _amount;
        emit LockSPAY(msg.sender, _amount);
    }

    /**
     * @notice Unlocks all locked tokens of the caller
     */
    function unlockTokens() external {
        uint256 balance = lockedBalance[msg.sender];
        if (balance == 0) {
            revert ZeroBalance();
        }

        spay.transfer(msg.sender, balance);
        lockedBalance[msg.sender] = 0;
        emit UnlockSPAY(msg.sender, balance);
    }

    /**
     * @notice Mints a pair of glasses, burns caller's spay and locks their collateral
     */
    function mintGlasses(uint8 _type) external {
        uint256 cost = glasses[_type].glassCost;
        uint256 collateral = glasses[_type].collateral;
        if (glasses[_type].mintedSupply >= glasses[_type].maxSupply) {
            revert InsufficientSupply(glasses[_type].mintedSupply);
        }
        if (spay.balanceOf(msg.sender) < cost + collateral) {
            revert InsufficientFunds(spay.balanceOf(msg.sender), cost);
        }

        uint256 tokenID = scriptGlasses.safeMint(msg.sender, _type);
        glasses[_type].mintedSupply++;
        spay.burnFrom(msg.sender, cost);
        _lockTokens(collateral);

        emit GlassMinted(msg.sender, tokenID, _type);
    }

    /**
     * @notice Confiscates user's glasses and transfers to owner
     * @param _tokenID ID of glasses to be confiscated
     */
    function confiscateGlasses(uint256 _tokenID) external onlyOwner {
        address glassesOwner = scriptGlasses.ownerOf(_tokenID);
        scriptGlasses.transferFrom(glassesOwner, address(this), _tokenID);
        emit GlassConfiscated(glassesOwner, _tokenID);
    }

    /**
     * @notice Mints specified gem and burns caller's spay
     * @param _type number of gems to be minted
     */
    function mintGem(uint8 _type) external {
        uint256 cost = glasses[_type].gemCost;
        if (spay.balanceOf(msg.sender) < cost) {
            revert InsufficientFunds(spay.balanceOf(msg.sender), cost);
        }

        uint256 tokenID = gem.safeMint(msg.sender, _type);
        spay.burnFrom(msg.sender, cost);

        emit GemMinted(msg.sender, tokenID, _type);
    }

    /**
     * @notice Equips specified gem into the socket of specified glasses and burns the gem
     * @param _glassID number of gems to be minted
     * @param _gemID number of gems to be minted
     */
    function equipGem(uint256 _glassID, uint256 _gemID) external {
        address glassOwner = scriptGlasses.ownerOf(_glassID);
        address gemOwner = gem.ownerOf(_gemID);
        uint8 glassType = scriptGlasses.glassType(_glassID);
        uint8 gemType = gem.gemType(_gemID);

        if (glassOwner != msg.sender) {
            revert AssetNotOwned(msg.sender, glassOwner);
        }
        if (gemOwner != msg.sender) {
            revert AssetNotOwned(msg.sender, gemOwner);
        }
        if (glassType != gemType) {
            revert GemNotCompatible(gemType, glassType);
        }

        gem.burn(_gemID);
        emit GemEquipped(_glassID, _gemID, gemType);
    }

    /**
     * @notice Rewards earned spay
     * @param _to address of the user to be rewarded
     * @param _amount amount of spay to be rewarded
     * @dev Only callable by Owner, will be called through meta transactions
     */
    function earningPayout(address _to, uint256 _amount) external onlyOwner {
        if (_amount == 0) {
            revert ZeroAmount();
        }
        spay.mint(_to, _amount);
        emit EarningPayout(_to, _amount);
    }

    /**
     * @notice Rewards referral spay
     * @param _to address of the user to be rewarded
     * @param _amount amount of spay to be rewarded
     * @param _referral id of referral
     * @dev Only callable by Owner, will be called through meta transactions
     */
    function referralPayout(
        address _to,
        uint256 _amount,
        string memory _referral
    ) external onlyOwner {
        if (_amount == 0) {
            revert ZeroAmount();
        }
        spay.mint(_to, _amount);
        emit ReferralPayout(_to, _amount, _referral);
    }

    /**
     * @notice Burns spay for recharging the glass
     * @param _user address of the user recharging the glasses
     * @param _amount amount of spay to be burnt
     * @param _glassId glasses being recharged
     */
    function rechargeGlasses(
        address _user,
        uint256 _amount,
        uint256 _glassId
    ) external onlyOwner {
        if (_amount == 0) {
            revert ZeroAmount();
        }
        spay.burnFrom(_user, _amount);
        emit RechargeGlasses(_user, _amount, _glassId);
    }

    /**
     * @notice Burns spay for recharging the glass
     * @param _user address of the user opening the loot box
     * @param _amount amount of spay to be burnt
     * @param _lootBox id of loot box
     */
    function opebLootBox(
        address _user,
        uint256 _amount,
        string memory _lootBox
    ) external onlyOwner {
        if (_amount == 0) {
            revert ZeroAmount();
        }
        spay.burnFrom(_user, _amount);
        emit OpenLootBox(_user, _amount, _lootBox);
    }
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
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Script Pay
/// @author @n4beel
/// @notice Interface for SPAY - native token of Script TV
interface IScriptPay is IERC20 {
    /**
     * @notice Mints SPAY
     * @param to address of the recipient
     * @param amount amount of SPAY to be minted
     * @dev Only callable by Owner, will be called by low level call function
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// Azuki helper
import "erc721a/contracts/IERC721A.sol";

/// @title Common Glasses
/// @author @n4beel
/// @notice Interface for Script TV Glasses
interface IScriptGlasses is IERC721A {
    /**
     * @dev Returns type of the glasses of the provided token ID
     * @param tokenID token ID of the glasses
     * @return type of the token ID
     */
    function glassType(uint256 tokenID) external view returns (uint8);

    /**
     * @notice Mints NFT
     * @param to address of the recipient
     * @param _type type of Glasses NFT to be minted
     * @dev Only callable by Owner, will be called by low level call function
     */
    function safeMint(address to, uint8 _type) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// Azuki helper
import "erc721a/contracts/extensions/IERC721ABurnable.sol";

/// @title Script Gem
/// @author @n4beel
/// @notice Interface for Gems
interface IScriptGem is IERC721ABurnable {
    /**
     * @dev Returns type of the gem of the provided token ID
     * @param tokenID token ID of the gem
     * @return type of the token ID
     */
    function gemType(uint256 tokenID) external view returns (uint8);

    /**
     * @notice Mints NFT
     * @param to address of the recipient
     * @param _type type of Gem NFT to be minted
     * @dev Only callable by Owner, will be called by low level call function
     */
    function safeMint(address to, uint8 _type) external returns (uint256);
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
// ERC721A Contracts v4.2.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of ERC721ABurnable.
 */
interface IERC721ABurnable is IERC721A {
    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external;
}