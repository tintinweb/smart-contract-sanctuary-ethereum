//SPDX-License-Identifier: MIT
//author: Evabase core team
pragma solidity ^0.8.16;

import "./interfaces/IOriFactory.sol";
import "./interfaces/IOriConfig.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./lib/ConsiderationStructs.sol";
import "./lib/ConsiderationEnums.sol";
import "./lib/ConsiderationConstants.sol";
import "./interfaces/IDerivative1155TokenType.sol";
import "./interfaces/IDerivative721TokenType.sol";
import "./interfaces/ILicenseTokenType.sol";
import "./interfaces/OriErrors.sol";

/**
 * @title Ori Config Center
 * @author ace
 * @notice  depoly License and Derivative NFT token.
 */
contract OriFactory is IOriFactory, OwnableUpgradeable, OriErrors {
    IOriConfig public config;
    mapping(address => PairStruct) public originTokenPair;

    mapping(address => TokenStatus) public tokenStatus;

    function initialize(address _config) external initializer {
        require(_config != address(0), "addess is 0x");
        __Ownable_init();
        config = IOriConfig(_config);
    }

    /**
     * @notice  see the given nft token enable status.
     *
     * @param token  is License or Derivative contract address.
     *
     */
    function getTokenStatus(address token) external view returns (TokenStatus) {
        return tokenStatus[token];
    }

    function defaultToken(address originToken) external view returns (address license, address derivative) {
        return (originTokenPair[originToken].licenseAddress, originTokenPair[originToken].derivativeAddress);
    }

    /**
     * @notice enable the given nft token.
     *
     * Emits an {TokenEnabled} event.
     *
     * Requirements:
     *
     * - The nft token `token` must been created by OriFactory.
     * - The `token` must be unenabled.
     * - Only the administrator can call it.
     *
     * @param token  is License or Derivative contract address.
     *
     */
    function enableToken(address token) external onlyOwner {
        require(
            tokenStatus[token] == TokenStatus.Pending || tokenStatus[token] == TokenStatus.Disabled,
            "invalid status"
        );
        _enableToken(token);
    }

    function _enableToken(address token) internal {
        tokenStatus[token] = TokenStatus.Enabled;
        emit TokenEnabled(token);
    }

    /**
     * @notice disable the given nft token.
     *
     * Emits an {TokenDisabled} event.
     *
     * Requirements:
     *
     * - The `token` must be enabled.
     * - Only the administrator can call it.
     *
     * @param token  is License or Derivative contract address.
     *
     */
    function disableToken(address token) external onlyOwner {
        require(tokenStatus[token] == TokenStatus.Enabled, "invalid status");
        tokenStatus[token] = TokenStatus.Disabled;
        emit TokenDisabled(token);
    }

    /**
     * @notice Create default license and derivative token contracts for the given NFT.
     * @dev Ori can deploy licenses and derivative contracts for every NFT contract.
     * Then each NFT's licens and derivatives will be stand-alone.
     * helping to analyz this NFT and makes the NFT managment structure clear and concise.
     *
     * Every one can call it to deploy license and derivative contracts for the given NFT.
     * but this created contracts is disabled, need the administrator to enable them.
     * them will be enabled immediately if the caller is an administrator.
     *
     * Emits a `LicenseTokenDeployed` and a `Derivative1155TokenDeployed` event.
     * And there are tow `TokenEnabled` events if the caller is an administrator.
     *
     *
     * Requirements:
     *
     * - The `originToken` must be NFT contract.
     * - Each NFT Token can only set one default license and derivative contract.
     *
     * @param originToken is the NFT contract.
     *
     */
    function deployToken(
        address originToken,
        TokenStandard dType,
        string memory dName,
        string memory dSymbol
    ) external {
        address licenseToken = _deployLicenseToken(originToken);

        address derivativeToken = _deployDerivativeToken(originToken, dType, dName, dSymbol);

        require(
            originTokenPair[originToken].licenseAddress == address(0) &&
                originTokenPair[originToken].derivativeAddress == address(0),
            "deployed"
        );

        originTokenPair[originToken] = PairStruct({licenseAddress: licenseToken, derivativeAddress: derivativeToken});
    }

    function _deployLicenseToken(address originToken) internal returns (address tokenAddress) {
        bytes memory bytecodeTemp = ILicenseTokenType(config.getAddress(CONFIG_LICENSETOKEN_TYPE_KEY))
            .licenseTokenType();
        bytes memory bytecode = abi.encodePacked(bytecodeTemp, abi.encode(address(config), originToken));
        tokenAddress = _deploy(originToken, bytecode, 2);
        emit LicenseTokenDeployed(originToken, tokenAddress);
    }

    /**
     * @notice Create a empty derivative NFT contract
     * @dev Allow every one to call it to create derivative NFT contract.
     * Only then can Ori whitelist it. and this new contract will be enabled immediately.
     *
     * Emits a `Derivative1155TokenDeployed` event. the event parameter `originToken` is zero.
     * And there are a `TokenEnabled` event if the caller is an administrator.
     */
    function deployDerivativeToken(
        TokenStandard dType,
        string memory dName,
        string memory dSymbol
    ) external {
        _deployDerivativeToken(address(0), dType, dName, dSymbol);
    }

    function _deployDerivativeToken(
        address originToken,
        TokenStandard dType,
        string memory dName,
        string memory dSymbol
    ) internal returns (address tokenAddress) {
        bytes memory bytecodeTemp;
        if (dType == TokenStandard.ERC721) {
            bytecodeTemp = IDerivative721TokenType(config.getAddress(CONFIG_DERIVATIVETOKEN_721_TYPE_KEY))
                .derivative721TokenType();
        } else if (dType == TokenStandard.ERC1155) {
            bytecodeTemp = IDerivative1155TokenType(config.getAddress(CONFIG_DERIVATIVETOKEN_1155_TYPE_KEY))
                .derivative1155TokenType();
        } else {
            revert notSupportTokenKindError();
        }

        bytes memory bytecode = abi.encodePacked(
            bytecodeTemp,
            abi.encode(address(msg.sender), address(config), originToken, dName, dSymbol)
        );

        tokenAddress = _deploy(originToken, bytecode, 1);
        emit DerivativeTokenDeployed(originToken, tokenAddress, dType, dName, dSymbol);
    }

    function _deploy(
        address originToken,
        bytes memory bytecode,
        uint256 index
    ) internal returns (address tokenAddress) {
        // solhint-disable not-rely-on-time
        bytes32 salt = keccak256(abi.encodePacked(originToken, block.timestamp, index));
        // solhint-disable no-inline-assembly
        assembly {
            tokenAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        require(TokenStatus.Unknow == tokenStatus[tokenAddress], "invalid status");

        if (msg.sender == owner()) {
            _enableToken(tokenAddress);
        } else {
            tokenStatus[tokenAddress] = TokenStatus.Pending;
        }
    }
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.16;
import "../lib/ConsiderationEnums.sol";

/**
 * @title Ori Protocol NFT Token Factory
 * @author ysqi
 * @notice management License and Derivative NFT token.
 */
interface IOriFactory {
    event TokenEnabled(address token);
    event TokenDisabled(address token);
    event LicenseTokenDeployed(address originToken, address license);
    event DerivativeTokenDeployed(
        address originToken,
        address derivative,
        TokenStandard dType,
        string dName,
        string dSymbol
    );

    function getTokenStatus(address token) external returns (TokenStatus);

    function defaultToken(address originToken) external returns (address license, address derivative);

    /**
     * @notice enable the given nft token.
     *
     * Emits an {TokenEnabled} event.
     *
     * Requirements:
     *
     * - The nft token `token` must been created by OriFactory.
     * - The `token` must be unenabled.
     * - Only the administrator can call it.
     *
     * @param token  is License or Derivative contract address.
     *
     */
    function enableToken(address token) external;

    /**
     * @notice disable the given nft token.
     *
     * Emits an {TokenDisabled} event.
     *
     * Requirements:
     *
     * - The `token` must be enabled.
     * - Only the administrator can call it.
     *
     * @param token  is License or Derivative contract address.
     *
     */
    function disableToken(address token) external;

    /**
     * @notice Create default license and derivative token contracts for the given NFT.
     * @dev Ori can deploy licenses and derivative contracts for every NFT contract.
     * Then each NFT's licens and derivatives will be stand-alone.
     * helping to analyz this NFT and makes the NFT managment structure clear and concise.
     *
     * Every one can call it to deploy license and derivative contracts for the given NFT.
     * but this created contracts is disabled, need the administrator to enable them.
     * them will be enabled immediately if the caller is an administrator.
     *
     * Emits a `LicenseTokenDeployed` and a `Derivative1155TokenDeployed` event.
     * And there are tow `TokenEnabled` events if the caller is an administrator.
     *
     *
     * Requirements:
     *
     * - The `originToken` must be NFT contract.
     * - Each NFT Token can only set one default license and derivative contract.
     *
     * @param originToken is the NFT contract.
     *
     */
    function deployToken(
        address originToken,
        TokenStandard dType,
        string memory dName,
        string memory dSymbol
    ) external;

    /**
     * @notice Create a empty derivative NFT contract
     * @dev Allow every one to call it to create derivative NFT contract.
     * Only then can Ori whitelist it. and this new contract will be enabled immediately.
     *
     * Emits a `Derivative1155TokenDeployed` event. the event parameter `originToken` is zero.
     * And there are a `TokenEnabled` event if the caller is an administrator.
     */
    function deployDerivativeToken(
        TokenStandard dType,
        string memory dName,
        string memory dSymbol
    ) external;
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.16;

/**
 * @title Ori Config Center
 * @author ysqi
 * @notice  Manage all configs for ori protocol.
 * each config the type of item key is bytes32, the item value type is bytes32 too.
 */
interface IOriConfig {
    /*
     * @notice White list change event
     * @param key
     * @param value is the new value.
     */
    event ChangeWhite(address indexed key, bool value);

    /*
     * @notice Configuration change event
     * @param key
     * @param value is the new value.
     */
    event Changed(bytes32 indexed key, bytes32 value);

    /*
     * @notice Configuration change event
     * @param key
     * @param value is the new value.
     */
    event ChangedBytes(bytes32 indexed key, bytes value);

    /**
     * @dev Returns the value of the given configuration item.
     */
    function get(bytes32 key) external view returns (bytes32);

    /**
     * @dev Returns value of the given configuration item.
     * Safely convert the bytes32 value to address before returning.
     */
    function getAddress(bytes32 key) external view returns (address);

    /**
     * @dev Returns value of the given configuration item.
     */
    function getUint256(bytes32 key) external view returns (uint256);

    /**
     * @notice Reset the configuration item value to an address.
     *
     * Emits an `Changed` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function resetAddress(bytes32 key, address value) external;

    /**
     * @notice Reset the configuration item value to a uint256.
     *
     * Emits an `Changed` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function resetUint256(bytes32 key, uint256 value) external;

    /**
     * @notice Reset the configuration item value to a bytes32.
     *
     * Emits an `Changed` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function reset(bytes32 key, bytes32 value) external;

    /**
     * @dev Returns the bytes.
     */
    function getBytes(bytes32 key) external view returns (bytes memory);

    /**
     * @notice  set the configuration item value to a bytes.
     *
     * Emits an `ChangedBytes` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function setBytes(bytes32 key, bytes memory value) external;

    /**
     * @dev Is it a whitelisted market.
     */
    function isWhiteMarketplace(address marketplace) external view returns (bool);

    /**
     * @notice  set the marketplace item value whiteList or not.
     *
     * Emits an `ChangeWhite` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param marketplace is the key of configuration item.
     * @param isWhite WhiteList or not.
     */
    function setWhiteMarketplace(address marketplace, bool isWhite) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.16;

import "./ConsiderationEnums.sol";

// NFT 标识
struct NFT {
    address token; //该 NFT 所在合约地址
    uint256 id; // 该 NFT ID 标识符
}

struct DerivativeMeta {
    NFT[] licenses; // 二创NFT所携带的 Licenses 清单
    uint256 supplyLimit; // 供给上限
    uint256 totalSupply; //当前总已供给数量
}

// License NFT 元数据
struct LicenseMeta {
    uint256 originTokenId; // License 所属 NFT
    uint16 earnPoint; // 单位是10000,原NFT持有人从二创NFT交易中赚取的交易额比例，100= 1%
    uint64 expiredAt; // 该 License 过期时间，过期后不能用于创建二仓作品
}

// approve sign data
struct ApproveAuthorization {
    address token;
    address from; //            from        from's address (Authorizer)
    address to; //     to's address
    uint256 validAfter; // The time after which this is valid (unix time)
    uint256 validBefore; // The time before which this is valid (unix time)
    bytes32 salt; // Unique salt
    bytes signature; //  the signature
}

//Store a pair of addresses
struct PairStruct {
    address licenseAddress;
    address derivativeAddress;
}

struct Settle {
    address recipient;
    uint256 value;
    uint256 index;
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.16;

/**
 * @dev the standard of token
 */
enum TokenStandard {
    Unknow,
    // 1 - ERC20 Token
    ERC20,
    // 2 - ERC721 Token (NFT)
    ERC721,
    // 3 - ERC1155 Token (NFT)
    ERC1155
}

/**
 * @dev the kind of token on ori protocol.
 */
enum TokenKind {
    Unknow,
    // 1- Licens Token
    OriLicense,
    // 2- Derivative Token
    OriDerivative
}

/**
 * @dev the status of token on ori protocol.
 */
enum TokenStatus {
    Unknow,
    //deployed but not enable
    Pending,
    Enabled,
    Disabled
}

//SPDX-License-Identifier: MIT
//author: Evabase core team
pragma solidity ^0.8.16;

// Operator Address For Newly created NFT contract operator for managing collections in Opensea
bytes32 constant CONFIG_OPERATPR_ALL_NFT_KEY = keccak256("CONFIG_OPERATPR_ALL_NFT");

//  Mint Settle Address
bytes32 constant CONFIG_DAFAULT_MINT_SETTLE_ADDRESS_KEY = keccak256("CONFIG_DAFAULT_MINT_SETTLE_ADDRESS");

// NFT Factory Contract Address
bytes32 constant CONFIG_NFTFACTORY_KEY = keccak256("CONFIG_NFTFACTORY_KEY");

// Derivative1155TokenType Contract Address
bytes32 constant CONFIG_DERIVATIVETOKEN_1155_TYPE_KEY = keccak256("CONFIG_DERIVATIVETOKEN_1155_TYPE");

// Derivative721TokenType Contract Address
bytes32 constant CONFIG_DERIVATIVETOKEN_721_TYPE_KEY = keccak256("CONFIG_DERIVATIVETOKEN_721_TYPE");

// LicenseTokenType Contract Address
bytes32 constant CONFIG_LICENSETOKEN_TYPE_KEY = keccak256("CONFIG_LICENSETOKEN_TYPE");

//Default owner address for NFT
bytes32 constant CONFIG_DEFAULT_OWNER_ALL_NFT_KEY = keccak256("CONFIG_DEFAULT_OWNER_ALL_NFT");

// Default Mint Fee 0.00001 ETH
bytes32 constant CONFIG_DAFAULT_MINT_FEE_KEY = keccak256("CONFIG_DAFAULT_MINT_FEE");

//Default Base url for NFT eg:https://nft.ori.com/
bytes32 constant CONFIG_DEFAULT_BASE_URL_ALL_NFT_KEY = keccak256("CONFIG_DEFAULT_BASE_URL_ALL_NFT");

// As EIP712 parameters
string constant NAME = "ORI";
// As EIP712 parameters
string constant VERSION = "1";
// Max licese Earn Point 5%
uint16 constant MAX_EARN_POINT = 500;

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.16;

/**
 * @title Derivative1155Token  Type
 * @author ace
 * @notice IDerivative1155TokenType.
 */
interface IDerivative1155TokenType {
    function derivative1155TokenType() external view returns (bytes memory);
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.16;

/**
 * @title Derivative721Token  Type
 * @author ace
 * @notice IDerivative721TokenType.
 */
interface IDerivative721TokenType {
    function derivative721TokenType() external view returns (bytes memory);
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.16;

/**
 * @title LicenseToken Type
 * @author ace
 * @notice ILicenseTokenType.
 */
interface ILicenseTokenType {
    function licenseTokenType() external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

/**
 * @title OriErrors
 * @author ysqi
 * @notice  OriErrors contains all errors related to Ori protocol.
 */
interface OriErrors {
    /**
     * @dev Revert with an error when a signature that does not contain a v
     *      value of 27 or 28 has been supplied.
     *
     * @param v The invalid v value.
     */
    error BadSignatureV(uint8 v);

    /**
     * @dev Revert with an error when the signer recovered by the supplied
     *      signature does not match the offerer or an allowed EIP-1271 signer
     *      as specified by the offerer in the event they are a contract.
     */
    error InvalidSigner();

    /**
     * @dev Revert with an error when a signer cannot be recovered from the
     *      supplied signature.
     */
    error InvalidSignature();

    /**
     * @dev Revert with an error when an EIP-1271 call to an account fails.
     */
    error BadContractSignature();

    /**
     * @dev Revert with an error when low-level call with value failed without reason.
     */
    error UnknownLowLevelCallFailed();

    /**
     * @dev Errors that occur when NFT expires transfer
     */
    error expiredError(uint256 id);

    /**
     * @dev atomicApproveForAll:approve to op which no implementer
     */
    error atomicApproveForAllNoImpl();

    /**
     * @dev address in not contract
     */
    error notContractError();

    /**
     * @dev not support EIP NFT error
     */
    error notSupportNftTypeError();

    /**
     * @dev not support TokenKind  error
     */
    error notSupportTokenKindError();
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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