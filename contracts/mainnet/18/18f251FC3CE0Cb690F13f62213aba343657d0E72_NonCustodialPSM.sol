// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import {Decimal} from "../external/Decimal.sol";
import {Constants} from "../Constants.sol";
import {OracleRef} from "./../refs/OracleRef.sol";
import {TribeRoles} from "./../core/TribeRoles.sol";
import {RateLimited} from "./../utils/RateLimited.sol";
import {IPCVDeposit, PCVDeposit} from "./../pcv/PCVDeposit.sol";
import {INonCustodialPSM} from "./INonCustodialPSM.sol";
import {GlobalRateLimitedMinter} from "./../utils/GlobalRateLimitedMinter.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice Peg Stability Module that holds no funds.
/// On a mint, it transfers all proceeds to a PCV Deposit
/// When funds are needed for a redemption, they are simply pulled from the PCV Deposit
contract NonCustodialPSM is
    OracleRef,
    RateLimited,
    ReentrancyGuard,
    INonCustodialPSM
{
    using Decimal for Decimal.D256;
    using SafeCast for *;
    using SafeERC20 for IERC20;

    /// @notice the fee in basis points for selling an asset into VOLT
    uint256 public override mintFeeBasisPoints;

    /// @notice the fee in basis points for buying the asset for VOLT
    uint256 public override redeemFeeBasisPoints;

    /// @notice the PCV deposit target to deposit and withdraw from
    IPCVDeposit public override pcvDeposit;

    /// @notice the token this PSM will exchange for VOLT
    /// Must be a stable token pegged to $1
    IERC20 public immutable override underlyingToken;

    /// @notice Rate Limited Minter contract that will be called when VOLT needs to be minted
    GlobalRateLimitedMinter public override rateLimitedMinter;

    /// @notice the max mint and redeem fee in basis points
    /// Governance cannot change the maximum fee
    uint256 public immutable override MAX_FEE = 300;

    /// @notice boolean switch that indicates whether redeeming is paused
    bool public redeemPaused;

    /// @notice boolean switch that indicates whether minting is paused
    bool public mintPaused;

    /// @notice struct for passing constructor parameters related to OracleRef
    struct OracleParams {
        address coreAddress;
        address oracleAddress;
        address backupOracle;
        int256 decimalsNormalizer;
    }

    /// @notice struct for passing constructor parameters related to MultiRateLimited
    struct RateLimitedParams {
        uint256 maxRateLimitPerSecond;
        uint256 rateLimitPerSecond;
        uint256 bufferCap;
    }

    /// @notice struct for passing constructor parameters related to the non custodial PSM
    struct PSMParams {
        uint256 mintFeeBasisPoints;
        uint256 redeemFeeBasisPoints;
        IERC20 underlyingToken;
        IPCVDeposit pcvDeposit;
        GlobalRateLimitedMinter rateLimitedMinter;
    }

    /// @notice construct the non custodial PSM. Structs are used to prevent stack too deep errors
    /// @param params oracle ref constructor data
    /// @param rateLimitedParams rate limited constructor data
    /// @param psmParams non custodial PSM constructor data
    constructor(
        OracleParams memory params,
        RateLimitedParams memory rateLimitedParams,
        PSMParams memory psmParams
    )
        OracleRef(
            params.coreAddress,
            params.oracleAddress,
            params.backupOracle,
            params.decimalsNormalizer,
            true /// hardcode doInvert to true to allow swaps to work correctly
        )
        /// rate limited replenishable passes false as the last param as there can be no partial actions
        RateLimited(
            rateLimitedParams.maxRateLimitPerSecond,
            rateLimitedParams.rateLimitPerSecond,
            rateLimitedParams.bufferCap,
            false
        )
    {
        underlyingToken = psmParams.underlyingToken;

        _setGlobalRateLimitedMinter(psmParams.rateLimitedMinter);
        _setMintFee(psmParams.mintFeeBasisPoints);
        _setRedeemFee(psmParams.redeemFeeBasisPoints);
        _setPCVDeposit(psmParams.pcvDeposit);
    }

    // ----------- Mint & Redeem pausing modifiers -----------

    /// @notice modifier that allows execution when redemptions are not paused
    modifier whileRedemptionsNotPaused() {
        require(!redeemPaused, "PegStabilityModule: Redeem paused");
        _;
    }

    /// @notice modifier that allows execution when minting is not paused
    modifier whileMintingNotPaused() {
        require(!mintPaused, "PegStabilityModule: Minting paused");
        _;
    }

    // ----------- Governor & Guardian only pausing api -----------

    /// @notice set secondary pausable methods to paused
    function pauseRedeem() external onlyGuardianOrGovernor {
        redeemPaused = true;
        emit RedemptionsPaused(msg.sender);
    }

    /// @notice set secondary pausable methods to unpaused
    function unpauseRedeem() external onlyGuardianOrGovernor {
        redeemPaused = false;
        emit RedemptionsUnpaused(msg.sender);
    }

    /// @notice set secondary pausable methods to paused
    function pauseMint() external onlyGuardianOrGovernor {
        mintPaused = true;
        emit MintingPaused(msg.sender);
    }

    /// @notice set secondary pausable methods to unpaused
    function unpauseMint() external onlyGuardianOrGovernor {
        mintPaused = false;
        emit MintingUnpaused(msg.sender);
    }

    // ----------- Governor, psm admin and parameter admin only state changing api -----------

    /// @notice set the mint fee vs oracle price in basis point terms
    /// @param newMintFeeBasisPoints the new fee in basis points for minting
    function setMintFee(uint256 newMintFeeBasisPoints)
        external
        override
        hasAnyOfTwoRoles(TribeRoles.GOVERNOR, TribeRoles.PARAMETER_ADMIN)
    {
        _setMintFee(newMintFeeBasisPoints);
    }

    /// @notice set the redemption fee vs oracle price in basis point terms
    /// @param newRedeemFeeBasisPoints the new fee in basis points for redemptions
    function setRedeemFee(uint256 newRedeemFeeBasisPoints)
        external
        override
        hasAnyOfTwoRoles(TribeRoles.GOVERNOR, TribeRoles.PARAMETER_ADMIN)
    {
        _setRedeemFee(newRedeemFeeBasisPoints);
    }

    /// @notice set the target for sending all PCV
    /// @param newTarget new PCV Deposit target for this PSM
    function setPCVDeposit(IPCVDeposit newTarget)
        external
        override
        hasAnyOfTwoRoles(TribeRoles.GOVERNOR, TribeRoles.PSM_ADMIN_ROLE)
    {
        _setPCVDeposit(newTarget);
    }

    /// @notice set the target to call for VOLT minting
    /// @param newMinter new Global Rate Limited Minter for this PSM
    function setGlobalRateLimitedMinter(GlobalRateLimitedMinter newMinter)
        external
        override
        hasAnyOfTwoRoles(TribeRoles.GOVERNOR, TribeRoles.PSM_ADMIN_ROLE)
    {
        _setGlobalRateLimitedMinter(newMinter);
    }

    // ----------- PCV Controller only state changing api -----------

    /// @notice withdraw ERC20 from the contract
    /// @param token address of the ERC20 to send
    /// @param to address destination of the ERC20
    /// @param amount quantity of ERC20 to send
    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external override onlyPCVController {
        IERC20(token).safeTransfer(to, amount);
        emit WithdrawERC20(msg.sender, token, to, amount);
    }

    // ----------- Public State Changing API -----------

    /// @notice function to redeem VOLT for an underlying asset
    /// We do not burn VOLT; this allows the contract's balance of VOLT to be used before the buffer is used
    /// In practice, this helps prevent artificial cycling of mint-burn cycles and prevents DOS attacks.
    /// This function will deplete the buffer based on the amount of VOLT that is being redeemed.
    /// @param to the destination address for proceeds
    /// @param amountVoltIn the amount of VOLT to sell
    /// @param minAmountOut the minimum amount out otherwise the TX will fail
    function redeem(
        address to,
        uint256 amountVoltIn,
        uint256 minAmountOut
    )
        external
        virtual
        override
        nonReentrant
        whenNotPaused
        whileRedemptionsNotPaused
        returns (uint256 amountOut)
    {
        _depleteBuffer(amountVoltIn); /// deplete buffer first to save gas on buffer exhaustion sad path

        updateOracle();

        amountOut = _getRedeemAmountOut(amountVoltIn);
        require(
            amountOut >= minAmountOut,
            "PegStabilityModule: Redeem not enough out"
        );

        IERC20(volt()).safeTransferFrom(
            msg.sender,
            address(this),
            amountVoltIn
        );

        pcvDeposit.withdraw(to, amountOut);

        emit Redeem(to, amountVoltIn, amountOut);
    }

    /// @notice function to buy VOLT for an underlying asset that is pegged to $1
    /// We first transfer any contract-owned VOLT, then mint the remaining if necessary
    /// This function will replenish the buffer based on the amount of VOLT that is being sent out.
    /// @param to the destination address for proceeds
    /// @param amountIn the amount of external asset to sell to the PSM
    /// @param minVoltAmountOut the minimum amount of VOLT out otherwise the TX will fail
    function mint(
        address to,
        uint256 amountIn,
        uint256 minVoltAmountOut
    )
        external
        virtual
        override
        nonReentrant
        whenNotPaused
        whileMintingNotPaused
        returns (uint256 amountVoltOut)
    {
        updateOracle();

        amountVoltOut = _getMintAmountOut(amountIn);
        require(
            amountVoltOut >= minVoltAmountOut,
            "PegStabilityModule: Mint not enough out"
        );

        underlyingToken.safeTransferFrom(
            msg.sender,
            address(pcvDeposit),
            amountIn
        );
        pcvDeposit.deposit();

        uint256 amountFeiToTransfer = Math.min(
            volt().balanceOf(address(this)),
            amountVoltOut
        );
        uint256 amountFeiToMint = amountVoltOut - amountFeiToTransfer;

        if (amountFeiToTransfer != 0) {
            IERC20(volt()).safeTransfer(to, amountFeiToTransfer);
        }

        if (amountFeiToMint != 0) {
            rateLimitedMinter.mintVolt(to, amountFeiToMint);
        }

        _replenishBuffer(amountVoltOut);

        emit Mint(to, amountIn, amountVoltOut);
    }

    // ----------- Public View-Only API ----------

    /// @notice calculate the amount of VOLT out for a given `amountIn` of underlying
    /// First get oracle price of token
    /// Then figure out how many dollars that amount in is worth by multiplying price * amount.
    /// ensure decimals are normalized if on underlying they are not 18
    /// @param amountIn the amount of external asset to sell to the PSM
    /// @return amountVoltOut the amount of VOLT received for the amountIn of external asset
    function getMintAmountOut(uint256 amountIn)
        public
        view
        override
        returns (uint256 amountVoltOut)
    {
        amountVoltOut = _getMintAmountOut(amountIn);
    }

    /// @notice calculate the amount of underlying out for a given `amountVoltIn` of VOLT
    /// First get oracle price of token
    /// Then figure out how many dollars that amount in is worth by multiplying price * amount.
    /// ensure decimals are normalized if on underlying they are not 18
    /// @param amountVoltIn the amount of VOLT to redeem
    /// @return amountTokenOut the amount of the external asset received in exchange for the amount of VOLT redeemed
    function getRedeemAmountOut(uint256 amountVoltIn)
        public
        view
        override
        returns (uint256 amountTokenOut)
    {
        amountTokenOut = _getRedeemAmountOut(amountVoltIn);
    }

    /// @notice getter to return the maximum amount of VOLT that could be purchased at once
    /// @return the maximum amount of VOLT available for purchase at once through this PSM
    function getMaxMintAmountOut() external view override returns (uint256) {
        return
            volt().balanceOf(address(this)) +
            rateLimitedMinter.individualBuffer(address(this));
    }

    // ----------- Internal Methods -----------

    /// @notice helper function to get mint amount out based on current market prices
    /// @dev will revert if price is outside of bounds and price bound PSM is being used
    /// @param amountIn the amount of stable asset in
    /// @return amountVoltOut the amount of VOLT received for the amountIn of stable assets
    function _getMintAmountOut(uint256 amountIn)
        internal
        view
        virtual
        returns (uint256 amountVoltOut)
    {
        Decimal.D256 memory price = readOracle();
        _validatePriceRange(price);

        Decimal.D256 memory adjustedAmountIn = price.mul(amountIn);

        amountVoltOut = adjustedAmountIn
            .mul(Constants.BASIS_POINTS_GRANULARITY - mintFeeBasisPoints)
            .div(Constants.BASIS_POINTS_GRANULARITY)
            .asUint256();
    }

    /// @notice helper function to get redeem amount out based on current market prices
    /// @dev will revert if price is outside of bounds and price bound PSM is being used
    /// @param amountVoltIn the amount of VOLT to redeem
    /// @return amountTokenOut the amount of the external asset received in exchange for the amount of VOLT redeemed
    function _getRedeemAmountOut(uint256 amountVoltIn)
        internal
        view
        virtual
        returns (uint256 amountTokenOut)
    {
        Decimal.D256 memory price = readOracle();
        _validatePriceRange(price);

        /// get amount of VOLT being provided being redeemed after fees
        Decimal.D256 memory adjustedAmountIn = Decimal.from(
            (amountVoltIn *
                (Constants.BASIS_POINTS_GRANULARITY - redeemFeeBasisPoints)) /
                Constants.BASIS_POINTS_GRANULARITY
        );

        /// now turn the VOLT into the underlying token amounts
        /// amount VOLT in / VOLT you receive for $1 = how much stable token to pay out
        amountTokenOut = adjustedAmountIn.div(price).asUint256();
    }

    // ----------- Helper methods to change state -----------

    /// @notice set the global rate limited minter this PSM calls to mint VOLT
    /// @param newMinter the new minter contract that this PSM will reference
    function _setGlobalRateLimitedMinter(GlobalRateLimitedMinter newMinter)
        internal
    {
        require(
            address(newMinter) != address(0),
            "PegStabilityModule: Invalid new GlobalRateLimitedMinter"
        );
        GlobalRateLimitedMinter oldMinter = rateLimitedMinter;
        rateLimitedMinter = newMinter;

        emit GlobalRateLimitedMinterUpdate(oldMinter, newMinter);
    }

    /// @notice set the mint fee vs oracle price in basis point terms
    /// @param newMintFeeBasisPoints the new fee for minting in basis points
    function _setMintFee(uint256 newMintFeeBasisPoints) internal {
        require(
            newMintFeeBasisPoints <= MAX_FEE,
            "PegStabilityModule: Mint fee exceeds max fee"
        );
        uint256 _oldMintFee = mintFeeBasisPoints;
        mintFeeBasisPoints = newMintFeeBasisPoints;

        emit MintFeeUpdate(_oldMintFee, newMintFeeBasisPoints);
    }

    /// @notice internal helper function to set the redemption fee
    /// @param newRedeemFeeBasisPoints the new fee for redemptions in basis points
    function _setRedeemFee(uint256 newRedeemFeeBasisPoints) internal {
        require(
            newRedeemFeeBasisPoints <= MAX_FEE,
            "PegStabilityModule: Redeem fee exceeds max fee"
        );
        uint256 _oldRedeemFee = redeemFeeBasisPoints;
        redeemFeeBasisPoints = newRedeemFeeBasisPoints;

        emit RedeemFeeUpdate(_oldRedeemFee, newRedeemFeeBasisPoints);
    }

    /// @notice helper function to set the PCV deposit
    /// @param newPCVDeposit the new PCV deposit that this PSM will pull assets from and deposit assets into
    function _setPCVDeposit(IPCVDeposit newPCVDeposit) internal {
        require(
            address(newPCVDeposit) != address(0),
            "PegStabilityModule: Invalid new PCVDeposit"
        );
        require(
            newPCVDeposit.balanceReportedIn() == address(underlyingToken),
            "PegStabilityModule: Underlying token mismatch"
        );
        IPCVDeposit oldTarget = pcvDeposit;
        pcvDeposit = newPCVDeposit;

        emit PCVDepositUpdate(oldTarget, newPCVDeposit);
    }

    // ----------- Hooks -----------

    /// @notice overriden function in the price bound PSM
    function _validatePriceRange(Decimal.D256 memory price)
        internal
        view
        virtual
    {}
}

/*
    Copyright 2019 dYdX Trading Inc.
    Copyright 2020 Empty Set Squad <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 private constant BASE = 10**18;

    // ============ Structs ============

    struct D256 {
        uint256 value;
    }

    // ============ Static Functions ============

    function zero() internal pure returns (D256 memory) {
        return D256({value: 0});
    }

    function one() internal pure returns (D256 memory) {
        return D256({value: BASE});
    }

    function from(uint256 a) internal pure returns (D256 memory) {
        return D256({value: a.mul(BASE)});
    }

    function ratio(uint256 a, uint256 b) internal pure returns (D256 memory) {
        return D256({value: getPartial(a, BASE, b)});
    }

    // ============ Self Functions ============

    function add(D256 memory self, uint256 b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: self.value.add(b.mul(BASE))});
    }

    function sub(D256 memory self, uint256 b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: self.value.sub(b.mul(BASE))});
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    ) internal pure returns (D256 memory) {
        return D256({value: self.value.sub(b.mul(BASE), reason)});
    }

    function mul(D256 memory self, uint256 b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: self.value.mul(b)});
    }

    function div(D256 memory self, uint256 b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: self.value.div(b)});
    }

    function pow(D256 memory self, uint256 b)
        internal
        pure
        returns (D256 memory)
    {
        if (b == 0) {
            return from(1);
        }

        D256 memory temp = D256({value: self.value});
        for (uint256 i = 1; i < b; i++) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(D256 memory self, D256 memory b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: self.value.add(b.value)});
    }

    function sub(D256 memory self, D256 memory b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: self.value.sub(b.value)});
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    ) internal pure returns (D256 memory) {
        return D256({value: self.value.sub(b.value, reason)});
    }

    function mul(D256 memory self, D256 memory b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: getPartial(self.value, b.value, BASE)});
    }

    function div(D256 memory self, D256 memory b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: getPartial(self.value, BASE, b.value)});
    }

    function equals(D256 memory self, D256 memory b)
        internal
        pure
        returns (bool)
    {
        return self.value == b.value;
    }

    function greaterThan(D256 memory self, D256 memory b)
        internal
        pure
        returns (bool)
    {
        return compareTo(self, b) == 2;
    }

    function lessThan(D256 memory self, D256 memory b)
        internal
        pure
        returns (bool)
    {
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(D256 memory self, D256 memory b)
        internal
        pure
        returns (bool)
    {
        return compareTo(self, b) > 0;
    }

    function lessThanOrEqualTo(D256 memory self, D256 memory b)
        internal
        pure
        returns (bool)
    {
        return compareTo(self, b) < 2;
    }

    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    // ============ Core Methods ============

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    ) private pure returns (uint256) {
        return target.mul(numerator).div(denominator);
    }

    function compareTo(D256 memory a, D256 memory b)
        private
        pure
        returns (uint256)
    {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {IWETH} from "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

library Constants {
    /// @notice the denominator for basis points granularity (10,000)
    uint256 public constant BASIS_POINTS_GRANULARITY = 10_000;

    /// @notice the denominator for basis points granularity (10,000) expressed as an int data type
    int256 public constant BP_INT = int256(BASIS_POINTS_GRANULARITY);

    uint256 public constant ONE_YEAR = 365.25 days;

    int256 public constant ONE_YEAR_INT = int256(ONE_YEAR);

    /// @notice WETH9 address
    IWETH public constant WETH =
        IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /// @notice USD stand-in address
    address public constant USD = 0x1111111111111111111111111111111111111111;

    /// @notice Wei per ETH, i.e. 10**18
    uint256 public constant ETH_GRANULARITY = 1e18;

    /// @notice number of decimals in ETH, 18
    uint256 public constant ETH_DECIMALS = 18;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IOracleRef.sol";
import "./CoreRef.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title Reference to an Oracle
/// @author Fei Protocol
/// @notice defines some utilities around interacting with the referenced oracle
abstract contract OracleRef is IOracleRef, CoreRef {
    using Decimal for Decimal.D256;
    using SafeCast for int256;

    /// @notice the oracle reference by the contract
    IOracle public override oracle;

    /// @notice the backup oracle reference by the contract
    IOracle public override backupOracle;

    /// @notice number of decimals to scale oracle price by, i.e. multiplying by 10^(decimalsNormalizer)
    int256 public override decimalsNormalizer;

    bool public override doInvert;

    /// @notice OracleRef constructor
    /// @param _core Fei Core to reference
    /// @param _oracle oracle to reference
    /// @param _backupOracle backup oracle to reference
    /// @param _decimalsNormalizer number of decimals to normalize the oracle feed if necessary
    /// @param _doInvert invert the oracle price if this flag is on
    constructor(
        address _core,
        address _oracle,
        address _backupOracle,
        int256 _decimalsNormalizer,
        bool _doInvert
    ) CoreRef(_core) {
        _setOracle(_oracle);
        if (_backupOracle != address(0) && _backupOracle != _oracle) {
            _setBackupOracle(_backupOracle);
        }
        _setDoInvert(_doInvert);
        _setDecimalsNormalizer(_decimalsNormalizer);
    }

    /// @notice sets the referenced oracle
    /// @param newOracle the new oracle to reference
    function setOracle(address newOracle) external override onlyGovernor {
        _setOracle(newOracle);
    }

    /// @notice sets the flag for whether to invert or not
    /// @param newDoInvert the new flag for whether to invert
    function setDoInvert(bool newDoInvert) external override onlyGovernor {
        _setDoInvert(newDoInvert);
    }

    /// @notice sets the new decimalsNormalizer
    /// @param newDecimalsNormalizer the new decimalsNormalizer
    function setDecimalsNormalizer(int256 newDecimalsNormalizer)
        external
        override
        onlyGovernor
    {
        _setDecimalsNormalizer(newDecimalsNormalizer);
    }

    /// @notice sets the referenced backup oracle
    /// @param newBackupOracle the new backup oracle to reference
    function setBackupOracle(address newBackupOracle)
        external
        override
        onlyGovernorOrAdmin
    {
        _setBackupOracle(newBackupOracle);
    }

    /// @notice invert a peg price
    /// @param price the peg price to invert
    /// @return the inverted peg as a Decimal
    /// @dev the inverted peg would be X per FEI
    function invert(Decimal.D256 memory price)
        public
        pure
        override
        returns (Decimal.D256 memory)
    {
        return Decimal.one().div(price);
    }

    /// @notice updates the referenced oracle
    function updateOracle() public override {
        oracle.update();
    }

    /// @notice the peg price of the referenced oracle
    /// @return the peg as a Decimal
    /// @dev the peg is defined as FEI per X with X being ETH, dollars, etc
    function readOracle() public view override returns (Decimal.D256 memory) {
        (Decimal.D256 memory _peg, bool valid) = oracle.read();
        if (!valid && address(backupOracle) != address(0)) {
            (_peg, valid) = backupOracle.read();
        }
        require(valid, "OracleRef: oracle invalid");

        // Scale the oracle price by token decimals delta if necessary
        uint256 scalingFactor;
        if (decimalsNormalizer < 0) {
            scalingFactor = 10**(-1 * decimalsNormalizer).toUint256();
            _peg = _peg.div(scalingFactor);
        } else {
            scalingFactor = 10**decimalsNormalizer.toUint256();
            _peg = _peg.mul(scalingFactor);
        }

        // Invert the oracle price if necessary
        if (doInvert) {
            _peg = invert(_peg);
        }
        return _peg;
    }

    function _setOracle(address newOracle) internal {
        require(newOracle != address(0), "OracleRef: zero address");
        address oldOracle = address(oracle);
        oracle = IOracle(newOracle);
        emit OracleUpdate(oldOracle, newOracle);
    }

    // Supports zero address if no backup
    function _setBackupOracle(address newBackupOracle) internal {
        address oldBackupOracle = address(backupOracle);
        backupOracle = IOracle(newBackupOracle);
        emit BackupOracleUpdate(oldBackupOracle, newBackupOracle);
    }

    function _setDoInvert(bool newDoInvert) internal {
        bool oldDoInvert = doInvert;
        doInvert = newDoInvert;

        if (oldDoInvert != newDoInvert) {
            _setDecimalsNormalizer(-1 * decimalsNormalizer);
        }

        emit InvertUpdate(oldDoInvert, newDoInvert);
    }

    function _setDecimalsNormalizer(int256 newDecimalsNormalizer) internal {
        int256 oldDecimalsNormalizer = decimalsNormalizer;
        decimalsNormalizer = newDecimalsNormalizer;
        emit DecimalsNormalizerUpdate(
            oldDecimalsNormalizer,
            newDecimalsNormalizer
        );
    }

    function _setDecimalsNormalizerFromToken(address token) internal {
        int256 feiDecimals = 18;
        int256 _decimalsNormalizer = feiDecimals -
            int256(uint256(IERC20Metadata(token).decimals()));

        if (doInvert) {
            _decimalsNormalizer = -1 * _decimalsNormalizer;
        }

        _setDecimalsNormalizer(_decimalsNormalizer);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/**
 @title Tribe DAO ACL Roles
 @notice Holds a complete list of all roles which can be held by contracts inside Tribe DAO.
         Roles are broken up into 3 categories:
         * Major Roles - the most powerful roles in the Tribe DAO which should be carefully managed.
         * Admin Roles - roles with management capability over critical functionality. Should only be held by automated or optimistic mechanisms
         * Minor Roles - operational roles. May be held or managed by shorter optimistic timelocks or trusted multisigs.
 */
library TribeRoles {
    /*///////////////////////////////////////////////////////////////
                                 Major Roles
    //////////////////////////////////////////////////////////////*/

    /// @notice the ultimate role of Tribe. Controls all other roles and protocol functionality.
    bytes32 internal constant GOVERNOR = keccak256("GOVERN_ROLE");

    /// @notice the protector role of Tribe. Admin of pause, veto, revoke, and minor roles
    bytes32 internal constant GUARDIAN = keccak256("GUARDIAN_ROLE");

    /// @notice the role which can arbitrarily move PCV in any size from any contract
    bytes32 internal constant PCV_CONTROLLER = keccak256("PCV_CONTROLLER_ROLE");

    /// @notice can mint FEI arbitrarily
    bytes32 internal constant MINTER = keccak256("MINTER_ROLE");

    /*///////////////////////////////////////////////////////////////
                                 Admin Roles
    //////////////////////////////////////////////////////////////*/

    /// @notice can manage the majority of Tribe protocol parameters. Sets boundaries for MINOR_PARAM_ROLE.
    bytes32 internal constant PARAMETER_ADMIN = keccak256("PARAMETER_ADMIN");

    /// @notice manages the Collateralization Oracle as well as other protocol oracles.
    bytes32 internal constant ORACLE_ADMIN = keccak256("ORACLE_ADMIN_ROLE");

    /// @notice manages TribalChief incentives and related functionality.
    bytes32 internal constant TRIBAL_CHIEF_ADMIN =
        keccak256("TRIBAL_CHIEF_ADMIN_ROLE");

    /// @notice admin of PCVGuardian
    bytes32 internal constant PCV_GUARDIAN_ADMIN =
        keccak256("PCV_GUARDIAN_ADMIN_ROLE");

    /// @notice admin of all Minor Roles
    bytes32 internal constant MINOR_ROLE_ADMIN = keccak256("MINOR_ROLE_ADMIN");

    /// @notice admin of the Fuse protocol
    bytes32 internal constant FUSE_ADMIN = keccak256("FUSE_ADMIN");

    /// @notice capable of vetoing DAO votes or optimistic timelocks
    bytes32 internal constant VETO_ADMIN = keccak256("VETO_ADMIN");

    /// @notice capable of setting FEI Minters within global rate limits and caps
    bytes32 internal constant MINTER_ADMIN = keccak256("MINTER_ADMIN");

    /// @notice manages the constituents of Optimistic Timelocks, including Proposers and Executors
    bytes32 internal constant OPTIMISTIC_ADMIN = keccak256("OPTIMISTIC_ADMIN");

    /*///////////////////////////////////////////////////////////////
                                 Minor Roles
    //////////////////////////////////////////////////////////////*/

    /// @notice capable of poking existing LBP auctions to exchange tokens.
    bytes32 internal constant LBP_SWAP_ROLE = keccak256("SWAP_ADMIN_ROLE");

    /// @notice capable of engaging with Votium for voting incentives.
    bytes32 internal constant VOTIUM_ROLE = keccak256("VOTIUM_ADMIN_ROLE");

    /// @notice capable of changing parameters within non-critical ranges
    bytes32 internal constant MINOR_PARAM_ROLE = keccak256("MINOR_PARAM_ROLE");

    /// @notice capable of adding an address to multi rate limited
    bytes32 internal constant ADD_MINTER_ROLE = keccak256("ADD_MINTER_ROLE");

    /// @notice capable of changing PCV Deposit and Global Rate Limited Minter in the PSM
    bytes32 internal constant PSM_ADMIN_ROLE = keccak256("PSM_ADMIN_ROLE");
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../refs/CoreRef.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @title abstract contract for putting a rate limit on how fast a contract can perform an action e.g. Minting
/// @author Fei Protocol
abstract contract RateLimited is CoreRef {
    /// @notice maximum rate limit per second governance can set for this contract
    uint256 public immutable MAX_RATE_LIMIT_PER_SECOND;

    /// @notice the rate per second for this contract
    uint256 public rateLimitPerSecond;

    /// @notice the last time the buffer was used by the contract
    uint256 public lastBufferUsedTime;

    /// @notice the cap of the buffer that can be used at once
    uint256 public bufferCap;

    /// @notice a flag for whether to allow partial actions to complete if the buffer is less than amount
    bool public doPartialAction;

    /// @notice the buffer at the timestamp of lastBufferUsedTime
    uint256 public bufferStored;

    event BufferUsed(uint256 amountUsed, uint256 bufferRemaining);
    event BufferCapUpdate(uint256 oldBufferCap, uint256 newBufferCap);
    event RateLimitPerSecondUpdate(
        uint256 oldRateLimitPerSecond,
        uint256 newRateLimitPerSecond
    );

    constructor(
        uint256 _maxRateLimitPerSecond,
        uint256 _rateLimitPerSecond,
        uint256 _bufferCap,
        bool _doPartialAction
    ) {
        lastBufferUsedTime = block.timestamp;

        _setBufferCap(_bufferCap);
        bufferStored = _bufferCap;

        require(
            _rateLimitPerSecond <= _maxRateLimitPerSecond,
            "RateLimited: rateLimitPerSecond too high"
        );
        _setRateLimitPerSecond(_rateLimitPerSecond);

        MAX_RATE_LIMIT_PER_SECOND = _maxRateLimitPerSecond;
        doPartialAction = _doPartialAction;
    }

    /// @notice set the rate limit per second
    function setRateLimitPerSecond(uint256 newRateLimitPerSecond)
        external
        virtual
        onlyGovernorOrAdmin
    {
        require(
            newRateLimitPerSecond <= MAX_RATE_LIMIT_PER_SECOND,
            "RateLimited: rateLimitPerSecond too high"
        );
        _updateBufferStored();

        _setRateLimitPerSecond(newRateLimitPerSecond);
    }

    /// @notice set the buffer cap
    function setBufferCap(uint256 newBufferCap)
        external
        virtual
        onlyGovernorOrAdmin
    {
        _setBufferCap(newBufferCap);
    }

    /// @notice the amount of action used before hitting limit
    /// @dev replenishes at rateLimitPerSecond per second up to bufferCap
    function buffer() public view returns (uint256) {
        uint256 elapsed = block.timestamp - lastBufferUsedTime;
        return
            Math.min(bufferStored + (rateLimitPerSecond * elapsed), bufferCap);
    }

    /** 
        @notice the method that enforces the rate limit. Decreases buffer by "amount". 
        If buffer is <= amount either
        1. Does a partial mint by the amount remaining in the buffer or
        2. Reverts
        Depending on whether doPartialAction is true or false
    */
    function _depleteBuffer(uint256 amount) internal virtual returns (uint256) {
        uint256 newBuffer = buffer();

        uint256 usedAmount = amount;
        if (doPartialAction && usedAmount > newBuffer) {
            usedAmount = newBuffer;
        }

        require(newBuffer != 0, "RateLimited: no rate limit buffer");
        require(usedAmount <= newBuffer, "RateLimited: rate limit hit");

        bufferStored = newBuffer - usedAmount;

        lastBufferUsedTime = block.timestamp;

        emit BufferUsed(usedAmount, bufferStored);

        return usedAmount;
    }

    /// @notice function to replenish buffer
    /// @param amount to increase buffer by if under buffer cap
    function _replenishBuffer(uint256 amount) internal {
        uint256 newBuffer = buffer();

        uint256 _bufferCap = bufferCap; /// gas opti, save an SLOAD

        /// cannot replenish any further if already at buffer cap
        if (newBuffer == _bufferCap) {
            return;
        }

        lastBufferUsedTime = block.timestamp;

        /// ensure that bufferStored cannot be gt buffer cap
        bufferStored = Math.min(newBuffer + amount, _bufferCap);
    }

    function _setRateLimitPerSecond(uint256 newRateLimitPerSecond) internal {
        uint256 oldRateLimitPerSecond = rateLimitPerSecond;
        rateLimitPerSecond = newRateLimitPerSecond;

        emit RateLimitPerSecondUpdate(
            oldRateLimitPerSecond,
            newRateLimitPerSecond
        );
    }

    function _setBufferCap(uint256 newBufferCap) internal {
        _updateBufferStored();

        uint256 oldBufferCap = bufferCap;
        bufferCap = newBufferCap;

        emit BufferCapUpdate(oldBufferCap, newBufferCap);
    }

    function _resetBuffer() internal {
        bufferStored = bufferCap;
    }

    function _updateBufferStored() internal {
        bufferStored = buffer();
        lastBufferUsedTime = block.timestamp;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../refs/CoreRef.sol";
import "./IPCVDeposit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title abstract contract for withdrawing ERC-20 tokens using a PCV Controller
/// @author Fei Protocol
abstract contract PCVDeposit is IPCVDeposit, CoreRef {
    using SafeERC20 for IERC20;

    /// @notice withdraw ERC20 from the contract
    /// @param token address of the ERC20 to send
    /// @param to address destination of the ERC20
    /// @param amount quantity of ERC20 to send
    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) public virtual override onlyPCVController {
        _withdrawERC20(token, to, amount);
    }

    function _withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) internal {
        IERC20(token).safeTransfer(to, amount);
        emit WithdrawERC20(msg.sender, token, to, amount);
    }

    /// @notice withdraw ETH from the contract
    /// @param to address to send ETH
    /// @param amountOut amount of ETH to send
    function withdrawETH(address payable to, uint256 amountOut)
        external
        virtual
        override
        onlyPCVController
    {
        Address.sendValue(to, amountOut);
        emit WithdrawETH(msg.sender, to, amountOut);
    }

    function balance() public view virtual override returns (uint256);

    function resistantBalanceAndVolt()
        public
        view
        virtual
        override
        returns (uint256, uint256)
    {
        return (balance(), 0);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPCVDeposit} from "../pcv/IPCVDeposit.sol";
import {GlobalRateLimitedMinter} from "../utils/GlobalRateLimitedMinter.sol";

/**
 * @title Fei Peg Stability Module
 * @author Fei Protocol
 * @notice  The Fei PSM is a contract which pulls reserve assets from PCV Deposits in order to exchange FEI at $1 of underlying assets with a fee.
 * `mint()` - buy FEI for $1 of underlying tokens
 * `redeem()` - sell FEI back for $1 of the same
 *
 *
 * The contract is a
 * OracleRef - to determine price of underlying, and
 * RateLimitedReplenishable - to stop infinite mints and related DOS issues
 *
 * Inspired by MakerDAO PSM, code written without reference
 */
interface INonCustodialPSM {
    // ----------- Public State Changing API -----------

    /// @notice mint `amountFeiOut` FEI to address `to` for `amountIn` underlying tokens
    /// @dev see getMintAmountOut() to pre-calculate amount out
    function mint(
        address to,
        uint256 amountIn,
        uint256 minAmountOut
    ) external returns (uint256 amountFeiOut);

    /// @notice redeem `amountFeiIn` FEI for `amountOut` underlying tokens and send to address `to`
    /// @dev see getRedeemAmountOut() to pre-calculate amount out
    function redeem(
        address to,
        uint256 amountFeiIn,
        uint256 minAmountOut
    ) external returns (uint256 amountOut);

    // ----------- Governor or Admin Only State Changing API -----------

    /// @notice set the mint fee vs oracle price in basis point terms
    function setMintFee(uint256 newMintFeeBasisPoints) external;

    /// @notice set the redemption fee vs oracle price in basis point terms
    function setRedeemFee(uint256 newRedeemFeeBasisPoints) external;

    /// @notice set the target for sending surplus reserves
    function setPCVDeposit(IPCVDeposit newTarget) external;

    /// @notice set the target to call for FEI minting
    function setGlobalRateLimitedMinter(GlobalRateLimitedMinter newMinter)
        external;

    /// @notice withdraw ERC20 from the contract
    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external;

    // ----------- Getters -----------

    /// @notice calculate the amount of FEI out for a given `amountIn` of underlying
    function getMintAmountOut(uint256 amountIn)
        external
        view
        returns (uint256 amountFeiOut);

    /// @notice calculate the amount of underlying out for a given `amountFeiIn` of FEI
    function getRedeemAmountOut(uint256 amountFeiIn)
        external
        view
        returns (uint256 amountOut);

    /// @notice the maximum mint amount out
    function getMaxMintAmountOut() external view returns (uint256);

    /// @notice the mint fee vs oracle price in basis point terms
    function mintFeeBasisPoints() external view returns (uint256);

    /// @notice the redemption fee vs oracle price in basis point terms
    function redeemFeeBasisPoints() external view returns (uint256);

    /// @notice the underlying token exchanged for FEI
    function underlyingToken() external view returns (IERC20);

    /// @notice the PCV deposit target to deposit and withdraw from
    function pcvDeposit() external view returns (IPCVDeposit);

    /// @notice Rate Limited Minter contract that will be called when FEI needs to be minted
    function rateLimitedMinter()
        external
        view
        returns (GlobalRateLimitedMinter);

    /// @notice the max mint and redeem fee in basis points
    function MAX_FEE() external view returns (uint256);

    // ----------- Events -----------

    /// @notice event emitted when a new max fee is set
    event MaxFeeUpdate(uint256 oldMaxFee, uint256 newMaxFee);

    /// @notice event emitted when a new mint fee is set
    event MintFeeUpdate(uint256 oldMintFee, uint256 newMintFee);

    /// @notice event emitted when a new redeem fee is set
    event RedeemFeeUpdate(uint256 oldRedeemFee, uint256 newRedeemFee);

    /// @notice event emitted when reservesThreshold is updated
    event ReservesThresholdUpdate(
        uint256 oldReservesThreshold,
        uint256 newReservesThreshold
    );

    /// @notice event emitted when surplus target is updated
    event PCVDepositUpdate(IPCVDeposit oldTarget, IPCVDeposit newTarget);

    /// @notice event emitted upon a redemption
    event Redeem(address to, uint256 amountFeiIn, uint256 amountAssetOut);

    /// @notice event emitted when fei gets minted
    event Mint(address to, uint256 amountIn, uint256 amountFeiOut);

    /// @notice event emitted when ERC20 tokens get withdrawn
    event WithdrawERC20(
        address indexed _caller,
        address indexed _token,
        address indexed _to,
        uint256 _amount
    );

    /// @notice event emitted when global rate limited minter is updated
    event GlobalRateLimitedMinterUpdate(
        GlobalRateLimitedMinter oldMinter,
        GlobalRateLimitedMinter newMinter
    );

    /// @notice event that is emitted when redemptions are paused
    event RedemptionsPaused(address account);

    /// @notice event that is emitted when redemptions are unpaused
    event RedemptionsUnpaused(address account);

    /// @notice event that is emitted when minting is paused
    event MintingPaused(address account);

    /// @notice event that is emitted when minting is unpaused
    event MintingUnpaused(address account);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import {MultiRateLimited} from "./MultiRateLimited.sol";
import {IGlobalRateLimitedMinter} from "./IGlobalRateLimitedMinter.sol";
import {CoreRef} from "./../refs/CoreRef.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @notice global contract to handle rate limited minting of VOLT on a global level
/// allows whitelisted minters to call in and specify the address to mint VOLT to within
/// that contract's limits
contract GlobalRateLimitedMinter is MultiRateLimited, IGlobalRateLimitedMinter {
    /// @param coreAddress address of the core contract
    /// @param _globalMaxRateLimitPerSecond maximum amount of VOLT that can replenish per second ever, this amount cannot be changed by governance
    /// @param _perAddressRateLimitMaximum maximum rate limit per second per address
    /// @param _maxRateLimitPerSecondPerAddress maximum rate limit per second per address in multi rate limited
    /// @param _maxBufferCap maximum buffer cap in multi rate limited contract
    /// @param _globalBufferCap maximum global buffer cap
    constructor(
        address coreAddress,
        uint256 _globalMaxRateLimitPerSecond,
        uint256 _perAddressRateLimitMaximum,
        uint256 _maxRateLimitPerSecondPerAddress,
        uint256 _maxBufferCap,
        uint256 _globalBufferCap
    )
        CoreRef(coreAddress)
        MultiRateLimited(
            _globalMaxRateLimitPerSecond,
            _perAddressRateLimitMaximum,
            _maxRateLimitPerSecondPerAddress,
            _maxBufferCap,
            _globalBufferCap
        )
    {}

    /// @notice mint VOLT to the target address and deplete the buffer
    /// pausable and depletes the msg.sender's buffer
    /// @param to the recipient address of the minted VOLT
    /// @param amount the amount of VOLT to mint
    function mintVolt(address to, uint256 amount)
        external
        virtual
        override
        whenNotPaused
    {
        _depleteIndividualBuffer(msg.sender, amount);
        _mintVolt(to, amount);
    }

    /// @notice mint VOLT to the target address and deplete the whole rate limited
    ///  minter's buffer, pausable and completely depletes the msg.sender's buffer
    /// @param to the recipient address of the minted VOLT
    /// mints all VOLT that msg.sender has in the buffer
    function mintMaxAllowableVolt(address to)
        external
        virtual
        override
        whenNotPaused
    {
        uint256 amount = Math.min(individualBuffer(msg.sender), buffer());

        _depleteIndividualBuffer(msg.sender, amount);
        _mintVolt(to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../oracle/IOracle.sol";

/// @title OracleRef interface
/// @author Fei Protocol
interface IOracleRef {
    // ----------- Events -----------

    event OracleUpdate(address indexed oldOracle, address indexed newOracle);

    event InvertUpdate(bool oldDoInvert, bool newDoInvert);

    event DecimalsNormalizerUpdate(
        int256 oldDecimalsNormalizer,
        int256 newDecimalsNormalizer
    );

    event BackupOracleUpdate(
        address indexed oldBackupOracle,
        address indexed newBackupOracle
    );

    // ----------- State changing API -----------

    function updateOracle() external;

    // ----------- Governor only state changing API -----------

    function setOracle(address newOracle) external;

    function setBackupOracle(address newBackupOracle) external;

    function setDecimalsNormalizer(int256 newDecimalsNormalizer) external;

    function setDoInvert(bool newDoInvert) external;

    // ----------- Getters -----------

    function oracle() external view returns (IOracle);

    function backupOracle() external view returns (IOracle);

    function doInvert() external view returns (bool);

    function decimalsNormalizer() external view returns (int256);

    function readOracle() external view returns (Decimal.D256 memory);

    function invert(Decimal.D256 calldata price)
        external
        pure
        returns (Decimal.D256 memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./ICoreRef.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title A Reference to Core
/// @author Fei Protocol
/// @notice defines some modifiers and utilities around interacting with Core
abstract contract CoreRef is ICoreRef, Pausable {
    ICore private immutable _core;
    IVolt private immutable _volt;
    IERC20 private immutable _vcon;

    /// @notice a role used with a subset of governor permissions for this contract only
    bytes32 public override CONTRACT_ADMIN_ROLE;

    constructor(address coreAddress) {
        _core = ICore(coreAddress);

        _volt = ICore(coreAddress).volt();
        _vcon = ICore(coreAddress).vcon();

        _setContractAdminRole(ICore(coreAddress).GOVERN_ROLE());
    }

    function _initialize() internal {} // no-op for backward compatibility

    modifier ifMinterSelf() {
        if (_core.isMinter(address(this))) {
            _;
        }
    }

    modifier onlyMinter() {
        require(_core.isMinter(msg.sender), "CoreRef: Caller is not a minter");
        _;
    }

    modifier onlyBurner() {
        require(_core.isBurner(msg.sender), "CoreRef: Caller is not a burner");
        _;
    }

    modifier onlyPCVController() {
        require(
            _core.isPCVController(msg.sender),
            "CoreRef: Caller is not a PCV controller"
        );
        _;
    }

    modifier onlyGovernorOrAdmin() {
        require(
            _core.isGovernor(msg.sender) || isContractAdmin(msg.sender),
            "CoreRef: Caller is not a governor or contract admin"
        );
        _;
    }

    modifier onlyGovernor() {
        require(
            _core.isGovernor(msg.sender),
            "CoreRef: Caller is not a governor"
        );
        _;
    }

    modifier onlyGuardianOrGovernor() {
        require(
            _core.isGovernor(msg.sender) || _core.isGuardian(msg.sender),
            "CoreRef: Caller is not a guardian or governor"
        );
        _;
    }

    modifier onlyGovernorOrGuardianOrAdmin() {
        require(
            _core.isGovernor(msg.sender) ||
                _core.isGuardian(msg.sender) ||
                isContractAdmin(msg.sender),
            "CoreRef: Caller is not governor or guardian or admin"
        );
        _;
    }

    // Named onlyTribeRole to prevent collision with OZ onlyRole modifier
    modifier onlyTribeRole(bytes32 role) {
        require(_core.hasRole(role, msg.sender), "UNAUTHORIZED");
        _;
    }

    // Modifiers to allow any combination of roles
    modifier hasAnyOfTwoRoles(bytes32 role1, bytes32 role2) {
        require(
            _core.hasRole(role1, msg.sender) ||
                _core.hasRole(role2, msg.sender),
            "UNAUTHORIZED"
        );
        _;
    }

    modifier hasAnyOfThreeRoles(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3
    ) {
        require(
            _core.hasRole(role1, msg.sender) ||
                _core.hasRole(role2, msg.sender) ||
                _core.hasRole(role3, msg.sender),
            "UNAUTHORIZED"
        );
        _;
    }

    modifier hasAnyOfFourRoles(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3,
        bytes32 role4
    ) {
        require(
            _core.hasRole(role1, msg.sender) ||
                _core.hasRole(role2, msg.sender) ||
                _core.hasRole(role3, msg.sender) ||
                _core.hasRole(role4, msg.sender),
            "UNAUTHORIZED"
        );
        _;
    }

    modifier hasAnyOfFiveRoles(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3,
        bytes32 role4,
        bytes32 role5
    ) {
        require(
            _core.hasRole(role1, msg.sender) ||
                _core.hasRole(role2, msg.sender) ||
                _core.hasRole(role3, msg.sender) ||
                _core.hasRole(role4, msg.sender) ||
                _core.hasRole(role5, msg.sender),
            "UNAUTHORIZED"
        );
        _;
    }

    modifier onlyVolt() {
        require(msg.sender == address(_volt), "CoreRef: Caller is not VOLT");
        _;
    }

    /// @notice sets a new admin role for this contract
    function setContractAdminRole(bytes32 newContractAdminRole)
        external
        override
        onlyGovernor
    {
        _setContractAdminRole(newContractAdminRole);
    }

    /// @notice returns whether a given address has the admin role for this contract
    function isContractAdmin(address _admin)
        public
        view
        override
        returns (bool)
    {
        return _core.hasRole(CONTRACT_ADMIN_ROLE, _admin);
    }

    /// @notice set pausable methods to paused
    function pause() public override onlyGuardianOrGovernor {
        _pause();
    }

    /// @notice set pausable methods to unpaused
    function unpause() public override onlyGuardianOrGovernor {
        _unpause();
    }

    /// @notice address of the Core contract referenced
    /// @return ICore implementation address
    function core() public view override returns (ICore) {
        return _core;
    }

    /// @notice address of the Fei contract referenced by Core
    /// @return IFei implementation address
    function volt() public view override returns (IVolt) {
        return _volt;
    }

    /// @notice address of the Tribe contract referenced by Core
    /// @return IERC20 implementation address
    function vcon() public view override returns (IERC20) {
        return _vcon;
    }

    /// @notice volt balance of contract
    /// @return volt amount held
    function voltBalance() public view override returns (uint256) {
        return _volt.balanceOf(address(this));
    }

    /// @notice vcon balance of contract
    /// @return vcon amount held
    function vconBalance() public view override returns (uint256) {
        return _vcon.balanceOf(address(this));
    }

    function _burnVoltHeld() internal {
        _volt.burn(voltBalance());
    }

    function _mintVolt(address to, uint256 amount) internal virtual {
        if (amount != 0) {
            _volt.mint(to, amount);
        }
    }

    function _setContractAdminRole(bytes32 newContractAdminRole) internal {
        bytes32 oldContractAdminRole = CONTRACT_ADMIN_ROLE;
        CONTRACT_ADMIN_ROLE = newContractAdminRole;
        emit ContractAdminRoleUpdate(
            oldContractAdminRole,
            newContractAdminRole
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../external/Decimal.sol";

/// @title generic oracle interface for Fei Protocol
/// @author Fei Protocol
interface IOracle {
    // ----------- Events -----------

    event Update(uint256 _peg);

    // ----------- State changing API -----------

    function update() external;

    // ----------- Getters -----------

    function read() external view returns (Decimal.D256 memory, bool);

    function isOutdated() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../core/ICore.sol";

/// @title CoreRef interface
/// @author Fei Protocol
interface ICoreRef {
    // ----------- Events -----------

    event CoreUpdate(address indexed oldCore, address indexed newCore);

    event ContractAdminRoleUpdate(
        bytes32 indexed oldContractAdminRole,
        bytes32 indexed newContractAdminRole
    );

    // ----------- Governor only state changing api -----------

    function setContractAdminRole(bytes32 newContractAdminRole) external;

    // ----------- Governor or Guardian only state changing api -----------

    function pause() external;

    function unpause() external;

    // ----------- Getters -----------

    function core() external view returns (ICore);

    function volt() external view returns (IVolt);

    function vcon() external view returns (IERC20);

    function voltBalance() external view returns (uint256);

    function vconBalance() external view returns (uint256);

    function CONTRACT_ADMIN_ROLE() external view returns (bytes32);

    function isContractAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import {IPermissions} from "./IPermissions.sol";
import {IVolt, IERC20} from "../volt/IVolt.sol";

/// @title Core Interface
/// @author Fei Protocol
interface ICore is IPermissions {
    // ----------- Events -----------
    event VoltUpdate(IERC20 indexed _volt);
    event VconUpdate(IERC20 indexed _vcon);

    // ----------- Getters -----------

    function volt() external view returns (IVolt);

    function vcon() external view returns (IERC20);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IPermissionsRead.sol";

/// @title Permissions interface
/// @author Fei Protocol
interface IPermissions is IAccessControl, IPermissionsRead {
    // ----------- Governor only state changing api -----------

    function createRole(bytes32 role, bytes32 adminRole) external;

    function grantMinter(address minter) external;

    function grantBurner(address burner) external;

    function grantPCVController(address pcvController) external;

    function grantGovernor(address governor) external;

    function grantGuardian(address guardian) external;

    function revokeMinter(address minter) external;

    function revokeBurner(address burner) external;

    function revokePCVController(address pcvController) external;

    function revokeGovernor(address governor) external;

    function revokeGuardian(address guardian) external;

    // ----------- Revoker only state changing api -----------

    function revokeOverride(bytes32 role, address account) external;

    // ----------- Getters -----------

    function GUARDIAN_ROLE() external view returns (bytes32);

    function GOVERN_ROLE() external view returns (bytes32);

    function BURNER_ROLE() external view returns (bytes32);

    function MINTER_ROLE() external view returns (bytes32);

    function PCV_CONTROLLER_ROLE() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title FEI stablecoin interface
/// @author Fei Protocol
interface IVolt is IERC20 {
    // ----------- Events -----------

    event Minting(
        address indexed _to,
        address indexed _minter,
        uint256 _amount
    );

    event Burning(
        address indexed _to,
        address indexed _burner,
        uint256 _amount
    );

    event IncentiveContractUpdate(
        address indexed _incentivized,
        address indexed _incentiveContract
    );

    // ----------- State changing api -----------

    function burn(uint256 amount) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // ----------- Minter only state changing api -----------

    function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title Permissions Read interface
/// @author Fei Protocol
interface IPermissionsRead {
    // ----------- Getters -----------

    function isBurner(address _address) external view returns (bool);

    function isMinter(address _address) external view returns (bool);

    function isGovernor(address _address) external view returns (bool);

    function isGuardian(address _address) external view returns (bool);

    function isPCVController(address _address) external view returns (bool);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IPCVDepositBalances.sol";

/// @title a PCV Deposit interface
/// @author Fei Protocol
interface IPCVDeposit is IPCVDepositBalances {
    // ----------- Events -----------
    event Deposit(address indexed _from, uint256 _amount);

    event Withdrawal(
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

    event WithdrawERC20(
        address indexed _caller,
        address indexed _token,
        address indexed _to,
        uint256 _amount
    );

    event WithdrawETH(
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

    // ----------- State changing api -----------

    function deposit() external;

    // ----------- PCV Controller only state changing api -----------

    function withdraw(address to, uint256 amount) external;

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external;

    function withdrawETH(address payable to, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title a PCV Deposit interface for only balance getters
/// @author Fei Protocol
interface IPCVDepositBalances {
    // ----------- Getters -----------

    /// @notice gets the effective balance of "balanceReportedIn" token if the deposit were fully withdrawn
    function balance() external view returns (uint256);

    /// @notice gets the token address in which this deposit returns its balance
    function balanceReportedIn() external view returns (address);

    /// @notice gets the resistant token balance and protocol owned fei of this deposit
    function resistantBalanceAndVolt() external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import {CoreRef} from "../refs/CoreRef.sol";
import {TribeRoles} from "./../core/TribeRoles.sol";
import {RateLimited} from "./RateLimited.sol";
import {IMultiRateLimited} from "./IMultiRateLimited.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @title abstract contract for putting a rate limit on how fast an address can perform an action e.g. Minting
/// there are two buffers, one buffer which is each individual addresses's current buffer,
/// and then there is a global buffer which is the buffer that each individual address must respect as well
/// @author Elliot Friedman, Fei Protocol
/// this contract was made abstract so that other contracts that already construct an instance of CoreRef
/// do not collide with this one
abstract contract MultiRateLimited is RateLimited, IMultiRateLimited {
    using SafeCast for *;

    /// @notice the struct containing all information per rate limited address
    struct RateLimitData {
        uint32 lastBufferUsedTime;
        uint112 bufferCap;
        uint112 bufferStored;
        uint112 rateLimitPerSecond;
    }

    /// @notice rate limited address information
    mapping(address => RateLimitData) public rateLimitPerAddress;

    /// @notice max rate limit per second allowable by non governor per contract
    uint256 public individualMaxRateLimitPerSecond;

    /// @notice max buffer cap allowable by non governor per contract
    uint256 public individualMaxBufferCap;

    /// @param _maxRateLimitPerSecond maximum amount of fei that can replenish per second ever, this amount cannot be changed by governance
    /// @param _rateLimitPerSecond maximum rate limit per second per address
    /// @param _individualMaxRateLimitPerSecond maximum rate limit per second per address in multi rate limited
    /// @param _individualMaxBufferCap maximum buffer cap in multi rate limited
    /// @param _globalBufferCap maximum global buffer cap
    constructor(
        uint256 _maxRateLimitPerSecond,
        uint256 _rateLimitPerSecond,
        uint256 _individualMaxRateLimitPerSecond,
        uint256 _individualMaxBufferCap,
        uint256 _globalBufferCap
    )
        RateLimited(
            _maxRateLimitPerSecond,
            _rateLimitPerSecond,
            _globalBufferCap,
            false
        )
    {
        require(
            _individualMaxBufferCap < _globalBufferCap,
            "MultiRateLimited: max buffer cap invalid"
        );

        individualMaxRateLimitPerSecond = _individualMaxRateLimitPerSecond;
        individualMaxBufferCap = _individualMaxBufferCap;
    }

    modifier addressIsRegistered(address rateLimitedAddress) {
        require(
            rateLimitPerAddress[rateLimitedAddress].lastBufferUsedTime != 0,
            "MultiRateLimited: rate limit address does not exist"
        );
        _;
    }

    // ----------- Governor and Admin only state changing api -----------

    /// @notice update the ADD_MINTER_ROLE rate limit per second
    /// @param newRateLimitPerSecond new maximum rate limit per second for add minter role
    function updateMaxRateLimitPerSecond(uint256 newRateLimitPerSecond)
        external
        override
        onlyGovernor
    {
        require(
            newRateLimitPerSecond <= MAX_RATE_LIMIT_PER_SECOND,
            "MultiRateLimited: exceeds global max rate limit per second"
        );

        uint256 oldMaxRateLimitPerSecond = individualMaxRateLimitPerSecond;
        individualMaxRateLimitPerSecond = newRateLimitPerSecond;

        emit MultiMaxRateLimitPerSecondUpdate(
            oldMaxRateLimitPerSecond,
            newRateLimitPerSecond
        );
    }

    /// @notice update the ADD_MINTER_ROLE max buffer cap
    /// @param newBufferCap new buffer cap for ADD_MINTER_ROLE added addresses
    function updateMaxBufferCap(uint256 newBufferCap)
        external
        override
        onlyGovernor
    {
        require(
            newBufferCap <= bufferCap,
            "MultiRateLimited: exceeds global buffer cap"
        );

        uint256 oldBufferCap = individualMaxBufferCap;
        individualMaxBufferCap = newBufferCap;

        emit MultiBufferCapUpdate(oldBufferCap, newBufferCap);
    }

    /// @notice add an authorized rateLimitedAddress contract
    /// @param rateLimitedAddress the new address to add as a rateLimitedAddress
    /// @param _rateLimitPerSecond the rate limit per second for this rateLimitedAddress
    /// @param _bufferCap  the buffer cap for this rateLimitedAddress
    function addAddress(
        address rateLimitedAddress,
        uint112 _rateLimitPerSecond,
        uint112 _bufferCap
    ) external override onlyGovernor {
        _addAddress(rateLimitedAddress, _rateLimitPerSecond, _bufferCap);
    }

    /// @notice add an authorized rateLimitedAddress contract
    /// @param rateLimitedAddress the address whose buffer and rate limit per second will be set
    /// @param _rateLimitPerSecond the new rate limit per second for this rateLimitedAddress
    /// @param _bufferCap  the new buffer cap for this rateLimitedAddress
    function updateAddress(
        address rateLimitedAddress,
        uint112 _rateLimitPerSecond,
        uint112 _bufferCap
    )
        external
        override
        addressIsRegistered(rateLimitedAddress)
        hasAnyOfTwoRoles(TribeRoles.ADD_MINTER_ROLE, TribeRoles.GOVERNOR)
    {
        if (core().hasRole(TribeRoles.ADD_MINTER_ROLE, msg.sender)) {
            require(
                _rateLimitPerSecond <= individualMaxRateLimitPerSecond,
                "MultiRateLimited: rate limit per second exceeds non governor allowable amount"
            );
            require(
                _bufferCap <= individualMaxBufferCap,
                "MultiRateLimited: max buffer cap exceeds non governor allowable amount"
            );
        }
        require(
            _bufferCap <= bufferCap,
            "MultiRateLimited: buffercap too high"
        );
        require(
            _rateLimitPerSecond <= MAX_RATE_LIMIT_PER_SECOND,
            "MultiRateLimited: rateLimitPerSecond too high"
        );

        _updateAddress(rateLimitedAddress, _rateLimitPerSecond, _bufferCap);
    }

    /// @notice add an authorized rateLimitedAddress contract
    /// @param rateLimitedAddress the new address to add as a rateLimitedAddress
    /// gives the newly added contract the maximum allowable rate limit per second and buffer cap
    function addAddressAsMinter(address rateLimitedAddress)
        external
        override
        onlyTribeRole(TribeRoles.ADD_MINTER_ROLE)
    {
        _addAddress(
            rateLimitedAddress,
            uint112(individualMaxRateLimitPerSecond),
            uint112(individualMaxBufferCap)
        );
    }

    /// @notice add an authorized rateLimitedAddress contract
    /// @param rateLimitedAddress the new address to add as a rateLimitedAddress
    /// gives the newly added contract the maximum allowable rate limit per second and buffer cap
    function addAddressAsMinter(
        address rateLimitedAddress,
        uint112 _rateLimitPerSecond,
        uint112 _bufferCap
    ) external onlyTribeRole(TribeRoles.ADD_MINTER_ROLE) {
        require(
            _rateLimitPerSecond <= individualMaxRateLimitPerSecond,
            "MultiRateLimited: rlps exceeds role amt"
        );
        require(
            _bufferCap <= individualMaxBufferCap,
            "MultiRateLimited: buffercap exceeds role amt"
        );
        _addAddress(rateLimitedAddress, _rateLimitPerSecond, _bufferCap);
    }

    /// @notice remove an authorized rateLimitedAddress contract
    /// @param rateLimitedAddress the address to remove from the whitelist of addresses
    function removeAddress(address rateLimitedAddress)
        external
        override
        addressIsRegistered(rateLimitedAddress)
        onlyGuardianOrGovernor
    {
        uint256 oldRateLimitPerSecond = rateLimitPerAddress[rateLimitedAddress]
            .rateLimitPerSecond;

        delete rateLimitPerAddress[rateLimitedAddress];

        emit IndividualRateLimitPerSecondUpdate(
            rateLimitedAddress,
            oldRateLimitPerSecond,
            0
        );
    }

    // ----------- Getters -----------

    /// @notice the amount of action used before hitting limit
    /// @dev replenishes at rateLimitPerSecond per second up to bufferCap
    /// @param rateLimitedAddress the address whose buffer will be returned
    /// @return the buffer of the specified rate limited address
    function individualBuffer(address rateLimitedAddress)
        public
        view
        override
        returns (uint112)
    {
        RateLimitData memory rateLimitData = rateLimitPerAddress[
            rateLimitedAddress
        ];

        uint256 elapsed = block.timestamp - rateLimitData.lastBufferUsedTime;
        return
            uint112(
                Math.min(
                    rateLimitData.bufferStored +
                        (rateLimitData.rateLimitPerSecond * elapsed),
                    rateLimitData.bufferCap
                )
            );
    }

    /// @notice the rate per second for each address
    function getRateLimitPerSecond(address limiter)
        external
        view
        override
        returns (uint256)
    {
        return rateLimitPerAddress[limiter].rateLimitPerSecond;
    }

    /// @notice the last time the buffer was used by each address
    function getLastBufferUsedTime(address limiter)
        external
        view
        override
        returns (uint256)
    {
        return rateLimitPerAddress[limiter].lastBufferUsedTime;
    }

    /// @notice the cap of the buffer that can be used at once
    function getBufferCap(address limiter)
        external
        view
        override
        returns (uint256)
    {
        return rateLimitPerAddress[limiter].bufferCap;
    }

    // ----------- Helper Methods -----------

    function _updateAddress(
        address rateLimitedAddress,
        uint112 _rateLimitPerSecond,
        uint112 _bufferCap
    ) internal {
        RateLimitData storage rateLimitData = rateLimitPerAddress[
            rateLimitedAddress
        ];

        uint112 oldRateLimitPerSecond = rateLimitData.rateLimitPerSecond;
        uint112 currentBufferStored = individualBuffer(rateLimitedAddress);
        uint32 newBlockTimestamp = block.timestamp.toUint32();

        rateLimitData.bufferStored = currentBufferStored;
        rateLimitData.lastBufferUsedTime = newBlockTimestamp;
        rateLimitData.bufferCap = _bufferCap;
        rateLimitData.rateLimitPerSecond = _rateLimitPerSecond;

        emit IndividualRateLimitPerSecondUpdate(
            rateLimitedAddress,
            oldRateLimitPerSecond,
            _rateLimitPerSecond
        );
    }

    /// @param rateLimitedAddress the new address to add as a rateLimitedAddress
    /// @param _rateLimitPerSecond the rate limit per second for this rateLimitedAddress
    /// @param _bufferCap  the buffer cap for this rateLimitedAddress
    function _addAddress(
        address rateLimitedAddress,
        uint112 _rateLimitPerSecond,
        uint112 _bufferCap
    ) internal {
        require(
            _bufferCap <= bufferCap,
            "MultiRateLimited: new buffercap too high"
        );
        require(
            rateLimitPerAddress[rateLimitedAddress].lastBufferUsedTime == 0,
            "MultiRateLimited: address already added"
        );
        require(
            _rateLimitPerSecond <= MAX_RATE_LIMIT_PER_SECOND,
            "MultiRateLimited: rateLimitPerSecond too high"
        );

        RateLimitData memory rateLimitData = RateLimitData({
            lastBufferUsedTime: block.timestamp.toUint32(),
            bufferCap: _bufferCap,
            rateLimitPerSecond: _rateLimitPerSecond,
            bufferStored: _bufferCap
        });

        rateLimitPerAddress[rateLimitedAddress] = rateLimitData;

        emit IndividualRateLimitPerSecondUpdate(
            rateLimitedAddress,
            0,
            _rateLimitPerSecond
        );
    }

    /// @notice the method that enforces the rate limit. Decreases buffer by "amount".
    /// @param rateLimitedAddress the address whose buffer will be depleted
    /// @param amount the amount to remove from the rateLimitedAddress's buffer
    function _depleteIndividualBuffer(
        address rateLimitedAddress,
        uint256 amount
    ) internal {
        _depleteBuffer(amount);

        uint256 newBuffer = individualBuffer(rateLimitedAddress);

        require(newBuffer != 0, "MultiRateLimited: no rate limit buffer");
        require(amount <= newBuffer, "MultiRateLimited: rate limit hit");

        uint32 lastBufferUsedTime = block.timestamp.toUint32();

        uint112 newBufferStored = uint112(newBuffer - amount);
        uint112 currentBufferCap = rateLimitPerAddress[rateLimitedAddress]
            .bufferCap;

        rateLimitPerAddress[rateLimitedAddress]
            .lastBufferUsedTime = lastBufferUsedTime;
        rateLimitPerAddress[rateLimitedAddress].bufferCap = currentBufferCap;
        rateLimitPerAddress[rateLimitedAddress].bufferStored = newBufferStored;

        emit IndividualBufferUsed(
            rateLimitedAddress,
            amount,
            newBuffer - amount
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IMultiRateLimited.sol";

/// @notice global contract to handle rate limited minting of VOLT on a global level
/// allows whitelisted minters to call in and specify the address to mint VOLT to within
/// the calling contract's limits
interface IGlobalRateLimitedMinter is IMultiRateLimited {
    /// @notice function that all VOLT minters call to mint VOLT
    /// pausable and depletes the msg.sender's buffer
    /// @param to the recipient address of the minted VOLT
    /// @param amount the amount of VOLT to mint
    function mintVolt(address to, uint256 amount) external;

    /// @notice mint VOLT to the target address and deplete the whole rate limited
    ///  minter's buffer, pausable and completely depletes the msg.sender's buffer
    /// @param to the recipient address of the minted VOLT
    /// mints all VOLT that msg.sender has in the buffer
    function mintMaxAllowableVolt(address to) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title interface for putting a rate limit on how fast a contract can perform an action, e.g. Minting
/// @author Fei Protocol
interface IMultiRateLimited {
    // ----------- Events -----------

    /// @notice emitted when a buffer is eaten into
    event IndividualBufferUsed(
        address rateLimitedAddress,
        uint256 amountUsed,
        uint256 bufferRemaining
    );

    /// @notice emitted when rate limit is updated
    event IndividualRateLimitPerSecondUpdate(
        address rateLimitedAddress,
        uint256 oldRateLimitPerSecond,
        uint256 newRateLimitPerSecond
    );

    /// @notice emitted when the non gov buffer cap max is updated
    event MultiBufferCapUpdate(uint256 oldBufferCap, uint256 newBufferCap);

    /// @notice emitted when the non gov buffer rate limit per second max is updated
    event MultiMaxRateLimitPerSecondUpdate(
        uint256 oldMaxRateLimitPerSecond,
        uint256 newMaxRateLimitPerSecond
    );

    // ----------- View API -----------

    /// @notice the rate per second for each address
    function getRateLimitPerSecond(address) external view returns (uint256);

    /// @notice the last time the buffer was used by each address
    function getLastBufferUsedTime(address) external view returns (uint256);

    /// @notice the cap of the buffer that can be used at once
    function getBufferCap(address) external view returns (uint256);

    /// @notice the amount of action that can be used before hitting limit
    /// @dev replenishes at rateLimitPerSecond per second up to bufferCap
    function individualBuffer(address) external view returns (uint112);

    // ----------- Governance State Changing API -----------

    /// @notice update the non gov max rate limit per second
    function updateMaxRateLimitPerSecond(uint256 newMaxRateLimitPerSecond)
        external;

    /// @notice update the non gov max buffer cap
    function updateMaxBufferCap(uint256 newBufferCap) external;

    /// @notice add an authorized contract, its per second replenishment and buffer set to the non governor caps
    function addAddressAsMinter(address) external;

    /// @notice add an authorized contract, its per second replenishment and buffer
    function addAddress(
        address,
        uint112,
        uint112
    ) external;

    /// @notice update an authorized contract
    function updateAddress(
        address,
        uint112,
        uint112
    ) external;

    /// @notice remove an authorized contract
    function removeAddress(address) external;
}