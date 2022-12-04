//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AccessError {
    error Unauthorized(address addr);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library InitError {
    error AlreadyInitialized();
    error NotInitialized();
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../errors/InitError.sol";

abstract contract InitializableMixin {
    modifier onlyIfInitialized() {
        if (!_isInitialized()) {
            revert InitError.NotInitialized();
        }

        _;
    }

    modifier onlyIfNotInitialized() {
        if (_isInitialized()) {
            revert InitError.AlreadyInitialized();
        }

        _;
    }

    function _isInitialized() internal view virtual returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    error InsufficientAllowance(uint required, uint existing);
    error InsufficientBalance(uint required, uint existing);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address to, uint amount) external returns (bool);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
    function setApprovalForAll(address operator, bool approved) external;

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../errors/AccessError.sol";

library AuthorizableStorage {
    struct Data {
        address authorized;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("Authorizable"));
        assembly {
            // bytes32(uint(keccak256("io.synthetix.authorizable")) - 1)
            store.slot := s
        }
    }

    function onlyAuthorized() internal view {
        if (msg.sender != getAuthorized()) {
            revert AccessError.Unauthorized(msg.sender);
        }
    }

    function getAuthorized() internal view returns (address) {
        return AuthorizableStorage.load().authorized;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../errors/AccessError.sol";

library OwnableStorage {
    struct Data {
        bool initialized;
        address owner;
        address nominatedOwner;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("Ownable"));
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
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../errors/InitError.sol";
import "./ERC20Storage.sol";

/*
    Reference implementations:
    * OpenZeppelin - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
    * Rari-Capital - https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol
*/

contract ERC20 is IERC20 {
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

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

    function name() external view override returns (string memory) {
        return ERC20Storage.load().name;
    }

    function symbol() external view override returns (string memory) {
        return ERC20Storage.load().symbol;
    }

    function decimals() external view override returns (uint8) {
        return ERC20Storage.load().decimals;
    }

    function totalSupply() external view override returns (uint) {
        return ERC20Storage.load().totalSupply;
    }

    function allowance(address owner, address spender) public view override returns (uint) {
        return ERC20Storage.load().allowance[owner][spender];
    }

    function balanceOf(address owner) public view override returns (uint) {
        return ERC20Storage.load().balanceOf[owner];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        ERC20Storage.load().allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint amount
    ) external override returns (bool) {
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ERC20Storage {
    struct Data {
        string name;
        string symbol;
        uint8 decimals;
        mapping(address => uint256) balanceOf;
        mapping(address => mapping(address => uint256)) allowance;
        uint256 totalSupply;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("ERC20"));
        assembly {
            store.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC721Enumerable.sol";

/// @title NFT token identifying an Account
interface INftModule is IERC721Enumerable {
    /// @notice Returns if `initialize` has been called by the owner
    function isInitialized() external returns (bool);

    /// @notice Allows owner to initialize the token after attaching a proxy
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory uri
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";

/// @title ERC20 token for snxUSD
interface ITokenModule is IERC20 {
    /// @notice returns if `initialize` has been called by the owner
    function isInitialized() external returns (bool);

    /// @notice allows owner to initialize the token after attaching a proxy
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) external;

    /// @notice mints token amount to "to" address
    function mint(address to, uint amount) external;

    /// @notice burns token amount from "to" address
    function burn(address to, uint amount) external;

    /// @notice sets token amount allowance to spender by "from" address
    function setAllowance(
        address from,
        address spender,
        uint amount
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/initializable/InitializableMixin.sol";
import "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import "@synthetixio/core-contracts/contracts/token/ERC20.sol";
import "@synthetixio/core-contracts/contracts/errors/AccessError.sol";
import "../interfaces/ITokenModule.sol";

contract TokenModule is ITokenModule, ERC20, InitializableMixin {
    function _isInitialized() internal view override returns (bool) {
        return ERC20Storage.load().decimals != 0;
    }

    function isInitialized() external view returns (bool) {
        return _isInitialized();
    }

    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) public {
        OwnableStorage.onlyOwner();
        _initialize(tokenName, tokenSymbol, tokenDecimals);
    }

    function burn(address from, uint256 amount) external override {
        OwnableStorage.onlyOwner();
        _burn(from, amount);
    }

    function mint(address to, uint256 amount) external override {
        OwnableStorage.onlyOwner();
        _mint(to, amount);
    }

    function setAllowance(
        address from,
        address spender,
        uint amount
    ) external override {
        OwnableStorage.onlyOwner();
        ERC20Storage.load().allowance[from][spender] = amount;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ITokenModule.sol";
import "../interfaces/INftModule.sol";
import "@synthetixio/core-contracts/contracts/errors/InitError.sol";

library AssociatedSystem {
    struct Data {
        address proxy;
        address impl;
        bytes32 kind;
    }

    error MismatchAssociatedSystemKind(bytes32 expected, bytes32 actual);

    function load(bytes32 id) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("AssociatedSystem", id));
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

    function set(
        Data storage self,
        address proxy,
        address impl,
        bytes32 kind
    ) internal {
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
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

import "@synthetixio/core-modules/contracts/interfaces/ITokenModule.sol";

/**
 * @title Module for managing the snxUSD token as an associated system.
 */
interface IUSDTokenModule is ITokenModule {
    /**
     * @notice Allows the core system to burn stablecoins with transfer allowance.
     */
    function burnWithAllowance(
        address from,
        address spender,
        uint amount
    ) external;

    /**
     * @notice Allows users to transfer tokens cross-chain using CCIP. This is disabled until _CCIP_CHAINLINK_SEND is set in UtilsModule. This is currently included for testing purposes. Functionality will change, including fee collection, as CCIP continues development.
     */
    function transferCrossChain(
        uint destChainId,
        address,
        uint amount
    ) external returns (uint feesPaid);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/ownership/AuthorizableStorage.sol";
import "@synthetixio/core-modules/contracts/modules/TokenModule.sol";
import "../../interfaces/IUSDTokenModule.sol";
import "../../interfaces/external/IEVM2AnySubscriptionOnRampRouterInterface.sol";

import "@synthetixio/core-modules/contracts/storage/AssociatedSystem.sol";

/**
 * @title Module for managing the snxUSD token as an associated system.
 * @dev See IUSDTokenModule.
 */
contract USDTokenModule is ERC20, InitializableMixin, IUSDTokenModule {
    using AssociatedSystem for AssociatedSystem.Data;

    uint private constant _TRANSFER_GAS_LIMIT = 100000;

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
    function mint(address target, uint amount) external override {
        if (
            msg.sender != OwnableStorage.getOwner() && msg.sender != AssociatedSystem.load(_CCIP_CHAINLINK_TOKEN_POOL).proxy
        ) {
            revert AccessError.Unauthorized(msg.sender);
        }

        _mint(target, amount);
    }

    /**
     * @dev Allows the core system and CCIP to burn tokens.
     */
    function burn(address target, uint amount) external override {
        if (
            msg.sender != OwnableStorage.getOwner() && msg.sender != AssociatedSystem.load(_CCIP_CHAINLINK_TOKEN_POOL).proxy
        ) {
            revert AccessError.Unauthorized(msg.sender);
        }

        _burn(target, amount);
    }

    /**
     * @inheritdoc IUSDTokenModule
     */
    function burnWithAllowance(
        address from,
        address spender,
        uint amount
    ) external {
        OwnableStorage.onlyOwner();

        ERC20Storage.Data storage store = ERC20Storage.load();

        if (amount < store.allowance[from][spender]) {
            revert InsufficientAllowance(amount, store.allowance[from][spender]);
        }
        store.allowance[from][spender] -= amount;
        _burn(from, amount);
    }

    /**
     * @inheritdoc IUSDTokenModule
     */
    function transferCrossChain(
        uint destChainId,
        address to,
        uint amount
    ) external returns (uint feesPaid) {
        AssociatedSystem.load(_CCIP_CHAINLINK_SEND).expectKind(AssociatedSystem.KIND_UNMANAGED);

        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(address(this));

        uint[] memory amounts = new uint[](1);
        amounts[0] = amount;

        IEVM2AnySubscriptionOnRampRouterInterface(AssociatedSystem.load(_CCIP_CHAINLINK_SEND).proxy).ccipSend(
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
    function setAllowance(
        address from,
        address spender,
        uint amount
    ) external override {
        OwnableStorage.onlyOwner();
        ERC20Storage.load().allowance[from][spender] = amount;
    }
}