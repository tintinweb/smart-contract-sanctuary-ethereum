// SPDX-License-Identifier: AGPL-3.0-only

/* 
DISCLAIMER: 
This contract hasn't been audited yet. Most likely contains unexpected bugs. 
Don't trust your funds to be held by this code before the final thoroughly tested and audited version release.
*/

pragma solidity 0.8.4;

import { MAD } from "./MAD.sol";
import { RouterEvents, FactoryVerifier } from "./EventsAndErrors.sol";

import { ERC20 } from "./lib/tokens/ERC20.sol";
import { ERC721Minimal } from "./lib/tokens/ERC721/Impl/ERC721Minimal.sol";
import { ERC721Basic } from "./lib/tokens/ERC721/Impl/ERC721Basic.sol";
import { ERC721Whitelist } from "./lib/tokens/ERC721/Impl/ERC721Whitelist.sol";
import { ERC721Lazy } from "./lib/tokens/ERC721/Impl/ERC721Lazy.sol";

import { ReentrancyGuard } from "./lib/security/ReentrancyGuard.sol";
import { Pausable } from "./lib/security/Pausable.sol";
import { Owned } from "./lib/auth/Owned.sol";

contract MADRouter721 is
    MAD,
    RouterEvents,
    Owned(msg.sender),
    Pausable,
    ReentrancyGuard
{
    /// @dev Function Sighash := 0x06fdde03
    function name()
        public
        pure
        override(MAD)
        returns (string memory)
    {
        assembly {
            mstore(0x20, 0x20)
            mstore(0x46, 0x6726F75746572)
            return(0x20, 0x60)
        }
    }

    ////////////////////////////////////////////////////////////////
    //                           STORAGE                          //
    ////////////////////////////////////////////////////////////////

    FactoryVerifier public MADFactory721;

    ////////////////////////////////////////////////////////////////
    //                         CONSTRUCTOR                        //
    ////////////////////////////////////////////////////////////////

    constructor(FactoryVerifier _factory) {
        MADFactory721 = _factory;
    }

    ////////////////////////////////////////////////////////////////
    //                       CREATOR SETTINGS                     //
    ////////////////////////////////////////////////////////////////

    /// @notice Collection `baseURI` setter.
    /// @dev Only available for Basic, Whitelist and Lazy token types.
    /// @dev Function Sighash := 0x4328bd00
    /// @dev Events logged by each tokens' `BaseURISet` functions.
    function setBase(address _token, string memory _baseURI)
        external
        nonReentrant
        whenNotPaused
    {
        (bytes32 _colID, uint8 _tokenType) = _tokenRender(
            _token
        );

        if (_tokenType == 1) {
            ERC721Basic(_token).setBaseURI(_baseURI);
            emit BaseURI(_colID, _baseURI);
        } else if (_tokenType == 2) {
            ERC721Whitelist(_token).setBaseURI(_baseURI);
            emit BaseURI(_colID, _baseURI);
        } else if (_tokenType > 2) {
            ERC721Lazy(_token).setBaseURI(_baseURI);
            emit BaseURI(_colID, _baseURI);
        } else {
            revert("INVALID_TYPE");
        }
    }

    /// @notice `ERC721Whitelist` whitelist config setter.
    /// @dev Function Sighash := 0xa123c38d
    /// @dev Event emitted by `ERC721Whitelist`
    /// token implementation contracts.
    function whitelistSettings(
        address _token,
        uint256 _price,
        uint256 _supply,
        bytes32 _root
    ) external nonReentrant whenNotPaused {
        (, uint8 _tokenType) = _tokenRender(_token);
        if (_tokenType == 2) {
            ERC721Whitelist(_token).whitelistConfig(
                _price,
                _supply,
                _root
            );
        } else revert("INVALID_TYPE");
    }

    /// @notice `ERC721Whitelist` free claim config setter.
    /// @dev Function Sighash := 0xcab2e41f
    /// @dev Event emitted by `ERC721Whitelist`
    /// token implementation contracts.
    function freeSettings(
        address _token,
        uint256 _freeAmount,
        uint256 _maxFree,
        bytes32 _claimRoot
    ) external nonReentrant whenNotPaused {
        (, uint8 _tokenType) = _tokenRender(_token);
        if (_tokenType == 2) {
            ERC721Whitelist(_token).freeConfig(
                _freeAmount,
                _maxFree,
                _claimRoot
            );
        } else revert("INVALID_TYPE");
    }

    /// @notice `ERC721Minimal` creator mint function handler.
    /// @dev Function Sighash := 0x42a42752
    function minimalSafeMint(address _token, address _to)
        external
        nonReentrant
        whenNotPaused
    {
        (, uint8 _tokenType) = _tokenRender(_token);
        if (_tokenType != 0) revert("INVALID_TYPE");
        ERC721Minimal(_token).safeMint(_to);
    }

    /// @notice Global token burn controller/single pusher for all token types.
    /// @dev Function Sighash := 0xba36b92d
    /// @param _ids The token IDs of each token to be burnt;
    /// should be left empty for the `ERC721Minimal` type.
    /// @dev Transfer events emitted by nft implementation contracts.
    function burn(address _token, uint256[] memory _ids)
        external
        nonReentrant
        whenNotPaused
    {
        (, uint8 _tokenType) = _tokenRender(_token);

        _tokenType < 1
            ? ERC721Minimal(_token).burn()
            : _tokenType == 1
            ? ERC721Basic(_token).burn(_ids)
            : _tokenType == 2
            ? ERC721Whitelist(_token).burn(_ids)
            : _tokenType > 2
            ? ERC721Lazy(_token).burn(_ids)
            : revert("INVALID_TYPE");
    }

    /// @notice Global MintState setter/controller with switch
    /// cases/control flow handling conditioned by
    /// both `_stateType` and `_tokenType`.
    /// @dev Function Sighash := 0xab9acd57
    /// @dev Events logged by each tokens' `setState` functions.
    /// @param _stateType Values legend:
    /// 0 := PublicMintState (minimal, basic, whitelist);
    /// 1 := WhitelistMintState (whitelist);
    /// 2 := FreeClaimState (whitelist).
    function setMintState(
        address _token,
        bool _state,
        uint8 _stateType
    ) external nonReentrant whenNotPaused {
        require(_stateType < 3, "INVALID_TYPE");
        (bytes32 _colID, uint8 _tokenType) = _tokenRender(
            _token
        );

        if (_stateType < 1) {
            _stateType0(_tokenType, _token, _state);
            emit PublicMintState(_colID, _tokenType, _state);
        } else if (_stateType == 1) {
            _stateType1(_tokenType, _token, _state);
            emit WhitelistMintState(
                _colID,
                _tokenType,
                _state
            );
        } else if (_stateType == 2) {
            _stateType2(_tokenType, _token, _state);
            emit FreeClaimState(_colID, _tokenType, _state);
        }
    }

    /// @notice `ERC721Whitelist` mint to creator function handler.
    /// @dev Function Sighash := 0x182ee485
    function creatorMint(address _token, uint256 _amount)
        external
        nonReentrant
        whenNotPaused
    {
        (, uint8 _tokenType) = _tokenRender(_token);
        if (_tokenType == 2) {
            ERC721Whitelist(_token).mintToCreator(_amount);
        } else revert("INVALID_TYPE");
    }

    /// @notice `ERC721Whitelist` gift tokens function handler.
    /// @dev Function Sighash := 0x67b5a642
    function gift(
        address _token,
        address[] calldata _addresses
    ) external nonReentrant whenNotPaused {
        (, uint8 _tokenType) = _tokenRender(_token);
        if (_tokenType == 2) {
            ERC721Whitelist(_token).giftTokens(_addresses);
        } else revert("INVALID_TYPE");
    }

    ////////////////////////////////////////////////////////////////
    //                       CREATOR WITHDRAW                     //
    ////////////////////////////////////////////////////////////////

    /// @notice Withdraw both ERC20 and ONE from ERC721 contract's balance.
    /// @dev Function Sighash := 0x9547ed5d
    /// @dev Leave `_token` param empty for withdrawing eth only.
    /// @dev No withdraw min needs to be passed as params, since
    /// all balance from the token's contract is emptied.
    function withdraw(address _token, ERC20 _erc20)
        external
        nonReentrant
        whenNotPaused
    {
        (bytes32 _colID, uint8 _tokenType) = _tokenRender(
            _token
        );

        if (_tokenType < 1) {
            address(_erc20) != address(0) &&
                _erc20.balanceOf(_token) != 0
                ? ERC721Minimal(_token).withdrawERC20(_erc20)
                : _token.balance != 0
                ? ERC721Minimal(_token).withdraw()
                : revert("NO_FUNDS");

            emit TokenFundsWithdrawn(
                _colID,
                _tokenType,
                msg.sender
            );
        }

        if (_tokenType == 1) {
            address(_erc20) != address(0) &&
                _erc20.balanceOf(_token) != 0
                ? ERC721Basic(_token).withdrawERC20(_erc20)
                : _token.balance != 0
                ? ERC721Basic(_token).withdraw()
                : revert("NO_FUNDS");

            emit TokenFundsWithdrawn(
                _colID,
                _tokenType,
                msg.sender
            );
        }

        if (_tokenType == 2) {
            address(_erc20) != address(0) &&
                _erc20.balanceOf(_token) != 0
                ? ERC721Whitelist(_token).withdrawERC20(
                    _erc20
                )
                : _token.balance != 0
                ? ERC721Whitelist(_token).withdraw()
                : revert("NO_FUNDS");

            emit TokenFundsWithdrawn(
                _colID,
                _tokenType,
                msg.sender
            );
        }

        if (_tokenType > 2) {
            address(_erc20) != address(0) &&
                _erc20.balanceOf(_token) != 0
                ? ERC721Lazy(_token).withdrawERC20(_erc20)
                : _token.balance != 0
                ? ERC721Lazy(_token).withdraw()
                : revert("NO_FUNDS");

            emit TokenFundsWithdrawn(
                _colID,
                _tokenType,
                msg.sender
            );
        }
    }

    ////////////////////////////////////////////////////////////////
    //                         HELPERS                            //
    ////////////////////////////////////////////////////////////////

    /// @notice Private auth-check mechanism that verifies `MADFactory` storage.
    /// @dev Retrieves both `colID` (bytes32) and collection type (uint8)
    /// for valid token and approved user.
    /// @dev Function Sighash := 0xdbf62b2e
    function _tokenRender(address _token)
        private
        view
        returns (bytes32 colID, uint8 tokenType)
    {
        colID = MADFactory721.getColID(_token);
        MADFactory721.creatorCheck(colID);
        tokenType = MADFactory721.typeChecker(colID);
    }

    /// @notice Internal function helper for resolving `PublicMintState` path.
    /// @dev Function Sighash := 0xde21620a
    function _stateType0(
        uint8 _tokenType,
        address _token,
        bool _state
    ) internal {
        if (_tokenType < 1) {
            ERC721Minimal(_token).setPublicMintState(_state);
        } else if (_tokenType == 1) {
            ERC721Basic(_token).setPublicMintState(_state);
        } else if (_tokenType == 2) {
            ERC721Whitelist(_token).setPublicMintState(
                _state
            );
        } else revert("INVALID_TYPE");
    }

    /// @notice Internal function helper for resolving `WhitelistMintState` path.
    /// @dev Function Sighash := 0x90036d9e
    function _stateType1(
        uint8 _tokenType,
        address _token,
        bool _state
    ) internal {
        if (_tokenType == 2) {
            ERC721Whitelist(_token).setWhitelistMintState(
                _state
            );
        } else revert("INVALID_TYPE");
    }

    /// @notice Internal function helper for resolving `FreeClaimState` path.
    /// @dev Function Sighash := 0xff454f63
    function _stateType2(
        uint8 _tokenType,
        address _token,
        bool _state
    ) internal {
        if (_tokenType == 2) {
            ERC721Whitelist(_token).setFreeClaimState(_state);
        } else revert("INVALID_TYPE");
    }

    ////////////////////////////////////////////////////////////////
    //                         OWNER FX                           //
    ////////////////////////////////////////////////////////////////

    /// @notice Change the address used for lazy minting voucher validation.
    /// @dev Function Sighash := 0x17f9fad1
    /// @dev Event emitted by token contract.
    function setSigner(address _token, address _signer)
        external
        onlyOwner
    {
        ERC721Lazy(_token).setSigner(_signer);
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

import { ERC721MinimalEvents } from "../Base/interfaces/ERC721EventAndErrors.sol";
import { ERC721, ERC721TokenReceiver } from "../Base/ERC721.sol";
import { ERC2981 } from "../../common/ERC2981.sol";
import { ERC20 } from "../../ERC20.sol";
import { SplitterImpl } from "../../../splitter/SplitterImpl.sol";

// import { ReentrancyGuard } from "../../../security/ReentrancyGuard.sol";
import { Owned } from "../../../auth/Owned.sol";
import { SafeTransferLib } from "../../../utils/SafeTransferLib.sol";

contract ERC721Minimal is
    ERC721,
    ERC2981,
    ERC721TokenReceiver,
    ERC721MinimalEvents,
    Owned
    // ReentrancyGuard
{
    ////////////////////////////////////////////////////////////////
    //                           STORAGE                          //
    ////////////////////////////////////////////////////////////////

    SplitterImpl public splitter;
    uint256 public price;
    string private _tokenURI;
    /// @dev  default := false
    bool private minted;
    /// @dev  default := false
    bool public publicMintState;

    ////////////////////////////////////////////////////////////////
    //                         CONSTRUCTOR                        //
    ////////////////////////////////////////////////////////////////

    /// @dev The fee of royalties denominator is 10000 in BPS.
    constructor(
        string memory _name,
        string memory _symbol,
        string memory __tokenURI,
        uint256 _price,
        SplitterImpl _splitter,
        uint96 _fraction,
        address _router
    ) ERC721(_name, _symbol) Owned(_router) {
        _tokenURI = __tokenURI;
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
        _safeMint(to, 1);
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

        emit PublicMintStateSet(_publicMintState);
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
        _safeMint(msg.sender, 1);
    }

    ////////////////////////////////////////////////////////////////
    //                           VIEW FX                          //
    ////////////////////////////////////////////////////////////////

    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(id == 1, "INVALID_ID");
        if (!minted) revert("NOT_MINTED");
        return _tokenURI;
    }

    ////////////////////////////////////////////////////////////////
    //                      REQUIRED OVERRIDES                    //
    ////////////////////////////////////////////////////////////////

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return
            // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7 ||
            // ERC165 Interface ID for ERC721
            interfaceId == 0x80ac58cd ||
            // ERC165 Interface ID for ERC721Metadata
            interfaceId == 0x5b5e139f ||
            // ERC165 Interface ID for ERC2981
            interfaceId == 0x2a55205a;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

import { ERC721BasicEvents } from "../Base/interfaces/ERC721EventAndErrors.sol";
import { ERC721, ERC721TokenReceiver } from "../Base/ERC721.sol";
import { ERC2981 } from "../../common/ERC2981.sol";
import { ERC20 } from "../../ERC20.sol";

import { Owned } from "../../../auth/Owned.sol";
import { ReentrancyGuard } from "../../../security/ReentrancyGuard.sol";
import { SplitterImpl } from "../../../splitter/SplitterImpl.sol";
import { Counters } from "../../../utils/Counters.sol";
import { Strings } from "../../../utils/Strings.sol";
import { SafeTransferLib } from "../../../utils/SafeTransferLib.sol";

contract ERC721Basic is
    ERC721,
    ERC2981,
    ERC721BasicEvents,
    ERC721TokenReceiver,
    Owned,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    ////////////////////////////////////////////////////////////////
    //                           STORAGE                          //
    ////////////////////////////////////////////////////////////////

    Counters.Counter private liveSupply;

    string private baseURI;
    uint256 public price;
    // capped max supply
    uint256 public maxSupply;

    bool public publicMintState; // default := false
    SplitterImpl public splitter;

    ////////////////////////////////////////////////////////////////
    //                          MODIFIERS                         //
    ////////////////////////////////////////////////////////////////

    modifier publicMintAccess() {
        if (!publicMintState) revert("PublicMintClosed");
        _;
    }

    modifier hasReachedMax(uint256 amount) {
        if (liveSupply.current() + amount > maxSupply)
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
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _price,
        uint256 _maxSupply,
        SplitterImpl _splitter,
        uint96 _fraction,
        address _router
    ) ERC721(_name, _symbol) Owned(_router) {
        baseURI = _baseURI;
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

    function setBaseURI(string memory _baseURI)
        external
        onlyOwner
    {
        baseURI = _baseURI;

        emit BaseURISet(_baseURI);
    }

    function setPublicMintState(bool _publicMintState)
        external
        onlyOwner
    {
        publicMintState = _publicMintState;

        emit PublicMintStateSet(_publicMintState);
    }

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
        // Transfer event emited by parent ERC721 contract
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
        // for (uint256 i = 0; i < amount; i++) {
        for (i; i < amount; ) {
            _safeMint(msg.sender, _nextId());
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
        // emit transfer event in parent ERC721 contract
    }

    ////////////////////////////////////////////////////////////////
    //                          HELPER FX                         //
    ////////////////////////////////////////////////////////////////

    function _nextId() private returns (uint256) {
        liveSupply.increment();
        return liveSupply.current();
    }

    ////////////////////////////////////////////////////////////////
    //                           VIEW FX                          //
    ////////////////////////////////////////////////////////////////

    function getBaseURI()
        external
        view
        returns (string memory)
    {
        return baseURI;
    }

    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (id > totalSupply()) revert("NotMintedYet");
        return
            string(
                abi.encodePacked(
                    baseURI,
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
        override(ERC721, ERC2981)
        returns (bool)
    {
        return
            // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7 ||
            // ERC165 Interface ID for ERC721
            interfaceId == 0x80ac58cd ||
            // ERC165 Interface ID for ERC721Metadata
            interfaceId == 0x5b5e139f ||
            // ERC165 Interface ID for ERC2981
            interfaceId == 0x2a55205a;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

import { ERC721WhitelistEvents } from "../Base/interfaces/ERC721EventAndErrors.sol";
import { ERC721, ERC721TokenReceiver } from "../Base/ERC721.sol";
import { ERC2981 } from "../../common/ERC2981.sol";
import { ERC20 } from "../../ERC20.sol";

import { ReentrancyGuard } from "../../../security/ReentrancyGuard.sol";
import { SplitterImpl } from "../../../splitter/SplitterImpl.sol";
import { MerkleProof } from "../../../utils/MerkleProof.sol";
import { Counters } from "../../../utils/Counters.sol";
import { Strings } from "../../../utils/Strings.sol";
import { Owned } from "../../../auth/Owned.sol";
import { SafeTransferLib } from "../../../utils/SafeTransferLib.sol";

contract ERC721Whitelist is
    ERC721,
    ERC2981,
    ERC721WhitelistEvents,
    ERC721TokenReceiver,
    Owned,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    ////////////////////////////////////////////////////////////////
    //                           STORAGE                          //
    ////////////////////////////////////////////////////////////////

    Counters.Counter private liveSupply;

    string private baseURI;
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

    uint256 public maxFree;
    uint256 public freeSupply;
    bytes32 public claimListMerkleRoot;
    /// @dev default := false.
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
            liveSupply.current() + amount >
            maxSupply - maxWhitelistSupply - maxFree
        ) revert("MaxMintReached");
        _;
    }

    modifier canMintFree(uint256 amount) {
        if (freeSupply + amount > maxFree)
            revert("MaxFreeReached");
        if (liveSupply.current() + amount > maxSupply)
            revert("MaxMintReached");
        _;
    }

    modifier whitelistMax(uint8 amount) {
        if (whitelistMinted + amount > maxWhitelistSupply)
            revert("MaxWhitelistReached");
        if (liveSupply.current() + amount > maxSupply)
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
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _price,
        uint256 _maxSupply,
        SplitterImpl _splitter,
        uint96 _fraction,
        address _router
    ) ERC721(_name, _symbol) Owned(_router) {
        baseURI = _baseURI;
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

    function setBaseURI(string memory _baseURI)
        external
        onlyOwner
    {
        baseURI = _baseURI;

        emit BaseURISet(_baseURI);
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

    // only mad
    function burn(uint256[] memory ids) external onlyOwner {
        uint256 i;
        uint256 len = ids.length;
        for (i; i < len; ) {
            // delId();
            liveSupply.decrement();
            _burn(ids[i]);
            unchecked {
                ++i;
            }
        }
        // assembly overflow check
        assembly {
            if lt(i, len) {
                mstore(0x00, "LOOP_OVERFLOW")
                revert(0x00, 0x20)
            }
        }
        // Transfer event emited by parent ERC721 contract
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
            _safeMint(tx.origin, _nextId());
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
        // Transfer event emitted in parent ERC721 contract
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
            _safeMint(addresses[i], _nextId());
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
        // Transfer event emitted in parent ERC721 contract
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
            _safeMint(msg.sender, _nextId());
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

        // Transfer event emitted in parent ERC721 contract
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
            _safeMint(msg.sender, _nextId());
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
        // Transfer event emitted in parent ERC721 contract
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
            _safeMint(msg.sender, _nextId());
            // j++;
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
        // Transfer event emitted in parent ERC721 contract
    }

    ////////////////////////////////////////////////////////////////
    //                          HELPER FX                         //
    ////////////////////////////////////////////////////////////////

    function _nextId() private returns (uint256) {
        liveSupply.increment();
        return liveSupply.current();
    }

    ////////////////////////////////////////////////////////////////
    //                           VIEW FX                          //
    ////////////////////////////////////////////////////////////////

    function getBaseURI()
        external
        view
        returns (string memory)
    {
        return baseURI;
    }

    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (id > totalSupply()) revert("NotMintedYet");
        return
            string(
                abi.encodePacked(
                    baseURI,
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
        override(ERC721, ERC2981)
        returns (bool)
    {
        return
            // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7 ||
            // ERC165 Interface ID for ERC721
            interfaceId == 0x80ac58cd ||
            // ERC165 Interface ID for ERC721Metadata
            interfaceId == 0x5b5e139f ||
            // ERC165 Interface ID for ERC2981
            interfaceId == 0x2a55205a;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

import { ERC721LazyEventsAndErrors } from "../Base/interfaces/ERC721EventAndErrors.sol";
import { ERC721, ERC721TokenReceiver } from "../Base/ERC721.sol";
import { ERC2981 } from "../../common/ERC2981.sol";
import { ERC20 } from "../../ERC20.sol";
import { ReentrancyGuard } from "../../../security/ReentrancyGuard.sol";
import { SplitterImpl } from "../../../splitter/SplitterImpl.sol";
import { Counters } from "../../../utils/Counters.sol";
import { Strings } from "../../../utils/Strings.sol";
import { Owned } from "../../../auth/Owned.sol";
import { SafeTransferLib } from "../../../utils/SafeTransferLib.sol";
import { Types } from "../../../../Types.sol";

contract ERC721Lazy is
    ERC721,
    ERC2981,
    ERC721LazyEventsAndErrors,
    ERC721TokenReceiver,
    Owned,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Types for Types.Voucher;

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

    /// @dev The signer address used for lazy minting voucher validation.
    address private signer;

    Counters.Counter private liveSupply;

    string private baseURI;

    SplitterImpl public splitter;

    mapping(bytes32 => bool) public usedVouchers;

    ////////////////////////////////////////////////////////////////
    //                         CONSTRUCTOR                        //
    ////////////////////////////////////////////////////////////////

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        SplitterImpl _splitter,
        uint96 _fraction,
        address _router,
        address _signer
    ) ERC721(_name, _symbol) Owned(_router) {
        _CHAIN_ID_OG = block.chainid;
        _DOMAIN_SEPARATOR_OG = computeDS();
        // setSigner(_signer);
        signer = _signer;
        baseURI = _baseURI;
        splitter = _splitter;

        _royaltyFee = _fraction;
        _royaltyRecipient = payable(splitter);

        emit SignerUpdated(_signer);
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
        address _signer = _verify(voucher, v, r, s);
        _lazyCheck(_signer, voucher);
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

    ////////////////////////////////////////////////////////////////
    //                         OWNER FX                           //
    ////////////////////////////////////////////////////////////////

    /// @dev Can only be updated by the Router's owner.
    function setSigner(address _signer) public onlyOwner {
        signer = _signer;

        emit SignerUpdated(_signer);
    }

    /// @notice Changes the `baseURI` value in storage.
    /// @dev Can only be accessed by the collection creator.
    function setBaseURI(string memory _baseURI)
        external
        onlyOwner
    {
        baseURI = _baseURI;

        emit BaseURISet(_baseURI);
    }

    function burn(uint256[] memory ids) external onlyOwner {
        uint256 i;
        uint256 len = ids.length;
        // for (uint256 i = 1; i < ids.length; i++) {
        for (i; i < len; ) {
            // delId();
            liveSupply.decrement();
            _burn(ids[i]);
            unchecked {
                ++i;
            }
        }
        // assembly overflow check
        assembly {
            if lt(i, len) {
                mstore(0x00, "LOOP_OVERFLOW")
                revert(0x00, 0x20)
            }
        }
        // Transfer event emited by parent ERC721 contract
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
    function _lazyCheck(
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

    function _verify(
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

    function computeDS() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _DOMAIN_TYPEHASH,
                    keccak256(bytes(name)),
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
            _mint(_key, _nextId());
            // can't overflow due to have been previously validated by signer
            unchecked {
                ++j;
            }
        }
    }

    ////////////////////////////////////////////////////////////////
    //                           VIEW FX                          //
    ////////////////////////////////////////////////////////////////

    function getBaseURI()
        external
        view
        returns (string memory)
    {
        return baseURI;
    }

    function tokenURI(uint256 id)
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
                    baseURI,
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
        override(ERC721, ERC2981)
        returns (bool)
    {
        return
            // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7 ||
            // ERC165 Interface ID for ERC721
            interfaceId == 0x80ac58cd ||
            // ERC165 Interface ID for ERC721Metadata
            interfaceId == 0x5b5e139f ||
            // ERC165 Interface ID for ERC2981
            interfaceId == 0x2a55205a;
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

interface ERC721MinimalEvents {
    ////////////////////////////////////////////////////////////////
    //                           EVENTS                           //
    ////////////////////////////////////////////////////////////////

    event RoyaltyRecipientSet(address indexed newRecipient);
    event RoyaltyFeeSet(uint256 indexed newRoyaltyFee);
    event PublicMintStateSet(bool indexed newPublicMintState);
}

interface ERC721BasicEvents {
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

    // /// @dev 0x2d0a3f8e
    // // error PublicMintClosed();
    // /// @dev 0xd05cb609
    // // error MaxSupplyReached();
    // /// @dev 0xbad086ea
    // // error NotMintedYet();
    // /// @dev 0xf7760f25
    // // error WrongPrice();
}

interface ERC721WhitelistEvents {
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

    // /// @dev 0x2d0a3f8e
    // error PublicMintClosed();
    // /// @dev 0x700a6c1f
    // error WhitelistMintClosed();
    // /// @dev 0xf44170cb
    // error FreeClaimClosed();
    // /// @dev 0xfc3fc71f
    // // error MaxMintReached();
    // /// @dev 0xf90c1bdb
    // error MaxFreeReached();
    // /// @dev 0xa554e6e1
    // // error MaxWhitelistReached();
    // /// @dev 0x646cf558
    // error AlreadyClaimed();
    // /// @dev 0xf7760f25
    // // error WrongPrice();
    // /// @dev 0xbad086ea
    // error NotMintedYet();
    // /// @dev 0x3b8474be
    // error AddressDenied();
}

interface ERC721LazyEventsAndErrors {
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

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id)
        public
        view
        virtual
        returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id)
        public
        view
        virtual
        returns (address owner)
    {
        require(
            (owner = _ownerOf[id]) != address(0),
            "NOT_MINTED"
        );
    }

    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256)
    {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool))
        public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id)
        public
        virtual
    {
        address owner = _ownerOf[id];

        require(
            msg.sender == owner ||
                isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from ||
                isApprovedForAll[from][msg.sender] ||
                msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    ""
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id)
        internal
        virtual
    {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    ""
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
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