// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./libraries/DataLib.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./Holder.sol";
import "./Auth.sol";

/*Errors */
error DataMissMatchOfHolder(string holderDID);
error DataMissMatch();

/**
 * @title Issuer Contract
 * @author Knoct
 * @notice  Issuance management of credential i.e generating credentialDID , issue credentials
 */
contract Issuer is NativeMetaTransaction{
    /*state variables */

    // Auth is official knoct contract to manage all the revocation and indenity status
    Auth public authority;
    // Holder contract where holder related functionalaties are present
    Holder public holderContract;

    // mapping to store all credential IDs corresponding to an IssuerDID
    //issuerDID --> all creds id's
    mapping(string => string[]) issuedCreds;

    /*modifier */
    modifier onlyVerifiedIssers() {
        // revert if status is not verified
        if (
            authority.getIssuerStatus(DataLib.getDID()) !=
            DataLib.IssuerStatus.EIS_Verified
        ) revert AccessOnlyToVerifiedIssuers();
        _;
    }

    /* Constructor */
    constructor(address authContractAddress, address holderContractAddress) {
        authority = Auth(authContractAddress);
        holderContract = Holder(holderContractAddress);
    }

    /**
     * @dev Private function to generate Credential DID
     * Note that-> It uses tx.origin i.e it returns the address of the account that sent the transaction
     * @param holderDID Holder ID
     */
    function generateCredDID(
        string memory holderDID
    ) private view returns (string memory) {
        // computing Keccak-256 hash of output of packed encoding
        // abi.encodePacked(arg); performs packed encoding and return bytes memory so here hashing this bytes memory
        // keccak256 returns bytes32 so wrapping this into uint256 and converting into hex form
        string memory hash = Strings.toHexString(
            uint256(
                keccak256(
                    abi.encodePacked(
                        tx.origin,
                        holderDID,
                        block.timestamp,
                        block.difficulty
                    )
                )
            )
        );
        string memory did = "did:cred:"; // replace with  DID method
        // again packed encoding and changing output of encoding inti string and returning as did
        did = string(abi.encodePacked(did, hash));
        return did;
    }

    // Apply for being an Issuer by this method
    function getApprovedAsIssuer() external {
        authority.getApprovedAsIssuer();
    }

    /**
     * @dev This calls addNewCred which can only be called verified Issuers and push credDID to issuedCreds array
     * @param holderDID Holder Id
     * @param dataTypes dataTypes present in given credential
     * @param data  data corresponding to dataType
     */

    function issueCred(
        string calldata holderDID,
        string[] calldata dataTypes,
        string[] calldata data
    ) private {
        // revert if there is miss match
        if (dataTypes.length != data.length) revert DataMissMatch();
        // get the credential DID from holderDID
        string memory credDID = generateCredDID(holderDID);
        // calling addNewCard function described from holderContract
        holderContract.addNewCred(credDID, holderDID, dataTypes, data);
        // pusshing credDID into list of issuedCreds
        issuedCreds[DataLib.getDID()].push(credDID);
    }

    /**
     * @dev This calls issueCred above private function and add new credential
     * @param holderDIDs Holder ID
     * @param dataTypes dataTypes present in given credential
     * @param data data corresponding to dataType
     */
    function issueCreds(
        string[] calldata holderDIDs,
        string[][] calldata dataTypes,
        string[][] calldata data
    ) external onlyVerifiedIssers {
        if (
            holderDIDs.length != dataTypes.length &&
            dataTypes.length != data.length
        ) revert DataMissMatch();
        for (uint i = 0; i < holderDIDs.length; i++)
            issueCred(holderDIDs[i], dataTypes[i], data[i]);
    }

    // Get list of all issued Credential
    function getAllIssuedCredDIDs() external view returns (string[] memory) {
        return issuedCreds[DataLib.getDID()];
    }

    //
    function getCredDID() external view returns (string memory) {
        string memory holderDID = DataLib.getDID();
        return generateCredDID(holderDID);
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
pragma solidity ^0.8.17;

import "./libraries/DataLib.sol";
import "./meta-transactions/NativeMetaTransaction.sol";

error AuthorityRestricted();
error AlreadyVerifiedAsIssuer();
error RequestIsAlreadyBeenPending();
error NoIssuerFoundWithThisDID();
error InValidTempleteDID();

/**
 * @title  This is knoct Authentication contracts
 * @author knoct
 * @notice Management of issuer Approver, revocation and making a template  by knoct
 */
contract Auth is NativeMetaTransaction{
    /* State variables */

    /**
     * @dev  official address of knoct and owner of contract who have the ability to verify the issuers
     */
    address immutable knoct;

    //array of all issuerDIDs
    string[] issuers;

    /**
     * @dev This is a mapping for issuerDID to issuer verification status
     */
    mapping(string => DataLib.IssuerStatus) issuerAuthentication;

    //verifier's data
    mapping(string => DataLib.VerifingTemplete) templetes; //templeteDID --> templete
    mapping(string => string[]) verifierTempletes; //verifierDID --> all templetes issued by verifier

    //modifiers
    modifier onlyKnoct() {
        if (msg.sender != knoct) revert AuthorityRestricted();
        _;
    }

    /* Functions */
    constructor() {
        knoct = msg.sender;
    }

    /**
     * @dev This is function that can be called by issuer to apply for being a Issuer
     *       by calling this method caller status(IssuerStatus) will be set to Pending state
     *       which can approve by knoct by approveAnIssuer method
     */

    function getApprovedAsIssuer() external {
        // get the IssuerDID from getDID function of DataLib library
        string memory newIssuerDID = DataLib.getDID();
        // declare staus and read the current status of IssuerDID
        DataLib.IssuerStatus status = issuerAuthentication[newIssuerDID];
        // check if status is alreadyVerified or not
        if (status == DataLib.IssuerStatus.EIS_Verified)
            revert AlreadyVerifiedAsIssuer();
        // check if status is yet in pending state if not process further
        if (status == DataLib.IssuerStatus.EIS_Pending)
            revert RequestIsAlreadyBeenPending();
        // setting the status into pending state
        issuerAuthentication[newIssuerDID] = DataLib.IssuerStatus.EIS_Pending;
        // pushing issuerDID to issuers array
        issuers.push(newIssuerDID);
    }

    /**
     *
     * @param issuerDID  DID of issuer which have to approve
     * @dev can be called by onlyKnoct(owner of the contract) to approve an issuer
     */
    function approveAnIssuer(string calldata issuerDID) external onlyKnoct {
        // declare staus and read the Authentucation status of IssuerDID
        DataLib.IssuerStatus status = issuerAuthentication[issuerDID];
        // check if status and revert if status is EIS_NotFound
        if (status == DataLib.IssuerStatus.EIS_NotFound)
            revert NoIssuerFoundWithThisDID();
        // revert if status is EIS_Verified
        if (status == DataLib.IssuerStatus.EIS_Verified)
            revert AlreadyVerifiedAsIssuer();
        // setting issuer status to EIS_Verified
        issuerAuthentication[issuerDID] = DataLib.IssuerStatus.EIS_Verified;
    }

    /**
     * @dev   This can be called by verifier for creating new Template for given dataTypes and adding verifierDID into
     *        verifierTempletes array
     * @param templeteDID templeteDID which is computed by verifierDID, block.timestamp and block.difficulty
     * @param dataTypes dataTypes present in VerifingTemplete requested for verification
     *
     */

    function createNewTemplete(
        string calldata templeteDID,
        string[] calldata dataTypes
    ) external {
        // get the verifierDID from getDID function of DataLib library
        string memory verifierDID = DataLib.getDID();
        // declare a VerifyingTemplete struct templete and read from templeteDID
        // storage t0 storage assign a reference so further value can be placed
        DataLib.VerifingTemplete storage templete = templetes[templeteDID];
        //setting  templeteDID to templete.templeteDID
        templete.templeteDID = templeteDID;
        // setting verifierDID to templete.verifierDID
        templete.verifierDID = verifierDID;
        // loop
        for (uint i = 0; i < dataTypes.length; i++) {
            // pushing given datatype to templete.dataTypes
            templete.dataTypes.push(dataTypes[i]);
        }
        // push templeteDID to verifierDID after creating this new templete
        verifierTempletes[verifierDID].push(templeteDID);
    }

    /**
     * @dev External function to get templete information i.e verifierDID and dataTypes
     * @param templeteDID templeteDID which is computed by verifierDID, block.timestamp and block.difficulty
     * @return verifierDID  ID of the verifier who created the templete
     * @return dataTypes  dataTypes added for verification in Verifying Templete
     */
    function getTemplete(
        string calldata templeteDID
    )
        external
        view
        returns (string memory verifierDID, string[] memory dataTypes)
    {
        // checking for InvalidTempleteDID
        if (bytes(templetes[templeteDID].verifierDID).length == 0)
            revert InValidTempleteDID();

        // return verifierDID and dataTypes corresponding to given templeteDID
        return (
            templetes[templeteDID].verifierDID,
            templetes[templeteDID].dataTypes
        );
    }

    /* Getter functions */
    // Get list of all issuers
    function getAllIssuers() external view returns (string[] memory) {
        return issuers;
    }

    // Get IssuerStatus to check if status is not listed, pending,verified
    // or rejected
    function getIssuerStatus(
        string calldata issuerDID
    ) external view returns (DataLib.IssuerStatus) {
        return issuerAuthentication[issuerDID];
    }

    //external function to get all templetes issued by verifier

    function getMyTempletes() external view returns (string[] memory) {
        return verifierTempletes[DataLib.getDID()];
    }

    //External function which return owner of the contract
    function getOwner() external view returns (address) {
        return knoct;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./libraries/DataLib.sol";
import "./Auth.sol";


error CredBelongsToAnotherHolder();
error CredIsNotVerified();
error OnlyAccepetedCreds();
error AccessOnlyToVerifiedIssuers();
error AlreadyVerifiedToThisTemplete();
error AlreadyRejectedThisTemplete();
error NoCredHasBeenVerifiedToThisTemplete();
error templeteBelongsToAnotherVerifier();
error NoAccessToAnyCredToThisTempleteForThisHolder();
error NoAccessToThisDataTypeWIthThisTemplete();
error CredIsNotSuitableForThisTemplete();

/**
 * @title  Holder contract which is handled by end user to manage his/her identity
 * @author knoct
 * @notice Management of credential ,adding new credential , reject credential for Holder
 */
contract Holder is NativeMetaTransaction{
    /* state variables*/

    // Auth is official knoct contract to manage all the revocation and indenity status
    Auth public authority;

    // Internal mapping to map credDID to cred struct which includes information of credential
    mapping(string => DataLib.Cred) creds;
    //Internal mapping to store list of the credDID for a individual Holder
    //holderDID --> list of all credDID owned by them
    mapping(string => string[]) holderCreds;
    //Internal mapping for finding direct Template Access information on templeteDID for a individual holderDID
    // HolderDID=> templeteDID=> DataLib.TempleteAccess
    mapping(string => mapping(string => DataLib.TempleteAccess)) acceptedCredToTempletes;
    //list of all templetes accepeted by a holderDID
    mapping(string => string[]) acceptedTempletes;
    // verifierDID=> templeteDID=> holderDID
    mapping(string => mapping(string => string[])) verifiedHolders; //verifierDID --> ( templeteDID --> holderDIDs )

    //modifiers

    //revert if Credential does not belong to Holder
    // DataLib.getDID() gives the DID of caller (it use tx.origin to make DID to return current caller DID=> HolderDID)
    modifier onlyOwnerOfTheCred(string calldata credDID) {
        // diffStrings returns true if both the input bytes array are different
        if (
            diffStrings(
                bytes(creds[credDID].holderDID),
                bytes(DataLib.getDID())
            )
        ) revert CredBelongsToAnotherHolder();
        _;
    }

    //revert if credential is not verified

    modifier onlyVerifiedCred(string calldata credDID) {
        if (
            creds[credDID].credStatus !=
            DataLib.CredVerificationStatus.ECVS_Verified
        ) revert CredIsNotVerified();
        _;
    }
    // revert if caller is not verified issuer
    modifier onlyVerifiedIssers() {
        // get issuerStatus and check if it is verified
        // revert if Issuer is not verified
        if (
            authority.getIssuerStatus(DataLib.getDID()) !=
            DataLib.IssuerStatus.EIS_Verified
        ) revert AccessOnlyToVerifiedIssuers();
        _;
    }

    // revert if caller is not templete owner

    modifier onlyTempleteOwner(string calldata templeteDID) {
        (string memory verifierDID, ) = authority.getTemplete(templeteDID);
        if (diffStrings(bytes(verifierDID), bytes(DataLib.getDID())))
            revert templeteBelongsToAnotherVerifier();
        _;
    }
    // revert if credential is not accepted
    modifier onlyAcceptedCred(string calldata credDID) {
        if (
            creds[credDID].acceptanceStatus !=
            DataLib.CredAcceptanceStatus.ECAS_Accepted
        ) revert OnlyAccepetedCreds();
        _;
    }

    /*constructor*/
    /**
     *
     * @param AuthAddress  knoct Authentication management contract address
     */
    constructor(address AuthAddress) {
        authority = Auth(AuthAddress);
    }

    /*helper private functions*/

    /**
     * @dev A Helper function for comparing two strings
     * @param str1  first bytes array
     * @param str2  second bytes array
     */
    function diffStrings(
        bytes memory str1,
        bytes memory str2
    ) private pure returns (bool) {
        //returns true if both str1 and str2 are different
        return
            (str1.length != str2.length) ||
            (keccak256(str1) != keccak256(str2));
    }

    /**
     * @dev Helper fucntion to check if a element is present in given array or not
     * @param array   given array in which search has been to perform
     * @param element  given element which have to be searched
     * @return bool returns true if element is present in the array otherwise false
     */
    function isInArray(
        string[] memory array,
        string memory element
    ) private pure returns (bool) {
        // checking if element is present in given array
        // linear search
        for (uint i = 0; i < array.length; i++) {
            if (!diffStrings(bytes(array[i]), bytes(element))) return true;
        }
        return false;
    }

    /**
     * @dev private method to check if given credDID is correctly matching with templeleDID
     * @param templeteDID  templeteDID which has been predefined and depend on verifierDID , block.timestamp and block.difficulty{ blockchain data}
     * @param credDID  credDID is sort of credential ID
     */
    function isCredAndTempleteMatching(
        string calldata templeteDID,
        string calldata credDID
    ) private view returns (bool) {
        // Get the dataTypes and declare as templetedataTypes
        (, string[] memory templetedataTypes) = authority.getTemplete(
            templeteDID
        );

        // declare a string arry credDataTypes and read credential dataTypes into it
        string[] memory credDataTypes = creds[credDID].dataTypes;
        // return false if both dataTypes are not matching
        if (templetedataTypes.length > credDataTypes.length) return false;
        for (uint i = 0; i < templetedataTypes.length; i++)
            if (!isInArray(credDataTypes, templetedataTypes[i])) return false;

        return true;
    }

    //functions

    /**
     * @dev   External method for adding new credential which can be called only by verified issuers
     * @param credDID credential ID
     * @param holderDID Holder DID
     * @param dataTypes list of all dataTypes present in credential
     * @param data given data corresponding to credential dataTypes
     */
    function addNewCred(
        string calldata credDID,
        string calldata holderDID,
        string[] memory dataTypes,
        string[] memory data
    ) external onlyVerifiedIssers {
        // get the IssuerDID from getDID function of DataLib library
        string memory issuerDID = DataLib.getDID();
        // declare a newcred of DataLib.Cred struct type and read from creds[credDID]
        DataLib.Cred storage newCred = creds[credDID];
        // setting the value of all members of newCred struct from given inputs
        newCred.credDID = credDID;
        newCred.credStatus = DataLib.CredVerificationStatus.ECVS_Verified;
        newCred.issuerDID = issuerDID;
        newCred.holderDID = holderDID;
        newCred.dataTypes = dataTypes;
        uint dataTypesLength = dataTypes.length;
        for (uint i = 0; i < dataTypesLength; i++) {
            creds[credDID].data[dataTypes[i]] = data[i];
        }

        //pushing into holdercreds
        holderCreds[holderDID].push(credDID);
    }

    /* External function which can be only called by owner of credential to accept pending 
  credential   */
    function acceptPendingCred(
        string calldata credDID
    ) external onlyOwnerOfTheCred(credDID) {
        // setting the status to ECAS_Accepted
        creds[credDID].acceptanceStatus = DataLib
            .CredAcceptanceStatus
            .ECAS_Accepted;
    }

    // external onlyOwnerOftheCred function which reject the pending credential by
    // seeting CredAcceptanceStatus to ECAS_Rejected

    function rejectPendingCred(
        string calldata credDID
    ) external onlyOwnerOfTheCred(credDID) {
        // setting the status to ECAS_Rejected
        creds[credDID].acceptanceStatus = DataLib
            .CredAcceptanceStatus
            .ECAS_Rejected;
    }

    //holder functionalities
    //toDO -- changable creds

    //verifying functionality

    /**
     * @dev owner of a accepted credential  can call this method to verify credential using templete
     * @param templeteDID templete ID
     * @param credDID credential ID
     */
    function verifyCredUsingtemplete(
        string calldata templeteDID,
        string calldata credDID
    ) external onlyOwnerOfTheCred(credDID) onlyAcceptedCred(credDID) {
        // get the holderDID from getDID function of DataLib library
        string memory holderDID = DataLib.getDID();
        // revert if  dataTypes from credDID and templeteDID is not matching
        if (!isCredAndTempleteMatching(templeteDID, credDID))
            revert CredIsNotSuitableForThisTemplete();
        // check the status and revert if credential is already verified
        if (
            acceptedCredToTempletes[holderDID][templeteDID].credAccessStatus ==
            DataLib.CredAccessStatus.ECAS_Accepted
        ) revert AlreadyVerifiedToThisTemplete();
        // Declare newTempleteAccess struct of type DataLib.TempleteAccess and read into it
        DataLib.TempleteAccess
            storage newTempleteAccess = acceptedCredToTempletes[holderDID][
                templeteDID
            ];
        //setting the value of all members of newTempleteAccess struct from given inputs
        newTempleteAccess.templeteDID = templeteDID;
        newTempleteAccess.credAccessStatus = DataLib
            .CredAccessStatus
            .ECAS_Accepted;
        newTempleteAccess.credDID = credDID;
        // pushing templetedDID to into list of acceptedTemplates
        acceptedTempletes[holderDID].push(templeteDID);
        // get the verifierDID corresponding to templeteDID
        (string memory verifierDID, ) = authority.getTemplete(templeteDID);
        // pushing HolderDID into list of verified holders for above templeteDID and VerifierDID
        verifiedHolders[verifierDID][templeteDID].push(holderDID);
    }

    /**
     * @dev External function which can be use by holder to Reject verified Credential
     * @param templeteDID tempelte ID
     */
    function rejectVerifiedCred(string calldata templeteDID) external {
        // get the holderDID from getDID function of DataLib library
        string memory holderDID = DataLib.getDID();
        // get the status from  acceptedCredToTempletes
        DataLib.CredAccessStatus status = acceptedCredToTempletes[holderDID][
            templeteDID
        ].credAccessStatus;
        // check if status is already rejected , revert if it is
        if (status == DataLib.CredAccessStatus.ECAS_Rejected)
            revert AlreadyRejectedThisTemplete();
        // check if status has been setted to NoAccess and return if it is
        if (status == DataLib.CredAccessStatus.ECAS_NoAccess)
            revert NoCredHasBeenVerifiedToThisTemplete();
        // setting status to ECAS_Rejected
        acceptedCredToTempletes[holderDID][templeteDID]
            .credAccessStatus = DataLib.CredAccessStatus.ECAS_Rejected;
    }

    // Get list of all acceptedTempletes of a Holder
    function getAllTempletesAccepted() external view returns (string[] memory) {
        return acceptedTempletes[DataLib.getDID()];
    }

    // Get Verified HolderDIDs corresponding to given templeteDID
    function getVerifiedHoldersToATemplete(
        string calldata templeteDID
    ) external view onlyTempleteOwner(templeteDID) returns (string[] memory) {
        // get the verifierDID from corresponding templeteDID
        (string memory verifierDID, ) = authority.getTemplete(templeteDID);
        // revert if diffStrings return true[ i.e verifierDID is not same as DataLib.getDID()]
        if (diffStrings(bytes(verifierDID), bytes(DataLib.getDID())))
            revert templeteBelongsToAnotherVerifier();
        // return list  verified holderDIDs
        return verifiedHolders[DataLib.getDID()][templeteDID];
    }

    /**
     * @dev External view function to get  Holder credential Data  from templete DID
     * @param holderDID  Holder ID
     * @param templeteDID Templete ID
     * @param dataType list of all dataTypes present in credential
     */
    function getHolderCredByTempleteDID(
        string memory holderDID,
        string calldata templeteDID,
        string calldata dataType
    ) external view onlyTempleteOwner(templeteDID) returns (string memory) {
        // check status if There is No Acess to any credential to this templete for given Holder
        if (
            acceptedCredToTempletes[holderDID][templeteDID].credAccessStatus !=
            DataLib.CredAccessStatus.ECAS_Accepted
        ) revert NoAccessToAnyCredToThisTempleteForThisHolder();
        // get the dataTypes corressponding to templeteDID
        (, string[] memory dataTypes) = authority.getTemplete(templeteDID);
        // check if dataType is present above dataTypes array
        if (!isInArray(dataTypes, dataType))
            revert NoAccessToThisDataTypeWIthThisTemplete();
        // get the credential DID
        string memory credDID = acceptedCredToTempletes[holderDID][templeteDID]
            .credDID;

        return creds[credDID].data[dataType];
    }

    //getters
    //Getter function for finding Credential status
    function getCredStatus(
        string calldata credDID
    ) external view returns (DataLib.CredAcceptanceStatus) {
        return creds[credDID].acceptanceStatus;
    }

    //  Get list of credDID owned by holder
    function getMyCreds() external view returns (string[] memory) {
        return holderCreds[DataLib.getDID()];
    }

    // get Holder of a given credDID
    function getCredHolder(
        string calldata credDID
    ) external view returns (string memory) {
        return creds[credDID].holderDID;
    }

    // Get Issuer of a given credDID
    function getCredIssuer(
        string calldata credDID
    ) external view returns (string memory) {
        return creds[credDID].issuerDID;
    }

    // Get list of all the dataTypes of a credDID
    function getCredDataTypes(
        string calldata credDID
    ) external view returns (string[] memory) {
        return creds[credDID].dataTypes;
    }

    // Get data of corresponding dataType for a given credDID
    function getCredData(
        string calldata credDID,
        string calldata dataType
    ) external view onlyOwnerOfTheCred(credDID) returns (string memory) {
        return creds[credDID].data[dataType];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";

library DataLib {
    enum IssuerStatus {
        EIS_NotFound,
        EIS_Pending,
        EIS_Verified,
        EIS_Rejected
    }

    enum CredVerificationStatus {
        ECVS_NotFound,
        ECVS_Verified,
        ECVS_Rejected
    }

    enum CredAcceptanceStatus {
        ECAS_Pending,
        ECAS_Accepted,
        ECAS_Rejected
    }

    enum CredAccessStatus {
        ECAS_NoAccess,
        ECAS_Accepted,
        ECAS_Rejected
    }

    struct TempleteAccess {
        string templeteDID; //templeteDID
        CredAccessStatus credAccessStatus; //access given to a (templete or issuer)
        string credDID; //credDID | credential that is given access to...
    }

    struct Cred {
        string credDID; //credential id
        CredVerificationStatus credStatus; //credit verification status
        string issuerDID; //Isuuer of this credential
        string holderDID; //to whom this credential belon
        CredAcceptanceStatus acceptanceStatus; //acctence status by holder
        string[] dataTypes;
        mapping(string => string) data; //dataTypes --> data
    }

    struct VerifingTemplete {
        string templeteDID;
        string verifierDID; //id of the verifier who created the templete
        string[] dataTypes; //dataTypes requested for verification
    }

    function getDID() external view returns (string memory) {
        string memory hash = Strings.toHexString(
            uint256(keccak256(abi.encodePacked(tx.origin)))
        );
        string memory did = "did:knoct:"; // replace with  DID method
        did = string(abi.encodePacked(did, hash));
        return did;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract EIP712Base {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string public constant ERC712_NAME = "KNOCT META-TX";

    string public constant ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
    keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // set domainSeperator at the time of deployment
    constructor() {
        _setDomainSeperator();
    }

    function _setDomainSeperator() internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(ERC712_NAME)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
    internal
    view
    returns (bytes32)
    {
        return
        keccak256(
            abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    bytes32 private constant META_TRANSACTION_TYPEHASH =
    keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) private metaNonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory) {
        require(userAddress != address(0), "UserAddress cannot be zero address");
        MetaTransaction memory metaTx =
        MetaTransaction({
        nonce: metaNonces[userAddress],
        from: userAddress,
        functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        metaNonces[userAddress] += 1;

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) =
        address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
    public
    pure
    returns (bytes32)
    {
        return
        keccak256(
            abi.encode(
                META_TRANSACTION_TYPEHASH,
                metaTx.nonce,
                metaTx.from,
                keccak256(metaTx.functionSignature)
            )
        );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = metaNonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
        signer ==
        ecrecover(
            toTypedMessageHash(hashMetaTransaction(metaTx)),
            sigV,
            sigR,
            sigS
        );
    }
}