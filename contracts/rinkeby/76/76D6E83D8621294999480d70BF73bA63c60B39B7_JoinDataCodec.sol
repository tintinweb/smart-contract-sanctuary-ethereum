//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Multisig wallet interface
/// @author Amit Molek
interface IWallet {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
    }

    struct Proposition {
        /// @dev Proposition's deadline
        uint256 endsAt;
        /// @dev Proposed transaction to execute
        Transaction tx;
        /// @dev can be useful if your `transaction` needs an accompanying hash.
        /// For example in EIP1271 `isValidSignature` function.
        /// Note: Pass zero hash (0x0) if you don't need this.
        bytes32 relevantHash;
    }

    /// @dev Emitted on proposition execution
    /// @param hash the transaction's hash
    /// @param value the value passed with `transaction`
    /// @param successful is the transaction were successfully executed
    event ExecutedTransaction(
        bytes32 indexed hash,
        uint256 value,
        bool successful
    );

    /// @dev Emitted on approved hash
    /// @param hash the approved hash
    event ApprovedHash(bytes32 hash);

    /// @return true if the hash has been approved
    function isHashApproved(bytes32 hash) external view returns (bool);

    /// @notice Execute proposition
    /// @param proposition the proposition to enact
    /// @param signatures a set of members EIP712 signatures on `proposition`
    /// @dev Emits `ExecutedTransaction` and `ApprovedHash` (only if `relevantHash` is passed) events
    function enactProposition(
        Proposition memory proposition,
        bytes[] memory signatures
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IWallet} from "../interfaces/IWallet.sol";

/// @author Amit Molek

/// @dev The data needed for `join`
/// This needs to be encoded (you can use `JoinDataCodec`) and be passed to `join`
struct JoinData {
    address member;
    IWallet.Proposition proposition;
    bytes[] signatures;
}

/// @dev Codec for `JoinData`
contract JoinDataCodec {
    function encode(JoinData memory joinData)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode(joinData);
    }

    function decode(bytes memory data) external pure returns (JoinData memory) {
        return abi.decode(data, (JoinData));
    }
}