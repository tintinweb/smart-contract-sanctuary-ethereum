// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/IJPEGCardsCigStaking.sol";

contract CappedETHDonation is Ownable {
    error OngoingDonation();
    error Unauthorized();
    error InactiveDonation();
    error InvalidAmount();
    error InvalidStart();
    error InvalidDuration();

    event NewDonationEvent(
        uint256 indexed eventId,
        uint256 totalCap,
        uint256 start,
        uint256 end
    );
    event Donation(
        uint256 indexed eventId,
        address indexed account,
        uint256 donatedAmount
    );
    event DonationEnded(uint256 indexed eventId, uint256 ethDonated);

    struct DonationEvent {
        uint256 totalCap;
        uint256 walletCap;
        uint256 whitelistCap;
        uint256 start;
        uint256 whitelistEnd;
        uint256 end;
        uint256 donatedAmount;
        mapping(address => uint256) donations;
    }

    IERC721 public immutable CARDS;
    IJPEGCardsCigStaking public immutable CIG_STAKING;

    uint256 public donationIndex;
    mapping(uint256 => DonationEvent) public donationEvents;

    constructor (IERC721 _cards, IJPEGCardsCigStaking _cigStaking) {
        CARDS = _cards;
        CIG_STAKING = _cigStaking;
    }

    receive() external payable {
        donate();
    }

    /// @notice Returns the amount donated by `_account` in `_eventId`.
    function donatedAmount(uint256 _eventId, address _account)
        external
        view
        returns (uint256)
    {
        return donationEvents[_eventId].donations[_account];
    }

    /// @notice Allows the owner to start a donation event. The event can have a whitelist period if `_whitelistDuration` is greater than 0.
    /// @param _cap The maximum amount of ETH that can be donated
    /// @param _walletCap The maximum amount of ETH that can be donated per wallet
    /// @param _whitelistCap The maximum amount of ETH that can be donated per whitelisted wallet
    /// @param _start The event's start timestamp
    /// @param _whitelistDuration The duration of the whitelist only period, can be 0 for no whitelist
    /// @param _publicDuration The duration of the public donation period
    function newDonationEvent(
        uint256 _cap,
        uint256 _walletCap,
        uint256 _whitelistCap,
        uint256 _start,
        uint256 _whitelistDuration,
        uint256 _publicDuration
    ) external onlyOwner {
        uint256 _donationIndex = donationIndex;
        DonationEvent storage _donation = donationEvents[_donationIndex];
        if (_donation.end != 0) revert OngoingDonation();

        if (_cap == 0 || _walletCap == 0) revert InvalidAmount();

        if (_start < block.timestamp) revert InvalidStart();
        if (_publicDuration == 0) revert InvalidDuration();

        if (_whitelistDuration > 0) {
            if (_whitelistCap == 0) revert InvalidAmount();

            _donation.whitelistCap = _whitelistCap;
            _donation.whitelistEnd = _start + _whitelistDuration;
        } else _donation.whitelistEnd = _start;

        _donation.totalCap = _cap;
        _donation.walletCap = _walletCap;
        _donation.start = _start;
        uint256 _end = _start + _whitelistDuration + _publicDuration;
        _donation.end = _end;

        emit NewDonationEvent(_donationIndex, _cap, _start, _end);
    }

    /// @notice Allows users to donate ETH in the current donation event.
    function donate() public payable {
        uint256 _donationIndex = donationIndex;
        DonationEvent storage _event = donationEvents[_donationIndex];
        if (
            _event.whitelistEnd > block.timestamp ||
            _event.end <= block.timestamp
        ) revert InactiveDonation();

        uint256 _newDonatedAmount = _event.donatedAmount + msg.value;
        uint256 _newUserDonatedAmount = _event.donations[msg.sender] +
            msg.value;
        if (
            msg.value == 0 ||
            _newUserDonatedAmount > _event.walletCap ||
            _newDonatedAmount > _event.totalCap
        ) revert InvalidAmount();

        _event.donations[msg.sender] = _newUserDonatedAmount;
        _event.donatedAmount = _newDonatedAmount;

        emit Donation(_donationIndex, msg.sender, msg.value);
    }

    /// @notice Allows whitelisted users to donate ETH in the current donation event.
    function donateWhitelist() external payable {
        uint256 _donationIndex = donationIndex;
        DonationEvent storage _event = donationEvents[_donationIndex];
        if (
            _event.start > block.timestamp ||
            _event.whitelistEnd <= block.timestamp
        ) revert InactiveDonation();

        if (CARDS.balanceOf(msg.sender) == 0 && !CIG_STAKING.isUserStaking(msg.sender))
            revert Unauthorized();

        uint256 _newDonatedAmount = _event.donatedAmount + msg.value;
        uint256 _newUserDonatedAmount = _event.donations[msg.sender] +
            msg.value;
        if (
            msg.value == 0 ||
            _newUserDonatedAmount > _event.whitelistCap ||
            _newDonatedAmount > _event.totalCap
        ) revert InvalidAmount();

        _event.donations[msg.sender] = _newUserDonatedAmount;
        _event.donatedAmount = _newDonatedAmount;

        emit Donation(_donationIndex, msg.sender, msg.value);
    }

    /// @notice Allows the owner to end the donation if it reached the cap or `block.timestamp` is greater than the current donation's `end` timestamp.
    function endDonation() external onlyOwner {
        uint256 _donationIndex = donationIndex;
        DonationEvent storage _event = donationEvents[_donationIndex];

        if (_event.start == 0) revert InactiveDonation();

        uint256 _donatedAmount = _event.donatedAmount;
        if (_event.totalCap != _donatedAmount) {
            if (block.timestamp < _event.end) revert OngoingDonation();
        }

        donationIndex = _donationIndex + 1;

        (bool _sent, ) = msg.sender.call{value: _donatedAmount}("");
        if (!_sent) revert();

        emit DonationEnded(_donationIndex, _donatedAmount);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IJPEGCardsCigStaking {
    function isUserStaking(address _user) external view returns (bool);
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