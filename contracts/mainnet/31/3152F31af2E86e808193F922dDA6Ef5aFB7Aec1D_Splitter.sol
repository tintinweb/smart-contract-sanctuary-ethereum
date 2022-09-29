// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

contract Splitter is IERC777Recipient, Ownable {
    event ETHPaymentReceived(address from, uint256 amount);
    event DUSTPaymentReceived(address from, uint256 amount);

    event CommunityShareChanged(address _from, uint256 _share);
    event CompanyShareChanged(address _from, uint256 _share);
    event ArtistShareChanged(
        address _from,
        uint256 _share,
        uint256 _artistIndex
    );

    event CommunityOwnerAddressChanged(address _address);
    event CompanyAddressChanged(address _address);
    event ArtistAddressChanged(address _address, uint256 _artistIndex);

    address private tokenContractAddress; // ERC777 NFT contract address
    address private communityOwnerAddress; // community owner, provide in constructor
    address private companyAddress; // company address, provide in constructor
    address[] private artistAddresses;

    uint256 private companyShares;
    uint256 private communityShares;
    uint256[] private artistShares; //index of share corresponding to artist should match index of artis in artistAddresses

    IERC777 private tokenContract; // DUST ERC777 NFT token contract

    IERC1820Registry private _erc1820 =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");

    constructor(
        address _communityOwnerAddress,
        address _companyAddress,
        uint256 _companyShares,
        uint256 _communityShares,
        address[] memory _artistAddresses,
        uint256[] memory _artistShares,
        address _tokenContractAddress
    ) {
        require(
            _communityOwnerAddress != address(0),
            "Cannot be ZERO address."
        );
        require(_companyAddress != address(0), "Cannot be ZERO address.");
        communityOwnerAddress = _communityOwnerAddress;
        companyAddress = _companyAddress;

        require(
            _artistShares.length <= 5,
            "At most 5 artists in splitter contract"
        );
        require(
            _artistShares.length == _artistAddresses.length,
            "Artist address or artist shares missing"
        );
        for (uint256 i = 0; i < _artistAddresses.length; i++) {
            require(
                _artistAddresses[i] != address(0),
                "Cannot be ZERO address."
            );
            artistAddresses.push(_artistAddresses[i]);
        }
        for (uint256 i = 0; i < _artistShares.length; i++) {
            require(
                _artistShares[i] > 0,
                "Artist shares must be positive integer!"
            );
            artistShares.push(_artistShares[i]);
        }

        require(
            _communityShares > 0,
            "Community shares must be positive integer!"
        );
        communityShares = _communityShares;

        require(_companyShares > 0, "Company shares must be positive integer!");
        companyShares = _companyShares;
        
        require(_tokenContractAddress != address(0), "Token contract cannot be ZERO address.");
        tokenContractAddress = _tokenContractAddress;
        tokenContract = IERC777(_tokenContractAddress); // initialize the NFT contract
        _erc1820.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        ); // register self with IERC1820 registry
    }

    // split upon receiving ETH payment
    receive() external payable virtual {
        emit ETHPaymentReceived(msg.sender, msg.value);
        bool success;

        uint256 _totalShares = getTotalShares();
        uint256 communityPayment = (communityShares * msg.value) / _totalShares;
        (success, ) = communityOwnerAddress.call{value: communityPayment}("");
        require(success, "Transfer failed.");

        uint256 companyPayment = (companyShares * msg.value) / _totalShares;
        (success, ) = companyAddress.call{value: companyPayment}("");
        require(success, "Transfer failed.");

        for (uint256 i = 0; i < artistShares.length; i++) {
            uint256 artistPayment = (artistShares[i] * msg.value) /
                _totalShares;
            (success, ) = artistAddresses[i].call{value: artistPayment}("");
            require(success, "Transfer failed.");
        }
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        require(msg.sender == tokenContractAddress, "Invalid token!");
        // Tokens were sent to the splitter
        emit DUSTPaymentReceived(from, amount);
        uint256 _totalShares = getTotalShares();
        uint256 communityPayment = (communityShares * amount) / _totalShares;
        tokenContract.send(communityOwnerAddress, communityPayment, "");

        uint256 companyPayment = (companyShares * amount) / _totalShares;
        tokenContract.send(companyAddress, companyPayment, "");
        for (uint256 i = 0; i < artistShares.length; i++) {
            uint256 artistPayment = (artistShares[i] * amount) / _totalShares;
            tokenContract.send(artistAddresses[i], artistPayment, "");
        }
    }

    function getTotalShares() public view returns (uint256) {
        uint256 _totalShares = communityShares + companyShares;
        for (uint256 i = 0; i < artistShares.length; i++) {
            _totalShares = _totalShares + artistShares[i];
        }
        return _totalShares;
    }

    function setCompanyShares(uint256 _shares) external onlyOwner {
        require(_shares > 0, "Company shares must be positive integer!");
        companyShares = _shares;
        emit CompanyShareChanged(msg.sender, _shares);
    }

    function getCompanyShares() external view returns (uint256) {
        return companyShares;
    }

    function setCommunityShares(uint256 _shares) external onlyOwner {
        require(_shares > 0, "Community shares must be positive integer!");
        communityShares = _shares;
        emit CommunityShareChanged(msg.sender, _shares);
    }

    function getCommunityShares() external view returns (uint256) {
        return communityShares;
    }

    function setArtistShares(uint256 _shares, uint256 _artistIndex)
        external
        onlyOwner
    {
        require(_artistIndex < artistAddresses.length, "Invalid index!");
        require(_shares > 0, "Artist shares must be positive integer!");
        artistShares[_artistIndex] = _shares;
        emit ArtistShareChanged(msg.sender, _shares, _artistIndex);
    }

    function getArtistShares() external view returns (uint256[] memory) {
        return artistShares;
    }

    function getCommunityOwnerAddress() external view returns (address) {
        return communityOwnerAddress;
    }

    // change community owner address
    function setCommunityOwnerAddress(address _communityOwnerAddress)
        external
        onlyOwner
    {
        require(
            _communityOwnerAddress != address(0),
            "Cannot be ZERO address."
        );
        communityOwnerAddress = _communityOwnerAddress;
        emit CommunityOwnerAddressChanged(communityOwnerAddress);
    }

    function getCompanyAddress() external view returns (address) {
        return companyAddress;
    }

    // change company address
    function setCompanyAddress(address _companyAddress) external onlyOwner {
        require(_companyAddress != address(0), "Cannot be ZERO address.");
        companyAddress = _companyAddress;
        emit CompanyAddressChanged(companyAddress);
    }

    function getArtistAddresses() external view returns (address[] memory) {
        return artistAddresses;
    }

    function setArtistAddress(address _address, uint256 _artistIndex)
        external
        onlyOwner
    {
        require(_artistIndex < artistAddresses.length, "Invalid index!");
        require(_address != address(0), "Cannot be ZERO address.");
        artistAddresses[_artistIndex] = _address;
        emit ArtistAddressChanged(_address, _artistIndex);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Emitted when `amount` tokens are created by `operator` and assigned to `to`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` is made operator for `tokenHolder`
     */
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when `operator` is revoked its operator status for `tokenHolder`
     */
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
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
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);

    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
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