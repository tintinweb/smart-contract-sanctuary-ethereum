// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./interfaces/ILnAsset.sol";
import "./interfaces/ILnPerpetual.sol";
import "./interfaces/ILnPerpExchange.sol";
import "./interfaces/ILnPerpPositionToken.sol";
import "./interfaces/ILnPrices.sol";

contract LnPerpetual is ILnPerpetual, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    event PositionCreated(
        address indexed user,
        uint256 indexed positionId,
        bool isLong,
        uint256 size,
        uint256 price,
        uint256 collateral,
        uint256 fees
    );
    event PositionIncreased(
        address indexed user,
        uint256 indexed positionId,
        uint256 size,
        uint256 price,
        uint256 additionalCollateral,
        uint256 fees
    );
    event CollateralAdded(address indexed user, uint256 indexed positionId, uint256 amount);
    event CollateralRemoved(address indexed user, uint256 indexed positionId, uint256 amount);
    event PoistionLiquidated(
        address indexed user,
        uint256 indexed positionId,
        uint256 size,
        uint256 price,
        address liquidator,
        uint256 fees,
        uint256 liquidatorReward,
        uint256 insuranceFundContribution
    );
    event PositionPartiallyClosed(
        address indexed user,
        uint256 indexed positionId,
        uint256 size,
        uint256 price,
        uint256 fees
    );
    event PositionClosed(
        address indexed user,
        uint256 indexed positionId,
        uint256 size,
        uint256 price,
        uint256 fees,
        uint256 collateralReturned
    );
    event PositionSync(uint256 indexed positionId, bool isLong, uint256 debt, uint256 locked, uint256 collateral);

    /**
     @param isLong Whether it's a long or short position.
     @param debt The amount of debt to be repaid to close the position. The amount is in lUSD for long positions, and in XYZ for short positions.
     @param locked The amount of locked proceeds. The amout is in XYZ for long positions, and is ignored for short positions.
     @param collateral The amount of lUSD collateral, which includes sell proceeds for short positions.
     */
    struct Position {
        bool isLong;
        uint256 debt;
        uint256 locked;
        uint256 collateral;
    }

    ILnPerpExchange public exchange;
    ILnPerpPositionToken public positionToken;
    ILnAsset public lusdToken;
    ILnAsset public underlyingToken;
    ILnPrices public lnPrices;
    uint256 public minInitMargin;
    uint256 public maintenanceMargin;
    uint256 public feeRate;
    uint256 public liquidatorRewardRatio; // % of position value liquidated to be rewarded
    uint256 public insuranceFundContributionRatio; // % of liquidator reward to be sent to insurance fund instead
    bytes32 public override underlyingTokenSymbol;

    uint256 public override totalUsdDebt;
    uint256 public override totalUnderlyingDebt;
    mapping(uint256 => Position) public positions;

    uint256 private constant UNIT = 10**18;
    bytes32 private constant LUSD = "lUSD";

    modifier onlyExchange() {
        require(msg.sender == address(exchange), "LnPerpetual: not exchange");
        _;
    }

    function getCollateralizationRatio(uint256 positionId) external view returns (uint256) {
        return _calculateCollateralizationRatio(positionId);
    }

    function __LnPerpetual_init(
        ILnPerpExchange _exchange,
        ILnPerpPositionToken _positionToken,
        ILnAsset _lusdToken,
        ILnAsset _underlyingToken,
        ILnPrices _lnPrices,
        uint256 _minInitMargin,
        uint256 _maintenanceMargin,
        uint256 _feeRate,
        uint256 _liquidatorRewardRatio,
        uint256 _insuranceFundContributionRatio
    ) public initializer {
        __Ownable_init();

        require(address(_exchange) != address(0), "LnPerpetual: zero address");
        require(address(_positionToken) != address(0), "LnPerpetual: zero address");
        require(address(_lusdToken) != address(0), "LnPerpetual: zero address");
        require(address(_underlyingToken) != address(0), "LnPerpetual: zero address");
        require(address(_lnPrices) != address(0), "LnPerpetual: zero address");
        require(_maintenanceMargin > 0, "LnPerpetual: zero amount");
        require(_minInitMargin > _maintenanceMargin, "LnPerpetual: invalid minInitMargin");

        exchange = _exchange;
        positionToken = _positionToken;
        lusdToken = _lusdToken;
        underlyingToken = _underlyingToken;
        lnPrices = _lnPrices;
        minInitMargin = _minInitMargin;
        maintenanceMargin = _maintenanceMargin;
        feeRate = _feeRate;
        liquidatorRewardRatio = _liquidatorRewardRatio;
        insuranceFundContributionRatio = _insuranceFundContributionRatio;

        underlyingTokenSymbol = _underlyingToken.keyName();

        // TODO: check if liquidator reward ratio makes sense
    }

    function setMinInitMargin(uint256 newMinInitMargin) external onlyOwner {
        require(newMinInitMargin > 0, "LnPerpetual: zero amount");
        minInitMargin = newMinInitMargin;
    }

    function setMaintenanceMargin(uint256 newMaintenanceMargin) external onlyOwner {
        require(newMaintenanceMargin > 0, "LnPerpetual: zero amount");
        maintenanceMargin = newMaintenanceMargin;
    }

    function setLnPrices(ILnPrices newLnPrices) external onlyOwner {
        require(address(newLnPrices) != address(0), "address: zero address");
        lnPrices = newLnPrices;
    }

    function setFeeRate(uint256 newFeeRate) external onlyOwner {
        feeRate = newFeeRate;
    }

    function openPosition(
        address user,
        bool isLong,
        uint256 size,
        uint256 collateral
    ) external override onlyExchange returns (uint256 positionId, uint256 underlyingPrice) {
        (positionId, underlyingPrice) = _openPosition(user, isLong, size, collateral);
    }

    function increasePosition(
        address user,
        uint256 positionId,
        uint256 size,
        uint256 collateral
    ) external override onlyExchange returns (uint256 underlyingPrice) {
        underlyingPrice = _increasePosition(user, positionId, size, collateral);
    }

    function addCollateral(uint256 positionId, uint256 amount) external {
        _addCollateral(msg.sender, positionId, amount);
    }

    function removeCollateral(
        uint256 positionId,
        uint256 amount,
        address to
    ) external {
        require(amount > 0, "LnPerpetual: zero amount");

        _removeCollateral(msg.sender, positionId, amount, to);
    }

    function closePositionByAmount(
        address user,
        uint256 positionId,
        uint256 amount,
        address to
    ) external override onlyExchange returns (uint256 underlyingPrice) {
        require(amount > 0, "LnPerpetual: zero amount");

        underlyingPrice = _closePositionByAmount(user, positionId, amount, to);
    }

    function closePosition(
        address user,
        uint256 positionId,
        address to
    ) external override onlyExchange returns (uint256 underlyingPrice) {
        underlyingPrice = _closePositionByAmount(user, positionId, 0, to);
    }

    function liquidatePosition(
        uint256 positionId,
        uint256 amount,
        address rewardTo
    ) external {
        require(amount > 0, "LnPerpetual: zero amount");

        _liquidatePosition(msg.sender, positionId, amount, rewardTo);
    }

    function _openPosition(
        address user,
        bool isLong,
        uint256 size,
        uint256 collateral
    ) private returns (uint256 positionId, uint256 underlyingPrice) {
        require(size > 0, "LnPerpetual: zero amount");
        require(collateral > 0, "LnPerpetual: zero amount");

        positionId = exchange.requestPositionMint(user);

        // Leave all other fields empty and let _addPositionSize take care of that
        if (isLong) {
            positions[positionId].isLong = true;
        }

        uint256 fees = _addPositionSize(positionId, size, collateral);
        underlyingPrice = lnPrices.getPrice(underlyingTokenSymbol);

        emit PositionCreated(user, positionId, isLong, size, lnPrices.getPrice(underlyingTokenSymbol), collateral, fees);

        _emitPositionSync(positionId);
    }

    function _increasePosition(
        address user,
        uint256 positionId,
        uint256 size,
        uint256 collateral
    ) private returns (uint256 underlyingPrice) {
        require(size > 0, "LnPerpetual: zero amount");

        require(user == positionToken.ownerOf(positionId), "LnPerpetual: owner mismatch");
        require(positions[positionId].debt > 0, "LnPerpetual: position not found");

        uint256 fees = _addPositionSize(positionId, size, collateral);
        underlyingPrice = lnPrices.getPrice(underlyingTokenSymbol);

        emit PositionIncreased(user, positionId, size, lnPrices.getPrice(underlyingTokenSymbol), collateral, fees);

        _emitPositionSync(positionId);
    }

    function _addPositionSize(
        uint256 positionId,
        uint256 size,
        uint256 collateral
    ) private returns (uint256 fees) {
        Position storage position = positions[positionId];

        if (collateral > 0) {
            lusdToken.transferFrom(address(exchange), address(this), collateral);
            position.collateral = position.collateral.add(collateral);
        }

        uint256 underlyingValue = lnPrices.exchange(underlyingTokenSymbol, size, LUSD);

        fees = underlyingValue.mul(feeRate).div(UNIT);
        if (fees > 0) {
            position.collateral = position.collateral.sub(fees);

            lusdToken.approve(address(exchange), fees);
            exchange.submitFees(positionId, fees);
        }

        if (position.isLong) {
            // Long: borrow lUSD to buy underlying
            position.debt = position.debt.add(underlyingValue);
            position.locked = position.locked.add(size);

            totalUsdDebt = totalUsdDebt.add(underlyingValue);
            exchange.requestAssetMint(address(underlyingToken), address(this), size);
        } else {
            // Short: borrow underlying to sell into lUSD
            position.debt = position.debt.add(size);
            position.collateral = position.collateral.add(underlyingValue);

            totalUnderlyingDebt = totalUnderlyingDebt.add(size);
            exchange.requestAssetMint(address(lusdToken), address(this), underlyingValue);
        }

        _assertCollateralizationRatio(positionId);
    }

    function _addCollateral(
        address user,
        uint256 positionId,
        uint256 amount
    ) private {
        require(positions[positionId].debt > 0, "LnPerpetual: position not found");

        positions[positionId].collateral = positions[positionId].collateral.add(amount);

        lusdToken.transferFrom(user, address(this), amount);

        emit CollateralAdded(user, positionId, amount);

        _emitPositionSync(positionId);
    }

    function _removeCollateral(
        address user,
        uint256 positionId,
        uint256 amount,
        address to
    ) private {
        require(user == positionToken.ownerOf(positionId), "LnPerpetual: owner mismatch");

        require(positions[positionId].debt > 0, "LnPerpetual: position not found");

        positions[positionId].collateral = positions[positionId].collateral.sub(amount);

        _assertCollateralizationRatio(positionId);

        lusdToken.transfer(to, amount);

        emit CollateralRemoved(user, positionId, amount);

        _emitPositionSync(positionId);
    }

    function _closePositionByAmount(
        address user,
        uint256 positionId,
        uint256 amount,
        address to
    ) private returns (uint256 underlyingPrice) {
        require(user == positionToken.ownerOf(positionId), "LnPerpetual: owner mismatch");

        if (positions[positionId].isLong) {
            (, underlyingPrice, ) = _closeLongPosition(user, positionId, amount, to, false);
        } else {
            (, underlyingPrice, ) = _closeShortPosition(user, positionId, amount, to, false);
        }
    }

    // TODO: change to automatically calculate amount on-chain in a future iteration
    function _liquidatePosition(
        address liquidator,
        uint256 positionId,
        uint256 amount,
        address rewardTo
    ) private {
        require(
            _calculateCollateralizationRatio(positionId) < maintenanceMargin,
            "LnPerpetual: not lower than maintenance margin"
        );

        address positionOwner = positionToken.ownerOf(positionId);

        (uint256 fees, uint256 underlyingPrice, uint256 liquidatorReward) =
            positions[positionId].isLong
                ? _closeLongPosition(positionOwner, positionId, amount, positionOwner, true)
                : _closeShortPosition(positionOwner, positionId, amount, positionOwner, true);

        uint256 collateralizationRatioAfter = _calculateCollateralizationRatio(positionId);
        require(
            collateralizationRatioAfter >= maintenanceMargin && collateralizationRatioAfter <= minInitMargin,
            "LnPerpetual: invalid liquidation amount"
        );

        // No contribution is holder not set
        uint256 insuranceContribution =
            exchange.insuranceFundHolder() == address(0)
                ? 0
                : liquidatorReward.mul(insuranceFundContributionRatio).div(UNIT);
        liquidatorReward = liquidatorReward.sub(insuranceContribution);

        if (liquidatorReward > 0) {
            // This amount has already been deducted from position collateral
            lusdToken.transfer(rewardTo, liquidatorReward);
        }
        if (insuranceContribution > 0) {
            lusdToken.approve(address(exchange), insuranceContribution);
            exchange.submitInsuranceFund(positionId, insuranceContribution);
        }

        emit PoistionLiquidated(
            positionOwner,
            positionId,
            amount,
            underlyingPrice,
            liquidator,
            fees,
            liquidatorReward,
            insuranceContribution
        );
    }

    function _closeLongPosition(
        address user,
        uint256 positionId,
        uint256 amount,
        address to,
        bool isLiquidation
    )
        private
        returns (
            uint256 fees,
            uint256 underlyingPrice,
            uint256 liquidationReward
        )
    {
        Position memory position = positions[positionId];
        require(position.debt > 0, "LnPerpetual: position not found");

        if (amount == 0) {
            amount = position.locked;
        } else {
            require(amount <= position.locked, "LnPerpetual: amount too large");
        }

        // Repay debt proportionally
        uint256 debtToRepay = amount == position.locked ? position.debt : position.debt.mul(amount).div(position.locked);

        // Adjust total USD debt stat
        totalUsdDebt = totalUsdDebt.sub(debtToRepay);

        // Adjust position data in-memory
        position.debt = position.debt.sub(debtToRepay);
        position.locked = position.locked.sub(amount);

        // Sell underlying into lUSD for debt repayment
        uint256 sellProceeds = lnPrices.exchange(underlyingTokenSymbol, amount, LUSD);
        exchange.requestAssetBurn(address(underlyingToken), address(this), amount);

        // Calculate fees & liquidation reward (extra debt to repay)
        uint256 feesAndLiquidationReward = 0;
        {
            // Avg entry price would be effecitvely used if calculated based on `debtToRepay`
            fees = sellProceeds.mul(feeRate).div(UNIT);
            if (fees > 0) {
                feesAndLiquidationReward = feesAndLiquidationReward.add(fees);

                lusdToken.approve(address(exchange), fees);
                exchange.submitFees(positionId, fees);
            }

            if (isLiquidation) {
                liquidationReward = sellProceeds.mul(liquidatorRewardRatio).div(UNIT);
                feesAndLiquidationReward = feesAndLiquidationReward.add(liquidationReward);
            }
        }

        // Mint/burn the net difference
        if (sellProceeds > debtToRepay) {
            // Mint the difference to this contract
            exchange.requestAssetMint(address(lusdToken), address(this), sellProceeds.sub(debtToRepay));
        } else if (sellProceeds < debtToRepay) {
            // Burn the difference
            exchange.requestAssetBurn(address(lusdToken), address(this), debtToRepay.sub(sellProceeds));
        }

        // Trick: pretend more debt is to be repaid to account for fees and liquidation reward
        debtToRepay = debtToRepay.add(feesAndLiquidationReward);

        if (sellProceeds >= debtToRepay) {
            // Sell proceeds alone are enough to cover debt repayment. The leftover goes into collateral
            position.collateral = position.collateral.add(sellProceeds.sub(debtToRepay));
        } else {
            // Still some debt left after repayment with sell proceeds
            debtToRepay = debtToRepay.sub(sellProceeds);

            if (position.collateral >= debtToRepay) {
                // Collateral enough to repay the remaining amount
                position.collateral = position.collateral.sub(debtToRepay);
            } else {
                // A bankrupted position can only be liquidated
                require(false, "LnPerpetual: bankrupted position");
            }
        }

        underlyingPrice = lnPrices.getPrice(underlyingTokenSymbol);

        if (position.debt == 0 && position.locked == 0) {
            if (position.collateral > 0) {
                lusdToken.transfer(to, position.collateral);
            }

            if (!isLiquidation) {
                emit PositionClosed(user, positionId, amount, underlyingPrice, fees, position.collateral);
            }

            emit PositionSync(positionId, true, 0, 0, 0);

            // Position completely closed
            exchange.requestPositionBurn(positionId);
            delete positions[positionId];
        } else {
            // Position partically closed (PnL goes into collateral)
            positions[positionId].debt = position.debt;
            positions[positionId].locked = position.locked;
            positions[positionId].collateral = position.collateral;

            if (!isLiquidation) {
                emit PositionPartiallyClosed(user, positionId, amount, underlyingPrice, fees);
            }

            _emitPositionSync(positionId);
        }
    }

    function _closeShortPosition(
        address user,
        uint256 positionId,
        uint256 amount,
        address to,
        bool isLiquidation
    )
        private
        returns (
            uint256 fees,
            uint256 underlyingPrice,
            uint256 liquidationReward
        )
    {
        Position memory position = positions[positionId];
        require(position.debt > 0, "LnPerpetual: position not found");

        uint256 debtToRepay = amount == 0 ? position.debt : amount;
        require(debtToRepay <= position.debt, "LnPerpetual: amount too large");

        // Adjust total underlying debt stat
        totalUnderlyingDebt = totalUnderlyingDebt.sub(debtToRepay);

        // Buy underlying with lUSD
        uint256 lusdNeededToRepay = lnPrices.exchange(underlyingTokenSymbol, debtToRepay, LUSD);

        // Calculate fees & liquidation reward (extra debt to repay)
        uint256 feesAndLiquidationReward = 0;
        {
            fees = lusdNeededToRepay.mul(feeRate).div(UNIT);
            if (fees > 0) {
                feesAndLiquidationReward = feesAndLiquidationReward.add(fees);

                lusdToken.approve(address(exchange), fees);
                exchange.submitFees(positionId, fees);
            }

            if (isLiquidation) {
                liquidationReward = lusdNeededToRepay.mul(liquidatorRewardRatio).div(UNIT);
                feesAndLiquidationReward = feesAndLiquidationReward.add(liquidationReward);
            }
        }

        exchange.requestAssetBurn(address(lusdToken), address(this), lusdNeededToRepay);

        // Trick: pretend more lUSD is needed to repay the debt
        lusdNeededToRepay = lusdNeededToRepay.add(feesAndLiquidationReward);

        require(position.collateral >= lusdNeededToRepay, "LnPerpetual: bankrupted position");

        // Adjust position data in-memory (no SafeMath needed actually)
        position.debt = position.debt.sub(debtToRepay);
        position.collateral = position.collateral.sub(lusdNeededToRepay);

        underlyingPrice = lnPrices.getPrice(underlyingTokenSymbol);

        if (position.debt == 0) {
            if (position.collateral > 0) {
                lusdToken.transfer(to, position.collateral);
            }

            if (!isLiquidation) {
                emit PositionClosed(user, positionId, amount, underlyingPrice, fees, position.collateral);
            }

            emit PositionSync(positionId, false, 0, 0, 0);

            // Position completely closed
            exchange.requestPositionBurn(positionId);
            delete positions[positionId];
        } else {
            // Position partically closed (PnL goes into collateral)
            positions[positionId].debt = position.debt;
            positions[positionId].collateral = position.collateral;

            if (!isLiquidation) {
                emit PositionPartiallyClosed(user, positionId, amount, underlyingPrice, fees);
            }

            _emitPositionSync(positionId);
        }
    }

    // This function should only be called after position is updated since it reads from storage
    function _assertCollateralizationRatio(uint256 positionId) private view {
        require(_calculateCollateralizationRatio(positionId) >= minInitMargin, "LnPerpetual: min init margin not reached");
    }

    // This function should only be called after position is updated since it reads from storage
    function _calculateCollateralizationRatio(uint256 positionId) private view returns (uint256) {
        Position memory position = positions[positionId];
        require(position.debt > 0, "LnPerpetual: position not found");

        if (position.isLong) {
            // Long: collateralRatio = (collateral + locked * price) / debt - 1
            return
                position
                    .collateral
                    .add(lnPrices.exchange(underlyingTokenSymbol, position.locked, LUSD))
                    .mul(UNIT)
                    .div(position.debt)
                    .sub(UNIT);
        } else {
            // Short: collateralRatio = collateral / (debt * price) - 1
            return
                position.collateral.mul(UNIT).div(lnPrices.exchange(underlyingTokenSymbol, position.debt, LUSD)).sub(UNIT);
        }
    }

    function _emitPositionSync(uint256 positionId) private {
        Position memory position = positions[positionId];
        require(position.debt > 0, "LnPerpetual: position not found");

        emit PositionSync(positionId, position.isLong, position.debt, position.locked, position.collateral);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
pragma solidity >=0.6.12 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILnAsset is IERC20 {
    function keyName() external view returns (bytes32);

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function move(
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;

interface ILnPerpetual {
    function underlyingTokenSymbol() external view returns (bytes32);

    function totalUsdDebt() external view returns (uint256);

    function totalUnderlyingDebt() external view returns (uint256);

    function openPosition(
        address user,
        bool isLong,
        uint256 size,
        uint256 collateral
    ) external returns (uint256 positionId, uint256 underlyingPrice);

    function increasePosition(
        address user,
        uint256 positionId,
        uint256 size,
        uint256 collateral
    ) external returns (uint256 underlyingPrice);

    function closePositionByAmount(
        address user,
        uint256 positionId,
        uint256 amount,
        address to
    ) external returns (uint256 underlyingPrice);

    function closePosition(
        address user,
        uint256 positionId,
        address to
    ) external returns (uint256 underlyingPrice);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;

interface ILnPerpExchange {
    function insuranceFundHolder() external view returns (address);

    function submitFees(uint256 positionId, uint256 amount) external;

    function submitInsuranceFund(uint256 positionId, uint256 amount) external;

    function requestPositionMint(address to) external returns (uint256 positionId);

    function requestPositionBurn(uint256 positionId) external;

    function requestAssetMint(
        address asset,
        address account,
        uint256 amount
    ) external;

    function requestAssetBurn(
        address asset,
        address account,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface ILnPerpPositionToken is IERC721Upgradeable {
    function positionExists(address perpAddress, uint256 positionId) external view returns (bool);

    function mint(address perpAddress, address to) external returns (uint256 tokenId);

    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

interface ILnPrices {
    function getPrice(bytes32 currencyKey) external view returns (uint);

    function exchange(
        bytes32 sourceKey,
        uint sourceAmount,
        bytes32 destKey
    ) external view returns (uint);

    function LUSD() external view returns (bytes32);
}