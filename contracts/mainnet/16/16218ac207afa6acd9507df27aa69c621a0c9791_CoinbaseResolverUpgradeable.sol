// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.13;

//////////////////////////
////    Interfaces    ////
//////////////////////////
import { IAddrResolver } from "ens/resolvers/profiles/IAddrResolver.sol";
import { INameResolver } from "ens/resolvers/profiles/INameResolver.sol";
import { IABIResolver } from "ens/resolvers/profiles/IABIResolver.sol";
import { IPubkeyResolver } from "ens/resolvers/profiles/IPubkeyResolver.sol";
import { ITextResolver } from "ens/resolvers/profiles/ITextResolver.sol";
import { IContentHashResolver } from "ens/resolvers/profiles/IContentHashResolver.sol";
import { IAddressResolver } from "ens/resolvers/profiles/IAddressResolver.sol";

import { IERC3668 } from "./interfaces/IERC3668.sol";
import { IExtendedResolver } from "./interfaces/IExtendedResolver.sol";
import { IWriteDeferral } from "./interfaces/IWriteDeferral.sol";
import { IResolverService } from "./interfaces/IResolverService.sol";

//////////////////////////
////    Libraries     ////
//////////////////////////
import { EnumerableSetUpgradeable } from "openzeppelin/utils/structs/EnumerableSetUpgradeable.sol";
import { StringsUpgradeable } from "openzeppelin/utils/StringsUpgradeable.sol";

import { SignatureVerifierUpgradeable } from "./libraries/SignatureVerifierUpgradeable.sol";
import { ResolverStateHelper } from "./libraries/ResolverStateHelper.sol";
import { TypeToString } from "./libraries/TypeToString.sol";

//////////////////////////
////      Types       ////
//////////////////////////
import { Initializable } from "openzeppelin/proxy/utils/Initializable.sol";
import { ERC165Upgradeable } from "openzeppelin/utils/introspection/ERC165Upgradeable.sol";

import { ManageableUpgradeable } from "./types/ManageableUpgradeable.sol";


//////////////////////////
////      Errors      ////
//////////////////////////
error TimeoutDurationTooShort();
error TimeoutDurationTooLong();

/**
 * @notice Coinbase Offchain ENS Resolver.
 * @dev Adapted from: https://github.com/ensdomains/offchain-resolver/blob/2bc616f19a94370828c35f29f71d5d4cab3a9a4f/packages/contracts/contracts/OffchainResolver.sol
 */
contract CoinbaseResolverUpgradeable is 
    Initializable,
    IERC3668, IWriteDeferral, 
    IExtendedResolver, 

    IAddrResolver, 
    INameResolver,
    IABIResolver,
    ITextResolver,
    IPubkeyResolver,
    IContentHashResolver,
    IAddressResolver,

    ERC165Upgradeable, ManageableUpgradeable {
    using StringsUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Event raised when a new signer is added.
    event SignerAdded(address indexed addedSigner);
    /// @notice Event raised when a signer is removed.
    event SignerRemoved(address indexed removedSigner);
    
    /// @notice Event raised when a new gateway URL is set.
    event GatewayUrlSet(string indexed previousUrl, string indexed newUrl);
    
    /// @notice Event raised when a new off-chain database timeout duration is set.
    event OffChainDatabaseTimeoutDurationSet(uint256 previousDuration, uint256 newDuration);

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Universal constant for the ETH coin type.
    uint constant private COIN_TYPE_ETH = 60;

    /// @dev Constant for name used in the domain definition of the off-chain write deferral reversion.
    string constant private WRITE_DEFERRAL_DOMAIN_NAME = "CoinbaseResolver";
    /// @dev Constant specifing the version of the domain definition.
    string constant private WRITE_DEFERRAL_DOMAIN_VERSION = "1";
    /// @dev Constant specifing the chainId that this contract lives on
    uint64 constant private CHAIN_ID = 1;

    /*//////////////////////////////////////////////////////////////
                             SLO CONSTRANTS
    //////////////////////////////////////////////////////////////*/

    bytes32 constant private RESOLVER_STATE_SLO = keccak256("coinbase.resolver.v1.state");

    /*//////////////////////////////////////////////////////////////
                               INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with the initial parameters.
     * @param newOwner Owner address.
     * @param newSignerManager Signer manager address.
     * @param newGatewayManager Gateway manager address.
     * @param newGatewayUrl Gateway URL.
     * @param newOffChainDatabaseUrl OffChainDatabase URL.
     * @param newSigners Signer addresses.
     */
    function initialize(
        address newOwner,
        address newSignerManager,
        address newGatewayManager,
        string memory newGatewayUrl,
        string memory newOffChainDatabaseUrl,
        uint256 newOffChainDatabaseTimeoutDuration,
        address[] memory newSigners
    ) public initializer {
        // initialize dependecies
        ManageableUpgradeable.__Managable_init();

        // Admin / Manager initialization
        _transferOwnership(newOwner);
        _changeSignerManager(newSignerManager);
        _changeGatewayManager(newGatewayManager);

        // State initialization
        _setGatewayUrl(newGatewayUrl);
        _setOffChainDatabaseUrl(newOffChainDatabaseUrl);
        _setOffChainDatabaseTimeoutDuration(newOffChainDatabaseTimeoutDuration);

        _addSigners(newSigners);
    }

    /*//////////////////////////////////////////////////////////////
                            ENSIP-10 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initiate a resolution conforming to the ENSIP-10. Reverts with an OffchainLookup error.
     * @param name DNS-encoded name to resolve.
     * @param data ABI-encoded data for the underlying resolution function (e.g. addr(bytes32), text(bytes32,string)).
     * @return Always reverts with an OffchainLookup error.
     */
    function resolve(bytes calldata name, bytes calldata data)
        external
        view
        override
        returns (bytes memory)
    {
        _offChainLookup(msg.data);
    }

    /*//////////////////////////////////////////////////////////////
                          ENS ERC-137 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, address a) external {
        setAddr(node, COIN_TYPE_ETH, addressToBytes(a));
    }

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return Always reverts with an OffchainLookup error.
     */
    function addr(bytes32 node) virtual override public view returns (address payable) {
        addr(node, COIN_TYPE_ETH);
    }

    /*//////////////////////////////////////////////////////////////
                          ENS ERC-181 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * Sets the name associated with an ENS node, for reverse records.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     */
    function setName(bytes32 node, string calldata name) external {
        IWriteDeferral.parameter[] memory params = new IWriteDeferral.parameter[](2);

        params[0].name = "node";
        params[0].value = TypeToString.bytes32ToString(node);
        
        params[1].name = "name";
        params[1].value = name;

        _offChainStorage(params);
    }

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return Always reverts with an OffchainLookup error.
     */
    function name(bytes32 node) override view external returns(string memory) {
        _offChainLookup(msg.data);
    }

    /*//////////////////////////////////////////////////////////////
                          ENS ERC-205 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * Sets the ABI associated with an ENS node.
     * Nodes may have one ABI of each content type. To remove an ABI, set it to
     * the empty string.
     * @param node The node to update.
     * @param contentType The content type of the ABI
     * @param data The ABI data.
     */
    function setABI(bytes32 node, uint256 contentType, bytes calldata data) external {
        IWriteDeferral.parameter[] memory params = new IWriteDeferral.parameter[](3);
        
        params[0].name = "node";
        params[0].value = TypeToString.bytes32ToString(node);

        params[1].name = "content_type";
        params[1].value = contentType.toString();

        params[2].name = "data";
        params[2].value = TypeToString.bytesToString(data);
        
        _offChainStorage(params);
    }

    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return Always reverts with an OffchainLookup error.
     */
    function ABI(bytes32 node, uint256 contentTypes) external view override returns (uint256, bytes memory) {
        _offChainLookup(msg.data);
    }

    /*//////////////////////////////////////////////////////////////
                          ENS ERC-619 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * Sets the SECP256k1 public key associated with an ENS node.
     * @param node The ENS node to query
     * @param x the X coordinate of the curve point for the public key.
     * @param y the Y coordinate of the curve point for the public key.
     */
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external {
        IWriteDeferral.parameter[] memory params = new IWriteDeferral.parameter[](3);

        params[0].name = "node";
        params[0].value = TypeToString.bytes32ToString(node);
        
        params[1].name = "x";
        params[1].value = TypeToString.bytes32ToString(x);
        
        params[2].name = "y";
        params[2].value = TypeToString.bytes32ToString(y);

        _offChainStorage(params);
    }

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x The X coordinate of the curve point for the public key.
     * @return y The Y coordinate of the curve point for the public key.
     * Always reverts with an OffchainLookup error.
     */
    function pubkey(bytes32 node) virtual override external view returns (bytes32 x, bytes32 y) {
        _offChainLookup(msg.data);
    }

    /*//////////////////////////////////////////////////////////////
                          ENS ERC-634 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * Sets the text data associated with an ENS node and key.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param key The key to set.
     * @param value The text data value to set.
     */
    function setText(bytes32 node, string calldata key, string calldata value) external {
        IWriteDeferral.parameter[] memory params = new IWriteDeferral.parameter[](3);
        
        params[0].name = "node";
        params[0].value = TypeToString.bytes32ToString(node);
        
        params[1].name = "key";
        params[1].value = key;

        params[2].name = "value";
        params[2].value = value;

        _offChainStorage(params);
    }

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return Always reverts with an OffchainLookup error.
     */
    function text(bytes32 node, string calldata key) override external view returns (string memory) {
        _offChainLookup(msg.data);
    }

    /*//////////////////////////////////////////////////////////////
                          ENS ERC-1577 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * Sets the contenthash associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param hash The contenthash to set
     */
    function setContenthash(bytes32 node, bytes calldata hash) external {
        IWriteDeferral.parameter[] memory params = new IWriteDeferral.parameter[](2);
        
        params[0].name = "node";
        params[0].value = TypeToString.bytes32ToString(node);

        params[1].name = "hash";
        params[1].value = TypeToString.bytesToString(hash);

        _offChainStorage(params);
    }

    /**
     * Returns the contenthash associated with an ENS node.
     * @param node The ENS node to query.
     * @return Always reverts with an OffchainLookup error.
     */
    function contenthash(bytes32 node) external view override returns (bytes memory) {
        _offChainLookup(msg.data);
    }

    /*//////////////////////////////////////////////////////////////
                          ENS ERC-2304 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param coinType The constant used to define the coin type of the corresponding address.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, uint coinType, bytes memory a) public {
        IWriteDeferral.parameter[] memory params = new IWriteDeferral.parameter[](3);
        
        params[0].name = "node";
        params[0].value = TypeToString.bytes32ToString(node);

        params[1].name = "coin_type";
        params[1].value = StringsUpgradeable.toString(coinType);

        params[2].name = "address";
        params[2].value = TypeToString.bytesToString(a);

        _offChainStorage(params);
    }

    /**
     * Returns the address associated with an ENS node for the corresponding coinType.
     * @param node The ENS node to query.
     * @param coinType The coin type of the corresponding address.
     * @return Always reverts with an OffchainLookup error.
     */
    function addr(bytes32 node, uint coinType) override view public returns(bytes memory) {
        _offChainLookup(msg.data);
    }

    /*//////////////////////////////////////////////////////////////
                        ENS CCIP RESOLVER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Builds an OffchainLookup error.
     * @param callData The calldata for the corresponding lookup.
     * @return Always reverts with an OffchainLookup error.
     */
    function _offChainLookup(bytes calldata callData) private view returns(bytes memory) {
        string[] memory urls = new string[](1);
        urls[0] = ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO).gatewayUrl;

        revert OffchainLookup(
            address(this),
            urls,
            callData,
            this.resolveWithProof.selector,
            callData
        );
    }

    /**
     * @notice Callback used by CCIP-read compatible clients to verify and parse the response.
     * @dev Reverts if the signature is invalid.
     * @param response ABI-encoded response data in the form of (bytes result, uint64 expires, bytes signature).
     * @param extraData Original request data.
     * @return ABI-encoded result data for the underlying resolution function.
     */
    function resolveWithProof(bytes calldata response, bytes calldata extraData)
        external
        view
        returns (bytes memory)
    {
        (address signer, bytes memory result) = SignatureVerifierUpgradeable.verify(
            extraData,
            response
        );

        require(
            ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO).signers.contains(signer),
            "CoinbaseResolver::resolveWithProof: invalid signature"
        );
        return result;
    }

    /*//////////////////////////////////////////////////////////////
                    ENS WRITE DEFERRAL RESOLVER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Builds an StorageHandledByOffChainDatabase error.
     * @param params The offChainDatabaseParamters used to build the corresponding mutation action.
     */
    function _offChainStorage(IWriteDeferral.parameter[] memory params) private view {
        ResolverStateHelper.ResolverState storage state_ = ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO);

        revert StorageHandledByOffChainDatabase(
            IWriteDeferral.domainData(
                {
                    name: WRITE_DEFERRAL_DOMAIN_NAME,
                    version: WRITE_DEFERRAL_DOMAIN_VERSION,
                    chainId: CHAIN_ID,
                    verifyingContract: address(this)
                }
            ),
            state_.offChainDatabaseUrl,
            IWriteDeferral.messageData(
                {
                    functionSelector: msg.sig,
                    sender: msg.sender,
                    parameters: params,
                    expirationTimestamp: block.timestamp + state_.offChainDatabaseTimeoutDuration
                }
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                    EXTERNAL ADMINISTRATIVE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set the gateway URL.
     * @dev Can only be called by the gateway manager.
     * @param newUrl New gateway URL.
     */
    function setGatewayUrl(string calldata newUrl) external onlyGatewayManager {
        _setGatewayUrl(newUrl);
    }

    /**
     * @notice Set the offChainDatabase URL.
     * @dev Can only be called by the gateway manager.
     * @param newUrl New offChainDatabase URL.
     */
    function setOffChainDatabaseUrl(string calldata newUrl) external onlyGatewayManager {
        _setOffChainDatabaseUrl(newUrl);
    }

    /**
     * @notice Set the offChainDatabase Timeout Duration.
     * @dev Can only be called by the gateway manager.
     * @param newDuration New offChainDatabase timout duration.
     */
    function setOffChainDatabaseTimoutDuration(uint256 newDuration) external onlyGatewayManager {
        _setOffChainDatabaseTimeoutDuration(newDuration);
    }

    /**
     * @notice Add a set of new signers.
     * @dev Can only be called by the signer manager.
     * @param signersToAdd Signer addresses.
     */
    function addSigners(address[] calldata signersToAdd)
        external
        onlySignerManager
    {
        _addSigners(signersToAdd);
    }

    /**
     * @notice Remove a set of existing signers.
     * @dev Can only be called by the signer manager.
     * @param signersToRemove Signer addresses.
     */
    function removeSigners(address[] calldata signersToRemove)
        external
        onlySignerManager
    {
        ResolverStateHelper.ResolverState storage state_ = ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO);

        uint256 length = signersToRemove.length;
        for (uint256 i = 0; i < length; i++) {
            address signer = signersToRemove[i];
            if (state_.signers.remove(signer)) {
                emit SignerRemoved(signer);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the gateway URL.
     * @return Gateway URL.
     */
    function gatewayUrl() external view returns (string memory) {
        return ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO).gatewayUrl;
    }

    /**
     * @notice Returns the off-chain database URL.
     * @return OffChainDatabase URL.
     */
    function offChainDatabaseUrl() external view returns (string memory) {
        return ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO).offChainDatabaseUrl;
    }

    /**
     * @notice Returns a list of signers.
     * @return List of signers.
     */
    function signers() external view returns (address[] memory) {
        return ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO).signers.values();
    }

    /**
     * @notice Returns whether a given account is a signer.
     * @return True if a given account is a signer.
     */
    function isSigner(address account) external view returns (bool) {
        return ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO).signers.contains(account);
    }

    /**
     * @notice Generates a hash for signing and verifying the offchain response.
     * @param expires Time at which the signature expires.
     * @param request Request data.
     * @param result Result data.
     * @return Hashed data for signing and verifying.
     */
    function makeSignatureHash(
        uint64 expires,
        bytes calldata request,
        bytes calldata result
    ) external view returns (bytes32) {
        return
            SignatureVerifierUpgradeable.makeSignatureHash(
                address(this),
                expires,
                request,
                result
            );
    }

    /*//////////////////////////////////////////////////////////////
                          PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the new gateway URL and emits a GatewayUrlSet event.
     * @param newUrl New URL to be set.
     */
    function _setGatewayUrl(string memory newUrl) private {
        ResolverStateHelper.ResolverState storage state_ = ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO);

        string memory previousUrl = state_.gatewayUrl;
        state_.gatewayUrl = newUrl;

        emit GatewayUrlSet(previousUrl, newUrl);
    }

    /**
     * @notice Sets the new off-chain database URL and emits an OffChainDatabaseUrlSet event.
     * @param newUrl New URL to be set.
     */
    function _setOffChainDatabaseUrl(string memory newUrl) private {
        ResolverStateHelper.ResolverState storage state_ = ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO);

        string memory previousUrl = state_.offChainDatabaseUrl;
        state_.offChainDatabaseUrl = newUrl;
        
        emit OffChainDatabaseHandlerURLChanged(previousUrl, newUrl);
    }

    /**
     * @notice Sets the new off-chain database timout duration and emits an OffChainDatabaseTimeoutDurationSet event.
     * @param newDuration New timout duration to be set.
     */
    function _setOffChainDatabaseTimeoutDuration(uint256 newDuration) private {
        if (newDuration < 60) revert TimeoutDurationTooShort();
        if (newDuration > 600) revert TimeoutDurationTooLong();

        ResolverStateHelper.ResolverState storage state_ = ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO);

        uint256 previousDuration = state_.offChainDatabaseTimeoutDuration;
        state_.offChainDatabaseTimeoutDuration = newDuration;
        
        emit OffChainDatabaseTimeoutDurationSet(previousDuration, newDuration);
    }

    /**
     * @notice Adds new signers and emits a SignersAdded event.
     * @param signersToAdd List of addresses to add as signers.
     */
    function _addSigners(address[] memory signersToAdd) private {
        ResolverStateHelper.ResolverState storage state_ = ResolverStateHelper.getResolverState(RESOLVER_STATE_SLO);

        uint256 length = signersToAdd.length;
        for (uint256 i = 0; i < length; i++) {
            address signer = signersToAdd[i];
            if (state_.signers.add(signer)) {
                emit SignerAdded(signer);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                                UTILS 
    //////////////////////////////////////////////////////////////*/

    function addressToBytes(address a) internal pure returns(bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }

    /*//////////////////////////////////////////////////////////////
                               ERC-165 
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Support ERC-165 introspection.
     * @param interfaceID Interface ID.
     * @return True if a given interface ID is supported.
     */
    function supportsInterface(bytes4 interfaceID)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceID == type(IExtendedResolver).interfaceId ||
            
            interfaceID == type(IAddrResolver).interfaceId || 
            interfaceID == type(IABIResolver).interfaceId ||
            interfaceID == type(IPubkeyResolver).interfaceId ||
            interfaceID == type(ITextResolver).interfaceId ||
            interfaceID == type(INameResolver).interfaceId ||
            interfaceID == type(IContentHashResolver).interfaceId ||
            interfaceID == type(IAddressResolver).interfaceId ||
            
            super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the legacy (ETH-only) addr function.
 */
interface IAddrResolver {
    event AddrChanged(bytes32 indexed node, address a);

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) external view returns (address payable);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface INameResolver {
    event NameChanged(bytes32 indexed node, string name);

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IABIResolver.sol";
import "../ResolverBase.sol";

interface IABIResolver {
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IPubkeyResolver {
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x The X coordinate of the curve point for the public key.
     * @return y The Y coordinate of the curve point for the public key.
     */
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ITextResolver {
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IContentHashResolver {
    event ContenthashChanged(bytes32 indexed node, bytes hash);

    /**
     * Returns the contenthash associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function contenthash(bytes32 node) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the new (multicoin) addr function.
 */
interface IAddressResolver {
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    function addr(bytes32 node, uint coinType) external view returns(bytes memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.13;

interface IERC3668 {
    /**
     * @dev Error to raise when an offchain lookup is required.
     * @param sender Sender address (address of this contract).
     * @param urls URLs to request to perform the offchain lookup.
     * @param callData Call data contains all the data to perform the offchain lookup.
     * @param callbackFunction Callback function that should be called after lookup.
     * @param extraData Optional extra data to send.
     */
    error OffchainLookup(
        address sender,
        string[] urls,
        bytes callData,
        bytes4 callbackFunction,
        bytes extraData
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IExtendedResolver {
    /**
     * @notice Function interface for the ENSIP-10 wildcard resolution function.
     * @param name DNS-encoded name to resolve.
     * @param data ABI-encoded data for the underlying resolution function (e.g. addr(bytes32), text(bytes32,string)).
     */
    function resolve(bytes memory name, bytes memory data)
        external
        view
        returns (bytes memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.13;

interface IWriteDeferral {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Event raised when the default chainId is changed for the corresponding L2 handler.
    event L2HandlerDefaultChainIdChanged(uint256 indexed previousChainId, uint256 indexed newChainId);
    /// @notice Event raised when the contractAddress is changed for the L2 handler corresponding to chainId.
    event L2HandlerContractAddressChanged(uint256 indexed chainId, address indexed previousContractAddress, address indexed newContractAddress);

    /// @notice Event raised when the url is changed for the corresponding Off-Chain Database handler.
    event OffChainDatabaseHandlerURLChanged(string indexed previousUrl, string indexed newUrl);

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Struct used to define the domain of the typed data signature, defined in EIP-712.
     * @param name The user friendly name of the contract that the signature corresponds to.
     * @param version The version of domain object being used.
     * @param chainId The ID of the chain that the signature corresponds to (ie Ethereum mainnet: 1, Goerli testnet: 5, ...). 
     * @param verifyingContract The address of the contract that the signature pertains to.
     */
    struct domainData {
        string name;
        string version;
        uint64 chainId;
        address verifyingContract;
    }    

    /**
     * @notice Struct used to define the message context used to construct a typed data signature, defined in EIP-712, 
     * to authorize and define the deferred mutation being performed.
     * @param functionSelector The function selector of the corresponding mutation.
     * @param sender The address of the user performing the mutation (msg.sender).
     * @param parameter[] A list of <key, value> pairs defining the inputs used to perform the deferred mutation.
     */
    struct messageData {
        bytes4 functionSelector;
        address sender;
        parameter[] parameters;
        uint256 expirationTimestamp;
    }

    /**
     * @notice Struct used to define a parameter for off-chain Database Handler deferral.
     * @param name The variable name of the parameter.
     * @param value The string encoded value representation of the parameter.
     */
    struct parameter {
        string name;
        string value;
    }


    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Error to raise when mutations are being deferred to an L2.
     * @param chainId Chain ID to perform the deferred mutation to.
     * @param contractAddress Contract Address at which the deferred mutation should transact with.
     */
    error StorageHandledByL2(
        uint256 chainId, 
        address contractAddress
    );

    /**
     * @dev Error to raise when mutations are being deferred to an Off-Chain Database.
     * @param sender the EIP-712 domain definition of the corresponding contract performing the off-chain database, write 
     * deferral reversion.
     * @param url URL to request to perform the off-chain mutation.
     * @param data the EIP-712 message signing data context used to authorize and instruct the mutation deferred to the 
     * off-chain database handler. 
     * In order to authorize the deferred mutation to be performed, the user must use the domain definition (sender) and message data 
     * (data) to construct a type data signature request defined in EIP-712. This signature, message data (data), and domainData (sender) 
     * are then included in the HTTP POST request, denoted sender, data, and signature.
     * 
     * Example HTTP POST request:
     *  {
     *      "sender": <abi encoded domainData (sender)>,
     *      "data": <abi encoded message data (data)>,
     *      "signature": <EIP-712 typed data signature of corresponding message data & domain definition>
     *  }
     * 
     */
    error StorageHandledByOffChainDatabase(
        domainData sender, 
        string url, 
        messageData data
    );     
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IResolverService {
    /**
     * @notice Function interface for the lookup function supported by the off-chain gateway.
     * @dev This function is executed off-chain by the off-chain gateway.
     * @param name DNS-encoded name to resolve.
     * @param data ABI-encoded data for the underlying resolution function (e.g. addr(bytes32), text(bytes32,string)).
     * @return result ABI-encode result of the lookup.
     * @return expires Time at which the signature expires.
     * @return sig A signer's signature authenticating the result.
     */
    function resolve(bytes calldata name, bytes calldata data)
        external
        view
        returns (
            bytes memory result,
            uint64 expires,
            bytes memory sig
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

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

// Original source: https://github.com/ensdomains/offchain-resolver/blob/2bc616f19a94370828c35f29f71d5d4cab3a9a4f/packages/contracts/contracts/SignatureVerifier.sol

pragma solidity ^0.8.13;

import { ECDSAUpgradeable } from "openzeppelin/utils/cryptography/ECDSAUpgradeable.sol";

library SignatureVerifierUpgradeable {
    /// @dev Prefix with 0x1900 to prevent the preimage from being a valid ethereum transaction.
    bytes2 private constant _PREIMAGE_PREFIX = 0x1900;

    /**
     * @dev Generates a hash for signing/verifying.
     * @param target The address the signature is for.
     * @param expires Time at which the signature expires.
     * @param request The original request that was sent.
     * @param result The `result` field of the response (not including the signature part).
     * @return Hashed data for signing and verifying.
     */
    function makeSignatureHash(
        address target,
        uint64 expires,
        bytes calldata request,
        bytes memory result
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _PREIMAGE_PREFIX,
                    target,
                    expires,
                    keccak256(request),
                    keccak256(result)
                )
            );
    }

    /**
     * @notice A valid non-expired response can still contain stale data
     * if the offchain data changes during the expiry duration before decoding the response.
     * @dev Verifies a signed message returned from a callback.
     * @param request The original request that was sent.
     * @param response An ABI encoded tuple of `(bytes result, uint64 expires, bytes sig)`, where `result` is the data to return
     *        to the caller, and `sig` is the (r,s,v) encoded message signature.
     * @return signer The address that signed this message.
     * @return result The `result` decoded from `response`.
     */
    function verify(bytes calldata request, bytes calldata response)
        internal
        view
        returns (address, bytes memory)
    {
        (bytes memory result, uint64 expires, bytes memory sig) = abi.decode(
            response,
            (bytes, uint64, bytes)
        );

        bytes32 r;
        bytes32 s;
        uint8 v;
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        /// @solidity memory-safe-assembly
        assembly {
            r := mload(add(sig, 0x20))
            s := mload(add(sig, 0x40))
            v := byte(0, mload(add(sig, 0x60)))
        }

        require(
            expires >= block.timestamp,
            "SignatureVerifier::verify: Signature expired"
        );

        bytes32 sigHash = makeSignatureHash(
            address(this),
            expires,
            request,
            result
        );

        address signer = ECDSAUpgradeable.recover(sigHash, sig);

        return (signer, result);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.13;

import { EnumerableSetUpgradeable } from "openzeppelin/utils/structs/EnumerableSetUpgradeable.sol";

library ResolverStateHelper {
    /**
     * @notice Struct used to define the state variables for the resolver. This is used to ease the 
     * upgradeability process and help prevent against storage conflicts.
     * @param gatewayUrl Gateway URL to use to perform offchain lookup.
     * @param offChainDatabaseUrl Off-Chain Database Write Deferral Resolver URL to handle deferred mutations at.
     * @param offChainDatabaseTimeoutDuration Off-Chain Database Write Deferral Resolver Timeout Duration in seconds for deferred mutations.
     * @param signers Addresses for the set of signers.
     */
    struct ResolverState {
        string  gatewayUrl;
        string  offChainDatabaseUrl;
        uint256 offChainDatabaseTimeoutDuration;

        EnumerableSetUpgradeable.AddressSet signers;
    }

    /**
     * @dev Returns a `ResolverState` with member variables located at `slot`.
     */
    function getResolverState(bytes32 slot) internal pure returns (ResolverState storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

library TypeToString {
    /**
     * @notice Creates a hex based encoded string representation of the specified bytes.
     * @param b The bytes to be encoded.
     * @return _string The encoded string.
     */
    function bytesToString(bytes memory b)
        internal
        pure
        returns (string memory)
    {
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(b.length << 1);

        uint8 b1;
        uint8 b2;
        for (uint256 i = 0; i < b.length; i++) {
            assembly {
                let lb := mload(add(add(b, 0x01), i))
                b1 := and(shr(4, lb), 0x0f)
                b2 := and(lb, 0x0f)
            }

            _string[i * 2] = HEX[b1];
            _string[i * 2 + 1] = HEX[b2];
        }
        return string(abi.encodePacked("0x", _string));
    }

    /**
     * @notice Creates a hex based encoded string representation of the specified bytes4 variable.
     * @param b4 The bytes4 to be encoded.
     * @return _string The encoded string.
     */
    function bytes4ToString(bytes4 b4) internal pure returns (string memory) {
        bytes memory b = new bytes(4);

        assembly {
            mstore(add(b, 32), b4)
        }

        return bytesToString(b);
    }

    /**
     * @notice Creates a hex based encoded string representation of the specified bytes32 variable.
     * @param b32 The bytes32 to be encoded.
     * @return _string The encoded string.
     */
    function bytes32ToString(bytes32 b32) internal pure returns (string memory) {
        bytes memory b = new bytes(32);

        assembly {
            mstore(add(b, 32), b32)
        }

        return bytesToString(b);
    }

    /**
     * @notice Creates a lowercase string representation of the address.
     * @param a The address to be encoded.
     * @return _string The encoded string.
     */
    function addressToString(address a) internal pure returns (string memory) {
        bytes memory b = new bytes(20);

        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }

        return bytesToString(b);
    }

    /**
     * @notice Creates a checksum compliant string representation of the address.
     * @param a The address to be encoded.
     * @return _string The encoded string.
     */
    function addressToCheckSumCompliantString(address a)
        internal
        pure
        returns (string memory)
    {
        string memory str = addressToString(a);

        bytes memory b = new bytes(20);
        uint256 len;
        assembly {
            len := mload(str)

            mstore(add(b, 32), mul(a, exp(256, 12)))
        }

        assert(len == 42);

        assembly {
            mstore(str, 0x28)
            mstore(add(str, 0x20), mload(add(str, 0x22)))
            mstore(add(str, 0x40), shl(16, mload(add(str, 0x40))))
        }

        bytes32 nibblets = keccak256(abi.encodePacked(str));

        bytes memory HEX_LOWER = "0123456789abcdef";
        bytes memory HEX_UPPER = "0123456789ABCDEF";

        bytes memory _string = new bytes(40);

        uint8 b1;
        uint8 b2;
        for (uint8 i = 0; i < 20; i++) {
            assembly {
                let lb := mload(add(add(b, 0x01), i))
                b1 := and(shr(4, lb), 0x0f)
                b2 := and(lb, 0x0f)
            }

            _string[i * 2] = uint8(nibblets[i] >> 4) > 7
                ? HEX_UPPER[b1]
                : HEX_LOWER[b1];
            _string[i * 2 + 1] = uint8(nibblets[i] & 0x0f) > 7
                ? HEX_UPPER[b2]
                : HEX_LOWER[b2];
        }

        return string(abi.encodePacked("0x", _string));
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.13;

import { OwnableUpgradeable } from "openzeppelin/access/OwnableUpgradeable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is a manager account (a signer manager, or a gateway manager) that
 * can be granted exclusive access to specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlySignerManager` and `onlyGatewayManager`, which can be applied to your
 * functions to restrict their use to the signer manager and the gateway
 * manager respectively.
 */
abstract contract ManageableUpgradeable is OwnableUpgradeable {
    /// @dev Address of the signer manager.
    address private _signerManager;
    /// @dev Address of the gateway manager.
    address private _gatewayManager;

    // function initialize() public onlyInitializing {
    //     OwnableUpgradeable.
    // }

    /// @notice Event raised when a signer manager is updated.
    event SignerManagerChanged(
        address indexed previousSignerManager,
        address indexed newSignerManager
    );

    /// @notice Event raised when a gateway manager is updated.
    event GatewayManagerChanged(
        address indexed previousGatewayManager,
        address indexed newGatewayManager
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Managable_init() internal onlyInitializing {
        OwnableUpgradeable.__Ownable_init();
    }

    /**
     * @notice Returns the address of the current signer manager.
     * @return address the signer manager address.
     */
    function signerManager() external view virtual returns (address) {
        return _signerManager;
    }

    /**
     * @notice Returns the address of the current gateway manager.
     * @return address the gateway manager address.
     */
    function gatewayManager() external view virtual returns (address) {
        return _gatewayManager;
    }

    /**
     * @dev Throws if called by any account other than the signer manager.
     */
    modifier onlySignerManager() {
        require(
            _signerManager == _msgSender(),
            "Manageable::onlySignerManager: caller is not signer manager"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the gateway manager.
     */
    modifier onlyGatewayManager() {
        require(
            _gatewayManager == _msgSender(),
            "Manageable::onlyGatewayManager: caller is not gateway manager"
        );
        _;
    }

    /**
     * @notice Change signer manager of the contract to a new account (`newSignerManager`).
     * @dev Can only be called by the current owner.
     * @param newSignerManager the new signer manager address.
     */
    function changeSignerManager(address newSignerManager)
        external
        virtual
        onlyOwner
    {
        require(
            newSignerManager != address(0),
            "Manageable::changeSignerManager: manager is the zero address"
        );
        _changeSignerManager(newSignerManager);
    }

    /**
     * @notice Change gateway manager of the contract to a new account (`newGatewayManager`).
     * @dev Can only be called by the current owner.
     * @param newGatewayManager the new gateway manager address.
     */
    function changeGatewayManager(address newGatewayManager)
        external
        virtual
        onlyOwner
    {
        require(
            newGatewayManager != address(0),
            "Manageable::changeGatewayManager: manager is the zero address"
        );
        _changeGatewayManager(newGatewayManager);
    }

    /**
     * @notice Change signer manager of the contract to a new account (`newSignerManager`).
     * @dev Internal function without access restriction.
     * @param newSignerManager the new signer manager address.
     */
    function _changeSignerManager(address newSignerManager) internal virtual {
        address oldSignerManager = _signerManager;
        _signerManager = newSignerManager;
        emit SignerManagerChanged(oldSignerManager, newSignerManager);
    }

    /**
     * @notice Change gateway manager of the contract to a new account (`newGatewayManager`).
     * @dev Internal function without access restriction.
     * @param newGatewayManager the new gateway manager address.
     */
    function _changeGatewayManager(address newGatewayManager) internal virtual {
        address oldGatewayManager = _gatewayManager;
        _gatewayManager = newGatewayManager;
        emit GatewayManagerChanged(oldGatewayManager, newGatewayManager);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract ResolverBase is ERC165 {
    function isAuthorised(bytes32 node) internal virtual view returns(bool);

    modifier authorised(bytes32 node) {
        require(isAuthorised(node));
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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