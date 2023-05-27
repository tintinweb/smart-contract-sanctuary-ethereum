// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import {CommonErrors} from "./Errors.sol";

/// @title Auth
contract Auth {

    /// @dev Emitted when the Golem Foundation multisig address is set.
    /// @param oldValue The old Golem Foundation multisig address.
    /// @param newValue The new Golem Foundation multisig address.
    event MultisigSet(address oldValue, address newValue);

    /// @dev Emitted when the deployer address is set.
    /// @param oldValue The old deployer address.
    event DeployerRenounced(address oldValue);

    /// @dev The deployer address.
    address public deployer;

    /// @dev The multisig address.
    address public multisig;

    /// @param _multisig The initial Golem Foundation multisig address.
    constructor(address _multisig) {
        multisig = _multisig;
        deployer = msg.sender;
    }

    /// @dev Sets the multisig address.
    /// @param _multisig The new multisig address.
    function setMultisig(address _multisig) external {
        require(msg.sender == multisig, CommonErrors.UNAUTHORIZED_CALLER);
        emit MultisigSet(multisig, _multisig);
        multisig = _multisig;
    }

    /// @dev Leaves the contract without a deployer. It will not be possible to call
    /// `onlyDeployer` functions. Can only be called by the current deployer.
    function renounceDeployer() external {
        require(msg.sender == deployer, CommonErrors.UNAUTHORIZED_CALLER);
        emit DeployerRenounced(deployer);
        deployer = address(0);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

library AllocationErrors {
    /// @notice Thrown when the user trying to allocate before first epoch has started
    /// @return HN:Allocations/not-started-yet
    string public constant EPOCHS_HAS_NOT_STARTED_YET =
        "HN:Allocations/first-epoch-not-started-yet";

    /// @notice Thrown when the user trying to allocate after decision window is closed
    /// @return HN:Allocations/decision-window-closed
    string public constant DECISION_WINDOW_IS_CLOSED =
        "HN:Allocations/decision-window-closed";

    /// @notice Thrown when user trying to allocate more than he has in rewards budget for given epoch.
    /// @return HN:Allocations/allocate-above-rewards-budget
    string public constant ALLOCATE_ABOVE_REWARDS_BUDGET =
        "HN:Allocations/allocate-above-rewards-budget";

    /// @notice Thrown when user trying to allocate to a proposal that does not exist.
    /// @return HN:Allocations/no-such-proposal
    string public constant ALLOCATE_TO_NON_EXISTING_PROPOSAL =
        "HN:Allocations/no-such-proposal";
}

library OracleErrors {
    /// @notice Thrown when trying to set the balance in oracle for epochs other then previous.
    /// @return HN:Oracle/can-set-balance-for-previous-epoch-only
    string public constant CANNOT_SET_BALANCE_FOR_PAST_EPOCHS =
        "HN:Oracle/can-set-balance-for-previous-epoch-only";

    /// @notice Thrown when trying to set the balance in oracle when balance can't yet be determined.
    /// @return HN:Oracle/can-set-balance-at-earliest-in-second-epoch
    string public constant BALANCE_CANT_BE_KNOWN =
        "HN:Oracle/can-set-balance-at-earliest-in-second-epoch";

    /// @notice Thrown when trying to set the oracle balance multiple times.
    /// @return HN:Oracle/balance-for-given-epoch-already-exists
    string public constant BALANCE_ALREADY_SET =
        "HN:Oracle/balance-for-given-epoch-already-exists";

    /// @notice Thrown if contract is misconfigured
    /// @return HN:Oracle/WithdrawalsTarget-not-set
    string public constant NO_TARGET =
        "HN:Oracle/WithdrawalsTarget-not-set";

    /// @notice Thrown if contract is misconfigured
    /// @return HN:Oracle/PayoutsManager-not-set
    string public constant NO_PAYOUTS_MANAGER =
        "HN:Oracle/PayoutsManager-not-set";

}

library DepositsErrors {
    /// @notice Thrown when transfer operation fails in GLM smart contract.
    /// @return HN:Deposits/cannot-transfer-from-sender
    string public constant GLM_TRANSFER_FAILED =
        "HN:Deposits/cannot-transfer-from-sender";

    /// @notice Thrown when trying to withdraw more GLMs than are in deposit.
    /// @return HN:Deposits/deposit-is-smaller
    string public constant DEPOSIT_IS_TO_SMALL =
        "HN:Deposits/deposit-is-smaller";
}

library EpochsErrors {
    /// @notice Thrown when calling the contract before the first epoch started.
    /// @return HN:Epochs/not-started-yet
    string public constant NOT_STARTED = "HN:Epochs/not-started-yet";

    /// @notice Thrown when updating epoch props to invalid values (decision window bigger than epoch duration.
    /// @return HN:Epochs/decision-window-bigger-than-duration
    string public constant DECISION_WINDOW_TOO_BIG = "HN:Epochs/decision-window-bigger-than-duration";
}

library TrackerErrors {
    /// @notice Thrown when trying to get info about effective deposits in future epochs.
    /// @return HN:Tracker/future-is-unknown
    string public constant FUTURE_IS_UNKNOWN = "HN:Tracker/future-is-unknown";

    /// @notice Thrown when trying to get info about effective deposits in epoch 0.
    /// @return HN:Tracker/epochs-start-from-1
    string public constant EPOCHS_START_FROM_1 =
        "HN:Tracker/epochs-start-from-1";
}

library PayoutsErrors {
    /// @notice Thrown when trying to register more funds than possess.
    /// @return HN:Payouts/registering-withdrawal-of-unearned-funds
    string public constant REGISTERING_UNEARNED_FUNDS =
        "HN:Payouts/registering-withdrawal-of-unearned-funds";
}

library ProposalsErrors {
    /// @notice Thrown when trying to change proposals that could already have been voted upon.
    /// @return HN:Proposals/only-future-proposals-changing-is-allowed
    string public constant CHANGING_PROPOSALS_IN_THE_PAST =
        "HN:Proposals/only-future-proposals-changing-is-allowed";
}

library CommonErrors {
    /// @notice Thrown when trying to call as an unauthorized account.
    /// @return HN:Common/unauthorized-caller
    string public constant UNAUTHORIZED_CALLER =
        "HN:Common/unauthorized-caller";
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import {CommonErrors} from "./Errors.sol";
import "./Auth.sol";

/// @title OctantBase
/// @dev This is the base contract for all Octant contracts that have functions with access restricted
/// to deployer or the Golem Foundation multisig.
/// It provides functionality for setting and accessing the Golem Foundation multisig address.
abstract contract OctantBase {

    /// @dev The Auth contract instance
    Auth auth;

    /// @param _auth the contract containing Octant authorities.
    constructor(address _auth) {
        auth = Auth(_auth);
    }

    /// @dev Gets the Golem Foundation multisig address.
    function getMultisig() internal view returns (address) {
        return auth.multisig();
    }

    /// @dev Modifier that allows only the Golem Foundation multisig address to call a function.
    modifier onlyMultisig() {
        require(msg.sender == auth.multisig(), CommonErrors.UNAUTHORIZED_CALLER);
        _;
    }

    /// @dev Modifier that allows only deployer address to call a function.
    modifier onlyDeployer() {
        require(msg.sender == auth.deployer(), CommonErrors.UNAUTHORIZED_CALLER);
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/IProposals.sol";
import "./interfaces/IEpochs.sol";

import {ProposalsErrors} from "./Errors.sol";
import "./OctantBase.sol";

/// @notice Contract tracking active Octant proposals in particular epoch.
/// Proposals are stored in IPFS in JSON format and are maintained entirely by Golem Foundation.
/// In order to get proposal details from IPFS call use returned values as this:
/// https://<IPFS Gateway of your choice>/ipfs/<CID>/<Proposal address>
// example: https://ipfs.io/ipfs/Qmbm97crHWQzNYNn2LPZ5hhGu4qEv1DXRP6qS4TCehruPn/1
contract Proposals is OctantBase, IProposals {
    /// @notice IPFS CID (Content identifier).
    /// Under this CID will be placed a directory with all the proposals,
    /// currently active and inactive.
    string public cid;

    IEpochs public epochs;

    mapping(uint256 => address[]) private proposalAddressesByEpoch;

    /// @notice mapping that stores account authorized to withdraw funds on behalf of the proposal.
    /// This is additional account, main proposal account is also eligible to withdraw.
    mapping(address => address) private authorizedAccountByProposal;

    constructor(
        address _epochs,
        string memory _initCID,
        address[] memory proposals,
        address _auth
    ) OctantBase(_auth) {
        epochs = IEpochs(_epochs);
        cid = _initCID;
        proposalAddressesByEpoch[0] = proposals;
    }

    /// @notice sets a new IPFS CID, where proposals are stored.
    function setCID(string memory _newCID) public onlyMultisig {
        cid = _newCID;
    }

    /// @notice sets proposal addresses that will be active in the particular epoch.
    /// Addresses should be provided as an array and will represent JSON file names stored under CID provided
    /// to this contract.
    function setProposalAddresses(
        uint256 _epoch,
        address[] calldata _proposalAddresses
    ) public onlyMultisig {
        require(_epoch >= epochs.getCurrentEpoch(), ProposalsErrors.CHANGING_PROPOSALS_IN_THE_PAST);
        proposalAddressesByEpoch[_epoch] = _proposalAddresses;
    }

    /// @return list of active proposal addresses in given epoch.
    function getProposalAddresses(
        uint256 _epoch
    ) public view returns (address[] memory) {
        for (uint256 iEpoch = _epoch; iEpoch > 0; iEpoch = iEpoch - 1) {
            if (proposalAddressesByEpoch[iEpoch].length > 0) {
                return proposalAddressesByEpoch[iEpoch];
            }
        }
        return proposalAddressesByEpoch[0];
    }

    /// @dev Returns whether the account is authorized for the given proposal.
    /// @param proposal The proposal to check authorization for.
    /// @param account The account to check authorization for.
    /// @return True if the account is authorized for the proposal, false otherwise.
    function isAuthorized(address proposal, address account) public view returns (bool) {
        return proposal == account || authorizedAccountByProposal[proposal] == account;
    }

    /// @dev Sets the authorized account for the given proposal.
    /// @param proposal The proposal to set the authorized account for.
    /// @param account The account to authorize for the proposal.
    /// @notice Only the owner of the contract can call this function.
    function setAuthorizedAccount(address proposal, address account) external onlyMultisig {
        authorizedAccountByProposal[proposal] = account;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IEpochs {
    function getCurrentEpoch() external view returns (uint32);

    function getEpochDuration() external view returns (uint256);

    function getDecisionWindow() external view returns (uint256);

    function isStarted() external view returns (bool);

    function isDecisionWindowOpen() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IProposals {

    function getProposalAddresses(
        uint256 _epoch
    ) external view returns (address[] memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IRewards {
    function individualReward(
        uint32 epoch,
        address user
    ) external view returns (uint256);

    function claimableReward(
        uint32 epoch,
        address user
    ) external view returns (uint256);

    function proposalReward(
        uint32 epoch,
        address proposal
    ) external view returns (uint256);

    function golemFoundationReward(
        uint32 epoch
    ) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IWithdrawalsTarget {
    function withdrawToVault(uint256) external;
    function withdrawToMultisig(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "../interfaces/IEpochs.sol";
import "../interfaces/IRewards.sol";

import {PayoutsErrors, CommonErrors} from "../Errors.sol";
import "../OctantBase.sol";

/// @title Contract tracking ETH payouts for Octant project.
/// @author Golem Foundation
contract Payouts is OctantBase {
    IRewards public immutable rewards;
    IEpochs public immutable epochs;
    address public payoutsManager;

    enum Payee { User, Proposal, GolemFoundation }

    struct Payout {
        // packed into two 32 byte slots
        // 16 bits is enough to store amount of ETH
        /// @dev last checkpointed epoch (=> funds from the epoch are are withdrawn)
        uint32 checkpointEpoch; // 32
        /// @dev total ETH payout by the end of checkpointed epoch, in wei
        uint144 checkpointSum; // 128+16
        /// @dev any extra ETH payout, less than required to checkpoint next epoch, in wei
        uint144 extra; // 128+16
        /// @dev total ETH payout, in wei
        uint144 total; // 128+16
    }

    /// @dev tracks ETH payouts to GLM stakers, proposals and Golem Foundation
    mapping(address => Payout) public payouts;

    constructor(
        address rewardsAddress,
        address epochsAddress,
        address _auth)
    OctantBase(_auth) {
        rewards = IRewards(rewardsAddress);
        epochs = IEpochs(epochsAddress);
    }

    /// @param payeeAddress address of a payee (user, proposal, of Golem Foundation)
    /// @param amount Payout amount
    function registerPayout(
        Payee payee,
        address payeeAddress,
        uint144 amount
    ) public onlyPayoutsManager {
        uint32 finalizedEpoch = getFinalizedEpoch();
        Payout memory p = payouts[payeeAddress];
        uint144 remaining = amount;
        bool stop = false;
        while (!stop) {
            uint144 stepFunds = uint144(
                _getRewards(payee, p.checkpointEpoch + 1, payeeAddress)
            );
            if (p.extra + remaining > stepFunds) {
                remaining = remaining - (stepFunds - p.extra);
                p.checkpointEpoch = p.checkpointEpoch + 1;
                require(
                    p.checkpointEpoch <= finalizedEpoch,
                    PayoutsErrors.REGISTERING_UNEARNED_FUNDS
                );
                p.checkpointSum = p.checkpointSum + stepFunds;
                p.extra = 0;
            } else {
                stop = true;
                p.extra = p.extra + remaining;
                p.total = p.total + amount;
                assert(p.total == p.checkpointSum + p.extra);
            }
        }
        payouts[payeeAddress] = p;
    }

    function payoutStatus(
        address user
    ) external view returns (Payout memory) {
        return payouts[user];
    }


    function setPayoutsManager(address _payoutsManager) public onlyDeployer {
        require(payoutsManager == address(0x0), "HN/Payouts:already-initialized");
        payoutsManager = _payoutsManager;
    }

    /// @dev returns most recent epoch from which funds can be spent
    function getFinalizedEpoch() public view returns (uint32) {
        if (epochs.isDecisionWindowOpen()) {
            return epochs.getCurrentEpoch() - 2;
        }
        else {
            return epochs.getCurrentEpoch() - 1;
        }
    }

    function withdrawableUserETH(address payeeAddress) external view returns (uint144) {
        return withdrawableETH(Payee.User, payeeAddress);
    }

    function withdrawableProposalETH(address payeeAddress) public view returns (uint144) {
        return withdrawableETH(Payee.Proposal, payeeAddress);
    }

    function withdrawableGolemFoundationETH(address payeeAddress) public view returns (uint144) {
        return withdrawableETH(Payee.GolemFoundation, payeeAddress);
    }

    function withdrawableETH(Payee payee, address payeeAddress) private view returns (uint144) {
        uint144 available;
        Payout memory p = payouts[payeeAddress];
        uint32 finalizedEpoch = getFinalizedEpoch();
        for (uint32 i = p.checkpointEpoch; i <= finalizedEpoch; i++) {
            uint144 stepFunds = uint144(_getRewards(payee, i, payeeAddress));
            available = available + stepFunds;
        }
        return available - p.extra;
    }

    function _getRewards(Payee payee, uint32 epoch, address payeeAddress) private view returns (uint256) {
        if (payee == Payee.User) {
            return rewards.claimableReward(epoch, payeeAddress);
        } else if (payee == Payee.Proposal) {
            return rewards.proposalReward(epoch, payeeAddress);
        } else if (payee == Payee.GolemFoundation) {
            return rewards.golemFoundationReward(epoch);
        } else {
            revert();
        }
    }

    modifier onlyPayoutsManager() {
        require(
            msg.sender == payoutsManager,
            CommonErrors.UNAUTHORIZED_CALLER
        );
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./../interfaces/IWithdrawalsTarget.sol";

import "./Payouts.sol";
import "../Proposals.sol";
import "../OctantBase.sol";

import {PayoutsErrors, CommonErrors} from "../Errors.sol";

/// @title Contract triggering ETH payouts for Octant project.
/// @author Golem Foundation
contract PayoutsManager is OctantBase {
    Payouts public immutable payouts;
    Proposals public proposals;

    event ETHWithdrawal(Payouts.Payee payee, address owner, uint224 amount);

    constructor(
        address _payoutsAddress,
        address _proposalsAddress,
        address _auth)
    OctantBase(_auth) {
        payouts = Payouts(_payoutsAddress);
        proposals = Proposals(_proposalsAddress);
    }

    function withdrawUser(uint144 amount) external {
        _withdraw(Payouts.Payee.User, payable(msg.sender), amount);
    }

    function withdrawProposal(address proposalAddress, uint144 amount) external {
        require(proposals.isAuthorized(msg.sender, proposalAddress), CommonErrors.UNAUTHORIZED_CALLER);
        _withdraw(Payouts.Payee.Proposal, payable(proposalAddress), amount);
    }

    function withdrawGolemFoundation(uint144 amount) external onlyMultisig {
        address multisig = super.getMultisig();
        _withdraw(Payouts.Payee.GolemFoundation, payable(multisig), amount);
    }

    function emergencyWithdraw(uint144 amount) external onlyMultisig {
        address multisig = super.getMultisig();
        payable(multisig).transfer(amount);
    }

    function _withdraw(Payouts.Payee payee, address payable payeeAddress, uint144 amount) private {
        payouts.registerPayout(payee, payeeAddress, amount);
        payeeAddress.transfer(amount);

        emit ETHWithdrawal(payee, payeeAddress, amount);
    }

    receive() external payable {
        /* do not add any code here, it will get reverted because of tiny gas stipend */
    }
}