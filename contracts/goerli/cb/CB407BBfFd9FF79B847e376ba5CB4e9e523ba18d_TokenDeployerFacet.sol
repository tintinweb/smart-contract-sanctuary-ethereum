// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/interface/IImplementationAuthorityVersion.sol";

interface IVersion{
    function version() external view returns(bytes32);
}
contract ImplementationAuthorityVersion is IImplementationAuthorityVersion, Ownable {
    event UpdatedImplementation(address newAddress);

    address public implementation;

    constructor(address _implementation) {
        implementation = _implementation;
        emit UpdatedImplementation(_implementation);
    }

    function getImplementation() external view returns (address) {
        return implementation;
    }

    function updateImplementation(address _newImplementation) public onlyOwner {
        implementation = _newImplementation;
        emit UpdatedImplementation(_newImplementation);
    }

    function getImplementationVersion() public view returns (bytes32) {
        return IVersion(implementation).version();
    }
    
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0; 

import 'contracts/interface/IImplementationAuthorityVersion.sol';
/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
 
contract ProxyV1 {
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev This event will be emitted every time the implementation gets upgraded
     * @param implementation representing the address of the upgraded implementation
     */
    event Upgraded(address indexed implementation);

    // Storage position of the address of the maintenance boolean
    bytes32 private constant maintenancePosition = keccak256("com.proxy.maintenance");
    // Storage position of the address of the current implementation
    bytes32 private constant implementationAuthorityPosition = keccak256("com.proxy.implementationAuthority");
    // Storage position of the owner of the contract
    bytes32 private constant proxyOwnerPosition = keccak256("com.proxy.owner");
    
    /**
     * @dev the constructor sets the original owner of the contract to the sender account.
     */
    constructor() {
        setUpgradeabilityOwner(msg.sender);
    }

    /**
     * @dev Tells if contract is on maintenance
     * @return _maintenance if contract is on maintenance
     */
    function maintenance() public view returns (bool _maintenance) {
        bytes32 position = maintenancePosition;
        assembly {
            _maintenance := sload(position)
        }
    }

    /**
     * @dev Sets if contract is on maintenance
     */
    function setMaintenance(bool _maintenance) external onlyProxyOwner {
        bytes32 position = maintenancePosition;
        assembly {
            sstore(position, _maintenance)
        }
    }

    /**
     * @dev Tells the address of the owner
     * @return owner the address of the owner
     */
    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }

    /**
     * @dev Sets the address of the owner
     */
    function setUpgradeabilityOwner(address newProxyOwner) internal {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, newProxyOwner)
        }
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        require(newOwner != address(0), 'OwnedUpgradeabilityProxy: OWNER ADDRESS ZERO');
        emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
        setUpgradeabilityOwner(newOwner);
    }

    /*
     * @dev Allows the proxy owner to upgrade the current version of the proxy.
     * @param implementation representing the address of the new implementation to be set.
     */
    function upgradeTo(address newImplementation) public onlyProxyOwner {
        _upgradeTo(newImplementation);
    }

    /*
     * @dev Allows the proxy owner to upgrade the current version of the proxy and call the new implementation
     * to initialize whatever is needed through a low level call.
     * @param implementation representing the address of the new implementation to be set.
     * @param data represents the msg.data to bet sent in the low level call. This parameter may include the function
     * signature of the implementation to be called with the needed payload
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) payable public onlyProxyOwner {
        upgradeTo(newImplementation);
        (bool success, ) = address(this).call{ value: msg.value }(data);
        require(success, "OwnedUpgradeabilityProxy: INVALID");
    }

    /**
     * @dev Fallback function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    fallback() external payable {
        _fallback();
    }

    receive () external payable {
        _fallback();
    }

    /**
     * @dev Tells the address of the current implementation
     * @return impl address of the current implementation
     */
    function implementation() public view returns (address impl) {
        bytes32 position = implementationAuthorityPosition;
        assembly {
            impl := sload(position)
        }
        impl = impl != address(0) ? IImplementationAuthorityVersion(impl).getImplementation() : address(0);
    }

    /**
     * @dev Sets the address of the current implementation
     * @param newImplementation address representing the new implementation to be set
     */
    function _setImplementation(address newImplementation) internal {
        bytes32 position = implementationAuthorityPosition;
        assembly {
            sstore(position, newImplementation)
        }
    }

    /**
     * @dev Upgrades the implementation address
     * @param newImplementation representing the address of the new implementation to be set
     */
    function _upgradeTo(address newImplementation) internal {
        address currentImplementation = implementation();
        require(currentImplementation != newImplementation, 'OwnedUpgradeabilityProxy: SAME IMPLEMENTATION ADDRESS');
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function _fallback() internal {
        if (maintenance()) {
            require(msg.sender == proxyOwner(), 'OwnedUpgradeabilityProxy: FORBIDDEN');
        }
        address _impl = implementation();
        require(_impl != address(0), 'OwnedUpgradeabilityProxy: ADDRESS ZERO');
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner(), 'OwnedUpgradeabilityProxy: FORBIDDEN');
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/libraries/LibRoles.sol";
import "contracts/libraries/LibMultifacet.sol";

contract DeployerRolesFacet {

    bytes32 constant SUB_ADMIN = keccak256("tokendeployerfacet.roles.sub_admin");
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

    function addSubAdmin(address account) external {
        LibMultifacet.enforceIsContractOwner();
        LibRoles._grantRole(SUB_ADMIN, account);
    }

    function revokeSubAdmin(address account) external {
        LibMultifacet.enforceIsContractOwner();
        LibRoles._revokeRole(SUB_ADMIN, account);
    }

    function isSubAdmin(address account) external view returns (bool){
        return LibRoles.hasRole(SUB_ADMIN, account);
    }

    function renounceRole(bytes32 role) external {
        LibRoles.renounceRole(role, msg.sender);
    }

    function enforceIsOwnerOrSubAdmin() internal view { 
        require(LibRoles.hasRole(SUB_ADMIN, msg.sender) || LibMultifacet.contractOwner() == msg.sender, "RolesFacet: Unauthorized");
    }

    function enforceIsSubAdmin() internal view {
        require(LibRoles.hasRole(SUB_ADMIN, msg.sender), "RolesFacet: Unauthorized");
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/facets/DeployerRolesFacet.sol";
import "contracts/libraries/LibTokenDeployer.sol";
import "contracts/libraries/LibImplHub.sol";
import "contracts/libraries/LibRoles.sol";
import "contracts/interface/ITokenDeployer.sol";

contract TokenDeployerFacet is ITokenDeployer, DeployerRolesFacet {

    function initializeFacet(bytes32 _templateKey, bytes32[] calldata _keys, bytes32[] calldata _versions, address[] calldata _impls) public {
        bindAndSetImplementationTemplate(_templateKey, _keys, _versions, _impls);
    }

    function bindAndSetImplementationTemplate(bytes32 _templateKey, bytes32[] calldata _keys, bytes32[] calldata _versions, address[] calldata _impls) public {
        LibMultifacet.enforceIsContractOwner();
        LibImplHub._bindAndSetImplementationTemplate(_templateKey, _keys, _versions, _impls);
    }

    function getImplementationsGivenTemplateKey(bytes32 _templateKey) public view returns (address[] memory){
        return LibImplHub.getImplementationsForTemplate(_templateKey);
    }

    function createToken(string memory _mappingValue, bytes calldata _initData) external {
        enforceIsOwnerOrSubAdmin();
        LibTokenDeployer._createToken(_mappingValue, _initData);
    }

    function deployAdminIdentity(uint256 executionBuffer, uint256 reqSig, address tokenizationAgent, address issuer, address token) public returns(address){
        enforceIsOwnerOrSubAdmin();
        return LibTokenDeployer.deployAdminIdentity(executionBuffer, reqSig, tokenizationAgent, issuer, token);
    }

    function addAgents(address _transferAgent, address _tokenizationAgent, address _token) public {
        enforceIsOwnerOrSubAdmin();
        LibTokenDeployer.addTokenizationAgentOnToken(_tokenizationAgent, _token);
        LibTokenDeployer.addTransferAgentOnToken(_transferAgent, _token);
    }

    function deployAndWhitelist(address _token, address _userAddress, uint16 _countryCode) public {
        LibTokenDeployer.deployAndWhitelist(_token, _userAddress, _countryCode);
    }

    function batchDeployAndWhitelist(address _token, address[] calldata _userAddress, uint16[] calldata _countryCodes) public {
        LibTokenDeployer.batchDeployAndWhitelist(_token, _userAddress, _countryCodes);
    }

    function getIdentityOf(address _userAddress) public view returns(address) {
        return LibTokenDeployer.getIdentityOf(_userAddress);
    }

    function setRolesOnToken(address _userAddress, bytes32[] memory _roles, address _token) public {
        enforceIsSubAdmin();
        LibTokenDeployer.setRolesOnToken(_userAddress, _roles, _token);
    }
    
    function revokeRolesOnToken(address _userAddress, bytes32[] memory _roles, address _token) public {
        enforceIsSubAdmin();
        LibTokenDeployer.revokeRolesOnToken(_userAddress, _roles, _token);
    }

    function addSubAdminOnToken(address _userAddress, address _token) public {
        enforceIsSubAdmin();
        LibTokenDeployer.addSubAdminOnToken(_userAddress, _token);
    }
    
    function revokeSubAdminOnToken(address _userAddress, address _token) public {
        enforceIsSubAdmin();
        LibTokenDeployer.revokeSubAdminOnToken(_userAddress, _token);
    }

    function addTokenizationAgentOnToken(address _agent, address _token) public {
        enforceIsSubAdmin();
        LibTokenDeployer.addTokenizationAgentOnToken(_agent, _token);
    }

    function revokeTokenizationAgentOnToken(address _agent, address _token) public {
        enforceIsSubAdmin();
        LibTokenDeployer.revokeTokenizationAgentOnToken(_agent, _token);
    }

    function addTransferAgentOnToken(address _agent, address _token) public {
        enforceIsSubAdmin();
        LibTokenDeployer.addTransferAgentOnToken(_agent, _token);
    }

    function removeTransferAgentOnToken(address _agent, address _token) public {
        enforceIsSubAdmin();
        LibTokenDeployer.removeTransferAgentOnToken(_agent, _token);
    }

    function updateReleaseTimestampForToken(address _token, uint256 _timestamp) public {
        enforceIsSubAdmin();
        LibTokenDeployer.updateReleaseTimestampForToken(_token, _timestamp);
    }

    function updateHolderLimitForToken(address _token, uint256 _newHolderLimit) public {
        enforceIsSubAdmin();
        LibTokenDeployer.updateHolderLimitForToken(_token, _newHolderLimit);
    }

    function addSubAdminOnIdentityRegistry(address _userAddress, address _identityRegistry) public {
        enforceIsSubAdmin();
        LibTokenDeployer.addSubAdminOnIdentityRegistry(_userAddress, _identityRegistry);
    }

    function revokeSubAdminOnIdentityRegistry(address _subAdminAddress, address _identityRegistry) public {
        enforceIsSubAdmin();
        LibTokenDeployer.revokeSubAdminOnIdentityRegistry(_subAdminAddress, _identityRegistry);
    }

    function addSubAdminOnCompliance(address _userAddress, address _compliance) public {
        enforceIsSubAdmin();
        LibTokenDeployer.addSubAdminOnCompliance(_userAddress, _compliance);
    }

    function revokeSubAdminOnCompliance(address _subAdmin, address _compliance) public {
        enforceIsSubAdmin();
        LibTokenDeployer.revokeSubAdminOnCompliance(_subAdmin, _compliance);
    }

    /// Functions for Multisig

    function addAdminIdentitySigner(address _signer, address _token) public {
        enforceIsSubAdmin();
        LibTokenDeployer.addAdminIdentitySigner(_signer, _token);
    }

    function removeMultisigSigner(address _signer, address _token) public {
        enforceIsSubAdmin();
        LibTokenDeployer.removeMultisigSigner(_signer, _token);
    }

    function setSigRequirementOnMultisig(uint256 _sigReq, address _token) public {
        enforceIsSubAdmin();
        LibTokenDeployer.setSigRequirementOnMultisig(_sigReq, _token);
    }

    function getAdminIdentityMinter(address _token) public view returns (address) {
        return LibTokenDeployer.getAdminIdentityMinter(_token);
    }

    function getTrustedIssuersRegistry(address _token) public view returns (address) {
        return LibTokenDeployer.getTrustedIssuersRegistry(_token);
    }

    function getClaimTopicsRegistry(address _token) public view returns (address) {
        return LibTokenDeployer.getClaimTopicsRegistry(_token);
    }

    function getIdentityRegistry(address _token) public view returns (address) {
        return LibTokenDeployer.getIdentityRegistry(_token);
    }

    function getComplianceContract(address _token) public view returns (address) {
        return LibTokenDeployer.getComplianceContract(_token);
    }

    function adminCallUnrestricted(address _to, uint256 _value, bytes calldata _data) public returns (bool) {
        enforceIsSubAdmin();
        return LibTokenDeployer.adminCallUnrestricted(_to, _value, _data);
    } 

    function adminCallsUnrestricted(address[] calldata _to, uint256[] calldata _value, bytes[] calldata _data) public {
        enforceIsSubAdmin();
        return LibTokenDeployer.adminCallsUnrestricted(_to, _value, _data);
    }
}

//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./IIdentity.sol";

interface IAdminIdentityInit is IIdentity{

    /**
    * @dev Definition of the structure of a Key.
    *
    * Specification: Keys are cryptographic public keys, or contract addresses associated with this identity.
    * The structure should be as follows:
    *   - key: A public key owned by this identity
    *      - purposes: uint256[] Array of the key purposes, like 1 = MANAGEMENT, 2 = EXECUTION
    *      - keyType: The type of key used, which would be a uint256 for different key types. e.g. 1 = ECDSA, 2 = RSA, etc.
    *      - key: bytes32 The public key. // Its the Keccak256 hash of the key
    */
    struct Key {
        uint256[] purposes;
        uint256 keyType;
        bytes32 key;
    }

    struct Execution {
        bytes32 proposer;
        address to;
        uint256 value;
        uint256 timestamp;
        bytes data;
        bool executed;
        bytes32[] approvals;
    }

   /**
    * @dev Definition of the structure of a Claim.
    *
    * Specification: Claims are information an issuer has about the identity holder.
    * The structure should be as follows:
    *   - claim: A claim published for the Identity.
    *      - topic: A uint256 number which represents the topic of the claim. (e.g. 1 biometric, 2 residence (ToBeDefined: number schemes, sub topics based on number ranges??))
    *      - scheme : The scheme with which this claim SHOULD be verified or how it should be processed. Its a uint256 for different schemes. E.g. could 3 mean contract verification, where the data will be call data, and the issuer a contract address to call (ToBeDefined). Those can also mean different key types e.g. 1 = ECDSA, 2 = RSA, etc. (ToBeDefined)
    *      - issuer: The issuers identity contract address, or the address used to sign the above signature. If an identity contract, it should hold the key with which the above message was signed, if the key is not present anymore, the claim SHOULD be treated as invalid. The issuer can also be a contract address itself, at which the claim can be verified using the call data.
    *      - signature: Signature which is the proof that the claim issuer issued a claim of topic for this identity. it MUST be a signed message of the following structure: `keccak256(abi.encode(identityHolder_address, topic, data))`
    *      - data: The hash of the claim data, sitting in another location, a bit-mask, call data, or actual data based on the claim scheme.
    *      - uri: The location of the claim, this can be HTTP links, swarm hashes, IPFS hashes, and such.
    */
    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
        bytes signature;
        bytes data;
        string uri;
    }

    /**
     * @dev Emitted when an approval was added for a queued execution.
     *  
     * Specification: MUST be triggered when approval was successfully added for execution.
     */
    event ApprovalAdded(uint256 indexed _id, bytes32 indexed _key);

    /**
     * @dev Emitted when an approval is cancelled for an execution.
     *  
     * Specification: MUST be triggered when a previous approval was cancelled.
     */
    event ApprovalCancelled(uint256 indexed _id, bytes32 indexed _key);

    /**
     * @dev Emitted when an execution is cancelled by an operator
     *  
     * Specification: MUST be triggered when execution is cancelled.
     */
    event ExecutionCancelled(uint256 indexed _id, bytes32 indexed _key);

    /**
     * @dev Emitted when a mint execution is requested and added to the queue.
     *  
     * Specification: MUST be triggered when initiateMultisigMint() function is called.
     */
    event MintExecutionRequested(uint256 indexed _id, address indexed _to, uint256 _value, bytes32 indexed _key);
    
    function cancelApproval(uint256 _id) external returns (bool);
    function cancelExecution(uint256 _id) external;
    function cancelCheck(uint256 _id) external view returns (bool);
    function setSigRequirement(uint256 _sigs) external;
    function setExecutionExpiry(uint256 _expiry) external;
    function getExecution(uint256 _id) external view returns(Execution memory);
    function getCurrentExecution() external view returns(Execution memory);
    function getNonce() external view returns(uint256);
    function initiateMultisigMint(address _to, uint256 _value) external;

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IIdentity.sol";

interface IClaimIssuer is IIdentity {
    function revokeClaim(bytes32 _claimId, address _identity) external returns(bool);
    function getRecoveredAddress(bytes calldata sig, bytes32 dataHash) external pure returns (address);
    function isClaimRevoked(bytes calldata _sig) external view returns (bool);
    function isClaimValid(IIdentity _identity, uint256 claimTopic, bytes calldata sig, bytes calldata data) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IClaimTopicsRegistry {
    /**
     *  this event is emitted when a claim topic has been added to the ClaimTopicsRegistry
     *  the event is emitted by the 'addClaimTopic' function
     *  `claimTopic` is the required claim added to the Claim Topics Registry
     */
    event ClaimTopicAdded(uint256 indexed claimTopic);

    /**
     *  this event is emitted when a claim topic has been removed from the ClaimTopicsRegistry
     *  the event is emitted by the 'removeClaimTopic' function
     *  `claimTopic` is the required claim removed from the Claim Topics Registry
     */
    event ClaimTopicRemoved(uint256 indexed claimTopic);

    /**
     * @dev Add a trusted claim topic (For example: KYC=1, AML=2).
     * Only owner can call.
     * emits `ClaimTopicAdded` event
     * @param _claimTopic The claim topic index
     */
    function addClaimTopic(uint256 _claimTopic) external;

    /**
     *  @dev Remove a trusted claim topic (For example: KYC=1, AML=2).
     *  Only owner can call.
     *  emits `ClaimTopicRemoved` event
     *  @param _claimTopic The claim topic index
     */
    function removeClaimTopic(uint256 _claimTopic) external;

    /**
     *  @dev Get the trusted claim topics for the security token
     *  @return Array of trusted claim topics
     */
    function getClaimTopics() external view returns (uint256[] memory);

    /**
     *  @dev Transfers the Ownership of ClaimTopics to a new Owner.
     *  Only owner can call.
     *  @param _newOwner The new owner of this contract.
     */
    function transferOwnershipOnClaimTopicsRegistryContract(address _newOwner) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface ICompliance {
    /**
     *  this event is emitted when the Agent has been added on the allowedList of this Compliance.
     *  the event is emitted by the Compliance constructor and by the addTokenAgent function
     *  `_agentAddress` is the address of the Agent to add
     */
    event TokenAgentAdded(address _agentAddress);

    /**
     *  this event is emitted when the Agent has been removed from the agent list of this Compliance.
     *  the event is emitted by the Compliance constructor and by the removeTokenAgent function
     *  `_agentAddress` is the address of the Agent to remove
     */
    event TokenAgentRemoved(address _agentAddress);

    /**
     *  this event is emitted when a token has been bound to the compliance contract
     *  the event is emitted by the bindToken function
     *  `_token` is the address of the token to bind
     */
    event TokenBound(address _token);

    /**
     *  this event is emitted when a token has been unbound from the compliance contract
     *  the event is emitted by the unbindToken function
     *  `_token` is the address of the token to unbind
     */
    event TokenUnbound(address _token);

    /**
     *  @dev Returns true if the Address is in the list of token agents
     *  @param _agentAddress address of this agent
     */
    function isTokenAgent(address _agentAddress) external view returns (bool);

    /**
     *  @dev Returns true if the address given corresponds to a token that is bound with the Compliance contract
     *  @param _token address of the token
     */
    function isTokenBound(address _token) external view returns (bool);

    /**
     *  @dev adds an agent to the list of token agents
     *  @param _agentAddress address of the agent to be added
     *  Emits a TokenAgentAdded event
     */
    function addTokenAgent(address _agentAddress) external;

    /**
     *  @dev remove Agent from the list of token agents
     *  @param _agentAddress address of the agent to be removed (must be added first)
     *  Emits a TokenAgentRemoved event
     */
    function removeTokenAgent(address _agentAddress) external;

    /**
     *  @dev binds a token to the compliance contract
     *  @param _token address of the token to bind
     *  Emits a TokenBound event
     */
    function bindToken(address _token) external;

    /**
     *  @dev unbinds a token from the compliance contract
     *  @param _token address of the token to unbind
     *  Emits a TokenUnbound event
     */
    function unbindToken(address _token) external;

    /**
     *  @dev checks that the transfer is compliant.
     *  READ ONLY FUNCTION, this function cannot be used to increment
     *  counters, emit events, ...
     *  @param _from The address of the sender
     *  @param _to The address of the receiver
     *  @param _amount The amount of tokens involved in the transfer
     */
    function canTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (bool);
    
    /**
     * @dev checks that the mint transaction is compliant.
     * @param _from The address of the minter
     * @param _to The address of the receiver
     * @param _amount The amount of tokens to mint
     */
    function canMint(
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (bool);

    /**
     *  @dev function called whenever tokens are transferred
     *  from one wallet to another
     *  this function can update state variables in the compliance contract
     *  these state variables being used by `canTransfer` to decide if a transfer
     *  is compliant or not depending on the values stored in these state variables and on
     *  the parameters of the compliance smart contract
     *  @param _from The address of the sender
     *  @param _to The address of the receiver
     *  @param _amount The amount of tokens involved in the transfer
     */
    function transferred(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    /**
     *  @dev function called whenever tokens are created
     *  on a wallet
     *  this function can update state variables in the compliance contract
     *  these state variables being used by `canTransfer` to decide if a transfer
     *  is compliant or not depending on the values stored in these state variables and on
     *  the parameters of the compliance smart contract
     *  @param _to The address of the receiver
     *  @param _amount The amount of tokens involved in the transfer
     */
    function created(address _to, uint256 _amount) external;

    /**
     *  @dev function called whenever tokens are destroyed
     *  this function can update state variables in the compliance contract
     *  these state variables being used by `canTransfer` to decide if a transfer
     *  is compliant or not depending on the values stored in these state variables and on
     *  the parameters of the compliance smart contract
     *  @param _from The address of the receiver
     *  @param _amount The amount of tokens involved in the transfer
     */
    function destroyed(address _from, uint256 _amount) external;

    /**
     *  @dev function used to transfer the ownership of the compliance contract
     *  to a new owner, giving him access to the `OnlyOwner` functions implemented on the contract
     *  @param newOwner The address of the new owner of the compliance contract
     *  This function can only be called by the owner of the compliance contract
     *  emits an `OwnershipTransferred` event
     */
    function transferOwnershipOnComplianceContract(address newOwner) external;

    function authorizeCountry(uint16 _countryToWhitelist) external;

    function authorizeCountries(uint16[] calldata _countries) external ;

    function removeAuthorizedCountry(uint16 _countryToRemove) external ;

    function isAuthorizedCountry(uint16 _countryCode) external view returns(bool) ;

    function addAgentOnComplianceContract(address _agent) external;

    function removeAgentOnComplianceContract(address _agent) external ;
    function init(address _token, uint256 _holdReleaseTime, uint256 _tokenLimitPerUser) external;

    function addSubAdminOnCompliance(address _userAddress) external;

    function revokeSubAdminOnCompliance(address _SubOwner) external;

    function updateReleaseTimestamp(uint256 _timestamp) external ;

    function updateHolderLimit(uint256 _newHolderLimit) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice this interface is a modified version of EIP-2535: Diamonds 3 standard - https://eips.ethereum.org/EIPS/eip-2535 - original author : Nick Mudge
 */

interface ICutFacet {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _facetCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function cutFacet(
        FacetCut[] calldata _facetCut,
        address _init,
        bytes calldata _calldata
    ) external;

     event FacetCutEvent(FacetCut[] _facetCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @dev interface of the ERC734 (Key Holder) standard as defined in the EIP.
 */
interface IERC734 {

    /**
     * @dev Emitted when an execution request was approved.
     *
     * Specification: MUST be triggered when approve was successfully called.
     */
    event Approved(uint256 indexed executionId, bool approved);

    /**
     * @dev Emitted when an execute operation was approved and successfully performed.
     *
     * Specification: MUST be triggered when approve was called and the execution was successfully approved.
     */
    event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    /**
     * @dev Emitted when an execution request was performed via `execute`.
     *
     * Specification: MUST be triggered when execute was successfully called.
     */
    event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    event ExecutionFailed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    /**
     * @dev Emitted when a key was added to the Identity.
     *
     * Specification: MUST be triggered when addKey was successfully called.
     */
    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);

    /**
     * @dev Emitted when a key was removed from the Identity.
     *
     * Specification: MUST be triggered when removeKey was successfully called.
     */
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);

    /**
     * @dev Emitted when the list of required keys to perform an action was updated.
     *
     * Specification: MUST be triggered when changeKeysRequired was successfully called.
     */
    event KeysRequiredChanged(uint256 purpose, uint256 number);


    /**
     * @dev Adds a _key to the identity. The _purpose specifies the purpose of the key.
     *
     * Triggers Event: `KeyAdded`
     *
     * Specification: MUST only be done by keys of purpose 1, or the identity itself. If it's the identity itself, the approval process will determine its approval.
     */
    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) external returns (bool success);

    /**
    * @dev Approves an execution or claim addition.
    *
    * Triggers Event: `Approved`, `Executed`
    *
    * Specification:
    * This SHOULD require n of m approvals of keys purpose 1, if the _to of the execution is the identity contract itself, to successfully approve an execution.
    * And COULD require n of m approvals of keys purpose 2, if the _to of the execution is another contract, to successfully approve an execution.
    */
    function approve(uint256 _id, bool _approve) external returns (bool success);

    /**
     * @dev Passes an execution instruction to an ERC725 identity.
     *
     * Triggers Event: `ExecutionRequested`, `Executed`
     *
     * Specification:
     * SHOULD require approve to be called with one or more keys of purpose 1 or 2 to approve this execution.
     * Execute COULD be used as the only accessor for `addKey` and `removeKey`.
     */
    function execute(address _to, uint256 _value, bytes calldata _data) external payable returns (uint256 executionId);

    /**
     * @dev Returns the full key data, if present in the identity.
     */
    function getKey(bytes32 _key) external view returns (uint256[] memory purposes, uint256 keyType, bytes32 key);

    /**
     * @dev Returns the list of purposes associated with a key.
     */
    function getKeyPurposes(bytes32 _key) external view returns(uint256[] memory _purposes);

    /**
     * @dev Returns an array of public key bytes32 held by this identity.
     */
    function getKeysByPurpose(uint256 _purpose) external view returns (bytes32[] memory keys);

    /**
     * @dev Returns TRUE if a key is present and has the given purpose. If the key is not present it returns FALSE.
     */
    function keyHasPurpose(bytes32 _key, uint256 _purpose) external view returns (bool exists);

    /**
     * @dev Removes _purpose for _key from the identity.
     *
     * Triggers Event: `KeyRemoved`
     *
     * Specification: MUST only be done by keys of purpose 1, or the identity itself. If it's the identity itself, the approval process will determine its approval.
     */
    function removeKey(bytes32 _key, uint256 _purpose) external returns (bool success);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @dev interface of the ERC735 (Claim Holder) standard as defined in the EIP.
 */
interface IERC735 {

    /**
     * @dev Emitted when a claim request was performed.
     *
     * Specification: Is not clear
     */
    event ClaimRequested(uint256 indexed claimRequestId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Emitted when a claim was added.
     *
     * Specification: MUST be triggered when a claim was successfully added.
     */
    event ClaimAdded(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Emitted when a claim was removed.
     *
     * Specification: MUST be triggered when removeClaim was successfully called.
     */
    event ClaimRemoved(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Emitted when a claim was changed.
     *
     * Specification: MUST be triggered when changeClaim was successfully called.
     */
    event ClaimChanged(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Get a claim by its ID.
     *
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address, uint256 topic))`.
     */
    function getClaim(bytes32 _claimId) external view returns(uint256 topic, uint256 scheme, address issuer, bytes memory signature, bytes memory data, string memory uri);

    /**
     * @dev Returns an array of claim IDs by topic.
     */
    function getClaimIdsByTopic(uint256 _topic) external view returns(bytes32[] memory claimIds);

    /**
     * @dev Add or update a claim.
     *
     * Triggers Event: `ClaimRequested`, `ClaimAdded`, `ClaimChanged`
     *
     * Specification: Requests the ADDITION or the CHANGE of a claim from an issuer.
     * Claims can requested to be added by anybody, including the claim holder itself (self issued).
     *
     * _signature is a signed message of the following structure: `keccak256(abi.encode(address identityHolder_address, uint256 topic, bytes data))`.
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address + uint256 topic))`.
     *
     * This COULD implement an approval process for pending claims, or add them right away.
     * MUST return a claimRequestId (use claim ID) that COULD be sent to the approve function.
     */
    function addClaim(uint256 _topic, uint256 _scheme, address issuer, bytes calldata _signature, bytes calldata _data, string calldata _uri) external returns (bytes32 claimRequestId);

    /**
     * @dev Removes a claim.
     *
     * Triggers Event: `ClaimRemoved`
     *
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address, uint256 topic))`.
     */
    function removeClaim(bytes32 _claimId) external returns (bool success);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC734.sol";
import "./IERC735.sol";

interface IIdentity is IERC734, IERC735 {}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import './ITrustedIssuersRegistry.sol';
import './IClaimTopicsRegistry.sol';
import './IIdentityRegistryStorage.sol';

interface IIdentityRegistry {
    /**
     *  this event is emitted when the ClaimTopicsRegistry has been set for the IdentityRegistry
     *  the event is emitted by the IdentityRegistry constructor
     *  `claimTopicsRegistry` is the address of the Claim Topics Registry contract
     */
    event ClaimTopicsRegistrySet(address indexed claimTopicsRegistry);

    /**
     *  this event is emitted when the IdentityRegistryStorage has been set for the IdentityRegistry
     *  the event is emitted by the IdentityRegistry constructor
     *  `identityStorage` is the address of the Identity Registry Storage contract
     */
    event IdentityStorageSet(address indexed identityStorage);

    /**
     *  this event is emitted when the ClaimTopicsRegistry has been set for the IdentityRegistry
     *  the event is emitted by the IdentityRegistry constructor
     *  `trustedIssuersRegistry` is the address of the Trusted Issuers Registry contract
     */
    event TrustedIssuersRegistrySet(address indexed trustedIssuersRegistry);

    /**
     *  this event is emitted when an Identity is registered into the Identity Registry.
     *  the event is emitted by the 'registerIdentity' function
     *  `investorAddress` is the address of the investor's wallet
     *  `identity` is the address of the Identity smart contract (onchainID)
     */
    event IdentityRegistered(address indexed investorAddress, IIdentity indexed identity);

    /**
     *  this event is emitted when an Identity is removed from the Identity Registry.
     *  the event is emitted by the 'deleteIdentity' function
     *  `investorAddress` is the address of the investor's wallet
     *  `identity` is the address of the Identity smart contract (onchainID)
     */
    event IdentityRemoved(address indexed investorAddress, IIdentity indexed identity);

    /**
     *  this event is emitted when an Identity has been updated
     *  the event is emitted by the 'updateIdentity' function
     *  `oldIdentity` is the old Identity contract's address to update
     *  `newIdentity` is the new Identity contract's
     */
    event IdentityUpdated(IIdentity indexed oldIdentity, IIdentity indexed newIdentity);

    /**
     *  this event is emitted when an Identity's country has been updated
     *  the event is emitted by the 'updateCountry' function
     *  `investorAddress` is the address on which the country has been updated
     *  `country` is the numeric code (ISO 3166-1) of the new country
     */
    event CountryUpdated(address indexed investorAddress, uint16 indexed country);

    /**
     *  @dev Register an identity contract corresponding to a user address.
     *  Requires that the user doesn't have an identity contract already registered.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  @param _userAddress The address of the user
     *  @param _identity The address of the user's identity contract
     *  @param _country The country of the investor
     *  emits `IdentityRegistered` event
     */
    function registerIdentity(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) external;

    /**
     *  @dev Removes an user from the identity registry.
     *  Requires that the user have an identity contract already deployed that will be deleted.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  @param _userAddress The address of the user to be removed
     *  emits `IdentityRemoved` event
     */
    function deleteIdentity(address _userAddress) external;

    /**
     *  @dev Replace the actual identityRegistryStorage contract with a new one.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _identityRegistryStorage The address of the new Identity Registry Storage
     *  emits `IdentityStorageSet` event
     */
    function setIdentityRegistryStorage(address _identityRegistryStorage) external;

    /**
     *  @dev Replace the actual claimTopicsRegistry contract with a new one.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _claimTopicsRegistry The address of the new claim Topics Registry
     *  emits `ClaimTopicsRegistrySet` event
     */
    function setClaimTopicsRegistry(address _claimTopicsRegistry) external;

    /**
     *  @dev Replace the actual trustedIssuersRegistry contract with a new one.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _trustedIssuersRegistry The address of the new Trusted Issuers Registry
     *  emits `TrustedIssuersRegistrySet` event
     */
    function setTrustedIssuersRegistry(address _trustedIssuersRegistry) external;

    /**
     *  @dev Updates the country corresponding to a user address.
     *  Requires that the user should have an identity contract already deployed that will be replaced.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  @param _userAddress The address of the user
     *  @param _country The new country of the user
     *  emits `CountryUpdated` event
     */
    function updateCountry(address _userAddress, uint16 _country) external;

    /**
     *  @dev Updates an identity contract corresponding to a user address.
     *  Requires that the user address should be the owner of the identity contract.
     *  Requires that the user should have an identity contract already deployed that will be replaced.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  @param _userAddress The address of the user
     *  @param _identity The address of the user's new identity contract
     *  emits `IdentityUpdated` event
     */
    function updateIdentity(address _userAddress, IIdentity _identity) external;

    /**
     *  @dev function allowing to register identities in batch
     *  This function can only be called by a wallet set as agent of the smart contract
     *  Requires that none of the users has an identity contract already registered.
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_userAddresses.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param _userAddresses The addresses of the users
     *  @param _identities The addresses of the corresponding identity contracts
     *  @param _countries The countries of the corresponding investors
     *  emits _userAddresses.length `IdentityRegistered` events
     */
    function batchRegisterIdentity(
        address[] calldata _userAddresses,
        IIdentity[] calldata _identities,
        uint16[] calldata _countries
    ) external;

    /**
     *  @dev This functions checks whether a wallet has its Identity registered or not
     *  in the Identity Registry.
     *  @param _userAddress The address of the user to be checked.
     *  @return 'True' if the address is contained in the Identity Registry, 'false' if not.
     */
    function contains(address _userAddress) external view returns (bool);

    /**
     *  @dev This functions checks whether an identity contract
     *  corresponding to the provided user address has the required claims or not based
     *  on the data fetched from trusted issuers registry and from the claim topics registry
     *  @param _userAddress The address of the user to be verified.
     *  @return 'True' if the address is verified, 'false' if not.
     */
    function isVerified(address _userAddress) external view returns (bool);

    /**
     *  @dev Returns the onchainID of an investor.
     *  @param _userAddress The wallet of the investor
     */
    function identity(address _userAddress) external view returns (IIdentity);

    /**
     *  @dev Returns the country code of an investor.
     *  @param _userAddress The wallet of the investor
     */
    function investorCountry(address _userAddress) external view returns (uint16);

    /**
     *  @dev Returns the IdentityRegistryStorage linked to the current IdentityRegistry.
     */
    function identityStorage() external view returns (IIdentityRegistryStorage);

    /**
     *  @dev Returns the TrustedIssuersRegistry linked to the current IdentityRegistry.
     */
    function issuersRegistry() external view returns (ITrustedIssuersRegistry);

    /**
     *  @dev Returns the ClaimTopicsRegistry linked to the current IdentityRegistry.
     */
    function topicsRegistry() external view returns (IClaimTopicsRegistry);

    /**
     *  @notice Transfers the Ownership of the Identity Registry to a new Owner.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _newOwner The new owner of this contract.
     */
    function transferOwnershipOnIdentityRegistryContract(address _newOwner) external;

    /**
     *  @notice Adds an address as _agent of the Identity Registry Contract.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _agent The _agent's address to add.
     */
    function addAgentOnIdentityRegistryContract(address _agent) external;

    /**
     *  @notice Removes an address from being _agent of the Identity Registry Contract.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _agent The _agent's address to remove.
     */
    function removeAgentOnIdentityRegistryContract(address _agent) external;

function addSubAdminOnIR(address _userAddress) external;
    // function revokeSubOwner(address _SubOwner) external ;

    // function isSubOwner (address _userAddress) external view returns (bool);
function isAgentOnIdentityRegistry(address _agent) external view returns (bool value);

function revokeSubAdminOnIR(address _SubAdmin) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import './IIdentity.sol';

interface IIdentityRegistryStorage {
    /**
     *  this event is emitted when an Identity is registered into the storage contract.
     *  the event is emitted by the 'registerIdentity' function
     *  `investorAddress` is the address of the investor's wallet
     *  `identity` is the address of the Identity smart contract (onchainID)
     */
    event IdentityStored(address indexed investorAddress, IIdentity indexed identity);

    /**
     *  this event is emitted when an Identity is removed from the storage contract.
     *  the event is emitted by the 'deleteIdentity' function
     *  `investorAddress` is the address of the investor's wallet
     *  `identity` is the address of the Identity smart contract (onchainID)
     */
    event IdentityUnstored(address indexed investorAddress, IIdentity indexed identity);

    /**
     *  this event is emitted when an Identity has been updated
     *  the event is emitted by the 'updateIdentity' function
     *  `oldIdentity` is the old Identity contract's address to update
     *  `newIdentity` is the new Identity contract's
     */
    event IdentityModified(IIdentity indexed oldIdentity, IIdentity indexed newIdentity);

    /**
     *  this event is emitted when an Identity's country has been updated
     *  the event is emitted by the 'updateCountry' function
     *  `investorAddress` is the address on which the country has been updated
     *  `country` is the numeric code (ISO 3166-1) of the new country
     */
    event CountryModified(address indexed investorAddress, uint16 indexed country);

    /**
     *  this event is emitted when an Identity Registry is bound to the storage contract
     *  the event is emitted by the 'addIdentityRegistry' function
     *  `identityRegistry` is the address of the identity registry added
     */
    event IdentityRegistryBound(address indexed identityRegistry);

    /**
     *  this event is emitted when an Identity Registry is unbound from the storage contract
     *  the event is emitted by the 'removeIdentityRegistry' function
     *  `identityRegistry` is the address of the identity registry removed
     */
    event IdentityRegistryUnbound(address indexed identityRegistry);

    /**
     *  @dev Returns the identity registries linked to the storage contract
     */
    function linkedIdentityRegistries() external view returns (address[] memory);

    /**
     *  @dev Returns the onchainID of an investor.
     *  @param _userAddress The wallet of the investor
     */
    function storedIdentity(address _userAddress) external view returns (IIdentity);

    /**
     *  @dev Returns the country code of an investor.
     *  @param _userAddress The wallet of the investor
     */
    function storedInvestorCountry(address _userAddress) external view returns (uint16);

    /**
     *  @dev adds an identity contract corresponding to a user address in the storage.
     *  Requires that the user doesn't have an identity contract already registered.
     *  This function can only be called by an address set as agent of the smart contract
     *  @param _userAddress The address of the user
     *  @param _identity The address of the user's identity contract
     *  @param _country The country of the investor
     *  emits `IdentityStored` event
     */
    function addIdentityToStorage(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) external;

    /**
     *  @dev Removes an user from the storage.
     *  Requires that the user have an identity contract already deployed that will be deleted.
     *  This function can only be called by an address set as agent of the smart contract
     *  @param _userAddress The address of the user to be removed
     *  emits `IdentityUnstored` event
     */
    function removeIdentityFromStorage(address _userAddress) external;

    /**
     *  @dev Updates the country corresponding to a user address.
     *  Requires that the user should have an identity contract already deployed that will be replaced.
     *  This function can only be called by an address set as agent of the smart contract
     *  @param _userAddress The address of the user
     *  @param _country The new country of the user
     *  emits `CountryModified` event
     */
    function modifyStoredInvestorCountry(address _userAddress, uint16 _country) external;

    /**
     *  @dev Updates an identity contract corresponding to a user address.
     *  Requires that the user address should be the owner of the identity contract.
     *  Requires that the user should have an identity contract already deployed that will be replaced.
     *  This function can only be called by an address set as agent of the smart contract
     *  @param _userAddress The address of the user
     *  @param _identity The address of the user's new identity contract
     *  emits `IdentityModified` event
     */
    function modifyStoredIdentity(address _userAddress, IIdentity _identity) external;

    /**
     *  @notice Transfers the Ownership of the Identity Registry Storage to a new Owner.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _newOwner The new owner of this contract.
     */
    function transferOwnershipOnIdentityRegistryStorage(address _newOwner) external;

    /**
     *  @notice Adds an identity registry as agent of the Identity Registry Storage Contract.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  This function adds the identity registry to the list of identityRegistries linked to the storage contract
     *  @param _identityRegistry The identity registry address to add.
     */
    function bindIdentityRegistry(address _identityRegistry) external;

    /**
     *  @notice Removes an identity registry from being agent of the Identity Registry Storage Contract.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  This function removes the identity registry from the list of identityRegistries linked to the storage contract
     *  @param _identityRegistry The identity registry address to remove.
     */
    function unbindIdentityRegistry(address _identityRegistry) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IImplementationAuthorityVersion {
    function getImplementation() external view returns(address);
    function getImplementationVersion() external view returns(bytes32);
    function updateImplementation(address _newImplementation) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import './IIdentityRegistry.sol';
import './ICompliance.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @dev interface
interface IToken is IERC20 {
    /**
     *  this event is emitted when the token information is updated.
     *  the event is emitted by the token constructor and by the setTokenInformation function
     *  `_newName` is the name of the token
     *  `_newSymbol` is the symbol of the token
     *  `_newDecimals` is the decimals of the token
     *  `_newVersion` is the version of the token, current version is 3.0
     *  `_newOnchainID` is the address of the onchainID of the token
     */
    event UpdatedTokenInformation(string _newName, string _newSymbol, uint8 _newDecimals, address _newOnchainID, uint _maxSupply);

    /**
     *  this event is emitted when the IdentityRegistry has been set for the token
     *  the event is emitted by the token constructor and by the setIdentityRegistry function
     *  `_identityRegistry` is the address of the Identity Registry of the token
     */
    event IdentityRegistryAdded(address indexed _identityRegistry);

    /**
     *  this event is emitted when the Compliance has been set for the token
     *  the event is emitted by the token constructor and by the setCompliance function
     *  `_compliance` is the address of the Compliance contract of the token
     */
    event ComplianceAdded(address indexed _compliance);

    /**
     *  this event is emitted when an investor successfully recovers his tokens
     *  the event is emitted by the recoveryAddress function
     *  `_lostWallet` is the address of the wallet that the investor lost access to
     *  `_newWallet` is the address of the wallet that the investor provided for the recovery
     *  `_investorOnchainID` is the address of the onchainID of the investor who asked for a recovery
     */
    event RecoverySuccess(address _lostWallet, address _newWallet, address _investorOnchainID);

    /**
     *  this event is emitted when the wallet of an investor is frozen or unfrozen
     *  the event is emitted by setAddressFrozen and batchSetAddressFrozen functions
     *  `_userAddress` is the wallet of the investor that is concerned by the freezing status
     *  `_isFrozen` is the freezing status of the wallet
     *  if `_isFrozen` equals `true` the wallet is frozen after emission of the event
     *  if `_isFrozen` equals `false` the wallet is unfrozen after emission of the event
     *  `_owner` is the address of the agent who called the function to freeze the wallet
     */
    event AddressFrozen(address indexed _userAddress, bool indexed _isFrozen, address indexed _owner);

    /**
     *  this event is emitted when a certain amount of tokens is frozen on a wallet
     *  the event is emitted by freezePartialTokens and batchFreezePartialTokens functions
     *  `_userAddress` is the wallet of the investor that is concerned by the freezing status
     *  `_amount` is the amount of tokens that are frozen
     */
    event TokensFrozen(address indexed _userAddress, uint256 _amount);

    /**
     *  this event is emitted when a certain amount of tokens is unfrozen on a wallet
     *  the event is emitted by unfreezePartialTokens and batchUnfreezePartialTokens functions
     *  `_userAddress` is the wallet of the investor that is concerned by the freezing status
     *  `_amount` is the amount of tokens that are unfrozen
     */
    event TokensUnfrozen(address indexed _userAddress, uint256 _amount);

    /**
     *  this event is emitted when the token is paused
     *  the event is emitted by the pause function
     *  `_userAddress` is the address of the wallet that called the pause function
     */
    event Paused(address _userAddress);

    /**
     *  this event is emitted when the token is unpaused
     *  the event is emitted by the unpause function
     *  `_userAddress` is the address of the wallet that called the unpause function
     */
    event Unpaused(address _userAddress);
    
    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 1 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * balanceOf() and transfer().
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the address of the onchainID of the token.
     * the onchainID of the token gives all the information available
     * about the token and is managed by the token issuer or his agent.
     */
    function getTokenIdentity() external view returns (address);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the integer valur of the circulation Supply of Tokens.
     */
    function circulationSupply() external view returns(uint256);

    /**
     *  @dev Returns the Identity Registry linked to the token
     */
    function identityRegistry() external view returns (IIdentityRegistry);

    /**
     *  @dev Returns the Compliance contract linked to the token
     */
    function compliance() external view returns (ICompliance);

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view returns (bool);

    /**
     *  @dev Returns the freezing status of a wallet
     *  if isFrozen returns `true` the wallet is frozen
     *  if isFrozen returns `false` the wallet is not frozen
     *  isFrozen returning `true` doesn't mean that the balance is free, tokens could be blocked by
     *  a partial freeze or the whole token could be blocked by pause
     *  @param _userAddress the address of the wallet on which isFrozen is called
     */
    function isFrozen(address _userAddress) external view returns (bool);

    /**
     *  @dev Returns the amount of tokens that are partially frozen on a wallet
     *  the amount of frozen tokens is always <= to the total balance of the wallet
     *  @param _userAddress the address of the wallet on which getFrozenTokens is called
     */
    function getFrozenTokens(address _userAddress) external view returns (uint256);

    /**
     *  @dev sets the token name
     *  @param _name the name of token to set
     *  Only the owner of the token smart contract can call this function
     *  emits a `UpdatedTokenInformation` event
     */
    function setName(string calldata _name) external;

    /**
     *  @dev sets the token symbol
     *  @param _symbol the token symbol to set
     *  Only the owner of the token smart contract can call this function
     *  emits a `UpdatedTokenInformation` event
     */
    function setSymbol(string calldata _symbol) external;

    /**
     *  @dev sets the identity of the token
     *  @param _tokenIdentity the address of the onchain ID to set
     *  Only the owner of the token smart contract can call this function
     *  emits a `UpdatedTokenInformation` event
     */
    function setTokenIdentity(address _tokenIdentity) external;

    /**
     *  @dev sets the MaxSupply of the token
     *  @param _maxCap the usigned integer
     *  Only the owner of the token smart contract can call this function
     *  emits a `MaxSupply` event
     */
    function setMaxSupply(uint256 _maxCap) external;

    /**
     *  @dev pauses the token contract, when contract is paused investors cannot transfer tokens anymore
     *  This function can only be called by a wallet set as agent of the token
     *  emits a `Paused` event
     */
    function pause() external;

    /**
     *  @dev unpauses the token contract, when contract is unpaused investors can transfer tokens
     *  if their wallet is not blocked & if the amount to transfer is <= to the amount of free tokens
     *  This function can only be called by a wallet set as agent of the token
     *  emits an `Unpaused` event
     */
    function unpause() external;

    /**
     *  @dev sets an address frozen status for this token.
     *  @param _userAddress The address for which to update frozen status
     *  @param _freeze Frozen status of the address
     *  This function can only be called by a wallet set as agent of the token
     *  emits an `AddressFrozen` event
     */
    function setAddressFrozen(address _userAddress, bool _freeze) external;

    /**
     *  @dev freezes token amount specified for given address.
     *  @param _userAddress The address for which to update frozen tokens
     *  @param _amount Amount of Tokens to be frozen
     *  This function can only be called by a wallet set as agent of the token
     *  emits a `TokensFrozen` event
     */
    function freezePartialTokens(address _userAddress, uint256 _amount) external;

    /**
     *  @dev unfreezes token amount specified for given address
     *  @param _userAddress The address for which to update frozen tokens
     *  @param _amount Amount of Tokens to be unfrozen
     *  This function can only be called by a wallet set as agent of the token
     *  emits a `TokensUnfrozen` event
     */
    function unfreezePartialTokens(address _userAddress, uint256 _amount) external;

    /**
     *  @dev sets the Identity Registry for the token
     *  @param _identityRegistry the address of the Identity Registry to set
     *  Only the owner of the token smart contract can call this function
     *  emits an `IdentityRegistryAdded` event
     */
    function setIdentityRegistry(address _identityRegistry) external;

    /**
     *  @dev sets the compliance contract of the token
     *  @param _compliance the address of the compliance contract to set
     *  Only the owner of the token smart contract can call this function
     *  emits a `ComplianceAdded` event
     */
    function setCompliance(address _compliance) external;

    /**
     *  @dev force a transfer of tokens between 2 whitelisted wallets
     *  In case the `from` address has not enough free tokens (unfrozen tokens)
     *  but has a total balance higher or equal to the `amount`
     *  the amount of frozen tokens is reduced in order to have enough free tokens
     *  to proceed the transfer, in such a case, the remaining balance on the `from`
     *  account is 100% composed of frozen tokens post-transfer.
     *  Require that the `to` address is a verified address,
     *  @param _from The address of the sender
     *  @param _to The address of the receiver
     *  @param _amount The number of tokens to transfer
     *  @return `true` if successful and revert if unsuccessful
     *  This function can only be called by a wallet set as agent of the token
     *  emits a `TokensUnfrozen` event if `_amount` is higher than the free balance of `_from`
     *  emits a `Transfer` event
     */
    function forcedTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    /**
     *  @dev mint tokens on a wallet
     *  Improved version of default mint method. Tokens can be minted
     *  to an address if only it is a verified address as per the security token.
     *  @param _to Address to mint the tokens to.
     *  @param _amount Amount of tokens to mint.
     *  This function can only be called by a wallet set as agent of the token
     *  emits a `Transfer` event
     */
    function mint(address _to, uint256 _amount) external;

    /**
     *  @dev burn tokens on a wallet
     *  In case the `account` address has not enough free tokens (unfrozen tokens)
     *  but has a total balance higher or equal to the `value` amount
     *  the amount of frozen tokens is reduced in order to have enough free tokens
     *  to proceed the burn, in such a case, the remaining balance on the `account`
     *  is 100% composed of frozen tokens post-transaction.
     *  @param _userAddress Address to burn the tokens from.
     *  @param _amount Amount of tokens to burn.
     *  This function can only be called by a wallet set as agent of the token
     *  emits a `TokensUnfrozen` event if `_amount` is higher than the free balance of `_userAddress`
     *  emits a `Transfer` event
     */
    function burn(address _userAddress, uint256 _amount) external;

    /**
     *  @dev recovery function used to force transfer tokens from a
     *  lost wallet to a new wallet for an investor.
     *  @param _lostWallet the wallet that the investor lost
     *  @param _newWallet the newly provided wallet on which tokens have to be transferred
     *  @param _investorOnchainID the onchainID of the investor asking for a recovery
     *  This function can only be called by a wallet set as agent of the token
     *  emits a `TokensUnfrozen` event if there is some frozen tokens on the lost wallet if the recovery process is successful
     *  emits a `Transfer` event if the recovery process is successful
     *  emits a `RecoverySuccess` event if the recovery process is successful
     *  emits a `RecoveryFails` event if the recovery process fails
     */
    function recoveryAddress(
        address _lostWallet,
        address _newWallet,
        address _investorOnchainID
    ) external returns (bool);

    /**
     *  @dev function allowing to issue transfers in batch
     *  Require that the msg.sender and `to` addresses are not frozen.
     *  Require that the total value should not exceed available balance.
     *  Require that the `to` addresses are all verified addresses,
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_toList.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param _toList The addresses of the receivers
     *  @param _amounts The number of tokens to transfer to the corresponding receiver
     *  emits _toList.length `Transfer` events
     */
    function batchTransfer(address[] calldata _toList, uint256[] calldata _amounts) external;

    /**
     *  @dev function allowing to issue forced transfers in batch
     *  Require that `_amounts[i]` should not exceed available balance of `_fromList[i]`.
     *  Require that the `_toList` addresses are all verified addresses
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_fromList.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param _fromList The addresses of the senders
     *  @param _toList The addresses of the receivers
     *  @param _amounts The number of tokens to transfer to the corresponding receiver
     *  This function can only be called by a wallet set as agent of the token
     *  emits `TokensUnfrozen` events if `_amounts[i]` is higher than the free balance of `_fromList[i]`
     *  emits _fromList.length `Transfer` events
     */
    function batchForcedTransfer(
        address[] calldata _fromList,
        address[] calldata _toList,
        uint256[] calldata _amounts
    ) external;

    /**
     *  @dev function allowing to mint tokens in batch
     *  Require that the `_toList` addresses are all verified addresses
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_toList.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param _toList The addresses of the receivers
     *  @param _amounts The number of tokens to mint to the corresponding receiver
     *  This function can only be called by a wallet set as agent of the token
     *  emits _toList.length `Transfer` events
     */
    function batchMint(address[] calldata _toList, uint256[] calldata _amounts) external;

    /**
     *  @dev function allowing to burn tokens in batch
     *  Require that the `_userAddresses` addresses are all verified addresses
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_userAddresses.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param _userAddresses The addresses of the wallets concerned by the burn
     *  @param _amounts The number of tokens to burn from the corresponding wallets
     *  This function can only be called by a wallet set as agent of the token
     *  emits _userAddresses.length `Transfer` events
     */
    function batchBurn(address[] calldata _userAddresses, uint256[] calldata _amounts) external;

    /**
     *  @dev function allowing to set frozen addresses in batch
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_userAddresses.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param _userAddresses The addresses for which to update frozen status
     *  @param _freeze Frozen status of the corresponding address
     *  This function can only be called by a wallet set as agent of the token
     *  emits _userAddresses.length `AddressFrozen` events
     */
    function batchSetAddressFrozen(address[] calldata _userAddresses, bool[] calldata _freeze) external;

    /**
     *  @dev function allowing to freeze tokens partially in batch
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_userAddresses.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param _userAddresses The addresses on which tokens need to be frozen
     *  @param _amounts the amount of tokens to freeze on the corresponding address
     *  This function can only be called by a wallet set as agent of the token
     *  emits _userAddresses.length `TokensFrozen` events
     */
    function batchFreezePartialTokens(address[] calldata _userAddresses, uint256[] calldata _amounts) external;

    /**
     *  @dev function allowing to unfreeze tokens partially in batch
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_userAddresses.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param _userAddresses The addresses on which tokens need to be unfrozen
     *  @param _amounts the amount of tokens to unfreeze on the corresponding address
     *  This function can only be called by a wallet set as agent of the token
     *  emits _userAddresses.length `TokensUnfrozen` events
     */
    function batchUnfreezePartialTokens(address[] calldata _userAddresses, uint256[] calldata _amounts) external;

    /**
     *  @dev transfers the ownership of the token smart contract
     *  @param _newOwner the address of the new token smart contract owner
     *  This function can only be called by the owner of the token
     *  emits an `OwnershipTransferred` event
     */
    function transferOwnershipOnTokenContract(address _newOwner) external;


    // function addIssuerOnTokenContract(address _agent) external;

    // function removeIssuerOnTokenContract(address _agent) external;

    function addAdmin(address _agent) external;

    function setRolesToTokenAgent(address _userAddress, bytes32[] memory roles) external;

    function revokeRolesOnTokenAgent(address _userAddress, bytes32[] memory roles) external;

    function revokeAdmin(address _agent) external;

    function addTokenizationAgentOnToken(address _userAddress) external;

    function removeTokenizationAgentOnToken(address _userAddress) external;

    function addTransferAgentOnToken(address _userAddress) external;

    function removeTransferAgentOnToken(address _userAddress) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface ITokenDeployer {

    event TokenCreated(address _tokenProxy, address _tokenImplAuth, address identityRegistry, string mappingValue, uint timestamp);
    event IdentityRegistered(address _userAddress);
    event IdentityCreated(address _userAddress, address _identityContract);
    event TemplateCreated(bytes32 indexed _templateKey, address indexed _operator);
    event TemplateSet(bytes32 indexed _template, address indexed _operator);
    event ImplementationStored(bytes32 _type, address indexed _implAuth, address indexed _operator);

    function bindAndSetImplementationTemplate(bytes32 _templateKey, bytes32[] calldata _keys, bytes32[] calldata _versions, address[] calldata _impls) external;
    function getImplementationsGivenTemplateKey(bytes32 _templateKey) external returns (address[] memory);
    function createToken(string memory _mappingValue, bytes calldata _initData) external;
    function deployAdminIdentity(uint256 executionBuffer, uint256 reqSig, address tokenizationAgent, address issuer, address token) external returns(address);
    function addAgents(address _transferAgent, address _tokenizationAgent, address _token) external;
    function deployAndWhitelist(address _token, address _userAddress, uint16 _countryCode) external;
    function batchDeployAndWhitelist(address _token, address[] calldata _userAddress, uint16[] calldata _countryCodes) external;
    function getIdentityOf(address _userAddress) external view returns(address);
    function setRolesOnToken(address _userAddress, bytes32[] memory _roles, address _token) external;
    function revokeRolesOnToken(address _userAddress, bytes32[] memory _roles, address _token) external;
    function addSubAdminOnToken(address _userAddress, address _token) external;
    function revokeSubAdminOnToken(address _userAddress, address _token) external;
    function addTokenizationAgentOnToken(address _agent, address _token) external;
    function revokeTokenizationAgentOnToken(address _agent, address _token) external;
    function addTransferAgentOnToken(address _agent, address _token) external;
    function removeTransferAgentOnToken(address _agent, address _token) external;
    function updateReleaseTimestampForToken(address _token, uint256 _timestamp) external;
    function updateHolderLimitForToken(address _token, uint256 _newHolderLimit) external;
    function addSubAdminOnIdentityRegistry(address _userAddress, address _identityRegistry) external;
    function revokeSubAdminOnIdentityRegistry(address _subAdminAddress, address _identityRegistry) external;
    function addSubAdminOnCompliance(address _userAddress, address _compliance) external;
    function revokeSubAdminOnCompliance(address _subAdmin, address _compliance) external;
    function addAdminIdentitySigner(address _signer, address _token) external;
    function removeMultisigSigner(address _signer, address _token) external;
    function setSigRequirementOnMultisig(uint256 _sigReq, address _token) external;
    function getAdminIdentityMinter(address _token) external view returns (address);
    function getTrustedIssuersRegistry(address _token) external view returns (address);
    function getClaimTopicsRegistry(address _token) external view returns (address);
    function getIdentityRegistry(address _token) external view returns (address);
    function getComplianceContract(address _token) external view returns (address);
    function adminCallUnrestricted(address _to, uint256 _value, bytes calldata _data) external returns (bool);
    function adminCallsUnrestricted(address[] calldata _to, uint256[] calldata _value, bytes[] calldata _data) external;

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import './IClaimIssuer.sol';

interface ITrustedIssuersRegistry {
    /**
     *  this event is emitted when a trusted issuer is added in the registry.
     *  the event is emitted by the addTrustedIssuer function
     *  `trustedIssuer` is the address of the trusted issuer's ClaimIssuer contract
     *  `claimTopics` is the set of claims that the trusted issuer is allowed to emit
     */
    event TrustedIssuerAdded(IClaimIssuer indexed trustedIssuer, uint256[] claimTopics);

    /**
     *  this event is emitted when a trusted issuer is removed from the registry.
     *  the event is emitted by the removeTrustedIssuer function
     *  `trustedIssuer` is the address of the trusted issuer's ClaimIssuer contract
     */
    event TrustedIssuerRemoved(IClaimIssuer indexed trustedIssuer);

    /**
     *  this event is emitted when the set of claim topics is changed for a given trusted issuer.
     *  the event is emitted by the updateIssuerClaimTopics function
     *  `trustedIssuer` is the address of the trusted issuer's ClaimIssuer contract
     *  `claimTopics` is the set of claims that the trusted issuer is allowed to emit
     */
    event ClaimTopicsUpdated(IClaimIssuer indexed trustedIssuer, uint256[] claimTopics);

    /**
     *  @dev registers a ClaimIssuer contract as trusted claim issuer.
     *  Requires that a ClaimIssuer contract doesn't already exist
     *  Requires that the claimTopics set is not empty
     *  @param _trustedIssuer The ClaimIssuer contract address of the trusted claim issuer.
     *  @param _claimTopics the set of claim topics that the trusted issuer is allowed to emit
     *  This function can only be called by the owner of the Trusted Issuers Registry contract
     *  emits a `TrustedIssuerAdded` event
     */
    function addTrustedIssuer(IClaimIssuer _trustedIssuer, uint256[] calldata _claimTopics) external;

    /**
     *  @dev Removes the ClaimIssuer contract of a trusted claim issuer.
     *  Requires that the claim issuer contract to be registered first
     *  @param _trustedIssuer the claim issuer to remove.
     *  This function can only be called by the owner of the Trusted Issuers Registry contract
     *  emits a `TrustedIssuerRemoved` event
     */
    function removeTrustedIssuer(IClaimIssuer _trustedIssuer) external;

    /**
     *  @dev Updates the set of claim topics that a trusted issuer is allowed to emit.
     *  Requires that this ClaimIssuer contract already exists in the registry
     *  Requires that the provided claimTopics set is not empty
     *  @param _trustedIssuer the claim issuer to update.
     *  @param _claimTopics the set of claim topics that the trusted issuer is allowed to emit
     *  This function can only be called by the owner of the Trusted Issuers Registry contract
     *  emits a `ClaimTopicsUpdated` event
     */
    function updateIssuerClaimTopics(IClaimIssuer _trustedIssuer, uint256[] calldata _claimTopics) external;

    /**
     *  @dev Function for getting all the trusted claim issuers stored.
     *  @return array of all claim issuers registered.
     */
    function getTrustedIssuers() external view returns (IClaimIssuer[] memory);

    /**
     *  @dev Checks if the ClaimIssuer contract is trusted
     *  @param _issuer the address of the ClaimIssuer contract
     *  @return true if the issuer is trusted, false otherwise.
     */
    function isTrustedIssuer(address _issuer) external view returns (bool);

    /**
     *  @dev Function for getting all the claim topic of trusted claim issuer
     *  Requires the provided ClaimIssuer contract to be registered in the trusted issuers registry.
     *  @param _trustedIssuer the trusted issuer concerned.
     *  @return The set of claim topics that the trusted issuer is allowed to emit
     */
    function getTrustedIssuerClaimTopics(IClaimIssuer _trustedIssuer) external view returns (uint256[] memory);

    /**
     *  @dev Function for checking if the trusted claim issuer is allowed
     *  to emit a certain claim topic
     *  @param _issuer the address of the trusted issuer's ClaimIssuer contract
     *  @param _claimTopic the Claim Topic that has to be checked to know if the `issuer` is allowed to emit it
     *  @return true if the issuer is trusted for this claim topic.
     */
    function hasClaimTopic(address _issuer, uint256 _claimTopic) external view returns (bool);

    /**
     *  @dev Transfers the Ownership of TrustedIssuersRegistry to a new Owner.
     *  @param _newOwner The new owner of this contract.
     *  This function can only be called by the owner of the Trusted Issuers Registry contract
     *  emits an `OwnershipTransferred` event
     */
    function transferOwnershipOnIssuersRegistryContract(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/core/ImplementationAuthorityVersion.sol";

library LibImplHub {
    
    bytes32 constant IMPL_HUB_STORAGE_POSITION = keccak256("multifacet.implementation.hub.storage");

    struct Template{
        bytes32[] implKeys;
        bytes32[] implVers;
        bytes[] data;
    }

    struct ImplHubStorage {
        mapping(bytes32 => Template) _keyToTemplate;
        mapping(bytes32 => mapping(bytes32 => address)) _implStore;
    }

    event TemplateCreated(bytes32 indexed _templateKey, address indexed _operator);
    event TemplateSet(bytes32 indexed _template, address indexed _operator);
    event ImplementationStored(bytes32 _type, address indexed _implAuth, address indexed _operator);

    function implHubStorage() internal pure returns (ImplHubStorage storage ihs) {
        bytes32 position = IMPL_HUB_STORAGE_POSITION;
        assembly {
            ihs.slot := position
        }
    }
      /**
     * @dev create and initialize an implementation template based on passed in parameters, the function will check that the lengths of the passed arrays are equal
     * @notice this function will be used to initialize implementations on the factory.  
     * @param _templateKey bytes32 key of template (can be keccak256 hash of arbitrary string or integer value), the template key will be stored as _template.
     * @param _keys bytes32 array of implementation keys
     * @param _versions bytes32 array of versions to use for template
     * @param _impls addresses of deployed implementations
     */
    function _bindAndSetImplementationTemplate(bytes32 _templateKey, bytes32[] calldata _keys, bytes32[] calldata _versions, address[] calldata _impls) internal { //Do both bind and set at the same time, check that lengths are equal.
        require(_keys.length == _impls.length && _versions.length == _impls.length, "check arrays");
        _createTemplate(_templateKey, _keys, _versions);
        for(uint256 i; i < _impls.length; i++) {
            _storeImplementation(_keys[i], _impls[i]);
        }
    }


    /**
     * @dev stand alone functionality for creating a template
     * @notice this function WILL not set implementations for you, this function only creates a deploy template you can use.  This function will also OVERWRITE any previous stored keys and versions for the template.
     * @param _templateKey see bindAndSetImplementationTemplate()
     * @param _keys bytes32 array of implementation keys to use for template
     * @param _versions bytes32 array representation of versions to use for template
     */
    function _createTemplate(bytes32 _templateKey, bytes32[] calldata _keys, bytes32[] calldata _versions) internal {
        ImplHubStorage storage ihs = implHubStorage();
        Template storage _template = ihs._keyToTemplate[_templateKey]; 
        _template.implKeys = _keys;
        _template.implVers = _versions;
        emit TemplateCreated(_templateKey, msg.sender);
    }

    /**
     * @dev store implementations given _keys and _impls arrays
     */
    function storeImplementations(bytes32[] calldata _keys, address[] calldata _impls) internal {
        require(_keys.length == _impls.length && _keys.length != 0, "check arrays");
        for(uint256 i; i < _keys.length; i++) {
            _storeImplementation(_keys[i], _impls[i]);
        }
    }

    /**
     * @dev public facing, stand-alone functionality for setting implementation. This function will store a single implementation
     */
    function storeImplementation(bytes32 _key, address _impl) internal {
        _storeImplementation(_key, _impl);
    }

    // function storeTemplateCache(address _operatingContract, bytes32[] calldata _cache) public {
    //     require(_operatingContract != address(0) && _cache.length > 0, "check args");
    //     _templateCache[_operatingContract] = _cache;
    // }

    /**
     * @dev internal function for binding implementations to ImplementationAuthorityVersion, then storing the address.
     */
    function _storeImplementation(bytes32 _key, address _impl) internal {   
        ImplHubStorage storage ihs = implHubStorage();
        ImplementationAuthorityVersion newImplementation = new ImplementationAuthorityVersion(_impl);
        ihs._implStore[_key][newImplementation.getImplementationVersion()] = address(newImplementation);
        emit ImplementationStored(_key, _impl, msg.sender);
    }
    
    function _getImplementation(bytes32 _key, bytes32 _version) internal view returns (address) {
        ImplHubStorage storage ihs = implHubStorage();
        return ihs._implStore[_key][_version];
    }

    // Implementation fetching functions
    function getImplementationGivenTemplate(bytes32 _templateKey, uint256 _implIndex) internal view returns (address) {
        ImplHubStorage storage ihs = implHubStorage();
        return _getImplementation(ihs._keyToTemplate[_templateKey].implKeys[_implIndex], ihs._keyToTemplate[_templateKey].implVers[_implIndex]);
    }
    
    // function getImplementationGivenCacheIndex(uint256 _cacheIndex, uint256 _implIndex) external view returns (address){
    //     ImplHubStorage storage ihs = implHubStorage();
    //     return _getImplementation(ihs._keyToTemplate[_templateCache[msg.sender][_cacheIndex]].implKeys[_implIndex],_templateStore[_templateCache[msg.sender][_cacheIndex]].implVers[_implIndex]);
    // }

    function getImplementation(bytes32 _key, bytes32 _version) internal view returns (address) {
        return _getImplementation(_key, _version);
    }

    function getImplementationsForTemplate(bytes32 _templateKey) internal view returns (address[] memory) {
        ImplHubStorage storage ihs = implHubStorage();
        uint256 len = ihs._keyToTemplate[_templateKey].implKeys.length;
        require(len > 0, "invalid template");
        Template memory template = ihs._keyToTemplate[_templateKey];
        address[] memory arr = new address[](len);
        for(uint256 i; i < len; i++) {
            arr[i] = ihs._implStore[template.implKeys[i]][template.implVers[i]];
        }
        return arr;
    }

    function getImplByKey(bytes32 _key, bytes32 _version) internal view returns(address){
        ImplHubStorage storage ihs = implHubStorage();
        return ihs._implStore[_key][_version];
    }

    // function getTemplateCache(address _operatingContract) public view returns(bytes32[] memory) {
    //     ImplHubStorage storage ihs = implHubStorage();
    //     return ihs._keyToTemplate[_operatingContract];
    // }

    // Administrative maintenance functions
    function relayCall(address _to, uint256 _value, bytes memory _data) internal returns(bool success, bytes memory data) {
        require(_to != address(0), "addr zero");
        (success, data) = _to.call{ value: _value}(_data);
    }    

    function relayCalls(address[] calldata _to, uint256[] calldata _value, bytes[] calldata _data) internal {
        require(_to.length == _value.length && _value.length == _data.length, "check arrays");
        bool success;
        bytes memory data;
        for(uint256 i; i < _to.length; i++) {
            (success, data) = relayCall(_to[i], _value[i], _data[i]);
            require(success, "failure");
        }
    }

    function upgradeImplementation(address _implAuth, address _newImpl) internal {
        require(_newImpl != address(0));
        IImplementationAuthorityVersion(_implAuth).updateImplementation(_newImpl);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/interface/ICutFacet.sol";

/**
 * @notice this library is a modified version of EIP-2535: Diamond 3 standard - https://eips.ethereum.org/EIPS/eip-2535 - original author : Nick Mudge
 */

library LibMultifacet {

    bytes32 constant MULTIFACET_STORAGE_POSITION = keccak256("multifacet.standard.multifacet.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition;
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition;
    }

    struct MultifacetStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function multifacetStorage() internal pure returns (MultifacetStorage storage ms) {
        bytes32 position = MULTIFACET_STORAGE_POSITION;
        assembly {
            ms.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        MultifacetStorage storage ms = multifacetStorage();
        address previousOwner = ms.contractOwner;
        ms.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = multifacetStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == multifacetStorage().contractOwner, "LibMultifacet: Must be contract owner");
    }

    event FacetCutEvent(ICutFacet.FacetCut[] _facetCut, address _init, bytes _calldata);

    function facetCut(
        ICutFacet.FacetCut[] memory _facetCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _facetCut.length; facetIndex++) {
            ICutFacet.FacetCutAction action = _facetCut[facetIndex].action;
            if(action == ICutFacet.FacetCutAction.Add) {
                addFunctions(_facetCut[facetIndex].facetAddress, _facetCut[facetIndex].functionSelectors);
            } else if (action == ICutFacet.FacetCutAction.Replace) {
                replaceFunctions(_facetCut[facetIndex].facetAddress, _facetCut[facetIndex].functionSelectors);
            } else if (action == ICutFacet.FacetCutAction.Remove) {
                removeFunctions(_facetCut[facetIndex].facetAddress, _facetCut[facetIndex].functionSelectors);
            } else {
                revert("LibMultifacet: Incorrect FacetCutAction");
            }
        }
        emit FacetCutEvent(_facetCut, _init, _calldata);
        initializeFacetCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibMultifacet: No selectors in facet to cut");
        MultifacetStorage storage ms = multifacetStorage();
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(_facetAddress != address(0), "LibMultifacet: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ms.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibMultifacet: New facet has no code");
            ms.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ms.facetAddresses.length);
            ms.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ms.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibMultifacet: Can't add function that already exists");
            ms.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ms.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            ms.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibMultifacet: No selectors in facet to cut");
        MultifacetStorage storage ms = multifacetStorage();
        require(_facetAddress != address(0), "LibMultifacet: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ms.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibMultifacet: New facet has no code");
            ms.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ms.facetAddresses.length);
            ms.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ms.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibMultifacet: Can't replace function with same function");
            removeFunction(oldFacetAddress, selector);
            // add function
            ms.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            ms.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ms.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibMultifacet: No selectors in facet to cut");
        MultifacetStorage storage ms = multifacetStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibMultifacet: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ms.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        MultifacetStorage storage ms = multifacetStorage();
        require(_facetAddress != address(0), "LibMultifacet: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibMultifacet: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ms.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ms.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ms.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ms.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ms.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ms.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ms.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ms.facetAddresses.length - 1;
            uint256 facetAddressPosition = ms.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ms.facetAddresses[lastFacetAddressPosition];
                ms.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ms.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
            }
            ms.facetAddresses.pop();
            delete ms.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeFacetCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibMultifacet: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibMultifacet: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibMultifacet: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibMultifacet: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/libraries/LibMultifacet.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

library LibRoles {

    bytes32 constant ROLES_STORAGE_POSITION = keccak256("multifacet.roles.storage");

    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct RoleStorage {
        mapping(bytes32 => RoleData) _roles;
    }

    function rolesStorage() internal pure returns (RoleStorage storage rs) {
        bytes32 position = ROLES_STORAGE_POSITION;
        assembly {
            rs.slot := position
        }
    }
  
    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) internal view returns (bool) {
        return rolesStorage()._roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view {
        _checkRole(role, msg.sender);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    //TODO set external function to replace onlyRole modifier
    function getRoleAdmin(bytes32 role) internal view returns (bytes32) {
        return rolesStorage()._roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    //TODO set external function to replace onlyRole modifier
    function grantRole(bytes32 role, address account) internal {
        LibMultifacet.enforceIsContractOwner();
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    //TODO set external function to replace onlyRole modifier
    function revokeRole(bytes32 role, address account) internal {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    //TODO set external function to replace onlyRole modifier
    function renounceRole(bytes32 role, address account) internal {
        require(account == msg.sender, "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal {
        _grantRole(role, account);
    }

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        bytes32 previousAdminRole = getRoleAdmin(role);
        rolesStorage()._roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            rolesStorage()._roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            rolesStorage()._roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'contracts/core/ProxyV1.sol';
import 'contracts/libraries/LibImplHub.sol';
import 'contracts/libraries/LibMultifacet.sol';
import 'contracts/interface/IToken.sol';
import 'contracts/interface/IIdentityRegistry.sol';
import 'contracts/interface/IAdminIdentityInit.sol';

library LibTokenDeployer {

    bytes32 constant VERSION = "0.0.1";
    bytes32 constant TOKEN_DEPLOYER_STORAGE_POSITION = keccak256("multifacet.token.deployer.storage");
    bytes32 constant TEMPLATE = keccak256("DEFAULT");
    bytes32 constant Minter_Role = keccak256("Minter_Role");

    enum Implementations{
        IDENTITY_REGISTRY,
        IDENTITY_REGISTRY_STORAGE,
        CLAIM_TOPICS_REGISTRY,
        TRUSTED_ISSUERS_REGISTRY,
        COMPLIANCE,
        TOKEN,
        IDENTITY,
        ADMIN_IDENTITY,
        ISSUER_IDENTITY
    }

    struct TokenInit{
        string name;
        string symbol;
        uint256 cap;
        uint256 holdRelease;
        uint256 tokenLimit;
        address issuer;
        address transferAgent;
        address tokenizationAgent;
        uint8 decimals;
        uint16[] countries;
    }

    event TokenCreated(address _tokenProxy, address _tokenImplAuth, address identityRegistry,
     string mappingValue, uint timestamp);
    event IdentityRegistered(address _userAddress);
    event IdentityCreated(address _userAddress, address _identityContract);

    struct TokenDeployerStorage {
        address[] tokens;
        address[] claimIssuerIdentities;
        address[] userIdentities;
        mapping(address => uint256) userIdentityId;
        mapping(address => uint256) claimIssuerIdentityId;
        mapping(address => uint256) tokenId;
        mapping(address => address) adminIdentityMinter;
    }

    function tokenDeployerStorage() internal pure returns (TokenDeployerStorage storage tds) {
        bytes32 position = TOKEN_DEPLOYER_STORAGE_POSITION;
        assembly {
            tds.slot := position
        }
    }

    function _createToken(string memory _mappingValue, bytes calldata _initData) internal {
        address identityRegistry = _initIdentityRegistry();
        _initProxyAndCompliance(identityRegistry, _mappingValue, _initData);
        IIdentityRegistry(identityRegistry).addAgentOnIdentityRegistryContract(address(this));
    }

     function _deployAndBindImpl(Implementations _impl) internal returns(address) {
        uint256 typeIndex = uint256(_impl);
        ProxyV1 deployed = new ProxyV1(); 
        deployed.upgradeTo(LibImplHub.getImplementationGivenTemplate(TEMPLATE, typeIndex)); 
        return address(deployed);
    }

    function _initIdentityRegistry() internal returns(address identityRegistry){
        identityRegistry = _deployAndBindImpl(Implementations.IDENTITY_REGISTRY);
        address claimTopicsRegistry = _deployAndBindImpl(Implementations.CLAIM_TOPICS_REGISTRY);
        address trustedIssuersRegistry = _deployAndBindImpl(Implementations.TRUSTED_ISSUERS_REGISTRY);
        address identityRegistryStorage = _deployAndBindImpl(Implementations.IDENTITY_REGISTRY_STORAGE);
        (bool success,) = identityRegistry.call(abi.encodeWithSelector(0x184b9559, trustedIssuersRegistry, claimTopicsRegistry, identityRegistryStorage));
        require(success, "identity Intiatialization Failed");
        (success,) = identityRegistryStorage.call(abi.encodeWithSelector(0xe1c7392a));
        require(success, "Identity Registry Storage Initialization Failed");
        (success,) = identityRegistryStorage.call(abi.encodeWithSelector(0x690a49f9, identityRegistry));
        require(success, "identityRegistryStorage bind Failed");
        (success,) = claimTopicsRegistry.call(abi.encodeWithSelector(0xe1c7392a));
        require(success, "claimTopicsRegistry init failure");
        (success,) = trustedIssuersRegistry.call(abi.encodeWithSelector(0xe1c7392a));
        require(success, "trustedIssuersRegistry init failure");
    }

    function _initCompliance(address _compliance, address _proxy, address _identityRegistry, TokenInit memory _initData) internal{
        (bool success,) = _compliance.call(abi.encodeWithSelector(0xc5ce23c2, address(this)));
        require(success, "Compliance Agent Factory Failed");
        ( success,) = _compliance.call(abi.encodeWithSelector(0xb6184ccd, _initData.countries));
        require(success, "Compliance countries Auth Failed");
        if(_initData.issuer != address(0)) {
            (success,) = _proxy.call(abi.encodeWithSelector(0x20694db0, _initData.issuer));
            require(success, "Adding Issuer Roles Failed");
            IIdentityRegistry(_identityRegistry).addAgentOnIdentityRegistryContract(_initData.issuer);
        }
        if(_initData.transferAgent != address(0)) {
            (success,) = _proxy.call(abi.encodeWithSelector(0xb0314599, _initData.transferAgent));
            require(success, "Adding Transfer Agent Failed");
        }
        if(_initData.tokenizationAgent != address(0)) {
            (success,) = _proxy.call(abi.encodeWithSelector(0xadccbc3c, _initData.tokenizationAgent));
            require(success, "Adding Tokenization Agent Failed");
            IIdentityRegistry(_identityRegistry).addAgentOnIdentityRegistryContract(_initData.tokenizationAgent);
        } 
        
    }

    function _initProxyAndCompliance(address _identityRegistry, string memory _mappingValue, bytes calldata _initData) internal{
        TokenInit memory _init = abi.decode(_initData, (TokenInit));
        TokenDeployerStorage storage tds = tokenDeployerStorage();
        address compliance = _deployAndBindImpl(Implementations.COMPLIANCE);
        address proxy = _deployAndBindImpl(Implementations.TOKEN);
        tds.tokens.push(proxy);
        tds.tokenId[proxy] = tds.tokens.length;
        address _tokenIdentity = _deployIdentity();
        (bool success,) = proxy.call(abi.encodeWithSelector(0xd44526bc, _identityRegistry, compliance, _init.name, _init.symbol, _init.decimals, _tokenIdentity, _init.cap));
        require(success, "Token Intiatialization Failed");
        (success,) = compliance.call(abi.encodeWithSelector(0xa4a2a9f6, proxy, _init.holdRelease, _init.tokenLimit));
        require(success, "Compliance Intiatialization Failed");
        _initCompliance(compliance, proxy, _identityRegistry, _init);
        emit TokenCreated(proxy, LibImplHub.getImplementationGivenTemplate(TEMPLATE, uint256(Implementations.TOKEN)) , _identityRegistry, _mappingValue, block.timestamp);
    }

    function _deployIdentity() internal returns (address) {
        address identity = _deployAndBindImpl(Implementations.IDENTITY);
        (bool success,) = identity.call(abi.encodeWithSelector(0x19ab453c, address(this)));
        require(success, "Identity Intiatialization Failed");
        return identity;
    }

    // //         // --------------------------Deploying MultiSig for Token-------------------------------------

    function deployAdminIdentity(uint256 executionBuffer, uint256 reqSig, address tokenizationAgent , address _issuer, address _token) internal returns (address) {
        TokenDeployerStorage storage tds = tokenDeployerStorage();
        address adminIdentityProxy = _deployAndBindImpl(Implementations.ADMIN_IDENTITY);
        (bool success,) = adminIdentityProxy.call(abi.encodeWithSelector(0xc0aa2852, address(this), executionBuffer, reqSig, _token));
        require(success, "Admin Identity Intiatialization Failed");
        (success,) = adminIdentityProxy.call(abi.encodeWithSelector(0x1d381240, keccak256(abi.encode(tokenizationAgent)), 2, 1));
        require(success, "Tokenize Addkey failure");
        (success,) = adminIdentityProxy.call(abi.encodeWithSelector(0x1d381240, keccak256(abi.encode(_issuer)), 2, 1));
        require(success, "Issuer Addkey failure");

        bytes32[] memory role = new bytes32[](1);
        role[0]=Minter_Role;

        setRolesOnToken(adminIdentityProxy, role, _token);
        revokeRolesOnToken(tokenizationAgent, role, _token);
        revokeRolesOnToken(_issuer, role, _token);

        tds.adminIdentityMinter[_token] = adminIdentityProxy;

        return adminIdentityProxy;
    }

        //         // --------------------------Functions for Token-------------------------------------

    function addAgents(address _transferAgent, address _tokenizationAgent, address _token) internal {
        addTokenizationAgentOnToken(_tokenizationAgent, _token);
        addTransferAgentOnToken(_transferAgent, _token);
    }

    function _whitelistUser(address _token, address _userAddress, uint16 _countryCode, address _userIdentity) internal {
        IIdentityRegistry iR = IToken(_token).identityRegistry();
        require(iR.isAgentOnIdentityRegistry(msg.sender),"Not an Agent on Token Identity Registry");
        IIdentityRegistry(iR).registerIdentity(_userAddress, IIdentity(_userIdentity), _countryCode);
        emit IdentityRegistered(_userAddress);
    }

    function deployAndWhitelist(address _token, address _userAddress, uint16 _CountryCode) internal {
        TokenDeployerStorage storage tds = tokenDeployerStorage();
        if(tds.userIdentityId[_userAddress] == 0){
        address userIdentity = _deployIdentity();
        tds.userIdentities.push(userIdentity);
        tds.userIdentityId[_userAddress] = tds.userIdentities.length;
        _whitelistUser(_token, _userAddress, _CountryCode, userIdentity);
        }
        else{
            address userIdentity = tds.userIdentities[tds.userIdentityId[_userAddress] - 1];
            _whitelistUser(_token, _userAddress, _CountryCode, userIdentity);
        }
    }

    function batchDeployAndWhitelist(address _token, address[] calldata _userAddress, uint16[] calldata _countrycodes) internal {
        for(uint i=0; i < _userAddress.length; i++)
        {
            deployAndWhitelist( _token,  _userAddress[i],  _countrycodes[i]);
        }
    }

    function getIdentityOf(address _userAddress) internal view returns(address){
        TokenDeployerStorage storage tds = tokenDeployerStorage();
        return tds.userIdentities[tds.userIdentityId[_userAddress] - 1];
    }

    function setRolesOnToken(address _userAddress, bytes32[] memory roles, address _token) internal {
        IToken token = IToken(_token);
        token.setRolesToTokenAgent(_userAddress, roles);
    }

    function revokeRolesOnToken(address _userAddress, bytes32[] memory roles, address _token) internal {
        IToken token = IToken(_token);
        token.revokeRolesOnTokenAgent(_userAddress, roles);
    }

    function addSubAdminOnToken(address _userAddress, address _token) internal {
        IToken token = IToken(_token);
        token.addAdmin(_userAddress);
    }

    function revokeSubAdminOnToken(address _userAddress, address _token) internal {
        IToken token = IToken(_token);
        token.revokeAdmin(_userAddress);
    }

    function addTokenizationAgentOnToken(address _agent, address _token) internal {
        IToken token = IToken(_token);
        token.addTokenizationAgentOnToken(_agent);
        IIdentityRegistry iR = token.identityRegistry();
        iR.addAgentOnIdentityRegistryContract(_agent);
    } 

    function revokeTokenizationAgentOnToken(address _agent, address _token) internal {
        IToken token = IToken(_token);
        token.removeTokenizationAgentOnToken(_agent);
        IIdentityRegistry iR = token.identityRegistry();
        iR.removeAgentOnIdentityRegistryContract(_agent);
    }

    function addTransferAgentOnToken(address _agent, address _token) internal {
        IToken token = IToken(_token);
        token.addTokenizationAgentOnToken(_agent);
    }

    function removeTransferAgentOnToken(address _agent, address _token) internal {
        IToken token = IToken(_token);
        token.removeTransferAgentOnToken(_agent);
    }

    function updateReleaseTimestampForToken(address _token, uint256 _timestamp) internal {
        IToken token = IToken(_token);
        ICompliance compliance = token.compliance();
        compliance.updateReleaseTimestamp(_timestamp);
    }

    function updateHolderLimitForToken(address _token, uint256 _newHolderLimit) internal {
        IToken token = IToken(_token);
        ICompliance compliance = token.compliance();
        compliance.updateHolderLimit(_newHolderLimit);
    }

            // --------------------------Functions for Identity Registry-------------------------------------

    function addSubAdminOnIdentityRegistry(address _userAddress, address _identityRegistry) internal {
        IIdentityRegistry iR = IIdentityRegistry(_identityRegistry);
        iR.addSubAdminOnIR(_userAddress);
    }

    function revokeSubAdminOnIdentityRegistry(address _SubAdminAddress, address _identityRegistry) internal {
        IIdentityRegistry iR = IIdentityRegistry(_identityRegistry);
        iR.revokeSubAdminOnIR(_SubAdminAddress);
    }

            // --------------------------Functions for Compliance-------------------------------------


    function addSubAdminOnCompliance(address _userAddress, address _compliance) internal {
        ICompliance compliance = ICompliance(_compliance);
        compliance.addSubAdminOnCompliance(_userAddress);
    }

    function revokeSubAdminOnCompliance(address _SubOwner, address _compliance) internal {
        ICompliance compliance = ICompliance(_compliance);
        compliance.revokeSubAdminOnCompliance(_SubOwner);
    }

            // --------------------------Function for MultiSig-------------------------------------

    function addAdminIdentitySigner(address _signer, address _token) internal {
        address multiSig = getAdminIdentityMinter(_token);
        IAdminIdentityInit(multiSig).addKey(keccak256(abi.encode(_signer)), 2, 1);

        bytes32[] memory role = new bytes32[](1);
        role[0]=Minter_Role;

        revokeRolesOnToken(_signer, role, _token);
    }

    function removeMultisigSigner(address _signer, address _token) internal {
        address multiSig = getAdminIdentityMinter(_token);
        IAdminIdentityInit(multiSig).removeKey(keccak256(abi.encode(_signer)), 2);
    }

    function setSigRequirementOnMultisig(uint256 _sigReq, address _token) internal {
        address multiSig = getAdminIdentityMinter(_token);
        IAdminIdentityInit(multiSig).setSigRequirement(_sigReq);
    }

    function getAdminIdentityMinter(address _token) internal view returns(address){
        TokenDeployerStorage storage tds = tokenDeployerStorage();
        return tds.adminIdentityMinter[_token];
    }

    function getTrustedIssuersRegistry(address _token) internal view returns(address) {
        return address((IToken(_token).identityRegistry()).issuersRegistry());
    }

    function getClaimTopicsRegistry(address _token) internal view returns(address) {
        return address((IToken(_token).identityRegistry()).topicsRegistry());
    }

    function getIdentityRegistry(address _token) internal view returns(address) {
        return address((IToken(_token).identityRegistry()));
    }

    function getComplianceContract(address _token) internal view returns(address) {
        return address((IToken(_token).compliance()));
    }

        // --------------------------UNRESTRICTED ADMIN FUNCTIONS-------------------------------------
    /**
     * @dev function to execute a low level call to any contracts owned by the factory
     */
    function adminCallUnrestricted(address _to, uint256 _value, bytes calldata _data) internal returns(bool success){
        (success,) = _to.call{value: _value}(_data);
    } 

    function adminCallsUnrestricted(address[] calldata _to, uint256[] calldata _value, bytes[] calldata _data) internal {
        require(_to.length == _value.length && _value.length == _data.length, "check arrays");
        bool success;
        for (uint256 i; i < _to.length; i++) {
            (success,) = _to[i].call{value: _value[i]}(_data[i]);
            require(success, "invalid call");
        }
    }
}