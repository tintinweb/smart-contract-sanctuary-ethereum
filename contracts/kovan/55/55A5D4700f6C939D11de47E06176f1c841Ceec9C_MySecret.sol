//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;


/// @notice The contract contrains a few secrets, to apply at least 2/3 has to be solved
/// @dev The contract is deployed on kovan and goerli at the same address
contract MySecret {
    bytes32 public immutable pwd2;
    address private factory;
    uint24 public nonce;
    bytes32 private pwd1;

    constructor() {
        pwd1 = _hash(314159265358979323846264338327950288419716939937510582097494459, 1644067340, 30000000, 340282366920938463463374607431768211454, 0xADFfc3D17a537eFCFf6D79f0FC54BF481031eD94);
        pwd2 = _hash(271828182845904523536028747135266249775724709369995957496696762, 1644067340, 30000000, 340282366920938463463374607431768211454, 0xADFfc3D17a537eFCFf6D79f0FC54BF481031eD94);
        factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    }

    function secret1(uint nonce2) external returns (bytes32){
        uint256 secret;
        address f = factory;
        uint256 n = nonce2;
        bytes memory data = abi.encodePacked(bytes4(0x22afcccb), uint256(3000));
        bytes memory buffer = new bytes(32);
        assembly {
            secret := sload(0x0)
            let bufref := add(buffer, 0x20)
            pop(call(gas(), f, 0, add(data, 0x20), 0x24, bufref, 0x20))
            let y := mload(bufref)
            mstore(bufref, add(add(secret, y), n))
            secret := keccak256(bufref, 0x20)  
        }
        return bytes32(secret);
    }


    function _hash(uint value, uint timestamp, uint gaslimit, uint difficulty, address sender) internal returns (bytes32) {

        uint256 seed = timestamp + gaslimit + difficulty + uint256(uint160(sender)) + value;
        bytes memory b = new bytes(32);
        uint256 n = nonce + 1;
        assembly {
            seed := mulmod(seed, seed, add(n, 0xffffff))
            let r := 1
            for { let i := 0 } lt(i, 5) { i := add(i, 1) } 
            {
                r := add(r, div(seed, r))
                mstore(add(b, 0x20), r)
                r := keccak256(add(b, 0x20), 0x20)                
            }
            mstore(add(b, 0x20), r)
        }
        nonce += 1;
        return keccak256(b);
    }

    event Success(uint256 res, string contacts);

    function get_info() view public returns (uint256) {
        return block.gaslimit;
    }
}