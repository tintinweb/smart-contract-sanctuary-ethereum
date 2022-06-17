//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
                 _   _         _____      _ _ _     _               ______ _____ _____
     /\         | | (_)       / ____|    | | (_)   (_)             |  ____/ ____/ ____|
    /  \   _ __ | |_ _ ______| |     ___ | | |_ ___ _  ___  _ __   | |__ | |   | |
   / /\ \ | '_ \| __| |______| |    / _ \| | | / __| |/ _ \| '_ \  |  __|| |   | |
  / ____ \| | | | |_| |      | |___| (_) | | | \__ \ | (_) | | | | | |___| |___| |____
 /_/    \_\_| |_|\__|_|       \_____\___/|_|_|_|___/_|\___/|_| |_| |______\_____\_____|

         n                                                                 :.
         E%                                                                :"5
        z  %                                                              :" `
        K   ":                                                           z   R
        ?     %.                                                       :^    J
         ".    ^s                                                     f     :~
          '+.    #L                                                 z"    .*
            '+     %L                                             z"    .~
              ":    '%.                                         .#     +
                ":    ^%.                                     .#`    +"
                  #:    "n                                  .+`   .z"
                    #:    ":                               z`    +"
                      %:   `*L                           z"    z"
                        *:   ^*L                       z*   .+"
                          "s   ^*L                   z#   .*"
                            #s   ^%L               z#   .*"
                              #s   ^%L           z#   .r"
                                #s   ^%.       u#   .r"
                                  #i   '%.   u#   [email protected]"
                                    #s   ^%u#   [email protected]"
                                      #s x#   .*"
                                       x#`  [email protected]%.
                                     x#`  .d"  "%.
                                   xf~  .r" #s   "%.
                             u   x*`  .r"     #s   "%.  x.
                             %Mu*`  x*"         #m.  "%zX"
                             :R(h x*              "h..*dN.
                           [email protected]#>                 7?dMRMh.
                         [email protected]@$#"#"                 *""*@MM$hL
                       [email protected]@MM8*                          "*[email protected]
                     z$RRM8F"                             "[email protected]$bL
                    5`RM$#                                  'R88f)R
                    'h.$"                                     #$x*

This contract is made to allow for the resending of cross chain messages
I.E. Layer Zero/Axelar as a protection measure on the off chance that a message gets
lost in transit by a protocol. As a further protection measure it implements security
features such as anti-collision and message expiriy. This is to ensure that it should
be impossible to have a message failure so bad that it cannot be recovered from,
while ensuring that an intentional collision to corrupt data cannot cause unexpected
behaviour other than that of what the original message would have created.

The implementation of this contract can cause vulnurablities, any development with or
around this should follow suite with a guideline paper published here: [], along with
general security audits and proper implementation on all fronts.
*/

import "../interfaces/IHelper.sol";
import "./interfaces/IECC.sol";
import "./eccAdmin.sol";

// slither-disable-next-line unimplemented-functions
contract ECC is IECC, ECCAdmin {
    constructor() {
        admin = msg.sender;
    }

    // pre register message
    // used when sending a message i.e. lzSend
    // slither-disable-next-line assembly
    function preRegMsg(
        bytes memory payload,
        address instigator
    ) external override callerAuth() returns (bytes32 metadata) {
        require(payload.length / 32 <= usableSize, "PAYLOAD_TOO_BIG");
        require(payload.length % 32 == 0, "PAYLOAD_NONDIVISABLE_BY_32");

        bytes32 payloadHash = keccak256(payload);

        bytes32 ptr = keccak256(abi.encode(
            instigator,
            block.timestamp,
            payloadHash
        ));

        assembly {
            let nonce
            { // modify ptr to have an consistent starting point
                let msze := sload(mSize.slot)
                let delta := mod(ptr, msze)
                let halfmsze := div(msze, 2)
                // round down at half
                if iszero(gt(delta, halfmsze)) { ptr := sub(ptr, delta) }
                if gt(delta, halfmsze) { ptr := add(ptr, delta) }

                // anti-collision logic
                for {} gt(sload(ptr), 0) {
                    ptr := add(ptr, msze)
                    nonce := add(nonce, 1)
                } {
                    // empty block to optimize away 2 jump opcodes every iteration
                }
            }

            { // write metadata
                // packing the struct tightly instead of loose packing
                metadata := or(shl(160, or(shl(16, or(shl(40, shr(216, payloadHash)), timestamp())), nonce)), instigator)
                sstore(ptr, metadata)
            }

            for { // write payload directly after metadata
                let l := div(mload(payload), 0x20)
                let i := sload(metadataSize.slot)
            } gt(l, 0) {
                sstore(add(ptr, i), mload(add(1, add(payload, i))))

                i := add(i, 1)
                l := sub(l, 1)
            } {
                // empty block to optimize away 2 jump opcodes every iteration
            }
        }

        // emit ptr
    }

    // pre processing validation
    // used prior to processing a message
    // checks if message has already been processed or is allowed to be processed
    function preProcessingValidation(
        bytes memory payload,
        bytes32 metadata
    ) external override callerAuth() view returns (bool) {
        bytes32 ptr = metadata;

        bytes32 payloadHash = keccak256(payload);

        assembly {
            // modify ptr to have an consistent starting point
            let msze := sload(mSize.slot)
            let delta := mod(ptr, msze)
            let halfmsze := div(msze, 2)
            // round down at half
            if iszero(gt(delta, halfmsze)) { ptr := sub(ptr, delta) }
            if gt(delta, halfmsze) { ptr := add(ptr, delta) }

            // anti-collision logic
            for {} gt(sload(ptr), 0) {
                if eq(sload(ptr), payloadHash) {
                    if eq(sload(add(ptr, 1)), metadata) {
                        mstore(0, 0)
                        return(0, 32)
                    }
                }
                ptr := add(ptr, msze)
            } {
                // empty block to optimize away 2 jump opcodes every iteration
            }

            mstore(0, 1)
            return(0, 32)
        }
    }

    // flag message as validate
    // slither-disable-next-line assembly
    function flagMsgValidated(
        bytes memory payload,
        bytes32 metadata
    ) external override callerAuth() returns (bool) {
        bytes32 ptr = metadata;

        bytes32 payloadHash = keccak256(payload);

        assembly {
            // modify ptr to have an consistent starting point
            let msze := sload(mSize.slot)
            let delta := mod(ptr, msze)
            let halfmsze := div(msze, 2)
            // round down at half
            if iszero(gt(delta, halfmsze)) { ptr := sub(ptr, delta) }
            if gt(delta, halfmsze) { ptr := add(ptr, delta) }

            { // anti-collision logic
                // we first check if ptr is empty
                if iszero(sload(ptr)) {
                    sstore(ptr, payloadHash)
                    sstore(add(ptr, 1), metadata)
                    mstore(0, 1)
                    return(0, 32)
                }
                // otherwise find non-collision slot
                for {} gt(sload(ptr), 0) {
                    if eq(sload(ptr), payloadHash) {
                        if eq(sload(add(ptr, 1)), metadata) {
                            mstore(0, 0)
                            return (0, 32)
                        }
                    }
                    ptr := add(ptr, msze)
                } {
                    // empty block to optimize away 2 jump opcodes every iteration
                }

                if iszero(sload(ptr)) {
                    sstore(ptr, payloadHash)
                    sstore(add(ptr, 1), metadata)
                    mstore(0, 1)
                    return(0, 32)
                }
            }
        }

        return false;
    }

    // resend message
    // checks expiry, allows to resend the data given nothing is corrupted
    // function rsm(uint256 messagePtr) external returns (bool) {
        // TODO: Is this needed?
    // }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface IHelper {
    enum Selector {
        MASTER_DEPOSIT,
        MASTER_REDEEM_ALLOWED,
        FB_REDEEM,
        MASTER_REPAY,
        MASTER_BORROW_ALLOWED,
        FB_BORROW,
        SATELLITE_LIQUIDATE_BORROW,
        MASTER_TRANSFER_ALLOWED,
        FB_COMPLETE_TRANSFER,
        PUSD_BRIDGE
    }

    // !!!!
    // @dev
    // an artificial uint256 param for metadata should be added
    // after packing the payload
    // metadata can be generated via call to ecc.preRegMsg()

    struct MDeposit {
        Selector selector; // = Selector.MASTER_DEPOSIT
        address user;
        address pToken;
        uint256 amountIncreased;
    }

    struct MRedeemAllowed {
        Selector selector; // = Selector.MASTER_REDEEM_ALLOWED
        address pToken;
        address user;
        uint256 amount;
    }

    struct FBRedeem {
        Selector selector; // = Selector.FB_REDEEM
        address pToken;
        address user;
        uint256 redeemAmount;
    }

    struct MRepay {
        Selector selector; // = Selector.MASTER_REPAY
        address borrower;
        uint256 amountRepaid;
    }

    struct MBorrowAllowed {
        Selector selector; // = Selector.MASTER_BORROW_ALLOWED
        address user;
        uint256 borrowAmount;
    }

    struct FBBorrow {
        Selector selector; // = Selector.FB_BORROW
        address user;
        uint256 borrowAmount;
    }

    struct SLiquidateBorrow {
        Selector selector; // = Selector.SATELLITE_LIQUIDATE_BORROW
        address borrower;
        address liquidator;
        uint256 seizeTokens;
        address pTokenCollateral;
    }

    struct MTransferAllowed {
        uint8 selector; // = Selector.MASTER_TRANSFER_ALLOWED
        address pToken;
        address spender;
        address user;
        address dst;
        uint256 amount;
    }

    struct FBCompleteTransfer {
        uint8 selector; // = Selector.FB_COMPLETE_TRANSFER
        address pToken;
        address spender;
        address src;
        address dst;
        uint256 tokens;
    }

    struct PUSDBridge {
        uint8 selector; // = Selector.PUSD_BRIDGE
        address minter;
        uint256 amount;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IECC {
    struct Metadata {
        bytes5 soph; // start of payload hash
        uint40 creation;
        uint16 nonce; // in case the same exact message is sent multiple times the same block, we increase the nonce in metadata
        address sender;
    }

    function preRegMsg(
        bytes memory payload,
        address instigator
    ) external returns (bytes32 metadata);

    function preProcessingValidation(
        bytes memory payload,
        bytes32 metadata
    ) external view returns (bool allowed);

    function flagMsgValidated(
        bytes memory payload,
        bytes32 metadata
    ) external returns (bool);

    // function rsm(uint256 messagePtr) external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./eccModifiers.sol";
import "./eccEvents.sol";

abstract contract ECCAdmin is ECCModifiers, ECCEvents {
    function changeOwner(
        address newOwner
    ) external onlyOwner() {
        require(newOwner != address(0), "NON_ZEROADDRESS");
        emit OwnerChanged(msg.sender, newOwner);
        admin = newOwner;
    }

    function changeCallerAuth(
        address caller,
        bool authorized
    ) external onlyOwner() {
        emit CallerAuthChanged(caller, authorized);
        authorizedCallers[caller] = authorized;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./eccStorage.sol";

abstract contract ECCModifiers is ECCStorage {
    modifier onlyOwner() {
        require(msg.sender == admin, "ONLY_OWNER");
        _;
    }

    modifier callerAuth() {
        require(authorizedCallers[msg.sender], "ONLY_AUTH_CALLER");
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ECCEvents {
    event OwnerChanged(address oldOwner, address newOwner);
    event CallerAuthChanged(address caller, bool authStatus);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract ECCStorage {
    // ? These vars are not marked as constant because inline yul does not support loading
    // ? constant vars from state...
    // max 16 slots
    // constable-states,unused-state
    // slither-disable-next-line all
    uint256 internal mSize = 16;
    // Must account for metadata
    // constable-states,unused-state
    // slither-disable-next-line all
    uint256 internal metadataSize = 1;
    // constable-states,unused-state
    // slither-disable-next-line all
    uint256 internal usableSize = 15;

    address internal admin;
    mapping(address => bool) internal authorizedCallers;
}