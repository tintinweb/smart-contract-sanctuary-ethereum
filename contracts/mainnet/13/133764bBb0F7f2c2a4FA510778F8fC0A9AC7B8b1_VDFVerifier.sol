// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BigNumber.sol";
import "./IsPrime.sol";
import "../policy/PolicedUtils.sol";

/** @title On-the-chain verification for RSA 2K VDF
 */
contract VDFVerifier is PolicedUtils, IsPrime {
    using BigNumber for BigNumber.Instance;

    /* 2048-bit modulus from RSA-2048 challenge
     * https://en.wikipedia.org/wiki/RSA_Factoring_Challenge
     * Our security assumptions rely on RSA challenge rules:
     * No attacker knows or can obtain the factorization
     * Factorization wasn't recorded on generation of the number.
     */

    bytes public constant N =
        hex"c7970ceedcc3b0754490201a7aa613cd73911081c790f5f1a8726f463550bb5b7ff0db8e1ea1189ec72f93d1650011bd721aeeacc2acde32a04107f0648c2813a31f5b0b7765ff8b44b4b6ffc93384b646eb09c7cf5e8592d40ea33c80039f35b4f14a04b51f7bfd781be4d1673164ba8eb991c2c4d730bbbe35f592bdef524af7e8daefd26c66fc02c479af89d64d373f442709439de66ceb955f3ea37d5159f6135809f85334b5cb1813addc80cd05609f10ac6a95ad65872c909525bdad32bc729592642920f24c61dc5b3c3b7923e56b16a4d9d373d8721f24a3fc0f1b3131f55615172866bccc30f95054c824e733a5eb6817f7bc16399d48c6361cc7e5";
    uint256 public constant MIN_BYTES = 64;

    /* The State is a data structure that tracks progress of a logical single verification session
     * from a single verifier. Once verification is complete,
     * state is removed, and (if succesfully verified) replaced by a entry
     * in verified
     */
    struct State {
        uint256 progress; // progress: 1 .. t-1
        uint256 t;
        uint256 x;
        bytes32 concatHash;
        BigNumber.Instance y;
        BigNumber.Instance xi;
        BigNumber.Instance yi;
    }

    // Mapping from verifier to state
    mapping(address => State) private state;

    /** @notice Mapping from keccak256(t, x) to keccak256(y)
     */
    mapping(bytes32 => bytes32) public verified;

    /* Event to be emitted when verification is complete.
     */
    event SuccessfulVerification(uint256 x, uint256 t, bytes y);

    /**
     * @notice Construct the contract with global parameters.
     */
    // solhint-disable-next-line no-empty-blocks
    constructor(Policy _policy) PolicedUtils(_policy) {
        // uses PolicedUtils constructor
    }

    /**
     * @notice Start the verification process
     * This starts the submission of a proof that (x^(2^(2^t+1)))==y
     * @notice The caller should have already set the prime number, _x, to use in the random inflation
     * contract.
     */
    function start(
        uint256 _x,
        uint256 _t,
        bytes calldata _ybytes
    ) external {
        require(
            verified[keccak256(abi.encode(_t, _x))] == bytes32(0),
            "this _x, _t combination has already been verified"
        );

        require(_t >= 2, "t must be at least 2");

        require(_x > 1, "The commitment (x) must be > 1");

        BigNumber.Instance memory n = BigNumber.from(N);
        BigNumber.Instance memory x = BigNumber.from(_x);
        BigNumber.Instance memory y = BigNumber.from(_ybytes);
        BigNumber.Instance memory x2 = BigNumber.multiply(x, x);

        require(
            y.minimalByteLength() >= MIN_BYTES,
            "The secret (y) must be at least 64 bytes long"
        );
        require(BigNumber.cmp(y, n) == -1, "y must be less than N");

        State storage currentState = state[msg.sender];

        currentState.progress = 1; // reset the contract
        currentState.t = _t;

        currentState.x = _x;
        currentState.y = y;

        currentState.xi = x2; // our time-lock-puzzle is for x2 = x^2; x2 is a QR mod n
        currentState.yi = y;
        currentState.concatHash = keccak256(
            abi.encodePacked(_x, y.asBytes(n.byteLength()))
        );
    }

    /**
     * @notice Submit next step of proof
     * To be continuously called with progress = 1 ... t-1 and corresponding u, inclusively.
     * progress input parameter indicates the expected value of progress after the successful processing of this step.
     *
     * So, we start with s.progress == 0 and call with progress=1, ... t-1. Once we set s.progress = t-1, we have
     * completed the verification successfully.
     *
     * In other words, the input is effectively (i, U_sqrt[i]).
     */
    function update(bytes calldata _ubytes) external {
        State storage s = state[msg.sender]; // saves gas

        require(s.progress > 0, "process has not yet been started");

        BigNumber.Instance memory n = BigNumber.from(N); // save in memory
        BigNumber.Instance memory one = BigNumber.from(1);
        BigNumber.Instance memory two = BigNumber.from(2);

        BigNumber.Instance memory u = BigNumber.from(_ubytes);
        BigNumber.Instance memory u2 = BigNumber.modexp(u, two, n); // u2 = u^2 mod n

        require(BigNumber.cmp(u, one) == 1, "u must be greater than 1");
        require(BigNumber.cmp(u, n) == -1, "u must be less than N");
        require(BigNumber.cmp(u2, one) == 1, "u*u must be greater than 1");

        uint256 nlen = n.byteLength();

        uint256 nextProgress = s.progress;

        BigNumber.Instance memory r = BigNumber.from(
            uint256(
                keccak256(
                    abi.encodePacked(
                        s.concatHash,
                        u.asBytes(nlen),
                        nextProgress
                    )
                )
            )
        );

        nextProgress++;

        BigNumber.Instance memory xi = BigNumber.modmul(
            BigNumber.modexp(s.xi, r, n),
            u2,
            n
        ); // xi^r * u^2
        BigNumber.Instance memory yi = BigNumber.modmul(
            BigNumber.modexp(u2, r, n),
            s.yi,
            n
        ); // u^2*r * y

        if (nextProgress != s.t) {
            // Intermediate step
            s.xi = xi;
            s.yi = yi;

            s.progress = nextProgress; // this becomes t-1 for the last step
        } else {
            // Final step. Finalize calculations.
            xi = xi.modexp(BigNumber.from(4), n); // xi^4. Must match yi

            require(
                BigNumber.cmp(xi, yi) == 0,
                "Verification failed in the last step"
            );

            // Success! Fall through

            verified[keccak256(abi.encode(s.t, s.x))] = keccak256(
                s.y.asBytes(nlen)
            );

            emit SuccessfulVerification(s.x, s.t, s.y.asBytes());
            delete (state[msg.sender]);
        }
    }

    /**
     * @notice Return verified state
     * @return true iff (x^(2^(2^t+1)))==y has been proven
     */
    function isVerified(
        uint256 _x,
        uint256 _t,
        bytes calldata _ybytes
    ) external view returns (bool) {
        BigNumber.Instance memory y = BigNumber.from(_ybytes);
        uint256 nlen = N.length;
        return
            verified[keccak256(abi.encode(_t, _x))] ==
            keccak256(y.asBytes(nlen));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

import "../clone/CloneFactory.sol";
import "./Policed.sol";
import "./ERC1820Client.sol";

/** @title Utility providing helpers for policed contracts
 *
 * See documentation for Policed to understand what a policed contract is.
 */
abstract contract PolicedUtils is Policed, CloneFactory {
    bytes32 internal constant ID_FAUCET = keccak256("Faucet");
    bytes32 internal constant ID_ECO = keccak256("ECO");
    bytes32 internal constant ID_ECOX = keccak256("ECOx");
    bytes32 internal constant ID_TIMED_POLICIES = keccak256("TimedPolicies");
    bytes32 internal constant ID_TRUSTED_NODES = keccak256("TrustedNodes");
    bytes32 internal constant ID_POLICY_PROPOSALS =
        keccak256("PolicyProposals");
    bytes32 internal constant ID_POLICY_VOTES = keccak256("PolicyVotes");
    bytes32 internal constant ID_CURRENCY_GOVERNANCE =
        keccak256("CurrencyGovernance");
    bytes32 internal constant ID_CURRENCY_TIMER = keccak256("CurrencyTimer");
    bytes32 internal constant ID_ECOXSTAKING = keccak256("ECOxStaking");

    // The minimum time of a generation.
    uint256 public constant MIN_GENERATION_DURATION = 14 days;
    // The initial generation
    uint256 public constant GENERATION_START = 1000;

    address internal expectedInterfaceSet;

    constructor(Policy _policy) Policed(_policy) {}

    /** ERC1820 permissioning interface
     *
     * @param _addr The address of the contract we might act on behalf of.
     */
    function canImplementInterfaceForAddress(bytes32, address _addr)
        external
        view
        override
        returns (bytes32)
    {
        require(
            _addr == address(policy) || _addr == expectedInterfaceSet,
            "Only the policy or interface contract can set the interface"
        );
        return ERC1820_ACCEPT_MAGIC;
    }

    /** Set the expected interface set
     */
    function setExpectedInterfaceSet(address _addr) public onlyPolicy {
        expectedInterfaceSet = _addr;
    }

    /** Create a clone of this contract
     *
     * Creates a clone of this contract by instantiating a proxy at a new
     * address and initializing it based on the current contract. Uses
     * optionality.io's CloneFactory functionality.
     *
     * This is used to save gas cost during deployments. Rather than including
     * the full contract code in every contract that might instantiate it we
     * can deploy it once and reference the location it was deployed to. Then
     * calls to clone() can be used to create instances as needed without
     * increasing the code size of the instantiating contract.
     */
    function clone() public virtual returns (address) {
        require(
            implementation() == address(this),
            "This method cannot be called on clones"
        );
        address _clone = createClone(address(this));
        PolicedUtils(_clone).initialize(address(this));
        return _clone;
    }

    /** Find the policy contract for a particular identifier.
     *
     * This is intended as a helper function for contracts that are managed by
     * a policy framework. A typical use case is checking if the address calling
     * a function is the authorized policy for a particular action.
     *
     * eg:
     * ```
     * function doSomethingPrivileged() public {
     *   require(
     *     msg.sender == policyFor(keccak256("PolicyForDoingPrivilegedThing")),
     *     "Only the privileged contract may call this"
     *     );
     * }
     * ```
     */
    function policyFor(bytes32 _id) internal view returns (address) {
        return ERC1820REGISTRY.getInterfaceImplementer(address(policy), _id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** @title Probable prime tester with Miller-Rabin
 */
contract IsPrime {
    /* Compute modular exponentiation using the modexp precompile contract
     * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-198.md
     */
    function expmod(
        uint256 _x,
        uint256 _e,
        uint256 _n
    ) private view returns (uint256 r) {
        assembly {
            let p := mload(0x40) // Load free memory pointer
            mstore(p, 0x20) // Store length of x (256 bit)
            mstore(add(p, 0x20), 0x20) // Store length of e (256 bit)
            mstore(add(p, 0x40), 0x20) // Store length of N (256 bit)
            mstore(add(p, 0x60), _x) // Store x
            mstore(add(p, 0x80), _e) // Store e
            mstore(add(p, 0xa0), _n) // Store n

            // Call precompiled modexp contract, input and output at p
            if iszero(staticcall(gas(), 0x05, p, 0xc0, p, 0x20)) {
                // revert if failed
                revert(0, 0)
            }
            // Load output (256 bit)
            r := mload(p)
        }
    }

    /** @notice Test if number is probable prime
     * Probability of false positive is (1/4)**_k
     * @param _n Number to be tested for primality
     * @param _k Number of iterations
     */
    function isProbablePrime(uint256 _n, uint256 _k)
        public
        view
        returns (bool)
    {
        if (_n == 2 || _n == 3 || _n == 5) {
            return true;
        }
        if (_n == 1 || (_n & 1 == 0)) {
            return false;
        }

        uint256 s = 0;
        uint256 _n3 = _n - 3;
        uint256 _n1 = _n - 1;
        uint256 d = _n1;

        //calculate the trailing zeros on the binary representation of the number
        if (d << 128 == 0) {
            d >>= 128;
            s += 128;
        }
        if (d << 192 == 0) {
            d >>= 64;
            s += 64;
        }
        if (d << 224 == 0) {
            d >>= 32;
            s += 32;
        }
        if (d << 240 == 0) {
            d >>= 16;
            s += 16;
        }
        if (d << 248 == 0) {
            d >>= 8;
            s += 8;
        }
        if (d << 252 == 0) {
            d >>= 4;
            s += 4;
        }
        if (d << 254 == 0) {
            d >>= 2;
            s += 2;
        }
        if (d << 255 == 0) {
            d >>= 1;
            s += 1;
        }

        bytes32 prevBlockHash = blockhash(block.number - 1);

        for (uint256 i = 0; i < _k; ++i) {
            bytes32 hash = keccak256(abi.encode(prevBlockHash, i));
            uint256 a = (uint256(hash) % _n3) + 2;
            uint256 x = expmod(a, d, _n);
            if (x != 1 && x != _n1) {
                uint256 j;
                for (j = 0; j < s; ++j) {
                    x = mulmod(x, x, _n);
                    if (x == _n1) {
                        break;
                    }
                }
                if (j == s) {
                    return false;
                }
            }
        }

        return true;
    }
}

pragma solidity ^0.8.0;

/*
MIT License

Copyright (c) 2017 zcoinofficial

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// Originated from https://github.com/zcoinofficial/solidity-BigNumber

// SPDX-License-Identifier: MIT

// solhint-disable no-inline-assembly, no-empty-blocks, function-max-lines

/**
 * @title Big integer math library
 */
library BigNumber {
    /*
     * BigNumber is defined as a struct named 'Instance' to avoid naming conflicts.
     * DO NOT ALLOW INSTANTIATING THIS DIRECTLY - use the 'from' functions defined below.
     * Hoping in future Solidity will allow visibility modifiers on structs.
     */

    // @notice store bytes in word-size (32 byte) chunks
    struct Instance {
        bytes32[] value;
    }

    /**
     * @notice Create a new Bignumber instance from byte array
     * @dev    If the caller subsequently clears or modifies the input _value, it will corrupt the BigNumber value.
     * @param _value Number stored in big endian bytes
     * @return instance of BigNumber
     */
    function from(bytes memory _value) internal view returns (Instance memory) {
        uint256 length = _value.length;
        if (length == 0) {
            // Zero
            return Instance(new bytes32[](0));
        }
        uint256 numSlots = (length + 31) >> 5;
        Instance memory _instance = Instance(new bytes32[](numSlots));

        // ensure there aren't any leading zero words
        // this is not the zeroOffset yet, this is the modulo of the length
        uint256 zeroOffset = length & 0x1f;
        bytes32 word;
        if (zeroOffset == 0) {
            assembly {
                // load the first word from _value
                word := mload(add(_value, 0x20))
            }
            require(
                word != 0,
                "High-word must be set when input is bytes32-aligned"
            );
        } else {
            // calculate zeroOffset
            zeroOffset = 32 - zeroOffset;
            assembly {
                // load the first word from _value
                word := shr(mul(0x8, zeroOffset), mload(add(_value, 0x20)))
            }
            require(
                word != 0,
                "High-word must be set when input is bytes32-aligned"
            );
        }

        assembly {
            /*
            Call precompiled contract to copy data
            gas cost is 15 + 3/word
            there is no packing for structs in memory, so we just load the slot for _instance
            shift 32 bytes to skip the length value of each reference type
            shift an additional 32 - offset bits on the result to naturally create the offset
            */
            if iszero(
                staticcall(
                    add(0x0f, mul(0x03, numSlots)),
                    0x04,
                    add(_value, 0x20),
                    length,
                    add(mload(_instance), add(0x20, zeroOffset)),
                    length
                )
            ) {
                revert(0, 0)
            }
        }

        return _instance;
    }

    /**
     * @notice Create a new BigNumber instance from uint256
     * @param _value Number stored in uint256
     * @return instance of BigNumber
     */
    function from(uint256 _value)
        internal
        pure
        returns (Instance memory instance)
    {
        if (_value != 0x0) {
            instance = Instance(new bytes32[](1));
            instance.value[0] = bytes32(_value);
        }
    }

    /**
     * @notice Convert instance to padded byte array
     * @param _instance BigNumber instance to convert
     * @param _size Desired size of byte array
     * @return result byte array
     */
    function asBytes(Instance memory _instance, uint256 _size)
        internal
        view
        returns (bytes memory)
    {
        uint256 length = _instance.value.length;
        require(_size & 0x1f == 0x0, "Size must be multiple of 0x20");

        uint256 _byteLength = length << 5;
        require(_size >= _byteLength, "Number too large to represent");

        uint256 zeroOffset = _size - _byteLength;
        bytes memory result = new bytes(_size);

        assembly {
            /*
            Call precompiled contract to copy data
            gas cost is 15 + 3/word
            there is no packing for structs in memory, so we just load the slot for _instance
            shift 32 bytes to skip the length value of each reference type
            shift an additional zeroOffset bits on the result to naturally create the offset
            */
            if iszero(
                staticcall(
                    add(0x0f, mul(0x03, length)),
                    0x04,
                    add(mload(_instance), 0x20),
                    _byteLength,
                    add(result, add(0x20, zeroOffset)),
                    _byteLength
                )
            ) {
                revert(0, 0)
            }
        }

        return result;
    }

    /**
     * @notice Convert instance to minimal byte array
     * @param _instance BigNumber instance to convert
     * @return result byte array
     */
    function asBytes(Instance memory _instance)
        internal
        view
        returns (bytes memory)
    {
        uint256 _length = _instance.value.length;
        if (_length == 0) {
            return new bytes(0);
        }

        bytes32 firstWord = _instance.value[0];
        uint256 zeroOffset = 0;
        if (firstWord >> 128 == 0) {
            firstWord <<= 128;
            zeroOffset += 16;
        }
        if (firstWord >> 192 == 0) {
            firstWord <<= 64;
            zeroOffset += 8;
        }
        if (firstWord >> 224 == 0) {
            firstWord <<= 32;
            zeroOffset += 4;
        }
        if (firstWord >> 240 == 0) {
            firstWord <<= 16;
            zeroOffset += 2;
        }
        if (firstWord >> 248 == 0) {
            zeroOffset += 1;
        }

        uint256 _byteLength = (_length << 5) - zeroOffset;

        bytes memory result = new bytes(_byteLength);

        assembly {
            /*
            Call precompiled contract to copy data
            gas cost is 15 + 3/word
            there is no packing for structs in memory, so we just load the slot for _instance
            shift 32 bytes to skip the length value of each reference type
            shift an additional 32 + zeroOffset bits on the result to naturally create the offset
            */
            if iszero(
                staticcall(
                    add(0x0f, mul(0x03, _length)),
                    0x04,
                    add(mload(_instance), add(0x20, zeroOffset)),
                    _byteLength,
                    add(result, 0x20),
                    _byteLength
                )
            ) {
                revert(0, 0)
            }
        }

        return result;
    }

    /**
     * @notice Obtain length (in bytes) of BigNumber instance
     * This will be rounded up to nearest multiple of 0x20 bytes
     *
     * @param _instance BigNumber instance
     * @return Size (in bytes) of BigNumber instance
     */
    function byteLength(Instance memory _instance)
        internal
        pure
        returns (uint256)
    {
        return _instance.value.length << 5;
    }

    /**
     * @notice Obtain minimal length (in bytes) of BigNumber instance
     *
     * @param _instance BigNumber instance
     * @return Size (in bytes) of minimal BigNumber instance
     */
    function minimalByteLength(Instance memory _instance)
        internal
        pure
        returns (uint256)
    {
        uint256 _byteLength = byteLength(_instance);

        if (_byteLength == 0) {
            return 0;
        }

        bytes32 firstWord = _instance.value[0];
        uint256 zeroOffset = 0;
        if (firstWord >> 128 == 0) {
            firstWord <<= 128;
            zeroOffset += 16;
        }
        if (firstWord >> 192 == 0) {
            firstWord <<= 64;
            zeroOffset += 8;
        }
        if (firstWord >> 224 == 0) {
            firstWord <<= 32;
            zeroOffset += 4;
        }
        if (firstWord >> 240 == 0) {
            firstWord <<= 16;
            zeroOffset += 2;
        }
        if (firstWord >> 248 == 0) {
            zeroOffset += 1;
        }

        return _byteLength - zeroOffset;
    }

    /**
     * @notice Perform modular exponentiation of BigNumber instance
     * @param _base Base number
     * @param _exponent Exponent
     * @param _modulus Modulus
     * @return result (_base ^ _exponent) % _modulus
     */
    function modexp(
        Instance memory _base,
        Instance memory _exponent,
        Instance memory _modulus
    ) internal view returns (Instance memory result) {
        result.value = innerModExp(
            _base.value,
            _exponent.value,
            _modulus.value
        );
    }

    /**
     * @notice Perform modular multiplication of BigNumber instances
     * @param _a number
     * @param _b number
     * @param _modulus Modulus
     * @return (_a * _b) % _modulus
     */
    function modmul(
        Instance memory _a,
        Instance memory _b,
        Instance memory _modulus
    ) internal view returns (Instance memory) {
        return modulo(multiply(_a, _b), _modulus);
    }

    /**
     * @notice Compare two BigNumber instances for equality
     * @param _a number
     * @param _b number
     * @return -1 if (_a<_b), 1 if (_a>_b) and 0 if (_a==_b)
     */
    function cmp(Instance memory _a, Instance memory _b)
        internal
        pure
        returns (int256)
    {
        uint256 aLength = _a.value.length;
        uint256 bLength = _b.value.length;
        if (aLength > bLength) return 0x1;
        if (bLength > aLength) return -0x1;

        bytes32 aWord;
        bytes32 bWord;

        for (uint256 i = 0; i < _a.value.length; i++) {
            aWord = _a.value[i];
            bWord = _b.value[i];

            if (aWord > bWord) {
                return 1;
            }
            if (bWord > aWord) {
                return -1;
            }
        }

        return 0;
    }

    /**
     * @notice Add two BigNumber instances
     * Not used outside the library itself
     */
    function privateAdd(Instance memory _a, Instance memory _b)
        internal
        pure
        returns (Instance memory instance)
    {
        uint256 aLength = _a.value.length;
        uint256 bLength = _b.value.length;
        if (aLength == 0) return _b;
        if (bLength == 0) return _a;

        if (aLength >= bLength) {
            instance.value = innerAdd(_a.value, _b.value);
        } else {
            instance.value = innerAdd(_b.value, _a.value);
        }
    }

    /**
     * @dev max + min
     */
    function innerAdd(bytes32[] memory _max, bytes32[] memory _min)
        private
        pure
        returns (bytes32[] memory result)
    {
        assembly {
            // Get the highest available block of memory
            let result_start := mload(0x40)

            // uint256 max (all bits set; inverse of 0)
            let uint_max := not(0x0)

            let carry := 0x0

            // load lengths of inputs
            let max_len := shl(5, mload(_max))
            let min_len := shl(5, mload(_min))

            // point to last word of each byte array.
            let max_ptr := add(_max, max_len)
            let min_ptr := add(_min, min_len)

            // set result_ptr end.
            let result_ptr := add(add(result_start, 0x20), max_len)

            // while 'min' words are still available
            // for(int i=0; i<min_length; i+=0x20)
            for {
                let i := 0x0
            } lt(i, min_len) {
                i := add(i, 0x20)
            } {
                // get next word for 'max'
                let max_val := mload(max_ptr)
                // get next word for 'min'
                let min_val := mload(min_ptr)

                // check if we need to carry over to a new word
                // sum of both words that we're adding
                let min_max := add(min_val, max_val)
                // plus the carry amount if there is one
                let min_max_carry := add(min_max, carry)
                // store result
                mstore(result_ptr, min_max_carry)
                // carry again if we've overflowed
                carry := or(lt(min_max, min_val), lt(min_max_carry, carry))
                // point to next 'min' word
                min_ptr := sub(min_ptr, 0x20)

                // point to next 'result' word
                result_ptr := sub(result_ptr, 0x20)
                // point to next 'max' word
                max_ptr := sub(max_ptr, 0x20)
            }

            // remainder after 'min' words are complete.
            // for(int i=min_length; i<max_length; i+=0x20)
            for {
                let i := min_len
            } lt(i, max_len) {
                i := add(i, 0x20)
            } {
                // get next word for 'max'
                let max_val := mload(max_ptr)

                // result_word = max_word+carry
                let max_carry := add(max_val, carry)
                mstore(result_ptr, max_carry)
                // finds whether or not to set the carry bit for the next iteration.
                carry := lt(max_carry, carry)

                // point to next 'result' word
                result_ptr := sub(result_ptr, 0x20)
                // point to next 'max' word
                max_ptr := sub(max_ptr, 0x20)
            }

            // store the carry bit
            mstore(result_ptr, carry)
            // move result ptr up by a slot if no carry
            result := add(result_start, sub(0x20, shl(0x5, carry)))

            // store length of result. we are finished with the byte array.
            mstore(result, add(shr(5, max_len), carry))

            // Update freemem pointer to point to new end of memory.
            mstore(0x40, add(result, add(shl(5, mload(result)), 0x20)))
        }
    }

    /**
     * @notice Return absolute difference between two instances
     * Not used outside the library itself
     */
    function absdiff(Instance memory _a, Instance memory _b)
        internal
        pure
        returns (Instance memory instance)
    {
        int256 compare = cmp(_a, _b);

        if (compare == 1) {
            instance.value = innerDiff(_a.value, _b.value);
        } else if (compare == -0x1) {
            instance.value = innerDiff(_b.value, _a.value);
        }
    }

    /**
     * @dev max - min
     */
    function innerDiff(bytes32[] memory _max, bytes32[] memory _min)
        private
        pure
        returns (bytes32[] memory result)
    {
        uint256 carry = 0x0;
        assembly {
            // Get the highest available block of memory
            let result_start := mload(0x40)

            // uint256 max. (all bits set; inverse of 0)
            let uint_max := not(0x0)

            // load lengths of inputs
            let max_len := shl(5, mload(_max))
            let min_len := shl(5, mload(_min))

            //go to end of arrays
            let max_ptr := add(_max, max_len)
            let min_ptr := add(_min, min_len)

            //point to least significant result word.
            let result_ptr := add(result_start, max_len)
            // save memory_end to update free memory pointer at the end.
            let memory_end := add(result_ptr, 0x20)

            // while 'min' words are still available.
            // for(int i=0; i<min_len; i+=0x20)
            for {
                let i := 0x0
            } lt(i, min_len) {
                i := add(i, 0x20)
            } {
                // get next word for 'max'
                let max_val := mload(max_ptr)
                // get next word for 'min'
                let min_val := mload(min_ptr)

                // result_word = (max_word-min_word)-carry
                // find whether or not to set the carry bit for the next iteration.
                let max_min := sub(max_val, min_val)
                let max_min_carry := sub(max_min, carry)
                mstore(result_ptr, max_min_carry)
                carry := or(gt(max_min, max_val), gt(max_min_carry, max_min))

                // point to next 'result' word
                min_ptr := sub(min_ptr, 0x20)
                // point to next 'result' word
                result_ptr := sub(result_ptr, 0x20)
                // point to next 'max' word
                max_ptr := sub(max_ptr, 0x20)
            }

            // remainder after 'min' words are complete.
            // for(int i=min_len; i<max_len; i+=0x20)
            for {
                let i := min_len
            } lt(i, max_len) {
                i := add(i, 0x20)
            } {
                // get next word for 'max'
                let max_val := mload(max_ptr)

                // result_word = max_word-carry
                let max_carry := sub(max_val, carry)
                mstore(result_ptr, max_carry)
                carry := gt(max_carry, max_val)

                // point to next 'result' word
                result_ptr := sub(result_ptr, 0x20)
                // point to next 'max' word
                max_ptr := sub(max_ptr, 0x20)
            }

            // the following code removes any leading words containing all zeroes in the result.
            let shift := 0x20
            for {

            } iszero(mload(add(result_ptr, shift))) {

            } {
                shift := add(shift, 0x20)
            }

            shift := sub(shift, 0x20)
            if gt(shift, 0x0) {
                // for(result_ptr+=0x20;; result==0x0; result_ptr+=0x20)
                // push up the start pointer for the result..
                result_start := add(result_start, shift)
                // and subtract a word (0x20 bytes) from the result length.
                max_len := sub(max_len, shift)
            }

            // point 'result' bytes value to the correct address in memory
            result := result_start

            // store length of result. we are finished with the byte array.
            mstore(result, shr(5, max_len))

            // Update freemem pointer.
            mstore(0x40, memory_end)
        }

        return (result);
    }

    /**
     * @notice Multiply two instances
     * @param _a number
     * @param _b number
     * @return res _a * _b
     */
    function multiply(Instance memory _a, Instance memory _b)
        internal
        view
        returns (Instance memory res)
    {
        res = opAndSquare(_a, _b, true);

        if (cmp(_a, _b) != 0x0) {
            // diffSquared = (a-b)^2
            Instance memory diffSquared = opAndSquare(_a, _b, false);

            // res = add_and_square - diffSquared
            // diffSquared can never be greater than res
            // so we are safe to use innerDiff directly instead of absdiff
            res.value = innerDiff(res.value, diffSquared.value);
        }
        res = privateRightShift(res);
        return res;
    }

    /**
     * @dev take two instances, add or diff them, then square the result
     */
    function opAndSquare(
        Instance memory _a,
        Instance memory _b,
        bool _add
    ) private view returns (Instance memory res) {
        Instance memory two = from(0x2);

        bytes memory _modulus;

        res = _add ? privateAdd(_a, _b) : absdiff(_a, _b);
        uint256 modIndex = (res.value.length << 6) + 0x1;

        _modulus = new bytes(1);
        assembly {
            //store length of modulus
            mstore(_modulus, modIndex)
            //set first modulus word
            mstore(
                add(_modulus, 0x20),
                0xf000000000000000000000000000000000000000000000000000000000000000
            )
            //update freemem pointer to be modulus index + length
            // mstore(0x40, add(_modulus, add(modIndex, 0x20)))
        }

        Instance memory modulus;
        modulus = from(_modulus);

        res = modexp(res, two, modulus);
    }

    /**
     * @dev a % mod
     */
    function modulo(Instance memory _a, Instance memory _mod)
        private
        view
        returns (Instance memory res)
    {
        Instance memory one = from(1);
        res = modexp(_a, one, _mod);
    }

    /**
     * @dev Use the precompile to perform _base ^ _exp % _mod
     */
    function innerModExp(
        bytes32[] memory _base,
        bytes32[] memory _exp,
        bytes32[] memory _mod
    ) private view returns (bytes32[] memory ret) {
        assembly {
            let bl := shl(5, mload(_base))
            let el := shl(5, mload(_exp))
            let ml := shl(5, mload(_mod))

            // Free memory pointer is always stored at 0x40
            let freemem := mload(0x40)

            // arg[0] = base.length @ +0
            mstore(freemem, bl)

            // arg[1] = exp.length @ + 0x20
            mstore(add(freemem, 0x20), el)

            // arg[2] = mod.length @ + 0x40
            mstore(add(freemem, 0x40), ml)

            // arg[3] = base.bits @ + 0x60
            // Use identity built-in (contract 0x4) as a cheap memcpy
            let success := staticcall(
                450,
                0x4,
                add(_base, 0x20),
                bl,
                add(freemem, 0x60),
                bl
            )

            // arg[4] = exp.bits @ +0x60+base.length
            let argBufferSize := add(0x60, bl)
            success := and(
                success,
                staticcall(
                    450,
                    0x4,
                    add(_exp, 0x20),
                    el,
                    add(freemem, argBufferSize),
                    el
                )
            )

            // arg[5] = mod.bits @ +0x60+base.length+exp.length
            argBufferSize := add(argBufferSize, el)
            success := and(
                success,
                staticcall(
                    0x1C2,
                    0x4,
                    add(_mod, 0x20),
                    ml,
                    add(freemem, argBufferSize),
                    ml
                )
            )

            // Total argBufferSize of input = 0x60+base.length+exp.length+mod.length
            argBufferSize := add(argBufferSize, ml)
            // Invoke contract 0x5, put return value right after mod.length, @ +0x60
            success := and(
                success,
                staticcall(
                    sub(gas(), 0x546),
                    0x5,
                    freemem,
                    argBufferSize,
                    add(0x60, freemem),
                    ml
                )
            )

            if iszero(success) {
                revert(0x0, 0x0)
            } //fail where we haven't enough gas to make the call

            let length := ml
            let result_ptr := add(0x60, freemem)

            // the following code removes any leading words containing all zeroes in the result.
            let shift := 0x0
            for {

            } and(gt(length, shift), iszero(mload(add(result_ptr, shift)))) {

            } {
                shift := add(shift, 0x20)
            }

            if gt(shift, 0x0) {
                // push up the start pointer for the result..
                result_ptr := add(result_ptr, shift)
                // and subtract a the words from the result length.
                length := sub(length, shift)
            }

            ret := sub(result_ptr, 0x20)
            mstore(ret, shr(5, length))

            // point to the location of the return value (length, bits)
            // assuming mod length is multiple of 0x20, return value is already in the right format.
            // Otherwise, the offset needs to be adjusted.
            // ret := add(0x40,freemem)
            // deallocate freemem pointer
            mstore(0x40, add(add(0x60, freemem), ml))
        }
        return ret;
    }

    /**
     * @dev Right shift instance 'dividend' by 'value' bits.
     * This clobbers the passed _dividend
     */
    function privateRightShift(Instance memory _dividend)
        internal
        pure
        returns (Instance memory)
    {
        bytes32[] memory result;
        uint256 wordShifted;
        uint256 maskShift = 0xfe;
        uint256 precedingWord;
        uint256 resultPtr;
        uint256 length = _dividend.value.length << 5;

        require(length <= 1024, "Length must be less than 8192 bits");

        assembly {
            resultPtr := add(mload(_dividend), length)
        }

        for (int256 i = int256(length) - 0x20; i >= 0x0; i -= 0x20) {
            // for each word:
            assembly {
                // get next word
                wordShifted := mload(resultPtr)
                // if i==0x0:
                switch iszero(i)
                case 0x1 {
                    // handles msword: no precedingWord needed.
                    precedingWord := 0x0
                }
                default {
                    // else get precedingWord.
                    precedingWord := mload(sub(resultPtr, 0x20))
                }
            }
            // right shift current by value
            wordShifted >>= 0x2;
            // left shift next significant word by maskShift
            precedingWord <<= maskShift;
            assembly {
                // store OR'd precedingWord and shifted value in-place
                mstore(resultPtr, or(wordShifted, precedingWord))
            }
            // point to next value.
            resultPtr -= 0x20;
        }

        assembly {
            // the following code removes a leading word if any containing all zeroes in the result.
            resultPtr := add(resultPtr, 0x20)

            if and(gt(length, 0x0), iszero(mload(resultPtr))) {
                // push up the start pointer for the result..
                resultPtr := add(resultPtr, 0x20)
                // and subtract a word (0x20 bytes) from the result length.
                length := sub(length, 0x20)
            }

            result := sub(resultPtr, 0x20)
            mstore(result, shr(5, length))
        }

        return Instance(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC1820Implementer.sol";
import "../proxy/ForwardTarget.sol";
import "./Policy.sol";

/** @title Policed Contracts
 *
 * A policed contract is any contract managed by a policy.
 */
abstract contract Policed is ForwardTarget, IERC1820Implementer, ERC1820Client {
    bytes32 internal constant ERC1820_ACCEPT_MAGIC =
        keccak256("ERC1820_ACCEPT_MAGIC");

    /** The address of the root policy instance overseeing this instance.
     *
     * This address can be used for ERC1820 lookup of other components, ERC1820
     * lookup of role policies, and interaction with the policy hierarchy.
     */
    Policy public immutable policy;

    /** Restrict method access to the root policy instance only.
     */
    modifier onlyPolicy() {
        require(
            msg.sender == address(policy),
            "Only the policy contract may call this method"
        );
        _;
    }

    constructor(Policy _policy) {
        require(
            address(_policy) != address(0),
            "Unrecoverable: do not set the policy as the zero address"
        );
        policy = _policy;
        ERC1820REGISTRY.setManager(address(this), address(_policy));
    }

    /** ERC1820 permissioning interface
     *
     * @param _addr The address of the contract we might act on behalf of.
     */
    function canImplementInterfaceForAddress(bytes32, address _addr)
        external
        view
        virtual
        override
        returns (bytes32)
    {
        require(
            _addr == address(policy),
            "This contract only implements interfaces for the policy contract"
        );
        return ERC1820_ACCEPT_MAGIC;
    }

    /** Initialize the contract (replaces constructor)
     *
     * Policed contracts are often the targets of proxies, and therefore need a
     * mechanism to initialize internal state when adopted by a new proxy. This
     * replaces the constructor.
     *
     * @param _self The address of the original contract deployment (as opposed
     *              to the address of the proxy contract, which takes the place
     *              of `this`).
     */
    function initialize(address _self)
        public
        virtual
        override
        onlyConstruction
    {
        super.initialize(_self);
        ERC1820REGISTRY.setManager(address(this), address(policy));
    }

    /** Execute code as indicated by the managing policy contract
     *
     * We allow the managing policy contract to execute arbitrary code in our
     * context by allowing it to specify an implementation address and some
     * message data, and then using delegatecall to execute the code at the
     * implementation address, passing in the message data, all within our
     * own address space.
     *
     * @param _delegate The address of the contract to delegate execution to.
     * @param _data The call message/data to execute on.
     */
    function policyCommand(address _delegate, bytes memory _data)
        public
        onlyPolicy
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            /* Call the address indicated by _delegate passing the data in _data
             * as the call message using delegatecall. This allows the calling
             * of arbitrary functions on _delegate (by encoding the call message
             * into _data) in the context of the current contract's storage.
             */
            let result := delegatecall(
                gas(),
                _delegate,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
            /* Collect up the return data from delegatecall and prepare it for
             * returning to the caller of policyCommand.
             */
            let size := returndatasize()
            returndatacopy(0x0, 0, size)
            /* If the delegated call reverted then revert here too. Otherwise
             * forward the return data prepared above.
             */
            switch result
            case 0 {
                revert(0x0, size)
            }
            default {
                return(0x0, size)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
The MIT License (MIT)

Copyright (c) 2018 Murray Software, LLC.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
/* solhint-disable */

// See the EIP-1167: http://eips.ethereum.org/EIPS/eip-1167 and
// clone-factory: https://github.com/optionality/clone-factory for details.

abstract contract CloneFactory {
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

/** @title Utilities for interfacing with ERC1820
 */
abstract contract ERC1820Client {
    IERC1820Registry internal constant ERC1820REGISTRY =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);

    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}

/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* solhint-disable no-inline-assembly */

/** @title Target for ForwardProxy and EcoInitializable */
abstract contract ForwardTarget {
    // Must match definition in ForwardProxy
    // keccak256("com.eco.ForwardProxy.target")
    uint256 private constant IMPLEMENTATION_SLOT =
        0xf86c915dad5894faca0dfa067c58fdf4307406d255ed0a65db394f82b77f53d4;

    modifier onlyConstruction() {
        require(
            implementation() == address(0),
            "Can only be called during initialization"
        );
        _;
    }

    constructor() {
        setImplementation(address(this));
    }

    /** @notice Storage initialization of cloned contract
     *
     * This is used to initialize the storage of the forwarded contract, and
     * should (typically) copy or repeat any work that would normally be
     * done in the constructor of the proxied contract.
     *
     * Implementations of ForwardTarget should override this function,
     * and chain to super.initialize(_self).
     *
     * @param _self The address of the original contract instance (the one being
     *              forwarded to).
     */
    function initialize(address _self) public virtual onlyConstruction {
        address _implAddress = address(ForwardTarget(_self).implementation());
        require(
            _implAddress != address(0),
            "initialization failure: nothing to implement"
        );
        setImplementation(_implAddress);
    }

    /** Get the address of the proxy target contract.
     */
    function implementation() public view returns (address _impl) {
        assembly {
            _impl := sload(IMPLEMENTATION_SLOT)
        }
    }

    /** @notice Set new implementation */
    function setImplementation(address _impl) internal {
        require(implementation() != _impl, "Implementation already matching");
        assembly {
            sstore(IMPLEMENTATION_SLOT, _impl)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "../proxy/ForwardTarget.sol";
import "./ERC1820Client.sol";

/** @title The policy contract that oversees other contracts
 *
 * Policy contracts provide a mechanism for building pluggable (after deploy)
 * governance systems for other contracts.
 */
contract Policy is ForwardTarget, ERC1820Client {
    mapping(bytes32 => bool) public setters;

    modifier onlySetter(bytes32 _identifier) {
        require(
            setters[_identifier],
            "Identifier hash is not authorized for this action"
        );

        require(
            ERC1820REGISTRY.getInterfaceImplementer(
                address(this),
                _identifier
            ) == msg.sender,
            "Caller is not the authorized address for identifier"
        );

        _;
    }

    /** Remove the specified role from the contract calling this function.
     * This is for cleanup only, so if another contract has taken the
     * role, this does nothing.
     *
     * @param _interfaceIdentifierHash The interface identifier to remove from
     *                                 the registry.
     */
    function removeSelf(bytes32 _interfaceIdentifierHash) external {
        address old = ERC1820REGISTRY.getInterfaceImplementer(
            address(this),
            _interfaceIdentifierHash
        );

        if (old == msg.sender) {
            ERC1820REGISTRY.setInterfaceImplementer(
                address(this),
                _interfaceIdentifierHash,
                address(0)
            );
        }
    }

    /** Find the policy contract for a particular identifier.
     *
     * @param _interfaceIdentifierHash The hash of the interface identifier
     *                                 look up.
     */
    function policyFor(bytes32 _interfaceIdentifierHash)
        public
        view
        returns (address)
    {
        return
            ERC1820REGISTRY.getInterfaceImplementer(
                address(this),
                _interfaceIdentifierHash
            );
    }

    /** Set the policy label for a contract
     *
     * @param _key The label to apply to the contract.
     *
     * @param _implementer The contract to assume the label.
     */
    function setPolicy(
        bytes32 _key,
        address _implementer,
        bytes32 _authKey
    ) public onlySetter(_authKey) {
        ERC1820REGISTRY.setInterfaceImplementer(
            address(this),
            _key,
            _implementer
        );
    }

    /** Enact the code of one of the governance contracts.
     *
     * @param _delegate The contract code to delegate execution to.
     */
    function internalCommand(address _delegate, bytes32 _authKey)
        public
        onlySetter(_authKey)
    {
        // solhint-disable-next-line avoid-low-level-calls
        (bool _success, ) = _delegate.delegatecall(
            abi.encodeWithSignature("enacted(address)", _delegate)
        );
        require(_success, "Command failed during delegatecall");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC1820Implementer.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for an ERC1820 implementer, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820#interface-implementation-erc1820implementerinterface[EIP].
 * Used by contracts that will be registered as implementers in the
 * {IERC1820Registry}.
 */
interface IERC1820Implementer {
    /**
     * @dev Returns a special value (`ERC1820_ACCEPT_MAGIC`) if this contract
     * implements `interfaceHash` for `account`.
     *
     * See {IERC1820Registry-setInterfaceImplementer}.
     */
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address account) external view returns (bytes32);
}