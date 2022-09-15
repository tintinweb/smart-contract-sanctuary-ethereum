/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;


/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: default_workspace/Staking(skm).sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;




contract StakingContract is Ownable {
    
    using SafeMath for uint;

    event ConfigUpdate(string field_, uint value_);
    event Staking(address indexed stakeholder_, uint stake_);
    event Rewarding(address indexed stakeholder_, uint reward_, uint lockedReward_, uint numberOfPeriods_);
    event InitiateWithdraw(address stakeholder_, uint amount_, uint releaseDate_);
    event Withdraw(address stakeholder_, uint amount_, uint fee_);
    event Active(address stakeholder_, bool active_);

    struct Withdrawal{
        uint releaseDate; 
        uint releaseAmount; 
    }

    struct StakeHolder {
        uint stakingBalance; 
        uint weight; 
        uint startDate; 
        uint lastClaimed;
        uint newStake; 
        uint lockedRewards; 
        bool unlockToken;
        Withdrawal[] withdrawals; 
    }

    function getWithdrawalLength(address stakeholderAddress) public view returns(uint length){
        return stakeholders[stakeholderAddress].withdrawals.length;
    }

    function getWithdrawal(uint index, address stakeholderAddress) public view returns(uint releaseDate, uint releaseAmount){
        return (stakeholders[stakeholderAddress].withdrawals[index].releaseDate,
                stakeholders[stakeholderAddress].withdrawals[index].releaseAmount);
    }

    struct RewardPeriod {
        uint rewardPerPeriod; 
        uint extraRewardMultiplier; 
        uint maxWeight; 
        mapping (uint => uint) _totalStakingBalance; 
    }

    mapping(address => StakeHolder) public stakeholders;

    mapping (uint => RewardPeriod) public rewardPeriods;

    uint public latestRewardPeriod; 
    mapping (uint => uint) _totalNewStake; 
    mapping (uint => uint) public _totalLockedRewards; 
    mapping (uint => uint) public weightCounts; 

    address public signatureAddress;


    uint public startDate; 
    uint public maxNumberOfPeriods; 
    uint public rewardPeriodDuration; 
    uint public periodsForExtraReward; 
    uint public cooldown; 
    uint public earlyWithdrawalFee; 
    uint public decimalPrecision = 10**6;

    constructor(
                uint maxNumberOfPeriods_, 
                uint rewardPeriodDuration_, 
                uint periodsForExtraReward_, 
                uint extraRewardMultiplier_,
                uint cooldown_,
                uint earlyWithdrawalFee_) {
        maxNumberOfPeriods = maxNumberOfPeriods_;
        rewardPeriodDuration = rewardPeriodDuration_;
        periodsForExtraReward = periodsForExtraReward_;
        cooldown = cooldown_;
        earlyWithdrawalFee = earlyWithdrawalFee_;

        startDate = block.timestamp;            
        
        rewardPeriods[0].extraRewardMultiplier = extraRewardMultiplier_;

    }

    function totalStakingBalance(uint period, uint weightExponent) public view returns (uint totalStaking){
        for(uint i = 0; i <= rewardPeriods[period].maxWeight; i++){
            totalStaking += rewardPeriods[period]._totalStakingBalance[i] * (i+1) ** weightExponent;
        }
    }

    function totalNewStake(uint weightExponent) public view returns (uint totalNew){
        for(uint i = 0; i <= rewardPeriods[latestRewardPeriod].maxWeight; i++){
            totalNew += _totalNewStake[i] * (i+1) ** weightExponent;        
        }
    }

    function totalLockedRewards(uint weightExponent) public view returns (uint totalLocked){
        for(uint i = 0; i <= rewardPeriods[latestRewardPeriod].maxWeight; i++){
            totalLocked += _totalLockedRewards[i] * (i+1) ** weightExponent;        
        }
    }

    function handleNewPeriod(uint endPeriod) public {
        if(currentPeriod() < endPeriod ){
            endPeriod = currentPeriod();
        }
        while(latestRewardPeriod < endPeriod){
            uint twsb = totalStakingBalance(latestRewardPeriod, 1);
            rewardPeriods[latestRewardPeriod].rewardPerPeriod = calculateRewardPerPeriod();

            latestRewardPeriod++;
            rewardPeriods[latestRewardPeriod].extraRewardMultiplier = rewardPeriods[latestRewardPeriod-1].extraRewardMultiplier;
            rewardPeriods[latestRewardPeriod].maxWeight = rewardPeriods[latestRewardPeriod-1].maxWeight;
            rewardPeriods[latestRewardPeriod].rewardPerPeriod = rewardPeriods[latestRewardPeriod-1].rewardPerPeriod;

            for(uint i = 0; i<=rewardPeriods[latestRewardPeriod-1].maxWeight;i++){
                rewardPeriods[latestRewardPeriod]._totalStakingBalance[i] = rewardPeriods[latestRewardPeriod-1]._totalStakingBalance[i] + _totalNewStake[i];
                _totalNewStake[i] = 0;
                uint newReward = 0;
                if(twsb > 0 && rewardPeriods[latestRewardPeriod-1]._totalStakingBalance[i] > 0){
                    newReward = (rewardPeriods[latestRewardPeriod-1].rewardPerPeriod * (i+1) + twsb)
                        * rewardPeriods[latestRewardPeriod-1]._totalStakingBalance[i] / twsb
                        - rewardPeriods[latestRewardPeriod-1]._totalStakingBalance[i];
                    rewardPeriods[latestRewardPeriod]._totalStakingBalance[i] += newReward;

                }
                if(latestRewardPeriod % periodsForExtraReward == 1){
                    rewardPeriods[latestRewardPeriod]._totalStakingBalance[i] += _totalLockedRewards[i]
                            + newReward * rewardPeriods[latestRewardPeriod-1].extraRewardMultiplier / (decimalPrecision);
                    _totalLockedRewards[i] = 0;
                } else {
                    _totalLockedRewards[i] += newReward * rewardPeriods[latestRewardPeriod-1].extraRewardMultiplier / (decimalPrecision);
                }
            }
        }
    }

    function calculateRewardPerPeriod() public view returns(uint rewardPerPeriod){
        uint totalStaked = totalStakingBalance(latestRewardPeriod, 0)
                    + totalNewStake(0)
                    + totalLockedRewards(0);
            if((totalStakingBalance(latestRewardPeriod, 1) > 0)){
                rewardPerPeriod = (latestRewardPeriod - totalStaked)
                    * decimalPrecision
                    / ((maxNumberOfPeriods + 1 - latestRewardPeriod) 
                        * (rewardPeriods[latestRewardPeriod].extraRewardMultiplier + decimalPrecision));
            } else {
                rewardPerPeriod = 0;
            }
    }

    function increaseWeight(uint weight_, bytes memory signature) public{
        handleNewPeriod(currentPeriod());
    
        address sender = _msgSender();

        require(signatureAddress == _recoverSigner(sender, weight_, signature),
            "Invalid sig");

        StakeHolder storage stakeholder = stakeholders[sender];
        require(weight_ > stakeholder.weight, "No weight increase");


        if(activeStakeholder(sender)){
            handleRewards(currentPeriod(), false, sender);

            rewardPeriods[latestRewardPeriod]._totalStakingBalance[stakeholder.weight] -= stakeholder.stakingBalance;
            rewardPeriods[latestRewardPeriod]._totalStakingBalance[weight_] += stakeholder.stakingBalance;
            
            _totalNewStake[stakeholder.weight] -= stakeholder.newStake;
            _totalNewStake[weight_] += stakeholder.newStake;

            _totalLockedRewards[stakeholder.weight] -= stakeholder.lockedRewards;
            _totalLockedRewards[weight_] += stakeholder.lockedRewards;
        
            weightCounts[stakeholder.weight]--;
            weightCounts[weight_]++;

            if(weight_ > rewardPeriods[latestRewardPeriod].maxWeight){
                rewardPeriods[latestRewardPeriod].maxWeight = weight_;
            }

        }

        stakeholder.weight = weight_;
    }

    function updateWeightBatch(address[] memory stakeholders_, uint[] memory weights_) public onlyOwner{

        require(stakeholders_.length == weights_.length, "Length mismatch");

        handleNewPeriod(currentPeriod());
        claimRewardsAsOwner(stakeholders_);

        for(uint i = 0; i < stakeholders_.length; i++){

            StakeHolder storage stakeholder = stakeholders[stakeholders_[i]];
            if(weights_[i] == stakeholder.weight){continue;}


            if(activeStakeholder(stakeholders_[i])){

                rewardPeriods[latestRewardPeriod]._totalStakingBalance[stakeholder.weight] -= stakeholder.stakingBalance;
                rewardPeriods[latestRewardPeriod]._totalStakingBalance[weights_[i]] += stakeholder.stakingBalance;
            
                _totalNewStake[stakeholder.weight] -= stakeholder.newStake;
                _totalNewStake[weights_[i]] += stakeholder.newStake;
                
                _totalLockedRewards[stakeholder.weight] -= stakeholder.lockedRewards;
                _totalLockedRewards[weights_[i]] += stakeholder.lockedRewards;
                
                weightCounts[stakeholder.weight]--;
                weightCounts[weights_[i]]++;

                if(weights_[i] > rewardPeriods[latestRewardPeriod].maxWeight){
                    rewardPeriods[latestRewardPeriod].maxWeight = weights_[i];
                }
            
            }

            stakeholder.weight = weights_[i];

        }

        handleDecreasingMaxWeight();
    }

    function stake() public payable {
        uint amount = msg.value;
        handleNewPeriod(currentPeriod());
        address sender = _msgSender();

        require(amount > 0, "Amount not positive");
    
        StakeHolder storage stakeholder = stakeholders[sender];

        if(activeStakeholder(sender) == false){
            if(stakeholder.weight > rewardPeriods[latestRewardPeriod].maxWeight){
                rewardPeriods[latestRewardPeriod].maxWeight = stakeholder.weight;
            }
            weightCounts[stakeholder.weight]++;
            stakeholder.startDate = block.timestamp;
            stakeholder.lastClaimed = currentPeriod();
            emit Active(sender, true);
        }

        handleRewards(currentPeriod(), false, sender);


        stakeholder.newStake += amount;

        _totalNewStake[stakeholder.weight] += amount;
        
        emit Staking(sender, amount);
    }

    function requestWithdrawal(uint amount, bool instant, bool claimRewardsFirst) public {
        address sender = _msgSender();
        StakeHolder storage stakeholder = stakeholders[sender];
        
        if(cooldown == 0){
            instant = true;
        }

        if (claimRewardsFirst){
            handleNewPeriod(currentPeriod());
            handleRewards(currentPeriod(), false, sender);
        } else {
            stakeholder.lastClaimed = currentPeriod();
        }
        
        require(stakeholder.stakingBalance >= 0 || stakeholder.newStake >= 0, "Nothing was staked");
        require(stakeholder.unlockToken, "No rights to withdraw");
        
        if(amount > stakeholder.newStake){
            if((amount - stakeholder.newStake) > stakeholder.stakingBalance){
                amount = stakeholder.stakingBalance + stakeholder.newStake;
                rewardPeriods[latestRewardPeriod]._totalStakingBalance[stakeholder.weight] -= stakeholder.stakingBalance;
                stakeholder.stakingBalance = 0;
            } else {
                rewardPeriods[latestRewardPeriod]._totalStakingBalance[stakeholder.weight] -= (amount - stakeholder.newStake);
                stakeholder.stakingBalance -= (amount - stakeholder.newStake);
            }
            _totalNewStake[stakeholder.weight] -= stakeholder.newStake;
            stakeholder.newStake = 0;
        } else {
            _totalNewStake[stakeholder.weight] -= amount;
            stakeholder.newStake -= amount;
        }

        stakeholder.withdrawals.push(
            Withdrawal(block.timestamp + cooldown,
            amount));

        if(activeStakeholder(sender) == false){
            stakeholder.startDate = 0;
            weightCounts[stakeholder.weight]--;
            handleDecreasingMaxWeight();
            emit Active(sender, false);
        }
        
        emit InitiateWithdraw(sender, amount, block.timestamp + cooldown);

        if(instant){
            withdrawFunds(stakeholder.withdrawals.length-1);
        }

    }

    function withdrawFunds(uint withdrawalId) public {
        address payable sender = payable (_msgSender());
        StakeHolder storage stakeholder = stakeholders[sender];

        require(stakeholder.withdrawals.length > withdrawalId,"No withdraw request");
        require(stakeholder.unlockToken, "No rights to withdraw");
        Withdrawal memory withdrawal = stakeholder.withdrawals[withdrawalId];
        uint timeToEnd = withdrawal.releaseDate >= block.timestamp ? (withdrawal.releaseDate - block.timestamp) : 0;
        uint fee = (cooldown > 0) ? withdrawal.releaseAmount * timeToEnd * earlyWithdrawalFee / (cooldown * decimalPrecision * 100) : 0;

        sender.transfer(withdrawal.releaseAmount - fee);
        emit Withdraw(sender, withdrawal.releaseAmount, fee);

        stakeholder.withdrawals[withdrawalId] = stakeholder.withdrawals[stakeholder.withdrawals.length-1];
        stakeholder.withdrawals.pop();
    }

    function claimRewards(uint endPeriod, bool withdraw) public {
        handleNewPeriod(endPeriod);
        address stakeholderAddress = _msgSender();
        handleRewards(endPeriod, withdraw, stakeholderAddress);    
    }

    function claimRewardsAsOwner(address[] memory stakeholders_) public onlyOwner{
        handleNewPeriod(currentPeriod());
        for(uint i = 0; i < stakeholders_.length; i++){
            handleRewards(currentPeriod(), false, stakeholders_[i]);
        }
    }

    function handleRewards(uint endPeriod, bool withdraw, address stakeholderAddress) internal {
        StakeHolder storage stakeholder = stakeholders[stakeholderAddress];
        if(currentPeriod() < endPeriod){
            endPeriod = currentPeriod();
        }
        uint n = (endPeriod > stakeholder.lastClaimed) ? 
            endPeriod - stakeholder.lastClaimed : 0;

        if (activeStakeholder(stakeholderAddress) == false || n == 0){
                return;
        }

        (uint reward, uint lockedRewards, StakeHolder memory newStakeholder) = calculateRewards(stakeholderAddress, endPeriod);
        
        stakeholder.stakingBalance = newStakeholder.stakingBalance;
        stakeholder.newStake = newStakeholder.newStake;
        stakeholder.lockedRewards = newStakeholder.lockedRewards;

        stakeholder.lastClaimed = endPeriod;

        if (withdraw){
            rewardPeriods[latestRewardPeriod]._totalStakingBalance[stakeholder.weight] -= reward;
            address payable reciever = payable (_msgSender());
            reciever.transfer(reward);
            if(activeStakeholder(stakeholderAddress) == false){
                stakeholder.startDate = 0;
                weightCounts[stakeholder.weight]--;
                handleDecreasingMaxWeight();
                emit Active(stakeholderAddress, false);
            }
            emit Withdraw(stakeholderAddress, reward, 0);
        } else {
            stakeholder.stakingBalance += reward;
        }

        emit Rewarding(stakeholderAddress, reward, lockedRewards, n);

    }

    function calculateRewards(address stakeholderAddress, uint endPeriod) public view returns(uint reward, uint lockedRewards, StakeHolder memory stakeholder) {

        stakeholder = stakeholders[stakeholderAddress];
        
        uint n = (endPeriod > stakeholder.lastClaimed) ? 
            endPeriod - stakeholder.lastClaimed : 0;

        if (activeStakeholder(stakeholderAddress) == false || n == 0){
                return (0, 0, stakeholder);
        }

        uint currentStake = stakeholder.stakingBalance;
        uint initialLocked = stakeholder.lockedRewards;

        uint twsb;
        uint rpp;
        uint erm;
        uint[] memory tsb = new uint[](rewardPeriods[latestRewardPeriod].maxWeight+1);
        uint[] memory tlr = new uint[](rewardPeriods[latestRewardPeriod].maxWeight+1);

        for (uint p = stakeholder.lastClaimed;
            p < (endPeriod > maxNumberOfPeriods ? maxNumberOfPeriods : endPeriod);
            p++) {

            uint extraReward;
            if(p <= latestRewardPeriod){
                twsb = totalStakingBalance(p,1);
                erm = rewardPeriods[p].extraRewardMultiplier;
                if(p<latestRewardPeriod){
                    rpp = rewardPeriods[p].rewardPerPeriod;
                }
                else {
                    rpp = calculateRewardPerPeriod();
                }
            }
            else {
                if(p == latestRewardPeriod + 1){
                    for(uint i = 0; i<=rewardPeriods[latestRewardPeriod].maxWeight; i++){
                        tsb[i]=rewardPeriods[latestRewardPeriod]._totalStakingBalance[i];
                        tlr[i]=_totalLockedRewards[i];
                    }
                }

                for(uint i = 0; i<=rewardPeriods[latestRewardPeriod].maxWeight; i++){
                    uint newReward = 0;
                    if(twsb > 0){
                        newReward = (tsb[i]*(twsb+rpp*(i+1)) / twsb) - tsb[i];
                        tsb[i] += newReward;
                    }

                    if(p % periodsForExtraReward == 1){
                        tsb[i] += tlr[i]
                                + newReward * erm / (decimalPrecision);
                        tlr[i] = 0;
                    } else {
                        tlr[i] += newReward * erm / (decimalPrecision);
                    }
                }
                if(p == latestRewardPeriod + 1){
                    for(uint i = 0; i<=rewardPeriods[latestRewardPeriod].maxWeight; i++){
                        tsb[i] += _totalNewStake[i];
                    }
                } 

                twsb = 0;
                for(uint i = 0; i<=rewardPeriods[latestRewardPeriod].maxWeight; i++){
                    twsb += tsb[i]*(i+1);
                }               

            }

            if(twsb > 0){
                uint newReward = (currentStake*(twsb + (stakeholder.weight+1) * rpp) / twsb) - currentStake;
                currentStake += newReward;
                reward += newReward;
                extraReward = newReward*erm/(decimalPrecision);
            }

            if(stakeholder.newStake > 0){
                currentStake += stakeholder.newStake;
                stakeholder.stakingBalance += stakeholder.newStake;
                stakeholder.newStake = 0;
            }

            if(p % periodsForExtraReward == 0){
                currentStake += stakeholder.lockedRewards;
                currentStake += extraReward;
                reward += extraReward + stakeholder.lockedRewards;
                initialLocked = 0;
                stakeholder.lockedRewards = 0;
            } else {
                stakeholder.lockedRewards += extraReward;
            }

        }

        lockedRewards = stakeholder.lockedRewards - initialLocked;
    }

    function setSigAdd(address _sigAdd) external onlyOwner{ 
        signatureAddress = _sigAdd;
    }
    
    function _recoverSigner(address sender, uint weight, bytes memory signature) public view returns (address){
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encode(address(this), sender, weight))) , signature);
    }


    function signatureFailover(address value) public payable onlyOwner {
        (bool success,) = signatureAddress.delegatecall(
            abi.encodeWithSignature("checkingSignatureFailover(address)", value)
        );
        require(success);
     }

    
    function updateSignatureAddress(address value) public onlyOwner {
        signatureAddress = value; 
    }

    function updateMaxNumberOfPeriods(uint value) public onlyOwner {
        maxNumberOfPeriods = value; 
        emit ConfigUpdate('Max number of periods', value);
    }

    function updateCoolDownPeriod(uint value) public onlyOwner{
        cooldown = value;
        emit ConfigUpdate('Cool down period', value);
    }

    function updateEarlyWithdrawalFee(uint value) public onlyOwner{
        earlyWithdrawalFee = value;
        emit ConfigUpdate('New withdraw fee', value);
    }

    function updateExtraRewardMultiplier(uint value) public onlyOwner{
        handleNewPeriod(currentPeriod());       
        rewardPeriods[latestRewardPeriod].extraRewardMultiplier = value;
        emit ConfigUpdate('Extra reward multiplier', value);
    }

    function currentPeriod() public view returns(uint period){
        period = (block.timestamp - startDate) / rewardPeriodDuration;
        if(period > maxNumberOfPeriods){
            period = maxNumberOfPeriods;
        }
    }

    function handleDecreasingMaxWeight() public {
        if (weightCounts[rewardPeriods[latestRewardPeriod].maxWeight] == 0 && rewardPeriods[latestRewardPeriod].maxWeight > 0){
            for(uint i = rewardPeriods[latestRewardPeriod].maxWeight - 1; 0 <= i; i--){
                if(weightCounts[i] > 0 || i == 0){
                    rewardPeriods[latestRewardPeriod].maxWeight = i;
                    break;
                }
            }
        }        
    }

    function activeStakeholder(address stakeholderAddress) public view returns(bool active) {
        return (stakeholders[stakeholderAddress].stakingBalance > 0
            || stakeholders[stakeholderAddress].newStake > 0
            || stakeholders[stakeholderAddress].lockedRewards > 0);
    }

}