// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IERC20PermitUpgradeable.sol";
import "./interfaces/IERC721Upgradeable.sol";
import "./Settings.sol";
import "./PlayerDraft.sol";
import "./PlayerAuction.sol";
import "./PlayerSwap.sol";
import "./PlayerOperations.sol";

contract PlayerCore is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    Settings,
    PlayerDraft,
    PlayerAuction,
    PlayerSwap,
    PlayerOperations
{
    function __playerCore_init(
        address _leagToken,
        address _dleagToken,
        address _playerV2,
        address _fantasyLeague,
        uint256 _divisionId,
        bytes32 _merkleRoot
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __settings_init(_leagToken, _playerV2, _fantasyLeague, _merkleRoot);
        __playerDraft_init(_dleagToken, _divisionId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable is IERC20Upgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to) external;

    function burn(uint256 tokenId) external;

    /** todo integration with Blaize
     * @dev Creates a new token random token for `to`. Its token ID will be
     * assigned by the id passed from external source (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     * This function is only for development purposes and should be revoked once integration with Blaize starts
     */
    function mintRandom(address to, uint256 tokenId) external;

    function UserToDivision(address user_address) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "./lib/DraftPickLib.sol";
import "./interfaces/IERC20PermitUpgradeable.sol";
import "./interfaces/IERC721Upgradeable.sol";
import "./interfaces/IFantasyLeague.sol";

/// @title PlayerCore marketplace contract.
contract Settings is OwnableUpgradeable {
    using DraftPickLib for address[];

    // ============ Storage ============
    bytes32 public merkleRoot;

    /// @notice Player2 NFT contract
    address public playerV2;

    /// @notice LEAG Token contract
    address public leagToken;
    address public dLeagToken;
    uint256 public draftStartDate;

    /// @notice NomoNFT contract
    address public nomoNft;

    /// @notice LEAG Reward Pool contract
    address public leagRewardPool;

    /// @notice Fantasy League contract
    address public fantasyLeague;

    /// @notice starts date of the tournament
    uint256 public tournamentStartDate;

    /// @notice division id which theses settings apply
    uint256 public divisionId; // todo divisionId && seasonId should come from Blaize contracts?

    /// @notice drafting order in which users were sorted upon initialization
    address[12] public draftOrder; // 12 teams in each division todo rename to users

    //TODO after vitko's PR goes in with the season id addition move it here and replace the existing roundProcessed with the new one from his PR
    mapping(uint8 => bool) public roundProcessed;

    // ============ Structs ============

    struct MerkleProof {
        uint256 index;
        address user;
        uint256 amount;
        bytes32[] proof;
    }

    // ============ Events ============

    event PlayerV2Set(address indexed playerV2);
    event LeagTokenSet(address indexed leagToken);
    event DraftStartDateSet(uint256 indexed draftStartDate);
    event LeagRewardPoolSet(address indexed leagRewardPool);
    event FantasyLeagueSet(address indexed fantasyLeague);
    event TournamentStartDateSet(uint256 tournamentStartDate);
    event UsersSorted(address[12] players);
    event NomoNFTSet(address indexed nomoNft);
    event RoundProcessed(uint8 round);

    // ============ Modifiers ============

    modifier onlyValidAddress(address _addr) {
        require(_addr != address(0), "Settings: Not a valid address");
        _;
    }

    modifier onlyWhenTournamentStarted() {
        require(
            block.timestamp > tournamentStartDate,
            "Settings: Tournament not started!"
        );
        _;
    }

    modifier onlyWhenDraftEnded(uint256 seasonId, uint256 divisionId) {
        require(roundProcessed[20], "Settings: Draft has not ended yet!");
        _;
    }

    modifier onlyFromDivision(uint256 divisionId) {
        uint256 actualDivisionId = IFantasyLeague(fantasyLeague).UserToDivision(
            msg.sender
        );
        require(
            divisionId == actualDivisionId,
            "User is not a member of the division"
        );
        _;
    }

    modifier hasDraftStarted() {
        require(
            block.timestamp > draftStartDate,
            "Settings: Pre-draft start countdown has not yet finished"
        );
        _;
    }

    // ============ Initializer ============
    function __settings_init(
        address _leagToken,
        address _playerV2,
        address _fantasyLeague,
        bytes32 _merkleRoot
    ) internal {
        __Ownable_init_unchained();
        leagToken = _leagToken;
        playerV2 = _playerV2;
        fantasyLeague = _fantasyLeague;
        merkleRoot = _merkleRoot;
    }

    // ============ Public functions ============

    /// @notice Sets the Player2 NFT Contract address
    /// @param _playerV2 Player2 NFT contract
    function setPlayerV2(address _playerV2)
        external
        onlyOwner
        onlyValidAddress(_playerV2)
    {
        playerV2 = _playerV2;
        emit PlayerV2Set(playerV2);
    }

    // @notice Sets Leag Token ERC20 address
    /// @param _leagToken Leag Token contract
    function setLeagToken(address _leagToken)
        external
        onlyOwner
        onlyValidAddress(_leagToken)
    {
        leagToken = _leagToken;
        emit LeagTokenSet(leagToken);
    }

    function setNomoNFT(address _nomoNft)
        external
        onlyOwner
        onlyValidAddress(_nomoNft)
    {
        nomoNft = _nomoNft;
        emit NomoNFTSet(nomoNft);
    }

    function setDraftStartDate(uint256 timestamp) external onlyOwner {
        draftStartDate = timestamp;
        emit DraftStartDateSet(draftStartDate);
    }

    // @notice Sets Leag Reward Pool address
    /// @param _leagRewardPool Reward pool address
    function setLeagRewardPool(address _leagRewardPool)
        external
        onlyOwner
        onlyValidAddress(_leagRewardPool)
    {
        leagRewardPool = _leagRewardPool;
        emit LeagRewardPoolSet(leagRewardPool);
    }

    // @notice Fantasy League address
    /// @param _fantasyLeague Fantasy League address
    function setFantasyLeague(address _fantasyLeague)
        external
        onlyOwner
        onlyValidAddress(_fantasyLeague)
    {
        fantasyLeague = _fantasyLeague;
        emit FantasyLeagueSet(fantasyLeague);
    }

    // @notice Sets tournament start date
    /// @param _tournamentStartDate start date
    function setTournamentStartDate(uint256 _tournamentStartDate)
        external
        onlyOwner
    {
        tournamentStartDate = _tournamentStartDate;
        emit TournamentStartDateSet(tournamentStartDate);
    }

    // ============ Public Functions ============

    // ============ Internal Functions ============

    // @notice Sorts users based on their staked balance and the current balance of LEAG tokens they currently posses in descending order. Even balances are randomly sorted
    /// @param mp user in a particular season and division which are to be sorted
    function sortPicks(MerkleProof[] memory mp) public onlyOwner {
        require(
            mp.length >= 1 && mp.length <= 12,
            "Player Draft: invalid length"
        );

        //todo require check if this user is in the division with all others in the array
        uint256 balance;
        bool foundEqual;
        uint256 equalStartIndex;
        uint256 equalEndIndex;
        bytes32 node;

        for (uint256 i = 0; i < mp.length; i++) {
            uint256 userBalance = IERC20PermitUpgradeable(leagToken).balanceOf(
                mp[i].user
            );

            node = keccak256(
                abi.encodePacked(mp[i].index, mp[i].user, mp[i].amount)
            );

            userBalance += MerkleProofUpgradeable.verify(
                mp[i].proof,
                merkleRoot,
                node
            )
                ? mp[i].amount
                : 0;

            for (uint256 j = i + 1; j < mp.length; j++) {
                uint256 nextUserBalance = IERC20PermitUpgradeable(leagToken)
                    .balanceOf(mp[j].user);

                node = keccak256(
                    abi.encodePacked(mp[j].index, mp[j].user, mp[j].amount)
                );

                nextUserBalance += MerkleProofUpgradeable.verify(
                    mp[j].proof,
                    merkleRoot,
                    node
                )
                    ? mp[j].amount
                    : 0;

                if (nextUserBalance > userBalance) {
                    MerkleProof memory temp = mp[i];
                    mp[i] = mp[j];
                    mp[j] = temp;
                    userBalance = nextUserBalance;
                }
            }

            draftOrder[i] = mp[i].user;

            if (userBalance == balance) {
                if (!foundEqual) {
                    equalStartIndex = i > 0 ? i - 1 : 0; // prevent underflow if all accounts have zero token balances
                    equalEndIndex = i;
                    foundEqual = true;
                } else {
                    equalEndIndex = i;
                }
            } else {
                if (equalStartIndex != equalEndIndex) {
                    draftOrder = DraftPickLib.randomizeArray(
                        draftOrder,
                        equalStartIndex,
                        equalEndIndex
                    );

                    equalStartIndex = 0;
                    equalEndIndex = 0;
                }

                balance = userBalance;
                foundEqual = false;
            }
        }

        if (equalStartIndex != equalEndIndex) {
            draftOrder = DraftPickLib.randomizeArray(
                draftOrder,
                equalStartIndex,
                equalEndIndex
            );
        }

        emit UsersSorted(draftOrder);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IERC20PermitUpgradeable.sol";
import "./lib/DraftPickLib.sol";
import {PermitSig} from "./cryptography/EIP712DraftPick.sol";
import "./interfaces/IERC721Upgradeable.sol";
import "./Settings.sol";
import "./cryptography/EIP712DraftPick.sol";
import "./interfaces/INomoNFT.sol";

// todo write natspec
abstract contract PlayerDraft is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    EIP712DraftPick,
    Settings
{
    // ============ Structs ============

    struct ReservedPlayer {
        address user;
        uint256 tokenId;
    }

    struct ReservationState {
        address user;
        uint256 startPeriod;
        uint256 endPeriod;
        bool redeemed;
    }

    // ============ State variables ============

    uint8 public round;

    uint256 public reserveExpirationTime;

    mapping(uint256 => ReservationState) public reservedPlayers; // tokenId -> Reservation
    // todo create another mapping by division (this must affect the sortPicks)

    // seasonId=>mapping(divisionId=>mapping(address=>roster)))
    mapping(uint256 => mapping(uint256 => mapping(address => uint256[])))
        public roster;

    // ============ Events ============

    /// @notice When selected player for a specific round has been drafted from a user
    event PlayerDrafted(
        uint256 divisionId,
        uint256 round,
        address user,
        uint256 tokenId
    );

    event PlayerReserved(
        address user,
        uint256 tokenId,
        uint256 startPeriod,
        uint256 endPeriod
    );

    event reserveExpirationTimeSet(uint256 reserveExpirationTime);

    event PlayerBought(
        address indexed user,
        uint256[] tokenIds,
        uint256 count,
        uint256 indexed value
    );

    event UserRosterUpdated(
        address indexed user,
        uint256[] roster,
        uint256 tokenId,
        bool added
    );

    // ============ Modifiers ============

    // ============ Initializer ============

    function __playerDraft_init(address _dleagToken, uint256 _divisionId)
        internal
        initializer
        onlyValidAddress(_dleagToken)
    {
        __Context_init_unchained();
        __Ownable_init_unchained();

        dLeagToken = _dleagToken;
        divisionId = _divisionId;
        round = 1;
    }

    // ============ Setters ============

    /**
     * @dev Updates the expiration period for the reserved player
     * @param expirationTime expiration period for the reservation of the player
     * Emits a {reserveExpirationTimeSet} event.
     */
    function setReserveExpirationTime(uint256 expirationTime)
        external
        onlyOwner
    {
        require(
            expirationTime >= 3600, //* 1 hour
            "Player Draft: expiration period should be at least 1 hour"
        );

        reserveExpirationTime = expirationTime;
        emit reserveExpirationTimeSet(reserveExpirationTime);
    }

    // ============ External functions ============

    function processRound(
        Draft[] memory drafts,
        bytes[] memory signatures,
        ReservedPlayer[] memory _reservedPlayers
    ) external onlyOwner nonReentrant hasDraftStarted {
        require(
            round <= 20 && !roundProcessed[round],
            "Player Draft: draft already ended"
        );

        require(
            drafts.length == signatures.length,
            "Player Draft: there should be signature for each draft"
        );
        require(
            drafts.length + _reservedPlayers.length <= draftOrder.length,
            "Player Draft: number of drafts exceeds the number of users"
        );

        for (uint256 i = 0; i < drafts.length; i++) {
            draftPlayer(drafts[i], signatures[i]);
        }

        for (uint256 i = 0; i < _reservedPlayers.length; i++) {
            reservePlayer(_reservedPlayers[i]);
        }

        roundProcessed[round] = true;
        if (round < 20) {
            round++;
        }
        emit RoundProcessed(round);
    }

    // ============ Public functions ============

    // ============ View functions ============

    // @notice Gets the draft order on how will be sorted users upon initialization of the contract
    function getDraftOrder() public view returns (address[12] memory) {
        if (round % 2 != 0) {
            return draftOrder;
        }

        address[12] memory reversedOrder;
        uint256 j = draftOrder.length;
        for (uint256 i = 0; i < draftOrder.length; i++) {
            reversedOrder[j - 1] = draftOrder[i];
            j--;
        }

        return reversedOrder;
    }

    // ============ Internal functions ============

    // ============ Private functions ============

    function draftPlayer(Draft memory draft, bytes memory signature)
        private
        returns (bool)
    {
        verify(draft, signature);
        IERC20PermitUpgradeable(dLeagToken).permit(
            draft.permit.owner,
            draft.permit.spender,
            draft.permit.value,
            draft.permit.deadline,
            draft.permit.v,
            draft.permit.r,
            draft.permit.s
        );

        IERC20PermitUpgradeable(dLeagToken).transferFrom(
            draft.permit.owner,
            address(this),
            draft.permit.value
        );

        IERC721Upgradeable(playerV2).mintRandom(
            draft.permit.owner,
            draft.tokenId
        );

        emit PlayerDrafted(
            draft.divisionId,
            draft.round,
            draft.permit.owner,
            draft.tokenId
        );
    }

    function reservePlayer(ReservedPlayer memory reservedPlayer)
        private
        onlyValidAddress(reservedPlayer.user)
    {
        reservedPlayers[reservedPlayer.tokenId].user = reservedPlayer.user;
        reservedPlayers[reservedPlayer.tokenId].startPeriod = block.timestamp;
        reservedPlayers[reservedPlayer.tokenId].endPeriod =
            block.timestamp +
            reserveExpirationTime;
        reservedPlayers[reservedPlayer.tokenId].redeemed = false;

        emit PlayerReserved(
            reservedPlayers[reservedPlayer.tokenId].user,
            reservedPlayer.tokenId,
            reservedPlayers[reservedPlayer.tokenId].startPeriod,
            reservedPlayers[reservedPlayer.tokenId].endPeriod
        );
    }

    //todo investigate with blaze, modifier that only a user from a specific season and division should be allowed to call function
    function buyPlayers(uint256[] memory _tokenIds, PermitSig memory permit)
        public
    {
        require(roundProcessed[20], "Player Draft: draft has not ended");
        uint256 _totalCost = 0;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            ReservationState memory _state = reservedPlayers[_tokenIds[i]];

            require(!_state.redeemed, "Player Draft: player already owned");

            if (
                block.timestamp > _state.startPeriod &&
                block.timestamp < _state.endPeriod
            ) {
                require(
                    _state.user == msg.sender,
                    "Player Draft: this is already reserved and reservation has not expired"
                );

                reservedPlayers[_tokenIds[i]].redeemed = true;
            }

            IERC721Upgradeable(playerV2).mintRandom(permit.owner, _tokenIds[i]);
        }

        _totalCost = _tokenIds.length * 1 * 10**18;

        IERC20PermitUpgradeable(dLeagToken).permit(
            permit.owner,
            permit.spender,
            _totalCost,
            permit.deadline,
            permit.v,
            permit.r,
            permit.s
        );

        IERC20PermitUpgradeable(dLeagToken).transferFrom(
            permit.owner,
            address(this),
            _totalCost
        );

        emit PlayerBought(msg.sender, _tokenIds, _tokenIds.length, _totalCost);
    }

    function assignToRoster(
        uint256 seasonId,
        uint256 divisionId,
        uint256 tokenId
    ) public {
        //todo we need to have a check whether this user is from the position passed
        //todo we need to have an integration check whether this user is from the position passed
        require(
            roster[seasonId][divisionId][msg.sender].length < 20,
            "PlayerDraft: Cannot have more than 20 players in possession"
        );
        uint256 newPlayerPos;
        (, , , , newPlayerPos, , , , ) = INomoNFT(nomoNft).getCardImage(
            tokenId
        );
        require(newPlayerPos != 0, "PlayerDraft: Player Position cannot be 0");
        if (roster[seasonId][divisionId][msg.sender].length < 14) {
            require(
                DraftPickLib.canAddToRoster(
                    roster[seasonId][divisionId][msg.sender],
                    newPlayerPos,
                    14
                ),
                "PlayerDraft: Cannot add that token to roster,position full"
            );
        }
        roster[seasonId][divisionId][msg.sender].push(newPlayerPos);
        emit UserRosterUpdated(
            msg.sender,
            roster[seasonId][divisionId][msg.sender],
            tokenId,
            true
        );
    }

    function removeFromRoster(
        uint256 seasonId,
        uint256 divisionId,
        uint256 tokenId
    ) public {
        require(
            roster[seasonId][divisionId][msg.sender].length > 0,
            "PlayerDraft: Roster must not be empty"
        );

        uint256 playerPos;
        (, , , , playerPos, , , , ) = INomoNFT(nomoNft).getCardImage(tokenId);
        bool removed = false;
        uint256[] memory currentRoster = roster[seasonId][divisionId][
            msg.sender
        ];
        for (uint256 i = 0; i < currentRoster.length; i++) {
            if (currentRoster[i] == playerPos) {
                uint256 old = currentRoster[currentRoster.length - 1];
                roster[seasonId][divisionId][msg.sender][
                    roster[seasonId][divisionId][msg.sender].length - 1
                ] = currentRoster[i];
                roster[seasonId][divisionId][msg.sender][i] = old;
                roster[seasonId][divisionId][msg.sender].pop();
                emit UserRosterUpdated(
                    msg.sender,
                    roster[seasonId][divisionId][msg.sender],
                    tokenId,
                    false
                );
                removed = true;
                break;
            }
        }

        require(removed, "PlayerDraft: Player Not Present");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IERC20PermitUpgradeable.sol";
import "./interfaces/IERC721Upgradeable.sol";
import "./Settings.sol";

import {PermitSig} from "./cryptography/EIP712DraftPick.sol";
import "./lib/DraftPickLib.sol";

/// @title Player Auction contract.
abstract contract PlayerAuction is
    Initializable,
    ERC721HolderUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    Settings
{
    using SafeERC20Upgradeable for IERC20PermitUpgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using DraftPickLib for address[];

    // ============ Enums ============

    /// @notice life cycle of the auction
    enum Status {
        inactive,
        live,
        ended
    }

    // ============ Structs ============

    /// @notice the state of the auction
    struct AuctionState {
        uint256 auctionId;
        uint256 auctionStart;
        uint256 auctionSoftStop;
        uint256 auctionHardStop;
        uint256 playerTokenId;
        address winning;
        uint256 price;
        Status status;
    }

    // ============ Storage ============

    /// @notice auction details for the current season => division id => auctionId
    mapping(uint256 => mapping(uint256 => mapping(uint256 => AuctionState)))
        public auctionState; //seasonId => divisionId => auctionId => AuctionState

    /// @notice tracks auction ids for different seasons and division ids
    mapping(uint256 => mapping(uint256 => CountersUpgradeable.Counter))
        public auctionIdCounter; //seasonId => divisionId => counter

    /// @notice keeps track for all the auctions that have happened in a particular season => division id
    mapping(uint256 => mapping(uint256 => AuctionState[])) public auctions; //seasonId => divisionId => auctions //todo this might be extracted in subgraph only

    /// @notice keeps track if there is an active auction of a certain playerTokenId
    mapping(uint256 => mapping(uint256 => mapping(uint256 => bool)))
        public hasActiveAuction; // seasonId => divisionId => playerTokenId

    /// @notice minimum auction amount required for starting an auction
    uint256 public minAuctionAmount;

    /// @notice minimum required step as amount for bidding in an active auction
    uint256 public outbidAmount; // min allowed outbid amount for all auctions;

    /// @notice hard deadline when an auction must finish, in order to prevent an endless auction
    uint256 public hardStop;

    /// @notice when nobody place new bid within the softStop, the auction ends and the winner can claim its reward.
    uint256 public softStop;

    // ============ Events ============

    event MinAuctionAmountSet(uint256 newAmount);
    event OutbidAmountSet(uint256 newAmount);
    event AuctionStopsSet(uint256 softStop, uint256 hardStop);
    event PriceUpdate(address indexed user, uint256 price);
    event AuctionStarted(
        address indexed user,
        uint256 price,
        uint256 seasonId,
        uint256 divisionId,
        uint256 auctionId,
        uint256 playerTokenId,
        uint256 start,
        uint256 softStop,
        uint256 hardStop
    );

    event AuctionBid(
        address indexed user,
        uint256 price,
        uint256 seasonId,
        uint256 divisionId,
        uint256 auctionId,
        uint256 newSoftEnd
    );

    event AuctionWon(
        address indexed user,
        uint256 price,
        uint256 seasonId,
        uint256 divisionId,
        uint256 auctionId,
        uint256 playerTokenId
    );

    // ============ Modifiers ============

    //todo onlyFromCurrDivision - should have interface provided by Blaize?

    // ============ Initializer ============
    function __playerAuction_init() internal {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
    }

    // ============ Setters ============

    /// @notice Sets minimum starting amount for starting a draft
    /// @param _minAuctionAmount Minimum auction amount
    function setMinAuctionAmount(uint256 _minAuctionAmount) external onlyOwner {
        minAuctionAmount = _minAuctionAmount;
        emit MinAuctionAmountSet(minAuctionAmount);
    }

    /// @notice Sets minimum outbid step above the current amount in order to bid in an auction
    /// @param _newOutbidAmount Minimum outbid amount
    function setMinOutbidAmount(uint256 _newOutbidAmount) external onlyOwner {
        outbidAmount = _newOutbidAmount;
        emit OutbidAmountSet(outbidAmount);
    }

    /// @notice Sets soft / hard stops when an auction will finish
    /// @param _softStop Minimum delay in time before a user can win, if nobody else outbids
    /// @param _hardStop Maximum amount of time to which an auction can prolong
    function setStops(uint256 _softStop, uint256 _hardStop) external onlyOwner {
        softStop = _softStop;
        hardStop = _hardStop;
        emit AuctionStopsSet(softStop, hardStop);
    }

    // ============ External Functions ============

    //todo add modifier only user from current division and season - this we should get from Blaize
    //todo add modifier that current player is not in the reserved time slot - this might not be needed as auction will be placed after the start of the season. On the other hand reserved player should be resolved before the start of the season
    //todo seasonId && divisionId would be best to get from Blaize
    /// @notice kick off an auction for a specific season and division
    /// @param seasonId Season id for the actual sporting season the auction is placed
    /// @param divisionId Division id where this auction will be started
    /// @param playerTokenId The gen2 Player token which the auction will be against
    /// @param permitSig Permit signature as struct for the owner, spender and value in order for a permit to be successful
    function auctionStart(
        uint256 seasonId,
        uint256 divisionId,
        uint256 playerTokenId,
        PermitSig calldata permitSig
    ) external virtual onlyWhenTournamentStarted {
        require(
            permitSig.value >= minAuctionAmount,
            "Player Auction :: open value too low"
        );

        require(
            !hasActiveAuction[seasonId][divisionId][playerTokenId],
            "Player Auction :: Active Auction for player"
        );

        auctionIdCounter[seasonId][divisionId].increment();
        uint256 auctionId = auctionIdCounter[seasonId][divisionId].current();

        auctionState[seasonId][divisionId][auctionId] = AuctionState({
            auctionId: auctionId,
            auctionStart: block.timestamp,
            auctionSoftStop: block.timestamp + softStop,
            auctionHardStop: block.timestamp + hardStop,
            playerTokenId: playerTokenId,
            winning: permitSig.owner,
            price: permitSig.value,
            status: Status.live
        });

        hasActiveAuction[seasonId][divisionId][playerTokenId] = true;

        IERC20PermitUpgradeable(leagToken).permit(
            permitSig.owner,
            permitSig.spender,
            permitSig.value,
            permitSig.deadline,
            permitSig.v,
            permitSig.r,
            permitSig.s
        );

        IERC20PermitUpgradeable(leagToken).transferFrom(
            permitSig.owner,
            address(this),
            permitSig.value
        );

        // todo might be outside of the contracts only
        auctions[seasonId][divisionId].push(
            auctionState[seasonId][divisionId][auctionId]
        );

        // todo integration with Blaize
        IERC721Upgradeable(playerV2).mintRandom(address(this), playerTokenId);

        emit AuctionStarted(
            permitSig.owner,
            permitSig.value,
            seasonId,
            divisionId,
            auctionId,
            playerTokenId,
            block.timestamp,
            block.timestamp + softStop,
            block.timestamp + hardStop
        );
    }

    //todo seasonId && divisionId would be best to get from Blaize
    /// @notice Place new bid for an active auction in a certain season and division against gen2 Player token
    /// @param seasonId Season id for the actual sporting season the auction is placed
    /// @param divisionId Division id where this auction will be started
    /// @param auctionId Auction which is about to be finished
    /// @param permitSig Permit signature as struct for the owner, spender and value in order for a permit to be successful
    function auctionBid(
        uint256 seasonId,
        uint256 divisionId,
        uint256 auctionId,
        PermitSig calldata permitSig
    ) external virtual nonReentrant {
        //todo modifier only user from this season and division

        AuctionState storage aucState = auctionState[seasonId][divisionId][
            auctionId
        ];

        require(
            permitSig.value >= aucState.price + outbidAmount,
            "Player Auction :: bid amount too low"
        );
        require(
            aucState.status == Status.live,
            "Player Auction :: Inactive auction"
        );
        require(
            block.timestamp < aucState.auctionHardStop,
            "Player Auction :: hard stop hit"
        ); // make sure there is a hard stop so we don't get into an endless auction
        require(
            block.timestamp < aucState.auctionSoftStop,
            "Player Auction :: soft stop hit"
        ); // if nobody claimed within the softStop auction ends

        uint256 prevBid = aucState.price;
        address prevWinner = aucState.winning;

        aucState.winning = permitSig.owner;
        aucState.price = permitSig.value;
        aucState.auctionSoftStop = block.timestamp + softStop;

        IERC20PermitUpgradeable(leagToken).safeTransfer(prevWinner, prevBid);
        IERC20PermitUpgradeable(leagToken).permit(
            permitSig.owner,
            permitSig.spender,
            permitSig.value,
            permitSig.deadline,
            permitSig.v,
            permitSig.r,
            permitSig.s
        );

        IERC20PermitUpgradeable(leagToken).safeTransferFrom(
            permitSig.owner,
            address(this),
            permitSig.value
        );

        emit AuctionBid(
            permitSig.owner,
            aucState.price,
            seasonId,
            divisionId,
            auctionId,
            aucState.auctionSoftStop
        );
    }

    //todo seasonId && divisionId would be best to get from Blaize
    /// @notice Finishes an active auction in a certain season and division against gen2 Player token
    /// @param seasonId Season id for the actual sporting season the auction is placed
    /// @param divisionId Division id where this auction will be started
    /// @param auctionId Auction which is about to be finished
    function endAuction(
        uint256 seasonId,
        uint256 divisionId,
        uint256 auctionId
    ) external virtual nonReentrant {
        //? todo should this function be visible from everyone
        AuctionState storage aucState = auctionState[seasonId][divisionId][
            auctionId
        ];

        require(
            aucState.status == Status.live,
            "endAuction :: auction already closed!"
        );
        require(
            block.timestamp >= aucState.auctionSoftStop,
            "endAuction :: bidding is still open"
        );

        aucState.status = Status.ended;
        hasActiveAuction[seasonId][divisionId][aucState.playerTokenId] = false;

        IERC721Upgradeable(playerV2).safeTransferFrom(
            address(this),
            aucState.winning,
            aucState.playerTokenId
        );

        uint256 fraction = aucState.price / draftOrder.length;
        uint256 dust = aucState.price - (fraction * draftOrder.length);

        address[] memory filtered = DraftPickLib.spliceByAddress(
            draftOrder,
            aucState.winning
        );

        for (uint256 i = 0; i < filtered.length; i++) {
            //todo integration with Blaize
            IERC20PermitUpgradeable(leagToken).safeTransfer(
                filtered[i],
                fraction
            );
        }

        IERC20PermitUpgradeable(leagToken).safeTransfer(
            leagRewardPool,
            fraction + dust
        );

        emit AuctionWon(
            aucState.winning,
            aucState.price,
            seasonId,
            divisionId,
            auctionId,
            aucState.playerTokenId
        );
    }

    // ============ Public Functions ============
    // ============ View Functions ============
    // ============ Internal Functions ============
    // ============ Private Functions ============

    // _______________ Gap reserved space _______________

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Settings.sol";

abstract contract PlayerSwap is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    Settings
{
    // ============ TO DO ============

    function __playerSwap_init() internal {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Settings.sol";
import "./interfaces/IERC20PermitUpgradeable.sol";
import "./interfaces/IERC721Upgradeable.sol";

abstract contract PlayerOperations is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    Settings
{
    // ============ State variables ============

    // ============ Events ============

    event PlayerDropped(
        uint256 seasonId,
        uint256 divisionId,
        uint256 tokenId,
        address user
    );

    // ============ Initializer ============

    function __playerDrop_init() internal {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    // ============ External Functions ============

    function dropPlayer(
        uint256 seasonId,
        uint256 divisionId,
        uint256 tokenId
    )
        external
        onlyFromDivision(divisionId)
        onlyWhenDraftEnded(seasonId, divisionId)
    {
        //TODO blaize: Probably will need integration with the Blaize contracts in regards to pointing out which params to pass when burning aka divsionId/tokenId
        IERC721Upgradeable(playerV2).burn(tokenId);
        if (block.timestamp < tournamentStartDate) {
            IERC20PermitUpgradeable(dLeagToken).transfer(
                msg.sender,
                1 * 10**18
            );
        }
        emit PlayerDropped(seasonId, divisionId, tokenId, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DraftPickLib {
    /**
     * @dev Returns the randomly chosen index.
     * @param max current length of the collection.
     * @return length of the collection
     */
    function randomize(uint256 max) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        keccak256(
                            abi.encodePacked(
                                msg.sender,
                                tx.origin,
                                gasleft(),
                                block.timestamp,
                                block.difficulty,
                                block.number,
                                blockhash(block.number),
                                address(this)
                            )
                        )
                    )
                )
            ) % max;
    }

    /**
     * @dev Returns the sliced array.
     * @param array the array to be sliced.
     * @param from the index to start the slicing.
     * @param to the index to end the slicing.
     * @return array of addresses
     */
    function slice(
        address[12] memory array,
        uint256 from,
        uint256 to
    ) internal pure returns (address[] memory) {
        require(
            array.length >= to,
            "the end element for the slice is out of bounds"
        );
        address[] memory sliced = new address[](to - from + 1);

        for (uint256 i = from; i <= to; i++) {
            sliced[i - from] = array[i];
        }

        return sliced;
    }

    /**
     * @dev Returns the spliced array.
     * @param array the array to be spliced.
     * @param _address the address of the user that will be spliced.
     * @return array of addresses
     */
    function spliceByAddress(address[12] memory array, address _address)
        internal
        pure
        returns (address[] memory)
    {
        require(array.length != 0, "empty array");
        require(_address != address(0), "the array index is negative");
        // require(index < array.length, "the array index is out of bounds");

        address[] memory spliced = new address[](array.length - 1);
        uint256 indexCounter = 0;

        for (uint256 i = 0; i < array.length; i++) {
            if (_address != array[i]) {
                spliced[indexCounter] = array[i];
                indexCounter++;
            }
        }

        return spliced;
    }

    /**
     * @dev Returns the spliced array.
     * @param array the array to be spliced.
     * @param index the index of the element that will be spliced.
     * @return array of addresses
     */
    function splice(address[] memory array, uint256 index)
        internal
        pure
        returns (address[] memory)
    {
        require(array.length != 0, "empty array");
        require(index >= 0, "the array index is negative");
        require(index < array.length, "the array index is out of bounds");

        address[] memory spliced = new address[](array.length - 1);
        uint256 indexCounter = 0;

        for (uint256 i = 0; i < array.length; i++) {
            if (i != index) {
                spliced[indexCounter] = array[i];
                indexCounter++;
            }
        }

        return spliced;
    }

    /**
     * @dev Method that randomizes array in a specific range
     * @param array the array to be randomized, with 12 records inside.
     * @param startIndex the index of the element where the randomization starts.
     * @param endIndex the index of the element where the randomiation ends.
     */
    function randomizeArray(
        address[12] memory array,
        uint256 startIndex,
        uint256 endIndex
    ) internal view returns (address[12] memory) {
        address[] memory sliced = slice(array, startIndex, endIndex);

        uint256 slicedLen = sliced.length;
        uint256 startIndexReplace = startIndex;
        for (uint256 i = 0; i < slicedLen; i++) {
            uint256 rng = randomize(sliced.length);

            address selected = sliced[rng];

            sliced = splice(sliced, rng);

            array[startIndexReplace] = selected;
            startIndexReplace++;
        }

        return array;
    }

    /**
     * @dev Method that returns wether we can add the tokenId to our active roster
     * @param currentRoaster the current roster to be validated
     * @param newPlayerPos the positionId of the new player
     */
    function canAddToRoster(
        uint256[] memory currentRoaster,
        uint256 newPlayerPos,
        uint256 cap
    ) internal pure returns (bool canBeAdded) {
        if (currentRoaster.length < cap) {
            uint8 QB = 0;
            uint8 RB = 0;
            uint8 TE = 0;
            uint8 WR = 0;
            uint8 FLEX = 0;
            uint8 DL = 0;
            uint8 LB = 0;
            uint8 DB = 0;
            for (uint256 i = 0; i < currentRoaster.length; i++) {
                uint256 playerPos = currentRoaster[i];

                if (playerPos == 1) {
                    TE = TE + 1;
                } else if (playerPos == 2 || playerPos == 6) {
                    LB = LB + 1;
                } else if (
                    playerPos == 3 || playerPos == 10 || playerPos == 16
                ) {
                    DL = DL + 1;
                } else if (playerPos == 4) {
                    if (WR == 2) {
                        FLEX = FLEX + 1;
                    } else {
                        WR = WR + 1;
                    }
                } else if (playerPos == 5) {
                    if (RB == 2) {
                        FLEX = FLEX + 1;
                    } else {
                        RB = RB + 1;
                    }
                } else if (
                    playerPos == 9 ||
                    playerPos == 11 ||
                    playerPos == 13 ||
                    playerPos == 17 ||
                    playerPos == 20
                ) {
                    DB = DB + 1;
                } else if (playerPos == 12) {
                    QB = QB + 1;
                }
            }

            if (newPlayerPos == 1) {
                if (TE < 1) {
                    TE = TE + 1;
                    return true;
                } else return false;
            } else if (newPlayerPos == 2 || newPlayerPos == 6) {
                if (LB < 2) {
                    LB = LB + 1;
                    return true;
                } else return false;
            } else if (
                newPlayerPos == 3 || newPlayerPos == 10 || newPlayerPos == 16
            ) {
                if (DL < 2) {
                    DL = DL + 1;
                    return true;
                } else return false;
            } else if (newPlayerPos == 4) {
                if (WR < 2) {
                    WR = WR + 1;
                    return true;
                } else if (FLEX < 2) {
                    FLEX = FLEX + 1;
                    return true;
                } else return false;
            } else if (newPlayerPos == 5) {
                if (RB < 2) {
                    RB = RB + 1;
                    return true;
                } else if (FLEX < 2) {
                    FLEX = FLEX + 1;
                    return true;
                }
                return false;
            } else if (
                newPlayerPos == 9 ||
                newPlayerPos == 11 ||
                newPlayerPos == 13 ||
                newPlayerPos == 17 ||
                newPlayerPos == 20
            ) {
                if (DB < 2) {
                    DB = DB + 1;
                    return true;
                } else return false;
            } else if (newPlayerPos == 12) {
                if (QB < 1) {
                    QB = QB + 1;
                    return true;
                } else return false;
            }
        } else return true;
    }
}

pragma solidity ^0.8.0;

interface IFantasyLeague {
    function UserToDivision(address user_address) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";

struct PermitSig {
    address owner;
    address spender;
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

abstract contract EIP712DraftPick is Initializable, ContextUpgradeable {
    using AddressUpgradeable for address;

    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 private constant DRAFT_TYPEHASH =
        keccak256(
            "Draft(uint256 divisionId,uint256 round,uint256 tokenId,uint256 salt,address user,PermitSig permit)PermitSig(address owner,address spender,uint256 value,uint256 deadline,uint8 v,bytes32 r,bytes32 s)"
        );

    bytes32 private constant PERMIT_TYPEHASH =
        keccak256(
            "PermitSig(address owner,address spender,uint256 value,uint256 deadline,uint8 v,bytes32 r,bytes32 s)"
        );

    struct Draft {
        uint256 divisionId;
        uint256 round;
        uint256 tokenId;
        uint256 salt;
        address user;
        PermitSig permit;
    }

    function DOMAIN_SEPARATOR() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256("playerDraft"), // string name
                    keccak256("1"), // string version
                    block.chainid, // uint256 chainId
                    address(this) // address verifyingContract
                )
            );
    }

    function hashPermit(PermitSig memory permit)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    PERMIT_TYPEHASH,
                    permit.owner,
                    permit.spender,
                    permit.value,
                    permit.deadline,
                    permit.v,
                    permit.r,
                    permit.s
                )
            );
    }

    function hashDraft(Draft memory draft) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            DRAFT_TYPEHASH,
                            draft.divisionId,
                            draft.round,
                            draft.tokenId,
                            draft.salt,
                            draft.user,
                            hashPermit(draft.permit)
                        )
                    )
                )
            );
    }

    function verify(Draft memory draft, bytes memory signature)
        public
        view
        returns (bool)
    {
        bytes32 hash = hashDraft(draft);
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                draft.user,
                hash,
                signature
            ),
            "draft signature verification error"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INomoNFT {
    function getCardImage(uint256 _cardImageId)
        external
        view
        returns (
            string memory name,
            string memory imageURL,
            uint256 league,
            uint256 gen,
            uint256 playerPosition,
            uint256 parametersSetId,
            string[] memory parametersNames,
            uint256[] memory parametersValues,
            uint256 parametersUpdateTime
        );

    function positionCodeToName(uint256 _positionCode)
        external
        returns (string memory position);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../AddressUpgradeable.sol";
import "../../interfaces/IERC1271Upgradeable.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureCheckerUpgradeable {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(hash, signature);
        if (error == ECDSAUpgradeable.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271Upgradeable.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271Upgradeable.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271Upgradeable {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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