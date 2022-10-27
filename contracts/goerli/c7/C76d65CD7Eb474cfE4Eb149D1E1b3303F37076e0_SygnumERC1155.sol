/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: Unlicensed

/**
 * @title NFTFactory
 * @author Team 3301 <[email protected]>
 * @dev Factory to be used by operators to deploy arbitrary Sygnum ERC1155 contracts.
 */
pragma solidity ^0.8.8;

/**
 * @title SygnumERC1155
 * @author Team 3301 <[email protected]>
 * @dev Implementation of the ERC1155 standard with permissioned minting and custom supply logic.
 */

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized();

    /**
     * @dev Error: "Initializable: Contract instance has already been initialized"
     */
    error InitializableContractAlreadyInitialized();

    /**
     * @dev Error: "Initializable: Contract instance is initializing"
     */
    error InitializableContractIsInitializing();

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        bool isTopLevelCall = !initializing;

        if (isTopLevelCall && !isConstructor() && initialized) revert InitializableContractAlreadyInitialized();

        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
            emit Initialized();
        }
    }

    /**
     * @dev Returns true if and only if the function is running in the constructor
     */
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    /**
     * @dev Function that returns wheteher a contract is already initialized. Returns `initialized`
     */
    function isInitialized() public view virtual returns (bool) {
        return initialized;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        if (initializing) revert InitializableContractIsInitializing();
        if (!initialized) {
            initialized = true;
            emit Initialized();
        }
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

/**
 * @title Pausable
 * @author Team 3301 <[email protected]>
 * @dev Contract module which allows children to implement an emergency stop
 *      mechanism that can be triggered by an authorized account in the TraderOperatorable
 *      contract.
 */

/**
 * @title TraderOperatorable
 * @author Team 3301 <[email protected]>
 * @dev TraderOperatorable contract stores TraderOperators contract address, and modifiers for
 *      contracts.
 */

/**
 * @title ITraderOperators
 * @notice Interface for TraderOperators contract
 */

abstract contract ITraderOperators {
    function isTrader(address _account) external view virtual returns (bool);

    function addTrader(address _account) external virtual;

    function removeTrader(address _account) external virtual;
}

/**
 * @title Operatorable
 * @author Team 3301 <[email protected]>
 * @dev Operatorable contract stores the BaseOperators contract address, and modifiers for
 *       contracts.
 */

/**
 * @title IBaseOperators
 * @notice Interface for BaseOperators contract
 */

interface IBaseOperators {
    function isOperator(address _account) external view returns (bool);

    function isAdmin(address _account) external view returns (bool);

    function isSystem(address _account) external view returns (bool);

    function isRelay(address _account) external view returns (bool);

    function isMultisig(address _contract) external view returns (bool);

    function confirmFor(address _address) external;

    function addOperator(address _account) external;

    function removeOperator(address _account) external;

    function addAdmin(address _account) external;

    function removeAdmin(address _account) external;

    function addSystem(address _account) external;

    function removeSystem(address _account) external;

    function addRelay(address _account) external;

    function removeRelay(address _account) external;

    function addOperatorAndAdmin(address _account) external;

    function removeOperatorAndAdmin(address _account) external;
}

contract Operatorable is Initializable {
    IBaseOperators internal operatorsInst;
    address private operatorsPending;

    /**
     * @dev Error: "Operatorable: caller does not have the operator role"
     */
    error OperatorableCallerNotOperator();

    /**
     * @dev Error: "Operatorable: caller does not have the admin role"
     */
    error OperatorableCallerNotAdmin();

    /**
     * @dev Error: "Operatorable: caller does not have the system role"
     */
    error OperatorableCallerNotSystem();

    /**
     * @dev Error: "Operatorable: caller does not have the multisig role"
     */
    error OperatorableCallerNotMultisig();

    /**
     * @dev Error: "Operatorable: caller does not have the admin or system role"
     */
    error OperatorableCallerNotAdminOrSystem();

    /**
     * @dev Error: "Operatorable: caller does not have the operator role nor system"
     */
    error OperatorableCallerNotOperatorOrSystem();

    /**
     * @dev Error: "Operatorable: caller does not have the relay role"
     */
    error OperatorableCallerNotRelay();

    /**
     * @dev Error: "Operatorable: caller does not have the operator role nor relay"
     */
    error OperatorableCallerNotOperatorOrRelay();

    /**
     * @dev Error: "Operatorable: caller does not have the admin role nor relay"
     */
    error OperatorableCallerNotAdminOrRelay();

    /**
     * @dev Error: "Operatorable: caller does not have the operator role nor system nor relay"
     */
    error OperatorableCallerNotOperatorOrSystemOrRelay();

    /**
     * @dev Error: "OperatorableCallerNotOperator() nor admin nor relay"
     */
    error OperatorableCallerNotOperatorOrAdminOrRelay();

    /**
     * @dev Error: "Operatorable: address of new operators contract can not be zero"
     */
    error OperatorableNewOperatorsZeroAddress();

    /**
     * @dev Error: "Operatorable: should be called from new operators contract"
     */
    error OperatorableCallerNotOperatorsContract(address _caller);

    event OperatorsContractChanged(address indexed caller, address indexed operatorsAddress);
    event OperatorsContractPending(address indexed caller, address indexed operatorsAddress);

    /**
     * @dev Reverts if sender does not have operator role associated.
     */
    modifier onlyOperator() {
        if (!isOperator(msg.sender)) revert OperatorableCallerNotOperator();
        _;
    }

    /**
     * @dev Reverts if sender does not have admin role associated.
     */
    modifier onlyAdmin() {
        if (!isAdmin(msg.sender)) revert OperatorableCallerNotAdmin();
        _;
    }

    /**
     * @dev Reverts if sender does not have system role associated.
     */
    modifier onlySystem() {
        if (!isSystem(msg.sender)) revert OperatorableCallerNotSystem();
        _;
    }

    /**
     * @dev Reverts if sender does not have multisig privileges.
     */
    modifier onlyMultisig() {
        if (!isMultisig(msg.sender)) revert OperatorableCallerNotMultisig();
        _;
    }

    /**
     * @dev Reverts if sender does not have admin or system role associated.
     */
    modifier onlyAdminOrSystem() {
        if (!isAdminOrSystem(msg.sender)) revert OperatorableCallerNotAdminOrSystem();
        _;
    }

    /**
     * @dev Reverts if sender does not have operator or system role associated.
     */
    modifier onlyOperatorOrSystem() {
        if (!isOperatorOrSystem(msg.sender)) revert OperatorableCallerNotOperatorOrSystem();
        _;
    }

    /**
     * @dev Reverts if sender does not have the relay role associated.
     */
    modifier onlyRelay() {
        if (!isRelay(msg.sender)) revert OperatorableCallerNotRelay();
        _;
    }

    /**
     * @dev Reverts if sender does not have relay or operator role associated.
     */
    modifier onlyOperatorOrRelay() {
        if (!isOperator(msg.sender) && !isRelay(msg.sender)) revert OperatorableCallerNotOperatorOrRelay();
        _;
    }

    /**
     * @dev Reverts if sender does not have relay or admin role associated.
     */
    modifier onlyAdminOrRelay() {
        if (!isAdmin(msg.sender) && !isRelay(msg.sender)) revert OperatorableCallerNotAdminOrRelay();
        _;
    }

    /**
     * @dev Reverts if sender does not have the operator, or system, or relay role associated.
     */
    modifier onlyOperatorOrSystemOrRelay() {
        if (!isOperator(msg.sender) && !isSystem(msg.sender) && !isRelay(msg.sender))
            revert OperatorableCallerNotOperatorOrSystemOrRelay();
        _;
    }

    /**
     * @dev Reverts if sender does not have the operator, or admin, or relay role associated.
     */
    modifier onlyOperatorOrAdminOrRelay() {
        if (!isOperator(msg.sender) && !isAdmin(msg.sender) && !isRelay(msg.sender))
            revert OperatorableCallerNotOperatorOrAdminOrRelay();
        _;
    }

    /**
     * @dev Initialization instead of constructor, called once. The setOperatorsContract function can be called only by Admin role with
     *       confirmation through the operators contract.
     * @param _baseOperators BaseOperators contract address.
     */
    function initialize(address _baseOperators) public virtual initializer {
        _setOperatorsContract(_baseOperators);
    }

    /**
     * @dev Set the new the address of Operators contract, should be confirmed from operators contract by calling confirmFor(addr)
     *       where addr is the address of current contract instance. This is done to prevent the case when the new contract address is
     *       broken and control of the contract can be lost in such case
     * @param _baseOperators BaseOperators contract address.
     */
    function setOperatorsContract(address _baseOperators) public onlyAdmin {
        if (_baseOperators == address(0)) revert OperatorableNewOperatorsZeroAddress();

        operatorsPending = _baseOperators;
        emit OperatorsContractPending(msg.sender, _baseOperators);
    }

    /**
     * @dev The function should be called from new operators contract by admin to ensure that operatorsPending address
     *       is the real contract address.
     */
    function confirmOperatorsContract() public {
        if (operatorsPending == address(0)) revert OperatorableNewOperatorsZeroAddress();

        if (msg.sender != operatorsPending) revert OperatorableCallerNotOperatorsContract(msg.sender);

        _setOperatorsContract(operatorsPending);
    }

    /**
     * @return The address of the BaseOperators contract.
     */
    function getOperatorsContract() public view returns (address) {
        return address(operatorsInst);
    }

    /**
     * @return The pending address of the BaseOperators contract.
     */
    function getOperatorsPending() public view returns (address) {
        return operatorsPending;
    }

    /**
     * @return If '_account' has operator privileges.
     */
    function isOperator(address _account) public view returns (bool) {
        return operatorsInst.isOperator(_account);
    }

    /**
     * @return If '_account' has admin privileges.
     */
    function isAdmin(address _account) public view returns (bool) {
        return operatorsInst.isAdmin(_account);
    }

    /**
     * @return If '_account' has system privileges.
     */
    function isSystem(address _account) public view returns (bool) {
        return operatorsInst.isSystem(_account);
    }

    /**
     * @return If '_account' has relay privileges.
     */
    function isRelay(address _account) public view returns (bool) {
        return operatorsInst.isRelay(_account);
    }

    /**
     * @return If '_contract' has multisig privileges.
     */
    function isMultisig(address _contract) public view returns (bool) {
        return operatorsInst.isMultisig(_contract);
    }

    /**
     * @return If '_account' has admin or system privileges.
     */
    function isAdminOrSystem(address _account) public view returns (bool) {
        return (operatorsInst.isAdmin(_account) || operatorsInst.isSystem(_account));
    }

    /**
     * @return If '_account' has operator or system privileges.
     */
    function isOperatorOrSystem(address _account) public view returns (bool) {
        return (operatorsInst.isOperator(_account) || operatorsInst.isSystem(_account));
    }

    /** INTERNAL FUNCTIONS */
    function _setOperatorsContract(address _baseOperators) internal {
        if (_baseOperators == address(0)) revert OperatorableNewOperatorsZeroAddress();

        operatorsInst = IBaseOperators(_baseOperators);
        emit OperatorsContractChanged(msg.sender, _baseOperators);
    }
}

contract TraderOperatorable is Operatorable {
    ITraderOperators internal traderOperatorsInst;
    address private traderOperatorsPending;

    /**
     * @dev Error: "TraderOperatorable: caller is not trader"
     */
    error TraderOperatorableCallerNotTrader();

    /**
     * @dev Error: "TraderOperatorable: caller is not trader or operator or system"
     */
    error TraderOperatorableCallerNotTraderOrOperatorOrSystem();

    /**
     * @dev Error: "TraderOperatorable: address of new traderOperators contract can not be zero"
     */
    error TraderOperatorableNewTraderOperatorsAddressZero();

    /**
     * @dev Error: "TraderOperatorable: address of pending traderOperators contract can not be zero"
     */
    error TraderOperatorablePendingTraderOperatorsAddressZero();

    /**
     * @dev Error: "TraderOperatorable: should be called from new traderOperators contract"
     */
    error TraderOperatorableCallerNotNewTraderOperator();

    event TraderOperatorsContractChanged(address indexed caller, address indexed traderOperatorsAddress);
    event TraderOperatorsContractPending(address indexed caller, address indexed traderOperatorsAddress);

    /**
     * @dev Reverts if sender does not have the trader role associated.
     */
    modifier onlyTrader() {
        if (!isTrader(msg.sender)) revert TraderOperatorableCallerNotTrader();
        _;
    }

    /**
     * @dev Reverts if sender does not have the operator or trader role associated.
     */
    modifier onlyOperatorOrTraderOrSystem() {
        if (!isOperator(msg.sender) && !isTrader(msg.sender) && !isSystem(msg.sender))
            revert TraderOperatorableCallerNotTraderOrOperatorOrSystem();
        _;
    }

    /**
     * @dev Initialization instead of constructor, called once. The setTradersOperatorsContract function can be called only by Admin role with
     * confirmation through the operators contract.
     * @param _baseOperators BaseOperators contract address.
     * @param _traderOperators TraderOperators contract address.
     */
    function initialize(address _baseOperators, address _traderOperators) public virtual initializer {
        super.initialize(_baseOperators);
        _setTraderOperatorsContract(_traderOperators);
    }

    /**
     * @dev Set the new the address of Operators contract, should be confirmed from operators contract by calling confirmFor(addr)
     * where addr is the address of current contract instance. This is done to prevent the case when the new contract address is
     * broken and control of the contract can be lost in such case
     * @param _traderOperators TradeOperators contract address.
     */
    function setTraderOperatorsContract(address _traderOperators) public onlyAdmin {
        if (_traderOperators == address(0)) revert TraderOperatorableNewTraderOperatorsAddressZero();

        traderOperatorsPending = _traderOperators;
        emit TraderOperatorsContractPending(msg.sender, _traderOperators);
    }

    /**
     * @dev The function should be called from new operators contract by admin to insure that traderOperatorsPending address
     *       is the real contract address.
     */
    function confirmTraderOperatorsContract() public {
        if (traderOperatorsPending == address(0)) revert TraderOperatorablePendingTraderOperatorsAddressZero();
        if (msg.sender != traderOperatorsPending) revert TraderOperatorableCallerNotNewTraderOperator();

        _setTraderOperatorsContract(traderOperatorsPending);
    }

    /**
     * @return The address of the TraderOperators contract.
     */
    function getTraderOperatorsContract() public view returns (address) {
        return address(traderOperatorsInst);
    }

    /**
     * @return The pending TraderOperators contract address
     */
    function getTraderOperatorsPending() public view returns (address) {
        return traderOperatorsPending;
    }

    /**
     * @return If '_account' has trader privileges.
     */
    function isTrader(address _account) public view returns (bool) {
        return traderOperatorsInst.isTrader(_account);
    }

    /** INTERNAL FUNCTIONS */
    function _setTraderOperatorsContract(address _traderOperators) internal {
        if (_traderOperators == address(0)) revert TraderOperatorableNewTraderOperatorsAddressZero();

        traderOperatorsInst = ITraderOperators(_traderOperators);
        emit TraderOperatorsContractChanged(msg.sender, _traderOperators);
    }
}

abstract contract Pausable is TraderOperatorable {
    bool internal _paused;

    /**
     * @dev Error: "Pausable: paused"
     */
    error PausablePaused();

    /**
     * @dev Error: "Pausable: not paused"
     */
    error PausableNotPaused();

    event Paused(address indexed account);
    event Unpaused(address indexed account);

    // solhint-disable-next-line func-visibility
    constructor() {
        _paused = false;
    }

    /**
     * @dev Reverts if contract is paused.
     */
    modifier whenNotPaused() {
        if (_paused) revert PausablePaused();
        _;
    }

    /**
     * @dev Reverts if contract is paused.
     */
    modifier whenPaused() {
        if (!_paused) revert PausableNotPaused();
        _;
    }

    /**
     * @dev Called by operator to pause child contract. The contract
     *      must not already be paused.
     */
    function pause() public virtual onlyOperatorOrTraderOrSystem whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /** @dev Called by operator to pause child contract. The contract
     *       must already be paused.
     */
    function unpause() public virtual onlyOperatorOrTraderOrSystem whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @return If child contract is already paused or not.
     */
    function isPaused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @return If child contract is not paused.
     */
    function isNotPaused() public view virtual returns (bool) {
        return !_paused;
    }
}

/**
 * @title Sygnum implementation for the ERC1155 specification
 * @author Team 3301 <[email protected]>
 * @dev ERC1155 implementation with max token supplies in bytes hex format, initializer for proxy support,
 * as well as support for admin and operator roles
 */
contract SygnumERC1155 is Initializable, Operatorable, Pausable, ERC1155, ERC2981 {
    using Strings for uint256;

    event Initialized(uint256 _maxUniqueTokens, string _baseUri);

    error SygnumERC1155MintingNotStarted();
    error SygnumERC1155MintingEnded();
    error SygnumERC1155AmountExceedsMaxSupply();
    error SygnumERC1155InvalidTokenID();
    error SygnumERC1155InvalidBaseOperators();
    error SygnumERC1155MintingZeroAmount();
    error SygnumERC1155RoyaltyRecipientIsZeroAddress();
    error SygnumERC1155InvalidBaseUri();
    error SygnumERC1155InvalidMaxTokenSupplies();
    error SygnumERC1155InvalidMintDuration();
    error SygnumERC1155MismatchingInputSize();
    error SygnumERC1155BatchLimitExceeded();

    string public name;
    string public symbol;

    uint256 public constant BATCH_LIMIT = 256;

    mapping(uint256 => uint256) public tokenSupply;
    string public baseUri;

    // Launch date and minting period
    uint256 public startDate;
    uint256 public mintDuration;

    // Max amount of unique tokens
    uint256 public maxUniqueTokens;
    // Max amount of copies per token
    bytes public encodedMaxTokenSupplies;

    /**
     * @dev Modifier checking whether minting is open. If startDate is 0, then minting is always open.
     * If startDate is not 0, then minting is open between startDate and startDate + mintDuration.
     */
    modifier isMintOpen() {
        if (startDate > 0) {
            if (block.timestamp < startDate) revert SygnumERC1155MintingNotStarted();
            if (mintDuration > 0) {
                if (block.timestamp >= startDate + mintDuration) revert SygnumERC1155MintingEnded();
            }
        }
        _;
    }

    /**
     * @dev Prevent that the implementation gets accidentally initialized by malicious users
     */
    constructor() {
        super._disableInitializers();
    }

    /**
     * @dev Function returning the maximum supply for a specific token ID, decoding it from the bytes hex format
     * @param tokenId The token ID
     * @return res The maximum supply for tokenId
     */
    function maxTokenSupply(uint256 tokenId) public view virtual returns (uint256 res) {
        res = uint16(
            bytes2(abi.encodePacked(encodedMaxTokenSupplies[2 * tokenId], encodedMaxTokenSupplies[2 * tokenId + 1]))
        );
    }

    /**
     * @dev Implements the safeTransferFrom function while checking whether the contract is paused
     * @param from Sender account
     * @param to Recipient account
     * @param id Token ID
     * @param amount Amount of tokens to send
     * @param data Calldata to pass if recipient is contract
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual override {
        ERC1155.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev Implements the safeBatchTransferFrom function while checking whether the contract is paused
     * @param from Sender account
     * @param to Recipient account
     * @param ids Array of token IDs
     * @param amounts Array of amounts to send for each token
     * @param data Calldata to pass if recipient is contract
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override {
        if (ids.length > BATCH_LIMIT) {
            revert SygnumERC1155BatchLimitExceeded();
        }
        ERC1155.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Minting function which limits calls to operator accounts only
     * @param to Recipient account
     * @param id Token ID
     * @param amount Amount of tokens to mint
     * @param data Calldata to pass if recipient is contract
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external virtual onlyOperator {
        _mint(to, id, amount, data);
    }

    /**
     * @dev Batch minting function which limits calls to operator accounts only
     * @param to Recipient account
     * @param ids Array of token IDs
     * @param amounts Array of amounts to mint for each token
     * @param data Calldata to pass if recipient is contract
     */
    function batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external virtual onlyOperator {
        _batchMint(to, ids, amounts, data);
    }

    /**
     * @dev Internal minting function which limits minting to specified period (if startDate is 0, then mint is
     * always open, if mintDuration is 0 then sale is open-ended). Also checks whether token ID is valid and
     * whether minting exceeds max token supply
     * @param to Recipient account
     * @param id Token ID
     * @param amount Amount of tokens to mint
     * @param data Calldata to pass if recipient is contract
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override isMintOpen {
        if (amount == 0) revert SygnumERC1155MintingZeroAmount();

        if (id >= maxUniqueTokens) revert SygnumERC1155InvalidTokenID();
        if (tokenSupply[id] + amount > maxTokenSupply(id)) revert SygnumERC1155AmountExceedsMaxSupply();

        tokenSupply[id] += amount;
        ERC1155._mint(to, id, amount, data);
    }

    /**
     * @dev Internal batch minting function which limits minting to specified period (if startDate is 0, then mint
     * is always open, if mintDuration is 0 then sale is open-ended). Also checks whether token IDs are valid and
     * whether minting exceeds max token supply for each token
     * @param to Recipient account
     * @param ids Array of token IDs
     * @param amounts Array of amounts to mint for each token
     * @param data Calldata to pass if recipient is contract
     */
    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override isMintOpen {
        if (ids.length > BATCH_LIMIT) {
            revert SygnumERC1155BatchLimitExceeded();
        }

        if (ids.length != amounts.length) revert SygnumERC1155MismatchingInputSize();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            if (id >= maxUniqueTokens) revert SygnumERC1155InvalidTokenID();
            if (tokenSupply[id] + amount > maxTokenSupply(id)) revert SygnumERC1155AmountExceedsMaxSupply();

            tokenSupply[id] += amount;
        }

        ERC1155._batchMint(to, ids, amounts, data);
    }

    /**
     * @dev Initializer for proxy use
     * @param _encodedMaxTokenSupplies max token supplies encoded in bytes hex format (two bytes per token)
     * @param _royaltyRecipient address defined to receive royalty payments from secondary marketplaces
     * @param _baseOperators address of the BaseOperators contract (defined in solidity-base-contracts)
     * @param _baseUri base URI directing to the IPFS token data
     * @param _startDate start date for mint. If 0, then mint is always open
     * @param _mintDuration duration of the mint. If 0, then sale is open-ended starting on _startDate
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        bytes calldata _encodedMaxTokenSupplies,
        address _royaltyRecipient,
        address _baseOperators,
        string memory _baseUri,
        uint256 _startDate,
        uint256 _mintDuration
    ) public initializer {
        if (_baseOperators.code.length == 0) revert SygnumERC1155InvalidBaseOperators();
        if (_royaltyRecipient == address(0)) revert SygnumERC1155RoyaltyRecipientIsZeroAddress();
        if (bytes(_baseUri).length == 0) revert SygnumERC1155InvalidBaseUri();
        if (_encodedMaxTokenSupplies.length % 2 != 0) revert SygnumERC1155InvalidMaxTokenSupplies();
        if (_startDate == 0 && _mintDuration > 0) revert SygnumERC1155InvalidMintDuration();

        if (_startDate > 0 && _mintDuration > 0) {
            if (_startDate + _mintDuration < block.timestamp) revert SygnumERC1155InvalidMintDuration();
        }

        name = _name;
        symbol = _symbol;

        encodedMaxTokenSupplies = _encodedMaxTokenSupplies;
        maxUniqueTokens = _encodedMaxTokenSupplies.length / 2;

        baseUri = _baseUri;

        startDate = _startDate;
        mintDuration = _mintDuration;

        ERC2981._setDefaultRoyalty(_royaltyRecipient, 0);
        Operatorable.initialize(_baseOperators);
        emit Initialized(_encodedMaxTokenSupplies.length, _baseUri);
    }

    /**
     * @dev Function returning the URI to access token metadata
     * @param tokenId The token ID
     * @return string The corresponding URI in string format
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        if (tokenId >= maxUniqueTokens) revert SygnumERC1155InvalidTokenID();

        string memory baseURI = baseUri;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    /**
     * @dev Mandatory override. See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC1155) returns (bool) {
        return ERC2981.supportsInterface(interfaceId) || ERC1155.supportsInterface(interfaceId);
    }

    /**
     * @dev Public restricted function to change the default royalty rate.
     * @param receiver The address receiving royalty payments
     * @param feeNumerator The fee rate expressed in basis points (per 10k)
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external virtual onlyOperator {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
                /// @solidity memory-safe-assembly
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

// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

/**
 * @title NFT Factory Contract
 * @author Team 3301 <[email protected]>
 * @dev The NFTFactory contract is used to produce new collections in the form of a proxy, linking it to
 * a specified implementation contract and initializing it with the appropriate parameters
 */
contract NFTFactory is Initializable, Operatorable {
    address public implementation;
    address public proxyAdmin;

    address[] public deployedCollections;

    event NewCollection(uint256 indexed _id, address indexed _proxyAddress);
    event ProxyAdminChanged(address indexed _newCollectionAdmin);
    event ImplementationChanged(address indexed _newImplementation);

    error NFTFactoryNewProxyAdminIsZeroAddress();
    error NFTFactoryNewProxyAdminIsSameAddress();
    error NFTFactoryNewImplementationIsZeroAddress();
    error NFTFactoryNewImplementationIsSameAddress();
    error NFTFactoryInvalidBaseOperators();

    /**
     * @dev Prevent that the implementation gets accidentally initialized by malicious users
     */
    constructor() {
        super._disableInitializers();
    }

    /**
     * @dev Function deploying a new collection proxy, initializing it with the specified parameters,
     * recording the new deployed collection locally and emitting an event
     * @param _encodedMaxTokenSupplies max token supplies encoded in bytes hex format (one byte per token)
     * @param _royaltyRecipient address defined to receive royalty payments from secondary marketplaces
     * @param _baseOperators address of the BaseOperators contract (defined in solidity-base-contracts)
     * @param _baseUri base URI directing to the IPFS token data
     * @param _startDate start date for mint. If 0, then mint is always open
     * @param _mintDuration duration of the mint. If 0, then sale is open-ended starting on _startDate
     */
    function newCollection(
        string memory _name,
        string memory _symbol,
        bytes calldata _encodedMaxTokenSupplies,
        address _royaltyRecipient,
        address _baseOperators,
        string memory _baseUri,
        uint256 _startDate,
        uint256 _mintDuration
    ) external onlyOperator returns (address) {
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            implementation,
            proxyAdmin,
            abi.encodeWithSignature(
                "initialize(string,string,bytes,address,address,string,uint256,uint256)",
                _name,
                _symbol,
                _encodedMaxTokenSupplies,
                _royaltyRecipient,
                _baseOperators,
                _baseUri,
                _startDate,
                _mintDuration
            )
        );

        deployedCollections.push(address(proxy));
        emit NewCollection(deployedCollections.length - 1, address(proxy));

        return address(proxy);
    }

    /**
     * @dev Function to change the proxy admin for future collections, callable only by owner
     * @param _newProxyAdmin New proxy admin address
     */
    function changeProxyAdmin(address _newProxyAdmin) external onlyOperator {
        if (_newProxyAdmin == address(0)) revert NFTFactoryNewProxyAdminIsZeroAddress();
        if (_newProxyAdmin == proxyAdmin) revert NFTFactoryNewProxyAdminIsSameAddress();
        proxyAdmin = _newProxyAdmin;

        emit ProxyAdminChanged(_newProxyAdmin);
    }

    /**
     * @dev Function to change the implementation for future collections, callable only by owner
     * @param _newImplementation New implementation address
     */
    function changeImplementation(address _newImplementation) external onlyOperator {
        if (_newImplementation == address(0)) revert NFTFactoryNewImplementationIsZeroAddress();
        if (_newImplementation == implementation) revert NFTFactoryNewImplementationIsSameAddress();
        implementation = _newImplementation;

        emit ImplementationChanged(_newImplementation);
    }

    /**
     * @dev Initializer function setting the implementation and proxy admin addresses for future collections
     * @param _impl The implementation address
     * @param _admin The proxy admin address
     */
    function initialize(
        address _impl,
        address _admin,
        address _baseOperators
    ) external initializer {
        if (_baseOperators.code.length == 0) revert NFTFactoryInvalidBaseOperators();
        if (_impl == address(0)) revert NFTFactoryNewImplementationIsZeroAddress();
        if (_admin == address(0)) revert NFTFactoryNewProxyAdminIsZeroAddress();

        implementation = _impl;
        proxyAdmin = _admin;
        Operatorable.initialize(_baseOperators);

        emit ImplementationChanged(_impl);
        emit ProxyAdminChanged(_admin);
    }
}