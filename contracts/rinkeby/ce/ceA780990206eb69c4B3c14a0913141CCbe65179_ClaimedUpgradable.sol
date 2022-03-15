pragma solidity 0.8.4;
import "./IERC721.sol";
import "./ReentrancyGuardUpgradable.sol";
import "./HasRegistrationUpgradable.sol";

contract ClaimedUpgradable is ReentrancyGuardUpgradable, HasRegistrationUpgradable {
    
    bool canClaim;
    mapping(address => bytes32) LegacyClaims;
    mapping(address => bytes32) LegacyClaimsBy;
    mapping(address => mapping(uint => address)) Claims;
    mapping(address => uint256[]) ClaimsFor;
    address[] BurnAddresses;
    
    function initialize() public initializer {
        __Ownable_init();
        ReentrancyGuardUpgradable.init();
        canClaim = true;
        BurnAddresses.push(address(0));
        BurnAddresses.push(0x5D152dd902CC9198B97E5b6Cf5fc23a8e4330180);
    }

    function version() public pure returns (uint256) {
        return 2;
    }
    
    function isBurnAddress(address needle) public view returns (bool) {
        address[] memory burnAddresses = getBurnAddresses();
        for (uint i=0; i < burnAddresses.length; i++) {
            if (burnAddresses[i] == needle) {
                return true;
            }
        }
        return false;
    }

    function toggleCanClaim() public onlyOwner {
        canClaim = !canClaim;
    }
    
    function claim(address nftAddress, uint tokenId, address _claimedBy) public nonReentrant isRegisteredContract(_msgSender()) {        
        if (canClaim) {
            addToClaims(nftAddress, tokenId, _claimedBy);
        } else { 
            revert("Claiming is turned off");
        }
    }
    
    function isClaimed(address nftAddress, uint tokenId, bytes32[] calldata proof ) public view returns(bool) {
        bytes32 _hash = keccak256(abi.encodePacked(tokenId));
        IERC721 token = IERC721(nftAddress);        
        if (proof.length == 0) {
            bool claimed = getClaims(nftAddress, tokenId) != address(0);
            bool addressClaimed = false;
            try token.ownerOf(tokenId) returns (address _owner) {
                if (isBurnAddress(_owner)) {
                    addressClaimed = true;
                }
            } catch {}
            return addressClaimed || claimed;
        } else {
            bytes32 root = getLegacyClaims(nftAddress);
            return verifyScript(root, _hash, proof);
        }
    }

    function getClaimsFor(address _owner) public view returns (uint256[] memory) {
        return ClaimsFor[_owner];
    }

    function getLegacyClaims(address nftAddress) public view returns(bytes32) {
        return LegacyClaims[nftAddress];
    }
    
    function claimedBy(address nftAddress, uint tokenId) public view returns (address _owner, string memory _type) {
        address claimed = getClaims(nftAddress, tokenId);
        if (claimed != address(0)) {
            return (claimed, "record");
        } else {
            return (address(0), "unknown");
        }
    }

    function legacyClaimedBy(address nftAddress, address claimant, uint tokenId, bytes32[] calldata proof) public view returns (address _owner, string memory _type) {
        bytes32 root = getLegacyClaimsBy(nftAddress);
        bytes32 _hash = keccak256(abi.encodePacked(claimant, tokenId));
        require(verifyScript(root, _hash, proof), "invalid proof");
        return (claimant, 'legacy');
    }

    function addLegacy(address nftAddress, bytes32 root) onlyOwner public {
        LegacyClaims[nftAddress] = root;      
    }

    function addLegacyClaimedBy(address nftAddress, bytes32 root) onlyOwner public {
        LegacyClaimsBy[nftAddress] = root;
    }

    function getBurnAddresses() internal view returns (address[] memory){
        return BurnAddresses;
    }

    function getLegacyClaimsBy(address nftAddress) internal view returns(bytes32) {
        return LegacyClaimsBy[nftAddress];
    }
    
    function getClaims(address nftAddress, uint tokenId) internal view returns (address) {
        return Claims[nftAddress][tokenId];
    }
    
    function addToBurnAddresses(address burnAddress) internal onlyOwner {
         BurnAddresses.push(burnAddress);
    }
    
    function addToClaims(address nftAddress, uint tokenId, address _owner) internal {
        Claims[nftAddress][tokenId] = _owner;
        ClaimsFor[_owner].push(tokenId);
    }

    function verifyScript(bytes32 root, bytes32 _hash, bytes32[] calldata proof) public pure returns (bool) {
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (_hash <= proofElement) {
                _hash = optihash(_hash, proofElement);
            } else {
                _hash = optihash(proofElement, _hash);
            }
        }
        return _hash == root;
    }
    // memory optimization from: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/3039
    function optihash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
        mstore(0x00, a)
        mstore(0x20, b)
        value := keccak256(0x00, 0x40)
        }
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
    
    function registerContract(address _contract, uint _type) public isRegisteredContractOrOwner(_msgSender()) {
        contractCount++;
        registeredContracts[_contract] = _type;
        registeredOfType[_type].push(_contract);
    }

    function unregisterContract(address _contract, uint256 index) public onlyOwner isRegisteredContract(_contract) {
        require(contractCount > 0, 'No vault contracts to remove');
        address[] storage arr = registeredOfType[registeredContracts[_contract]];
        arr[index] = arr[arr.length - 1];
        arr.pop();
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