// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract GLHF {
    bytes32 public gs;
    mapping(bytes2 => bool) public ui;
    mapping(address => uint32) public us;
    bool private _do;
    address private _o;

    modifier oo() {
        require(msg.sender == _o, "nope");
        _;
    }

    modifier udo() {
        require(_do, "nope");
        _;
    }

    constructor() {
        _o = address(this);
        gs = keccak256(abi.encodePacked(blockhash(block.number)));
    }

    function ia(uint32 a_, uint8 b_)
        public
        view
        oo
        returns (uint32)
    {
        assembly {
            let r := add(a_, b_)
            mstore(0x00, r)
            return(0x00, 32)
        }
    }

    function ex() public udo {
        assembly {
            sstore(_do.slot, 0)
        }
    }

    function en(bytes calldata d_) public {
        assembly {
            function lus() -> a, uh {
                mstore(0, caller())
                mstore(32, us.slot)
                uh := keccak256(0, 64)
                a := sload(uh)
            }
            function sgs() -> bh {
                mstore(0, blockhash(number()))
                mstore(32, sload(gs.slot))
                bh := keccak256(0, 64)
                sstore(gs.slot, bh)
            }
            function cu(id) {
                mstore(0, id)
                mstore(32, ui.slot)
                let uih := keccak256(0, 64)
                let u := sload(uih)
                if gt(u, 0) {
                    revert(0, 0)
                }
                sstore(uih, 1)
            }
            let id := shl(0xF0, shr(0xC8, calldataload(d_.offset)))
            cu(id)
            let cn := shr(0xF8, shl(0x20, calldataload(d_.offset)))
            for {
                let i := 0
            } lt(i, cn) {
                i := add(i, 1)
            } {
                let a, uh := lus()
                let p := mload(0x40)
                mstore(p, calldataload(d_.offset))
                mstore(add(p, 0x04), a)
                let ic := shr(0xF8, shl(0xF8, calldataload(d_.offset)))
                mstore(add(p, 0x24), ic)
                let s := call(gas(), address(), 0, p, 0x44, 0, 0)
                if iszero(s) {
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
                returndatacopy(p, 0, returndatasize())
                sstore(uh, mload(p))
            }
            let blh := sgs()
            let blkh := shr(0xE0, shl(0xE0, blh))
            let a, uh := lus()
            if lt(a, 0x0100) {
                revert(0, 0)
            }
            let ef := shr(0xE0, shl(0xD8, calldataload(d_.offset)))
            ef := xor(ef, blkh)
            ef := xor(ef, shl(0x08, a))
            ef := shl(0xE0, ef)
            let p := mload(0x40)
            mstore(p, ef)
            mstore(add(p, 0x04), 0)
            let ea := shr(0x60, shl(0x38, calldataload(d_.offset)))
            ea := xor(ea, blh)
            if eq(ea, address()) {
                revert(0,0)
            }
            sstore(_do.slot, 1)
            let s := call(gas(), ea, 0, p, 0x20, 0, 0)
            if iszero(s) {
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }
            let rt := mload(p)
            if iszero(not(eq(rt, a))) {
                revert(0,0)
            }
        }
    }
}