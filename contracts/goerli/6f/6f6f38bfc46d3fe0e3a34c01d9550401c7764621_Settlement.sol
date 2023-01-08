// SPDX-License-Identifier: None
pragma solidity ^0.8.13;

/*
................................................................................................................................... 
................................................................................................................................... 
...................................................................................................................................
..................................................................................... .............................................
..................................................................................      ........................................... 
................................................................................  :2BB: ........................................... 
..............................................................................  SQBBBBi ...........................................
............................................................................  XBPBBBB1ii7 .........................................
..................................         ................................ :BQOBiQBBrr27 .........................................
................................. QBBDq2Ui.   ...........................  XBlg . gBX:vs ..........................................
................................. .BBBBq1MQMXi   .......................  QB  ..  dB:rLL ..........................................
..................................  QBB7BBL7PQBP:  ....................  BQ  ... vB7i71 ...........................................
...................................  PBEBE.   :PBBj  .....         ...  BE ...  vBj:7ui ...........................................
....................................  sBP  ....  YBB5    .rj5SK5IJr.   Bd .... sBu:7jr ............................................
...................................... .gBI  ....  7BBLKMQEP2IU5XPZRMbQR .... 5BJ:7jr .............................................
.......................................  :RBq   ...  SBI.           .7bi  .. ZB7i7jr .....     ....................................
.........................................  :PBgj.        ............  ..s:7Bgir7ji ..   .uERB  ...................................
...........................................   2MBguS: ...................:QBu:7LJ:    :5RQEY:BL ...................................
..............................................  .jBB ................. .. iBrrv7   :SQQbi    BKvr .................................
................................................  B.  .................    Md::  UQQP:   ..  PBiu .................................
................................................ :B  ;PSB;......... ;PSB;  PM:UZQZr   ...... jQ7L .................................
................................................ .B  iE gj......... Bq BB  jBDDs   ......... iBY7 .................................
........................................   .     .B  ;BBB;....:v... ;BBB;  vB.       .......  QPi7 ................................
....................................... .DBQgqqL 2R:j7. . ... r5  .  ..  :rvB. .:r2XX. ...... PQi7 ................................
....................................... BB..rYIddB1IXdbi ..   jg:  ..  vSKSPQr.:ii..5B. ..    7BrY ................................
...................................... 1B        bZoooZP  .DBBBBBBB1. 7goooqB        SB   :LXPDQvvi ...............................
...................................... iBv .....  Qo.oi7 . PB.. ..BP ..Do.oQ5 .....  XMJqRRMPUvrv1v ...............................
....................................... iBI ..... :g.j: ... Pv...KI .. .J.D:  ....  XQZPXs7r77L7ri ................................
........................................ .QM  .... .ji...... PS.PK ....  iY. ....  RBviirLv7i .. ..................................
.........................................  DB2  ...  :i.....  .V. .....:i: ....  rBgiivsr .........................................
..........................................  iBBI   .. .......:...:............  PB1:7YY  ..........................................
............................................  7RBPiUu .......:i::..........  .2Bgri7J7  ...........................................
..............................................  :KRB. .:.................. :UZKBYivsi .............................................
................................................  gQ .:.................. :I7 .QEi7  ..............................................
................................................ 7B  ..................... X.5B1:Lv ...............................................
............................................  . :Br ...................... qBZr:vss ...............................................
........................................... iJ iQY ....................... 1Bg:vvi ................................................
.......................................... rB  B: ........................ .BZiv  .................................................
.......................................... sB   I ........................ .dD:Y ..................................................
.......................................... Bi   .J ........................ JBrv ..................................................
........................................... bB   .S ....................... :Bj7 ..................................................
............................................ Bq   .L ...................... :Rdi7 .................................................
.............................................. Bd  .: ...................... EgiY .................................................
.............................................. QBi gZ1Jr:  ................. Eg:j .................................................
............................................... 1BDBRPZRRQRRZP27.    ...... iBYrJ .................................................
................................................. irir7ir7sjSPMQBRbui  .:: UB2:71 .................................................
...................................................  iii       :iUPQQBR i QQ7i7u7 .................................................
..................................................... .........     .7Bv  Dg:7Yi ..................................................
....................................................................  sB   Bv7: ...................................................
...................................................................... PB  B5r. ...................................................
....................................................................... qBXB5r. ...................................................
........................................................................ igPYL. ...................................................
.......................................................................... VVJ  ...................................................
............................................................................  :....................................................
...................................................................................................................................
...................................................................................................................................
...................................................................................................................................
*/


import "solmate/tokens/WETH.sol";
import "./utils/BidSignatures.sol";
import "./utils/Pikapatible.sol";

/// @title PikaPool Protocol Settlement Contract
/// @author 0xKhepri and PikaPool Developers

/// @dev Error thrown if WETH transferFrom() call fails, implying the bidder's payment failed
error PaymentFailure();
/// @dev Error thrown if a mint fails
error MintFailure();

contract Settlement is BidSignatures {

    /// @dev Struct of signature data for winning bids to be deconstructed and validated to mint NFTs
    /// @param bid The winning bid fed to this Settlement contract by the Orchestrator
    /// @param v ECDSA cryptographic parameter derived from digest hash and bidder privatekey
    /// @param r ECDSA cryptographic parameter derived from digest hash and bidder privatekey
    /// @param s ECDSA cryptographic parameter derived from digest hash and bidder privatekey
    struct Signature {
        Bid bid;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @dev WETH contract for this chain, set in constructor
    WETH public weth;

    /// @dev Maximum mint threshold amount to prevent excessive first-time token transfer costs
    /// @dev Stored in storage for gas optimization (as opposed to repeated mstores)
    uint256 public mintMax;

    event SettlementFailure(address indexed bidder, bytes indexed reason);

    constructor(address _wethAddress, uint256 _mintMax) {
        weth = WETH(payable(_wethAddress));
        mintMax = _mintMax;
    }
    
    /// @dev Function to settle each winning bid via EIP-712 signature
    /// @param auctionName The name of the creator's NFT collection being auctioned
    /// @param auctionAddress The address of the creator NFT being bid on. Becomes a string off-chain.
    /// @param bidder The address of the bid's originator, similar to tx.origin.
    /// @param amount The number of assets being bid on.
    /// @param basePrice The base price per NFT set by the collection's creator
    /// @param tip The tip per NFT offered by the bidder in order to win a mint in the auction
    function settleFromSignature(
        string memory auctionName,
        address auctionAddress,
        address bidder,
        uint256 amount,
        uint256 basePrice,
        uint256 tip,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {

        address recovered = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    // gas optimization of BidSignatures.hashBid(): calldata < mstore/mload !
                    keccak256(
                        abi.encode(
                            BID_TYPE_HASH,
                            auctionName,
                            auctionAddress,
                            bidder,
                            amount,
                            basePrice,
                            tip
                        )
                    )
                )
            ),
            v,
            r,
            s
        );

        // handle signature error cases
        if (recovered == address(0) || recovered != bidder) return false;
        else return true;
    }
    
    /// @dev Internal function that finalizes the settlements upon verification of signatures
    function _settle(
        address auctionAddress, 
        address bidder, 
        uint256 amount, 
        uint256 basePrice,
        uint256 tip
    ) internal {
        uint256 totalWithoutTip = amount * basePrice;
        // check allowance before weth transfer to prevent reverts during batch settling
        if (weth.allowance(bidder, address(this)) >= totalWithoutTip) {
            bool p = weth.transferFrom(bidder, address(this), totalWithoutTip + tip);

            // if weth transfer succeeds, unwrap weth to eth and pay for creator's NFT mint
            // create a gas table for these steps as they add more gas overhead than they're worth
            if (p) {
                weth.withdraw(totalWithoutTip);
                Pikapatible(payable(auctionAddress)).mint{ value: totalWithoutTip }(bidder, amount);
            } else {
                emit SettlementFailure(bidder, bytes("Payment Failed"));
            }
        } else {
            emit SettlementFailure(bidder, bytes("Approve WETH"));
        }
    }

    /// @dev Function to be called by the Orchestrator following the conclusion of each auction
    /// @notice Once testnet deployments are complete and testing has been completed by the team's various addresses, restrict this function to Orchestrator only via access control
    function finalizeAuction(Signature[] memory signatures) external /* onlyOwner(=orchestrator) */ { 
        // uint256 length = signatures.length; // for when signatures is moved to calldata
        for (uint256 i; i < signatures.length; ) {
            if (signatures[i].bid.amount <= mintMax) {
                bool settle = settleFromSignature(
                    signatures[i].bid.auctionName,
                    payable(signatures[i].bid.auctionAddress),
                    signatures[i].bid.bidder,
                    signatures[i].bid.amount,
                    signatures[i].bid.basePrice,
                    signatures[i].bid.tip,
                    signatures[i].v,
                    signatures[i].r,
                    signatures[i].s
                );
                if (settle) { 
                    _settle(
                        signatures[i].bid.auctionAddress, 
                        signatures[i].bid.bidder, 
                        signatures[i].bid.amount, 
                        signatures[i].bid.basePrice,
                        signatures[i].bid.tip
                    );
                } else {
                    emit SettlementFailure(signatures[i].bid.bidder, bytes("Invalid Sig"));
                }
            } else {
                emit SettlementFailure(signatures[i].bid.bidder, bytes("Exceeds MintMax"));
            }

            unchecked {
                ++i;
            }
        }        
    }

    receive() external payable {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "./ERC20.sol";

import {SafeTransferLib} from "../utils/SafeTransferLib.sol";

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/WETH.sol)
/// @author Inspired by WETH9 (https://github.com/dapphub/ds-weth/blob/master/src/weth9.sol)
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.13;

/// @title PikaPool Protocol Settlement Contract
/// @author 0xKhepri and PikaPool Developers

abstract contract BidSignatures {

    /// @dev Struct of bid data to be hashed and signed for meta-transactions. 
    /// @param auctionName The name of the creator's NFT collection being auctioned
    /// @param auctionAddress The address of the creator NFT being bid on. Becomes a string off-chain.
    /// @param bidder The address of the bid's originator, similar to tx.origin.
    /// @param amount The number of assets being bid on.
    /// @param basePrice The base price per NFT set by the collection's creator
    /// @param tip The tip per NFT offered by the bidder in order to win a mint in the auction
    struct Bid {
        string auctionName;
        address auctionAddress;
        address bidder;
        uint256 amount;
        uint256 basePrice;
        uint256 tip;
    }

    /// @dev The EIP-712 type hash for the Bid struct
    bytes32 public constant BID_TYPE_HASH = 
        keccak256("Bid(string auctionName,address auctionAddress,address bidder,uint256 amount,uint256 basePrice,uint256 tip)"
    );
    
    /// @dev The EIP-712 domain type hash, required to derive domain separator
    bytes32 public constant DOMAIN_TYPE_HASH = 
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    /// @dev The EIP-712 domain name, required to derive domain separator
    bytes32 public constant DOMAIN_NAME = keccak256("Pikapool Auction");

    /// @dev The EIP-712 domain version, required to derive domain separator
    bytes32 public constant DOMAIN_VERSION = keccak256("1");

    /// @dev The EIP-712 domain separator, required to prevent replay attacks across networks
    bytes32 public immutable DOMAIN_SEPARATOR;

    /// @dev Event emitted when a bid is signed.
    //todo
    // event Signature(address indexed owner, bytes bidData, bool revoked);

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPE_HASH,
                DOMAIN_NAME,
                DOMAIN_VERSION,
                block.chainid,
                address(this)
            )
        );
    }

    /// @dev Function to compute hash of a bid
    function hashBid(Bid memory bid) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                BID_TYPE_HASH,
                bid.auctionName,
                bid.auctionAddress,
                bid.bidder,
                bid.amount,
                bid.basePrice,
                bid.tip
            )
        );
    }

    /// @dev Function to compute hash of fully EIP-712 encoded message for the domain to be used with ecrecover()
    function hashTypedData(Bid memory bid) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                hashBid(bid)
            )
        );
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.13;

import "ERC721A/ERC721A.sol";
import "solmate/auth/Owned.sol";

/// @title PikaPool Protocol Settlement Contract
/// @author 0xKhepri and PikaPool Developers

/// @dev This plugin attaches to any ERC721A contract and renders it Pika-Compatible 'Pikapatible'
/// by implementing its mint function and declaring the PikaPool Settlement contract its owner.
/// This ensures all payments and tips are reliably received on mint from PikaPool in accordance with its robust auction engine
abstract contract Pikapatible is ERC721A, Owned {

    uint256 public price;

    constructor(address _settlementContract, uint256 _priceInGweth) Owned(_settlementContract) {
        price = _priceInGweth;
    }

    /// @dev This mint function can be attached to any ERC721A to enjoy the benefits of the PikaPool auction engine
    /// It will not mint if insufficient funds are paid, avoiding a revert() in order to facilitate the
    /// Settlement contract's batch minting functionality
    /// @notice ERC721A's _safeMint() functionality is shirked in favor of _mint, as all PikaPool mints 
    /// utilize meta-transactions. This ensures no smart contracts can bid as they do not possess private keys.
    /// @notice May only be called by the Settlement contract
    /// @param to The bidder address to mint to, provided a sufficient bid was offered
    /// @param amount The number of NFTs to mint to the bidder
    function mint(address to, uint256 amount) external payable onlyOwner returns (bool success) {
        if (msg.value >= price) {
            _mint(to, amount);

            return true;
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

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

    mapping(address => mapping(address => uint256)) public allowance;

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

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
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

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

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
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

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

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
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

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
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
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
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

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
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

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256 packed) {
        if (_startTokenId() <= tokenId) {
            packed = _packedOwnerships[tokenId];
            // If not burned.
            if (packed & _BITMASK_BURNED == 0) {
                // If the data at the starting slot does not exist, start the scan.
                if (packed == 0) {
                    if (tokenId >= _currentIndex) revert OwnerQueryForNonexistentToken();
                    // Invariant:
                    // There will always be an initialized ownership slot
                    // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                    // before an unintialized ownership slot
                    // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                    // Hence, `tokenId` will not underflow.
                    //
                    // We can directly compare the packed value.
                    // If the address is zero, packed will be zero.
                    for (;;) {
                        unchecked {
                            packed = _packedOwnerships[--tokenId];
                        }
                        if (packed == 0) continue;
                        return packed;
                    }
                }
                // Otherwise, the data exists and is not burned. We can skip the scan.
                // This is possible because we have already achieved the target condition.
                // This saves 2143 gas on transfers of initialized tokens.
                return packed;
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account. See {ERC721A-_approve}.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     */
    function approve(address to, uint256 tokenId) public payable virtual override {
        _approve(to, tokenId, true);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                // The `iszero(eq(,))` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
                // The compiler will optimize the `iszero` away for performance.
                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                       APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_approve(to, tokenId, false)`.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _approve(to, tokenId, false);
    }

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        bool approvalCheck
    ) internal virtual {
        address owner = ownerOf(tokenId);

        if (approvalCheck)
            if (_msgSenderERC721A() != owner)
                if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                    revert ApprovalCallerNotOwnerNorApproved();
                }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

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

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}