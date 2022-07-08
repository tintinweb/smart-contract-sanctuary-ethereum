// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IKYC.sol";
import "./ISubscription.sol";

contract KYC is IKYC {
    error InvalidSubscription();
    error NotAllowed();

    /// Mapping for storing kyc completed addresses
    mapping(address => bool) private _kycList;
    /// Mapping for storing addresses which can call `isKYCPassed`
    mapping(address => bool) private _queryWhitelist;

    address public owner;
    address public kycManager;

    ISubscription public subscription;

    function init(
        address _owner,
        address _subscription,
        address _kycManager
    ) external {
        owner = _owner;
        kycManager = _kycManager;
        subscription = ISubscription(_subscription);

        _queryWhitelist[owner] = true;
    }

    function whitelist(address queryAddress, bool allowed) external {
        if (msg.sender != owner) revert NotAllowed();

        _queryWhitelist[queryAddress] = allowed;
    }

    function addKYCUser(address user) external {
        if (msg.sender != kycManager) revert NotAllowed();

        _kycList[user] = true;
    }

    function addKYCUsers(address[] memory users) external {
        if (msg.sender != kycManager) revert NotAllowed();

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            _kycList[user] = true;
        }
    }

    function isKYCPassed(address user) external view returns (bool result) {
        if (!subscription.isSubscriptionValid(owner)) revert InvalidSubscription();
        if (!_queryWhitelist[msg.sender]) revert NotAllowed();

        result = _kycList[user];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IKYC {
    function init(
        address _owner,
        address _subscription,
        address _kycManager
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ISubscription {
    function getSubscriptionDeadline(address subscriber) external view returns (uint256 deadline);

    function isSubscriptionValid(address subscriber) external view returns (bool result);
}