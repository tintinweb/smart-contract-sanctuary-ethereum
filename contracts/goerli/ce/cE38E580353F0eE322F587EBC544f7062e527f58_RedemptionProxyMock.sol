// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../interfaces/IRedemptionProxy.sol";

contract RedemptionProxyMock is IRedemptionProxy {
    mapping(address => mapping(uint256 => bool)) _redemptions;
    mapping(address => mapping(uint256 => bool)) _claims;

    function setRedeem(
        address addr,
        uint256 contribtionId,
        bool value
    ) public {
        _redemptions[addr][contribtionId] = value;
    }

    function canRedeem(address addr, uint256 contribtionId)
        external
        view
        override
        returns (bool)
    {
        return _redemptions[addr][contribtionId];
    }

    function setClaims(
        address addr,
        uint256 contribtionId,
        bool value
    ) public {
        _claims[addr][contribtionId] = value;
    }

    function canClaim(address addr, uint256 contributionId)
        external
        view
        override
        returns (bool)
    {
        return _claims[addr][contributionId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IRedemptionProxy {
    function canRedeem(address addr, uint256 contribtionId)
        external
        view
        returns (bool);

    function canClaim(
        address addr,
        uint256 contributionId
    ) external view returns (bool);
}