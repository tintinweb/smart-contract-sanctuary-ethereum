// SPDX-License-Identifier: AGPL-3.0-or-later

/// ConstantMultipleValidator.sol

// Copyright (C) 2022 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.0;

struct GenericTriggerData {
    uint256 cdpId;
    uint16 triggerType;
    uint256 execCollRatio;
    uint256 targetCollRatio;
    uint256 bsPrice;
    bool continuous;
    uint64 deviation;
    uint32 maxBaseFeeInGwei;
}

import { RatioUtils } from "../libs/RatioUtils.sol";
import { IValidator } from "../interfaces/IValidator.sol";

contract ConstantMultipleValidator is IValidator {
    using RatioUtils for uint256;

    function decode(bytes[] memory triggerData)
        public
        pure
        returns (uint256[] memory cdpIds, uint256[] memory triggerTypes)
    {
        cdpIds = new uint256[](triggerData.length);
        triggerTypes = new uint256[](triggerData.length);
        for (uint256 i = 0; i < triggerData.length; i++) {
            (cdpIds[i], triggerTypes[i]) = abi.decode(triggerData[i], (uint256, uint16));
        }
    }

    function validate(uint256[] memory replacedTriggerId, bytes[] memory triggersData)
        external
        pure
        returns (bool)
    {
        require(triggersData.length == 2, "validator/wrong-trigger-count");
        (uint256[] memory cdpIds, uint256[] memory triggerTypes) = decode(triggersData);
        require(triggerTypes[0] == 3 && triggerTypes[1] == 4, "validator/wrong-trigger-type");
        require(cdpIds[0] == cdpIds[1], "validator/different-cdps");
        GenericTriggerData memory buyTriggerData = abi.decode(
            triggersData[0],
            (GenericTriggerData)
        );
        GenericTriggerData memory sellTriggerData = abi.decode(
            triggersData[1],
            (GenericTriggerData)
        );
        require(
            (buyTriggerData.continuous == sellTriggerData.continuous) == true,
            "validator/continous-not-true"
        );
        require(
            buyTriggerData.maxBaseFeeInGwei == sellTriggerData.maxBaseFeeInGwei,
            "validator/max-fee-not-equal"
        );
        require(
            buyTriggerData.deviation == sellTriggerData.deviation,
            "validator/deviation-not-equal"
        );
        require(
            buyTriggerData.targetCollRatio == sellTriggerData.targetCollRatio,
            "validator/coll-ratio-not-equal"
        );
        return true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// BasicBuyCommand.sol

// Copyright (C) 2021-2021 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.0;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

library RatioUtils {
    using SafeMath for uint256;

    uint256 public constant RATIO = 10**4;
    uint256 public constant WAD = 10**18;
    uint256 public constant RAY = 10**27;
    uint256 public constant RAD = 10**45;

    // convert base units to ratio
    function toRatio(uint256 units) internal pure returns (uint256) {
        return units.mul(RATIO);
    }

    function wad(uint256 ratio) internal pure returns (uint256) {
        return ratio.mul(WAD).div(RATIO);
    }

    function ray(uint256 ratio) internal pure returns (uint256) {
        return ratio.mul(RAY).div(RATIO);
    }

    function bounds(uint256 ratio, uint64 deviation)
        internal
        pure
        returns (uint256 lower, uint256 upper)
    {
        uint256 offset = ratio.mul(deviation).div(RATIO);
        return (ratio.sub(offset), ratio.add(offset));
    }

    function rayToWad(uint256 _ray) internal pure returns (uint256 _wad) {
        _wad = _ray.mul(WAD).div(RAY);
    }

    function wadToRay(uint256 _wad) internal pure returns (uint256 _ray) {
        _ray = _wad.mul(RAY).div(WAD);
    }

    function radToWad(uint256 _rad) internal pure returns (uint256 _wad) {
        _wad = _rad.mul(WAD).div(RAD);
    }

    function wadToRad(uint256 _wad) internal pure returns (uint256 _rad) {
        _rad = _wad.mul(RAD).div(WAD);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IValidator {
    function validate(uint256[] memory replacedTriggerId, bytes[] memory triggersData)
        external
        view
        returns (bool);

    function decode(bytes[] memory triggersData)
        external
        view
        returns (uint256[] calldata cdpIds, uint256[] calldata triggerTypes);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}