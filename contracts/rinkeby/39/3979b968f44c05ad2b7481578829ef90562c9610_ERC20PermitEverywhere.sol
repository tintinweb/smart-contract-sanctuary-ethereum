/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

contract ERC20PermitEverywhere {
    struct PermitTransferFrom {
        IERC20 token;
        address spender;
        uint256 maxAmount;
        uint256 deadline;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public immutable TRANSFER_PERMIT_TYPEHASH;

    // Owner -> current nonce.
    mapping (address => uint256) public currentNonce;

    constructor() {
        uint256 chainId;
        assembly { chainId := chainid() }
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
            keccak256(bytes('ERC20PermitEverywhere')),
            keccak256(bytes('1.0.0')),
            chainId,
            address(this)
        ));
        TRANSFER_PERMIT_TYPEHASH =
            keccak256('PermitTransferFrom(address token,address spender,uint256 maxAmount,uint256 deadline,uint256 nonce)');
    }

    function executePermitTransferFrom(
        address owner,
        address to,
        uint256 amount,
        PermitTransferFrom memory permit,
        Signature memory sig
    )
        external
    {
        require(permit.spender == address(0) || msg.sender == permit.spender, 'SPENDER_NOT_PERMITTED');
        require(permit.deadline >= block.timestamp, 'PERMIT_EXPIRED');
        require(permit.maxAmount >= amount, 'EXCEEDS_PERMIT_AMOUNT');
        uint256 nonce = currentNonce[owner]++;
        require(owner == getSigner(hashPermit(permit, nonce), sig), 'INVALID_SIGNER');
        _transferFrom(permit.token, owner, to, amount);
    }

    function hashPermit(PermitTransferFrom memory permit, uint256 nonce)
        public
        view
        returns (bytes32 h)
    {
        bytes32 dh = DOMAIN_SEPARATOR;
        bytes32 th = TRANSFER_PERMIT_TYPEHASH;
        assembly {
            if lt(permit, 0x20)  {
                invalid()
            }
            let c1 := mload(sub(permit, 0x20))
            let c2 := mload(add(permit, 0x80))
            mstore(sub(permit, 0x20), th)
            mstore(add(permit, 0x80), nonce)
            let ph := keccak256(sub(permit, 0x20), 0xC0)
            mstore(sub(permit, 0x20), c1)
            mstore(add(permit, 0x80), c2)
            let p:= mload(0x40)
            mstore(p, 0x1901000000000000000000000000000000000000000000000000000000000000)
            mstore(add(p, 0x02), dh)
            mstore(add(p, 0x22), ph)
            h := keccak256(p, 0x42)
        }
    }

    function getSigner(bytes32 hash, Signature memory sig) private pure returns (address signer) {
        signer = ecrecover(hash, sig.v, sig.r, sig.s);
        require(signer != address(0), 'INVALID_SIGNATURE');
    }

    function _transferFrom(IERC20 token, address owner, address to, uint256 amount) private {
        bytes4 transferFromSelector = IERC20.transferFrom.selector;
        bool s;
        assembly {
            let p:= mload(0x40)
            mstore(p, transferFromSelector)
            mstore(add(p, 0x04), owner)
            mstore(add(p, 0x24), to)
            mstore(add(p, 0x44), amount)
            s:= call(gas(), token, 0, p, 0x64, 0, 0)
            if iszero(s) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
            if gt(returndatasize(), 0x19) {
                returndatacopy(p, 0, 0x20)
                s := and(not(iszero(mload(p))), 1)
            }
        }
        require(s, 'TRANSFER_FAILED');
    }
}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address owner, address to, uint256 amount) external returns (bool);
}