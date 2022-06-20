// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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

// SPDX-License-Identifier: AGPL-1.0

pragma solidity >=0.7.5 <=0.8.10;

interface IBondCalculator {
    function valuation(address tokenIn, uint256 amount_) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

interface INoteKeeper {
    /**
     * @notice  Info for market note
     * @dev     Note::payout is sTHEO remaining to be paid
     *          Note::created is the time the Note was created
     *          Note::matured is the timestamp when the Note is redeemable
     *          Note::redeemed is time market was redeemed
     *          Note::marketID is market ID of deposit. uint48 to avoid adding a slot.
     */
    struct Note {
        uint256 payout;
        uint48 created;
        uint48 matured;
        uint48 redeemed;
        uint48 marketID;
        uint48 discount;
        bool autoStake;
    }

    function redeem(address _user, uint256[] memory _indexes) external returns (uint256);

    function redeemAll(address _user) external returns (uint256);

    function pushNote(address to, uint256 index) external;

    function pullNote(address from, uint256 index) external returns (uint256 newIndex_);

    function indexesFor(address _user) external view returns (uint256[] memory);

    function pendingFor(address _user, uint256 _index)
        external
        view
        returns (
            uint256 payout_,
            uint48 created_,
            uint48 expiry_,
            uint48 timeRemaining_,
            bool matured_,
            uint48 discount_
        );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IStakedTHEOToken is IERC20 {
    function rebase(uint256 theoProfit_, uint256 epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function balanceOf(address who) external view override returns (uint256);

    function gonsForBalance(uint256 amount) external view returns (uint256);

    function balanceForGons(uint256 gons) external view returns (uint256);

    function index() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IStaking {
    function stake(
        address _to,
        uint256 _amount,
        bool _claim
    ) external returns (uint256, uint256 _index);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit(uint256 _index) external;

    function toggleLock() external;

    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256);

    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_);

    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_);

    function rebase() external;

    function index() external view returns (uint256);

    function contractBalance() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function supplyInWarmup() external view returns (uint256);

    function indexesFor(address _user) external view returns (uint256[] memory);

    function claimAll(address _recipient) external returns (uint256);

    function pushClaim(address _to, uint256 _index) external;

    function pullClaim(address _from, uint256 _index) external returns (uint256 newIndex_);

    function pushClaimForBond(address _to, uint256 _index) external returns (uint256 newIndex_);

    function basis() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITheopetraAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event ManagerPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event SignerPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event ManagerPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);
    event SignerPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function manager() external view returns (address);

    function vault() external view returns (address);

    function whitelistSigner() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IBondCalculator.sol";

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function tokenPerformanceUpdate() external;

    function baseSupply() external view returns (uint256);

    function deltaTokenPrice() external view returns (int256);

    function deltaTreasuryYield() external view returns (int256);

    function getTheoBondingCalculator() external view returns (IBondCalculator);

    function setTheoBondingCalculator(address _theoBondingCalculator) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IWhitelistBondDepository {
    /**
     * @notice      Info about each type of market
     * @dev         Market::capacity is capacity remaining
     *              Market::quoteToken is token to accept as payment
     *              Market::priceFeed is address of the price consumer, to return the USD value for the quote token when deposits are made
     *              Market::capacityInQuote is in payment token (true) or in THEO (false, default)
     *              Market::sold is base tokens out
     *              Market::purchased quote tokens in
     *              Market::usdPricePerTHEO is 9 decimal USD value for each THEO bond
     */
    struct Market {
        uint256 capacity;
        IERC20 quoteToken;
        address priceFeed;
        bool capacityInQuote;
        uint64 sold;
        uint256 purchased;
        uint256 usdPricePerTHEO;
    }

    /**
     * @notice      Info for creating new markets
     * @dev         Terms::fixedTerm is fixed term or fixed expiration
     *              Terms::vesting is length of time from deposit to maturity if fixed-term
     *              Terms::conclusion is timestamp when market no longer offered (doubles as time when market matures if fixed-expiry)
     */
    struct Terms {
        bool fixedTerm;
        uint48 vesting;
        uint48 conclusion;
    }

    /**
     * @notice      Additional info about market
     * @dev         Metadata::quoteDecimals is decimals of quote token
     */
    struct Metadata {
        uint8 quoteDecimals;
    }

    struct DepositInfo {
        uint256 payout_;
        uint256 expiry_;
        uint256 index_;
    }

    /**
     * @notice deposit market
     * @param _bid uint256
     * @param _amount uint256
     * @param _maxPrice uint256
     * @param _user address
     * @param _referral address
     * @param signature bytes
     * @return depositInfo DepositInfo
     */
    function deposit(
        uint256 _bid,
        uint256 _amount,
        uint256 _maxPrice,
        address _user,
        address _referral,
        bytes calldata signature
    ) external returns (DepositInfo memory depositInfo);

    /**
     * @notice create market
     * @param _quoteToken IERC20 is the token used to deposit
     * @param _priceFeed address is address of the price consumer, to return the USD value for the quote token when deposits are made
     * @param _market uint256[2] is [capacity, fixed bond price (9 decimals) USD per THEO]
     * @param _booleans bool[2] is [capacity in quote, fixed term]
     * @param _terms uint256[2] is [vesting, conclusion]
     * @return id_ uint256 is ID of the market
     */
    function create(
        IERC20 _quoteToken,
        address _priceFeed,
        uint256[2] memory _market,
        bool[2] memory _booleans,
        uint256[2] memory _terms
    ) external returns (uint256 id_);

    function close(uint256 _id) external;

    function isLive(uint256 _bid) external view returns (bool);

    function liveMarkets() external view returns (uint256[] memory);

    function liveMarketsFor(address _quoteToken) external view returns (uint256[] memory);

    function getMarkets() external view returns (uint256[] memory);

    function getMarketsFor(address _quoteToken) external view returns (uint256[] memory);

    function calculatePrice(uint256 _bid) external view returns (uint256);

    function payoutFor(uint256 _amount, uint256 _bid) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import { IERC20 } from "../Interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{ value: amount }(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "../Types/NoteKeeper.sol";
import "../Types/Signed.sol";
import "../Types/PriceConsumerV3.sol";

import "../Libraries/SafeERC20.sol";

import "../Interfaces/IERC20Metadata.sol";
import "../Interfaces/IWhitelistBondDepository.sol";

/**
 * @title Theopetra Whitelist Bond Depository
 */

contract WhitelistTheopetraBondDepository is IWhitelistBondDepository, NoteKeeper, Signed, PriceConsumerV3 {
    /* ======== DEPENDENCIES ======== */

    using SafeERC20 for IERC20;

    /* ======== EVENTS ======== */

    event CreateMarket(
        uint256 indexed id,
        address indexed baseToken,
        address indexed quoteToken,
        uint256 fixedBondPrice
    );
    event CloseMarket(uint256 indexed id);
    event Bond(uint256 indexed id, uint256 amount, uint256 price);

    /* ======== STATE VARIABLES ======== */

    // Storage
    Market[] public markets; // persistent market data
    Terms[] public terms; // deposit construction data
    Metadata[] public metadata; // extraneous market data
    address private wethHelper;

    // Queries
    mapping(address => uint256[]) public marketsForQuote; // market IDs for quote token

    /* ======== CONSTRUCTOR ======== */

    constructor(
        ITheopetraAuthority _authority,
        IERC20 _theo,
        IStakedTHEOToken _stheo,
        IStaking _staking,
        ITreasury _treasury
    ) NoteKeeper(_authority, _theo, _stheo, _staking, _treasury) {
        // save gas for users by bulk approving stake() transactions
        _theo.approve(address(_staking), 1e45);
    }

    /* ======== DEPOSIT ======== */

    /**
     * @notice             deposit quote tokens in exchange for a bond from a specified market
     * @param _id          the ID of the market
     * @param _amount      the amount of quote token to spend
     * @param _maxPrice    the maximum price at which to buy
     * @param _user        the recipient of the payout
     * @param _referral    the front end operator address
     * @return depositInfo DepositInfo
     */
    function deposit(
        uint256 _id,
        uint256 _amount,
        uint256 _maxPrice,
        address _user,
        address _referral,
        bytes calldata signature
    ) external override returns (DepositInfo memory depositInfo) {
        if (msg.sender != wethHelper) {
            verifySignature("", signature);
        }
        Market storage market = markets[_id];
        Terms memory term = terms[_id];
        uint48 currentTime = uint48(block.timestamp);

        // Markets end at a defined timestamp
        // |-------------------------------------| t
        require(currentTime < term.conclusion, "Depository: market concluded");

        // Get the price of THEO in quote token terms
        // i.e. the number of quote tokens per THEO
        // With 9 decimal places
        uint256 price = calculatePrice(_id);

        // Users input a maximum price, which protects them from price changes after
        // entering the mempool. max price is a slippage mitigation measure
        require(price <= _maxPrice, "Depository: more than max price");

        /**
         * payout for the deposit = amount / price
         *
         * where
         * payout = THEO out, in THEO decimals (9)
         * amount = quote tokens in
         * price = quote tokens per THEO, in THEO decimals (9)
         *
         * 1e18 = THEO decimals (9) + price decimals (9)
         */
        depositInfo.payout_ = ((_amount * 1e18) / price) / (10**metadata[_id].quoteDecimals);

        /*
         * each market is initialized with a capacity
         *
         * this is either the number of THEO that the market can sell
         * (if capacity in quote is false),
         *
         * or the number of quote tokens that the market can buy
         * (if capacity in quote is true)
         */

        require(
            market.capacity >= (market.capacityInQuote ? _amount : depositInfo.payout_),
            "Depository: capacity exceeded"
        );

        market.capacity -= market.capacityInQuote ? _amount : depositInfo.payout_;

        if (market.capacity == 0) {
            emit CloseMarket(_id);
        }

        /**
         * bonds mature with a cliff at a set timestamp
         * prior to the expiry timestamp, no payout tokens are accessible to the user
         * after the expiry timestamp, the entire payout can be redeemed
         *
         * there are two types of bonds: fixed-term and fixed-expiration
         *
         * fixed-term bonds mature in a set amount of time from deposit
         * i.e. term = 1 week. when alice deposits on day 1, her bond
         * expires on day 8. when bob deposits on day 2, his bond expires day 9.
         *
         * fixed-expiration bonds mature at a set timestamp
         * i.e. expiration = day 10. when alice deposits on day 1, her term
         * is 9 days. when bob deposits on day 2, his term is 8 days.
         */
        depositInfo.expiry_ = term.fixedTerm ? term.vesting + currentTime : term.vesting;

        // markets keep track of how many quote tokens have been
        // purchased, and how much THEO has been sold
        market.purchased += _amount;
        market.sold += uint64(depositInfo.payout_);

        emit Bond(_id, _amount, price);

        /**
         * user data is stored as Notes. these are isolated array entries
         * storing the amount due, the time created, the time when payout
         * is redeemable, the time when payout was redeemed, and the ID
         * of the market deposited into
         */
        depositInfo.index_ = addNote(
            _user,
            depositInfo.payout_,
            uint48(depositInfo.expiry_),
            uint48(_id),
            _referral,
            0,
            false
        );

        // transfer payment to treasury
        market.quoteToken.safeTransferFrom(msg.sender, address(treasury), _amount);
    }

    /* ======== CREATE ======== */

    /**
     * @notice             creates a new market type
     * @dev                current price should be in 9 decimals.
     * @param _quoteToken  token used to deposit
     * @param _market      [capacity (in THEO or quote), fixed bond price (9 decimals) USD per THEO]
     * @param _booleans    [capacity in quote, fixed term]
     * @param _terms       [vesting length (if fixed term) or vested timestamp, conclusion timestamp]
     * @param _priceFeed   address of the price consumer, to return the USD value for the quote token when deposits are made
     * @return id_         ID of new bond market
     */
    function create(
        IERC20 _quoteToken,
        address _priceFeed,
        uint256[2] memory _market,
        bool[2] memory _booleans,
        uint256[2] memory _terms
    ) external override onlyPolicy returns (uint256 id_) {
        // the decimal count of the quote token
        uint256 decimals = IERC20Metadata(address(_quoteToken)).decimals();

        // depositing into, or getting info for, the created market uses this ID
        id_ = markets.length;

        markets.push(
            Market({
                quoteToken: _quoteToken,
                priceFeed: _priceFeed,
                capacityInQuote: _booleans[0],
                capacity: _market[0],
                purchased: 0,
                sold: 0,
                usdPricePerTHEO: _market[1]
            })
        );

        terms.push(Terms({ fixedTerm: _booleans[1], vesting: uint48(_terms[0]), conclusion: uint48(_terms[1]) }));

        metadata.push(Metadata({ quoteDecimals: uint8(decimals) }));

        marketsForQuote[address(_quoteToken)].push(id_);

        emit CreateMarket(id_, address(theo), address(_quoteToken), _market[1]);
    }

    /**
     * @notice             disable existing market
     * @param _id          ID of market to close
     */
    function close(uint256 _id) external override onlyPolicy {
        terms[_id].conclusion = uint48(block.timestamp);
        markets[_id].capacity = 0;
        emit CloseMarket(_id);
    }

    /* ======== EXTERNAL VIEW ======== */

    /**
     * @notice             payout due for amount of quote tokens
     * @param _amount      amount of quote tokens to spend
     * @param _id          ID of market
     * @return             amount of THEO to be paid in THEO decimals
     *
     * @dev 1e18 = theo decimals (9) + fixed bond price decimals (9)
     */
    function payoutFor(uint256 _amount, uint256 _id) external view override returns (uint256) {
        Metadata memory meta = metadata[_id];
        return (_amount * 1e18) / calculatePrice(_id) / 10**meta.quoteDecimals;
    }

    /**
     * @notice             is a given market accepting deposits
     * @param _id          ID of market
     */
    function isLive(uint256 _id) public view override returns (bool) {
        return (markets[_id].capacity != 0 && terms[_id].conclusion > block.timestamp);
    }

    /**
     * @notice returns an array of all active market IDs
     */
    function liveMarkets() external view override returns (uint256[] memory) {
        uint256 num;
        for (uint256 i = 0; i < markets.length; i++) {
            if (isLive(i)) num++;
        }

        uint256[] memory ids = new uint256[](num);
        uint256 nonce;
        for (uint256 i = 0; i < markets.length; i++) {
            if (isLive(i)) {
                ids[nonce] = i;
                nonce++;
            }
        }
        return ids;
    }

    /**
     * @notice             returns an array of all active market IDs for a given quote token
     * @param _token       quote token to check for
     */
    function liveMarketsFor(address _token) external view override returns (uint256[] memory) {
        uint256[] memory mkts = marketsForQuote[_token];
        uint256 num;

        for (uint256 i = 0; i < mkts.length; i++) {
            if (isLive(mkts[i])) num++;
        }

        uint256[] memory ids = new uint256[](num);
        uint256 nonce;

        for (uint256 i = 0; i < mkts.length; i++) {
            if (isLive(mkts[i])) {
                ids[nonce] = mkts[i];
                nonce++;
            }
        }
        return ids;
    }


    /**
     * @notice returns an array of market IDs for historical analysis
     */
    function getMarkets() external view override returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](markets.length);
        for (uint256 i = 0; i < markets.length; i++) {
                ids[i] = i;
        }
        return ids;
    }

    /**
     * @notice             returns an array of all market IDs for a given quote token
     * @param _token       quote token to check for
     */
    function getMarketsFor(address _token) external view override returns (uint256[] memory) {
        uint256[] memory mkts = marketsForQuote[_token];
        uint256[] memory ids = new uint256[](mkts.length);

        for (uint256 i = 0; i < mkts.length; i++) {
            ids[i] = mkts[i];
        }
        return ids;
    }

    /**
     * @notice                  calculate the price of THEO in quote token terms; i.e. the number of quote tokens per THEO
     * @dev                     get the latest price for the market's quote token in USD
     *                          (`priceConsumerPrice`, with decimals `priceConsumerDecimals`)
     *                          then `scalePrice` to scale the fixed bond price to THEO decimals when calculating `price`.
     *                          finally, calculate `price` as quote tokens per THEO, in THEO decimals (9)
     * @param _id               market ID
     * @return                  uint256 price of THEO in quote token terms, in THEO decimals (9)
     */
    function calculatePrice(uint256 _id) public view override returns (uint256) {
        (int256 priceConsumerPrice, uint8 priceConsumerDecimals) = getLatestPrice(markets[_id].priceFeed);

        int256 scaledPrice = scalePrice(int256(markets[_id].usdPricePerTHEO), 9, 9 + priceConsumerDecimals);

        uint256 price = uint256(scaledPrice / priceConsumerPrice);
        return price;
    }

    /* ======== INTERNAL PURE ======== */

    /**
     * @param _price            fixed bond price (USD per THEO), 9 decimals
     * @param _priceDecimals    decimals (9) used for the fixed bond price
     * @param _decimals         sum of decimals for THEO token (9) + decimals for the price feed
     */
    function scalePrice(
        int256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) internal pure returns (int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10**uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10**uint256(_priceDecimals - _decimals));
        }
        return _price;
    }

    /* ====== POLICY FUNCTIONS ====== */

    function setWethHelper(address _wethHelper) external onlyGovernor {
        require(_wethHelper != address(0), "Zero address");
        wethHelper = _wethHelper;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "../Types/TheopetraAccessControlled.sol";
import "../Interfaces/IERC20.sol";

abstract contract FrontEndRewarder is TheopetraAccessControlled {
    /* ========= STATE VARIABLES ========== */

    uint256 public daoReward; // % reward for dao (3 decimals: 100 = 1%)
    uint256 public refReward; // % reward for referrer (3 decimals: 100 = 1%)
    mapping(address => uint256) public rewards; // front end operator rewards
    mapping(address => bool) public whitelisted; // whitelisted status for operators

    IERC20 internal immutable theo; // reward token

    event SetRewards(uint256 toRef, uint256 toDao);
    constructor(ITheopetraAuthority _authority, IERC20 _theo) TheopetraAccessControlled(_authority) {
        theo = _theo;
    }

    /* ========= EXTERNAL FUNCTIONS ========== */

    // pay reward to front end operator
    function getReward() external {
        uint256 reward = rewards[msg.sender];

        rewards[msg.sender] = 0;
        theo.transfer(msg.sender, reward);
    }

    /* ========= INTERNAL ========== */

    /**
     * @notice add new market payout to user data
     */
    function _giveRewards(uint256 _payout, address _referral) internal returns (uint256) {
        // first we calculate rewards paid to the DAO and to the front end operator (referrer)
        uint256 toDAO = (_payout * daoReward) / 1e4;
        uint256 toRef = (_payout * refReward) / 1e4;

        // and store them in our rewards mapping
        if (whitelisted[_referral]) {
            rewards[_referral] += toRef;
            rewards[authority.guardian()] += toDAO;
        } else {
            // the DAO receives both rewards if referrer is not whitelisted
            rewards[authority.guardian()] += toDAO + toRef;
        }
        return toDAO + toRef;
    }

    /**
     * @notice set rewards for front end operators and DAO
     */
    function setRewards(uint256 _toFrontEnd, uint256 _toDAO) external onlyGovernor {
        refReward = _toFrontEnd;
        daoReward = _toDAO;

        emit SetRewards(_toFrontEnd, _toDAO);
    }

    /**
     * @notice add or remove addresses from the reward whitelist
     */
    function whitelist(address _operator) external onlyPolicy {
        whitelisted[_operator] = !whitelisted[_operator];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "./FrontEndRewarder.sol";

import "../Interfaces/IStakedTHEOToken.sol";
import "../Interfaces/IStaking.sol";
import "../Interfaces/ITreasury.sol";
import "../Interfaces/INoteKeeper.sol";

abstract contract NoteKeeper is INoteKeeper, FrontEndRewarder {
    mapping(address => Note[]) public notes; // user deposit data
    mapping(address => mapping(uint256 => address)) private noteTransfers; // change note ownership
    mapping(address => mapping(uint256 => uint256)) private noteForClaim; // index of staking claim for a user's note

    event TreasuryUpdated(address addr);
    event PushNote(address from, address to, uint256 noteId);
    event PullNote(address from, address to, uint256 noteId);

    IStakedTHEOToken internal immutable sTHEO;
    IStaking internal immutable staking;
    ITreasury internal treasury;

    constructor(
        ITheopetraAuthority _authority,
        IERC20 _theo,
        IStakedTHEOToken _stheo,
        IStaking _staking,
        ITreasury _treasury
    ) FrontEndRewarder(_authority, _theo) {
        sTHEO = _stheo;
        staking = _staking;
        treasury = _treasury;
    }

    // if treasury address changes on authority, update it
    function updateTreasury() external {
        require(
            msg.sender == authority.governor() ||
                msg.sender == authority.guardian() ||
                msg.sender == authority.policy(),
            "Only authorized"
        );
        address treasuryAddress = authority.vault();
        treasury = ITreasury(treasuryAddress);
        emit TreasuryUpdated(treasuryAddress);
    }

    /* ========== ADD ========== */

    /**
     * @notice             adds a new Note for a user, stores the front end & DAO rewards, and mints & stakes payout & rewards
     * @param _user        the user that owns the Note
     * @param _payout      the amount of THEO due to the user
     * @param _expiry      the timestamp when the Note is redeemable
     * @param _marketID    the ID of the market deposited into
     * @param _discount    the discount on the bond (that is, the bond rate, variable). This is a proportion (that is, a percentage in its decimal form), with 9 decimals
     * @return index_      the index of the Note in the user's array
     */
    function addNote(
        address _user,
        uint256 _payout,
        uint48 _expiry,
        uint48 _marketID,
        address _referral,
        uint48 _discount,
        bool _autoStake
    ) internal returns (uint256 index_) {
        // the index of the note is the next in the user's array
        index_ = notes[_user].length;

        // the new note is pushed to the user's array
        notes[_user].push(
            Note({
                payout: _payout,
                created: uint48(block.timestamp),
                matured: _expiry,
                redeemed: 0,
                marketID: _marketID,
                discount: _discount,
                autoStake: _autoStake
            })
        );

        // front end operators can earn rewards by referring users
        uint256 rewards = _giveRewards(_payout, _referral);

        // mint and stake payout
        treasury.mint(address(this), _payout + rewards);

        if (_autoStake) {
            // note that only the payout gets staked (front end rewards are in THEO)
            // Get index for the claim to approve for pushing
            (, uint256 claimIndex) = staking.stake(address(this), _payout, true);
            // approve the user to transfer the staking claim
            staking.pushClaim(_user, claimIndex);

            // Map the index of the user's note to the claimIndex
            noteForClaim[_user][index_] = claimIndex;
        }
    }

    /* ========== REDEEM ========== */

    /**
     * @notice             redeem notes for user
     * @dev                adapted from Olympus V2. Olympus V2 either sends payout as gOHM
     *                     or calls an `unwrap` function on the staking contract
     *                     to convert the payout from gOHM into sOHM and then send as sOHM.
     *                     This current contract sends payout as sTHEO.
     * @param _user        the user to redeem for
     * @param _indexes     the note indexes to redeem
     * @return payout_     sum of payout sent, in sTHEO
     */
    function redeem(address _user, uint256[] memory _indexes) public override returns (uint256 payout_) {
        uint48 time = uint48(block.timestamp);
        uint256 sTheoPayout = 0;
        uint256 theoPayout = 0;

        for (uint256 i = 0; i < _indexes.length; i++) {
            (uint256 pay, , , , bool matured, ) = pendingFor(_user, _indexes[i]);

            if (matured) {
                notes[_user][_indexes[i]].redeemed = time; // mark as redeemed
                payout_ += pay;
                if (notes[_user][_indexes[i]].autoStake) {
                    uint256 _claimIndex = noteForClaim[_user][_indexes[i]];
                    staking.pushClaimForBond(_user, _claimIndex);
                    sTheoPayout += pay;
                } else {
                    theoPayout += pay;
                }
            }
        }
        if (theoPayout > 0) theo.transfer(_user, theoPayout);
        if (sTheoPayout > 0) sTHEO.transfer(_user, sTheoPayout);
    }

    /**
     * @notice             redeem all redeemable markets for user
     * @dev                if possible, query indexesFor() off-chain and input in redeem() to save gas
     * @param _user        user to redeem all notes for
     * @return             sum of payout sent, in sTHEO
     */
    function redeemAll(address _user) external override returns (uint256) {
        return redeem(_user, indexesFor(_user));
    }

    /* ========== TRANSFER ========== */

    /**
     * @notice             approve an address to transfer a note
     * @param _to          address to approve note transfer for
     * @param _index       index of note to approve transfer for
     */
    function pushNote(address _to, uint256 _index) external override {
        require(notes[msg.sender][_index].created != 0, "Depository: note not found");
        noteTransfers[msg.sender][_index] = _to;

        emit PushNote(msg.sender, _to, _index);
    }

    /**
     * @notice             transfer a note that has been approved by an address
     * @dev                if the note being pulled is autostaked then update noteForClaim as follows:
     *                     get the relevant `claimIndex` associated with the note that is being pulled.
     *                     Then add the claimIndex to the recipient's noteForClaim.
     *                     After updating noteForClaim, the staking claim is pushed to the recipient, in order to
     *                     update `claimTransfers` in the Staking contract and thereby change claim ownership (from the note's pusher to the note's recipient)
     * @param _from        the address that approved the note transfer
     * @param _index       the index of the note to transfer (in the sender's array)
     */
    function pullNote(address _from, uint256 _index) external override returns (uint256 newIndex_) {
        require(noteTransfers[_from][_index] == msg.sender, "Depository: transfer not found");
        require(notes[_from][_index].redeemed == 0, "Depository: note redeemed");

        newIndex_ = notes[msg.sender].length;

        if (notes[_from][_index].autoStake) {
            uint256 claimIndex = noteForClaim[_from][_index];
            noteForClaim[msg.sender][newIndex_] = claimIndex;
            staking.pushClaim(msg.sender, claimIndex);
        }
        notes[msg.sender].push(notes[_from][_index]);

        delete notes[_from][_index];
        emit PullNote(_from, msg.sender, _index);
    }

    /* ========== VIEW ========== */

    // Note info

    /**
     * @notice             all pending notes for user
     * @param _user        the user to query notes for
     * @return             the pending notes for the user
     */
    function indexesFor(address _user) public view override returns (uint256[] memory) {
        Note[] memory info = notes[_user];

        uint256 length;
        for (uint256 i = 0; i < info.length; i++) {
            if (info[i].redeemed == 0 && info[i].payout != 0) length++;
        }

        uint256[] memory indexes = new uint256[](length);
        uint256 position;

        for (uint256 i = 0; i < info.length; i++) {
            if (info[i].redeemed == 0 && info[i].payout != 0) {
                indexes[position] = i;
                position++;
            }
        }

        return indexes;
    }

    /**
     * @notice                  calculate amount available for claim for a single note
     * @param _user             the user that the note belongs to
     * @param _index            the index of the note in the user's array
     * @return payout_          the payout due, in sTHEO
     * @return created_         the time the note was created
     * @return expiry_          the time the note is redeemable
     * @return timeRemaining_   the time remaining until the note is matured
     * @return matured_         if the payout can be redeemed
     */
    function pendingFor(address _user, uint256 _index)
        public
        view
        override
        returns (
            uint256 payout_,
            uint48 created_,
            uint48 expiry_,
            uint48 timeRemaining_,
            bool matured_,
            uint48 discount_
        )
    {
        Note memory note = notes[_user][_index];

        payout_ = note.payout;
        created_ = note.created;
        expiry_ = note.matured;
        timeRemaining_ = note.matured > block.timestamp ? uint48(note.matured - block.timestamp) : 0;
        matured_ = note.redeemed == 0 && note.matured <= block.timestamp && note.payout != 0;
        discount_ = note.discount;
    }

    function getNotesCount(address _user) external view returns (uint256) {
        return notes[_user].length;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
    /**
     * Returns the latest price
     */
    function getLatestPrice(address priceFeedAddress) public view returns (int256, uint8) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(priceFeedAddress).latestRoundData();

        uint8 decimals = AggregatorV3Interface(priceFeedAddress).decimals();

        return (price, decimals);
    }
}

// SPDX-License-Identifier: BSD-3

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./TheopetraAccessControlled.sol";

abstract contract Signed is TheopetraAccessControlled {
    using Strings for uint256;
    using ECDSA for bytes32;

    string private _secret;

    event SetSecret(string secret);

    function setSecret(string calldata secret) external onlyGovernor {
        _secret = secret;
        emit SetSecret(secret);
    }

    function createHash(string memory data) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), msg.sender, data, _secret));
    }

    function getSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        return hash.toEthSignedMessageHash().recover(signature);
    }

    function isAuthorizedSigner(address extracted) internal view virtual returns (bool) {
        return extracted == authority.whitelistSigner();
    }

    function verifySignature(string memory data, bytes calldata signature) internal view {
        address extracted = getSigner(createHash(data), signature);
        require(isAuthorizedSigner(extracted), "Signature verification failed");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../Interfaces/ITheopetraAuthority.sol";

abstract contract TheopetraAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(ITheopetraAuthority indexed authority);

    string constant UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    ITheopetraAuthority public authority;

    /* ========== Constructor ========== */

    constructor(ITheopetraAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyManager() {
        require(msg.sender == authority.manager(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(ITheopetraAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}