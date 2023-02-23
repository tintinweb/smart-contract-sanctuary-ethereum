//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for access related errors.
 */
library AccessError {
    /**
     * @dev Thrown when an address tries to perform an unauthorized action.
     * @param addr The address that attempts the action.
     */
    error Unauthorized(address addr);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for address related errors.
 */
library AddressError {
    /**
     * @dev Thrown when a zero address was passed as a function parameter (0x0000000000000000000000000000000000000000).
     */
    error ZeroAddress();

    /**
     * @dev Thrown when an address representing a contract is expected, but no code is found at the address.
     * @param contr The address that was expected to be a contract.
     */
    error NotAContract(address contr);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for array related errors.
 */
library ArrayError {
    /**
     * @dev Thrown when an unexpected empty array is detected.
     */
    error EmptyArray();

    /**
     * @dev Thrown when attempting to access an array beyond its current number of items.
     */
    error OutOfBounds();
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for change related errors.
 */
library ChangeError {
    /**
     * @dev Thrown when a change is expected but none is detected.
     */
    error NoChange();
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for initialization related errors.
 */
library InitError {
    /**
     * @dev Thrown when attempting to initialize a contract that is already initialized.
     */
    error AlreadyInitialized();

    /**
     * @dev Thrown when attempting to interact with a contract that has not been initialized yet.
     */
    error NotInitialized();
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for errors related with expected function parameters.
 */
library ParameterError {
    /**
     * @dev Thrown when an invalid parameter is used in a function.
     * @param parameter The name of the parameter.
     * @param reason The reason why the received parameter is invalid.
     */
    error InvalidParameter(string parameter, string reason);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../errors/InitError.sol";

/**
 * @title Mixin for contracts that require initialization.
 */
abstract contract InitializableMixin {
    /**
     * @dev Reverts if contract is not initialized.
     */
    modifier onlyIfInitialized() {
        if (!_isInitialized()) {
            revert InitError.NotInitialized();
        }

        _;
    }

    /**
     * @dev Reverts if contract is already initialized.
     */
    modifier onlyIfNotInitialized() {
        if (_isInitialized()) {
            revert InitError.AlreadyInitialized();
        }

        _;
    }

    /**
     * @dev Override this function to determine if the contract is initialized.
     * @return True if initialized, false otherwise.
     */
    function _isInitialized() internal view virtual returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC165 interface for determining if a contract supports a given interface.
 */
interface IERC165 {
    /**
     * @notice Determines if the contract in question supports the specified interface.
     * @param interfaceID XOR of all selectors in the contract.
     * @return True if the contract supports the specified interface.
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC20 token implementation.
 */
interface IERC20 {
    /**
     * @notice Emitted when tokens have been transferred.
     * @param from The address that originally owned the tokens.
     * @param to The address that received the tokens.
     * @param amount The number of tokens that were transferred.
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice Emitted when a user has provided allowance to another user for transferring tokens on its behalf.
     * @param owner The address that is providing the allowance.
     * @param spender The address that received the allowance.
     * @param amount The number of tokens that were added to `spender`'s allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Thrown when the address interacting with the contract does not have sufficient allowance to transfer tokens from another contract.
     * @param required The necessary allowance.
     * @param existing The current allowance.
     */
    error InsufficientAllowance(uint required, uint existing);

    /**
     * @notice Thrown when the address interacting with the contract does not have sufficient tokens.
     * @param required The necessary balance.
     * @param existing The current balance.
     */
    error InsufficientBalance(uint required, uint existing);

    /**
     * @notice Retrieves the name of the token, e.g. "Synthetix Network Token".
     * @return A string with the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @notice Retrieves the symbol of the token, e.g. "SNX".
     * @return A string with the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Retrieves the number of decimals used by the token. The default is 18.
     * @return The number of decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Returns the total number of tokens in circulation (minted - burnt).
     * @return The total number of tokens.
     */
    function totalSupply() external view returns (uint);

    /**
     * @notice Returns the balance of a user.
     * @param owner The address whose balance is being retrieved.
     * @return The number of tokens owned by the user.
     */
    function balanceOf(address owner) external view returns (uint);

    /**
     * @notice Returns how many tokens a user has allowed another user to transfer on its behalf.
     * @param owner The user who has given the allowance.
     * @param spender The user who was given the allowance.
     * @return The amount of tokens `spender` can transfer on `owner`'s behalf.
     */
    function allowance(address owner, address spender) external view returns (uint);

    /**
     * @notice Transfer tokens from one address to another.
     * @param to The address that will receive the tokens.
     * @param amount The amount of tokens to be transferred.
     * @return A boolean which is true if the operation succeeded.
     */
    function transfer(address to, uint amount) external returns (bool);

    /**
     * @notice Allows users to provide allowance to other users so that they can transfer tokens on their behalf.
     * @param spender The address that is receiving the allowance.
     * @param amount The amount of tokens that are being added to the allowance.
     * @return A boolean which is true if the operation succeeded.
     */
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**
     * @notice Allows a user who has been given allowance to transfer tokens on another user's behalf.
     * @param from The address that owns the tokens that are being transferred.
     * @param to The address that will receive the tokens.
     * @param amount The number of tokens to transfer.
     * @return A boolean which is true if the operation succeeded.
     */
    function transferFrom(address from, address to, uint amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC721 non-fungible token (NFT) contract.
 */
interface IERC721 {
    /**
     * @notice Thrown when an address attempts to provide allowance to itself.
     * @param addr The address attempting to provide allowance.
     */
    error CannotSelfApprove(address addr);

    /**
     * @notice Thrown when attempting to transfer a token to an address that does not satisfy IERC721Receiver requirements.
     * @param addr The address that cannot receive the tokens.
     */
    error InvalidTransferRecipient(address addr);

    /**
     * @notice Thrown when attempting to specify an owner which is not valid (ex. the 0x00000... address)
     */
    error InvalidOwner(address addr);

    /**
     * @notice Thrown when attempting to operate on a token id that does not exist.
     * @param id The token id that does not exist.
     */
    error TokenDoesNotExist(uint256 id);

    /**
     * @notice Thrown when attempting to mint a token that already exists.
     * @param id The token id that already exists.
     */
    error TokenAlreadyMinted(uint256 id);

    /**
     * @notice Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @notice Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @notice Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @notice Returns the number of tokens in ``owner``'s account.
     *
     * Requirements:
     *
     * - `owner` must be a valid address
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @notice Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`.
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
     * @notice Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Transfers `tokenId` token from `from` to `to`.
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
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Gives permission to `to` to transfer `tokenId` token to another account.
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
     * @notice Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @notice Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @notice Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./IERC721.sol";

/**
 * @title ERC721 extension with helper functions that allow the enumeration of NFT tokens.
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @notice Thrown calling *ByIndex function with an index greater than the number of tokens existing
     * @param requestedIndex The index requested by the caller
     * @param length The length of the list that is being iterated, making the max index queryable length - 1
     */
    error IndexOverrun(uint requestedIndex, uint length);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     *
     * Requirements:
     * - `owner` must be a valid address
     * - `index` must be less than the balance of the tokens for the owner
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     *
     * Requirements:
     * - `index` must be less than the total supply of the tokens
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./IERC165.sol";

/**
 * @title Additional metadata for IERC721 tokens.
 */
interface IERC721Metadata is IERC165 {
    /**
     * @notice Retrieves the name of the token, e.g. "Synthetix Account Token".
     * @return A string with the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @notice Retrieves the symbol of the token, e.g. "SNX-ACC".
     * @return A string with the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Retrieves the off-chain URI where the specified token id may contain associated data, such as images, audio, etc.
     * @param tokenId The numeric id of the token in question.
     * @return The URI of the token in question.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC721 extension that allows contracts to receive tokens with `safeTransferFrom`.
 */
interface IERC721Receiver {
    /**
     * @notice Function that will be called by ERC721 tokens implementing the `safeTransferFrom` function.
     * @dev The contract transferring the token will revert if the receiving contract does not implement this function.
     * @param operator The address that is executing the transfer.
     * @param from The address whose token is being transferred.
     * @param tokenId The numeric id of the token being transferred.
     * @param data Optional additional data that may be passed by the operator, and could be used by the implementing contract.
     * @return The selector of this function (IERC721Receiver.onERC721Received.selector). Caller will revert if not returned.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) external returns (bytes4);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Contract for facilitating ownership by a single address.
 */
interface IOwnable {
    /**
     * @notice Thrown when an address tries to accept ownership but has not been nominated.
     * @param addr The address that is trying to accept ownership.
     */
    error NotNominated(address addr);

    /**
     * @notice Emitted when an address has been nominated.
     * @param newOwner The address that has been nominated.
     */
    event OwnerNominated(address newOwner);

    /**
     * @notice Emitted when the owner of the contract has changed.
     * @param oldOwner The previous owner of the contract.
     * @param newOwner The new owner of the contract.
     */
    event OwnerChanged(address oldOwner, address newOwner);

    /**
     * @notice Allows a nominated address to accept ownership of the contract.
     * @dev Reverts if the caller is not nominated.
     */
    function acceptOwnership() external;

    /**
     * @notice Allows the current owner to nominate a new owner.
     * @dev The nominated owner will have to call `acceptOwnership` in a separate transaction in order to finalize the action and become the new contract owner.
     * @param newNominatedOwner The address that is to become nominated.
     */
    function nominateNewOwner(address newNominatedOwner) external;

    /**
     * @notice Allows a nominated owner to reject the nomination.
     */
    function renounceNomination() external;

    /**
     * @notice Returns the current owner of the contract.
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the current nominated owner of the contract.
     * @dev Only one address can be nominated at a time.
     */
    function nominatedOwner() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Contract to be used as the implementation of a Universal Upgradeable Proxy Standard (UUPS) proxy.
 *
 * Important: A UUPS proxy requires its upgradeability functions to be in the implementation as opposed to the proxy. This means that if the proxy is upgraded to an implementation that does not support this interface, it will no longer be upgradeable.
 */
interface IUUPSImplementation {
    /**
     * @notice Thrown when an incoming implementation will not be able to receive future upgrades.
     */
    error ImplementationIsSterile(address implementation);

    /**
     * @notice Thrown intentionally when testing future upgradeability of an implementation.
     */
    error UpgradeSimulationFailed();

    /**
     * @notice Emitted when the implementation of the proxy has been upgraded.
     * @param self The address of the proxy whose implementation was upgraded.
     * @param implementation The address of the proxy's new implementation.
     */
    event Upgraded(address indexed self, address implementation);

    /**
     * @notice Allows the proxy to be upgraded to a new implementation.
     * @param newImplementation The address of the proxy's new implementation.
     * @dev Will revert if `newImplementation` is not upgradeable.
     * @dev The implementation of this function needs to be protected by some sort of access control such as `onlyOwner`.
     */
    function upgradeTo(address newImplementation) external;

    /**
     * @notice Function used to determine if a new implementation will be able to receive future upgrades in `upgradeTo`.
     * @param newImplementation The address of the new implementation being tested for future upgradeability.
     * @dev This function will always revert, but will revert with different error messages. The function `upgradeTo` uses this error to determine the future upgradeability of the implementation in question.
     */
    function simulateUpgradeTo(address newImplementation) external;

    /**
     * @notice Retrieves the current implementation of the proxy.
     * @return The address of the current implementation.
     */
    function getImplementation() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./OwnableStorage.sol";
import "../interfaces/IOwnable.sol";
import "../errors/AddressError.sol";
import "../errors/ChangeError.sol";

/**
 * @title Contract for facilitating ownership by a single address.
 * See IOwnable.
 */
contract Ownable is IOwnable {
    constructor(address initialOwner) {
        OwnableStorage.load().owner = initialOwner;
    }

    /**
     * @inheritdoc IOwnable
     */
    function acceptOwnership() public override {
        OwnableStorage.Data storage store = OwnableStorage.load();

        address currentNominatedOwner = store.nominatedOwner;
        if (msg.sender != currentNominatedOwner) {
            revert NotNominated(msg.sender);
        }

        emit OwnerChanged(store.owner, currentNominatedOwner);
        store.owner = currentNominatedOwner;

        store.nominatedOwner = address(0);
    }

    /**
     * @inheritdoc IOwnable
     */
    function nominateNewOwner(address newNominatedOwner) public override onlyOwner {
        OwnableStorage.Data storage store = OwnableStorage.load();

        if (newNominatedOwner == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (newNominatedOwner == store.nominatedOwner) {
            revert ChangeError.NoChange();
        }

        store.nominatedOwner = newNominatedOwner;
        emit OwnerNominated(newNominatedOwner);
    }

    /**
     * @inheritdoc IOwnable
     */
    function renounceNomination() external override {
        OwnableStorage.Data storage store = OwnableStorage.load();

        if (store.nominatedOwner != msg.sender) {
            revert NotNominated(msg.sender);
        }

        store.nominatedOwner = address(0);
    }

    /**
     * @inheritdoc IOwnable
     */
    function owner() external view override returns (address) {
        return OwnableStorage.load().owner;
    }

    /**
     * @inheritdoc IOwnable
     */
    function nominatedOwner() external view override returns (address) {
        return OwnableStorage.load().nominatedOwner;
    }

    /**
     * @dev Reverts if the caller is not the owner.
     */
    modifier onlyOwner() {
        OwnableStorage.onlyOwner();

        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../errors/AccessError.sol";

library OwnableStorage {
    bytes32 private constant _SLOT_OWNABLE_STORAGE =
        keccak256(abi.encode("io.synthetix.core-contracts.Ownable"));

    struct Data {
        address owner;
        address nominatedOwner;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = _SLOT_OWNABLE_STORAGE;
        assembly {
            store.slot := s
        }
    }

    function onlyOwner() internal view {
        if (msg.sender != getOwner()) {
            revert AccessError.Unauthorized(msg.sender);
        }
    }

    function getOwner() internal view returns (address) {
        return OwnableStorage.load().owner;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

abstract contract AbstractProxy {
    fallback() external payable {
        _forward();
    }

    receive() external payable {
        _forward();
    }

    function _forward() internal {
        address implementation = _getImplementation();

        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _getImplementation() internal view virtual returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

contract ProxyStorage {
    bytes32 private constant _SLOT_PROXY_STORAGE =
        keccak256(abi.encode("io.synthetix.core-contracts.Proxy"));

    struct ProxyStore {
        address implementation;
        bool simulatingUpgrade;
    }

    function _proxyStore() internal pure returns (ProxyStore storage store) {
        bytes32 s = _SLOT_PROXY_STORAGE;
        assembly {
            store.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/IUUPSImplementation.sol";
import "../errors/AddressError.sol";
import "../errors/ChangeError.sol";
import "../utils/AddressUtil.sol";
import "./ProxyStorage.sol";

abstract contract UUPSImplementation is IUUPSImplementation, ProxyStorage {
    /**
     * @inheritdoc IUUPSImplementation
     */
    function simulateUpgradeTo(address newImplementation) public override {
        ProxyStore storage store = _proxyStore();

        store.simulatingUpgrade = true;

        address currentImplementation = store.implementation;
        store.implementation = newImplementation;

        (bool rollbackSuccessful, ) = newImplementation.delegatecall(
            abi.encodeCall(this.upgradeTo, (currentImplementation))
        );

        if (!rollbackSuccessful || _proxyStore().implementation != currentImplementation) {
            revert UpgradeSimulationFailed();
        }

        store.simulatingUpgrade = false;

        // solhint-disable-next-line reason-string
        revert();
    }

    /**
     * @inheritdoc IUUPSImplementation
     */
    function getImplementation() external view override returns (address) {
        return _proxyStore().implementation;
    }

    function _upgradeTo(address newImplementation) internal virtual {
        if (newImplementation == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (!AddressUtil.isContract(newImplementation)) {
            revert AddressError.NotAContract(newImplementation);
        }

        ProxyStore storage store = _proxyStore();

        if (newImplementation == store.implementation) {
            revert ChangeError.NoChange();
        }

        if (!store.simulatingUpgrade && _implementationIsSterile(newImplementation)) {
            revert ImplementationIsSterile(newImplementation);
        }

        store.implementation = newImplementation;

        emit Upgraded(address(this), newImplementation);
    }

    function _implementationIsSterile(
        address candidateImplementation
    ) internal virtual returns (bool) {
        (bool simulationReverted, bytes memory simulationResponse) = address(this).delegatecall(
            abi.encodeCall(this.simulateUpgradeTo, (candidateImplementation))
        );

        return
            !simulationReverted &&
            keccak256(abi.encodePacked(simulationResponse)) ==
            keccak256(abi.encodePacked(UpgradeSimulationFailed.selector));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./AbstractProxy.sol";
import "./ProxyStorage.sol";
import "../errors/AddressError.sol";
import "../utils/AddressUtil.sol";

contract UUPSProxy is AbstractProxy, ProxyStorage {
    constructor(address firstImplementation) {
        if (firstImplementation == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (!AddressUtil.isContract(firstImplementation)) {
            revert AddressError.NotAContract(firstImplementation);
        }

        _proxyStore().implementation = firstImplementation;
    }

    function _getImplementation() internal view virtual override returns (address) {
        return _proxyStore().implementation;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {UUPSProxy} from "./UUPSProxy.sol";
import {OwnableStorage} from "../ownership/OwnableStorage.sol";

contract UUPSProxyWithOwner is UUPSProxy {
    // solhint-disable-next-line no-empty-blocks
    constructor(address firstImplementation, address initialOwner) UUPSProxy(firstImplementation) {
        OwnableStorage.load().owner = initialOwner;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/IERC20.sol";
import "../errors/InitError.sol";
import "./ERC20Storage.sol";

/*
 * @title ERC20 token implementation.
 * See IERC20.
 *
 * Reference implementations:
 * - OpenZeppelin - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
 * - Rari-Capital - https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol
 */
contract ERC20 is IERC20 {
    /**
     * @inheritdoc IERC20
     */
    function name() external view override returns (string memory) {
        return ERC20Storage.load().name;
    }

    /**
     * @inheritdoc IERC20
     */
    function symbol() external view override returns (string memory) {
        return ERC20Storage.load().symbol;
    }

    /**
     * @inheritdoc IERC20
     */
    function decimals() external view override returns (uint8) {
        return ERC20Storage.load().decimals;
    }

    /**
     * @inheritdoc IERC20
     */
    function totalSupply() external view virtual override returns (uint256) {
        return ERC20Storage.load().totalSupply;
    }

    /**
     * @inheritdoc IERC20
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return ERC20Storage.load().allowance[owner][spender];
    }

    /**
     * @inheritdoc IERC20
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        return ERC20Storage.load().balanceOf[owner];
    }

    /**
     * @inheritdoc IERC20
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @inheritdoc IERC20
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual override returns (bool) {
        uint256 currentAllowance = ERC20Storage.load().allowance[msg.sender][spender];
        _approve(msg.sender, spender, currentAllowance + addedValue);

        return true;
    }

    /**
     * @inheritdoc IERC20
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual override returns (bool) {
        uint256 currentAllowance = ERC20Storage.load().allowance[msg.sender][spender];
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @inheritdoc IERC20
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, to, amount);

        return true;
    }

    /**
     * @inheritdoc IERC20
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        return _transferFrom(from, to, amount);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 amount
    ) internal virtual returns (bool) {
        ERC20Storage.Data storage store = ERC20Storage.load();

        uint256 currentAllowance = store.allowance[from][msg.sender];
        if (currentAllowance < amount) {
            revert InsufficientAllowance(amount, currentAllowance);
        }

        unchecked {
            store.allowance[from][msg.sender] -= amount;
        }

        _transfer(from, to, amount);

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        ERC20Storage.Data storage store = ERC20Storage.load();

        uint256 accountBalance = store.balanceOf[from];
        if (accountBalance < amount) {
            revert InsufficientBalance(amount, accountBalance);
        }

        // We are now sure that we can perform this operation safely
        // since it didn't revert in the previous step.
        // The total supply cannot exceed the maximum value of uint256,
        // thus we can now perform accounting operations in unchecked mode.
        unchecked {
            store.balanceOf[from] -= amount;
            store.balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        ERC20Storage.load().allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address to, uint256 amount) internal virtual {
        ERC20Storage.Data storage store = ERC20Storage.load();

        store.totalSupply += amount;

        // No need for overflow check since it is done in the previous step
        unchecked {
            store.balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        ERC20Storage.Data storage store = ERC20Storage.load();

        uint256 accountBalance = store.balanceOf[from];
        if (accountBalance < amount) {
            revert InsufficientBalance(amount, accountBalance);
        }

        // No need for underflow check since it would have occured in the previous step
        unchecked {
            store.balanceOf[from] -= amount;
            store.totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }

    function _initialize(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) internal virtual {
        ERC20Storage.Data storage store = ERC20Storage.load();

        if (bytes(store.name).length > 0 || bytes(store.symbol).length > 0 || store.decimals > 0) {
            revert InitError.AlreadyInitialized();
        }

        store.name = tokenName;
        store.symbol = tokenSymbol;
        store.decimals = tokenDecimals;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/IERC20.sol";

library ERC20Helper {
    error FailedTransfer(address from, address to, uint value);

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert FailedTransfer(address(this), to, value);
        }
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert FailedTransfer(from, to, value);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library ERC20Storage {
    bytes32 private constant _SLOT_ERC20_STORAGE =
        keccak256(abi.encode("io.synthetix.core-contracts.ERC20"));

    struct Data {
        string name;
        string symbol;
        uint8 decimals;
        mapping(address => uint256) balanceOf;
        mapping(address => mapping(address => uint256)) allowance;
        uint256 totalSupply;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = _SLOT_ERC20_STORAGE;
        assembly {
            store.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Metadata.sol";
import "../interfaces/IERC721Receiver.sol";
import "../errors/AddressError.sol";
import "../errors/AccessError.sol";
import "../errors/InitError.sol";
import "../errors/ParameterError.sol";
import "./ERC721Storage.sol";
import "../utils/AddressUtil.sol";
import "../utils/StringUtil.sol";

/*
 * @title ERC721 non-fungible token (NFT) contract.
 * See IERC721.
 *
 * Reference implementations:
 * - OpenZeppelin - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
 */
contract ERC721 is IERC721, IERC721Metadata {
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == this.supportsInterface.selector || // ERC165
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    /**
     * @inheritdoc IERC721
     */
    function balanceOf(address holder) public view virtual override returns (uint) {
        if (holder == address(0)) {
            revert InvalidOwner(holder);
        }

        return ERC721Storage.load().balanceOf[holder];
    }

    /**
     * @inheritdoc IERC721
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist(tokenId);
        }

        return ERC721Storage.load().ownerOf[tokenId];
    }

    /**
     * @inheritdoc IERC721Metadata
     */
    function name() external view virtual override returns (string memory) {
        return ERC721Storage.load().name;
    }

    /**
     * @inheritdoc IERC721Metadata
     */
    function symbol() external view virtual override returns (string memory) {
        return ERC721Storage.load().symbol;
    }

    /**
     * @inheritdoc IERC721Metadata
     */
    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist(tokenId);
        }

        string memory baseURI = ERC721Storage.load().baseTokenURI;

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, StringUtil.uintToString(tokenId)))
                : "";
    }

    /**
     * @inheritdoc IERC721
     */
    function approve(address to, uint256 tokenId) public virtual override {
        ERC721Storage.Data storage store = ERC721Storage.load();
        address holder = store.ownerOf[tokenId];

        if (to == holder) {
            revert CannotSelfApprove(to);
        }

        if (msg.sender != holder && !isApprovedForAll(holder, msg.sender)) {
            revert AccessError.Unauthorized(msg.sender);
        }

        _approve(to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist(tokenId);
        }

        return ERC721Storage.load().tokenApprovals[tokenId];
    }

    /**
     * @inheritdoc IERC721
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (msg.sender == operator) {
            revert CannotSelfApprove(operator);
        }

        ERC721Storage.load().operatorApprovals[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @inheritdoc IERC721
     */
    function isApprovedForAll(
        address holder,
        address operator
    ) public view virtual override returns (bool) {
        return ERC721Storage.load().operatorApprovals[holder][operator];
    }

    /**
     * @inheritdoc IERC721
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert AccessError.Unauthorized(msg.sender);
        }

        _transfer(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert AccessError.Unauthorized(msg.sender);
        }

        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert InvalidTransferRecipient(to);
        }
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return ERC721Storage.load().ownerOf[tokenId] != address(0);
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address holder = ownerOf(tokenId);

        // Not checking tokenId existence since it is checked in ownerOf() and getApproved()

        return (spender == holder ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(holder, spender));
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        ERC721Storage.Data storage store = ERC721Storage.load();
        if (to == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (tokenId == 0) {
            revert ParameterError.InvalidParameter("tokenId", "cannot be zero");
        }

        if (_exists(tokenId)) {
            revert TokenAlreadyMinted(tokenId);
        }

        _beforeTransfer(address(0), to, tokenId);

        store.balanceOf[to] += 1;
        store.ownerOf[tokenId] = to;

        _postTransfer(address(0), to, tokenId);

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        ERC721Storage.Data storage store = ERC721Storage.load();
        address holder = store.ownerOf[tokenId];

        _approve(address(0), tokenId);

        _beforeTransfer(holder, address(0), tokenId);

        store.balanceOf[holder] -= 1;
        delete store.ownerOf[tokenId];

        _postTransfer(holder, address(0), tokenId);

        emit Transfer(holder, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        ERC721Storage.Data storage store = ERC721Storage.load();

        if (ownerOf(tokenId) != from) {
            revert AccessError.Unauthorized(from);
        }

        if (to == address(0)) {
            revert AddressError.ZeroAddress();
        }

        _beforeTransfer(from, to, tokenId);

        // Clear approvals from the previous holder
        _approve(address(0), tokenId);

        store.balanceOf[from] -= 1;
        store.balanceOf[to] += 1;
        store.ownerOf[tokenId] = to;

        _postTransfer(from, to, tokenId);

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        ERC721Storage.load().tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal returns (bool) {
        if (AddressUtil.isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (
                bytes4 retval
            ) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch {
                return false;
            }
        } else {
            return true;
        }
    }

    function _beforeTransfer(
        address from,
        address to,
        uint256 tokenId // solhint-disable-next-line no-empty-blocks
    ) internal virtual {}

    function _postTransfer(
        address from,
        address to,
        uint256 tokenId // solhint-disable-next-line no-empty-blocks
    ) internal virtual {}

    function _initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory baseTokenURI
    ) internal virtual {
        ERC721Storage.Data storage store = ERC721Storage.load();
        if (
            bytes(store.name).length > 0 ||
            bytes(store.symbol).length > 0 ||
            bytes(store.baseTokenURI).length > 0
        ) {
            revert InitError.AlreadyInitialized();
        }

        if (bytes(tokenName).length == 0 || bytes(tokenSymbol).length == 0) {
            revert ParameterError.InvalidParameter("name/symbol", "must not be empty");
        }

        store.name = tokenName;
        store.symbol = tokenSymbol;
        store.baseTokenURI = baseTokenURI;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./ERC721.sol";
import "./ERC721EnumerableStorage.sol";
import "../interfaces/IERC721Enumerable.sol";

/*
 * @title ERC721 extension with helper functions that allow the enumeration of NFT tokens.
 * See IERC721Enumerable
 *
 * Reference implementations:
 * - OpenZeppelin - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721EnumerableStorage.sol
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC721Enumerable).interfaceId;
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) public view virtual override returns (uint256) {
        if (ERC721.balanceOf(owner) <= index) {
            revert IndexOverrun(index, ERC721.balanceOf(owner));
        }
        return ERC721EnumerableStorage.load().ownedTokens[owner][index];
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function totalSupply() public view virtual override returns (uint256) {
        return ERC721EnumerableStorage.load().allTokens.length;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        if (index >= ERC721Enumerable.totalSupply()) {
            revert IndexOverrun(index, ERC721Enumerable.totalSupply());
        }
        return ERC721EnumerableStorage.load().allTokens[index];
    }

    function _beforeTransfer(address from, address to, uint256 tokenId) internal virtual override {
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        ERC721EnumerableStorage.load().ownedTokens[to][length] = tokenId;
        ERC721EnumerableStorage.load().ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        ERC721EnumerableStorage.load().allTokensIndex[tokenId] = ERC721EnumerableStorage
            .load()
            .allTokens
            .length;
        ERC721EnumerableStorage.load().allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = ERC721EnumerableStorage.load().ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ERC721EnumerableStorage.load().ownedTokens[from][lastTokenIndex];

            ERC721EnumerableStorage.load().ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            ERC721EnumerableStorage.load().ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete ERC721EnumerableStorage.load().ownedTokensIndex[tokenId];
        delete ERC721EnumerableStorage.load().ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721EnumerableStorage.load().allTokens.length - 1;
        uint256 tokenIndex = ERC721EnumerableStorage.load().allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = ERC721EnumerableStorage.load().allTokens[lastTokenIndex];

        ERC721EnumerableStorage.load().allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        ERC721EnumerableStorage.load().allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete ERC721EnumerableStorage.load().allTokensIndex[tokenId];
        ERC721EnumerableStorage.load().allTokens.pop();
    }

    function _initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory baseTokenURI
    ) internal virtual override {
        super._initialize(tokenName, tokenSymbol, baseTokenURI);
        if (ERC721EnumerableStorage.load().allTokens.length > 0) {
            revert InitError.AlreadyInitialized();
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library ERC721EnumerableStorage {
    bytes32 private constant _SLOT_ERC721_ENUMERABLE_STORAGE =
        keccak256(abi.encode("io.synthetix.core-contracts.ERC721Enumerable"));

    struct Data {
        mapping(uint256 => uint256) ownedTokensIndex;
        mapping(uint256 => uint256) allTokensIndex;
        mapping(address => mapping(uint256 => uint256)) ownedTokens;
        uint256[] allTokens;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = _SLOT_ERC721_ENUMERABLE_STORAGE;
        assembly {
            store.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library ERC721Storage {
    bytes32 private constant _SLOT_ERC721_STORAGE =
        keccak256(abi.encode("io.synthetix.core-contracts.ERC721"));

    struct Data {
        string name;
        string symbol;
        string baseTokenURI;
        mapping(uint256 => address) ownerOf;
        mapping(address => uint256) balanceOf;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = _SLOT_ERC721_STORAGE;
        assembly {
            store.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library AddressUtil {
    function isContract(address account) internal view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(account)
        }

        return size > 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./SafeCast.sol";

/**
 * @title Utility library used to represent "decimals" (fixed point numbers) with integers, with two different levels of precision.
 *
 * They are represented by N * UNIT, where UNIT is the number of decimals of precision in the representation.
 *
 * Examples:
 * 1) Given UNIT = 100
 * then if A = 50, A represents the decimal 0.50
 * 2) Given UNIT = 1000000000000000000
 * then if A = 500000000000000000, A represents the decimal 0.500000000000000000
 *
 * Note: An accompanying naming convention of the postfix "D<Precision>" is helpful with this utility. I.e. if a variable "myValue" represents a low resolution decimal, it should be named "myValueD18", and if it was a high resolution decimal "myValueD27". While scaling, intermediate precision decimals like "myValue45" could arise. Non-decimals should have no postfix, i.e. just "myValue".
 *
 * Important: Multiplication and division operations are currently not supported for high precision decimals. Using these operations on them will yield incorrect results and fail silently.
 */
library DecimalMath {
    using SafeCastU256 for uint256;
    using SafeCastI256 for int256;

    // solhint-disable numcast/safe-cast

    // Numbers representing 1.0 (low precision).
    uint256 public constant UNIT = 1e18;
    int256 public constant UNIT_INT = int256(UNIT);
    uint128 public constant UNIT_UINT128 = uint128(UNIT);
    int128 public constant UNIT_INT128 = int128(UNIT_INT);

    // Numbers representing 1.0 (high precision).
    uint256 public constant UNIT_PRECISE = 1e27;
    int256 public constant UNIT_PRECISE_INT = int256(UNIT_PRECISE);
    int128 public constant UNIT_PRECISE_INT128 = int128(UNIT_PRECISE_INT);

    // Precision scaling, (used to scale down/up from one precision to the other).
    uint256 public constant PRECISION_FACTOR = 9; // 27 - 18 = 9 :)

    // solhint-enable numcast/safe-cast

    // -----------------
    // uint256
    // -----------------

    /**
     * @dev Multiplies two low precision decimals.
     *
     * Since the two numbers are assumed to be fixed point numbers,
     * (x * UNIT) * (y * UNIT) = x * y * UNIT ^ 2,
     * the result is divided by UNIT to remove double scaling.
     */
    function mulDecimal(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return (x * y) / UNIT;
    }

    /**
     * @dev Divides two low precision decimals.
     *
     * Since the two numbers are assumed to be fixed point numbers,
     * (x * UNIT) / (y * UNIT) = x / y (Decimal representation is lost),
     * x is first scaled up to end up with a decimal representation.
     */
    function divDecimal(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return (x * UNIT) / y;
    }

    /**
     * @dev Scales up a value.
     *
     * E.g. if value is not a decimal, a scale up by 18 makes it a low precision decimal.
     * If value is a low precision decimal, a scale up by 9 makes it a high precision decimal.
     */
    function upscale(uint x, uint factor) internal pure returns (uint) {
        return x * 10 ** factor;
    }

    /**
     * @dev Scales down a value.
     *
     * E.g. if value is a high precision decimal, a scale down by 9 makes it a low precision decimal.
     * If value is a low precision decimal, a scale down by 9 makes it a regular integer.
     *
     * Scaling down a regular integer would not make sense.
     */
    function downscale(uint x, uint factor) internal pure returns (uint) {
        return x / 10 ** factor;
    }

    // -----------------
    // uint128
    // -----------------

    // Note: Overloading doesn't seem to work for similar types, i.e. int256 and int128, uint256 and uint128, etc, so explicitly naming the functions differently here.

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimalUint128(uint128 x, uint128 y) internal pure returns (uint128) {
        return (x * y) / UNIT_UINT128;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimalUint128(uint128 x, uint128 y) internal pure returns (uint128) {
        return (x * UNIT_UINT128) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscaleUint128(uint128 x, uint factor) internal pure returns (uint128) {
        return x * (10 ** factor).to128();
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscaleUint128(uint128 x, uint factor) internal pure returns (uint128) {
        return x / (10 ** factor).to128();
    }

    // -----------------
    // int256
    // -----------------

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimal(int256 x, int256 y) internal pure returns (int256) {
        return (x * y) / UNIT_INT;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimal(int256 x, int256 y) internal pure returns (int256) {
        return (x * UNIT_INT) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscale(int x, uint factor) internal pure returns (int) {
        return x * (10 ** factor).toInt();
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscale(int x, uint factor) internal pure returns (int) {
        return x / (10 ** factor).toInt();
    }

    // -----------------
    // int128
    // -----------------

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimalInt128(int128 x, int128 y) internal pure returns (int128) {
        return (x * y) / UNIT_INT128;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimalInt128(int128 x, int128 y) internal pure returns (int128) {
        return (x * UNIT_INT128) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscaleInt128(int128 x, uint factor) internal pure returns (int128) {
        return x * ((10 ** factor).toInt()).to128();
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscaleInt128(int128 x, uint factor) internal pure returns (int128) {
        return x / ((10 ** factor).toInt().to128());
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/IERC165.sol";

library ERC165Helper {
    function safeSupportsInterface(
        address candidate,
        bytes4 interfaceID
    ) internal returns (bool supportsInterface) {
        (bool success, bytes memory response) = candidate.call(
            abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceID)
        );

        if (!success) {
            return false;
        }

        if (response.length == 0) {
            return false;
        }

        assembly {
            supportsInterface := mload(add(response, 32))
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

// Eth Heap
// Author: Zac Mitton
// License: MIT

library HeapUtil {
    // default max-heap

    uint private constant _ROOT_INDEX = 1;

    struct Data {
        uint128 idCount;
        Node[] nodes; // root is index 1; index 0 not used
        mapping(uint128 => uint) indices; // unique id => node index
    }
    struct Node {
        uint128 id; //use with another mapping to store arbitrary object types
        int128 priority;
    }

    //call init before anything else
    function init(Data storage self) internal {
        if (self.nodes.length == 0) self.nodes.push(Node(0, 0));
    }

    function insert(Data storage self, uint128 id, int128 priority) internal returns (Node memory) {
        //√
        if (self.nodes.length == 0) {
            init(self);
        } // test on-the-fly-init

        Node memory n;

        // MODIFIED: support updates
        extractById(self, id);

        self.idCount++;
        self.nodes.push();
        n = Node(id, priority);
        _bubbleUp(self, n, self.nodes.length - 1);

        return n;
    }

    function extractMax(Data storage self) internal returns (Node memory) {
        //√
        return _extract(self, _ROOT_INDEX);
    }

    function extractById(Data storage self, uint128 id) internal returns (Node memory) {
        //√
        return _extract(self, self.indices[id]);
    }

    //view
    function dump(Data storage self) internal view returns (Node[] memory) {
        //note: Empty set will return `[Node(0,0)]`. uninitialized will return `[]`.
        return self.nodes;
    }

    function getById(Data storage self, uint128 id) internal view returns (Node memory) {
        return getByIndex(self, self.indices[id]); //test that all these return the emptyNode
    }

    function getByIndex(Data storage self, uint i) internal view returns (Node memory) {
        return self.nodes.length > i ? self.nodes[i] : Node(0, 0);
    }

    function getMax(Data storage self) internal view returns (Node memory) {
        return getByIndex(self, _ROOT_INDEX);
    }

    function size(Data storage self) internal view returns (uint) {
        return self.nodes.length > 0 ? self.nodes.length - 1 : 0;
    }

    function isNode(Node memory n) internal pure returns (bool) {
        return n.id > 0;
    }

    //private
    function _extract(Data storage self, uint i) private returns (Node memory) {
        //√
        if (self.nodes.length <= i || i <= 0) {
            return Node(0, 0);
        }

        Node memory extractedNode = self.nodes[i];
        delete self.indices[extractedNode.id];

        Node memory tailNode = self.nodes[self.nodes.length - 1];
        self.nodes.pop();

        if (i < self.nodes.length) {
            // if extracted node was not tail
            _bubbleUp(self, tailNode, i);
            _bubbleDown(self, self.nodes[i], i); // then try bubbling down
        }
        return extractedNode;
    }

    function _bubbleUp(Data storage self, Node memory n, uint i) private {
        //√
        if (i == _ROOT_INDEX || n.priority <= self.nodes[i / 2].priority) {
            _insert(self, n, i);
        } else {
            _insert(self, self.nodes[i / 2], i);
            _bubbleUp(self, n, i / 2);
        }
    }

    function _bubbleDown(Data storage self, Node memory n, uint i) private {
        //
        uint length = self.nodes.length;
        uint cIndex = i * 2; // left child index

        if (length <= cIndex) {
            _insert(self, n, i);
        } else {
            Node memory largestChild = self.nodes[cIndex];

            if (length > cIndex + 1 && self.nodes[cIndex + 1].priority > largestChild.priority) {
                largestChild = self.nodes[++cIndex]; // TEST ++ gets executed first here
            }

            if (largestChild.priority <= n.priority) {
                //TEST: priority 0 is valid! negative ints work
                _insert(self, n, i);
            } else {
                _insert(self, largestChild, i);
                _bubbleDown(self, n, cIndex);
            }
        }
    }

    function _insert(Data storage self, Node memory n, uint i) private {
        //√
        self.nodes[i] = n;
        self.indices[n.id] = i;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * Utilities that convert numeric types avoiding silent overflows.
 */
import "./SafeCast/SafeCastU32.sol";
import "./SafeCast/SafeCastI32.sol";
import "./SafeCast/SafeCastI24.sol";
import "./SafeCast/SafeCastU56.sol";
import "./SafeCast/SafeCastI56.sol";
import "./SafeCast/SafeCastU64.sol";
import "./SafeCast/SafeCastI128.sol";
import "./SafeCast/SafeCastI256.sol";
import "./SafeCast/SafeCastU128.sol";
import "./SafeCast/SafeCastU160.sol";
import "./SafeCast/SafeCastU256.sol";
import "./SafeCast/SafeCastAddress.sol";
import "./SafeCast/SafeCastBytes32.sol";

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastAddress {
    function toBytes32(address x) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(x)));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastBytes32 {
    function toAddress(bytes32 x) internal pure returns (address) {
        return address(uint160(uint256(x)));
    }

    function toUint(bytes32 x) internal pure returns (uint) {
        return uint(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI128 {
    error OverflowInt128ToUint128();
    error OverflowInt128ToInt32();

    function toUint(int128 x) internal pure returns (uint128) {
        // ----------------<==============o==============>-----------------
        // ----------------xxxxxxxxxxxxxxxo===============>----------------
        if (x < 0) {
            revert OverflowInt128ToUint128();
        }

        return uint128(x);
    }

    function to256(int128 x) internal pure returns (int256) {
        return int256(x);
    }

    function to32(int128 x) internal pure returns (int32) {
        // ----------------<==============o==============>-----------------
        // ----------------xxxxxxxxxxxx<==o==>xxxxxxxxxxxx-----------------
        if (x < int(type(int32).min) || x > int(type(int32).max)) {
            revert OverflowInt128ToInt32();
        }

        return int32(x);
    }

    function zero() internal pure returns (int128) {
        return int128(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI24 {
    function to256(int24 x) internal pure returns (int256) {
        return int256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI256 {
    error OverflowInt256ToUint256();
    error OverflowInt256ToInt128();
    error OverflowInt256ToInt24();

    function to128(int256 x) internal pure returns (int128) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxx<==============o==============>xxxxxxxxxxxxx----
        if (x < int256(type(int128).min) || x > int256(type(int128).max)) {
            revert OverflowInt256ToInt128();
        }

        return int128(x);
    }

    function to24(int256 x) internal pure returns (int24) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxxxxxxxxxx<======o=======>xxxxxxxxxxxxxxxxxxxx----
        if (x < int256(type(int24).min) || x > int256(type(int24).max)) {
            revert OverflowInt256ToInt24();
        }

        return int24(x);
    }

    function toUint(int256 x) internal pure returns (uint256) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxxxxxxxxxxxxxxxxxo===============================>
        if (x < 0) {
            revert OverflowInt256ToUint256();
        }

        return uint256(x);
    }

    function zero() internal pure returns (int256) {
        return int256(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI32 {
    error OverflowInt32ToUint32();

    function toUint(int32 x) internal pure returns (uint32) {
        // ----------------------<========o========>----------------------
        // ----------------------xxxxxxxxxo=========>----------------------
        if (x < 0) {
            revert OverflowInt32ToUint32();
        }

        return uint32(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI56 {
    error OverflowInt56ToInt24();

    function to24(int56 x) internal pure returns (int24) {
        // ----------------------<========o========>-----------------------
        // ----------------------xxx<=====o=====>xxx-----------------------
        if (x < int(type(int24).min) || x > int(type(int24).max)) {
            revert OverflowInt56ToInt24();
        }

        return int24(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU128 {
    error OverflowUint128ToInt128();

    function to256(uint128 x) internal pure returns (uint256) {
        return uint256(x);
    }

    function toInt(uint128 x) internal pure returns (int128) {
        // -------------------------------o===============>----------------
        // ----------------<==============o==============>x----------------
        if (x > uint128(type(int128).max)) {
            revert OverflowUint128ToInt128();
        }

        return int128(x);
    }

    function toBytes32(uint128 x) internal pure returns (bytes32) {
        return bytes32(uint256(x));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU160 {
    function to256(uint160 x) internal pure returns (uint256) {
        return uint256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU256 {
    error OverflowUint256ToUint128();
    error OverflowUint256ToInt256();
    error OverflowUint256ToUint64();
    error OverflowUint256ToUint32();
    error OverflowUint256ToUint160();

    function to128(uint256 x) internal pure returns (uint128) {
        // -------------------------------o===============================>
        // -------------------------------o===============>xxxxxxxxxxxxxxxx
        if (x > type(uint128).max) {
            revert OverflowUint256ToUint128();
        }

        return uint128(x);
    }

    function to64(uint256 x) internal pure returns (uint64) {
        // -------------------------------o===============================>
        // -------------------------------o======>xxxxxxxxxxxxxxxxxxxxxxxxx
        if (x > type(uint64).max) {
            revert OverflowUint256ToUint64();
        }

        return uint64(x);
    }

    function to32(uint256 x) internal pure returns (uint32) {
        // -------------------------------o===============================>
        // -------------------------------o===>xxxxxxxxxxxxxxxxxxxxxxxxxxxx
        if (x > type(uint32).max) {
            revert OverflowUint256ToUint32();
        }

        return uint32(x);
    }

    function to160(uint256 x) internal pure returns (uint160) {
        // -------------------------------o===============================>
        // -------------------------------o==================>xxxxxxxxxxxxx
        if (x > type(uint160).max) {
            revert OverflowUint256ToUint160();
        }

        return uint160(x);
    }

    function toBytes32(uint256 x) internal pure returns (bytes32) {
        return bytes32(x);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        // -------------------------------o===============================>
        // ----<==========================o===========================>xxxx
        if (x > uint256(type(int256).max)) {
            revert OverflowUint256ToInt256();
        }

        return int256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU32 {
    error OverflowUint32ToInt32();

    function toInt(uint32 x) internal pure returns (int32) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint32(type(int32).max)) {
            revert OverflowUint32ToInt32();
        }

        return int32(x);
    }

    function to256(uint32 x) internal pure returns (uint256) {
        return uint256(x);
    }

    function to56(uint32 x) internal pure returns (uint56) {
        return uint56(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU56 {
    error OverflowUint56ToInt56();

    function toInt(uint56 x) internal pure returns (int56) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint56(type(int56).max)) {
            revert OverflowUint56ToInt56();
        }

        return int56(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU64 {
    error OverflowUint64ToInt64();

    function toInt(uint64 x) internal pure returns (int64) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint64(type(int64).max)) {
            revert OverflowUint64ToInt64();
        }

        return int64(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./SafeCast.sol";

library SetUtil {
    using SafeCastAddress for address;
    using SafeCastBytes32 for bytes32;
    using SafeCastU256 for uint256;

    // ----------------------------------------
    // Uint support
    // ----------------------------------------

    struct UintSet {
        Bytes32Set raw;
    }

    function add(UintSet storage set, uint value) internal {
        add(set.raw, value.toBytes32());
    }

    function remove(UintSet storage set, uint value) internal {
        remove(set.raw, value.toBytes32());
    }

    function replace(UintSet storage set, uint value, uint newValue) internal {
        replace(set.raw, value.toBytes32(), newValue.toBytes32());
    }

    function contains(UintSet storage set, uint value) internal view returns (bool) {
        return contains(set.raw, value.toBytes32());
    }

    function length(UintSet storage set) internal view returns (uint) {
        return length(set.raw);
    }

    function valueAt(UintSet storage set, uint position) internal view returns (uint) {
        return valueAt(set.raw, position).toUint();
    }

    function positionOf(UintSet storage set, uint value) internal view returns (uint) {
        return positionOf(set.raw, value.toBytes32());
    }

    function values(UintSet storage set) internal view returns (uint[] memory) {
        bytes32[] memory store = values(set.raw);
        uint[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // ----------------------------------------
    // Address support
    // ----------------------------------------

    struct AddressSet {
        Bytes32Set raw;
    }

    function add(AddressSet storage set, address value) internal {
        add(set.raw, value.toBytes32());
    }

    function remove(AddressSet storage set, address value) internal {
        remove(set.raw, value.toBytes32());
    }

    function replace(AddressSet storage set, address value, address newValue) internal {
        replace(set.raw, value.toBytes32(), newValue.toBytes32());
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return contains(set.raw, value.toBytes32());
    }

    function length(AddressSet storage set) internal view returns (uint) {
        return length(set.raw);
    }

    function valueAt(AddressSet storage set, uint position) internal view returns (address) {
        return valueAt(set.raw, position).toAddress();
    }

    function positionOf(AddressSet storage set, address value) internal view returns (uint) {
        return positionOf(set.raw, value.toBytes32());
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = values(set.raw);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // ----------------------------------------
    // Core bytes32 support
    // ----------------------------------------

    error PositionOutOfBounds();
    error ValueNotInSet();
    error ValueAlreadyInSet();

    struct Bytes32Set {
        bytes32[] _values;
        mapping(bytes32 => uint) _positions; // Position zero is never used.
    }

    function add(Bytes32Set storage set, bytes32 value) internal {
        if (contains(set, value)) {
            revert ValueAlreadyInSet();
        }

        set._values.push(value);
        set._positions[value] = set._values.length;
    }

    function remove(Bytes32Set storage set, bytes32 value) internal {
        uint position = set._positions[value];
        if (position == 0) {
            revert ValueNotInSet();
        }

        uint index = position - 1;
        uint lastIndex = set._values.length - 1;

        // If the element being deleted is not the last in the values,
        // move the last element to its position.
        if (index != lastIndex) {
            bytes32 lastValue = set._values[lastIndex];

            set._values[index] = lastValue;
            set._positions[lastValue] = position;
        }

        // Remove the last element in the values.
        set._values.pop();
        delete set._positions[value];
    }

    function replace(Bytes32Set storage set, bytes32 value, bytes32 newValue) internal {
        if (!contains(set, value)) {
            revert ValueNotInSet();
        }

        if (contains(set, newValue)) {
            revert ValueAlreadyInSet();
        }

        uint position = set._positions[value];
        delete set._positions[value];

        uint index = position - 1;

        set._values[index] = newValue;
        set._positions[newValue] = position;
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return set._positions[value] != 0;
    }

    function length(Bytes32Set storage set) internal view returns (uint) {
        return set._values.length;
    }

    function valueAt(Bytes32Set storage set, uint position) internal view returns (bytes32) {
        if (position == 0 || position > set._values.length) {
            revert PositionOutOfBounds();
        }

        uint index = position - 1;

        return set._values[index];
    }

    function positionOf(Bytes32Set storage set, bytes32 value) internal view returns (uint) {
        if (!contains(set, value)) {
            revert ValueNotInSet();
        }

        return set._positions[value];
    }

    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return set._values;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/*
    Reference implementations:
    * OpenZeppelin - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
*/

library StringUtil {
    function uintToString(uint value) internal pure returns (string memory) {
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
            // solhint-disable-next-line numcast/safe-cast
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module for connecting a system with other associated systems.

 * Associated systems become available to all system modules for communication and interaction, but as opposed to inter-modular communications, interactions with associated systems will require the use of `CALL`.
 *
 * Associated systems can be managed or unmanaged.
 * - Managed systems are connected via a proxy, which means that their implementation can be updated, and the system controls the execution context of the associated system. Example, an snxUSD token connected to the system, and controlled by the system.
 * - Unmanaged systems are just addresses tracked by the system, for which it has no control whatsoever. Example, Uniswap v3, Curve, etc.
 *
 * Furthermore, associated systems are typed in the AssociatedSystem utility library (See AssociatedSystem.sol):
 * - KIND_ERC20: A managed associated system specifically wrapping an ERC20 implementation.
 * - KIND_ERC721: A managed associated system specifically wrapping an ERC721 implementation.
 * - KIND_UNMANAGED: Any unmanaged associated system.
 */
interface IAssociatedSystemsModule {
    /**
     * @notice Emitted when an associated system is set.
     * @param kind The type of associated system (managed ERC20, managed ERC721, unmanaged, etc - See the AssociatedSystem util).
     * @param id The bytes32 identifier of the associated system.
     * @param proxy The main external contract address of the associated system.
     * @param impl The address of the implementation of the associated system (if not behind a proxy, will equal `proxy`).
     */
    event AssociatedSystemSet(
        bytes32 indexed kind,
        bytes32 indexed id,
        address proxy,
        address impl
    );

    /**
     * @notice Emitted when the function you are calling requires an associated system, but it
     * has not been registered
     */
    error MissingAssociatedSystem(bytes32 id);

    /**
     * @notice Creates or initializes a managed associated ERC20 token.
     * @param id The bytes32 identifier of the associated system. If the id is new to the system, it will create a new proxy for the associated system.
     * @param name The token name that will be used to initialize the proxy.
     * @param symbol The token symbol that will be used to initialize the proxy.
     * @param decimals The token decimals that will be used to initialize the proxy.
     * @param impl The ERC20 implementation of the proxy.
     */
    function initOrUpgradeToken(
        bytes32 id,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address impl
    ) external;

    /**
     * @notice Creates or initializes a managed associated ERC721 token.
     * @param id The bytes32 identifier of the associated system. If the id is new to the system, it will create a new proxy for the associated system.
     * @param name The token name that will be used to initialize the proxy.
     * @param symbol The token symbol that will be used to initialize the proxy.
     * @param uri The token uri that will be used to initialize the proxy.
     * @param impl The ERC721 implementation of the proxy.
     */
    function initOrUpgradeNft(
        bytes32 id,
        string memory name,
        string memory symbol,
        string memory uri,
        address impl
    ) external;

    /**
     * @notice Registers an unmanaged external contract in the system.
     * @param id The bytes32 identifier to use to reference the associated system.
     * @param endpoint The address of the associated system.
     *
     * Note: The system will not be able to control or upgrade the associated system, only communicate with it.
     */
    function registerUnmanagedSystem(bytes32 id, address endpoint) external;

    /**
     * @notice Retrieves an associated system.
     * @param id The bytes32 identifier used to reference the associated system.
     * @return addr The external contract address of the associated system.
     * @return kind The type of associated system (managed ERC20, managed ERC721, unmanaged, etc - See the AssociatedSystem util).
     */
    function getAssociatedSystem(bytes32 id) external view returns (address addr, bytes32 kind);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module for granular enabling and disabling of system features and functions.
 *
 * Interface functions that are controlled by a feature flag simply need to add this line to their body:
 * `FeatureFlag.ensureAccessToFeature(FLAG_ID);`
 *
 * If such a line is not present in a function, then it is not controlled by a feature flag.
 *
 * If a feature flag is set and then removed forever, consider deleting the line mentioned above from the function's body.
 */
interface IFeatureFlagModule {
    /**
     * @notice Emitted when general access has been given or removed for a feature.
     * @param feature The bytes32 id of the feature.
     * @param allowAll True if the feature was allowed for everyone and false if it is only allowed for those included in the allowlist.
     */
    event FeatureFlagAllowAllSet(bytes32 indexed feature, bool allowAll);

    /**
     * @notice Emitted when general access has been blocked for a feature.
     * @param feature The bytes32 id of the feature.
     * @param denyAll True if the feature was blocked for everyone and false if it is only allowed for those included in the allowlist or if allowAll is set to true.
     */
    event FeatureFlagDenyAllSet(bytes32 indexed feature, bool denyAll);

    /**
     * @notice Emitted when an address was given access to a feature.
     * @param feature The bytes32 id of the feature.
     * @param account The address that was given access to the feature.
     */
    event FeatureFlagAllowlistAdded(bytes32 indexed feature, address account);

    /**
     * @notice Emitted when access to a feature has been removed from an address.
     * @param feature The bytes32 id of the feature.
     * @param account The address that no longer has access to the feature.
     */
    event FeatureFlagAllowlistRemoved(bytes32 indexed feature, address account);

    /**
     * @notice Emitted when the list of addresses which can block a feature has been updated
     * @param feature The bytes32 id of the feature.
     * @param deniers The list of addresses which are allowed to block a feature
     */
    event FeatureFlagDeniersReset(bytes32 indexed feature, address[] deniers);

    /**
     * @notice Enables or disables free access to a feature.
     * @param feature The bytes32 id of the feature.
     * @param allowAll True to allow anyone to use the feature, false to fallback to the allowlist.
     */
    function setFeatureFlagAllowAll(bytes32 feature, bool allowAll) external;

    /**
     * @notice Enables or disables free access to a feature.
     * @param feature The bytes32 id of the feature.
     * @param denyAll True to allow noone to use the feature, false to fallback to the allowlist.
     */
    function setFeatureFlagDenyAll(bytes32 feature, bool denyAll) external;

    /**
     * @notice Allows an address to use a feature.
     * @dev This function does nothing if the specified account is already on the allowlist.
     * @param feature The bytes32 id of the feature.
     * @param account The address that is allowed to use the feature.
     */
    function addToFeatureFlagAllowlist(bytes32 feature, address account) external;

    /**
     * @notice Disallows an address from using a feature.
     * @dev This function does nothing if the specified account is already on the allowlist.
     * @param feature The bytes32 id of the feature.
     * @param account The address that is disallowed from using the feature.
     */
    function removeFromFeatureFlagAllowlist(bytes32 feature, address account) external;

    /**
     * @notice Sets addresses which can disable a feature (but not enable it). Overwrites any preexisting data.
     * @param feature The bytes32 id of the feature.
     * @param deniers The addresses which should have the ability to unilaterally disable the feature
     */
    function setDeniers(bytes32 feature, address[] memory deniers) external;

    /**
     * @notice Gets the list of address which can block a feature
     * @param feature The bytes32 id of the feature.
     */
    function getDeniers(bytes32 feature) external returns (address[] memory);

    /**
     * @notice Determines if the given feature is freely allowed to all users.
     * @param feature The bytes32 id of the feature.
     * @return True if anyone is allowed to use the feature, false if per-user control is used.
     */
    function getFeatureFlagAllowAll(bytes32 feature) external view returns (bool);

    /**
     * @notice Determines if the given feature is denied to all users.
     * @param feature The bytes32 id of the feature.
     * @return True if noone is allowed to use the feature.
     */
    function getFeatureFlagDenyAll(bytes32 feature) external view returns (bool);

    /**
     * @notice Returns a list of addresses that are allowed to use the specified feature.
     * @param feature The bytes32 id of the feature.
     * @return The queried list of addresses.
     */
    function getFeatureFlagAllowlist(bytes32 feature) external view returns (address[] memory);

    /**
     * @notice Determines if an address can use the specified feature.
     * @param feature The bytes32 id of the feature.
     * @param account The address that is being queried for access to the feature.
     * @return A boolean with the response to the query.
     */
    function isFeatureAllowed(bytes32 feature, address account) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC721Enumerable.sol";

/**
 * @title Module wrapping an ERC721 token implementation.
 */
interface INftModule is IERC721Enumerable {
    /**
     * @notice Returns wether the token has been initialized.
     * @return A boolean with the result of the query.
     */
    function isInitialized() external returns (bool);

    /**
     * @notice Initializes the token with name, symbol, and uri.
     */
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory uri
    ) external;

    /**
     * @notice Allows the owner to mint tokens.
     * @param to The address to receive the newly minted tokens.
     * @param tokenId The ID of the newly minted token
     */
    function mint(address to, uint tokenId) external;

    /**
     * @notice Allows the owner to mint tokens. Verifies that the receiver can receive the token
     * @param to The address to receive the newly minted token.
     * @param tokenId The ID of the newly minted token
     * @param data any data which should be sent to the receiver
     */
    function safeMint(address to, uint256 tokenId, bytes memory data) external;

    /**
     * @notice Allows the owner to burn tokens.
     * @param tokenId The token to burn
     */
    function burn(uint tokenId) external;

    /**
     * @notice Allows an address that holds tokens to provide allowance to another.
     * @param tokenId The token which should be allowed to spender
     * @param spender The address that is given allowance.
     */
    function setAllowance(uint tokenId, address spender) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module for giving a system owner based access control.
 */
// solhint-disable-next-line no-empty-blocks
interface IOwnerModule {

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";

/**
 * @title Module wrapping an ERC20 token implementation.
 */
interface ITokenModule is IERC20 {
    /**
     * @notice Returns wether the token has been initialized.
     * @return A boolean with the result of the query.
     */
    function isInitialized() external returns (bool);

    /**
     * @notice Initializes the token with name, symbol, and decimals.
     */
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) external;

    /**
     * @notice Allows the owner to mint tokens.
     * @param to The address to receive the newly minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint amount) external;

    /**
     * @notice Allows the owner to burn tokens.
     * @param to The address whose tokens will be burnt.
     * @param amount The amount of tokens to burn.
     */
    function burn(address to, uint amount) external;

    /**
     * @notice Allows an address that holds tokens to provide allowance to another.
     * @param from The address that is providing allowance.
     * @param spender The address that is given allowance.
     * @param amount The amount of allowance being given.
     */
    function setAllowance(address from, address spender, uint amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/errors/InitError.sol";
import "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import "@synthetixio/core-contracts/contracts/proxy/UUPSProxyWithOwner.sol";
import "../interfaces/IAssociatedSystemsModule.sol";

import "@synthetixio/core-contracts/contracts/interfaces/IUUPSImplementation.sol";
import "../interfaces/IOwnerModule.sol";
import "../interfaces/ITokenModule.sol";
import "../interfaces/INftModule.sol";

import "../storage/AssociatedSystem.sol";

/**
 * @title Module for connecting a system with other associated systems.
 * @dev See IAssociatedSystemsModule.
 */
contract AssociatedSystemsModule is IAssociatedSystemsModule {
    using AssociatedSystem for AssociatedSystem.Data;

    /**
     * @inheritdoc IAssociatedSystemsModule
     */
    function initOrUpgradeToken(
        bytes32 id,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address impl
    ) external override {
        OwnableStorage.onlyOwner();
        _initOrUpgradeToken(id, name, symbol, decimals, impl);
    }

    /**
     * @inheritdoc IAssociatedSystemsModule
     */
    function initOrUpgradeNft(
        bytes32 id,
        string memory name,
        string memory symbol,
        string memory uri,
        address impl
    ) external override {
        OwnableStorage.onlyOwner();
        _initOrUpgradeNft(id, name, symbol, uri, impl);
    }

    /**
     * @inheritdoc IAssociatedSystemsModule
     */
    function registerUnmanagedSystem(bytes32 id, address endpoint) external override {
        OwnableStorage.onlyOwner();
        // empty string require kind will make sure the system is either unregistered or already unmanaged
        AssociatedSystem.load(id).expectKind("");

        _setAssociatedSystem(id, AssociatedSystem.KIND_UNMANAGED, endpoint, endpoint);
    }

    /**
     * @inheritdoc IAssociatedSystemsModule
     */
    function getAssociatedSystem(
        bytes32 id
    ) external view override returns (address addr, bytes32 kind) {
        addr = AssociatedSystem.load(id).proxy;
        kind = AssociatedSystem.load(id).kind;
    }

    modifier onlyIfAssociated(bytes32 id) {
        if (address(AssociatedSystem.load(id).proxy) == address(0)) {
            revert MissingAssociatedSystem(id);
        }

        _;
    }

    function _setAssociatedSystem(bytes32 id, bytes32 kind, address proxy, address impl) internal {
        AssociatedSystem.load(id).set(proxy, impl, kind);
        emit AssociatedSystemSet(kind, id, proxy, impl);
    }

    function _upgradeToken(bytes32 id, address impl) internal {
        AssociatedSystem.Data storage store = AssociatedSystem.load(id);
        store.expectKind(AssociatedSystem.KIND_ERC20);

        store.impl = impl;

        address proxy = store.proxy;

        // tell the associated proxy to upgrade to the new implementation
        IUUPSImplementation(proxy).upgradeTo(impl);

        _setAssociatedSystem(id, AssociatedSystem.KIND_ERC20, proxy, impl);
    }

    function _upgradeNft(bytes32 id, address impl) internal {
        AssociatedSystem.Data storage store = AssociatedSystem.load(id);
        store.expectKind(AssociatedSystem.KIND_ERC721);

        store.impl = impl;

        address proxy = store.proxy;

        // tell the associated proxy to upgrade to the new implementation
        IUUPSImplementation(proxy).upgradeTo(impl);

        _setAssociatedSystem(id, AssociatedSystem.KIND_ERC721, proxy, impl);
    }

    function _initOrUpgradeToken(
        bytes32 id,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address impl
    ) internal {
        AssociatedSystem.Data storage store = AssociatedSystem.load(id);

        if (store.proxy != address(0)) {
            _upgradeToken(id, impl);
        } else {
            // create a new proxy and own it
            address proxy = address(new UUPSProxyWithOwner(impl, address(this)));

            ITokenModule(proxy).initialize(name, symbol, decimals);

            _setAssociatedSystem(id, AssociatedSystem.KIND_ERC20, proxy, impl);
        }
    }

    function _initOrUpgradeNft(
        bytes32 id,
        string memory name,
        string memory symbol,
        string memory uri,
        address impl
    ) internal {
        OwnableStorage.onlyOwner();
        AssociatedSystem.Data storage store = AssociatedSystem.load(id);

        if (store.proxy != address(0)) {
            _upgradeNft(id, impl);
        } else {
            // create a new proxy and own it
            address proxy = address(new UUPSProxyWithOwner(impl, address(this)));

            INftModule(proxy).initialize(name, symbol, uri);

            _setAssociatedSystem(id, AssociatedSystem.KIND_ERC721, proxy, impl);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import "../storage/FeatureFlag.sol";

import "../interfaces/IFeatureFlagModule.sol";

/**
 * @title Module for granular enabling and disabling of system features and functions.
 * See IFeatureFlagModule.
 */
contract FeatureFlagModule is IFeatureFlagModule {
    using SetUtil for SetUtil.AddressSet;
    using FeatureFlag for FeatureFlag.Data;

    /**
     * @inheritdoc IFeatureFlagModule
     */
    function setFeatureFlagAllowAll(bytes32 feature, bool allowAll) external override {
        OwnableStorage.onlyOwner();
        FeatureFlag.load(feature).allowAll = allowAll;

        if (allowAll) {
            FeatureFlag.load(feature).denyAll = false;
        }

        emit FeatureFlagAllowAllSet(feature, allowAll);
    }

    /**
     * @inheritdoc IFeatureFlagModule
     */
    function setFeatureFlagDenyAll(bytes32 feature, bool denyAll) external override {
        FeatureFlag.Data storage flag = FeatureFlag.load(feature);

        if (!denyAll || !flag.isDenier(msg.sender)) {
            OwnableStorage.onlyOwner();
        }

        flag.denyAll = denyAll;

        emit FeatureFlagDenyAllSet(feature, denyAll);
    }

    /**
     * @inheritdoc IFeatureFlagModule
     */
    function addToFeatureFlagAllowlist(bytes32 feature, address account) external override {
        OwnableStorage.onlyOwner();

        SetUtil.AddressSet storage permissionedAddresses = FeatureFlag
            .load(feature)
            .permissionedAddresses;

        if (!permissionedAddresses.contains(account)) {
            permissionedAddresses.add(account);
            emit FeatureFlagAllowlistAdded(feature, account);
        }
    }

    /**
     * @inheritdoc IFeatureFlagModule
     */
    function removeFromFeatureFlagAllowlist(bytes32 feature, address account) external override {
        OwnableStorage.onlyOwner();

        SetUtil.AddressSet storage permissionedAddresses = FeatureFlag
            .load(feature)
            .permissionedAddresses;

        if (permissionedAddresses.contains(account)) {
            FeatureFlag.load(feature).permissionedAddresses.remove(account);
            emit FeatureFlagAllowlistRemoved(feature, account);
        }
    }

    /**
     * @inheritdoc IFeatureFlagModule
     */
    function setDeniers(bytes32 feature, address[] memory deniers) external override {
        OwnableStorage.onlyOwner();
        FeatureFlag.Data storage flag = FeatureFlag.load(feature);

        // resize array (its really dumb how you have to do this)
        uint storageLen = flag.deniers.length;
        for (uint i = storageLen; i > deniers.length; i--) {
            flag.deniers.pop();
        }

        for (uint i = 0; i < deniers.length; i++) {
            if (i >= storageLen) {
                flag.deniers.push(deniers[i]);
            } else {
                flag.deniers[i] = deniers[i];
            }
        }

        emit FeatureFlagDeniersReset(feature, deniers);
    }

    /**
     * @inheritdoc IFeatureFlagModule
     */
    function getDeniers(bytes32 feature) external view override returns (address[] memory) {
        FeatureFlag.Data storage flag = FeatureFlag.load(feature);
        address[] memory addrs = new address[](flag.deniers.length);
        for (uint i = 0; i < addrs.length; i++) {
            addrs[i] = flag.deniers[i];
        }

        return addrs;
    }

    /**
     * @inheritdoc IFeatureFlagModule
     */
    function getFeatureFlagAllowAll(bytes32 feature) external view override returns (bool) {
        return FeatureFlag.load(feature).allowAll;
    }

    /**
     * @inheritdoc IFeatureFlagModule
     */
    function getFeatureFlagDenyAll(bytes32 feature) external view override returns (bool) {
        return FeatureFlag.load(feature).denyAll;
    }

    /**
     * @inheritdoc IFeatureFlagModule
     */
    function getFeatureFlagAllowlist(
        bytes32 feature
    ) external view override returns (address[] memory) {
        return FeatureFlag.load(feature).permissionedAddresses.values();
    }

    /**
     * @inheritdoc IFeatureFlagModule
     */
    function isFeatureAllowed(
        bytes32 feature,
        address account
    ) external view override returns (bool) {
        return FeatureFlag.hasAccess(feature, account);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/token/ERC721Enumerable.sol";
import "@synthetixio/core-contracts/contracts/utils/AddressUtil.sol";
import "@synthetixio/core-contracts/contracts/initializable/InitializableMixin.sol";
import "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import "@synthetixio/core-contracts/contracts/errors/AddressError.sol";

import "../storage/Initialized.sol";

import "../interfaces/INftModule.sol";

/**
 * @title Module wrapping an ERC721 token implementation.
 * See INftModule.
 */
contract NftModule is INftModule, ERC721Enumerable, InitializableMixin {
    bytes32 internal constant _INITIALIZED_NAME = "NftModule";

    /**
     * @inheritdoc INftModule
     */
    function isInitialized() external view returns (bool) {
        return _isInitialized();
    }

    /**
     * @inheritdoc INftModule
     */
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory uri
    ) public {
        OwnableStorage.onlyOwner();

        _initialize(tokenName, tokenSymbol, uri);
        Initialized.load(_INITIALIZED_NAME).initialized = true;
    }

    /**
     * @inheritdoc INftModule
     */
    function burn(uint256 tokenId) external override {
        OwnableStorage.onlyOwner();
        _burn(tokenId);
    }

    /**
     * @inheritdoc INftModule
     */
    function mint(address to, uint256 tokenId) external override {
        OwnableStorage.onlyOwner();
        _mint(to, tokenId);
    }

    /**
     * @inheritdoc INftModule
     */
    function safeMint(address to, uint256 tokenId, bytes memory data) external override {
        OwnableStorage.onlyOwner();
        _mint(to, tokenId);

        if (!_checkOnERC721Received(address(0), to, tokenId, data)) {
            revert InvalidTransferRecipient(to);
        }
    }

    /**
     * @inheritdoc INftModule
     */
    function setAllowance(uint tokenId, address spender) external override {
        OwnableStorage.onlyOwner();
        ERC721Storage.load().tokenApprovals[tokenId] = spender;
    }

    function _isInitialized() internal view override returns (bool) {
        return Initialized.load(_INITIALIZED_NAME).initialized;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/ownership/Ownable.sol";
import "@synthetixio/core-contracts/contracts/initializable/InitializableMixin.sol";
import "../interfaces/IOwnerModule.sol";

/**
 * @title Module for giving a system owner based access control.
 * See IOwnerModule.
 */
contract OwnerModule is Ownable, IOwnerModule {
    // solhint-disable-next-line no-empty-blocks
    constructor() Ownable(address(0)) {
        // empty intentionally
    }

    // no impl intentionally
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/proxy/UUPSImplementation.sol";
import "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";

contract UpgradeModule is UUPSImplementation {
    function upgradeTo(address newImplementation) public override {
        OwnableStorage.onlyOwner();
        _upgradeTo(newImplementation);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/ITokenModule.sol";
import "../interfaces/INftModule.sol";

library AssociatedSystem {
    struct Data {
        address proxy;
        address impl;
        bytes32 kind;
    }

    error MismatchAssociatedSystemKind(bytes32 expected, bytes32 actual);

    function load(bytes32 id) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("io.synthetix.core-modules.AssociatedSystem", id));
        assembly {
            store.slot := s
        }
    }

    bytes32 public constant KIND_ERC20 = "erc20";
    bytes32 public constant KIND_ERC721 = "erc721";
    bytes32 public constant KIND_UNMANAGED = "unmanaged";

    function getAddress(Data storage self) internal view returns (address) {
        return self.proxy;
    }

    function asToken(Data storage self) internal view returns (ITokenModule) {
        expectKind(self, KIND_ERC20);
        return ITokenModule(self.proxy);
    }

    function asNft(Data storage self) internal view returns (INftModule) {
        expectKind(self, KIND_ERC721);
        return INftModule(self.proxy);
    }

    function set(Data storage self, address proxy, address impl, bytes32 kind) internal {
        self.proxy = proxy;
        self.impl = impl;
        self.kind = kind;
    }

    function expectKind(Data storage self, bytes32 kind) internal view {
        bytes32 actualKind = self.kind;

        if (actualKind != kind && actualKind != KIND_UNMANAGED) {
            revert MismatchAssociatedSystemKind(kind, actualKind);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";

library FeatureFlag {
    using SetUtil for SetUtil.AddressSet;

    error FeatureUnavailable(bytes32 which);

    struct Data {
        bytes32 name;
        bool allowAll;
        bool denyAll;
        SetUtil.AddressSet permissionedAddresses;
        address[] deniers;
    }

    function load(bytes32 featureName) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("io.synthetix.core-modules.FeatureFlag", featureName));
        assembly {
            store.slot := s
        }
    }

    function ensureAccessToFeature(bytes32 feature) internal view {
        if (!hasAccess(feature, msg.sender)) {
            revert FeatureUnavailable(feature);
        }
    }

    function hasAccess(bytes32 feature, address value) internal view returns (bool) {
        Data storage store = FeatureFlag.load(feature);

        if (store.denyAll) {
            return false;
        }

        return store.allowAll || store.permissionedAddresses.contains(value);
    }

    function isDenier(Data storage self, address possibleDenier) internal view returns (bool) {
        for (uint i = 0; i < self.deniers.length; i++) {
            if (self.deniers[i] == possibleDenier) {
                return true;
            }
        }

        return false;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library Initialized {
    struct Data {
        bool initialized;
    }

    function load(bytes32 id) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("io.synthetix.code-modules.Initialized", id));
        assembly {
            store.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../storage/NodeOutput.sol";
import "../storage/NodeDefinition.sol";

/// @title Module for managing nodes
interface INodeModule {
    /**
     * @notice Thrown when the specified nodeId has not been registered in the system.
     */
    error NodeNotRegistered(bytes32 nodeId);

    /**
     * @notice Thrown when a node is registered without a valid definition.
     */
    error InvalidNodeDefinition(NodeDefinition.Data nodeType);

    /**
     * @notice Thrown when a node cannot be processed
     */
    error UnprocessableNode(bytes32 nodeId);

    /**
     * @notice Thrown when a node is registered with an invalid external node
     */
    error IncorrectExternalNodeInterface(address externalNode);

    /**
     * @notice Emitted when `registerNode` is called.
     * @param nodeId The id of the registered node.
     * @param nodeType The nodeType assigned to this node.
     * @param parameters The parameters assigned to this node.
     * @param parents The parents assigned to this node.
     */
    event NodeRegistered(
        bytes32 nodeId,
        NodeDefinition.NodeType nodeType,
        bytes parameters,
        bytes32[] parents
    );

    /**
     * @notice Registers a node
     * @param nodeType The nodeType assigned to this node.
     * @param parameters The parameters assigned to this node.
     * @param parents The parents assigned to this node.
     * @return The id of the registered node.
     */
    function registerNode(
        NodeDefinition.NodeType nodeType,
        bytes memory parameters,
        bytes32[] memory parents
    ) external returns (bytes32);

    /**
     * @notice Returns the ID of a node, whether or not it has been registered.
     * @param parents The parents assigned to this node.
     * @param nodeType The nodeType assigned to this node.
     * @param parameters The parameters assigned to this node.
     * @return The id of the node.
     */
    function getNodeId(
        NodeDefinition.NodeType nodeType,
        bytes memory parameters,
        bytes32[] memory parents
    ) external returns (bytes32);

    /**
     * @notice Returns a node's definition (type, parameters, and parents)
     * @param nodeId The node ID
     * @return The node's definition data
     */
    function getNode(bytes32 nodeId) external view returns (NodeDefinition.Data memory);

    /**
     * @notice Returns a node current output data
     * @param nodeId The node ID
     * @return The node's output data
     */
    function process(bytes32 nodeId) external view returns (NodeOutput.Data memory);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library NodeDefinition {
    enum NodeType {
        NONE,
        REDUCER,
        EXTERNAL,
        CHAINLINK,
        UNISWAP,
        PYTH,
        PRICE_DEVIATION_CIRCUIT_BREAKER,
        STALENESS_CIRCUIT_BREAKER
    }

    struct Data {
        NodeType nodeType;
        bytes parameters;
        bytes32[] parents;
    }

    function load(bytes32 id) internal pure returns (Data storage node) {
        bytes32 s = keccak256(abi.encode("io.synthetix.oracle-manager.Node", id));
        assembly {
            node.slot := s
        }
    }

    function create(
        Data memory nodeDefinition
    ) internal returns (NodeDefinition.Data storage node, bytes32 id) {
        id = getId(nodeDefinition);

        node = load(id);

        node.nodeType = nodeDefinition.nodeType;
        node.parameters = nodeDefinition.parameters;
        node.parents = nodeDefinition.parents;
    }

    function getId(Data memory nodeDefinition) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    nodeDefinition.nodeType,
                    nodeDefinition.parameters,
                    nodeDefinition.parents
                )
            );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library NodeOutput {
    struct Data {
        int256 price;
        uint256 timestamp;
        // solhint-disable-next-line private-vars-leading-underscore
        uint256 __slotAvailableForFutureUse1;
        // solhint-disable-next-line private-vars-leading-underscore
        uint256 __slotAvailableForFutureUse2;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/// @title Interface an aggregator needs to adhere.
interface IAggregatorV3Interface {
    /// @notice decimals used by the aggregator
    function decimals() external view returns (uint8);

    /// @notice aggregator's description
    function description() external view returns (string memory);

    /// @notice aggregator's version
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    /// @notice get's round data for requested id
    function getRoundData(
        uint80 id
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    /// @notice get's latest round data
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";

/**
 * @notice Application contracts that intend to receive CCIP messages from
 * the OffRampRouter should implement this interface.
 */
interface IAny2EVMMessageReceiverInterface {
    struct Any2EVMMessage {
        uint256 srcChainId;
        bytes sender;
        bytes data;
        IERC20[] destTokens;
        uint256[] amounts;
    }

    /**
     * @notice Called by the OffRampRouter to deliver a message
     * @param message CCIP Message
     * @dev Note ensure you check the msg.sender is the OffRampRouter
     */
    function ccipReceive(Any2EVMMessage calldata message) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";

/**
 * @notice Application contracts that intend to send messages via CCIP
 * will interact with this interface.
 */
interface IEVM2AnySubscriptionOnRampRouterInterface {
    struct EVM2AnySubscriptionMessage {
        bytes receiver; // Address of the receiver on the destination chain for EVM chains use abi.encode(destAddress).
        bytes data; // Bytes that we wish to send to the receiver
        IERC20[] tokens; // The ERC20 tokens we wish to send for EVM source chains
        uint256[] amounts; // The amount of ERC20 tokens we wish to send for EVM source chains
        uint256 gasLimit; // the gas limit for the call to the receiver for destination chains
    }

    /**
     * @notice Request a message to be sent to the destination chain
     * @param destChainId The destination chain ID
     * @param message The message payload
     */
    function ccipSend(uint256 destChainId, EVM2AnySubscriptionMessage calldata message) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC165.sol";

/// @title Interface a Market needs to adhere.
interface IMarket is IERC165 {
    /// @notice returns a human-readable name for a given market
    function name(uint128 marketId) external view returns (string memory);

    /// @notice returns amount of USD that the market would try to mint256 if everything was withdrawn
    function reportedDebt(uint128 marketId) external view returns (uint256);

    /// @notice returns the amount of collateral which should (in addition to `reportedDebt`) be prevented from withdrawing from this market
    /// if your market does not require locking, set this to `0`
    function locked(uint128 marketId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC165.sol";

/// @title Interface a reward distributor.
interface IRewardDistributor is IERC165 {
    /// @notice Returns a human-readable name for the reward distributor
    function name() external returns (string memory);

    /// @notice This function should revert if msg.sender is not the Synthetix CoreProxy address.
    /// @return whether or not the payout was executed
    function payout(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        address sender,
        uint256 amount
    ) external returns (bool);

    /// @notice Address to ERC-20 token distributed by this distributor, for display purposes only
    /// @dev Return address(0) if providing non ERC-20 rewards
    function token() external returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module for managing accounts.
 * @notice Manages the system's account token NFT. Every user will need to register an account before being able to interact with the system.
 */
interface IAccountModule {
    /**
     * @notice Thrown when the account interacting with the system is expected to be the associated account token, but is not.
     */
    error OnlyAccountTokenProxy(address origin);

    /**
     * @notice Thrown when an account attempts to renounce a permission that it didn't have.
     */
    error PermissionNotGranted(uint128 accountId, bytes32 permission, address user);

    /**
     * @notice Emitted when an account token with id `accountId` is minted to `sender`.
     * @param accountId The id of the account.
     * @param owner The address that owns the created account.
     */
    event AccountCreated(uint128 indexed accountId, address indexed owner);

    /**
     * @notice Emitted when `user` is granted `permission` by `sender` for account `accountId`.
     * @param accountId The id of the account that granted the permission.
     * @param permission The bytes32 identifier of the permission.
     * @param user The target address to whom the permission was granted.
     * @param sender The Address that granted the permission.
     */
    event PermissionGranted(
        uint128 indexed accountId,
        bytes32 indexed permission,
        address indexed user,
        address sender
    );

    /**
     * @notice Emitted when `user` has `permission` renounced or revoked by `sender` for account `accountId`.
     * @param accountId The id of the account that has had the permission revoked.
     * @param permission The bytes32 identifier of the permission.
     * @param user The target address for which the permission was revoked.
     * @param sender The address that revoked the permission.
     */
    event PermissionRevoked(
        uint128 indexed accountId,
        bytes32 indexed permission,
        address indexed user,
        address sender
    );

    /**
     * @dev Data structure for tracking each user's permissions.
     */
    struct AccountPermissions {
        /**
         * @dev The address for which all the permissions are granted.
         */
        address user;
        /**
         * @dev The array of permissions given to the associated address.
         */
        bytes32[] permissions;
    }

    /**
     * @notice Returns an array of `AccountPermission` for the provided `accountId`.
     * @param accountId The id of the account whose permissions are being retrieved.
     * @return accountPerms An array of AccountPermission objects describing the permissions granted to the account.
     */
    function getAccountPermissions(
        uint128 accountId
    ) external view returns (AccountPermissions[] memory accountPerms);

    /**
     * @notice Mints an account token with id `requestedAccountId` to `msg.sender`.
     * @param requestedAccountId The id requested for the account being created. Reverts if id already exists.
     *
     * Requirements:
     *
     * - `requestedAccountId` must not already be minted.
     *
     * Emits a {AccountCreated} event.
     */
    function createAccount(uint128 requestedAccountId) external;

    /**
     * @notice Called by AccountTokenModule to notify the system when the account token is transferred.
     * @dev Resets user permissions and assigns ownership of the account token to the new holder.
     * @param to The new holder of the account NFT.
     * @param accountId The id of the account that was just transferred.
     *
     * Requirements:
     *
     * - `msg.sender` must be the account token.
     */
    function notifyAccountTransfer(address to, uint128 accountId) external;

    /**
     * @notice Grants `permission` to `user` for account `accountId`.
     * @param accountId The id of the account that granted the permission.
     * @param permission The bytes32 identifier of the permission.
     * @param user The target address that received the permission.
     *
     * Requirements:
     *
     * - `msg.sender` must own the account token with ID `accountId` or have the "admin" permission.
     *
     * Emits a {PermissionGranted} event.
     */
    function grantPermission(uint128 accountId, bytes32 permission, address user) external;

    /**
     * @notice Revokes `permission` from `user` for account `accountId`.
     * @param accountId The id of the account that revoked the permission.
     * @param permission The bytes32 identifier of the permission.
     * @param user The target address that no longer has the permission.
     *
     * Requirements:
     *
     * - `msg.sender` must own the account token with ID `accountId` or have the "admin" permission.
     *
     * Emits a {PermissionRevoked} event.
     */
    function revokePermission(uint128 accountId, bytes32 permission, address user) external;

    /**
     * @notice Revokes `permission` from `msg.sender` for account `accountId`.
     * @param accountId The id of the account whose permission was renounced.
     * @param permission The bytes32 identifier of the permission.
     *
     * Emits a {PermissionRevoked} event.
     */
    function renouncePermission(uint128 accountId, bytes32 permission) external;

    /**
     * @notice Returns `true` if `user` has been granted `permission` for account `accountId`.
     * @param accountId The id of the account whose permission is being queried.
     * @param permission The bytes32 identifier of the permission.
     * @param user The target address whose permission is being queried.
     * @return hasPermission A boolean with the response of the query.
     */
    function hasPermission(
        uint128 accountId,
        bytes32 permission,
        address user
    ) external view returns (bool hasPermission);

    /**
     * @notice Returns `true` if `target` is authorized to `permission` for account `accountId`.
     * @param accountId The id of the account whose permission is being queried.
     * @param permission The bytes32 identifier of the permission.
     * @param target The target address whose permission is being queried.
     * @return isAuthorized A boolean with the response of the query.
     */
    function isAuthorized(
        uint128 accountId,
        bytes32 permission,
        address target
    ) external view returns (bool isAuthorized);

    /**
     * @notice Returns the address for the account token used by the module.
     * @return accountNftToken The address of the account token.
     */
    function getAccountTokenAddress() external view returns (address accountNftToken);

    /**
     * @notice Returns the address that owns a given account, as recorded by the system.
     * @param accountId The account id whose owner is being retrieved.
     * @return owner The owner of the given account id.
     */
    function getAccountOwner(uint128 accountId) external view returns (address owner);

    /**
     * @notice Returns the last unix timestamp that a permissioned action was taken with this account
     * @param accountId The account id to check
     * @return timestamp The unix timestamp of the last time a permissioned action occured with the account
     */
    function getAccountLastInteraction(uint128 accountId) external view returns (uint256 timestamp);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-modules/contracts/interfaces/INftModule.sol";

/**
 * @title Module with custom NFT logic for the account token.
 */
// solhint-disable-next-line no-empty-blocks
interface IAccountTokenModule is INftModule {

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module for associating debt with the system.
 * @notice Allows a market to associate debt to a user's existing position.
 * E.g. when migrating a position from v2 into v3's legacy market, the market first scales up everyone's debt, and then associates it to a position using this module.
 */
interface IAssociateDebtModule {
    /**
     * @notice Thrown when the specified market is not connected to the specified pool in debt association.
     */
    error NotFundedByPool(uint256 marketId, uint256 poolId);

    /**
     * @notice Thrown when a debt association would shift a position below the liquidation ratio.
     */
    error InsufficientCollateralRatio(
        uint256 collateralValue,
        uint256 debt,
        uint256 ratio,
        uint256 minRatio
    );

    /**
     * @notice Emitted when `associateDebt` is called.
     * @param marketId The id of the market to which debt was associated.
     * @param poolId The id of the pool associated to the target market.
     * @param collateralType The address of the collateral type that acts as collateral in the corresponding pool.
     * @param accountId The id of the account whose debt is being associated.
     * @param amount The amount of debt being associated with the specified account, denominated with 18 decimals of precision.
     * @param updatedDebt The total updated debt of the account, denominated with 18 decimals of precision
     */
    event DebtAssociated(
        uint128 indexed marketId,
        uint128 indexed poolId,
        address indexed collateralType,
        uint128 accountId,
        uint256 amount,
        int256 updatedDebt
    );

    /**
     * @notice Allows a market to associate debt with a specific position.
     * The specified debt will be removed from all vault participants pro-rata. After removing the debt, the amount will
     * be allocated directly to the specified account.
     * **NOTE**: if the specified account is an existing staker on the vault, their position will be included in the pro-rata
     * reduction. Ex: if there are 10 users staking 10 USD of debt on a pool, and associate debt is called with 10 USD on one of those users,
     * their debt after the operation is complete will be 19 USD. This might seem unusual, but its actually ideal behavior when
     * your market has incurred some new debt, and it wants to allocate this amount directly to a specific user. In this case, the user's
     * debt balance would increase pro rata, but then get decreased pro-rata, and then increased to the full amount on their account. All
     * other accounts would be left with no change to their debt, however.
     * @param marketId The id of the market to which debt was associated.
     * @param poolId The id of the pool associated to the target market.
     * @param collateralType The address of the collateral type that acts as collateral in the corresponding pool.
     * @param accountId The id of the account whose debt is being associated.
     * @param amount The amount of debt being associated with the specified account, denominated with 18 decimals of precision.
     * @return debtAmount The updated debt of the position, denominated with 18 decimals of precision.
     */
    function associateDebt(
        uint128 marketId,
        uint128 poolId,
        address collateralType,
        uint128 accountId,
        uint256 amount
    ) external returns (int256 debtAmount);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../storage/CollateralConfiguration.sol";

/**
 * @title Module for configuring system wide collateral.
 * @notice Allows the owner to configure collaterals at a system wide level.
 */
interface ICollateralConfigurationModule {
    /**
     * @notice Emitted when a collateral type’s configuration is created or updated.
     * @param collateralType The address of the collateral type that was just configured.
     * @param config The object with the newly configured details.
     */
    event CollateralConfigured(address indexed collateralType, CollateralConfiguration.Data config);

    /**
     * @notice Creates or updates the configuration for the given `collateralType`.
     * @param config The CollateralConfiguration object describing the new configuration.
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner of the system.
     *
     * Emits a {CollateralConfigured} event.
     *
     */
    function configureCollateral(CollateralConfiguration.Data memory config) external;

    /**
     * @notice Returns a list of detailed information pertaining to all collateral types registered in the system.
     * @dev Optionally returns only those that are currently enabled.
     * @param hideDisabled Wether to hide disabled collaterals or just return the full list of collaterals in the system.
     * @return collaterals The list of collateral configuration objects set in the system.
     */
    function getCollateralConfigurations(
        bool hideDisabled
    ) external view returns (CollateralConfiguration.Data[] memory collaterals);

    /**
     * @notice Returns detailed information pertaining the specified collateral type.
     * @param collateralType The address for the collateral whose configuration is being queried.
     * @return collateral The configuration object describing the given collateral.
     */
    function getCollateralConfiguration(
        address collateralType
    ) external view returns (CollateralConfiguration.Data memory collateral);

    /**
     * @notice Returns the current value of a specified collateral type.
     * @param collateralType The address for the collateral whose price is being queried.
     * @return priceD18 The price of the given collateral, denominated with 18 decimals of precision.
     */
    function getCollateralPrice(address collateralType) external view returns (uint256 priceD18);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../storage/CollateralLock.sol";

/**
 * @title Module for managing user collateral.
 * @notice Allows users to deposit and withdraw collateral from the system.
 */
interface ICollateralModule {
    /**
     * @notice Thrown when an interacting account does not have sufficient collateral for an operation (withdrawal, lock, etc).
     */
    error InsufficientAccountCollateral(uint256 amount);

    /**
     * @notice Emitted when `tokenAmount` of collateral of type `collateralType` is deposited to account `accountId` by `sender`.
     * @param accountId The id of the account that deposited collateral.
     * @param collateralType The address of the collateral that was deposited.
     * @param tokenAmount The amount of collateral that was deposited, denominated in the token's native decimal representation.
     * @param sender The address of the account that triggered the deposit.
     */
    event Deposited(
        uint128 indexed accountId,
        address indexed collateralType,
        uint256 tokenAmount,
        address indexed sender
    );

    /**
     * @notice Emitted when a lock is created on someone's account
     * @param accountId The id of the account that received a lock
     * @param collateralType The address of the collateral type that was locked
     * @param tokenAmount The amount of collateral that was locked, demoninated in system units (1e18)
     * @param expireTimestamp unix timestamp at which the lock is due to expire
     */
    event CollateralLockCreated(
        uint128 indexed accountId,
        address indexed collateralType,
        uint256 tokenAmount,
        uint64 expireTimestamp
    );

    /**
     * @notice Emitted when a lock is cleared from an account due to expiration
     * @param accountId The id of the account that has the expired lock
     * @param collateralType The address of the collateral type that was unlocked
     * @param tokenAmount The amount of collateral that was unlocked, demoninated in system units (1e18)
     * @param expireTimestamp unix timestamp at which the unlock is due to expire
     */
    event CollateralLockExpired(
        uint128 indexed accountId,
        address indexed collateralType,
        uint256 tokenAmount,
        uint64 expireTimestamp
    );

    /**
     * @notice Emitted when `tokenAmount` of collateral of type `collateralType` is withdrawn from account `accountId` by `sender`.
     * @param accountId The id of the account that withdrew collateral.
     * @param collateralType The address of the collateral that was withdrawn.
     * @param tokenAmount The amount of collateral that was withdrawn, denominated in the token's native decimal representation.
     * @param sender The address of the account that triggered the withdrawal.
     */
    event Withdrawn(
        uint128 indexed accountId,
        address indexed collateralType,
        uint256 tokenAmount,
        address indexed sender
    );

    /**
     * @notice Deposits `tokenAmount` of collateral of type `collateralType` into account `accountId`.
     * @dev Anyone can deposit into anyone's active account without restriction.
     * @param accountId The id of the account that is making the deposit.
     * @param collateralType The address of the token to be deposited.
     * @param tokenAmount The amount being deposited, denominated in the token's native decimal representation.
     *
     * Emits a {Deposited} event.
     */
    function deposit(uint128 accountId, address collateralType, uint256 tokenAmount) external;

    /**
     * @notice Withdraws `tokenAmount` of collateral of type `collateralType` from account `accountId`.
     * @param accountId The id of the account that is making the withdrawal.
     * @param collateralType The address of the token to be withdrawn.
     * @param tokenAmount The amount being withdrawn, denominated in the token's native decimal representation.
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner of the account, have the `ADMIN` permission, or have the `WITHDRAW` permission.
     *
     * Emits a {Withdrawn} event.
     *
     */
    function withdraw(uint128 accountId, address collateralType, uint256 tokenAmount) external;

    /**
     * @notice Returns the total values pertaining to account `accountId` for `collateralType`.
     * @param accountId The id of the account whose collateral is being queried.
     * @param collateralType The address of the collateral type whose amount is being queried.
     * @return totalDeposited The total collateral deposited in the account, denominated with 18 decimals of precision.
     * @return totalAssigned The amount of collateral in the account that is delegated to pools, denominated with 18 decimals of precision.
     * @return totalLocked The amount of collateral in the account that cannot currently be undelegated from a pool, denominated with 18 decimals of precision.
     */
    function getAccountCollateral(
        uint128 accountId,
        address collateralType
    ) external view returns (uint256 totalDeposited, uint256 totalAssigned, uint256 totalLocked);

    /**
     * @notice Returns the amount of collateral of type `collateralType` deposited with account `accountId` that can be withdrawn or delegated to pools.
     * @param accountId The id of the account whose collateral is being queried.
     * @param collateralType The address of the collateral type whose amount is being queried.
     * @return amountD18 The amount of collateral that is available for withdrawal or delegation, denominated with 18 decimals of precision.
     */
    function getAccountAvailableCollateral(
        uint128 accountId,
        address collateralType
    ) external view returns (uint256 amountD18);

    /**
     * @notice Clean expired locks from locked collateral arrays for an account/collateral type. It includes offset and items to prevent gas exhaustion. If both, offset and items, are 0 it will traverse the whole array (unlimited).
     * @param accountId The id of the account whose locks are being cleared.
     * @param collateralType The address of the collateral type to clean locks for.
     * @param offset The index of the first lock to clear.
     * @param count The number of slots to check for cleaning locks. Set to 0 to clean all locks at/after offset
     * @return cleared the number of locks that were actually expired (and therefore cleared)
     */
    function cleanExpiredLocks(
        uint128 accountId,
        address collateralType,
        uint256 offset,
        uint256 count
    ) external returns (uint cleared);

    /**
     * @notice Get a list of locks existing in account. Lists all locks in storage, even if they are expired
     * @param accountId The id of the account whose locks we want to read
     * @param collateralType The address of the collateral type for locks we want to read
     * @param offset The index of the first lock to read
     * @param count The number of slots to check for cleaning locks. Set to 0 to read all locks after offset
     */
    function getLocks(
        uint128 accountId,
        address collateralType,
        uint256 offset,
        uint256 count
    ) external view returns (CollateralLock.Data[] memory locks);

    /**
     * @notice Create a new lock on the given account. you must have `admin` permission on the specified account to create a lock.
     * @dev Collateral can be withdrawn from the system if it is not assigned or delegated to a pool. Collateral locks are an additional restriction that applies on top of that. I.e. if collateral is not assigned to a pool, but has a lock, it cannot be withdrawn.
     * @dev Collateral locks are initially intended for the Synthetix v2 to v3 migration, but may be used in the future by the Spartan Council, for example, to create and hand off accounts whose withdrawals from the system are locked for a given amount of time.
     * @param accountId The id of the account for which a lock is to be created.
     * @param collateralType The address of the collateral type for which the lock will be created.
     * @param amount The amount of collateral tokens to wrap in the lock being created, denominated with 18 decimals of precision.
     * @param expireTimestamp The date in which the lock will become clearable.
     */
    function createLock(
        uint128 accountId,
        address collateralType,
        uint256 amount,
        uint64 expireTimestamp
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module for the minting and burning of stablecoins.
 */
interface IIssueUSDModule {
    /**
     * @notice Thrown when an account does not have sufficient debt to burn USD.
     */
    error InsufficientDebt(int256 currentDebt);

    /**
     * @notice Emitted when {sender} mints {amount} of snxUSD with the specified liquidity position.
     * @param accountId The id of the account for which snxUSD was emitted.
     * @param poolId The id of the pool whose collateral was used to emit the snxUSD.
     * @param collateralType The address of the collateral that is backing up the emitted snxUSD.
     * @param amount The amount of snxUSD emitted, denominated with 18 decimals of precision.
     * @param sender The address that triggered the operation.
     */
    event UsdMinted(
        uint128 indexed accountId,
        uint128 indexed poolId,
        address collateralType,
        uint256 amount,
        address indexed sender
    );

    /**
     * @notice Emitted when {sender} burns {amount} of snxUSD with the specified liquidity position.
     * @param accountId The id of the account for which snxUSD was burned.
     * @param poolId The id of the pool whose collateral was used to emit the snxUSD.
     * @param collateralType The address of the collateral that was backing up the emitted snxUSD.
     * @param amount The amount of snxUSD burned, denominated with 18 decimals of precision.
     * @param sender The address that triggered the operation.
     */
    event UsdBurned(
        uint128 indexed accountId,
        uint128 indexed poolId,
        address collateralType,
        uint256 amount,
        address indexed sender
    );

    /**
     * @notice Mints {amount} of snxUSD with the specified liquidity position.
     * @param accountId The id of the account that is minting snxUSD.
     * @param poolId The id of the pool whose collateral will be used to back up the mint.
     * @param collateralType The address of the collateral that will be used to back up the mint.
     * @param amount The amount of snxUSD to be minted, denominated with 18 decimals of precision.
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner of the account, have the `ADMIN` permission, or have the `MINT` permission.
     * - After minting, the collateralization ratio of the liquidity position must not be below the target collateralization ratio for the corresponding collateral type.
     *
     * Emits a {UsdMinted} event.
     */
    function mintUsd(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        uint256 amount
    ) external;

    /**
     * @notice Burns {amount} of snxUSD with the specified liquidity position.
     * @param accountId The id of the account that is burning snxUSD.
     * @param poolId The id of the pool whose collateral was used to back up the snxUSD.
     * @param collateralType The address of the collateral that was used to back up the snxUSD.
     * @param amount The amount of snxUSD to be burnt, denominated with 18 decimals of precision.
     *
     * Emits a {UsdMinted} event.
     */
    function burnUsd(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        uint256 amount
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module for liquidated positions and vaults that are below the liquidation ratio.
 */
interface ILiquidationModule {
    /**
     * @notice Thrown when attempting to liquidate an account that is not eligible for liquidation.
     */
    error IneligibleForLiquidation(
        uint256 collateralValue,
        int256 debt,
        uint256 currentCRatio,
        uint256 cratio
    );

    /**
     * @notice Thrown when an entire vault instead of a single account should be liquidated.
     */
    error MustBeVaultLiquidated();

    /**
     * @notice Emitted when an account is liquidated.
     * @param accountId The id of the account that was liquidated.
     * @param poolId The pool id of the position that was liquidated.
     * @param collateralType The collateral type used in the position that was liquidated.
     * @param liquidationData The amount of collateral liquidated, debt liquidated, and collateral awarded to the liquidator.
     * @param liquidateAsAccountId Account id that will receive the rewards from the liquidation.
     * @param sender The address of the account that is triggering the liquidation.
     */
    event Liquidation(
        uint128 indexed accountId,
        uint128 indexed poolId,
        address indexed collateralType,
        LiquidationData liquidationData,
        uint128 liquidateAsAccountId,
        address sender
    );

    /**
     * @notice Emitted when a vault is liquidated.
     * @param poolId The id of the pool whose vault was liquidated.
     * @param collateralType The collateral address of the vault that was liquidated.
     * @param liquidationData The amount of collateral liquidated, debt liquidated, and collateral awarded to the liquidator.
     * @param liquidateAsAccountId Account id that will receive the rewards from the liquidation.
     * @param sender The address of the account that is triggering the liquidation.
     */
    event VaultLiquidation(
        uint128 indexed poolId,
        address indexed collateralType,
        LiquidationData liquidationData,
        uint128 liquidateAsAccountId,
        address sender
    );

    /**
     * @notice Data structure that holds liquidation information, used in events and in return statements.
     */
    struct LiquidationData {
        /**
         * @dev The debt of the position that was liquidated.
         */
        uint256 debtLiquidated;
        /**
         * @dev The collateral of the position that was liquidated.
         */
        uint256 collateralLiquidated;
        /**
         * @dev The amount rewarded in the liquidation.
         */
        uint256 amountRewarded;
    }

    /**
     * @notice Liquidates a position by distributing its debt and collateral among other positions in its vault.
     * @param accountId The id of the account whose position is to be liquidated.
     * @param poolId The id of the pool which holds the position that is to be liquidated.
     * @param collateralType The address of the collateral being used in the position that is to be liquidated.
     * @param liquidateAsAccountId Account id that will receive the rewards from the liquidation.
     * @return liquidationData Information about the position that was liquidated.
     */
    function liquidate(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        uint128 liquidateAsAccountId
    ) external returns (LiquidationData memory liquidationData);

    /**
     * @notice Liquidates an entire vault.
     * @dev Can only be done if the vault itself is under collateralized.
     * @dev LiquidateAsAccountId determines which account to deposit the seized collateral into (this is necessary particularly if the collateral in the vault is vesting).
     * @dev Will only liquidate a portion of the debt for the vault if `maxUsd` is supplied.
     * @param poolId The id of the pool whose vault is being liquidated.
     * @param collateralType The address of the collateral whose vault is being liquidated.
     * @param maxUsd The maximum amount of USD that the liquidator is willing to provide for the liquidation, denominated with 18 decimals of precision.
     * @return liquidationData Information about the vault that was liquidated.
     */
    function liquidateVault(
        uint128 poolId,
        address collateralType,
        uint128 liquidateAsAccountId,
        uint256 maxUsd
    ) external returns (LiquidationData memory liquidationData);

    /**
     * @notice Determines whether a specified position is liquidatable.
     * @param accountId The id of the account whose position is being queried for liquidation.
     * @param poolId The id of the pool whose position is being queried for liquidation.
     * @param collateralType The address of the collateral backing up the position being queried for liquidation.
     * @return canLiquidate A boolean with the response to the query.
     */
    function isPositionLiquidatable(
        uint128 accountId,
        uint128 poolId,
        address collateralType
    ) external returns (bool canLiquidate);

    /**
     * @notice Determines whether a specified vault is liquidatable.
     * @param poolId The id of the pool that owns the vault that is being queried for liquidation.
     * @param collateralType The address of the collateral being held at the vault that is being queried for liquidation.
     * @return canVaultLiquidate A boolean with the response to the query.
     */
    function isVaultLiquidatable(
        uint128 poolId,
        address collateralType
    ) external returns (bool canVaultLiquidate);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module for allowing markets to directly increase their credit capacity by providing their own collateral.
 */
interface IMarketCollateralModule {
    /**
     * @notice Thrown when a user attempts to deposit more collateral than that allowed by a market.
     */
    error InsufficientMarketCollateralDepositable(
        uint128 marketId,
        address collateralType,
        uint256 tokenAmountToDeposit
    );

    /**
     * @notice Thrown when a user attempts to withdraw more collateral from the market than what it has provided.
     */
    error InsufficientMarketCollateralWithdrawable(
        uint128 marketId,
        address collateralType,
        uint256 tokenAmountToWithdraw
    );

    /**
     * @notice Emitted when `amount` of collateral of type `collateralType` is deposited to market `marketId` by `sender`.
     * @param marketId The id of the market in which collateral was deposited.
     * @param collateralType The address of the collateral that was directly deposited in the market.
     * @param tokenAmount The amount of tokens that were deposited, denominated in the token's native decimal representation.
     * @param sender The address that triggered the deposit.
     */
    event MarketCollateralDeposited(
        uint128 indexed marketId,
        address indexed collateralType,
        uint256 tokenAmount,
        address indexed sender
    );

    /**
     * @notice Emitted when `amount` of collateral of type `collateralType` is withdrawn from market `marketId` by `sender`.
     * @param marketId The id of the market from which collateral was withdrawn.
     * @param collateralType The address of the collateral that was withdrawn from the market.
     * @param tokenAmount The amount of tokens that were withdrawn, denominated in the token's native decimal representation.
     * @param sender The address that triggered the withdrawal.
     */
    event MarketCollateralWithdrawn(
        uint128 indexed marketId,
        address indexed collateralType,
        uint256 tokenAmount,
        address indexed sender
    );

    /**
     * @notice Emitted when the system owner specifies the maximum depositable collateral of a given type in a given market.
     * @param marketId The id of the market for which the maximum was configured.
     * @param collateralType The address of the collateral for which the maximum was configured.
     * @param systemAmount The amount to which the maximum was set, denominated with 18 decimals of precision.
     * @param owner The owner of the system, which triggered the configuration change.
     */
    event MaximumMarketCollateralConfigured(
        uint128 indexed marketId,
        address indexed collateralType,
        uint256 systemAmount,
        address indexed owner
    );

    /**
     * @notice Allows a market to deposit collateral.
     * @param marketId The id of the market in which the collateral was directly deposited.
     * @param collateralType The address of the collateral that was deposited in the market.
     * @param amount The amount of collateral that was deposited, denominated in the token's native decimal representation.
     */
    function depositMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint256 amount
    ) external;

    /**
     * @notice Allows a market to withdraw collateral that it has previously deposited.
     * @param marketId The id of the market from which the collateral was withdrawn.
     * @param collateralType The address of the collateral that was withdrawn from the market.
     * @param amount The amount of collateral that was withdrawn, denominated in the token's native decimal representation.
     */
    function withdrawMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint256 amount
    ) external;

    /**
     * @notice Allow the system owner to configure the maximum amount of a given collateral type that a specified market is allowed to deposit.
     * @param marketId The id of the market for which the maximum is to be configured.
     * @param collateralType The address of the collateral for which the maximum is to be applied.
     * @param amount The amount that is to be set as the new maximum, denominated with 18 decimals of precision.
     */
    function configureMaximumMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint256 amount
    ) external;

    /**
     * @notice Return the total maximum amount of a given collateral type that a specified market is allowed to deposit.
     * @param marketId The id of the market for which the maximum is being queried.
     * @param collateralType The address of the collateral for which the maximum is being queried.
     * @return amountD18 The maximum amount of collateral set for the market, denominated with 18 decimals of precision.
     */
    function getMaximumMarketCollateral(
        uint128 marketId,
        address collateralType
    ) external returns (uint256 amountD18);

    /**
     * @notice Return the total amount of a given collateral type that a specified market has deposited.
     * @param marketId The id of the market for which the directly deposited collateral amount is being queried.
     * @param collateralType The address of the collateral for which the amount is being queried.
     * @return amountD18 The total amount of collateral of this type delegated to the market, denominated with 18 decimals of precision.
     */
    function getMarketCollateralAmount(
        uint128 marketId,
        address collateralType
    ) external returns (uint256 amountD18);

    /**
     * @notice Return the total value of collateral that a specified market has deposited.
     * @param marketId The id of the market for which the directly deposited collateral amount is being queried.
     * @return valueD18 The total value of collateral deposited by the market, denominated with 18 decimals of precision.
     */
    function getMarketCollateralValue(uint128 marketId) external returns (uint256 valueD18);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title System-wide entry point for the management of markets connected to the system.
 */
interface IMarketManagerModule {
    /**
     * @notice Thrown when a market does not have enough liquidity for a withdrawal.
     */
    error NotEnoughLiquidity(uint128 marketId, uint256 amount);

    /**
     * @notice Thrown when an attempt to register a market that does not conform to the IMarket interface is made.
     */
    error IncorrectMarketInterface(address market);

    /**
     * @notice Emitted when a new market is registered in the system.
     * @param market The address of the external market that was registered in the system.
     * @param marketId The id with which the market was registered in the system.
     * @param sender The account that trigger the registration of the market.
     */
    event MarketRegistered(
        address indexed market,
        uint128 indexed marketId,
        address indexed sender
    );

    /**
     * @notice Emitted when a market deposits snxUSD in the system.
     * @param marketId The id of the market that deposited snxUSD in the system.
     * @param target The address of the account that provided the snxUSD in the deposit.
     * @param amount The amount of snxUSD deposited in the system, denominated with 18 decimals of precision.
     * @param market The address of the external market that is depositing.
     */
    event MarketUsdDeposited(
        uint128 indexed marketId,
        address indexed target,
        uint256 amount,
        address indexed market
    );

    /**
     * @notice Emitted when a market withdraws snxUSD from the system.
     * @param marketId The id of the market that withdrew snxUSD from the system.
     * @param target The address of the account that received the snxUSD in the withdrawal.
     * @param amount The amount of snxUSD withdrawn from the system, denominated with 18 decimals of precision.
     * @param market The address of the external market that is withdrawing.
     */
    event MarketUsdWithdrawn(
        uint128 indexed marketId,
        address indexed target,
        uint256 amount,
        address indexed market
    );

    /**
     * @notice Connects an external market to the system.
     * @dev Creates a Market object to track the external market, and returns the newly created market id.
     * @param market The address of the external market that is to be registered in the system.
     * @return newMarketId The id with which the market will be registered in the system.
     */
    function registerMarket(address market) external returns (uint128 newMarketId);

    /**
     * @notice Allows an external market connected to the system to deposit USD in the system.
     * @dev The system burns the incoming USD, increases the market's credit capacity, and reduces its issuance.
     * @dev See `IMarket`.
     * @param marketId The id of the market in which snxUSD will be deposited.
     * @param target The address of the account on who's behalf the deposit will be made.
     * @param amount The amount of snxUSD to be deposited, denominated with 18 decimals of precision.
     */
    function depositMarketUsd(uint128 marketId, address target, uint256 amount) external;

    /**
     * @notice Allows an external market connected to the system to withdraw snxUSD from the system.
     * @dev The system mints the requested snxUSD (provided that the market has sufficient credit), reduces the market's credit capacity, and increases its net issuance.
     * @dev See `IMarket`.
     * @param marketId The id of the market from which snxUSD will be withdrawn.
     * @param target The address of the account that will receive the withdrawn snxUSD.
     * @param amount The amount of snxUSD to be withdraw, denominated with 18 decimals of precision.
     */
    function withdrawMarketUsd(uint128 marketId, address target, uint256 amount) external;

    /**
     * @notice Returns the total withdrawable snxUSD amount for the specified market.
     * @param marketId The id of the market whose withdrawable USD amount is being queried.
     * @return withdrawableD18 The total amount of snxUSD that the market could withdraw at the time of the query, denominated with 18 decimals of precision.
     */
    function getWithdrawableMarketUsd(
        uint128 marketId
    ) external view returns (uint256 withdrawableD18);

    /**
     * @notice Returns the net issuance of the specified market (snxUSD withdrawn - snxUSD deposited).
     * @param marketId The id of the market whose net issuance is being queried.
     * @return issuanceD18 The net issuance of the market, denominated with 18 decimals of precision.
     */
    function getMarketNetIssuance(uint128 marketId) external view returns (int128 issuanceD18);

    /**
     * @notice Returns the reported debt of the specified market.
     * @param marketId The id of the market whose reported debt is being queried.
     * @return reportedDebtD18 The market's reported debt, denominated with 18 decimals of precision.
     */
    function getMarketReportedDebt(
        uint128 marketId
    ) external view returns (uint256 reportedDebtD18);

    /**
     * @notice Returns the total debt of the specified market.
     * @param marketId The id of the market whose debt is being queried.
     * @return totalDebtD18 The total debt of the market, denominated with 18 decimals of precision.
     */
    function getMarketTotalDebt(uint128 marketId) external view returns (int256 totalDebtD18);

    /**
     * @notice Returns the total snxUSD value of the collateral for the specified market.
     * @param marketId The id of the market whose collateral is being queried.
     * @return valueD18 The market's total snxUSD value of collateral, denominated with 18 decimals of precision.
     */
    function getMarketCollateral(uint128 marketId) external view returns (uint256 valueD18);

    /**
     * @notice Returns the value per share of the debt of the specified market.
     * @dev This is not a view function, and actually updates the entire debt distribution chain.
     * @param marketId The id of the market whose debt per share is being queried.
     * @return debtPerShareD18 The market's debt per share value, denominated with 18 decimals of precision.
     */
    function getMarketDebtPerShare(uint128 marketId) external returns (int256 debtPerShareD18);

    /**
     * @notice Returns wether the capacity of the specified market is locked.
     * @param marketId The id of the market whose capacity is being queried.
     * @return isLocked A boolean that is true if the market's capacity is locked at the time of the query.
     */
    function isMarketCapacityLocked(uint128 marketId) external view returns (bool isLocked);

    /**
     * @notice Update a market's current debt registration with the system.
     * This function is provided as an escape hatch for pool griefing, preventing
     * overwhelming the system with a series of very small pools and creating high gas
     * costs to update an account.
     * @param marketId the id of the market that needs pools bumped
     * @return finishedDistributing whether or not all bumpable pools have been bumped and target price has been reached
     */
    function distributeDebtToPools(
        uint128 marketId,
        uint256 maxIter
    ) external returns (bool finishedDistributing);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module that enables calling multiple methods of the system in a single transaction.
 */
interface IMulticallModule {
    /**
     * @notice Executes multiple transaction payloads in a single transaction.
     * @dev Each transaction is executed using `delegatecall`, and targets the system address.
     * @param data Array of calldata objects, one for each function that is to be called in the system.
     * @return results Array of each `delegatecall`'s response corresponding to the incoming calldata array.
     */
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module that allows the system owner to mark official pools.
 */
interface IPoolConfigurationModule {
    /**
     * @notice Emitted when the system owner sets the preferred pool.
     * @param poolId The id of the pool that was set as preferred.
     */
    event PreferredPoolSet(uint256 poolId);

    /**
     * @notice Emitted when the system owner adds an approved pool.
     * @param poolId The id of the pool that was approved.
     */
    event PoolApprovedAdded(uint256 poolId);

    /**
     * @notice Emitted when the system owner removes an approved pool.
     * @param poolId The id of the pool that is no longer approved.
     */
    event PoolApprovedRemoved(uint256 poolId);

    /**
     * @notice Sets the unique system preferred pool.
     * @dev Note: The preferred pool does not receive any special treatment. It is only signaled as preferred here.
     * @param poolId The id of the pool that is to be set as preferred.
     */
    function setPreferredPool(uint128 poolId) external;

    /**
     * @notice Marks a pool as approved by the system owner.
     * @dev Approved pools do not receive any special treatment. They are only signaled as approved here.
     * @param poolId The id of the pool that is to be approved.
     */
    function addApprovedPool(uint128 poolId) external;

    /**
     * @notice Un-marks a pool as preferred by the system owner.
     * @param poolId The id of the pool that is to be no longer approved.
     */
    function removeApprovedPool(uint128 poolId) external;

    /**
     * @notice Retrieves the unique system preferred pool.
     * @return poolId The id of the pool that is currently set as preferred in the system.
     */
    function getPreferredPool() external view returns (uint128 poolId);

    /**
     * @notice Retrieves the pool that are approved by the system owner.
     * @return poolIds An array with all of the pool ids that are approved in the system.
     */
    function getApprovedPools() external view returns (uint256[] calldata poolIds);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../storage/MarketConfiguration.sol";

/**
 * @title Module for the creation and management of pools.
 * @dev The pool owner can be specified during creation, can be transferred, and has credentials for configuring the pool.
 */
interface IPoolModule {
    /**
     * @notice Thrown when attempting to disconnect a market whose capacity is locked, and whose removal would cause a decrease in its associated pool's credit delegation proportion.
     */
    error CapacityLocked(uint256 marketId);

    /**
     * @notice Gets fired when pool will be created.
     * @param poolId The id of the newly created pool.
     * @param owner The owner of the newly created pool.
     * @param sender The address that triggered the creation of the pool.
     */
    event PoolCreated(uint128 indexed poolId, address indexed owner, address indexed sender);

    /**
     * @notice Gets fired when pool owner proposes a new owner.
     * @param poolId The id of the pool for which the nomination ocurred.
     * @param nominatedOwner The address that was nominated as the new owner of the pool.
     * @param owner The address of the current owner of the pool.
     */
    event PoolOwnerNominated(
        uint128 indexed poolId,
        address indexed nominatedOwner,
        address indexed owner
    );

    /**
     * @notice Gets fired when pool nominee accepts nomination.
     * @param poolId The id of the pool for which the owner nomination was accepted.
     * @param owner The address of the new owner of the pool, which accepted the nomination.
     */
    event PoolOwnershipAccepted(uint128 indexed poolId, address indexed owner);

    /**
     * @notice Gets fired when pool owner revokes nomination.
     * @param poolId The id of the pool in which the nomination was revoked.
     * @param owner The current owner of the pool.
     */
    event PoolNominationRevoked(uint128 indexed poolId, address indexed owner);

    /**
     * @notice Gets fired when pool nominee renounces nomination.
     * @param poolId The id of the pool for which the owner nomination was renounced.
     * @param owner The current owner of the pool.
     */
    event PoolNominationRenounced(uint128 indexed poolId, address indexed owner);

    /**
     * @notice Gets fired when pool name changes.
     * @param poolId The id of the pool whose name was updated.
     * @param name The new name of the pool.
     * @param sender The address that triggered the rename of the pool.
     */
    event PoolNameUpdated(uint128 indexed poolId, string name, address indexed sender);

    /**
     * @notice Gets fired when pool gets configured.
     * @param poolId The id of the pool whose configuration was set.
     * @param markets Array of configuration data of the markets that were connected to the pool.
     * @param sender The address that triggered the pool configuration.
     */
    event PoolConfigurationSet(
        uint128 indexed poolId,
        MarketConfiguration.Data[] markets,
        address indexed sender
    );

    /**
     * @notice Creates a pool with the requested pool id.
     * @param requestedPoolId The requested id for the new pool. Reverts if the id is not available.
     * @param owner The address that will own the newly created pool.
     */
    function createPool(uint128 requestedPoolId, address owner) external;

    /**
     * @notice Allows the pool owner to configure the pool.
     * @dev The pool's configuration is composed of an array of MarketConfiguration objects, which describe which markets the pool provides liquidity to, in what proportion, and to what extent.
     * @dev Incoming market ids need to be provided in ascending order.
     * @param poolId The id of the pool whose configuration is being set.
     * @param marketDistribution The array of market configuration objects that define the list of markets that are connected to the system.
     */
    function setPoolConfiguration(
        uint128 poolId,
        MarketConfiguration.Data[] memory marketDistribution
    ) external;

    /**
     * @notice Retrieves the MarketConfiguration of the specified pool.
     * @param poolId The id of the pool whose configuration is being queried.
     * @return markets The array of MarketConfiguration objects that describe the pool's configuration.
     */
    function getPoolConfiguration(
        uint128 poolId
    ) external view returns (MarketConfiguration.Data[] memory markets);

    /**
     * @notice Allows the owner of the pool to set the pool's name.
     * @param poolId The id of the pool whose name is being set.
     * @param name The new name to give to the pool.
     */
    function setPoolName(uint128 poolId, string memory name) external;

    /**
     * @notice Returns the pool's name.
     * @param poolId The id of the pool whose name is being queried.
     * @return poolName The current name of the pool.
     */
    function getPoolName(uint128 poolId) external view returns (string memory poolName);

    /**
     * @notice Allows the current pool owner to nominate a new owner.
     * @param nominatedOwner The address to nominate os the new pool owner.
     * @param poolId The id whose ownership is being transferred.
     */
    function nominatePoolOwner(address nominatedOwner, uint128 poolId) external;

    /**
     * @notice After a new pool owner has been nominated, allows it to accept the nomination and thus ownership of the pool.
     * @param poolId The id of the pool for which the caller is to accept ownership.
     */
    function acceptPoolOwnership(uint128 poolId) external;

    /**
     * @notice After a new pool owner has been nominated, allows it to reject the nomination.
     * @param poolId The id of the pool for which the new owner nomination is to be revoked.
     */
    function revokePoolNomination(uint128 poolId) external;

    /**
     * @notice Allows the current nominated owner to renounce the nomination.
     * @param poolId The id of the pool for which the caller is renouncing ownership nomination.
     */
    function renouncePoolNomination(uint128 poolId) external;

    /**
     * @notice Returns the current pool owner.
     * @param poolId The id of the pool whose ownership is being queried.
     * @return owner The current owner of the pool.
     */
    function getPoolOwner(uint128 poolId) external view returns (address owner);

    /**
     * @notice Returns the current nominated pool owner.
     * @param poolId The id of the pool whose nominated owner is being queried.
     * @return nominatedOwner The current nominated owner of the pool.
     */
    function getNominatedPoolOwner(uint128 poolId) external view returns (address nominatedOwner);

    /**
     * @notice Allows the system owner (not the pool owner) to set the system-wide minimum liquidity ratio.
     * @param minLiquidityRatio The new system-wide minimum liquidity ratio, denominated with 18 decimals of precision. (100% is represented by 1 followed by 18 zeros.)
     */
    function setMinLiquidityRatio(uint256 minLiquidityRatio) external;

    /**
     * @notice Retrieves the system-wide minimum liquidity ratio.
     * @return minRatioD18 The current system-wide minimum liquidity ratio, denominated with 18 decimals of precision. (100% is represented by 1 followed by 18 zeros.)
     */
    function getMinLiquidityRatio() external view returns (uint256 minRatioD18);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module for connecting rewards distributors to vaults.
 */
interface IRewardsManagerModule {
    /**
     * @notice Emitted when a reward distributor returns `false` from `payout` indicating a problem
     * preventing the payout from being executed. In this case, it is advised to check with the
     * project maintainers, and possibly try again in the future.
     * @param distributor the distributor which originated the issue
     */
    error RewardUnavailable(address distributor);

    /**
     * @notice Emitted when the pool owner or an existing reward distributor sets up rewards for vault participants.
     * @param poolId The id of the pool on which rewards were distributed.
     * @param collateralType The collateral type of the pool on which rewards were distributed.
     * @param distributor The reward distributor associated to the rewards that were distributed.
     * @param amount The amount of rewards that were distributed.
     * @param start The date one which the rewards will begin to be claimable.
     * @param duration The time in which all of the distributed rewards will be claimable.
     */
    event RewardsDistributed(
        uint128 indexed poolId,
        address indexed collateralType,
        address distributor,
        uint256 amount,
        uint256 start,
        uint256 duration
    );

    /**
     * @notice Emitted when a vault participant claims rewards.
     * @param accountId The id of the account that claimed the rewards.
     * @param poolId The id of the pool where the rewards were claimed.
     * @param collateralType The address of the collateral used in the pool's rewards.
     * @param distributor The address of the rewards distributor associated with these rewards.
     * @param amount The amount of rewards that were claimed.
     */
    event RewardsClaimed(
        uint128 indexed accountId,
        uint128 indexed poolId,
        address indexed collateralType,
        address distributor,
        uint256 amount
    );

    /**
     * @notice Emitted when a new rewards distributor is registered.
     * @param poolId The id of the pool whose reward distributor was registered.
     * @param collateralType The address of the collateral used in the pool's rewards.
     * @param distributor The address of the newly registered reward distributor.
     */
    event RewardsDistributorRegistered(
        uint128 indexed poolId,
        address indexed collateralType,
        address indexed distributor
    );

    /**
     * @notice Emitted when an already registered rewards distributor is removed.
     * @param poolId The id of the pool whose reward distributor was registered.
     * @param collateralType The address of the collateral used in the pool's rewards.
     * @param distributor The address of the registered reward distributor.
     */
    event RewardsDistributorRemoved(
        uint128 indexed poolId,
        address indexed collateralType,
        address indexed distributor
    );

    /**
     * @notice Called by pool owner to register rewards for vault participants.
     * @param poolId The id of the pool whose rewards are to be managed by the specified distributor.
     * @param collateralType The address of the collateral used in the pool's rewards.
     * @param distributor The address of the reward distributor to be registered.
     */
    function registerRewardsDistributor(
        uint128 poolId,
        address collateralType,
        address distributor
    ) external;

    /**
     * @notice Called by pool owner to remove a registered rewards distributor for vault participants.
     * WARNING: if you remove a rewards distributor, the same address can never be re-registered again. If you
     * simply want to turn off
     * rewards, call `distributeRewards` with 0 emission. If you need to completely reset the rewards distributor
     * again, create a new rewards distributor at a new address and register the new one.
     * This function is provided since the number of rewards distributors added to an account is finite,
     * so you can remove an unused rewards distributor if need be.
     * NOTE: unclaimed rewards can still be claimed after a rewards distributor is removed (though any
     * rewards-over-time will be halted)
     * @param poolId The id of the pool whose rewards are to be managed by the specified distributor.
     * @param collateralType The address of the collateral used in the pool's rewards.
     * @param distributor The address of the reward distributor to be registered.
     */
    function removeRewardsDistributor(
        uint128 poolId,
        address collateralType,
        address distributor
    ) external;

    /**
     * @notice Called by a registered distributor to set up rewards for vault participants.
     * @dev Will revert if the caller is not a registered distributor.
     * @param poolId The id of the pool to distribute rewards to.
     * @param collateralType The address of the collateral used in the pool's rewards.
     * @param amount The amount of rewards to be distributed.
     * @param start The date at which the rewards will begin to be claimable.
     * @param duration The period after which all distributed rewards will be claimable.
     */
    function distributeRewards(
        uint128 poolId,
        address collateralType,
        uint256 amount,
        uint64 start,
        uint32 duration
    ) external;

    /**
     * @notice Allows a user with appropriate permissions to claim rewards associated with a position.
     * @param accountId The id of the account that is to claim the rewards.
     * @param poolId The id of the pool to claim rewards on.
     * @param collateralType The address of the collateral used in the pool's rewards.
     * @param distributor The address of the rewards distributor associated with the rewards being claimed.
     * @return amountClaimedD18 The amount of rewards that were available for the account and thus claimed.
     */
    function claimRewards(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        address distributor
    ) external returns (uint256 amountClaimedD18);

    /**
     * @notice For a given position, return the rewards that can currently be claimed.
     * @param poolId The id of the pool being queried.
     * @param collateralType The address of the collateral used in the pool's rewards.
     * @param accountId The id of the account whose available rewards are being queried.
     * @return claimableD18 An array of ids of the reward entries that are claimable by the position.
     * @return distributors An array with the addresses of the reward distributors associated with the claimable rewards.
     */
    function updateRewards(
        uint128 poolId,
        address collateralType,
        uint128 accountId
    ) external returns (uint256[] memory claimableD18, address[] memory distributors);

    /**
     * @notice Returns the number of individual units of amount emitted per second per share for the given poolId, collateralType, distributor vault.
     * @param poolId The id of the pool being queried.
     * @param collateralType The address of the collateral used in the pool's rewards.
     * @param distributor The address of the rewards distributor associated with the rewards in question.
     * @return rateD18 The queried rewards rate.
     */
    function getRewardRate(
        uint128 poolId,
        address collateralType,
        address distributor
    ) external view returns (uint256 rateD18);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-modules/contracts/interfaces/ITokenModule.sol";

/**
 * @title Module for managing the snxUSD token as an associated system.
 */
interface IUSDTokenModule is ITokenModule {
    /**
     * @notice Allows the core system to burn snxUSD held by the `from` address, provided that it has given allowance to `spender`.
     * @param from The address that holds the snxUSD to be burned.
     * @param spender The address to which the holder has given allowance to.
     * @param amount The amount of snxUSD to be burned, denominated with 18 decimals of precision.
     */
    function burnWithAllowance(address from, address spender, uint256 amount) external;

    /**
     * @notice Allows users to transfer tokens cross-chain using CCIP. This is disabled until _CCIP_CHAINLINK_SEND is set in UtilsModule. This is currently included for testing purposes. Functionality will change, including fee collection, as CCIP continues development.
     * @param destChainId The id of the chain where tokens are to be transferred to.
     * @param to The destination address in the target chain.
     * @param amount The amount of tokens to be transferred, denominated with 18 decimals of precision.
     * @return feesPaidD18 The amount of fees paid in the cross-chain transfer, denominated with 18 decimals of precision.
     */
    function transferCrossChain(
        uint256 destChainId,
        address to,
        uint256 amount
    ) external returns (uint256 feesPaidD18);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module with assorted utility functions.
 */
interface IUtilsModule {
    /**
     * @notice Configure CCIP addresses on the stablecoin.
     * @param ccipSend The address on this chain to which CCIP messages will be sent.
     * @param ccipReceive The address on this chain from which CCIP messages will be received.
     * @param ccipTokenPool The address where CCIP fees will be sent to when sending and receiving cross chain messages.
     */
    function registerCcip(address ccipSend, address ccipReceive, address ccipTokenPool) external;

    /**
     * @notice Configure the system's single oracle manager address.
     * @param oracleManagerAddress The address of the oracle manager.
     */
    function configureOracleManager(address oracleManagerAddress) external;

    /**
     * @notice Configure a generic value in the KV system
     * @param k the key of the value to set
     * @param v the value that the key should be set to
     */
    function setConfig(bytes32 k, bytes32 v) external;

    /**
     * @notice Read a generic value from the KV system
     * @param k the key to read
     * @return v the value set on the specified k
     */
    function getConfig(bytes32 k) external view returns (bytes32 v);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Allows accounts to delegate collateral to a pool.
 * @dev Delegation updates the account's position in the vault that corresponds to the associated pool and collateral type pair.
 * @dev A pool contains one vault for each collateral type it supports, and vaults are not shared between pools.
 */
interface IVaultModule {
    /**
     * @notice Thrown when attempting to delegate collateral to a vault with a leverage amount that is not supported by the system.
     */
    error InvalidLeverage(uint256 leverage);

    /**
     * @notice Thrown when attempting to delegate collateral to a market whose capacity is locked.
     */
    error CapacityLocked(uint256 marketId);

    /**
     * @notice Thrown when the specified new collateral amount to delegate to the vault equals the current existing amount.
     */
    error InvalidCollateralAmount();

    /**
     * @notice Emitted when {sender} updates the delegation of collateral in the specified liquidity position.
     * @param accountId The id of the account whose position was updated.
     * @param poolId The id of the pool in which the position was updated.
     * @param collateralType The address of the collateral associated to the position.
     * @param amount The new amount of the position, denominated with 18 decimals of precision.
     * @param leverage The new leverage value of the position, denominated with 18 decimals of precision.
     * @param sender The address that triggered the update of the position.
     */
    event DelegationUpdated(
        uint128 indexed accountId,
        uint128 indexed poolId,
        address collateralType,
        uint256 amount,
        uint256 leverage,
        address indexed sender
    );

    /**
     * @notice Updates an account's delegated collateral amount for the specified pool and collateral type pair.
     * @param accountId The id of the account associated with the position that will be updated.
     * @param poolId The id of the pool associated with the position.
     * @param collateralType The address of the collateral used in the position.
     * @param amount The new amount of collateral delegated in the position, denominated with 18 decimals of precision.
     * @param leverage The new leverage amount used in the position, denominated with 18 decimals of precision.
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner of the account, have the `ADMIN` permission, or have the `DELEGATE` permission.
     * - If increasing the amount delegated, it must not exceed the available collateral (`getAccountAvailableCollateral`) associated with the account.
     * - If decreasing the amount delegated, the liquidity position must have a collateralization ratio greater than the target collateralization ratio for the corresponding collateral type.
     *
     * Emits a {DelegationUpdated} event.
     */
    function delegateCollateral(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        uint256 amount,
        uint256 leverage
    ) external;

    /**
     * @notice Returns the collateralization ratio of the specified liquidity position. If debt is negative, this function will return 0.
     * @dev Call this function using `callStatic` to treat it as a view function.
     * @dev The return value is a percentage with 18 decimals places.
     * @param accountId The id of the account whose collateralization ratio is being queried.
     * @param poolId The id of the pool in which the account's position is held.
     * @param collateralType The address of the collateral used in the queried position.
     * @return ratioD18 The collateralization ratio of the position (collateral / debt), denominated with 18 decimals of precision.
     */
    function getPositionCollateralRatio(
        uint128 accountId,
        uint128 poolId,
        address collateralType
    ) external returns (uint256 ratioD18);

    /**
     * @notice Returns the debt of the specified liquidity position. Credit is expressed as negative debt.
     * @dev This is not a view function, and actually updates the entire debt distribution chain.
     * @dev Call this function using `callStatic` to treat it as a view function.
     * @param accountId The id of the account being queried.
     * @param poolId The id of the pool in which the account's position is held.
     * @param collateralType The address of the collateral used in the queried position.
     * @return debtD18 The amount of debt held by the position, denominated with 18 decimals of precision.
     */
    function getPositionDebt(
        uint128 accountId,
        uint128 poolId,
        address collateralType
    ) external returns (int256 debtD18);

    /**
     * @notice Returns the amount and value of the collateral associated with the specified liquidity position.
     * @dev Call this function using `callStatic` to treat it as a view function.
     * @dev collateralAmount is represented as an integer with 18 decimals.
     * @dev collateralValue is represented as an integer with the number of decimals specified by the collateralType.
     * @param accountId The id of the account being queried.
     * @param poolId The id of the pool in which the account's position is held.
     * @param collateralType The address of the collateral used in the queried position.
     * @return collateralAmountD18 The amount of collateral used in the position, denominated with 18 decimals of precision.
     * @return collateralValueD18 The value of collateral used in the position, denominated with 18 decimals of precision.
     */
    function getPositionCollateral(
        uint128 accountId,
        uint128 poolId,
        address collateralType
    ) external view returns (uint256 collateralAmountD18, uint256 collateralValueD18);

    /**
     * @notice Returns all information pertaining to a specified liquidity position in the vault module.
     * @param accountId The id of the account being queried.
     * @param poolId The id of the pool in which the account's position is held.
     * @param collateralType The address of the collateral used in the queried position.
     * @return collateralAmountD18 The amount of collateral used in the position, denominated with 18 decimals of precision.
     * @return collateralValueD18 The value of the collateral used in the position, denominated with 18 decimals of precision.
     * @return debtD18 The amount of debt held in the position, denominated with 18 decimals of precision.
     * @return collateralizationRatioD18 The collateralization ratio of the position (collateral / debt), denominated with 18 decimals of precision.
     **/
    function getPosition(
        uint128 accountId,
        uint128 poolId,
        address collateralType
    )
        external
        returns (
            uint256 collateralAmountD18,
            uint256 collateralValueD18,
            int256 debtD18,
            uint256 collateralizationRatioD18
        );

    /**
     * @notice Returns the total debt (or credit) that the vault is responsible for. Credit is expressed as negative debt.
     * @dev This is not a view function, and actually updates the entire debt distribution chain.
     * @dev Call this function using `callStatic` to treat it as a view function.
     * @param poolId The id of the pool that owns the vault whose debt is being queried.
     * @param collateralType The address of the collateral of the associated vault.
     * @return debtD18 The overall debt of the vault, denominated with 18 decimals of precision.
     **/
    function getVaultDebt(uint128 poolId, address collateralType) external returns (int256 debtD18);

    /**
     * @notice Returns the amount and value of the collateral held by the vault.
     * @dev Call this function using `callStatic` to treat it as a view function.
     * @dev collateralAmount is represented as an integer with 18 decimals.
     * @dev collateralValue is represented as an integer with the number of decimals specified by the collateralType.
     * @param poolId The id of the pool that owns the vault whose collateral is being queried.
     * @param collateralType The address of the collateral of the associated vault.
     * @return collateralAmountD18 The collateral amount of the vault, denominated with 18 decimals of precision.
     * @return collateralValueD18 The collateral value of the vault, denominated with 18 decimals of precision.
     */
    function getVaultCollateral(
        uint128 poolId,
        address collateralType
    ) external returns (uint256 collateralAmountD18, uint256 collateralValueD18);

    /**
     * @notice Returns the collateralization ratio of the vault. If debt is negative, this function will return 0.
     * @dev Call this function using `callStatic` to treat it as a view function.
     * @dev The return value is a percentage with 18 decimals places.
     * @param poolId The id of the pool that owns the vault whose collateralization ratio is being queried.
     * @param collateralType The address of the collateral of the associated vault.
     * @return ratioD18 The collateralization ratio of the vault, denominated with 18 decimals of precision.
     */
    function getVaultCollateralRatio(
        uint128 poolId,
        address collateralType
    ) external returns (uint256 ratioD18);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/external/IAggregatorV3Interface.sol";

contract AggregatorV3Mock is IAggregatorV3Interface {
    uint80 private _roundId;
    uint256 private _timestamp;
    uint256 private _price;

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function description() external pure override returns (string memory) {
        return "Fake price feed";
    }

    function version() external pure override returns (uint256) {
        return 3;
    }

    function mockSetCurrentPrice(uint256 currentPrice) external {
        _price = currentPrice;
        _timestamp = block.timestamp;
        _roundId++;
    }

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80
    )
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return this.latestRoundData();
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        // solhint-disable-next-line numcast/safe-cast
        return (_roundId, int256(_price), _timestamp, _timestamp, _roundId);
    }

    function setRoundId(uint80 roundId) external {
        _roundId = roundId;
    }

    function setTimestamp(uint256 timestamp) external {
        _timestamp = timestamp;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/token/ERC20.sol";

contract CollateralMock is ERC20 {
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) public {
        _initialize(tokenName, tokenSymbol, tokenDecimals);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

contract CollateralMockWithoutDecimals {
    bytes32 private constant _SLOT_ERC20_STORAGE =
        keccak256(abi.encode("io.synthetix.core-contracts.ERC20"));

    struct Data {
        string name;
        string symbol;
        mapping(address => uint256) balanceOf;
        mapping(address => mapping(address => uint256)) allowance;
        uint256 totalSupply;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = _SLOT_ERC20_STORAGE;
        assembly {
            store.slot := s
        }
    }

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    error InsufficientAllowance(uint256 required, uint256 existing);
    error InsufficientBalance(uint256 required, uint256 existing);
    error AlreadyInitialized();
    error NotInitialized();

    function initialize(string memory tokenName, string memory tokenSymbol) public {
        _initialize(tokenName, tokenSymbol);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }

    function name() external view returns (string memory) {
        return load().name;
    }

    function symbol() external view returns (string memory) {
        return load().symbol;
    }

    /**
     * @dev decimals() was intentionally removed from this mock contract.
     */

    // function decimals() external view  returns (uint8) {}

    function totalSupply() external view returns (uint256) {
        return load().totalSupply;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return load().allowance[owner][spender];
    }

    function balanceOf(address owner) public view returns (uint256) {
        return load().balanceOf[owner];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        uint256 currentAllowance = load().allowance[msg.sender][spender];
        _approve(msg.sender, spender, currentAllowance + addedValue);

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = load().allowance[msg.sender][spender];
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        return _transferFrom(from, to, amount);
    }

    function _transferFrom(address from, address to, uint256 amount) internal returns (bool) {
        Data storage store = load();

        uint256 currentAllowance = store.allowance[from][msg.sender];
        if (currentAllowance < amount) {
            revert InsufficientAllowance(amount, currentAllowance);
        }

        unchecked {
            store.allowance[from][msg.sender] -= amount;
        }

        _transfer(from, to, amount);

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        Data storage store = load();

        uint256 accountBalance = store.balanceOf[from];
        if (accountBalance < amount) {
            revert InsufficientBalance(amount, accountBalance);
        }

        // We are now sure that we can perform this operation safely
        // since it didn't revert in the previous step.
        // The total supply cannot exceed the maximum value of uint256,
        // thus we can now perform accounting operations in unchecked mode.
        unchecked {
            store.balanceOf[from] -= amount;
            store.balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        load().allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address to, uint256 amount) internal {
        Data storage store = load();

        store.totalSupply += amount;

        // No need for overflow check since it is done in the previous step
        unchecked {
            store.balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        Data storage store = load();

        uint256 accountBalance = store.balanceOf[from];
        if (accountBalance < amount) {
            revert InsufficientBalance(amount, accountBalance);
        }

        // No need for underflow check since it would have occured in the previous step
        unchecked {
            store.balanceOf[from] -= amount;
            store.totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }

    function _initialize(string memory tokenName, string memory tokenSymbol) internal {
        Data storage store = load();

        if (bytes(store.name).length > 0 || bytes(store.symbol).length > 0) {
            revert AlreadyInitialized();
        }

        store.name = tokenName;
        store.symbol = tokenSymbol;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";
import "../interfaces/external/IMarket.sol";
import "../interfaces/IMarketManagerModule.sol";
import "../interfaces/IAssociateDebtModule.sol";
import "../interfaces/IMarketCollateralModule.sol";

contract MockMarket is IMarket {
    using DecimalMath for uint256;

    uint256 private _reportedDebt;
    uint256 private _locked;
    uint256 private _price;

    address private _proxy;
    uint128 private _marketId;

    function initialize(address proxy, uint128 marketId, uint256 initialPrice) external {
        _proxy = proxy;
        _marketId = marketId;
        _price = initialPrice;
    }

    function callAssociateDebt(
        uint128 poolId,
        address collateralType,
        uint128 accountId,
        uint256 amount
    ) external {
        IAssociateDebtModule(_proxy).associateDebt(
            _marketId,
            poolId,
            collateralType,
            accountId,
            amount
        );
    }

    function buySynth(uint256 amount) external {
        _reportedDebt += amount;
        uint256 toDeposit = amount.divDecimal(_price);
        IMarketManagerModule(_proxy).depositMarketUsd(_marketId, msg.sender, toDeposit);
    }

    function sellSynth(uint256 amount) external {
        _reportedDebt -= amount;
        uint256 toDeposit = amount.divDecimal(_price);
        IMarketManagerModule(_proxy).withdrawMarketUsd(_marketId, msg.sender, toDeposit);
    }

    function depositUsd(uint256 amount) external {
        IMarketManagerModule(_proxy).depositMarketUsd(_marketId, msg.sender, amount);
    }

    function withdrawUsd(uint256 amount) external {
        IMarketManagerModule(_proxy).withdrawMarketUsd(_marketId, msg.sender, amount);
    }

    function setReportedDebt(uint256 newReportedDebt) external {
        _reportedDebt = newReportedDebt;
    }

    function setLocked(uint256 newLocked) external {
        _locked = newLocked;
    }

    function reportedDebt(uint128) external view override returns (uint256) {
        return _reportedDebt;
    }

    function name(uint128) external pure override returns (string memory) {
        return "MockMarket";
    }

    function locked(uint128) external view override returns (uint256) {
        return _locked;
    }

    function setPrice(uint256 newPrice) external {
        _price = newPrice;
    }

    function price() external view returns (uint256) {
        return _price;
    }

    function depositCollateral(address collateralType, uint256 amount) external {
        IERC20(collateralType).transferFrom(msg.sender, address(this), amount);
        IERC20(collateralType).approve(_proxy, amount);
        IMarketCollateralModule(_proxy).depositMarketCollateral(_marketId, collateralType, amount);
    }

    function withdrawCollateral(address collateralType, uint256 amount) external {
        IMarketCollateralModule(_proxy).withdrawMarketCollateral(_marketId, collateralType, amount);
        IERC20(collateralType).transfer(msg.sender, amount);
    }

    function name(uint256) external pure returns (string memory) {
        return "Mock Market";
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(IMarket).interfaceId ||
            interfaceId == this.supportsInterface.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";
import "@synthetixio/core-contracts/contracts/errors/AccessError.sol";

import "../interfaces/IRewardsManagerModule.sol";
import "../interfaces/external/IRewardDistributor.sol";

contract RewardDistributorMock is IRewardDistributor {
    address private _rewardManager;
    address private _token;
    string private _name;

    bool public shouldFailPayout;

    function initialize(address rewardManager, address token_, string memory name_) public {
        _rewardManager = rewardManager;
        _token = token_;
        _name = name_;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function token() public view override returns (address) {
        return _token;
    }

    function setShouldFailPayout(bool fail) external {
        shouldFailPayout = fail;
    }

    function payout(
        uint128,
        uint128,
        address,
        address sender,
        uint256 amount
    ) external returns (bool) {
        // IMPORTANT: In production, this function should revert if msg.sender is not the Synthetix CoreProxy address.
        if (msg.sender != _rewardManager) {
            revert AccessError.Unauthorized(msg.sender);
        }
        IERC20(_token).transfer(sender, amount);
        return !shouldFailPayout;
    }

    function distributeRewards(
        uint128 poolId,
        address collateralType,
        uint256 amount,
        uint64 start,
        uint32 duration
    ) public {
        IRewardsManagerModule(_rewardManager).distributeRewards(
            poolId,
            collateralType,
            amount,
            start,
            duration
        );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(IRewardDistributor).interfaceId ||
            interfaceId == this.supportsInterface.selector;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-modules/contracts/modules/NftModule.sol";
import "../../../contracts/interfaces/IAccountTokenModule.sol";
import "../../../contracts/interfaces/IAccountModule.sol";

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/**
 * @title Module with custom NFT logic for the account token.
 * @dev See IAccountTokenModule.
 */
contract AccountTokenModule is IAccountTokenModule, NftModule {
    using SafeCastU256 for uint256;

    /**
     * @dev Updates account RBAC storage to track the current owner of the token.
     */
    function _postTransfer(
        address, // from (unused)
        address to,
        uint256 tokenId
    ) internal virtual override {
        IAccountModule(OwnableStorage.getOwner()).notifyAccountTransfer(to, tokenId.to128());
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {AssociatedSystemsModule as BaseAssociatedSystemsModule} from "@synthetixio/core-modules/contracts/modules/AssociatedSystemsModule.sol";

/**
 * @title Module for connecting to other systems.
 * See core-modules/../AssociatedSystemsModule
 */
// solhint-disable-next-line no-empty-blocks
contract AssociatedSystemsModule is BaseAssociatedSystemsModule {

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {OwnerModule as BaseOwnerModule} from "@synthetixio/core-modules/contracts/modules/OwnerModule.sol";

/**
 * @title Module for owner based access control.
 * See core-modules/../OwnerModule
 */
// solhint-disable-next-line no-empty-blocks
contract OwnerModule is BaseOwnerModule {

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {UpgradeModule as BaseUpgradeModule} from "@synthetixio/core-modules/contracts/modules/UpgradeModule.sol";

/**
 * @title Module UUPS type upgradeability.
 * See core-modules/../UpgradeModule
 */
// solhint-disable-next-line no-empty-blocks
contract UpgradeModule is BaseUpgradeModule {

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-modules/contracts/storage/AssociatedSystem.sol";

import "../../interfaces/IAccountModule.sol";
import "../../interfaces/IAccountTokenModule.sol";
import "../../storage/Account.sol";

import "@synthetixio/core-modules/contracts/storage/FeatureFlag.sol";

/**
 * @title Module for managing accounts.
 * @dev See IAccountModule.
 */
contract AccountModule is IAccountModule {
    using SetUtil for SetUtil.AddressSet;
    using SetUtil for SetUtil.Bytes32Set;
    using AccountRBAC for AccountRBAC.Data;
    using Account for Account.Data;

    bytes32 private constant _ACCOUNT_SYSTEM = "accountNft";

    bytes32 private constant _CREATE_ACCOUNT_FEATURE_FLAG = "createAccount";

    /**
     * @inheritdoc IAccountModule
     */
    function getAccountTokenAddress() public view override returns (address) {
        return AssociatedSystem.load(_ACCOUNT_SYSTEM).proxy;
    }

    /**
     * @inheritdoc IAccountModule
     */
    function getAccountPermissions(
        uint128 accountId
    ) external view returns (AccountPermissions[] memory accountPerms) {
        AccountRBAC.Data storage accountRbac = Account.load(accountId).rbac;

        uint256 allPermissionsLength = accountRbac.permissionAddresses.length();
        accountPerms = new AccountPermissions[](allPermissionsLength);
        for (uint256 i = 1; i <= allPermissionsLength; i++) {
            address permissionAddress = accountRbac.permissionAddresses.valueAt(i);
            accountPerms[i - 1] = AccountPermissions({
                user: permissionAddress,
                permissions: accountRbac.permissions[permissionAddress].values()
            });
        }
    }

    /**
     * @inheritdoc IAccountModule
     */
    function createAccount(uint128 requestedAccountId) external override {
        FeatureFlag.ensureAccessToFeature(_CREATE_ACCOUNT_FEATURE_FLAG);
        IAccountTokenModule accountTokenModule = IAccountTokenModule(getAccountTokenAddress());
        accountTokenModule.safeMint(msg.sender, requestedAccountId, "");

        Account.create(requestedAccountId, msg.sender);

        emit AccountCreated(requestedAccountId, msg.sender);
    }

    /**
     * @inheritdoc IAccountModule
     */
    function notifyAccountTransfer(address to, uint128 accountId) external override {
        _onlyAccountToken();

        Account.Data storage account = Account.load(accountId);

        address[] memory permissionedAddresses = account.rbac.permissionAddresses.values();
        for (uint i = 0; i < permissionedAddresses.length; i++) {
            account.rbac.revokeAllPermissions(permissionedAddresses[i]);
        }

        account.rbac.setOwner(to);
    }

    /**
     * @inheritdoc IAccountModule
     */
    function hasPermission(
        uint128 accountId,
        bytes32 permission,
        address user
    ) public view override returns (bool) {
        return Account.load(accountId).rbac.hasPermission(permission, user);
    }

    /**
     * @inheritdoc IAccountModule
     */
    function isAuthorized(
        uint128 accountId,
        bytes32 permission,
        address user
    ) public view override returns (bool) {
        return Account.load(accountId).rbac.authorized(permission, user);
    }

    /**
     * @inheritdoc IAccountModule
     */
    function grantPermission(
        uint128 accountId,
        bytes32 permission,
        address user
    ) external override {
        AccountRBAC.isPermissionValid(permission);

        Account.Data storage account = Account.loadAccountAndValidatePermission(
            accountId,
            AccountRBAC._ADMIN_PERMISSION
        );

        account.rbac.grantPermission(permission, user);

        emit PermissionGranted(accountId, permission, user, msg.sender);
    }

    /**
     * @inheritdoc IAccountModule
     */
    function revokePermission(
        uint128 accountId,
        bytes32 permission,
        address user
    ) external override {
        Account.Data storage account = Account.loadAccountAndValidatePermission(
            accountId,
            AccountRBAC._ADMIN_PERMISSION
        );

        account.rbac.revokePermission(permission, user);

        emit PermissionRevoked(accountId, permission, user, msg.sender);
    }

    /**
     * @inheritdoc IAccountModule
     */
    function renouncePermission(uint128 accountId, bytes32 permission) external override {
        if (!Account.load(accountId).rbac.hasPermission(permission, msg.sender)) {
            revert PermissionNotGranted(accountId, permission, msg.sender);
        }

        Account.load(accountId).rbac.revokePermission(permission, msg.sender);

        emit PermissionRevoked(accountId, permission, msg.sender, msg.sender);
    }

    /**
     * @inheritdoc IAccountModule
     */
    function getAccountOwner(uint128 accountId) public view returns (address) {
        return Account.load(accountId).rbac.owner;
    }

    /**
     * @inheritdoc IAccountModule
     */
    function getAccountLastInteraction(uint128 accountId) external view returns (uint256) {
        return Account.load(accountId).lastInteraction;
    }

    /**
     * @dev Reverts if the caller is not the account token managed by this module.
     */
    // Note: Disabling Solidity warning, not sure why it suggests pure mutability.
    // solc-ignore-next-line func-mutability
    function _onlyAccountToken() internal view {
        if (msg.sender != address(getAccountTokenAddress())) {
            revert OnlyAccountTokenProxy(msg.sender);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../../interfaces/IAssociateDebtModule.sol";

import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import "@synthetixio/core-contracts/contracts/token/ERC20Helper.sol";
import "@synthetixio/core-contracts/contracts/errors/AccessError.sol";

import "@synthetixio/core-modules/contracts/storage/FeatureFlag.sol";

import "../../storage/Account.sol";
import "../../storage/Pool.sol";

/**
 * @title Module for associating debt with the system.
 * @dev See IAssociateDebtModule.
 */
contract AssociateDebtModule is IAssociateDebtModule {
    using DecimalMath for uint256;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using ERC20Helper for address;
    using Distribution for Distribution.Data;
    using Pool for Pool.Data;
    using Vault for Vault.Data;
    using VaultEpoch for VaultEpoch.Data;
    using CollateralConfiguration for CollateralConfiguration.Data;
    using ScalableMapping for ScalableMapping.Data;

    bytes32 private constant _USD_TOKEN = "USDToken";
    bytes32 private constant _ASSOCIATE_DEBT_FEATURE_FLAG = "associateDebt";

    /**
     * @inheritdoc IAssociateDebtModule
     */
    function associateDebt(
        uint128 marketId,
        uint128 poolId,
        address collateralType,
        uint128 accountId,
        uint256 amount
    ) external returns (int256) {
        FeatureFlag.ensureAccessToFeature(_ASSOCIATE_DEBT_FEATURE_FLAG);
        Account.exists(accountId);

        Pool.Data storage poolData = Pool.load(poolId);
        VaultEpoch.Data storage epochData = poolData.vaults[collateralType].currentEpoch();
        Market.Data storage marketData = Market.load(marketId);

        if (msg.sender != marketData.marketAddress) {
            revert AccessError.Unauthorized(msg.sender);
        }

        // The market must appear in pool configuration of the specified position
        if (!poolData.hasMarket(marketId)) {
            revert NotFundedByPool(marketId, poolId);
        }

        // Refresh latest account debt
        poolData.updateAccountDebt(collateralType, accountId);

        // Remove the debt we're about to assign to a specific position, pro-rata
        epochData.distributeDebtToAccounts(-amount.toInt());

        // Assign this debt to the specified position
        int256 updatedDebt = epochData.assignDebtToAccount(accountId, amount.toInt());

        (, uint256 actorCollateralValue) = poolData.currentAccountCollateral(
            collateralType,
            accountId
        );

        // Reverts if this debt increase would make the position liquidatable
        _verifyCollateralRatio(
            collateralType,
            updatedDebt > 0 ? updatedDebt.toUint() : 0,
            actorCollateralValue
        );

        emit DebtAssociated(marketId, poolId, collateralType, accountId, amount, updatedDebt);

        return updatedDebt;
    }

    /**
     * @dev Reverts if a collateral ratio would be liquidatable.
     */
    function _verifyCollateralRatio(
        address collateralType,
        uint256 debt,
        uint256 collateralValue
    ) internal view {
        uint256 liquidationRatio = CollateralConfiguration.load(collateralType).liquidationRatioD18;
        if (debt != 0 && collateralValue.divDecimal(debt) < liquidationRatio) {
            revert InsufficientCollateralRatio(
                collateralValue,
                debt,
                collateralValue.divDecimal(debt),
                liquidationRatio
            );
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";

import "../../interfaces/ICollateralConfigurationModule.sol";
import "../../storage/CollateralConfiguration.sol";

/**
 * @title Module for configuring system wide collateral.
 * @dev See ICollateralConfigurationModule.
 */
contract CollateralConfigurationModule is ICollateralConfigurationModule {
    using SetUtil for SetUtil.AddressSet;
    using CollateralConfiguration for CollateralConfiguration.Data;

    /**
     * @inheritdoc ICollateralConfigurationModule
     */
    function configureCollateral(CollateralConfiguration.Data memory config) external override {
        OwnableStorage.onlyOwner();

        CollateralConfiguration.set(config);

        emit CollateralConfigured(config.tokenAddress, config);
    }

    /**
     * @inheritdoc ICollateralConfigurationModule
     */
    function getCollateralConfigurations(
        bool hideDisabled
    ) external view override returns (CollateralConfiguration.Data[] memory) {
        SetUtil.AddressSet storage collateralTypes = CollateralConfiguration
            .loadAvailableCollaterals();

        uint256 numCollaterals = collateralTypes.length();
        CollateralConfiguration.Data[]
            memory filteredCollaterals = new CollateralConfiguration.Data[](numCollaterals);

        uint256 collateralsIdx;
        for (uint256 i = 1; i <= numCollaterals; i++) {
            address collateralType = collateralTypes.valueAt(i);

            CollateralConfiguration.Data storage collateral = CollateralConfiguration.load(
                collateralType
            );

            if (!hideDisabled || collateral.depositingEnabled) {
                filteredCollaterals[collateralsIdx++] = collateral;
            }
        }

        return filteredCollaterals;
    }

    /**
     * @inheritdoc ICollateralConfigurationModule
     */
    // Note: Disabling Solidity warning, not sure why it suggests pure mutability.
    // solc-ignore-next-line func-mutability
    function getCollateralConfiguration(
        address collateralType
    ) external view override returns (CollateralConfiguration.Data memory) {
        return CollateralConfiguration.load(collateralType);
    }

    /**
     * @inheritdoc ICollateralConfigurationModule
     */
    function getCollateralPrice(address collateralType) external view override returns (uint256) {
        return
            CollateralConfiguration.getCollateralPrice(
                CollateralConfiguration.load(collateralType)
            );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/token/ERC20Helper.sol";
import "@synthetixio/core-contracts/contracts/errors/ArrayError.sol";
import "@synthetixio/core-contracts/contracts/errors/ParameterError.sol";

import "../../interfaces/ICollateralModule.sol";

import "../../storage/Account.sol";
import "../../storage/CollateralConfiguration.sol";
import "../../storage/Config.sol";

import "@synthetixio/core-modules/contracts/storage/FeatureFlag.sol";

/**
 * @title Module for managing user collateral.
 * @dev See ICollateralModule.
 */
contract CollateralModule is ICollateralModule {
    using SetUtil for SetUtil.AddressSet;
    using ERC20Helper for address;
    using CollateralConfiguration for CollateralConfiguration.Data;
    using Account for Account.Data;
    using AccountRBAC for AccountRBAC.Data;
    using Collateral for Collateral.Data;
    using SafeCastU256 for uint256;

    bytes32 private constant _DEPOSIT_FEATURE_FLAG = "deposit";
    bytes32 private constant _WITHDRAW_FEATURE_FLAG = "withdraw";

    bytes32 private constant _CONFIG_TIMEOUT_WITHDRAW = "accountTimeoutWithdraw";

    /**
     * @inheritdoc ICollateralModule
     */
    function deposit(
        uint128 accountId,
        address collateralType,
        uint256 tokenAmount
    ) external override {
        FeatureFlag.ensureAccessToFeature(_DEPOSIT_FEATURE_FLAG);
        CollateralConfiguration.collateralEnabled(collateralType);
        Account.exists(accountId);

        Account.Data storage account = Account.load(accountId);

        address depositFrom = msg.sender;

        address self = address(this);

        uint256 allowance = IERC20(collateralType).allowance(depositFrom, self);
        if (allowance < tokenAmount) {
            revert IERC20.InsufficientAllowance(tokenAmount, allowance);
        }

        collateralType.safeTransferFrom(depositFrom, self, tokenAmount);

        account.collaterals[collateralType].increaseAvailableCollateral(
            CollateralConfiguration.load(collateralType).convertTokenToSystemAmount(tokenAmount)
        );

        emit Deposited(accountId, collateralType, tokenAmount, msg.sender);
    }

    /**
     * @inheritdoc ICollateralModule
     */
    function withdraw(
        uint128 accountId,
        address collateralType,
        uint256 tokenAmount
    ) external override {
        FeatureFlag.ensureAccessToFeature(_WITHDRAW_FEATURE_FLAG);
        Account.Data storage account = Account.loadAccountAndValidatePermissionAndTimeout(
            accountId,
            AccountRBAC._WITHDRAW_PERMISSION,
            uint256(Config.read(_CONFIG_TIMEOUT_WITHDRAW))
        );

        uint256 tokenAmountD18 = CollateralConfiguration
            .load(collateralType)
            .convertTokenToSystemAmount(tokenAmount);

        (uint256 totalDeposited, uint256 totalAssigned, uint256 totalLocked) = account
            .getCollateralTotals(collateralType);

        // The amount that cannot be withdrawn from the protocol is the max of either
        // locked collateral or delegated collateral.
        uint256 unavailableCollateral = totalLocked > totalAssigned ? totalLocked : totalAssigned;

        uint256 availableForWithdrawal = totalDeposited - unavailableCollateral;
        if (tokenAmountD18 > availableForWithdrawal) {
            revert InsufficientAccountCollateral(tokenAmountD18);
        }

        account.collaterals[collateralType].decreaseAvailableCollateral(tokenAmountD18);

        collateralType.safeTransfer(msg.sender, tokenAmount);

        emit Withdrawn(accountId, collateralType, tokenAmount, msg.sender);
    }

    /**
     * @inheritdoc ICollateralModule
     */
    function getAccountCollateral(
        uint128 accountId,
        address collateralType
    )
        external
        view
        override
        returns (uint256 totalDeposited, uint256 totalAssigned, uint256 totalLocked)
    {
        return Account.load(accountId).getCollateralTotals(collateralType);
    }

    /**
     * @inheritdoc ICollateralModule
     */
    function getAccountAvailableCollateral(
        uint128 accountId,
        address collateralType
    ) public view override returns (uint256) {
        return Account.load(accountId).collaterals[collateralType].amountAvailableForDelegationD18;
    }

    /**
     * @inheritdoc ICollateralModule
     */
    function cleanExpiredLocks(
        uint128 accountId,
        address collateralType,
        uint256 offset,
        uint256 count
    ) external override returns (uint cleared) {
        CollateralLock.Data[] storage locks = Account
            .load(accountId)
            .collaterals[collateralType]
            .locks;

        uint64 currentTime = block.timestamp.to64();

        uint len = locks.length;

        if (offset >= len) {
            return 0;
        }

        if (count == 0 || offset + count >= len) {
            count = len - offset;
        }

        uint index = offset;
        for (uint i = 0; i < count; i++) {
            if (locks[index].lockExpirationTime <= currentTime) {
                emit CollateralLockExpired(
                    accountId,
                    collateralType,
                    locks[index].amountD18,
                    locks[index].lockExpirationTime
                );

                locks[index] = locks[locks.length - 1];
                locks.pop();
            } else {
                index++;
            }
        }

        return count + offset - index;
    }

    /**
     * @inheritdoc ICollateralModule
     */
    function getLocks(
        uint128 accountId,
        address collateralType,
        uint256 offset,
        uint256 count
    ) external view override returns (CollateralLock.Data[] memory locks) {
        CollateralLock.Data[] storage storageLocks = Account
            .load(accountId)
            .collaterals[collateralType]
            .locks;
        uint len = storageLocks.length;

        if (count == 0 || offset + count >= len) {
            count = offset < len ? len - offset : 0;
        }

        locks = new CollateralLock.Data[](count);

        for (uint i = 0; i < count; i++) {
            locks[i] = storageLocks[offset + i];
        }
    }

    /**
     * @inheritdoc ICollateralModule
     */
    function createLock(
        uint128 accountId,
        address collateralType,
        uint256 amount,
        uint64 expireTimestamp
    ) external override {
        Account.Data storage account = Account.loadAccountAndValidatePermission(
            accountId,
            AccountRBAC._ADMIN_PERMISSION
        );

        (uint256 totalDeposited, , uint256 totalLocked) = account.getCollateralTotals(
            collateralType
        );

        if (expireTimestamp <= block.timestamp) {
            revert ParameterError.InvalidParameter("expireTimestamp", "must be in the future");
        }

        if (amount == 0) {
            revert ParameterError.InvalidParameter("amount", "must be nonzero");
        }

        if (amount > totalDeposited - totalLocked) {
            revert InsufficientAccountCollateral(amount);
        }

        account.collaterals[collateralType].locks.push(
            CollateralLock.Data(amount.to128(), expireTimestamp)
        );

        emit CollateralLockCreated(accountId, collateralType, amount, expireTimestamp);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {FeatureFlagModule as BaseFeatureFlagModule} from "@synthetixio/core-modules/contracts/modules/FeatureFlagModule.sol";

/**
 * @title Module that allows disabling certain system features.
 *
 * Users will not be able to interact with certain functions associated to disabled features.
 */
// solhint-disable-next-line no-empty-blocks
contract FeatureFlagModule is BaseFeatureFlagModule {

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../../interfaces/IIssueUSDModule.sol";

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "@synthetixio/core-modules/contracts/storage/AssociatedSystem.sol";

import "../../storage/Account.sol";
import "../../storage/CollateralConfiguration.sol";

import "@synthetixio/core-modules/contracts/storage/FeatureFlag.sol";

/**
 * @title Module for the minting and burning of stablecoins.
 * @dev See IIssueUSDModule.
 */
contract IssueUSDModule is IIssueUSDModule {
    using Account for Account.Data;
    using AccountRBAC for AccountRBAC.Data;
    using AssociatedSystem for AssociatedSystem.Data;
    using Pool for Pool.Data;
    using CollateralConfiguration for CollateralConfiguration.Data;
    using Vault for Vault.Data;
    using VaultEpoch for VaultEpoch.Data;
    using Distribution for Distribution.Data;
    using ScalableMapping for ScalableMapping.Data;

    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;

    bytes32 private constant _USD_TOKEN = "USDToken";

    bytes32 private constant _MINT_FEATURE_FLAG = "mintUsd";
    bytes32 private constant _BURN_FEATURE_FLAG = "burnUsd";

    /**
     * @inheritdoc IIssueUSDModule
     */
    function mintUsd(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        uint256 amount
    ) external override {
        FeatureFlag.ensureAccessToFeature(_MINT_FEATURE_FLAG);
        Account.loadAccountAndValidatePermission(accountId, AccountRBAC._MINT_PERMISSION);

        // disabled collateralType cannot be used for minting
        CollateralConfiguration.collateralEnabled(collateralType);

        Pool.Data storage pool = Pool.loadExisting(poolId);

        int256 debt = pool.updateAccountDebt(collateralType, accountId);
        int256 newDebt = debt + amount.toInt();

        // Ensure minting stablecoins is increasing the debt of the position
        if (newDebt <= debt) {
            revert ParameterError.InvalidParameter(
                "newDebt",
                "should be greater than current debt"
            );
        }

        // If the resulting debt of the account is greater than zero, ensure that the resulting c-ratio is sufficient
        (, uint256 collateralValue) = pool.currentAccountCollateral(collateralType, accountId);
        if (newDebt > 0) {
            CollateralConfiguration.load(collateralType).verifyIssuanceRatio(
                newDebt.toUint(),
                collateralValue
            );
        }

        VaultEpoch.Data storage epoch = Pool.load(poolId).vaults[collateralType].currentEpoch();

        // Increase the debt of the position
        epoch.assignDebtToAccount(accountId, amount.toInt());

        // Decrease the credit available in the vault
        pool.recalculateVaultCollateral(collateralType);

        // Mint stablecoins to the sender
        AssociatedSystem.load(_USD_TOKEN).asToken().mint(msg.sender, amount);

        emit UsdMinted(accountId, poolId, collateralType, amount, msg.sender);
    }

    /**
     * @inheritdoc IIssueUSDModule
     */
    function burnUsd(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        uint256 amount
    ) external override {
        FeatureFlag.ensureAccessToFeature(_BURN_FEATURE_FLAG);
        Pool.Data storage pool = Pool.load(poolId);

        // Retrieve current position debt
        int256 debt = pool.updateAccountDebt(collateralType, accountId);

        // Ensure the position can't burn if it already has no debt
        if (debt <= 0) {
            revert InsufficientDebt(debt);
        }

        // Only allow burning the total debt of the position
        if (debt < amount.toInt()) {
            amount = debt.toUint();
        }

        // Burn the stablecoins
        AssociatedSystem.load(_USD_TOKEN).asToken().burn(msg.sender, amount);

        VaultEpoch.Data storage epoch = Pool.load(poolId).vaults[collateralType].currentEpoch();

        // Decrease the debt of the position
        epoch.assignDebtToAccount(accountId, -amount.toInt());

        // Increase the credit available in the vault
        pool.recalculateVaultCollateral(collateralType);

        emit UsdBurned(accountId, poolId, collateralType, amount, msg.sender);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../../interfaces/ILiquidationModule.sol";

import "../../storage/Account.sol";

import "@synthetixio/core-modules/contracts/storage/AssociatedSystem.sol";

import "@synthetixio/core-contracts/contracts/errors/ParameterError.sol";
import "@synthetixio/core-contracts/contracts/token/ERC20Helper.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "@synthetixio/core-modules/contracts/storage/FeatureFlag.sol";

/**
 * @title Module for liquidated positions and vaults that are below the liquidation ratio.
 * @dev See ILiquidationModule.
 */
contract LiquidationModule is ILiquidationModule {
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using DecimalMath for uint256;
    using ERC20Helper for address;
    using AssociatedSystem for AssociatedSystem.Data;
    using CollateralConfiguration for CollateralConfiguration.Data;
    using Collateral for Collateral.Data;
    using Pool for Pool.Data;
    using Vault for Vault.Data;
    using VaultEpoch for VaultEpoch.Data;
    using Distribution for Distribution.Data;
    using ScalableMapping for ScalableMapping.Data;

    bytes32 private constant _USD_TOKEN = "USDToken";

    bytes32 private constant _LIQUIDATE_FEATURE_FLAG = "liquidate";
    bytes32 private constant _LIQUIDATE_VAULT_FEATURE_FLAG = "liquidateVault";

    /**
     * @inheritdoc ILiquidationModule
     */
    function liquidate(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        uint128 liquidateAsAccountId
    ) external override returns (LiquidationData memory liquidationData) {
        FeatureFlag.ensureAccessToFeature(_LIQUIDATE_FEATURE_FLAG);
        // Ensure the account receiving rewards exists
        Account.exists(liquidateAsAccountId);

        Pool.Data storage pool = Pool.load(poolId);
        CollateralConfiguration.Data storage collateralConfig = CollateralConfiguration.load(
            collateralType
        );
        VaultEpoch.Data storage epoch = pool.vaults[collateralType].currentEpoch();

        int256 rawDebt = pool.updateAccountDebt(collateralType, accountId);
        (uint256 collateralAmount, uint256 collateralValue) = pool.currentAccountCollateral(
            collateralType,
            accountId
        );
        liquidationData.collateralLiquidated = collateralAmount;

        // Verify whether the position is eligible for liquidation
        if (rawDebt <= 0 || !_isLiquidatable(collateralType, rawDebt, collateralValue)) {
            revert IneligibleForLiquidation(
                collateralValue,
                rawDebt,
                rawDebt <= 0 ? 0 : collateralValue.divDecimal(rawDebt.toUint()),
                collateralConfig.liquidationRatioD18
            );
        }

        liquidationData.debtLiquidated = rawDebt.toUint();

        uint256 liquidatedAccountShares = epoch.accountsDebtDistribution.getActorShares(
            accountId.toBytes32()
        );
        if (epoch.accountsDebtDistribution.totalSharesD18 == liquidatedAccountShares) {
            // will be left with 0 shares, which can't be socialized
            revert MustBeVaultLiquidated();
        }

        // Although amountRewarded is the minimum to delegate to a vault, this value may increase in the future
        liquidationData.amountRewarded = collateralConfig.liquidationRewardD18;
        if (liquidationData.amountRewarded >= epoch.collateralAmounts.totalAmount()) {
            // vault is too small to be liquidated socialized
            revert MustBeVaultLiquidated();
        }

        // This will clear the user's account the same way as if they had withdrawn normally
        epoch.updateAccountPosition(accountId, 0, 0);

        // Distribute the liquidated collateral among other positions in the vault, minus the reward amount
        epoch.collateralAmounts.scale(
            liquidationData.collateralLiquidated.toInt() - liquidationData.amountRewarded.toInt()
        );

        // Remove the debt assigned to the liquidated account
        epoch.assignDebtToAccount(accountId, -liquidationData.debtLiquidated.toInt());

        // Distribute this debt among other accounts in the vault
        epoch.distributeDebtToAccounts(liquidationData.debtLiquidated.toInt());

        // The collateral is reduced by `amountRewarded`, so we need to reduce the stablecoins capacity available to the markets
        pool.recalculateVaultCollateral(collateralType);

        // Send amountRewarded to the specified account
        Account.load(liquidateAsAccountId).collaterals[collateralType].increaseAvailableCollateral(
            liquidationData.amountRewarded
        );

        emit Liquidation(
            accountId,
            poolId,
            collateralType,
            liquidationData,
            liquidateAsAccountId,
            msg.sender
        );
    }

    /**
     * @inheritdoc ILiquidationModule
     */
    function liquidateVault(
        uint128 poolId,
        address collateralType,
        uint128 liquidateAsAccountId,
        uint256 maxUsd
    ) external override returns (LiquidationData memory liquidationData) {
        FeatureFlag.ensureAccessToFeature(_LIQUIDATE_VAULT_FEATURE_FLAG);
        // Ensure the account receiving collateral exists
        Account.exists(liquidateAsAccountId);

        // The liquidator must provide at least some stablecoins to repay debt
        if (maxUsd == 0) {
            revert ParameterError.InvalidParameter("maxUsd", "must be higher than 0");
        }

        Pool.Data storage pool = Pool.load(poolId);
        CollateralConfiguration.Data storage collateralConfig = CollateralConfiguration.load(
            collateralType
        );
        Vault.Data storage vault = pool.vaults[collateralType];

        // Retrieve the collateral and the debt of the vault
        int256 rawVaultDebt = pool.currentVaultDebt(collateralType);
        (, uint256 collateralValue) = pool.currentVaultCollateral(collateralType);

        // Verify whether the vault is eligible for liquidation
        if (!_isLiquidatable(collateralType, rawVaultDebt, collateralValue)) {
            revert IneligibleForLiquidation(
                collateralValue,
                rawVaultDebt,
                rawVaultDebt > 0 ? collateralValue.divDecimal(rawVaultDebt.toUint()) : 0,
                collateralConfig.liquidationRatioD18
            );
        }

        uint256 vaultDebt = rawVaultDebt.toUint();

        if (vaultDebt <= maxUsd) {
            // Conduct a full vault liquidation
            liquidationData.debtLiquidated = vaultDebt;

            // Burn all of the stablecoins necessary to clear the debt of this vault
            AssociatedSystem.load(_USD_TOKEN).asToken().burn(msg.sender, vaultDebt);

            // Provide all of the collateral to the liquidator
            liquidationData.collateralLiquidated = vault
                .currentEpoch()
                .collateralAmounts
                .totalAmount();

            // Increment the epoch counter
            pool.resetVault(collateralType);
        } else {
            // Conduct a partial vault liquidation
            liquidationData.debtLiquidated = maxUsd;

            // Burn all of the stablecoins provided by the liquidator
            AssociatedSystem.load(_USD_TOKEN).asToken().burn(msg.sender, maxUsd);

            VaultEpoch.Data storage epoch = vault.currentEpoch();

            // Provide the proportional amount of collateral to the liquidator
            liquidationData.collateralLiquidated =
                (epoch.collateralAmounts.totalAmount() * liquidationData.debtLiquidated) /
                vaultDebt;

            // Reduce the debt of the remaining positions in the vault
            epoch.distributeDebtToAccounts(-liquidationData.debtLiquidated.toInt());

            // Reduce the collateral of the remaining positions in the vault
            epoch.collateralAmounts.scale(-liquidationData.collateralLiquidated.toInt());
        }

        // Send liquidationData.collateralLiquidated to the specified account
        Account.load(liquidateAsAccountId).collaterals[collateralType].increaseAvailableCollateral(
            liquidationData.collateralLiquidated
        );
        liquidationData.amountRewarded = liquidationData.collateralLiquidated;

        emit VaultLiquidation(
            poolId,
            collateralType,
            liquidationData,
            liquidateAsAccountId,
            msg.sender
        );
    }

    /**
     * @dev Returns whether a combination of debt and credit is liquidatable for a specified collateral type
     */
    function _isLiquidatable(
        address collateralType,
        int256 debt,
        uint256 collateralValue
    ) internal view returns (bool) {
        if (debt <= 0) {
            return false;
        }
        return
            collateralValue.divDecimal(debt.toUint()) <
            CollateralConfiguration.load(collateralType).liquidationRatioD18;
    }

    /**
     * @inheritdoc ILiquidationModule
     */
    function isPositionLiquidatable(
        uint128 accountId,
        uint128 poolId,
        address collateralType
    ) external override returns (bool) {
        Pool.Data storage pool = Pool.load(poolId);
        int256 rawDebt = pool.updateAccountDebt(collateralType, accountId);
        (, uint256 collateralValue) = pool.currentAccountCollateral(collateralType, accountId);
        return rawDebt >= 0 && _isLiquidatable(collateralType, rawDebt, collateralValue);
    }

    /**
     * @inheritdoc ILiquidationModule
     */
    function isVaultLiquidatable(
        uint128 poolId,
        address collateralType
    ) external override returns (bool) {
        Pool.Data storage pool = Pool.load(poolId);
        int256 rawVaultDebt = pool.currentVaultDebt(collateralType);
        (, uint256 collateralValue) = pool.currentVaultCollateral(collateralType);
        return rawVaultDebt >= 0 && _isLiquidatable(collateralType, rawVaultDebt, collateralValue);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import "@synthetixio/core-contracts/contracts/token/ERC20Helper.sol";

import "../../interfaces/IMarketCollateralModule.sol";
import "../../storage/Market.sol";

import "@synthetixio/core-modules/contracts/storage/FeatureFlag.sol";

/**
 * @title Module for allowing markets to directly increase their credit capacity by providing their own collateral.
 * @dev See IMarketCollateralModule.
 */
contract MarketCollateralModule is IMarketCollateralModule {
    using SafeCastU256 for uint256;
    using ERC20Helper for address;
    using CollateralConfiguration for CollateralConfiguration.Data;
    using Market for Market.Data;

    bytes32 private constant _DEPOSIT_MARKET_COLLATERAL_FEATURE_FLAG = "depositMarketCollateral";
    bytes32 private constant _WITHDRAW_MARKET_COLLATERAL_FEATURE_FLAG = "withdrawMarketCollateral";

    /**
     * @inheritdoc IMarketCollateralModule
     */
    function depositMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint256 tokenAmount
    ) public override {
        FeatureFlag.ensureAccessToFeature(_DEPOSIT_MARKET_COLLATERAL_FEATURE_FLAG);
        Market.Data storage marketData = Market.load(marketId);

        // Ensure the sender is the market address associated with the specified marketId
        if (msg.sender != marketData.marketAddress) {
            revert AccessError.Unauthorized(msg.sender);
        }

        uint256 systemAmount = CollateralConfiguration
            .load(collateralType)
            .convertTokenToSystemAmount(tokenAmount);

        uint256 maxDepositable = marketData.maximumDepositableD18[collateralType];
        uint256 depositedCollateralEntryIndex = _findOrCreateDepositEntryIndex(
            marketData,
            collateralType
        );
        Market.DepositedCollateral storage collateralEntry = marketData.depositedCollateral[
            depositedCollateralEntryIndex
        ];

        // Ensure that depositing this amount will not exceed the maximum amount allowed for the market
        if (collateralEntry.amountD18 + systemAmount > maxDepositable)
            revert InsufficientMarketCollateralDepositable(marketId, collateralType, tokenAmount);

        // Account for the collateral and transfer it into the system.
        collateralEntry.amountD18 += systemAmount;
        collateralType.safeTransferFrom(marketData.marketAddress, address(this), tokenAmount);

        emit MarketCollateralDeposited(marketId, collateralType, tokenAmount, msg.sender);
    }

    /**
     * @inheritdoc IMarketCollateralModule
     */
    function withdrawMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint256 tokenAmount
    ) public override {
        FeatureFlag.ensureAccessToFeature(_WITHDRAW_MARKET_COLLATERAL_FEATURE_FLAG);
        Market.Data storage marketData = Market.load(marketId);

        uint256 systemAmount = CollateralConfiguration
            .load(collateralType)
            .convertTokenToSystemAmount(tokenAmount);

        // Ensure the sender is the market address associated with the specified marketId
        if (msg.sender != marketData.marketAddress) revert AccessError.Unauthorized(msg.sender);

        uint256 depositedCollateralEntryIndex = _findOrCreateDepositEntryIndex(
            marketData,
            collateralType
        );
        Market.DepositedCollateral storage collateralEntry = marketData.depositedCollateral[
            depositedCollateralEntryIndex
        ];

        // Ensure that the market is not withdrawing more collateral than it has deposited
        if (systemAmount > collateralEntry.amountD18) {
            revert InsufficientMarketCollateralWithdrawable(marketId, collateralType, tokenAmount);
        }

        // Account for transferring out collateral
        collateralEntry.amountD18 -= systemAmount;

        // Ensure that the market is not withdrawing collateral such that it results in a negative getWithdrawableMarketUsd
        int256 newWithdrawableMarketUsd = marketData.creditCapacityD18 +
            marketData.getDepositedCollateralValue().toInt();
        if (newWithdrawableMarketUsd < 0) {
            revert InsufficientMarketCollateralWithdrawable(marketId, collateralType, tokenAmount);
        }

        // Transfer the collateral to the market
        collateralType.safeTransfer(marketData.marketAddress, tokenAmount);

        emit MarketCollateralWithdrawn(marketId, collateralType, tokenAmount, msg.sender);
    }

    /**
     * @dev Returns the index of the relevant deposited collateral entry for the given market and collateral type.
     */
    function _findOrCreateDepositEntryIndex(
        Market.Data storage marketData,
        address collateralType
    ) internal returns (uint256 depositedCollateralEntryIndex) {
        Market.DepositedCollateral[] storage depositedCollateral = marketData.depositedCollateral;
        for (uint256 i = 0; i < depositedCollateral.length; i++) {
            Market.DepositedCollateral storage depositedCollateralEntry = depositedCollateral[i];
            if (depositedCollateralEntry.collateralType == collateralType) {
                return i;
            }
        }

        // If this function hasn't returned an index yet, create a new deposited collateral entry and return its index.
        marketData.depositedCollateral.push(Market.DepositedCollateral(collateralType, 0));
        return marketData.depositedCollateral.length - 1;
    }

    /**
     * @inheritdoc IMarketCollateralModule
     */
    function configureMaximumMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint256 amount
    ) external override {
        OwnableStorage.onlyOwner();

        Market.Data storage marketData = Market.load(marketId);
        marketData.maximumDepositableD18[collateralType] = amount;

        emit MaximumMarketCollateralConfigured(marketId, collateralType, amount, msg.sender);
    }

    /**
     * @inheritdoc IMarketCollateralModule
     */
    function getMarketCollateralAmount(
        uint128 marketId,
        address collateralType
    ) external view override returns (uint256 collateralAmountD18) {
        Market.Data storage marketData = Market.load(marketId);
        Market.DepositedCollateral[] storage depositedCollateral = marketData.depositedCollateral;
        for (uint256 i = 0; i < depositedCollateral.length; i++) {
            Market.DepositedCollateral storage depositedCollateralEntry = depositedCollateral[i];
            if (depositedCollateralEntry.collateralType == collateralType) {
                return depositedCollateralEntry.amountD18;
            }
        }
    }

    /**
     * @inheritdoc IMarketCollateralModule
     */
    function getMarketCollateralValue(uint128 marketId) external view override returns (uint256) {
        return Market.load(marketId).getDepositedCollateralValue();
    }

    /**
     * @inheritdoc IMarketCollateralModule
     */
    function getMaximumMarketCollateral(
        uint128 marketId,
        address collateralType
    ) external view override returns (uint256) {
        Market.Data storage marketData = Market.load(marketId);
        return marketData.maximumDepositableD18[collateralType];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../../interfaces/IMarketManagerModule.sol";
import "../../interfaces/IUSDTokenModule.sol";
import "../../interfaces/external/IMarket.sol";

import "@synthetixio/core-contracts/contracts/errors/AccessError.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import "@synthetixio/core-contracts/contracts/utils/ERC165Helper.sol";

import "../../storage/Market.sol";
import "../../storage/MarketCreator.sol";

import "@synthetixio/core-modules/contracts/storage/AssociatedSystem.sol";
import "@synthetixio/core-modules/contracts/storage/FeatureFlag.sol";

/**
 * @title System-wide entry point for the management of markets connected to the system.
 * @dev See IMarketManagerModule.
 */
contract MarketManagerModule is IMarketManagerModule {
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using Market for Market.Data;
    using AssociatedSystem for AssociatedSystem.Data;

    bytes32 private constant _USD_TOKEN = "USDToken";
    bytes32 private constant _MARKET_FEATURE_FLAG = "registerMarket";
    bytes32 private constant _DEPOSIT_MARKET_FEATURE_FLAG = "depositMarketUsd";
    bytes32 private constant _WITHDRAW_MARKET_FEATURE_FLAG = "withdrawMarketUsd";

    /**
     * @inheritdoc IMarketManagerModule
     */
    function registerMarket(address market) external override returns (uint128 marketId) {
        FeatureFlag.ensureAccessToFeature(_MARKET_FEATURE_FLAG);

        if (!ERC165Helper.safeSupportsInterface(market, type(IMarket).interfaceId)) {
            revert IncorrectMarketInterface(market);
        }

        marketId = MarketCreator.create(market).id;

        emit MarketRegistered(market, marketId, msg.sender);

        return marketId;
    }

    /**
     * @inheritdoc IMarketManagerModule
     */
    function getWithdrawableMarketUsd(uint128 marketId) public view override returns (uint256) {
        int256 withdrawable = Market.load(marketId).creditCapacityD18 +
            Market.load(marketId).getDepositedCollateralValue().toInt();

        return withdrawable < 0 ? 0 : withdrawable.toUint();
    }

    /**
     * @inheritdoc IMarketManagerModule
     */
    function getMarketNetIssuance(uint128 marketId) external view override returns (int128) {
        return Market.load(marketId).netIssuanceD18;
    }

    /**
     * @inheritdoc IMarketManagerModule
     */
    function getMarketReportedDebt(uint128 marketId) external view override returns (uint256) {
        return Market.load(marketId).getReportedDebt();
    }

    /**
     * @inheritdoc IMarketManagerModule
     */
    function getMarketCollateral(uint128 marketId) external view override returns (uint256) {
        return Market.load(marketId).poolsDebtDistribution.totalSharesD18;
    }

    /**
     * @inheritdoc IMarketManagerModule
     */
    function getMarketTotalDebt(uint128 marketId) external view override returns (int256) {
        return Market.load(marketId).totalDebt();
    }

    /**
     * @inheritdoc IMarketManagerModule
     */
    function getMarketDebtPerShare(uint128 marketId) external override returns (int256) {
        Market.Data storage market = Market.load(marketId);

        market.distributeDebtToPools(999999999);

        return market.getDebtPerShare();
    }

    /**
     * @inheritdoc IMarketManagerModule
     */
    function isMarketCapacityLocked(uint128 marketId) external view override returns (bool) {
        return Market.load(marketId).isCapacityLocked();
    }

    /**
     * @inheritdoc IMarketManagerModule
     */
    function depositMarketUsd(uint128 marketId, address target, uint256 amount) external override {
        FeatureFlag.ensureAccessToFeature(_DEPOSIT_MARKET_FEATURE_FLAG);
        Market.Data storage market = Market.load(marketId);

        // Call must come from the market itself.
        if (msg.sender != market.marketAddress) revert AccessError.Unauthorized(msg.sender);

        // verify if the market is authorized to burn the USD for the target
        ITokenModule usdToken = AssociatedSystem.load(_USD_TOKEN).asToken();

        // Adjust accounting.
        market.creditCapacityD18 += amount.toInt().to128();
        market.netIssuanceD18 -= amount.toInt().to128();

        // Burn the incoming USD.
        // Note: Instead of burning, we could transfer USD to and from the MarketManager,
        // but minting and burning takes the USD out of circulation,
        // which doesn't affect `totalSupply`, thus simplifying accounting.
        IUSDTokenModule(address(usdToken)).burnWithAllowance(target, msg.sender, amount);

        emit MarketUsdDeposited(marketId, target, amount, msg.sender);
    }

    /**
     * @inheritdoc IMarketManagerModule
     */
    function withdrawMarketUsd(uint128 marketId, address target, uint256 amount) external override {
        FeatureFlag.ensureAccessToFeature(_WITHDRAW_MARKET_FEATURE_FLAG);
        Market.Data storage marketData = Market.load(marketId);

        // Call must come from the market itself.
        if (msg.sender != marketData.marketAddress) revert AccessError.Unauthorized(msg.sender);

        // Ensure that the market's balance allows for this withdrawal.
        if (amount > getWithdrawableMarketUsd(marketId))
            revert NotEnoughLiquidity(marketId, amount);

        // Adjust accounting.
        marketData.creditCapacityD18 -= amount.toInt().to128();
        marketData.netIssuanceD18 += amount.toInt().to128();

        // Mint the requested USD.
        AssociatedSystem.load(_USD_TOKEN).asToken().mint(target, amount);

        emit MarketUsdWithdrawn(marketId, target, amount, msg.sender);
    }

    /**
     * @inheritdoc IMarketManagerModule
     */
    function distributeDebtToPools(
        uint128 marketId,
        uint256 maxIter
    ) external override returns (bool) {
        return Market.load(marketId).distributeDebtToPools(maxIter);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../../interfaces/IMulticallModule.sol";

/**
 * @title Module that enables calling multiple methods of the system in a single transaction.
 * @dev See IMulticallModule.
 * @dev Implementation adapted from https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol
 */
contract MulticallModule is IMulticallModule {
    /**
     * @inheritdoc IMulticallModule
     */
    function multicall(
        bytes[] calldata data
    ) public payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 6 lines from https://ethereum.stackexchange.com/a/83577
                // solhint-disable-next-line reason-string
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";

import "../../interfaces/IPoolConfigurationModule.sol";
import "../../storage/SystemPoolConfiguration.sol";

import "../../storage/Pool.sol";

/**
 * @title Module that allows the system owner to mark official pools.
 * @dev See IPoolConfigurationModule.
 */
contract PoolConfigurationModule is IPoolConfigurationModule {
    using SetUtil for SetUtil.UintSet;

    using Pool for Pool.Data;

    /**
     * @inheritdoc IPoolConfigurationModule
     */
    function setPreferredPool(uint128 poolId) external override {
        OwnableStorage.onlyOwner();
        Pool.loadExisting(poolId);

        SystemPoolConfiguration.load().preferredPool = poolId;

        emit PreferredPoolSet(poolId);
    }

    /**
     * @inheritdoc IPoolConfigurationModule
     */
    function getPreferredPool() external view override returns (uint128) {
        return SystemPoolConfiguration.load().preferredPool;
    }

    /**
     * @inheritdoc IPoolConfigurationModule
     */
    function addApprovedPool(uint128 poolId) external override {
        OwnableStorage.onlyOwner();
        Pool.loadExisting(poolId);

        SystemPoolConfiguration.load().approvedPools.add(poolId);

        emit PoolApprovedAdded(poolId);
    }

    /**
     * @inheritdoc IPoolConfigurationModule
     */
    function removeApprovedPool(uint128 poolId) external override {
        OwnableStorage.onlyOwner();
        Pool.loadExisting(poolId);

        SystemPoolConfiguration.load().approvedPools.remove(poolId);

        emit PoolApprovedRemoved(poolId);
    }

    /**
     * @inheritdoc IPoolConfigurationModule
     */
    function getApprovedPools() external view override returns (uint256[] memory) {
        return SystemPoolConfiguration.load().approvedPools.values();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import "@synthetixio/core-contracts/contracts/errors/AccessError.sol";
import "@synthetixio/core-contracts/contracts/errors/AddressError.sol";
import "@synthetixio/core-contracts/contracts/errors/ParameterError.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "@synthetixio/core-modules/contracts/storage/FeatureFlag.sol";

import "../../interfaces/IPoolModule.sol";
import "../../storage/Pool.sol";

/**
 * @title Module for the creation and management of pools.
 * @dev See IPoolModule.
 */
contract PoolModule is IPoolModule {
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using DecimalMath for uint256;
    using Pool for Pool.Data;
    using Market for Market.Data;

    bytes32 private constant _POOL_FEATURE_FLAG = "createPool";

    /**
     * @inheritdoc IPoolModule
     */
    function createPool(uint128 requestedPoolId, address owner) external override {
        FeatureFlag.ensureAccessToFeature(_POOL_FEATURE_FLAG);

        if (owner == address(0)) {
            revert AddressError.ZeroAddress();
        }

        Pool.create(requestedPoolId, owner);

        emit PoolCreated(requestedPoolId, owner, msg.sender);
    }

    /**
     * @inheritdoc IPoolModule
     */
    function nominatePoolOwner(address nominatedOwner, uint128 poolId) external override {
        Pool.onlyPoolOwner(poolId, msg.sender);

        Pool.load(poolId).nominatedOwner = nominatedOwner;

        emit PoolOwnerNominated(poolId, nominatedOwner, msg.sender);
    }

    /**
     * @inheritdoc IPoolModule
     */
    function acceptPoolOwnership(uint128 poolId) external override {
        Pool.Data storage pool = Pool.load(poolId);

        if (pool.nominatedOwner != msg.sender) {
            revert AccessError.Unauthorized(msg.sender);
        }

        pool.owner = msg.sender;
        pool.nominatedOwner = address(0);

        emit PoolOwnershipAccepted(poolId, msg.sender);
    }

    /**
     * @inheritdoc IPoolModule
     */
    function revokePoolNomination(uint128 poolId) external override {
        Pool.onlyPoolOwner(poolId, msg.sender);

        Pool.load(poolId).nominatedOwner = address(0);

        emit PoolNominationRevoked(poolId, msg.sender);
    }

    /**
     * @inheritdoc IPoolModule
     */
    function renouncePoolNomination(uint128 poolId) external override {
        Pool.Data storage pool = Pool.load(poolId);

        if (pool.nominatedOwner != msg.sender) {
            revert AccessError.Unauthorized(msg.sender);
        }

        pool.nominatedOwner = address(0);

        emit PoolNominationRenounced(poolId, msg.sender);
    }

    /**
     * @inheritdoc IPoolModule
     */
    function getPoolOwner(uint128 poolId) external view override returns (address) {
        return Pool.load(poolId).owner;
    }

    /**
     * @inheritdoc IPoolModule
     */
    function getNominatedPoolOwner(uint128 poolId) external view override returns (address) {
        return Pool.load(poolId).nominatedOwner;
    }

    /**
     * @inheritdoc IPoolModule
     */
    function setPoolConfiguration(
        uint128 poolId,
        MarketConfiguration.Data[] memory newMarketConfigurations
    ) external override {
        Pool.Data storage pool = Pool.loadExisting(poolId);
        Pool.onlyPoolOwner(poolId, msg.sender);

        // Update each market's pro-rata liquidity and collect accumulated debt into the pool's debt distribution.
        // Note: This follows the same pattern as Pool.recalculateVaultCollateral(),
        // where we need to distribute the debt, adjust the market configurations and distribute again.
        pool.distributeDebtToVaults();

        // Identify markets that need to be removed or verified later for being locked.
        (
            uint128[] memory potentiallyLockedMarkets,
            uint128[] memory removedMarkets
        ) = _analyzePoolConfigurationChange(pool, newMarketConfigurations);

        // Replace existing market configurations with the new ones.
        // (May leave old configurations at the end of the array if the new array is shorter).
        uint256 i = 0;
        uint256 totalWeight = 0;
        // Iterate up to the shorter length.
        uint256 len = newMarketConfigurations.length < pool.marketConfigurations.length
            ? newMarketConfigurations.length
            : pool.marketConfigurations.length;
        for (; i < len; i++) {
            pool.marketConfigurations[i] = newMarketConfigurations[i];
            totalWeight += newMarketConfigurations[i].weightD18;
        }

        // If the old array was shorter, push the new elements in.
        for (; i < newMarketConfigurations.length; i++) {
            pool.marketConfigurations.push(newMarketConfigurations[i]);
            totalWeight += newMarketConfigurations[i].weightD18;
        }

        // If the old array was longer, truncate it.
        uint256 popped = pool.marketConfigurations.length - i;
        for (i = 0; i < popped; i++) {
            pool.marketConfigurations.pop();
        }

        // Rebalance all markets that need to be removed.
        for (i = 0; i < removedMarkets.length && removedMarkets[i] != 0; i++) {
            Market.rebalancePools(removedMarkets[i], poolId, 0, 0);
        }

        pool.totalWeightsD18 = totalWeight.to128();

        // Distribute debt again because the unused credit capacity has been updated, and this information needs to be propagated immediately.
        pool.distributeDebtToVaults();

        // The credit delegation proportion of the pool can only stay the same, or increase,
        // so prevent the removal of markets whose capacity is locked.
        // Note: This check is done here because it needs to happen after removed markets are rebalanced.
        for (i = 0; i < potentiallyLockedMarkets.length && potentiallyLockedMarkets[i] != 0; i++) {
            if (Market.load(potentiallyLockedMarkets[i]).isCapacityLocked()) {
                revert CapacityLocked(potentiallyLockedMarkets[i]);
            }
        }

        emit PoolConfigurationSet(poolId, newMarketConfigurations, msg.sender);
    }

    /**
     * @inheritdoc IPoolModule
     */
    function getPoolConfiguration(
        uint128 poolId
    ) external view override returns (MarketConfiguration.Data[] memory) {
        Pool.Data storage pool = Pool.load(poolId);

        MarketConfiguration.Data[] memory marketConfigurations = new MarketConfiguration.Data[](
            pool.marketConfigurations.length
        );

        for (uint256 i = 0; i < pool.marketConfigurations.length; i++) {
            marketConfigurations[i] = pool.marketConfigurations[i];
        }

        return marketConfigurations;
    }

    /**
     * @inheritdoc IPoolModule
     */
    function setPoolName(uint128 poolId, string memory name) external override {
        Pool.Data storage pool = Pool.loadExisting(poolId);
        Pool.onlyPoolOwner(poolId, msg.sender);

        pool.name = name;

        emit PoolNameUpdated(poolId, name, msg.sender);
    }

    /**
     * @inheritdoc IPoolModule
     */
    function getPoolName(uint128 poolId) external view override returns (string memory poolName) {
        return Pool.load(poolId).name;
    }

    /**
     * @inheritdoc IPoolModule
     */
    function setMinLiquidityRatio(uint256 minLiquidityRatio) external override {
        OwnableStorage.onlyOwner();

        SystemPoolConfiguration.load().minLiquidityRatioD18 = minLiquidityRatio;
    }

    /**
     * @inheritdoc IPoolModule
     */
    function getMinLiquidityRatio() external view override returns (uint256) {
        return SystemPoolConfiguration.load().minLiquidityRatioD18;
    }

    /**
     * @dev Compares a new pool configuration with the existing one,
     * and returns information about markets that need to be removed, or whose capacity might be locked.
     *
     * Note: Stack too deep errors prevent the use of local variables to improve code readability here.
     */
    function _analyzePoolConfigurationChange(
        Pool.Data storage pool,
        MarketConfiguration.Data[] memory newMarketConfigurations
    )
        internal
        view
        returns (uint128[] memory potentiallyLockedMarkets, uint128[] memory removedMarkets)
    {
        uint256 oldIdx = 0;
        uint256 potentiallyLockedMarketsIdx = 0;
        uint256 removedMarketsIdx = 0;
        uint128 lastMarketId = 0;

        potentiallyLockedMarkets = new uint128[](pool.marketConfigurations.length);
        removedMarkets = new uint128[](pool.marketConfigurations.length);

        // First we need the total weight of the new distribution.
        uint256 totalWeightD18 = 0;
        for (uint256 i = 0; i < newMarketConfigurations.length; i++) {
            totalWeightD18 += newMarketConfigurations[i].weightD18;
        }

        // Now, iterate through the incoming market configurations, and compare with them with the existing ones.
        for (uint256 newIdx = 0; newIdx < newMarketConfigurations.length; newIdx++) {
            // Reject duplicate market ids,
            // AND ensure that they are provided in ascending order.
            if (newMarketConfigurations[newIdx].marketId <= lastMarketId) {
                revert ParameterError.InvalidParameter(
                    "markets",
                    "must be supplied in strictly ascending order"
                );
            }
            lastMarketId = newMarketConfigurations[newIdx].marketId;

            // Reject markets with no weight.
            if (newMarketConfigurations[newIdx].weightD18 == 0) {
                revert ParameterError.InvalidParameter("weights", "weight must be non-zero");
            }

            // Note: The following blocks of code compare the incoming market (at newIdx) to an existing market (at oldIdx).
            // newIdx increases once per iteration in the for loop, but oldIdx may increase multiple times if certain conditions are met.

            // If the market id of newIdx is greater than any of the old market ids,
            // consider all the old ones removed and mark them for post verification (increases oldIdx for each).
            while (
                oldIdx < pool.marketConfigurations.length &&
                pool.marketConfigurations[oldIdx].marketId <
                newMarketConfigurations[newIdx].marketId
            ) {
                potentiallyLockedMarkets[potentiallyLockedMarketsIdx++] = pool
                    .marketConfigurations[oldIdx]
                    .marketId;
                removedMarkets[removedMarketsIdx++] = potentiallyLockedMarkets[
                    potentiallyLockedMarketsIdx - 1
                ];

                oldIdx++;
            }

            // If the market id of newIdx is equal to any of the old market ids,
            // consider it updated (increases oldIdx once).
            if (
                oldIdx < pool.marketConfigurations.length &&
                pool.marketConfigurations[oldIdx].marketId ==
                newMarketConfigurations[newIdx].marketId
            ) {
                // Get weight ratios for comparison below.
                // Upscale them to make sure that we have compatible precision in case of very small values.
                // If the market's new maximum share value or weight ratio decreased,
                // mark it for later verification.
                if (
                    newMarketConfigurations[newIdx].maxDebtShareValueD18 <
                    pool.marketConfigurations[oldIdx].maxDebtShareValueD18 ||
                    newMarketConfigurations[newIdx]
                        .weightD18
                        .to256()
                        .upscale(DecimalMath.PRECISION_FACTOR)
                        .divDecimal(totalWeightD18) < // newWeightRatioD27
                    pool
                        .marketConfigurations[oldIdx]
                        .weightD18
                        .to256()
                        .upscale(DecimalMath.PRECISION_FACTOR)
                        .divDecimal(pool.totalWeightsD18) // oldWeightRatioD27
                ) {
                    potentiallyLockedMarkets[
                        potentiallyLockedMarketsIdx++
                    ] = newMarketConfigurations[newIdx].marketId;
                }

                oldIdx++;
            }

            // Note: processing or checks for added markets is not necessary.
        } // for end

        // If any of the old markets was not processed up to this point,
        // it means that it is not present in the new array, so mark it for removal.
        while (oldIdx < pool.marketConfigurations.length) {
            removedMarkets[removedMarketsIdx++] = pool.marketConfigurations[oldIdx].marketId;
            oldIdx++;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/errors/AccessError.sol";
import "@synthetixio/core-contracts/contracts/errors/ParameterError.sol";
import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import "@synthetixio/core-contracts/contracts/utils/ERC165Helper.sol";

import "../../storage/Account.sol";
import "../../storage/AccountRBAC.sol";
import "../../storage/Pool.sol";

import "../../interfaces/IRewardsManagerModule.sol";

import "@synthetixio/core-modules/contracts/storage/FeatureFlag.sol";

/**
 * @title Module for connecting rewards distributors to vaults.
 * @dev See IRewardsManagerModule.
 */
contract RewardsManagerModule is IRewardsManagerModule {
    using SetUtil for SetUtil.Bytes32Set;
    using DecimalMath for uint256;
    using DecimalMath for int256;
    using SafeCastU32 for uint32;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;

    using Vault for Vault.Data;
    using Distribution for Distribution.Data;
    using RewardDistribution for RewardDistribution.Data;

    uint256 private constant _MAX_REWARD_DISTRIBUTIONS = 10;

    bytes32 private constant _CLAIM_FEATURE_FLAG = "claimRewards";

    /**
     * @inheritdoc IRewardsManagerModule
     */
    function registerRewardsDistributor(
        uint128 poolId,
        address collateralType,
        address distributor
    ) external override {
        Pool.Data storage pool = Pool.load(poolId);
        SetUtil.Bytes32Set storage rewardIds = pool.vaults[collateralType].rewardIds;

        if (pool.owner != msg.sender) {
            revert AccessError.Unauthorized(msg.sender);
        }

        // Limit the maximum amount of rewards distributors can be connected to each vault to prevent excessive gas usage on other calls
        if (rewardIds.length() > _MAX_REWARD_DISTRIBUTIONS) {
            revert ParameterError.InvalidParameter("index", "too large");
        }

        if (
            !ERC165Helper.safeSupportsInterface(distributor, type(IRewardDistributor).interfaceId)
        ) {
            revert ParameterError.InvalidParameter("distributor", "invalid interface");
        }

        bytes32 rewardId = _getRewardId(poolId, collateralType, distributor);

        if (rewardIds.contains(rewardId)) {
            revert ParameterError.InvalidParameter("distributor", "is already registered");
        }
        if (address(pool.vaults[collateralType].rewards[rewardId].distributor) != address(0)) {
            revert ParameterError.InvalidParameter("distributor", "cant be re-registered");
        }

        rewardIds.add(rewardId);
        if (distributor == address(0)) {
            revert ParameterError.InvalidParameter("distributor", "must be non-zero");
        }
        pool.vaults[collateralType].rewards[rewardId].distributor = IRewardDistributor(distributor);

        emit RewardsDistributorRegistered(poolId, collateralType, distributor);
    }

    /**
     * @inheritdoc IRewardsManagerModule
     */
    function distributeRewards(
        uint128 poolId,
        address collateralType,
        uint256 amount,
        uint64 start,
        uint32 duration
    ) external override {
        Pool.Data storage pool = Pool.load(poolId);
        SetUtil.Bytes32Set storage rewardIds = pool.vaults[collateralType].rewardIds;

        // Identify the reward id for the caller, and revert if it is not a registered reward distributor.
        bytes32 rewardId = _getRewardId(poolId, collateralType, msg.sender);
        if (!rewardIds.contains(rewardId)) {
            revert ParameterError.InvalidParameter(
                "poolId-collateralType-distributor",
                "reward is not registered"
            );
        }

        RewardDistribution.Data storage reward = pool.vaults[collateralType].rewards[rewardId];

        reward.rewardPerShareD18 += reward
            .distribute(
                pool.vaults[collateralType].currentEpoch().accountsDebtDistribution,
                amount.toInt(),
                start,
                duration
            )
            .toUint()
            .to128();

        emit RewardsDistributed(poolId, collateralType, msg.sender, amount, start, duration);
    }

    /**
     * @inheritdoc IRewardsManagerModule
     */
    function updateRewards(
        uint128 poolId,
        address collateralType,
        uint128 accountId
    ) external override returns (uint256[] memory, address[] memory) {
        Account.exists(accountId);
        Vault.Data storage vault = Pool.load(poolId).vaults[collateralType];
        return vault.updateRewards(accountId);
    }

    /**
     * @inheritdoc IRewardsManagerModule
     */
    function getRewardRate(
        uint128 poolId,
        address collateralType,
        address distributor
    ) external view override returns (uint256) {
        return _getRewardRate(poolId, collateralType, distributor);
    }

    /**
     * @inheritdoc IRewardsManagerModule
     */
    function claimRewards(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        address distributor
    ) external override returns (uint256) {
        FeatureFlag.ensureAccessToFeature(_CLAIM_FEATURE_FLAG);
        Account.loadAccountAndValidatePermission(accountId, AccountRBAC._REWARDS_PERMISSION);

        Vault.Data storage vault = Pool.load(poolId).vaults[collateralType];
        bytes32 rewardId = keccak256(abi.encode(poolId, collateralType, distributor));

        if (address(vault.rewards[rewardId].distributor) != distributor) {
            revert ParameterError.InvalidParameter("invalid-params", "reward is not found");
        }

        uint256 rewardAmount = vault.updateReward(accountId, rewardId);

        RewardDistribution.Data storage reward = vault.rewards[rewardId];
        reward.claimStatus[accountId].pendingSendD18 = 0;
        bool success = vault.rewards[rewardId].distributor.payout(
            accountId,
            poolId,
            collateralType,
            msg.sender,
            rewardAmount
        );

        if (!success) {
            revert RewardUnavailable(distributor);
        }

        emit RewardsClaimed(
            accountId,
            poolId,
            collateralType,
            address(vault.rewards[rewardId].distributor),
            rewardAmount
        );

        return rewardAmount;
    }

    /**
     * @dev Return the amount of rewards being distributed to a vault per second
     */
    function _getRewardRate(
        uint128 poolId,
        address collateralType,
        address distributor
    ) internal view returns (uint256) {
        Vault.Data storage vault = Pool.load(poolId).vaults[collateralType];
        uint256 totalShares = vault.currentEpoch().accountsDebtDistribution.totalSharesD18;
        bytes32 rewardId = _getRewardId(poolId, collateralType, distributor);

        int256 curTime = block.timestamp.toInt();

        // No rewards are currently being distributed if the distributor doesn't exist, they are scheduled to be distributed in the future, or the distribution as already completed
        if (
            address(vault.rewards[rewardId].distributor) == address(0) ||
            vault.rewards[rewardId].start > curTime.toUint() ||
            vault.rewards[rewardId].start + vault.rewards[rewardId].duration <= curTime.toUint()
        ) {
            return 0;
        }

        return
            vault.rewards[rewardId].scheduledValueD18.to256().toUint().divDecimal(
                vault.rewards[rewardId].duration.to256().divDecimal(totalShares)
            );
    }

    /**
     * @dev Generate an ID for a rewards distributor connection by hashing its address with the vault's collateral type address and pool id
     */
    function _getRewardId(
        uint128 poolId,
        address collateralType,
        address distributor
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(poolId, collateralType, distributor));
    }

    /**
     * @inheritdoc IRewardsManagerModule
     */
    function removeRewardsDistributor(
        uint128 poolId,
        address collateralType,
        address distributor
    ) external override {
        Pool.Data storage pool = Pool.load(poolId);
        SetUtil.Bytes32Set storage rewardIds = pool.vaults[collateralType].rewardIds;

        if (pool.owner != msg.sender) {
            revert AccessError.Unauthorized(msg.sender);
        }

        bytes32 rewardId = _getRewardId(poolId, collateralType, distributor);

        if (!rewardIds.contains(rewardId)) {
            revert ParameterError.InvalidParameter("distributor", "is not registered");
        }

        rewardIds.remove(rewardId);

        if (distributor == address(0)) {
            revert ParameterError.InvalidParameter("distributor", "must be non-zero");
        }

        RewardDistribution.Data storage reward = pool.vaults[collateralType].rewards[rewardId];

        // ensure rewards emission is stopped (users can still come in to claim rewards after the fact)
        reward.rewardPerShareD18 += reward
            .distribute(
                pool.vaults[collateralType].currentEpoch().accountsDebtDistribution,
                0,
                0,
                0
            )
            .toUint()
            .to128();

        emit RewardsDistributorRemoved(poolId, collateralType, distributor);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-modules/contracts/interfaces/IAssociatedSystemsModule.sol";
import "@synthetixio/core-modules/contracts/storage/AssociatedSystem.sol";
import "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";

import "../../interfaces/IUtilsModule.sol";

import "../../storage/OracleManager.sol";
import "../../storage/Config.sol";

/**
 * @title Module with assorted utility functions.
 * @dev See IUtilsModule.
 */
contract UtilsModule is IUtilsModule {
    using AssociatedSystem for AssociatedSystem.Data;

    bytes32 private constant _USD_TOKEN = "USDToken";
    bytes32 private constant _CCIP_CHAINLINK_SEND = "ccipChainlinkSend";
    bytes32 private constant _CCIP_CHAINLINK_RECV = "ccipChainlinkRecv";
    bytes32 private constant _CCIP_CHAINLINK_TOKEN_POOL = "ccipChainlinkTokenPool";

    /**
     * @inheritdoc IUtilsModule
     */
    function registerCcip(
        address ccipSend,
        address ccipReceive,
        address ccipTokenPool
    ) external override {
        OwnableStorage.onlyOwner();

        IAssociatedSystemsModule usdToken = IAssociatedSystemsModule(
            AssociatedSystem.load(_USD_TOKEN).proxy
        );

        usdToken.registerUnmanagedSystem(_CCIP_CHAINLINK_SEND, ccipSend);
        usdToken.registerUnmanagedSystem(_CCIP_CHAINLINK_RECV, ccipReceive);
        usdToken.registerUnmanagedSystem(_CCIP_CHAINLINK_TOKEN_POOL, ccipTokenPool);
    }

    /**
     * @inheritdoc IUtilsModule
     */
    function configureOracleManager(address oracleManagerAddress) external override {
        OwnableStorage.onlyOwner();

        OracleManager.Data storage oracle = OracleManager.load();
        oracle.oracleManagerAddress = oracleManagerAddress;
    }

    function setConfig(bytes32 k, bytes32 v) external override {
        OwnableStorage.onlyOwner();
        return Config.put(k, v);
    }

    function getConfig(bytes32 k) external view override returns (bytes32 v) {
        OwnableStorage.onlyOwner();
        return Config.read(k);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "../../storage/Account.sol";
import "../../storage/Pool.sol";

import "@synthetixio/core-modules/contracts/storage/FeatureFlag.sol";

import "../../interfaces/IVaultModule.sol";

/**
 * @title Allows accounts to delegate collateral to a pool.
 * @dev See IVaultModule.
 */
contract VaultModule is IVaultModule {
    using SetUtil for SetUtil.UintSet;
    using SetUtil for SetUtil.Bytes32Set;
    using SetUtil for SetUtil.AddressSet;
    using DecimalMath for uint256;
    using Pool for Pool.Data;
    using Vault for Vault.Data;
    using VaultEpoch for VaultEpoch.Data;
    using Collateral for Collateral.Data;
    using CollateralConfiguration for CollateralConfiguration.Data;
    using AccountRBAC for AccountRBAC.Data;
    using Distribution for Distribution.Data;
    using CollateralConfiguration for CollateralConfiguration.Data;
    using ScalableMapping for ScalableMapping.Data;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;

    bytes32 private constant _DELEGATE_FEATURE_FLAG = "delegateCollateral";

    /**
     * @inheritdoc IVaultModule
     */
    function delegateCollateral(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        uint256 newCollateralAmountD18,
        uint256 leverage
    ) external override {
        FeatureFlag.ensureAccessToFeature(_DELEGATE_FEATURE_FLAG);
        Pool.loadExisting(poolId);
        Account.loadAccountAndValidatePermission(accountId, AccountRBAC._DELEGATE_PERMISSION);

        // Each collateral type may specify a minimum collateral amount that can be delegated.
        // See CollateralConfiguration.minDelegationD18.
        if (newCollateralAmountD18 > 0) {
            CollateralConfiguration.requireSufficientDelegation(
                collateralType,
                newCollateralAmountD18
            );
        }

        // System only supports leverage of 1.0 for now.
        if (leverage != DecimalMath.UNIT) revert InvalidLeverage(leverage);

        // Identify the vault that corresponds to this collateral type and pool id.
        Vault.Data storage vault = Pool.load(poolId).vaults[collateralType];

        // Use account interaction to update its rewards.
        vault.updateRewards(accountId);

        uint256 currentCollateralAmount = vault.currentAccountCollateral(accountId);

        // Ensure current collateral amount differs from the new collateral amount.
        if (newCollateralAmountD18 == currentCollateralAmount) revert InvalidCollateralAmount();

        // If increasing delegated collateral amount,
        // Check that the account has sufficient collateral.
        if (newCollateralAmountD18 > currentCollateralAmount) {
            // Check if the collateral is enabled here because we still want to allow reducing delegation for disabled collaterals.
            CollateralConfiguration.collateralEnabled(collateralType);

            Account.requireSufficientCollateral(
                accountId,
                collateralType,
                newCollateralAmountD18 - currentCollateralAmount
            );
        }

        // Update the account's position for the given pool and collateral type,
        // Note: This will trigger an update in the entire debt distribution chain.
        uint256 collateralPrice = _updatePosition(
            accountId,
            poolId,
            collateralType,
            newCollateralAmountD18,
            currentCollateralAmount,
            leverage
        );

        _updateAccountCollateralPools(
            accountId,
            poolId,
            collateralType,
            newCollateralAmountD18 > 0
        );

        // If decreasing the delegated collateral amount,
        // check the account's collateralization ratio.
        // Note: This is the best time to do so since the user's debt and the collateral's price have both been updated.
        if (newCollateralAmountD18 < currentCollateralAmount) {
            int256 debt = vault.currentEpoch().consolidatedDebtAmountsD18[accountId];

            // Minimum collateralization ratios are configured in the system per collateral type.abi
            // Ensure that the account's updated position satisfies this requirement.
            CollateralConfiguration.load(collateralType).verifyIssuanceRatio(
                debt < 0 ? 0 : debt.toUint(),
                newCollateralAmountD18.mulDecimal(collateralPrice)
            );

            // Accounts cannot reduce collateral if any of the pool's
            // connected market has its capacity locked.
            _verifyNotCapacityLocked(poolId);
        }

        emit DelegationUpdated(
            accountId,
            poolId,
            collateralType,
            newCollateralAmountD18,
            leverage,
            msg.sender
        );
    }

    /**
     * @inheritdoc IVaultModule
     */
    function getPositionCollateralRatio(
        uint128 accountId,
        uint128 poolId,
        address collateralType
    ) external override returns (uint256) {
        return Pool.load(poolId).currentAccountCollateralRatio(collateralType, accountId);
    }

    /**
     * @inheritdoc IVaultModule
     */
    function getVaultCollateralRatio(
        uint128 poolId,
        address collateralType
    ) external override returns (uint256) {
        return Pool.load(poolId).currentVaultCollateralRatio(collateralType);
    }

    /**
     * @inheritdoc IVaultModule
     */
    function getPositionCollateral(
        uint128 accountId,
        uint128 poolId,
        address collateralType
    ) external view override returns (uint256 amount, uint256 value) {
        (amount, value) = Pool.load(poolId).currentAccountCollateral(collateralType, accountId);
    }

    /**
     * @inheritdoc IVaultModule
     */
    function getPosition(
        uint128 accountId,
        uint128 poolId,
        address collateralType
    )
        external
        override
        returns (
            uint256 collateralAmount,
            uint256 collateralValue,
            int256 debt,
            uint256 collateralizationRatio
        )
    {
        Pool.Data storage pool = Pool.load(poolId);

        debt = pool.updateAccountDebt(collateralType, accountId);
        (collateralAmount, collateralValue) = pool.currentAccountCollateral(
            collateralType,
            accountId
        );
        collateralizationRatio = pool.currentAccountCollateralRatio(collateralType, accountId);
    }

    /**
     * @inheritdoc IVaultModule
     */
    function getPositionDebt(
        uint128 accountId,
        uint128 poolId,
        address collateralType
    ) external override returns (int256) {
        return Pool.load(poolId).updateAccountDebt(collateralType, accountId);
    }

    /**
     * @inheritdoc IVaultModule
     */
    function getVaultCollateral(
        uint128 poolId,
        address collateralType
    ) public view override returns (uint256 amount, uint256 value) {
        return Pool.load(poolId).currentVaultCollateral(collateralType);
    }

    /**
     * @inheritdoc IVaultModule
     */
    function getVaultDebt(uint128 poolId, address collateralType) public override returns (int256) {
        return Pool.load(poolId).currentVaultDebt(collateralType);
    }

    /**
     * @dev Updates the given account's position regarding the given pool and collateral type,
     * with the new amount of delegated collateral.
     *
     * The update will be reflected in the registered delegated collateral amount,
     * but it will also trigger updates to the entire debt distribution chain.
     */
    function _updatePosition(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        uint256 newCollateralAmount,
        uint256 oldCollateralAmount,
        uint256 leverage
    ) internal returns (uint256 collateralPrice) {
        Pool.Data storage pool = Pool.load(poolId);

        // Trigger an update in the debt distribution chain to make sure that
        // the user's debt is up to date.
        pool.updateAccountDebt(collateralType, accountId);

        // Get the collateral entry for the given account and collateral type.
        Collateral.Data storage collateral = Account.load(accountId).collaterals[collateralType];

        // Adjust collateral depending on increase/decrease of amount.
        if (newCollateralAmount > oldCollateralAmount) {
            collateral.decreaseAvailableCollateral(newCollateralAmount - oldCollateralAmount);
        } else {
            collateral.increaseAvailableCollateral(oldCollateralAmount - newCollateralAmount);
        }

        // If the collateral amount is not negative, make sure that the pool exists
        // in the collateral entry's pool array. Otherwise remove it.
        _updateAccountCollateralPools(accountId, poolId, collateralType, newCollateralAmount > 0);

        // Update the account's position in the vault data structure.
        pool.vaults[collateralType].currentEpoch().updateAccountPosition(
            accountId,
            newCollateralAmount,
            leverage
        );

        // Trigger another update in the debt distribution chain,
        // and surface the latest price for the given collateral type (which is retrieved in the update).
        collateralPrice = pool.recalculateVaultCollateral(collateralType);
    }

    function _verifyNotCapacityLocked(uint128 poolId) internal view {
        Pool.Data storage pool = Pool.load(poolId);

        Market.Data storage market = pool.findMarketWithCapacityLocked();

        if (market.id > 0) {
            revert CapacityLocked(market.id);
        }
    }

    /**
     * @dev Registers the pool in the given account's collaterals array.
     */
    function _updateAccountCollateralPools(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        bool added
    ) internal {
        Collateral.Data storage depositedCollateral = Account.load(accountId).collaterals[
            collateralType
        ];

        bool containsPool = depositedCollateral.pools.contains(poolId);
        if (added && !containsPool) {
            depositedCollateral.pools.add(poolId);
        } else if (!added && containsPool) {
            depositedCollateral.pools.remove(poolId);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./common/OwnerModule.sol";
import "./common/UpgradeModule.sol";

// The below contract is only used during initialization as a kernel for the first release which the system can be upgraded onto.
// Subsequent upgrades will not need this module bundle
// In the future on live networks, we may want to find some way to hardcode the owner address here to prevent grieving

// solhint-disable-next-line no-empty-blocks
contract InitialModuleBundle is OwnerModule, UpgradeModule {

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../../interfaces/IUSDTokenModule.sol";
import "../../interfaces/external/IEVM2AnySubscriptionOnRampRouterInterface.sol";

import "@synthetixio/core-modules/contracts/storage/AssociatedSystem.sol";
import "@synthetixio/core-contracts/contracts/token/ERC20.sol";
import "@synthetixio/core-contracts/contracts/initializable/InitializableMixin.sol";
import "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";

/**
 * @title Module for managing the snxUSD token as an associated system.
 * @dev See IUSDTokenModule.
 */
contract USDTokenModule is ERC20, InitializableMixin, IUSDTokenModule {
    using AssociatedSystem for AssociatedSystem.Data;

    uint256 private constant _TRANSFER_GAS_LIMIT = 100000;

    bytes32 private constant _CCIP_CHAINLINK_SEND = "ccipChainlinkSend";
    bytes32 private constant _CCIP_CHAINLINK_RECV = "ccipChainlinkRecv";
    bytes32 private constant _CCIP_CHAINLINK_TOKEN_POOL = "ccipChainlinkTokenPool";

    /**
     * @dev For use as an associated system.
     */
    function _isInitialized() internal view override returns (bool) {
        return ERC20Storage.load().decimals != 0;
    }

    /**
     * @dev For use as an associated system.
     */
    function isInitialized() external view returns (bool) {
        return _isInitialized();
    }

    /**
     * @dev For use as an associated system.
     */
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) public virtual {
        OwnableStorage.onlyOwner();
        _initialize(tokenName, tokenSymbol, tokenDecimals);
    }

    /**
     * @dev Allows the core system and CCIP to mint tokens.
     */
    function mint(address target, uint256 amount) external override {
        if (
            msg.sender != OwnableStorage.getOwner() &&
            msg.sender != AssociatedSystem.load(_CCIP_CHAINLINK_TOKEN_POOL).proxy
        ) {
            revert AccessError.Unauthorized(msg.sender);
        }

        _mint(target, amount);
    }

    /**
     * @dev Allows the core system and CCIP to burn tokens.
     */
    function burn(address target, uint256 amount) external override {
        if (
            msg.sender != OwnableStorage.getOwner() &&
            msg.sender != AssociatedSystem.load(_CCIP_CHAINLINK_TOKEN_POOL).proxy
        ) {
            revert AccessError.Unauthorized(msg.sender);
        }

        _burn(target, amount);
    }

    /**
     * @inheritdoc IUSDTokenModule
     */
    function burnWithAllowance(address from, address spender, uint256 amount) external {
        OwnableStorage.onlyOwner();

        ERC20Storage.Data storage erc20 = ERC20Storage.load();

        if (amount > erc20.allowance[from][spender]) {
            revert InsufficientAllowance(amount, erc20.allowance[from][spender]);
        }

        erc20.allowance[from][spender] -= amount;

        _burn(from, amount);
    }

    /**
     * @inheritdoc IUSDTokenModule
     */
    function transferCrossChain(
        uint256 destChainId,
        address to,
        uint256 amount
    ) external returns (uint256 feesPaid) {
        AssociatedSystem.load(_CCIP_CHAINLINK_SEND).expectKind(AssociatedSystem.KIND_UNMANAGED);

        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(address(this));

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        IEVM2AnySubscriptionOnRampRouterInterface(AssociatedSystem.load(_CCIP_CHAINLINK_SEND).proxy)
            .ccipSend(
                destChainId,
                IEVM2AnySubscriptionOnRampRouterInterface.EVM2AnySubscriptionMessage(
                    abi.encode(to), // Address of the receiver on the destination chain for EVM chains use abi.encode(destAddress).
                    "", // Bytes that we wish to send to the receiver
                    tokens, // The ERC20 tokens we wish to send for EVM source chains
                    amounts, // The amount of ERC20 tokens we wish to send for EVM source chains
                    _TRANSFER_GAS_LIMIT // the gas limit for the call to the receiver for destination chains
                )
            );

        return (0);
    }

    /**
     * @dev Included to satisfy ITokenModule inheritance.
     */
    function setAllowance(address from, address spender, uint256 amount) external override {
        OwnableStorage.onlyOwner();
        ERC20Storage.load().allowance[from][spender] = amount;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {UUPSProxyWithOwner} from "@synthetixio/core-contracts/contracts/proxy/UUPSProxyWithOwner.sol";

/**
 * Synthetix V3 Core Proxy Contract
 *
 * Visit https://usecannon.com/packages/synthetix to interact with this protocol
 */
contract Proxy is UUPSProxyWithOwner {
    // solhint-disable-next-line no-empty-blocks
    constructor(
        address firstImplementation,
        address initialOwner
    ) UUPSProxyWithOwner(firstImplementation, initialOwner) {}
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./AccountRBAC.sol";
import "./Collateral.sol";
import "./Pool.sol";

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/**
 * @title Object for tracking accounts with access control and collateral tracking.
 */
library Account {
    using AccountRBAC for AccountRBAC.Data;
    using Pool for Pool.Data;
    using Collateral for Collateral.Data;
    using SetUtil for SetUtil.UintSet;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;

    /**
     * @dev Thrown when the given target address does not have the given permission with the given account.
     */
    error PermissionDenied(uint128 accountId, bytes32 permission, address target);

    /**
     * @dev Thrown when an account cannot be found.
     */
    error AccountNotFound(uint128 accountId);

    /**
     * @dev Thrown when an account does not have sufficient collateral for a particular operation in the system.
     */
    error InsufficientAccountCollateral(uint256 requestedAmount);

    /**
     * @dev Thrown when the requested operation requires an activity timeout before the
     */
    error AccountActivityTimeoutPending(
        uint128 accountId,
        uint256 currentTime,
        uint256 requiredTime
    );

    struct Data {
        /**
         * @dev Numeric identifier for the account. Must be unique.
         * @dev There cannot be an account with id zero (See ERC721._mint()).
         */
        uint128 id;
        /**
         * @dev Role based access control data for the account.
         */
        AccountRBAC.Data rbac;
        uint64 lastInteraction;
        uint64 __slotAvailableForFutureUse;
        uint128 __slot2AvailableForFutureUse;
        /**
         * @dev Address set of collaterals that are being used in the system by this account.
         */
        mapping(address => Collateral.Data) collaterals;
    }

    /**
     * @dev Returns the account stored at the specified account id.
     */
    function load(uint128 id) internal pure returns (Data storage account) {
        bytes32 s = keccak256(abi.encode("io.synthetix.synthetix.Account", id));
        assembly {
            account.slot := s
        }
    }

    /**
     * @dev Creates an account for the given id, and associates it to the given owner.
     *
     * Note: Will not fail if the account already exists, and if so, will overwrite the existing owner. Whatever calls this internal function must first check that the account doesn't exist before re-creating it.
     */
    function create(uint128 id, address owner) internal returns (Data storage account) {
        account = load(id);

        account.id = id;
        account.rbac.owner = owner;
    }

    /**
     * @dev Reverts if the account does not exist with appropriate error. Otherwise, returns the account.
     */
    function exists(uint128 id) internal view returns (Data storage account) {
        Data storage a = load(id);
        if (a.rbac.owner == address(0)) {
            revert AccountNotFound(id);
        }

        return a;
    }

    /**
     * @dev Given a collateral type, returns information about the total collateral assigned, deposited, and locked by the account
     */
    function getCollateralTotals(
        Data storage self,
        address collateralType
    )
        internal
        view
        returns (uint256 totalDepositedD18, uint256 totalAssignedD18, uint256 totalLockedD18)
    {
        totalAssignedD18 = getAssignedCollateral(self, collateralType);
        totalDepositedD18 =
            totalAssignedD18 +
            self.collaterals[collateralType].amountAvailableForDelegationD18;
        totalLockedD18 = self.collaterals[collateralType].getTotalLocked();

        return (totalDepositedD18, totalAssignedD18, totalLockedD18);
    }

    /**
     * @dev Returns the total amount of collateral that has been delegated to pools by the account, for the given collateral type.
     */
    function getAssignedCollateral(
        Data storage self,
        address collateralType
    ) internal view returns (uint256) {
        uint256 totalAssignedD18 = 0;

        SetUtil.UintSet storage pools = self.collaterals[collateralType].pools;

        for (uint256 i = 1; i <= pools.length(); i++) {
            uint128 poolIdx = pools.valueAt(i).to128();

            Pool.Data storage pool = Pool.load(poolIdx);

            (uint256 collateralAmountD18, ) = pool.currentAccountCollateral(
                collateralType,
                self.id
            );
            totalAssignedD18 += collateralAmountD18;
        }

        return totalAssignedD18;
    }

    function recordInteraction(Data storage self) internal {
        // solhint-disable-next-line numcast/safe-cast
        self.lastInteraction = uint64(block.timestamp);
    }

    /**
     * @dev Loads the Account object for the specified accountId,
     * and validates that sender has the specified permission. It also resets
     * the interaction timeout. These
     * are different actions but they are merged in a single function
     * because loading an account and checking for a permission is a very
     * common use case in other parts of the code.
     */
    function loadAccountAndValidatePermission(
        uint128 accountId,
        bytes32 permission
    ) internal returns (Data storage account) {
        account = Account.load(accountId);

        if (!account.rbac.authorized(permission, msg.sender)) {
            revert PermissionDenied(accountId, permission, msg.sender);
        }

        recordInteraction(account);
    }

    /**
     * @dev Loads the Account object for the specified accountId,
     * and validates that sender has the specified permission. It also resets
     * the interaction timeout. These
     * are different actions but they are merged in a single function
     * because loading an account and checking for a permission is a very
     * common use case in other parts of the code.
     */
    function loadAccountAndValidatePermissionAndTimeout(
        uint128 accountId,
        bytes32 permission,
        uint256 timeout
    ) internal view returns (Data storage account) {
        account = Account.load(accountId);

        if (!account.rbac.authorized(permission, msg.sender)) {
            revert PermissionDenied(accountId, permission, msg.sender);
        }

        uint256 endWaitingPeriod = account.lastInteraction + timeout;
        if (block.timestamp < endWaitingPeriod) {
            revert AccountActivityTimeoutPending(accountId, block.timestamp, endWaitingPeriod);
        }
    }

    /**
     * @dev Ensure that the account has the required amount of collateral funds remaining
     */
    function requireSufficientCollateral(
        uint128 accountId,
        address collateralType,
        uint256 amountD18
    ) internal view {
        if (
            Account.load(accountId).collaterals[collateralType].amountAvailableForDelegationD18 <
            amountD18
        ) {
            revert InsufficientAccountCollateral(amountD18);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import "@synthetixio/core-contracts/contracts/errors/AddressError.sol";

/**
 * @title Object for tracking an accounts permissions (role based access control).
 */
library AccountRBAC {
    using SetUtil for SetUtil.Bytes32Set;
    using SetUtil for SetUtil.AddressSet;

    /**
     * @dev All permissions used by the system
     * need to be hardcoded here.
     */
    bytes32 internal constant _ADMIN_PERMISSION = "ADMIN";
    bytes32 internal constant _WITHDRAW_PERMISSION = "WITHDRAW";
    bytes32 internal constant _DELEGATE_PERMISSION = "DELEGATE";
    bytes32 internal constant _MINT_PERMISSION = "MINT";
    bytes32 internal constant _REWARDS_PERMISSION = "REWARDS";

    /**
     * @dev Thrown when a permission specified by a user does not exist or is invalid.
     */
    error InvalidPermission(bytes32 permission);

    struct Data {
        /**
         * @dev The owner of the account and admin of all permissions.
         */
        address owner;
        /**
         * @dev Set of permissions for each address enabled by the account.
         */
        mapping(address => SetUtil.Bytes32Set) permissions;
        /**
         * @dev Array of addresses that this account has given permissions to.
         */
        SetUtil.AddressSet permissionAddresses;
    }

    /**
     * @dev Reverts if the specified permission is unknown to the account RBAC system.
     */
    function isPermissionValid(bytes32 permission) internal pure {
        if (
            permission != AccountRBAC._WITHDRAW_PERMISSION &&
            permission != AccountRBAC._DELEGATE_PERMISSION &&
            permission != AccountRBAC._MINT_PERMISSION &&
            permission != AccountRBAC._ADMIN_PERMISSION &&
            permission != AccountRBAC._REWARDS_PERMISSION
        ) {
            revert InvalidPermission(permission);
        }
    }

    /**
     * @dev Sets the owner of the account.
     */
    function setOwner(Data storage self, address owner) internal {
        self.owner = owner;
    }

    /**
     * @dev Grants a particular permission to the specified target address.
     */
    function grantPermission(Data storage self, bytes32 permission, address target) internal {
        if (target == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (permission == "") {
            revert InvalidPermission("");
        }

        if (!self.permissionAddresses.contains(target)) {
            self.permissionAddresses.add(target);
        }

        self.permissions[target].add(permission);
    }

    /**
     * @dev Revokes a particular permission from the specified target address.
     */
    function revokePermission(Data storage self, bytes32 permission, address target) internal {
        self.permissions[target].remove(permission);

        if (self.permissions[target].length() == 0) {
            self.permissionAddresses.remove(target);
        }
    }

    /**
     * @dev Revokes all permissions for the specified target address.
     * @notice only removes permissions for the given address, not for the entire account
     */
    function revokeAllPermissions(Data storage self, address target) internal {
        bytes32[] memory permissions = self.permissions[target].values();

        if (permissions.length == 0) {
            return;
        }

        for (uint256 i = 0; i < permissions.length; i++) {
            self.permissions[target].remove(permissions[i]);
        }

        self.permissionAddresses.remove(target);
    }

    /**
     * @dev Returns wether the specified address has the given permission.
     */
    function hasPermission(
        Data storage self,
        bytes32 permission,
        address target
    ) internal view returns (bool) {
        return target != address(0) && self.permissions[target].contains(permission);
    }

    /**
     * @dev Returns wether the specified target address has the given permission, or has the high level admin permission.
     */
    function authorized(
        Data storage self,
        bytes32 permission,
        address target
    ) internal view returns (bool) {
        return ((target == self.owner) ||
            hasPermission(self, _ADMIN_PERMISSION, target) ||
            hasPermission(self, permission, target));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "./CollateralLock.sol";

/**
 * @title Stores information about a deposited asset for a given account.
 *
 * Each account will have one of these objects for each type of collateral it deposited in the system.
 */
library Collateral {
    using SafeCastU256 for uint256;

    struct Data {
        /**
         * @dev The amount that can be withdrawn or delegated in this collateral.
         */
        uint256 amountAvailableForDelegationD18;
        /**
         * @dev The pools to which this collateral delegates to.
         */
        SetUtil.UintSet pools;
        /**
         * @dev Marks portions of the collateral as locked,
         * until a given unlock date.
         *
         * Note: Locks apply to delegated collateral and to collateral not
         * assigned or delegated to a pool (see ICollateralModule).
         */
        CollateralLock.Data[] locks;
    }

    /**
     * @dev Increments the entry's availableCollateral.
     */
    function increaseAvailableCollateral(Data storage self, uint256 amountD18) internal {
        self.amountAvailableForDelegationD18 += amountD18;
    }

    /**
     * @dev Decrements the entry's availableCollateral.
     */
    function decreaseAvailableCollateral(Data storage self, uint256 amountD18) internal {
        self.amountAvailableForDelegationD18 -= amountD18;
    }

    /**
     * @dev Returns the total amount in this collateral entry that is locked.
     *
     * Sweeps through all existing locks and accumulates their amount,
     * if their unlock date is in the future.
     */
    function getTotalLocked(Data storage self) internal view returns (uint256) {
        uint64 currentTime = block.timestamp.to64();

        uint256 lockedD18;
        for (uint256 i = 0; i < self.locks.length; i++) {
            CollateralLock.Data storage lock = self.locks[i];

            if (lock.lockExpirationTime > currentTime) {
                lockedD18 += lock.amountD18;
            }
        }

        return lockedD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/errors/ParameterError.sol";
import "@synthetixio/oracle-manager/contracts/interfaces/INodeModule.sol";
import "@synthetixio/oracle-manager/contracts/storage/NodeOutput.sol";
import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "./OracleManager.sol";

/**
 * @title Tracks system-wide settings for each collateral type, as well as helper functions for it, such as retrieving its current price from the oracle manager.
 */
library CollateralConfiguration {
    bytes32 private constant _SLOT_AVAILABLE_COLLATERALS =
        keccak256(
            abi.encode("io.synthetix.synthetix.CollateralConfiguration_availableCollaterals")
        );

    using SetUtil for SetUtil.AddressSet;
    using DecimalMath for uint256;
    using SafeCastI256 for int256;

    /**
     * @dev Thrown when the token address of a collateral cannot be found.
     */
    error CollateralNotFound();

    /**
     * @dev Thrown when deposits are disabled for the given collateral type.
     * @param collateralType The address of the collateral type for which depositing was disabled.
     */
    error CollateralDepositDisabled(address collateralType);

    /**
     * @dev Thrown when collateral ratio is not sufficient in a given operation in the system.
     * @param collateralValue The net USD value of the position.
     * @param debt The net USD debt of the position.
     * @param ratio The collateralization ratio of the position.
     * @param minRatio The minimum c-ratio which was not met. Could be issuance ratio or liquidation ratio, depending on the case.
     */
    error InsufficientCollateralRatio(
        uint256 collateralValue,
        uint256 debt,
        uint256 ratio,
        uint256 minRatio
    );

    /**
     * @dev Thrown when the amount being delegated is less than the minimum expected amount.
     * @param minDelegation The current minimum for deposits and delegation set to this collateral type.
     */
    error InsufficientDelegation(uint256 minDelegation);

    /**
     * @dev Thrown when attempting to convert a token to the system amount and the conversion results in a loss of precision.
     * @param tokenAmount The amount of tokens that were attempted to be converted.
     * @param decimals The number of decimals of the token that was attempted to be converted.
     */
    error PrecisionLost(uint tokenAmount, uint8 decimals);

    struct Data {
        /**
         * @dev Allows the owner to control deposits and delegation of collateral types.
         */
        bool depositingEnabled;
        /**
         * @dev System-wide collateralization ratio for issuance of snxUSD.
         * Accounts will not be able to mint snxUSD if they are below this issuance c-ratio.
         */
        uint256 issuanceRatioD18;
        /**
         * @dev System-wide collateralization ratio for liquidations of this collateral type.
         * Accounts below this c-ratio can be immediately liquidated.
         */
        uint256 liquidationRatioD18;
        /**
         * @dev Amount of tokens to award when an account is liquidated.
         */
        uint256 liquidationRewardD18;
        /**
         * @dev The oracle manager node id which reports the current price for this collateral type.
         */
        bytes32 oracleNodeId;
        /**
         * @dev The token address for this collateral type.
         */
        address tokenAddress;
        /**
         * @dev Minimum amount that accounts can delegate to pools.
         * Helps prevent spamming on the system.
         * Note: If zero, liquidationRewardD18 will be used.
         */
        uint256 minDelegationD18;
    }

    /**
     * @dev Loads the CollateralConfiguration object for the given collateral type.
     * @param token The address of the collateral type.
     * @return collateralConfiguration The CollateralConfiguration object.
     */
    function load(address token) internal pure returns (Data storage collateralConfiguration) {
        bytes32 s = keccak256(abi.encode("io.synthetix.synthetix.CollateralConfiguration", token));
        assembly {
            collateralConfiguration.slot := s
        }
    }

    /**
     * @dev Loads all available collateral types configured in the system.
     * @return availableCollaterals An array of addresses, one for each collateral type supported by the system.
     */
    function loadAvailableCollaterals()
        internal
        pure
        returns (SetUtil.AddressSet storage availableCollaterals)
    {
        bytes32 s = _SLOT_AVAILABLE_COLLATERALS;
        assembly {
            availableCollaterals.slot := s
        }
    }

    /**
     * @dev Configures a collateral type.
     * @param config The CollateralConfiguration object with all the settings for the collateral type being configured.
     */
    function set(Data memory config) internal {
        SetUtil.AddressSet storage collateralTypes = loadAvailableCollaterals();

        if (!collateralTypes.contains(config.tokenAddress)) {
            collateralTypes.add(config.tokenAddress);
        }

        if (config.minDelegationD18 < config.liquidationRewardD18) {
            revert ParameterError.InvalidParameter(
                "minDelegation",
                "must be greater than liquidationReward"
            );
        }

        Data storage storedConfig = load(config.tokenAddress);

        storedConfig.tokenAddress = config.tokenAddress;
        storedConfig.issuanceRatioD18 = config.issuanceRatioD18;
        storedConfig.liquidationRatioD18 = config.liquidationRatioD18;
        storedConfig.oracleNodeId = config.oracleNodeId;
        storedConfig.liquidationRewardD18 = config.liquidationRewardD18;
        storedConfig.minDelegationD18 = config.minDelegationD18;
        storedConfig.depositingEnabled = config.depositingEnabled;
    }

    /**
     * @dev Shows if a given collateral type is enabled for deposits and delegation.
     * @param token The address of the collateral being queried.
     */
    function collateralEnabled(address token) internal view {
        if (!load(token).depositingEnabled) {
            revert CollateralDepositDisabled(token);
        }
    }

    /**
     * @dev Reverts if the amount being delegated is insufficient for the system.
     * @param token The address of the collateral type.
     * @param amountD18 The amount being checked for sufficient delegation.
     */
    function requireSufficientDelegation(address token, uint256 amountD18) internal view {
        CollateralConfiguration.Data storage config = load(token);

        uint256 minDelegationD18 = config.minDelegationD18;

        if (minDelegationD18 == 0) {
            minDelegationD18 = config.liquidationRewardD18;
        }

        if (amountD18 < minDelegationD18) {
            revert InsufficientDelegation(minDelegationD18);
        }
    }

    /**
     * @dev Returns the price of this collateral configuration object.
     * @param self The CollateralConfiguration object.
     * @return The price of the collateral with 18 decimals of precision.
     */
    function getCollateralPrice(Data storage self) internal view returns (uint256) {
        OracleManager.Data memory oracleManager = OracleManager.load();
        NodeOutput.Data memory node = INodeModule(oracleManager.oracleManagerAddress).process(
            self.oracleNodeId
        );

        return node.price.toUint();
    }

    /**
     * @dev Reverts if the specified collateral and debt values produce a collateralization ratio which is below the amount required for new issuance of snxUSD.
     * @param self The CollateralConfiguration object whose collateral and settings are being queried.
     * @param debtD18 The debt component of the ratio.
     * @param collateralValueD18 The collateral component of the ratio.
     */
    function verifyIssuanceRatio(
        Data storage self,
        uint256 debtD18,
        uint256 collateralValueD18
    ) internal view {
        if (
            debtD18 != 0 &&
            (collateralValueD18 == 0 ||
                collateralValueD18.divDecimal(debtD18) < self.issuanceRatioD18)
        ) {
            revert InsufficientCollateralRatio(
                collateralValueD18,
                debtD18,
                collateralValueD18.divDecimal(debtD18),
                self.issuanceRatioD18
            );
        }
    }

    /**
     * @dev Converts token amounts with non-system decimal precisions, to 18 decimals of precision.
     * E.g: $TOKEN_A uses 6 decimals of precision, so this would upscale it by 12 decimals.
     * E.g: $TOKEN_B uses 20 decimals of precision, so this would downscale it by 2 decimals.
     * @param self The CollateralConfiguration object corresponding to the collateral type being converted.
     * @param tokenAmount The token amount, denominated in its native decimal precision.
     * @return amountD18 The converted amount, denominated in the system's 18 decimal precision.
     */
    function convertTokenToSystemAmount(
        Data storage self,
        uint256 tokenAmount
    ) internal view returns (uint256 amountD18) {
        // this extra condition is to prevent potentially malicious untrusted code from being executed on the next statement
        if (self.tokenAddress == address(0)) {
            revert CollateralNotFound();
        }

        /// @dev this try-catch block assumes there is no malicious code in the token's fallback function
        try IERC20(self.tokenAddress).decimals() returns (uint8 decimals) {
            if (decimals == 18) {
                amountD18 = tokenAmount;
            } else if (decimals < 18) {
                amountD18 = (tokenAmount * DecimalMath.UNIT) / (10 ** decimals);
            } else {
                // ensure no precision is lost when converting to 18 decimals
                if (tokenAmount % (10 ** (decimals - 18)) != 0) {
                    revert PrecisionLost(tokenAmount, decimals);
                }

                // this will scale down the amount by the difference between the token's decimals and 18
                amountD18 = (tokenAmount * DecimalMath.UNIT) / (10 ** decimals);
            }
        } catch {
            // if the token doesn't have a decimals function, assume it's 18 decimals
            amountD18 = tokenAmount;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Represents a given amount of collateral locked until a given date.
 */
library CollateralLock {
    struct Data {
        /**
         * @dev The amount of collateral that has been locked.
         */
        uint128 amountD18;
        /**
         * @dev The date when the locked amount becomes unlocked.
         */
        uint64 lockExpirationTime;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title System wide configuration for anything
 */
library Config {
    struct Data {
        uint256 __unused;
    }

    /**
     * @dev Returns a config value
     */
    function read(bytes32 k) internal view returns (bytes32 v) {
        bytes32 s = keccak256(abi.encode("Config", k));
        assembly {
            v := sload(s)
        }
    }

    function put(bytes32 k, bytes32 v) internal {
        bytes32 s = keccak256(abi.encode("Config", k));
        assembly {
            sstore(s, v)
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "./DistributionActor.sol";

/**
 * @title Data structure that allows you to track some global value, distributed amongst a set of actors.
 *
 * The total value can be scaled with a valuePerShare multiplier, and individual actor shares can be calculated as their amount of shares times this multiplier.
 *
 * Furthermore, changes in the value of individual actors can be tracked since their last update, by keeping track of the value of the multiplier, per user, upon each interaction. See DistributionActor.lastValuePerShare.
 *
 * A distribution is similar to a ScalableMapping, but it has the added functionality of being able to remember the previous value of the scalar multiplier for each actor.
 *
 * Whenever the shares of an actor of the distribution is updated, you get information about how the actor's total value changed since it was last updated.
 */
library Distribution {
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using DecimalMath for int256;

    /**
     * @dev Thrown when an attempt is made to distribute value to a distribution
     * with no shares.
     */
    error EmptyDistribution();

    struct Data {
        /**
         * @dev The total number of shares in the distribution.
         */
        uint128 totalSharesD18;
        /**
         * @dev The value per share of the distribution, represented as a high precision decimal.
         */
        int128 valuePerShareD27;
        /**
         * @dev Tracks individual actor information, such as how many shares an actor has, their lastValuePerShare, etc.
         */
        mapping(bytes32 => DistributionActor.Data) actorInfo;
    }

    /**
     * @dev Inflates or deflates the total value of the distribution by the given value.
     *
     * The value being distributed ultimately modifies the distribution's valuePerShare.
     */
    function distributeValue(Data storage self, int256 valueD18) internal {
        if (valueD18 == 0) {
            return;
        }

        uint256 totalSharesD18 = self.totalSharesD18;

        if (totalSharesD18 == 0) {
            revert EmptyDistribution();
        }

        int256 valueD45 = valueD18 * DecimalMath.UNIT_PRECISE_INT;
        int256 deltaValuePerShareD27 = valueD45 / totalSharesD18.toInt();

        self.valuePerShareD27 += deltaValuePerShareD27.to128();
    }

    /**
     * @dev Updates an actor's number of shares in the distribution to the specified amount.
     *
     * Whenever an actor's shares are changed in this way, we record the distribution's current valuePerShare into the actor's lastValuePerShare record.
     *
     * Returns the the amount by which the actors value changed since the last update.
     */
    function setActorShares(
        Data storage self,
        bytes32 actorId,
        uint256 newActorSharesD18
    ) internal returns (int valueChangeD18) {
        valueChangeD18 = getActorValueChange(self, actorId);

        DistributionActor.Data storage actor = self.actorInfo[actorId];

        uint128 sharesUint128D18 = newActorSharesD18.to128();
        self.totalSharesD18 = self.totalSharesD18 + sharesUint128D18 - actor.sharesD18;

        actor.sharesD18 = sharesUint128D18;
        _updateLastValuePerShare(self, actor, newActorSharesD18);
    }

    /**
     * @dev Updates an actor's lastValuePerShare to the distribution's current valuePerShare, and
     * returns the change in value for the actor, since their last update.
     */
    function accumulateActor(
        Data storage self,
        bytes32 actorId
    ) internal returns (int valueChangeD18) {
        DistributionActor.Data storage actor = self.actorInfo[actorId];
        return _updateLastValuePerShare(self, actor, actor.sharesD18);
    }

    /**
     * @dev Calculates how much an actor's value has changed since its shares were last updated.
     *
     * This change is calculated as:
     * Since `value = valuePerShare * shares`,
     * then `delta_value = valuePerShare_now * shares - valuePerShare_then * shares`,
     * which is `(valuePerShare_now - valuePerShare_then) * shares`,
     * or just `delta_valuePerShare * shares`.
     */
    function getActorValueChange(
        Data storage self,
        bytes32 actorId
    ) internal view returns (int valueChangeD18) {
        return _getActorValueChange(self, self.actorInfo[actorId]);
    }

    /**
     * @dev Returns the number of shares owned by an actor in the distribution.
     */
    function getActorShares(
        Data storage self,
        bytes32 actorId
    ) internal view returns (uint256 sharesD18) {
        return self.actorInfo[actorId].sharesD18;
    }

    /**
     * @dev Returns the distribution's value per share in normal precision (18 decimals).
     * @param self The distribution whose value per share is being queried.
     * @return The value per share in 18 decimal precision.
     */
    function getValuePerShare(Data storage self) internal view returns (int) {
        return self.valuePerShareD27.to256().downscale(DecimalMath.PRECISION_FACTOR);
    }

    function _updateLastValuePerShare(
        Data storage self,
        DistributionActor.Data storage actor,
        uint256 newActorShares
    ) private returns (int valueChangeD18) {
        valueChangeD18 = _getActorValueChange(self, actor);

        actor.lastValuePerShareD27 = newActorShares == 0
            ? SafeCastI128.zero()
            : self.valuePerShareD27;
    }

    function _getActorValueChange(
        Data storage self,
        DistributionActor.Data storage actor
    ) private view returns (int valueChangeD18) {
        int256 deltaValuePerShareD27 = self.valuePerShareD27 - actor.lastValuePerShareD27;

        int256 changedValueD45 = deltaValuePerShareD27 * actor.sharesD18.toInt();
        valueChangeD18 = changedValueD45 / DecimalMath.UNIT_PRECISE_INT;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Stores information for specific actors in a Distribution.
 */
library DistributionActor {
    struct Data {
        /**
         * @dev The actor's current number of shares in the associated distribution.
         */
        uint128 sharesD18;
        /**
         * @dev The value per share that the associated distribution had at the time that the actor's number of shares was last modified.
         *
         * Note: This is also a high precision decimal. See Distribution.valuePerShare.
         */
        int128 lastValuePerShareD27;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/HeapUtil.sol";

import "./Distribution.sol";
import "./CollateralConfiguration.sol";
import "./MarketPoolInfo.sol";

import "../interfaces/external/IMarket.sol";

/**
 * @title Connects external contracts that implement the `IMarket` interface to the system.
 *
 * Pools provide credit capacity (collateral) to the markets, and are reciprocally exposed to the associated market's debt.
 *
 * The Market object's main responsibility is to track collateral provided by the pools that support it, and to trace their debt back to such pools.
 */
library Market {
    using Distribution for Distribution.Data;
    using HeapUtil for HeapUtil.Data;
    using DecimalMath for uint256;
    using DecimalMath for uint128;
    using DecimalMath for int256;
    using DecimalMath for int128;
    using SafeCastU256 for uint256;
    using SafeCastU128 for uint128;
    using SafeCastI256 for int256;
    using SafeCastI128 for int128;

    /**
     * @dev Thrown when a specified market is not found.
     */
    error MarketNotFound(uint128 marketId);

    struct Data {
        /**
         * @dev Numeric identifier for the market. Must be unique.
         * @dev There cannot be a market with id zero (See MarketCreator.create()). Id zero is used as a null market reference.
         */
        uint128 id;
        /**
         * @dev Address for the external contract that implements the `IMarket` interface, which this Market objects connects to.
         *
         * Note: This object is how the system tracks the market. The actual market is external to the system, i.e. its own contract.
         */
        address marketAddress;
        /**
         * @dev Issuance can be seen as how much USD the Market "has issued", printed, or has asked the system to mint on its behalf.
         *
         * More precisely it can be seen as the net difference between the USD burnt and the USD minted by the market.
         *
         * More issuance means that the market owes more USD to the system.
         *
         * A market burns USD when users deposit it in exchange for some asset that the market offers.
         * The Market object calls `MarketManager.depositUSD()`, which burns the USD, and decreases its issuance.
         *
         * A market mints USD when users return the asset that the market offered and thus withdraw their USD.
         * The Market object calls `MarketManager.withdrawUSD()`, which mints the USD, and increases its issuance.
         *
         * Instead of burning, the Market object could transfer USD to and from the MarketManager, but minting and burning takes the USD out of circulation, which doesn't affect `totalSupply`, thus simplifying accounting.
         *
         * How much USD a market can mint depends on how much credit capacity is given to the market by the pools that support it, and reflected in `Market.capacity`.
         *
         */
        int128 netIssuanceD18;
        /**
         * @dev The total amount of USD that the market could withdraw if it were to immediately unwrap all its positions.
         *
         * The Market's credit capacity increases when the market burns USD, i.e. when it deposits USD in the MarketManager.
         *
         * It decreases when the market mints USD, i.e. when it withdraws USD from the MarketManager.
         *
         * The Market's credit capacity also depends on how much credit is given to it by the pools that support it.
         *
         * The Market's credit capacity also has a dependency on the external market reported debt as it will respond to that debt (and hence change the credit capacity if it increases or decreases)
         *
         * The credit capacity can go negative if all of the collateral provided by pools is exhausted, and there is market provided collateral available to consume. in this case, the debt is still being
         * appropriately assigned, but the market has a dynamic cap based on deposited collateral types.
         *
         */
        int128 creditCapacityD18;
        /**
         * @dev The total balance that the market had the last time that its debt was distributed.
         *
         * A Market's debt is distributed when the reported debt of its associated external market is rolled into the pools that provide credit capacity to it.
         */
        int128 lastDistributedMarketBalanceD18;
        /**
         * @dev A heap of pools for which the market has not yet hit its maximum credit capacity.
         *
         * The heap is ordered according to this market's max value per share setting in the pools that provide credit capacity to it. See `MarketConfiguration.maxDebtShareValue`.
         *
         * The heap's getMax() and extractMax() functions allow us to retrieve the pool with the lowest `maxDebtShareValue`, since its elements are inserted and prioritized by negating their `maxDebtShareValue`.
         *
         * Lower max values per share are on the top of the heap. I.e. the heap could look like this:
         *  .    -1
         *      / \
         *     /   \
         *    -2    \
         *   / \    -3
         * -4   -5
         *
         * TL;DR: This data structure allows us to easily find the pool with the lowest or "most vulnerable" max value per share and process it if its actual value per share goes beyond this limit.
         */
        HeapUtil.Data inRangePools;
        /**
         * @dev A heap of pools for which the market has hit its maximum credit capacity.
         *
         * Used to reconnect pools to the market, when it falls back below its maximum credit capacity.
         *
         * See inRangePools for why a heap is used here.
         */
        HeapUtil.Data outRangePools;
        /**
         * @dev A market's debt distribution connects markets to the debt distribution chain, in this case pools. Pools are actors in the market's debt distribution, where the amount of shares they possess depends on the amount of collateral they provide to the market. The value per share of this distribution depends on the total debt or balance of the market (netIssuance + reportedDebt).
         *
         * The debt distribution chain will move debt from the market into its connected pools.
         *
         * Actors: Pools.
         * Shares: The USD denominated credit capacity that the pool provides to the market.
         * Value per share: Debt per dollar of credit that the associated external market accrues.
         *
         */
        Distribution.Data poolsDebtDistribution;
        /**
         * @dev Additional info needed to remember pools when they are removed from the distribution (or subsequently re-added).
         */
        mapping(uint128 => MarketPoolInfo.Data) pools;
        /**
         * @dev Array of entries of market provided collateral.
         *
         * Markets may obtain additional liquidity, beyond that coming from depositors, by providing their own collateral.
         *
         */
        DepositedCollateral[] depositedCollateral;
        /**
         * @dev The maximum amount of market provided collateral, per type, that this market can deposit.
         */
        mapping(address => uint256) maximumDepositableD18;
    }

    /**
     * @dev Data structure that allows the Market to track the amount of market provided collateral, per type.
     */
    struct DepositedCollateral {
        address collateralType;
        uint256 amountD18;
    }

    /**
     * @dev Returns the market stored at the specified market id.
     */
    function load(uint128 id) internal pure returns (Data storage market) {
        bytes32 s = keccak256(abi.encode("io.synthetix.synthetix.Market", id));
        assembly {
            market.slot := s
        }
    }

    /**
     * @dev Queries the external market contract for the amount of debt it has issued.
     *
     * The reported debt of a market represents the amount of USD that the market would ask the system to mint, if all of its positions were to be immediately closed.
     *
     * The reported debt of a market is collateralized by the assets in the pools which back it.
     *
     * See the `IMarket` interface.
     */
    function getReportedDebt(Data storage self) internal view returns (uint256) {
        return IMarket(self.marketAddress).reportedDebt(self.id);
    }

    /**
     * @dev Queries the market for the amount of collateral which should be prevented from withdrawal.
     */
    function getLockedCreditCapacity(Data storage self) internal view returns (uint256) {
        return IMarket(self.marketAddress).locked(self.id);
    }

    /**
     * @dev Returns the total debt of the market.
     *
     * A market's total debt represents its debt plus its issuance, and thus represents the total outstanding debt of the market.
     *
     * Note: it also takes into account the deposited collateral value. See note in  getDepositedCollateralValue()
     *
     * Example:
     * (1 EUR = 1.11 USD)
     * If an Euro market has received 100 USD to mint 90 EUR, its reported debt is 90 EUR or 100 USD, and its issuance is -100 USD.
     * Thus, its total balance is 100 USD of reported debt minus 100 USD of issuance, which is 0 USD.
     *
     * Additionally, the market's totalDebt might be affected by price fluctuations via reportedDebt, or fees.
     *
     */
    function totalDebt(Data storage self) internal view returns (int256) {
        return
            getReportedDebt(self).toInt() +
            self.netIssuanceD18 -
            getDepositedCollateralValue(self).toInt();
    }

    /**
     * @dev Returns the USD value for the total amount of collateral provided by the market itself.
     *
     * Note: This is not credit capacity provided by depositors through pools.
     */
    function getDepositedCollateralValue(Data storage self) internal view returns (uint256) {
        uint256 totalDepositedCollateralValueD18 = 0;

        // Sweep all DepositedCollateral entries and aggregate their USD value.
        for (uint256 i = 0; i < self.depositedCollateral.length; i++) {
            DepositedCollateral memory entry = self.depositedCollateral[i];
            CollateralConfiguration.Data storage collateralConfiguration = CollateralConfiguration
                .load(entry.collateralType);

            if (entry.amountD18 == 0) {
                continue;
            }

            uint256 priceD18 = CollateralConfiguration.getCollateralPrice(collateralConfiguration);

            totalDepositedCollateralValueD18 += priceD18.mulDecimal(entry.amountD18);
        }

        return totalDepositedCollateralValueD18;
    }

    /**
     * @dev Returns the amount of credit capacity that a certain pool provides to the market.

     * This credit capacity is obtained by reading the amount of shares that the pool has in the market's debt distribution, which represents the amount of USD denominated credit capacity that the pool has provided to the market.
     */
    function getPoolCreditCapacity(
        Data storage self,
        uint128 poolId
    ) internal view returns (uint256) {
        return self.poolsDebtDistribution.getActorShares(poolId.toBytes32());
    }

    /**
     * @dev Given an amount of shares that represent USD credit capacity from a pool, and a maximum value per share, returns the potential contribution to credit capacity that these shares could accrue, if their value per share was to hit the maximum.
     *
     * The resulting value is calculated multiplying the amount of creditCapacity provided by the pool by the delta between the maxValue per share vs current value.
     *
     * This function is used when the Pools are rebalanced to adjust each pool credit capacity based on a change in the amount of shares provided and/or a new maxValue per share
     *
     */
    function getCreditCapacityContribution(
        Data storage self,
        uint256 creditCapacitySharesD18,
        int256 maxShareValueD18
    ) internal view returns (int256 contributionD18) {
        // Determine how much the current value per share deviates from the maximum.
        uint256 deltaValuePerShareD18 = (maxShareValueD18 -
            self.poolsDebtDistribution.getValuePerShare()).toUint();

        return deltaValuePerShareD18.mulDecimal(creditCapacitySharesD18).toInt();
    }

    /**
     * @dev Returns true if the market's current capacity is below the amount of locked capacity.
     *
     */
    function isCapacityLocked(Data storage self) internal view returns (bool) {
        return self.creditCapacityD18 < getLockedCreditCapacity(self).toInt();
    }

    /**
     * @dev Gets any outstanding debt. Do not call this method except in tests
     *
     * Note: This function should only be used in tests!
     */
    // solhint-disable-next-line private-vars-leading-underscore, func-name-mixedcase
    function _testOnly_getOutstandingDebt(
        Data storage self,
        uint128 poolId
    ) internal returns (int256 debtChangeD18) {
        return
            self.pools[poolId].pendingDebtD18.toInt() +
            self.poolsDebtDistribution.accumulateActor(poolId.toBytes32());
    }

    /**
     * Returns the number of pools currently active in the market
     *
     * Note: this is test only
     */
    // solhint-disable-next-line private-vars-leading-underscore, func-name-mixedcase
    function _testOnly_inRangePools(Data storage self) internal view returns (uint256) {
        return self.inRangePools.size();
    }

    /**
     * Returns the number of pools currently active in the market
     *
     * Note: this is test only
     */
    // solhint-disable-next-line private-vars-leading-underscore, func-name-mixedcase
    function _testOnly_outRangePools(Data storage self) internal view returns (uint256) {
        return self.outRangePools.size();
    }

    /**
     * @dev Returns the debt value per share
     */
    function getDebtPerShare(Data storage self) internal view returns (int256 debtPerShareD18) {
        return self.poolsDebtDistribution.getValuePerShare();
    }

    /**
     * @dev Wrapper that adjusts a pool's shares in the market's credit capacity, making sure that the market's outstanding debt is first passed on to its connected pools.
     *
     * Called by a pool when it distributes its debt.
     *
     */
    function rebalancePools(
        uint128 marketId,
        uint128 poolId,
        int256 maxDebtShareValueD18, // (in USD)
        uint256 newCreditCapacityD18 // in collateralValue (USD)
    ) internal returns (int256 debtChangeD18) {
        Data storage self = load(marketId);

        if (self.marketAddress == address(0)) {
            revert MarketNotFound(marketId);
        }

        // Iter avoids griefing - MarketManager can call this with user specified iters and thus clean up a grieved market.
        distributeDebtToPools(self, 9999999999);

        return adjustPoolShares(self, poolId, newCreditCapacityD18, maxDebtShareValueD18);
    }

    /**
     * @dev Called by pools when they modify the credit capacity provided to the market, as well as the maximum value per share they tolerate for the market.
     *
     * These two settings affect the market in the following ways:
     * - Updates the pool's shares in `poolsDebtDistribution`.
     * - Moves the pool in and out of inRangePools/outRangePools.
     * - Updates the market credit capacity property.
     */
    function adjustPoolShares(
        Data storage self,
        uint128 poolId,
        uint256 newCreditCapacityD18,
        int256 newPoolMaxShareValueD18
    ) internal returns (int256 debtChangeD18) {
        uint256 oldCreditCapacityD18 = getPoolCreditCapacity(self, poolId);
        int256 oldPoolMaxShareValueD18 = -self.inRangePools.getById(poolId).priority;

        // Sanity checks
        // require(oldPoolMaxShareValue == 0, "value is not 0");
        // require(newPoolMaxShareValue == 0, "new pool max share value is in fact set");

        self.pools[poolId].creditCapacityAmountD18 = newCreditCapacityD18.to128();

        int128 valuePerShareD18 = self.poolsDebtDistribution.getValuePerShare().to128();

        if (newCreditCapacityD18 == 0) {
            self.inRangePools.extractById(poolId);
            self.outRangePools.extractById(poolId);
        } else if (newPoolMaxShareValueD18 < valuePerShareD18) {
            // this will ensure calculations below can correctly gauge shares changes
            newCreditCapacityD18 = 0;
            self.inRangePools.extractById(poolId);
            self.outRangePools.insert(poolId, newPoolMaxShareValueD18.to128());
        } else {
            self.inRangePools.insert(poolId, -newPoolMaxShareValueD18.to128());
            self.outRangePools.extractById(poolId);
        }

        int256 changedValueD18 = self.poolsDebtDistribution.setActorShares(
            poolId.toBytes32(),
            newCreditCapacityD18
        );
        debtChangeD18 = self.pools[poolId].pendingDebtD18.toInt() + changedValueD18;
        self.pools[poolId].pendingDebtD18 = 0;

        // recalculate market capacity
        if (newPoolMaxShareValueD18 > valuePerShareD18) {
            self.creditCapacityD18 += getCreditCapacityContribution(
                self,
                newCreditCapacityD18,
                newPoolMaxShareValueD18
            ).to128();
        }

        if (oldPoolMaxShareValueD18 > valuePerShareD18) {
            self.creditCapacityD18 -= getCreditCapacityContribution(
                self,
                oldCreditCapacityD18,
                oldPoolMaxShareValueD18
            ).to128();
        }
    }

    /**
     * @dev Moves debt from the market into the pools that connect to it.
     *
     * This function should be called before any of the pools' shares are modified in `poolsDebtDistribution`.
     *
     * Note: The parameter `maxIter` is used as an escape hatch to discourage griefing.
     */
    function distributeDebtToPools(
        Data storage self,
        uint256 maxIter
    ) internal returns (bool fullyDistributed) {
        // Get the current and last distributed market balances.
        // Note: The last distributed balance will be cached within this function's execution.
        int256 targetBalanceD18 = totalDebt(self);
        int256 outstandingBalanceD18 = targetBalanceD18 - self.lastDistributedMarketBalanceD18;

        (, bool exhausted) = bumpPools(self, outstandingBalanceD18, maxIter);

        if (!exhausted && self.poolsDebtDistribution.totalSharesD18 > 0) {
            // cannot use `outstandingBalance` here because `self.lastDistributedMarketBalance`
            // may have changed after calling the bump functions above
            self.poolsDebtDistribution.distributeValue(
                targetBalanceD18 - self.lastDistributedMarketBalanceD18
            );
            self.lastDistributedMarketBalanceD18 = targetBalanceD18.to128();
        }

        return !exhausted;
    }

    /**
     * @dev Determine the target valuePerShare of the poolsDebtDistribution, given the value that is yet to be distributed.
     */
    function getTargetValuePerShare(
        Market.Data storage self,
        int256 valueToDistributeD18
    ) internal view returns (int256 targetValuePerShareD18) {
        return
            self.poolsDebtDistribution.getValuePerShare() +
            (
                self.poolsDebtDistribution.totalSharesD18 > 0
                    ? valueToDistributeD18.divDecimal(
                        self.poolsDebtDistribution.totalSharesD18.toInt()
                    ) // solhint-disable-next-line numcast/safe-cast
                    : int256(0)
            );
    }

    /**
     * @dev Finds pools for which this market's max value per share limit is hit, distributes their debt, and disconnects the market from them.
     *
     * The debt is distributed up to the limit of the max value per share that the pool tolerates on the market.
     */
    function bumpPools(
        Data storage self,
        int256 maxDistributedD18,
        uint256 maxIter
    ) internal returns (int256 actuallyDistributedD18, bool exhausted) {
        if (maxDistributedD18 == 0) {
            return (0, false);
        }

        // Determine the direction based on the amount to be distributed.
        int128 k;
        HeapUtil.Data storage fromHeap;
        HeapUtil.Data storage toHeap;
        if (maxDistributedD18 > 0) {
            k = 1;
            fromHeap = self.inRangePools;
            toHeap = self.outRangePools;
        } else {
            k = -1;
            fromHeap = self.outRangePools;
            toHeap = self.inRangePools;
        }

        // Note: This loop should rarely execute its main body. When it does, it only executes once for each pool that exceeds the limit since `distributeValue` is not run for most pools. Thus, market users are not hit with any overhead as a result of this.
        uint256 iters;
        for (iters = 0; iters < maxIter; iters++) {
            // Exit if there are no pools that can be moved
            if (fromHeap.size() == 0) {
                break;
            }

            // Identify the pool with the lowest maximum value per share.
            HeapUtil.Node memory edgePool = fromHeap.getMax();

            // 2 cases where we want to break out of this loop
            if (
                // If there is no pool in range, and we are going down
                (maxDistributedD18 - actuallyDistributedD18 > 0 &&
                    self.poolsDebtDistribution.totalSharesD18 == 0) ||
                // If there is a pool in ragne, and the lowest max value per share does not hit the limit, exit
                // Note: `-edgePool.priority` is actually the max value per share limit of the pool
                (self.poolsDebtDistribution.totalSharesD18 > 0 &&
                    -edgePool.priority >=
                    k * getTargetValuePerShare(self, (maxDistributedD18 - actuallyDistributedD18)))
            ) {
                break;
            }

            // The pool has hit its maximum value per share and needs to be removed.
            // Note: No need to update capacity because pool max share value = valuePerShare when this happens.
            togglePool(fromHeap, toHeap);

            // Distribute the market's debt to the limit, i.e. for that which exceeds the maximum value per share.
            if (self.poolsDebtDistribution.totalSharesD18 > 0) {
                int256 debtToLimitD18 = self
                    .poolsDebtDistribution
                    .totalSharesD18
                    .toInt()
                    .mulDecimal(
                        -k * edgePool.priority - self.poolsDebtDistribution.getValuePerShare() // Diff between current value and max value per share.
                    );
                self.poolsDebtDistribution.distributeValue(debtToLimitD18);

                // Update the global distributed and outstanding balances with the debt that was just distributed.
                actuallyDistributedD18 += debtToLimitD18;
            } else {
                self.poolsDebtDistribution.valuePerShareD27 = (-k * edgePool.priority)
                    .to256()
                    .upscale(DecimalMath.PRECISION_FACTOR)
                    .to128();
            }

            // Detach the market from this pool by removing the pool's shares from the market.
            // The pool will remain "detached" until the pool manager specifies a new poolsDebtDistribution.
            if (maxDistributedD18 > 0) {
                // the below requires are only for sanity
                require(
                    self.poolsDebtDistribution.getActorShares(edgePool.id.toBytes32()) > 0,
                    "no shares before actor removal"
                );

                uint256 newPoolDebtD18 = self
                    .poolsDebtDistribution
                    .setActorShares(edgePool.id.toBytes32(), 0)
                    .toUint();
                self.pools[edgePool.id].pendingDebtD18 += newPoolDebtD18.to128();
            } else {
                require(
                    self.poolsDebtDistribution.getActorShares(edgePool.id.toBytes32()) == 0,
                    "actor has shares before add"
                );

                self.poolsDebtDistribution.setActorShares(
                    edgePool.id.toBytes32(),
                    self.pools[edgePool.id].creditCapacityAmountD18
                );
            }
        }

        // Record the accumulated distributed balance.
        self.lastDistributedMarketBalanceD18 += actuallyDistributedD18.to128();

        exhausted = iters == maxIter;
    }

    /**
     * @dev Moves a pool from one heap into another.
     */
    function togglePool(HeapUtil.Data storage from, HeapUtil.Data storage to) internal {
        HeapUtil.Node memory node = from.extractMax();
        to.insert(node.id, -node.priority);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Tracks a market's weight within a Pool, and its maximum debt.
 *
 * Each pool has an array of these, with one entry per market managed by the pool.
 *
 * A market's weight determines how much liquidity the pool provides to the market, and how much debt exposure the market gives the pool.
 *
 * Weights are used to calculate percentages by adding all the weights in the pool and dividing the market's weight by the total weights.
 *
 * A market's maximum debt in a pool is indicated with a maximum debt value per share.
 */
library MarketConfiguration {
    struct Data {
        /**
         * @dev Numeric identifier for the market.
         *
         * Must be unique, and in a list of `MarketConfiguration[]`, must be increasing.
         */
        uint128 marketId;
        /**
         * @dev The ratio of each market's `weight` to the pool's `totalWeights` determines the pro-rata share of the market to the pool's total liquidity.
         */
        uint128 weightD18;
        /**
         * @dev Maximum value per share that a pool will tolerate for this market.
         *
         * If the the limit is met, the markets exceeding debt will be distributed, and it will be disconnected from the pool that no longer provides credit to it.
         *
         * Note: This value will have no effect if the system wide limit is hit first. See `PoolConfiguration.minLiquidityRatioD18`.
         */
        int128 maxDebtShareValueD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./Market.sol";

/**
 * @title Encapsulates market creation logic
 */
library MarketCreator {
    bytes32 private constant _SLOT_MARKET_CREATOR =
        keccak256(abi.encode("io.synthetix.synthetix.Markets"));

    struct Data {
        /**
         * @dev Tracks an array of market ids for each external IMarket address.
         */
        mapping(address => uint128[]) marketIdsForAddress;
        /**
         * @dev Keeps track of the last market id created.
         * Used for easily creating new markets.
         */
        uint128 lastCreatedMarketId;
    }

    /**
     * @dev Returns the singleton market store of the system.
     */
    function getMarketStore() internal pure returns (Data storage marketStore) {
        bytes32 s = _SLOT_MARKET_CREATOR;
        assembly {
            marketStore.slot := s
        }
    }

    /**
     * @dev Given an external contract address representing an `IMarket`, creates a new id for the market, and tracks it internally in the system.
     *
     * The id used to track the market will be automatically assigned by the system according to the last id used.
     *
     * Note: If an external `IMarket` contract tracks several market ids, this function should be called for each market it tracks, resulting in multiple ids for the same address.
     */
    function create(address marketAddress) internal returns (Market.Data storage market) {
        Data storage marketStore = getMarketStore();

        uint128 id = marketStore.lastCreatedMarketId;
        id++;

        market = Market.load(id);

        market.id = id;
        market.marketAddress = marketAddress;

        marketStore.lastCreatedMarketId = id;

        loadIdsByAddress(marketAddress).push(id);
    }

    /**
     * @dev Returns an array of market ids representing the markets linked to the system at a particular external contract address.
     *
     * Note: A contract implementing the `IMarket` interface may represent more than just one market, and thus several market ids could be associated to a single external contract address.
     */
    function loadIdsByAddress(address marketAddress) internal view returns (uint128[] storage ids) {
        return getMarketStore().marketIdsForAddress[marketAddress];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Stores information regarding a pool's relationship to a market, such that it can be added or removed from a distribution
 */
library MarketPoolInfo {
    struct Data {
        /**
         * @dev The credit capacity that this pool is providing to the relevant market. Needed to re-add the pool to the distribution when going back in range.
         */
        uint128 creditCapacityAmountD18;
        /**
         * @dev The amount of debt the pool has which hasn't been passed down the debt distribution chain yet.
         */
        uint128 pendingDebtD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Represents Oracle Manager
 */
library OracleManager {
    bytes32 private constant _SLOT_ORACLE_MANAGER =
        keccak256(abi.encode("io.synthetix.synthetix.OracleManager"));

    struct Data {
        /**
         * @dev The oracle manager address.
         */
        address oracleManagerAddress;
    }

    /**
     * @dev Loads the singleton storage info about the oracle manager.
     */
    function load() internal pure returns (Data storage oracleManager) {
        bytes32 s = _SLOT_ORACLE_MANAGER;
        assembly {
            oracleManager.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./Distribution.sol";
import "./MarketConfiguration.sol";
import "./Vault.sol";
import "./Market.sol";
import "./SystemPoolConfiguration.sol";

import "@synthetixio/core-contracts/contracts/errors/AccessError.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/**
 * @title Aggregates collateral from multiple users in order to provide liquidity to a configurable set of markets.
 *
 * The set of markets is configured as an array of MarketConfiguration objects, where the weight of the market can be specified. This weight, and the aggregated total weight of all the configured markets, determines how much collateral from the pool each market has, as well as in what proportion the market passes on debt to the pool and thus to all its users.
 *
 * The pool tracks the collateral provided by users using an array of Vaults objects, for which there will be one per collateral type. Each vault tracks how much collateral each user has delegated to this pool, how much debt the user has because of minting USD, as well as how much corresponding debt the pool has passed on to the user.
 */
library Pool {
    using CollateralConfiguration for CollateralConfiguration.Data;
    using Market for Market.Data;
    using Vault for Vault.Data;
    using Distribution for Distribution.Data;
    using DecimalMath for uint256;
    using DecimalMath for int256;
    using DecimalMath for int128;
    using SafeCastAddress for address;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;

    /**
     * @dev Thrown when the specified pool is not found.
     */
    error PoolNotFound(uint128 poolId);

    /**
     * @dev Thrown when attempting to create a pool that already exists.
     */
    error PoolAlreadyExists(uint128 poolId);

    struct Data {
        /**
         * @dev Numeric identifier for the pool. Must be unique.
         * @dev A pool with id zero exists! (See Pool.loadExisting()). Users can delegate to this pool to be able to mint USD without being exposed to fluctuating debt.
         */
        uint128 id;
        /**
         * @dev Text identifier for the pool.
         *
         * Not required to be unique.
         */
        string name;
        /**
         * @dev Creator of the pool, which has configuration access rights for the pool.
         *
         * See onlyPoolOwner.
         */
        address owner;
        /**
         * @dev Allows the current pool owner to nominate a new owner, and thus transfer pool configuration credentials.
         */
        address nominatedOwner;
        /**
         * @dev Sum of all market weights.
         *
         * Market weights are tracked in `MarketConfiguration.weight`, one for each market. The ratio of each market's `weight` to the pool's `totalWeights` determines the pro-rata share of the market to the pool's total liquidity.
         *
         * Reciprocally, this pro-rata share also determines how much the pool is exposed to each market's debt.
         */
        uint128 totalWeightsD18;
        /**
         * @dev Accumulated cache value of all vault collateral debts
         */
        int128 totalVaultDebtsD18;
        /**
         * @dev Array of markets connected to this pool, and their configurations. I.e. weight, etc.
         *
         * See totalWeights.
         */
        MarketConfiguration.Data[] marketConfigurations;
        /**
         * @dev A pool's debt distribution connects pools to the debt distribution chain, i.e. vaults and markets. Vaults are actors in the pool's debt distribution, where the amount of shares they possess depends on the amount of collateral each vault delegates to the pool.
         *
         * The debt distribution chain will move debt from markets into this pools, and then from pools to vaults.
         *
         * Actors: Vaults.
         * Shares: USD value, proportional to the amount of collateral that the vault delegates to the pool.
         * Value per share: Debt per dollar of collateral. Depends on aggregated debt of connected markets.
         *
         */
        Distribution.Data vaultsDebtDistribution;
        /**
         * @dev Reference to all the vaults that provide liquidity to this pool.
         *
         * Each collateral type will have its own vault, specific to this pool. I.e. if two pools both use SNX collateral, each will have its own SNX vault.
         *
         * Vaults track user collateral and debt using a debt distribution, which is connected to the debt distribution chain.
         */
        mapping(address => Vault.Data) vaults;
    }

    /**
     * @dev Returns the pool stored at the specified pool id.
     */
    function load(uint128 id) internal pure returns (Data storage pool) {
        bytes32 s = keccak256(abi.encode("io.synthetix.synthetix.Pool", id));
        assembly {
            pool.slot := s
        }
    }

    /**
     * @dev Creates a pool for the given pool id, and assigns the caller as its owner.
     *
     * Reverts if the specified pool already exists.
     */
    function create(uint128 id, address owner) internal returns (Pool.Data storage pool) {
        if (id == 0 || load(id).id == id) {
            revert PoolAlreadyExists(id);
        }

        pool = load(id);

        pool.id = id;
        pool.owner = owner;
    }

    /**
     * @dev Ticker function that updates the debt distribution chain downwards, from markets into the pool, according to each market's weight.
     *
     * It updates the chain by performing these actions:
     * - Splits the pool's total liquidity of the pool into each market, pro-rata. The amount of shares that the pool has on each market depends on how much liquidity the pool provides to the market.
     * - Accumulates the change in debt value from each market into the pools own vault debt distribution's value per share.
     */
    function distributeDebtToVaults(Data storage self) internal {
        uint256 totalWeightsD18 = self.totalWeightsD18;

        if (totalWeightsD18 == 0) {
            return; // Nothing to rebalance.
        }

        // Read from storage once, before entering the loop below.
        // These values should not change while iterating through each market.
        uint256 totalCreditCapacityD18 = self.vaultsDebtDistribution.totalSharesD18;
        int128 debtPerShareD18 = totalCreditCapacityD18 > 0 // solhint-disable-next-line numcast/safe-cast
            ? int(self.totalVaultDebtsD18).divDecimal(totalCreditCapacityD18.toInt()).to128() // solhint-disable-next-line numcast/safe-cast
            : int128(0);

        int256 cumulativeDebtChangeD18 = 0;

        uint256 minLiquidityRatioD18 = SystemPoolConfiguration.load().minLiquidityRatioD18;

        // Loop through the pool's markets, applying market weights, and tracking how this changes the amount of debt that this pool is responsible for.
        // This debt extracted from markets is then applied to the pool's vault debt distribution, which thus exposes debt to the pool's vaults.
        for (uint256 i = 0; i < self.marketConfigurations.length; i++) {
            MarketConfiguration.Data storage marketConfiguration = self.marketConfigurations[i];

            uint256 weightD18 = marketConfiguration.weightD18;

            // Calculate each market's pro-rata USD liquidity.
            // Note: the factor `(weight / totalWeights)` is not deduped in the operations below to maintain numeric precision.

            uint256 marketCreditCapacityD18 = (totalCreditCapacityD18 * weightD18) /
                totalWeightsD18;

            Market.Data storage marketData = Market.load(marketConfiguration.marketId);

            // Contain the pool imposed market's maximum debt share value.
            // Imposed by system.
            int256 effectiveMaxShareValueD18 = getSystemMaxValuePerShare(
                marketData.id,
                minLiquidityRatioD18,
                debtPerShareD18
            );
            // Imposed by pool.
            int256 configuredMaxShareValueD18 = marketConfiguration.maxDebtShareValueD18;
            effectiveMaxShareValueD18 = effectiveMaxShareValueD18 < configuredMaxShareValueD18
                ? effectiveMaxShareValueD18
                : configuredMaxShareValueD18;

            // Update each market's corresponding credit capacity.
            // The returned value represents how much the market's debt changed after changing the shares of this pool actor, which is aggregated to later be passed on the pools debt distribution.
            cumulativeDebtChangeD18 += Market.rebalancePools(
                marketConfiguration.marketId,
                self.id,
                effectiveMaxShareValueD18,
                marketCreditCapacityD18
            );
        }

        // Passes on the accumulated debt changes from the markets, into the pool, so that vaults can later access this debt.
        self.vaultsDebtDistribution.distributeValue(cumulativeDebtChangeD18);
    }

    /**
     * @dev Determines the resulting maximum value per share for a market, according to a system-wide minimum liquidity ratio. This prevents markets from assigning more debt to pools than they have collateral to cover.
     *
     * Note: There is a market-wide fail safe for each market at `MarketConfiguration.maxDebtShareValue`. The lower of the two values should be used.
     *
     * See `SystemPoolConfiguration.minLiquidityRatio`.
     */
    function getSystemMaxValuePerShare(
        uint128 marketId,
        uint256 minLiquidityRatioD18,
        int256 debtPerShareD18
    ) internal view returns (int256) {
        // Retrieve the current value per share of the market.
        Market.Data storage marketData = Market.load(marketId);
        int256 valuePerShareD18 = marketData.poolsDebtDistribution.getValuePerShare();

        // Calculate the margin of debt that the market would incur if it hit the system wide limit.
        uint256 marginD18 = minLiquidityRatioD18 == 0
            ? DecimalMath.UNIT
            : DecimalMath.UNIT.divDecimal(minLiquidityRatioD18);

        // The resulting maximum value per share is the distribution's value per share,
        // plus the margin to hit the limit, minus the current debt per share.
        return valuePerShareD18 + marginD18.toInt() - debtPerShareD18;
    }

    /**
     * @dev Reverts if the pool does not exist with appropriate error. Otherwise, returns the pool.
     */
    function loadExisting(uint128 id) internal view returns (Data storage) {
        Data storage p = load(id);
        if (id != 0 && p.id != id) {
            revert PoolNotFound(id);
        }

        return p;
    }

    /**
     * @dev Returns true if the pool is exposed to the specified market.
     */
    function hasMarket(Data storage self, uint128 marketId) internal view returns (bool) {
        for (uint256 i = 0; i < self.marketConfigurations.length; i++) {
            if (self.marketConfigurations[i].marketId == marketId) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Ticker function that updates the debt distribution chain for a specific collateral type downwards, from the pool into the corresponding the vault, according to changes in the collateral's price.
     *
     * It updates the chain by performing these actions:
     * - Collects the latest price of the corresponding collateral and updates the vault's liquidity.
     * - Updates the vaults shares in the pool's debt distribution, according to the collateral provided by the vault.
     * - Updates the value per share of the vault's debt distribution.
     */
    function recalculateVaultCollateral(
        Data storage self,
        address collateralType
    ) internal returns (uint256 collateralPriceD18) {
        // Update each market's pro-rata liquidity and collect accumulated debt into the pool's debt distribution.
        distributeDebtToVaults(self);

        // Transfer the debt change from the pool into the vault.
        bytes32 actorId = collateralType.toBytes32();
        self.vaults[collateralType].distributeDebtToAccounts(
            self.vaultsDebtDistribution.accumulateActor(actorId)
        );

        // Get the latest collateral price.
        collateralPriceD18 = CollateralConfiguration.load(collateralType).getCollateralPrice();

        // Changes in price update the corresponding vault's total collateral value as well as its liquidity (collateral - debt).
        (uint256 usdWeightD18, , int256 deltaDebtD18) = self
            .vaults[collateralType]
            .updateCreditCapacity(collateralPriceD18);

        // Update the vault's shares in the pool's debt distribution, according to the value of its collateral.
        self.vaultsDebtDistribution.setActorShares(actorId, usdWeightD18);

        // Accumulate the change in total liquidity, from the vault, into the pool.
        self.totalVaultDebtsD18 = self.totalVaultDebtsD18 + deltaDebtD18.to128();

        // Distribute debt again because the market credit capacity may have changed, so we should ensure the vaults have the most up to date capacities
        distributeDebtToVaults(self);
    }

    /**
     * @dev Updates the debt distribution chain for this pool, and consolidates the given account's debt.
     */
    function updateAccountDebt(
        Data storage self,
        address collateralType,
        uint128 accountId
    ) internal returns (int256 debtD18) {
        recalculateVaultCollateral(self, collateralType);

        return self.vaults[collateralType].consolidateAccountDebt(accountId);
    }

    /**
     * @dev Clears all vault data for the specified collateral type.
     */
    function resetVault(Data storage self, address collateralType) internal {
        // Creates a new epoch in the vault, effectively zeroing out all values.
        self.vaults[collateralType].reset();

        // Ensure that the vault's values update the debt distribution chain.
        recalculateVaultCollateral(self, collateralType);
    }

    /**
     * @dev Calculates the collateralization ratio of the vault that tracks the given collateral type.
     *
     * The c-ratio is the vault's share of the total debt of the pool, divided by the collateral it delegates to the pool.
     *
     * Note: This is not a view function. It updates the debt distribution chain before performing any calculations.
     */
    function currentVaultCollateralRatio(
        Data storage self,
        address collateralType
    ) internal returns (uint256) {
        int256 vaultDebtD18 = currentVaultDebt(self, collateralType);
        (, uint256 collateralValueD18) = currentVaultCollateral(self, collateralType);

        return vaultDebtD18 > 0 ? collateralValueD18.divDecimal(vaultDebtD18.toUint()) : 0;
    }

    /**
     * @dev Finds a connected market whose credit capacity has reached its locked limit.
     *
     * Note: Returns market zero (null market) if none is found.
     */
    function findMarketWithCapacityLocked(
        Data storage self
    ) internal view returns (Market.Data storage lockedMarket) {
        for (uint256 i = 0; i < self.marketConfigurations.length; i++) {
            Market.Data storage market = Market.load(self.marketConfigurations[i].marketId);

            if (market.isCapacityLocked()) {
                return market;
            }
        }

        // Market zero = null market.
        return Market.load(0);
    }

    /**
     * @dev Returns the debt of the vault that tracks the given collateral type.
     *
     * The vault's debt is the vault's share of the total debt of the pool, or its share of the total debt of the markets connected to the pool. The size of this share depends on how much collateral the pool provides to the pool.
     *
     * Note: This is not a view function. It updates the debt distribution chain before performing any calculations.
     */
    function currentVaultDebt(Data storage self, address collateralType) internal returns (int256) {
        recalculateVaultCollateral(self, collateralType);

        return self.vaults[collateralType].currentDebt();
    }

    /**
     * @dev Returns the total amount and value of the specified collateral delegated to this pool.
     */
    function currentVaultCollateral(
        Data storage self,
        address collateralType
    ) internal view returns (uint256 collateralAmountD18, uint256 collateralValueD18) {
        uint256 collateralPriceD18 = CollateralConfiguration
            .load(collateralType)
            .getCollateralPrice();

        collateralAmountD18 = self.vaults[collateralType].currentCollateral();
        collateralValueD18 = collateralPriceD18.mulDecimal(collateralAmountD18);
    }

    /**
     * @dev Returns the amount and value of collateral that the specified account has delegated to this pool.
     */
    function currentAccountCollateral(
        Data storage self,
        address collateralType,
        uint128 accountId
    ) internal view returns (uint256 collateralAmountD18, uint256 collateralValueD18) {
        uint256 collateralPriceD18 = CollateralConfiguration
            .load(collateralType)
            .getCollateralPrice();

        collateralAmountD18 = self.vaults[collateralType].currentAccountCollateral(accountId);
        collateralValueD18 = collateralPriceD18.mulDecimal(collateralAmountD18);
    }

    /**
     * @dev Returns the specified account's collateralization ratio (collateral / debt).
     * @dev If the account's debt is negative or zero, returns an "infinite" c-ratio.
     */
    function currentAccountCollateralRatio(
        Data storage self,
        address collateralType,
        uint128 accountId
    ) internal returns (uint256) {
        int256 positionDebtD18 = updateAccountDebt(self, collateralType, accountId);
        if (positionDebtD18 <= 0) {
            return type(uint256).max;
        }

        (, uint256 positionCollateralValueD18) = currentAccountCollateral(
            self,
            collateralType,
            accountId
        );

        return positionCollateralValueD18.divDecimal(positionDebtD18.toUint());
    }

    /**
     * @dev Reverts if the caller is not the owner of the specified pool.
     */
    function onlyPoolOwner(uint128 poolId, address caller) internal view {
        if (Pool.load(poolId).owner != caller) {
            revert AccessError.Unauthorized(caller);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/errors/ParameterError.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "../interfaces/external/IRewardDistributor.sol";

import "./Distribution.sol";
import "./RewardDistributionClaimStatus.sol";

/**
 * @title Used by vaults to track rewards for its participants. There will be one of these for each pool, collateral type, and distributor combination.
 */
library RewardDistribution {
    using DecimalMath for int256;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using SafeCastU64 for uint64;
    using SafeCastU32 for uint32;
    using SafeCastI32 for int32;

    struct Data {
        /**
         * @dev The 3rd party smart contract which holds/mints tokens for distributing rewards to vault participants.
         */
        IRewardDistributor distributor;
        /**
         * @dev Available slot.
         */
        uint128 __slotAvailableForFutureUse;
        /**
         * @dev The value of the rewards in this entry.
         */
        uint128 rewardPerShareD18;
        /**
         * @dev The status for each actor, regarding this distribution's entry.
         */
        mapping(uint256 => RewardDistributionClaimStatus.Data) claimStatus;
        /**
         * @dev Value to be distributed as rewards in a scheduled form.
         */
        int128 scheduledValueD18;
        /**
         * @dev Date at which the entry's rewards will begin to be claimable.
         *
         * Note: Set to <= block.timestamp to distribute immediately to currently participating users.
         */
        uint64 start;
        /**
         * @dev Time span after the start date, in which the whole of the entry's rewards will become claimable.
         */
        uint32 duration;
        /**
         * @dev Date on which this distribution entry was last updated.
         */
        uint32 lastUpdate;
    }

    /**
     * @dev Distributes rewards into a new rewards distribution entry.
     *
     * Note: this function allows for more special cases such as distributing at a future date or distributing over time.
     * If you want to apply the distribution to the pool, call `distribute` with the return value. Otherwise, you can
     * record this independently as well.
     */
    function distribute(
        Data storage self,
        Distribution.Data storage dist,
        int256 amountD18,
        uint64 start,
        uint32 duration
    ) internal returns (int256 diffD18) {
        uint256 totalSharesD18 = dist.totalSharesD18;

        if (totalSharesD18 == 0) {
            revert ParameterError.InvalidParameter(
                "amount",
                "can't distribute to empty distribution"
            );
        }

        uint256 curTime = block.timestamp;

        // Unlocks the entry's distributed amount into its value per share.
        diffD18 += updateEntry(self, totalSharesD18);

        // If the current time is past the end of the entry's duration,
        // update any rewards which may have accrued since last run.
        // (instant distribution--immediately disperse amount).
        if (start + duration <= curTime) {
            diffD18 += amountD18.divDecimal(totalSharesD18.toInt());

            self.lastUpdate = 0;
            self.start = 0;
            self.duration = 0;
            self.scheduledValueD18 = 0;
            // Else, schedule the amount to distribute.
        } else {
            self.scheduledValueD18 = amountD18.to128();

            self.start = start;
            self.duration = duration;

            // The amount is actually the amount distributed already *plus* whatever has been specified now.
            self.lastUpdate = 0;

            diffD18 += updateEntry(self, totalSharesD18);
        }
    }

    /**
     * @dev Updates the total shares of a reward distribution entry, and releases its unlocked value into its value per share, depending on the time elapsed since the start of the distribution's entry.
     *
     * Note: call every time before `totalShares` changes.
     */
    function updateEntry(
        Data storage self,
        uint256 totalSharesAmountD18
    ) internal returns (int256) {
        // Cannot process distributed rewards if a pool is empty or if it has no rewards.
        if (self.scheduledValueD18 == 0 || totalSharesAmountD18 == 0) {
            return 0;
        }

        uint256 curTime = block.timestamp;

        int256 valuePerShareChangeD18 = 0;

        // Cannot update an entry whose start date has not being reached.
        if (curTime < self.start) {
            return 0;
        }

        // If the entry's duration is zero and the its last update is zero,
        // consider the entry to be an instant distribution.
        if (self.duration == 0 && self.lastUpdate < self.start) {
            // Simply update the value per share to the total value divided by the total shares.
            valuePerShareChangeD18 = self.scheduledValueD18.to256().divDecimal(
                totalSharesAmountD18.toInt()
            );
            // Else, if the last update was before the end of the duration.
        } else if (self.lastUpdate < self.start + self.duration) {
            // Determine how much was previously distributed.
            // If the last update is zero, then nothing was distributed,
            // otherwise the amount is proportional to the time elapsed since the start.
            int256 lastUpdateDistributedD18 = self.lastUpdate < self.start
                ? SafeCastI128.zero()
                : (self.scheduledValueD18 * (self.lastUpdate - self.start).toInt()) /
                    self.duration.toInt();

            // If the current time is beyond the duration, then consider all scheduled value to be distributed.
            // Else, the amount distributed is proportional to the elapsed time.
            int256 curUpdateDistributedD18 = self.scheduledValueD18;
            if (curTime < self.start + self.duration) {
                // Note: Not using an intermediate time ratio variable
                // in the following calculation to maintain precision.
                curUpdateDistributedD18 =
                    (curUpdateDistributedD18 * (curTime - self.start).toInt()) /
                    self.duration.toInt();
            }

            // The final value per share change is the difference between what is to be distributed and what was distributed.
            valuePerShareChangeD18 = (curUpdateDistributedD18 - lastUpdateDistributedD18)
                .divDecimal(totalSharesAmountD18.toInt());
        }

        self.lastUpdate = curTime.to32();

        return valuePerShareChangeD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Tracks information per actor within a RewardDistribution.
 */
library RewardDistributionClaimStatus {
    struct Data {
        /**
         * @dev The last known reward per share for this actor.
         */
        uint128 lastRewardPerShareD18;
        /**
         * @dev The amount of rewards pending to be claimed by this actor.
         */
        uint128 pendingSendD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/**
 * @title Data structure that wraps a mapping with a scalar multiplier.
 *
 * If you wanted to modify all the values in a mapping by the same amount, you would normally have to loop through each entry in the mapping. This object allows you to modify all of them at once, by simply modifying the scalar multiplier.
 *
 * I.e. a regular mapping represents values like this:
 * value = mapping[id]
 *
 * And a scalable mapping represents values like this:
 * value = mapping[id] * scalar
 *
 * This reduces the number of computations needed for modifying the balances of N users from O(n) to O(1).

 * Note: Notice how users are tracked by a generic bytes32 id instead of an address. This allows the actors of the mapping not just to be addresses. They can be anything, for example a pool id, an account id, etc.
 *
 * *********************
 * Conceptual Examples
 * *********************
 *
 * 1) Socialization of collateral during a liquidation.
 *
 * Scalable mappings are very useful for "socialization" of collateral, that is, the re-distribution of collateral when an account is liquidated. Suppose 1000 ETH are liquidated, and would need to be distributed amongst 1000 depositors. With a regular mapping, every depositor's balance would have to be modified in a loop that iterates through every single one of them. With a scalable mapping, the scalar would simply need to be incremented so that the total value of the mapping increases by 1000 ETH.
 *
 * 2) Socialization of debt during a liquidation.
 *
 * Similar to the socialization of collateral during a liquidation, the debt of the position that is being liquidated can be re-allocated using a scalable mapping with a single action. Supposing a scalable mapping tracks each user's debt in the system, and that 1000 sUSD has to be distributed amongst 1000 depositors, the debt data structure's scalar would simply need to be incremented so that the total value or debt of the distribution increments by 1000 sUSD.
 *
 */
library ScalableMapping {
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using DecimalMath for int256;
    using DecimalMath for uint256;

    /**
     * @dev Thrown when attempting to scale a mapping with an amount that is lower than its resolution.
     */
    error InsufficientMappedAmount();

    /**
     * @dev Thrown when attempting to scale a mapping with no shares.
     */
    error CannotScaleEmptyMapping();

    struct Data {
        uint128 totalSharesD18;
        int128 scaleModifierD27;
        mapping(bytes32 => uint256) sharesD18;
    }

    /**
     * @dev Inflates or deflates the total value of the distribution by the given value.
     * @dev The incoming value is split per share, and used as a delta that is *added* to the existing scale modifier. The resulting scale modifier must be in the range [-1, type(int128).max).
     */
    function scale(Data storage self, int256 valueD18) internal {
        if (valueD18 == 0) {
            return;
        }

        uint256 totalSharesD18 = self.totalSharesD18;
        if (totalSharesD18 == 0) {
            revert CannotScaleEmptyMapping();
        }

        int256 valueD45 = valueD18 * DecimalMath.UNIT_PRECISE_INT;
        int256 deltaScaleModifierD27 = valueD45 / totalSharesD18.toInt();

        self.scaleModifierD27 += deltaScaleModifierD27.to128();

        if (self.scaleModifierD27 < -DecimalMath.UNIT_PRECISE_INT) {
            revert InsufficientMappedAmount();
        }
    }

    /**
     * @dev Updates an actor's individual value in the distribution to the specified amount.
     *
     * The change in value is manifested in the distribution by changing the actor's number of shares in it, and thus the distribution's total number of shares.
     *
     * Returns the resulting amount of shares that the actor has after this change in value.
     */
    function set(
        Data storage self,
        bytes32 actorId,
        uint256 newActorValueD18
    ) internal returns (uint256 resultingSharesD18) {
        // Represent the actor's change in value by changing the actor's number of shares,
        // and keeping the distribution's scaleModifier constant.

        resultingSharesD18 = getSharesForAmount(self, newActorValueD18);

        // Modify the total shares with the actor's change in shares.
        self.totalSharesD18 = (self.totalSharesD18 + resultingSharesD18 - self.sharesD18[actorId])
            .to128();

        self.sharesD18[actorId] = resultingSharesD18.to128();
    }

    /**
     * @dev Returns the value owned by the actor in the distribution.
     *
     * i.e. actor.shares * scaleModifier
     */
    function get(Data storage self, bytes32 actorId) internal view returns (uint256 valueD18) {
        uint256 totalSharesD18 = self.totalSharesD18;
        if (totalSharesD18 == 0) {
            return 0;
        }

        return (self.sharesD18[actorId] * totalAmount(self)) / totalSharesD18;
    }

    /**
     * @dev Returns the total value held in the distribution.
     *
     * i.e. totalShares * scaleModifier
     */
    function totalAmount(Data storage self) internal view returns (uint256 valueD18) {
        return
            ((self.scaleModifierD27 + DecimalMath.UNIT_PRECISE_INT).toUint() *
                self.totalSharesD18) / DecimalMath.UNIT_PRECISE;
    }

    function getSharesForAmount(
        Data storage self,
        uint256 amountD18
    ) internal view returns (uint256 sharesD18) {
        sharesD18 =
            (amountD18 * DecimalMath.UNIT_PRECISE) /
            (self.scaleModifierD27 + DecimalMath.UNIT_PRECISE_INT128).toUint();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";

/**
 * @title System wide configuration for pools.
 */
library SystemPoolConfiguration {
    bytes32 private constant _SLOT_SYSTEM_POOL_CONFIGURATION =
        keccak256(abi.encode("io.synthetix.synthetix.SystemPoolConfiguration"));

    struct Data {
        /**
         * @dev Owner specified system-wide limiting factor that prevents markets from minting too much debt, similar to the issuance ratio to a collateral type.
         *
         * Note: If zero, then this value defaults to 100%.
         */
        uint256 minLiquidityRatioD18;
        uint128 __reservedForFutureUse;
        /**
         * @dev Id of the main pool set by the system owner.
         */
        uint128 preferredPool;
        /**
         * @dev List of pools approved by the system owner.
         */
        SetUtil.UintSet approvedPools;
    }

    /**
     * @dev Returns the configuration singleton.
     */
    function load() internal pure returns (Data storage systemPoolConfiguration) {
        bytes32 s = _SLOT_SYSTEM_POOL_CONFIGURATION;
        assembly {
            systemPoolConfiguration.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./VaultEpoch.sol";
import "./RewardDistribution.sol";

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/**
 * @title Tracks collateral and debt distributions in a pool, for a specific collateral type.
 *
 * I.e. if a pool supports SNX and ETH collaterals, it will have an SNX Vault, and an ETH Vault.
 *
 * The Vault data structure is itself split into VaultEpoch sub-structures. This facilitates liquidations,
 * so that whenever one occurs, a clean state of all data is achieved by simply incrementing the epoch index.
 *
 * It is recommended to understand VaultEpoch before understanding this object.
 */
library Vault {
    using VaultEpoch for VaultEpoch.Data;
    using Distribution for Distribution.Data;
    using RewardDistribution for RewardDistribution.Data;
    using ScalableMapping for ScalableMapping.Data;
    using DecimalMath for uint256;
    using DecimalMath for int128;
    using DecimalMath for int256;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using SetUtil for SetUtil.Bytes32Set;

    /**
     * @dev Thrown when a non-existent reward distributor is referenced
     */
    error RewardDistributorNotFound();

    struct Data {
        /**
         * @dev The vault's current epoch number.
         *
         * Vault data is divided into epochs. An epoch changes when an entire vault is liquidated.
         */
        uint256 epoch;
        /**
         * @dev Unused property, maintained for backwards compatibility in storage layout.
         */
        // solhint-disable-next-line private-vars-leading-underscore
        bytes32 __slotAvailableForFutureUse;
        /**
         * @dev The previous debt of the vault, when `updateCreditCapacity` was last called by the Pool.
         */
        int128 prevTotalDebtD18;
        /**
         * @dev Vault data for all the liquidation cycles divided into epochs.
         */
        mapping(uint256 => VaultEpoch.Data) epochData;
        /**
         * @dev Tracks available rewards, per user, for this vault.
         */
        mapping(bytes32 => RewardDistribution.Data) rewards;
        /**
         * @dev Tracks reward ids, for this vault.
         */
        SetUtil.Bytes32Set rewardIds;
    }

    /**
     * @dev Return's the VaultEpoch data for the current epoch.
     */
    function currentEpoch(Data storage self) internal view returns (VaultEpoch.Data storage) {
        return self.epochData[self.epoch];
    }

    /**
     * @dev Updates the vault's credit capacity as the value of its collateral minus its debt.
     *
     * Called as a ticker when users interact with pools, allowing pools to set
     * vaults' credit capacity shares within them.
     *
     * Returns the amount of collateral that this vault is providing in net USD terms.
     */
    function updateCreditCapacity(
        Data storage self,
        uint256 collateralPriceD18
    ) internal returns (uint256 usdWeightD18, int256 totalDebtD18, int256 deltaDebtD18) {
        VaultEpoch.Data storage epochData = currentEpoch(self);

        usdWeightD18 = (epochData.collateralAmounts.totalAmount()).mulDecimal(collateralPriceD18);

        totalDebtD18 = epochData.totalDebt();

        deltaDebtD18 = totalDebtD18 - self.prevTotalDebtD18;

        self.prevTotalDebtD18 = totalDebtD18.to128();
    }

    /**
     * @dev Updated the value per share of the current epoch's incoming debt distribution.
     */
    function distributeDebtToAccounts(Data storage self, int256 debtChangeD18) internal {
        currentEpoch(self).distributeDebtToAccounts(debtChangeD18);
    }

    /**
     * @dev Consolidates an accounts debt.
     */
    function consolidateAccountDebt(
        Data storage self,
        uint128 accountId
    ) internal returns (int256) {
        return currentEpoch(self).consolidateAccountDebt(accountId);
    }

    /**
     * @dev Traverses available rewards for this vault, and updates an accounts
     * claim on them according to the amount of debt shares they have.
     */
    function updateRewards(
        Data storage self,
        uint128 accountId
    ) internal returns (uint256[] memory, address[] memory) {
        uint256[] memory rewards = new uint256[](self.rewardIds.length());
        address[] memory distributors = new address[](self.rewardIds.length());

        uint256 numRewards = self.rewardIds.length();
        for (uint256 i = 0; i < numRewards; i++) {
            RewardDistribution.Data storage dist = self.rewards[self.rewardIds.valueAt(i + 1)];

            if (address(dist.distributor) == address(0)) {
                continue;
            }

            rewards[i] = updateReward(self, accountId, self.rewardIds.valueAt(i + 1));
            distributors[i] = address(dist.distributor);
        }

        return (rewards, distributors);
    }

    /**
     * @dev Traverses available rewards for this vault and the reward id, and updates an accounts
     * claim on them according to the amount of debt shares they have.
     */
    function updateReward(
        Data storage self,
        uint128 accountId,
        bytes32 rewardId
    ) internal returns (uint256) {
        uint256 totalSharesD18 = currentEpoch(self).accountsDebtDistribution.totalSharesD18;
        uint256 actorSharesD18 = currentEpoch(self).accountsDebtDistribution.getActorShares(
            accountId.toBytes32()
        );

        RewardDistribution.Data storage dist = self.rewards[rewardId];

        if (address(dist.distributor) == address(0)) {
            revert RewardDistributorNotFound();
        }

        dist.rewardPerShareD18 += dist.updateEntry(totalSharesD18).toUint().to128();

        dist.claimStatus[accountId].pendingSendD18 += actorSharesD18
            .mulDecimal(dist.rewardPerShareD18 - dist.claimStatus[accountId].lastRewardPerShareD18)
            .to128();

        dist.claimStatus[accountId].lastRewardPerShareD18 = dist.rewardPerShareD18;

        return dist.claimStatus[accountId].pendingSendD18;
    }

    /**
     * @dev Increments the current epoch index, effectively producing a
     * completely blank new VaultEpoch data structure in the vault.
     */
    function reset(Data storage self) internal {
        self.epoch++;
    }

    /**
     * @dev Returns the vault's combined debt (consolidated and unconsolidated),
     * for the current epoch.
     */
    function currentDebt(Data storage self) internal view returns (int256) {
        return currentEpoch(self).totalDebt();
    }

    /**
     * @dev Returns the total value in the Vault's collateral distribution, for the current epoch.
     */
    function currentCollateral(Data storage self) internal view returns (uint256) {
        return currentEpoch(self).collateralAmounts.totalAmount();
    }

    /**
     * @dev Returns an account's collateral value in this vault's current epoch.
     */
    function currentAccountCollateral(
        Data storage self,
        uint128 accountId
    ) internal view returns (uint256) {
        return currentEpoch(self).getAccountCollateral(accountId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./Distribution.sol";
import "./ScalableMapping.sol";

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/**
 * @title Tracks collateral and debt distributions in a pool, for a specific collateral type, in a given epoch.
 *
 * Collateral is tracked with a distribution as opposed to a regular mapping because liquidations cause collateral to be socialized. If collateral was tracked using a regular mapping, such socialization would be difficult and require looping through individual balances, or some other sort of complex and expensive mechanism. Distributions make socialization easy.
 *
 * Debt is also tracked in a distribution for the same reason, but it is additionally split in two distributions: incoming and consolidated debt.
 *
 * Incoming debt is modified when a liquidations occurs.
 * Consolidated debt is updated when users interact with the system.
 */
library VaultEpoch {
    using Distribution for Distribution.Data;
    using DecimalMath for uint256;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using ScalableMapping for ScalableMapping.Data;

    struct Data {
        /**
         * @dev Amount of debt in this Vault that is yet to be consolidated.
         *
         * E.g. when a given amount of debt is socialized during a liquidation, but it yet hasn't been rolled into
         * the consolidated debt distribution.
         */
        int128 unconsolidatedDebtD18;
        /**
         * @dev Amount of debt in this Vault that has been consolidated.
         */
        int128 totalConsolidatedDebtD18;
        /**
         * @dev Tracks incoming debt for each user.
         *
         * The value of shares in this distribution change as the associate market changes, i.e. price changes in an asset in
         * a spot market.
         *
         * Also, when debt is socialized in a liquidation, it is done onto this distribution. As users
         * interact with the system, their independent debt is consolidated or rolled into consolidatedDebtDist.
         */
        Distribution.Data accountsDebtDistribution;
        /**
         * @dev Tracks collateral delegated to this vault, for each user.
         *
         * Uses a distribution instead of a regular market because of the way collateral is socialized during liquidations.
         *
         * A regular mapping would require looping over the mapping of each account's collateral, or moving the liquidated
         * collateral into a place where it could later be claimed. With a distribution, liquidated collateral can be
         * socialized very easily.
         */
        ScalableMapping.Data collateralAmounts;
        /**
         * @dev Tracks consolidated debt for each user.
         *
         * Updated when users interact with the system, consolidating changes from the fluctuating accountsDebtDistribution,
         * and directly when users mint or burn USD, or repay debt.
         */
        mapping(uint256 => int256) consolidatedDebtAmountsD18;
    }

    /**
     * @dev Updates the value per share of the incoming debt distribution.
     * Used for socialization during liquidations, and to bake in market changes.
     *
     * Called from:
     * - LiquidationModule.liquidate
     * - Pool.recalculateVaultCollateral (ticker)
     */
    function distributeDebtToAccounts(Data storage self, int256 debtChangeD18) internal {
        self.accountsDebtDistribution.distributeValue(debtChangeD18);

        // Cache total debt here.
        // Will roll over to individual users as they interact with the system.
        self.unconsolidatedDebtD18 += debtChangeD18.to128();
    }

    /**
     * @dev Adjusts the debt associated with `accountId` by `amountD18`.
     * Used to add or remove debt from/to a specific account, instead of all accounts at once (use distributeDebtToAccounts for that)
     */
    function assignDebtToAccount(
        Data storage self,
        uint128 accountId,
        int256 amountD18
    ) internal returns (int256 newDebtD18) {
        int256 currentDebtD18 = self.consolidatedDebtAmountsD18[accountId];
        self.consolidatedDebtAmountsD18[accountId] += amountD18;
        self.totalConsolidatedDebtD18 += amountD18.to128();
        return currentDebtD18 + amountD18;
    }

    /**
     * @dev Consolidates user debt as they interact with the system.
     *
     * Fluctuating debt is moved from incoming to consolidated debt.
     *
     * Called as a ticker from various parts of the system, usually whenever the
     * real debt of a user needs to be known.
     */
    function consolidateAccountDebt(
        Data storage self,
        uint128 accountId
    ) internal returns (int256 currentDebtD18) {
        int256 newDebtD18 = self.accountsDebtDistribution.accumulateActor(accountId.toBytes32());

        currentDebtD18 = assignDebtToAccount(self, accountId, newDebtD18);
        self.unconsolidatedDebtD18 -= newDebtD18.to128();
    }

    /**
     * @dev Updates a user's collateral value, and sets their exposure to debt
     * according to the collateral they delegated and the leverage used.
     *
     * Called whenever a user's collateral changes.
     */
    function updateAccountPosition(
        Data storage self,
        uint128 accountId,
        uint256 collateralAmountD18,
        uint256 leverageD18
    ) internal {
        bytes32 actorId = accountId.toBytes32();

        // Ensure account debt is consolidated before we do next things.
        consolidateAccountDebt(self, accountId);

        self.collateralAmounts.set(actorId, collateralAmountD18);
        self.accountsDebtDistribution.setActorShares(
            actorId,
            self.collateralAmounts.sharesD18[actorId].mulDecimal(leverageD18)
        );
    }

    /**
     * @dev Returns the vault's total debt in this epoch, including the debt
     * that hasn't yet been consolidated into individual accounts.
     */
    function totalDebt(Data storage self) internal view returns (int256) {
        return self.unconsolidatedDebtD18 + self.totalConsolidatedDebtD18;
    }

    /**
     * @dev Returns an account's value in the Vault's collateral distribution.
     */
    function getAccountCollateral(
        Data storage self,
        uint128 accountId
    ) internal view returns (uint256 amountD18) {
        return self.collateralAmounts.get(accountId.toBytes32());
    }
}