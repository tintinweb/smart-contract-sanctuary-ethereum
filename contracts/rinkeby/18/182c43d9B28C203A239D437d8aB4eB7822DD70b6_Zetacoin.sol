// contracts/Zetacoin.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "SigmaProofVerifier.sol";
import "ERC20.sol";
import "IERC20.sol";
import "AccessControlEnumerable.sol";
import "Context.sol";

contract Zetacoin is Context, AccessControlEnumerable{
    IERC20 token;

    // The fixed amount of tokens minted and spent by each call to mint() and spend()
    uint256 constant public AMOUNT = 1000;

    // The list of commitments to (S, r) i.e. the list of coins
    // The length of this list must be a power of 2 at all times
    uint256[] coins;

    // The index of the last coin in the list
    uint256 lastIdx;

    // This is to avoid having to calculate the log_2 of the length of the list
    uint256 logCounter;

    // The list of spent serial numbers S
    // This record is kept to prevent double spending
    uint256[] spentSerialNumbers;

    // Constructor
    constructor(address tokenAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        token = IERC20(tokenAddress);
        lastIdx = 0;
        logCounter = 1;

        // The list of coins must have a minimum size of 2
        // We can't use a commitment to 0, 0 here, as the ECC library doesn't like multiplying a 0 point by a scalar
        coins.push(SigmaProofVerifier.commit(BigNum._new(42), BigNum._new(42)));
        coins.push(SigmaProofVerifier.commit(BigNum._new(42), BigNum._new(42)));
    }

    // Modifier to check token allowance
    modifier checkAllowance(uint256 amount) {
        require(token.allowance(_msgSender(), address(this)) >= amount, "The contract has not been given the necessary allowance");
        _;
    }

    // The mint function adds a commitment to the list of coins and returns its index
    // It then ensures the list has length of a power of 2
    function mint(uint256 commitment) public checkAllowance(AMOUNT) returns(uint256 index) {
        // Deposit the amount in the contract
        token.transferFrom(_msgSender(), address(this), AMOUNT);

        index = lastIdx;
        
        // If the list is already long enough, assign the commitment to the next index
        if (lastIdx < coins.length) {
            coins[lastIdx] = commitment;
        }
        // This means, we have to extend to the next power of 2
        else {
            // Otherwise, append the commitment to the list
            coins.push(commitment);

            // Ensure the list has length of a power of 2 (fill up with some commitments)
            while (coins.length & (coins.length - 1) != 0)
                coins.push(SigmaProofVerifier.commit(BigNum._new(42), BigNum._new(42)));

            logCounter++;
        }
        lastIdx++;
    }

    // The spend function verifies the provided proof and marks the coin as spent
    // If successful, it transacts the ERC20 token to the caller
    // If the proof is invalid, the spend fails and the transaction is reverted
    function spend(uint256 serialNumber, SigmaProofVerifier.Proof memory proof) public returns(bool success) {
        // Check that the serial number has not been spent yet
        bool isSpent = false;
        for (uint256 i = 0; i < spentSerialNumbers.length && !isSpent; i++)
            isSpent = isSpent || (spentSerialNumbers[i] == serialNumber);
        require(!isSpent, "The coin with this serial number has already been spent");

        // Homorphically substract the serial number from the coins
        uint256[] memory commitments = new uint256[](coins.length);
        BigNum.instance memory serialNumberNeg = BigNum.instance(new uint128[](2), true);
        serialNumberNeg.val[0] = uint128(serialNumber & BigNum.LOWER_MASK);
        serialNumberNeg.val[1] = uint128(serialNumber >> 128);
        uint256 negExpSerialNumber = BigNum.modExp(SigmaProofVerifier.G, serialNumberNeg);
        for (uint256 i = 0; i < coins.length; i++)
            commitments[i] = mulmod(coins[i], negExpSerialNumber, BigNum.PRIME);
        
        // Check the proof
        success = SigmaProofVerifier.verify(serialNumber, commitments, logCounter, proof);
        require(success, "The proof is invalid");

        // Mark the coin as spent
        spentSerialNumbers.push(serialNumber);

        // Transfer the ERC20 token to the caller
        token.transfer(_msgSender(), AMOUNT);
    }

    function getCoins() public view returns(uint256[] memory) {
        return coins;
    }

    // Resets the state of the contract
    // Only admmins can reset. This will essentially delete everyones fund
    // Admins can block users from using the underlying Delta-Token anyway
    // -> Remove when deployed outside a CBDC context
    function reset() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Only admins can reset the contract");
        lastIdx = 0;
        logCounter = 1;
        delete coins;
        coins.push(SigmaProofVerifier.commit(BigNum._new(42), BigNum._new(42)));
        coins.push(SigmaProofVerifier.commit(BigNum._new(42), BigNum._new(42)));
        delete spentSerialNumbers;
    }

    // Return the amount of tokens currently held by the contract
    function getBalance() public view returns(uint256 balance) {
        return token.balanceOf(address(this));
    }
}

// contracts/SigmaProofVerifier.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "BigNum.sol";


library SigmaProofVerifier {

    uint256 constant G = 0x57f7c5d58d84b91555c706fa707abfff239c1aa3229f7f59277e14f3925c5523;
    uint256 constant H = 0x378aa97c89749406b334da8fb9757af4e9d320820d474cf4cdad30d7f999f35f;

    struct Proof {
        uint256[] C_l;
        uint256[] C_a;
        uint256[] C_b;
        uint256[] C_d;
        BigNum.instance[] F;
        BigNum.instance[] Z_a;
        BigNum.instance[] Z_b;
        BigNum.instance z_d;
    }

    function commit(BigNum.instance memory m, BigNum.instance memory r) internal view returns (uint256) {
        return mulmod(BigNum.modExp(G, m), BigNum.modExp(H, r), BigNum.PRIME);
    }

    // Check the commitments to l part 1
    function verifyProofCheck1(
        uint256 n,
        BigNum.instance memory x,
        uint256[] memory C_l, 
        uint256[] memory C_a,
        BigNum.instance[] memory F,
        BigNum.instance[] memory Z_a)
    internal view returns (bool check) {
        // Declare the left and right side of the check
        uint256 left;
        uint256 right;

        // Check the commitments to l
        check = true;
        for (uint256 i = 0; i < n; i++) {
            left = BigNum.modExp(C_l[i], x);
            left = mulmod(left, C_a[i], BigNum.PRIME);
            right = commit(F[i], Z_a[i]);
            check = check && left == right;
        }
    }

    // Check the commitments to l part 2
    function verifyProofCheck2(
        uint256 n,
        BigNum.instance memory x,
        uint256[] memory C_l, 
        uint256[] memory C_b,
        BigNum.instance[] memory F,
        BigNum.instance[] memory Z_b)
    internal view returns (bool check) {
        // Declare the left and right side of the check
        uint256 left;
        uint256 right;

        check = true;
        for (uint256 i = 0; i < n; i++) {
            left = BigNum.modExp(C_l[i], BigNum.sub(x, F[i]));
            left = mulmod(left, C_b[i], BigNum.PRIME);
            //ECC.Point memory right = ECC.commit(0, proof.Z_b[i]);
            right = BigNum.modExp(H, Z_b[i]);
            check = check && left == right;
        }
    }

    // Check the commitment to 0
    function verifyProofCheck3(
        uint256 n,
        BigNum.instance memory x,
        uint256[] memory commitments,
        Proof memory proof)
    internal view returns (bool check) {
        // Declare the left and right side of the check
        uint256 left;
        uint256 right;
        
        // N = 2**n
        uint256 N = commitments.length;

        uint256 leftProduct = 1;
        BigNum.instance memory product;
        for (uint256 i = 0; i < N; i++) {
            // Calculate the product of F_j, i_j
            product = BigNum._new(1);
            for (uint256 j = 0; j < n; j++) {
                uint256 i_j = (i >> j) & 1;
                if (i_j == 1)
                    product = BigNum.mul(product, proof.F[j]);
                else
                    product = BigNum.mul(product, BigNum.sub(x, proof.F[j]));
            }
            leftProduct = mulmod(leftProduct, BigNum.modExp(commitments[i], product), BigNum.PRIME);
        }

        // Calculate the sum of the other commitments
        uint256 rightProduct = 1;
        BigNum.instance memory xPowk = BigNum._new(1);
        for (uint256 k = 0; k < n; k++) {
            xPowk.neg = true;
            rightProduct = mulmod(rightProduct, BigNum.modExp(proof.C_d[k], xPowk), BigNum.PRIME);
            xPowk.neg = false;
            xPowk = BigNum.mul(xPowk, x);
        }

        left = mulmod(leftProduct, rightProduct, BigNum.PRIME);
        // ECC.Point memory right = ECC.commit(0, proof.z_d);
        right = BigNum.modExp(H, proof.z_d);
        check = left == right;
    }

    function hashAll(
        uint256 serialNumber,
        bytes memory message,
        uint256[] memory commitments,
        Proof memory proof)
    internal pure returns (bytes32 result) {
        // Hash the serial number
        result = sha256(abi.encodePacked(serialNumber));

        // Hash the message
        result = sha256(abi.encodePacked(result, message));

        // Hash the ECC curve generator points
        result = sha256(abi.encodePacked(result, G));
        result = sha256(abi.encodePacked(result, H));

        // Hash the commitments
        for (uint256 i = 0; i < commitments.length; i++)
            result = sha256(abi.encodePacked(result, commitments[i]));
        for (uint256 i = 0; i < proof.C_l.length; i++)
            result = sha256(abi.encodePacked(result, proof.C_l[i]));
        for (uint256 i = 0; i < proof.C_a.length; i++)
            result = sha256(abi.encodePacked(result, proof.C_a[i]));
        for (uint256 i = 0; i < proof.C_b.length; i++)
            result = sha256(abi.encodePacked(result, proof.C_b[i]));
        for (uint256 i = 0; i < proof.C_d.length; i++)
            result = sha256(abi.encodePacked(result, proof.C_d[i]));
    }

    function verify(
        uint256 serialNumber,
        uint256[] memory commitments,
        uint256 n,
        Proof memory proof)
    internal view returns (bool result) {
        // Compute the hash used for the challenge
        uint256 xInt = uint256(hashAll(serialNumber, "Adrian", commitments, proof));
        BigNum.instance memory x = BigNum.instance(new uint128[](2), false);
        x.val[0] = uint128(xInt & BigNum.LOWER_MASK);
        x.val[1] = uint128(xInt >> 128);

        result = verifyProofCheck1(n, x, proof.C_l, proof.C_a, proof.F, proof.Z_a);
        result = result && verifyProofCheck2(n, x, proof.C_l, proof.C_b, proof.F, proof.Z_b);
        result = result && verifyProofCheck3(n, x, commitments, proof);
    }
}

// contracts/BigNum.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library BigNum {
    
    struct instance {
        uint128[] val;
        bool neg;
    }

    uint256 constant LOWER_MASK = 2**128 - 1;
    //uint256 constant PRIME = 0xffffffff00000001000000000000000000000000ffffffffffffffffffffffff;
    uint256 constant PRIME = 0x83b4f95d30d4f5c4d271f66f220b41547ad121eefbf8d2ab745e5cefd2ef3123;

    function _new(int128 num) internal pure returns (instance memory) {
        instance memory ret;
        ret.val = new uint128[](1);
        if (num < 0) {
            ret.neg = true;
            ret.val[0] = uint128(-num);
        } else {
            ret.neg = false;
            ret.val[0] = uint128(num);
        }
        return ret;
    }

    function addInternal(uint128[] memory max, uint128[] memory min) internal pure returns (uint128[] memory) {

        // TODO: Only add 1 if overflow
        uint128[] memory result = new uint128[](max.length + 1);
        uint256 carry = 0;

        for (uint i = 0; i < max.length; i++) {
            uint256 intermediate = 0;
            if (i < min.length)
                intermediate = uint256(max[i]) + uint256(min[i]) + carry;
            else
                intermediate = uint256(max[i]) + carry;

            uint128 lower = uint128(intermediate & LOWER_MASK);
            carry = intermediate >> 128;

            result[i] = lower;
        }

        // if there remains a carry, add it to the result
        if (carry > 0) {
            result[result.length - 1] = uint128(carry);
        // Otherwise get rid of the extra bit
        }
        else {
            // resullt.length--
            assembly { mstore(result, sub(mload(result), 1)) }
        }
        return result;
    }

    function subInternal(uint128[] memory max, uint128[] memory min) internal pure returns (uint128[] memory) {
        
        uint128[] memory result = new uint128[](max.length);
        int256 carry = 0;

        for (uint i = 0; i < max.length; i++) {
            int256 intermediate = 0;
            if (i < min.length)
                intermediate = int256(uint256(max[i])) - int256(uint256(min[i])) - carry;
            else
                intermediate = int256(uint256(max[i])) - carry;

            if (intermediate < 0) {
                intermediate += 2**128;
                carry = 1;
            } else {
                carry = 0;
            }

            result[i] = uint128(uint256(intermediate));
        }

        // Clean up leading zeros
        while (result.length > 1 && result[result.length - 1] == 0)
            // result.length--;
            assembly { mstore(result, sub(mload(result), 1)) }


        return result;
    }

    function mulInternal(uint128[] memory left, uint128[] memory right) internal pure returns (uint128[] memory) {
        uint128[] memory result = new uint128[](left.length + right.length);
       
        // calculate left[i] * right
        for (uint256 i = 0; i < left.length; i++) {
            uint256 carry = 0;

            // calculate left[i] * right[j]
            for (uint256 j = 0; j < right.length; j++) {
                // Multiply with current digit of first number and add result to previously stored result at current position.
                uint256 tmp = uint256(left[i]) * uint256(right[j]);

                uint256 tmpLower = tmp & LOWER_MASK;
                uint256 tmpUpper = tmp >> 128;

                // Add both tmpLower and tmpHigher to the correct positions and take care of the carry
                uint256 intermediateLower = tmpLower + uint256(result[i + j]);
			    result[i + j] = uint128(intermediateLower & LOWER_MASK);
			    uint256 intermediateCarry = intermediateLower >> 128;

			    uint256 intermediateUpper = tmpUpper + uint256(result[i + j + 1]) + intermediateCarry + carry;
			    result[i + j + 1] = uint128(intermediateUpper & LOWER_MASK);
			    carry = intermediateUpper >> 128;
            }
        }
        // Get rid of leading zeros
        while (result.length > 1 && result[result.length - 1] == 0)
            // result.length--;
            assembly { mstore(result, sub(mload(result), 1)) }

        return result;
    }

    // Only compares absolute values
    function compare(uint128[] memory left, uint128[] memory right) internal pure returns(int)
    {
        if (left.length > right.length)
            return 1;
        if (left.length < right.length)
            return -1;
        
        // From here on we know that both numbers are the same bit size
	    // Therefore, we have to check the bytes, starting from the most significant one
        for (uint i = left.length; i > 0; i--) {
            if (left[i-1] > right[i-1])
                return 1;
            if (left[i-1] < right[i-1])
                return -1;
        }

        // Check the least significant byte
        if (left[0] > right[0])
            return 1;
        if (left[0] < right[0])
            return -1;
        
        // Only if all of the bytes are equal, return 0
        return 0;
    }

    function add(instance memory left, instance memory right) internal pure returns (instance memory)
    {
        int cmp = compare(left.val, right.val);

        if (left.neg || right.neg) {
            if (left.neg && right.neg) {
                if (cmp > 0)
                    return instance(addInternal(left.val, right.val), true);
                else
                    return instance(addInternal(right.val, left.val), true);
            }
            else {
                if (cmp > 0)
                    return instance(subInternal(left.val, right.val), left.neg);
                else
                    return instance(subInternal(right.val, left.val), !left.neg);
            }
        }
        else {
            if (cmp > 0)
                    return instance(addInternal(left.val, right.val), false);
                else
                    return instance(addInternal(right.val, left.val), false);
        }
    }

    // This function is not strictly neccessary, as add can be used for subtraction as well
    function sub(instance memory left, instance memory right) internal pure returns (instance memory)
    {
        int cmp = compare(left.val, right.val);

        if (left.neg || right.neg) {
            if (left.neg && right.neg) {
                if (cmp > 0)
                    return instance(subInternal(left.val, right.val), true);
                else
                    return instance(subInternal(right.val, left.val), false);
            }
            else {
                if (cmp > 0)
                    return instance(addInternal(left.val, right.val), left.neg);
                else
                    return instance(addInternal(right.val, left.val), left.neg);
            }
        }
        else {
            if (cmp > 0)
                    return instance(subInternal(left.val, right.val), false);
                else
                    return instance(subInternal(right.val, left.val), true);
        }
    }

    function mul(instance memory left, instance memory right) internal pure returns (instance memory)
    {
        if ((left.neg && right.neg) || (!left.neg && !right.neg))
            return instance(mulInternal(left.val, right.val), false);
        else
            return instance(mulInternal(left.val, right.val), true);
    }

    // Needed as there are multiple valid representations of 0
    function isZero(instance memory num) internal pure returns(bool) {
        if (num.val.length == 0) {
            return true;
        }
        else {
            // all the array items must be zero
            for (uint i = 0; i < num.val.length; i++) {
                if (num.val[i] != 0)
                    return false;
            }
        }
        return true;
    }

    // This function is inspired by https://github.com/monicanagent/cypherpoker/issues/5
    // Note: exp values must be 255 or shorter, otherwise the loop counter overflows
    // -> This isn't an issue as the function is only called with exponents that are 128 bit max
    // function modExp(uint256 base, uint256 exp) internal pure returns (uint256 result)  {
    //     result = 1;
    //     if (exp > 2**255 - 1) {
    //         for (uint count = 1; count <= exp / 2; count *= 2) {
    //             if (exp & count != 0)
    //                 result = mulmod(result, base, PRIME);
    //             base = mulmod(base, base, PRIME);
    //         }
    //         if (exp & 1 << 255 != 0)
    //             result = mulmod(result, base, PRIME);
    //     }
    //     else {
    //         for (uint count = 1; count <= exp; count *= 2) {
    //             if (exp & count != 0)
    //                 result = mulmod(result, base, PRIME);
    //             base = mulmod(base, base, PRIME);
    //         }
    //     }
    // }

    // Inspired by https://medium.com/@rbkhmrcr/precompiles-solidity-e5d29bd428c4
    function modExp(uint256 base, uint256 e) internal view returns (uint256 result) {
        assembly {
            // define pointer
            let p := mload(0x40)
            // store data assembly-favouring ways
            mstore(p, 0x20)             // Length of Base
            mstore(add(p, 0x20), 0x20)  // Length of Exponent
            mstore(add(p, 0x40), 0x20)  // Length of Modulus
            mstore(add(p, 0x60), base)  // Base
            mstore(add(p, 0x80), e)     // Exponent
            mstore(add(p, 0xa0), PRIME) // Modulus
            if iszero(staticcall(sub(gas(), 2000), 0x05, p, 0xc0, p, 0x20)) {
                revert(0, 0)
            }
            // data
            result := mload(p)
        }
    }


    // Calculates a uint256 to the power of a big number mod p
    function modExp(uint256 base, BigNum.instance memory power) internal view returns (uint256 result) {
        // 0 or 1 to the power of anything is 0 or 1 respectively
        if (base == 0 || base == 1)
            return base;

        // When calculating a negative power, we have to invert the base
        // Use Fermats little theorem to calculate the multiplicative inverse
        if (power.neg == true)
            base = modExp(base, PRIME - 2);

        result = 1;
        for (uint256 i = 0; i < power.val.length; i++) {
            uint256 tmp = base;
            // Multiply the correct power of 128
            for (uint256 j = 0; j < i; j++)
                tmp = modExp(tmp, 2**128);
            tmp = modExp(tmp, uint256(power.val[i]));
            result = mulmod(result, tmp, PRIME);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "IAccessControlEnumerable.sol";
import "AccessControl.sol";
import "EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "IAccessControl.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}