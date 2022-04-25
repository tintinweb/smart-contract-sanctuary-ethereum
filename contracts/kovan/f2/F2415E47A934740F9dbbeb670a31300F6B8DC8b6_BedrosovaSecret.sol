/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;


/// @notice The contract contrains a few secrets, to apply at least 2/3 has to be solved
contract BedrosovaSecret {
    bytes32 private immutable pwd2;
    address private factory; //[0] 20
    uint24 public nonce; //[0] 3
    bytes32 private pwd1; //[1]

    bytes32 public mysecret1;
    bytes32 public mysecret2;
    bytes32 public mysecret3;

    constructor() {
        pwd1 = 0xa097646de778accb462d6593c18082346d3f3cd355fe8cbf6f1b3551b5c6044d;
        pwd2 = 0x5f668062be9682387cd8957f8339033192b55962f2280292c705e5811dd8df8a;
        factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    }

    function SetNonce(uint24 _nonce) public{
        nonce=_nonce;
    }

    function Get3Secrets() public{
        uint256 secret;
        address f = factory;
        uint256 n = nonce;
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
        mysecret1=bytes32(secret);

        bytes32 secr2 = pwd1;
        mysecret2= keccak256(abi.encode(secr2, nonce+1));

        bytes32 secr3 = pwd2;
        mysecret3= keccak256(abi.encode(secr3, nonce+2));
    }

    /// @notice The goal is to emit the Success event with your contacts
    function submitApplication(string calldata contacts, bytes32 password1, bytes32 password2, bytes32 password3) external {
        uint256 res;
        try this.secret1(password1) {
            res += 1;
        } catch {}
        try this.secret2(password2) {
            res += 1;
        } catch {}
        try this.secret3(password3) {
            res += 1;
        } catch {}
        if (res > 1) {
            emit Success(res, contacts);
        } else {
            revert("Score is too low");
        }
    }

    

    function secret1(bytes32 password_) external {
        uint256 secret;
        address f = factory;
        uint256 n = nonce;
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
        require(password_ == bytes32(secret), "Forbidden");
        nonce += 1;
    }


    function secret2(bytes32 password_) external {
        bytes32 secret = pwd1;
        require(password_ == keccak256(abi.encode(secret, nonce)), "Forbidden");
        nonce += 1;
    }

    function secret3(bytes32 password_) external {
        bytes32 secret = pwd2;
        require(password_ == keccak256(abi.encode(secret, nonce)), "Forbidden");
        nonce += 1;
    }

    function _hash(uint256 value) internal returns (bytes32) {
        uint256 seed = block.timestamp + block.gaslimit + block.difficulty + uint256(uint160(msg.sender)) + value;
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
}