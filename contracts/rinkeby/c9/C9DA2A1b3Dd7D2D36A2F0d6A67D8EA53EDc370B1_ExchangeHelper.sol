// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;
pragma abicoder v2;

import { Ownable } from '../../Ownable.sol';
import { ExchangeAutoProxy } from '../ExchangeAutoProxy.sol';

import { LibBps } from '../../libraries/LibBps.sol';
import { LibExchange } from '../../libraries/LibExchange.sol';
import { LibAssetTypes } from '../../libraries/LibAssetTypes.sol';
import { LibOrder } from '../../libraries/LibOrder.sol';
import { LibOrderTypes } from '../../libraries/LibOrderTypes.sol';
import { LibOrderData } from '../../libraries/LibOrderData.sol';
import { LibOrderDataV1Types } from '../../libraries/LibOrderDataV1Types.sol';
import { LibFill } from '../../libraries/LibFill.sol';
import { LibFillTypes } from '../../libraries/LibFillTypes.sol';
import { LibPartTypes } from '../../libraries/LibPartTypes.sol';
import { LibFeeSide } from '../../libraries/LibFeeSide.sol';
import { LibFeeSideTypes } from '../../libraries/LibFeeSideTypes.sol';

import { IExchangeHelper } from './IExchangeHelper.sol';
import { IExchangeHelperGovernedProxy } from '../../interfaces/IExchangeHelperGovernedProxy.sol';
import { IGovernedContract } from '../../interfaces/IGovernedContract.sol';

contract ExchangeHelper is Ownable, ExchangeAutoProxy, IExchangeHelper {
    // ExchangeHelperGovernedProxy should be deployed first and its address passed to this constructor
    constructor(
        address _proxy,
        address _owner // Owner of the implementation smart contract
    ) Ownable(_owner) ExchangeAutoProxy(_proxy, address(this)) {}

    // Governance functions
    //
    // This function allows to set sporkProxy address after deployment in order to enable upgrades
    function setSporkProxy(address payable _sporkProxy) public onlyOwner {
        IExchangeHelperGovernedProxy(proxy).setSporkProxy(_sporkProxy);
    }

    // This function is called in order to upgrade to a new Exchange implementation
    function destroy(IGovernedContract _newImpl) external requireProxy {
        // Self destruct
        _destroy(_newImpl);
    }

    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function migrate(IGovernedContract _oldImpl) external requireProxy {
        _migrate(_oldImpl);
    }

    // LibBps
    function bps(uint256 value, uint16 bpsValue) external pure override returns (uint256) {
        return LibBps.bps(value, bpsValue);
    }

    // LibFill
    function fillOrder(
        LibOrderTypes.Order calldata leftOrder,
        LibOrderTypes.Order calldata rightOrder,
        uint256 leftOrderTakeAssetFill,
        uint256 rightOrderTakeAssetFill
    ) external pure override returns (LibFillTypes.FillResult memory) {
        return
            LibFill.fillOrder(
                leftOrder,
                rightOrder,
                leftOrderTakeAssetFill,
                rightOrderTakeAssetFill
            );
    }

    // LibOrder
    function hashKey(LibOrderTypes.Order calldata order) external pure override returns (bytes32) {
        return LibOrder.hashKey(order);
    }

    function validate(LibOrderTypes.Order calldata order) external view override {
        LibOrder.validate(order);
    }

    // LibExchange
    function validateOrder(
        LibOrderTypes.Order calldata order,
        bytes calldata signature,
        address callerAddress,
        address veriyingContractProxy
    ) external view override {
        LibExchange.validateOrder(order, signature, callerAddress, veriyingContractProxy);
    }

    function validateMatch(
        LibOrderTypes.Order calldata orderLeft,
        LibOrderTypes.Order calldata orderRight,
        uint256 matchLeftBeforeBlock,
        uint256 matchRightBeforeBlock,
        bytes memory orderBookSignatureLeft,
        bytes memory orderBookSignatureRight,
        address verifyingContractProxy,
        address orderBook
    ) external view override returns (bytes32 leftOrderKeyHash, bytes32 rightOrderKeyHash) {
        (leftOrderKeyHash, rightOrderKeyHash) = LibExchange.validateMatch(
            orderLeft,
            orderRight,
            matchLeftBeforeBlock,
            matchRightBeforeBlock,
            orderBookSignatureLeft,
            orderBookSignatureRight,
            verifyingContractProxy,
            orderBook
        );
    }

    function matchAssets(
        LibOrderTypes.Order calldata orderLeft,
        LibOrderTypes.Order calldata orderRight
    )
        external
        pure
        override
        returns (
            LibAssetTypes.AssetType memory, // Asset type expected by order maker
            LibAssetTypes.AssetType memory // Asset type expected by order taker
        )
    {
        return LibExchange.matchAssets(orderLeft, orderRight);
    }

    function calculateTotalAmount(uint256 amount, LibPartTypes.Part[] calldata orderOriginFees)
        external
        pure
        override
        returns (uint256)
    {
        return LibExchange.calculateTotalAmount(amount, orderOriginFees);
    }

    function subFeeInBps(
        uint256 rest,
        uint256 total,
        uint16 feeInBps
    ) external pure override returns (uint256, uint256) {
        return LibExchange.subFeeInBps(rest, total, feeInBps);
    }

    function getRoyaltiesByAssetType(
        LibAssetTypes.AssetType calldata assetType,
        address royaltiesRegistry
    ) external view override returns (LibPartTypes.Part[] memory) {
        return LibExchange.getRoyaltiesByAssetType(assetType, royaltiesRegistry);
    }

    // LibOrderData
    function parse(LibOrderTypes.Order memory order)
        external
        pure
        override
        returns (LibOrderDataV1Types.DataV1 memory)
    {
        return LibOrderData.parse(order);
    }

    // LibFeeSide
    function getFeeSide(
        bytes4 makerAssetClass, // Asset class expected to be received by maker
        bytes4 takerAssetClass // Asset class expected to be received by taker
    ) external pure override returns (LibFeeSideTypes.FeeSide) {
        return LibFeeSide.getFeeSide(makerAssetClass, takerAssetClass);
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;
pragma abicoder v2;

import { LibPartTypes } from '../libraries/LibPartTypes.sol';

interface IRoyaltiesRegistry {
    // Royalties setters
    function setProviderByToken(address token, address provider) external;

    function setRoyaltiesByToken(address token, LibPartTypes.Part[] memory royalties) external;

    function setOwnerRoyaltiesByTokenAndTokenId(
        address token,
        uint256 tokenId,
        LibPartTypes.Part[] memory royalties
    ) external;

    function setCreatorRoyaltiesByTokenAndTokenId(
        address token,
        uint256 tokenId,
        LibPartTypes.Part[] memory royalties
    ) external;

    // Provider getter
    function getProviderByToken(address token) external view returns (address);

    // Royalties getter
    function getRoyalties(address token, uint256 tokenId)
        external
        view
        returns (LibPartTypes.Part[] memory);
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

library LibSignature {
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
        // Check the signature length
        if (signature.length != 65) {
            revert('LibSignature: invalid ECDSA signature length');
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            'LibSignature: invalid ECDSA signature `s` value'
        );

        // If the signature is valid (and not malleable), return the signer address
        // v > 30 is a special case, we need to adjust hash with '\x19Ethereum Signed Message:\n32'
        // and v = v - 4
        address signer;
        if (v > 30) {
            require(v - 4 == 27 || v - 4 == 28, 'LibSignature: invalid ECDSA signature `v` value');
            signer = ecrecover(toEthSignedMessageHash(hash), v - 4, r, s);
        } else {
            require(v == 27 || v == 28, 'LibSignature: invalid ECDSA signature `v` value');
            signer = ecrecover(hash, v, r, s);
        }

        require(signer != address(0), 'LibSignature: invalid ECDSA signature');

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash));
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

library LibPartTypes {
    struct Part {
        address payable account;
        // `value` is used to capture basepoints (bps) for royalties, origin fees, and payouts
        // `value` can only range from 0 to 10,000, therefore uint16 with a range of 0 to 65,535 suffices
        uint16 value;
    }

    // use for external providers that implement values based on uint96 (e.g. Rarible)
    struct Part96 {
        address payable account;
        uint96 value;
    }

    // use for external providers following the LooksRare pattern
    struct FeeInfo {
        address setter;
        address receiver;
        uint256 fee;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

import { LibAssetTypes } from './LibAssetTypes.sol';

library LibOrderTypes {
    struct Order {
        address maker;
        LibAssetTypes.Asset makeAsset;
        address taker;
        LibAssetTypes.Asset takeAsset;
        uint256 salt;
        uint256 start;
        uint256 end;
        bytes4 dataType;
        bytes data;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;
pragma abicoder v2;

import { LibPartTypes } from './LibPartTypes.sol';

library LibOrderDataV1Types {
    bytes4 public constant V1 = bytes4(keccak256('V1'));

    struct DataV1 {
        LibPartTypes.Part[] payouts;
        LibPartTypes.Part[] originFees;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;
pragma abicoder v2;

import { LibOrderDataV1Types } from './LibOrderDataV1Types.sol';

library LibOrderDataV1 {
    bytes4 public constant V1 = bytes4(keccak256('V1'));

    function decodeOrderDataV1(bytes memory data)
        internal
        pure
        returns (LibOrderDataV1Types.DataV1 memory orderData)
    {
        orderData = abi.decode(data, (LibOrderDataV1Types.DataV1));
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

import { LibPartTypes } from './LibPartTypes.sol';
import { LibOrderTypes } from './LibOrderTypes.sol';
import { LibOrderDataV1 } from './LibOrderDataV1.sol';
import { LibOrderDataV1Types } from './LibOrderDataV1Types.sol';

library LibOrderData {
    function parse(LibOrderTypes.Order memory order)
        internal
        pure
        returns (LibOrderDataV1Types.DataV1 memory dataOrder)
    {
        if (order.dataType == LibOrderDataV1.V1) {
            dataOrder = LibOrderDataV1.decodeOrderDataV1(order.data);
            if (dataOrder.payouts.length == 0) {
                dataOrder = payoutSet(order.maker, dataOrder);
            }
        } else if (
            order.dataType == 0xffffffff // Empty order data
        ) {
            dataOrder = payoutSet(order.maker, dataOrder);
        } else {
            revert('LibOrderData: Unknown Order data type');
        }
    }

    function payoutSet(address orderAddress, LibOrderDataV1Types.DataV1 memory dataOrderOnePayoutIn)
        internal
        pure
        returns (LibOrderDataV1Types.DataV1 memory)
    {
        LibPartTypes.Part[] memory payout = new LibPartTypes.Part[](1);
        payout[0].account = payable(orderAddress);
        payout[0].value = 10000; // 100% of payout goes to payout[0].account
        dataOrderOnePayoutIn.payouts = payout;
        return dataOrderOnePayoutIn;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

import { LibOrderTypes } from './LibOrderTypes.sol';
import { LibMath } from './LibMath.sol';
import { LibAsset } from './LibAsset.sol';
import { LibAssetClasses } from './LibAssetClasses.sol';
import { SafeMath } from './SafeMath.sol';

library LibOrder {
    using SafeMath for uint256;

    bytes32 constant ORDER_TYPEHASH =
        keccak256(
            'Order(address maker,Asset makeAsset,address taker,Asset takeAsset,uint256 salt,uint256 start,uint256 end,bytes4 dataType,bytes data)Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)'
        );

    bytes32 constant MATCH_ALLOWANCE_TYPEHASH =
        keccak256('MatchAllowance(bytes32 orderKeyHash,uint256 matchBeforeBlock)');

    function calculateRemaining(LibOrderTypes.Order memory order, uint256 takeAssetFill)
        internal
        pure
        returns (uint256 makeValue, uint256 takeValue)
    {
        // ensure that the order was not previously cancelled (takeAssetFill set to UINT256_MAX)
        require(takeAssetFill < 2**256 - 1, 'LibOrder: Order was previously cancelled');
        // Calculate remaining takeAsset value as:
        // takeValue = takeAsset.value - fill
        takeValue = order.takeAsset.value.sub(takeAssetFill);
        // Calculate corresponding makeAsset value as:
        // makeValue = makeAsset.value * (takeValue / takeAsset.value)
        makeValue = LibMath.safeGetPartialAmountFloor(
            order.makeAsset.value,
            order.takeAsset.value,
            takeValue
        );
    }

    function hashKey(LibOrderTypes.Order memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    order.maker,
                    LibAsset.hash(order.makeAsset.assetType),
                    LibAsset.hash(order.takeAsset.assetType),
                    order.salt
                )
            );
    }

    function hash(LibOrderTypes.Order memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.maker,
                    LibAsset.hash(order.makeAsset),
                    order.taker,
                    LibAsset.hash(order.takeAsset),
                    order.salt,
                    order.start,
                    order.end,
                    order.dataType,
                    keccak256(order.data)
                )
            );
    }

    function hash(bytes32 orderKeyHash, uint256 matchBeforeBlock) internal pure returns (bytes32) {
        return keccak256(abi.encode(MATCH_ALLOWANCE_TYPEHASH, orderKeyHash, matchBeforeBlock));
    }

    function validate(LibOrderTypes.Order memory order) internal view {
        // Check order start and end blocks
        require(
            order.start == 0 || order.start < block.number,
            'LibOrder: Order start block validation failed'
        );
        require(
            order.end == 0 || order.end > block.number,
            'LibOrder: Order end block validation failed'
        );
        // Check order assets types
        // We only allow trading of ETH and some select ERC20 tokens for ERC721 and ERC1155 assets
        if (
            order.makeAsset.assetType.assetClass == LibAssetClasses.ETH_ASSET_CLASS ||
            order.makeAsset.assetType.assetClass == LibAssetClasses.WETH_ASSET_CLASS ||
            order.makeAsset.assetType.assetClass == LibAssetClasses.ERC20_ASSET_CLASS
        ) {
            require(
                order.takeAsset.assetType.assetClass == LibAssetClasses.ERC721_ASSET_CLASS ||
                    order.takeAsset.assetType.assetClass == LibAssetClasses.ERC1155_ASSET_CLASS,
                'LibOrder: Asset types mismatch - makeAsset is fungible, therefore takeAsset must be non-fungible'
            );
        }
        if (
            order.takeAsset.assetType.assetClass == LibAssetClasses.ETH_ASSET_CLASS ||
            order.takeAsset.assetType.assetClass == LibAssetClasses.WETH_ASSET_CLASS ||
            order.takeAsset.assetType.assetClass == LibAssetClasses.ERC20_ASSET_CLASS
        ) {
            require(
                order.makeAsset.assetType.assetClass == LibAssetClasses.ERC721_ASSET_CLASS ||
                    order.makeAsset.assetType.assetClass == LibAssetClasses.ERC1155_ASSET_CLASS,
                'LibOrder: Asset types mismatch - takeAsset is fungible, therefore makeAsset must be non-fungible'
            );
        }
        // We disallow trading of ERC721(or ERC1155) for ERC721(or ERC1155)
        if (
            order.makeAsset.assetType.assetClass == LibAssetClasses.ERC721_ASSET_CLASS ||
            order.makeAsset.assetType.assetClass == LibAssetClasses.ERC1155_ASSET_CLASS
        ) {
            require(
                order.takeAsset.assetType.assetClass != LibAssetClasses.ERC721_ASSET_CLASS &&
                    order.takeAsset.assetType.assetClass != LibAssetClasses.ERC1155_ASSET_CLASS,
                'LibOrder: Asset types mismatch - makeAsset is non-fungible, therefore takeAsset must be fungible'
            );
        }
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

import { SafeMath } from './SafeMath.sol';

library LibMath {
    using SafeMath for uint256;

    // @dev Calculates partial value given a numerator and denominator rounded down.

    function safeGetPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (uint256 partialAmount) {
        if (isRoundingErrorFloor(numerator, denominator, target)) {
            revert('LibMath: rounding error'); // Reverts if rounding error is >= 0.1%
        }
        partialAmount = numerator.mul(target).div(denominator);
    }

    /// @dev Checks if rounding error >= 0.1% when rounding down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return isError Rounding error is present.
    function isRoundingErrorFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (bool isError) {
        if (denominator == 0) {
            revert('LibMath: division by zero');
        }

        // The absolute rounding error is the difference between the rounded
        // value and the ideal value. The relative rounding error is the
        // absolute rounding error divided by the absolute value of the
        // ideal value. This is undefined when the ideal value is zero.
        //
        // The ideal value is `numerator * target / denominator`.
        // Let's call `numerator * target % denominator` the remainder.
        // The absolute error is `remainder / denominator`.
        //
        // When the ideal value is zero, we require the absolute error to
        // be zero. Fortunately, this is always the case. The ideal value is
        // zero iff `numerator == 0` and/or `target == 0`. In this case the
        // remainder and absolute error are also zero.
        if (target == 0 || numerator == 0) {
            return false;
        }

        // Otherwise, we want the relative rounding error to be strictly
        // less than 0.1%.
        // The relative error is `remainder / (numerator * target)`.
        // We want the relative error less than 1 / 1000:
        //        remainder / (numerator * target)  <  1 / 1000
        // or equivalently:
        //        1000 * remainder  <  numerator * target
        // so we have a rounding error iff:
        //        1000 * remainder  >=  numerator * target
        uint256 remainder = mulmod(target, numerator, denominator);
        isError = remainder.mul(1000) >= numerator.mul(target);
    }

    function safeGetPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (uint256 partialAmount) {
        if (isRoundingErrorCeil(numerator, denominator, target)) {
            revert('LibMath: rounding error');
        }
        partialAmount = numerator.mul(target).add(denominator.sub(1)).div(denominator);
    }

    /// @dev Checks if rounding error >= 0.1% when rounding up.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return isError Rounding error is present.
    function isRoundingErrorCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (bool isError) {
        if (denominator == 0) {
            revert('LibMath: division by zero');
        }

        // See the comments in `isRoundingError`.
        if (target == 0 || numerator == 0) {
            // When either is zero, the ideal value and rounded value are zero
            // and there is no rounding error. (Although the relative error
            // is undefined.)
            return false;
        }
        // Compute remainder as before
        uint256 remainder = mulmod(target, numerator, denominator);
        remainder = denominator.sub(remainder) % denominator;
        isError = remainder.mul(1000) >= numerator.mul(target);
        return isError;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

library LibFillTypes {
    struct FillResult {
        uint256 rightOrderTakeValue;
        uint256 leftOrderTakeValue;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

import { LibOrder } from './LibOrder.sol';
import { LibOrderTypes } from './LibOrderTypes.sol';
import { LibFillTypes } from './LibFillTypes.sol';
import { LibMath } from './LibMath.sol';
import { SafeMath } from './SafeMath.sol';

library LibFill {
    using SafeMath for uint256;

    function fillOrder(
        LibOrderTypes.Order memory leftOrder,
        LibOrderTypes.Order memory rightOrder,
        uint256 leftOrderTakeAssetFill,
        uint256 rightOrderTakeAssetFill
    ) internal pure returns (LibFillTypes.FillResult memory) {
        // Calculate orders' remaining make and take values based on current fill
        (uint256 leftMakeValue, uint256 leftTakeValue) = LibOrder.calculateRemaining(
            leftOrder,
            leftOrderTakeAssetFill
        );
        (uint256 rightMakeValue, uint256 rightTakeValue) = LibOrder.calculateRemaining(
            rightOrder,
            rightOrderTakeAssetFill
        );

        //We have 3 cases here:
        if (rightTakeValue > leftMakeValue) {
            // 1st case: left order will end up fully filled
            return
                fillLeft(
                    leftMakeValue,
                    leftTakeValue,
                    rightOrder.makeAsset.value,
                    rightOrder.takeAsset.value
                );
        }
        // 2nd case: right order will end up fully filled
        // 3rd case: both orders will end up fully filled
        return
            fillRight(
                leftOrder.makeAsset.value,
                leftOrder.takeAsset.value,
                rightMakeValue,
                rightTakeValue
            );
    }

    function fillRight(
        uint256 leftMakeValue,
        uint256 leftTakeValue,
        uint256 rightMakeValue,
        uint256 rightTakeValue
    ) internal pure returns (LibFillTypes.FillResult memory result) {
        // In this case we have rightTakeValue <= leftMakeValue
        // We know that right order will be fully filled
        // We calculate the corresponding left order's take value (amount that taker will receive):
        //
        // leftTake = rightTakeValue * (leftTakeValue / leftMakeValue)
        //
        uint256 leftTake = LibMath.safeGetPartialAmountFloor(
            rightTakeValue,
            leftMakeValue,
            leftTakeValue
        );
        // And we make sure that left order's take value is not larger than right order's make value
        require(leftTake <= rightMakeValue, 'LibFill: fillRight unable to fill');
        // Return fill result
        //
        // rightTake is returned unchanged (maker will receive the take amount specified in maker order)
        //
        // leftTake is less than initially specified by taker, and less than, or equal to rightMake (maker will pay no
        // more than the make amount specified in maker order)
        //
        // WARNING: with this logic it is possible for taker to receive less than expected if the initial ratio
        // leftTakeValue/leftMakeValue is less than the ratio rightMakeValue/rightTakeValue !
        //
        return LibFillTypes.FillResult(rightTakeValue, leftTake);
    }

    function fillLeft(
        uint256 leftMakeValue,
        uint256 leftTakeValue,
        uint256 rightMakeValue,
        uint256 rightTakeValue
    ) internal pure returns (LibFillTypes.FillResult memory result) {
        // In this case we have rightTakeValue > leftMakeValue
        // We know that left order will be fully filled
        // We calculate the corresponding right order's take value (amount that maker will receive):
        //
        // rightTake = leftTakeValue * (rightTakeValue / rightMakeValue)
        //
        uint256 rightTake = LibMath.safeGetPartialAmountFloor(
            leftTakeValue,
            rightMakeValue,
            rightTakeValue
        );
        // And wake sure that right order's take value is not larger than left order's make value
        require(rightTake <= leftMakeValue, 'LibFill: fillLeft unable to fill');
        // Return fill result
        //
        // leftTake is returned unchanged (taker will receive the take amount specified in taker order)
        //
        // rightTake is deducted from leftTake and the initial ratio (rightTakeValue / rightMakeValue) specified by
        // maker, and cannot be larger than leftMake
        //
        return LibFillTypes.FillResult(rightTake, leftTakeValue);
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

library LibFeeSideTypes {
    enum FeeSide {
        NONE,
        MAKE,
        TAKE
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

import { LibFeeSideTypes } from './LibFeeSideTypes.sol';
import { LibAssetClasses } from './LibAssetClasses.sol';

library LibFeeSide {
    function getFeeSide(
        bytes4 makerAssetClass, // Asset class expected to be received by maker
        bytes4 takerAssetClass // Asset class expected to be received by taker
    ) internal pure returns (LibFeeSideTypes.FeeSide) {
        // Determine fee side
        // The fee side corresponds to which side of the trade (order maker or taker) is paying the trading fee
        //
        // The fee asset is the asset in which fees and royalties are paid. It is determined in the following order:
        // 1) ETH
        // 2) WETH
        // 3) ERC20 asset
        // 4) ERC1155 asset
        // 5) none
        if (makerAssetClass == LibAssetClasses.ETH_ASSET_CLASS) {
            return LibFeeSideTypes.FeeSide.TAKE;
        }
        if (takerAssetClass == LibAssetClasses.ETH_ASSET_CLASS) {
            return LibFeeSideTypes.FeeSide.MAKE;
        }
        if (
            makerAssetClass == LibAssetClasses.WETH_ASSET_CLASS ||
            makerAssetClass == LibAssetClasses.PROXY_WETH_ASSET_CLASS
        ) {
            return LibFeeSideTypes.FeeSide.TAKE;
        }
        if (
            takerAssetClass == LibAssetClasses.WETH_ASSET_CLASS ||
            takerAssetClass == LibAssetClasses.PROXY_WETH_ASSET_CLASS
        ) {
            return LibFeeSideTypes.FeeSide.MAKE;
        }
        if (makerAssetClass == LibAssetClasses.ERC20_ASSET_CLASS) {
            return LibFeeSideTypes.FeeSide.TAKE;
        }
        if (takerAssetClass == LibAssetClasses.ERC20_ASSET_CLASS) {
            return LibFeeSideTypes.FeeSide.MAKE;
        }
        if (makerAssetClass == LibAssetClasses.ERC1155_ASSET_CLASS) {
            return LibFeeSideTypes.FeeSide.TAKE;
        }
        if (takerAssetClass == LibAssetClasses.ERC1155_ASSET_CLASS) {
            return LibFeeSideTypes.FeeSide.MAKE;
        }
        return LibFeeSideTypes.FeeSide.NONE;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;
pragma abicoder v2;

import { SafeMath } from './SafeMath.sol';
import { LibEIP712 } from './LibEIP712.sol';
import { LibAddress } from './LibAddress.sol';
import { LibAsset } from './LibAsset.sol';
import { LibAssetTypes } from './LibAssetTypes.sol';
import { LibAssetClasses } from './LibAssetClasses.sol';
import { LibOrder } from './LibOrder.sol';
import { LibOrderTypes } from './LibOrderTypes.sol';
import { LibPartTypes } from './LibPartTypes.sol';
import { LibBps } from './LibBps.sol';
import { LibSignature } from './LibSignature.sol';

import { IRoyaltiesRegistry } from '../royalties-registry/IRoyaltiesRegistry.sol';
import { IERC1271 } from '../interfaces/IERC1271.sol';

library LibExchange {
    using SafeMath for uint256;

    // See: https://eips.ethereum.org/EIPS/eip-1271
    bytes4 internal constant MAGICVALUE = 0x1626ba7e; // bytes4(keccak256("isValidSignature(bytes32,bytes)")

    // Assets match functions
    function simpleMatch(
        LibAssetTypes.AssetType memory _takeAssetType,
        LibAssetTypes.AssetType memory _makeAssetType
    ) private pure returns (LibAssetTypes.AssetType memory) {
        bytes32 leftHash = keccak256(_takeAssetType.data);
        bytes32 rightHash = keccak256(_makeAssetType.data);
        if (leftHash == rightHash) {
            return _takeAssetType;
        }
        return LibAssetTypes.AssetType(0, '');
    }

    function matchAssets(
        LibAssetTypes.AssetType memory _takeAssetType, // Asset type expected by one side
        LibAssetTypes.AssetType memory _makeAssetType // Asset type sent by the other side
    ) private pure returns (LibAssetTypes.AssetType memory) {
        bytes4 classTake = _takeAssetType.assetClass;
        bytes4 classMake = _makeAssetType.assetClass;
        // Match ETH and WETH assets
        if (
            classTake == LibAssetClasses.ETH_ASSET_CLASS ||
            classTake == LibAssetClasses.WETH_ASSET_CLASS
        ) {
            if (
                classMake == LibAssetClasses.ETH_ASSET_CLASS ||
                classMake == LibAssetClasses.WETH_ASSET_CLASS
            ) {
                return _takeAssetType;
            }
            return LibAssetTypes.AssetType(0, '');
        }
        // Match ERC20 asset
        if (classTake == LibAssetClasses.ERC20_ASSET_CLASS) {
            if (classMake == LibAssetClasses.ERC20_ASSET_CLASS) {
                return simpleMatch(_takeAssetType, _makeAssetType);
            }
            return LibAssetTypes.AssetType(0, '');
        }
        // Match ERC721 asset
        if (classTake == LibAssetClasses.ERC721_ASSET_CLASS) {
            if (classMake == LibAssetClasses.ERC721_ASSET_CLASS) {
                return simpleMatch(_takeAssetType, _makeAssetType);
            }
            return LibAssetTypes.AssetType(0, '');
        }
        // Match ERC1155 asset
        if (classTake == LibAssetClasses.ERC1155_ASSET_CLASS) {
            if (classMake == LibAssetClasses.ERC1155_ASSET_CLASS) {
                return simpleMatch(_takeAssetType, _makeAssetType);
            }
            return LibAssetTypes.AssetType(0, '');
        }

        revert('LibExchange: asset class not supported');
    }

    function matchAssets(
        LibOrderTypes.Order memory orderLeft,
        LibOrderTypes.Order memory orderRight
    )
        internal
        pure
        returns (
            LibAssetTypes.AssetType memory makerAssetType, // Asset type expected by order maker
            LibAssetTypes.AssetType memory takerAssetType // Asset type expected by order taker
        )
    {
        makerAssetType = matchAssets(orderRight.takeAsset.assetType, orderLeft.makeAsset.assetType);
        require(makerAssetType.assetClass != 0, 'LibExchange: assets do not match');
        takerAssetType = matchAssets(orderLeft.takeAsset.assetType, orderRight.makeAsset.assetType);
        require(takerAssetType.assetClass != 0, 'LibExchange: assets do not match');
    }

    function validateOrder(
        LibOrderTypes.Order memory _order,
        bytes memory _signature,
        address _callerAddress,
        address _verifyingContractProxy
    ) internal view {
        if (_order.salt == 0) {
            // When order is submitted by order.maker, order.salt can be 0
            if (_order.maker != address(0)) {
                // We check that order has been submitted by order.maker
                require(_callerAddress == _order.maker, 'LibExchange: order maker is not caller');
            } else {
                // If order.maker is not set, we set it to callerAddress
                _order.maker = _callerAddress;
            }
        } else {
            // When order is submitted by a third party account, order.salt cannot be 0 and we check that the signature
            //  has been created by order.maker, or by a smart-contract implementing the EIP-1271 standard
            if (_callerAddress != _order.maker) {
                // Calculate order EIP712 hashStruct
                bytes32 hashStruct = LibOrder.hash(_order);
                // Verify order EIP712 hashStruct signature
                if (
                    LibSignature.recover(
                        LibEIP712.hashEIP712Message(hashStruct, _verifyingContractProxy),
                        _signature
                    ) != _order.maker
                ) {
                    if (LibAddress.isContract(_order.maker)) {
                        // If order.maker is a smart-contract, it must implement the ERC1271 standard to validate the
                        // signature (see: https://eips.ethereum.org/EIPS/eip-1271)
                        require(
                            IERC1271(_order.maker).isValidSignature(
                                LibEIP712.hashEIP712Message(hashStruct, _verifyingContractProxy),
                                _signature
                            ) == MAGICVALUE,
                            'LibExchange: EIP-1271 contract order signature verification error'
                        );
                    } else {
                        // If order.maker is not a smart-contract, it must be the signer
                        revert('LibExchange: EIP-712 wallet order signature verification error');
                    }
                }
            }
        }
    }

    function validateMatch(
        LibOrderTypes.Order calldata _orderLeft,
        LibOrderTypes.Order calldata _orderRight,
        uint256 _matchLeftBeforeBlock,
        uint256 _matchRightBeforeBlock,
        bytes memory _orderBookSignatureLeft,
        bytes memory _orderBookSignatureRight,
        address _verifyingContractProxy,
        address _orderBook
    ) internal view returns (bytes32 _leftOrderKeyHash, bytes32 _rightOrderKeyHash) {
        // Calculate left order hashKey
        _leftOrderKeyHash = LibOrder.hashKey(_orderLeft);
        // Verify order-book's matchAllowance for orders submitted by third parties only
        if (_orderLeft.salt > 0) {
            // Make sure current block is below matchLeftBeforeBlock
            require(
                _matchLeftBeforeBlock > block.number,
                'LibExchange: matchLeftBeforeBlock has already been mined'
            );
            // OrderBook must be the signer
            if (
                recoverMatchAllowanceSigner(
                    _leftOrderKeyHash,
                    _matchLeftBeforeBlock,
                    _orderBookSignatureLeft,
                    _verifyingContractProxy
                ) != _orderBook
            ) {
                revert('LibExchange: EIP-712 left matchAllowance signature verification error');
            }
        }
        // Calculate right order hashKey
        _rightOrderKeyHash = LibOrder.hashKey(_orderRight);
        // Verify order-book's matchAllowance for orders submitted by third parties only
        if (_orderRight.salt > 0) {
            // Make sure current block is below matchRightBeforeBlock
            require(
                _matchRightBeforeBlock > block.number,
                'LibExchange: matchRightBeforeBlock has already been mined'
            );
            // OrderBook must be the signer
            if (
                recoverMatchAllowanceSigner(
                    _rightOrderKeyHash,
                    _matchRightBeforeBlock,
                    _orderBookSignatureRight,
                    _verifyingContractProxy
                ) != _orderBook
            ) {
                revert('LibExchange: EIP-712 right matchAllowance signature verification error');
            }
        }
    }

    function recoverMatchAllowanceSigner(
        bytes32 _orderKeyHash,
        uint256 _matchBeforeBlock,
        bytes memory _orderBookSignature,
        address _verifyingContractProxy
    ) internal pure returns (address _recovered) {
        // Calculate matchAllowance EIP712 hashStruct
        bytes32 hashStruct = LibOrder.hash(_orderKeyHash, _matchBeforeBlock);
        // Verify matchAllowance EIP712 hashStruct signature
        _recovered = LibSignature.recover(
            LibEIP712.hashEIP712Message(hashStruct, _verifyingContractProxy),
            _orderBookSignature
        );
    }

    // Helper functions
    function subFee(uint256 _value, uint256 _fee)
        internal
        pure
        returns (uint256 _newValue, uint256 _realFee)
    {
        if (_value > _fee) {
            _newValue = _value.sub(_fee);
            _realFee = _fee;
        } else {
            _newValue = 0;
            _realFee = _value;
        }
    }

    // Subtract, from _rest amount, a fee expressed in bps of a _total amount
    function subFeeInBps(
        uint256 _rest,
        uint256 _total,
        uint16 _feeInBps
    ) internal pure returns (uint256 _newRest, uint256 _realFee) {
        uint256 _fee = LibBps.bps(_total, _feeInBps); // Calculate fee
        return subFee(_rest, _fee); // Subtract fee from _rest and return new rest and real fee
    }

    function calculateTotalAmount(uint256 _amount, LibPartTypes.Part[] memory _orderOriginFees)
        internal
        pure
        returns (uint256 _total)
    {
        _total = _amount;
        // Add origin fees  to amount
        for (uint256 i = 0; i < _orderOriginFees.length; i++) {
            _total = _total.add(LibBps.bps(_amount, _orderOriginFees[i].value));
        }
    }

    function getRoyaltiesByAssetType(
        LibAssetTypes.AssetType memory _assetType,
        address _royaltiesRegistry
    ) internal view returns (LibPartTypes.Part[] memory) {
        if (
            _assetType.assetClass == LibAssetClasses.ERC1155_ASSET_CLASS ||
            _assetType.assetClass == LibAssetClasses.ERC721_ASSET_CLASS
        ) {
            (address token, uint256 tokenId) = abi.decode(_assetType.data, (address, uint256));
            return IRoyaltiesRegistry(_royaltiesRegistry).getRoyalties(token, tokenId);
        }
        LibPartTypes.Part[] memory empty;
        return empty;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

library LibEIP712 {
    // Calculates EIP712 encoding for a hash struct in this EIP712 Domain.
    // Note that we use the verifying contract's proxy address here instead of the verifying contract's address,
    // so that users signatures remain valid when we upgrade the Exchange contract
    function hashEIP712Message(bytes32 hashStruct, address veriyingContractProxy)
        internal
        pure
        returns (bytes32 result)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
                ),
                keccak256(bytes('Energi')),
                keccak256(bytes('1')),
                chainId,
                veriyingContractProxy
            )
        );

        result = keccak256(abi.encodePacked('\x19\x01', eip712DomainHash, hashStruct));
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

import { SafeMath } from './SafeMath.sol';

library LibBps {
    using SafeMath for uint256;

    function bps(uint256 value, uint16 bpsValue) internal pure returns (uint256) {
        return value.mul(bpsValue).div(10000);
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

library LibAssetTypes {
    struct AssetType {
        bytes4 assetClass;
        bytes data; // Token address (and id in the case of ERC721 and ERC1155)
    }

    struct Asset {
        AssetType assetType;
        uint256 value;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

library LibAssetClasses {
    // Asset classes
    bytes4 public constant ETH_ASSET_CLASS = bytes4(keccak256('ETH'));
    bytes4 public constant WETH_ASSET_CLASS = bytes4(keccak256('WETH'));
    bytes4 public constant PROXY_WETH_ASSET_CLASS = bytes4(keccak256('PROXY_WETH'));
    bytes4 public constant ERC20_ASSET_CLASS = bytes4(keccak256('ERC20'));
    bytes4 public constant ERC721_ASSET_CLASS = bytes4(keccak256('ERC721'));
    bytes4 public constant ERC1155_ASSET_CLASS = bytes4(keccak256('ERC1155'));
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

import { LibAssetTypes } from './LibAssetTypes.sol';

library LibAsset {
    bytes32 constant ASSET_TYPE_TYPEHASH = keccak256('AssetType(bytes4 assetClass,bytes data)');

    bytes32 constant ASSET_TYPEHASH =
        keccak256(
            'Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)'
        );

    function hash(LibAssetTypes.AssetType memory assetType) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(ASSET_TYPE_TYPEHASH, assetType.assetClass, keccak256(assetType.data))
            );
    }

    function hash(LibAssetTypes.Asset memory asset) internal pure returns (bytes32) {
        return keccak256(abi.encode(ASSET_TYPEHASH, hash(asset.assetType), asset.value));
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

/**
 * @dev Collection of functions related to the address type
 */
library LibAddress {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(address(this).balance >= amount, 'LibAddress: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }('');
        require(success, 'LibAddress: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
        return functionCall(target, data, 'LibAddress: low-level call failed');
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                'LibAddress: low-level call with value failed'
            );
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
        require(address(this).balance >= value, 'LibAddress: insufficient balance for call');
        require(isContract(target), 'LibAddress: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return functionStaticCall(target, data, 'LibAddress: low-level static call failed');
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
        require(isContract(target), 'LibAddress: static call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.7.6;

import { IProposal } from './IProposal.sol';
import { IGovernedContract } from './IGovernedContract.sol';

/**
 * Interface of UpgradeProposal
 */
interface IUpgradeProposal is IProposal {
    function impl() external view returns (IGovernedContract);
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.7.6;

interface IProposal {
    function parent() external view returns (address);

    function created_block() external view returns (uint256);

    function deadline() external view returns (uint256);

    function fee_payer() external view returns (address payable);

    function fee_amount() external view returns (uint256);

    function accepted_weight() external view returns (uint256);

    function rejected_weight() external view returns (uint256);

    function total_weight() external view returns (uint256);

    function quorum_weight() external view returns (uint256);

    function isFinished() external view returns (bool);

    function isAccepted() external view returns (bool);

    function withdraw() external;

    function destroy() external;

    function collect() external;

    function voteAccept() external;

    function voteReject() external;

    function setFee() external payable;

    function canVote(address owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.7.6;
//pragma experimental SMTChecker;

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

/**
 * Genesis version of IGovernedProxy interface.
 *
 * Base Consensus interface for upgradable contracts proxy.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */
interface IGovernedProxy {
    event UpgradeProposal(IGovernedContract indexed impl, IUpgradeProposal proposal);

    event Upgraded(IGovernedContract indexed impl, IUpgradeProposal proposal);

    function impl() external view returns (IGovernedContract);

    function initialize(address _impl) external;

    function proposeUpgrade(IGovernedContract _newImpl, uint256 _period)
        external
        payable
        returns (IUpgradeProposal);

    function upgrade(IUpgradeProposal _proposal) external;

    function upgradeProposalImpl(IUpgradeProposal _proposal)
        external
        view
        returns (IGovernedContract new_impl);

    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory proposals);

    function collectUpgradeProposal(IUpgradeProposal _proposal) external;

    fallback() external;

    receive() external payable;
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.7.6;

/**
 * Genesis version of GovernedContract interface.
 *
 * Base Consensus interface for upgradable contracts.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */

interface IGovernedContract {
    // Return actual proxy address for secure validation
    function proxy() external view returns (address);
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

interface IExchangeHelperGovernedProxy {
    function initialize(address _impl) external;

    function setSporkProxy(address payable _sporkProxy) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

interface IERC1271 {
    /**
     * @dev Function must be implemented by deriving contract
     * @param _hash Arbitrary length data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     * @return A bytes4 magic value 0x1626ba7e if the signature check passes, 0x00000000 if not
     */
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        external
        view
        returns (bytes4);
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;
pragma abicoder v2;

import { LibAssetTypes } from '../../libraries/LibAssetTypes.sol';
import { LibOrderTypes } from '../../libraries/LibOrderTypes.sol';
import { LibFillTypes } from '../../libraries/LibFillTypes.sol';
import { LibPartTypes } from '../../libraries/LibPartTypes.sol';
import { LibFeeSideTypes } from '../../libraries/LibFeeSideTypes.sol';
import { LibOrderDataV1Types } from '../../libraries/LibOrderDataV1Types.sol';

interface IExchangeHelper {
    // Functions
    function bps(uint256 value, uint16 bpsValue) external pure returns (uint256);

    function fillOrder(
        LibOrderTypes.Order calldata leftOrder,
        LibOrderTypes.Order calldata rightOrder,
        uint256 leftOrderTakeAssetFill,
        uint256 rightOrderTakeAssetFill
    ) external pure returns (LibFillTypes.FillResult memory);

    function hashKey(LibOrderTypes.Order calldata order) external pure returns (bytes32);

    function validate(LibOrderTypes.Order calldata order) external view;

    function validateOrder(
        LibOrderTypes.Order calldata order,
        bytes calldata _signature,
        address _callerAddress,
        address _veriyingContractProxy
    ) external view;

    function validateMatch(
        LibOrderTypes.Order calldata orderLeft,
        LibOrderTypes.Order calldata orderRight,
        uint256 matchLeftBeforeBlock,
        uint256 matchRightBeforeBlock,
        bytes memory orderBookSignatureLeft,
        bytes memory orderBookSignatureRight,
        address verifyingContractProxy,
        address orderBook
    ) external view returns (bytes32, bytes32);

    function matchAssets(
        LibOrderTypes.Order calldata orderLeft,
        LibOrderTypes.Order calldata orderRight
    ) external pure returns (LibAssetTypes.AssetType memory, LibAssetTypes.AssetType memory);

    function calculateTotalAmount(uint256 _amount, LibPartTypes.Part[] calldata _orderOriginFees)
        external
        pure
        returns (uint256);

    function subFeeInBps(
        uint256 _rest,
        uint256 _total,
        uint16 _feeInBps
    ) external pure returns (uint256, uint256);

    function getRoyaltiesByAssetType(
        LibAssetTypes.AssetType calldata assetType,
        address _royaltiesRegistry
    ) external view returns (LibPartTypes.Part[] memory);

    function parse(LibOrderTypes.Order memory order)
        external
        pure
        returns (LibOrderDataV1Types.DataV1 memory);

    function getFeeSide(bytes4 makerAssetClass, bytes4 takerAssetClass)
        external
        pure
        returns (LibFeeSideTypes.FeeSide);
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

import { GovernedContract } from '../GovernedContract.sol';
import { IGovernedProxy } from '../interfaces/IGovernedProxy.sol';

/**
 * ExchangeAutoProxy is a version of GovernedContract which deploys its own proxy.
 * This is useful to avoid a circular dependency between GovernedContract and GovernedProxy
 * wherein they need each other's address in the constructor.
 * If you want a new governed contract to create a proxy, pass address(0) when deploying
 * otherwise, you can pass a proxy address like in normal GovernedContract
 */

contract ExchangeAutoProxy is GovernedContract {
    constructor(address _proxy, address _impl) GovernedContract(_proxy) {
        proxy = _proxy;
        IGovernedProxy(payable(proxy)).initialize(_impl);
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of 'user permissions'.
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: Not owner');
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'Ownable: Zero address not allowed');
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.7.6;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * Genesis version of GovernedContract common base.
 *
 * Base Consensus interface for upgradable contracts.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */
contract GovernedContract {
    address public proxy;

    constructor(address _proxy) {
        proxy = _proxy;
    }

    modifier requireProxy() {
        require(msg.sender == proxy, 'Governed Contract: Not proxy');
        _;
    }

    function getProxy() internal view returns (address _proxy) {
        _proxy = proxy;
    }

    // solium-disable-next-line no-empty-blocks
    function _migrate(IGovernedContract) internal {}

    function _destroy(IGovernedContract _newImpl) internal {
        selfdestruct(address(uint160(address(_newImpl))));
    }

    function _callerAddress() internal view returns (address payable) {
        if (msg.sender == proxy) {
            // This is guarantee of the GovernedProxy
            // solium-disable-next-line security/no-tx-origin
            return tx.origin;
        } else {
            return msg.sender;
        }
    }
}