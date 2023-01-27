// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(
        address indexed user,
        address indexed newOwner
    );

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(
        address newOwner
    ) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IReputation {
    function limiter(
        uint256 _userCredit
    ) external pure returns (uint256 _spendLimit);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import { IReputation } from "./lib/interfaces/IReputation.sol";
import { Owned } from "./lib/auth/Owned.sol";

contract Reputation is IReputation, Owned(msg.sender) {
    /// @dev Asymptote numerator constant value for the `limiter` fx.
    uint256 public constant maxLimit = 1e6;
    /// @dev Denominator's constant operand for the `limiter` fx.
    uint256 public constant magicValue = 2.5e11;

    // prettier-ignore
    // solhint-disable no-inline-assembly
    // solhint-disable-next-line no-empty-blocks
    constructor(/*  */) {/*  */}

    function limiter(
        uint256 _userCredit
    )
        external
        pure
        override(IReputation)
        returns (uint256 _spendLimit)
    {
        _spendLimit = (1 +
            ((maxLimit * _userCredit) /
                sqrt(
                    magicValue + (_userCredit * _userCredit)
                )));
    }

    /// @notice Taken from Solmate's FixedPointMathLib.
    /// (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
    function sqrt(
        uint256 x
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(
                lt(y, 0x10000000000000000000000000000000000)
            ) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            z := sub(z, lt(div(x, z), z))
        }
    }
}