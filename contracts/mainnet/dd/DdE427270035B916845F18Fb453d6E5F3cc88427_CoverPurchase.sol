/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {ISecurityMatrix} from "../secmatrix/ISecurityMatrix.sol";
import {Math} from "../common/Math.sol";
import {Constant} from "../common/Constant.sol";
import {ICoverConfig} from "./ICoverConfig.sol";
import {ICoverData} from "./ICoverData.sol";
import {ICoverQuotation} from "./ICoverQuotation.sol";
import {ICoverQuotationData} from "./ICoverQuotationData.sol";
import {ICapitalPool} from "../pool/ICapitalPool.sol";
import {IPremiumPool} from "../pool/IPremiumPool.sol";
import {IExchangeRate} from "../exchange/IExchangeRate.sol";
import {IReferralProgram} from "../referral/IReferralProgram.sol";
import {ICoverPurchase} from "./ICoverPurchase.sol";
import {IProduct} from "../product/IProduct.sol";
import {CoverLib} from "./CoverLib.sol";

contract CoverPurchase is ICoverPurchase, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    // the security matrix address
    address public smx;
    // the insur token address
    address public insur;
    // the cover data address
    address public data;
    // the cover config address
    address public cfg;
    // the cover quotation address
    address public quotation;
    // the cover quotation data address
    address public quotationData;
    // the exchange rate address
    address public exchangeRate;
    // the referral program address
    address public referralProgram;
    // the product address
    address public product;

    // the overall capacity currency (e.g. USDT)
    address public capacityCurrency;
    // the overall capacity available amount (e.g. 10mil)
    uint256 public capacityAvailableAmount;
    // the number of blocks window size (e.g. 600 blocks)
    uint256 public capacityNumOfBlocksWindowSize;
    // the last window start block number
    uint256 public lastWindowStartBlockNumber;
    // the last window sold capacity amount
    uint256 public lastWindowSoldCapacityAmount;

    function initialize() public initializer {
        __Ownable_init();
    }

    function setup(
        address _securityMatrix,
        address _insurToken,
        address _coverDataAddress,
        address _coverCfgAddress,
        address _coverQuotationAddress,
        address _coverQuotationDataAddress,
        address _productAddress,
        address _exchangeRate,
        address _referralProgram
    ) external onlyOwner {
        require(_securityMatrix != address(0), "S:1");
        require(_insurToken != address(0), "S:2");
        require(_coverDataAddress != address(0), "S:3");
        require(_coverCfgAddress != address(0), "S:4");
        require(_coverQuotationAddress != address(0), "S:5");
        require(_coverQuotationDataAddress != address(0), "S:6");
        require(_productAddress != address(0), "S:7");
        require(_exchangeRate != address(0), "S:8");
        require(_referralProgram != address(0), "S:9");
        smx = _securityMatrix;
        insur = _insurToken;
        data = _coverDataAddress;
        cfg = _coverCfgAddress;
        quotation = _coverQuotationAddress;
        quotationData = _coverQuotationDataAddress;
        product = _productAddress;
        exchangeRate = _exchangeRate;
        referralProgram = _referralProgram;
    }

    event SetOverallCapacityEvent(address indexed _currency, uint256 _availableAmount, uint256 _numOfBlocksWindowSize);

    function setOverallCapacity(
        address _currency,
        uint256 _availableAmount,
        uint256 _numOfBlocksWindowSize
    ) external override onlyOwner {
        capacityCurrency = _currency;
        capacityAvailableAmount = _availableAmount;
        capacityNumOfBlocksWindowSize = _numOfBlocksWindowSize;
        emit SetOverallCapacityEvent(_currency, _availableAmount, _numOfBlocksWindowSize);
    }

    function getOverallCapacity()
        external
        view
        override
        returns (
            address,
            uint256,
            uint256
        )
    {
        return (capacityCurrency, capacityAvailableAmount, capacityNumOfBlocksWindowSize);
    }

    modifier allowedCaller() {
        require((ISecurityMatrix(smx).isAllowdCaller(address(this), _msgSender())) || (_msgSender() == owner()), "allowedCaller");
        _;
    }

    function prepareBuyCover(
        uint256[] memory products,
        uint256[] memory durationInDays,
        uint256[] memory amounts,
        uint256[] memory usedAmounts,
        uint256[] memory totalAmounts,
        uint256 allTotalAmount,
        address[] memory currencies,
        address owner,
        uint256 referralCode,
        uint256[] memory rewardPercentages
    )
        external
        view
        override
        returns (
            uint256 premiumAmount,
            uint256[] memory helperParameters,
            uint256 discountPercentX10000,
            uint256[] memory insurRewardAmounts
        )
    {
        require(products.length == durationInDays.length, "GPCHK: 1");
        require(products.length == amounts.length, "GPCHK: 2");
        require(ICoverConfig(cfg).isValidCurrency(currencies[0]) && ICoverConfig(cfg).isValidCurrency(currencies[1]), "GPCHK: 3");
        require(owner != address(0), "GPCHK: 4");
        require(address(uint160(referralCode)) != address(0), "GPCHK: 5");

        // calculate total amounts and total weights
        helperParameters = new uint256[](2);
        for (uint256 i = 0; i < products.length; i++) {
            uint256 productId = products[i];
            uint256 coverDuration = durationInDays[i];
            uint256 coverAmount = amounts[i];
            helperParameters[0] = helperParameters[0].add(coverAmount);
            helperParameters[1] = helperParameters[1].add(coverAmount.mul(coverDuration).mul(ICoverQuotationData(quotationData).getUnitCost(productId)));
        }

        // calculate the cover premium amount
        (premiumAmount, discountPercentX10000) = ICoverQuotation(quotation).getPremium(products, durationInDays, amounts, usedAmounts, totalAmounts, allTotalAmount, currencies[0]);
        premiumAmount = IExchangeRate(exchangeRate).getTokenToTokenAmount(currencies[0], currencies[1], premiumAmount);
        require(premiumAmount > 0, "GPCHK: 6");

        // calculate the cover owner and referral INSUR reward amounts
        require(rewardPercentages.length == 2, "GPCHK: 7");
        insurRewardAmounts = new uint256[](2);
        uint256 premiumAmount2Insur = IExchangeRate(exchangeRate).getTokenToTokenAmount(currencies[1], insur, premiumAmount);
        if (premiumAmount2Insur > 0 && owner != address(uint160(referralCode))) {
            // calculate the Cover Owner INSUR Reward Amount
            uint256 coverOwnerRewardPctg = CoverLib.getRewardPctg(cfg, rewardPercentages[0]);
            insurRewardAmounts[0] = CoverLib.getRewardAmount(premiumAmount2Insur, coverOwnerRewardPctg);
            // calculate the Referral INSUR Reward Amount
            uint256 referralRewardPctg = IReferralProgram(referralProgram).getRewardPctg(Constant.REFERRALREWARD_COVER, rewardPercentages[1]);
            insurRewardAmounts[1] = IReferralProgram(referralProgram).getRewardAmount(Constant.REFERRALREWARD_COVER, premiumAmount2Insur, referralRewardPctg);
        }

        // check the overall capacity
        if (capacityCurrency != address(0)) {
            uint256 occuipedCapacityAmount = IExchangeRate(exchangeRate).getTokenToTokenAmount(currencies[0], capacityCurrency, helperParameters[0]);
            uint256 totalOccupiedCapacityAmount = capacityNumOfBlocksWindowSize.add(lastWindowStartBlockNumber) <= block.number ? occuipedCapacityAmount : occuipedCapacityAmount.add(lastWindowSoldCapacityAmount);
            require(totalOccupiedCapacityAmount <= capacityAvailableAmount, "GPCHK: 8");
        }

        return (premiumAmount, helperParameters, discountPercentX10000, insurRewardAmounts);
    }

    event BuyCoverEventV3(address indexed currency, address indexed owner, uint256 coverId, uint256 productId, uint256 durationInDays, uint256 extendedClaimDays, uint256 coverAmount, address indexed premiumCurrency, uint256 estimatedPremiumAmount, uint256 coverStatus, uint256 delayEffectiveDays);

    event BuyCoverEventV4(address indexed currency, address indexed owner, uint256 coverId, uint256 productId, uint256 durationInDays, uint256 extendedClaimDays, uint256 coverAmount, address indexed premiumCurrency, uint256 estimatedPremiumAmount, uint256 coverStatus, uint256 delayEffectiveDays, string freeText);

    event BuyCoverOwnerRewardEventV2(address indexed owner, uint256 rewardPctg, uint256 insurRewardAmt);

    function buyCover(
        uint16[] memory products,
        uint16[] memory durationInDays,
        uint256[] memory amounts,
        address[] memory addresses,
        uint256 premiumAmount,
        uint256 referralCode,
        uint256[] memory helperParameters,
        string memory freeText
    ) external override allowedCaller {
        // check and update the overall capacity amount
        if (capacityCurrency != address(0)) {
            uint256 occuipedCapacityAmount = IExchangeRate(exchangeRate).getTokenToTokenAmount(addresses[1], capacityCurrency, helperParameters[0]);
            if (capacityNumOfBlocksWindowSize.add(lastWindowStartBlockNumber) <= block.number) {
                lastWindowStartBlockNumber = block.number;
                lastWindowSoldCapacityAmount = occuipedCapacityAmount;
            } else {
                lastWindowSoldCapacityAmount = lastWindowSoldCapacityAmount.add(occuipedCapacityAmount);
            }
            require(lastWindowSoldCapacityAmount <= capacityAvailableAmount, "CPBC: 1");
        }
        // check and get the reward percentages if there is a valid referral code
        uint256[] memory rewardPctgs = new uint256[](2);
        if (addresses[0] != address(uint160(referralCode))) {
            uint256 premiumAmount2Insur = IExchangeRate(exchangeRate).getTokenToTokenAmount(addresses[2], insur, premiumAmount);
            // distribute the cover owner reward
            rewardPctgs[0] = CoverLib.getRewardPctg(cfg, helperParameters[2]);
            uint256 ownerRewardAmount = CoverLib.processCoverOwnerReward(data, addresses[0], premiumAmount2Insur, rewardPctgs[0]);
            emit BuyCoverOwnerRewardEventV2(addresses[0], rewardPctgs[0], ownerRewardAmount);
            // distribute the referral reward if the referral address is not the owner address
            rewardPctgs[1] = IReferralProgram(referralProgram).getRewardPctg(Constant.REFERRALREWARD_COVER, helperParameters[3]);
            IReferralProgram(referralProgram).processReferralReward(address(uint160(referralCode)), addresses[0], Constant.REFERRALREWARD_COVER, premiumAmount2Insur, rewardPctgs[1]);
        }
        // create the expanded cover records (one per each cover item)
        _createCovers(products, durationInDays, amounts, addresses, premiumAmount, helperParameters, freeText, rewardPctgs);
    }

    function _createCovers(
        uint16[] memory products,
        uint16[] memory durationInDays,
        uint256[] memory amounts,
        address[] memory addresses,
        uint256 premiumAmount,
        uint256[] memory helperParameters,
        string memory freeText,
        uint256[] memory rewardPctgs
    ) internal {
        uint256 cumPremiumAmount = 0;
        for (uint256 index = 0; index < products.length; ++index) {
            uint256 estimatedPremiumAmount = 0;
            if (index == products.length.sub(1)) {
                estimatedPremiumAmount = premiumAmount.sub(cumPremiumAmount);
            } else {
                uint256 currentWeight = amounts[index].mul(durationInDays[index]).mul(ICoverQuotationData(quotationData).getUnitCost(products[index]));
                estimatedPremiumAmount = premiumAmount.mul(currentWeight).div(helperParameters[1]);
                cumPremiumAmount = cumPremiumAmount.add(estimatedPremiumAmount);
            }
            _createOneCover(products[index], durationInDays[index], amounts[index], addresses, estimatedPremiumAmount, freeText, rewardPctgs);
        }
    }

    function _createOneCover(
        uint256 productId,
        uint256 durationInDays,
        uint256 amount,
        address[] memory addresses,
        uint256 estimatedPremiumAmount,
        string memory freeText,
        uint256[] memory rewardPctgs
    ) internal {
        uint256 nextCoverId = ICoverData(data).increaseCoverCount(addresses[0]);
        {
            uint256 beginTimestamp = block.timestamp.add(IProduct(product).getProductDelayEffectiveDays(productId) * 1 days); // solhint-disable-line not-rely-on-time
            uint256 endTimestamp = beginTimestamp.add(durationInDays * 1 days);
            ICoverData(data).setNewCoverDetails(addresses[0], nextCoverId, productId, amount, addresses[1], addresses[2], estimatedPremiumAmount, beginTimestamp, endTimestamp, endTimestamp.add(ICoverConfig(cfg).getMaxClaimDurationInDaysAfterExpired() * 1 days), Constant.COVERSTATUS_ACTIVE);
        }

        if (bytes(freeText).length > 0) {
            ICoverData(data).setCoverFreeText(addresses[0], nextCoverId, freeText);
        }

        if (rewardPctgs[0] > 0) {
            ICoverData(data).setCoverRewardPctg(addresses[0], nextCoverId, rewardPctgs[0]);
        }

        if (rewardPctgs[1] > 0) {
            ICoverData(data).setCoverReferralRewardPctg(addresses[0], nextCoverId, rewardPctgs[1]);
        }

        uint256 delayEffectiveDays = IProduct(product).getProductDelayEffectiveDays(productId);
        emit BuyCoverEventV4(addresses[1], addresses[0], nextCoverId, productId, durationInDays, ICoverConfig(cfg).getMaxClaimDurationInDaysAfterExpired(), amount, addresses[2], estimatedPremiumAmount, Constant.COVERSTATUS_ACTIVE, delayEffectiveDays, freeText);
    }
}

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
library SafeMathUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface ISecurityMatrix {
    function isAllowdCaller(address _callee, address _caller) external view returns (bool);
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

// a library for performing various math operations
library Math {
    using SafeMathUpgradeable for uint256;

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? y : x;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y.div(2).add(1);
            while (x < z) {
                z = x;
                x = (y.div(x).add(x)).div(2);
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // power private function
    function pow(uint256 _base, uint256 _exponent) internal pure returns (uint256) {
        if (_exponent == 0) {
            return 1;
        } else if (_exponent == 1) {
            return _base;
        } else if (_base == 0 && _exponent != 0) {
            return 0;
        } else {
            uint256 z = _base;
            for (uint256 i = 1; i < _exponent; i++) {
                z = z.mul(_base);
            }
            return z;
        }
    }
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

library Constant {
    // the standard 10**18 Amount Multiplier
    uint256 public constant MULTIPLIERX10E18 = 10**18;

    // the valid ETH and DAI addresses (Rinkeby, TBD: Mainnet)
    address public constant BCNATIVETOKENADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // product status enumerations
    uint256 public constant PRODUCTSTATUS_ENABLED = 1;
    uint256 public constant PRODUCTSTATUS_DISABLED = 2;

    // the cover status enumerations
    uint256 public constant COVERSTATUS_ACTIVE = 0;
    uint256 public constant COVERSTATUS_EXPIRED = 1;
    uint256 public constant COVERSTATUS_CLAIMINPROGRESS = 2;
    uint256 public constant COVERSTATUS_CLAIMDONE = 3;
    uint256 public constant COVERSTATUS_CANCELLED = 4;

    // the claim proposal result status enumerations
    uint256 public constant CLAIMPROPOSALSTATUS_NONE = 0;
    uint256 public constant CLAIMPROPOSALSTATUS_ACCEPTED = 1;
    uint256 public constant CLAIMPROPOSALSTATUS_REJECTED = 2;

    // the claim status enumerations
    uint256 public constant CLAIMSTATUS_SUBMITTED = 0;
    uint256 public constant CLAIMSTATUS_INVESTIGATING = 1;
    uint256 public constant CLAIMSTATUS_PREPAREFORVOTING = 2;
    uint256 public constant CLAIMSTATUS_VOTING = 3;
    uint256 public constant CLAIMSTATUS_VOTINGCOMPLETED = 4;
    uint256 public constant CLAIMSTATUS_ABDISCRETION = 5;
    uint256 public constant CLAIMSTATUS_COMPLAINING = 6;
    uint256 public constant CLAIMSTATUS_COMPLAININGCOMPLETED = 7;
    uint256 public constant CLAIMSTATUS_ACCEPTED = 8;
    uint256 public constant CLAIMSTATUS_REJECTED = 9;
    uint256 public constant CLAIMSTATUS_PAYOUTREADY = 10;
    uint256 public constant CLAIMSTATUS_PAID = 11;
    uint256 public constant CLAIMSTATUS_ANALYZING = 12;

    // the voting outcome status enumerations
    uint256 public constant OUTCOMESTATUS_NONE = 0;
    uint256 public constant OUTCOMESTATUS_ACCEPTED = 1;
    uint256 public constant OUTCOMESTATUS_REJECTED = 2;

    // the referral reward type
    uint256 public constant REFERRALREWARD_NONE = 0;
    uint256 public constant REFERRALREWARD_COVER = 1;
    uint256 public constant REFERRALREWARD_STAKING = 2;

    // DAO proposal status enumerations
    uint256 public constant DAOPROPOSALSTATUS_SUBMITTED = 0;
    uint256 public constant DAOPROPOSALSTATUS_VOTING = 1;
    uint256 public constant DAOPROPOSALSTATUS_CANCELLED = 2;
    uint256 public constant DAOPROPOSALSTATUS_COMPLETED = 3;
    uint256 public constant DAOPROPOSALSTATUS_PASSED = 4;
    uint256 public constant DAOPROPOSALSTATUS_FAILED = 5;
    uint256 public constant DAOPROPOSALSTATUS_EXECUTED = 6;

    // DAO vote choice enumerations
    uint256 public constant DAOVOTECHOICE_SUPPORT = 0;
    uint256 public constant DAOVOTECHOICE_AGAINST = 1;
    uint256 public constant DAOVOTECHOICE_ABSTAINED = 2;
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface ICoverConfig {
    function getAllValidCurrencyArray() external view returns (address[] memory);

    function isValidCurrency(address currency) external view returns (bool);

    function getMinDurationInDays() external view returns (uint256);

    function getMaxDurationInDays() external view returns (uint256);

    function getMinAmountOfCurrency(address currency) external view returns (uint256);

    function getMaxAmountOfCurrency(address currency) external view returns (uint256);

    function getCoverConfigDetails()
        external
        view
        returns (
            uint256,
            uint256,
            address[] memory,
            uint256[] memory,
            uint256[] memory
        );

    function getMaxClaimDurationInDaysAfterExpired() external view returns (uint256);

    function getInsurTokenRewardPercentX10000() external view returns (uint256);

    function getCancelCoverFeeRateX10000() external view returns (uint256);
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface ICoverData {
    function getCoverCount(address owner) external view returns (uint256);

    function increaseCoverCount(address owner) external returns (uint256);

    function setNewCoverDetails(
        address owner,
        uint256 coverId,
        uint256 productId,
        uint256 amount,
        address currency,
        address premiumCurrency,
        uint256 premiumAmount,
        uint256 beginTimestamp,
        uint256 endTimestamp,
        uint256 maxClaimableTimestamp,
        uint256 coverStatus
    ) external;

    function getCoverBeginTimestamp(address owner, uint256 coverId) external view returns (uint256);

    function setCoverBeginTimestamp(
        address owner,
        uint256 coverId,
        uint256 timestamp
    ) external;

    function getCoverEndTimestamp(address owner, uint256 coverId) external view returns (uint256);

    function setCoverEndTimestamp(
        address owner,
        uint256 coverId,
        uint256 timestamp
    ) external;

    function getCoverMaxClaimableTimestamp(address owner, uint256 coverId) external view returns (uint256);

    function setCoverMaxClaimableTimestamp(
        address owner,
        uint256 coverId,
        uint256 timestamp
    ) external;

    function getCoverProductId(address owner, uint256 coverId) external view returns (uint256);

    function setCoverProductId(
        address owner,
        uint256 coverId,
        uint256 productId
    ) external;

    function getCoverCurrency(address owner, uint256 coverId) external view returns (address);

    function setCoverCurrency(
        address owner,
        uint256 coverId,
        address currency
    ) external;

    function getCoverAmount(address owner, uint256 coverId) external view returns (uint256);

    function setCoverAmount(
        address owner,
        uint256 coverId,
        uint256 amount
    ) external;

    function getAdjustedCoverStatus(address owner, uint256 coverId) external view returns (uint256);

    function setCoverStatus(
        address owner,
        uint256 coverId,
        uint256 coverStatus
    ) external;

    function getEligibleClaimAmount(address owner, uint256 coverId) external view returns (uint256);

    function isValidClaim(
        address owner,
        uint256 coverId,
        uint256 amount
    ) external view returns (bool);

    function getCoverEstimatedPremiumAmount(address owner, uint256 coverId) external view returns (uint256);

    function setCoverEstimatedPremiumAmount(
        address owner,
        uint256 coverId,
        uint256 amount
    ) external;

    function getBuyCoverInsurTokenEarned(address owner) external view returns (uint256);

    function increaseBuyCoverInsurTokenEarned(address owner, uint256 amount) external;

    function decreaseBuyCoverInsurTokenEarned(address owner, uint256 amount) external;

    function getTotalInsurTokenRewardAmount() external view returns (uint256);

    function increaseTotalInsurTokenRewardAmount(uint256 amount) external;

    function decreaseTotalInsurTokenRewardAmount(uint256 amount) external;

    function getCoverRewardPctg(address owner, uint256 coverId) external view returns (uint256);

    function setCoverRewardPctg(
        address owner,
        uint256 coverId,
        uint256 rewardPctg
    ) external;

    function getCoverClaimedAmount(address owner, uint256 coverId) external view returns (uint256);

    function increaseCoverClaimedAmount(
        address owner,
        uint256 coverId,
        uint256 amount
    ) external;

    function getCoverReferralRewardPctg(address owner, uint256 coverId) external view returns (uint256);

    function setCoverReferralRewardPctg(
        address owner,
        uint256 coverId,
        uint256 referralRewardPctg
    ) external;

    function getCoverPremiumCurrency(address owner, uint256 coverId) external view returns (address);

    function setCoverPremiumCurrency(
        address owner,
        uint256 coverId,
        address premiumCurrency
    ) external;

    function getCoverFreeText(address owner, uint256 coverId) external view returns (string memory);

    function setCoverFreeText(
        address owner,
        uint256 coverId,
        string memory freeText
    ) external;
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface ICoverQuotation {
    function getNetUnitCosts(
        uint256[] memory products,
        uint256[] memory usedAmounts,
        uint256[] memory totalAmounts,
        uint256 allTotalAmount
    ) external view returns (uint256[] memory);

    function getGrossUnitCosts(
        uint256[] memory products,
        uint256[] memory usedAmounts,
        uint256[] memory totalAmounts,
        uint256 allTotalAmount
    ) external view returns (uint256[] memory);

    function getPremium(
        uint256[] memory products,
        uint256[] memory durationInDays,
        uint256[] memory amounts,
        uint256[] memory usedAmounts,
        uint256[] memory totalAmounts,
        uint256 allTotalAmount,
        address currency
    ) external view returns (uint256, uint256);
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface ICoverQuotationData {
    function getUnitCost(uint256 productId) external view returns (uint256);

    function getDiscountFactorCount() external view returns (uint256);

    function getDiscountFactor(uint256 numOfProducts) external view returns (uint256);

    function getHighRiskCeilingProductScore() external view returns (uint256);

    function getAdjustmentFactorCount() external view returns (uint256);

    function getAdjustmentFactor(uint256 highRiskProductCount) external view returns (uint256);

    function getTheta1Percent() external view returns (uint256);

    function getTheta2Percent() external view returns (uint256);

    function getRiskMarginPercent() external view returns (uint256);

    function getExpenseMarginPercent() external view returns (uint256);

    function getPremiumDiscountPercentX10000() external view returns (uint256);

    function getPremiumNumOfDecimals() external view returns (uint256);
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface ICapitalPool {
    function canBuyCoverPerProduct(
        uint256 _productId,
        uint256 _amount,
        address _token
    ) external view returns (bool);

    function canBuyCover(uint256 _amount, address _token) external view returns (bool);

    function buyCoverPerProduct(
        uint256 _productId,
        uint256 _amount,
        address _token
    ) external;

    function hasTokenInStakersPool(address _token) external view returns (bool);

    function getCapacityInfo() external view returns (uint256, uint256);

    function getProductCapacityInfo(uint256[] memory _products)
        external
        view
        returns (
            address,
            uint256[] memory,
            uint256[] memory
        );

    function getProductCapacityRatio(uint256 _productId) external view returns (uint256);

    function getBaseToken() external view returns (address);

    function getCoverAmtPPMaxRatio() external view returns (uint256);

    function getCoverAmtPPInBaseToken(uint256 _productId) external view returns (uint256);

    function settlePaymentForClaim(
        address _token,
        uint256 _amount,
        uint256 _claimId
    ) external;

    function getStakingPercentageX10000() external view returns (uint256);

    function getTVLinBaseToken() external view returns (address, uint256);
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface IPremiumPool {
    function addPremiumAmount(address _token, uint256 _amount) external payable;

    function getPremiumPoolAmtInPaymentToken(address _paymentToken) external view returns (uint256);

    function settlePayoutFromPremium(
        address _paymentToken,
        uint256 _settleAmt,
        address _claimToSettlementPool
    ) external returns (uint256);
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface IExchangeRate {
    function getBaseCurrency() external view returns (address);

    function setBaseCurrency(address _currency) external;

    function getAllCurrencyArray() external view returns (address[] memory);

    function addCurrencies(
        address[] memory _currencies,
        uint128[] memory _multipliers,
        uint128[] memory _rates
    ) external;

    function removeCurrency(address _currency) external;

    function getAllCurrencyRates() external view returns (uint256[] memory);

    function updateAllCurrencies(uint128[] memory _rates) external;

    function updateCurrency(address _currency, uint128 _rate) external;

    function getTokenToTokenAmount(
        address _fromToken,
        address _toToken,
        uint256 _amount
    ) external view returns (uint256);
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface IReferralProgram {
    function getReferralINSURRewardPctg(uint256 rewardType) external view returns (uint256);

    function setReferralINSURRewardPctg(uint256 rewardType, uint256 percent) external;

    function getReferralINSURRewardAmount() external view returns (uint256);

    function getTotalReferralINSURRewardAmount() external view returns (uint256);

    function getRewardPctg(uint256 rewardType, uint256 overwrittenRewardPctg) external view returns (uint256);

    function getRewardAmount(
        uint256 rewardType,
        uint256 baseAmount,
        uint256 overwrittenRewardPctg
    ) external view returns (uint256);

    function processReferralReward(
        address referrer,
        address referee,
        uint256 rewardType,
        uint256 baseAmount,
        uint256 rewardPctg
    ) external;

    function unlockRewardByController(address referrer, address to) external returns (uint256);

    function getINSURRewardBalanceDetails() external view returns (uint256, uint256);

    function removeINSURRewardBalance(address toAddress, uint256 amount) external;
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface ICoverPurchase {
    function setOverallCapacity(
        address _currency,
        uint256 _availableAmount,
        uint256 _numOfBlocksWindowSize
    ) external;

    function getOverallCapacity()
        external
        view
        returns (
            address,
            uint256,
            uint256
        );

    function prepareBuyCover(
        uint256[] memory products,
        uint256[] memory durationInDays,
        uint256[] memory amounts,
        uint256[] memory usedAmounts,
        uint256[] memory totalAmounts,
        uint256 allTotalAmount,
        address[] memory currencies,
        address owner,
        uint256 referralCode,
        uint256[] memory rewardPercentages
    )
        external
        view
        returns (
            uint256,
            uint256[] memory,
            uint256,
            uint256[] memory
        );

    function buyCover(
        uint16[] memory products,
        uint16[] memory durationInDays,
        uint256[] memory amounts,
        address[] memory addresses,
        uint256 premiumAmount,
        uint256 referralCode,
        uint256[] memory helperParameters,
        string memory freeText
    ) external;
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface IProduct {
    function getProductCount() external view returns (uint256);

    function getProductDelayEffectiveDays(uint256 productId) external view returns (uint256);

    function getProductScore(uint256 productId) external view returns (uint256);

    function getProductClaimDisabledFlag(uint256 productId) external view returns (bool);

    function getProductStatus(uint256 productId) external view returns (uint256);

    function getProductDetails(uint256 productId)
        external
        view
        returns (
            bytes32,
            bytes32,
            bytes32,
            uint256,
            uint256,
            uint256,
            bool
        );

    function getAllProductDetails()
        external
        view
        returns (
            uint256[] memory,
            bytes32[] memory,
            bytes32[] memory,
            bytes32[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        );
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {Constant} from "../common/Constant.sol";
import {ICoverConfig} from "./ICoverConfig.sol";
import {ICoverData} from "./ICoverData.sol";
import {Math} from "../common/Math.sol";

library CoverLib {
    using SafeMathUpgradeable for uint256;

    function getRewardPctg(address coverCfg, uint256 overwrittenRewardPctg) internal view returns (uint256) {
        return overwrittenRewardPctg > 0 ? overwrittenRewardPctg : ICoverConfig(coverCfg).getInsurTokenRewardPercentX10000();
    }

    function getRewardAmount(uint256 premiumAmount2Insur, uint256 rewardPctg) internal pure returns (uint256) {
        return rewardPctg <= 10000 ? premiumAmount2Insur.mul(rewardPctg).div(10**4) : 0;
    }

    function processCoverOwnerReward(
        address coverData,
        address owner,
        uint256 premiumAmount2Insur,
        uint256 rewardPctg
    ) internal returns (uint256) {
        require(rewardPctg <= 10000, "PCORWD: 1");
        uint256 rewardAmount = getRewardAmount(premiumAmount2Insur, rewardPctg);
        if (rewardAmount > 0) {
            ICoverData(coverData).increaseTotalInsurTokenRewardAmount(rewardAmount);
            ICoverData(coverData).increaseBuyCoverInsurTokenEarned(owner, rewardAmount);
        }
        return rewardAmount;
    }

    function getEarnedPremiumAmount(
        address coverData,
        address owner,
        uint256 coverId,
        uint256 premiumAmount
    ) internal view returns (uint256) {
        return premiumAmount.sub(getUnearnedPremiumAmount(coverData, owner, coverId, premiumAmount));
    }

    function getUnearnedPremiumAmount(
        address coverData,
        address owner,
        uint256 coverId,
        uint256 premiumAmount
    ) internal view returns (uint256) {
        uint256 unearnedPremAmt = premiumAmount;
        uint256 cvAmt = ICoverData(coverData).getCoverAmount(owner, coverId);
        uint256 begin = ICoverData(coverData).getCoverBeginTimestamp(owner, coverId);
        uint256 end = ICoverData(coverData).getCoverEndTimestamp(owner, coverId);
        uint256 claimed = ICoverData(coverData).getCoverClaimedAmount(owner, coverId);
        if (claimed > 0) {
            unearnedPremAmt = unearnedPremAmt.mul(cvAmt.sub(claimed)).div(cvAmt);
        }
        uint256 totalRewardPctg = getTotalRewardPctg(coverData, owner, coverId);
        if (totalRewardPctg > 0) {
            unearnedPremAmt = unearnedPremAmt.mul(uint256(10000).sub(totalRewardPctg)).div(10000);
        }
        uint256 adjustedNowTimestamp = Math.max(block.timestamp, begin); // solhint-disable-line not-rely-on-time
        return unearnedPremAmt.mul(end.sub(adjustedNowTimestamp)).div(end.sub(begin));
    }

    function getTotalRewardPctg(
        address coverData,
        address owner,
        uint256 coverId
    ) internal view returns (uint256) {
        return ICoverData(coverData).getCoverRewardPctg(owner, coverId).add(ICoverData(coverData).getCoverReferralRewardPctg(owner, coverId));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly { size := extcodesize(account) }
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

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
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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