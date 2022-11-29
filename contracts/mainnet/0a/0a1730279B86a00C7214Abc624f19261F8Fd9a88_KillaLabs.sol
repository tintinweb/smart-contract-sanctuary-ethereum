// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./StaticNFT.sol";

/* ------------
    Interfaces
   ------------ */

interface IRewarder {
    function reward(
        address recipient,
        uint256[] calldata bears,
        uint256[] calldata rewardIds,
        bytes calldata signature
    ) external;

    function reward(
        address recipient,
        uint256[] calldata bears,
        uint256[] calldata rewardIds
    ) external;
}

interface IKillaBits is IERC721 {
    function tokenUpgrade(uint256 token) external view returns (uint64);
}

/* ---------
    Structs
   --------- */

struct Stake {
    uint32 ts;
    address owner;
    uint16 bit;
}

/* ------
    Main
   ------ */

contract KillaLabs is Ownable, StaticNFT {
    using Strings for uint16;
    using Strings for uint256;

    /* --------
        Errors
       -------- */
    error NotYourToken();
    error NotCompleted();
    error CanNoLongerEscape();
    error ArrayLengthMismatch();
    error StakingNotEnabled();
    error BearAlreadyClaimedReward();
    error BitAlreadyClaimedReward();

    /* --------
        Events
       -------- */
    event EnteredLab(uint256[] bears, uint256[] bits);
    event ExitedLab(uint256[] bears);
    event EscapedLab(uint256[] bears);

    /* --------
        Config
       -------- */
    uint256 public immutable stakeTime;
    IERC721 public immutable killaBearsContract;
    IKillaBits public immutable killaBitsContract;
    IRewarder public rewardsContract;
    bool public stakingEnabled;
    mapping(address => bool) public stakingEnabledFor;

    /* --------
        Stakes
       -------- */
    mapping(uint256 => Stake) public stakes;
    mapping(address => uint256) public balances;
    mapping(uint256 => bool) public bearsClaimed;
    mapping(uint256 => bool) public bitsClaimed;

    constructor(
        address killaBearsAddress,
        address killaBitsAddress,
        uint256 _stakeTime
    ) StaticNFT("KillaLabs", "KillaLabs") {
        stakeTime = _stakeTime;
        killaBearsContract = IERC721(killaBearsAddress);
        killaBitsContract = IKillaBits(killaBitsAddress);
    }

    /* ---------
        Staking
       --------- */

    /// @notice Stake pairs of KILLABEARS and KILLABITS
    function enter(uint256[] calldata bears, uint256[] calldata bits) external {
        if (!stakingEnabled && !stakingEnabledFor[msg.sender])
            revert StakingNotEnabled();

        uint256 index = bears.length;
        if (index != bits.length) revert ArrayLengthMismatch();

        uint256 ts = block.timestamp;

        balances[msg.sender] += index;

        while (index > 0) {
            index--;

            uint256 bear = bears[index];
            uint256 bit = bits[index];

            if (bearsClaimed[bear]) revert BearAlreadyClaimedReward();
            if (bitsClaimed[bit]) revert BitAlreadyClaimedReward();

            killaBearsContract.transferFrom(msg.sender, address(this), bear);
            killaBitsContract.transferFrom(msg.sender, address(this), bit);

            stakes[bear] = Stake(uint32(ts), msg.sender, uint16(bit));

            emit Transfer(address(0), msg.sender, bear);
        }

        emit EnteredLab(bears, bits);
    }

    /// @notice Unstake and claim rewards
    function exit(
        uint256[] calldata bears,
        uint256[] calldata rewards,
        bytes calldata signature
    ) external {
        uint256 index = bears.length;
        balances[msg.sender] -= index;

        while (index > 0) {
            index--;

            uint256 bear = bears[index];
            Stake storage stake = stakes[bear];
            address owner = stake.owner;
            uint256 bit = stake.bit;

            if (owner != msg.sender) revert NotYourToken();
            if (block.timestamp - stake.ts < stakeTime) revert NotCompleted();

            bearsClaimed[bear] = true;
            bitsClaimed[bit] = true;
            killaBearsContract.transferFrom(address(this), owner, bear);
            killaBitsContract.transferFrom(address(this), owner, bit);

            delete stakes[bear];
            emit Transfer(msg.sender, address(0), bear);
        }

        rewardsContract.reward(msg.sender, bears, rewards, signature);

        emit ExitedLab(bears);
    }

    /// @notice Failsafe unstake without claiming after the staking period, but still mark as claimed
    function escapeAndMarkAsClaimed(uint256[] calldata bears) external {
        uint256 index = bears.length;
        balances[msg.sender] -= index;

        while (index > 0) {
            index--;

            uint256 bear = bears[index];
            Stake storage stake = stakes[bear];
            address owner = stake.owner;
            uint256 bit = stake.bit;

            if (owner != msg.sender) revert NotYourToken();
            if (block.timestamp - stake.ts < stakeTime) revert NotCompleted();

            bearsClaimed[bear] = true;
            bitsClaimed[bit] = true;
            killaBearsContract.transferFrom(address(this), owner, bear);
            killaBitsContract.transferFrom(address(this), owner, bit);

            delete stakes[bear];
            emit Transfer(msg.sender, address(0), bear);
        }

        emit ExitedLab(bears);
    }

    /// @notice Unstake prematurely
    function escape(uint256[] calldata bears) external {
        uint256 index = bears.length;
        balances[msg.sender] -= index;

        while (index > 0) {
            index--;

            uint256 bear = bears[index];
            Stake storage stake = stakes[bear];
            address owner = stake.owner;
            uint256 bit = stake.bit;

            if (owner != msg.sender) revert NotYourToken();
            if (block.timestamp - stake.ts >= stakeTime)
                revert CanNoLongerEscape();

            killaBearsContract.transferFrom(address(this), owner, bear);
            killaBitsContract.transferFrom(address(this), owner, bit);

            delete stakes[bear];

            emit Transfer(msg.sender, address(0), bear);
        }
        emit EscapedLab(bears);
    }

    /* -------
        Token
       ------- */

    /// @dev used by StaticNFT base contract
    function getBalance(address _addr)
        internal
        view
        override
        returns (uint256)
    {
        return balances[_addr];
    }

    /// @dev used by StaticNFT base contract
    function getOwner(uint256 tokenId)
        internal
        view
        override
        returns (address)
    {
        return stakes[tokenId].owner;
    }

    /* -------
        Admin
       ------- */

    /// @notice Unstake and claim rewards for holder
    function adminExit(
        address holder,
        uint256[] calldata bears,
        uint256[] calldata rewards
    ) external onlyOwner {
        uint256 index = bears.length;
        balances[holder] -= index;

        while (index > 0) {
            index--;

            uint256 bear = bears[index];
            Stake storage stake = stakes[bear];
            address owner = stake.owner;
            uint256 bit = stake.bit;

            if (owner != holder) revert NotYourToken();
            if (block.timestamp - stake.ts < stakeTime) revert NotCompleted();

            bearsClaimed[bear] = true;
            bitsClaimed[bit] = true;
            killaBearsContract.transferFrom(address(this), owner, bear);
            killaBitsContract.transferFrom(address(this), owner, bit);

            delete stakes[bear];
            emit Transfer(holder, address(0), bear);
        }

        rewardsContract.reward(holder, bears, rewards);

        emit ExitedLab(bears);
    }

    /// @notice Unstake prematurely for holder
    function adminEscape(uint256[] calldata bears) external onlyOwner {
        uint256 index = bears.length;
        while (index > 0) {
            index--;

            uint256 bear = bears[index];
            Stake storage stake = stakes[bear];
            address owner = stake.owner;
            uint256 bit = stake.bit;

            if (block.timestamp - stake.ts >= stakeTime)
                revert CanNoLongerEscape();

            killaBearsContract.transferFrom(address(this), owner, bear);
            killaBitsContract.transferFrom(address(this), owner, bit);

            delete stakes[bear];

            balances[owner]--;

            emit Transfer(owner, address(0), bear);
        }
        emit EscapedLab(bears);
    }

    /// @notice Set the rewarder contract
    function setRewarder(address addr) external onlyOwner {
        rewardsContract = IRewarder(addr);
    }

    /// @notice Enable/disable staking
    function toggleStaking(bool enabled) external onlyOwner {
        stakingEnabled = enabled;
    }

    /// @notice Enable/disable staking for a given wallet
    function toggleStakingFor(address who, bool enabled) external onlyOwner {
        stakingEnabledFor[who] = enabled;
    }

    /// @notice Set the base URI
    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    /* -------
        Other
       ------- */

    /// @dev URI is different based on which bear and bit are staked, how long they've been staked, and the equipped gear
    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        if (getOwner(tokenId) == address(0)) {
            if (bearsClaimed[tokenId]) {
                return
                    string(
                        abi.encodePacked(
                            baseURI,
                            "claimed/",
                            tokenId.toString()
                        )
                    );
            } else {
                return
                    string(
                        abi.encodePacked(
                            baseURI,
                            "escaped/",
                            tokenId.toString()
                        )
                    );
            }
        }

        Stake storage stake = stakes[tokenId];

        uint256 day = (block.timestamp - stake.ts) / 86400 + 1;
        uint256 upgrade = IKillaBits(killaBitsContract).tokenUpgrade(stake.bit);

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        tokenId.toString(),
                        "/",
                        stake.bit.toString(),
                        "/",
                        day.toString(),
                        "/",
                        upgrade.toString()
                    )
                )
                : "";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract StaticNFT is IERC721 {
    using Strings for uint256;

    string public name;
    string public symbol;
    string public baseURI;

    error TransferNotAllowed();
    error InvalidOwner();
    error NonExistentToken();

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function getBalance(address) internal view virtual returns (uint256);

    function getOwner(uint256) internal view virtual returns (address);

    function balanceOf(address owner) external view override returns (uint256) {
        if (owner == address(0)) revert InvalidOwner();
        return getBalance(owner);
    }

    function ownerOf(uint256 tokenId) external view override returns (address) {
        address owner = getOwner(tokenId);
        if (owner == address(0)) revert NonExistentToken();
        return owner;
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override {
        revert TransferNotAllowed();
    }

    function safeTransferFrom(
        address,
        address,
        uint256
    ) external pure override {
        revert TransferNotAllowed();
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external pure override {
        revert TransferNotAllowed();
    }

    function approve(address, uint256) external pure override {
        revert TransferNotAllowed();
    }

    function setApprovalForAll(address, bool) external pure override {
        revert TransferNotAllowed();
    }

    function getApproved(uint256) external pure override returns (address) {
        return address(0);
    }

    function isApprovedForAll(address, address)
        external
        pure
        override
        returns (bool)
    {
        return false;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        returns (string memory)
    {
        if (getOwner(tokenId) == address(0)) revert NonExistentToken();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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