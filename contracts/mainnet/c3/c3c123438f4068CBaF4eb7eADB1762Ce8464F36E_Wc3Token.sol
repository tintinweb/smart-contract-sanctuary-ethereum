// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./IWitnetPriceFeed.sol";

import "./IWc3Admin.sol";
import "./IWc3Events.sol";
import "./IWc3Surrogates.sol";
import "./IWc3View.sol";

/// @title Witty Creatures 3.0 - ERC721 Token contract
/// @author Otherplane Labs, 2022.
contract Wc3Token
    is
        ERC721,
        Ownable,
        ReentrancyGuard,
        IWc3Admin,
        IWc3Events,
        IWc3Surrogates,
        IWc3View
{
    using Strings for uint256;
    using Wc3Lib for bytes32;
    using Wc3Lib for string;
    using Wc3Lib for Wc3Lib.Status;
    using Wc3Lib for Wc3Lib.Storage;
    using Wc3Lib for Wc3Lib.WittyCreatureStatus;

    IWitnetRandomness immutable public override randomizer;
    IWitnetPriceRouter immutable public override router;
    uint256 immutable override public guildId;
    bytes32 immutable override public usdPriceAssetId;

    bytes32 immutable internal __version;
    Wc3Lib.Storage internal __storage;    

    modifier inStatus(Wc3Lib.Status _status) {
        require(
            __storage.status(randomizer) == _status,
            Wc3Lib.statusRevertMessage(_status)
        );
        _;
    }

    modifier selfMintUsdCost6(uint _tokenId) {
        uint _initGas = gasleft();
        {
            _;
        }
        Wc3Lib.WittyCreature storage __wc3 = __storage.intrinsics[_tokenId];
        (int _lastPrice, bytes32 _witnetProof) = _estimateUsdPrice6();
        __wc3.mintBlock = block.number;
        __wc3.mintGasPrice = tx.gasprice;
        __wc3.mintTimestamp = block.timestamp;
        __wc3.mintUsdPriceWitnetProof = _witnetProof;
        uint _mintGas = __storage.mintGasOverhead + _initGas - gasleft();
        __wc3.mintGas = _mintGas;
        __wc3.mintUsdCost6 = (uint(_lastPrice) * tx.gasprice * _mintGas) / 10 ** 18; 
    }

    modifier tokenExists(uint256 _tokenId) {
        require(
            _exists(_tokenId),
            "Wc3Token: void token"
        );
        _;
    }

    constructor(
            string memory _version,
            address _randomizer,
            address _router,
            address _decorator,
            address _signator,
            uint8[] memory _percentileMarks,
            uint256 _expirationBlocks,
            uint256 _totalEggs,
            string memory _usdPriceCaption,
            uint256 _mintGasOverhead            
        )
        ERC721("Witty Creatures EthCC'5", "WC3")
    {
        assert(_randomizer != address(0));
        assert(_router != address(0));

        guildId = block.chainid;        
        __version = _version.toBytes32();      

        randomizer = IWitnetRandomness(_randomizer);
        router = IWitnetPriceRouter(_router);

        setDecorator(
            IWc3Decorator(_decorator)
        );
        setMintGasOverhead(
            _mintGasOverhead
        );
        setSettings(
            _expirationBlocks,
            _totalEggs,
            _percentileMarks
        );
        setSignator(
            _signator
        );        

        usdPriceAssetId = router.currencyPairId(_usdPriceCaption);
        require(
            router.supportsCurrencyPair(usdPriceAssetId),
            string(abi.encodePacked(
                bytes("Wc3Token: unsupported currency pair: "),
                _usdPriceCaption
            ))
        );
    }

    /// @dev Required for receiving unused funds back when calling to `randomizer.randomize()`
    receive() external payable {}


    // ========================================================================
    // --- 'ERC721Metadata' overriden functions -------------------------------
  
    function baseURI()
        public view
        virtual
        returns (string memory)
    {
        return decorator().baseURI();
    }
    
    function metadata(uint256 _tokenId)
        external view 
        virtual 
        tokenExists(_tokenId)
        returns (string memory)
    {
        return decorator().toJSON(
            randomizer.getRandomnessAfter(__storage.hatchingBlock),
            __storage.intrinsics[_tokenId]
        );
    }

    function tokenURI(uint256 _tokenId)
        public view
        virtual override
        tokenExists(_tokenId)
        returns (string memory)
    {
        return string(abi.encodePacked(
            baseURI(),
            "metadata/",
            block.chainid.toString(),
            "/",
            _tokenId.toString()
        ));
    }


    // ========================================================================
    // --- Implementation of 'IWc3Admin' --------------------------------------

    /// Sets Opensea-compliant Decorator contract
    /// @dev Only callable by the owner, when in 'Batching' status.
    function setDecorator(IWc3Decorator _decorator)
        public
        override
        onlyOwner
        inStatus(Wc3Lib.Status.Batching)
    {
        require(
            address(_decorator) != address(0),
            "Wc3Token: no decorator"
        );
        __storage.decorator = address(_decorator);
        emit Decorator(address(_decorator));
    }

    /// Set estimated gas units required for minting one single token.
    /// @dev Only callable by the owner, at any time.
    function setMintGasOverhead(
            uint256 _mintGasOverhead
        )
        public override
        onlyOwner
    {
        __storage.mintGasOverhead = _mintGasOverhead;
        emit MintGasOverhead(_mintGasOverhead);
    }

    /// Sets Externally Owned Account that is authorized to sign tokens' intrinsics before getting minted.
    /// @dev Only callable by the owner, at any time.
    /// @dev Cannot be set to zero address.
    /// @param _signator Externally-owned account to be authorized    
    function setSignator(address _signator)
        public override
        onlyOwner
    {
        require(
            _signator != address(0),
            "Wc3Token: no signator"
        );
        __storage.signator = _signator;
        emit Signator(_signator);
    }

    /// Change batch parameters. Only possible while in 'Batching' status.
    /// @dev Only callable by the owner, while on 'Batching' status.
    /// @param _expirationBlocks Number of blocks after Witnet randomness is generated, during which creatures may get minted.
    /// @param _totalEggs Max number of tokens that may eventually get minted.
    /// @param _percentileMarks Creature-category ordered percentile marks (Legendary first).   
    function setSettings(
            uint256 _expirationBlocks,
            uint256 _totalEggs,
            uint8[] memory _percentileMarks
        )
        public
        virtual override
        onlyOwner
        inStatus(Wc3Lib.Status.Batching)
    {
        require(
            _totalEggs > 0,
            "Wc3Token: zero eggs"
        );
        require(
            _percentileMarks.length == uint8(Wc3Lib.WittyCreatureRarity.Common) + 1,
            "Wc3Token: bad percentile marks"
        );        

        __storage.settings.expirationBlocks = _expirationBlocks;
        __storage.settings.totalEggs = _totalEggs;
        __storage.settings.percentileMarks = new uint8[](_percentileMarks.length);

        uint8 _checkSum; for (uint8 _i = 0; _i < _percentileMarks.length; _i ++) {
            uint8 _mark = _percentileMarks[_i];
            __storage.settings.percentileMarks[_i] = _mark;
            _checkSum += _mark;
        }
        require(_checkSum == 100, "Wc3Token: bad percentile checksum");

        emit Settings(
            _expirationBlocks,
            _totalEggs,
            _percentileMarks
        );
    }

    /// Starts hatching, which means: (a) game settings cannot be altered anymore, (b) a 
    /// random number will be requested to the Witnet Decentralized Oracle Network, and (c)
    /// the contract will automatically turn to the 'Hatching' status as soon as the randomness
    /// gets solved by the Witnet oracle. While the randomness request gets solved, the contract will 
    /// remain in 'Randomizing' status.
    /// @dev Only callable by the owner, while in 'Batching' status.
    function startHatching()
        external payable
        virtual
        nonReentrant
        onlyOwner
        inStatus(Wc3Lib.Status.Batching)
    {   
        // Decorator must be forged first:
        require(
            decorator().forged(),
            "Wc3Token: unforged decorator"
        );

        // Request randomness from the Witnet oracle:
        uint _usedFunds = randomizer.randomize{ value: msg.value }();

        // Sets hatching block number:
        __storage.hatchingBlock = block.number;
        
        // Transfer back unused funds:
        if (_usedFunds < msg.value ) {
            payable(msg.sender).transfer(msg.value - _usedFunds);   
        }
    }

    // ========================================================================
    // --- Implementation of 'IWc3Surrogates' -------------------------------

    function mint(
            address _tokenOwner,
            string calldata _name,
            uint256 _globalRanking,
            uint256 _guildId,
            uint256 _guildPlayers,
            uint256 _guildRanking,
            uint256 _index,
            uint256 _score,
            bytes calldata _signature
        )
        external
        virtual override
        selfMintUsdCost6(_guildRanking)
        nonReentrant
        inStatus(Wc3Lib.Status.Hatching)
    {
        // Verify guildfundamental facts:
        _verifyGuildFacts(
            _guildId,
            _guildPlayers,
            _guildRanking
        );

        // Verify signature:
        _verifySignature(
            _tokenOwner,
            _name,
            _globalRanking,
            _guildId,
            _guildPlayers,
            _guildRanking,
            _index,
            _score,            
            _signature
        );

        // Token id will be the same as the achieved guild ranking for this egg during EthCC'5:
        uint256 _tokenId = _guildRanking;

        // Verify the token has not been already minted:
        require(
            __storage.intrinsics[_tokenId].mintTimestamp == 0,
            "Wc3Token: already minted"
        );

        // Save token intrinsics to storage:
        __mintWittyCreature(
            _name,
            _globalRanking,
            _guildPlayers,
            _guildRanking,
            _index,
            _score
        );

        // Mint the actual ERC-721 token:
        _safeMint(_tokenOwner, _tokenId);

        // Increment token supply:
        __storage.totalSupply ++;
    }


    // ========================================================================
    // --- Implementation of 'IWc3View' ------------------------------------

    
    function decorator()
        public view
        override
        returns (IWc3Decorator)
    {
        return IWc3Decorator(__storage.decorator);
    }
    
    function getHatchingBlock()
        public view
        override
        returns (uint256)
    {
        return __storage.hatchingBlock;
    }

    function getHatchingRandomness()
        public view
        override
        returns (bytes32 _hatchingRandomness)
    {
        return randomizer.getRandomnessAfter(__storage.hatchingBlock);
    }

    function getMintGasOverhead()
        public view
        override
        returns (uint256)
    {
        return __storage.mintGasOverhead;
    }

    function getSettings()
        external view
        override
        returns (Wc3Lib.Settings memory)
    {
        return __storage.settings;
    }

    function getStatus()
        public view
        override
        returns (Wc3Lib.Status)
    {
        return __storage.status(randomizer);
    }

    function getStatusString()
        external view
        override
        returns (string memory)
    {
        return getStatus().toString();
    }

    function getTokenIntrinsics(uint256 _tokenId)
        external view
        override
        returns (Wc3Lib.WittyCreature memory)
    {
        return __storage.intrinsics[_tokenId];
    }

    function getTokenRandomTraits(uint256 _tokenId)
        external view
        override
        returns (Wc3Lib.WittyCreatureTraits memory _traits)
    {
        bytes32 _randomness = getHatchingRandomness();
        if (_randomness != 0) {
            _traits = decorator().randomTraits(
                _randomness,
                __storage.intrinsics[_tokenId].eggIndex
            );
        }
    }

    function getTokenStatus(uint256 _tokenId)
        public view
        override
        returns (Wc3Lib.WittyCreatureStatus)
    {
        return __storage.tokenStatus(randomizer, _tokenId);
    }

    function getTokenStatusString(uint256 _tokenId)
        external view
        override
        returns (string memory)
    {
        return getTokenStatus(_tokenId).toString();
    }

    function preview(
            string memory _name,
            uint256 _globalRanking,
            uint256 _guildId,
            uint256 _guildPlayers,
            uint256 _guildRanking,
            uint256 _index,
            uint256 _score
        )
        public view
        virtual override
        inStatus(Wc3Lib.Status.Hatching)
        returns (string memory)
    {
        // Verify guild facts:
        _verifyGuildFacts(
            _guildId,
            _guildPlayers,
            _guildRanking
        );

        // Preview creature image:
        return decorator().toJSON(
            randomizer.getRandomnessAfter(__storage.hatchingBlock),
            Wc3Lib.WittyCreature({
                eggName: _name,
                eggGlobalRanking: _globalRanking,
                eggGuildRanking: _guildRanking,
                eggIndex: _index,
                eggRarity: __storage.eggRarity((_guildRanking * 100) / _guildPlayers),
                eggScore: _score,
                mintBlock: 0,
                mintGas: 0,
                mintGasPrice: 0,
                mintTimestamp: 0,
                mintUsdCost6: 0,
                mintUsdPriceWitnetProof: 0
            })
        );
    }

    function signator()
        external view
        override
        returns (address)
    {
        return __storage.signator;
    }

    function totalSupply()
        public view
        override
        returns (uint256)
    {
        return __storage.totalSupply;
    }

    function usdPriceCaption()
        public view
        override
        returns (string memory)
    {
        return router.lookupERC2362ID(usdPriceAssetId);
    }

    function version()
        external view
        override
        returns (string memory)
    {
        return __version.toString();
    }

    
    // ------------------------------------------------------------------------
    // --- INTERNAL VIRTUAL METHODS -------------------------------------------
    // ------------------------------------------------------------------------

    /// @dev Rely on the Witnet oracle to fetch current USD price, and verification proof
    function _estimateUsdPrice6()
        internal view
        returns (int _lastKnownPrice, bytes32 _priceWitnetProof)
    {
        IWitnetPriceFeed _pf = IWitnetPriceFeed(address(router.getPriceFeed(usdPriceAssetId)));
        if (address(_pf) != address(0)) {
            (_lastKnownPrice,, _priceWitnetProof,) = _pf.lastValue();
        }
    }
    
    function __mintWittyCreature(
            string calldata _name,
            uint256 _globalRanking,
            uint256 _guildPlayers,
            uint256 _guildRanking,
            uint256 _index,
            uint256 _score
        )
        internal
        virtual
    {
        // Save intrinsics into storage:
        Wc3Lib.WittyCreature storage __wc3 = __storage.intrinsics[_guildRanking];
        __wc3.eggName = _name;
        __wc3.eggGlobalRanking = _globalRanking;
        __wc3.eggGuildRanking = _guildRanking;
        __wc3.eggIndex = _index;
        __wc3.eggRarity = __storage.eggRarity((_guildRanking * 100) / _guildPlayers);
        __wc3.eggScore = _score;
    }

    function _verifyGuildFacts(
            uint _guildId,
            uint _guildPlayers,
            uint _guildRanking
        )
        internal view
        virtual
    {
        require(_guildId == guildId, "Wc3Token: bad guild");
        
        require(_guildPlayers > 0, "Wc3Token: no players");
        require(_guildPlayers <= __storage.settings.totalEggs, "Wc3Token: bad players");
        
        require(_guildRanking > 0, "Wc3Token: no ranking");
        require(_guildRanking <= _guildPlayers, "Wc3Token: bad ranking");
    }

    function _verifySignature(
            address _tokenOwner,
            string memory _name,
            uint256 _globalRanking,
            uint256 _guildId,
            uint256 _guildPlayers,
            uint256 _guildRanking,
            uint256 _index,
            uint256 _score,
            bytes memory _signature
        )
        internal view
        virtual
    {
        bytes32 _hash = keccak256(abi.encode(
            _tokenOwner,
            _name,
            _globalRanking,
            _guildId,
            _guildPlayers,
            _guildRanking,
            _index,
            _score
        ));
        require(
            Wc3Lib.recoverAddr(_hash, _signature) == __storage.signator,
            "Wc3Token: bad signature"
        );
    }

}