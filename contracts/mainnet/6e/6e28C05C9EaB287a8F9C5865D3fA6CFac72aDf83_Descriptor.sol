// SPDX-License-Identifier: MIT

/// @author notu @notuart

pragma solidity ^0.8.9;

import './interfaces/IDescriptor.sol';
import './Authorizable.sol';

contract Descriptor is IDescriptor, Authorizable {
  Traits public traits;

  constructor() Authorizable() {
    traits = Traits({
      accessories: 17,
      animations: 0,
      backgrounds: 26,
      bodies: 71,
      bottoms: 0,
      ears: 8,
      eyes: 84,
      faces: 53,
      fx: 0,
      heads: 368,
      mouths: 60,
      overlays: 6,
      shoes: 0,
      tops: 95
    });
  }

  // Convenient way to add new traits
  function addTraits(Traits calldata add) external onlyAuthorized {
    traits = Traits({
      accessories: traits.accessories + add.accessories,
      animations: traits.animations + add.animations,
      backgrounds: traits.backgrounds + add.backgrounds,
      bodies: traits.bodies + add.bodies,
      bottoms: traits.bottoms + add.bottoms,
      ears: traits.ears + add.ears,
      eyes: traits.eyes + add.eyes,
      faces: traits.faces + add.faces,
      fx: traits.fx + add.fx,
      heads: traits.heads + add.heads,
      mouths: traits.mouths + add.mouths,
      overlays: traits.overlays + add.overlays,
      shoes: traits.shoes + add.shoes,
      tops: traits.tops + add.tops
    });
  }

  // Override all traits at once
  function udpateTraits(Traits calldata updates) external onlyAuthorized {
    traits = updates;
  }

  function accessoryExists(uint256 id) external view returns (bool) {
    return id < traits.accessories;
  }

  function animationExists(uint256 id) external view returns (bool) {
    return id < traits.animations;
  }

  function backgroundExists(uint256 id) external view returns (bool) {
    return id < traits.backgrounds;
  }

  function bodyExists(uint256 id) external view returns (bool) {
    return id < traits.bodies;
  }

  function bottomExists(uint256 id) external view returns (bool) {
    return id < traits.bottoms;
  }

  function earExists(uint256 id) external view returns (bool) {
    return id < traits.ears;
  }

  function eyeExists(uint256 id) external view returns (bool) {
    return id < traits.eyes;
  }

  function faceExists(uint256 id) external view returns (bool) {
    return id < traits.faces;
  }

  function fxExists(uint256 id) external view returns (bool) {
    return id < traits.fx;
  }

  function headExists(uint256 id) external view returns (bool) {
    return id < traits.heads;
  }

  function mouthExists(uint256 id) external view returns (bool) {
    return id < traits.mouths;
  }

  function overlayExists(uint256 id) external view returns (bool) {
    return id < traits.overlays;
  }

  function shoeExists(uint256 id) external view returns (bool) {
    return id < traits.shoes;
  }

  function topExists(uint256 id) external view returns (bool) {
    return id < traits.tops;
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

interface IDescriptor {
  struct Traits {
    uint256 accessories;
    uint256 animations;
    uint256 backgrounds;
    uint256 bodies;
    uint256 bottoms;
    uint256 ears;
    uint256 eyes;
    uint256 faces;
    uint256 fx;
    uint256 heads;
    uint256 mouths;
    uint256 overlays;
    uint256 shoes;
    uint256 tops;
  }

  function addTraits(Traits calldata add) external;

  function udpateTraits(Traits calldata updates) external;

  function accessoryExists(uint256 id) external view returns (bool);

  function animationExists(uint256 id) external view returns (bool);

  function backgroundExists(uint256 id) external view returns (bool);

  function bodyExists(uint256 id) external view returns (bool);

  function bottomExists(uint256 id) external view returns (bool);

  function earExists(uint256 id) external view returns (bool);

  function eyeExists(uint256 id) external view returns (bool);

  function faceExists(uint256 id) external view returns (bool);

  function fxExists(uint256 id) external view returns (bool);

  function headExists(uint256 id) external view returns (bool);

  function mouthExists(uint256 id) external view returns (bool);

  function overlayExists(uint256 id) external view returns (bool);

  function shoeExists(uint256 id) external view returns (bool);

  function topExists(uint256 id) external view returns (bool);
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