// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./interfaces/INomoRNG.sol";

/**
 * @title Handle Nomo divisions
 */
contract NomoDivisions is OwnableUpgradeable {
    /// @notice Array of registered players
    address[] public players;

    /// @notice Address of admin
    address public admin;

    /// @dev Defines amount of players in division
    uint256 constant PLAYERS_IN_DIVISION = 12;

    /// @notice Random number used for player shuffling
    uint256 public randomNumber;

    /// @notice Shuffle allowed after this date
    uint256 public shuffleStartDate;

    /// @notice Last shuffled player ID
    uint256 public lastShuffledId;

    /// @notice Tokens staked by player
    mapping(address => uint256[]) public stakedTokens;

    /// @dev Staked NFT contract
    IERC721Upgradeable private nftToken;

    /// @dev Random number generator
    INomoRNG private generator;

    // EVENTS

    /// @dev When owner change the admin
    event AdminChanged(address newAdmin);

    /// @dev When new player added to the game
    event PlayerAdded(address player);

    /// @dev When staked NFT contract changed
    event NFTContractChanged(address nft);

    /// @dev When shuffleStartDate changed
    event ShuffleStartDateChanged(uint256 shuffleStartDate);

    // MODIFIERS

    /**
     * @dev Restrict access for "admin" address only
     * @dev Check is admin address was defined after deploy
     */
    modifier onlyAdmin() {
        require(admin != address(0), "set admin first");
        require(msg.sender == admin, "not an admin");
        _;
    }

    /**
     * @dev Check is division exists
     * @param _division Division ID
     */
    modifier divisionExists(uint256 _division) {
        require(_division > 0, "division ID should be > 0");
        require(_division * PLAYERS_IN_DIVISION <= countPlayers(), "division doesn't exist");
        _;
    }

    /**
     * @dev Check is player added
     * @param _player Player address
     */
    modifier playerExists(address _player) {
        require(isPlayerExist(_player), "player not found");
        _;
    }

    /**
     * @dev Check is address is not zero
     * @param _address Address to check
     */
    modifier notZeroAddress(address _address) {
        require(_address != address(0), "zero address");
        _;
    }

    // PLAYERS AREA

    /**
     * @notice Add player NFTs to stake
     * @param _tokenIds Array of token IDs
     */
    function stakeNFT(uint256[] memory _tokenIds) external playerExists(msg.sender) {
        for (uint256 _i; _i < _tokenIds.length; _i++) {
            nftToken.transferFrom(msg.sender, address(this), _tokenIds[_i]);
            stakedTokens[msg.sender].push(_tokenIds[_i]);
        }
    }

    /**
     * @notice Remove player NFTs from stake
     * @param _tokenIds Array of token IDs
     */
    function unstakeNFT(uint256[] memory _tokenIds) external playerExists(msg.sender) {
        for (uint256 _i; _i < _tokenIds.length; _i++) {
            require(isPlayerOwnsNFT(msg.sender, _tokenIds[_i]), "wrong tokenId");
            delete stakedTokens[msg.sender][getStakedTokenIndex(msg.sender, _tokenIds[_i])];
            nftToken.transferFrom(address(this), msg.sender, _tokenIds[_i]);
        }
    }

    // ADMIN AREA

    /**
     * @notice Add player to the game
     * @param _player Address of player
     */
    function addPlayer(address _player) external onlyAdmin notZeroAddress(_player) {
        require(!isPlayerExist(_player), "player already added");
        players.push(_player);
        emit PlayerAdded(_player);
    }

    /**
     * @notice Get random from generator
     * @dev You need generate random on RNG first
     */
    function getRandomNumber() external onlyAdmin notZeroAddress(address(generator)) {
        randomNumber = generator.requestRandomNumber();
    }

    /**
     * @notice Shuffle players
     * @param _shuffleTo Max player ID to shuffle
     */
    function shufflePlayers(uint256 _shuffleTo) external onlyAdmin {
        // We can get random number only after shuffleStartDate
        require(randomNumber > 0, "get random first");

        // Check is player amount more than amount to shuffle
        if (players.length <= _shuffleTo) {
            _shuffleTo = players.length - 1;
        }

        // Shuffle players
        for (uint256 _i = lastShuffledId; _i <= _shuffleTo; _i++) {
            uint256 _n = _i + uint256(keccak256(abi.encodePacked(randomNumber))) % (players.length - _i);
            address _current = players[_n];
            players[_n] = players[_i];
            players[_i] = _current;
        }

        // Save last shuffled ID
        lastShuffledId = _shuffleTo;
    }

    /**
     * @notice Change NFT address
     * @param _nft New NFT address
     */
    function setNFTContract(IERC721Upgradeable _nft) external onlyAdmin notZeroAddress(address(_nft)) {
        nftToken = _nft;
        emit NFTContractChanged(address(_nft));
    }

    /**
     * @notice Change shuffle start date
     * @param _shuffleStartDate New timestamp
     */
    function setShuffleStartDate(uint256 _shuffleStartDate) external onlyAdmin {
        shuffleStartDate = _shuffleStartDate;
        emit ShuffleStartDateChanged(shuffleStartDate);
    }

    // OWNER AREA

    /**
     * @notice Change admin
     * @param _admin New admin address
     */
    function changeAdmin(address _admin) external onlyOwner notZeroAddress(_admin) {
        admin = _admin;
        emit AdminChanged(_admin);
    }

    /**
     * @notice Define random number generator contract
     * @param _generator RNG contract address
     */
    function setRNG(INomoRNG _generator) external onlyOwner notZeroAddress(address(_generator)) {
        generator = _generator;
    }

    // VIEWS

    /**
     * @notice Count all players
     * @return Players in game
     */
    function countPlayers() public view returns (uint256) {
        return players.length;
    }

    /**
     * @notice Count divisions
     * @return _count Total divisions
     */
    function countDivisions() external view returns (uint256 _count) {
        _count = countPlayers() / PLAYERS_IN_DIVISION;
        if (_count * PLAYERS_IN_DIVISION < countPlayers()) {
            _count++;
        }
    }

    /**
     * @notice Check is player added to the game
     * @return Is player added
     */
    function isPlayerExist(address _player) public view returns (bool) {
        for (uint256 _i = 0; _i < players.length; _i++) {
            if (players[_i] == _player) {
                return true;
            }
        }

        return false;
    }

    /**
     * @notice Check is player owns NFT
     * @param _player Address of a player
     * @param _tokenId ID of the NFT
     * @return Is player owns NFT
     */
    function isPlayerOwnsNFT(address _player, uint256 _tokenId) public view returns (bool) {
        if (stakedTokens[_player].length == 0) {
            return false;
        }

        for (uint256 _i = 0; _i < stakedTokens[_player].length; _i++) {
            if (stakedTokens[_player][_i] == _tokenId) {
                return true;
            }
        }

        return false;
    }

    /**
     * @notice Get player NFT index by ID
     * @param _player Address of a player
     * @param _tokenId ID of the NFT
     * @return ID of NFT
     */
    function getStakedTokenIndex(address _player, uint256 _tokenId) public view returns (uint256) {
        for (uint256 _i = 0; _i < stakedTokens[_player].length; _i++) {
            if (stakedTokens[_player][_i] == _tokenId) {
                return _i;
            }
        }

        revert("not found");
    }

    /**
     * @notice Get all players in division by Id of the division
     * @param _division ID of the division
     * @return _players Array of division players addresses
     */
    function getDivision(uint256 _division)
        public
        view
        divisionExists(_division)
        returns (address[] memory _players)
    {
        uint256 _from =
            _division * PLAYERS_IN_DIVISION - PLAYERS_IN_DIVISION;

        _players = new address[](PLAYERS_IN_DIVISION);
        for (uint256 _i = 0; _i < PLAYERS_IN_DIVISION; _i++) {
            _players[_i] = players[_from + _i];
        }
    }

    /**
     * @notice Get division ID by player address
     * @param _player Address of player
     * @return _divisionId ID of division
     */
    function getDivisionId(address _player) external view playerExists(_player) returns (uint256 _divisionId) {
        uint256 _playerId = 0;
        for (uint256 _i = 0; _i < players.length; _i++) {
            if (_player == players[_i]) {
                _playerId = _i;
                break;
            }
        }
        _divisionId = (_playerId + PLAYERS_IN_DIVISION) / PLAYERS_IN_DIVISION;
    }

    // SYSTEM

    function initialize(
        address _admin,
        IERC721Upgradeable _nft,
        uint256 _shuffleStartDate
    ) external initializer {
        __Ownable_init();

        admin = _admin;
        nftToken = _nft;
        shuffleStartDate = _shuffleStartDate;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
pragma solidity ^0.8.6;

interface INomoRNG {
    function requestRandomNumber() external returns (uint256 _random);
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
interface IERC165Upgradeable {
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