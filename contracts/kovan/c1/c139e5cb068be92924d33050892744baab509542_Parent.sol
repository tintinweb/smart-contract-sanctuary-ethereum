// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./Child.sol";

contract Parent {
    bytes32 public constant CHILD_BYTECODE_KECCAK32 =
        0x3777cc71780224f9113b98623e11e85919892f48d89f0264112bb5be178f2d2e;

    uint256 public nonce;
    uint256 public claimNonce;

    event ChildCreated(address addr);

    function balance() public view returns (uint256) {
        return nonce - claimNonce;
    }

    function claim() public {
        require(claimNonce < nonce, "no remaining balance");
        Child child = Child(computeChild(++claimNonce));
        child.destruct(payable(msg.sender));
    }

    function createChild() public payable {
        assert(msg.value > 0);
        emit ChildCreated(
            address(
                new Child{
                    salt: keccak256(abi.encode(++nonce)),
                    value: msg.value
                }()
            )
        );
    }

    function computeChild(uint256 _nonce) public view returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                address(this),
                                keccak256(abi.encode(_nonce)),
                                CHILD_BYTECODE_KECCAK32
                            )
                        )
                    )
                )
            );
    }

    function k3ccak256(bytes calldata data) public pure returns (bytes32) {
        return keccak256(data);
    }
}