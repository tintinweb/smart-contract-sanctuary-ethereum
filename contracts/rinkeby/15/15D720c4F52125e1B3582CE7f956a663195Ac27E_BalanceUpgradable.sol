pragma solidity 0.8.4;
import "./IERC721.sol";
import "./ReentrancyGuardUpgradable.sol";
import "./HasRegistrationUpgradable.sol";

contract BalanceUpgradable is ReentrancyGuardUpgradable, HasRegistrationUpgradable {

    bool canAddBalances;
    mapping(uint256 => bool) public usedNonces;

    struct BalanceObject {
        uint balance;
        uint blockchain;
        string name;
        string symbol;
        uint256 tokenId;
        address _address;
        uint256 _type;
    }

    struct Balances {
        BalanceObject[] balances;
    }

    mapping(address => mapping(uint256 => Balances)) internal balances;
    mapping(address => uint256[]) contractTokenIds;
    mapping(address=> mapping(address => bool)) public witnesses;
    mapping(bytes32 => mapping(address => uint256[])) public tokensToContractMap;
    
    function initialize() public initializer {
        __Ownable_init();
        ReentrancyGuardUpgradable.init();
        canAddBalances = true;
    }

    function version() public pure returns(uint256) {
        return 2;
    }

    /* ADMIN WRITE */
    function addWitness(address nftAddress, address _witness) public onlyOwner {
        witnesses[nftAddress][_witness] = true;
    }

    function removeWitness(address nftAddress, address _witness) public onlyOwner {
        witnesses[nftAddress][_witness] = false;
    }

    function isWitness(address nftAddress, address witness) public view onlyOwner returns (bool) {
        return witnesses[nftAddress][witness];
    }

    function getBalance(address nftAddress, uint256 tokenId) public view onlyOwner returns (Balances memory) {
        return balances[nftAddress][tokenId];
    } 

    function getAssetsForContract(address nftAddress) public view onlyOwner returns (uint256[] memory) {
        return contractTokenIds[nftAddress];
    }

    function getAssetsForContractAtIndex(address nftAddress, uint256 index) public view onlyOwner returns (uint256) {
        return contractTokenIds[nftAddress][index];
    }

    function getTokensFromMap(address nftAddress, bytes32 token) public view onlyOwner returns(uint256[] memory) {
        return tokensToContractMap[token][nftAddress];
    }

    function addBalanceToAsset(address nftAddress, uint256 tokenId, Balances calldata balance) public onlyOwner {
         balances[nftAddress][tokenId] = balance;
         contractTokenIds[nftAddress].push(tokenId);
    }

    function addTokenToMap(address nftAddress, bytes32 token, uint256 tokenId) public onlyOwner {
        tokensToContractMap[token][nftAddress].push(tokenId);
    }

    function addNonce(uint256 nonce) public onlyOwner returns (bool) {
        require(!usedNonces[nonce], 'Nonce already used');
        return usedNonces[nonce] = true;
    }

    function toggleCanAddBalances() public onlyOwner {
        canAddBalances = !canAddBalances;
    }

    /* USER WRITE */

    function addBalanceToAsset(address nftAddress, uint256 tokenId, Balances calldata balance, uint256 nonce, bytes calldata signature) public nonReentrant {
        if (canAddBalances) {
            require(IERC721(nftAddress).ownerOf(tokenId) == _msgSender(), 'Only owner can add balance');
            require(!usedNonces[nonce], 'Nonce already used');
            require(addNonce(nonce), 'Nonce not added');
            bytes32 serializedBalance = getSerializedBalance(balance);
            bytes32 _hash = addNonceToSerializedBalance(serializedBalance, nonce);
            require(isWitnessed(nftAddress, _hash, signature), 'Not a witness');
            addBalanceToAsset(nftAddress, tokenId, balance);
            addTokensToMap(nftAddress, tokenId, balance);
        } else {
            revert("Adding balances is disabled");
        }
        
    }

    function addTokensToMap(address nftAddress, uint256 tokenId, Balances calldata _balances) internal {
        for (uint i = 0; i < _balances.balances.length; i++) {
            BalanceObject memory balance = _balances.balances[i];
            bytes32 _hash = keccak256(abi.encodePacked(balance.blockchain, balance.name));
            addTokenToMap(nftAddress, _hash, tokenId);
        }
    }


    function getSerializedBalances(Balances calldata _balances) public pure returns (bytes32[] memory) {
        bytes32[] memory hashes = new bytes32[](_balances.balances.length);
        for (uint i = 0; i < _balances.balances.length; i++) {
            BalanceObject memory balance = _balances.balances[i];
            hashes[i] = keccak256(abi.encodePacked(balance.balance, balance.blockchain, balance.name, balance.symbol, balance.tokenId, balance._address, balance._type));
        }
        return hashes;
    }

    function getSerializedBalance(Balances calldata _balances) public pure returns (bytes32) {
        bytes32[] memory hashes = getSerializedBalances(_balances);
        bytes32 _hash = keccak256(abi.encodePacked(hashes[0]));
        for (uint i = 1; i < hashes.length; i++) {
            _hash = keccak256(abi.encodePacked(_hash, hashes[i]));
        }
        return _hash;
    }    

    function addNonceToSerializedBalance(bytes32 _hash, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(nonce, _hash));
    }

    function isWitnessed(address nftAddress, bytes32 _hash, bytes calldata signature) public view returns (bool) {
        address addressFromSig = recoverSigner(_hash, signature);
        return isWitness(nftAddress, addressFromSig);
    }

    function getTokenIdsFromMap(address nftAddress, uint blockchain, string calldata name) public view returns (uint256[] memory) {
        bytes32 _hash = keccak256(abi.encodePacked(blockchain, name));
        return getTokensFromMap(nftAddress, _hash);
    }

    function getTokenIdCountFromMap(address nftAddress, uint blockchain, string calldata name) public view returns(uint256) {
        bytes32 _hash = keccak256(abi.encodePacked(blockchain, name));
        return getTokensFromMap(nftAddress, _hash).length;
    }

    function getTokenIdsFromMapAtIndex(address nftAddress, uint blockchain, string calldata name, uint256 index) public view returns (uint256) {
        bytes32 _hash = keccak256(abi.encodePacked(blockchain, name));
        return getTokensFromMap(nftAddress, _hash)[index];
    }

    /* UTIL */
    function getAddressFromSignatureHash(bytes32 _hash, bytes calldata signature) public pure returns (address) {
        address addressFromSig = recoverSigner(_hash, signature);
        return addressFromSig;
    }

    function recoverSigner(bytes32 hash, bytes memory sig) public pure returns (address) {
        require(sig.length == 65, "Require correct length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Signature version not match");

        return recoverSigner2(hash, v, r, s);
    }

    function recoverSigner2(bytes32 h, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, h));
        address addr = ecrecover(prefixedHash, v, r, s);

        return addr;
    }

}

pragma solidity 0.8.4;
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
    function isApprovedForAll(address _owner, address _operator) external returns (bool);
    function setApprovalForAll( address _operator, bool _approved) external;
}

pragma solidity 0.8.4;
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

pragma solidity 0.8.4;
import "./IsOverridableUpgradable.sol";

interface IRegistrationStorage {
    function upgradeVersion(address _newVersion) external;
}

contract HasRegistrationUpgradable is IsOverridableUpgradable {

    // address StorageAddress;
    // bool initialized = false;

    mapping(address => uint256) public registeredContracts; // 0 EMPTY, 1 ERC1155, 2 ERC721, 3 HANDLER, 4 ERC20, 5 BALANCE, 6 CLAIM, 7 UNKNOWN, 8 FACTORY, 9 STAKING
    mapping(uint256 => address[]) public registeredOfType;
    
    uint256 public contractCount;

    modifier isRegisteredContract(address _contract) {
        require(registeredContracts[_contract] > 0, "Contract is not registered");
        _;
    }

    modifier isRegisteredContractOrOwner(address _contract) {
        require(registeredContracts[_contract] > 0 || owner() == _msgSender(), "Contract is not registered nor Owner");
        _;
    }

    // constructor(address storageContract) {
    //     StorageAddress = storageContract;
    // }

    // function initialize() public {
    //     require(!initialized, 'already initialized');
    //     IRegistrationStorage _storage = IRegistrationStorage(StorageAddress);
    //     _storage.upgradeVersion(address(this));
    //     initialized = true;
    // }

    function registerContract(address _contract, uint _type) public isRegisteredContractOrOwner(_msgSender()) {
        contractCount++;
        registeredContracts[_contract] = _type;
        registeredOfType[_type].push(_contract);
    }

    function unregisterContract(address _contract, uint256 index) public onlyOwner isRegisteredContract(_contract) {
        require(contractCount > 0, 'No vault contracts to remove');
        delete registeredOfType[registeredContracts[_contract]][index];
        delete registeredContracts[_contract];
        contractCount--;
    }

    function isRegistered(address _contract, uint256 _type) public view returns (bool) {
        return registeredContracts[_contract] == _type;
    }
}

pragma solidity 0.8.4;
import "./OwnableUpgradeable.sol";

abstract contract IsOverridableUpgradable is OwnableUpgradeable {

    bool byPassable;
    mapping(address => mapping(bytes4 => bool)) byPassableFunction;
    mapping(address => mapping(uint256 => bool)) byPassableIds;

    modifier onlyOwner override {
        bool canBypass = byPassable && byPassableFunction[_msgSender()][msg.sig];
        require(owner() == _msgSender() || canBypass, "Not owner or able to bypass");
            _;
    }

    modifier onlyOwnerOrBypassWithId(uint256 id) {
        require (owner() == _msgSender() || (id != 0 && byPassableIds[_msgSender()][id]), "Invalid id");
            _;
    }

    function toggleBypassability() public onlyOwner {
      byPassable = !byPassable;
    }

    function addBypassRule(address who, bytes4 functionSig, uint256 id) public onlyOwner {
        byPassableFunction[who][functionSig] = true;
        if (id != 0) {
            byPassableIds[who][id] = true;
        }        
    }

    function removeBypassRule(address who, bytes4 functionSig, uint256 id) public onlyOwner {
        byPassableFunction[who][functionSig] = false;
        if (id !=0) {
            byPassableIds[who][id] = true;
        }        
    }
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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}