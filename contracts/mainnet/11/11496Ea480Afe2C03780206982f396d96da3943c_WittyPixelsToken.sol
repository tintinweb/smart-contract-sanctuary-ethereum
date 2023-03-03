// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppeling's patterns
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

// Witnet compilation dependencies:
import "witnet-solidity-bridge/contracts/UsingWitnet.sol";
import "witnet-solidity-bridge/contracts/apps/WitnetRequestFactory.sol";

// WittyPixels interfaces:
import "./WittyPixelsLib.sol";
import "./interfaces/ITokenVaultFactory.sol";
import "./interfaces/IWittyPixelsToken.sol";
import "./interfaces/IWittyPixelsTokenAdmin.sol";

import "./patterns/WittyPixelsUpgradeableBase.sol";

/// @title  WittyPixels NFT - ERC721 token contract
/// @author Otherplane Labs Ltd., 2022
/// @dev    This contract needs to be proxified.
contract WittyPixelsToken
    is
        ERC721Upgradeable,
        IWittyPixelsToken,
        IWittyPixelsTokenAdmin,
        WittyPixelsUpgradeableBase,
        // Secured by Witnet !!
        UsingWitnet
{
    using ERC165Checker for address;
    using WittyPixelsLib for bytes;
    using WittyPixelsLib for bytes32[];
    using WittyPixelsLib for uint256;
    using WittyPixelsLib for WittyPixels.ERC721Token;
    using WittyPixelsLib for WittyPixels.TokenStorage;

    WitnetRequestTemplate immutable public imageDigestRequestTemplate;
    WitnetRequestTemplate immutable public valuesArrayRequestTemplate;
    
    /// @notice A new token has been fractionalized from this factory.
    event Fractionalized(
        address indexed from,   // owner of the token being fractionalized
        address indexed token,  // token collection address
        uint256 tokenId,        // token id
        address tokenVault      // token vault contract just created
    );
    
    modifier initialized {
        require(
            __proxiable().implementation != address(0),
            "WittyPixelsToken: not initialized"
        );
        _;
    }

    modifier tokenExists(uint256 _tokenId) {
        require(
            _exists(_tokenId),
            "WittyPixelsToken: unknown token"
        );
        _;
    }

    modifier tokenInStatus(uint256 _tokenId, WittyPixels.ERC721TokenStatus _status) {
        require(
            getTokenStatus(_tokenId) == _status,
            "WittyPixelsToken: bad mood"
        );
        _;
    }

    constructor(
            WitnetRequestBoard _witnetRequestBoard,
            WitnetRequestFactory _witnetRequestFactory,
            bool _upgradable,
            bytes32 _version
        )
        UsingWitnet(WitnetRequestBoard(_witnetRequestBoard))
        WittyPixelsUpgradeableBase(
            _upgradable,
            _version,
            "art.wittypixels.token"
        )
    {
        require(
            address(_witnetRequestFactory).supportsInterface(type(IWitnetRequestFactory).interfaceId),
            "WittyPixelsToken: uncompliant WitnetRequestFactory"
        );
        (
            imageDigestRequestTemplate,
            valuesArrayRequestTemplate
        ) = WittyPixelsLib.buildHttpRequestTemplates(_witnetRequestFactory);
    }


    // ================================================================================================================
    // --- Overrides IERC165 interface --------------------------------------------------------------------------------

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 _interfaceId)
      public view
      virtual override
      onlyDelegateCalls
      returns (bool)
    {
        return _interfaceId == type(ITokenVaultFactory).interfaceId
            || _interfaceId == type(IWittyPixelsToken).interfaceId
            || ERC721Upgradeable.supportsInterface(_interfaceId)
            || _interfaceId == type(Ownable2StepUpgradeable).interfaceId
            || _interfaceId == type(Upgradeable).interfaceId
            || _interfaceId == type(IWittyPixelsTokenAdmin).interfaceId
        ;
    }


    // ================================================================================================================
    // --- Overrides 'Upgradeable' ------------------------------------------------------------------------------------

    /// Initialize storage-context when invoked as delegatecall. 
    /// @dev Must fail when trying to initialize same instance more than once.
    function initialize(bytes memory _initdata) 
        public
        virtual override
        onlyDelegateCalls // => we don't want the logic base contract to be ever initialized
    {
        if (__proxiable().proxy == address(0)) {
            // a proxy is being initilized for the first time ...
            __initializeProxy(_initdata);
        }
        else {
            // a proxy is being upgraded ...
            // only the proxy's owner can upgrade it
            require(
                msg.sender == owner(),
                "WittyPixelsToken: not the owner"
            );
            // the implementation cannot be upgraded more than once, though
            require(
                __proxiable().implementation != base(),
                "WittyPixelsToken: already initialized"
            );
            emit Upgraded(msg.sender, base(), codehash(), version());
        }
        __proxiable().implementation = base();
    }

    
    // ================================================================================================================
    // --- Overrides 'ERC721TokenMetadata' overriden functions --------------------------------------------------------

    function tokenURI(uint256 _tokenId)
        public view
        virtual override
        tokenExists(_tokenId)
        returns (string memory)
    {
        return WittyPixelsLib.tokenMetadataURI(_tokenId, __wpx721().items[_tokenId].baseURI);
    }


    // ================================================================================================================
    // --- Based on 'ITokenVaultFactory' ------------------------------------------------------------------------------

    /// @notice Fractionalize next token in collection by transferring ownership to new instance
    /// @notice of the ERC721 Token Vault prototype contract. 
    /// @dev Token must be in 'Minting' status and involved Witnet requests successfully solved.
    /// @dev Once Witnet requests involved in minting process are solved, anyone may proceed withç
    /// @dev fractionalization of next token. Curatorship of the vault will be transferred to the owner, though.
    /// @param _tokenVaultSalt Salt to be used when deterministically cloning current token vault prototype.
    /// @param _tokenVaultSettings Extra settings to be passed when initializing the token vault contract.
    function fractionalize(
            bytes32 _tokenVaultSalt,
            bytes memory _tokenVaultSettings
        )
        virtual external
        onlyOwner
        tokenInStatus(
            __wpx721().totalSupply + 1,
            WittyPixels.ERC721TokenStatus.Minting
        )
        returns (ITokenVault _tokenVault)
    {
        uint256 _tokenId = __wpx721().totalSupply + 1;

        // Check there's a token vault prototype set:
        require(
            address(__wpx721().tokenVaultPrototype) != address(0),
            "WittyPixelsToken: no token vault prototype"
        );

        // Try to deserialize results to http/data queries, as provied from Witnet,
        // and update token's metadata storage:
        try __wpx721().fetchWitnetResults(witnet, _tokenId) {
            // Upon success, clone the token vault prototype 
            // that will fractioanlized the minted token:
            {
                string memory _tokenVaultName = string(abi.encodePacked(
                    name(),
                    bytes(" #"),
                    _tokenId.toString()
                ));
                bytes memory _tokenVaultInitData = abi.encode(
                    WittyPixels.TokenVaultInitParams({
                        curator: owner(),
                        name: _tokenVaultName,
                        symbol: symbol(),
                        settings: _tokenVaultSettings,
                        token: address(this),
                        tokenId: _tokenId,
                        tokenPixels: __wpx721().items[_tokenId].theStats.canvasPixels
                    })
                );
                _tokenVault = ITokenVault(address(
                    __wpx721().tokenVaultPrototype.cloneDeterministicAndInitialize(
                        _tokenVaultSalt,
                        _tokenVaultInitData
                    )
                ));
            }
        }
        catch Error(string memory _reason) {
            revert(
                string(abi.encodePacked(
                    "WittyPixelsToken: ",
                    bytes(_reason)
                ))
            );
        }
        catch {
            revert("WittyPixelsToken: unable to read http/results");
        }

        // Store token vault contract:
        __wpx721().vaults[_tokenId] = IWittyPixelsTokenVault(address(_tokenVault));
        __wpx721().totalTokenVaults ++;

        // Mint the actual ERC-721 token and set the just created vault contract as first owner ever:
        _mint(address(_tokenVault), _tokenId);
        
        // Increment total supply:
        __wpx721().totalSupply ++;

        // Emits event
        emit Fractionalized(msg.sender, address(this), _tokenId, address(_tokenVault));
    }

    /// @notice Returns token vault prototype being instantiated when fractionalizing. 
    /// @dev If destructible, it must be owned by this contract.
    function getTokenVaultFactoryPrototype()
        external view
        returns (ITokenVault)
    {
        return ITokenVault(__wpx721().tokenVaultPrototype);
    }


    // ================================================================================================================
    // --- Implementation of 'IWittyPixelsToken' ----------------------------------------------------------------------

    /// @notice Returns base URI to be used by upcoming tokens of this collection.
    function baseURI()
        override public view
        initialized
        returns (string memory)
    {
        return __wpx721().baseURI;
    }

    /// @notice Returns image URI of given token.
    function imageURI(uint256 _tokenId)
        override external view 
        initialized
        returns (string memory)
    {
        WittyPixels.ERC721TokenStatus _tokenStatus = getTokenStatus(_tokenId);
        if (_tokenStatus == WittyPixels.ERC721TokenStatus.Void) {
            return string(hex"");
        } else {
            return WittyPixelsLib.tokenImageURI(
                _tokenId,
                _tokenStatus == WittyPixels.ERC721TokenStatus.Launching
                    ? baseURI()
                    : __wpx721().items[_tokenId].baseURI
            );
        }
    }

    /// @notice Serialize token ERC721Token to JSON string.
    function metadata(uint256 _tokenId)
        external view override
        tokenExists(_tokenId)
        returns (string memory)
    {
        IWittyPixelsTokenVault _tokenVault = __wpx721().vaults[_tokenId];
        IWittyPixelsTokenVault.Stats memory _dynamicMetadata = _tokenVault.getStats();
        return __wpx721().items[_tokenId].toJSON(
            _tokenId,
            address(_tokenVault),
            _dynamicMetadata.redeemedPixels,
            _dynamicMetadata.ethSoFarDonated
        );
    }

    /// @notice Returns WittyPixels token charity metadata of given token.
    function getTokenCharityValues(uint256 _tokenId)
        override external view
        initialized
        returns (address, uint8)
    {
        return (
            __wpx721().items[_tokenId].theCharity.wallet,
            __wpx721().items[_tokenId].theCharity.percentage
        );
    }

    function setTokenCharityDescription(uint256 _tokenId, string memory _description)
        external
        onlyOwner
    {
        __wpx721().items[_tokenId].theCharity.description = _description;
    }

    /// @notice Returns WittyPixels token metadata of given token.
    function getTokenMetadata(uint256 _tokenId)
        override external view
        initialized
        returns (WittyPixels.ERC721Token memory)
    {
        return __wpx721().items[_tokenId];
    }

    /// @notice Returns status of given WittyPixels token.
    /// @dev Possible values:
    /// @dev - 0 => Unknown, not yet launched
    /// @dev - 1 => Launched: info about the corresponding WittyPixels events has been provided by the collection's owner
    /// @dev - 2 => Minting: the token is being minted, awaiting for external data to be retrieved by the Witnet Oracle.
    /// @dev - 3 => Fracionalized: the token has been minted and its ownership transfered to a WittyPixelsTokenVault contract.
    /// @dev - 4 => Acquired: token's ownership has been acquired and belongs to the WittyPixelsTokenVault no more. 
    function getTokenStatus(uint256 _tokenId)
        override public view
        initialized
        returns (WittyPixels.ERC721TokenStatus)
    {
        if (_tokenId <= __wpx721().totalSupply) {
            IWittyPixelsTokenVault _tokenVault = __wpx721().vaults[_tokenId];
            if (
                address(_tokenVault) != address(0)
                    && ownerOf(_tokenId) != address(__wpx721().vaults[_tokenId])
            ) {
                return WittyPixels.ERC721TokenStatus.Acquired;
            } else {
                return WittyPixels.ERC721TokenStatus.Fractionalized;
            }
        } else {
            WittyPixels.ERC721Token storage __token = __wpx721().items[_tokenId];
            if (__token.birthTs > 0) {
                return WittyPixels.ERC721TokenStatus.Minting;
            } else if (bytes(__token.theEvent.name).length > 0) {
                return WittyPixels.ERC721TokenStatus.Launching;
            } else {
                return WittyPixels.ERC721TokenStatus.Void;
            }
        }
    }

    /// @notice Returns literal string representing current status of given WittyPixels token.    
    function getTokenStatusString(uint256 _tokenId)
        override external view
        initialized
        returns (string memory)
    {
        WittyPixels.ERC721TokenStatus _status = getTokenStatus(_tokenId);
        if (_status == WittyPixels.ERC721TokenStatus.Acquired) {
            return "Acquired";
        } else if (_status == WittyPixels.ERC721TokenStatus.Fractionalized) {
            return "Fractionalized";
        } else if (_status == WittyPixels.ERC721TokenStatus.Minting) {
            return "Minting";
        } else if (_status == WittyPixels.ERC721TokenStatus.Launching) {
            return "Launching";
        } else {
            return "Void";
        }
    }
    
    /// @notice Returns WittyPixelsTokenVault instance bound to the given token.
    /// @dev Reverts if the token has not yet been fractionalized.
    function getTokenVault(uint256 _tokenId)
        public view
        override
        tokenExists(_tokenId)
        returns (ITokenVaultWitnet)
    {
        return __wpx721().vaults[_tokenId];
    }

    /// @notice Returns Identifiers of Witnet queries involved in the minting of given token.
    /// @dev Returns zero addresses if the token is yet in 'Unknown' or 'Launched' status.
    function getTokenWitnetQueries(uint256 _tokenId)
        virtual override
        public view
        initialized
        returns (WittyPixels.ERC721TokenWitnetQueries memory)
    {
        return __wpx721().tokenWitnetQueries[_tokenId];
    }

    /// @notice Returns Witnet data requests involved in the the minting of given token.
    /// @dev Returns zero addresses if the token is yet in 'Unknown' or 'Launched' status.
    function getTokenWitnetRequests(uint256 _tokenId)
        virtual override
        external view
        initialized
        returns (WittyPixels.ERC721TokenWitnetRequests memory)

    {
        return __wpx721().tokenWitnetRequests[_tokenId];
    }

    /// @notice Returns number of pixels within the WittyPixels Canvas of given token.
    function pixelsOf(uint256 _tokenId)
        virtual override
        external view
        initialized
        returns (uint256)
    {
        return __wpx721().items[_tokenId].theStats.totalPixels;
    }

    /// @notice Returns number of pixels contributed to given WittyPixels Canvas by given address.
    /// @dev Every WittyPixels player needs to claim contribution to a WittyPixels Canvas by calling 
    /// @dev to the `redeem(bytes deeds)` method on the corresponding token's vault contract.
    function pixelsFrom(uint256 _tokenId, address _from)
        virtual override
        external view
        initialized
        returns (uint256)
    {
        IWittyPixelsTokenVault _vault = IWittyPixelsTokenVault(address(getTokenVault(_tokenId)));
        return (address(_vault) != address(0)
            ? _vault.pixelsOf(_from)
            : 0
        );
    }

    /// @notice Emits MetadataUpdate event as specified by EIP-4906.
    /// @dev Only acceptable if called from token's vault and given token is 'Fractionalized' status.
    function updateMetadataFromTokenVault(uint256 _tokenId)
        virtual override
        external
        initialized
    {
        require(
            _tokenId <= __wpx721().totalSupply,
            "WittyPixelsToken: unknown token"
        );
        require(
            msg.sender == address(__wpx721().vaults[_tokenId]),
            "WittyPixelsToken: not the token's vault"
        );
        emit MetadataUpdate(_tokenId);
    }

    /// @notice Count NFTs tracked by this contract.
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///         them has an assigned and queryable owner not equal to the zero address
    function totalSupply()
        external view
        override
        returns (uint256)
    {
        return __wpx721().totalSupply;
    }

    /// @notice Verifies the provided Merkle Proof matches the token's authorship's root that
    /// @notice was retrieved by the Witnet Oracle upon minting of given token. 
    /// @dev Reverts if the token has not yet been fractionalized.
    function verifyTokenAuthorship(
            uint256 _tokenId,
            uint256 _playerIndex,
            uint256 _playerPixels,
            bytes32[] memory _proof
        )
        external view
        override
        tokenExists(_tokenId)
        returns (bool)
    {
        WittyPixels.ERC721Token storage __token = __wpx721().items[_tokenId];
        return (
            _proof.merkle(keccak256(abi.encode(
                _playerIndex,
                _playerPixels
            ))) == __token.theStats.canvasRoot
        );
    }


    // ================================================================================================================
    // --- Implementation of 'IWittyPixelsTokenAdmin' -----------------------------------------------------------------

    /// @notice Settle next token's event related metadata.
    /// @param _theEvent Event metadata, including name, venut, starting and ending timestamps.
    /// @param _theCharity Charity metadata, if any. Charity address and percentage > 0 must be provided.
    function launch(
            WittyPixels.ERC721TokenEvent calldata _theEvent,
            WittyPixels.ERC721TokenCharity calldata _theCharity
        )
        override external
        onlyOwner
        returns (uint256 _tokenId)
    {
        _tokenId = __wpx721().totalSupply + 1;
        WittyPixels.ERC721TokenStatus _status = getTokenStatus(_tokenId);
        require(
            _status == WittyPixels.ERC721TokenStatus.Void
                || _status == WittyPixels.ERC721TokenStatus.Launching,
            "WittyPixelsToken: bad mood"
        );
        // Check the event data:
        require(
            bytes(_theEvent.name).length > 0
                && bytes(_theEvent.venue).length > 0,
            "WittyPixelsToken: event empty strings"
        );
        require(
            _theEvent.startTs <= _theEvent.endTs,
            "WittyPixelsToken: event bad timestamps"
        );
        // Save token's event data:
        __wpx721().items[_tokenId].theEvent = _theEvent;
        // Save token's charity data, if any:
        if (_theCharity.wallet != address(0)) {
            require(
                _theCharity.wallet.code.length == 0,
                "WittyPixelsToken: charity wallet not an EOA"
            );
            require(
                _theCharity.percentage > 0 && _theCharity.percentage <= 100,
                "WittyPixelsToken: bad charity percentage"
            );
            require(
                bytes(_theCharity.description).length > 0,
                "WittyPixelsToken: no charity description"
            );
            __wpx721().items[_tokenId].theCharity = _theCharity;
        }
    }
    
    /// @notice Mint next WittyPixelsTM token: one new token id per ERC721TokenEvent where WittyPixelsTM is played.
    /// @param _witnetSLA Witnessing SLA parameters of underlying data requests to be solved by the Witnet oracle.
    function mint(WitnetV2.RadonSLA calldata _witnetSLA)
        override external payable
        onlyOwner
        nonReentrant
    {
        uint256 _tokenId = __wpx721().totalSupply + 1;
        string memory _baseuri = __wpx721().baseURI;

        WittyPixels.ERC721TokenStatus _status = getTokenStatus(_tokenId);
        require(
            _status == WittyPixels.ERC721TokenStatus.Launching
                || _status == WittyPixels.ERC721TokenStatus.Minting,
            "WittyPixelsToken: bad mood"
        );        
        WittyPixels.ERC721Token storage __token = __wpx721().items[_tokenId];
        require(
            block.timestamp >= __token.theEvent.endTs,
            "WittyPixelsToken: the event is not over yet"
        );

        WittyPixels.ERC721TokenWitnetQueries storage __witnetQueries = __wpx721().tokenWitnetQueries[_tokenId];
        if (__witnetQueries.imageDigestId > 0) {
            // Revert if both queries from previous minting attempt were not yet solved
            if (
                !_witnetCheckResultAvailability(__witnetQueries.imageDigestId)
                    && !_witnetCheckResultAvailability(__witnetQueries.tokenStatsId)
            ) {
                revert("WittyPixelsToken: awaiting Witnet responses");
            }
        } else {
            // Settle witnet requests only on the first minting attempt:
            string[][] memory _args = new string[][](1);
            _args[0] = new string[](2);
            _args[0][0] = _baseuri;
            _args[0][1] = _tokenId.toString();
            __wpx721().tokenWitnetRequests[_tokenId] = WittyPixels.ERC721TokenWitnetRequests({
                imageDigest: imageDigestRequestTemplate.settleArgs(_args),
                tokenStats: valuesArrayRequestTemplate.settleArgs(_args)
            });
        }
        
        uint _totalUsedFunds;
        WittyPixels.ERC721TokenWitnetRequests storage __witnetRequests = __wpx721().tokenWitnetRequests[_tokenId];
        {
            // Ask Witnet to confirm the token's image URI actually exists:
            (__witnetQueries.imageDigestId, _totalUsedFunds) = _witnetPostRequest(
                __witnetRequests.imageDigest.modifySLA(_witnetSLA)
            );
        }
        {
            uint _usedFunds;
            // Ask Witnet to retrieve token's metadata stats from the token base uri provider:            
            (__witnetQueries.tokenStatsId, _usedFunds) = _witnetPostRequest(
                __witnetRequests.tokenStats.modifySLA(_witnetSLA)
            );
            _totalUsedFunds += _usedFunds;
        }

        // Set the token's base uri, inception timestamp 
        // and the token stats' audit history radHash from Witnet:
        __token.baseURI = _baseuri;
        __token.birthTs = block.timestamp;
        __token.tokenStatsWitnetRadHash = __witnetRequests.tokenStats.radHash();

        // Transfer back unused funds, if any:
        if (_totalUsedFunds < msg.value) {
            payable(msg.sender).transfer(msg.value - _totalUsedFunds);
        }
        
        // Emit event:
        emit Minting(_tokenId, _baseuri, _witnetSLA);
    }

    /// @notice Sets collection's base URI.
    function setBaseURI(string calldata _uri)
        external 
        override
        onlyOwner 
    {
        __setBaseURI(_uri);
    }

    /// @notice Sets token vault contract to be used as prototype in following mints.
    function setTokenVaultFactoryPrototype(address _prototype)
        external
        override
        onlyOwner
    {
        _verifyPrototypeCompliance(_prototype);
        __wpx721().tokenVaultPrototype = IWittyPixelsTokenVault(_prototype);
    }


    // ================================================================================================================
    // --- Internal virtual methods -----------------------------------------------------------------------------------

    function __initializeProxy(bytes memory _initdata)
        virtual internal
        initializer 
    {
        // As for OpenZeppelin's ERC721Upgradeable implementation,
        // name and symbol can only be initialized once;
        // as for an upgradable (and proxiable) contract as this one,
        // the setting of name and symbol needs to be invoked in
        // a dedicated and unique 'initializer' method, other from the
        // `initialize(bytes)` method that gets called every time
        // a proxy contract is upgraded.

        // read and set ERC721 initialization parameters
        WittyPixels.TokenInitParams memory _params = abi.decode(
            _initdata,
            (WittyPixels.TokenInitParams)
        );
        __ERC721_init(
            _params.name,
            _params.symbol
        );        
        __Ownable2Step_init();
        __ReentrancyGuard_init();
        __proxiable().proxy = address(this);
        __proxiable().implementation = base();
        __setBaseURI(_params.baseURI);
    }

    function __setBaseURI(string memory _baseuri)
        virtual internal
    {
        __wpx721().baseURI = WittyPixelsLib.checkBaseURI(_baseuri);
    }

    function _verifyPrototypeCompliance(address _prototype)
        virtual
        internal view
    {
        require(
            _prototype.supportsInterface(type(IWittyPixelsTokenVault).interfaceId),
            "WittyPixelsToken: uncompliant prototype"
        );
    }

    function __wpx721()
        internal pure
        returns (WittyPixels.TokenStorage storage ptr)
    {
        bytes32 slothash = WittyPixels.WPX_TOKEN_SLOTHASH;
        assembly {
            ptr.slot := slothash
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./WitnetRequest.sol";
import "../libs/WitnetV2.sol";

abstract contract WitnetRequestTemplate
{
    event WitnetRequestTemplateSettled(WitnetRequest indexed request, bytes32 indexed radHash, string[][] args);

    function class() virtual external view returns (bytes4);
    function getDataSources() virtual external view returns (bytes32[] memory);
    function getDataSourcesCount() virtual external view returns (uint256);    
    function getRadonAggregatorHash() virtual external view returns (bytes32);
    function getRadonTallyHash() virtual external view returns (bytes32);
    function getResultDataMaxSize() virtual external view returns (uint16);
    function getResultDataType() virtual external view returns (WitnetV2.RadonDataTypes);
    function lookupDataSourceByIndex(uint256) virtual external view returns (WitnetV2.DataSource memory);
    function lookupRadonAggregator() virtual external view returns (WitnetV2.RadonReducer memory);
    function lookupRadonTally() virtual external view returns (WitnetV2.RadonReducer memory);
    function parameterized() virtual external view returns (bool);
    function settleArgs(string[][] calldata args) virtual external returns (WitnetRequest);
    function version() virtual external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./WitnetRequestTemplate.sol";
import "../libs/WitnetV2.sol";

abstract contract WitnetRequest
    is
        IWitnetRequest
{
    event WitnetRequestSettled(WitnetV2.RadonSLA sla);

    function args() virtual external view returns (string[][] memory);
    function class() virtual external view returns (bytes4);
    function curator() virtual external view returns (address);
    function getRadonSLA() virtual external view returns (WitnetV2.RadonSLA memory);
    function initialized() virtual external view returns (bool);
    function modifySLA(WitnetV2.RadonSLA calldata sla) virtual external returns (IWitnetRequest);
    function radHash() virtual external view returns (bytes32);
    function slaHash() virtual external view returns (bytes32);
    function template() virtual external view returns (WitnetRequestTemplate);
    function version() virtual external view returns (string memory);
}

// SPDX-License-Identifier: MIT

/* solhint-disable var-name-mixedcase */

pragma solidity >=0.6.0 <0.9.0;

import "./Initializable.sol";
import "./Proxiable.sol";

abstract contract Upgradeable is Initializable, Proxiable {

    address internal immutable _BASE;
    bytes32 internal immutable _CODEHASH;
    bool internal immutable _UPGRADABLE;

    modifier onlyDelegateCalls virtual {
        require(
            address(this) != _BASE,
            "Upgradeable: not a delegate call"
        );
        _;
    }

    /// Emitted every time the contract gets upgraded.
    /// @param from The address who ordered the upgrading. Namely, the WRB operator in "trustable" implementations.
    /// @param baseAddr The address of the new implementation contract.
    /// @param baseCodehash The EVM-codehash of the new implementation contract.
    /// @param versionTag Ascii-encoded version literal with which the implementation deployer decided to tag it.
    event Upgraded(
        address indexed from,
        address indexed baseAddr,
        bytes32 indexed baseCodehash,
        string  versionTag
    );

    constructor (bool _isUpgradable) {
        address _base = address(this);
        bytes32 _codehash;        
        assembly {
            _codehash := extcodehash(_base)
        }
        _BASE = _base;
        _CODEHASH = _codehash;
        _UPGRADABLE = _isUpgradable;
    }

    /// @dev Retrieves base contract. Differs from address(this) when called via delegate-proxy pattern.
    function base() public view returns (address) {
        return _BASE;
    }

    /// @dev Retrieves the immutable codehash of this contract, even if invoked as delegatecall.
    function codehash() public view returns (bytes32) {
        return _CODEHASH;
    }

    /// @dev Determines whether the logic of this contract is potentially upgradable.
    function isUpgradable() public view returns (bool) {
        return _UPGRADABLE;
    }

    /// @dev Tells whether provided address could eventually upgrade the contract.
    function isUpgradableFrom(address from) virtual external view returns (bool);

    /// @notice Re-initialize contract's storage context upon a new upgrade from a proxy.    
    /// @dev Must fail when trying to upgrade to same logic contract more than once.
    function initialize(bytes memory) virtual external;

    /// @dev Retrieves human-redable named version of current implementation.
    function version() virtual public view returns (string memory); 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

abstract contract Proxiable {
    /// @dev Complying with EIP-1822: Universal Upgradeable Proxy Standard (UUPS)
    /// @dev See https://eips.ethereum.org/EIPS/eip-1822.
    function proxiableUUID() virtual external view returns (bytes32);

    struct ProxiableSlot {
        address implementation;
        address proxy;
    }

    function __implementation() internal view returns (address) {
        return __proxiable().implementation;
    }

    function __proxy() internal view returns (address) {
        return __proxiable().proxy;
    }

    function __proxiable() internal pure returns (ProxiableSlot storage proxiable) {
        assembly {
            // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
            proxiable.slot := 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable2Step.sol";

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./Initializable.sol";

abstract contract Clonable
    is
        Initializable
{
    address immutable internal _SELF = address(this);

    event Cloned(address indexed by, address indexed self, address indexed clone);

    modifier onlyDelegateCalls virtual {
        require(address(this) != _SELF, "Clonable: not a delegate call");
        _;
    }

    modifier wasInitialized {
        require(initialized(), "Clonable: not initialized");
        _;
    }

    /// @notice Tells whether this contract is a clone of `self()`
    function cloned()
        public view
        returns (bool)
    {
        return (
            address(this) != self()
        );
    }

    /// @notice Tells whether this instance has been initialized.
    function initialized() virtual public view returns (bool);

    /// @notice Contract address to which clones will be re-directed.
    function self() virtual public view returns (address) {
        return _SELF;
    }

    /// Deploys and returns the address of a minimal proxy clone that replicates contract
    /// behaviour while using its own EVM storage.
    /// @dev This function should always provide a new address, no matter how many times 
    /// @dev is actually called from the same `msg.sender`.
    /// @dev See https://eips.ethereum.org/EIPS/eip-1167.
    /// @dev See https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/.
    function _clone()
        internal
        returns (address _instance)
    {
        bytes memory ptr = _cloneBytecodePtr();
        assembly {
            // CREATE new instance:
            _instance := create(0, ptr, 0x37)
        }        
        require(_instance != address(0), "Clonable: CREATE failed");
        emit Cloned(msg.sender, self(), _instance);
    }

    /// @notice Returns minimal proxy's deploy bytecode.
    function _cloneBytecode()
        virtual internal view
        returns (bytes memory)
    {
        return abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            bytes20(self()),
            hex"5af43d82803e903d91602b57fd5bf3"
        );
    }

    /// @notice Returns mem pointer to minimal proxy's deploy bytecode.
    function _cloneBytecodePtr()
        virtual internal view
        returns (bytes memory ptr)
    {
        address _base = self();
        assembly {
            // ptr to free mem:
            ptr := mload(0x40)
            // begin minimal proxy construction bytecode:
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            // make minimal proxy delegate all calls to `self()`:
            mstore(add(ptr, 0x14), shl(0x60, _base))
            // end minimal proxy construction bytecode:
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
        }
    }

    /// Deploys and returns the address of a minimal proxy clone that replicates contract 
    /// behaviour while using its own EVM storage.
    /// @dev This function uses the CREATE2 opcode and a `_salt` to deterministically deploy
    /// @dev the clone. Using the same `_salt` multiple times will revert, since
    /// @dev no contract can be deployed more than once at the same address.
    /// @dev See https://eips.ethereum.org/EIPS/eip-1167.
    /// @dev See https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/.
    function _cloneDeterministic(bytes32 _salt)
        internal
        returns (address _instance)
    {
        bytes memory ptr = _cloneBytecodePtr();
        assembly {
            // CREATE2 new instance:
            _instance := create2(0, ptr, 0x37, _salt)
        }
        require(_instance != address(0), "Clonable: CREATE2 failed");
        emit Cloned(msg.sender, self(), _instance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./Witnet.sol";

library WitnetV2 {

    error IndexOutOfBounds(uint256 index, uint256 range);
    error InsufficientBalance(uint256 weiBalance, uint256 weiExpected);
    error InsufficientFee(uint256 weiProvided, uint256 weiExpected);
    error Unauthorized(address violator);

    error RadonFilterMissingArgs(uint8 opcode);

    error RadonRequestNoSources();
    error RadonRequestSourcesArgsMismatch(uint expected, uint actual);
    error RadonRequestMissingArgs(uint index, uint expected, uint actual);
    error RadonRequestResultsMismatch(uint index, uint8 read, uint8 expected);
    error RadonRequestTooHeavy(bytes bytecode, uint weight);

    error RadonSlaNoReward();
    error RadonSlaNoWitnesses();
    error RadonSlaTooManyWitnesses(uint256 numWitnesses);
    error RadonSlaConsensusOutOfRange(uint256 percentage);
    error RadonSlaLowCollateral(uint256 witnessCollateral);

    error UnsupportedDataRequestMethod(uint8 method, string schema, string body, string[2][] headers);
    error UnsupportedRadonDataType(uint8 datatype, uint256 maxlength);
    error UnsupportedRadonFilterOpcode(uint8 opcode);
    error UnsupportedRadonFilterArgs(uint8 opcode, bytes args);
    error UnsupportedRadonReducerOpcode(uint8 opcode);
    error UnsupportedRadonReducerScript(uint8 opcode, bytes script, uint256 offset);
    error UnsupportedRadonScript(bytes script, uint256 offset);
    error UnsupportedRadonScriptOpcode(bytes script, uint256 cursor, uint8 opcode);
    error UnsupportedRadonTallyScript(bytes32 hash);

    function toEpoch(uint _timestamp) internal pure returns (uint) {
        return 1 + (_timestamp - 11111) / 15;
    }

    function toTimestamp(uint _epoch) internal pure returns (uint) {
        return 111111+ _epoch * 15;
    }

    struct Beacon {
        uint256 escrow;
        uint256 evmBlock;
        uint256 gasprice;
        address relayer;
        address slasher;
        uint256 superblockIndex;
        uint256 superblockRoot;        
    }

    enum BeaconStatus {
        Idle
    }

    struct Block {
        bytes32 blockHash;
        bytes32 drTxsRoot;
        bytes32 drTallyTxsRoot;
    }
    
    enum BlockStatus {
        Idle
    }

    struct DrPost {
        uint256 block;
        DrPostStatus status;
        DrPostRequest request;
        DrPostResponse response;
    }
    
    /// Data kept in EVM-storage for every Request posted to the Witnet Request Board.
    struct DrPostRequest {
        uint256 epoch;
        address requester;
        address reporter;
        bytes32 radHash;
        bytes32 slaHash;
        uint256 weiReward;
    }

    /// Data kept in EVM-storage containing Witnet-provided response metadata and result.
    struct DrPostResponse {
        address disputer;
        address reporter;
        uint256 escrowed;
        uint256 drCommitTxEpoch;
        uint256 drTallyTxEpoch;
        bytes32 drTallyTxHash;
        bytes   drTallyResultCborBytes;
    }

    enum DrPostStatus {
        Void,
        Deleted,
        Expired,
        Posted,
        Disputed,
        Reported,
        Finalized,
        Accepted,
        Rejected
    }

    struct DataProvider {
        string  authority;
        uint256 totalSources;
        mapping (uint256 => bytes32) sources;
    }

    enum DataRequestMethods {
        /* 0 */ Unknown,
        /* 1 */ HttpGet,
        /* 2 */ Rng,
        /* 3 */ HttpPost
    }

    struct DataSource {
        uint8 argsCount;
        DataRequestMethods method;
        RadonDataTypes resultDataType;
        string url;
        string body;
        string[2][] headers;
        bytes script;
    }

    enum RadonDataTypes {
        /* 0x00 */ Any, 
        /* 0x01 */ Array,
        /* 0x02 */ Bool,
        /* 0x03 */ Bytes,
        /* 0x04 */ Integer,
        /* 0x05 */ Float,
        /* 0x06 */ Map,
        /* 0x07 */ String,
        Unused0x08, Unused0x09, Unused0x0A, Unused0x0B,
        Unused0x0C, Unused0x0D, Unused0x0E, Unused0x0F,
        /* 0x10 */ Same,
        /* 0x11 */ Inner,
        /* 0x12 */ Match,
        /* 0x13 */ Subscript
    }

    struct RadonFilter {
        RadonFilterOpcodes opcode;
        bytes args;
    }

    enum RadonFilterOpcodes {
        /* 0x00 */ GreaterThan,
        /* 0x01 */ LessThan,
        /* 0x02 */ Equals,
        /* 0x03 */ AbsoluteDeviation,
        /* 0x04 */ RelativeDeviation,
        /* 0x05 */ StandardDeviation,
        /* 0x06 */ Top,
        /* 0x07 */ Bottom,
        /* 0x08 */ Mode,
        /* 0x09 */ LessOrEqualThan
    }

    struct RadonReducer {
        RadonReducerOpcodes opcode;
        RadonFilter[] filters;
        bytes script;
    }

    enum RadonReducerOpcodes {
        /* 0x00 */ Minimum,
        /* 0x01 */ Maximum,
        /* 0x02 */ Mode,
        /* 0x03 */ AverageMean,
        /* 0x04 */ AverageMeanWeighted,
        /* 0x05 */ AverageMedian,
        /* 0x06 */ AverageMedianWeighted,
        /* 0x07 */ StandardDeviation,
        /* 0x08 */ AverageDeviation,
        /* 0x09 */ MedianDeviation,
        /* 0x0A */ MaximumDeviation,
        /* 0x0B */ ConcatenateAndHash
    }

    struct RadonSLA {
        uint numWitnesses;
        uint minConsensusPercentage;
        uint witnessReward;
        uint witnessCollateral;
        uint minerCommitFee;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./WitnetV2.sol";

/// @title A library for decoding Witnet request results
/// @notice The library exposes functions to check the Witnet request success.
/// and retrieve Witnet results from CBOR values into solidity types.
/// @author The Witnet Foundation.
library WitnetLib {

    using WitnetBuffer for WitnetBuffer.Buffer;
    using WitnetCBOR for WitnetCBOR.CBOR;
    using WitnetCBOR for WitnetCBOR.CBOR[];
    using WitnetLib for bytes;

    
    /// ===============================================================================================================
    /// --- WitnetLib internal methods --------------------------------------------------------------------------------

    /// @notice Decode raw CBOR bytes into a Witnet.Result instance.
    /// @param bytecode Raw bytes representing a CBOR-encoded value.
    /// @return A `Witnet.Result` instance.
    function resultFromCborBytes(bytes memory bytecode)
        internal pure
        returns (Witnet.Result memory)
    {
        WitnetCBOR.CBOR memory cborValue = WitnetCBOR.fromBytes(bytecode);
        return _resultFromCborValue(cborValue);
    }

    function toAddress(bytes memory _value) internal pure returns (address) {
        return address(toBytes20(_value));
    }

    function toBytes4(bytes memory _value) internal pure returns (bytes4) {
        return bytes4(toFixedBytes(_value, 4));
    }
    
    function toBytes20(bytes memory _value) internal pure returns (bytes20) {
        return bytes20(toFixedBytes(_value, 20));
    }
    
    function toBytes32(bytes memory _value) internal pure returns (bytes32) {
        return toFixedBytes(_value, 32);
    }

    function toFixedBytes(bytes memory _value, uint8 _numBytes)
        internal pure
        returns (bytes32 _bytes32)
    {
        assert(_numBytes <= 32);
        unchecked {
            uint _len = _value.length > _numBytes ? _numBytes : _value.length;
            for (uint _i = 0; _i < _len; _i ++) {
                _bytes32 |= bytes32(_value[_i] & 0xff) >> (_i * 8);
            }
        }
    }

    function toLowerCase(string memory str)
        internal pure
        returns (string memory)
    {
        bytes memory lowered = new bytes(bytes(str).length);
        unchecked {
            for (uint i = 0; i < lowered.length; i ++) {
                uint8 char = uint8(bytes(str)[i]);
                if (char >= 65 && char <= 90) {
                    lowered[i] = bytes1(char + 32);
                } else {
                    lowered[i] = bytes1(char);
                }
            }
        }
        return string(lowered);
    }

    /// @notice Convert a `uint64` into a 2 characters long `string` representing its two less significant hexadecimal values.
    /// @param _u A `uint64` value.
    /// @return The `string` representing its hexadecimal value.
    function toHexString(uint8 _u)
        internal pure
        returns (string memory)
    {
        bytes memory b2 = new bytes(2);
        uint8 d0 = uint8(_u / 16) + 48;
        uint8 d1 = uint8(_u % 16) + 48;
        if (d0 > 57)
            d0 += 7;
        if (d1 > 57)
            d1 += 7;
        b2[0] = bytes1(d0);
        b2[1] = bytes1(d1);
        return string(b2);
    }

    /// @notice Convert a `uint64` into a 1, 2 or 3 characters long `string` representing its.
    /// three less significant decimal values.
    /// @param _u A `uint64` value.
    /// @return The `string` representing its decimal value.
    function toString(uint8 _u)
        internal pure
        returns (string memory)
    {
        if (_u < 10) {
            bytes memory b1 = new bytes(1);
            b1[0] = bytes1(uint8(_u) + 48);
            return string(b1);
        } else if (_u < 100) {
            bytes memory b2 = new bytes(2);
            b2[0] = bytes1(uint8(_u / 10) + 48);
            b2[1] = bytes1(uint8(_u % 10) + 48);
            return string(b2);
        } else {
            bytes memory b3 = new bytes(3);
            b3[0] = bytes1(uint8(_u / 100) + 48);
            b3[1] = bytes1(uint8(_u % 100 / 10) + 48);
            b3[2] = bytes1(uint8(_u % 10) + 48);
            return string(b3);
        }
    }

    function tryUint(string memory str)
        internal pure
        returns (uint res, bool)
    {
        unchecked {
            for (uint256 i = 0; i < bytes(str).length; i++) {
                if (
                    (uint8(bytes(str)[i]) - 48) < 0
                        || (uint8(bytes(str)[i]) - 48) > 9
                ) {
                    return (0, false);
                }
                res += (uint8(bytes(str)[i]) - 48) * 10 ** (bytes(str).length - i - 1);
            }
            return (res, true);
        }   
    }

    /// @notice Returns true if Witnet.Result contains an error.
    /// @param result An instance of Witnet.Result.
    /// @return `true` if errored, `false` if successful.
    function failed(Witnet.Result memory result)
      internal pure
      returns (bool)
    {
        return !result.success;
    }

    /// @notice Returns true if Witnet.Result contains valid result.
    /// @param result An instance of Witnet.Result.
    /// @return `true` if errored, `false` if successful.
    function succeeded(Witnet.Result memory result)
      internal pure
      returns (bool)
    {
        return result.success;
    }

    /// ===============================================================================================================
    /// --- WitnetLib private methods ---------------------------------------------------------------------------------

    /// @notice Decode an errored `Witnet.Result` as a `uint[]`.
    /// @param result An instance of `Witnet.Result`.
    /// @return The `uint[]` error parameters as decoded from the `Witnet.Result`.
    function _errorsFromResult(Witnet.Result memory result)
        private pure
        returns(uint[] memory)
    {
        require(
            failed(result),
            "WitnetLib: no actual error"
        );
        return result.value.readUintArray();
    }

    /// @notice Decode a CBOR value into a Witnet.Result instance.
    /// @param cbor An instance of `Witnet.Value`.
    /// @return A `Witnet.Result` instance.
    function _resultFromCborValue(WitnetCBOR.CBOR memory cbor)
        private pure
        returns (Witnet.Result memory)    
    {
        // Witnet uses CBOR tag 39 to represent RADON error code identifiers.
        // [CBOR tag 39] Identifiers for CBOR: https://github.com/lucas-clemente/cbor-specs/blob/master/id.md
        bool success = cbor.tag != 39;
        return Witnet.Result(success, cbor);
    }

    /// @notice Convert a stage index number into the name of the matching Witnet request stage.
    /// @param stageIndex A `uint64` identifying the index of one of the Witnet request stages.
    /// @return The name of the matching stage.
    function _stageName(uint64 stageIndex)
        private pure
        returns (string memory)
    {
        if (stageIndex == 0) {
            return "retrieval";
        } else if (stageIndex == 1) {
            return "aggregation";
        } else if (stageIndex == 2) {
            return "tally";
        } else {
            return "unknown";
        }
    }


    /// ===============================================================================================================
    /// --- WitnetLib public methods (if used library will have to linked to calling contracts) -----------------------

    function asAddress(Witnet.Result memory result)
        public pure
        returns (address)
    {
        require(
            result.success,
            "WitnetLib: tried to read `address` from errored result."
        );
        if (result.value.majorType == uint8(WitnetCBOR.MAJOR_TYPE_BYTES)) {
            return result.value.readBytes().toAddress();
        } else {
            revert("WitnetLib: reading address from string not yet supported.");
        }
    }

    /// @notice Decode a boolean value from a Witnet.Result as an `bool` value.
    /// @param result An instance of Witnet.Result.
    /// @return The `bool` decoded from the Witnet.Result.
    function asBool(Witnet.Result memory result)
        public pure
        returns (bool)
    {
        require(
            result.success,
            "WitnetLib: tried to read `bool` value from errored result."
        );
        return result.value.readBool();
    }

    /// @notice Decode a bytes value from a Witnet.Result as a `bytes` value.
    /// @param result An instance of Witnet.Result.
    /// @return The `bytes` decoded from the Witnet.Result.
    function asBytes(Witnet.Result memory result)
        public pure
        returns(bytes memory)
    {
        require(
            result.success,
            "WitnetLib: Tried to read bytes value from errored Witnet.Result"
        );
        return result.value.readBytes();
    }

    function asBytes4(Witnet.Result memory result)
        public pure
        returns (bytes4)
    {
        return asBytes(result).toBytes4();
    }

    /// @notice Decode a bytes value from a Witnet.Result as a `bytes32` value.
    /// @param result An instance of Witnet.Result.
    /// @return The `bytes32` decoded from the Witnet.Result.
    function asBytes32(Witnet.Result memory result)
        public pure
        returns (bytes32)
    {
        return asBytes(result).toBytes32();
    }

    /// @notice Decode an error code from a Witnet.Result as a member of `Witnet.ErrorCodes`.
    /// @param result An instance of `Witnet.Result`.
    function asErrorCode(Witnet.Result memory result)
        public pure
        returns (Witnet.ErrorCodes)
    {
        uint[] memory errors = _errorsFromResult(result);
        if (errors.length == 0) {
            return Witnet.ErrorCodes.Unknown;
        } else {
            return Witnet.ErrorCodes(errors[0]);
        }
    }

    /// @notice Generate a suitable error message for a member of `Witnet.ErrorCodes` and its corresponding arguments.
    /// @dev WARN: Note that client contracts should wrap this function into a try-catch foreseing potential errors generated in this function
    /// @param result An instance of `Witnet.Result`.
    /// @return errorCode Decoded error code.
    /// @return errorString Decoded error message.
    function asErrorMessage(Witnet.Result memory result)
        public pure
        returns (
            Witnet.ErrorCodes errorCode,
            string memory errorString
        )
    {
        uint[] memory errors = _errorsFromResult(result);
        if (errors.length == 0) {
            return (
                Witnet.ErrorCodes.Unknown,
                "Unknown error: no error code."
            );
        }
        else {
            errorCode = Witnet.ErrorCodes(errors[0]);
        }
        if (
            errorCode == Witnet.ErrorCodes.SourceScriptNotCBOR
                && errors.length >= 2
        ) {
            errorString = string(abi.encodePacked(
                "Source script #",
                toString(uint8(errors[1])),
                " was not a valid CBOR value"
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.SourceScriptNotArray
                && errors.length >= 2
        ) {
            errorString = string(abi.encodePacked(
                "The CBOR value in script #",
                toString(uint8(errors[1])),
                " was not an Array of calls"
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.SourceScriptNotRADON
                && errors.length >= 2
        ) {
            errorString = string(abi.encodePacked(
                "The CBOR value in script #",
                toString(uint8(errors[1])),
                " was not a valid Data Request"
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.RequestTooManySources
                && errors.length >= 2
        ) {
            errorString = string(abi.encodePacked(
                "The request contained too many sources (", 
                toString(uint8(errors[1])), 
                ")"
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.ScriptTooManyCalls
                && errors.length >= 4
        ) {
            errorString = string(abi.encodePacked(
                "Script #",
                toString(uint8(errors[2])),
                " from the ",
                _stageName(uint8(errors[1])),
                " stage contained too many calls (",
                toString(uint8(errors[3])),
                ")"
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.UnsupportedOperator
                && errors.length >= 5
        ) {
            errorString = string(abi.encodePacked(
                "Operator code 0x",
                toHexString(uint8(errors[4])),
                " found at call #",
                toString(uint8(errors[3])),
                " in script #",
                toString(uint8(errors[2])),
                " from ",
                _stageName(uint8(errors[1])),
                " stage is not supported"
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.HTTP
                && errors.length >= 3
        ) {
            errorString = string(abi.encodePacked(
                "Source #",
                toString(uint8(errors[1])),
                " could not be retrieved. Failed with HTTP error code: ",
                toString(uint8(errors[2] / 100)),
                toString(uint8(errors[2] % 100 / 10)),
                toString(uint8(errors[2] % 10))
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.RetrievalTimeout
                && errors.length >= 2
        ) {
            errorString = string(abi.encodePacked(
                "Source #",
                toString(uint8(errors[1])),
                " could not be retrieved because of a timeout"
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.Underflow
                && errors.length >= 5
        ) {
            errorString = string(abi.encodePacked(
                "Underflow at operator code 0x",
                toHexString(uint8(errors[4])),
                " found at call #",
                toString(uint8(errors[3])),
                " in script #",
                toString(uint8(errors[2])),
                " from ",
                _stageName(uint8(errors[1])),
                " stage"
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.Overflow
                && errors.length >= 5
        ) {
            errorString = string(abi.encodePacked(
                "Overflow at operator code 0x",
                toHexString(uint8(errors[4])),
                " found at call #",
                toString(uint8(errors[3])),
                " in script #",
                toString(uint8(errors[2])),
                " from ",
                _stageName(uint8(errors[1])),
                " stage"
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.DivisionByZero
                && errors.length >= 5
        ) {
            errorString = string(abi.encodePacked(
                "Division by zero at operator code 0x",
                toHexString(uint8(errors[4])),
                " found at call #",
                toString(uint8(errors[3])),
                " in script #",
                toString(uint8(errors[2])),
                " from ",
                _stageName(uint8(errors[1])),
                " stage"
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.BridgeMalformedRequest
        ) {
            errorString = "The structure of the request is invalid and it cannot be parsed";
        } else if (
            errorCode == Witnet.ErrorCodes.BridgePoorIncentives
        ) {
            errorString = "The request has been rejected by the bridge node due to poor incentives";
        } else if (
            errorCode == Witnet.ErrorCodes.BridgeOversizedResult
        ) {
            errorString = "The request result length exceeds a bridge contract defined limit";
        } else {
            errorString = string(abi.encodePacked(
                "Unknown error (0x",
                toHexString(uint8(errors[0])),
                ")"
            ));
        }
        return (
            errorCode,
            errorString
        );
    }

    /// @notice Decode a fixed16 (half-precision) numeric value from a Witnet.Result as an `int32` value.
    /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values.
    /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`.
    /// use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
    /// @param result An instance of Witnet.Result.
    /// @return The `int128` decoded from the Witnet.Result.
    function asFixed16(Witnet.Result memory result)
        public pure
        returns (int32)
    {
        require(
            result.success,
            "WitnetLib: tried to read `fixed16` value from errored result."
        );
        return result.value.readFloat16();
    }

    /// @notice Decode an array of fixed16 values from a Witnet.Result as an `int32[]` array.
    /// @param result An instance of Witnet.Result.
    /// @return The `int128[]` decoded from the Witnet.Result.
    function asFixed16Array(Witnet.Result memory result)
        public pure
        returns (int32[] memory)
    {
        require(
            result.success,
            "WitnetLib: tried to read `fixed16[]` value from errored result."
        );
        return result.value.readFloat16Array();
    }

    /// @notice Decode a integer numeric value from a Witnet.Result as an `int128` value.
    /// @param result An instance of Witnet.Result.
    /// @return The `int` decoded from the Witnet.Result.
    function asInt(Witnet.Result memory result)
      public pure
      returns (int)
    {
        require(
            result.success,
            "WitnetLib: tried to read `int` value from errored result."
        );
        return result.value.readInt();
    }

    /// @notice Decode an array of integer numeric values from a Witnet.Result as an `int[]` array.
    /// @param result An instance of Witnet.Result.
    /// @return The `int[]` decoded from the Witnet.Result.
    function asIntArray(Witnet.Result memory result)
        public pure
        returns (int[] memory)
    {
        require(
            result.success,
            "WitnetLib: tried to read `int[]` value from errored result."
        );
        return result.value.readIntArray();
    }

    /// @notice Decode a string value from a Witnet.Result as a `string` value.
    /// @param result An instance of Witnet.Result.
    /// @return The `string` decoded from the Witnet.Result.
    function asString(Witnet.Result memory result)
        public pure
        returns(string memory)
    {
        require(
            result.success,
            "WitnetLib: tried to read `string` value from errored result."
        );
        return result.value.readString();
    }

    /// @notice Decode an array of string values from a Witnet.Result as a `string[]` value.
    /// @param result An instance of Witnet.Result.
    /// @return The `string[]` decoded from the Witnet.Result.
    function asStringArray(Witnet.Result memory result)
        public pure
        returns (string[] memory)
    {
        require(
            result.success,
            "WitnetLib: tried to read `string[]` value from errored result.");
        return result.value.readStringArray();
    }

    /// @notice Decode a natural numeric value from a Witnet.Result as a `uint` value.
    /// @param result An instance of Witnet.Result.
    /// @return The `uint` decoded from the Witnet.Result.
    function asUint(Witnet.Result memory result)
        public pure
        returns(uint)
    {
        require(
            result.success,
            "WitnetLib: tried to read `uint64` value from errored result"
        );
        return result.value.readUint();
    }

    /// @notice Decode an array of natural numeric values from a Witnet.Result as a `uint[]` value.
    /// @param result An instance of Witnet.Result.
    /// @return The `uint[]` decoded from the Witnet.Result.
    function asUintArray(Witnet.Result memory result)
        public pure
        returns (uint[] memory)
    {
        require(
            result.success,
            "WitnetLib: tried to read `uint[]` value from errored result."
        );
        return result.value.readUintArray();
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./WitnetBuffer.sol";

/// @title A minimalistic implementation of “RFC 7049 Concise Binary Object Representation”
/// @notice This library leverages a buffer-like structure for step-by-step decoding of bytes so as to minimize
/// the gas cost of decoding them into a useful native type.
/// @dev Most of the logic has been borrowed from Patrick Gansterer’s cbor.js library: https://github.com/paroga/cbor-js
/// @author The Witnet Foundation.
/// 
/// TODO: add support for Map (majorType = 5)
/// TODO: add support for Float32 (majorType = 7, additionalInformation = 26)
/// TODO: add support for Float64 (majorType = 7, additionalInformation = 27) 

library WitnetCBOR {

  using WitnetBuffer for WitnetBuffer.Buffer;
  using WitnetCBOR for WitnetCBOR.CBOR;

  /// Data struct following the RFC-7049 standard: Concise Binary Object Representation.
  struct CBOR {
      WitnetBuffer.Buffer buffer;
      uint8 initialByte;
      uint8 majorType;
      uint8 additionalInformation;
      uint64 len;
      uint64 tag;
  }

  uint8 internal constant MAJOR_TYPE_INT = 0;
  uint8 internal constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 internal constant MAJOR_TYPE_BYTES = 2;
  uint8 internal constant MAJOR_TYPE_STRING = 3;
  uint8 internal constant MAJOR_TYPE_ARRAY = 4;
  uint8 internal constant MAJOR_TYPE_MAP = 5;
  uint8 internal constant MAJOR_TYPE_TAG = 6;
  uint8 internal constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint32 internal constant UINT32_MAX = type(uint32).max;
  uint64 internal constant UINT64_MAX = type(uint64).max;
  
  error EmptyArray();
  error InvalidLengthEncoding(uint length);
  error UnexpectedMajorType(uint read, uint expected);
  error UnsupportedPrimitive(uint primitive);
  error UnsupportedMajorType(uint unexpected);  

  modifier isMajorType(
      WitnetCBOR.CBOR memory cbor,
      uint8 expected
  ) {
    if (cbor.majorType != expected) {
      revert UnexpectedMajorType(cbor.majorType, expected);
    }
    _;
  }

  modifier notEmpty(WitnetBuffer.Buffer memory buffer) {
    if (buffer.data.length == 0) {
      revert WitnetBuffer.EmptyBuffer();
    }
    _;
  }

  function eof(CBOR memory cbor)
    internal pure
    returns (bool)
  {
    return cbor.buffer.cursor >= cbor.buffer.data.length;
  }

  /// @notice Decode a CBOR structure from raw bytes.
  /// @dev This is the main factory for CBOR instances, which can be later decoded into native EVM types.
  /// @param bytecode Raw bytes representing a CBOR-encoded value.
  /// @return A `CBOR` instance containing a partially decoded value.
  function fromBytes(bytes memory bytecode)
    internal pure
    returns (CBOR memory)
  {
    WitnetBuffer.Buffer memory buffer = WitnetBuffer.Buffer(bytecode, 0);
    return fromBuffer(buffer);
  }

  /// @notice Decode a CBOR structure from raw bytes.
  /// @dev This is an alternate factory for CBOR instances, which can be later decoded into native EVM types.
  /// @param buffer A Buffer structure representing a CBOR-encoded value.
  /// @return A `CBOR` instance containing a partially decoded value.
  function fromBuffer(WitnetBuffer.Buffer memory buffer)
    internal pure
    notEmpty(buffer)
    returns (CBOR memory)
  {
    uint8 initialByte;
    uint8 majorType = 255;
    uint8 additionalInformation;
    uint64 tag = UINT64_MAX;
    uint256 len;
    bool isTagged = true;
    while (isTagged) {
      // Extract basic CBOR properties from input bytes
      initialByte = buffer.readUint8();
      len ++;
      majorType = initialByte >> 5;
      additionalInformation = initialByte & 0x1f;
      // Early CBOR tag parsing.
      if (majorType == MAJOR_TYPE_TAG) {
        uint _cursor = buffer.cursor;
        tag = readLength(buffer, additionalInformation);
        len += buffer.cursor - _cursor;
      } else {
        isTagged = false;
      }
    }
    if (majorType > MAJOR_TYPE_CONTENT_FREE) {
      revert UnsupportedMajorType(majorType);
    }
    return CBOR(
      buffer,
      initialByte,
      majorType,
      additionalInformation,
      uint64(len),
      tag
    );
  }

  function fork(WitnetCBOR.CBOR memory self)
    internal pure
    returns (WitnetCBOR.CBOR memory)
  {
    return CBOR({
      buffer: self.buffer.fork(),
      initialByte: self.initialByte,
      majorType: self.majorType,
      additionalInformation: self.additionalInformation,
      len: self.len,
      tag: self.tag
    });
  }

  function settle(CBOR memory self)
      internal pure
      returns (WitnetCBOR.CBOR memory)
  {
    if (!self.eof()) {
      return fromBuffer(self.buffer);
    } else {
      return self;
    }
  }

  function skip(CBOR memory self)
      internal pure
      returns (WitnetCBOR.CBOR memory)
  {
    if (
      self.majorType == MAJOR_TYPE_INT
        || self.majorType == MAJOR_TYPE_NEGATIVE_INT
    ) {
      self.buffer.cursor += self.peekLength();
    } else if (
        self.majorType == MAJOR_TYPE_STRING
          || self.majorType == MAJOR_TYPE_BYTES
    ) {
      uint64 len = readLength(self.buffer, self.additionalInformation);
      self.buffer.cursor += len;
    } else if (
      self.majorType == MAJOR_TYPE_ARRAY
    ) { 
      self.len = readLength(self.buffer, self.additionalInformation);      
    // } else if (
    //   self.majorType == MAJOR_TYPE_CONTENT_FREE
    // ) {
      // TODO
    } else {
      revert UnsupportedMajorType(self.majorType);
    }
    return self;
  }

  function peekLength(CBOR memory self)
    internal pure
    returns (uint64)
  {
    assert(1 << 0 == 1);
    if (self.additionalInformation < 24) {
      return self.additionalInformation;
    } else if (self.additionalInformation > 27) {
      revert InvalidLengthEncoding(self.additionalInformation);
    } else {
      return uint64(1 << (self.additionalInformation - 24));
    }
  }

  // event Array(uint cursor, uint items);
  // event Log2(uint index, bytes data, uint cursor, uint major, uint addinfo, uint len);
  function readArray(CBOR memory self)
    internal pure
    isMajorType(self, MAJOR_TYPE_ARRAY)
    returns (CBOR[] memory items)
  {
    uint64 len = readLength(self.buffer, self.additionalInformation);
    // emit Array(self.buffer.cursor, len);
    items = new CBOR[](len + 1);
    for (uint ix = 0; ix < len; ix ++) {
      items[ix] = self.fork().settle();
      // emit Log2(
      //   ix,
      //   items[ix].buffer.data,
      //   items[ix].buffer.cursor,
      //   items[ix].majorType,
      //   items[ix].additionalInformation,
      //   items[ix].len
      // );
      self.buffer.cursor = items[ix].buffer.cursor;
      self.majorType = items[ix].majorType;
      self.additionalInformation = items[ix].additionalInformation;
      self.len = items[ix].len;
      if (self.majorType == MAJOR_TYPE_ARRAY) {
        CBOR[] memory subitems = self.readArray();
        self = subitems[subitems.length - 1];
      } else {
        self.skip();
      }
    }
    items[len] = self;
  }

  /// Reads the length of the settle CBOR item from a buffer, consuming a different number of bytes depending on the
  /// value of the `additionalInformation` argument.
  function readLength(
      WitnetBuffer.Buffer memory buffer,
      uint8 additionalInformation
    ) 
    internal pure
    returns (uint64)
  {
    if (additionalInformation < 24) {
      return additionalInformation;
    }
    if (additionalInformation == 24) {
      return buffer.readUint8();
    }
    if (additionalInformation == 25) {
      return buffer.readUint16();
    }
    if (additionalInformation == 26) {
      return buffer.readUint32();
    }
    if (additionalInformation == 27) {
      return buffer.readUint64();
    }
    if (additionalInformation == 31) {
      return UINT64_MAX;
    }
    revert InvalidLengthEncoding(additionalInformation);
  }

  /// @notice Read a `CBOR` structure into a native `bool` value.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as a `bool` value.
  function readBool(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_CONTENT_FREE)
    returns (bool)
  {
    if (cbor.additionalInformation == 20) {
      return false;
    } else if (cbor.additionalInformation == 21) {
      return true;
    } else {
      revert UnsupportedPrimitive(cbor.additionalInformation);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `bytes` value.
  /// @param cbor An instance of `CBOR`.
  /// @return output The value represented by the input, as a `bytes` value.   
  function readBytes(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_BYTES)
    returns (bytes memory output)
  {
    cbor.len = readLength(
      cbor.buffer,
      cbor.additionalInformation
    );
    if (cbor.len == UINT32_MAX) {
      // These checks look repetitive but the equivalent loop would be more expensive.
      uint32 length = uint32(_readIndefiniteStringLength(
        cbor.buffer,
        cbor.majorType
      ));
      if (length < UINT32_MAX) {
        output = abi.encodePacked(cbor.buffer.read(length));
        length = uint32(_readIndefiniteStringLength(
          cbor.buffer,
          cbor.majorType
        ));
        if (length < UINT32_MAX) {
          output = abi.encodePacked(
            output,
            cbor.buffer.read(length)
          );
        }
      }
    } else {
      return cbor.buffer.read(uint32(cbor.len));
    }
  }

  /// @notice Decode a `CBOR` structure into a `fixed16` value.
  /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`
  /// use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as an `int128` value.
  function readFloat16(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_CONTENT_FREE)
    returns (int32)
  {
    if (cbor.additionalInformation == 25) {
      return cbor.buffer.readFloat16();
    } else {
      revert UnsupportedPrimitive(cbor.additionalInformation);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `int128[]` value whose inner values follow the same convention 
  /// @notice as explained in `decodeFixed16`.
  /// @param cbor An instance of `CBOR`.
  function readFloat16Array(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_ARRAY)
    returns (int32[] memory values)
  {
    uint64 length = readLength(cbor.buffer, cbor.additionalInformation);
    if (length < UINT64_MAX) {
      values = new int32[](length);
      for (uint64 i = 0; i < length; ) {
        CBOR memory item = fromBuffer(cbor.buffer);
        values[i] = readFloat16(item);
        unchecked {
          i ++;
        }
      }
    } else {
      revert InvalidLengthEncoding(length);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `int128` value.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as an `int128` value.
  function readInt(CBOR memory cbor)
    internal pure
    returns (int)
  {
    if (cbor.majorType == 1) {
      uint64 _value = readLength(
        cbor.buffer,
        cbor.additionalInformation
      );
      return int(-1) - int(uint(_value));
    } else if (cbor.majorType == 0) {
      // Any `uint64` can be safely casted to `int128`, so this method supports majorType 1 as well so as to have offer
      // a uniform API for positive and negative numbers
      return int(readUint(cbor));
    }
    else {
      revert UnexpectedMajorType(cbor.majorType, 1);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `int[]` value.
  /// @param cbor instance of `CBOR`.
  /// @return array The value represented by the input, as an `int[]` value.
  function readIntArray(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_ARRAY)
    returns (int[] memory array)
  {
    uint64 length = readLength(cbor.buffer, cbor.additionalInformation);
    if (length < UINT64_MAX) {
      array = new int[](length);
      for (uint i = 0; i < length; ) {
        CBOR memory item = fromBuffer(cbor.buffer);
        array[i] = readInt(item);
        unchecked {
          i ++;
        }
      }
    } else {
      revert InvalidLengthEncoding(length);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `string` value.
  /// @param cbor An instance of `CBOR`.
  /// @return text The value represented by the input, as a `string` value.
  function readString(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_STRING)
    returns (string memory text)
  {
    cbor.len = readLength(cbor.buffer, cbor.additionalInformation);
    if (cbor.len == UINT64_MAX) {
      bool _done;
      while (!_done) {
        uint64 length = _readIndefiniteStringLength(
          cbor.buffer,
          cbor.majorType
        );
        if (length < UINT64_MAX) {
          text = string(abi.encodePacked(
            text,
            cbor.buffer.readText(length / 4)
          ));
        } else {
          _done = true;
        }
      }
    } else {
      return string(cbor.buffer.readText(cbor.len));
    }
  }

  /// @notice Decode a `CBOR` structure into a native `string[]` value.
  /// @param cbor An instance of `CBOR`.
  /// @return strings The value represented by the input, as an `string[]` value.
  function readStringArray(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_ARRAY)
    returns (string[] memory strings)
  {
    uint length = readLength(cbor.buffer, cbor.additionalInformation);
    if (length < UINT64_MAX) {
      strings = new string[](length);
      for (uint i = 0; i < length; ) {
        CBOR memory item = fromBuffer(cbor.buffer);
        strings[i] = readString(item);
        unchecked {
          i ++;
        }
      }
    } else {
      revert InvalidLengthEncoding(length);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `uint64` value.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as an `uint64` value.
  function readUint(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_INT)
    returns (uint)
  {
    return readLength(
      cbor.buffer,
      cbor.additionalInformation
    );
  }

  /// @notice Decode a `CBOR` structure into a native `uint64[]` value.
  /// @param cbor An instance of `CBOR`.
  /// @return values The value represented by the input, as an `uint64[]` value.
  function readUintArray(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_ARRAY)
    returns (uint[] memory values)
  {
    uint64 length = readLength(cbor.buffer, cbor.additionalInformation);
    if (length < UINT64_MAX) {
      values = new uint[](length);
      for (uint ix = 0; ix < length; ) {
        CBOR memory item = fromBuffer(cbor.buffer);
        values[ix] = readUint(item);
        unchecked {
          ix ++;
        }
      }
    } else {
      revert InvalidLengthEncoding(length);
    }
  }  

  /// Read the length of a CBOR indifinite-length item (arrays, maps, byte strings and text) from a buffer, consuming
  /// as many bytes as specified by the first byte.
  function _readIndefiniteStringLength(
      WitnetBuffer.Buffer memory buffer,
      uint8 majorType
    )
    private pure
    returns (uint64 len)
  {
    uint8 initialByte = buffer.readUint8();
    if (initialByte == 0xff) {
      return UINT64_MAX;
    }
    len = readLength(
      buffer,
      initialByte & 0x1f
    );
    if (len >= UINT64_MAX) {
      revert InvalidLengthEncoding(len);
    } else if (majorType != (initialByte >> 5)) {
      revert UnexpectedMajorType((initialByte >> 5), majorType);
    }
  }
 
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/// @title A convenient wrapper around the `bytes memory` type that exposes a buffer-like interface
/// @notice The buffer has an inner cursor that tracks the final offset of every read, i.e. any subsequent read will
/// start with the byte that goes right after the last one in the previous read.
/// @dev `uint32` is used here for `cursor` because `uint16` would only enable seeking up to 8KB, which could in some
/// theoretical use cases be exceeded. Conversely, `uint32` supports up to 512MB, which cannot credibly be exceeded.
/// @author The Witnet Foundation.
library WitnetBuffer {

  error EmptyBuffer();
  error IndexOutOfBounds(uint index, uint range);
  error MissingArgs(uint expected, uint given);

  /// Iterable bytes buffer.
  struct Buffer {
      bytes data;
      uint cursor;
  }

  // Ensures we access an existing index in an array
  modifier withinRange(uint index, uint _range) {
    if (index >= _range) {
      revert IndexOutOfBounds(index, _range);
    }
    _;
  }

  /// @notice Concatenate undefinite number of bytes chunks.
  /// @dev Faster than looping on `abi.encodePacked(output, _buffs[ix])`.
  function concat(bytes[] memory _buffs)
    internal pure
    returns (bytes memory output)
  {
    unchecked {
      uint destinationPointer;
      uint destinationLength;
      assembly {
        // get safe scratch location
        output := mload(0x40)
        // set starting destination pointer
        destinationPointer := add(output, 32)
      }      
      for (uint ix = 1; ix <= _buffs.length; ix ++) {  
        uint source;
        uint sourceLength;
        uint sourcePointer;        
        assembly {
          // load source length pointer
          source := mload(add(_buffs, mul(ix, 32)))
          // load source length
          sourceLength := mload(source)
          // sets source memory pointer
          sourcePointer := add(source, 32)
        }
        _memcpy(
          destinationPointer,
          sourcePointer,
          sourceLength
        );
        assembly {          
          // increase total destination length
          destinationLength := add(destinationLength, sourceLength)
          // sets destination memory pointer
          destinationPointer := add(destinationPointer, sourceLength)
        }
      }
      assembly {
        // protect output bytes
        mstore(output, destinationLength)
        // set final output length
        mstore(0x40, add(mload(0x40), add(destinationLength, 32)))
      }
    }
  }

  function fork(WitnetBuffer.Buffer memory buffer)
    internal pure
    returns (WitnetBuffer.Buffer memory)
  {
    return Buffer(
      buffer.data,
      buffer.cursor
    );
  }

  function mutate(
      WitnetBuffer.Buffer memory buffer,
      uint length,
      bytes memory pokes
    )
    internal pure
    withinRange(length, buffer.data.length - buffer.cursor)
  {
    bytes[] memory parts = new bytes[](3);
    parts[0] = peek(
      buffer,
      0,
      buffer.cursor
    );
    parts[1] = pokes;
    parts[2] = peek(
      buffer,
      buffer.cursor + length,
      buffer.data.length - buffer.cursor - length
    );
    buffer.data = concat(parts);
  }

  /// @notice Read and consume the next byte from the buffer.
  /// @param buffer An instance of `Buffer`.
  /// @return The next byte in the buffer counting from the cursor position.
  function next(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor, buffer.data.length)
    returns (bytes1)
  {
    // Return the byte at the position marked by the cursor and advance the cursor all at once
    return buffer.data[buffer.cursor ++];
  }

  function peek(
      WitnetBuffer.Buffer memory buffer,
      uint offset,
      uint length
    )
    internal pure
    withinRange(offset + length, buffer.data.length + 1)
    returns (bytes memory)
  {
    bytes memory data = buffer.data;
    bytes memory peeks = new bytes(length);
    uint destinationPointer;
    uint sourcePointer;
    assembly {
      destinationPointer := add(peeks, 32)
      sourcePointer := add(add(data, 32), offset)
    }
    _memcpy(
      destinationPointer,
      sourcePointer,
      length
    );
    return peeks;
  }

  // @notice Extract bytes array from buffer starting from current cursor.
  /// @param buffer An instance of `Buffer`.
  /// @param length How many bytes to peek from the Buffer.
  // solium-disable-next-line security/no-assign-params
  function peek(
      WitnetBuffer.Buffer memory buffer,
      uint length
    )
    internal pure
    withinRange(length, buffer.data.length - buffer.cursor)
    returns (bytes memory)
  {
    return peek(
      buffer,
      buffer.cursor,
      length
    );
  }

  /// @notice Read and consume a certain amount of bytes from the buffer.
  /// @param buffer An instance of `Buffer`.
  /// @param length How many bytes to read and consume from the buffer.
  /// @return output A `bytes memory` containing the first `length` bytes from the buffer, counting from the cursor position.
  function read(Buffer memory buffer, uint length)
    internal pure
    withinRange(buffer.cursor + length, buffer.data.length + 1)
    returns (bytes memory output)
  {
    // Create a new `bytes memory destination` value
    output = new bytes(length);
    // Early return in case that bytes length is 0
    if (length > 0) {
      bytes memory input = buffer.data;
      uint offset = buffer.cursor;
      // Get raw pointers for source and destination
      uint sourcePointer;
      uint destinationPointer;
      assembly {
        sourcePointer := add(add(input, 32), offset)
        destinationPointer := add(output, 32)
      }
      // Copy `length` bytes from source to destination
      _memcpy(
        destinationPointer,
        sourcePointer,
        length
      );
      // Move the cursor forward by `length` bytes
      seek(
        buffer,
        length,
        true
      );
    }
  }
  
  /// @notice Read and consume the next 2 bytes from the buffer as an IEEE 754-2008 floating point number enclosed in an
  /// `int32`.
  /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `float16`
  /// use cases. In other words, the integer output of this method is 10,000 times the actual value. The input bytes are
  /// expected to follow the 16-bit base-2 format (a.k.a. `binary16`) in the IEEE 754-2008 standard.
  /// @param buffer An instance of `Buffer`.
  /// @return result The `int32` value of the next 4 bytes in the buffer counting from the cursor position.
  function readFloat16(Buffer memory buffer)
    internal pure
    returns (int32 result)
  {
    uint32 value = readUint16(buffer);
    // Get bit at position 0
    uint32 sign = value & 0x8000;
    // Get bits 1 to 5, then normalize to the [-14, 15] range so as to counterweight the IEEE 754 exponent bias
    int32 exponent = (int32(value & 0x7c00) >> 10) - 15;
    // Get bits 6 to 15
    int32 significand = int32(value & 0x03ff);
    // Add 1024 to the fraction if the exponent is 0
    if (exponent == 15) {
      significand |= 0x400;
    }
    // Compute `2 ^ exponent · (1 + fraction / 1024)`
    if (exponent >= 0) {
      result = (
        int32((int256(1 << uint256(int256(exponent)))
          * 10000
          * int256(uint256(int256(significand)) | 0x400)) >> 10)
      );
    } else {
      result = (int32(
        ((int256(uint256(int256(significand)) | 0x400) * 10000)
          / int256(1 << uint256(int256(- exponent))))
          >> 10
      ));
    }
    // Make the result negative if the sign bit is not 0
    if (sign != 0) {
      result *= -1;
    }
  }

  // Read a text string of a given length from a buffer. Returns a `bytes memory` value for the sake of genericness,
  /// but it can be easily casted into a string with `string(result)`.
  // solium-disable-next-line security/no-assign-params
  function readText(
      WitnetBuffer.Buffer memory buffer,
      uint64 length
    )
    internal pure
    returns (bytes memory text)
  {
    text = new bytes(length);
    unchecked {
      for (uint64 index = 0; index < length; index ++) {
        uint8 char = readUint8(buffer);
        if (char & 0x80 != 0) {
          if (char < 0xe0) {
            char = (char & 0x1f) << 6
              | (readUint8(buffer) & 0x3f);
            length -= 1;
          } else if (char < 0xf0) {
            char  = (char & 0x0f) << 12
              | (readUint8(buffer) & 0x3f) << 6
              | (readUint8(buffer) & 0x3f);
            length -= 2;
          } else {
            char = (char & 0x0f) << 18
              | (readUint8(buffer) & 0x3f) << 12
              | (readUint8(buffer) & 0x3f) << 6  
              | (readUint8(buffer) & 0x3f);
            length -= 3;
          }
        }
        text[index] = bytes1(char);
      }
      // Adjust text to actual length:
      assembly {
        mstore(text, length)
      }
    }
  }

  /// @notice Read and consume the next byte from the buffer as an `uint8`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint8` value of the next byte in the buffer counting from the cursor position.
  function readUint8(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor, buffer.data.length)
    returns (uint8 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 1), offset))
    }
    buffer.cursor ++;
  }

  /// @notice Read and consume the next 2 bytes from the buffer as an `uint16`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint16` value of the next 2 bytes in the buffer counting from the cursor position.
  function readUint16(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor + 1, buffer.data.length)
    returns (uint16 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 2), offset))
    }
    buffer.cursor += 2;
  }

  /// @notice Read and consume the next 4 bytes from the buffer as an `uint32`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint32` value of the next 4 bytes in the buffer counting from the cursor position.
  function readUint32(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor + 3, buffer.data.length)
    returns (uint32 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 4), offset))
    }
    buffer.cursor += 4;
  }

  /// @notice Read and consume the next 8 bytes from the buffer as an `uint64`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint64` value of the next 8 bytes in the buffer counting from the cursor position.
  function readUint64(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor + 7, buffer.data.length)
    returns (uint64 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 8), offset))
    }
    buffer.cursor += 8;
  }

  /// @notice Read and consume the next 16 bytes from the buffer as an `uint128`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint128` value of the next 16 bytes in the buffer counting from the cursor position.
  function readUint128(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor + 15, buffer.data.length)
    returns (uint128 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 16), offset))
    }
    buffer.cursor += 16;
  }

  /// @notice Read and consume the next 32 bytes from the buffer as an `uint256`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint256` value of the next 32 bytes in the buffer counting from the cursor position.
  function readUint256(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor + 31, buffer.data.length)
    returns (uint256 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 32), offset))
    }
    buffer.cursor += 32;
  }

  /// @notice Count number of required parameters for given bytes arrays
  /// @dev Wildcard format: "\#\", with # in ["0".."9"].
  /// @param input Bytes array containing strings.
  /// @param count Highest wildcard index found, plus 1.
  function argsCountOf(bytes memory input)
    internal pure
    returns (uint8 count)
  {
    if (input.length < 3) {
      return 0;
    }
    unchecked {
      uint ix = 0; 
      uint length = input.length - 2;
      for (; ix < length; ) {
        if (
          input[ix] == bytes1("\\")
            && input[ix + 2] == bytes1("\\")
            && input[ix + 1] >= bytes1("0")
            && input[ix + 1] <= bytes1("9")
        ) {
          uint8 ax = uint8(uint8(input[ix + 1]) - uint8(bytes1("0")) + 1);
          if (ax > count) {
            count = ax;
          }
          ix += 3;
        } else {
          ix ++;
        }
      }
    }
  }

  /// @notice Replace bytecode indexed wildcards by correspondent string.
  /// @dev Wildcard format: "\#\", with # in ["0".."9"].
  /// @param input Bytes array containing strings.
  /// @param args String values for replacing existing indexed wildcards in input.
  function replace(bytes memory input, string[] memory args)
    internal pure
    returns (bytes memory output)
  {
    uint ix = 0; uint lix = 0;
    uint inputLength;
    uint inputPointer;
    uint outputLength;
    uint outputPointer;    
    uint source;
    uint sourceLength;
    uint sourcePointer;

    if (input.length < 3) {
      return input;
    }
    
    assembly {
      // set starting input pointer
      inputPointer := add(input, 32)
      // get safe output location
      output := mload(0x40)
      // set starting output pointer
      outputPointer := add(output, 32)
    }         

    unchecked {
      uint length = input.length - 2;
      for (; ix < length; ) {
        if (
          input[ix] == bytes1("\\")
            && input[ix + 2] == bytes1("\\")
            && input[ix + 1] >= bytes1("0")
            && input[ix + 1] <= bytes1("9")
        ) {
          inputLength = (ix - lix);
          if (ix > lix) {
            _memcpy(
              outputPointer,
              inputPointer,
              inputLength
            );
            inputPointer += inputLength + 3;
            outputPointer += inputLength;
          } else {
            inputPointer += 3;
          }
          uint ax = uint(uint8(input[ix + 1]) - uint8(bytes1("0")));
          if (ax >= args.length) {
            revert MissingArgs(ax + 1, args.length);
          }
          assembly {
            source := mload(add(args, mul(32, add(ax, 1))))
            sourceLength := mload(source)
            sourcePointer := add(source, 32)      
          }        
          _memcpy(
            outputPointer,
            sourcePointer,
            sourceLength
          );
          outputLength += inputLength + sourceLength;
          outputPointer += sourceLength;
          ix += 3;
          lix = ix;
        } else {
          ix ++;
        }
      }
      ix = input.length;    
    }
    if (outputLength > 0) {
      if (ix > lix ) {
        _memcpy(
          outputPointer,
          inputPointer,
          ix - lix
        );
        outputLength += (ix - lix);
      }
      assembly {
        // set final output length
        mstore(output, outputLength)
        // protect output bytes
        mstore(0x40, add(mload(0x40), add(outputLength, 32)))
      }
    }
    else {
      return input;
    }
  }

  /// @notice Move the inner cursor of the buffer to a relative or absolute position.
  /// @param buffer An instance of `Buffer`.
  /// @param offset How many bytes to move the cursor forward.
  /// @param relative Whether to count `offset` from the last position of the cursor (`true`) or the beginning of the
  /// buffer (`true`).
  /// @return The final position of the cursor (will equal `offset` if `relative` is `false`).
  // solium-disable-next-line security/no-assign-params
  function seek(
      Buffer memory buffer,
      uint offset,
      bool relative
    )
    internal pure
    withinRange(offset, buffer.data.length + 1)
    returns (uint)
  {
    // Deal with relative offsets
    if (relative) {
      offset += buffer.cursor;
    }
    buffer.cursor = offset;
    return offset;
  }

  /// @notice Move the inner cursor a number of bytes forward.
  /// @dev This is a simple wrapper around the relative offset case of `seek()`.
  /// @param buffer An instance of `Buffer`.
  /// @param relativeOffset How many bytes to move the cursor forward.
  /// @return The final position of the cursor.
  function seek(
      Buffer memory buffer,
      uint relativeOffset
    )
    internal pure
    returns (uint)
  {
    return seek(
      buffer,
      relativeOffset,
      true
    );
  }

  /// @notice Copy bytes from one memory address into another.
  /// @dev This function was borrowed from Nick Johnson's `solidity-stringutils` lib, and reproduced here under the terms
  /// of [Apache License 2.0](https://github.com/Arachnid/solidity-stringutils/blob/master/LICENSE).
  /// @param dest Address of the destination memory.
  /// @param src Address to the source memory.
  /// @param len How many bytes to copy.
  // solium-disable-next-line security/no-assign-params
  function _memcpy(
      uint dest,
      uint src,
      uint len
    )
    private pure
  {
    unchecked {
      // Copy word-length chunks while possible
      for (; len >= 32; len -= 32) {
        assembly {
          mstore(dest, mload(src))
        }
        dest += 32;
        src += 32;
      }
      if (len > 0) {
        // Copy remaining bytes
        uint _mask = 256 ** (32 - len) - 1;
        assembly {
          let srcpart := and(mload(src), not(_mask))
          let destpart := and(mload(dest), _mask)
          mstore(dest, or(destpart, srcpart))
        }
      }
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./WitnetCBOR.sol";
import "../interfaces/IWitnetRequest.sol";

library Witnet {

    /// ===============================================================================================================
    /// --- Witnet internal methods -----------------------------------------------------------------------------------

    /// @notice Witnet function that computes the hash of a CBOR-encoded Data Request.
    /// @param _bytecode CBOR-encoded RADON.
    function hash(bytes memory _bytecode) internal pure returns (bytes32) {
        return sha256(_bytecode);
    }

    /// Struct containing both request and response data related to every query posted to the Witnet Request Board
    struct Query {
        Request request;
        Response response;
        address from;      // Address from which the request was posted.
    }

    /// Possible status of a Witnet query.
    enum QueryStatus {
        Unknown,
        Posted,
        Reported,
        Deleted
    }

    /// Data kept in EVM-storage for every Request posted to the Witnet Request Board.
    struct Request {
        IWitnetRequest addr;    // The contract containing the Data Request which execution has been requested.
        address requester;      // Address from which the request was posted.
        bytes32 hash;           // Hash of the Data Request whose execution has been requested.
        uint256 gasprice;       // Minimum gas price the DR resolver should pay on the solving tx.
        uint256 reward;         // Escrowed reward to be paid to the DR resolver.
    }

    /// Data kept in EVM-storage containing Witnet-provided response metadata and result.
    struct Response {
        address reporter;       // Address from which the result was reported.
        uint256 timestamp;      // Timestamp of the Witnet-provided result.
        bytes32 drTxHash;       // Hash of the Witnet transaction that solved the queried Data Request.
        bytes   cborBytes;      // Witnet-provided result CBOR-bytes to the queried Data Request.
    }

    /// Data struct containing the Witnet-provided result to a Data Request.
    struct Result {
        bool success;           // Flag stating whether the request could get solved successfully, or not.
        WitnetCBOR.CBOR value;             // Resulting value, in CBOR-serialized bytes.
    }

    /// ===============================================================================================================
    /// --- Witnet error codes table ----------------------------------------------------------------------------------

    enum ErrorCodes {
        // 0x00: Unknown error. Something went really bad!
        Unknown,
        // Script format errors
        /// 0x01: At least one of the source scripts is not a valid CBOR-encoded value.
        SourceScriptNotCBOR,
        /// 0x02: The CBOR value decoded from a source script is not an Array.
        SourceScriptNotArray,
        /// 0x03: The Array value decoded form a source script is not a valid Data Request.
        SourceScriptNotRADON,
        /// Unallocated
        ScriptFormat0x04,
        ScriptFormat0x05,
        ScriptFormat0x06,
        ScriptFormat0x07,
        ScriptFormat0x08,
        ScriptFormat0x09,
        ScriptFormat0x0A,
        ScriptFormat0x0B,
        ScriptFormat0x0C,
        ScriptFormat0x0D,
        ScriptFormat0x0E,
        ScriptFormat0x0F,
        // Complexity errors
        /// 0x10: The request contains too many sources.
        RequestTooManySources,
        /// 0x11: The script contains too many calls.
        ScriptTooManyCalls,
        /// Unallocated
        Complexity0x12,
        Complexity0x13,
        Complexity0x14,
        Complexity0x15,
        Complexity0x16,
        Complexity0x17,
        Complexity0x18,
        Complexity0x19,
        Complexity0x1A,
        Complexity0x1B,
        Complexity0x1C,
        Complexity0x1D,
        Complexity0x1E,
        Complexity0x1F,
        // Operator errors
        /// 0x20: The operator does not exist.
        UnsupportedOperator,
        /// Unallocated
        Operator0x21,
        Operator0x22,
        Operator0x23,
        Operator0x24,
        Operator0x25,
        Operator0x26,
        Operator0x27,
        Operator0x28,
        Operator0x29,
        Operator0x2A,
        Operator0x2B,
        Operator0x2C,
        Operator0x2D,
        Operator0x2E,
        Operator0x2F,
        // Retrieval-specific errors
        /// 0x30: At least one of the sources could not be retrieved, but returned HTTP error.
        HTTP,
        /// 0x31: Retrieval of at least one of the sources timed out.
        RetrievalTimeout,
        /// Unallocated
        Retrieval0x32,
        Retrieval0x33,
        Retrieval0x34,
        Retrieval0x35,
        Retrieval0x36,
        Retrieval0x37,
        Retrieval0x38,
        Retrieval0x39,
        Retrieval0x3A,
        Retrieval0x3B,
        Retrieval0x3C,
        Retrieval0x3D,
        Retrieval0x3E,
        Retrieval0x3F,
        // Math errors
        /// 0x40: Math operator caused an underflow.
        Underflow,
        /// 0x41: Math operator caused an overflow.
        Overflow,
        /// 0x42: Tried to divide by zero.
        DivisionByZero,
        /// Unallocated
        Math0x43,
        Math0x44,
        Math0x45,
        Math0x46,
        Math0x47,
        Math0x48,
        Math0x49,
        Math0x4A,
        Math0x4B,
        Math0x4C,
        Math0x4D,
        Math0x4E,
        Math0x4F,
        // Other errors
        /// 0x50: Received zero reveals
        NoReveals,
        /// 0x51: Insufficient consensus in tally precondition clause
        InsufficientConsensus,
        /// 0x52: Received zero commits
        InsufficientCommits,
        /// 0x53: Generic error during tally execution
        TallyExecution,
        /// Unallocated
        OtherError0x54,
        OtherError0x55,
        OtherError0x56,
        OtherError0x57,
        OtherError0x58,
        OtherError0x59,
        OtherError0x5A,
        OtherError0x5B,
        OtherError0x5C,
        OtherError0x5D,
        OtherError0x5E,
        OtherError0x5F,
        /// 0x60: Invalid reveal serialization (malformed reveals are converted to this value)
        MalformedReveal,
        /// Unallocated
        OtherError0x61,
        OtherError0x62,
        OtherError0x63,
        OtherError0x64,
        OtherError0x65,
        OtherError0x66,
        OtherError0x67,
        OtherError0x68,
        OtherError0x69,
        OtherError0x6A,
        OtherError0x6B,
        OtherError0x6C,
        OtherError0x6D,
        OtherError0x6E,
        OtherError0x6F,
        // Access errors
        /// 0x70: Tried to access a value from an index using an index that is out of bounds
        ArrayIndexOutOfBounds,
        /// 0x71: Tried to access a value from a map using a key that does not exist
        MapKeyNotFound,
        /// Unallocated
        OtherError0x72,
        OtherError0x73,
        OtherError0x74,
        OtherError0x75,
        OtherError0x76,
        OtherError0x77,
        OtherError0x78,
        OtherError0x79,
        OtherError0x7A,
        OtherError0x7B,
        OtherError0x7C,
        OtherError0x7D,
        OtherError0x7E,
        OtherError0x7F,
        OtherError0x80,
        OtherError0x81,
        OtherError0x82,
        OtherError0x83,
        OtherError0x84,
        OtherError0x85,
        OtherError0x86,
        OtherError0x87,
        OtherError0x88,
        OtherError0x89,
        OtherError0x8A,
        OtherError0x8B,
        OtherError0x8C,
        OtherError0x8D,
        OtherError0x8E,
        OtherError0x8F,
        OtherError0x90,
        OtherError0x91,
        OtherError0x92,
        OtherError0x93,
        OtherError0x94,
        OtherError0x95,
        OtherError0x96,
        OtherError0x97,
        OtherError0x98,
        OtherError0x99,
        OtherError0x9A,
        OtherError0x9B,
        OtherError0x9C,
        OtherError0x9D,
        OtherError0x9E,
        OtherError0x9F,
        OtherError0xA0,
        OtherError0xA1,
        OtherError0xA2,
        OtherError0xA3,
        OtherError0xA4,
        OtherError0xA5,
        OtherError0xA6,
        OtherError0xA7,
        OtherError0xA8,
        OtherError0xA9,
        OtherError0xAA,
        OtherError0xAB,
        OtherError0xAC,
        OtherError0xAD,
        OtherError0xAE,
        OtherError0xAF,
        OtherError0xB0,
        OtherError0xB1,
        OtherError0xB2,
        OtherError0xB3,
        OtherError0xB4,
        OtherError0xB5,
        OtherError0xB6,
        OtherError0xB7,
        OtherError0xB8,
        OtherError0xB9,
        OtherError0xBA,
        OtherError0xBB,
        OtherError0xBC,
        OtherError0xBD,
        OtherError0xBE,
        OtherError0xBF,
        OtherError0xC0,
        OtherError0xC1,
        OtherError0xC2,
        OtherError0xC3,
        OtherError0xC4,
        OtherError0xC5,
        OtherError0xC6,
        OtherError0xC7,
        OtherError0xC8,
        OtherError0xC9,
        OtherError0xCA,
        OtherError0xCB,
        OtherError0xCC,
        OtherError0xCD,
        OtherError0xCE,
        OtherError0xCF,
        OtherError0xD0,
        OtherError0xD1,
        OtherError0xD2,
        OtherError0xD3,
        OtherError0xD4,
        OtherError0xD5,
        OtherError0xD6,
        OtherError0xD7,
        OtherError0xD8,
        OtherError0xD9,
        OtherError0xDA,
        OtherError0xDB,
        OtherError0xDC,
        OtherError0xDD,
        OtherError0xDE,
        OtherError0xDF,
        // Bridge errors: errors that only belong in inter-client communication
        /// 0xE0: Requests that cannot be parsed must always get this error as their result.
        /// However, this is not a valid result in a Tally transaction, because invalid requests
        /// are never included into blocks and therefore never get a Tally in response.
        BridgeMalformedRequest,
        /// 0xE1: Witnesses exceeds 100
        BridgePoorIncentives,
        /// 0xE2: The request is rejected on the grounds that it may cause the submitter to spend or stake an
        /// amount of value that is unjustifiably high when compared with the reward they will be getting
        BridgeOversizedResult,
        /// Unallocated
        OtherError0xE3,
        OtherError0xE4,
        OtherError0xE5,
        OtherError0xE6,
        OtherError0xE7,
        OtherError0xE8,
        OtherError0xE9,
        OtherError0xEA,
        OtherError0xEB,
        OtherError0xEC,
        OtherError0xED,
        OtherError0xEE,
        OtherError0xEF,
        OtherError0xF0,
        OtherError0xF1,
        OtherError0xF2,
        OtherError0xF3,
        OtherError0xF4,
        OtherError0xF5,
        OtherError0xF6,
        OtherError0xF7,
        OtherError0xF8,
        OtherError0xF9,
        OtherError0xFA,
        OtherError0xFB,
        OtherError0xFC,
        OtherError0xFD,
        OtherError0xFE,
        // This should not exist:
        /// 0xFF: Some tally error is not intercepted but should
        UnhandledIntercept
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./IWitnetBytecodes.sol";
import "../../requests/WitnetRequest.sol";

interface IWitnetRequestFactory {
    
    event WitnetRequestBuilt(WitnetRequest request);
    event WitnetRequestTemplateBuilt(WitnetRequestTemplate template, bool parameterized);
    
    function buildRequest(
            bytes32[] memory sourcesIds,
            bytes32 aggregatorId,
            bytes32 tallyId,
            uint16  resultDataMaxSize
        ) external returns (WitnetRequest request);
    
    function buildRequestTemplate(
            bytes32[] memory sourcesIds,
            bytes32 aggregatorId,
            bytes32 tallyId,
            uint16  resultDataMaxSize
        ) external returns (WitnetRequestTemplate template);
    
    function class() external view returns (bytes4);    
    function registry() external view returns (IWitnetBytecodes);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../../libs/WitnetV2.sol";

interface IWitnetBytecodes {

    error UnknownDataSource(bytes32 hash);
    error UnknownRadonReducer(bytes32 hash);
    error UnknownRadonRequest(bytes32 hash);
    error UnknownRadonSLA(bytes32 hash);
    
    event NewDataProvider(uint256 index);
    event NewDataSourceHash(bytes32 hash);
    event NewRadonReducerHash(bytes32 hash);
    event NewRadHash(bytes32 hash);
    event NewSlaHash(bytes32 hash);

    function bytecodeOf(bytes32 radHash) external view returns (bytes memory);
    function bytecodeOf(bytes32 radHash, bytes32 slahHash) external view returns (bytes memory);

    function hashOf(bytes32 radHash, bytes32 slaHash) external pure returns (bytes32 drQueryHash);
    function hashWeightWitsOf(bytes32 radHash, bytes32 slaHash) external view returns (
            bytes32 drQueryHash,
            uint32  drQueryWeight,
            uint256 drQueryWits
        );

    function lookupDataProvider(uint256 index) external view returns (string memory, uint);
    function lookupDataProviderIndex(string calldata authority) external view returns (uint);
    function lookupDataProviderSources(uint256 index, uint256 offset, uint256 length) external view returns (bytes32[] memory);
    function lookupDataSource(bytes32 hash) external view returns (WitnetV2.DataSource memory);
    function lookupDataSourceArgsCount(bytes32 hash) external view returns (uint8);
    function lookupDataSourceResultDataType(bytes32 hash) external view returns (WitnetV2.RadonDataTypes);
    function lookupRadonReducer(bytes32 hash) external view returns (WitnetV2.RadonReducer memory);
    function lookupRadonRequestAggregator(bytes32 hash) external view returns (WitnetV2.RadonReducer memory);
    function lookupRadonRequestResultMaxSize(bytes32 hash) external view returns (uint256);
    function lookupRadonRequestResultDataType(bytes32 hash) external view returns (WitnetV2.RadonDataTypes);
    function lookupRadonRequestSources(bytes32 hash) external view returns (bytes32[] memory);
    function lookupRadonRequestSourcesCount(bytes32 hash) external view returns (uint);
    function lookupRadonRequestTally(bytes32 hash) external view returns (WitnetV2.RadonReducer memory);
    function lookupRadonSLA(bytes32 hash) external view returns (WitnetV2.RadonSLA memory);
    function lookupRadonSLAReward(bytes32 hash) external view returns (uint);
    
    function verifyDataSource(
            WitnetV2.DataRequestMethods requestMethod,
            string calldata requestSchema,
            string calldata requestAuthority,
            string calldata requestPath,
            string calldata requestQuery,
            string calldata requestBody,
            string[2][] calldata requestHeaders,
            bytes calldata requestRadonScript
        ) external returns (bytes32 hash);
    
    function verifyRadonReducer(WitnetV2.RadonReducer calldata reducer)
        external returns (bytes32 hash);
    
    function verifyRadonRequest(
            bytes32[] calldata sources,
            bytes32 aggregator,
            bytes32 tally,
            uint16 resultMaxSize,
            string[][] calldata args
        ) external returns (bytes32 hash);    
    
    function verifyRadonSLA(WitnetV2.RadonSLA calldata sla)
        external returns (bytes32 hash);

    function totalDataProviders() external view returns (uint);
   
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../libs/Witnet.sol";

/// @title The Witnet interface for decoding Witnet-provided request to Data Requests.
/// This interface exposes functions to check for the success/failure of
/// a Witnet-provided result, as well as to parse and convert result into
/// Solidity types suitable to the application level. 
/// @author The Witnet Foundation.
interface IWitnetRequestParser {

    /// Decode raw CBOR bytes into a Witnet.Result instance.
    /// @param _cborBytes Raw bytes representing a CBOR-encoded value.
    /// @return A `Witnet.Result` instance.
    function resultFromCborBytes(bytes memory _cborBytes) external pure returns (Witnet.Result memory);

    /// Tell if a Witnet.Result is successful.
    /// @param _result An instance of Witnet.Result.
    /// @return `true` if successful, `false` if errored.
    function isOk(Witnet.Result memory _result) external pure returns (bool);

    /// Tell if a Witnet.Result is errored.
    /// @param _result An instance of Witnet.Result.
    /// @return `true` if errored, `false` if successful.
    function isError(Witnet.Result memory _result) external pure returns (bool);

    /// Decode a boolean value from a Witnet.Result as an `bool` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `bool` decoded from the Witnet.Result.
    function asBool(Witnet.Result memory _result) external pure returns (bool);

    /// Decode a bytes value from a Witnet.Result as a `bytes` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `bytes` decoded from the Witnet.Result.
    function asBytes(Witnet.Result memory _result) external pure returns (bytes memory);

    /// Decode a bytes value from a Witnet.Result as a `bytes32` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `bytes32` decoded from the Witnet.Result.
    function asBytes32(Witnet.Result memory _result) external pure returns (bytes32);

    /// Decode an error code from a Witnet.Result as a member of `Witnet.ErrorCodes`.
    /// @param _result An instance of `Witnet.Result`.
    /// @return The `CBORValue.Error memory` decoded from the Witnet.Result.
    function asErrorCode(Witnet.Result memory _result) external pure returns (Witnet.ErrorCodes);

    /// Generate a suitable error message for a member of `Witnet.ErrorCodes` and its corresponding arguments.
    /// @dev WARN: Note that client contracts should wrap this function into a try-catch foreseing potential errors generated in this function
    /// @param _result An instance of `Witnet.Result`.
    /// @return A tuple containing the `CBORValue.Error memory` decoded from the `Witnet.Result`, plus a loggable error message.
    function asErrorMessage(Witnet.Result memory _result) external pure returns (Witnet.ErrorCodes, string memory);

    /// Decode a fixed16 (half-precision) numeric value from a Witnet.Result as an `int32` value.
    /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values.
    /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`.
    /// use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int32` decoded from the Witnet.Result.
    function asFixed16(Witnet.Result memory _result) external pure returns (int32);

    /// Decode an array of fixed16 values from a Witnet.Result as an `int32[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int32[]` decoded from the Witnet.Result.
    function asFixed16Array(Witnet.Result memory _result) external pure returns (int32[] memory);

    /// Decode a integer numeric value from a Witnet.Result as an `int128` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int` decoded from the Witnet.Result.
    function asInt128(Witnet.Result memory _result) external pure returns (int);

    /// Decode an array of integer numeric values from a Witnet.Result as an `int128[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int128[]` decoded from the Witnet.Result.
    function asInt128Array(Witnet.Result memory _result) external pure returns (int[] memory);

    /// Decode a string value from a Witnet.Result as a `string` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `string` decoded from the Witnet.Result.
    function asString(Witnet.Result memory _result) external pure returns (string memory);

    /// Decode an array of string values from a Witnet.Result as a `string[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `string[]` decoded from the Witnet.Result.
    function asStringArray(Witnet.Result memory _result) external pure returns (string[] memory);

    /// Decode a natural numeric value from a Witnet.Result as a `uint` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `uint` decoded from the Witnet.Result.
    function asUint64(Witnet.Result memory _result) external pure returns (uint);

    /// Decode an array of natural numeric values from a Witnet.Result as a `uint[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `uint[]` decoded from the Witnet.Result.
    function asUint64Array(Witnet.Result memory _result) external pure returns (uint[] memory);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../libs/Witnet.sol";

/// @title Witnet Request Board info interface.
/// @author The Witnet Foundation.
interface IWitnetRequestBoardView {
    /// Estimates the amount of reward we need to insert for a given gas price.
    /// @param _gasPrice The gas price for which we need to calculate the rewards.
    function estimateReward(uint256 _gasPrice) external view returns (uint256);

    /// Returns next query id to be generated by the Witnet Request Board.
    function getNextQueryId() external view returns (uint256);

    /// Gets the whole Query data contents, if any, no matter its current status.
    function getQueryData(uint256 _queryId) external view returns (Witnet.Query memory);

    /// Gets current status of given query.
    function getQueryStatus(uint256 _queryId) external view returns (Witnet.QueryStatus);

    /// Retrieves the whole Request record posted to the Witnet Request Board.
    /// @dev Fails if the `_queryId` is not valid or, if it has already been reported
    /// @dev or deleted.
    /// @param _queryId The unique identifier of a previously posted query.
    function readRequest(uint256 _queryId) external view returns (Witnet.Request memory);

    /// Retrieves the serialized bytecode of a previously posted Witnet Data Request.
    /// @dev Fails if the `_queryId` is not valid, or if the related script bytecode 
    /// @dev got changed after being posted. Returns empty array once it gets reported, 
    /// @dev or deleted.
    /// @param _queryId The unique query identifier.
    function readRequestBytecode(uint256 _queryId) external view returns (bytes memory);

    /// Retrieves the gas price that any assigned reporter will have to pay when reporting 
    /// result to a previously posted Witnet data request.
    /// @dev Fails if the `_queryId` is not valid or, if it has already been 
    /// @dev reported, or deleted. 
    /// @param _queryId The unique query identifie
    function readRequestGasPrice(uint256 _queryId) external view returns (uint256);

    /// Retrieves the reward currently set for the referred query.
    /// @dev Fails if the `_queryId` is not valid or, if it has already been 
    /// @dev reported, or deleted. 
    /// @param _queryId The unique query identifier.
    function readRequestReward(uint256 _queryId) external view returns (uint256);

    /// Retrieves the whole `Witnet.Response` record referred to a previously posted Witnet Data Request.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponse(uint256 _queryId) external view returns (Witnet.Response memory);

    /// Retrieves the hash of the Witnet transaction hash that actually solved the referred query.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponseDrTxHash(uint256 _queryId) external view returns (bytes32);    

    /// Retrieves the address that reported the result to a previously-posted request.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponseReporter(uint256 _queryId) external view returns (address);

    /// Retrieves the Witnet-provided CBOR-bytes result of a previously posted request.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponseResult(uint256 _queryId) external view returns (Witnet.Result memory);

    /// Retrieves the timestamp in which the result to the referred query was solved by the Witnet DON.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponseTimestamp(uint256 _queryId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../libs/Witnet.sol";

/// @title Witnet Requestor Interface
/// @notice It defines how to interact with the Witnet Request Board in order to:
///   - request the execution of Witnet Radon scripts (data request);
///   - upgrade the resolution reward of any previously posted request, in case gas price raises in mainnet;
///   - read the result of any previously posted request, eventually reported by the Witnet DON.
///   - remove from storage all data related to past and solved data requests, and results.
/// @author The Witnet Foundation.
interface IWitnetRequestBoardRequestor {
    /// Retrieves a copy of all Witnet-provided data related to a previously posted request, removing the whole query from the WRB storage.
    /// @dev Fails if the `_queryId` is not in 'Reported' status, or called from an address different to
    /// @dev the one that actually posted the given request.
    /// @param _queryId The unique query identifier.
    function deleteQuery(uint256 _queryId) external returns (Witnet.Response memory);

    /// Requests the execution of the given Witnet Data Request in expectation that it will be relayed and solved by the Witnet DON.
    /// A reward amount is escrowed by the Witnet Request Board that will be transferred to the reporter who relays back the Witnet-provided 
    /// result to this request.
    /// @dev Fails if:
    /// @dev - provided reward is too low.
    /// @dev - provided script is zero address.
    /// @dev - provided script bytecode is empty.
    /// @param _addr The address of the IWitnetRequest contract that can provide the actual Data Request bytecode.
    /// @return _queryId An unique query identifier.
    function postRequest(IWitnetRequest _addr) external payable returns (uint256 _queryId);

    /// Increments the reward of a previously posted request by adding the transaction value to it.
    /// @dev Updates request `gasPrice` in case this method is called with a higher 
    /// @dev gas price value than the one used in previous calls to `postRequest` or
    /// @dev `upgradeReward`. 
    /// @dev Fails if the `_queryId` is not in 'Posted' status.
    /// @dev Fails also in case the request `gasPrice` is increased, and the new 
    /// @dev reward value gets below new recalculated threshold. 
    /// @param _queryId The unique query identifier.
    function upgradeReward(uint256 _queryId) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/// @title The Witnet Request Board Reporter interface.
/// @author The Witnet Foundation.
interface IWitnetRequestBoardReporter {
    /// Reports the Witnet-provided result to a previously posted request. 
    /// @dev Will assume `block.timestamp` as the timestamp at which the request was solved.
    /// @dev Fails if:
    /// @dev - the `_queryId` is not in 'Posted' status.
    /// @dev - provided `_drTxHash` is zero;
    /// @dev - length of provided `_result` is zero.
    /// @param _queryId The unique identifier of the data request.
    /// @param _drTxHash The hash of the corresponding data request transaction in Witnet.
    /// @param _result The result itself as bytes.
    function reportResult(
            uint256 _queryId,
            bytes32 _drTxHash,
            bytes calldata _result
        ) external;

    /// Reports the Witnet-provided result to a previously posted request.
    /// @dev Fails if:
    /// @dev - called from unauthorized address;
    /// @dev - the `_queryId` is not in 'Posted' status.
    /// @dev - provided `_drTxHash` is zero;
    /// @dev - length of provided `_result` is zero.
    /// @param _queryId The unique query identifier
    /// @param _timestamp The timestamp of the solving tally transaction in Witnet.
    /// @param _drTxHash The hash of the corresponding data request transaction in Witnet.
    /// @param _result The result itself as bytes.
    function reportResult(
            uint256 _queryId,
            uint256 _timestamp,
            bytes32 _drTxHash,
            bytes calldata _result
        ) external;

    /// Reports Witnet-provided results to multiple requests within a single EVM tx.
    /// @dev Must emit a PostedResult event for every succesfully reported result.
    /// @param _batchResults Array of BatchResult structs, every one containing:
    ///         - unique query identifier;
    ///         - timestamp of the solving tally txs in Witnet. If zero is provided, EVM-timestamp will be used instead;
    ///         - hash of the corresponding data request tx at the Witnet side-chain level;
    ///         - data request result in raw bytes.
    /// @param _verbose If true, must emit a BatchReportError event for every failing report, if any. 
    function reportResultBatch(BatchResult[] calldata _batchResults, bool _verbose) external;
        
        struct BatchResult {
            uint256 queryId;
            uint256 timestamp;
            bytes32 drTxHash;
            bytes   cborBytes;
        }

        event BatchReportError(uint256 queryId, string reason);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/// @title Witnet Request Board emitting events interface.
/// @author The Witnet Foundation.
interface IWitnetRequestBoardEvents {
    /// Emitted when a Witnet Data Request is posted to the WRB.
    event PostedRequest(uint256 queryId, address from);

    /// Emitted when a Witnet-solved result is reported to the WRB.
    event PostedResult(uint256 queryId, address from);

    /// Emitted when all data related to given query is deleted from the WRB.
    event DeletedQuery(uint256 queryId, address from);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/// @title The Witnet Data Request basic interface.
/// @author The Witnet Foundation.
interface IWitnetRequest {
    /// A `IWitnetRequest` is constructed around a `bytes` value containing 
    /// a well-formed Witnet Data Request using Protocol Buffers.
    function bytecode() external view returns (bytes memory);

    /// Returns SHA256 hash of Witnet Data Request as CBOR-encoded bytes.
    function hash() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// solhint-disable var-name-mixedcase
// solhint-disable payable-fallback

pragma solidity >=0.8.0 <0.9.0;

import "../patterns/ERC165.sol";
import "../patterns/Ownable2Step.sol";
import "../patterns/ReentrancyGuard.sol";
import "../patterns/Upgradeable.sol";

import "./WitnetProxy.sol";

/// @title Witnet Request Board base contract, with an Upgradeable (and Destructible) touch.
/// @author The Witnet Foundation.
abstract contract WitnetUpgradableBase
    is
        ERC165,
        Ownable2Step,
        Upgradeable, 
        ReentrancyGuard
{
    bytes32 internal immutable _WITNET_UPGRADABLE_VERSION;

    error AlreadyUpgraded(address implementation);
    error NotCompliant(bytes4 interfaceId);
    error NotUpgradable(address self);
    error OnlyOwner(address owner);

    constructor(
            bool _upgradable,
            bytes32 _versionTag,
            string memory _proxiableUUID
        )
        Upgradeable(_upgradable)
    {
        _WITNET_UPGRADABLE_VERSION = _versionTag;
        proxiableUUID = keccak256(bytes(_proxiableUUID));
    }
    
    /// @dev Reverts if proxy delegatecalls to unexistent method.
    fallback() external {
        revert("WitnetUpgradableBase: not implemented");
    }


    // ================================================================================================================
    // --- Overrides IERC165 interface --------------------------------------------------------------------------------

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 _interfaceId)
      public view
      virtual override
      returns (bool)
    {
        return _interfaceId == type(Ownable2Step).interfaceId
            || _interfaceId == type(Upgradeable).interfaceId
            || super.supportsInterface(_interfaceId);
    }

    // ================================================================================================================
    // --- Overrides 'Proxiable' --------------------------------------------------------------------------------------

    /// @dev Gets immutable "heritage blood line" (ie. genotype) as a Proxiable, and eventually Upgradeable, contract.
    ///      If implemented as an Upgradeable touch, upgrading this contract to another one with a different 
    ///      `proxiableUUID()` value should fail.
    bytes32 public immutable override proxiableUUID;


    // ================================================================================================================
    // --- Overrides 'Upgradeable' --------------------------------------------------------------------------------------

    /// Retrieves human-readable version tag of current implementation.
    function version() public view virtual override returns (string memory) {
        return _toString(_WITNET_UPGRADABLE_VERSION);
    }


    // ================================================================================================================
    // --- Internal methods -------------------------------------------------------------------------------------------

    /// Converts bytes32 into string.
    function _toString(bytes32 _bytes32)
        internal pure
        returns (string memory)
    {
        bytes memory _bytes = new bytes(_toStringLength(_bytes32));
        for (uint _i = 0; _i < _bytes.length;) {
            _bytes[_i] = _bytes32[_i];
            unchecked {
                _i ++;
            }
        }
        return string(_bytes);
    }

    // Calculate length of string-equivalent to given bytes32.
    function _toStringLength(bytes32 _bytes32)
        internal pure
        returns (uint _length)
    {
        for (; _length < 32; ) {
            if (_bytes32[_length] == 0) {
                break;
            }
            unchecked {
                _length ++;
            }
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../patterns/Upgradeable.sol";

/// @title WitnetProxy: upgradable delegate-proxy contract. 
/// @author The Witnet Foundation.
contract WitnetProxy {

    /// Event emitted every time the implementation gets updated.
    event Upgraded(address indexed implementation);  

    /// Constructor with no params as to ease eventual support of Singleton pattern (i.e. ERC-2470).
    constructor () {}

    receive() virtual external payable {}

    /// Payable fallback accepts delegating calls to payable functions.  
    fallback() external payable { /* solhint-disable no-complex-fallback */
        address _implementation = implementation();
        assembly { /* solhint-disable avoid-low-level-calls */
            // Gas optimized delegate call to 'implementation' contract.
            // Note: `msg.data`, `msg.sender` and `msg.value` will be passed over 
            //       to actual implementation of `msg.sig` within `implementation` contract.
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _implementation, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
                case 0  { 
                    // pass back revert message:
                    revert(ptr, size) 
                }
                default {
                  // pass back same data as returned by 'implementation' contract:
                  return(ptr, size) 
                }
        }
    }

    /// Returns proxy's current implementation address.
    function implementation() public view returns (address) {
        return __proxySlot().implementation;
    }

    /// Upgrades the `implementation` address.
    /// @param _newImplementation New implementation address.
    /// @param _initData Raw data with which new implementation will be initialized.
    /// @return Returns whether new implementation would be further upgradable, or not.
    function upgradeTo(address _newImplementation, bytes memory _initData)
        public returns (bool)
    {
        // New implementation cannot be null:
        require(_newImplementation != address(0), "WitnetProxy: null implementation");

        address _oldImplementation = implementation();
        if (_oldImplementation != address(0)) {
            // New implementation address must differ from current one:
            require(_newImplementation != _oldImplementation, "WitnetProxy: nothing to upgrade");

            // Assert whether current implementation is intrinsically upgradable:
            try Upgradeable(_oldImplementation).isUpgradable() returns (bool _isUpgradable) {
                require(_isUpgradable, "WitnetProxy: not upgradable");
            } catch {
                revert("WitnetProxy: unable to check upgradability");
            }

            // Assert whether current implementation allows `msg.sender` to upgrade the proxy:
            (bool _wasCalled, bytes memory _result) = _oldImplementation.delegatecall(
                abi.encodeWithSignature(
                    "isUpgradableFrom(address)",
                    msg.sender
                )
            );
            require(_wasCalled, "WitnetProxy: not compliant");
            require(abi.decode(_result, (bool)), "WitnetProxy: not authorized");
            require(
                Upgradeable(_oldImplementation).proxiableUUID() == Upgradeable(_newImplementation).proxiableUUID(),
                "WitnetProxy: proxiableUUIDs mismatch"
            );
        }

        // Initialize new implementation within proxy-context storage:
        (bool _wasInitialized,) = _newImplementation.delegatecall(
            abi.encodeWithSignature(
                "initialize(bytes)",
                _initData
            )
        );
        require(_wasInitialized, "WitnetProxy: unable to initialize");

        // If all checks and initialization pass, update implementation address:
        __proxySlot().implementation = _newImplementation;
        emit Upgraded(_newImplementation);

        // Asserts new implementation complies w/ minimal implementation of Upgradeable interface:
        try Upgradeable(_newImplementation).isUpgradable() returns (bool _isUpgradable) {
            return _isUpgradable;
        }
        catch {
            revert ("WitnetProxy: not compliant");
        }
    }

    /// @dev Complying with EIP-1967, retrieves storage struct containing proxy's current implementation address.
    function __proxySlot() private pure returns (Proxiable.ProxiableSlot storage _slot) {
        assembly {
            // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
            _slot.slot := 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../requests/WitnetRequestTemplate.sol";

contract WitnetRequestFactoryData {

    bytes32 internal constant _WITNET_REQUEST_SLOTHASH =
        /* keccak256("io.witnet.data.request") */
        0xbf9e297db5f64cdb81cd821e7ad085f56008e0c6100f4ebf5e41ef6649322034;

    bytes32 internal constant _WITNET_REQUEST_FACTORY_SLOTHASH =
        /* keccak256("io.witnet.data.request.factory") */
        0xfaf45a8ecd300851b566566df52ca7611b7a56d24a3449b86f4e21c71638e642;

    bytes32 internal constant _WITNET_REQUEST_TEMPLATE_SLOTHASH =
        /* keccak256("io.witnet.data.request.template") */
        0x50402db987be01ecf619cd3fb022cf52f861d188e7b779dd032a62d082276afb;

    struct Slot {
        address owner;
        address pendingOwner;
    }

    struct WitnetRequestSlot {
        /// Array of string arguments passed upon initialization.
        string[][] args;  
        /// Witnet Data Request bytecode after inserting string arguments.
        bytes bytecode;    
        /// Address from which the request's SLA can be modifies.
        address curator;
        /// SHA-256 hash of the Witnet Data Request bytecode.
        bytes32 hash;
        /// Radon RAD hash. 
        bytes32 radHash;
        /// Radon SLA hash.
        bytes32 slaHash;
        /// Parent WitnetRequestTemplate contract.
        WitnetRequestTemplate template;
    }

    struct WitnetRequestTemplateSlot {
        /// Whether any of the sources is parameterized.
        bool parameterized;
        /// @notice Result data type.
        WitnetV2.RadonDataTypes resultDataType;
        /// @notice Result max size or rank (if variable type).
        uint16 resultDataMaxSize;        
        /// @notice Aggregator reducer hash.
        bytes32 aggregatorHash;
        /// @notice Tally reducer hash.
        bytes32 tallyHash;
        /// @notice Array of sources hashes passed upon construction.
        bytes32[] sources;
    }

    function __witnetRequestFactory()
        internal pure
        returns (Slot storage ptr)
    {
        assembly {
            ptr.slot := _WITNET_REQUEST_FACTORY_SLOTHASH
        }
    }

    function __witnetRequest()
        internal pure
        returns (WitnetRequestSlot storage ptr)
    {
        assembly {
            ptr.slot := _WITNET_REQUEST_SLOTHASH
        }
    }

    function __witnetRequestTemplate()
        internal pure
        returns (WitnetRequestTemplateSlot storage ptr)
    {
        assembly {
            ptr.slot := _WITNET_REQUEST_TEMPLATE_SLOTHASH
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "../data/WitnetRequestFactoryData.sol";
import "../impls/WitnetUpgradableBase.sol";
import "../patterns/Clonable.sol";
import "../interfaces/V2/IWitnetRequestFactory.sol";

contract WitnetRequestFactory
    is
        Clonable,
        IWitnetRequestFactory,
        WitnetRequest,
        WitnetRequestTemplate,
        WitnetRequestFactoryData,
        WitnetUpgradableBase        
{
    using ERC165Checker for address;

    /// @notice Reference to Witnet Data Requests Bytecode Registry
    IWitnetBytecodes immutable public override registry;

    modifier onlyDelegateCalls override(Clonable, Upgradeable) {
        require(
            address(this) != _BASE,
            "WitnetRequestFactory: not a delegate call"
        );
        _;
    }

    modifier onlyOnFactory {
        require(
            address(this) == __proxy(),
            "WitnetRequestFactory: not a factory"
        );
        _;
    }

    modifier onlyOnTemplates {
        require(
            __witnetRequestTemplate().tallyHash != bytes32(0),
            "WitnetRequestFactory: not a template"
        );
        _;
    }

    constructor(
            IWitnetBytecodes _registry,
            bool _upgradable,
            bytes32 _versionTag
        )
        WitnetUpgradableBase(
            _upgradable,
            _versionTag,
            "io.witnet.requests.factory"
        )
    {
        require(
            address(_registry).supportsInterface(type(IWitnetBytecodes).interfaceId),
            "WitnetRequestFactory: uncompliant registry"
        );
        registry = _registry;
        // let logic contract be used as a factory, while avoiding further initializations:
        __proxiable().proxy = address(this);
        __proxiable().implementation = address(this);
        __witnetRequestFactory().owner = address(0);
    }


    /// ===============================================================================================================
    /// --- IWitnetRequestFactory implementation ----------------------------------------------------------------------

    function buildRequest(
            bytes32[] memory _sources,
            bytes32 _aggregator,
            bytes32 _tally,
            uint16  _resultDataMaxSize
        )
        virtual override
        external
        onlyOnFactory
        returns (WitnetRequest _request)
    {
        WitnetRequestTemplate _template = buildRequestTemplate(
            _sources,
            _aggregator,
            _tally,
            _resultDataMaxSize
        );
        require(
            !_template.parameterized(),
            "WitnetRequestFactory: parameterized sources"
        );
        _request = _template.settleArgs(abi.decode(hex"",(string[][])));
        emit WitnetRequestBuilt(_request);
    }

    function buildRequestTemplate(
            bytes32[] memory _sources,
            bytes32 _aggregator,
            bytes32 _tally,
            uint16  _resultDataMaxSize
        )
        virtual override
        public
        onlyOnFactory
        returns (WitnetRequestTemplate _template)
    {
        bytes32 _salt = keccak256(
            // As to avoid template address collisions from:
            abi.encodePacked( 
                // - different factory versions
                _WITNET_UPGRADABLE_VERSION,
                // - different templates
                _sources, 
                _aggregator,
                _tally,
                _resultDataMaxSize
            )
        );
        address _address = address(uint160(uint256(keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                _salt,
                keccak256(_cloneBytecode())
            )
        ))));
        if (_address.code.length > 0) {
            _template = WitnetRequestTemplate(_address);
        } else {
            _template = WitnetRequestFactory(
                _cloneDeterministic(_salt)
            ).initializeWitnetRequestTemplate(
                _sources,
                _aggregator,
                _tally,
                _resultDataMaxSize
            );
            emit WitnetRequestTemplateBuilt(
                _template,
                _template.parameterized()
            );
        }
    }

    function class() 
        virtual override(IWitnetRequestFactory, WitnetRequest, WitnetRequestTemplate)
        external view
        returns (bytes4)
    {
        if (address(this) == _SELF) {
            return type(Upgradeable).interfaceId;
        } else {
            if (address(this) == __proxy()) {
                return type(IWitnetRequestFactory).interfaceId;
            } else if (__witnetRequest().radHash != bytes32(0)) {
                return type(WitnetRequest).interfaceId;
            } else {
                return type(WitnetRequestTemplate).interfaceId;
            }
        }
    }

    function initializeWitnetRequestTemplate(
            bytes32[] calldata _sources,
            bytes32 _aggregatorId,
            bytes32 _tallyId,
            uint16  _resultDataMaxSize
        )
        virtual public
        initializer
        returns (WitnetRequestTemplate)
    {
        WitnetV2.RadonDataTypes _resultDataType;
        require(
            _sources.length > 0,
            "WitnetRequestTemplate: no sources"
        );
        // check all sources return the same data types, 
        // and whether any of them is parameterized
        bool _parameterized;
        for (uint _ix = 0; _ix < _sources.length; _ix ++) {
            if (_ix == 0) {
                _resultDataType = registry.lookupDataSourceResultDataType(_sources[_ix]);
            } else {
                require(
                    _resultDataType == registry.lookupDataSourceResultDataType(_sources[_ix]),
                    "WitnetRequestTemplate: mismatching sources"
                );
            }
            if (!_parameterized) {
                _parameterized = registry.lookupDataSourceArgsCount(_sources[_ix]) > 0;
            }
        }
        // revert if the aggregator reducer is unknown
        registry.lookupRadonReducer(_aggregatorId);
        // revert if the tally reducer is unknown
        registry.lookupRadonReducer(_tallyId);
        {
            WitnetRequestTemplateSlot storage __data = __witnetRequestTemplate();
            __data.parameterized = _parameterized;
            __data.aggregatorHash = _aggregatorId;
            __data.tallyHash = _tallyId;
            __data.resultDataType = _resultDataType;
            __data.resultDataMaxSize = _resultDataMaxSize;
            __data.sources = _sources;
        }
        return WitnetRequestTemplate(address(this));
    }
    
    function initializeWitnetRequest(
            address _from,
            bytes32 _radHash,
            string[][] memory _args
        )
        virtual public
        initializer
        returns (WitnetRequest)
    {
        WitnetRequestSlot storage __data = __witnetRequest();
        __data.args = _args;
        __data.curator = _from;
        __data.radHash = _radHash;
        __data.template = WitnetRequestTemplate(msg.sender);
        return WitnetRequest(address(this));
    }


    // ================================================================================================================
    // ---Overrides 'IERC165' -----------------------------------------------------------------------------------------

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 _interfaceId)
      public view
      virtual override
      returns (bool)
    {
        if (__witnetRequest().radHash != bytes32(0)) {
            return (
                _interfaceId == type(IWitnetRequest).interfaceId
                    || _interfaceId == type(WitnetRequest).interfaceId
                    || _interfaceId  == type(WitnetRequestTemplate).interfaceId
            );
        }
        else if (__witnetRequestTemplate().sources.length > 0) {
            return (_interfaceId == type(WitnetRequestTemplate).interfaceId);
        }
        else if (address(this) == __proxy()) {
            return (
                _interfaceId == type(IWitnetRequestFactory).interfaceId
                    || super.supportsInterface(_interfaceId)
            );
        }
        else {
            return (_interfaceId == type(Upgradeable).interfaceId);
        }
    }


    // ================================================================================================================
    // --- Overrides 'Ownable2Step' -----------------------------------------------------------------------------------

    /// @notice Returns the address of the pending owner.
    function pendingOwner()
        public view
        virtual override
        returns (address)
    {
        return __witnetRequestFactory().pendingOwner;
    }

    /// @notice Returns the address of the current owner.
    function owner()
        public view
        virtual override
        returns (address)
    {
        return __witnetRequestFactory().owner;
    }

    /// @notice Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
    /// @dev Can only be called by the current owner.
    function transferOwnership(address _newOwner)
        public
        virtual override
        onlyOwner
    {
        __witnetRequestFactory().pendingOwner = _newOwner;
        emit OwnershipTransferStarted(owner(), _newOwner);
    }

    /// @dev Transfers ownership of the contract to a new account (`_newOwner`) and deletes any pending owner.
    /// @dev Internal function without access restriction.
    function _transferOwnership(address _newOwner)
        internal
        virtual override
    {
        delete __witnetRequestFactory().pendingOwner;
        address _oldOwner = owner();
        if (_newOwner != _oldOwner) {
            __witnetRequestFactory().owner = _newOwner;
            emit OwnershipTransferred(_oldOwner, _newOwner);
        }
    }


    // ================================================================================================================
    // --- Overrides 'Upgradeable' -------------------------------------------------------------------------------------

    /// @notice Re-initialize contract's storage context upon a new upgrade from a proxy.
    /// @dev Must fail when trying to upgrade to same logic contract more than once.
    function initialize(bytes memory) 
        virtual override
        public
        onlyDelegateCalls
    {
        // WitnetRequest or WitnetRequestTemplate instances would already be initialized,
        // so only callable from proxies, in practice.

        address _owner = __witnetRequestFactory().owner;
        if (_owner == address(0)) {
            // set owner if none set yet
            _owner = msg.sender;
            __witnetRequestFactory().owner = _owner;
        } else {
            // only owner can initialize the proxy
            if (msg.sender != _owner) {
                revert WitnetUpgradableBase.OnlyOwner(_owner);
            }
        }

        if (__proxiable().proxy == address(0)) {
            // first initialization of the proxy
            __proxiable().proxy = address(this);
        }

        if (__proxiable().implementation != address(0)) {
            // same implementation cannot be initialized more than once:
            if(__proxiable().implementation == base()) {
                revert WitnetUpgradableBase.AlreadyUpgraded(base());
            }
        }        
        __proxiable().implementation = base();

        emit Upgraded(msg.sender, base(), codehash(), version());
    }

    /// Tells whether provided address could eventually upgrade the contract.
    function isUpgradableFrom(address _from) external view override returns (bool) {
        address _owner = __witnetRequestFactory().owner;
        return (
            // false if the WRB is intrinsically not upgradable, or `_from` is no owner
            isUpgradable()
                && _owner == _from
        );
    }


    // ================================================================================================================
    /// --- Clonable implementation and override ----------------------------------------------------------------------

    /// @notice Tells whether a WitnetRequest instance has been fully initialized.
    /// @dev True only on WitnetRequest instances with some Radon SLA set.
    function initialized()
        virtual override(Clonable, WitnetRequest)
        public view
        returns (bool)
    {
        return __witnetRequest().slaHash != bytes32(0);
    }

    /// @notice Contract address to which clones will be re-directed.
    function self()
        virtual override
        public view
        returns (address)
    {
        return (__proxy() != address(0)
            ? __implementation()
            : base()
        );
    }


    /// ===============================================================================================================
    /// --- IWitnetRequest implementation -----------------------------------------------------------------------------

    function bytecode() override external view returns (bytes memory) {
        return __witnetRequest().bytecode;
    }

    function hash() override external view returns (bytes32) {
        return __witnetRequest().hash;
    }


    /// ===============================================================================================================
    /// --- WitnetRequest implementation ------------------------------------------------------------------------------

    function args()
        override
        external view
        onlyDelegateCalls
        returns (string[][] memory)
    {
        return __witnetRequest().args;
    }

    function curator()
        override
        external view
        onlyDelegateCalls
        returns (address)
    {
        return __witnetRequest().curator;
    }

    function getRadonSLA()
        override
        external view
        onlyDelegateCalls
        returns (WitnetV2.RadonSLA memory)
    {
        return registry.lookupRadonSLA(
            __witnetRequest().slaHash
        );
    }

    function radHash()
        override
        external view
        onlyDelegateCalls
        returns (bytes32)
    {
        return __witnetRequest().radHash;
    }

    function slaHash() 
        override
        external view
        onlyDelegateCalls
        returns (bytes32)
    {
        return __witnetRequest().slaHash;
    }

    function template()
        override
        external view
        onlyDelegateCalls
        returns (WitnetRequestTemplate)
    {
        return __witnetRequest().template;
    }

    function modifySLA(WitnetV2.RadonSLA memory _sla)
        virtual override
        external
        onlyDelegateCalls
        returns (IWitnetRequest)
    {
        WitnetRequestTemplate _template = __witnetRequest().template;
        require(
            address(_template) != address(0),
            "WitnetRequestFactory: not a request"
        );
        require(
            msg.sender == __witnetRequest().curator,
            "WitnetRequest: not the curator"
        );
        bytes32 _slaHash = registry.verifyRadonSLA(_sla);
        WitnetRequestSlot storage __data = __witnetRequest();
        if (_slaHash != __data.slaHash) {
            bytes memory _bytecode = registry.bytecodeOf(__data.radHash, _slaHash);
            __data.bytecode = _bytecode;
            __data.hash = Witnet.hash(_bytecode);
            __data.slaHash = _slaHash;        
            emit WitnetRequestSettled(_sla);
        }
        return IWitnetRequest(address(this));
    }

    function version() 
        virtual override(WitnetRequest, WitnetRequestTemplate, WitnetUpgradableBase)
        public view
        returns (string memory)
    {
        return WitnetUpgradableBase.version();
    }


    /// ===============================================================================================================
    /// --- WitnetRequestTemplate implementation ----------------------------------------------------------------------

    function getDataSources()
        override
        external view
        onlyDelegateCalls
        returns (bytes32[] memory)
    {
        WitnetRequestTemplate _template = __witnetRequest().template;
        if (address(_template) != address(0)) {
            return _template.getDataSources();
        } else {
            return __witnetRequestTemplate().sources;
        }

    }

    function getDataSourcesCount() 
        override
        external view
        onlyDelegateCalls
        returns (uint256)
    {
        WitnetRequestTemplate _template = __witnetRequest().template;
        if (address(_template) != address(0)) {
            return _template.getDataSourcesCount();
        } else {
            return __witnetRequestTemplate().sources.length;
        }
    }

    function getRadonAggregatorHash()
        override
        external view
        onlyDelegateCalls
        returns (bytes32)
    {
        WitnetRequestTemplate _template = __witnetRequest().template;
        if (address(_template) != address(0)) {
            return _template.getRadonAggregatorHash();
        } else {
            return __witnetRequestTemplate().aggregatorHash;
        }
    }
    
    function getRadonTallyHash()
        override
        external view
        onlyDelegateCalls
        returns (bytes32)
    {
        WitnetRequestTemplate _template = __witnetRequest().template;
        if (address(_template) != address(0)) {
            return _template.getRadonTallyHash();
        } else {
            return __witnetRequestTemplate().tallyHash;
        }
    }
    
    function getResultDataMaxSize()
        override
        external view
        onlyDelegateCalls
        returns (uint16)
    {
        WitnetRequestTemplate _template = __witnetRequest().template;
        if (address(_template) != address(0)) {
            return _template.getResultDataMaxSize();
        } else {
            return __witnetRequestTemplate().resultDataMaxSize;
        }
    }

    function getResultDataType() 
        override
        external view
        onlyDelegateCalls
        returns (WitnetV2.RadonDataTypes)
    {
        WitnetRequestTemplate _template = __witnetRequest().template;
        if (address(_template) != address(0)) {
            return _template.getResultDataType();
        } else {
            return __witnetRequestTemplate().resultDataType;
        }
    }

    function lookupDataSourceByIndex(uint256 _index) 
        override
        external view
        onlyDelegateCalls
        returns (WitnetV2.DataSource memory)
    {
        WitnetRequestTemplate _template = __witnetRequest().template;
        if (address(_template) != address(0)) {
            return _template.lookupDataSourceByIndex(_index);
        } else {
            require(
                _index < __witnetRequestTemplate().sources.length,
                "WitnetRequestTemplate: out of range"
            );
            return registry.lookupDataSource(
                __witnetRequestTemplate().sources[_index]
            );
        }
    }

    function lookupRadonAggregator()
        override
        external view
        onlyDelegateCalls
        returns (WitnetV2.RadonReducer memory)
    {
        WitnetRequestTemplate _template = __witnetRequest().template;
        if (address(_template) != address(0)) {
            return _template.lookupRadonAggregator();
        } else {
            return registry.lookupRadonReducer(
                __witnetRequestTemplate().aggregatorHash
            );
        }
    }

    function lookupRadonTally()
        override
        external view
        onlyDelegateCalls
        returns (WitnetV2.RadonReducer memory)
    {
        WitnetRequestTemplate _template = __witnetRequest().template;
        if (address(_template) != address(0)) {
            return _template.lookupRadonTally();
        } else {
            return registry.lookupRadonReducer(
                __witnetRequestTemplate().tallyHash
            );
        }
    }

    function parameterized()
        override
        external view
        onlyDelegateCalls
        returns (bool)
    {
        WitnetRequestTemplate _template = __witnetRequest().template;
        if (address(_template) != address(0)) {
            return _template.parameterized();
        } else {
            return __witnetRequestTemplate().parameterized;
        }
    }

    function settleArgs(string[][] memory _args)
        virtual override
        external
        onlyOnTemplates
        returns (WitnetRequest _request)
    {
        WitnetRequestTemplateSlot storage __data = __witnetRequestTemplate();
        bytes32 _radHash = registry.verifyRadonRequest(
            __data.sources,
            __data.aggregatorHash,
            __data.tallyHash,
            __data.resultDataMaxSize,
            _args
        );
        bytes32 _salt = keccak256( 
            // As to avoid request address collisions from:
            abi.encodePacked( 
                // - different factory versions
                _WITNET_UPGRADABLE_VERSION,
                // - different curators
                msg.sender,
                // - different templates or args values
                _radHash
            )
        );
        address _address = address(uint160(uint256(keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                _salt,
                keccak256(_cloneBytecode())
            )
        ))));
        if (_address.code.length > 0) {
            _request = WitnetRequest(_address);
        } else {
            _request = WitnetRequestFactory(_cloneDeterministic(_salt))
                .initializeWitnetRequest(
                    msg.sender,
                    _radHash,
                    _args
                );
        }
        emit WitnetRequestTemplateSettled(_request, _radHash, _args);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IWitnetRequestBoardEvents.sol";
import "./interfaces/IWitnetRequestBoardReporter.sol";
import "./interfaces/IWitnetRequestBoardRequestor.sol";
import "./interfaces/IWitnetRequestBoardView.sol";
import "./interfaces/IWitnetRequestParser.sol";

/// @title Witnet Request Board functionality base contract.
/// @author The Witnet Foundation.
abstract contract WitnetRequestBoard is
    IWitnetRequestBoardEvents,
    IWitnetRequestBoardReporter,
    IWitnetRequestBoardRequestor,
    IWitnetRequestBoardView,
    IWitnetRequestParser
{}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./WitnetRequestBoard.sol";

/// @title The UsingWitnet contract
/// @dev Witnet-aware contracts can inherit from this contract in order to interact with Witnet.
/// @author The Witnet Foundation.
abstract contract UsingWitnet {

    WitnetRequestBoard public immutable witnet;

    /// Include an address to specify the WitnetRequestBoard entry point address.
    /// @param _wrb The WitnetRequestBoard entry point address.
    constructor(WitnetRequestBoard _wrb)
    {
        require(address(_wrb) != address(0), "UsingWitnet: zero address");
        witnet = _wrb;
    }

    /// Provides a convenient way for client contracts extending this to block the execution of the main logic of the
    /// contract until a particular request has been successfully solved and reported by Witnet.
    modifier witnetRequestSolved(uint256 _id) {
        require(
                _witnetCheckResultAvailability(_id),
                "UsingWitnet: request not solved"
            );
        _;
    }

    /// Check if a data request has been solved and reported by Witnet.
    /// @dev Contracts depending on Witnet should not start their main business logic (e.g. receiving value from third.
    /// parties) before this method returns `true`.
    /// @param _id The unique identifier of a previously posted data request.
    /// @return A boolean telling if the request has been already resolved or not. Returns `false` also, if the result was deleted.
    function _witnetCheckResultAvailability(uint256 _id)
        internal view
        virtual
        returns (bool)
    {
        return witnet.getQueryStatus(_id) == Witnet.QueryStatus.Reported;
    }

    /// Estimate the reward amount.
    /// @param _gasPrice The gas price for which we want to retrieve the estimation.
    /// @return The reward to be included when either posting a new request, or upgrading the reward of a previously posted one.
    function _witnetEstimateReward(uint256 _gasPrice)
        internal view
        virtual
        returns (uint256)
    {
        return witnet.estimateReward(_gasPrice);
    }

    /// Estimates the reward amount, considering current transaction gas price.
    /// @return The reward to be included when either posting a new request, or upgrading the reward of a previously posted one.
    function _witnetEstimateReward()
        internal view
        virtual
        returns (uint256)
    {
        return witnet.estimateReward(tx.gasprice);
    }

    /// Send a new request to the Witnet network with transaction value as a reward.
    /// @param _request An instance of `IWitnetRequest` contract.
    /// @return _id Sequential identifier for the request included in the WitnetRequestBoard.
    /// @return _reward Current reward amount escrowed by the WRB until a result gets reported.
    function _witnetPostRequest(IWitnetRequest _request)
        internal
        virtual
        returns (uint256 _id, uint256 _reward)
    {
        _reward = _witnetEstimateReward();
        require(
            _reward <= msg.value,
            "UsingWitnet: reward too low"
        );
        _id = witnet.postRequest{value: _reward}(_request);
    }

    /// Upgrade the reward for a previously posted request.
    /// @dev Call to `upgradeReward` function in the WitnetRequestBoard contract.
    /// @param _id The unique identifier of a request that has been previously sent to the WitnetRequestBoard.
    /// @return Amount in which the reward has been increased.
    function _witnetUpgradeReward(uint256 _id)
        internal
        virtual
        returns (uint256)
    {
        uint256 _currentReward = witnet.readRequestReward(_id);        
        uint256 _newReward = _witnetEstimateReward();
        uint256 _fundsToAdd = 0;
        if (_newReward > _currentReward) {
            _fundsToAdd = (_newReward - _currentReward);
        }
        witnet.upgradeReward{value: _fundsToAdd}(_id); // Let Request.gasPrice be updated
        return _fundsToAdd;
    }

    /// Read the Witnet-provided result to a previously posted request.
    /// @param _id The unique identifier of a request that was posted to Witnet.
    /// @return The result of the request as an instance of `Witnet.Result`.
    function _witnetReadResult(uint256 _id)
        internal view
        virtual
        returns (Witnet.Result memory)
    {
        return witnet.readResponseResult(_id);
    }

    /// Retrieves copy of all response data related to a previously posted request, removing the whole query from storage.
    /// @param _id The unique identifier of a previously posted request.
    /// @return The Witnet-provided result to the request.
    function _witnetDeleteQuery(uint256 _id)
        internal
        virtual
        returns (Witnet.Response memory)
    {
        return witnet.deleteQuery(_id);
    }

}

// SPDX-License-Identifier: MIT
// solhint-disable var-name-mixedcase

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "witnet-solidity-bridge/contracts/patterns/Upgradeable.sol";
import "witnet-solidity-bridge/contracts/impls/WitnetProxy.sol";

/// @title Witnet Request Board base contract, with an Upgradeable (and Destructible) touch.
/// @author The Witnet Foundation.
abstract contract WittyPixelsUpgradeableBase
    is
        Ownable2StepUpgradeable,
        ReentrancyGuardUpgradeable,
        Upgradeable
{
    bytes32 internal immutable _UPGRADABLE_VERSION_TAG;

    error AlreadyInitialized(address implementation);
    error NotCompliant(bytes4 interfaceId);
    error NotUpgradable(address self);
    error OnlyOwner(address owner);

    constructor(
            bool _upgradable,
            bytes32 _versionTag,
            string memory _proxiableUUID
        )
        Upgradeable(_upgradable)
    {
        _UPGRADABLE_VERSION_TAG = _versionTag;
        proxiableUUID = keccak256(bytes(_proxiableUUID));        
        // Logic-only instance will have no owner.
    }
    
    /// @dev Reverts if proxy delegatecalls to unexistent method.
    fallback() external { // solhint-disable
        revert("WittyPixelsUpgradeableBase: not implemented");
    }


    // ================================================================================================================
    // --- Overrides 'Proxiable' --------------------------------------------------------------------------------------

    /// @dev Gets immutable "heritage blood line" (ie. genotype) as a Proxiable, and eventually Upgradeable, contract.
    ///      If implemented as an Upgradeable touch, upgrading this contract to another one with a different 
    ///      `proxiableUUID()` value should fail.
    bytes32 public immutable override proxiableUUID;


    // ================================================================================================================
    // --- Overrides 'Upgradeable' --------------------------------------------------------------------------------------

    /// Tells whether provided address could eventually upgrade the contract.
    function isUpgradableFrom(address _from) external view override returns (bool) {
        return (
            // false if the WRB is intrinsically not upgradable, or `_from` is no owner
            isUpgradable()
                && _from == owner()
        );
    }

    
    /// Retrieves human-readable version tag of current implementation.
    function version() public view override returns (string memory) {
        return _toString(_UPGRADABLE_VERSION_TAG);
    }


    // ================================================================================================================
    // --- Internal methods -------------------------------------------------------------------------------------------

    /// Converts bytes32 into string.
    function _toString(bytes32 _bytes32)
        internal pure
        returns (string memory)
    {
        bytes memory _bytes = new bytes(_toStringLength(_bytes32));
        for (uint _i = 0; _i < _bytes.length;) {
            _bytes[_i] = _bytes32[_i];
            unchecked {
                _i ++;
            }
        }
        return string(_bytes);
    }

    // Calculate length of string-equivalent to given bytes32.
    function _toStringLength(bytes32 _bytes32)
        internal pure
        returns (uint _length)
    {
        for (; _length < 32; ) {
            if (_bytes32[_length] == 0) {
                break;
            }
            unchecked {
                _length ++;
            }
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITokenVaultWitnet.sol";
import "./ITokenVaultAuctionDutch.sol";

abstract contract IWittyPixelsTokenVault
    is
        ITokenVaultWitnet,
        ITokenVaultAuctionDutch
{
    event Donation(address from, address charity, uint256 value);

    struct Stats {
        uint256 redeemedPixels;
        uint256 redeemedPlayers;
        uint256 totalPixels;
        uint256 totalTransfers;
        uint256 totalWithdrawals;
        uint256 ethSoFarDonated;
    }

    enum Status {
        /* 0 */ Awaiting,
        /* 1 */ Randomizing,
        /* 2 */ Auctioning,
        /* 3 */ Acquired
    }

    /// @notice Returns number of legitimate players that have redeemed authorhsip of at least one pixel from the NFT token.
    function getAuthorsCount() virtual external view returns (uint256);

    /// @notice Returns range of authors's address and legacy pixels, as specified by `offset` and `count` params.
    function getAuthorsRange(uint offset, uint count) virtual external view returns (address[] memory, uint256[] memory);

    /// @notice Returns status data about the token vault contract, relevant from an UI/UX perspective
    /// @return status Enum value representing current contract status: Awaiting, Randomizing, Auctioning, Acquired
    /// @return stats Set of meters reflecting number of pixels, players, ERC20 transfers and withdrawls, up to date. 
    /// @return currentPrice Price in ETH/wei at which the whole NFT ownership can be bought, or at which it was actually sold.
    /// @return nextPriceTimestamp The approximate timestamp at which the currentPrice may change. Zero, if it's not expected to ever change again.
    function getInfo() virtual external view returns (
            Status  status,
            Stats memory stats,
            uint256 currentPrice,
            uint256 nextPriceTimestamp
        );

    /// @notice Returns Charity information related to this token vault contract.
    /// @return wallet The Charity EVM address where donations will be transferred to.
    /// @return percentage Percentage of the final price that will be eventually donated to the Charity wallet.
    /// @return ethSoFarDonated Cumuled amount of ETH that has been so far donated to the Charity wallet.
    function getCharityInfo() virtual external view returns (
            address wallet,
            uint8   percentage,
            uint256 ethSoFarDonated
        );

    /// @notice Gets info regarding a formerly verified player, given its index. 
    /// @return playerAddress Address from which the token's ownership was redeemed. Zero if this player hasn't redeemed ownership yet.
    /// @return redeemedPixels Number of pixels formerly redemeed by given player. 
    function getPlayerInfo(uint256) virtual external view returns (
            address playerAddress,
            uint256 redeemedPixels
        );

    /// @notice Returns set of meters reflecting number of pixels, players, ERC20 transfers, withdrawals, 
    /// @notice and totally donated funds up to now.
    function getStats() virtual external view returns (Stats memory stats);

    /// @notice Gets accounting info regarding given address.
    /// @return wpxBalance Current ERC20 balance.
    /// @return wpxShare10000 NFT ownership percentage based on current ERC20 balance, multiplied by 100.
    /// @return ethWithdrawable ETH/wei amount that can be potentially withdrawn from this address.
    /// @return soulboundPixels Soulbound pixels contributed from this wallet address, if any.    
    function getWalletInfo(address) virtual external view returns (
            uint256 wpxBalance,
            uint256 wpxShare10000,
            uint256 ethWithdrawable,
            uint256 soulboundPixels
        );

    /// @notice Returns sum of legacy pixels ever redeemed from the given address.
    /// The moral right over a player's finalized pixels is inalienable, so the value returned by this method
    /// will be preserved even though the player transfers ERC20/WPX tokens to other accounts, or if she decides to cash out 
    /// her share if the parent NFT token ever gets acquired. 
    function pixelsOf(address) virtual external view returns (uint256);

    /// @notice Returns total number of finalized pixels within the WittyPixels canvas.
    function totalPixels() virtual external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";
import "../WittyPixels.sol";

interface IWittyPixelsTokenAdmin {
    
    event Launched(uint256 tokenId, WittyPixels.ERC721TokenEvent theEvent);
    event Minting(uint256 tokenId, string baseURI, WitnetV2.RadonSLA witnetSLA);

    /// @notice Settle next token's event related metadata.
    /// @param theEvent Event metadata, including name, venut, starting and ending timestamps.
    /// @param theCharity Charity metadata, if any. Charity address and percentage > 0 must be provided.
    function launch(
            WittyPixels.ERC721TokenEvent calldata theEvent,
            WittyPixels.ERC721TokenCharity calldata theCharity
        ) external returns (uint256 tokenId);
    
    /// @notice Mint next WittyPixelsTM token: one new token id per ERC721TokenEvent where WittyPixelsTM is played.
    /// @param witnetSLA Witnessing SLA parameters of underlying data requests to be solved by the Witnet oracle.
    function mint(WitnetV2.RadonSLA calldata witnetSLA) external payable;

    /// @notice Sets collection's base URI.
    function setBaseURI(string calldata baseURI) external;

    /// @notice Sets token vault contract to be used as prototype in following mints.
    function setTokenVaultFactoryPrototype(address prototype) external;    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../WittyPixels.sol";

interface IWittyPixelsToken {

    /// ===============================================================================================================
    /// --- ERC721 extensions -----------------------------------------------------------------------------------------

    event MetadataUpdate(uint256 tokenId);
    
    function baseURI() external view returns (string memory);    
    function imageURI(uint256 tokenId) external view returns (string memory);    
    function metadata(uint256 tokenId) external view returns (string memory);    
    function totalSupply() external view returns (uint256);

    
    /// ===============================================================================================================
    /// --- WittyPixels token specific methods ------------------------------------------------------------------------


    /// @notice Returns WittyPixels token charity metadata of given token.
    function getTokenCharityValues(uint256 tokenId) external view returns (address walet, uint8 percentage);

    /// @notice Returns WittyPixels token metadata of given token.
    function getTokenMetadata(uint256 tokenId) external view returns (WittyPixels.ERC721Token memory);

    /// @notice Returns status of given WittyPixels token.
    /// @dev Possible values:
    /// @dev - 0 => Unknown, not yet launched
    /// @dev - 1 => Launched: info about the corresponding WittyPixels events has been provided by the collection's owner
    /// @dev - 2 => Minting: the token is being minted, awaiting for external data to be retrieved by the Witnet Oracle.
    /// @dev - 3 => Fracionalized: the token has been minted and its ownership transfered to a WittyPixelsTokenVault contract.
    /// @dev - 4 => Acquired: token's ownership has been acquired and belongs to the WittyPixelsTokenVault no more. 
    function getTokenStatus(uint256 tokenId) external view returns (WittyPixels.ERC721TokenStatus);
    
    /// @notice Returns literal string representing current status of given WittyPixels token.
    function getTokenStatusString(uint256 tokenId) external view returns (string memory);
    
    /// @notice Returns WittyPixelsTokenVault instance bound to the given token.
    /// @dev Reverts if the token has not yet been fractionalized.
    function getTokenVault(uint256 tokenId) external view returns (ITokenVaultWitnet);
    
    /// @notice Returns the identifiers of Witnet queries involved in the minting of given token.
    /// @dev Returns zeros if the token is yet in 'Unknown' or 'Launched' status.
    function getTokenWitnetQueries(uint256 tokenId) external view returns (WittyPixels.ERC721TokenWitnetQueries memory);

    /// @notice Returns Witnet data requests involved in the the minting of given token.
    /// @dev Returns zero addresses if the token is yet in 'Unknown' or 'Launched' status.
    function getTokenWitnetRequests(uint256 _tokenId) external view returns (WittyPixels.ERC721TokenWitnetRequests memory);
    
    /// @notice Returns number of pixels within the WittyPixels Canvas of given token.
    function pixelsOf(uint256 tokenId) external view returns (uint256);

    /// @notice Returns number of pixels contributed to given WittyPixels Canvas by given address.
    /// @dev Every WittyPixels player needs to claim contribution to a WittyPixels Canvas by calling 
    /// @dev to the `redeem(bytes deeds)` method on the corresponding token's vault contract.
    function pixelsFrom(uint256 tokenId, address from) external view returns (uint256);

    /// @notice Emits MetadataUpdate event as specified by EIP-4906.
    /// @dev Only acceptable if called from token's vault and given token is 'Fractionalized' status.
    function updateMetadataFromTokenVault(uint256 tokenId) external;

    /// @notice Verifies the provided Merkle Proof matches the token's authorship's root that
    /// @notice was retrieved by the Witnet Oracle upon minting of given token. 
    /// @dev Reverts if the token has not yet been fractionalized.
    function verifyTokenAuthorship(
            uint256 tokenId,
            uint256 playerIndex,
            uint256 playerPixels,
            bytes32[] calldata authorshipProof
        ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITokenVault.sol";

abstract contract ITokenVaultWitnet
    is
        ITokenVault
{
    function cloneAndInitialize(bytes calldata) virtual external returns (ITokenVaultWitnet);
    function cloneDeterministicAndInitialize(bytes32, bytes calldata) virtual external returns (ITokenVaultWitnet);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITokenVault.sol";

interface ITokenVaultFactory {
    
    /// @notice A new token has been fractionalized from this factory.
    event Fractionalized(
        address indexed from,   // owner of the token being fractionalized
        address indexed token,  // token collection address
        uint256 tokenId,        // token id
        address tokenVault      // token vault contract just created
    );

    /// @notice Fractionalize given token by transferring ownership to new instance of ERC-20 ERC721Token Vault. 
    /// @param token Address of ERC-721 collection.
    /// @param tokenId ERC721Token identifier within that collection.
    /// @param tokenVaultSettings Extra settings to be passed when initializing the token vault contract.
    function fractionalize(
            address token,
            uint256 tokenId,
            bytes   memory tokenVaultSettings
        )
        external returns (ITokenVault);
    
    /// @notice Gets indexed token vault contract created by this factory.
    /// @dev First created vault should be assigned index 1.
    function getTokenVaultByIndex(uint256 index) external view returns (ITokenVault);
    
    /// @notice Returns token vault prototype being instantiated when fractionalizing. 
    /// @dev If destructible, it must be owned by the factory contract.
    function getTokenVaultFactoryPrototype() external view returns (ITokenVault);

    /// @notice Returns number of vaults created so far.
    function totalTokenVaults() external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITokenVaultAuction.sol";

abstract contract ITokenVaultAuctionDutch
    is
        ITokenVaultAuction
{  
    struct Settings {
        uint256 deltaPrice;
        uint256 deltaSeconds;
        uint256 reservePrice;
        uint256 startingPrice;
        uint256 startingTs;
    }

    function acquire() virtual external payable;
    function getNextPriceTimestamp() virtual external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenVaultAuction {    
    event AuctionSettings(address indexed from, bytes settings);    
    function auctioning() external view returns (bool);
    function getPrice() external view returns (uint256);
    function getAuctionSettings() external view returns (bytes memory);
    function getAuctionType() external pure returns (bytes4);
    function setAuctionSettings(bytes calldata) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./IERC165.sol";
import "./IERC1633.sol";

abstract contract ITokenVault
    is 
        IERC20Upgradeable,
        IERC165,
        IERC1633
{
    event Acquired(address buyer, uint256 value);
    event Withdrawal(address from, uint256 value);

    /// @notice Returns whether this NFT vault has already been acquired. 
    function acquired() virtual external view returns (bool);

    /// @notice Address of the previous owner, the one that decided to fractionalize the NFT.
    function curator() virtual external view returns (address);

    /// @notice Redeems partial ownership of `parentTokenId` by providing valid ownership deeds.
    function redeem(bytes calldata deeds) virtual external;

    /// @notice Withdraw the proportional part of the acquisition value, according to caller's current balance.
    /// @dev Fails if not yet acquired. 
    function withdraw() virtual external returns (uint256);

    /// @notice Tells withdrawable amount in weis from given address.
    /// @dev Returns 0 in all cases while not yet acquired. 
    function withdrawableFrom(address from) virtual external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/// @title EIP-1633: Re-Fungible ERC721Token Standard (RFT)
/// @dev https://eips.ethereum.org/EIPS/eip-1633
interface IERC1633 /* is ERC20, ERC165 */ {
    /// @dev Note: the ERC-165 identifier for this interface is 0x5755c3f2.
    function parentToken() external view returns(address _parentToken);
    function parentTokenId() external view returns(uint256 _parentTokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./WittyPixels.sol";

import "witnet-solidity-bridge/contracts/WitnetRequestBoard.sol";
import "witnet-solidity-bridge/contracts/apps/WitnetRequestFactory.sol";
import "witnet-solidity-bridge/contracts/libs/WitnetLib.sol";

/// @title  WittyPixelsLib - Deployable library containing helper methods.
/// @author Otherplane Labs Ltd., 2023

library WittyPixelsLib {

    using WitnetCBOR for WitnetCBOR.CBOR;
    using WitnetLib for Witnet.Result;
    using WittyPixelsLib for WitnetRequestBoard;

    /// ===============================================================================================================
    /// --- Witnet-related helper functions ---------------------------------------------------------------------------

    /// @dev Helper function for building the HTTP/GET parameterized requests
    /// @dev from which specific data requests will be created and sent
    /// @dev to the Witnet decentralized oracle every time a new token of
    /// @dev athe ERC721 collection is minted.
    function buildHttpRequestTemplates(WitnetRequestFactory factory)
        public
        returns (
            WitnetRequestTemplate imageDigestRequestTemplate,
            WitnetRequestTemplate valuesArrayRequestTemplate
        )
    {
        IWitnetBytecodes registry = factory.registry();
        
        bytes32 httpGetImageDigest;
        bytes32 httpGetValuesArray;
        bytes32 reducerModeNoFilters;

        /// Verify that need witnet radon artifacts are actually valid and known by the factory:
        {
            httpGetImageDigest = registry.verifyDataSource(
                /* requestMethod */    WitnetV2.DataRequestMethods.HttpGet,
                /* requestSchema */    "",
                /* requestAuthority */ "\\0\\",         // => will be substituted w/ WittyPixelsLib.baseURI() on next mint
                /* requestPath */      "image/\\1\\",   // => will by substituted w/ tokenId on next mint
                /* requestQuery */     "digest=sha-256",
                /* requestBody */      "",
                /* requestHeader */    new string[2][](0),
                /* requestScript */    hex"80"
                                       // <= WitnetScript([ Witnet.TYPES.STRING ])
            );
            httpGetValuesArray = registry.verifyDataSource(
                /* requestMethod    */ WitnetV2.DataRequestMethods.HttpGet,
                /* requestSchema    */ "",
                /* requestAuthority */ "\\0\\",         // => will be substituted w/ WittyPixelsLib.baseURI() on every new mint
                /* requestPath      */ "stats/\\1\\",   // => will by substituted w/ tokenId on next mint
                /* requestQuery     */ "",
                /* requestBody      */ "",
                /* requestHeader    */ new string[2][](0),
                /* requestScript    */ hex"8218771869"
                                       // <= WitnetScript([ Witnet.TYPES.STRING ]).parseJSONMap().valuesAsArray()
            );
            reducerModeNoFilters = registry.verifyRadonReducer(
                WitnetV2.RadonReducer({
                    opcode: WitnetV2.RadonReducerOpcodes.Mode,
                    filters: new WitnetV2.RadonFilter[](0),
                    script: hex""
                })
            );
        }
        /// Use WitnetRequestFactory for building actual witnet request templates
        /// that will be parameterized w/ specific SLA valus on every new mint:  
        {
            bytes32[] memory retrievals = new bytes32[](1);
            {
                retrievals[0] = httpGetImageDigest;
                imageDigestRequestTemplate = factory.buildRequestTemplate(
                    /* retrieval templates */ retrievals,
                    /* aggregation reducer */ reducerModeNoFilters,
                    /* witnessing reducer  */ reducerModeNoFilters,
                    /* (reserved) */ 0
                );
            }
            {
                retrievals[0] = httpGetValuesArray;
                valuesArrayRequestTemplate = factory.buildRequestTemplate(
                    /* retrieval templates */ retrievals,
                    /* aggregation reducer */ reducerModeNoFilters,
                    /* witnessing reducer  */ reducerModeNoFilters,
                    /* (reserved) */ 0
                );
            }
        }
    }

    /// @notice Checks availability of Witnet responses to http/data queries, trying
    /// @notice to deserialize Witnet results into valid token metadata.
    /// @notice into a Solidity string.
    /// @dev Reverts should any of the http/requests failed, or if not able to deserialize result data.
    function fetchWitnetResults(
            WittyPixels.TokenStorage storage self, 
            WitnetRequestBoard witnet, 
            uint256 tokenId
        )
        public
    {
        WittyPixels.ERC721Token storage __token = self.items[tokenId];
        WittyPixels.ERC721TokenWitnetQueries storage __witnetQueries = self.tokenWitnetQueries[tokenId];
        // Revert if any of the witnet queries was not yet solved
        {
            if (
                !witnet.checkResultAvailability(__witnetQueries.imageDigestId)
                    || !witnet.checkResultAvailability(__witnetQueries.tokenStatsId)
            ) {
                revert("awaiting response from Witnet");
            }
        }
        Witnet.Response memory _witnetResponse; Witnet.Result memory _witnetResult;
        // Try to read response to 'image-digest' query, 
        // while freeing some storage from the Witnet Request Board:
        {
            _witnetResponse = witnet.fetchResponse(__witnetQueries.imageDigestId);
            _witnetResult = WitnetLib.resultFromCborBytes(_witnetResponse.cborBytes);
            {
                // Revert if the Witnet query failed:
                require(
                    _witnetResult.success,
                    "'image-digest' query failed"
                );
                // Revert if the Witnet response was previous to when minting started:
                require(
                    _witnetResponse.timestamp >= __token.birthTs,
                    "anachronic 'image-digest' result"
                );
            }
            // Deserialize http/response to 'image-digest':
            __token.imageDigest = _witnetResult.value.readString();
            __token.imageDigestWitnetTxHash = _witnetResponse.drTxHash;
        }
        // Try to read response to 'token-stats' query, 
        // while freeing some storage from the Witnet Request Board:
        {
            _witnetResponse = witnet.fetchResponse(__witnetQueries.tokenStatsId);
            _witnetResult = WitnetLib.resultFromCborBytes(_witnetResponse.cborBytes);
            {
                // Revert if the Witnet query failed:
                require(
                    _witnetResult.success,
                    "'token-stats' query failed"
                );
                // Revert if the Witnet response was previous to when minting started:
                require(
                    _witnetResponse.timestamp >= __token.birthTs, 
                    "anachronic 'token-stats' result");
            }
            // Try to deserialize Witnet response to 'token-stats':
            __token.theStats = toERC721TokenStats(_witnetResult.value);
        }
    }

    /// @dev Check if a some previsouly posted request has been solved and reported from Witnet.
    function checkResultAvailability(
            WitnetRequestBoard witnet,
            uint256 witnetQueryId
        )
        internal view
        returns (bool)
    {
        return witnet.getQueryStatus(witnetQueryId) == Witnet.QueryStatus.Reported;
    }

    /// @dev Retrieves copy of all response data related to a previously posted request, 
    /// @dev removing the whole query from storage.
    function fetchResponse(
            WitnetRequestBoard witnet,
            uint256 witnetQueryId
        )
        internal
        returns (Witnet.Response memory)
    {
        return witnet.deleteQuery(witnetQueryId);
    }

    /// @dev Deserialize a CBOR-encoded data request result from Witnet 
    /// @dev into a WittyPixels.ERC721TokenStats structure
    function toERC721TokenStats(WitnetCBOR.CBOR memory cbor)
        internal pure
        returns (WittyPixels.ERC721TokenStats memory)
    {
        WitnetCBOR.CBOR[] memory fields = cbor.readArray();
        if (fields.length >= 7) {
            return WittyPixels.ERC721TokenStats({
                canvasHeight: fields[0].readUint(),
                canvasPixels: fields[1].readUint(),
                canvasRoot:   toBytes32(fromHex(fields[2].readString())),
                canvasWidth:  fields[3].readUint(),
                totalPixels:  fields[4].readUint(),
                totalPlayers: fields[5].readUint(),
                totalScans:   fields[6].readUint()
            });
        } else {
            revert("WittyPixelsLib: missing fields");
        }
    }
    

    /// ===============================================================================================================
    /// --- WittyPixels-related helper methods ------------------------------------------------------------------------

    /// @dev Returns JSON string containing the metadata of given tokenId
    /// @dev following an OpenSea-compatible schema.
    function toJSON(
            WittyPixels.ERC721Token memory self,
            uint256 tokenId,
            address tokenVaultAddress,
            uint256 redeemedPixels,
            uint256 ethSoFarDonated
        )
        public pure
        returns (string memory)
    {
        string memory _name = string(abi.encodePacked(
            "\"name\": \"", self.theEvent.name, "\","
        ));
        string memory _description = string(abi.encodePacked(
            "\"description\": \"",
            _loadJsonDescription(self, tokenId, tokenVaultAddress),
            "\","
        ));
        string memory _externalUrl = string(abi.encodePacked(
            "\"external_url\": \"https://witnet.io\","
        ));
        string memory _image = string(abi.encodePacked(
            "\"image\": \"", tokenImageURI(tokenId, self.baseURI), "\","
        ));
        string memory _attributes = string(abi.encodePacked(
            "\"attributes\": [",
            _loadJsonAttributes(self, redeemedPixels, ethSoFarDonated),
            "]"
        ));
        return string(abi.encodePacked(
            "{", _name, _description, _externalUrl, _image, _attributes, "}"
        ));
    }

    function tokenImageURI(uint256 tokenId, string memory baseURI)
        internal pure
        returns (string memory)
    {
        return string(abi.encodePacked(
            baseURI,
            "/image/",
            toString(tokenId)
        ));
    }

    function tokenMetadataURI(uint256 tokenId, string memory baseURI)
        internal pure
        returns (string memory)
    {
        return string(abi.encodePacked(
            baseURI,
            "/metadata/",
            toString(tokenId)
        ));
    }

    function tokenStatsURI(uint256 tokenId, string memory baseURI)
        internal pure
        returns (string memory)
    {
        return string(abi.encodePacked(
            baseURI,
            "/stats/",
            toString(tokenId)
        ));
    }
    
    function checkBaseURI(string memory uri)
        internal pure
        returns (string memory)
    {
        require((
            bytes(uri).length > 0
                && bytes(uri)[
                    bytes(uri).length - 1
                ] != bytes1("/")
            ), "WittyPixelsLib: bad uri"
        );
        return uri;
    }

    function fromHex(string memory s)
        internal pure
        returns (bytes memory)
    {
        bytes memory ss = bytes(s);
        assert(ss.length % 2 == 0);
        bytes memory r = new bytes(ss.length / 2);
        unchecked {
            for (uint i = 0; i < ss.length / 2; i ++) {
                r[i] = bytes1(
                    fromHexChar(uint8(ss[2 * i])) * 16
                        + fromHexChar(uint8(ss[2 * i + 1]))
                );
            }
        }
        return r;
    }

    function fromHexChar(uint8 c)
        internal pure
        returns (uint8)
    {
        if (
            bytes1(c) >= bytes1("0")
                && bytes1(c) <= bytes1("9")
        ) {
            return c - uint8(bytes1("0"));
        } else if (
            bytes1(c) >= bytes1("a")
                && bytes1(c) <= bytes1("f")
        ) {
            return 10 + c - uint8(bytes1("a"));
        } else if (
            bytes1(c) >= bytes1("A")
                && bytes1(c) <= bytes1("F")
        ) {
            return 10 + c - uint8(bytes1("A"));
        } else {
            revert("WittyPixelsLib: invalid hex");
        }
    }

    function hash(bytes32 a, bytes32 b)
        internal pure
        returns (bytes32)
    {
        return (a < b 
            ? _hash(a, b)
            : _hash(b, a)
        );
    }

    function merkle(bytes32[] memory proof, bytes32 leaf)
        internal pure
        returns (bytes32 root)
    {
        root = leaf;
        for (uint i = 0; i < proof.length; i ++) {
            root = hash(root, proof[i]);
        }
    }

    /// Recovers address from hash and signature.
    function recoverAddr(bytes32 hash_, bytes memory signature)
        internal pure
        returns (address)
    {
        if (signature.length != 65) {
            return (address(0));
        }
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }
        if (v != 27 && v != 28) {
            return address(0);
        }
        return ecrecover(hash_, v, r, s);
    }   

    function slice(bytes memory src, uint offset)
        internal pure
        returns (bytes memory dest)
    {
        assert(offset < src.length);
        unchecked {
            uint srcPtr;
            uint destPtr;
            uint len = src.length - offset;
            assembly {
                srcPtr := add(src, add(32, offset))
                destPtr:= add(dest, 32)
                mstore(dest, len)
            }
            _memcpy(
                destPtr,
                srcPtr,
                len
            );
        }
    }

    function toBytes32(bytes memory _value) internal pure returns (bytes32) {
        return toFixedBytes(_value, 32);
    }

    function toFixedBytes(bytes memory _value, uint8 _numBytes)
        internal pure
        returns (bytes32 _bytes32)
    {
        assert(_numBytes <= 32);
        unchecked {
            uint _len = _value.length > _numBytes ? _numBytes : _value.length;
            for (uint _i = 0; _i < _len; _i ++) {
                _bytes32 |= bytes32(_value[_i] & 0xff) >> (_i * 8);
            }
        }
    }

    bytes16 private constant _HEX_SYMBOLS_ = "0123456789abcdef";

    /// @dev Converts a `uint256` to its ASCII `string` decimal representation.
    function toString(uint256 value)
        internal pure
        returns (string memory)
    {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _HEX_SYMBOLS_))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /// @dev Converts an `address` to its hex `string` representation with no "0x" prefix.
    function toHexString(address value)
        internal pure
        returns (string memory)
    {
        return toHexString(abi.encodePacked(value));
    }

    /// @dev Converts a `bytes32` value to its hex `string` representation with no "0x" prefix.
    function toHexString(bytes32 value)
        internal pure
        returns (string memory)
    {
        return toHexString(abi.encodePacked(value));
    }

    /// @dev Converts a bytes buff to its hex `string` representation with no "0x" prefix.
    function toHexString(bytes memory buf)
        internal pure
        returns (string memory)
    {
        unchecked {
            bytes memory str = new bytes(buf.length * 2);
            for (uint i = 0; i < buf.length; i++) {
                str[i*2] = _HEX_SYMBOLS_[uint(uint8(buf[i] >> 4))];
                str[i*2 + 1] = _HEX_SYMBOLS_[uint(uint8(buf[i] & 0x0f))];
            }
            return string(str);
        }
    }

    // @dev Converts a `bytes7`value to its hex `string`representation with no "0x" prefix.
    function toHexString7(bytes7 value)
        internal pure
        returns (string memory)
    {
        return toHexString(abi.encodePacked(value));
    }


    // ================================================================================================================
    // --- WittyPixelsLib private methods ----------------------------------------------------------------------------

    function _loadJsonAttributes(
            WittyPixels.ERC721Token memory self,
            uint256 redeemedPixels,
            uint256 ethSoFarDonated
        )
        private pure
        returns (string memory)
    {
        string memory _eventName = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Event Name\",",
                "\"value\": \"", self.theEvent.name, "\"",
            "},"
        ));
        string memory _eventVenue = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Event Venue\",",
                "\"value\": \"", self.theEvent.venue, "\"",
            "},"
        ));
        string memory _eventWhereabouts = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Event Whereabouts\",",
                "\"value\": \"", self.theEvent.whereabouts, "\"",
            "},"
        ));
        string memory _eventStartDate = string(abi.encodePacked(
             "{",
                "\"display_type\": \"date\",",
                "\"trait_type\": \"Kick-off Date\",",
                "\"value\": ", toString(self.theEvent.startTs),
            "},"
        ));
        string memory _totalPlayers = string(abi.encodePacked(
            "{", 
                "\"trait_type\": \"Total Players\",",
                "\"value\": ", toString(self.theStats.totalPlayers),
            "},"
        ));
        string memory _totalScans = string(abi.encodePacked(
            "{", 
                "\"trait_type\": \"Total Scans\",",
                "\"value\": ", toString(self.theStats.totalScans),
            "}"
        ));
        return string(abi.encodePacked(
            _eventName,
            _eventVenue,
            _eventWhereabouts,
            _eventStartDate,
            _loadJsonCharityAttributes(self, ethSoFarDonated),
            _loadJsonCanvasAttributes(self, redeemedPixels),
            _totalPlayers,
            _totalScans
        ));
    }

    function _loadJsonCanvasAttributes(
            WittyPixels.ERC721Token memory self,
            uint256 redeemedPixels
        )
        private pure
        returns (string memory)
    {
        string memory _authorsRoot = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Authors' Root\",",
                "\"value\": \"", toHexString7(bytes7(self.theStats.canvasRoot)), "\"",
            "},"
        ));
        string memory _canvasDate = string(abi.encodePacked(
             "{",
                "\"display_type\": \"date\",",
                "\"trait_type\": \"Minting Date\",",
                "\"value\": ", toString(self.birthTs),
            "},"
        ));
        string memory _canvasDigest = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Canvas Digest\",",
                "\"value\": \"", self.imageDigest, "\"",
            "},"
        )); 
        string memory _canvasHeight = string(abi.encodePacked(
             "{",
                "\"display_type\": \"number\",",
                "\"trait_type\": \"Canvas Height\",",
                "\"value\": ", toString(self.theStats.canvasHeight),
            "},"
        ));    
        string memory _canvasWidth = string(abi.encodePacked(
             "{",
                "\"display_type\": \"number\",",
                "\"trait_type\": \"Canvas Width\",",
                "\"value\": ", toString(self.theStats.canvasWidth),
            "},"
        ));
        string memory _canvasPixels = string(abi.encodePacked(
            "{", 
                "\"trait_type\": \"Canvas Pixels\",",
                "\"value\": ", toString(self.theStats.canvasPixels),
            "},"
        ));
        string memory _canvasOverpaint;
        if (
            self.theStats.totalPixels > 0
                && self.theStats.totalPixels > self.theStats.canvasPixels
        ) {
            uint _index = 100 * (self.theStats.totalPixels - self.theStats.canvasPixels);
            _index /= self.theStats.totalPixels;
            _canvasOverpaint = string(abi.encodePacked(
                "{",
                    "\"display_type\": \"boost_percentage\",",
                    "\"trait_type\": \"Canvas Rivalry Index\",",
                    "\"value\": ", toString(_index),
                "},"
            ));
        }
        string memory _canvasParticipation;
        if (
            self.theStats.totalScans >= self.theStats.totalPlayers
        ) {
            uint _index = 100 * (self.theStats.totalScans - self.theStats.totalPlayers);
            _index /= self.theStats.totalScans;
            _canvasParticipation = string(abi.encodePacked(
                "{",
                    "\"display_type\": \"boost_percentage\",",
                    "\"trait_type\": \"Canvas Interactivity Index\",",
                    "\"value\": ", toString(_index),
                "},"
            ));
        }
        string memory _canvasRedemption;
        uint _redemptionRatio = (100 * redeemedPixels) / self.theStats.canvasPixels;
        if (_redemptionRatio > 0) {
            _canvasRedemption = string(abi.encodePacked(
                "{",
                    "\"display_type\": \"boost_percentage\",",
                    "\"trait_type\": \"$WPX Redemption Ratio\",",
                    "\"value\": ", toString(_redemptionRatio),
                "},"
            ));
        }
        return string(abi.encodePacked(
            _authorsRoot,
            _canvasDate,
            _canvasDigest,
            _canvasHeight,            
            _canvasWidth,
            _canvasPixels,
            _canvasOverpaint,
            _canvasParticipation,
            _canvasRedemption
        ));
    }

    function _loadJsonCharityAttributes(
            WittyPixels.ERC721Token memory self,
            uint256 ethSoFarDonated
        )
        private pure
        returns (string memory)
    {
        string memory _charityAddress;
        string memory _charityDonatedETH;
        string memory _charityPercentage;
        if (self.theCharity.wallet != address(0)) {
            _charityAddress = string(abi.encodePacked(
                "{",
                    "\"trait_type\": \"Charity Wallet\",",
                    "\"value\": \"0x", toHexString(self.theCharity.wallet), "\"",
                "},"
            ));
            uint _eth100 = (100 * ethSoFarDonated) / 10 ** 18;
            if (_eth100 > 0) {
                _charityDonatedETH = string(abi.encodePacked(
                    "{",
                        "\"trait_type\": \"Charity Donations\",",
                        "\"value\": \"", _fixed2String(_eth100), " ETH\"",
                    "},"
                ));
            }
            _charityPercentage = string(abi.encodePacked(
                "{",
                    "\"display_type\": \"boost_number\",",
                    "\"trait_type\": \"Charitable Cause Percentage\",",
                    "\"max_value\": 100,",
                    "\"value\": ", toString(self.theCharity.percentage),
                "},"
            ));
        }
        return string(abi.encodePacked(
                _charityAddress,
                _charityDonatedETH,
                _charityPercentage
            ));
    }

    function _loadJsonDescription(
            WittyPixels.ERC721Token memory self,
            uint256 tokenId,
            address tokenVaultAddress
        )
        private pure
        returns (string memory)
    {
        string memory _tokenIdStr = toString(tokenId);
        string memory _totalPlayersString = toString(self.theStats.totalPlayers);
        string memory _radHashHexString = toHexString(self.tokenStatsWitnetRadHash);
        string memory _charityDescription;
        if (self.theCharity.wallet != address(0)) {
            _charityDescription = string(abi.encodePacked(
                "See actual donations in [Etherscan](https://etherscan.io/address/0x",
                toHexString(self.theCharity.wallet), "?fromaddress=0x",
                toHexString(tokenVaultAddress), "). ",
                (bytes(self.theCharity.description).length > 0
                    ? self.theCharity.description
                    : string(hex"")
                )
            ));
        }
        return string(abi.encodePacked(
            "WittyPixelsTM collaborative art canvas #", _tokenIdStr, " drawn by ", _totalPlayersString,
            " attendees during <b>", self.theEvent.name, "</b> in ", self.theEvent.venue, 
            ". This token was fractionalized and secured by the [Witnet multichain",
            " oracle](https://witnet.io). Historical WittyPixelsTM game info and",
            " authors' root can be audited with [Witnet's block explorer](https://witnet.network/search/",
            _radHashHexString, "). ", _charityDescription          
        ));
    }

    function _fixed2String(uint value)
        private pure
        returns (string memory)
    {
        uint _int = value / 100;
        uint _decimals = value - _int;
        return string(abi.encodePacked(
            toString(_int),
            ".",
            _decimals < 10 ? "0" : "",
            toString(_decimals)
        ));
    }

    function _hash(bytes32 a, bytes32 b)
        private pure
        returns (bytes32 value)
    {
        assembly {
            mstore(0x0, a)
            mstore(0x20, b)
            value := keccak256(0x0, 0x40)
        }
    }

    function _memcpy(
            uint _dest,
            uint _src,
            uint _len
        )
        private pure
    {
        // Copy word-length chunks while possible
        for (; _len >= 32; _len -= 32) {
            assembly {
                mstore(_dest, mload(_src))
            }
            _dest += 32;
            _src += 32;
        }
        if (_len > 0) {
            // Copy remaining bytes
            uint _mask = 256 ** (32 - _len) - 1;
            assembly {
                let _srcpart := and(mload(_src), not(_mask))
                let _destpart := and(mload(_dest), _mask)
                mstore(_dest, or(_destpart, _srcpart))
            }
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "witnet-solidity-bridge/contracts/requests/WitnetRequest.sol";
import "./interfaces/IWittyPixelsTokenVault.sol";

/// @title  WittyPixels - Library containing both ERC721 and ERC20 data models
/// @author Otherplane Labs Ltd., 2023

library WittyPixels {

    /// ===============================================================================================================
    /// --- WITTYPIXELS DATA MODEL ------------------------------------------------------------------------------------
    
    bytes32 internal constant WPX_TOKEN_SLOTHASH =
        /* keccak256("art.wittypixels.token") */
        0xa1c65a69721a75d8ec79c686c8573bd06e7f0c400997cbe153064301cbc480d5;
    
    bytes32 internal constant WPX_TOKEN_VAULT_SLOTHASH =
        /* keccak256("art.wittypixels.token.vault") */
        0x3c39a4bcf91d618a40909e659271a0d850789843a1b2ede0bffa31cd98ff6976;

    struct TokenInitParams {
        string baseURI;
        string name;
        string symbol;
    }

    struct TokenStorage {
        // --- ERC721
        string  baseURI;
        uint256 totalSupply;
        mapping (uint256 => ERC721Token) items;
        
        // --- ITokenVaultFactory
        IWittyPixelsTokenVault tokenVaultPrototype;
        uint256 totalTokenVaults;
        mapping (uint256 => IWittyPixelsTokenVault) vaults;

        // --- WittyPixelsToken
        WitnetRequest imageDigestRequest;
        WitnetRequest tokenStatsRequest;
        mapping (uint256 => ERC721TokenWitnetQueries) tokenWitnetQueries;
        mapping (uint256 => ERC721TokenWitnetRequests) tokenWitnetRequests;
    }

    enum ERC721TokenStatus {
        Void,
        Launching,
        Minting,
        Fractionalized,
        Acquired
    }

    struct ERC721Token {
        string  baseURI;
        uint256 birthTs;        
        string  imageDigest;
        bytes32 imageDigestWitnetTxHash;         
        bytes32 tokenStatsWitnetRadHash;
        ERC721TokenEvent theEvent;
        ERC721TokenStats theStats;
        ERC721TokenCharity theCharity;
    }
    
    struct ERC721TokenEvent {
        string  name;
        string  venue;
        string  whereabouts;
        uint256 startTs;
        uint256 endTs;
    }

    struct ERC721TokenStats {
        uint256 canvasHeight;
        uint256 canvasPixels;
        bytes32 canvasRoot;
        uint256 canvasWidth;
        uint256 totalPixels;
        uint256 totalPlayers;
        uint256 totalScans;
    }

    struct ERC721TokenCharity {
        string  description;
        uint8   percentage; 
        address wallet;
    }
    
    struct ERC721TokenWitnetQueries {
        uint256 imageDigestId;
        uint256 tokenStatsId;
    }

    struct ERC721TokenWitnetRequests {
        WitnetRequest imageDigest;
        WitnetRequest tokenStats;
    }

    struct TokenVaultOwnershipDeeds {
        address parentToken;
        uint256 parentTokenId;
        address playerAddress;
        uint256 playerIndex;
        uint256 playerPixels;
        bytes32[] playerPixelsProof;
        bytes signature;
    }

    struct TokenVaultInitParams {
        address curator;
        string  name;
        bytes   settings;
        string  symbol;
        address token;
        uint256 tokenId;
        uint256 tokenPixels;
    }

    struct TokenVaultStorage {
        // --- IERC1633
        address parentToken;
        uint256 parentTokenId;

        // --- IWittyPixelsTokenVault
        address curator;
        uint256 finalPrice;
        
        ITokenVaultAuctionDutch.Settings settings;
        IWittyPixelsTokenVault.Stats stats;
        
        address[] authors;
        mapping (address => uint256) legacyPixels;
        mapping (address => bool) redeemed;
        mapping (uint256 => TokenVaultPlayerInfo) players;

        TokenVaultCharity charity;
    }

    struct TokenVaultPlayerInfo {
        address addr;
        uint256 pixels;
    }

    struct TokenVaultCharity {
        uint8 percentage;
        address wallet;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}