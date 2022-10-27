//SPDX-License-Identifier: MIT
//author: Evabase core team
pragma solidity 0.8.16;

import "./interfaces/IOriFactory.sol";
import "./interfaces/IOriConfig.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./lib/ConsiderationStructs.sol";
import "./lib/ConsiderationEnums.sol";
import "./lib/ConsiderationConstants.sol";
import "./lib/ConfigHelper.sol";
import "./interfaces/OriErrors.sol";
import "./interfaces/ILicenseToken.sol";
import "./interfaces/IDerivativeToken.sol";
import "./TokenProxy.sol";

/**
 * @title Ori Config Center
 * @author ace
 * @notice  depoly License and Derivative NFT token.
 */
contract OriFactory is IOriFactory, OwnableUpgradeable {
    using ConfigHelper for IOriConfig;
    mapping(address => PairStruct) public originTokenPair;

    uint256 private constant _LICENSE_OPENED = 3;
    uint256 private constant _DERIVATIVE_OPENED = 5;
    uint256 private constant _OPENED = 1;

    /**
     *  Type       Enable  Binary
     *  License     N      0b010 = 2
     *  License     Y      0b011 = 3
     *  Derivative  N      0b100 = 4
     *  Derivative  Y      0b101 = 5
     *
     */
    mapping(address => uint256) private _tokens;

    function initialize() external initializer {
        __Ownable_init();
    }

    function requireRegistration(address token) external view returns (bool isLicense) {
        uint256 s = _tokens[token];
        require(s > 0 && s & _OPENED == _OPENED, "invalid status");

        isLicense = s & _LICENSE_OPENED == _LICENSE_OPENED;
        if (!isLicense) {
            require(s & _DERIVATIVE_OPENED == _DERIVATIVE_OPENED, "not dToken");
        }
    }

    function licenseToken(address originToken) external view returns (address) {
        return (originTokenPair[originToken].licenseAddress);
    }

    function derivativeToken(address originToken) external view returns (address) {
        return (originTokenPair[originToken].derivativeAddress);
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
        uint256 s = _tokens[token];
        require(s > 0 && s & _OPENED == 0, "invalid status");
        _tokens[token] = s ^ _OPENED;
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
        uint256 s = _tokens[token];
        require(s > 0 && s & _OPENED == _OPENED, "invalid status");
        _tokens[token] = s ^ _OPENED;
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
    function createOrignPair(address originToken) external override {
        if (originTokenPair[originToken].licenseAddress != address(0)) {
            return;
        }

        // safe check, nft editor is the owner of nft.
        address nftEditor = IOriConfig(CONFIG).nftEditor();
        if (nftEditor == address(0)) revert nftEditorIsEmpty();

        {
            require(originToken.code.length > 0, "not contract");
            address lToken = _deploy(
                type(LicenseProxy).creationCode,
                keccak256(abi.encodePacked(originToken, "license"))
            );
            ILicenseToken(lToken).initialize(owner(), originToken);
            originTokenPair[originToken].licenseAddress = lToken;
            _tokens[lToken] = _LICENSE_OPENED;
            emit LicenseTokenDeployed(originToken, lToken);
        }
        {
            address derivative;
            if (IERC165(originToken).supportsInterface(ERC721_IDENTIFIER)) {
                string memory dName;
                string memory dSymbol;
                if (IERC165(originToken).supportsInterface(ERC721_METADATA_IDENTIFIER)) {
                    dName = string.concat("Derivative Of ", IERC721Metadata(originToken).name());
                    dSymbol = string.concat("DER_", IERC721Metadata(originToken).symbol());
                } else {
                    dName = "Derivative";
                    dSymbol = "DER";
                }
                derivative = _deployDerivative721(originToken, address(this), dName, dSymbol);
            } else if (IERC165(originToken).supportsInterface(ERC1155_IDENTIFIER)) {
                derivative = _deployDerivative721(originToken, address(this), "Derivative", "DER");
            } else {
                revert("not support");
            }
            originTokenPair[originToken].derivativeAddress = derivative;
        }
    }

    /**
     * @notice Create a empty derivative NFT contract
     * @dev Allow every one to call it to create derivative NFT contract.
     * Only then can Ori whitelist it. and this new contract will be enabled immediately.
     *
     * Emits a `Derivative1155TokenDeployed` event. the event parameter `originToken` is zero.
     * And there are a `TokenEnabled` event if the caller is an administrator.
     */
    function deployDerivative721(string memory dName, string memory dSymbol) external override returns (address token) {
        return _deployDerivative721(address(0), _msgSender(), dName, dSymbol);
    }

    function deployDerivative1155() public override returns (address token) {
        return _deployDerivative1155(address(0), _msgSender());
    }

    function _deployDerivative1155(address origin, address creator) private returns (address token) {
        token = _deploy(
            type(ERC1155DerivativeProxy).creationCode,
            keccak256(abi.encodePacked(creator, origin, block.number))
        );
        IDerivativeToken(token).initialize(creator, address(0), "", "");
        _tokens[token] = _DERIVATIVE_OPENED;
        emit DerivativeTokenDeployed(origin, token);
    }

    function _deployDerivative721(
        address origin,
        address creator,
        string memory dName,
        string memory dSymbol
    ) private returns (address token) {
        // salt= tx.origin + dname +dsymbol
        token = _deploy(
            type(ERC721DerivativeProxy).creationCode,
            keccak256(abi.encodePacked(creator, origin, dName, dSymbol))
        );
        IDerivativeToken(token).initialize(creator, origin, dName, dSymbol);
        _tokens[token] = _DERIVATIVE_OPENED;
        emit DerivativeTokenDeployed(origin, token);
    }

    function _deploy(bytes memory bytecode, bytes32 salt) internal returns (address addr) {
        // solhint-disable no-inline-assembly
        assembly {
            addr := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        require(addr.code.length > 0, "Failed on deploy");
    }
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;
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
    event DerivativeTokenDeployed(address originToken, address derivative);

    function requireRegistration(address token) external view returns (bool isLicense);

    function licenseToken(address originToken) external view returns (address);

    function derivativeToken(address originToken) external view returns (address);

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
    function createOrignPair(address originToken) external;

    /**
     * @notice Create a empty derivative NFT contract
     * @dev Allow every one to call it to create derivative NFT contract.
     * Only then can Ori whitelist it. and this new contract will be enabled immediately.
     *
     * Emits a `Derivative1155TokenDeployed` event. the event parameter `originToken` is zero.
     * And there are a `TokenEnabled` event if the caller is an administrator.
     */
    function deployDerivative721(string memory dName, string memory dSymbol) external returns (address token);

    function deployDerivative1155() external returns (address token);
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

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

pragma solidity 0.8.16;

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

pragma solidity 0.8.16;

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

//SPDX-License-Identifier: MIT
//author: Evabase core team
pragma solidity 0.8.16;

// Operator Address For Newly created NFT contract operator for managing collections in Opensea
bytes32 constant CONFIG_OPERATPR_ALL_NFT_KEY = keccak256("CONFIG_OPERATPR_ALL_NFT");

//  Mint Settle Address
bytes32 constant CONFIG_DAFAULT_MINT_SETTLE_ADDRESS_KEY = keccak256("CONFIG_DAFAULT_MINT_SETTLE_ADDRESS");

bytes32 constant CONFIG_LICENSE_MINT_FEE_RECEIVER_KEY = keccak256("CONFIG_LICENSE_MINT_FEE_RECEIVER");

// nft edtior
bytes32 constant CONFIG_NFT_EDITOR_KEY = keccak256("CONFIG_NFT_EDITOR_ADDRESS");

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

//Default Base url for NFT eg:https://ori-static.particle.network/
bytes32 constant CONFIG_DEFAULT_BASE_URL_ALL_NFT_KEY = keccak256("CONFIG_DEFAULT_BASE_URL_ALL_NFT");

// Max licese Earn Point Para
bytes32 constant CONFIG_DEFAULT_MAX_LICESE_EARN_POINT_KEY = keccak256("CONFIG_DEFAULT_MAX_LICESE_EARN_POINT");

bytes32 constant CONFIG_LICENSE_ERC1155_IMPL_KEY = keccak256("CONFIG_LICENSE_ERC1155_IMPL");
bytes32 constant CONFIG_DERIVATIVE_ERC721_IMPL_KEY = keccak256("CONFIG_DERIVATIVE_ERC721_IMPL");
bytes32 constant CONFIG_DERIVATIVE_ERC1155_IMPL_KEY = keccak256("CONFIG_DERIVATIVE_ERC1155_IMPL");

// As EIP712 parameters
string constant NAME = "ORI";
// As EIP712 parameters
string constant VERSION = "1";

// salt=0x0000000000000000000000000000000000000000000000987654321123456789
address constant CONFIG = 0x94745d1a874253760Ca5B47dc3DB8E4185D7b8Dd;

// https://eips.ethereum.org/EIPS/eip-721
bytes4 constant ERC721_METADATA_IDENTIFIER = 0x5b5e139f;
bytes4 constant ERC721_IDENTIFIER = 0x80ac58cd;
// https://eips.ethereum.org/EIPS/eip-1155
bytes4 constant ERC1155_IDENTIFIER = 0xd9b67a26;

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

import "../interfaces/IOriConfig.sol";
import "./ConsiderationConstants.sol";

library ConfigHelper {
    function oriFactory(IOriConfig cfg) internal view returns (address) {
        return cfg.getAddress(CONFIG_NFTFACTORY_KEY);
    }

    function isExchange(IOriConfig cfg, address acct) internal view returns (bool) {
        return cfg.getUint256(keccak256(abi.encode("EXCHANGE", acct))) == 1;
    }

    function oriAdmin(IOriConfig cfg) internal view returns (address) {
        return cfg.getAddress(CONFIG_DEFAULT_OWNER_ALL_NFT_KEY);
    }

    function mintFeeReceiver(IOriConfig cfg) internal view returns (address) {
        return cfg.getAddress(CONFIG_LICENSE_MINT_FEE_RECEIVER_KEY);
    }

    function nftEditor(IOriConfig cfg) internal view returns (address) {
        return cfg.getAddress(CONFIG_NFT_EDITOR_KEY);
    }

    function operator(IOriConfig cfg) internal view returns (address) {
        return cfg.getAddress(CONFIG_OPERATPR_ALL_NFT_KEY);
    }

    function maxEarnBP(IOriConfig cfg) internal view returns (uint256) {
        return cfg.getUint256(CONFIG_DEFAULT_MAX_LICESE_EARN_POINT_KEY);
    }

    function mintFeeBP(IOriConfig cfg) internal view returns (uint256) {
        return cfg.getUint256(CONFIG_DAFAULT_MINT_FEE_KEY);
    }

    function settlementHouse(IOriConfig cfg) internal view returns (address) {
        return cfg.getAddress(CONFIG_DAFAULT_MINT_SETTLE_ADDRESS_KEY);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

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

/**
 * @dev not support function  error
 */
error notSupportFunctionError();

error nftEditorIsEmpty();

error invalidTokenType();

error notFoundLicenseToken();

error amountIsZero();

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;
import "./IApproveAuthorization.sol";
import "./ITokenActionable.sol";

/**
 * @title NFT License token
 * @author ysqi
 * @notice NFT License token protocol.
 */
interface ILicenseToken is IApproveAuthorization, ITokenActionable {
    function initialize(address creator, address origin) external;

    /**
     * @notice return the license meta data.
     *
     * Requirements:
     *
     * - `id` must be exist.
     * @param id is the token id.
     * @return LicenseMeta:
     *
     *    uint256 originTokenId;
     *    uint16 earnPoint;
     *    uint64 expiredAt;
     */
    function meta(uint256 id) external view returns (LicenseMeta calldata);

    /**
     * @notice return the license[] metas data.
     *
     * Requirements:
     *
     * - `id` must be exist.
     * @param ids is the token ids.
     * @return LicenseMetas:
     *
     *    uint256 originTokenId;
     *    uint16 earnPoint;
     *    uint64 expiredAt;
     */
    function metas(uint256[] memory ids) external view returns (LicenseMeta[] calldata);

    /*
     * @notice return whether NFT has expired.
     *
     * Requirements:
     *
     * - `id` must be exist.
     *
     * @param id is the token id.
     * @return bool returns whether NFT has expired.
     */
    function expired(uint256 id) external view returns (bool);
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

import "../lib/ConsiderationStructs.sol";

/**
 * @title NFT Derivative token
 * @author ysqi
 * @notice NFT Derivative token protocol.
 */
interface IDerivativeToken {
    function initialize(
        address creator,
        address originToken,
        string memory name,
        string memory symbol
    ) external;

    /**
     * @notice return the Derivative[] metas data.
     *
     * Requirements:
     *
     * - `id` must be exist.
     * @param id is the token id.
     * @return DerivativeMeta
     */
    function meta(uint256 id) external view returns (DerivativeMeta calldata);

    /**
     * @notice return the license[] metas data.
     *
     * Requirements:
     *
     * - `id` must be exist.
     * @param ids is the token ids.
     * @return DerivativeMetas:
     *
     */
    function metas(uint256[] memory ids) external view returns (DerivativeMeta[] calldata);
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

import "./lib/AutoProxy.sol";
import "./lib/ConsiderationConstants.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract LicenseProxy is AutoProxy {
    constructor() AutoProxy(CONFIG, CONFIG_LICENSE_ERC1155_IMPL_KEY, "") {}
}

contract ERC721DerivativeProxy is AutoProxy {
    constructor() AutoProxy(CONFIG, CONFIG_DERIVATIVE_ERC721_IMPL_KEY, "") {}
}

contract ERC1155DerivativeProxy is AutoProxy {
    constructor() AutoProxy(CONFIG, CONFIG_DERIVATIVE_ERC1155_IMPL_KEY, "") {}
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

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

/**
 * @title  Atomic approve token
 * @author ysqi
 * @notice gives permission to transfer token to another account on this call.
 */
interface IApproveAuthorization {
    /**
     * @notice the `from` gives permission to `to` to transfer token to another account on this call.
     * The approval is cleared when the call is end.
     *
     * Emits an `AtomicApproved` event.
     *
     * Requirements:
     *
     * - `to` must be the same with `msg.sender`. and it must implement {IApproveSet-onAtomicApproveSet}, which is called after approve.
     * - `to` can't be the `from`.
     * - `nonce` can only be used once.
     * - The validity of this authorization operation must be between `validAfter` and `validBefore`.
     *
     * @param from        from's address (Authorizer)
     * @param to      to's address
     * @param validAfter    The time after which this is valid (unix time)
     * @param validBefore   The time before which this is valid (unix time)
     * @param salt          Unique salt
     * @param signature     the signature
     */
    function approveForAllAuthorization(
        address from,
        address to,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 salt,
        bytes memory signature
    ) external;
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;
import "../lib/ConsiderationStructs.sol";

/**
 * @title define token mint or burn actions
 * @author ysqi
 * @notice Two types of Tokens within the Ori protocol need to support Mint and Burn operations.
 */
interface ITokenActionable {
    /*
     * @dev Returns the NFT operator address(ITokenOperator).
     * Only operator can mint or burn OriLicense/OriDerivative/ NFT.
     */

    function operator() external view returns (address);

    function creator() external view returns (address);

    /**
     * @dev Returns the editor of the current collection on Opensea.
     * this editor will be configured in the `IOriConfig` contract.
     */
    function owner() external view returns (address);

    /*
     * @dev Returns the OriLicense/OriDerivative slave NFT contract address.
     * If no origin NFT, returns zero address.
     */
    function originToken() external view returns (address);

    /**
     * @notice Creates `amount` tokens of token type `id`, and assigns them to `to`.
     * @param meta is the token meta information.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function create(
        address to,
        bytes calldata meta,
        uint256 amount
    ) external;

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    /**
     *@dev Retruns the last tokenId of this token.
     */
    function nonce() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract AutoProxy is Proxy {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    address public immutable beacon;
    bytes32 private immutable _implKey;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(
        address beacon_,
        bytes32 implKey_,
        bytes memory data
    ) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        require(Address.isContract(beacon_), "beacon is not a contract");

        beacon = beacon_;
        _implKey = implKey_;

        address impl = _implementation();
        _setImplementation(impl);
        if (data.length > 0) Address.functionDelegateCall(impl, data);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal view override returns (address impl) {
        (bool success, bytes memory ret) = beacon.staticcall(abi.encodeWithSignature("getAddress(bytes32)", _implKey));
        require(success, "call becaon failed");
        impl = abi.decode(ret, (address));
        require(impl != address(0), "impl is zero");
    }

    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
        emit Upgraded(newImplementation);
    }

    function _beforeFallback() internal override {
        //check and update
        address implStorage = StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
        address implTrue = _implementation();
        if (implTrue != implStorage) {
            _setImplementation(implTrue);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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