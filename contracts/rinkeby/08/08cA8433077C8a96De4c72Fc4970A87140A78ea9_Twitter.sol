// SPDX-License-Identifier: CC-PDDC
pragma solidity ^0.8.13;

import "Registry.sol";
import "Oracle.sol";

contract Twitter is Registry, Oracle {
    // Mapping of resolver to Twitter handle to wallet address
    mapping(address => mapping(bytes32 => address)) private records;

    // Mapping of Oracle address to price in wei
    mapping(address => uint256) private oraclePrices;

    /// Submits a payment to an oracle to run a verification job
    /// @param resolver - the address of the oracle
    /// @param tweetId - bytes32 encoded unique tweet ID that contains a proof
    function submit(address resolver, bytes32 tweetId)
        external
        payable
        virtual
    {
        if (msg.value < oraclePrices[resolver]) revert ErrorOracleFeeTooLow();
        payable(resolver).transfer(msg.value);
        emit SubmitProof(resolver, tweetId, msg.sender);
    }

    /// Submit a dispute for a Twitter handle
    /// @param resolver - the address of the Oracle that resolved the Twitter handle
    /// @param twitterHandle - the Twitter @ username to dispute
    function dispute(address resolver, bytes32 twitterHandle)
        external
        payable
        virtual
    {
        if (msg.value < oraclePrices[resolver]) revert ErrorOracleFeeTooLow();
        payable(resolver).transfer(msg.value);
        emit SubmitDispute(resolver, twitterHandle);
    }

    /// Resolves a Twitter handle to a wallet address
    /// @param resolver - the address of the Oracle that resolved the Twitter handle
    /// @param twitterHandle - the Twitter @ username to resolve
    /// @return ownerAddress - the address the Twitter handle belongs to (or 0x0 if none)
    function resolve(address resolver, bytes32 twitterHandle)
        external
        view
        virtual
        returns (address ownerAddress)
    {
        return records[resolver][twitterHandle];
    }

    /// Called by the oracle after it verifies multiple tweets
    /// @param twitterHandles - the Twitter handles to be verified
    /// @param owners - the addresses which were verified for the handles
    function batchVerify(
        bytes32[] memory twitterHandles,
        address[] memory owners
    ) external virtual {
        if (twitterHandles.length != owners.length)
            revert BatchParamLengthNotMatching();
        unchecked {
            uint256 index = 0;
            do {
                records[msg.sender][twitterHandles[index]] = owners[index];
                emit Verified(msg.sender, owners[index], twitterHandles[index]);
                index++;
            } while (index != twitterHandles.length);
        }
    }

    /// Called by the oracle after it verifies a tweet
    /// @param twitterHandle - the Twitter @ username to verify
    /// @param owner - the address the Twitter handle belongs to (or 0x0 if none)
    function verify(bytes32 twitterHandle, address owner) external virtual {
        records[msg.sender][twitterHandle] = owner;
        emit Verified(msg.sender, owner, twitterHandle);
    }

    /// Called by the oracle to set the price of a verification job
    function setOraclePrice(uint256 priceInWei) external virtual {
        oraclePrices[msg.sender] = priceInWei;
    }
}

// SPDX-License-Identifier: CC-PDDC
pragma solidity ^0.8.0;

/// @title Aces and Eights Registry Interface
/// @author hexcowboy <cowboy.dev>
interface Registry {
    /// Logged when an account has requested verification
    /// @param oracle - the address of the resolver oracle
    /// @param proof - the unique identifier to prove
    /// @param requester - the address which submitted the proof
    event SubmitProof(
        address indexed oracle,
        bytes32 indexed proof,
        address indexed requester
    );

    /// Logged when someone disputes the ownership of an address's connected account
    /// @param owner the address of the owner being disputed
    /// @param (2) - the account ID, username, or unique identifier of the account being disputed
    event SubmitDispute(address indexed owner, bytes32 indexed);

    /// Given data, an oracle should be able to use it to verify an external account
    /// @param resolver - the address of the resolver oracle
    /// @param proof - the object data to verify
    ///  Examples include:
    ///   - Twitter: The ID of the Tweet
    ///   - Instagram: The alphanumeric post ID
    /// @notice check your registry's implementation to understand what kind of data to pass as parameters
    function submit(address resolver, bytes32 proof) external payable;

    /// A connection can be disputed if the caller pays the oracle to audit it
    ///  Cases include:
    ///   - An account is banned
    ///   - An account removes their verification post
    ///   - An account's name has changed
    /// @param resolver - the address of the resolver oracle
    /// @param (2) - the account ID, username, or unique identifier that is being disputed
    /// @notice check your registry's implementation to understand what kind of data to pass as parameters
    function dispute(address resolver, bytes32) external payable;

    /// Resolves a record to a wallet (or contract) address
    /// @param resolver - the address of the resolver oracle
    /// @param (2) - the identifier to verify
    ///  Examples include:
    ///   - The username of a verified account
    function resolve(address resolver, bytes32) external view returns (address);
}

// SPDX-License-Identifier: CC-PDDC
pragma solidity ^0.8.0;

/// @title Aces and Eights Oracle Interface
/// @author hexcowboy <cowboy.dev>
interface Oracle {
    error ErrorOracleFeeTooLow();
    error BatchParamLengthNotMatching();

    /// Logged when an account has requested verification
    /// @param resolver - the oracle that resolved the account
    /// @param owner - the address of the owner that was verified
    /// @param (2) the identity that was linked to the owner
    ///  Examples include:
    ///   - Twitter: The @ username of the owner
    event Verified(
        address indexed resolver,
        address indexed owner,
        bytes32 indexed
    );

    /// Verifies an object, usually updating records in a Registry contract
    /// @param proof - the object to be verified
    ///  Examples include:
    ///   - Twitter: The @ username of the owner
    /// @param owner - the address which was verified for the object
    function verify(bytes32 proof, address owner) external;

    /// Verifies an object, usually updating records in a Registry contract
    /// @notice - the array agrument lengths must match
    /// @notice - the array elements must correspend to the same index
    /// @param (1) - the objects to be verified
    ///  Examples include:
    ///   - Twitter: The @ username of the owner
    /// @param owners - the addresses which were verified for the objects
    function batchVerify(bytes32[] memory, address[] memory owners) external;

    /// Sets the price in wei for a verification job
    /// @param priceInWei - the desired price in wei
    function setOraclePrice(uint256 priceInWei) external;
}