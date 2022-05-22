// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC165.sol";
import "./IERC20.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuardUpgradable.sol";

contract Rental is ReentrancyGuardUpgradable, OwnableUpgradeable {

    using SafeMath for uint256;
    
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 private constant _INTERFACE_ID_ERC20 = 0x74a1476f;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    struct Asset {
        address contractAddress;
        uint256 tokenId;
        bytes4 interfaceId;
    }

    struct Fee {
        address contractAddress;
        uint256 amount;
        uint8 feeType; // 0 EMPTY, 1 FLAT, 2 BLOCK
    }

    struct AssetInventory {
        Asset asset;
        uint256 amount;
    }

    mapping(bytes32 => AssetInventory) public Inventory;
    mapping(bytes32 => Fee) public InventoryFee;
    bytes32[] private _Identifiers;
    mapping(bytes32 => bool) private _InventoryIdentifierUsed;

    mapping(bytes32 => bytes32[]) private _AssetToAssetInventory;
    bytes32[] private _Assets;

    function initialize() public initializer {
        __Ownable_init();
        ReentrancyGuardUpgradable.init();
    }

    function GetAssets() public view returns (bytes32[] memory assets) {
        return _Assets;
    }

    function GetAssetInventory(bytes32 assetTokenIdentifier) public view returns (bytes32[] memory assets) {
        return _AssetToAssetInventory[assetTokenIdentifier];
    }

    function Rent(address askAddress, uint256 askTokenId, address costAddress, uint256 costTokenId) public nonReentrant {
        AssetInventory memory cost = Inventory[keccak256(abi.encodePacked(askAddress, askTokenId, costAddress, costTokenId))];
        AssetInventory memory ask = Inventory[keccak256(abi.encodePacked(cost.asset.contractAddress, cost.asset.tokenId, askAddress, askTokenId))];
        require(cost.asset.contractAddress != address(0), 'invalid inventory');
        require(_checkBalanceOfAsset(askAddress, askTokenId, address(this), ask.asset.interfaceId) >= ask.amount, 'contract balance not enough');
        require(_checkBalanceOfAsset(cost.asset.contractAddress, cost.asset.tokenId, _msgSender(), cost.asset.interfaceId) >= cost.amount, 'user balance is not enough');
        require(_checkAllowanceOfAsset(cost.asset.contractAddress, cost.asset.interfaceId, cost.amount), 'not allowed to swap');
        require(_transferAsset(askAddress, askTokenId, ask.asset.interfaceId, address(this), _msgSender(), ask.amount), 'error swapping ask');
        require(_transferAsset(cost.asset.contractAddress, cost.asset.tokenId, cost.asset.interfaceId, _msgSender(), address(this), cost.amount), 'error swapping cost');
    }

    // onlyOwner function to rescue assets

    function AddInventory(address askAddress, uint256 askTokenId, uint256 askAmount, address costAddress, uint256 costTokenId, uint256 costAmount) public onlyOwner {
        bytes32 askInventoryIdentifier = keccak256(abi.encodePacked(askAddress, askTokenId, costAddress, costTokenId));
        bytes32 askTokenIdentifier = keccak256(abi.encodePacked(askAddress, askTokenId));
        bytes32 costInventoryIdentifier = keccak256(abi.encodePacked(costAddress, costTokenId, askAddress, askTokenId));
        bytes32 costTokenIdentifier = keccak256(abi.encodePacked(costAddress, costTokenId));
        require(askInventoryIdentifier != costInventoryIdentifier, "ask and cost should not be the same");
        require(!_InventoryIdentifierUsed[askInventoryIdentifier] && !_InventoryIdentifierUsed[costInventoryIdentifier], 'inventory already exists');
        _addAsset(askTokenIdentifier, askInventoryIdentifier);
        _addAsset(costTokenIdentifier, costInventoryIdentifier);
        bytes4 costType = _determineTokenInterface(costAddress);
        bytes4 askType = _determineTokenInterface(askAddress);
        Inventory[askInventoryIdentifier] = AssetInventory(Asset(costAddress, costTokenId, costType), costAmount);
        Inventory[costInventoryIdentifier] = AssetInventory(Asset(askAddress, askTokenId, askType), askAmount);
    }

    function AddFee(address askAddress, uint256 askTokenId,address costAddress, uint256 costTokenId, address feeContract, uint256 amount, uint8 feeType ) public onlyOwner {
        bytes32 askInventoryIdentifier = keccak256(abi.encodePacked(askAddress, askTokenId, costAddress, costTokenId));
        require(_InventoryIdentifierUsed[askInventoryIdentifier], 'unknown inventory');
        InventoryFee[askInventoryIdentifier] = Fee(feeContract, amount, feeType);
    }

    function _addAsset(bytes32 assetTokenIdentifier, bytes32 assetInventoryIdentifier) private {
        if (!_containsAsset(assetTokenIdentifier)) {
            _Assets.push(assetTokenIdentifier);
        }
        if (!_InventoryIdentifierUsed[assetInventoryIdentifier]) {
            _AssetToAssetInventory[assetTokenIdentifier].push(assetInventoryIdentifier);
            _InventoryIdentifierUsed[assetInventoryIdentifier] = true;
            _Identifiers.push(assetInventoryIdentifier);
        }
    }

    function DeleteInventory(address askAddress, uint256 askTokenId, address costAddress, uint256 costTokenId) public onlyOwner {
        bytes32 askInventoryIdentifier = keccak256(abi.encodePacked(askAddress, askTokenId, costAddress, costTokenId));
        bytes32 askTokenIdentifier = keccak256(abi.encodePacked(askAddress, askTokenId));
        bytes32 costInventoryIdentifier = keccak256(abi.encodePacked(costAddress, costTokenId, askAddress, askTokenId));
        bytes32 costTokenIdentifier = keccak256(abi.encodePacked(costAddress, costTokenId));
        require(_InventoryIdentifierUsed[askInventoryIdentifier] && _InventoryIdentifierUsed[costInventoryIdentifier], 'inventory does not exist');
        _removeFromInventory(askTokenIdentifier, askInventoryIdentifier);
        _removeFromInventory(costTokenIdentifier, costInventoryIdentifier);
    }

    function _removeFromInventory(bytes32 assetTokenIdentifier, bytes32 assetInventoryIdentifier) private {
        
        bool assetTokenUsed = false;
        for(uint i=0; i<_Identifiers.length; i++) {
            bytes32 tokenIdentifier = keccak256(abi.encodePacked(Inventory[_Identifiers[i]].asset.contractAddress, Inventory[_Identifiers[i]].asset.tokenId));
            if (_Identifiers[i] == assetInventoryIdentifier) {
                _Identifiers[i] = _Identifiers[_Identifiers.length - 1];
                _Identifiers.pop();
            }
            if (assetTokenIdentifier == tokenIdentifier) {
                assetTokenUsed = true;
            }
        }
        if (!assetTokenUsed || _Identifiers.length == 1 ) {
            _deleteFromArray(_Assets, assetTokenIdentifier);
        }
        _deleteFromArray(_AssetToAssetInventory[assetTokenIdentifier], assetInventoryIdentifier);
        delete Inventory[assetInventoryIdentifier];
        delete _InventoryIdentifierUsed[assetInventoryIdentifier];
    }

    function _deleteFromArray(bytes32[] storage arr, bytes32 assetIdentifier) private {
        for(uint i=0; i<arr.length; i++) {
            if (arr[i] == assetIdentifier) {
                arr[i] = arr[arr.length - 1];
                arr.pop();
            }
        }
    }

    function _containsAsset(bytes32 assetIdentifier) private view returns (bool seen) {
        seen = false;
        for(uint i=0; i<_Assets.length; i++) {
            if (_Assets[i] == assetIdentifier) {
               seen = true;
            }
        }      
    }

    function Version() public virtual pure returns (uint256 version) {
        return 1;
    }

    function _determineTokenInterface(address contractAddress) private view returns (bytes4 interfaceId) {
        if (_checkInterface(contractAddress, _INTERFACE_ID_ERC1155)) {
            return _INTERFACE_ID_ERC1155;
        } else if (_checkInterface(contractAddress, _INTERFACE_ID_ERC721)) {
            return _INTERFACE_ID_ERC721;
        }
        return _INTERFACE_ID_ERC20;
    }

    function _checkBalanceOfAsset(address contractAddress, uint256 tokenId, address account, bytes4 interfaceId) private view returns (uint256 balance) {
        if (interfaceId == _INTERFACE_ID_ERC1155) {
            return IERC1155(contractAddress).balanceOf(account, tokenId);
        } else if (interfaceId == _INTERFACE_ID_ERC721) {
            return (IERC721(contractAddress).ownerOf(tokenId) == account)? 1: 0;
        } else {
            return IERC20(contractAddress).balanceOf(account);
        }
    }

    function _checkAllowanceOfAsset(address contractAddress, bytes4 interfaceId, uint256 amount) private view returns (bool approved) {
        if (interfaceId == _INTERFACE_ID_ERC1155) {
            return IERC1155(contractAddress).isApprovedForAll(_msgSender(), address(this));
        } else if (interfaceId == _INTERFACE_ID_ERC721) {
            return IERC721(contractAddress).isApprovedForAll(_msgSender(), address(this));
        } else {
            return IERC20(contractAddress).allowance(_msgSender(), address(this)) >= amount;
        }
    }

    function _transferAsset(address contractAddress, uint256 tokenId, bytes4 interfaceId, address fromAddress, address destinationAddress, uint256 amount) private returns (bool transferred) {
        if (interfaceId == _INTERFACE_ID_ERC1155) {
            IERC1155(contractAddress).safeTransferFrom(fromAddress, destinationAddress, tokenId, amount, "");
        } else if (interfaceId == _INTERFACE_ID_ERC721) {
            try IERC721(contractAddress).safeTransferFrom(fromAddress, destinationAddress, tokenId) {} // erc721 should safe transfer
            catch {
                IERC721(contractAddress).transferFrom(fromAddress, destinationAddress, tokenId); // emblem safe transfer is non standard
            }
        } else {
            IERC20(contractAddress).transferFrom(fromAddress, destinationAddress, amount);
        }
        return _checkBalanceOfAsset(contractAddress, tokenId, destinationAddress, interfaceId) >= amount;
    }

    function _checkInterface(address token, bytes4 _interface) private view returns (bool) {
        IERC165 nftToken = IERC165(token);
        bool supportsInterface = false;
        try  nftToken.supportsInterface(_interface) returns (bool _supports) {
            supportsInterface = _supports;
        } catch {
            if (_interface == 0x74a1476f) {
                supportsInterface = true;
            }
        }
        return supportsInterface;
    }

    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IERC721 {
    function burn(uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function mint( address _to, uint256 _tokenId, string calldata _uri, string calldata _payload) external;
    function changeName(string calldata name, string calldata symbol) external;
    function updateTokenUri(uint256 _tokenId,string memory _uri) external;
    function tokenPayload(uint256 _tokenId) external view returns (string memory);
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
    function getApproved(uint256 _tokenId) external returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function setApprovalForAll( address _operator, bool _approved) external;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
    function mint(address _to, uint256 _tokenId, uint256 _amount) external;
    function burn(address _from, uint256 _tokenId, uint256 _amount) external;
    function mintWithSerial(address _to, uint256 _tokenId, uint256 _amount, bytes memory serialNumber) external;
}

interface IERC1155Receiver {
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns(bytes4);
    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external returns(bytes4);
}

interface IERC1155MetadataURI  {
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
    modifier onlyOwner() virtual {
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
pragma solidity ^0.8.4;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;
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
contract ReentrancyGuardUpgradable {
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
    uint256 private _NOT_ENTERED;
    uint256 private _ENTERED;

    uint256 private _status;

    function init() internal {
         _NOT_ENTERED = 1;
         _ENTERED = 2;
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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