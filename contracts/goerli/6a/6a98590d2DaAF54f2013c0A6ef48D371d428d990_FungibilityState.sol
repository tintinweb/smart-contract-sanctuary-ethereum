// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/IBToken.sol";

import "./CIState.sol";
import "../struct/RebalanceAmount.sol";

import "hardhat/console.sol";

/// @notice Add fungibility calculation to state contract
contract FungibilityState is CIState {

    /// @notice bToken for Asset
    IBToken public immutable bAsset;    

    /// @notice bToken for Asset
    IBToken public immutable bStable;    

    constructor(
        address _gac,
        address _market,
        address _feed,
        uint _DIVIDER_ASSET,
        uint _DIVIDER_STABLE,
        address _bAsset,
        address _bStable
    ) CIState(_gac, _market, _feed, _DIVIDER_ASSET, _DIVIDER_STABLE) {
        (lastRoundId, lastPrice, , lastTimestamp, ) = AggregatorV3Interface(
            _feed
        ).latestRoundData();
        require(lastTimestamp > 0, "CIS: last-timestamp");

        require(_bStable != address(0), "CMA: bstable-token-address-zero");
        require(_bAsset != address(0), "CMA: basset-token-address-zero");

        bAsset = IBToken(_bAsset);
        bStable = IBToken(_bStable);                
    }

    /// @inheritdoc IState
    function newTakerPosition(
        address account,
        uint assetAmount,
        uint16 risk,
        uint16 term,
        uint floor
    ) external override onlyMarket returns (uint shares) {
        _newTakerPosition(assetAmount, risk, term, floor);
        shares = calc.takerShare(assetAmount,risk,term,floor) * (assetAmount + bAsset.marketSupply(market)) / UDIVIDER;        
        bAsset.mint(market, account, shares);
    }

    /// @inheritdoc IState
    function closeTakerPosition(
        address account,
        uint assetAmount,
        uint16 risk,
        uint16 term,
        uint floor,
        uint premium,
        Payout calldata payout,
        uint shares
    ) external override onlyMarket {
        _closeTakerPosition(assetAmount, risk, term, floor, premium, payout);
        bAsset.burn(market, account, shares);
    }

    /// @inheritdoc IState
    function claimTakerPosition(
        address account,
        uint assetAmount,
        uint16 risk,
        uint16 term,
        uint floor,
        uint premium,
        Payout calldata payout, 
        uint shares
    )  external override onlyMarket {
        _claimTakerPosition(assetAmount, risk, term, floor, premium, payout);
        bAsset.burn(market, account, shares);
    }

    /// @inheritdoc IState
    function newMakerPosition(
        address account,
        uint stableAmount,
        uint16 tier,
        uint16 term
    )  external override onlyMarket returns (uint shares, uint Q) {
        _newMakerPosition(account, stableAmount, tier, term);
        shares = calc.makerShare(stableAmount,tier,term) * (stableAmount + bStable.marketSupply(market)) / UDIVIDER;    
        bStable.mint(market, account, shares);
    }

    /// @inheritdoc IState
    function closeMakerPosition(
        address account,
        uint stableAmount,
        uint16 tier,
        uint16 term,
        int yield,
        Payout calldata payout, 
        uint shares,
        uint Q
    )  external override onlyMarket {
        _closeMakerPosition(account, stableAmount, tier, term, yield, payout);
        bStable.burn(market, account, shares);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @title IMintable 
interface IBToken {
    function mint(address market, address to, uint amount) external;
    function burn(address market, address from, uint amount) external;
    function marketSupply(address market) external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./ClaimState.sol";
import "../struct/RebalanceAmount.sol";

import "hardhat/console.sol";

/// @notice Implementation of State with cumulative index for takers
abstract contract CIState is ClaimState {
    using Address for address;

    /// @notice current taker cumulative index
    uint public override ciTakerAsset;
    uint public override ciTakerStable;

    /// @notice current maker cumulative index
    uint public override ciMaker;

    /// @notice current applied price update timestamp
    uint public lastTimestamp;

    /// @notice current applied price update roundId
    uint80 public lastRoundId;

    /// @notice current applied price from a price feed
    int public lastPrice;

    event Update(bool indexed toCurrentTime, uint ciTakerAsset, uint ciTakerStable);

    /// @param _gac GlobalAccessController instance
    /// @param _market market address
    /// @param _feed price feed contract
    /// @dev {_feed} should implement {AggregatorV3Interface}
    /// @param _DIVIDER_ASSET asset token precision
    constructor(
        address _gac,
        address _market,
        address _feed,
        uint _DIVIDER_ASSET,
        uint _DIVIDER_STABLE
    ) State(_gac, _market, _feed, _DIVIDER_ASSET, _DIVIDER_STABLE) {
        (lastRoundId, lastPrice, , lastTimestamp, ) = AggregatorV3Interface(
            _feed
        ).latestRoundData();
        require(lastTimestamp > 0, "CIS: last-timestamp");
    }

    /// @inheritdoc IState
    function calcCI()
        public
        view
        override
        returns (
            uint cia,
            uint cis
        )
    {
        uint papsInAsset;
        uint papsInStable;
        (papsInAsset, papsInStable, , , , ,) = calc.calcNewPaps(true);

        if(RWA > 0){
            cia = ciTakerAsset + papsInAsset * DIVIDER_ASSET / RWA;
            cis = ciTakerStable + papsInStable * DIVIDER_ASSET / RWA;
        } else {
            cia = ciTakerAsset;
            cis = ciTakerStable;
        }
    }

    /// @inheritdoc IState
    function updateStateToCurrentTime() public override onlyAdapter {
        _update(true);
    }

    /// @inheritdoc IState
    function updateStateToLastPrice() public override onlyKeeper {
        _update(false);
    }

    function _update(bool toCurrentTime) internal {
        console.log("start updateStateToLastPrice");
        uint papsInAsset;
        uint papsInStable;
        uint numberUpdatePrice;
        (
            papsInAsset, 
            papsInStable, 
            lastPrice, 
            lastTimestamp, 
            lastRoundId, 
            numberUpdatePrice,
            expectedClaims
        ) = calc.calcNewPaps(toCurrentTime);

        console.log("cotinue updateStateToLastPrice");

        if(RWA > 0){
            ciTakerAsset += papsInAsset * DIVIDER_ASSET / RWA;
            ciTakerStable += papsInStable * DIVIDER_ASSET / RWA;

            B -= papsInAsset;
            L -= RWL * papsInAsset / RWA;
        }

        E += D * calc.YIELD_EPSILON() / UDIVIDER * numberUpdatePrice;

        console.log("cotinue2 updateStateToLastPrice");

        if (!toCurrentTime){
            RebalanceAmount memory ra = calc.rebalanceAmount(0, 0);
            AP = uint(int(AP) + ra.deltaAP);
            AR = uint(int(AR) + ra.deltaAR);
            CP = uint(int(CP) + ra.deltaCP);
            CR = uint(int(CR) + ra.deltaCR);
        }

        console.log("end updateStateToLastPrice");
        emit Update(toCurrentTime, ciTakerAsset, ciTakerStable);
    }

    function _newTakerPosition(
        uint assetAmount,
        uint16 risk,
        uint16 term,
        uint floor
    ) internal {
        uint rate = calc.getTakerRate(risk, term);

        // AP += assetAmount;
        RWA += (assetAmount * rate) / UDIVIDER;
        RWL += (floor * assetAmount * rate) / UDIVIDER / DIVIDER_ASSET;
        L += (floor * assetAmount) / DIVIDER_ASSET;
        B += assetAmount;

        _addToClaimState(floor * DIVIDER_ORACLE / DIVIDER_STABLE, assetAmount * DIVIDER_STABLE / DIVIDER_ASSET);

        (int deltaAP, int deltaAR) = calc.rebalanceTokenPool(int(assetAmount));
        AP = uint(int(AP) + deltaAP);
        AR = uint(int(AR) + deltaAR);
    }

    function _closeTakerPosition(
        uint assetAmount,
        uint16 risk,
        uint16 term,
        uint floor,
        uint premium,
        Payout calldata payout
    ) internal {
        uint rate = calc.getTakerRate(risk, term);

        RWA -= (assetAmount * rate) / DIVIDER_ASSET;
        RWL -= (floor * assetAmount * rate) / UDIVIDER / DIVIDER_ASSET;
        L -= (floor * (assetAmount - premium)) / DIVIDER_ASSET;
        B -= (assetAmount - premium);

        _removeFromClaimState(floor * DIVIDER_ORACLE / DIVIDER_STABLE, assetAmount * DIVIDER_STABLE / DIVIDER_ASSET);

        if (payout.assetAmount > 0) {
            (int deltaAP, int deltaAR) = calc.rebalanceTokenPool(-int(payout.assetAmount));
            AP = uint(int(AP) + deltaAP);
            AR = uint(int(AR) + deltaAR);
        }

        if (payout.stableAmount > 0){
            (int deltaCP, int deltaCR) = calc.rebalanceStablePool(-int(payout.stableAmount));
            CP = uint(int(CP) + deltaCP);
            CR = uint(int(CR) + deltaCR);
        }
    }

    function _claimTakerPosition(
        uint assetAmount,
        uint16 risk,
        uint16 term,
        uint floor,
        uint premium,
        Payout calldata payout
    ) internal {
        uint rate = calc.getTakerRate(risk, term);

        RWA -= (assetAmount * rate) / DIVIDER_ASSET;
        RWL -= (floor * assetAmount * rate) / UDIVIDER / DIVIDER_ASSET;
        L -= (floor * (assetAmount - premium)) / DIVIDER_ASSET;
        B -= assetAmount - premium;

        _removeFromClaimState(floor * DIVIDER_ORACLE / DIVIDER_STABLE, assetAmount * DIVIDER_STABLE / DIVIDER_ASSET);

        if (payout.assetAmount > 0) {
            (int deltaAP, int deltaAR) = calc.rebalanceTokenPool(-int(payout.assetAmount));
            AP = uint(int(AP) + deltaAP);
            AR = uint(int(AR) + deltaAR);
        }

        if (payout.stableAmount > 0){
            (int deltaCP, int deltaCR) = calc.rebalanceStablePool(-int(payout.stableAmount));
            CP = uint(int(CP) + deltaCP);
            CR = uint(int(CR) + deltaCR);
        }
    }

    function _newMakerPosition(
        address account,
        uint stableAmount,
        uint16 tier,
        uint16 term
    ) internal {
        (uint positiveRate, uint negativeRate) = calc.getMakerRate(tier, term);

        D += stableAmount;

        RWCp += stableAmount * positiveRate / DIVIDER_STABLE;
        RWCn += stableAmount * negativeRate / DIVIDER_STABLE;

        (int deltaCP, int deltaCR) = calc.rebalanceStablePool(int(stableAmount));
        CP = uint(int(CP) + deltaCP);
        CR = uint(int(CR) + deltaCR);
    }

    function _closeMakerPosition(
        address account,
        uint stableAmount,
        uint16 tier,
        uint16 term,
        int yield,
        Payout calldata payout
    ) internal {
        (uint positiveRate, uint negativeRate) = calc.getMakerRate(tier, term);

        uint partOfDebt = stableAmount * DIVIDER_STABLE / D;

        D -= stableAmount;
        E -= E * partOfDebt / DIVIDER_STABLE;
        RWCp -= stableAmount * positiveRate / DIVIDER_STABLE;
        RWCn -= stableAmount * negativeRate / DIVIDER_STABLE;

        if (payout.assetAmount > 0) {
            (int deltaAP, int deltaAR) = calc.rebalanceTokenPool(-int(payout.assetAmount));
            AP = uint(int(AP) + deltaAP);
            AR = uint(int(AR) + deltaAR);
        }

        if (payout.stableAmount > 0){
            (int deltaCP, int deltaCR) = calc.rebalanceStablePool(-int(payout.stableAmount));
            CP = uint(int(CP) + deltaCP);
            CR = uint(int(CR) + deltaCR);
        }
    }

    /// @inheritdoc IState
    function lastUsedPrice()
        external
        view
        override
        returns (
            int _price,
            uint _updatedAt,
            uint80 _roundId
        )
    {
        return (lastPrice, lastTimestamp, lastRoundId);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

struct RebalanceAmount {
    int deltaAP;
    int deltaAR;
    int deltaCP;
    int deltaCR;
    int deltaE;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IClaimState.sol";
import "../struct/ExpectedClaims.sol";
import "./State.sol";
import "../math/Ticks.sol";

import "hardhat/console.sol";

/// @notice Calculate claim value for each price level
abstract contract ClaimState is IClaimState, State {

    mapping(int24 => uint) public ticks;

    ExpectedClaims public expectedClaims;
    Ticks public tickLib;

    function setTickLib(address _tickLib) onlyAdmin external {
        tickLib = Ticks(_tickLib);
    }

    function initializeExpectedClaims(int24 _lastTick, uint _upperLiquidity, uint _claim) onlyAdmin external {
        expectedClaims = ExpectedClaims({
            tick: _lastTick,
            upperLiquidity: _upperLiquidity,
            claim: _claim
        });
    }

    function getExpectedClaims() external view override returns (ExpectedClaims memory) {
        return expectedClaims;
    }

    function getClaims() external view override returns (uint claim) {
        return expectedClaims.claim;
    }

    function moveToTick(int24 tick, ExpectedClaims memory _expectedClaims) public view override returns(ExpectedClaims memory) {
        uint prevTickPrice = tickLib.getPriceAtTick(_expectedClaims.tick);
        if (tick > _expectedClaims.tick) { // price moves up
            console.log("moveToTick forward number ticks %s", uint(int(tick - _expectedClaims.tick)));
            for (int24 _tick = int24(_expectedClaims.tick); _tick < tick; _tick++) {
                if (ticks[_tick] > 0){
                    uint tickPrice = tickLib.getPriceAtTick(_tick);
                    _expectedClaims.upperLiquidity -= ticks[_tick];
                    uint deltaClaim = ticks[_tick] * tickPrice / DIVIDER_ORACLE;
                    if (deltaClaim > _expectedClaims.claim) {
                        _expectedClaims.claim = 0;
                    } else {
                        _expectedClaims.claim -= deltaClaim;
                    }
                }
            }
        }
        else { // price moves down
            console.log("moveToTick backward number ticks %s", uint(int( _expectedClaims.tick - tick)));
            for (int24 _tick = int24(_expectedClaims.tick)-1; _tick >= tick; _tick--) {
                uint tickPrice = tickLib.getPriceAtTick(_tick);
                _expectedClaims.claim += ticks[_tick] * tickPrice / DIVIDER_ORACLE;
                _expectedClaims.upperLiquidity += ticks[_tick];
                prevTickPrice = tickPrice;
            }
        }
        _expectedClaims.tick = tick;
        return _expectedClaims;
    }

    function moveToPrice(uint price, ExpectedClaims memory _expectedClaims) public view override returns(ExpectedClaims memory) {
        int24 tick = tickLib.getTickAtPrice(price); 
        return moveToTick(tick, _expectedClaims);
    }

    function _addToClaimState(uint price, uint amount) internal {
        int24 tick = tickLib.getTickAtPrice(price);
        ticks[tick] += amount;
        if (tick > expectedClaims.tick) {
            uint tickPrice = tickLib.getPriceAtTick(tick);
            expectedClaims.upperLiquidity += amount;

            uint claim = tickPrice * amount / DIVIDER_ORACLE;
            expectedClaims.claim += claim;
        }
    }

    function _removeFromClaimState(uint price, uint amount) internal {
        int24 tick = tickLib.getTickAtPrice(price);
        ticks[tick] -= amount;
        if (tick > expectedClaims.tick) {
            uint tickPrice = tickLib.getPriceAtTick(tick);
            expectedClaims.upperLiquidity -= amount;
            uint claim = tickPrice * amount / DIVIDER_ORACLE;
            expectedClaims.claim -= claim;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../struct/ExpectedClaims.sol";

/// @title IClaimState
interface IClaimState {
    function getExpectedClaims() external view returns (ExpectedClaims memory);
    function getClaims() external view returns (uint);
    function moveToTick(int24 tick, ExpectedClaims memory _claims) external view returns(ExpectedClaims memory);
    function moveToPrice(uint price, ExpectedClaims memory _claims) external view returns(ExpectedClaims memory);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

struct ExpectedClaims {
    uint upperLiquidity;
    uint claim;
    int24 tick;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../interfaces/IState.sol";
import "../interfaces/IMarket.sol";
import "../interfaces/ICalculation.sol";

import "../access/ModuleAccessController.sol";

import "../math/TakerPositionRateAlpha.sol"; // remove Alpha to run tests
import "../math/Precisions.sol";

/// @title Market state base contract
abstract contract State is
    ModuleAccessController,
    Precisions,
    TakerPositionRateAlpha, // remove Alpha to run tests
    IState
{
    /// @notice adapter role
    bytes32 public constant ADAPTER_ROLE = keccak256("ADAPTER_ROLE");        

    /// @notice market address
    address public immutable market;

    /// @notice price feed contract address
    address public immutable feed;

    /// @notice risk calculation contract
    ICalculation public calc;

    /// @notice rebalaner contract address
    address public rebalancer;

    /// @inheritdoc IState
    uint public override AP;

    /// @inheritdoc IState
    uint public override AR;

    /// @inheritdoc IState
    uint public override CP;

    /// @inheritdoc IState
    uint public override CR;

    /// @inheritdoc IState
    uint public override B;

    /// @inheritdoc IState
    uint public override L;

    /// @inheritdoc IState
    uint public override D;

    /// @inheritdoc IState
    uint public override E;

    /// @inheritdoc IState
    uint public override RWA;

    /// @inheritdoc IState
    uint public override RWL;

    /// @inheritdoc IState
    uint public override RWCp;

    /// @inheritdoc IState
    uint public override RWCn;

    /// @param _gac GlobalAccessController instance
    /// @param _market market address
    /// @param _feed price feed contract
    /// @dev {_feed} should implement {AggregatorV3Interface}
    /// @param _DIVIDER_ASSET asset token precision
    constructor(
        address _gac,
        address _market,
        address _feed,
        uint _DIVIDER_ASSET,
        uint _DIVIDER_STABLE
    ) ModuleAccessController(_gac) Precisions(_DIVIDER_ASSET, _DIVIDER_STABLE) {
        market = _market;
        feed = _feed;
        B = 10000; 
        L = 1000000; // for round up issue 
    }

    /// @notice requires a msg.sender to be a market
    modifier onlyMarket() {
        require(msg.sender == market, "CS: not-market");
        _;
    }

    /// @notice requires a msg.sender to be a adapter of market
    modifier onlyAdapter() {
        require(IAccessControl(market).hasRole(ADAPTER_ROLE, msg.sender ), "CS: not-adapter");
        _;
    }

    /// @notice requires a msg.sender to be a rebalancer
    modifier onlyRebalancer() {
        require(msg.sender == rebalancer, "CS: not-rebalancer");
        _;
    }

    /// @inheritdoc IState
    function update(
        int deltaAP,
        int deltaAR,
        int deltaCP,
        int deltaCR,
        int deltaE
    ) public override onlyRebalancer {
        AP = uint(int(AP) + deltaAP);
        AR = uint(int(AR) + deltaAR);
        CP = uint(int(CP) + deltaCP);
        CR = uint(int(CR) + deltaCR);
        E = uint(int(E) + deltaE);
    }

    /// @inheritdoc IState
    function getStateAsStruct()
        public
        view
        override
        returns (MarketState memory)
    {
        return
            MarketState({
                AP: (DIVIDER * int(AP)) / int(DIVIDER_ASSET),
                AR: (DIVIDER * int(AR)) / int(DIVIDER_ASSET),
                CP: (DIVIDER * int(CP)) / int(DIVIDER_STABLE),
                CR: (DIVIDER * int(CR)) / int(DIVIDER_STABLE),
                B: (DIVIDER * int(B)) / int(DIVIDER_ASSET),
                L: (DIVIDER * int(L)) / int(DIVIDER_STABLE),
                D: (DIVIDER * int(D)) / int(DIVIDER_STABLE),
                E: (DIVIDER * int(E)) / int(DIVIDER_STABLE),
                RWA: (DIVIDER * int(RWA)) / int(DIVIDER_ASSET)
            });
    }

    /// @inheritdoc IState
    function setRiskCalc(address _calc) external override onlyGovernance {
        calc = ICalculation(_calc);
    }

    /// @inheritdoc IState
    function setRebalancer(address _rebalancer)
        external
        override
        onlyGovernance
    {
        rebalancer = _rebalancer;
    }

    /// @inheritdoc IState
    function getState()
        external
        view
        override
        returns (
            uint _AP,
            uint _AR,
            uint _CP,
            uint _CR,
            uint _B,
            uint _L,
            uint _D,
            uint _E
        )
    {
        return (AP, AR, CP, CR, B, L, D, E);
    }

    /// @inheritdoc IState
    function price()
        public
        view
        virtual
        override
        returns (
            int _price,
            uint _updatedAt,
            uint80 _roundId
        )
    {
        (_roundId, _price, , _updatedAt, ) = AggregatorV3Interface(feed)
            .latestRoundData();
    }

    /// @inheritdoc IState
    function priceAt(uint80 _roundId)
        public
        view
        virtual
        override
        returns (int _price, uint _updatedAt)
    {
        (, _price, , _updatedAt, ) = AggregatorV3Interface(feed).getRoundData(
            _roundId
        );
    }
}

pragma solidity >0.7.0;

import "../libraries/TickMath.sol";

contract Ticks {
    /// @dev used to increase tick size
    int24 private constant tickScale = 100;

    function getPriceAtTick(int24 tick) public pure returns (uint) {
        uint160 priceSqrtRaw = TickMath.getSqrtRatioAtTick(
            int24(tick * tickScale)
        );

        return (uint(priceSqrtRaw) >> 96)**2;
    }

    function getTickAtPrice(uint price) public pure returns (int24) {
        int24 tickRaw = TickMath.getTickAtSqrtRatio(
            uint160(_sqrt(price) << 96)
        );
        return tickRaw / tickScale;
    }

    function getNextTick(int24 tick) public pure returns (int24) {
        return tick + 1;
    }

    function getPrevTick(int24 tick) public pure returns (int24) {
        return tick - 1;
    }

    function _sqrt(uint y) internal pure returns (uint sqrt) {
        if (y > 3) {
            sqrt = y;
            uint x = y / 2 + 1;
            while (x < sqrt) {
                sqrt = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            sqrt = 1;
        }
    }

    function sqrtu (uint256 x) internal pure returns (uint) {
        unchecked {
            if (x == 0) return 0;
            else {
                uint256 xx = x;
                uint256 r = 1;
                if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
                if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
                if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
                if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
                if (xx >= 0x100) { xx >>= 8; r <<= 4; }
                if (xx >= 0x10) { xx >>= 4; r <<= 2; }
                if (xx >= 0x8) { r <<= 1; }
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1; // Seven iterations should be enough
                uint256 r1 = x / r;
                return (r < r1 ? r : r1);
            }
        }
    }
}

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IClaimState.sol";
import "../struct/TakerPosition.sol";
import "../struct/MakerPosition.sol";
import "../struct/MarketState.sol";
import "../struct/Payout.sol";

interface IState is IClaimState {
    /// @return current asset Pool value
    function AP() external view returns (uint);

    /// @return current asset Reserve value
    function AR() external view returns (uint);

    /// @return current book value
    function B() external view returns (uint);

    /// @return current liability value in price oracle precision
    function L() external view returns (uint);

    /// @return current capital Pool value
    function CP() external view returns (uint);

    /// @return current capital Reserve value
    function CR() external view returns (uint);

    /// @return current debt value
    function D() external view returns (uint);

    /// @return current yield target value
    function E() external view returns (uint);

    /// @return current risk weighted asset pool value
    function RWA() external view returns (uint);

    /// @return current risk weighted liability value
    function RWL() external view returns (uint);

    /// @return current risk weighted capital value with positive rate
    function RWCp() external view returns (uint);

    /// @return current risk weighted capital value with negative rate
    function RWCn() external view returns (uint);

    /// @notice create new taker position state callback
    /// @param assetAmount amount of asset token
    /// @param risk position risk value
    /// @param term position term value
    /// @param floor position floor value
    function newTakerPosition(
        address account,
        uint assetAmount,
        uint16 risk,
        uint16 term,
        uint floor
    ) external returns (uint shares);

    /// @notice create taker position state callback
    /// @param account user address
    /// @param assetAmount amount of asset token
    /// @param risk position risk value
    /// @param term position term value
    /// @param floor position floor value
    /// @param payout payout stuct value
    function closeTakerPosition(
        address account,
        uint assetAmount,
        uint16 risk,
        uint16 term,
        uint floor,
        uint premium,
        Payout calldata payout, 
        uint shares
    ) external;

    /// @notice claim on taker position state callback
    /// @param account user address
    /// @param assetAmount amount of asset token
    /// @param risk position risk value
    /// @param term position term value
    /// @param floor position floor value
    /// @param payout payout stuct value
    function claimTakerPosition(
        address account,
        uint assetAmount,
        uint16 risk,
        uint16 term,
        uint floor,
        uint premium,
        Payout calldata payout, 
        uint shares
    ) external;

    /// @notice create new maker position state callback
    /// @param account user address
    /// @param stableAmount amount of stable token
    /// @param tier position tier value
    /// @param term position term value
    function newMakerPosition(
        address account,
        uint stableAmount,
        uint16 tier,
        uint16 term
    ) external returns (uint shares, uint Q);

    /// @notice close maker position state callback
    /// @param account user address
    /// @param stableAmount amount of stable token
    /// @param tier position tier value
    /// @param term position term value
    /// @param yield position yield value
    /// @param payout payout stuct value
    function closeMakerPosition(
        address account,
        uint stableAmount,
        uint16 tier,
        uint16 term,
        int yield,
        Payout calldata payout,
        uint shares,
        uint Q
    ) external;

    /// @notice returns asset information from a price feed
    /// @return _price current asset price
    /// @return _updatedAt price updated at timestamp
    /// @return _roundId latest price update id
    function price()
        external
        view
        returns (
            int _price,
            uint _updatedAt,
            uint80 _roundId
        );

    /// @notice returns last used price information
    /// @return _price last used asset price
    /// @return _updatedAt last used price updated at timestamp
    /// @return _roundId last used price update id
    function lastUsedPrice()
        external
        view
        returns (
            int _price,
            uint _updatedAt,
            uint80 _roundId
        );

    /// @notice returns price info by roundId used price information
    /// @param roundId price update round id
    /// @return _price price by a given round id
    /// @return _updatedAt price updated at by a given round id
    function priceAt(uint80 roundId)
        external
        view
        returns (int _price, uint _updatedAt);

    /// @notice updates state veriable by a given delta values
    /// @param deltaAP delta Asset Pool value
    /// @param deltaAR delta Asset Reserve value
    /// @param deltaCP delta Capital Pool value
    /// @param deltaCR delta Capital Reserve value
    /// @param deltaY delta Yeld target value
    function update(
        int deltaAP,
        int deltaAR,
        int deltaCP,
        int deltaCR,
        int deltaY
    ) external;

    /// @notice updates state variables to current time
    function updateStateToCurrentTime() external;

    /// @notice updates state variables to last price
    function updateStateToLastPrice() external;

    /// @return state variables as a struct
    function getStateAsStruct() external view returns (MarketState memory);

    /// @notice returns state variables by a single function call
    function getState()
        external
        view
        returns (
            uint AP,
            uint AR,
            uint CP,
            uint CR,
            uint B,
            uint L,
            uint D,
            uint Y
        );

    /// @notice set a rebalancer contract address
    /// @param _rebalancer new rebalancer address
    function setRebalancer(address _rebalancer) external;

    /// @notice set a risk calculation contract address
    /// @param _calc new risk calculation address
    function setRiskCalc(address _calc) external;

    /// @notice calculates a cumulative index for taker
    /// @return cia cummulative index (in assets)
    /// @return cis cummulative index (in stables)
    function calcCI()
        external
        view
        returns (
            uint cia,
            uint cis
        );

    function ciTakerAsset() external view returns (uint);

    function ciTakerStable() external view returns (uint);

    function ciMaker() external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable as IERC20Metadata} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../struct/TakerPosition.sol";
import "../struct/MakerPosition.sol";
import "../struct/UserPositions.sol";
import "../struct/Payout.sol";

import "./IMakerPosition.sol";
import "./ITakerPosition.sol";
import "./IBond.sol";

interface IMarket {
    /// @notice opens a new taker position
    /// @param account initial position owner
    /// @param amount asset amount to protect
    /// @param risk position risk value
    /// @param term position term value
    /// @param bumpAmount bump amount to lock as a bond in the position
    /// @param flags packed position flags
    /// @return id created position id
    /// @dev allowed values of {risk} and {term} are depends of a particular
    /// market and a {Calculation} contract that is uses
    function protect(
        address account,
        uint amount,
        uint toTreasury,
        uint16 risk,
        uint16 term,
        uint bumpAmount,
        uint192 flags
    ) external returns (uint id, uint floor);

    /// @notice closes an existing taker position
    /// @notice position can be closed only if position term is over
    /// @param account position owner
    /// @param id taker position id
    /// @param unwrap if market is a wrapped native, this flag is says that asset should be
    /// unwrapped to native or it should be returned as a wrapped native
    /// @param stable stable token address to make payout in
    function close(
        address account,
        uint id,
        bool unwrap,
        address stable
    ) external returns (uint premium, Payout memory payout);

    /// @notice closes an existing taker position and claims stable
    /// @notice position can be closed only if position term is over
    /// @param account position owner
    /// @param id taker position id
    /// @param stable stable token address to make payout in
    function claim(
        address account,
        uint id,
        address stable
    ) external returns (uint premium, Payout memory payout);

    /// @notice cancel existing taker position
    /// @notice position can be canceled even if position term is not over
    /// @param account position owner
    /// @param id taker position id
    /// @param unwrap if market is a wrapped native, this flag is says that asset should be
    /// unwrapped to native or it should be returned as a wrapped native
    /// @param stable stable token address to make payout in
    function cancel(
        address account,
        uint id,
        bool unwrap,
        address stable
    ) external returns (uint premium, Payout memory payout);

    /// @notice opens a new maker position
    /// @param account initial position owner
    /// @param amount asset amount to protect
    /// @param risk position risk value
    /// @param term position term value
    /// @param bumpAmount bump amount to lock as a bond in the position
    /// @param flags packed position flags
    /// @return id created position id
    /// @dev allowed values of {risk} and {term} are depends of a particular
    /// market and a {Calculation} contract that is uses
    function deposit(
        address account,
        uint amount,
        uint toTreasury,
        uint16 risk,
        uint16 term,
        uint bumpAmount,
        uint192 flags
    ) external returns (uint id);

    /// @notice closes an existing maker position and claim yield
    /// @notice position can be closed only if position term is over
    /// @param account initial position owner
    /// @param id existing position id
    /// @param stable stable token address to make payout in
    function withdraw(
        address account,
        uint id,
        address stable
    ) external returns (int yield, Payout memory payout);

    /// @notice Allows a Maker to terminate their position before the end of the fixed term.
    /// @notice Comes with forfeiture of positive yield and an early termination penalty.
    /// @param account initial position owner
    /// @param id existing position id
    /// @param stable stable token address to make payout in
    function abandon(
        address account,
        uint id,
        address stable
    ) external returns (int yield, Payout memory payout);

    /// @notice Set user profile data for given account
    /// @param account user address
    /// @param profile profile data (can be use separately by few fields)
    function setUserProfile(address account, uint profile) external;

    /// @notice Asset token address
    /// @return Asset token
    function ASSET() external view returns (IERC20);

    /// @notice Stable token address
    /// @return Stable token
    function STABLE() external view returns (IERC20);

    /// @return risk calculation contract address
    function getRiskCalc() external view returns (address);

    /// @return market state contract address
    function getState() external view returns (address);

    /// @notice Get all Taker`s positions
    /// @param taker taker address
    /// @return array of ids of all taker`s positions
    function getTakerPositions(address taker)
        external
        view
        returns (uint[] memory);

    /// @notice Get all Maker`s positions
    /// @param maker maker address
    /// @return array of ids of all maker`s positions
    function getMakerPositions(address maker)
        external
        view
        returns (uint[] memory);

    /// @notice Get Taker position by position id
    /// @param id position id
    /// @return position struct
    function getTakerPosition(uint id)
        external
        view
        returns (TakerPosition memory);

    /// @notice Get Maker position by position id
    /// @param id position id
    /// @return position struct
    function getMakerPosition(uint id)
        external
        view
        returns (MakerPosition memory);

    /// @notice Get Taker position size and locked bond amount 
    /// @param id  position id
    /// @return size position size (in assets)
    /// @return bond locked bond amount
    function getTakerPositionSize(uint id) external view returns (uint size, uint bond);

    /// @notice Get Maker position size
    /// @param id position id
    /// @return size position size (in stable)
    /// @return bond position bond locked bond amount
    function getMakerPositionSize(uint id) external view returns (uint size, uint bond);

    /// @notice Get user profile
    /// @param account address of account
    /// @return uint value that can be divided by few fields    
    function getUserProfile(address account) external view returns (uint);

    // calculate premium
    function premiumOnClose(uint id) external view returns (uint premiumByCI, uint fee, uint extraPremium);

    function premiumOnClaim(uint id) external view returns (uint premiumByCI, uint fee, uint extraPremium);

    function premiumOnCancel(uint id) external view returns (uint premiumByCI, uint fee, uint extraPremium);

    // calculate yield
    function yieldOnWithdraw(uint id) external view returns (int);

    function yieldOnAbandon(uint id) external view returns (int);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IRebalanceCalculation.sol";
import "./IRiskCalculation.sol";

interface ICalculation is IRebalanceCalculation, IRiskCalculation {
    function validateMakerPos(uint16 risk, uint16 term) external pure;

    function validateTakerPos(uint16 risk, uint16 term) external pure;

    function takerShare(uint amount, uint16 risk, uint16 term, uint floor) external view returns (uint);
    function makerShare(uint amount, uint16 tier, uint16 term) external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IGlobalAccessControl.sol";

/// @notice Module Access Controller (MAC)
/// @notice Inherit this to provide access control functions.
abstract contract ModuleAccessController is AccessControl {
    /// @dev contract-owned role, stored in AccessControl
    bytes32 public constant LOCAL_GOVERNANCE_ROLE =
        keccak256("LOCAL_GOVERNANCE_ROLE");

    /// @dev protocol-owned role, stored in GlobalAccessController
    bytes32 public constant GLOBAL_GOVERNANCE_ROLE =
        keccak256("GLOBAL_GOVERNANCE_ROLE");

    /// @dev GlobalAccessController instance reference
    IGlobalAccessControl public gac;

    /// @param _gac GlobalAccessController address
    constructor(address _gac) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setGlobalAccessController(_gac);
    }

    /// @dev requires msg.sender to have DEFAULT_ADMIN_ROLE
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "MAC: not-Admin");
        _;
    }

    /// @dev requires msg.sender to have either a LOCAL_GOVERNANCE_ROLE or a GLOBAL_GOVERNANCE_ROLE or both
    modifier onlyGovernance() {
        require(
            hasRole(LOCAL_GOVERNANCE_ROLE, msg.sender) ||
                gac.userHasRole(GLOBAL_GOVERNANCE_ROLE, msg.sender),
            "MAC: not-Governance"
        );
        _;
    }

    /// @dev requires msg.sender to have a LOCAL_GOVERNANCE_ROLE
    modifier onlyLocalGovernance() {
        require(
            hasRole(LOCAL_GOVERNANCE_ROLE, msg.sender),
            "MAC: not-localGov"
        );
        _;
    }

    /// @dev requires msg.sender to have a GLOBAL_GOVERNANCE_ROLE
    modifier onlyGlobalGovernance() {
        require(
            gac.userHasRole(gac.GLOBAL_GOVERNANCE_ROLE(), msg.sender),
            "MAC: not-globalGov"
        );
        _;
    }

    /// @dev requires msg.sender to have a GLOBAL_KEEPER_ROLE
    modifier onlyKeeper() {
        require(
            gac.userHasRole(gac.GLOBAL_KEEPER_ROLE(), msg.sender),
            "MAC: not-keeper"
        );
        _;
    }


    /// @notice store external global access controller address to check access using global permission storage
    function _setGlobalAccessController(address _gac) internal {
        gac = IGlobalAccessControl(_gac);
    }

    /// @notice grants a given role to a given account
    /// @notice can be called only from address with a DEFAULT_ADMIN_ROLE
    /// @dev same as {_grantRole}
    function grantRole(bytes32 role, address account)
        public
        override
        onlyAdmin
    {
        _grantRole(role, account);
    }

    /// @notice revokes a given role from a given account
    /// @notice can be called only from address with a DEFAULT_ADMIN_ROLE
    /// @dev same as {_revokeRole}
    function revokeRole(bytes32 role, address account)
        public
        override
        onlyAdmin
    {
        _revokeRole(role, account);
    }

    /// @notice returns is a user has a role on a GlobalAccessController
    function userHasRole(bytes32 role, address account)
        public
        view
        returns (bool)
    {
        return gac.userHasRole(role, account);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/ITakerPositionRate.sol";

/// @notice NFT token for taker position
abstract contract TakerPositionRateAlpha is ITakerPositionRate {

    uint public constant T_10_70 = 1.52 * 10**18;
    uint public constant T_5_70 = 1.75 * 10**18;

    uint public constant T_10_80 = 1.98 * 10**18;
    uint public constant T_5_80 = 2.27 * 10**18;

    uint public constant T_10_85 = 2.57 * 10**18;
    uint public constant T_5_85 = 2.96 * 10**18;

    uint public constant T_10_90 = 3.34 * 10**18;
    uint public constant T_5_90 = 3.84 * 10**18;

    uint public constant T_10_95 = 4.34 * 10**18;
    uint public constant T_5_95 = 5.00 * 10**18;


    function getTakerRate(uint16 risk, uint16 term)
        public
        pure
        override
        returns (uint)
    {
        if (risk == 7000) {
            if (term == 5) return T_5_70;
            if (term == 10) return T_10_70;
        } else if (risk == 8000) {
            if (term == 5) return T_5_80;
            if (term == 10) return T_10_80;
        } else if (risk == 8500) {
            if (term == 5) return T_5_85;
            if (term == 10) return T_10_85;
        } else if (risk == 9000) {
            if (term == 5) return T_5_90;
            if (term == 10) return T_10_90;
        } else if (risk == 9500) {
            if (term == 5) return T_5_95;
            if (term == 10) return T_10_95;
        }

        revert("TPR: wrong-rate");
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

abstract contract Precisions {
    uint public constant DIVIDER_PRECISION = 18; // DIVIDER that used in all calculation

    uint public constant DIVIDER_ORACLE_PRECISION = 8; // oracle divider

    uint public constant UDIVIDER = (10**DIVIDER_PRECISION);
    int public constant DIVIDER = int(10**DIVIDER_PRECISION);
    uint public constant DIVIDER_ORACLE = (10**DIVIDER_ORACLE_PRECISION);

    uint public immutable DIVIDER_ASSET;
    uint public immutable DIVIDER_STABLE;

    constructor(uint _DIVIDER_ASSET, uint _DIVIDER_STABLE) {
        DIVIDER_STABLE = _DIVIDER_STABLE;
        DIVIDER_ASSET = _DIVIDER_ASSET;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice Taker position representation structure
struct TakerPosition {
    address owner; // owner of the position
    uint assetAmount; // amount of tokens
    uint floor; // floor price of the protected tokens
    uint bumpAmount; // locked bump amount for this position
    uint ci; // start position cummulative index
    uint32 start; // timestamp when position was opened
    uint16 risk; // risk in percentage with 100 multiplier (9000 means 90%)
    uint16 term; // term (in days) of protection
    uint192 flags; // option flags
    uint shares;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice Maker position representaion structure
struct MakerPosition {
    address owner; // owner of the position
    uint stableAmount; // amount of stable tokens
    uint bumpAmount; // locked bump amount for this position
    uint ci; // start position cummulative index
    uint32 start; // CI when position was opened
    uint16 term; // term (in days) of protection
    uint16 tier; // tier number (1-5)
    uint192 flags; // option flags
    uint shares; // share of the capital pool
    uint Q;     // 
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

struct MarketState {
    int AP; // Asset pool (in tokens with DIVIDER precision)
    int AR; // Asset reserve (in tokens with DIVIDER precision)
    int CP; // Capital pool with DIVIDER precision
    int CR; // Capital reserve with DIVIDER precision
    int B; // Book (in tokens with DIVIDER precision)
    int L; // Liability in ORACLE precision
    int D; // Debt with DIVIDER precision
    int E; // Yield target value with DIVIDER precision (can be negative)
    int RWA; // Risk weighted asset pool
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice Maker position representaion structure
struct Payout {
    //uint bumpAmount;
    uint assetAmount;
    uint stableAmount;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

struct UserPositions {
    EnumerableSet.UintSet taker;
    EnumerableSet.UintSet maker;
    uint profile;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../struct/MakerPosition.sol";

interface IMakerPosition {
    /// @notice creates a new maker position
    /// @notice takes part of an {amount} to lock as a bond
    /// if deposited bond amount is insufficient
    /// @param amount asset amount to protect
    /// @param tier position tier value
    /// @param term position term value
    /// @param autorenew whether position auto renewing is available
    /// or it`s not
    /// @return id created position id
    /// @dev allowed values of {tier} and {term} are depends of a particular
    /// market and a {Calculation} contract that is uses
    function deposit(
        uint amount,
        uint16 tier,
        uint16 term,
        bool autorenew
    ) external returns (uint id);

    /// @notice protect with bump bond permit only
    /// @notice See more in {deposit}
    function depositWithAutoBondingPermit(
        uint amount,
        uint16 tier,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint id);

    /// @notice deposit with both stable and bump bond permits
    /// @notice See more in {depositWithPermit}
    /// @param permitStable encoded [deadline, v, r, s] values for stable permit using abi.encode
    /// @param permitBump encoded [deadline, v, r, s] values for bump permit using abi.encode
    function depositWithPermitWithAutoBondingPermit(
        uint amount,
        uint16 tier,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        bytes memory permitStable,
        bytes memory permitBump
    ) external returns (uint id);

    /// @notice deposit with stable token permit only
    /// @notice See more in {deposit}
    function depositWithPermit(
        uint amount,
        uint16 tier,
        uint16 term,
        bool autorenew,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint id);

    /// @notice closes an existing maker position and claim yield
    /// @notice position can be closed only if position term is over
    /// @param id existing position id
    /// @param withdrawBond says to withdraw deposited bump tokens back to user or not
    function withdraw(uint id, bool withdrawBond) external;

    /// @notice emergency close of an existing maker position
    /// @notice position can be abandoned even if position term is not over
    /// @param id existing position id
    /// @dev requires {abandonmentPermitted} flag to be true
    function abandon(uint id) external;

    /// @notice toggles an auto renew flag value for existing maker position
    /// @notice can be called only from position owner
    /// @param id existing position id
    function toggleMakerAutorenew(uint id) external;

    /// @param id existing maker position id
    /// @return pos maker position struct
    function getMakerPosition(uint id)
        external
        view
        returns (MakerPosition memory);

    /// @notice emits when new Maker position opens
    /// @param account position owner
    /// @param id created position id
    /// @param amount position asset amount
    /// @param tier position tier value
    /// @param term position term value
    /// @param flags position packed flags
    event Deposit(
        address indexed account,
        uint id,
        uint amount,
        uint16 tier,
        uint16 term,
        uint192 flags,
        uint bumpAmount,
        uint boost,
        uint incentives
    );

    /// @notice emits whenever Maker makes withdraw
    /// @param account position owner
    /// @param id position id
    /// @param reward maker claimed reward
    /// @param assetAmount position claimed asset amount
    /// @param stableAmount position claimed stable amount
    event Withdraw(
        address indexed account,
        uint id,
        int reward,
        uint assetAmount,
        uint stableAmount
    );

    /// @notice emits whenever Maker abandons the position
    /// @param account position owner
    /// @param id position id
    /// @param reward maker claimed reward
    /// @param assetAmount position claimed asset amount
    /// @param stableAmount position claimed stable amount
    event Abandon(
        address indexed account,
        uint id,
        int reward,
        uint assetAmount,
        uint stableAmount
    );        

    /// @notice emits whenever the position is liquidating
    /// @param account position owner
    /// @param id position id 
    event LiquidateMakerPosition(  
        address indexed account,
        uint id
    );    
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../struct/TakerPosition.sol";

interface ITakerPosition {
    /// @notice opens a new taker position
    /// @notice takes part of an {amount} to lock as a bond
    /// if deposited bond amount is insufficient
    /// @param amount asset amount to protect
    /// @param risk position risk value
    /// @param term position term value
    /// @param autorenew whether position auto renewing is available
    /// or it`s not
    /// @return id created position id
    /// @dev allowed values of {risk} and {term} are depends of a particular
    /// market and a {Calculation} contract that is uses
    function protect(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew
    ) external returns (uint id);

    /// @notice opens a new taker position
    /// @notice takes a part of an position amount to lock as a bond
    /// if deposited bond amount is insufficient
    /// @param risk position risk value
    /// @param term position term value
    /// @param autorenew whether position auto renewing is available
    /// or it`s not
    /// @return id created position id
    /// @dev allowed values of {risk} and {term} are depends of a particular
    /// market and a {Calculation} contract that is uses
    /// @dev position asset amount should be passed to function as msg.value
    function protectNative(
        uint16 risk,
        uint16 term,
        bool autorenew
    ) external payable returns (uint id);

    /// @notice protect with bump bond permit only
    /// @notice See more in {protect}
    function protectWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint id);

    /// @notice protect with both asset and bump bond permits
    /// @notice See more in {protectWithPermit}
    /// @param permitAsset encoded [deadline, v, r, s] values for asset permit using abi.encode
    /// @param permitBump encoded [deadline, v, r, s] values for bump permit using abi.encode
    function protectWithPermitWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        bytes memory permitAsset,
        bytes memory permitBump
    ) external returns (uint id);

    /// @notice protect with asset token permit only
    /// @notice See more in {protect}
    function protectWithPermit(
        uint amount,
        uint16 risk,
        uint16 term,    
        bool autorenew,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint id);

    /// @notice closes an existing taker position
    /// @notice position can be closed only if position term is over
    /// @param id taker position id
    /// @param unwrap if market is a wrapped native, this flag is says that asset should be
    /// unwrapped to native or it should be returned as a wrapped native
    /// @param withdrawBond says to withdraw deposited bump tokens back to user or not
    function close(
        uint id,
        bool unwrap,
        bool withdrawBond
    ) external;

    /// @notice closes an existing taker position and claims stable
    /// @notice position can be closed only if position period has passed
    /// @param id taker position id
    /// @param withdrawBond says to withdraw deposited bump tokens back to user or not
    function claim(uint id, bool withdrawBond) external;

    /// @notice cancel taker position
    /// @notice position can be canceled even if position term is not over
    /// @param id taker position id
    /// @param unwrap if market is a wrapped native, this flag is says that asset should be
    /// unwrapped to native or it should be returned as a wrapped native
    /// @dev requires {cancellationPermitted} flag to be true
    function cancel(
        uint id,
        bool unwrap
    ) external;

    /// @notice toggles an auto renew flag value for existing taker position
    /// @notice can be called only from position owner
    /// @param id existing position id
    function toggleTakerAutorenew(uint id) external;

    /// @param id existing maker position id
    /// @return pos taker position struct
    function getTakerPosition(uint id)
        external
        view
        returns (TakerPosition memory);

    /// @notice emits when new Taker position opens
    /// @param account position owner
    /// @param id created position id
    /// @param amount position asset amount
    /// @param floor position asset price floor
    /// @param risk position risk value
    /// @param term position term value
    /// @param flags position packed flags
    event Protect(
        address indexed account,
        uint id,
        uint amount,
        uint floor,
        uint16 risk,
        uint16 term,
        uint192 flags,
        uint bumpAmount,
        uint boost,
        uint incentives
    );

    /// @notice emits whenever Maker makes claim
    /// @param account position owner
    /// @param id position id
    /// @param floor position asset price floor
    /// @param assetAmount position claimed asset amount
    /// @param stableAmount position claimed stable amount
    event Claim(
        address indexed account,
        uint id,
        uint floor,
        uint assetAmount,
        uint stableAmount
    );

    /// @notice emits whenever Maker makes close
    /// @param account position owner
    /// @param id position id
    /// @param premium paid premium
    /// @param assetAmount position claimed asset amount
    /// @param stableAmount position claimed stable amount
    event Close(
        address indexed account,
        uint id,
        uint premium,
        uint assetAmount,
        uint stableAmount
    );

    /// @notice emits whenever Maker cancels a position
    /// @param account position owner
    /// @param id position id
    /// @param premium paid premium
    /// @param assetAmount position claimed asset amount
    /// @param stableAmount position claimed stable amount
    event Cancel(
        address indexed account,
        uint id,
        uint premium,
        uint assetAmount,
        uint stableAmount
    );

    /// @notice emits whenever Taker makes close and premium reach position size
    /// @param account position owner
    /// @param id position id
    event PremiumTooHigh(
        address indexed account,
        uint id
    );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../struct/BondConfig.sol";

/// @title IBond
interface IBond {
    /// @return address of token which contract stores
    function BOND_TOKEN_ADDRESS() external view returns (address);

    function total() external view returns (uint);

    /// @notice transfers amount from your address to contract
    /// @param depositTo - address on which tokens will be deposited
    /// @param amount - amount of token to store in contract
    function deposit(address depositTo, uint amount) external;

    /// @notice permit version of {deposit} method
    function depositWithPermit(
        address depositTo,
        uint amount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice transfers amount from given address to contract
    /// @dev should be called only from authorized accounts
    /// @param from - user address
    /// @param amount - amount of token to withdraw from contract
    function withdrawFrom(address from, uint amount) external;

    /// @notice transfers amount from your address to contract
    /// @param amount - amount of token to withdraw from contract
    function withdraw(uint amount) external;

    /// @notice unlocks amount of token in contract
    /// @param _owner - owner of the position
    /// @param bondAmount - amount of bond token to unlock
    function unlock(address _owner, uint bondAmount) external;

    /// @notice calculates taker's bond to lock in contract
    /// @param token - token address
    /// @param amount - amount of asset token
    /// @param risk - risk in percentage with 100 multiplier (9000 means 90%)
    /// @param term - term (in days) of protection
    /// @return bondAmount to lock based on taker position
    function takerBond(
        address token,
        uint amount,
        uint16 risk,
        uint16 term
    ) external view returns (uint bondAmount);

    /// @notice calculates maker's bond to lock in contract
    /// @param token - token address
    /// @param amount - amount of stable token to lock
    /// @param risk - risk number (1-5)
    /// @param term - term (in days) of protection
    /// @return bondAmount to lock based on maker position
    function makerBond(
        address token,
        uint amount,
        uint16 risk,
        uint16 term
    ) external view returns (uint bondAmount);

    /// @notice how much of bond amount will be reduced for taker position
    function takerToSwap(address token, uint bondAmount)
        external
        view
        returns (uint amount);

    /// @notice how much of bond amount will be reduced for maker position
    function makerToSwap(address token, uint bondAmount)
        external
        view
        returns (uint amount);

    function autoLockBondTakerPosition(
        address recipient,
        address token,
        uint amount,
        uint16 risk,
        uint16 term,
        uint boostAmount,
        uint incentivesAmount              
    )
        external
        returns (
            uint bondAmount,
            uint toTransfer,
            uint toReduce
        );

    function autoLockBondMakerPosition(
        address recipient,
        address token,
        uint amount,
        uint16 risk,
        uint16 term,
        uint boostAmount,
        uint incentivesAmount              
    )
        external
        returns (
            uint bondAmount,
            uint toTransfer,
            uint toReduce
        );

    /// @notice calculates amount of bond position for taker
    function calcBondSizeForTakerPosition(
        address recipient,
        address token,
        uint amount,
        uint16 risk,
        uint16 term  
    )
        external
        view
        returns (
            uint toLock,
            uint toTransfer,
            uint toReduce
        );

    /// @notice calculates amount of bond position for maker
    function calcBondSizeForMakerPosition(
        address recipient,
        address token,
        uint amount,
        uint16 risk,
        uint16 term     
    )
        external
        view
        returns (
            uint toLock,
            uint toTransfer,
            uint toReduce
        );

    /// @notice locks amount of deposited bond
    function lock(address addr, uint amount) external;

    /// @param addr - address of user
    /// @return amount - locked amount of particular user
    function lockedOf(address addr) external view returns (uint amount);

    /// @param addr - address of user
    /// @return amount - deposited amount of particular user
    function balanceOf(address addr) external view returns (uint amount);

    /// @notice transfer locked bond between accounts
    function transferLocked(
        address from,
        address to,
        uint amount
    ) external;

    /// @notice Calculate Bond multipliers for given token
    function calcBonding(
        address token,
        uint bumpPrice,
        uint assetPrice
    ) external;

    function setBondTheta(
        address token, 
        uint thetaAsset1, 
        uint thetaStable1, 
        uint thetaAsset2, 
        uint thetaStable2 
    ) external;

    /// @notice liquidate user locked bonds (used in liquidation flow)
    function liquidate(address from, uint amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @title BondConfig
struct BondConfig {
    uint bumpPerAsset; 
    uint bumpPerStable; 
    uint assetPerBump;  
    uint stablePerBump;
    uint thetaAsset1;
    uint thetaAsset2;
    uint thetaStable1;
    uint thetaStable2;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../struct/TakerPosition.sol";
import "../struct/MakerPosition.sol";
import "../struct/MarketState.sol";
import "../struct/RebalanceAmount.sol";

/// @notice Rebalance parameters calculation
interface IRebalanceCalculation {
    function getSellAmount()  external view returns (uint sellToken, uint sellStable);

    function rebalanceAmount(int changeToken, int changeStable) external view returns (RebalanceAmount memory);

    function rebalanceTokenPool(int changeToken) external view returns(int deltaAP, int deltaAR);

    function rebalanceStablePool(int changeStable) external view returns(int deltaCP, int deltaCR);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IMarket.sol";
import "./ITakerPositionRate.sol";
import "./IMakerPositionRate.sol";
import "./IPAPCalculation.sol";
import "./IYieldCalculation.sol";
import "../struct/BoostingParameters.sol";

interface IRiskCalculation is ITakerPositionRate, IMakerPositionRate, IPAPCalculation, IYieldCalculation {

    function premiumOnClose(uint id) external view returns (uint premiumByCI, uint fee, uint extraPremium);

    function premiumOnClaim(uint id) external view returns (uint premiumByCI, uint fee, uint extraPremium);

    function premiumOnCancel(uint id) external view returns (uint premiumByCI, uint fee, uint extraPremium);

    function yieldOnWithdraw(uint id) external view returns (int);

    function yieldOnAbandon(uint id) external view returns (int);

    function boostParameters() external returns (BoostingParameters memory);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface ITakerPositionRate {
    function getTakerRate(uint16 risk, uint16 term)
        external
        pure
        returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IMakerPositionRate {
    function getMakerRate(uint16 tier, uint16 term)
        external
        pure
        returns (uint, uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "../struct/ExpectedClaims.sol";

interface IPAPCalculation {

    /// @notice Calculate premium against the asset pool
    /// @param toCurrentTime - force update to current time
    function calcNewPaps(bool toCurrentTime)
    external
    view
    returns (
        uint papsInAsset,
        uint papsInStable,
        int _lastPrice,
        uint _lastTimestamp,
        uint80 _lastRoundId,
        uint numberUpdatePrice,
        ExpectedClaims memory expectedClaims
    );

    function pClaim(
        uint expectedClaims,
        int L
    ) external view returns (int);

    function pClaim(
        uint expectedClaims,
        uint L
    ) external view returns (int);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IYieldCalculation {
    function YIELD_EPSILON() external pure returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

struct BoostingParameters {
    int w1max;
    int w11max;
    int w1;
    int lrr1;
    int w11;
    int lrr11;
    int pbl1;
    int pbl11;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
        _checkRole(role, _msgSender());
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice Interface for shared access control
interface IGlobalAccessControl {
    function GLOBAL_GOVERNANCE_ROLE() external view returns (bytes32);
    
    function GLOBAL_KEEPER_ROLE() external view returns (bytes32);

    function userHasRole(bytes32 role, address account)
        external
        view
        returns (bool);
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

import "./IERC165.sol";

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(uint24(MAX_TICK)), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}