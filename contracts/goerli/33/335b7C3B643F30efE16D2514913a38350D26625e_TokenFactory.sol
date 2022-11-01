//SPDX-License-Identifier: GPL-3.0

import '../proxy/ProxyFinal.sol';
// import '../token/Token.sol';
import '../registry/IdentityRegistry.sol';
import '../registry/ClaimTopicsRegistry.sol';
import '../registry/TrustedIssuersRegistry.sol';
import '../registry/IdentityRegistryStorage.sol';
import '../registry/IIdentityRegistry.sol';
import 'contracts/proxy/IProxyFinal.sol';

pragma solidity ^0.8.0;

contract TokenFactory {

    address public token;
    address public implAuthority;
    address public identityRegistry;
    address public claimTopicsRegistry;
    address public trustIssuerRegistry;
    address public identityRegistryStorage;
    address public compliance;
    address public proxy;

    address public tokenImpl;
    address public implAuthorityImpl;
    address public identityRegistryImpl;
    address public claimTopicsRegistryImpl;
    address public trustIssuerRegistryImpl;
    address public identityRegistryStorageImpl;
    address public complianceImpl;
    address public proxyImpl;

    address public _owner;
    
    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner,"Only owner can call");
        _;
    }

    // function initializeToken() {  
    // }

    function _deployIdentityRegistry(address __identityRegistry, bytes32 salt) internal returns (address _identityRegistry) {
        require(tx.origin == msg.sender,"Only owner can call");
        bytes20 targetBytes = bytes20(__identityRegistry);

        assembly {
            
            // let clone := mload(0x40)
            // mstore(
            //     clone,
            //     0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            // )

            // mstore(add(clone, 0x14), targetBytes)

            // mstore(
            //     add(clone, 0x28),
            //     0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            // )

            _identityRegistry := create2(0, add(targetBytes, 0x20), mload(targetBytes), salt)
    }
    return _identityRegistry;
    }

    function _deployClaimTopicsRegistry(address claimTopicRegistry, bytes32 salt) internal returns (address _claimTopicsRegistry) {
        require(tx.origin == msg.sender,"Only owner can call");
        bytes20 targetBytes = bytes20(claimTopicRegistry);

        assembly {
            
            // let clone := mload(0x40)
            // mstore(
            //     clone,
            //     0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            // )

            // mstore(add(clone, 0x14), targetBytes)

            // mstore(
            //     add(clone, 0x28),
            //     0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            // )

            // _claimTopicsRegistry := create(0, clone, 0x37)
            
            _claimTopicsRegistry := create2(0, add(targetBytes, 0x20), mload(targetBytes), salt)

        }
        return _claimTopicsRegistry;
    }

    function _deployTrustedIssuersRegistry(address trustIssuersRegistry, bytes32 salt) internal returns (address _trustIssuers) {
        require(tx.origin == msg.sender,"Only owner can call");
        bytes20 targetBytes = bytes20(trustIssuersRegistry);

        assembly {
            
            // let clone := mload(0x40)
            // mstore(
            //     clone,
            //     0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            // )

            // mstore(add(clone, 0x14), targetBytes)

            // mstore(
            //     add(clone, 0x28),
            //     0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            // )

            // _trustIssuers := create(0, clone, 0x37)

            _trustIssuers := create2(0, add(targetBytes, 0x20), mload(targetBytes), salt)

        }
        return _trustIssuers;
    }

    function _deployIdentityRegistryStorage(address __identityRegistryStorage, bytes32 salt) internal returns (address _identityRegistryStorage) {
         require(tx.origin == msg.sender,"Only owner can call");

         bytes20 targetBytes = bytes20(__identityRegistryStorage);

        assembly {
            
            // let clone := mload(0x40)
            // mstore(
            //     clone,
            //     0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            // )

            // mstore(add(clone, 0x14), targetBytes)

            // mstore(
            //     add(clone, 0x28),
            //     0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            // )

            // _identityRegistryStorage := create(0, clone, 0x37)

            _identityRegistryStorage := create2(0, add(targetBytes, 0x20), mload(targetBytes), salt)

        }
        return _identityRegistryStorage;
    }

    // TODO : DEPLOY THRU FACTORY EXCLUSIVELY

    function _deployProxy(address __proxy, bytes32 salt) internal returns (address _proxy) {
        require(tx.origin == msg.sender,"Only owner can call");
        // convert address to 20 bytes
        bytes20 targetBytes = bytes20(__proxy);

        assembly {
            
            // let clone := mload(0x40)
            // mstore(
            //     clone,
            //     0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            // )

            // mstore(add(clone, 0x14), targetBytes)

            // mstore(
            //     add(clone, 0x28),
            //     0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            // )

            // _proxy := create(0, clone, 0x37)

            _proxy := create2(0, add(targetBytes, 0x20), mload(targetBytes), salt)


        //     address logic = IImplementationAuthority(_proxy).getImplementation();


        //     (bool success, ) =
        //     logic.delegatecall(
        //         abi.encodeWithSignature(
        //             'init(address,address,string,string,uint8,address,uint256)',
        //             _identityRegistry,
        //             _compliance,
        //             _name,
        //             _symbol,
        //             _decimals,
        //             _onchainID,
        //             _cap
        //         )
        //     );
        // require(success, 'Initialization failed.');
        }
        return _proxy;
    }

    function _deployToken(address __token, bytes32 salt) internal returns (address _token) {
         require(tx.origin == msg.sender,"Only owner can call");

         bytes20 targetBytes = bytes20(__token);

        assembly {
            
            // let clone := mload(0x40)
            // mstore(
            //     clone,
            //     0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            // )

            // mstore(add(clone, 0x14), targetBytes)

            // mstore(
            //     add(clone, 0x28),
            //     0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            // )

            // _token := create(0, clone, 0x37)
            _token := create2(0, add(targetBytes, 0x20), mload(targetBytes), salt)


        }
        return _token;
    }

    function _deployCompliance(address __compliance, bytes32 salt) internal returns (address _compliance) {
         require(tx.origin == msg.sender,"Only owner can call");

         bytes20 targetBytes = bytes20(__compliance);

        assembly {
            
            // let clone := mload(0x40)
            // mstore(
            //     clone,
            //     0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            // )

            // mstore(add(clone, 0x14), targetBytes)

            // mstore(
            //     add(clone, 0x28),
            //     0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            // )

            // _compliance := create(0, clone, 0x37)

            _compliance := create2(0, add(targetBytes, 0x20), mload(targetBytes), salt)

        }
        return _compliance;
    }

    function _deployimplAuthority(address __implAuthority, bytes32 salt) internal returns (address _implAuthority) {
         require(tx.origin == msg.sender,"Only owner can call");

         bytes20 targetBytes = bytes20(__implAuthority);

        assembly {
            
            // let clone := mload(0x40)
            // mstore(
            //     clone,
            //     0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            // )

            // mstore(add(clone, 0x14), targetBytes)

            // mstore(
            //     add(clone, 0x28),
            //     0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            // )

            // _implAuthority := create(0, clone, 0x37)
            _implAuthority := create2(0, add(targetBytes, 0x20), mload(targetBytes), salt)

        }
        return _implAuthority;
    }

    function setImplementation (address _token, address _identityRegistry, address _claimTopicsRegistry, address _trustIssuerRegistry, address _identityRegistryStorage, address _complianceaddress, address _proxy) public onlyOwner{
        tokenImpl = _token;
        // implAuthorityImpl = _implAuthority;
        identityRegistryImpl = _identityRegistry;
        claimTopicsRegistryImpl = _claimTopicsRegistry;
        trustIssuerRegistryImpl = _trustIssuerRegistry;
        identityRegistryStorageImpl = _identityRegistryStorage;
        complianceImpl = _complianceaddress;
        proxyImpl = _proxy;
    }

    function createToken(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _onchainID,
        uint256 _cap) external onlyOwner{
        token = _deployToken(tokenImpl, 0x4920616d20546f6b656e20666f7220616e204173736574000000000000000000);
        implAuthority = _deployimplAuthority(implAuthorityImpl, 0x4920616d20546f6b656e20666f7220616e204173736574000000000000000000);
        identityRegistry = _deployIdentityRegistry(identityRegistryImpl, 0x4920616d20546f6b656e20666f7220616e204173736574000000000000000000);
        claimTopicsRegistry = _deployClaimTopicsRegistry(claimTopicsRegistryImpl, 0x4920616d20546f6b656e20666f7220616e204173736574000000000000000000);
        trustIssuerRegistry = _deployTrustedIssuersRegistry(trustIssuerRegistryImpl, 0x4920616d20546f6b656e20666f7220616e204173736574000000000000000000);
        identityRegistryStorage = _deployIdentityRegistryStorage(identityRegistryStorageImpl,0x4920616d20546f6b656e20666f7220616e204173736574000000000000000000);
        compliance = _deployCompliance(complianceImpl, 0x4920616d20546f6b656e20666f7220616e204173736574000000000000000000);
        proxy = _deployProxy(proxyImpl, 0x4920616d20546f6b656e20666f7220616e204173736574000000000000000000);

        // IIdentityRegistry(identityRegistry).init(trustIssuerRegistry, claimTopicsRegistry, identityRegistryStorage);

        // bytes memory mem = abi.encodeWithSelector(0x696e6974, trustIssuerRegistry, claimTopicsRegistry, identityRegistryStorage);
        // address tokenIdentityRegistry = IIdentityRegistryStorage(identityRegistry);

        (bool success,) = identityRegistry.call(abi.encodeWithSelector(0x696e6974, trustIssuerRegistry, claimTopicsRegistry, identityRegistryStorage));
        require(success, "identity Intiatialization Failed");
        // (bool success1,) = proxy.call(abi.encodeWithSelector(0x696e6974, implAuthority, identityRegistry, compliance, _name, _symbol, _decimals, _onchainID, _cap));
        // require(success1, "Token Intiatialization Failed");
    
        (bool success1,) = proxy.call(abi.encodeWithSelector(0x696e6974, identityRegistry, compliance, _name, _symbol, _decimals, _onchainID, _cap));
        require(success1, "Token Intiatialization Failed");

    }

    // function initializeToken(
    //     string memory _name,
    //     string memory _symbol,
    //     uint8 _decimals,
    //     address _onchainID,
    //     uint256 _cap) public onlyOwner{

    // // ITokenProxy(proxy).init(logic, identityRegistry, compliance, _name, _symbol, _decimals, _onchainID, _cap);

    //     // address tokenProxy = IIdentityRegistryStorage(proxy);

    //     (bool success,) = proxy.call(abi.encodeWithSelector(0x696e6974, implAuthority, identityRegistry, compliance, _name, _symbol, _decimals, _onchainID, _cap));


    // }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0; 


/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
 
contract ProxyFinal {
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
    bytes32 private constant implementationPosition = keccak256("com.proxy.implementation");
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
        require(newOwner != address(0), 'OwnedUpgradeabilityProxy: INVALID');
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
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

    /**
     * @dev Sets the address of the current implementation
     * @param newImplementation address representing the new implementation to be set
     */
    function setImplementation(address newImplementation) internal {
        bytes32 position = implementationPosition;
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
        require(currentImplementation != newImplementation, 'OwnedUpgradeabilityProxy: INVALID');
        setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function _fallback() internal {
        if (maintenance()) {
            require(msg.sender == proxyOwner(), 'OwnedUpgradeabilityProxy: FORBIDDEN');
        }
        address _impl = implementation();
        require(_impl != address(0), 'OwnedUpgradeabilityProxy: INVALID');
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

// SPDX-License-Identifier: GPL-3.0
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2021, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@onchain-id/solidity/contracts/interface/IClaimIssuer.sol';
import '@onchain-id/solidity/contracts/interface/IIdentity.sol';

import '../registry/IClaimTopicsRegistry.sol';
import '../registry/ITrustedIssuersRegistry.sol';
import '../registry/IIdentityRegistry.sol';
import '../roles/AgentRole.sol';
import '../registry/IIdentityRegistryStorage.sol';


contract IdentityRegistry is IIdentityRegistry, AgentRole {
    /// @dev Address of the ClaimTopicsRegistry Contract
    IClaimTopicsRegistry private tokenTopicsRegistry;

    /// @dev Address of the TrustedIssuersRegistry Contract
    ITrustedIssuersRegistry private tokenIssuersRegistry;

    /// @dev Address of the IdentityRegistryStorage Contract
    IIdentityRegistryStorage private tokenIdentityStorage;

    /**
     *  @dev the constructor initiates the Identity Registry smart contract
     *  @param _trustedIssuersRegistry the trusted issuers registry linked to the Identity Registry
     *  @param _claimTopicsRegistry the claim topics registry linked to the Identity Registry
     *  @param _identityStorage the identity registry storage linked to the Identity Registry
     *  emits a `ClaimTopicsRegistrySet` event
     *  emits a `TrustedIssuersRegistrySet` event
     *  emits an `IdentityStorageSet` event
     */
    constructor(
        address _trustedIssuersRegistry,
        address _claimTopicsRegistry,
        address _identityStorage
    ) {
        tokenTopicsRegistry = IClaimTopicsRegistry(_claimTopicsRegistry);
        tokenIssuersRegistry = ITrustedIssuersRegistry(_trustedIssuersRegistry);
        tokenIdentityStorage = IIdentityRegistryStorage(_identityStorage);
        emit ClaimTopicsRegistrySet(_claimTopicsRegistry);
        emit TrustedIssuersRegistrySet(_trustedIssuersRegistry);
        emit IdentityStorageSet(_identityStorage);
    }

    /**
     *  @dev See {IIdentityRegistry-identity}.
     */
    function identity(address _userAddress) public view override returns (IIdentity) {
        return tokenIdentityStorage.storedIdentity(_userAddress);
    }

    /**
     *  @dev See {IIdentityRegistry-investorCountry}.
     */
    function investorCountry(address _userAddress) external view override returns (uint16) {
        return tokenIdentityStorage.storedInvestorCountry(_userAddress);
    }

    /**
     *  @dev See {IIdentityRegistry-issuersRegistry}.
     */
    function issuersRegistry() external view override returns (ITrustedIssuersRegistry) {
        return tokenIssuersRegistry;
    }

    /**
     *  @dev See {IIdentityRegistry-topicsRegistry}.
     */
    function topicsRegistry() external view override returns (IClaimTopicsRegistry) {
        return tokenTopicsRegistry;
    }

    /**
     *  @dev See {IIdentityRegistry-identityStorage}.
     */
    function identityStorage() external view override returns (IIdentityRegistryStorage) {
        return tokenIdentityStorage;
    }

    /**
     *  @dev See {IIdentityRegistry-registerIdentity}.
     */
    function registerIdentity(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) public override onlyAgent {
        tokenIdentityStorage.addIdentityToStorage(_userAddress, _identity, _country);
        emit IdentityRegistered(_userAddress, _identity);
    }

    /**
     *  @dev See {IIdentityRegistry-batchRegisterIdentity}.
     */
    function batchRegisterIdentity(
        address[] calldata _userAddresses,
        IIdentity[] calldata _identities,
        uint16[] calldata _countries
    ) external override {
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            registerIdentity(_userAddresses[i], _identities[i], _countries[i]);
        }
    }

    /**
     *  @dev See {IIdentityRegistry-updateIdentity}.
     */
    function updateIdentity(address _userAddress, IIdentity _identity) external override onlyAgent {
        IIdentity oldIdentity = identity(_userAddress);
        tokenIdentityStorage.modifyStoredIdentity(_userAddress, _identity);
        emit IdentityUpdated(oldIdentity, _identity);
    }

    /**
     *  @dev See {IIdentityRegistry-updateCountry}.
     */
    function updateCountry(address _userAddress, uint16 _country) external override onlyAgent {
        tokenIdentityStorage.modifyStoredInvestorCountry(_userAddress, _country);
        emit CountryUpdated(_userAddress, _country);
    }

    /**
     *  @dev See {IIdentityRegistry-deleteIdentity}.
     */
    function deleteIdentity(address _userAddress) external override onlyAgent {
        tokenIdentityStorage.removeIdentityFromStorage(_userAddress);
        emit IdentityRemoved(_userAddress, identity(_userAddress));
    }

    /**
     *  @dev See {IIdentityRegistry-isVerified}.
     */
    function isVerified(address _userAddress) external view override returns (bool) {
        if (address(identity(_userAddress)) == address(0)) {
            return false;
        }
        uint256[] memory requiredClaimTopics = tokenTopicsRegistry.getClaimTopics();
        if (requiredClaimTopics.length == 0) {
            return true;
        }
        uint256 foundClaimTopic;
        uint256 scheme;
        address issuer;
        bytes memory sig;
        bytes memory data;
        uint256 claimTopic;
        for (claimTopic = 0; claimTopic < requiredClaimTopics.length; claimTopic++) {
            bytes32[] memory claimIds = identity(_userAddress).getClaimIdsByTopic(requiredClaimTopics[claimTopic]);
            if (claimIds.length == 0) {
                return false;
            }
            for (uint256 j = 0; j < claimIds.length; j++) {
                (foundClaimTopic, scheme, issuer, sig, data, ) = identity(_userAddress).getClaim(claimIds[j]);

                try IClaimIssuer(issuer).isClaimValid(identity(_userAddress), requiredClaimTopics[claimTopic], sig,
                data) returns(bool _validity){
                    if (
                        _validity
                        && tokenIssuersRegistry.hasClaimTopic(issuer, requiredClaimTopics[claimTopic])
                        && tokenIssuersRegistry.isTrustedIssuer(issuer)
                    ) {
                        j = claimIds.length;
                    }
                    if (!tokenIssuersRegistry.isTrustedIssuer(issuer) && j == (claimIds.length - 1)) {
                        return false;
                    }
                    if (!tokenIssuersRegistry.hasClaimTopic(issuer, requiredClaimTopics[claimTopic]) && j == (claimIds.length - 1)) {
                        return false;
                    }
                    if (!_validity && j == (claimIds.length - 1)) {
                        return false;
                    }
                }
                catch {
                    if (j == (claimIds.length - 1)) {
                        return false;
                    }
                }
            }
        }
        return true;
    }

    /**
     *  @dev See {IIdentityRegistry-setIdentityRegistryStorage}.
     */
    function setIdentityRegistryStorage(address _identityRegistryStorage) external override onlyOwner {
        tokenIdentityStorage = IIdentityRegistryStorage(_identityRegistryStorage);
        emit IdentityStorageSet(_identityRegistryStorage);
    }

    /**
     *  @dev See {IIdentityRegistry-setClaimTopicsRegistry}.
     */
    function setClaimTopicsRegistry(address _claimTopicsRegistry) external override onlyOwner {
        tokenTopicsRegistry = IClaimTopicsRegistry(_claimTopicsRegistry);
        emit ClaimTopicsRegistrySet(_claimTopicsRegistry);
    }

    /**
     *  @dev See {IIdentityRegistry-setTrustedIssuersRegistry}.
     */
    function setTrustedIssuersRegistry(address _trustedIssuersRegistry) external override onlyOwner {
        tokenIssuersRegistry = ITrustedIssuersRegistry(_trustedIssuersRegistry);
        emit TrustedIssuersRegistrySet(_trustedIssuersRegistry);
    }

    /**
     *  @dev See {IIdentityRegistry-contains}.
     */
    function contains(address _userAddress) external view override returns (bool) {
        if (address(identity(_userAddress)) == address(0)) {
            return false;
        }
        return true;
    }

    /**
     *  @dev See {IIdentityRegistry-transferOwnershipOnIdentityRegistryContract}.
     */
    function transferOwnershipOnIdentityRegistryContract(address _newOwner) external override onlyOwner {
        transferOwnership(_newOwner);
    }

    /**
     *  @dev See {IIdentityRegistry-addAgentOnIdentityRegistryContract}.
     */
    function addAgentOnIdentityRegistryContract(address _agent) external override {
        addAgent(_agent);
    }

    /**
     *  @dev See {IIdentityRegistry-removeAgentOnIdentityRegistryContract}.
     */
    function removeAgentOnIdentityRegistryContract(address _agent) external override {
        removeAgent(_agent);
    }
}

// SPDX-License-Identifier: GPL-3.0
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2021, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

import '../registry/IClaimTopicsRegistry.sol';

contract ClaimTopicsRegistry is IClaimTopicsRegistry, Ownable {
    /// @dev All required Claim Topics
    uint256[] private claimTopics;

    /**
     *  @dev See {IClaimTopicsRegistry-addClaimTopic}.
     */
    function addClaimTopic(uint256 _claimTopic) external override onlyOwner {
        uint256 length = claimTopics.length;
        for (uint256 i = 0; i < length; i++) {
            require(claimTopics[i] != _claimTopic, 'claimTopic already exists');
        }
        claimTopics.push(_claimTopic);
        emit ClaimTopicAdded(_claimTopic);
    }

    /**
     *  @dev See {IClaimTopicsRegistry-removeClaimTopic}.
     */
    function removeClaimTopic(uint256 _claimTopic) external override onlyOwner {
        uint256 length = claimTopics.length;
        for (uint256 i = 0; i < length; i++) {
            if (claimTopics[i] == _claimTopic) {
                claimTopics[i] = claimTopics[length - 1];
                claimTopics.pop();
                emit ClaimTopicRemoved(_claimTopic);
                break;
            }
        }
    }

    /**
     *  @dev See {IClaimTopicsRegistry-getClaimTopics}.
     */
    function getClaimTopics() external view override returns (uint256[] memory) {
        return claimTopics;
    }

    /**
     *  @dev See {IClaimTopicsRegistry-transferOwnershipOnClaimTopicsRegistryContract}.
     */
    function transferOwnershipOnClaimTopicsRegistryContract(address _newOwner) external override onlyOwner {
        transferOwnership(_newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2021, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@onchain-id/solidity/contracts/interface/IClaimIssuer.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import '../registry/ITrustedIssuersRegistry.sol';


contract TrustedIssuersRegistry is ITrustedIssuersRegistry, Ownable {
    /// @dev Array containing all TrustedIssuers identity contract address.
    IClaimIssuer[] private trustedIssuers;

    /// @dev Mapping between a trusted issuer index and its corresponding claimTopics.
    mapping(address => uint256[]) private trustedIssuerClaimTopics;

    /**
     *  @dev See {ITrustedIssuersRegistry-addTrustedIssuer}.
     */
    function addTrustedIssuer(IClaimIssuer _trustedIssuer, uint256[] calldata _claimTopics) external override onlyOwner {
        require(trustedIssuerClaimTopics[address(_trustedIssuer)].length == 0, 'trusted Issuer already exists');
        require(_claimTopics.length > 0, 'trusted claim topics cannot be empty');
        trustedIssuers.push(_trustedIssuer);
        trustedIssuerClaimTopics[address(_trustedIssuer)] = _claimTopics;
        emit TrustedIssuerAdded(_trustedIssuer, _claimTopics);
    }

    /**
     *  @dev See {ITrustedIssuersRegistry-removeTrustedIssuer}.
     */
    function removeTrustedIssuer(IClaimIssuer _trustedIssuer) external override onlyOwner {
        require(trustedIssuerClaimTopics[address(_trustedIssuer)].length != 0, 'trusted Issuer doesn\'t exist');
        uint256 length = trustedIssuers.length;
        for (uint256 i = 0; i < length; i++) {
            if (trustedIssuers[i] == _trustedIssuer) {
                trustedIssuers[i] = trustedIssuers[length - 1];
                trustedIssuers.pop();
                break;
            }
        }
        delete trustedIssuerClaimTopics[address(_trustedIssuer)];
        emit TrustedIssuerRemoved(_trustedIssuer);
    }

    /**
     *  @dev See {ITrustedIssuersRegistry-updateIssuerClaimTopics}.
     */
    function updateIssuerClaimTopics(IClaimIssuer _trustedIssuer, uint256[] calldata _claimTopics) external override onlyOwner {
        require(trustedIssuerClaimTopics[address(_trustedIssuer)].length != 0, 'trusted Issuer doesn\'t exist');
        require(_claimTopics.length > 0, 'claim topics cannot be empty');
        trustedIssuerClaimTopics[address(_trustedIssuer)] = _claimTopics;
        emit ClaimTopicsUpdated(_trustedIssuer, _claimTopics);
    }

    /**
     *  @dev See {ITrustedIssuersRegistry-getTrustedIssuers}.
     */
    function getTrustedIssuers() external view override returns (IClaimIssuer[] memory) {
        return trustedIssuers;
    }

    /**
     *  @dev See {ITrustedIssuersRegistry-isTrustedIssuer}.
     */
    function isTrustedIssuer(address _issuer) external view override returns (bool) {
        uint256 length = trustedIssuers.length;
        for (uint256 i = 0; i < length; i++) {
            if (address(trustedIssuers[i]) == _issuer) {
                return true;
            }
        }
        return false;
    }

    /**
     *  @dev See {ITrustedIssuersRegistry-getTrustedIssuerClaimTopics}.
     */
    function getTrustedIssuerClaimTopics(IClaimIssuer _trustedIssuer) external view override returns (uint256[] memory) {
        require(trustedIssuerClaimTopics[address(_trustedIssuer)].length != 0, 'trusted Issuer doesn\'t exist');
        return trustedIssuerClaimTopics[address(_trustedIssuer)];
    }

    /**
     *  @dev See {ITrustedIssuersRegistry-hasClaimTopic}.
     */
    function hasClaimTopic(address _issuer, uint256 _claimTopic) external view override returns (bool) {
        uint256 length = trustedIssuerClaimTopics[_issuer].length;
        uint256[] memory claimTopics = trustedIssuerClaimTopics[_issuer];
        for (uint256 i = 0; i < length; i++) {
            if (claimTopics[i] == _claimTopic) {
                return true;
            }
        }
        return false;
    }

    /**
     *  @dev See {ITrustedIssuersRegistry-transferOwnershipOnIssuersRegistryContract}.
     */
    function transferOwnershipOnIssuersRegistryContract(address _newOwner) external override onlyOwner {
        transferOwnership(_newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2021, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@onchain-id/solidity/contracts/interface/IIdentity.sol';

import '../roles/AgentRole.sol';
import '../registry/IIdentityRegistryStorage.sol';

contract IdentityRegistryStorage is IIdentityRegistryStorage, AgentRole {
    /// @dev struct containing the identity contract and the country of the user
    struct Identity {
        IIdentity identityContract;
        uint16 investorCountry;
    }

    /// @dev mapping between a user address and the corresponding identity
    mapping(address => Identity) private identities;

    /// @dev array of Identity Registries linked to this storage
    address[] private identityRegistries;

    /**
     *  @dev See {IIdentityRegistryStorage-linkedIdentityRegistries}.
     */
    function linkedIdentityRegistries() external view override returns (address[] memory) {
        return identityRegistries;
    }

    /**
     *  @dev See {IIdentityRegistryStorage-storedIdentity}.
     */
    function storedIdentity(address _userAddress) external view override returns (IIdentity) {
        return identities[_userAddress].identityContract;
    }

    /**
     *  @dev See {IIdentityRegistryStorage-storedInvestorCountry}.
     */
    function storedInvestorCountry(address _userAddress) external view override returns (uint16) {
        return identities[_userAddress].investorCountry;
    }

    /**
     *  @dev See {IIdentityRegistryStorage-addIdentityToStorage}.
     */
    function addIdentityToStorage(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) external override onlyAgent {
        require(address(_identity) != address(0), 'contract address can\'t be a zero address');
        require(address(identities[_userAddress].identityContract) == address(0), 'identity contract already exists, please use update');
        identities[_userAddress].identityContract = _identity;
        identities[_userAddress].investorCountry = _country;
        emit IdentityStored(_userAddress, _identity);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-modifyStoredIdentity}.
     */
    function modifyStoredIdentity(address _userAddress, IIdentity _identity) external override onlyAgent {
        require(address(identities[_userAddress].identityContract) != address(0), 'this user has no identity registered');
        require(address(_identity) != address(0), 'contract address can\'t be a zero address');
        IIdentity oldIdentity = identities[_userAddress].identityContract;
        identities[_userAddress].identityContract = _identity;
        emit IdentityModified(oldIdentity, _identity);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-modifyStoredInvestorCountry}.
     */
    function modifyStoredInvestorCountry(address _userAddress, uint16 _country) external override onlyAgent {
        require(address(identities[_userAddress].identityContract) != address(0), 'this user has no identity registered');
        identities[_userAddress].investorCountry = _country;
        emit CountryModified(_userAddress, _country);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-removeIdentityFromStorage}.
     */
    function removeIdentityFromStorage(address _userAddress) external override onlyAgent {
        require(address(identities[_userAddress].identityContract) != address(0), 'you haven\'t registered an identity yet');
        delete identities[_userAddress];
        emit IdentityUnstored(_userAddress, identities[_userAddress].identityContract);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-transferOwnershipOnIdentityRegistryStorage}.
     */
    function transferOwnershipOnIdentityRegistryStorage(address _newOwner) external override onlyOwner {
        transferOwnership(_newOwner);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-bindIdentityRegistry}.
     */
    function bindIdentityRegistry(address _identityRegistry) external override {
        addAgent(_identityRegistry);
        identityRegistries.push(_identityRegistry);
        emit IdentityRegistryBound(_identityRegistry);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-unbindIdentityRegistry}.
     */
    function unbindIdentityRegistry(address _identityRegistry) external override {
        require(identityRegistries.length > 0, 'identity registry is not stored');
        uint256 length = identityRegistries.length;
        for (uint256 i = 0; i < length; i++) {
            if (identityRegistries[i] == _identityRegistry) {
                identityRegistries[i] = identityRegistries[length - 1];
                identityRegistries.pop();
                break;
            }
        }
        removeAgent(_identityRegistry);
        emit IdentityRegistryUnbound(_identityRegistry);
    }
}

// SPDX-License-Identifier: GPL-3.0
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2021, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../registry/ITrustedIssuersRegistry.sol';
import '../registry/IClaimTopicsRegistry.sol';
import '../registry/IIdentityRegistryStorage.sol';

import '@onchain-id/solidity/contracts/interface/IClaimIssuer.sol';
import '@onchain-id/solidity/contracts/interface/IIdentity.sol';

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
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0; 


/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
 
interface IProxyFinal {

    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev This event will be emitted every time the implementation gets upgraded
     * @param implementation representing the address of the upgraded implementation
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Tells if contract is on maintenance
     * @return _maintenance if contract is on maintenance
     */
    function maintenance() external view returns (bool _maintenance);

    /**
     * @dev Sets if contract is on maintenance
     */
    function setMaintenance(bool _maintenance) external;

    /**
     * @dev Tells the address of the owner
     * @return owner the address of the owner
     */

    /**
     * @dev Sets the address of the owner
     */

   

    /*
     * @dev Allows the proxy owner to upgrade the current version of the proxy.
     * @param implementation representing the address of the new implementation to be set.
     */
    function upgradeTo(address newImplementation) external ;

    /*
     * @dev Allows the proxy owner to upgrade the current version of the proxy and call the new implementation
     * to initialize whatever is needed through a low level call.
     * @param implementation representing the address of the new implementation to be set.
     * @param data represents the msg.data to bet sent in the low level call. This parameter may include the function
     * signature of the implementation to be called with the needed payload
     */

  
   


   
}

// SPDX-License-Identifier: GPL-3.0
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2021, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@onchain-id/solidity/contracts/interface/IClaimIssuer.sol';

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

// SPDX-License-Identifier: GPL-3.0
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2021, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

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
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2021, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

import './Roles.sol';

contract AgentRole is Ownable {
    using Roles for Roles.Role;

    event AgentAdded(address indexed _agent);
    event AgentRemoved(address indexed _agent);

    Roles.Role private _agents;

    modifier onlyAgent() {
        require(isAgent(msg.sender), 'AgentRole: caller does not have the Agent role');
        _;
    }

    function isAgent(address _agent) public view returns (bool) {
        return _agents.has(_agent);
    }

    function addAgent(address _agent) public onlyOwner {
        _agents.add(_agent);
        emit AgentAdded(_agent);
    }

    function removeAgent(address _agent) public onlyOwner {
        _agents.remove(_agent);
        emit AgentRemoved(_agent);
    }
}

// SPDX-License-Identifier: GPL-3.0
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2021, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@onchain-id/solidity/contracts/interface/IIdentity.sol';

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

import "./IIdentity.sol";

interface IClaimIssuer is IIdentity {
    function revokeClaim(bytes32 _claimId, address _identity) external returns(bool);
    function getRecoveredAddress(bytes calldata sig, bytes32 dataHash) external pure returns (address);
    function isClaimRevoked(bytes calldata _sig) external view returns (bool);
    function isClaimValid(IIdentity _identity, uint256 claimTopic, bytes calldata sig, bytes calldata data) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC734.sol";
import "./IERC735.sol";

interface IIdentity is IERC734, IERC735 {}

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

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), 'Roles: account already has role');
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), 'Roles: account does not have role');
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), 'Roles: account is the zero address');
        return role.bearer[account];
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