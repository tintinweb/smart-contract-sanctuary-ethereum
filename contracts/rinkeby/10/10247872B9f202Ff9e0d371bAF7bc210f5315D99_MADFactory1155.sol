// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

/* 
DISCLAIMER: 
This contract hasn't been audited yet. Most likely contains unexpected bugs. 
Don't trust your funds to be held by this code before the final thoroughly tested and audited version release.
*/

import { MAD } from "./MAD.sol";

import { FactoryEventsAndErrors1155, FactoryVerifier } from "./EventsAndErrors.sol";

import { ERC1155MinimalDeployer, ERC1155BasicDeployer, ERC1155WhitelistDeployer, ERC1155LazyDeployer } from "./lib/deployers/ERC1155Deployer.sol";

import { SplitterDeployer } from "./lib/deployers/SplitterDeployer.sol";

import { Pausable } from "./lib/security/Pausable.sol";
import { Owned } from "./lib/auth/Owned.sol";
import { ReentrancyGuard } from "./lib/security/ReentrancyGuard.sol";
import { DCPrevent } from "./lib/security/DCPrevent.sol";
import { Types, SplitterImpl } from "./Types.sol";

import { CREATE3, Bytes32AddressLib } from "./lib/utils/CREATE3.sol";

// prettier-ignore
contract MADFactory1155 is MAD,
    FactoryEventsAndErrors1155,
    FactoryVerifier,
    ReentrancyGuard,
    DCPrevent(),
    Owned(msg.sender),
    Pausable
{
    using Types for Types.ERC721Type;
    using Types for Types.Collection1155;
    using Types for Types.SplitterConfig;
    using Bytes32AddressLib for address;
    using Bytes32AddressLib for bytes32;

    /// @dev Function SigHash: 0x06fdde03
    function name()
        public
        pure
        override(MAD)
        returns (string memory)
    {
        assembly {
            mstore(0x20, 0x20)
            mstore(0x47, 0x07666163746F7279)
            return(0x20, 0x60)
        }
    }

    ////////////////////////////////////////////////////////////////
    //                           STORAGE                          //
    ////////////////////////////////////////////////////////////////

    
    /// @dev `colIDs` are derived from adding 12 bytes of zeros to an collection's address.
    /// @dev colID => colInfo(salt/type/addr/time/splitter)
    mapping(bytes32 => Types.Collection1155) public colInfo;

    /// @dev Maps an collection creator, of type address, to an array of `colIDs`.
    mapping(address => bytes32[]) public  userTokens;

    /// @dev Nested mapping that takes an collection creator as key of 
    /// an hashmap of splitter contracts to its respective deployment configs.
    mapping(address => mapping(address => Types.SplitterConfig))
        public splitterInfo;

    /// @dev Stores authorized ambassador addresses to be opted as shareholders of splitter contracts.  
    mapping(address => bool) public ambWhitelist;

    /// @dev Instance of `MADRouter` being passed as parameter of collection's constructor.
    address public router;

    /// @dev Instance of `MADMarketplace` being passed as parameter of `creatorAuth`.
    address public market;

    /// @dev Self-reference pointer for assembly internal calls.
    // address private _this;

    /// @dev The signer address used for lazy minting voucher validation.
    address private signer;

    ////////////////////////////////////////////////////////////////
    //                         CONSTRUCTOR                        //
    ////////////////////////////////////////////////////////////////

    constructor
    (
        address _marketplace, 
        address _router, 
        address _signer
    )
    {
        setMarket(_marketplace);
        setRouter(_router);
        setSigner(_signer);
    }

    ////////////////////////////////////////////////////////////////
    //                           CORE FX                          //
    ////////////////////////////////////////////////////////////////

    /// @notice Splitter deployment pusher.
    /// @dev Function Sighash := 0x9e5c4b70
    /// @param _splitterSalt Nonce/Entropy factor used by CREATE3 method. Must be always different to avoid address collision.
    /// to generate payment splitter deployment address.
    /// @param _ambassador User may choose from one of the whitelisted addresses to donate
    /// 1%-20% of secondary sales royalties (optional, will be disregarded if left empty(value == address(0)).
    /// @param _ambShare Percentage (1%-20%) of secondary sales royalties to be donated to an ambassador
    /// (optional, will be disregarded if left empty(value == 0)).
    function splitterCheck(
        string memory _splitterSalt,
        address _ambassador,
        uint256 _ambShare
    ) external nonReentrant isThisOg whenNotPaused {
        bytes32 splitterSalt = keccak256(
            bytes(_splitterSalt)
        );
        if (_ambassador == address(0)) {
            address[] memory _payees = _payeesBuffer(address(0), owner);
            uint256[] memory _shares = _sharesBuffer(0);

            address _splitter = SplitterDeployer._SplitterDeploy(
                _splitterSalt,
                _payees,
                _shares
            );

            splitterInfo[tx.origin][_splitter] = Types
                .SplitterConfig({
                    splitter: _splitter,
                    splitterSalt: splitterSalt,
                    ambassador: address(0),
                    ambShare: 0,
                    valid: true
                });

            emit SplitterCreated(
                tx.origin,
                _shares,
                _payees,
                _splitter
            );

        } else if (
            _ambShare != 0 && 
            _ambShare < 21 &&
            ambWhitelist[_ambassador] == true
        ) {
            address[] memory _payees = _payeesBuffer(_ambassador, owner);
            uint256[] memory _shares = _sharesBuffer(_ambShare); 

            address _splitter = SplitterDeployer._SplitterDeploy(
                _splitterSalt,
                // [owner, _ambassador, tx.origin],
                _payees,
                // [10, _ambShare, 90 - _ambShare]
                _shares
            );

            splitterInfo[tx.origin][_splitter] = Types
                .SplitterConfig({
                    splitter: _splitter,
                    splitterSalt: splitterSalt,
                    ambassador: _ambassador,
                    ambShare: _ambShare,
                    valid: true
                });

            emit SplitterCreated(
                tx.origin,
                _shares,
                _payees,
                _splitter
            );

        } else { 
            assembly {
                mstore(0x00, 0x00adecf0)
                revert(0x1c, 0x04)
            
            }
        }
    }

    /// @notice Core public ERC1155 token types deployment pusher.
    /// @dev Function Sighash := 0x73fd6808
    /// @dev Args passed as params in this function serve as common denominator for all token types.
    /// @dev Extra config options must be set directly by through token type specific functions in `MADRouter` contract.
    /// @dev Frontend must attent that salt values must have common pattern so to not replicate same output.
    /// @param _tokenType Values legend:
    /// 0=Minimal; 1=Basic; 2=Whitelist; 3=Lazy.
    /// @param _tokenSalt Nonce/Entropy factor used by CREATE3 method
    /// to generate collection deployment address. Must be always different to avoid address collision.
    /// @param _price Public mint price of the collection to be deployed.
    /// @param _maxSupply Maximum supply of tokens to be minted of the collection to be deployed
    /// (Not used for ERC1155Minimal token type, since it always equals to one).
    /// @param _uri The URL + CID to be added the tokenID and suffix (.json) by the tokenURI function
    /// in the collection to be deployed (baseURI used as tokenURI itself for the ERC1155Minimal token type).
    /// @param _splitter Previously deployed Splitter implementation so to validate and attach to collection.
    function createCollection(
        uint8 _tokenType,
        string memory _tokenSalt,
        uint256 _price,
        uint256 _maxSupply,
        string memory _uri,
        address _splitter
    )
        external
        nonReentrant
        isThisOg
        whenNotPaused
    {
        _limiter(_tokenType, _splitter);

        if (_tokenType < 1) {
        (bytes32 tokenSalt, address deployed) = 
            ERC1155MinimalDeployer._1155MinimalDeploy(
                _tokenSalt,
                _uri,
                _price,
                _splitter,
                router
            );

        bytes32 colId = deployed.fillLast12Bytes();
        userTokens[tx.origin].push(colId);

        colInfo[colId] = Types.Collection1155(
            tx.origin,
            Types.ERC1155Type.ERC1155Minimal,
            tokenSalt,
            block.number,
            _splitter
        );

        emit ERC1155MinimalCreated(
            _splitter,
            deployed,
            tx.origin
        );
        }
        if (_tokenType == 1) {
            (bytes32 tokenSalt, address deployed) = 
            ERC1155BasicDeployer._1155BasicDeploy(
                _tokenSalt,
                _uri,
                _price,
                _maxSupply,
                _splitter,
                router
            );

        bytes32 colId = deployed.fillLast12Bytes();
        userTokens[tx.origin].push(colId);

        colInfo[colId] = Types.Collection1155(
            tx.origin,
            Types.ERC1155Type.ERC1155Basic,
            tokenSalt,
            block.number,
            _splitter
        );

        emit ERC1155BasicCreated(
            _splitter,
            deployed,
            tx.origin
        );
        }
        if (_tokenType == 2) {
            (bytes32 tokenSalt, address deployed) = 
            ERC1155WhitelistDeployer._1155WhitelistDeploy(
                _tokenSalt,
                _uri,
                _price,
                _maxSupply,
                _splitter,
                router
            );

        bytes32 colId = deployed.fillLast12Bytes();
        userTokens[tx.origin].push(colId);

        colInfo[colId] = Types.Collection1155(
            tx.origin,
            Types.ERC1155Type.ERC1155Whitelist,
            tokenSalt,
            block.number,
            _splitter
        );

        emit ERC1155WhitelistCreated(
            _splitter,
            deployed,
            tx.origin
        );
        }
        if (_tokenType > 2) {
            (bytes32 tokenSalt, address deployed) = 
            ERC1155LazyDeployer._1155LazyDeploy(
                    _tokenSalt,
                    _uri,
                    _splitter,
                    router,
                    signer
            );

        bytes32 colId = deployed.fillLast12Bytes();
        userTokens[tx.origin].push(colId);

        colInfo[colId] = Types.Collection1155(
            tx.origin,
            Types.ERC1155Type.ERC1155Lazy,
            tokenSalt,
            block.number,
            _splitter
        );

        emit ERC1155LazyCreated(
            _splitter,
            deployed,
            tx.origin
        );
        }
    }

    ////////////////////////////////////////////////////////////////
    //                         OWNER FX                           //
    ////////////////////////////////////////////////////////////////
    
    /// @dev `MADMarketplace` instance setter.
    /// @dev Function Sighash := 
    function setMarket(address _market) public onlyOwner {
        assembly {
            sstore(market.slot, _market)
        }

        emit MarketplaceUpdated(_market);
    }

    /// @dev `MADRouter` instance setter.
    /// @dev Function Sighash := 0xc0d78655
    function setRouter(address _router) public onlyOwner {
        // router = _router;
        assembly {
            sstore(router.slot, _router)
        }

        emit RouterUpdated(_router);
    }

    /// @dev Setter for EIP712 signer/validator instance.
    /// @dev Function Sighash := 0x6c19e783
    function setSigner(address _signer) public onlyOwner {
        // signer = _signer;
        assembly {
            sstore(signer.slot, _signer)
        }

        emit SignerUpdated(_signer);
    }

    /// @dev Add address to ambassador whitelist.
    /// @dev Function Sighash := 0x295c25d5
    function addAmbassador(address _whitelistedAmb)
        public
        onlyOwner
    {
        // ambWhitelist[_whitelistedAmb] = true;
        assembly {
            mstore(0x00, _whitelistedAmb)
            mstore(0x20, ambWhitelist.slot)
            let ambSlot := keccak256(0x00, 0x40)
            sstore(ambSlot, 1)
        }

        emit AmbassadorAdded(_whitelistedAmb);
    }

    /// @dev Delete address from ambassador whitelist.
    /// @dev Function Sighash := 0xf2d0e148
    function delAmbassador(address _removedAmb)
        public
        onlyOwner
    {
        // delete ambWhitelist[_removedAmb];
        assembly {
            mstore(0x00, _removedAmb)
            mstore(0x20, ambWhitelist.slot)
            let ambSlot := keccak256(0x00, 0x40)
            sstore(ambSlot, 0)
        }

        emit AmbassadorDeleted(_removedAmb);
    }

    /// @notice Paused state initializer for security risk mitigation pratice.
    /// @dev Function Sighash := 0x8456cb59
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpaused state initializer for security risk mitigation pratice.
    /// @dev Function Sighash := 0x3f4ba83a
    function unpause() external onlyOwner {
        _unpause();
    }

    ////////////////////////////////////////////////////////////////
    //                           HELPERS                          //
    ////////////////////////////////////////////////////////////////

    /// @notice Everything in storage can be fetch through the 
    /// getters natively provided by all public mappings.
    /// @dev This public getter serve as a hook to ease frontend 
    /// fetching whilst estimating user's colID indexes.
    /// @dev Function Sighash := 0x8691fe46
    function getIDsLength(address _user) 
        external 
        view 
        returns (uint256) 
    {
        return userTokens[_user].length;
    }

    /// @inheritdoc FactoryVerifier
    function getColID(address _colAddress) external pure override(FactoryVerifier) returns (bytes32 colID) {
        colID = _colAddress.fillLast12Bytes();
        
    }

    /// @inheritdoc FactoryVerifier
    function typeChecker(bytes32 _colID) external override(FactoryVerifier) view returns(uint8 pointer) {
        _isRouter();
        Types.Collection1155 storage col = colInfo[_colID];
        
        assembly {
            let x := sload(col.slot)
            pointer := shr(160, x)
        }
    }

    /// @dev Builds payees dynamic sized array buffer for `splitterCheck` cases.
    function _payeesBuffer(address amb, address castedAddr) internal view returns (address[] memory memOffset) {
        if (amb == address(0)) {
            assembly {
                memOffset := mload(0x40)
                mstore(add(memOffset, 0x00), 2)
                mstore(add(memOffset, 0x20), castedAddr)
                mstore(add(memOffset, 0x40), origin())
                mstore(0x40, add(memOffset, 0x60))
            }
        }
        else {
            assembly {
                memOffset := mload(0x40)
                mstore(add(memOffset, 0x00), 3)
                mstore(add(memOffset, 0x20), castedAddr)
                mstore(add(memOffset, 0x40), amb)
                mstore(add(memOffset, 0x60), origin())
                mstore(0x40, add(memOffset, 0x80))
            }
        }
    }

    /// @dev Builds shares dynamic sized array buffer for `splitterCheck` cases.
    function _sharesBuffer(uint256 _ambShare) internal pure returns (uint256[] memory memOffset) {
        if (_ambShare == 0) {
            assembly {
                memOffset := mload(0x40)
                mstore(add(memOffset, 0x00), 2) 
                mstore(add(memOffset, 0x20), 10) 
                mstore(add(memOffset, 0x40), 90) 
                mstore(0x40, add(memOffset, 0x60))
            }
        }
        else {
            assembly {
                memOffset := mload(0x40)
                mstore(add(memOffset, 0x00), 3)
                mstore(add(memOffset, 0x20), 10) 
                mstore(add(memOffset, 0x40), _ambShare) 
                mstore(add(memOffset, 0x60), sub(90,_ambShare)) 
                mstore(0x40, add(memOffset, 0x80))
            }
        }
    }

    /// @inheritdoc FactoryVerifier
    function creatorAuth(address _token, address _user) 
        external 
        override(FactoryVerifier) 
        view 
        returns(bool stdout) 
    {
        _isMarket();
        if (!_userRender(_user)) { assembly { stdout := 0 } }

        bytes32 buffer = 
            _token.fillLast12Bytes();
        bytes32[] memory digest = 
            new bytes32[](userTokens[_user].length);
        uint256 i;    
        uint256 len = digest.length;
        mapping(address => bytes32[]) storage usrTkns =
            userTokens;
        for (i; i < len;) {
            if(buffer == usrTkns[_user][i]) {
                stdout = true;
            } unchecked { ++i; } 
        }
    }

    /// @inheritdoc FactoryVerifier
    function creatorCheck(bytes32 _colID) 
    public
    override(FactoryVerifier)
    view
    returns(address creator, bool check) 
    {
        _isRouter();
        Types.Collection1155 storage col = colInfo[_colID];
        
        assembly {
            let x := sload(col.slot)
            // get the first 20 bytes of storage slot
            creator := and(x, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)

            if eq(creator, origin()) {
                check := true
            }
        // if(!check) revert AccessDenied();
            if iszero(check) {
                mstore(0x00, 0x4ca88867)
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Stablishes sealed/safe callpath for `MADRouter` contract.
    /// @dev Function Sighash := 0xb4d30bec
    function _isRouter() private view {
        // if (msg.sender != router) revert AccessDenied();
        assembly {
            // let stdin := sload(router.slot)
            // if eq(origin(), sload(router.slot)) {
            if iszero(eq(caller(), sload(router.slot))) {
                mstore(0x00, 0x4ca88867FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                revert(0, 4) // (offset, length)
            }
        } 
    }

    /// @dev Stablishes sealed/safe callpath for `MADMarketplace` contract.
    /// @dev Function Sighash := 
    function _isMarket() private view {
        assembly {
            if iszero(eq(caller(), sload(market.slot))) {
                mstore(0x00, 0x4ca88867FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                revert(0, 4) // (offset, length)
            }
        } 
    }

    function _limiter(
        uint8 _tokenType,
        address _splitter
    ) private view {
        bool val = splitterInfo[tx.origin][_splitter].valid;
        // require(_tokenType < 4, "INVALID_TYPE");
        // if (!splitterInfo[tx.origin][_splitter].valid)
        //     revert AccessDenied();
        assembly {
            if or(gt(_tokenType,3),iszero(val)) {
                mstore(0x00,0x4ca8886700000000000000000000000000000000000000000000000000000000)
                revert(0,4)
            }
        }
    }

    /// @notice Private view helper that checks an user against `userTokens` storage slot.
    /// @dev Function Sighash := 0xbe749257
    /// @dev `creatorAuth` method extension.
    /// @return _stdout := 1 as boolean standard output.
    function _userRender(address _user) private view returns(bool _stdout){
        assembly {
            let freeMemoryPointer := mload(0x40)
            // sload(userTokens.slot)
            mstore(add(freeMemoryPointer, 32), userTokens.slot)
            mstore(add(freeMemoryPointer, 64), _user) 
            let hash := keccak256(freeMemoryPointer, 64)
            if iszero(sload(hash)) {
                _stdout := false
            }
        }
    }

    function getDeployedAddr(string memory _salt)
        public
        view
        returns (
            address
        )
    {
        bytes32 salt = keccak256(bytes(_salt));
        return CREATE3.getDeployed(salt);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/* 
DISCLAIMER: 
This contract hasn't been audited yet. Most likely contains unexpected bugs. 
Don't trust your funds to be held by this code before the final thoroughly tested and audited version release.
*/

pragma solidity 0.8.4;

///     ...     ..      ..                    ..
///   x*8888x.:*8888: -"888:                dF
///  X   48888X `8888H  8888               '88bu.
/// X8x.  8888X  8888X  !888>        u     '*88888bu
/// X8888 X8888  88888   "*8%-    us888u.    ^"*8888N
/// '*888!X8888> X8888  xH8>   [email protected] "8888"  beWE "888L
///   `?8 `8888  X888X X888>   9888  9888   888E  888E
///   -^  '888"  X888  8888>   9888  9888   888E  888E
///    dx '88~x. !88~  8888>   9888  9888   888E  888F
///  .8888Xf.888x:!    X888X.: 9888  9888  .888N..888
/// :""888":~"888"     `888*"  "888*""888"  `"888*""
///     "~'    "~        ""     ^Y"   ^Y'      ""     MADNFTs © 2022.

/// GNU AFFERO GENERAL PUBLIC LICENSE
/// Version 3, 19 November 2007
///
/// Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
/// Everyone is permitted to copy and distribute verbatim copies
/// of this license document, but changing it is not allowed.
///
/// (https://spdx.org/licenses/AGPL-3.0-only.html)

abstract contract MAD {
    function name()
        public
        pure
        virtual
        returns (string memory);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

import { FactoryVerifier } from "./lib/auth/FactoryVerifier.sol";
import { IERC721 } from "./Types.sol";
import { IERC1155 } from "./Types.sol";

interface FactoryEventsAndErrors721 {
    ////////////////////////////////////////////////////////////////
    //                           EVENTS                           //
    ////////////////////////////////////////////////////////////////

    event AmbassadorAdded(address indexed whitelistedAmb);
    event AmbassadorDeleted(address indexed removedAmb);
    event MarketplaceUpdated(address indexed newMarket);
    event RouterUpdated(address indexed newRouter);
    event SignerUpdated(address indexed newSigner);

    event SplitterCreated(
        address indexed creator,
        uint256[] shares,
        address[] payees,
        address splitter
    );

    event ERC721MinimalCreated(
        address indexed newSplitter,
        address indexed newCollection,
        address indexed newCreator
    );
    event ERC721BasicCreated(
        address indexed newSplitter,
        address indexed newCollection,
        address indexed newCreator
    );
    event ERC721WhitelistCreated(
        address indexed newSplitter,
        address indexed newCollection,
        address indexed newCreator
    );
    event ERC721LazyCreated(
        address indexed newSplitter,
        address indexed newCollection,
        address indexed newCreator
    );

    ////////////////////////////////////////////////////////////////
    //                           ERRORS                           //
    ////////////////////////////////////////////////////////////////

    /// @dev 0x00adecf0
    error SplitterFail();
}

interface FactoryEventsAndErrors1155 {
    ////////////////////////////////////////////////////////////////
    //                           EVENTS                           //
    ////////////////////////////////////////////////////////////////

    event AmbassadorAdded(address indexed whitelistedAmb);
    event AmbassadorDeleted(address indexed removedAmb);
    event MarketplaceUpdated(address indexed newMarket);
    event RouterUpdated(address indexed newRouter);
    event SignerUpdated(address indexed newSigner);

    event SplitterCreated(
        address indexed creator,
        uint256[] shares,
        address[] payees,
        address splitter
    );

    event ERC1155MinimalCreated(
        address indexed newSplitter,
        address indexed newCollection,
        address indexed newCreator
    );
    event ERC1155BasicCreated(
        address indexed newSplitter,
        address indexed newCollection,
        address indexed newCreator
    );
    event ERC1155WhitelistCreated(
        address indexed newSplitter,
        address indexed newCollection,
        address indexed newCreator
    );
    event ERC1155LazyCreated(
        address indexed newSplitter,
        address indexed newCollection,
        address indexed newCreator
    );

    ////////////////////////////////////////////////////////////////
    //                           ERRORS                           //
    ////////////////////////////////////////////////////////////////

    /// @dev 0x00adecf0
    error SplitterFail();
}

interface MarketplaceEventsAndErrors721 {
    ////////////////////////////////////////////////////////////////
    //                           EVENTS                           //
    ////////////////////////////////////////////////////////////////

    event FactoryUpdated(FactoryVerifier indexed newFactory);

    event AuctionSettingsUpdated(
        uint256 indexed newMinDuration,
        uint256 indexed newIncrement,
        uint256 indexed newMinBidValue
    );

    event MakeOrder(
        IERC721 indexed token,
        uint256 id,
        bytes32 indexed hash,
        address seller
    );
    event CancelOrder(
        IERC721 indexed token,
        uint256 id,
        bytes32 indexed hash,
        address seller
    );
    event Bid(
        IERC721 indexed token,
        uint256 id,
        bytes32 indexed hash,
        address bidder,
        uint256 bidPrice
    );
    event Claim(
        IERC721 indexed token,
        uint256 id,
        bytes32 indexed hash,
        address seller,
        address taker,
        uint256 price
    );

    ////////////////////////////////////////////////////////////////
    //                           ERRORS                           //
    ////////////////////////////////////////////////////////////////

    /// @dev 0xf7760f25
    error WrongPrice();
    /// @dev 0x90b8ec18
    error TransferFailed();
    /// @dev 0x0863b103
    error InvalidBidder();
    /// @dev 0xdf9428da
    error CanceledOrder();
    /// @dev 0x70f8f33a
    error ExceedsMaxEP();
    /// @dev 0x4ca88867
    error AccessDenied();
    /// @dev 0x921dbfec
    error NeedMoreTime();
    /// @dev 0x07ae5744
    error NotBuyable();
    /// @dev 0x3e0827ab
    error BidExists();
    /// @dev 0xf88b07a3
    error SoldToken();
    /// @dev 0x2af0c7f8
    error Timeout();
    /// @dev 0xffc96cb0
    error EAOnly();
}

interface MarketplaceEventsAndErrors1155 {
    ////////////////////////////////////////////////////////////////
    //                           EVENTS                           //
    ////////////////////////////////////////////////////////////////

    event FactoryUpdated(FactoryVerifier indexed newFactory);

    event AuctionSettingsUpdated(
        uint256 indexed newMinDuration,
        uint256 indexed newIncrement,
        uint256 indexed newMinBidValue
    );

    event MakeOrder(
        IERC1155 indexed token,
        uint256 id,
        uint256 amount,
        bytes32 indexed hash,
        address seller
    );
    event CancelOrder(
        IERC1155 indexed token,
        uint256 id,
        uint256 amount,
        bytes32 indexed hash,
        address seller
    );
    event Bid(
        IERC1155 indexed token,
        uint256 id,
        uint256 amount,
        bytes32 indexed hash,
        address bidder,
        uint256 bidPrice
    );
    event Claim(
        IERC1155 indexed token,
        uint256 id,
        uint256 amount,
        bytes32 indexed hash,
        address seller,
        address taker,
        uint256 price
    );

    ////////////////////////////////////////////////////////////////
    //                           ERRORS                           //
    ////////////////////////////////////////////////////////////////

    /// @dev 0xf7760f25
    error WrongPrice();
    /// @dev 0x90b8ec18
    error TransferFailed();
    /// @dev 0x0863b103
    error InvalidBidder();
    /// @dev 0xdf9428da
    error CanceledOrder();
    /// @dev 0x70f8f33a
    error ExceedsMaxEP();
    /// @dev 0x4ca88867
    error AccessDenied();
    /// @dev 0x921dbfec
    error NeedMoreTime();
    /// @dev 0x07ae5744
    error NotBuyable();
    /// @dev 0x3e0827ab
    error BidExists();
    /// @dev 0xf88b07a3
    error SoldToken();
    /// @dev 0x2af0c7f8
    error Timeout();
    /// @dev 0xffc96cb0
    error EAOnly();
}

interface RouterEvents {
    ////////////////////////////////////////////////////////////////
    //                           EVENTS                           //
    ////////////////////////////////////////////////////////////////

    event TokenFundsWithdrawn(
        bytes32 indexed _id,
        uint8 indexed _type,
        address indexed _payee
    );

    event PublicMintState(
        bytes32 indexed _id,
        uint8 indexed _type,
        bool indexed _state
    );

    event WhitelistMintState(
        bytes32 indexed _id,
        uint8 indexed _type,
        bool indexed _state
    );

    event FreeClaimState(
        bytes32 indexed _id,
        uint8 indexed _type,
        bool indexed _state
    );

    event BaseURI(
        bytes32 indexed _id,
        string indexed _baseURI
    );
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

import { SplitterImpl } from "../../Types.sol";

import { ERC1155Minimal } from "../tokens/ERC1155/Impl/ERC1155Minimal.sol";
import { ERC1155Basic } from "../tokens/ERC1155/Impl/ERC1155Basic.sol";
import { ERC1155Whitelist } from "../tokens/ERC1155/Impl/ERC1155Whitelist.sol";
import { ERC1155Lazy } from "../tokens/ERC1155/Impl/ERC1155Lazy.sol";

import { CREATE3 } from "../utils/CREATE3.sol";

library ERC1155MinimalDeployer {
    function _1155MinimalDeploy(
        string memory _tokenSalt,
        string memory _uri,
        uint256 _price,
        address _splitter,
        address _router
    ) public returns (bytes32 tokenSalt, address deployed) {
        SplitterImpl splitter = SplitterImpl(
            payable(_splitter)
        );
        tokenSalt = keccak256(bytes(_tokenSalt));
        deployed = CREATE3.deploy(
            tokenSalt,
            abi.encodePacked(
                type(ERC1155Minimal).creationCode,
                abi.encode(
                    _uri,
                    _price,
                    splitter,
                    750, // fixed 7.5% royalties
                    _router
                )
            ),
            0
        );
    }
}

library ERC1155BasicDeployer {
    function _1155BasicDeploy(
        string memory _tokenSalt,
        string memory _uri,
        uint256 _price,
        uint256 _maxSupply,
        address _splitter,
        address _router
    ) public returns (bytes32 tokenSalt, address deployed) {
        SplitterImpl splitter = SplitterImpl(
            payable(_splitter)
        );
        tokenSalt = keccak256(bytes(_tokenSalt));
        deployed = CREATE3.deploy(
            tokenSalt,
            abi.encodePacked(
                type(ERC1155Basic).creationCode,
                abi.encode(
                    _uri,
                    _price,
                    _maxSupply,
                    splitter,
                    750, // fixed 7.5% royalties
                    _router
                )
            ),
            0
        );
    }
}

library ERC1155WhitelistDeployer {
    function _1155WhitelistDeploy(
        string memory _tokenSalt,
        string memory _uri,
        uint256 _price,
        uint256 _maxSupply,
        address _splitter,
        address _router
    ) public returns (bytes32 tokenSalt, address deployed) {
        SplitterImpl splitter = SplitterImpl(
            payable(_splitter)
        );
        tokenSalt = keccak256(bytes(_tokenSalt));
        deployed = CREATE3.deploy(
            tokenSalt,
            abi.encodePacked(
                type(ERC1155Whitelist).creationCode,
                abi.encode(
                    _uri,
                    _price,
                    _maxSupply,
                    splitter,
                    750, // fixed 7.5% royalties
                    _router
                )
            ),
            0
        );
    }
}

library ERC1155LazyDeployer {
    function _1155LazyDeploy(
        string memory _tokenSalt,
        string memory _uri,
        address _splitter,
        address _router,
        address _signer
    ) public returns (bytes32 tokenSalt, address deployed) {
        SplitterImpl splitter = SplitterImpl(
            payable(_splitter)
        );
        tokenSalt = keccak256(bytes(_tokenSalt));
        deployed = CREATE3.deploy(
            tokenSalt,
            abi.encodePacked(
                type(ERC1155Lazy).creationCode,
                abi.encode(
                    _uri,
                    splitter,
                    750, // fixed 7.5% royalties
                    _router,
                    _signer
                )
            ),
            0
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

import { SplitterImpl } from "../../Types.sol";

import { CREATE3 } from "../utils/CREATE3.sol";

library SplitterDeployer {
    function _SplitterDeploy(
        string memory _salt,
        address[] memory _payees,
        uint256[] memory _shares
    ) public returns (address deployed) {
        bytes32 salt = keccak256(bytes(_salt));
        deployed = CREATE3.deploy(
            salt,
            abi.encodePacked(
                type(SplitterImpl).creationCode,
                abi.encode(_payees, _shares)
            ),
            0
        );
        // return SplitterImpl(payable(deployed));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

/// @author Modified from OpenZeppelin Contracts
/// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol)

/// @dev Contract module which allows children to implement an emergency stop
/// mechanism that can be triggered by an authorized account.
/// This module is used through inheritance. It will make available the
/// modifiers `whenNotPaused` and `whenPaused`, which can be applied to
/// the functions of your contract. Note that they will not be pausable by
/// simply including this module, only once the modifiers are put in place.

abstract contract Pausable {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "PAUSED");
        _;
    }

    modifier whenPaused() {
        require(paused(), "UNPAUSED");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(
        address indexed user,
        address indexed newOwner
    );

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner)
        public
        virtual
        onlyOwner
    {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// // SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

abstract contract DCPrevent {
    address private immutable og;

    modifier isThisOg() {
        selfReferencePointer();
        _;
    }

    constructor() {
        og = address(this);
    }

    function selfReferencePointer() private view {
        if (address(this) != og) revert("BAD_CALL");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

import { SplitterImpl } from "./lib/splitter/SplitterImpl.sol";
import { IERC721 } from "./lib/tokens/ERC721/Base/interfaces/IERC721.sol";
import { IERC1155 } from "./lib/tokens/ERC1155/Base/interfaces/IERC1155.sol";

// prettier-ignore
library Types {
    enum ERC721Type {
        ERC721Minimal,    // := 0
        ERC721Basic,      // := 1
        ERC721Whitelist,  // := 2
        ERC721Lazy        // := 3
    }
    
    enum ERC1155Type {
        ERC1155Minimal,    // := 0
        ERC1155Basic,      // := 1
        ERC1155Whitelist,  // := 2
        ERC1155Lazy        // := 3
    }

    struct Collection721 {
        address creator;
        Types.ERC721Type colType;
        bytes32 colSalt;
        uint256 blocknumber;
        address splitter;
    }

    struct Collection1155 {
        address creator;
        Types.ERC1155Type colType;
        bytes32 colSalt;
        uint256 blocknumber;
        address splitter;
    }

    struct SplitterConfig {
        address splitter;
        bytes32 splitterSalt;
        address ambassador;
        uint256 ambShare;
        bool valid;
    }

    struct Voucher {
        bytes32 voucherId;
        address[] users;
        uint256 amount;
        uint256 price;
    }

    struct UserBatch {
        bytes32 voucherId;
        uint256[] ids;
        uint256 price;
        address user;
    }

    /// @param orderType Values legend:
    /// 0=Fixed Price; 1=Dutch Auction; 2=English Auction.
    /// @param endBlock Equals to canceled order when value is set to 0.
    struct Order721 {
        uint8 orderType;
        address seller;
        IERC721 token;
        uint256 tokenId;
        uint256 startPrice;
        uint256 endPrice;
        uint256 startBlock;
        uint256 endBlock;
        uint256 lastBidPrice;
        address lastBidder;
        bool isSold;
    }

    /// @param orderType Values legend:
    /// 0=Fixed Price; 1=Dutch Auction; 2=English Auction.
    /// @param endBlock Equals to canceled order when value is set to 0.
    struct Order1155 {
        uint8 orderType;
        address seller;
        IERC1155 token;
        uint256 tokenId;
        uint256 amount;
        uint256 startPrice;
        uint256 endPrice;
        uint256 startBlock;
        uint256 endBlock;
        uint256 lastBidPrice;
        address lastBidder;
        bool isSold;
    }
}

/* 
    ├─ type: ContractDefinition
    ├─ name: Types
    ├─ baseContracts
    ├─ subNodes
    │  ├─ 0
    │  │  ├─ type: EnumDefinition
    │  │  ├─ name: ERC721Type
    │  │  └─ members
    │  │     ├─ 0
    │  │     │  ├─ type: EnumValue
    │  │     │  └─ name: ERC721Minimal
    │  │     ├─ 1
    │  │     │  ├─ type: EnumValue
    │  │     │  └─ name: ERC721Basic
    │  │     ├─ 2
    │  │     │  ├─ type: EnumValue
    │  │     │  └─ name: ERC721Whitelist
    │  │     └─ 3
    │  │        ├─ type: EnumValue
    │  │        └─ name: ERC721Lazy
    │  ├─ 1
    │  │  ├─ type: StructDefinition
    │  │  ├─ name: Collection
    │  │  └─ members
    │  │     ├─ 0
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: ElementaryTypeName
    │  │     │  │  ├─ name: address
    │  │     │  │  └─ stateMutability
    │  │     │  ├─ name: creator
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: creator
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     ├─ 1
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: UserDefinedTypeName
    │  │     │  │  └─ namePath: Types.ERC721Type
    │  │     │  ├─ name: colType
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: colType
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     ├─ 2
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: ElementaryTypeName
    │  │     │  │  ├─ name: bytes32
    │  │     │  │  └─ stateMutability
    │  │     │  ├─ name: colSalt
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: colSalt
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     ├─ 3
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: ElementaryTypeName
    │  │     │  │  ├─ name: uint256
    │  │     │  │  └─ stateMutability
    │  │     │  ├─ name: blocknumber
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: blocknumber
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     └─ 4
    │  │        ├─ type: VariableDeclaration
    │  │        ├─ typeName
    │  │        │  ├─ type: UserDefinedTypeName
    │  │        │  └─ namePath: SplitterImpl
    │  │        ├─ name: splitter
    │  │        ├─ identifier
    │  │        │  ├─ type: Identifier
    │  │        │  └─ name: splitter
    │  │        ├─ storageLocation
    │  │        ├─ isStateVar: false
    │  │        ├─ isIndexed: false
    │  │        └─ expression
    │  ├─ 2
    │  │  ├─ type: StructDefinition
    │  │  ├─ name: SplitterConfig
    │  │  └─ members
    │  │     ├─ 0
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: UserDefinedTypeName
    │  │     │  │  └─ namePath: SplitterImpl
    │  │     │  ├─ name: splitter
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: splitter
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     ├─ 1
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: ElementaryTypeName
    │  │     │  │  ├─ name: bytes32
    │  │     │  │  └─ stateMutability
    │  │     │  ├─ name: splitterSalt
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: splitterSalt
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     ├─ 2
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: ElementaryTypeName
    │  │     │  │  ├─ name: address
    │  │     │  │  └─ stateMutability
    │  │     │  ├─ name: ambassador
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: ambassador
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     ├─ 3
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: ElementaryTypeName
    │  │     │  │  ├─ name: uint256
    │  │     │  │  └─ stateMutability
    │  │     │  ├─ name: ambShare
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: ambShare
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     └─ 4
    │  │        ├─ type: VariableDeclaration
    │  │        ├─ typeName
    │  │        │  ├─ type: ElementaryTypeName
    │  │        │  ├─ name: bool
    │  │        │  └─ stateMutability
    │  │        ├─ name: valid
    │  │        ├─ identifier
    │  │        │  ├─ type: Identifier
    │  │        │  └─ name: valid
    │  │        ├─ storageLocation
    │  │        ├─ isStateVar: false
    │  │        ├─ isIndexed: false
    │  │        └─ expression
    │  ├─ 3
    │  │  ├─ type: StructDefinition
    │  │  ├─ name: Voucher
    │  │  └─ members
    │  │     ├─ 0
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: ElementaryTypeName
    │  │     │  │  ├─ name: bytes32
    │  │     │  │  └─ stateMutability
    │  │     │  ├─ name: voucherId
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: voucherId
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     ├─ 1
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: ArrayTypeName
    │  │     │  │  ├─ baseTypeName
    │  │     │  │  │  ├─ type: ElementaryTypeName
    │  │     │  │  │  ├─ name: address
    │  │     │  │  │  └─ stateMutability
    │  │     │  │  └─ length
    │  │     │  ├─ name: users
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: users
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     ├─ 2
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: ElementaryTypeName
    │  │     │  │  ├─ name: uint256
    │  │     │  │  └─ stateMutability
    │  │     │  ├─ name: amount
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: amount
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     └─ 3
    │  │        ├─ type: VariableDeclaration
    │  │        ├─ typeName
    │  │        │  ├─ type: ElementaryTypeName
    │  │        │  ├─ name: uint256
    │  │        │  └─ stateMutability
    │  │        ├─ name: price
    │  │        ├─ identifier
    │  │        │  ├─ type: Identifier
    │  │        │  └─ name: price
    │  │        ├─ storageLocation
    │  │        ├─ isStateVar: false
    │  │        ├─ isIndexed: false
    │  │        └─ expression
    │  └─ 4
    │     ├─ type: StructDefinition
    │     ├─ name: Order
    │     └─ members
    │        ├─ 0
    │        │  ├─ type: VariableDeclaration
    │        │  ├─ typeName
    │        │  │  ├─ type: ElementaryTypeName
    │        │  │  ├─ name: uint8
    │        │  │  └─ stateMutability
    │        │  ├─ name: orderType
    │        │  ├─ identifier
    │        │  │  ├─ type: Identifier
    │        │  │  └─ name: orderType
    │        │  ├─ storageLocation
    │        │  ├─ isStateVar: false
    │        │  ├─ isIndexed: false
    │        │  └─ expression
    │        ├─ 1
    │        │  ├─ type: VariableDeclaration
    │        │  ├─ typeName
    │        │  │  ├─ type: ElementaryTypeName
    │        │  │  ├─ name: address
    │        │  │  └─ stateMutability
    │        │  ├─ name: seller
    │        │  ├─ identifier
    │        │  │  ├─ type: Identifier
    │        │  │  └─ name: seller
    │        │  ├─ storageLocation
    │        │  ├─ isStateVar: false
    │        │  ├─ isIndexed: false
    │        │  └─ expression
    │        ├─ 2
    │        │  ├─ type: VariableDeclaration
    │        │  ├─ typeName
    │        │  │  ├─ type: UserDefinedTypeName
    │        │  │  └─ namePath: IERC721
    │        │  ├─ name: token
    │        │  ├─ identifier
    │        │  │  ├─ type: Identifier
    │        │  │  └─ name: token
    │        │  ├─ storageLocation
    │        │  ├─ isStateVar: false
    │        │  ├─ isIndexed: false
    │        │  └─ expression
    │        ├─ 3
    │        │  ├─ type: VariableDeclaration
    │        │  ├─ typeName
    │        │  │  ├─ type: ElementaryTypeName
    │        │  │  ├─ name: uint256
    │        │  │  └─ stateMutability
    │        │  ├─ name: tokenId
    │        │  ├─ identifier
    │        │  │  ├─ type: Identifier
    │        │  │  └─ name: tokenId
    │        │  ├─ storageLocation
    │        │  ├─ isStateVar: false
    │        │  ├─ isIndexed: false
    │        │  └─ expression
    │        ├─ 4
    │        │  ├─ type: VariableDeclaration
    │        │  ├─ typeName
    │        │  │  ├─ type: ElementaryTypeName
    │        │  │  ├─ name: uint256
    │        │  │  └─ stateMutability
    │        │  ├─ name: startPrice
    │        │  ├─ identifier
    │        │  │  ├─ type: Identifier
    │        │  │  └─ name: startPrice
    │        │  ├─ storageLocation
    │        │  ├─ isStateVar: false
    │        │  ├─ isIndexed: false
    │        │  └─ expression
    │        ├─ 5
    │        │  ├─ type: VariableDeclaration
    │        │  ├─ typeName
    │        │  │  ├─ type: ElementaryTypeName
    │        │  │  ├─ name: uint256
    │        │  │  └─ stateMutability
    │        │  ├─ name: endPrice
    │        │  ├─ identifier
    │        │  │  ├─ type: Identifier
    │        │  │  └─ name: endPrice
    │        │  ├─ storageLocation
    │        │  ├─ isStateVar: false
    │        │  ├─ isIndexed: false
    │        │  └─ expression
    │        ├─ 6
    │        │  ├─ type: VariableDeclaration
    │        │  ├─ typeName
    │        │  │  ├─ type: ElementaryTypeName
    │        │  │  ├─ name: uint256
    │        │  │  └─ stateMutability
    │        │  ├─ name: startBlock
    │        │  ├─ identifier
    │        │  │  ├─ type: Identifier
    │        │  │  └─ name: startBlock
    │        │  ├─ storageLocation
    │        │  ├─ isStateVar: false
    │        │  ├─ isIndexed: false
    │        │  └─ expression
    │        ├─ 7
    │        │  ├─ type: VariableDeclaration
    │        │  ├─ typeName
    │        │  │  ├─ type: ElementaryTypeName
    │        │  │  ├─ name: uint256
    │        │  │  └─ stateMutability
    │        │  ├─ name: endBlock
    │        │  ├─ identifier
    │        │  │  ├─ type: Identifier
    │        │  │  └─ name: endBlock
    │        │  ├─ storageLocation
    │        │  ├─ isStateVar: false
    │        │  ├─ isIndexed: false
    │        │  └─ expression
    │        ├─ 8
    │        │  ├─ type: VariableDeclaration
    │        │  ├─ typeName
    │        │  │  ├─ type: ElementaryTypeName
    │        │  │  ├─ name: uint256
    │        │  │  └─ stateMutability
    │        │  ├─ name: lastBidPrice
    │        │  ├─ identifier
    │        │  │  ├─ type: Identifier
    │        │  │  └─ name: lastBidPrice
    │        │  ├─ storageLocation
    │        │  ├─ isStateVar: false
    │        │  ├─ isIndexed: false
    │        │  └─ expression
    │        ├─ 9
    │        │  ├─ type: VariableDeclaration
    │        │  ├─ typeName
    │        │  │  ├─ type: ElementaryTypeName
    │        │  │  ├─ name: address
    │        │  │  └─ stateMutability
    │        │  ├─ name: lastBidder
    │        │  ├─ identifier
    │        │  │  ├─ type: Identifier
    │        │  │  └─ name: lastBidder
    │        │  ├─ storageLocation
    │        │  ├─ isStateVar: false
    │        │  ├─ isIndexed: false
    │        │  └─ expression
    │        └─ 10
    │           ├─ type: VariableDeclaration
    │           ├─ typeName
    │           │  ├─ type: ElementaryTypeName
    │           │  ├─ name: bool
    │           │  └─ stateMutability
    │           ├─ name: isSold
    │           ├─ identifier
    │           │  ├─ type: Identifier
    │           │  └─ name: isSold
    │           ├─ storageLocation
    │           ├─ isStateVar: false
    │           ├─ isIndexed: false
    │           └─ expression
    └─ kind: library
 */

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

/// @notice Library for converting between addresses and bytes32 values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/Bytes32AddressLib.sol)
library Bytes32AddressLib {
    function fromLast20Bytes(bytes32 bytesValue)
        internal
        pure
        returns (address)
    {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue)
        internal
        pure
        returns (bytes32)
    {
        return bytes32(bytes20(addressValue));
    }
}

/// @notice Deploy to deterministic addresses without an initcode factor.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/CREATE3.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/create3/blob/master/contracts/Create3.sol)
library CREATE3 {
    using Bytes32AddressLib for bytes32;

    //--------------------------------------------------------------------------------//
    // Opcode     | Opcode + Arguments    | Description      | Stack View             //
    //--------------------------------------------------------------------------------//
    // 0x36       |  0x36                 | CALLDATASIZE     | size                   //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 size                 //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 0 size               //
    // 0x37       |  0x37                 | CALLDATACOPY     |                        //
    // 0x36       |  0x36                 | CALLDATASIZE     | size                   //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 size                 //
    // 0x34       |  0x34                 | CALLVALUE        | value 0 size           //
    // 0xf0       |  0xf0                 | CREATE           | newContract            //
    //--------------------------------------------------------------------------------//
    // Opcode     | Opcode + Arguments    | Description      | Stack View             //
    //--------------------------------------------------------------------------------//
    // 0x67       |  0x67XXXXXXXXXXXXXXXX | PUSH8 bytecode   | bytecode               //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 bytecode             //
    // 0x52       |  0x52                 | MSTORE           |                        //
    // 0x60       |  0x6008               | PUSH1 08         | 8                      //
    // 0x60       |  0x6018               | PUSH1 18         | 24 8                   //
    // 0xf3       |  0xf3                 | RETURN           |                        //
    //--------------------------------------------------------------------------------//
    bytes internal constant PROXY_BYTECODE =
        hex"67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3";

    bytes32 internal constant PROXY_BYTECODE_HASH =
        keccak256(PROXY_BYTECODE);

    function deploy(
        bytes32 salt,
        bytes memory creationCode,
        uint256 value
    ) internal returns (address deployed) {
        bytes memory proxyChildBytecode = PROXY_BYTECODE;

        address proxy;
        assembly {
            // Deploy a new contract with our pre-made bytecode via CREATE2.
            // We start 32 bytes into the code to avoid copying the byte length.
            proxy := create2(
                0,
                add(proxyChildBytecode, 32),
                mload(proxyChildBytecode),
                salt
            )
        }
        require(proxy != address(0), "DEPLOYMENT_FAILED");

        deployed = getDeployed(salt);
        (bool success, ) = proxy.call{ value: value }(
            creationCode
        );
        require(
            success && deployed.code.length != 0,
            "INITIALIZATION_FAILED"
        );
    }

    function getDeployed(bytes32 salt)
        internal
        view
        returns (address)
    {
        address proxy = keccak256(
            abi.encodePacked(
                // Prefix:
                bytes1(0xFF),
                // Creator:
                address(this),
                // Salt:
                salt,
                // Bytecode hash:
                PROXY_BYTECODE_HASH
            )
        ).fromLast20Bytes();

        return
            keccak256(
                abi.encodePacked(
                    // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01)
                    // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex)
                    hex"d6_94",
                    proxy,
                    hex"01" // Nonce of the proxy contract (1)
                )
            ).fromLast20Bytes();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

// import { Types } from "../../Types.sol";

/// @title Factory Verifier
/// @notice Core contract binding interface that connect both
/// `MADMarketplace` and `MADRouter` storage verifications made to `MADFactory`.
interface FactoryVerifier {
    // using Types for Types.ERC721Type;

    /// @dev 0x4ca88867
    error AccessDenied();

    /// @notice Authority validator for no-fee marketplace listing.
    /// @dev Function Sighash := 0x76de0f3d
    /// @dev Binds Marketplace's pull payment methods to Factory storage.
    /// @param _token Address of the traded token.
    /// @param _user Token Seller that must match collection creator for no-fee listing.
    /// @return stdout := 1 as boolean standard output.
    function creatorAuth(address _token, address _user)
        external
        view
        returns (bool stdout);

    /// @notice Authority validator for `MADRouter` creator settings and withdraw functions.
    /// @dev Function Sighash := 0xb64bd5eb
    /// @param _colID 32 bytes collection ID value.
    /// @return creator bb
    /// @return check Boolean output to either approve or reject call's `tx.origin` function access.
    function creatorCheck(bytes32 _colID)
        external
        view
        returns (address creator, bool check);

    // /// @dev Convert `colID` to address (32bytes => 20bytes).
    // /// @dev Function Sighash := 0xc3e15ec0
    // function getColAddress(bytes32 _colID)
    //     external
    //     pure
    //     returns (address colAddress);

    /// @dev Convert address to `colID` (20bytes => 32bytes).
    /// @dev Function Sighash := 0x617d1d3b
    function getColID(address _colAddress)
        external
        pure
        returns (bytes32 colID);

    /// @dev Returns the collection type uint8 value in case token and user are authorized.
    /// @dev Function Sighash := 0xd93cb8fd
    function typeChecker(bytes32 _colID)
        external
        view
        returns (uint8 pointer);
}

// SPDX-License-Identifier: AGPL-3.0-only

/// @title Payment splitter base contract that allows to split Ether payments among a group of accounts.
/// @author Modified from OpenZeppelin Contracts
/// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/finance/PaymentSplitter.sol)

pragma solidity 0.8.4;

import "../utils/SafeTransferLib.sol";

// import "./Address.sol";

/// @notice The split can be in equal parts or in any other arbitrary proportion.
/// The way this is specified is by assigning each account to a number of shares.
/// Of all the Ether that this contract receives, each account will then be able to claim
/// an amount proportional to the percentage of total shares they were assigned.

/// @dev `PaymentSplitter` follows a _pull payment_ model. This means that payments are not
/// automatically forwarded to the accounts but kept in this contract, and the actual transfer
/// is triggered asa separate step by calling the {release} function.

/// @dev This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether).
/// Rebasing tokens, and tokens that apply fees during transfers, are likely to not be supported
/// as expected. If in doubt, we encourage you to run tests before sending real value to this contract.

contract SplitterImpl {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    event ERC20PaymentReleased(
        ERC20 indexed token,
        address to,
        uint256 amount
    );

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(ERC20 => uint256) private _erc20TotalReleased;
    mapping(ERC20 => mapping(address => uint256))
        private _erc20Released;

    /// @dev Creates an instance of `PaymentSplitter` where each account in `payees`
    /// is assigned the number of shares at the matching position in the `shares` array.
    /// @dev All addresses in `payees` must be non-zero. Both arrays must have the same
    /// non-zero length, and there must be no duplicates in `payees`.
    constructor(
        address[] memory payees,
        uint256[] memory shares_
    ) payable {
        require(
            payees.length == shares_.length,
            "LENGTH_MISMATCH"
        );
        require(
            payees.length != 0, /* > 0 */
            "NO_PAYEES"
        );
        uint256 i;
        uint256 len = payees.length;
        for (i; i < len; ) {
            _addPayee(payees[i], shares_[i]);
            unchecked {
                ++i;
            }
        }
        // no risk of loop overflow since payees are bounded by factory parameters
    }

    /// @dev The Ether received will be logged with {PaymentReceived} events.
    /// Note that these events are not fully reliable: it's possible for a contract
    /// to receive Ether without triggering this function. This only affects the
    /// reliability of the events, and not the actual splitting of Ether.
    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }

    /// @dev Getter for the total shares held by payees.
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /// @dev Getter for the total amount of Ether already released.
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /// @dev Getter for the total amount of `token` already released.
    /// `token` should be the address of an ERC20 contract.
    function totalReleased(ERC20 token)
        public
        view
        returns (uint256)
    {
        return _erc20TotalReleased[token];
    }

    /// @dev Getter for the amount of shares held by an account.
    function shares(address account)
        public
        view
        returns (uint256)
    {
        return _shares[account];
    }

    /// @dev Getter for the amount of Ether already released to a payee.
    function released(address account)
        public
        view
        returns (uint256)
    {
        return _released[account];
    }

    /// @dev Getter for the amount of `token` tokens already released to a payee.
    /// `token` should be the address of an ERC20 contract.
    function released(ERC20 token, address account)
        public
        view
        returns (uint256)
    {
        return _erc20Released[token][account];
    }

    /// @dev Getter for the address of the payee number `index`.
    function payee(uint256 index)
        public
        view
        returns (address)
    {
        return _payees[index];
    }

    /// @dev Getter for the amount of payee's releasable Ether.
    function releasable(address account)
        public
        view
        returns (uint256)
    {
        uint256 totalReceived = address(this).balance +
            totalReleased();
        return
            _pendingPayment(
                account,
                totalReceived,
                released(account)
            );
    }

    /// @dev Getter for the amount of payee's releasable `token` tokens.
    /// `token` should be the address of an ERC20 contract.
    function releasable(ERC20 token, address account)
        public
        view
        returns (uint256)
    {
        uint256 totalReceived = token.balanceOf(
            address(this)
        ) + totalReleased(token);
        return
            _pendingPayment(
                account,
                totalReceived,
                released(token, account)
            );
    }

    /// @dev Triggers a transfer to `account` of the amount of Ether they are owed,
    /// according to their percentage of the total shares and their previous withdrawals.
    function release(address payable account) public virtual {
        require(
            _shares[account] != 0, /* > 0 */
            "NO_SHARES"
        );

        uint256 payment = releasable(account);

        require(payment != 0, "DENIED_ACCOUNT");
        // require(
        //     address(this).balance >= payment,
        //     "INSUFFICIENT_BALANCE"
        // );

        _released[account] += payment;
        _totalReleased += payment;

        // Address.sendValue(account, payment);
        SafeTransferLib.safeTransferETH(account, payment);
        emit PaymentReleased(account, payment);
    }

    /// @dev Triggers a transfer to `account` of the amount of `token` tokens
    /// they are owed, according to their percentage of the total shares and
    /// their previous withdrawals. `token` must be the address of an ERC20 contract.
    function release(ERC20 token, address account)
        public
        virtual
    {
        require(
            _shares[account] != 0, /* > 0 */
            "NO_SHARES"
        );

        uint256 payment = releasable(token, account);

        require(payment != 0, "DENIED_ACCOUNT");
        // require(
        //     token.balanceOf(address(this)) >= payment,
        //     "INSUFFICIENT_BALANCE"
        // );

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeTransferLib.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /// @dev internal logic for computing the pending payment of an `account`,
    /// given the token historical balances and already released amounts.
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return
            (totalReceived * _shares[account]) /
            _totalShares -
            alreadyReleased;
    }

    /// @dev Add a new payee to the contract.
    /// @param account The address of the payee to add.
    /// @param shares_ The number of shares owned by the payee.
    function _addPayee(address account, uint256 shares_)
        private
    {
        require(account != address(0), "DEAD_ADDRESS");
        require(
            shares_ != 0, /* > 0 */
            "INVALID_SHARE"
        );
        require(_shares[account] == 0, "ALREADY_PAYEE");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

/// @title Required interface of an ERC721 compliant contract.
interface IERC721 {
    /// @dev Emitted when `tokenId` token is transferred from `from` to `to`.
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /// @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /// @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /// @return balance Returns the number of tokens in ``owner``'s account.
    function balanceOf(address owner)
        external
        view
        returns (uint256 balance);

    /// @return owner Returns the owner of the `tokenId` token.
    /// @dev Requirements: `tokenId` must exist.
    function ownerOf(uint256 tokenId)
        external
        view
        returns (address owner);

    /// @notice Safely transfers `tokenId` token from `from` to `to`.
    /// @dev Emits a {Transfer} event.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /// @notice Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
    /// are aware of the ERC721 protocol to prevent tokens from being forever locked.
    /// @dev Emits a {Transfer} event.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /// @notice Transfers `tokenId` token from `from` to `to`.
    /// @dev Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
    /// @dev Emits a {Transfer} event.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /// @notice Gives permission to `to` to transfer `tokenId` token to another account.
    /// The approval is cleared when the token is transferred. Only a single account can be
    /// approved at a time, so approving the zero address clears previous approvals.
    /// @dev Emits an {Approval} event.
    function approve(address to, uint256 tokenId) external;

    /// @notice Approve or remove `operator` as an operator for the caller.
    /// @dev Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
    /// @dev Emits an {ApprovalForAll} event.
    function setApprovalForAll(
        address operator,
        bool _approved
    ) external;

    /// @notice Returns the account approved for `tokenId` token.
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /// @notice Returns if the `operator` is allowed to manage all of the assets of `owner`.
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /// @notice Queries EIP2981 royalty info for marketplace royalty payment enforcement.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

/// @title Required interface of an ERC1155 compliant contract.
interface IERC1155 {
    /// @dev Emitted when `value` tokens of token type `id` are transferred
    /// from `from` to `to` by `operator`.
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /// @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from`
    /// and `to` are the same for all transfers.
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /// @dev Emitted when `account` grants or revokes permission to `operator` to
    /// transfer their tokens, according to `approved`.
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /// @return Returns the amount of tokens of token type `id` owned by `account`.
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /// @dev Batched version of {balanceOf}.
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /// @notice Transfers `amount` tokens of token type `id` from `from` to `to`,
    /// making sure the recipient can receive the tokens.
    /// @dev Emits a {TransferSingle} event.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /// @dev Batched version of {safeTransferFrom}.
    /// @dev Emits a {TransferBatch} event.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    /// @notice Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`.
    /// @dev `operator` cannot be the caller.
    /// @dev Emits an {ApprovalForAll} event.
    function setApprovalForAll(
        address operator,
        bool approved
    ) external;

    /// @notice Returns true if `operator` is approved to transfer ``account``'s tokens.
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    /// @notice Queries EIP2981 royalty info for marketplace royalty payment enforcement.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    /// @notice Queries for ERC165 introspection support.
    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.4;

import { ERC20 } from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount)
        internal
    {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(
                        eq(mload(0), 1),
                        gt(returndatasize(), 31)
                    ),
                    iszero(returndatasize())
                ),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(
                    gas(),
                    token,
                    0,
                    freeMemoryPointer,
                    100,
                    0,
                    32
                )
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(
                        eq(mload(0), 1),
                        gt(returndatasize(), 31)
                    ),
                    iszero(returndatasize())
                ),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(
                    gas(),
                    token,
                    0,
                    freeMemoryPointer,
                    68,
                    0,
                    32
                )
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0x095ea7b300000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(
                        eq(mload(0), 1),
                        gt(returndatasize(), 31)
                    ),
                    iszero(returndatasize())
                ),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(
                    gas(),
                    token,
                    0,
                    freeMemoryPointer,
                    68,
                    0,
                    32
                )
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.4;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256))
        public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(
            deadline >= block.timestamp,
            "PERMIT_DEADLINE_EXPIRED"
        );

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(
                recoveredAddress != address(0) &&
                    recoveredAddress == owner,
                "INVALID_SIGNER"
            );

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR()
        public
        view
        virtual
        returns (bytes32)
    {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : computeDomainSeparator();
    }

    function computeDomainSeparator()
        internal
        view
        virtual
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount)
        internal
        virtual
    {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount)
        internal
        virtual
    {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

import { ERC1155MinimalEvents } from "../Base/interfaces/ERC1155EventAndErrors.sol";
import { ERC1155B as ERC1155, ERC1155TokenReceiver } from "../Base/ERC1155B.sol";
import { ERC2981 } from "../../common/ERC2981.sol";
import { ERC20 } from "../../ERC20.sol";
import { SplitterImpl } from "../../../splitter/SplitterImpl.sol";

// import { ReentrancyGuard } from "../../../security/ReentrancyGuard.sol";
import { Owned } from "../../../auth/Owned.sol";
import { SafeTransferLib } from "../../../utils/SafeTransferLib.sol";

contract ERC1155Minimal is
    ERC1155,
    ERC2981,
    ERC1155MinimalEvents,
    ERC1155TokenReceiver,
    Owned
    // ReentrancyGuard
{
    ////////////////////////////////////////////////////////////////
    //                           STORAGE                          //
    ////////////////////////////////////////////////////////////////

    SplitterImpl public splitter;
    uint256 public price;
    string private _uri;
    /// @dev  default := false
    bool private minted;
    /// @dev  default := false
    bool public publicMintState;

    ////////////////////////////////////////////////////////////////
    //                         CONSTRUCTOR                        //
    ////////////////////////////////////////////////////////////////

    /// @dev The fee of royalties denominator is 10000 in BPS.
    constructor(
        string memory _tokenURI,
        uint256 _price,
        SplitterImpl _splitter,
        uint96 _fraction,
        address _router
    ) Owned(_router) {
        _uri = _tokenURI;
        price = _price;
        splitter = _splitter;
        _royaltyFee = _fraction;
        _royaltyRecipient = payable(splitter);

        emit RoyaltyFeeSet(_royaltyFee);
        emit RoyaltyRecipientSet(_royaltyRecipient);
    }

    ////////////////////////////////////////////////////////////////
    //                          OWNER FX                          //
    ////////////////////////////////////////////////////////////////

    /// @dev Can't be reminted if already minted, due to boolean.
    function safeMint(address to) external onlyOwner {
        if (minted == true) revert("ALREADY_MINTED");

        minted = true;
        _mint(to, 1, "");
    }

    /// @dev Can't be reburnt since `minted` is not updated to false.
    function burn() external onlyOwner {
        _burn(1);
    }

    function setPublicMintState(bool _publicMintState)
        external
        onlyOwner
    {
        publicMintState = _publicMintState;

        emit PublicMintStateSet(publicMintState);
    }

    function withdraw() external onlyOwner {
        SafeTransferLib.safeTransferETH(
            tx.origin,
            address(this).balance
        );
    }

    function withdrawERC20(ERC20 _token) external onlyOwner {
        SafeTransferLib.safeTransfer(
            _token,
            tx.origin,
            _token.balanceOf(address(this))
        );
    }

    ////////////////////////////////////////////////////////////////
    //                           USER FX                          //
    ////////////////////////////////////////////////////////////////

    function publicMint() external payable {
        if (!publicMintState) revert("PUBLICMINT_OFF");
        require(msg.value == price, "WRONG_PRICE");
        if (minted == true) revert("ALREADY_MINTED");

        minted = true;
        _mint(msg.sender, 1, "");
    }

    ////////////////////////////////////////////////////////////////
    //                           VIEW FX                          //
    ////////////////////////////////////////////////////////////////

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(id == 1, "INVALID_ID");
        if (!minted) revert("NOT_MINTED");
        return _uri;
    }

    ////////////////////////////////////////////////////////////////
    //                      REQUIRED OVERRIDES                    //
    ////////////////////////////////////////////////////////////////

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(ERC2981)
        returns (bool)
    {
        return
            // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7 ||
            // ERC165 Interface ID for ERC1155
            interfaceId == 0xd9b67a26 ||
            // ERC165 Interface ID for ERC1155MetadataURI
            interfaceId == 0x0e89341c ||
            // ERC165 Interface ID for ERC2981
            interfaceId == 0x2a55205a;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

import { ERC1155BasicEvents } from "../Base/interfaces/ERC1155EventAndErrors.sol";
import { ERC1155B as ERC1155, ERC1155TokenReceiver } from "../Base/ERC1155B.sol";
import { ERC2981 } from "../../common/ERC2981.sol";
import { ERC20 } from "../../ERC20.sol";

import { Owned } from "../../../auth/Owned.sol";
import { ReentrancyGuard } from "../../../security/ReentrancyGuard.sol";
import { SplitterImpl } from "../../../splitter/SplitterImpl.sol";
import { Counters } from "../../../utils/Counters.sol";
import { Strings } from "../../../utils/Strings.sol";
import { SafeTransferLib } from "../../../utils/SafeTransferLib.sol";

contract ERC1155Basic is
    ERC1155,
    ERC2981,
    ERC1155BasicEvents,
    ERC1155TokenReceiver,
    Owned,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    ////////////////////////////////////////////////////////////////
    //                           STORAGE                          //
    ////////////////////////////////////////////////////////////////

    Counters.Counter private liveSupply;

    string private _uri;
    uint256 public price;
    /// @dev Capped max supply.
    uint256 public maxSupply;
    /// @dev default := false.
    bool public publicMintState;
    SplitterImpl public splitter;

    ////////////////////////////////////////////////////////////////
    //                          MODIFIERS                         //
    ////////////////////////////////////////////////////////////////

    modifier publicMintAccess() {
        if (!publicMintState) revert("PublicMintClosed");
        _;
    }

    modifier hasReachedMax(uint256 amount) {
        if (totalSupply() + amount > maxSupply)
            revert("MaxSupplyReached");
        _;
    }

    modifier priceCheck(uint256 _price, uint256 amount) {
        if (_price * amount != msg.value)
            revert("WrongPrice");
        _;
    }

    ////////////////////////////////////////////////////////////////
    //                         CONSTRUCTOR                        //
    ////////////////////////////////////////////////////////////////

    constructor(
        string memory __uri,
        uint256 _price,
        uint256 _maxSupply,
        SplitterImpl _splitter,
        uint96 _fraction,
        address _router
    ) Owned(_router) {
        _uri = __uri;
        price = _price;
        maxSupply = _maxSupply;
        splitter = _splitter;
        _royaltyFee = _fraction;
        _royaltyRecipient = payable(splitter);

        emit RoyaltyFeeSet(_royaltyFee);
        emit RoyaltyRecipientSet(_royaltyRecipient);
    }

    ////////////////////////////////////////////////////////////////
    //                         OWNER FX                           //
    ////////////////////////////////////////////////////////////////

    function setURI(string memory __uri) external onlyOwner {
        _uri = __uri;

        emit BaseURISet(__uri);
    }

    function setPublicMintState(bool _publicMintState)
        external
        onlyOwner
    {
        publicMintState = _publicMintState;

        emit PublicMintStateSet(_publicMintState);
    }

    /// @dev Burns an arbitrary length array of ids of different owners.
    function burn(uint256[] memory ids) external onlyOwner {
        uint256 i;
        uint256 len = ids.length;
        for (i; i < len; ) {
            liveSupply.decrement();
            _burn(ids[i]);
            unchecked {
                ++i;
            }
        }
        assembly {
            if lt(i, len) {
                mstore(0x00, "LOOP_OVERFLOW")
                revert(0x00, 0x20)
            }
        }
        // Transfer events emited by parent ERC1155 contract
    }

    /// @dev Burns an arbitrary length array of ids owned by a single account.
    function burnBatch(address from, uint256[] memory ids)
        external
        onlyOwner
    {
        uint256 i;
        uint256 len = ids.length;
        for (i; i < len; ) {
            liveSupply.decrement();
            unchecked {
                ++i;
            }
        }
        assembly {
            if lt(i, len) {
                mstore(0x00, "LOOP_OVERFLOW")
                revert(0x00, 0x20)
            }
        }
        _batchBurn(from, ids);
        // Transfer event emited by parent ERC1155 contract
    }

    function withdraw() external onlyOwner {
        SafeTransferLib.safeTransferETH(
            tx.origin,
            address(this).balance
        );
    }

    function withdrawERC20(ERC20 _token) external onlyOwner {
        SafeTransferLib.safeTransfer(
            _token,
            tx.origin,
            _token.balanceOf(address(this))
        );
    }

    ////////////////////////////////////////////////////////////////
    //                           USER FX                          //
    ////////////////////////////////////////////////////////////////

    function mint(uint256 amount)
        external
        payable
        nonReentrant
        publicMintAccess
        hasReachedMax(amount)
        priceCheck(price, amount)
    {
        uint256 i;
        for (i; i < amount; ) {
            _mint(msg.sender, _nextId(), "");
            unchecked {
                ++i;
            }
        }
        // assembly overflow check
        assembly {
            if lt(i, amount) {
                mstore(0x00, "LOOP_OVERFLOW")
                revert(0x00, 0x20)
            }
        }
        // Transfer events emited by parent ERC1155 contract
    }

    /// @dev Enables public minting of an arbitrary length array of specific ids.
    function mintBatch(uint256[] memory ids)
        external
        payable
        nonReentrant
        publicMintAccess
    {
        uint256 len = ids.length;
        _mintBatchCheck(len);
        uint256 i;
        for (i; i < len; ) {
            liveSupply.increment();
            unchecked {
                ++i;
            }
        }
        assembly {
            if lt(i, len) {
                mstore(0x00, "LOOP_OVERFLOW")
                revert(0x00, 0x20)
            }
        }
        _batchMint(msg.sender, ids, "");
        // Transfer event emited by parent ERC1155 contract
    }

    ////////////////////////////////////////////////////////////////
    //                          HELPER FX                         //
    ////////////////////////////////////////////////////////////////

    function _mintBatchCheck(uint256 _amount) private view {
        if (price * _amount != msg.value)
            revert("WrongPrice");
        if (totalSupply() + _amount > maxSupply)
            revert("MaxSupplyReached");
    }

    function _nextId() private returns (uint256) {
        liveSupply.increment();
        return liveSupply.current();
    }

    ////////////////////////////////////////////////////////////////
    //                           VIEW FX                          //
    ////////////////////////////////////////////////////////////////

    function getURI() external view returns (string memory) {
        return _uri;
    }

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (id > totalSupply()) {
            // revert("NotMintedYet");
            assembly {
                mstore(0x00, 0xbad086ea)
                revert(0x1c, 0x04)
            }
        }
        return
            string(
                abi.encodePacked(
                    _uri,
                    Strings.toString(id),
                    ".json"
                )
            );
    }

    function totalSupply() public view returns (uint256) {
        return liveSupply.current();
    }

    ////////////////////////////////////////////////////////////////
    //                     REQUIRED OVERRIDES                     //
    ////////////////////////////////////////////////////////////////

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(ERC2981)
        returns (bool)
    {
        return
            // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7 ||
            // ERC165 Interface ID for ERC1155
            interfaceId == 0xd9b67a26 ||
            // ERC165 Interface ID for ERC1155MetadataURI
            interfaceId == 0x0e89341c ||
            // ERC165 Interface ID for ERC2981
            interfaceId == 0x2a55205a;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

import { ERC1155WhitelistEvents } from "../Base/interfaces/ERC1155EventAndErrors.sol";
import { ERC1155B as ERC1155, ERC1155TokenReceiver } from "../Base/ERC1155B.sol";
import { ERC2981 } from "../../common/ERC2981.sol";
import { ERC20 } from "../../ERC20.sol";

import { Owned } from "../../../auth/Owned.sol";
import { ReentrancyGuard } from "../../../security/ReentrancyGuard.sol";
import { MerkleProof } from "../../../utils/MerkleProof.sol";
import { SplitterImpl } from "../../../splitter/SplitterImpl.sol";
import { Counters } from "../../../utils/Counters.sol";
import { Strings } from "../../../utils/Strings.sol";
import { SafeTransferLib } from "../../../utils/SafeTransferLib.sol";

contract ERC1155Whitelist is
    ERC1155,
    ERC2981,
    ERC1155WhitelistEvents,
    ERC1155TokenReceiver,
    Owned,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    ////////////////////////////////////////////////////////////////
    //                           STORAGE                          //
    ////////////////////////////////////////////////////////////////

    Counters.Counter private liveSupply;

    string private _uri;
    uint256 public publicPrice;
    uint256 public maxSupply;

    /// @dev default := false.
    bool public publicMintState;
    SplitterImpl public splitter;

    // merkle
    uint256 public whitelistPrice;
    uint256 public maxWhitelistSupply;
    bytes32 public whitelistMerkleRoot;
    /// @dev default := false.
    bool public whitelistMintState;
    /// @dev Current whitelist supply.
    uint256 public whitelistMinted;

    // free
    uint256 public maxFree;
    uint256 public freeSupply;
    bytes32 public claimListMerkleRoot;
    /// @dev default := false
    bool public freeClaimState;
    /// @dev Default amount to be claimed as free in a collection.
    uint256 public freeAmount;
    /// @dev Stores the amount of whitelist minted tokens of an address.
    /// @dev For fetching purposes and max free claim control.
    mapping(address => bool) public claimed;

    ////////////////////////////////////////////////////////////////
    //                          MODIFIERS                         //
    ////////////////////////////////////////////////////////////////

    modifier publicMintAccess() {
        if (!publicMintState) revert("PublicMintClosed");
        _;
    }

    modifier whitelistMintAccess() {
        if (!whitelistMintState)
            revert("WhitelistMintClosed");
        _;
    }

    modifier freeClaimAccess() {
        if (!freeClaimState) revert("FreeClaimClosed");
        _;
    }

    modifier hasReachedMax(uint256 amount) {
        if (
            totalSupply() + amount >
            maxSupply - maxWhitelistSupply - maxFree
        ) revert("MaxMintReached");
        _;
    }

    modifier canMintFree(uint256 amount) {
        if (freeSupply + amount > maxFree)
            revert("MaxFreeReached");
        if (totalSupply() + amount > maxSupply)
            revert("MaxMintReached");
        _;
    }

    modifier whitelistMax(uint8 amount) {
        if (whitelistMinted + amount > maxWhitelistSupply)
            revert("MaxWhitelistReached");
        if (totalSupply() + amount > maxSupply)
            revert("MaxMintReached");
        _;
    }

    modifier priceCheck(uint256 _price, uint256 amount) {
        if (_price * amount != msg.value)
            revert("WrongPrice");
        _;
    }

    modifier merkleVerify(
        bytes32[] calldata merkleProof,
        bytes32 root
    ) {
        if (
            !MerkleProof.verify(
                merkleProof,
                root,
                bytes32(uint256(uint160(msg.sender)))
            )
        ) revert("AddressDenied");
        _;
    }

    ////////////////////////////////////////////////////////////////
    //                         CONSTRUCTOR                        //
    ////////////////////////////////////////////////////////////////

    constructor(
        string memory __uri,
        uint256 _price,
        uint256 _maxSupply,
        SplitterImpl _splitter,
        uint96 _fraction,
        address _router
    ) Owned(_router) {
        _uri = __uri;
        publicPrice = _price;
        maxSupply = _maxSupply;
        splitter = _splitter;

        _royaltyFee = _fraction;
        _royaltyRecipient = payable(splitter);

        emit RoyaltyFeeSet(_royaltyFee);
        emit RoyaltyRecipientSet(_royaltyRecipient);
    }

    ////////////////////////////////////////////////////////////////
    //                         OWNER FX                           //
    ////////////////////////////////////////////////////////////////

    function whitelistConfig(
        uint256 _price,
        uint256 _supply,
        bytes32 _root
    ) external onlyOwner {
        whitelistPrice = _price;
        maxWhitelistSupply = _supply;
        whitelistMerkleRoot = _root;

        emit WhitelistConfigSet(_price, _supply, _root);
    }

    function freeConfig(
        uint256 _freeAmount,
        uint256 _maxFree,
        bytes32 _claimListMerkleRoot
    ) external onlyOwner {
        freeAmount = _freeAmount;
        maxFree = _maxFree;
        claimListMerkleRoot = _claimListMerkleRoot;

        emit FreeConfigSet(
            _freeAmount,
            _maxFree,
            _claimListMerkleRoot
        );
    }

    function setURI(string memory __uri) external onlyOwner {
        _uri = __uri;

        emit BaseURISet(__uri);
    }

    function setPublicMintState(bool _publicMintState)
        external
        onlyOwner
    {
        publicMintState = _publicMintState;

        emit PublicMintStateSet(_publicMintState);
    }

    function setWhitelistMintState(bool _whitelistMintState)
        external
        onlyOwner
    {
        whitelistMintState = _whitelistMintState;

        emit WhitelistMintStateSet(_whitelistMintState);
    }

    function setFreeClaimState(bool _freeClaimState)
        external
        onlyOwner
    {
        freeClaimState = _freeClaimState;

        emit FreeClaimStateSet(_freeClaimState);
    }

    /// @dev Burns an arbitrary length array of ids of different owners.
    function burn(uint256[] memory ids) external onlyOwner {
        uint256 i;
        uint256 len = ids.length;
        for (i; i < len; ) {
            liveSupply.decrement();
            _burn(ids[i]);
            unchecked {
                ++i;
            }
        }
        assembly {
            if lt(i, len) {
                mstore(0x00, "LOOP_OVERFLOW")
                revert(0x00, 0x20)
            }
        }
        // Transfer events emited by parent ERC1155 contract
    }

    /// @dev Burns an arbitrary length array of ids owned by a single account.
    function burnBatch(address from, uint256[] memory ids)
        external
        onlyOwner
    {
        uint256 i;
        uint256 len = ids.length;
        for (i; i < len; ) {
            // delId();
            liveSupply.decrement();
            unchecked {
                ++i;
            }
        }
        assembly {
            if lt(i, len) {
                mstore(0x00, "LOOP_OVERFLOW")
                revert(0x00, 0x20)
            }
        }
        _batchBurn(from, ids);
        // Transfer event emited by parent ERC1155 contract
    }

    function mintToCreator(uint256 amount)
        external
        nonReentrant
        onlyOwner
        canMintFree(amount)
    {
        freeSupply += amount;
        uint256 i;
        for (i; i < amount; ) {
            _mint(tx.origin, _nextId(), "");
            unchecked {
                ++i;
            }
        }
        assembly {
            if lt(i, amount) {
                mstore(0x00, "LOOP_OVERFLOW")
                revert(0x00, 0x20)
            }
        }
        // Transfer event emitted in parent ERC1155 contract
    }

    function mintBatchToCreator(uint256[] memory ids)
        external
        nonReentrant
        onlyOwner
    {
        uint256 len = ids.length;
        _canBatchToCreator(len);
        freeSupply += len;
        uint256 i;
        for (i; i < len; ) {
            liveSupply.increment();
            unchecked {
                ++i;
            }
        }
        assembly {
            if lt(i, len) {
                mstore(0x00, "LOOP_OVERFLOW")
                revert(0x00, 0x20)
            }
        }
        _batchMint(tx.origin, ids, "");
        // Transfer event emitted in parent ERC1155 contract
    }

    /// @dev Mints one token per address.
    function giftTokens(address[] calldata addresses)
        external
        nonReentrant
        onlyOwner
        canMintFree(addresses.length)
    {
        uint256 amountGifted = addresses.length;
        freeSupply += amountGifted;
        uint256 i;
        for (i; i < amountGifted; ) {
            _mint(addresses[i], _nextId(), "");
            unchecked {
                ++i;
            }
        }
        assembly {
            if lt(i, amountGifted) {
                mstore(0x00, "LOOP_OVERFLOW")
                revert(0x00, 0x20)
            }
        }
        // transfer event emitted in parent ERC1155 contract
    }

    function withdraw() external onlyOwner {
        SafeTransferLib.safeTransferETH(
            tx.origin,
            address(this).balance
        );
    }

    function withdrawERC20(ERC20 _token) external onlyOwner {
        SafeTransferLib.safeTransfer(
            _token,
            tx.origin,
            _token.balanceOf(address(this))
        );
    }

    ////////////////////////////////////////////////////////////////
    //                           USER FX                          //
    ////////////////////////////////////////////////////////////////

    function mint(uint256 amount)
        external
        payable
        nonReentrant
        publicMintAccess
        hasReachedMax(amount)
        priceCheck(publicPrice, amount)
    {
        uint256 i;
        for (i; i < amount; ) {
            _mint(msg.sender, _nextId(), "");
            unchecked {
                ++i;
            }
        }

        assembly {
            if lt(i, amount) {
                mstore(0x00, "LOOP_OVERFLOW")
                revert(0x00, 0x20)
            }
        }

        // Transfer event emitted in parent ERC1155 contract
    }

    function mintBatch(uint256[] memory ids)
        external
        payable
        nonReentrant
        publicMintAccess
    {
        uint256 len = ids.length;
        _canBatchMint(len);
        uint256 i;
        for (i; i < len; ) {
            liveSupply.increment();
            unchecked {
                ++i;
            }
        }
        assembly {
            if lt(i, len) {
                mstore(0x00, "LOOP_OVERFLOW")
                revert(0x00, 0x20)
            }
        }
        _batchMint(msg.sender, ids, "");
        // Transfer event emitted in parent ERC1155 contract
    }

    function whitelistMint(
        uint8 amount,
        bytes32[] calldata merkleProof
    )
        external
        payable
        nonReentrant
        whitelistMintAccess
        priceCheck(whitelistPrice, amount)
        merkleVerify(merkleProof, whitelistMerkleRoot)
        whitelistMax(amount)
    {
        unchecked {
            whitelistMinted += amount;
        }
        uint256 i;
        for (i; i < amount; ) {
            _mint(msg.sender, _nextId(), "");
            unchecked {
                ++i;
            }
        }
        // assembly overflow check
        assembly {
            if lt(i, amount) {
                mstore(0x00, "LOOP_OVERFLOW")
                revert(0x00, 0x20)
            }
        }
        // Transfer event emitted in parent ERC1155 contract
    }

    function whitelistMintBatch(
        uint256[] memory ids,
        bytes32[] calldata merkleProof
    )
        external
        payable
        nonReentrant
        whitelistMintAccess
        merkleVerify(merkleProof, whitelistMerkleRoot)
    {
        uint256 len = ids.length;
        _canWhitelistBatch(len);
        uint256 i;
        unchecked {
            whitelistMinted += len;
            for (i; i < len; ++i) {
                liveSupply.increment();
            }
        }
        // assembly overflow check
        assembly {
            if lt(i, len) {
                mstore(0x00, "LOOP_OVERFLOW")
                revert(0x00, 0x20)
            }
        }
        _batchMint(msg.sender, ids, "");
        // Transfer event emitted in parent ERC1155 contract
    }

    function claimFree(bytes32[] calldata merkleProof)
        external
        freeClaimAccess
        merkleVerify(merkleProof, claimListMerkleRoot)
        canMintFree(freeAmount)
    {
        if (claimed[msg.sender] == true)
            revert("AlreadyClaimed");

        unchecked {
            claimed[msg.sender] = true;
            freeSupply += freeAmount;
        }

        uint256 j; /* = 0; */
        while (j < freeAmount) {
            _mint(msg.sender, _nextId(), "");
            unchecked {
                ++j;
            }
        }
        // assembly overflow check
        assembly {
            if lt(j, sload(freeAmount.slot)) {
                mstore(0x00, "LOOP_OVERFLOW")
                revert(0x00, 0x20)
            }
        }
        // Transfer event emitted in parent ERC1155 contract
    }

    ////////////////////////////////////////////////////////////////
    //                          HELPER FX                         //
    ////////////////////////////////////////////////////////////////

    function _nextId() private returns (uint256) {
        liveSupply.increment();
        return liveSupply.current();
    }

    function _canBatchToCreator(uint256 _amount)
        private
        view
    {
        if (freeSupply + _amount > maxFree)
            revert("MaxFreeReached");
        if (totalSupply() + _amount > maxSupply)
            revert("MaxMintReached");
    }

    function _canBatchMint(uint256 amount) private view {
        if (
            totalSupply() + amount >
            maxSupply - maxWhitelistSupply - maxFree
        ) revert("MaxMintReached");
        if (publicPrice * amount != msg.value)
            revert("WrongPrice");
    }

    function _canWhitelistBatch(uint256 amount) private view {
        if (whitelistPrice * amount != msg.value)
            revert("WrongPrice");
        if (whitelistMinted + amount > maxWhitelistSupply)
            revert("MaxWhitelistReached");
        if (totalSupply() + amount > maxSupply)
            revert("MaxMintReached");
    }

    ////////////////////////////////////////////////////////////////
    //                           VIEW FX                          //
    ////////////////////////////////////////////////////////////////

    function getURI() external view returns (string memory) {
        return _uri;
    }

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (id > totalSupply()) {
            // revert("NotMintedYet");
            assembly {
                mstore(0x00, 0xbad086ea)
                revert(0x1c, 0x04)
            }
        }

        return
            string(
                abi.encodePacked(
                    _uri,
                    Strings.toString(id),
                    ".json"
                )
            );
    }

    function totalSupply() public view returns (uint256) {
        return liveSupply.current();
    }

    ////////////////////////////////////////////////////////////////
    //                     REQUIRED OVERRIDES                     //
    ////////////////////////////////////////////////////////////////

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(ERC2981)
        returns (bool)
    {
        return
            // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7 ||
            // ERC165 Interface ID for ERC1155
            interfaceId == 0xd9b67a26 ||
            // ERC165 Interface ID for ERC1155MetadataURI
            interfaceId == 0x0e89341c ||
            // ERC165 Interface ID for ERC2981
            interfaceId == 0x2a55205a;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

import { ERC1155LazyEventsAndErrors } from "../Base/interfaces/ERC1155EventAndErrors.sol";
import { ERC1155B as ERC1155, ERC1155TokenReceiver } from "../Base/ERC1155B.sol";
import { ERC2981 } from "../../common/ERC2981.sol";
import { ERC20 } from "../../ERC20.sol";
import { ReentrancyGuard } from "../../../security/ReentrancyGuard.sol";
import { SplitterImpl } from "../../../splitter/SplitterImpl.sol";
import { Counters } from "../../../utils/Counters.sol";
import { Strings } from "../../../utils/Strings.sol";
import { Owned } from "../../../auth/Owned.sol";
import { SafeTransferLib } from "../../../utils/SafeTransferLib.sol";
import { Types } from "../../../../Types.sol";

contract ERC1155Lazy is
    ERC1155,
    ERC2981,
    ERC1155LazyEventsAndErrors,
    ERC1155TokenReceiver,
    Owned,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Types for Types.Voucher;
    using Types for Types.UserBatch;

    ////////////////////////////////////////////////////////////////
    //                           STORAGE                          //
    ////////////////////////////////////////////////////////////////

    uint256 internal immutable _CHAIN_ID_OG;

    bytes32 internal immutable _DOMAIN_SEPARATOR_OG;

    bytes32 private constant _DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 private constant _VOUCHER_TYPEHASH =
        keccak256(
            "Voucher(bytes32 voucherId,address[] users,uint256 amount,uint256 price)"
        );

    bytes32 private constant _USERBATCH_TYPEHASH =
        keccak256(
            "UserBatch(bytes32 voucherId,uint256[] ids,uint256 price,address user)"
        );

    /// @dev The signer address used for lazy minting voucher validation.
    address private signer;

    Counters.Counter private liveSupply;

    string private _uri;

    SplitterImpl public splitter;

    mapping(bytes32 => bool) public usedVouchers;

    ////////////////////////////////////////////////////////////////
    //                         CONSTRUCTOR                        //
    ////////////////////////////////////////////////////////////////

    constructor(
        string memory __uri,
        SplitterImpl _splitter,
        uint96 _fraction,
        address _router,
        address _signer
    ) Owned(_router) {
        _CHAIN_ID_OG = block.chainid;
        _DOMAIN_SEPARATOR_OG = computeDS();
        setSigner(_signer);
        _uri = __uri;
        splitter = _splitter;

        _royaltyFee = _fraction;
        _royaltyRecipient = payable(splitter);

        emit RoyaltyFeeSet(_royaltyFee);
        emit RoyaltyRecipientSet(_royaltyRecipient);
    }

    ////////////////////////////////////////////////////////////////
    //                        LAZY MINT                           //
    ////////////////////////////////////////////////////////////////

    /// @notice This method enables offchain ledgering of tokens to establish onchain provenance as
    /// long as a trusted signer can be retrieved as the validator of such contract state update.
    /// @dev Neither `totalSupply` nor `price` accountings for any of the possible mint
    /// types(e.g., public, free/gifted, toCreator) need to be recorded by the contract;
    /// since its condition checking control flow takes place in offchain databases.
    function lazyMint(
        Types.Voucher calldata voucher,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        address _signer = _verifyVoucher(voucher, v, r, s);
        _voucherCheck(_signer, voucher);
        usedVouchers[voucher.voucherId] = true;
        uint256 len = voucher.users.length;
        uint256 i;
        for (i; i < len; ) {
            _userMint(voucher.amount, voucher.users[i]);
            // can't overflow due to have been previously validated by signer
            unchecked {
                ++i;
            }
        }
    }

    /// @notice `_batchMint` version of `lazyMint`.
    function lazyMintBatch(
        Types.UserBatch calldata userBatch,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        address _signer = _verifyBatch(userBatch, v, r, s);
        _batchCheck(_signer, userBatch);
        usedVouchers[userBatch.voucherId] = true;

        uint256 len = userBatch.ids.length;
        uint256 i;
        for (i; i < len; ) {
            liveSupply.increment();
            // can't overflow due to have been previously validated by signer
            unchecked {
                ++i;
            }
        }
        _batchMint(userBatch.user, userBatch.ids, "");
    }

    ////////////////////////////////////////////////////////////////
    //                         OWNER FX                           //
    ////////////////////////////////////////////////////////////////

    /// @dev Can only be updated by the Router's owner.
    function setSigner(address _signer) public onlyOwner {
        signer = _signer;

        emit SignerUpdated(_signer);
    }

    /// @notice Changes the `_uri` value in storage.
    /// @dev Can only be accessed by the collection creator.
    function setURI(string memory __uri) external onlyOwner {
        _uri = __uri;

        emit BaseURISet(__uri);
    }

    /// @dev Burns an arbitrary length array of ids of different owners.
    function burn(uint256[] memory ids) external onlyOwner {
        uint256 i;
        uint256 len = ids.length;
        // for (uint256 i = 0; i < ids.length; i++) {
        for (i; i < len; ) {
            // delId();
            liveSupply.decrement();
            _burn(ids[i]);
            unchecked {
                ++i;
            }
        }
        assembly {
            if lt(i, len) {
                mstore(0x00, "LOOP_OVERFLOW")
                revert(0x00, 0x20)
            }
        }
        // Transfer events emited by parent ERC1155 contract
    }

    /// @dev Burns an arbitrary length array of ids owned by a single account.
    function burnBatch(address from, uint256[] memory ids)
        external
        onlyOwner
    {
        uint256 i;
        uint256 len = ids.length;
        for (i; i < len; ) {
            // delId();
            liveSupply.decrement();
            unchecked {
                ++i;
            }
        }
        assembly {
            if lt(i, len) {
                mstore(0x00, "LOOP_OVERFLOW")
                revert(0x00, 0x20)
            }
        }
        _batchBurn(from, ids);
        // Transfer event emited by parent ERC1155 contract
    }

    function withdraw() external onlyOwner {
        SafeTransferLib.safeTransferETH(
            tx.origin,
            address(this).balance
        );
    }

    function withdrawERC20(ERC20 _token) external onlyOwner {
        SafeTransferLib.safeTransfer(
            _token,
            tx.origin,
            _token.balanceOf(address(this))
        );
    }

    ////////////////////////////////////////////////////////////////
    //                          HELPER FX                         //
    ////////////////////////////////////////////////////////////////

    function _nextId() private returns (uint256) {
        liveSupply.increment();
        return liveSupply.current();
    }

    /// @dev Checks for signer validity and if total balance provided in the message matches to voucher's record.
    function _voucherCheck(
        address _signer,
        Types.Voucher calldata voucher
    ) private view {
        if (_signer != signer) revert InvalidSigner();
        if (usedVouchers[voucher.voucherId] == true)
            revert UsedVoucher();
        if (
            msg.value !=
            (voucher.price *
                voucher.amount *
                voucher.users.length)
        ) revert WrongPrice();
    }

    /// @dev Checks for signer validity and if total balance provided in the message matches to voucher's record.
    function _batchCheck(
        address _signer,
        Types.UserBatch calldata userBatch
    ) private view {
        if (_signer != signer) revert InvalidSigner();
        if (usedVouchers[userBatch.voucherId] == true)
            revert UsedVoucher();
        if (
            msg.value !=
            (userBatch.price * userBatch.ids.length)
        ) revert WrongPrice();
    }

    function _verifyVoucher(
        Types.Voucher calldata _voucher,
        // bytes calldata _sig
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address recovered) {
        unchecked {
            recovered = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                _VOUCHER_TYPEHASH,
                                _voucher.voucherId,
                                keccak256(
                                    abi.encodePacked(
                                        _voucher.users
                                    )
                                ),
                                _voucher.amount,
                                _voucher.price
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );
        }
    }

    function _verifyBatch(
        Types.UserBatch calldata _userBatch,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address recovered) {
        unchecked {
            recovered = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                _USERBATCH_TYPEHASH,
                                _userBatch.voucherId,
                                keccak256(
                                    abi.encodePacked(
                                        _userBatch.ids
                                    )
                                ),
                                _userBatch.price,
                                _userBatch.user
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );
        }
    }

    function computeDS() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _DOMAIN_TYPEHASH,
                    keccak256(bytes("MAD")),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    function _userMint(uint256 _amount, address _key)
        internal
    {
        uint256 j;
        while (j < _amount) {
            _mint(_key, _nextId(), "");
            // can't overflow due to have been previously validated by signer
            unchecked {
                ++j;
            }
        }
    }

    ////////////////////////////////////////////////////////////////
    //                           VIEW FX                          //
    ////////////////////////////////////////////////////////////////

    function getURI() external view returns (string memory) {
        return _uri;
    }

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (id > totalSupply()) revert NotMintedYet();
        return
            string(
                abi.encodePacked(
                    _uri,
                    Strings.toString(id),
                    ".json"
                )
            );
    }

    function totalSupply() public view returns (uint256) {
        return liveSupply.current();
    }

    function DOMAIN_SEPARATOR()
        public
        view
        returns (bytes32)
    {
        return
            block.chainid == _CHAIN_ID_OG
                ? _DOMAIN_SEPARATOR_OG
                : computeDS();
    }

    ////////////////////////////////////////////////////////////////
    //                     REQUIRED OVERRIDES                     //
    ////////////////////////////////////////////////////////////////

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(ERC2981)
        returns (bool)
    {
        return
            // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7 ||
            // ERC165 Interface ID for ERC1155
            interfaceId == 0xd9b67a26 ||
            // ERC165 Interface ID for ERC1155MetadataURI
            interfaceId == 0x0e89341c ||
            // ERC165 Interface ID for ERC2981
            interfaceId == 0x2a55205a;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

interface ERC1155MinimalEvents {
    ////////////////////////////////////////////////////////////////
    //                           EVENTS                           //
    ////////////////////////////////////////////////////////////////

    event RoyaltyRecipientSet(address indexed newRecipient);
    event RoyaltyFeeSet(uint256 indexed newRoyaltyFee);
    event PublicMintStateSet(bool indexed newPublicMintState);
}

interface ERC1155BasicEvents {
    ////////////////////////////////////////////////////////////////
    //                           EVENTS                           //
    ////////////////////////////////////////////////////////////////

    event BaseURISet(string indexed newBaseURI);
    event RoyaltyRecipientSet(address indexed newRecipient);
    event RoyaltyFeeSet(uint256 indexed newRoyaltyFee);
    event PublicMintStateSet(bool indexed newPublicState);

    ////////////////////////////////////////////////////////////////
    //                           ERRORS                           //
    ////////////////////////////////////////////////////////////////

    /// @dev 0xbad086ea
    error NotMintedYet();
    // /// @dev 0x2d0a3f8e
    // error PublicMintClosed();
    // /// @dev 0xd05cb609
    // error MaxSupplyReached();
    // /// @dev 0xf7760f25
    // error WrongPrice();
}

interface ERC1155WhitelistEvents {
    ////////////////////////////////////////////////////////////////
    //                           EVENTS                           //
    ////////////////////////////////////////////////////////////////

    event BaseURISet(string indexed newBaseURI);
    event RoyaltyRecipientSet(address indexed newRecipient);
    event RoyaltyFeeSet(uint256 indexed newRoyaltyFee);
    event PublicMintStateSet(bool indexed newPublicState);
    event FreeClaimStateSet(bool indexed freeClaimState);
    event WhitelistMintStateSet(
        bool indexed newWhitelistState
    );
    event WhitelistConfigSet(
        uint256 indexed newWhitelistPrice,
        uint256 indexed newMaxWhitelistSupply,
        bytes32 indexed newMerkleRoot
    );
    event FreeConfigSet(
        uint256 newFreeAmount,
        uint256 indexed newMaxFree,
        bytes32 indexed newMerkleRoot
    );

    ////////////////////////////////////////////////////////////////
    //                           ERRORS                           //
    ////////////////////////////////////////////////////////////////

    /// @dev 0xbad086ea
    error NotMintedYet();
    // /// @dev 0x2d0a3f8e
    // error PublicMintClosed();
    // /// @dev 0x700a6c1f
    // error WhitelistMintClosed();
    // /// @dev 0xf44170cb
    // error FreeClaimClosed();
    // /// @dev 0xfc3fc71f
    // error MaxMintReached();
    // /// @dev 0xf90c1bdb
    // error MaxFreeReached();
    // /// @dev 0xa554e6e1
    // error MaxWhitelistReached();
    // /// @dev 0x646cf558
    // error AlreadyClaimed();
    // /// @dev 0xf7760f25
    // error WrongPrice();
    // /// @dev 0x3b8474be
    // error AddressDenied();
}

interface ERC1155LazyEventsAndErrors {
    ////////////////////////////////////////////////////////////////
    //                           EVENTS                           //
    ////////////////////////////////////////////////////////////////

    event SignerUpdated(address indexed newSigner);
    event BaseURISet(string indexed newBaseURI);
    event RoyaltyRecipientSet(address indexed newRecipient);
    event RoyaltyFeeSet(uint256 indexed newRoyaltyFee);

    ////////////////////////////////////////////////////////////////
    //                           ERRORS                           //
    ////////////////////////////////////////////////////////////////

    /// @dev 0x815e1d64
    error InvalidSigner();
    /// @dev 0xe647f413
    error UsedVoucher();
    /// @dev 0xf7760f25
    error WrongPrice();
    /// @dev 0xbad086ea
    error NotMintedYet();
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

// import { ERC1155TokenReceiver } from "./ERC1155.sol";

/// @notice Minimalist and gas efficient ERC1155 implementation optimized for single supply ids.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155B.sol)
abstract contract ERC1155B {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(address => bool))
        public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                            ERC1155B STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public ownerOf;

    function balanceOf(address owner, uint256 id)
        public
        view
        virtual
        returns (uint256 bal)
    {
        address idOwner = ownerOf[id];

        assembly {
            // We avoid branching by using assembly to take
            // the bool output of eq() and use it as a uint.
            bal := eq(idOwner, owner)
        }
    }

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id)
        public
        view
        virtual
        returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(
            msg.sender == from ||
                isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        require(from == ownerOf[id], "WRONG_FROM"); // Can only transfer from the owner.

        // Can only transfer 1 with ERC1155B.
        require(amount == 1, "INVALID_AMOUNT");

        ownerOf[id] = to;

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) ==
                    ERC1155TokenReceiver
                        .onERC1155Received
                        .selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(
            ids.length == amounts.length,
            "LENGTH_MISMATCH"
        );

        require(
            msg.sender == from ||
                isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < ids.length; i++) {
                id = ids[i];
                amount = amounts[i];

                // Can only transfer from the owner.
                require(from == ownerOf[id], "WRONG_FROM");

                // Can only transfer 1 with ERC1155B.
                require(amount == 1, "INVALID_AMOUNT");

                ownerOf[id] = to;
            }
        }

        emit TransferBatch(
            msg.sender,
            from,
            to,
            ids,
            amounts
        );

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to)
                    .onERC1155BatchReceived(
                        msg.sender,
                        from,
                        ids,
                        amounts,
                        data
                    ) ==
                    ERC1155TokenReceiver
                        .onERC1155BatchReceived
                        .selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    )
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(
            owners.length == ids.length,
            "LENGTH_MISMATCH"
        );

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf(owners[i], ids[i]);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        // Minting twice would effectively be a force transfer.
        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        ownerOf[id] = to;

        emit TransferSingle(
            msg.sender,
            address(0),
            to,
            id,
            1
        );

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    address(0),
                    id,
                    1,
                    data
                ) ==
                    ERC1155TokenReceiver
                        .onERC1155Received
                        .selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        // Generate an amounts array locally to use in the event below.
        uint256[] memory amounts = new uint256[](idsLength);

        uint256 id; // Storing outside the loop saves ~7 gas per iteration.

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < idsLength; ++i) {
                id = ids[i];

                // Minting twice would effectively be a force transfer.
                require(
                    ownerOf[id] == address(0),
                    "ALREADY_MINTED"
                );

                ownerOf[id] = to;

                amounts[i] = 1;
            }
        }

        emit TransferBatch(
            msg.sender,
            address(0),
            to,
            ids,
            amounts
        );

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to)
                    .onERC1155BatchReceived(
                        msg.sender,
                        address(0),
                        ids,
                        amounts,
                        data
                    ) ==
                    ERC1155TokenReceiver
                        .onERC1155BatchReceived
                        .selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function _batchBurn(address from, uint256[] memory ids)
        internal
        virtual
    {
        // Burning unminted tokens makes no sense.
        require(from != address(0), "INVALID_FROM");

        uint256 idsLength = ids.length; // Saves MLOADs.

        // Generate an amounts array locally to use in the event below.
        uint256[] memory amounts = new uint256[](idsLength);

        uint256 id; // Storing outside the loop saves ~7 gas per iteration.

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < idsLength; ++i) {
                id = ids[i];

                require(ownerOf[id] == from, "WRONG_FROM");

                ownerOf[id] = address(0);

                amounts[i] = 1;
            }
        }

        emit TransferBatch(
            msg.sender,
            from,
            address(0),
            ids,
            amounts
        );
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        ownerOf[id] = address(0);

        emit TransferSingle(
            msg.sender,
            owner,
            address(0),
            id,
            1
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return
            ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return
            ERC1155TokenReceiver
                .onERC1155BatchReceived
                .selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

//// @title Minimal ERC2981 (NFT Royalty Standard) implementation.
//// @author Modified from exp.table (https://etherscan.io/address/0x0faed6ddef3773f3ee5828383aaeeaca2a94564a#code)

abstract contract ERC2981 {
    /// @dev one global fee for all royalties.
    uint256 internal _royaltyFee;
    /// @dev one global recipient for all royalties.
    address internal _royaltyRecipient;

    // solhint-disable-line no-unused-vars
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _royaltyRecipient;
        royaltyAmount = (salePrice * _royaltyFee) / 10000;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x2a55205a; // ERC165 Interface ID for ERC2981
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

//// @title Counters
//// @author Matt Condon (@shrugs)
//// @author Modified from OpenZeppelin Contracts
//// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol)
//// @notice Provides counters that can only be incremented, decremented or reset.
//// @dev Include with `using Counters for Counters.Counter;`
library Counters {
    struct Counter {
        //// @dev Interactions must be restricted to the library's function.
        uint256 _value; // default: 0
    }

    function current(Counter storage counter)
        internal
        view
        returns (uint256)
    {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value++; /* += 1; */
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "DECREMENT_OVERFLOW");
        unchecked {
            counter._value--; /* = value - 1; */
        }
    }

    function reset(Counter storage counter) internal {
        unchecked {
            counter._value = 0x00;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/// @title Uint256 to string conversion library.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibString.sol)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/LibString.sol)

pragma solidity 0.8.4;

library Strings {
    /// @dev Converts a `uint256` to its ASCII `string` decimal representation.
    function toString(uint256 value)
        internal
        pure
        returns (string memory str)
    {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            str := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                str := sub(str, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(str, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                str := sub(str, 1)
                mstore8(str, add(48, mod(temp, 10)))
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

/// @notice Gas optimized verification of proof of inclusion for a leaf in a Merkle tree.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/MerkleProof.sol)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/MerkleProof.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol)
library MerkleProof {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        assembly {
            // Left shift by 5 is equivalent to multiplying by 0x20.
            let end := add(proof.offset, shl(5, proof.length))

            // Iterate over proof elements to compute root hash.
            for {
                // Initialize `offset` to the offset of `proof` in the calldata.
                let offset := proof.offset
            } iszero(eq(offset, end)) {
                offset := add(offset, 0x20)
            } {
                // Slot of `leaf` in scratch space.
                // If the condition is true: 0x20, otherwise: 0x00.
                let scratch := shl(
                    5,
                    gt(leaf, calldataload(offset))
                )

                // Store elements to hash contiguously in scratch space.
                // Scratch space is 64 bytes (0x00 - 0x3f) and both elements are 32 bytes.
                mstore(scratch, leaf)
                mstore(
                    xor(scratch, 0x20),
                    calldataload(offset)
                )
                // Reuse `leaf` to store the hash to reduce stack operations.
                leaf := keccak256(0x00, 0x40)
            }
            isValid := eq(leaf, root)
        }
    }

    function verifyMultiProof(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32[] calldata leafs,
        bool[] calldata flags
    ) internal pure returns (bool isValid) {
        // Rebuilds the root by consuming and producing values on a queue.
        // The queue starts with the `leafs` array, and goes into a `hashes` array.
        // After the process, the last element on the queue is verified
        // to be equal to the `root`.
        //
        // The `flags` array denotes whether the sibling
        // should be popped from the queue (`flag == true`), or
        // should be popped from the `proof` (`flag == false`).
        assembly {
            // If the number of flags is correct.
            if eq(
                add(leafs.length, proof.length),
                add(flags.length, 1)
            ) {
                // Left shift by 5 is equivalent to multiplying by 0x20.
                // Compute the end calldata offset of `leafs`.
                let leafsEnd := add(
                    leafs.offset,
                    shl(5, leafs.length)
                )
                // These are the calldata offsets.
                let leafsOffset := leafs.offset
                let flagsOffset := flags.offset
                let proofOffset := proof.offset

                // We can use the free memory space for the queue.
                // We don't need to allocate, since the queue is temporary.
                let hashesFront := mload(0x40)
                let hashesBack := hashesFront
                // This is the end of the memory for the queue.
                let end := add(
                    hashesBack,
                    shl(5, flags.length)
                )

                // For the case where `proof.length + leafs.length == 1`.
                if iszero(flags.length) {
                    // If `proof.length` is zero, `leafs.length` is 1.
                    if iszero(proof.length) {
                        // Push the only leaf onto the queue.
                        mstore(
                            hashesBack,
                            calldataload(leafsOffset)
                        )
                    }
                    // If `leafs.length` is zero, `proof.length` is 1.
                    if iszero(leafs.length) {
                        // Push the only proof onto the queue.
                        mstore(
                            hashesBack,
                            calldataload(proofOffset)
                        )
                    }
                    // Advance `hashesBack` to push onto the queue.
                    hashesBack := add(hashesBack, 0x20)
                    // Advance `end` too so that we can skip the iteration.
                    end := add(end, 0x20)
                }

                // prettier-ignore
                for {} iszero(eq(hashesBack, end)) {} {
                    let a := 0

                    // Pops a value from the queue into `a`.
                    switch lt(leafsOffset, leafsEnd)
                    case 0 {
                        // Pop from `hashes` if there are no more leafs.
                        a := mload(hashesFront)
                        hashesFront := add(hashesFront, 0x20)
                    }
                    default {
                        // Otherwise, pop from `leafs`.
                        a := calldataload(leafsOffset)
                        leafsOffset := add(leafsOffset, 0x20)
                    }

                    let b := 0
                    // If the flag is false, load the next proof,
                    // else, pops from the queue.
                    switch calldataload(flagsOffset)
                    case 0 {
                        // Loads the next proof.
                        b := calldataload(proofOffset)
                        proofOffset := add(proofOffset, 0x20)
                    }
                    default {
                        // Pops a value from the queue into `a`.
                        switch lt(leafsOffset, leafsEnd)
                        case 0 {
                            // Pop from `hashes` if there are no more leafs.
                            b := mload(hashesFront)
                            hashesFront := add(hashesFront, 0x20)
                        }
                        default {
                            // Otherwise, pop from `leafs`.
                            b := calldataload(leafsOffset)
                            leafsOffset := add(leafsOffset, 0x20)
                        }
                    }
                    // Advance to the next flag offset.
                    flagsOffset := add(flagsOffset, 0x20)

                    // Slot of `a` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(a, b))
                    // Hash the scratch space and push the result onto the queue.
                    mstore(scratch, a)
                    mstore(xor(scratch, 0x20), b)
                    mstore(hashesBack, keccak256(0x00, 0x40))
                    hashesBack := add(hashesBack, 0x20)
                }
                // Checks if the last value in the queue is same as the root.
                isValid := eq(
                    mload(sub(hashesBack, 0x20)),
                    root
                )
            }
        }
    }
}