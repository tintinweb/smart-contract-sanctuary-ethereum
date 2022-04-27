// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./proxy/OpenDefiNFTProxy.sol";
import "./proxy/OpenDefiExchangeProxy.sol";

import "./interfaces/IOpenDefiNFT.sol";
import "./interfaces/IExchange.sol";
import "./interfaces/IOpenDefiCollectionFactory.sol";

contract OpenDefiCollectionFactory is
    Ownable,
    Pausable,
    IOpenDefiCollectionFactory
{
    using SafeMath for uint256;

    address public collectionBeacon;
    address public exchangeBeacon;

    uint256 public override latestCollectionId;
    mapping(uint256 => address) public override collections;
    mapping(uint256 => address) public override exchanges;

    bool public override isFactoryPublic;

    event UpdateFactoryAccess(bool _isPublic);
    event CreatedCollection(
        address indexed collectionAddress,
        address indexed exchangeAddress
    );

    modifier isOpen() {
        if (!isFactoryPublic)
            require(
                owner() == _msgSender(),
                "Ownable: caller  is not the owner"
            );
        _;
    }

    constructor(address _collectionBeacon, address _exchangeBeacon) {
        require(
            _collectionBeacon != address(0),
            "ZERO COLLECTION BEACON ADDRESS "
        );
        require(_exchangeBeacon != address(0), "ZERO EXCHANGE BEACON ADDRESS ");

        collectionBeacon = _collectionBeacon;
        exchangeBeacon = _exchangeBeacon;
        isFactoryPublic = false;
    }

    /**
     * @dev The function will pause the contract and restricitng the buying, burning and related NFT functionalities
     */
    function pause() external onlyOwner returns (bool) {
        _pause();
        return true;
    }

    /**
     * @dev The function will remove the pause criteria and allow the contract to perform the NFT functionalities
     */
    function unpause() external onlyOwner returns (bool) {
        _unpause();
        return true;
    }

    function paused()
        public
        view
        override(IOpenDefiCollectionFactory, Pausable)
        returns (bool)
    {
        return Pausable.paused();
    }

    /**
     * @dev The function to change the access status of the factory contract.
     * only owner can create collection when the factory is not public.
     */
    function updateFactoryAccess(bool _isPublic) external onlyOwner {
        isFactoryPublic = _isPublic;
        emit UpdateFactoryAccess(_isPublic);
    }

    struct CollectionData {
        string uri;
        string name;
        string symbol;
        address[] backedAssets;
    }

    struct ExchangeData {
        bool isPrivateCollection;
        address insuranceToken;
        uint256 insuranceInterval;
        uint256 insurancePrice;
        uint256[] feeConfig;
        address[] feeTokens;
    }

    /**
     * @dev The function can create collection for the NFTs
     * only owner can create collection when the factory is not public.
     * ERC 20 tokens associated with the NFTs are added when collection is created.
     */
    function createCollection(
        ExchangeData memory exchangeData,
        CollectionData memory collectionData,
        bytes32 _salt1,
        bytes32 _salt2
    ) external isOpen whenNotPaused {
        bytes32 salt1 = keccak256(abi.encode(msg.sender, _salt1));
        bytes32 salt2 = keccak256(abi.encode(msg.sender, _salt2));

        address collectionAddr = _create(salt1, true);
        address exchangeAddr = _create(salt2, false);

        _initOpenDefiNFT(collectionAddr, exchangeAddr, collectionData);
        _initOpenDefiExchange(exchangeAddr, collectionAddr, exchangeData);

        collections[latestCollectionId] = collectionAddr;
        exchanges[latestCollectionId] = exchangeAddr;
        latestCollectionId = latestCollectionId.add(1);

        emit CreatedCollection(collectionAddr, exchangeAddr);
    }

    function _create(bytes32 _salt, bool isCollection)
        internal
        returns (address)
    {
        address addr;
        bytes memory beaconProxyByteCode = getBytecode(isCollection);

        assembly {
            addr := create2(
                callvalue(),
                add(beaconProxyByteCode, 0x20),
                mload(beaconProxyByteCode),
                _salt
            )
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        return addr;
    }

    function _initOpenDefiNFT(
        address _opendefiNFT,
        address _exchange,
        CollectionData memory collectionData
    ) internal {
        IOpenDefiNFT opendefiNFT = IOpenDefiNFT(_opendefiNFT);
        opendefiNFT.__OpenDefiNFT_init(
            collectionData.uri,
            collectionData.name,
            collectionData.symbol,
            collectionData.backedAssets,
            _msgSender(),
            _exchange
        );
    }

    function _initOpenDefiExchange(
        address _opendefiNFTExchange,
        address _collection,
        ExchangeData memory exchangeData
    ) internal {
        IExchange opendefiNFTExchange = IExchange(_opendefiNFTExchange);

        opendefiNFTExchange.__OpenDefiExchange_init(
            exchangeData.isPrivateCollection,
            _collection,
            exchangeData.insuranceToken,
            _msgSender(),
            exchangeData.insuranceInterval,
            exchangeData.insurancePrice,
            exchangeData.feeConfig,
            exchangeData.feeTokens
        );
    }

    function preComputeAddress(
        address _creator,
        bytes32 _salt,
        bool isCollection
    ) external view returns (address predicted) {
        bytes32 salt = keccak256(abi.encode(_creator, _salt));

        bytes memory beaconProxyByteCode = getBytecode(isCollection);

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(beaconProxyByteCode)
            )
        );

        return address(uint160(uint256(hash)));
    }

    function getBytecode(bool isCollection)
        internal
        view
        returns (bytes memory)
    {
        return
            isCollection
                ? abi.encodePacked(
                    type(OpenDefiNFTProxy).creationCode,
                    abi.encode(collectionBeacon)
                )
                : abi.encodePacked(
                    type(OpenDefiExchangeProxy).creationCode,
                    abi.encode(exchangeBeacon)
                );
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

contract OpenDefiNFTProxy {
    address private immutable beacon;

    constructor(address _beacon) {
        require(_beacon != address(0), "OpenDefiNFTProxy:ZERO_ADDRESS ");
        beacon = _beacon;
    }

    fallback() external payable {
        address impl = _implementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

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

    function _implementation() internal view virtual returns (address) {
        return IBeacon(beacon).implementation();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

contract OpenDefiExchangeProxy {
    address private immutable beacon;

    constructor(address _beacon) {
        require(_beacon != address(0), "OpenDefiExchangeProxy:ZERO_ADDRESS ");
        beacon = _beacon;
    }

    fallback() external payable {
        address impl = _implementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

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

    function _implementation() internal view virtual returns (address) {
        return IBeacon(beacon).implementation();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "../libraries/LibPart.sol";

/// @dev Interface for the OpenDefi Collection Factory
interface IOpenDefiNFT {
    /**
     * @notice Called to initialise the collection
     */
    function __OpenDefiNFT_init(
        string memory _uri,
        string memory _name,
        string memory _symbol,
        address[] memory _backedAssets,
        address _owner,
        address _exchangeAddress
    ) external;

    /*
     * @notice return royalty details for the provide token id.
     */
    function getRoyalties(uint256 id)
        external
        view
        returns (LibPart.Part[] memory);

    /*
     *Token (ERC721, ERC721Minimal, ERC721MinimalMeta, ERC1155 ) can have a number of different royalties beneficiaries
     *calculate sum all royalties, but royalties beneficiary will be only one royalties[0].account, according to rules of IERC2981
     */
    function royaltyInfo(uint256 id, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    // To store collection factory address.
    function collectionFactory() external view returns (address);

    // To store exchange contract address.
    function exchangeAddress() external view returns (address);

    /**
     * @dev Returns true if the burning is paused, and false otherwise.
     */
    function burnPaused() external view returns (bool);

    /**
     * @dev Returns true if the NFT transfer is paused, and false otherwise.
     */
    function transferPaused() external view returns (bool);

    /**
     * @dev Returns true if the NFT collection is paused, and false otherwise.
     */
    function paused() external view returns (bool);

    // stores NFT name
    function name() external view returns (string memory);

    // stores NFT symbol
    function symbol() external view returns (string memory);

    // Mapping from token id to creators
    function creators(uint256, uint256) external view returns (LibPart.Part memory);

    function addBackedAssets(
        address asset,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external;

    function getSupply(uint256 tokenId) external view returns (uint256);

    function getBackedAssetAmounts(uint256 _id)
        external
        view
        returns (uint256[] memory);

    // Storage variable to store the backed asset id.
    function backedAssetID() external view returns (uint256);

    // Mapping from token id to backed asset address.
    function backedAssets(uint256 assetId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @dev Interface for the Exchange
interface IExchange {
    function __OpenDefiExchange_init(
        bool _isPrivateCollection,
        address _collection,
        address _insuranceToken,
        address _owner,
        uint256 _insuranceInterval,
        uint256 _insurancePrice,
        uint256[] memory _feeConfig,
        address[] memory _feeTokens
    ) external;

    /**
     * @dev function allows the buyers to puchase nft from a list of options.
     * Appropriate Fee is calculated and added to the purchase.
     * Minimum protection date period is calculated and added to each NFT purchases.
     */
    function buyNFT(
        address buyer,
        uint256 amount,
        uint256 tokenId,
        uint256 feeTokenId,
        bool isInsured,
        bytes memory data
    ) external;

    /**
     * @dev Function to save the initial NFT price
     *
     * Requirements:
     * The number price passed should be equal to the fee token id.
     */
    function saveNFTLaunchPrice(uint256 _id, uint256[] memory _nftPrice)
        external;

    /**
     * @dev Function to get the NFT price
     *
     */
    function getNFTPrice(uint256 _id) external view returns (uint256[] memory);

    /**
     * @dev To update the NFT prices '_nftPrice'
     *
     * Requirements:
     * Caller should be owner
     * token id og nft should be valid
     * fee token id should be valid
     */
    function updateNFTPrice(
        uint256 _id,
        uint256 feeTokenId,
        uint256 _nftPrice
    ) external;

    /**
     * @dev Buyer can redeem the NFT which was bought before.
     * The contract not be paused for burn.
     * The buyer should have posses the token inorder to redeem it.
     */
    function redeemNFT(
        address buyer,
        uint256 amount,
        uint256 tokenId,
        uint256 purchaseId,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @dev Interface for the OpenDefi Collection Factory
interface IOpenDefiCollectionFactory {
    /**
     * @dev Called to view latest collection id
     */
    function latestCollectionId() external view returns (uint256);

    /**
     * @dev Called to view status of factory
     */
    function isFactoryPublic() external view returns (bool);

    /**
     * @dev Called to view collection address mapped to a collection id
     * @param collectionId - the collection id mapped for collection address
     * @return collectionAddress - address of collection
     */
    function collections(uint256 collectionId) external view returns (address);

    function exchanges(uint256 collectionId) external view returns (address);

    function paused() external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library LibPart {
    bytes32 public constant TYPE_HASH =
        keccak256("Part(address account,uint96 value)");

    /// @notice Stores account address and amount which can be used for fee related purposes
    struct Part {
        address payable account;
        uint96 value;
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