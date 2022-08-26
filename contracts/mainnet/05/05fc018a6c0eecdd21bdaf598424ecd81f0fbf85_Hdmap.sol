/// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import { Dmap } from './dmap.sol';
import {
  SimpleNameZone,
  SimpleNameZoneFactory
} from "zonefab/SimpleNameZone.sol";
import { Harberger, Perwei } from "./Harberger.sol";
import { ReentrancyGuard } from "./ReentrancyGuard.sol";

struct Deed {
  address controller;
  uint256 collateral;
  uint256 timestamp;
}

// Hdmap as in Harberger dmap
contract Hdmap is ReentrancyGuard {
  Dmap                      public immutable dmap;
  SimpleNameZoneFactory     public immutable zonefab;
  mapping(bytes32=>Deed)    public           deeds;
  uint256                   public immutable numerator    = 1;
  uint256                   public immutable denominator  = 0x1E18558;
  bytes32                          immutable LOCK         = bytes32(uint(0x1));

  error ErrAuthorization();
  error ErrRecipient();
  error ErrValue();

  event Give(
    address indexed giver,
    bytes32 indexed zone,
    address indexed recipient
  );

  constructor() {
    dmap = Dmap(0x90949c9937A11BA943C7A72C3FA073a37E3FdD96);
    zonefab = SimpleNameZoneFactory(0xa964133B1d5b3FF1c4473Ad19bE37b6E2AaDE62b);
  }

  function fiscal(
    bytes32 org
  ) external view returns (uint256 nextPrice, uint256 taxes) {
    Deed memory deed = deeds[org];
    return Harberger.getNextPrice(
      Perwei(numerator, denominator),
      block.timestamp - deed.timestamp,
      deed.collateral
    );
  }

  function assess(bytes32 org) nonReentrant external payable {
    Deed memory deed = deeds[org];
    if (deed.controller == address(0)) {
      deed.collateral = msg.value;
      deed.controller = msg.sender;
      deed.timestamp = block.timestamp;
      deeds[org] = deed;
      dmap.set(org, LOCK, bytes32(bytes20(address(zonefab.make()))));
      emit Give(address(0), org, msg.sender);
    } else {
      (uint256 nextPrice, uint256 taxes) = Harberger.getNextPrice(
        Perwei(numerator, denominator),
        block.timestamp - deed.timestamp,
        deed.collateral
      );

      if (msg.value < nextPrice && deed.controller != msg.sender) {
        revert ErrValue();
      }

      address beneficiary = deed.controller;
      deed.collateral = msg.value;
      deed.controller = msg.sender;
      deed.timestamp= block.timestamp;
      deeds[org] = deed;

      // NOTE: Stakers and beneficiaries must not control the finalization of
      // this function, hence, we're not checking for the calls' success.
      // DONATIONS: Consider donating to dmap://:free.timdaub to help
      // compensate for deployment costs.
      block.coinbase.call{value: taxes}("");
      beneficiary.call{value: nextPrice}("");
      emit Give(beneficiary, org, msg.sender);
    }
  }

  function give(bytes32 org, address recipient) external {
    if (recipient == address(0)) revert ErrRecipient();
    if (deeds[org].controller != msg.sender) revert ErrAuthorization();
    deeds[org].controller = recipient;
    emit Give(msg.sender, org, recipient);
  }

  function lookup(bytes32 org) public view returns (address zone) {
    bytes32 slot = keccak256(abi.encode(address(this), org));
    (, bytes32 data) = dmap.get(slot);
    return address(bytes20(data));
  }

  function read(
    bytes32 org,
    bytes32 key
  ) public view returns (bytes32 meta, bytes32 data) {
    address zone = lookup(org);
    bytes32 slot = keccak256(abi.encode(zone, key));
    return dmap.get(slot);
  }

  function stow(bytes32 org, bytes32 key, bytes32 meta, bytes32 data) external {
    if (deeds[org].controller != msg.sender) revert ErrAuthorization();
    SimpleNameZone z = SimpleNameZone(lookup(org));
    z.stow(key, meta, data);
  }
}

/// SPDX-License-Identifier: AGPL-3.0

// One day, someone is going to try very hard to prevent you
// from accessing one of these storage slots.

pragma solidity 0.8.13;

interface Dmap {
    error LOCKED();
    event Set(
        address indexed zone,
        bytes32 indexed name,
        bytes32 indexed meta,
        bytes32 indexed data
    ) anonymous;

    function set(bytes32 name, bytes32 meta, bytes32 data) external;
    function get(bytes32 slot) external view returns (bytes32 meta, bytes32 data);
}

contract _dmap_ {
    error LOCKED();
    uint256 constant LOCK = 0x1;
    constructor(address rootzone) { assembly {
        sstore(0, LOCK)
        sstore(1, shl(96, rootzone))
    }}
    fallback() external payable { assembly {
        if eq(36, calldatasize()) {
            mstore(0, sload(calldataload(4)))
            mstore(32, sload(add(1, calldataload(4))))
            return(0, 64)
        }
        let name := calldataload(4)
        let meta := calldataload(36)
        let data := calldataload(68)
        mstore(0, caller())
        mstore(32, name)
        let slot := keccak256(0, 64)
        log4(0, 0, caller(), name, meta, data)
        sstore(add(slot, 1), data)
        if iszero(or(xor(100, calldatasize()), and(LOCK, sload(slot)))) {
            sstore(slot, meta)
            return(0, 0)
        }
        if eq(100, calldatasize()) {
            mstore(0, shl(224, 0xa1422f69))
            revert(0, 4)
        }
        revert(0, 0)
    }}
}

/// SPDX-License-Identifier: AGPL-3.0
/// Original credit https://github.com/packzone/packzone
pragma solidity 0.8.13;

interface Dmap {
    error LOCKED();
    event Set(
        address indexed zone,
        bytes32 indexed name,
        bytes32 indexed meta,
        bytes32 indexed data
    ) anonymous;

    function set(bytes32 name, bytes32 meta, bytes32 data) external;
    function get(bytes32 slot) external view returns (bytes32 meta, bytes32 data);
}

contract SimpleNameZone {
    Dmap immutable public dmap;
    address public auth;

    event Give(address indexed giver, address indexed heir);

    error ErrAuth();

    constructor(Dmap _dmap_) {
        dmap = _dmap_;
        auth = msg.sender;
    }

    function stow(bytes32 name, bytes32 meta, bytes32 data) external {
        if (msg.sender != auth) revert ErrAuth();
        dmap.set(name, meta, data);
    }

    function give(address heir) external {
        if (msg.sender != auth) revert ErrAuth();
        auth = heir;
        emit Give(msg.sender, heir);
    }

    function read(bytes32 name) external view returns (bytes32 meta, bytes32 data) {
        bytes32 slot = keccak256(abi.encode(address(this), name));
        (meta, data) = dmap.get(slot);
        return (meta, data);

    }
}

contract SimpleNameZoneFactory {
    Dmap immutable public dmap;
    mapping(address=>bool) public made;

    event Make(address indexed caller, address indexed zone);

    constructor(Dmap _dmap_) {
        dmap = _dmap_;
    }

    function make() payable external returns (SimpleNameZone) {
        SimpleNameZone zone = new SimpleNameZone(dmap);
        made[address(zone)] = true;
        zone.give(msg.sender);
        emit Make(msg.sender, address(zone));
        return zone;
    }
}

/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.6;

import {FixedPointMathLib} from "./FixedPointMathLib.sol";

/* Introduction of "Perwei" struct:

  To ensure accounting precision, financial and scientific applications make
  use of a so called "parts-per" notation and so it turns out that: "One part
  per hundred is generally represented by the percent sign (%)" [1].

  But with Solidity and Ethereum having a precision of up to 18 decimal points
  but no native fixed point math arithmetic functions, we have to be careful
  when e.g. calculating fractions of a value.

  E.g. in cases where we want to calculate the tax of a property that's worth
  only 1000 Wei (= 0.000000000000001 Ether) using naive percentages leads to
  inaccuracies when dealing with Solidity's division operator. Hence, libraries
  like solmate and others have come up with "parts-per"-ready implementations
  where values are scaled up. The `Perwei` struct here represents a structure
  of numerator and denominator that allows precise calculations of up to 18
  decimals in the results, e.g. Perwei(1, 1e18).

  References:
  - 1:
https://en.wikipedia.org/w/index.php?title=Parts-per_notation&oldid=1068959843

*/
struct Perwei {
  uint256 numerator;
  uint256 denominator;
}

library Harberger {
  function getNextPrice(
    Perwei memory perwei,
    uint256 blockDiff,
    uint256 collateral
  ) internal pure returns (uint256, uint256) {
    uint256 taxes = taxPerBlock(perwei, blockDiff, collateral);
    int256 diff = int256(collateral) - int256(taxes);

    if (diff <= 0) {
      return (0, collateral);
    } else {
      return (uint256(diff), taxes);
    }
  }

  function taxPerBlock(
    Perwei memory perwei,
    uint256 blockDiff,
    uint256 collateral
  ) internal pure returns (uint256) {
    return FixedPointMathLib.fdiv(
      collateral * blockDiff * perwei.numerator,
      perwei.denominator * FixedPointMathLib.WAD,
      FixedPointMathLib.WAD
    );
  }
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                            COMMON BASE UNITS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant YAD = 1e8;
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RAD = 1e45;

    /*///////////////////////////////////////////////////////////////
                         FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // If baseUnit is zero this will return zero instead of reverting.
            z := div(z, baseUnit)
        }
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * baseUnit in z for now.
            z := mul(x, baseUnit)

            // Equivalent to require(y != 0 && (x == 0 || (x * baseUnit) / x == baseUnit))
            if iszero(and(iszero(iszero(y)), or(iszero(x), eq(div(z, x), baseUnit)))) {
                revert(0, 0)
            }

            // We ensure y is not zero above, so there is never division by zero here.
            z := div(z, y)
        }
    }

    function fpow(
        uint256 x,
        uint256 n,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := baseUnit
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store baseUnit in z for now.
                    z := baseUnit
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, baseUnit)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, baseUnit)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, baseUnit)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z)
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z)
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z)
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z)
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z)
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z)
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}