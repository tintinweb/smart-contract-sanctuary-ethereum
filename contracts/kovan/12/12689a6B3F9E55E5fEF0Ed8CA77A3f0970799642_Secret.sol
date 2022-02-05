//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;


/// @notice The contract contrains a few secrets, to apply at least 2/3 has to be solved
/// @dev The contract is deployed on kovan and goerli at the same address
contract Secret {
    bytes32 private immutable pwd2;
    address private factory;
    uint24 public nonce;
    bytes32 private pwd1;

    constructor() {
        pwd1 = _hash(314159265358979323846264338327950288419716939937510582097494459);
        pwd2 = _hash(271828182845904523536028747135266249775724709369995957496696762);
        factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
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