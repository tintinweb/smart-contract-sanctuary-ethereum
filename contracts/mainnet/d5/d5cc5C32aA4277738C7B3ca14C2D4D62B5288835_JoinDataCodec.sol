//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

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

    /// @notice Execute proposition
    /// @param proposition the proposition to enact
    /// @param signatures a set of members EIP712 signatures on `proposition`
    /// @dev Emits `ExecutedTransaction` and `ApprovedHash` (only if `relevantHash` is passed) events
    /// @return successful true if the `proposition`'s transaction executed successfully
    /// @return returnData the data returned from the transaction
    function enactProposition(
        Proposition memory proposition,
        bytes[] memory signatures
    ) external returns (bool successful, bytes memory returnData);

    /// @return true, if the proposition has been enacted
    function isPropositionEnacted(bytes32 propositionHash)
        external
        view
        returns (bool);

    /// @return the maximum amount of value allowed to be transferred out of the contract
    function maxAllowedTransfer() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IWallet} from "../interfaces/IWallet.sol";

/// @author Amit Molek

/// @dev The data needed for `join`
/// This needs to be encoded (you can use `JoinDataCodec`) and be passed to `join`
struct JoinData {
    address member;
    IWallet.Proposition proposition;
    bytes[] signatures;
    /// @dev How much ownership units `member` want to acquire
    uint256 ownershipUnits;
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