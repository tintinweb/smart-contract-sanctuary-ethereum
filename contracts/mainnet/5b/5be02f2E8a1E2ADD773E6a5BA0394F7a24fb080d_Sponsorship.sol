// SPDX-License-Identifier: MIT

/// @author notu @notuart

pragma solidity ^0.8.9;

import './interfaces/ISponsorship.sol';
import './Authorizable.sol';

contract Sponsorship is ISponsorship, Authorizable {
  /// Mapping from token ID to number of sponsorships given
  mapping(uint256 => uint256) public scores;

  /// Mapping from beneficiary to sponsor token ID
  mapping(uint256 => uint256) public sponsors;

  /// Amount of souls sponsored by this address
  function scoreOf(uint256 tokenId) public view returns (uint256) {
    return scores[tokenId];
  }

  /// Retrieve the sponsor for a given token ID
  function sponsorOf(uint256 tokenId) public view returns (uint256) {
    return sponsors[tokenId];
  }

  /// Adds a new sponsorship
  function create(uint256 sponsor, uint256 recipient) public onlyAuthorized {
    if (sponsor > 0) {
      scores[sponsor] += 1;
      sponsors[recipient] = sponsor;
    }
  }
}

// SPDX-License-Identifier: CC0

/// @author notu @notuart

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './interfaces/IAuthorizable.sol';

contract Authorizable is IAuthorizable, ReentrancyGuard {
  mapping(address => bool) public authorized;

  modifier onlyAuthorized() {
    if (authorized[msg.sender] == false) {
      revert Unauthorized();
    }
    _;
  }

  constructor() {
    authorized[msg.sender] = true;
  }

  function grantAuthorization(
    address account
  ) public onlyAuthorized nonReentrant {
    authorized[account] = true;
  }

  function revokeAuthorization(
    address account
  ) public onlyAuthorized nonReentrant {
    authorized[account] = false;
  }
}

// SPDX-License-Identifier: MIT

/// @author notu @notuart

pragma solidity ^0.8.9;

interface ISponsorship {
  /// Amount of souls sponsored by this address
  function scoreOf(uint256 tokenId) external view returns (uint256);

  /// Retrieve the sponsor for a given token ID
  function sponsorOf(uint256 tokenId) external view returns (uint256);

  /// Adds a new sponsorship
  function create(uint256 sponsor, uint256 recipient) external;
}

// SPDX-License-Identifier: MIT

/// @author notu @notuart

pragma solidity ^0.8.9;

interface IAuthorizable {
  error Unauthorized();

  function grantAuthorization(address account) external;

  function revokeAuthorization(address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}