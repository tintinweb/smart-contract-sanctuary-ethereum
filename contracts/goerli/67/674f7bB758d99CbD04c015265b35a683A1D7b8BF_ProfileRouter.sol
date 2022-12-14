// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
pragma solidity >=0.8.9;

interface IMaster {
    enum TypeOracle {
        Metric,
        KYC
    }

    enum TypeMetric {
        Unknown,
        Uint, 
        Int, 
        FloatUint, 
        FloatInt, 
        Address,
        Bool,
        String,
        KYC
    }

    struct OracleProposal {
        bytes32 votingId;
        string[] names;
        TypeMetric[] metricTypes;
        string description;
        address oracle;
        uint endTime;
        uint support;
        TypeOracle character;
    }

    struct MemberProposal {
        bytes32 votingId;
        address member;
        uint endTime;
        uint support;
    }

    function becomeOracle(string[] calldata _names, TypeMetric[] calldata _typeMetric, string calldata _description, TypeOracle _type) external; 

    function voteForOracle(uint _id) external;
    
    function finishOracleVoiting(uint _id) external;

    function becomeMember() external;

    function voteForMember(uint _id) external;

    function finishMemberVoiting(uint _id) external;

    function setProposalDuration(uint _duration) external;

    function removeOracle(address _oracle, bytes32 _id, bool _isOracleKYC) external;

    function removeCommunityMember(address _member) external;

    function getTypeMetricByNameId(bytes32 _nameId) external view returns(TypeMetric);

    function getNamesByProposalId(uint _id) external view returns(string[] memory);

    function getIsOracleToNameId(address _oracle, bytes32 _id) external view returns(bool);

    function getIsOracleKYC(address _oracle) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IProfileContract {

    function fullName() external view returns(string memory);

    function addressWallet() external view returns(address);

    function transferProfileOwnership(address _newAddress) external;

    function acceptProfileOwnership() external;

    function cancelTransferProfileOwnership() external returns(address newAddressWallet);

    function deleteProfile() external;

    function approveKYC(string memory _name) external;

    function registerNameIds(string[] memory _names) external;

    function setBytes32(bytes32 _id, bytes32 _data) external;

    function setString(bytes32 _id, string memory _data) external;

    function getBytes32(bytes32 _id) external view returns(bytes32);

    function getString(bytes32 _id) external view returns(string memory);

    function getLengthMetricNames() external view returns(uint);

    function getSliceMetricNames(uint _start, uint _end) external view returns(string[] memory slice);

    function getLengthConfirmations() external view returns(uint);

    function getSliceConfirmations(uint _start, uint _end) external view returns(string[] memory slice);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
  
import './interfaces/IMaster.sol';
import "./interfaces/IProfileContract.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ProfileContract is IProfileContract {

    address private _addressWallet;
    address private _newAddressWallet;
    address private _profileRouter;
    string private _fullName;
    IMaster public immutable master;

    string[] confirmations;
    string[] metricNames;

    mapping(bytes32 => bytes32) public dataBytes32; 

    mapping(bytes32 => string) public dataStrings;

    mapping(address => bool) public kycOracles;

    mapping(bytes32 => bool) public registeredNameIds;

    bool public KYC; 

    constructor(address _wallet, address _master, address _router, string memory _name) {
        _addressWallet = _wallet;
        master = IMaster(_master);
        _fullName = _name;
        _profileRouter = _router;
    }

    modifier onlyProfileRouter {
        address sender = msg.sender;
        require(sender == _profileRouter, 'The function can only be called by ProfileRouter');
        _;
    }

    function fullName() external view returns(string memory) {
        return _fullName;
    }

    function addressWallet() external view returns(address) {
        return _addressWallet;
    }

    function transferProfileOwnership(address _newAddress) external onlyProfileRouter {
        require(tx.origin == _addressWallet, 'You are not the owner of the profile');
        require(_newAddress != _addressWallet, 'It is impossible to transfer the profile to yourself');
        require(_newAddressWallet == address(0),
            string(
                    abi.encodePacked(
                        "The function has already been called for the account ",
                        Strings.toHexString(_newAddressWallet),
                        ", accept or cancel"
                    )
                )
        );
        _newAddressWallet = _newAddress;
    }

    function acceptProfileOwnership() external onlyProfileRouter {
        require(tx.origin == _newAddressWallet, 'You are not the new owner of the profile');
        _addressWallet = _newAddressWallet;
        _newAddressWallet = address(0);
    }

    function cancelTransferProfileOwnership() external onlyProfileRouter returns(address newAddressWallet) {
        require(tx.origin == _addressWallet || tx.origin == _newAddressWallet, 'Only the old or new owner can cancel the transfer of ownership');
        require(_newAddressWallet != address(0), "There are no transmitted profiles");
        newAddressWallet = _newAddressWallet;
        _newAddressWallet = address(0);
    }

    function deleteProfile() external onlyProfileRouter {
        require(tx.origin == _addressWallet, 'You are not the new owner of the profile');
        require(_newAddressWallet == address(0), "Complete the transfer of ownership or cancel it");
        address payable recipient = payable(address(_addressWallet));
        selfdestruct(recipient);
    }

    function approveKYC(string memory _name) external {
        address sender = msg.sender;
        bytes32 nameId = _stringToHash(_name);
        require(!kycOracles[sender], 'Already approved');
        require(master.getIsOracleKYC(sender), "The sender is not a KYC oracle");
        require(master.getIsOracleToNameId(sender, nameId), "Invalid name");
        require(master.getTypeMetricByNameId(nameId) == IMaster.TypeMetric.KYC, "The type of this metric is not KYC");
        confirmations.push(_name);
        kycOracles[sender] = true;
        if(!KYC) {
            KYC = true;
        }
        
    }

    function registerNameIds(string[] memory _names) external {
        require(_names.length > 0, "Empty array");
        address sender = msg.sender;
        for(uint i = 0; i < _names.length; i++) {
            bytes32 nameId = _stringToHash(_names[i]);
            require(!registeredNameIds[nameId],
                string(
                        abi.encodePacked(
                            "This id by name '",
                            _names[i],
                            "' is already registered"
                        )
                    )             
             );
            require(master.getIsOracleToNameId(sender, nameId), 
                string(
                        abi.encodePacked(
                            "'",
                            _names[i],
                            "' - invalid data id"
                        )
                    )
            );
            registeredNameIds[nameId] = true;
            metricNames.push(_names[i]);
        }
    }

    function setBytes32(bytes32 _nameId, bytes32 _data) external {
        address sender = tx.origin;
        require(master.getIsOracleToNameId(sender, _nameId), 'Invalid data id');
        require(registeredNameIds[_nameId], 'Unregistered id');
        dataBytes32[_nameId] = _data;
    }

    function setString(bytes32 _nameId, string memory _data) external {
        address sender = tx.origin;
        require(master.getIsOracleToNameId(sender, _nameId), 'Invalid data id');
        require(registeredNameIds[_nameId], 'Unregistered id');
        dataStrings[_nameId] = _data;
    }

    function getBytes32(bytes32 _nameId) external view returns(bytes32) {
        return dataBytes32[_nameId];
    }

    function getString(bytes32 _nameId) external view returns(string memory) {
        return dataStrings[_nameId];
    }

    function getLengthMetricNames() external view returns(uint) {
        return metricNames.length;
    }

    function getSliceMetricNames(uint _start, uint _end) external view returns(string[] memory slice) {
        require(_end > _start, "Invalid input data");
        uint sliceLength = _end - _start;
        slice = new string[](sliceLength);
        for(uint i = 0; i < sliceLength; i++) {
            uint storagePosition = i + _start;
            slice[i] = metricNames[storagePosition];
        }
    }

    function getLengthConfirmations() external view returns(uint) {
        return confirmations.length;
    }

    function getSliceConfirmations(uint _start, uint _end) external view returns(string[] memory slice) {
        require(_end > _start, "Invalid input data");
        uint sliceLength = _end - _start;
        slice = new string[](sliceLength);
        for(uint i = 0; i < sliceLength; i++) {
            uint storagePosition = i + _start;
            slice[i] = confirmations[storagePosition];
        }
    }

    function _stringToHash(string memory _parameter) internal pure returns(bytes32 _hash) {
        _hash = keccak256(abi.encodePacked(_parameter));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./ProfileContract.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract ProfileRouter is Context {

    struct UserInfo {
        mapping(address => bool) profilesMap;
        address[] profilesArr;
        address[] transmittedProfiles;
        address[] acceptedProfiles;
    }

    address private immutable _thisAddress;

    address private immutable _master;
    mapping(address => UserInfo) usersData;

    constructor(address _masterAddress) {
        _master = _masterAddress;
        _thisAddress = address(this);
    }

    function createNewProfileContract(string memory _fullName) external {
        address sender = _msgSender();
        UserInfo storage user = usersData[sender];
        address newProfile = address(_deployNewProfile(sender, _fullName));
        user.profilesMap[newProfile] = true;
        user.profilesArr.push(newProfile);
    }

    function transferProfileOwnership(address _newOwner, address _profile) external {
        address sender = _msgSender();
        UserInfo storage ProfileSender = usersData[sender];
        UserInfo storage ProfileRecipient = usersData[_newOwner];
        ProfileContract(_profile).transferProfileOwnership(_newOwner);
        ProfileSender.transmittedProfiles.push(_profile);
        ProfileRecipient.acceptedProfiles.push(_profile);
    }

    function acceptProfileOwnership(address _profile) external {
        address sender = _msgSender();
        ProfileContract profile = ProfileContract(_profile);
        address oldOwner = profile.addressWallet();
        UserInfo storage ProfileSender = usersData[oldOwner];
        UserInfo storage ProfileRecipient = usersData[sender];
        profile.acceptProfileOwnership();
        _removeAddressFromArray(_profile, ProfileSender.transmittedProfiles);
        _removeAddressFromArray(_profile, ProfileRecipient.acceptedProfiles);
        _removeAddressFromArray(_profile, ProfileSender.profilesArr);
        ProfileSender.profilesMap[_profile] = false;
        ProfileRecipient.profilesArr.push(_profile);
        ProfileRecipient.profilesMap[_profile] = true;
    }

    function cancelTransferProfileOwnership(address _profile) external {
        ProfileContract profile = ProfileContract(_profile);
        address newOwner = profile.cancelTransferProfileOwnership();
        address oldOwner = profile.addressWallet();
        UserInfo storage ProfileSender = usersData[oldOwner];
        UserInfo storage ProfileRecipient = usersData[newOwner];
        _removeAddressFromArray(_profile, ProfileSender.transmittedProfiles);
        _removeAddressFromArray(_profile, ProfileRecipient.acceptedProfiles);
    }

    function deleteProfile(address _profile) external {
        address sender = _msgSender();
        UserInfo storage ProfileSender = usersData[sender];
        ProfileContract(_profile).deleteProfile();
        ProfileSender.profilesMap[_profile] = false;
        _removeAddressFromArray(_profile, ProfileSender.profilesArr);
    }

    function isProfileBelongWallet(address _profile, address _wallet) external view returns(bool) {
        return usersData[_wallet].profilesMap[_profile];
    }

    function getLengthProfilesArray(address _user) external view returns(uint) {
        return usersData[_user].profilesArr.length;
    }

    function getSliceProfilesArray(address _user, uint _start, uint _end) external view returns(address[] memory slice) {
        require(_end > _start, "Invalid input data");
        uint sliceLength = _end - _start;
        address[] memory profilesArr = usersData[_user].profilesArr;
        slice = new address[](sliceLength);
        for(uint i = 0; i < sliceLength; i++) {
            uint storagePosition = i + _start;
            slice[i] = profilesArr[storagePosition];
        }
    }

    function getTransmittedProfiles(address _user) external view returns(address[] memory) {
        return usersData[_user].transmittedProfiles;
    }

    function getAcceptedProfiles(address _user) external view returns(address[] memory) {
        return usersData[_user].acceptedProfiles;
    }

    function _deployNewProfile(address _profile, string memory _name) internal returns(ProfileContract profile) {
        profile = new ProfileContract(_profile, _master, _thisAddress,_name);
    }

    function _removeAddressFromArray(address _el, address[] storage _array) internal {
        uint index;
        bool isElement;
        for(uint i = 0; i < _array.length; i++) {
            if(_array[i] == _el) {
                index = i;
                isElement = true;
                break;
            }
        }
        if(isElement) {
            _array[index] = _array[_array.length - 1];
            _array.pop();
        }
    }
}