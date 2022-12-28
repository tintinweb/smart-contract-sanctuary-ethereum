// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (C) 2022 Spanning Labs Inc.
pragma solidity ^0.8.2;

import "./ISpanningDelegate.sol";

/**
 * DomainServer provides a delegate interface that correctly
 * returns a given operational domain. It has pass throughs or
 * no-ops for typical SpanningDelegate functionality.
 */
contract DomainServer is ISpanningDelegate {
    // A unique identifier for the delegate.
    bytes4 private domain_;

    /**
     * @dev Initializes a Domain Server.
     *
     * @param domain - Unique identifier for the delegate
     */
    constructor(bytes4 domain) {
        domain_ = domain;
    }

    /**
     * @return bytes4 - Domain of the delegate.
     */
    function getDomain() public view override returns (bytes4) {
        return domain_;
    }

    modifier domainServerOnly() {
        require(false, "Domain Server Only");
        _;
    }

    /**
     * @dev No-op
     */
    function makeDeployable() external pure override domainServerOnly {
        return;
    }

    /**
     * @dev No-op
     */
    function revokeDeployable() external pure override domainServerOnly {
        return;
    }

    /**
     * @return bool - Deployable status of the domain server is always false
     */
    function isDeployable() external pure override returns (bool) {
        return false;
    }

    /**
     * @return bool - Domain server never has valid message data
     */
    function isValidData() external pure override returns (bool) {
        return false;
    }

    /**
     * @return bytes32 - no-op
     */
    function currentSenderAddress()
        external
        pure
        override
        returns (bytes32)
    {
        return bytes32(0);
    }

    /**
     * @return bytes32 - no-op
     */
    function currentTxnSenderAddress()
        external
        pure
        override
        returns (bytes32)
    {
        return bytes32(0);
    }

    /**
     * @dev No-op
     */
    function spanningCall(
        bytes32,
        bytes32,
        bytes32,
        bytes calldata
    ) external pure override domainServerOnly {
        return;
    }

    /**
     * @dev No-op
     */
    function makeRequest(bytes32, bytes calldata)
        external
        pure
        override
        domainServerOnly
    {
        return;
    }
}