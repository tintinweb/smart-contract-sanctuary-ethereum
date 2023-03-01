// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IExternalPosition Contract
/// @author Enzyme Council <[email protected]>
interface IExternalPosition {
    function getDebtAssets() external returns (address[] memory, uint256[] memory);

    function getManagedAssets() external returns (address[] memory, uint256[] memory);

    function init(bytes memory) external;

    function receiveCallFromVault(bytes memory) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IExternalPositionParser Interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for all external position parsers
interface IExternalPositionParser {
    function parseAssetsForAction(
        address _externalPosition,
        uint256 _actionId,
        bytes memory _encodedActionArgs
    )
        external
        returns (
            address[] memory assetsToTransfer_,
            uint256[] memory amountsToTransfer_,
            address[] memory assetsToReceive_
        );

    function parseInitArgs(address _vaultProxy, bytes memory _initializationData)
        external
        returns (bytes memory initArgs_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

import "../../../../../persistent/external-positions/IExternalPosition.sol";

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @title ISolvV2BondBuyerPosition Interface
/// @author Enzyme Council <[email protected]>
interface ISolvV2BondBuyerPosition is IExternalPosition {
    enum Actions {
        BuyOffering,
        Claim
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title SolvV2BondBuyerPositionDataDecoder Contract
/// @author Enzyme Council <[email protected]>
/// @notice Abstract contract containing data decodings for SolvV2BondBuyerPosition payloads
abstract contract SolvV2BondBuyerPositionDataDecoder {
    /// @dev Helper to decode args used during the BuyOffering action
    function __decodeBuyOfferingActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (uint24 offeringId_, uint128 units_)
    {
        return abi.decode(_actionArgs, (uint24, uint128));
    }

    /// @dev Helper to decode args used during the Claim action
    function __decodeClaimActionArgs(bytes memory _actionArgs)
        internal
        pure
        returns (
            address voucher_,
            uint32 tokenId_,
            uint256 units_
        )
    {
        return abi.decode(_actionArgs, (address, uint32, uint256));
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../../../interfaces/ISolvV2BondPool.sol";
import "../../../../interfaces/ISolvV2BondVoucher.sol";
import "../../../../interfaces/ISolvV2InitialConvertibleOfferingMarket.sol";
import "../IExternalPositionParser.sol";
import "./ISolvV2BondBuyerPosition.sol";
import "./SolvV2BondBuyerPositionDataDecoder.sol";

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @title SolvV2BondBuyerPositionParser
/// @author Enzyme Council <[email protected]>
/// @notice Parser for Solv Bond Buyer positions
contract SolvV2BondBuyerPositionParser is
    IExternalPositionParser,
    SolvV2BondBuyerPositionDataDecoder
{
    using SafeMath for uint256;

    ISolvV2InitialConvertibleOfferingMarket
        private immutable INITIAL_BOND_OFFERING_MARKET_CONTRACT;

    constructor(address _initialBondOfferingMarket) public {
        INITIAL_BOND_OFFERING_MARKET_CONTRACT = ISolvV2InitialConvertibleOfferingMarket(
            _initialBondOfferingMarket
        );
    }

    /// @notice Parses the assets to send and receive for the callOnExternalPosition
    /// @param _actionId The _actionId for the callOnExternalPosition
    /// @param _encodedActionArgs The encoded parameters for the callOnExternalPosition
    /// @return assetsToTransfer_ The assets to be transferred from the Vault
    /// @return amountsToTransfer_ The amounts to be transferred from the Vault
    /// @return assetsToReceive_ The assets to be received at the Vault
    function parseAssetsForAction(
        address,
        uint256 _actionId,
        bytes memory _encodedActionArgs
    )
        external
        override
        returns (
            address[] memory assetsToTransfer_,
            uint256[] memory amountsToTransfer_,
            address[] memory assetsToReceive_
        )
    {
        if (_actionId == uint256(ISolvV2BondBuyerPosition.Actions.BuyOffering)) {
            (uint24 offerId, uint128 units) = __decodeBuyOfferingActionArgs(_encodedActionArgs);

            ISolvV2InitialConvertibleOfferingMarket.Offering
                memory offering = INITIAL_BOND_OFFERING_MARKET_CONTRACT.offerings(offerId);

            uint256 voucherPrice = INITIAL_BOND_OFFERING_MARKET_CONTRACT.getPrice(offerId);

            ISolvV2InitialConvertibleOfferingMarket.Market
                memory market = INITIAL_BOND_OFFERING_MARKET_CONTRACT.markets(offering.voucher);
            uint256 amount = uint256(units).mul(voucherPrice).div(10**uint256(market.decimals));

            assetsToTransfer_ = new address[](1);
            assetsToTransfer_[0] = offering.currency;
            amountsToTransfer_ = new uint256[](1);
            amountsToTransfer_[0] = amount;
        } else if (_actionId == uint256(ISolvV2BondBuyerPosition.Actions.Claim)) {
            (address voucher, uint256 tokenId, ) = __decodeClaimActionArgs(_encodedActionArgs);

            ISolvV2BondVoucher voucherContract = ISolvV2BondVoucher(voucher);

            uint256 slotId = voucherContract.voucherSlotMapping(tokenId);
            ISolvV2BondPool.SlotDetail memory slotDetail = voucherContract.getSlotDetail(slotId);

            assetsToReceive_ = new address[](2);
            assetsToReceive_[0] = voucherContract.underlying();
            assetsToReceive_[1] = slotDetail.fundCurrency;
        }

        return (assetsToTransfer_, amountsToTransfer_, assetsToReceive_);
    }

    /// @notice Parse and validate input arguments to be used when initializing a newly-deployed ExternalPositionProxy
    /// @dev Empty for this external position type
    function parseInitArgs(address, bytes memory) external override returns (bytes memory) {}
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @title ISolvV2BondPool Interface
/// @author Enzyme Council <[email protected]>
/// @dev Source: https://github.com/solv-finance/solv-v2-ivo/blob/main/vouchers/bond-voucher/contracts/BondPool.sol
interface ISolvV2BondPool {
    enum CollateralType {
        ERC20,
        VESTING_VOUCHER
    }

    struct SlotDetail {
        address issuer;
        address fundCurrency;
        uint256 totalValue;
        uint128 lowestPrice;
        uint128 highestPrice;
        uint128 settlePrice;
        uint64 effectiveTime;
        uint64 maturity;
        CollateralType collateralType;
        bool isIssuerRefunded;
        bool isIssuerWithdrawn;
        bool isClaimed;
        bool isValid;
    }

    function getIssuerSlots(address _issuer) external view returns (uint256[] memory slots_);

    function getSettlePrice(uint256 _slot) external view returns (uint128 settlePrice_);

    function getSlotDetail(uint256 _slot) external view returns (SlotDetail memory slotDetail_);

    function getWithdrawableAmount(uint256 _slot)
        external
        view
        returns (uint256 withdrawTokenAmount_);

    function refund(uint256 _slot) external;

    function slotBalances(uint256 _slotId, address _currency)
        external
        view
        returns (uint256 balance_);

    function valueDecimals() external view returns (uint8 decimals_);

    function withdraw(uint256 _slot) external returns (uint256 withdrawTokenAmount_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ISolvV2BondPool.sol";

/// @title ISolvV2BondVoucher Interface
/// @author Enzyme Council <[email protected]>
/// @dev Source: https://github.com/solv-finance/solv-v2-ivo/blob/main/vouchers/bond-voucher/contracts/BondVoucher.sol
interface ISolvV2BondVoucher {
    function approve(address _to, uint256 _tokenId) external;

    function bondPool() external view returns (address bondPool_);

    function claimTo(
        uint256 _tokenId,
        address _to,
        uint256 _claimUnits
    ) external;

    function getSlot(
        address _issuer,
        address _fundCurrency,
        uint128 _lowestPrice,
        uint128 _highestPrice,
        uint64 _effectiveTime,
        uint64 _maturity
    ) external view returns (uint256 slot_);

    function getSlotDetail(uint256 _slot)
        external
        view
        returns (ISolvV2BondPool.SlotDetail memory slotDetail_);

    function nextTokenId() external view returns (uint32 nextTokenId_);

    function ownerOf(uint256 _tokenId) external view returns (address owner_);

    function slotOf(uint256 _tokenId) external view returns (uint256 slotId_);

    function underlying() external view returns (address underlying_);

    function unitsInToken(uint256 tokenId_) external view returns (uint256 units_);

    function voucherSlotMapping(uint256 _tokenId) external returns (uint256 slotId_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @title ISolvV2InitialConvertibleOfferingMarket Interface
/// @author Enzyme Council <[email protected]>
/// @dev Source: https://github.com/solv-finance/solv-v2-ivo/blob/main/markets/convertible-offering-market/contracts/InitialConvertibleOfferingMarket.sol
interface ISolvV2InitialConvertibleOfferingMarket {
    enum VoucherType {
        STANDARD_VESTING,
        FLEXIBLE_DATE_VESTING,
        BOUNDING
    }

    struct Market {
        VoucherType voucherType;
        address voucherPool;
        address asset;
        uint8 decimals;
        uint16 feeRate;
        bool onlyManangerOffer;
        bool isValid;
    }

    /**
     * @param lowestPrice Lower price bound of the voucher (8 decimals)
     * @param highestPrice Upper price bound of the voucher (8 decimals)
     * @param tokenInAmount Amount of underlying tokens sent as collateral for minting (determined the amount of tokens )
     * @param effectiveTime Effective timestamp. Refers to when the bond takes effect (like startTime)
     * @param maturity Maturity timestamp of the voucher
     */
    struct MintParameter {
        uint128 lowestPrice;
        uint128 highestPrice;
        uint128 tokenInAmount;
        uint64 effectiveTime;
        uint64 maturity;
    }

    enum PriceType {
        FIXED,
        DECLIINING_BY_TIME
    }

    struct Offering {
        uint24 offeringId;
        uint32 startTime;
        uint32 endTime;
        PriceType priceType;
        uint128 totalUnits;
        uint128 units;
        uint128 min;
        uint128 max;
        address voucher;
        address currency;
        address issuer;
        bool useAllowList;
        bool isValid;
    }

    function buy(uint24 _offeringId, uint128 _units)
        external
        payable
        returns (uint256 amount_, uint128 fee_);

    function getPrice(uint24 _offeringId) external view returns (uint256 price_);

    function markets(address _voucher) external view returns (Market memory market_);

    function mintParameters(uint24 _offeringId)
        external
        view
        returns (MintParameter memory mintParameter_);

    function offer(
        address _voucher,
        address _currency,
        uint128 _min,
        uint128 _max,
        uint32 _startTime,
        uint32 _endTime,
        bool _useAllowList,
        PriceType _priceType,
        bytes calldata _priceData,
        MintParameter calldata _mintParameter
    ) external returns (uint24 offeringId_);

    function offerings(uint24 _offerId) external view returns (Offering memory offering_);

    function remove(uint24 _offeringId) external;
}