/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)



/**
 * @dev String operations.
 */
library CustomStrings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * Edited from OpenZeppelin's implementation
     * Returns hex string without leading 0x
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length);

        for (uint256 i = 2 * length; i > 0; --i) {
            buffer[i - 1] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }

        return string(buffer);
    }
}
// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    function timestampFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    // function timestampToDateTime(uint256 timestamp)
    //     internal
    //     pure
    //     returns (
    //         uint256 year,
    //         uint256 month,
    //         uint256 day,
    //         uint256 hour,
    //         uint256 minute,
    //         uint256 second
    //     )
    // {
    //     (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    //     uint256 secs = timestamp % SECONDS_PER_DAY;
    //     hour = secs / SECONDS_PER_HOUR;
    //     secs = secs % SECONDS_PER_HOUR;
    //     minute = secs / SECONDS_PER_MINUTE;
    //     second = secs % SECONDS_PER_MINUTE;
    // }
}


library MathHelpers {
    using CustomStrings for uint256;

    struct ComputationData {
        uint256 a;
        uint256 b;
        uint256 c;
        uint256 d;
        uint256 e;
    }

    struct StageAndProgressResult {
        uint256 stage;
        uint256 percentageOfStage;
        uint256 currentYear;
        uint256 currentMonth;
        uint256 currentDay;
        string description;
    }

    // sqrt approximation
    function sqrt(int256 x) internal pure returns (int256 y) {
        int256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    // Bhaskara’s Approximation Formula for Sine
    function sin(
        int256 angle // deg * 100
    ) internal pure returns (int256) {
        int256 correctedAngle;
        int8 sign;
        int16 oneHundredEightyDeg = 180 * 100;

        if (angle > oneHundredEightyDeg) {
            // trig relation: cos(x) = -cos(x - 180)
            correctedAngle = angle - (oneHundredEightyDeg);
            sign = -1;
        } else {
            correctedAngle = angle;
            sign = 1;
        }

        int256 rad = (10000 * 4 * correctedAngle * ((18000) - correctedAngle)) /
            (405000000 - (correctedAngle * ((18000) - correctedAngle)));

        return sign * rad; // rad * 10000
    }

    // Trig relation: cos(x) = sin(90 - x)
    function cos(
        int256 angle // deg * 100
    ) internal pure returns (int256) {
        int256 correctedAngle;
        int8 sign;
        int16 oneHundredEightyDeg = 180 * 100;

        if (angle > oneHundredEightyDeg) {
            // trig relation: cos(x) = -cos(x - 180)
            correctedAngle = angle - (oneHundredEightyDeg);
            sign = -1;
        } else {
            correctedAngle = angle;
            sign = 1;
        }

        int256 sinAngle = (90 * 100) - correctedAngle;

        return sign * sin(sinAngle);
    }

    // Trig relation: tan(x) = sin(x) / cos(x)
    function tan(
        int256 angle // deg * 100
    ) internal pure returns (int256) {
        require(angle != 9000, "tan(90) is NaN");
        return (10000 * sin(angle)) / cos(angle); // rad
    }

    // Approximation of arccosine
    function acos(
        int256 angle // rad * 10000
    ) internal pure returns (int256) {
        int256 value1 = 2000000;
        int256 value3 = 200;
        int256 eight_thirds = 2666;

        int256 a = sqrt(value1 + (value3 * angle));
        int256 b = sqrt(value1 - (value3 * angle));
        int256 c = sqrt(200000000 - (100000 * a));

        return ((eight_thirds * c) - ((10000 * b) / 3));
    }

    //
    // Astronomical Equations
    //

    // 23.5deg * sin((200 / 365) * 360deg)

    function delta(int256 daysSinceVernalEquinox)
        internal
        pure
        returns (int256)
    {
        int256 a = (100 * 360 * daysSinceVernalEquinox) / 365;
        int256 b = sin(a);
        int256 c = 41 * b;

        return c;
    }

    function tau(int256 latitude, int256 daysSinceVernalEquinox)
        internal
        pure
        returns (int256)
    {
        int256 tanBeta = tan(latitude); // rad * 10,000

        int256 deltaFromVernalEquinox = delta(daysSinceVernalEquinox);
        int256 tanDelta = tan((deltaFromVernalEquinox * 180) / 31415); // rad * 10,000

        int256 cosTau = -1 * (tanBeta / 100) * (tanDelta / 100);
        int256 tauRes = acos(cosTau);

        return tauRes;
    }

    function secondsOffset(int256 longitude) internal pure returns (int256) {
        return (longitude * 240) / 100; // deg * 240 (deg are multiplied by 100)
    }

    // Shortened algorithm for calculating the length
    // of a day for a given day of the year and latitude
    //
    // http://www.jgiesen.de/astro/solarday.htm
    //

    function hoursToCulmination(int256 latitude, uint256 daysSinceVernalEquinox)
        internal
        pure
        returns (uint256)
    {
        int256 tauFromVernalEquinoxAndLatitude = tau(
            latitude,
            int256(daysSinceVernalEquinox)
        );

        int256 pi = 314159;

        int256 degrees = (tauFromVernalEquinoxAndLatitude * 180) / pi;

        // return degrees;
        int256 percentOfDayToCulmination = (degrees * 100) / 360;

        int256 daylightHoursToCulmination = (percentOfDayToCulmination * 24) /
            10;

        return uint256(daylightHoursToCulmination);
    }

    function currentDaysSinceEquinox(int256 longitude, uint256 currentSeconds)
        internal
        pure
        returns (ComputationData memory)
    {
        uint256 longitudeOffsetSeconds = uint256(
            int256(currentSeconds) + secondsOffset(longitude)
        );

        (
            uint256 currentYear,
            uint256 currentMonth,
            uint256 currentDay
        ) = BokkyPooBahsDateTimeLibrary.timestampToDate(longitudeOffsetSeconds);

        uint256 march21SecondsSinceEpoch = BokkyPooBahsDateTimeLibrary
            .timestampFromDate(
                currentMonth > 3 ? currentYear : currentYear - 1,
                3,
                21
            );

        uint256 differenceSeconds = longitudeOffsetSeconds -
            march21SecondsSinceEpoch;

        uint256 differenceDays = differenceSeconds / 86400;

        uint256 remainderSecondsToday = differenceSeconds % 86400;

        uint256 daysSinceEquinox = differenceDays % 365;

        return
            ComputationData({
                a: daysSinceEquinox,
                b: remainderSecondsToday,
                c: currentYear,
                d: currentMonth,
                e: currentDay
            });
    }

    function stageCompletion(
        uint256 currentSeconds,
        uint256 stageStartSeconds,
        uint256 stageEndSeconds
    ) internal pure returns (uint256) {
        uint256 stageLength = stageEndSeconds - stageStartSeconds;
        uint256 currentStageLength = currentSeconds - stageStartSeconds;

        return (currentStageLength * 100) / stageLength;
    }

    function liveHoursToCulmination(
        int256 latitude,
        int256 longitude,
        uint256 currentSeconds
    ) internal pure returns (ComputationData memory) {
        ComputationData memory daysSinceEquinoxRes = currentDaysSinceEquinox(
            longitude,
            currentSeconds
        );

        return
            ComputationData(
                hoursToCulmination(latitude, daysSinceEquinoxRes.a), // hours * 100
                daysSinceEquinoxRes.b, // currentSecondsToday
                daysSinceEquinoxRes.c, // currentYear
                daysSinceEquinoxRes.d, // currentMonth
                daysSinceEquinoxRes.e // currentDay
            );
    }

    function updatedPercentage(
        uint256 percentageOfStage,
        uint256 breakPointPercentage
    ) internal pure returns (uint256) {
        uint256 scalePercentage = breakPointPercentage / 10;

        return
            percentageOfStage <= breakPointPercentage
                ? (percentageOfStage * 10) / scalePercentage
                : ((percentageOfStage - breakPointPercentage) * 10) /
                    (10 - scalePercentage);
    }

    function baseDescription(
        uint256 stageLengthSeconds,
        uint256 baseStageCompletionPercentage,
        bool relativeToStart,
        string memory context
    ) internal pure returns (string memory) {
        uint256 relevantHours;
        if (relativeToStart) {
            relevantHours =
                (stageLengthSeconds * baseStageCompletionPercentage) /
                360000;
        } else {
            relevantHours =
                (stageLengthSeconds * (100 - baseStageCompletionPercentage)) /
                360000;
        }

        string memory hoursDescription = relevantHours == 0
            ? "just "
            : string.concat(
                relevantHours.toString(),
                " hour",
                relevantHours == 1 ? " " : "s "
            );

        return
            string.concat(
                hoursDescription,
                relativeToStart ? "after " : "before ",
                context
            );
    }

    function liveStageAndProgress(
        int256 latitude,
        int256 longitude,
        uint256 currentSeconds
    ) internal pure returns (StageAndProgressResult memory) {
        ComputationData memory hoursToCulminationRes = liveHoursToCulmination(
            latitude,
            longitude,
            currentSeconds
        );

        uint256 secondsToCulmination = (hoursToCulminationRes.a * 3600) / 1000;
        uint256 noonSeconds = 43200; // seconds from midnight to midday

        uint256 sunriseSeconds = noonSeconds - secondsToCulmination;
        uint256 sunsetSeconds = noonSeconds + secondsToCulmination;

        // get the correct "stage" and percentage of stage
        uint256 stage;
        uint256 percentageOfStage;
        string memory description;

        if (hoursToCulminationRes.b < sunriseSeconds) {
            // midnight -> sunrise
            percentageOfStage = stageCompletion(
                hoursToCulminationRes.b,
                0,
                sunriseSeconds
            );

            description = baseDescription(
                sunriseSeconds,
                percentageOfStage,
                percentageOfStage <= 50,
                percentageOfStage <= 50 ? "solar midnight" : "sunrise"
            );

            stage = percentageOfStage <= 90 ? 0 : 1; // 90% from midnight to sunrise
            percentageOfStage = updatedPercentage(percentageOfStage, 90);
        } else if (hoursToCulminationRes.b < noonSeconds) {
            // sunrise -> noon
            percentageOfStage = stageCompletion(
                hoursToCulminationRes.b,
                sunriseSeconds,
                noonSeconds
            );

            stage = percentageOfStage <= 50 ? 2 : 3; // 50% from sunrise to noon

            description = baseDescription(
                noonSeconds - sunriseSeconds,
                percentageOfStage,
                stage == 2,
                stage == 2 ? "sunrise" : "solar noon"
            );

            percentageOfStage = updatedPercentage(percentageOfStage, 50);
        } else if (hoursToCulminationRes.b < sunsetSeconds) {
            // noon -> sunset
            percentageOfStage = stageCompletion(
                hoursToCulminationRes.b,
                noonSeconds,
                sunsetSeconds
            );

            stage = percentageOfStage <= 50 ? 4 : 5; // 50% from noon to sunset

            description = baseDescription(
                sunsetSeconds - noonSeconds,
                percentageOfStage,
                stage == 4,
                stage == 4 ? "solar noon" : "sunset"
            );

            percentageOfStage = updatedPercentage(percentageOfStage, 50);
        } else {
            // sunset -> midnight
            percentageOfStage = stageCompletion(
                hoursToCulminationRes.b,
                sunsetSeconds,
                86400 // 24 hours (midnight)
            );

            description = baseDescription(
                86400 - sunsetSeconds,
                percentageOfStage,
                percentageOfStage <= 50,
                percentageOfStage <= 50 ? "sunset" : "solar midnight"
            );

            stage = percentageOfStage <= 10 ? 6 : 7; // 30% from sunset to midnight
            percentageOfStage = updatedPercentage(percentageOfStage, 10);
        }

        return
            StageAndProgressResult(
                stage,
                percentageOfStage,
                hoursToCulminationRes.c,
                hoursToCulminationRes.d,
                hoursToCulminationRes.e,
                description
            );
    }
}
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

struct StageColorData {
    uint256 topColor;
    uint256 bottomColor;
    uint256 topOffsetPercentage;
    uint256 bottomOffsetPercentage;
}

struct SkyMetadata {
    string locationName;
    int256 latitude;
    int256 longitude;
}

contract SkyRenderer is Ownable {
    using CustomStrings for uint256;
    using Base64 for *;

    // Colors to use for rendering sky
    StageColorData[8] internal stageColorsData; // 0 - midnight, 2 - sunrise, 4 - noon, 6 - sunset

    constructor() {}

    // ========     ========
    // ======= OWNER =======
    // ========     ========

    function setStageColors(StageColorData[8] calldata stageColors)
        external
        onlyOwner
    {
        for (uint256 n = 0; n < stageColors.length; n++) {
            stageColorsData[n] = stageColors[n];
        }
    }

    // ========     ========
    // ======= RENDER ======
    // ========     ========

    function renderSky(
        uint256 tokenId,
        string calldata locationName,
        int256 latitude,
        int256 longitude
    ) public view returns (string memory) {
        MathHelpers.StageAndProgressResult memory computationRes = MathHelpers
            .liveStageAndProgress(latitude, longitude, block.timestamp);

        bytes memory dateString = bytes.concat(
            bytes(computationRes.currentYear.toString()),
            ".",
            bytes(computationRes.currentMonth.toString()),
            ".",
            bytes(computationRes.currentDay.toString())
        );

        bytes memory tokenName = bytes.concat(
            "The sky over ",
            bytes(locationName),
            " on ",
            dateString
        );

        bytes memory tokenDescription = bytes.concat(
            tokenName,
            " ",
            bytes(computationRes.description),
            "."
        );

        bytes memory attributes = bytes.concat(
            '"viewed_at": "',
            dateString,
            '", "location_name": "',
            bytes(locationName),
            '", "latitude": "',
            bytes(intDegToString(latitude)),
            '", "longitude": "',
            bytes(intDegToString(longitude)),
            '", "stage": "',
            bytes(computationRes.stage.toString()),
            '", "percentage": "',
            bytes(computationRes.percentageOfStage.toString())
        );

        bytes memory tokenUriMetadata = bytes.concat(
            '{ "name": "',
            tokenName,
            '", "description": "',
            tokenDescription,
            '", "image": "',
            bytes(
                renderSkySvgBase64(
                    tokenId,
                    computationRes.stage,
                    computationRes.percentageOfStage
                )
            ),
            '", "attributes": { ',
            attributes,
            '" } }'
        );

        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(tokenUriMetadata)
            );
    }

    function intDegToString(int256 n) internal pure returns (string memory) {
        uint256 absN = n < 0 ? uint256(-n) : uint256(n);

        string memory numberWithDecimal = string.concat(
            (absN / 100).toString(),
            ".",
            (absN % 100).toString()
        );

        if (n < 0) {
            return string.concat("-", numberWithDecimal);
        } else {
            return numberWithDecimal;
        }
    }

    function renderSkySvgBase64(
        uint256 tokenId,
        uint256 stage,
        uint256 percentageOfStage
    ) internal view returns (string memory) {
        return
            string.concat(
                "data:image/svg+xml;base64,",
                Base64.encode(renderSkySvg(tokenId, stage, percentageOfStage))
            );
    }

    function renderSkySvg(
        uint256 tokenId,
        uint256 stage,
        uint256 percentageOfStage
    ) internal view returns (bytes memory) {
        string memory innerSky = renderSkyGradient(stage, percentageOfStage);

        if (stage % (stageColorsData.length - 1) == 0) {
            innerSky = string.concat(
                innerSky,
                renderStarFilter(
                    tokenId,
                    stage == 0 ? 100 - percentageOfStage : percentageOfStage
                )
            );
        }

        return
            bytes.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024">',
                bytes(innerSky),
                "</svg>"
            );
    }

    function renderSkyGradient(uint256 stage, uint256 percentageOfStage)
        internal
        view
        returns (string memory)
    {
        StageColorData memory currentStageColorData = getCurrentColorData(
            stage,
            percentageOfStage
        );

        return
            string.concat(
                '<path fill="url(#a)" d="M0 0h1024v1024H0z"/><defs><linearGradient id="a" gradientTransform="rotate(90)"><stop offset="',
                currentStageColorData.topOffsetPercentage.toString(),
                '%" stop-color="#',
                currentStageColorData.topColor.toHexString(),
                '"/><stop offset="',
                currentStageColorData.bottomOffsetPercentage.toString(),
                '%" stop-color="#',
                currentStageColorData.bottomColor.toHexString(),
                '"/></linearGradient></defs>'
            );
    }

    function getCurrentColorData(uint256 stage, uint256 percentageOfStage)
        internal
        view
        returns (StageColorData memory)
    {
        uint256 nextStageIndex = stage >= 7 ? 0 : stage + 1;

        uint256 stageTopColor = stageColorsData[stage].topColor;
        uint256 stageBottomColor = stageColorsData[stage].bottomColor;

        uint256 nextTopColor = stageColorsData[nextStageIndex].topColor;
        uint256 nextBottomColor = stageColorsData[nextStageIndex].bottomColor;

        // lerp colors if needed

        if (stageTopColor != nextTopColor) {
            stageTopColor = uint256(
                lerpHexColors(
                    int256(stageTopColor),
                    int256(nextTopColor),
                    int256(percentageOfStage)
                )
            );
        }

        if (stageBottomColor != nextBottomColor) {
            stageBottomColor = uint256(
                lerpHexColors(
                    int256(stageBottomColor),
                    int256(nextBottomColor),
                    int256(percentageOfStage)
                )
            );
        }

        // Interpolate gradient offsets

        uint256 stageTopOffset = stageColorsData[stage].topOffsetPercentage;
        uint256 stageBottomOffset = stageColorsData[stage]
            .bottomOffsetPercentage;

        uint256 nextTopOffset = stageColorsData[nextStageIndex]
            .topOffsetPercentage;
        uint256 nextBottomOffset = stageColorsData[nextStageIndex]
            .bottomOffsetPercentage;

        if (stageTopOffset != nextTopOffset) {
            stageTopOffset = uint256(
                int256(stageTopOffset) +
                    ((int256(nextTopOffset) - int256(stageTopOffset)) *
                        int256(percentageOfStage)) /
                    100
            );
        }

        if (stageBottomOffset != nextBottomOffset) {
            stageTopOffset = uint256(
                int256(stageBottomOffset) +
                    ((int256(nextBottomOffset) - int256(stageBottomOffset)) *
                        int256(percentageOfStage)) /
                    100
            );
        }

        return
            StageColorData(
                stageTopColor,
                stageBottomColor,
                stageTopOffset,
                stageBottomOffset
            );
    }

    function renderStarFilter(uint256 tokenId, uint256 opacity)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                '<filter id="b"><feTurbulence baseFrequency="0.2"',
                ' seed="',
                tokenId.toString(),
                '" />',
                '<feColorMatrix values="0 0 0 20 -4 0 0 0 20 -4 0 0 0 20 -4 -2 -2 -2 1.7 0"/></filter>',
                '<rect width="100%" height="100%" filter="url(#b)" opacity="',
                opacity.toString(),
                '%"/>'
            );
    }

    // Linear interpolation between two hex colors

    function lerpHexColors(
        int256 startColor,
        int256 endColor,
        int256 percentage // 0-100
    ) internal pure returns (int256) {
        int256 ar = (startColor & 0xFF0000) >> 16;
        int256 ag = (startColor & 0x00FF00) >> 8;
        int256 ab = (startColor & 0x0000FF);

        int256 br = (endColor & 0xFF0000) >> 16;
        int256 bg = (endColor & 0x00FF00) >> 8;
        int256 bb = (endColor & 0x0000FF);

        int256 rr = ((100 * ar) + percentage * (br - ar)) / 100;
        int256 rg = ((100 * ag) + percentage * (bg - ag)) / 100;
        int256 rb = ((100 * ab) + percentage * (bb - ab)) / 100;

        return (rr << 16) + (rg << 8) + (rb | 0);
    }
}