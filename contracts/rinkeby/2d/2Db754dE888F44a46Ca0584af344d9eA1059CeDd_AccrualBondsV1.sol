// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {TransferHelper}             from "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import {FixedPointMathLib}          from "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";

import {Initializable}              from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable}   from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable}        from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {IERC20Upgradeable}          from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20Permit}               from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

import {BondPriceLib}               from "./libraries/BondPriceLib.sol";
import {AccrualBondLib}             from "./libraries/AccrualBondLib.sol";

import {AccrualBondStorageV1}       from "./AccrualBondStorageV1.sol";

interface ICNV {
    function mint(address guy, uint256 wad) external;
    function burn(address guy, uint256 wad) external;
}

contract AccrualBondsV1 is AccrualBondStorageV1, Initializable, AccessControlUpgradeable, PausableUpgradeable {

    /* -------------------------------------------------------------------------- */
    /*                           ACCESS CONTROL ROLES                             */
    /* -------------------------------------------------------------------------- */

    bytes32 public constant TREASURY_ROLE           = DEFAULT_ADMIN_ROLE;
    bytes32 public constant STAKING_ROLE            = bytes32(keccak256("STAKING_ROLE"));
    bytes32 public constant POLICY_ROLE             = bytes32(keccak256("POLICY_ROLE"));

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice emitted when a bond is sold/purchased
    /// @param bonder account that purchased the bond
    /// @param token token used to purchase the bond 
    /// @param output amount of output tokens obligated to user
    event BondSold(
        address indexed bonder, 
        address indexed token, 
        uint256 input, 
        uint256 output
    );

    /// @notice emitted when a bond is redeemed/claimed
    /// @param bonder account that purchased the bond
    /// @param bondId users bond position identifier 
    /// @param output amount of output tokens obligated to user
    event BondRedeemed(
        address indexed bonder, 
        uint256 indexed bondId, 
        uint256 output
    );

    /// @notice emitted when a user transfers a bond to another account
    /// @param sender the account that is transfering a bond
    /// @param recipient the account that is receiving the bond
    event BondTransfered(
        address indexed sender,
        address indexed recipient,
        uint256 senderBondId,
        uint256 recipientBondId
    );

    /// @notice emitted when policy updates pricing or mints supply
    /// @param caller presumably policy multi-sig
    /// @param supplyDelta the amount of output tokens to mint to this contract
    /// @param positiveDelta whether the supply delta is postive or negative (mint or burn)
    /// @param newVirtualOutputReserves the new value for virtual output reserves
    /// @param tokens the quote assets that will have their pricing info updated
    /// @param virtualInputReserves the new virtualInputReserves for tokens, used in pricing
    /// @param halfLives the new halfLives for tokens, used in pricing
    /// @param levelBips the new levelBips for tokens, used in pricing
    /// @param updateElapsed whether tokens elapsed time should be updated, used in pricing
    event PolicyUpdate(
        address indexed caller, 
        uint256 supplyDelta, 
        bool indexed positiveDelta,
        uint256 newVirtualOutputReserves, 
        address[] tokens, 
        uint256[] virtualInputReserves, 
        uint256[] halfLives, 
        uint256[] levelBips, 
        bool[] updateElapsed
    );

    /// @notice emitted when quote asset is added
    /// @param caller presumably treasury multi-sig
    /// @param token token used to purchase the bond 
    /// @param virtualInputReserves virtual reserves for input token
    /// @param halfLife rate of change for decay/growth mechanism
    /// @param levelBips percentage of current virtual reserves to target 
    event InputAssetAdded(
        address indexed caller, 
        address indexed token, 
        uint256 virtualInputReserves, 
        uint256 halfLife, 
        uint256 levelBips
    );

    /// @notice emitted when quote asset is removed
    /// @param caller presumably policy or treasury multi-sig
    /// @param token token used to purchase the bond 
    event InputAssetRemoved(
        address indexed caller,
        address indexed token
    );

    /// @notice emitted when policy mint allowance is updated
    /// @param caller presumably policy multi-sig
    event PolicyMintAllowanceSet(
        address indexed caller, 
        uint256 mintAllowance
    );

    /// @notice emitted when revenue beneficiary is set
    /// @param caller presumably the treasury multi-sig
    /// @param beneficiary new account that will receive accrued funds
    event BeneficiarySet(
        address indexed caller, 
        address beneficiary
    );

    /// @notice emitted when staking vebases
    /// @param outputTokensEmitted the amount of output tokens emitted this epoch
    event Vebase(
        uint256 outputTokensEmitted
    );

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */

    /// @notice OZ upgradeable initialization
    function initialize(
        uint256 _term,
        uint256 _virtualOutputReserves,
        address _outputToken,
        address _beneficiary,
        address _treasury,
        address _policy,
        address _staking
    ) external virtual initializer {
        // make sure contract has not been initialized
        require(term == 0, "INITIALIZED");

        // initialize state
        __Context_init();
        __AccessControl_init();
        __Pausable_init();
        __ERC165_init();

        term = _term;
        virtualOutputReserves = _virtualOutputReserves;
        outputToken = _outputToken;
        beneficiary = _beneficiary;

        // setup roles
        _grantRole(DEFAULT_ADMIN_ROLE, _treasury);
        _grantRole(POLICY_ROLE, _policy);
        _grantRole(STAKING_ROLE, _staking);

        // pause contract
        _pause();
    }



    /* -------------------------------------------------------------------------- */
    /*                             PURCHASE BOND LOGIC                            */
    /* -------------------------------------------------------------------------- */

    /// @notice internal logic that handles bond purchases
    /// @param sender the account that purchased the bond
    /// @param recipient the account that will receive the bond
    /// @param token token used to purchase the bond 
    /// @param input the amount of input tokens used to purchase bond
    /// @param minOutput the min amount of output tokens bonder is willig to receive
    function _purchaseBond(
        address sender,
        address recipient,
        address token,
        uint256 input,
        uint256 minOutput
    ) internal whenNotPaused() virtual returns (uint256 output) {

        // F6: CHECKS
        
        // fetch quote price info from storage
        BondPriceLib.QuotePriceInfo storage quote = quoteInfo[token];
        
        // make sure there is pricing info for token
        require(quote.virtualInputReserves != 0,"!LIQUIDITY");
        
        // calculate and store availableDebt so we can ensure
        // we're not incuring more debt than we can pay back
        uint256 availableDebt = IERC20Upgradeable(outputToken).balanceOf(address(this)) - totalDebt;
        
        // calculate 'output' value
        output = BondPriceLib.getAmountOut(
            input,
            availableDebt,
            virtualOutputReserves,
            quote.virtualInputReserves,
            block.timestamp - quote.lastUpdate,
            quote.halfLife,
            quote.levelBips
        );
        
        // if output is less than min output, or greater than available debt revert
        require(output >= minOutput && availableDebt >= output, "!output");

        // F6: EFFECTS

        // transfer principal from sender -> beneficiary
        TransferHelper.safeTransferFrom(token, sender, beneficiary, input);
        
        // unchecked because cnvEmitted and totalDebt cannot
        // be greater than totalSupply, which is checked 
        unchecked { 
            // increase cnvEmitted by amount sold
            cnvEmitted += output;

            // increase totalDebt by amount sold
            totalDebt += output;
        }

        quote.virtualInputReserves += input;
        
        // push position to user storage
        positions[recipient].push(AccrualBondLib.Position(output, 0, block.timestamp));
      
        // T2 - Are events emitted for every storage mutating function?
        emit BondSold(sender, token, input, output);
    }

    /// @notice purchase an accrual bond
    /// @param recipient the account that will receive the bond
    /// @param token token used to purchase the bond 
    /// @param input the amount of input tokens used to purchase bond
    /// @param minOutput the min amount of output tokens bonder is willig to receive
    function purchaseBond(
        address recipient,
        address token,
        uint256 input,
        uint256 minOutput
    ) external virtual returns (uint256 output) {
        
        // purchase bond on behalf of recipient
        return _purchaseBond(msg.sender, recipient, token, input, minOutput);
    }

    /// @notice purchase an accrual bond using EIP-2612 permit
    /// @param recipient the account that will receive the bond
    /// @param token token used to purchase the bond 
    /// @param input the amount of input tokens used to purchase bond
    /// @param minOutput the min amount of output tokens bonder is willig to receive
    /// @param deadline eip-2612
    /// @param v eip-2612
    /// @param r eip-2612     
    /// @param s eip-2612
    function purchaseBondUsingPermit(
        address recipient,
        address token,
        uint256 input,
        uint256 minOutput,
        uint256 deadline, uint8 v, bytes32 r, bytes32 s
    ) external virtual returns (uint256 output) {
        
        // approve tokens for spender - https://eips.ethereum.org/EIPS/eip-2612
        IERC20Permit(token).permit(msg.sender, address(this), input, deadline, v, r, s);

        // purchase bond on behalf of recipient
        return _purchaseBond(msg.sender, recipient, token, input, minOutput);
    }

    /* -------------------------------------------------------------------------- */
    /*                              REDEEM BOND LOGIC                             */
    /* -------------------------------------------------------------------------- */

    /// @notice redeem your bond with output distrobuted linearly
    /// @param recipient the account that will receive the bond
    /// @param bondId users bond position identifier 
    function _redeemBond(
        address caller,
        address recipient,
        uint256 bondId
    ) internal whenNotPaused() virtual returns (uint256 output) {

        // F6: CHECKS

        // fetch position from storage
        AccrualBondLib.Position storage position = positions[caller][bondId];
        
        // calculate redemption amount
        output = AccrualBondLib.getRedeemAmountOut(position.owed, position.redeemed, position.creation, term);
        
        // skip redemption if output is zero to save gas
        if (output > 0) {

            // F6: EFFECTS
            
            // decrease total debt by redeemed amount
            totalDebt -= output;
            
            // increase user redeemed amount by redeemed amount
            position.redeemed += output;
            
            // send recipient redeemed output tokens
            TransferHelper.safeTransfer(outputToken, recipient, output);
            
            // T2 - Are events emitted for every storage mutating function?
            emit BondRedeemed(caller, bondId, output);
        }
    }

    /// @notice redeem your bond with output distrobuted linearly
    /// @param recipient the account that will receive the bond
    /// @param bondId users bond position identifier 
    function redeemBond(
        address recipient,
        uint256 bondId
    ) external whenNotPaused() virtual returns (uint256 output) {

        // redeem users bond, and cache output
        output = _redeemBond(msg.sender, recipient, bondId);

        // revert is output is equal to zero to save gas 
        require(output > 0, "!output");
    }

    /// @notice redeem your bond with output distrobuted linearly
    /// @param recipient the account that will receive the bond
    /// @param bondIds array of users bond position identifiers
    function redeemBondBatch(
        address recipient,
        uint256[] memory bondIds
    ) external whenNotPaused() virtual returns (uint256 output) {

        // cache array length to save gas
        uint256 length = bondIds.length;

        // this is safe because total output can never 
        // be greater than outputToken's totalSupply
        unchecked {
            for (uint256 i; i < length; i++) {
                // redeem users bonds
                output += _redeemBond(msg.sender, recipient, bondIds[i]);
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                            BOND TRANSFER LOGIC                             */
    /* -------------------------------------------------------------------------- */

    /// @notice transfer a bond from one account to another
    /// @param recipient the account that will receive the bond
    /// @param bondId users bond position identifier 
    function transferBond(
        address recipient,
        uint256 bondId
    ) external whenNotPaused() virtual {

        // fetch position from storage
        AccrualBondLib.Position memory position = positions[msg.sender][bondId];

        // delete position from senders storage
        delete positions[msg.sender][bondId];

        // push position to recipients storage
        positions[recipient].push(position);

        // T2 - Are events emitted for every storage mutating function?
        emit BondTransfered(msg.sender, recipient, bondId, positions[recipient].length);
    }

    /* -------------------------------------------------------------------------- */
    /*                              MANAGEMENT LOGIC                              */
    /* -------------------------------------------------------------------------- */

    /// @notice update pricing + mint supply if policy and there's sufficient mint allowance
    /// @param supplyDelta the amount of output tokens to mint to this contract
    /// @param positiveDelta whether the supply delta is postive or negative (mint or burn)
    /// @param newVirtualOutputReserves the new value for virtual output reserves
    /// @param tokens the quote assets that will have their pricing info updated
    /// @param virtualInputReserves the new virtualInputReserves for tokens, used in pricing
    /// @param halfLives the new halfLives for tokens, used in pricing
    /// @param levelBips the new levelBips for tokens, used in pricing
    /// @param updateElapsed whether tokens elapsed time should be updated, used in pricing
    function policyUpdate(
        uint256 supplyDelta,
        bool positiveDelta,
        uint256 newVirtualOutputReserves,
        address[] memory tokens,
        uint256[] memory virtualInputReserves,
        uint256[] memory halfLives,
        uint256[] memory levelBips,
        bool[] memory updateElapsed
    ) external virtual onlyRole(POLICY_ROLE) {

        // CHECK THAT WE SUFFICE STAKING.minPrice()

        // if supplyDelta is greater than zero, mint supply
        if (supplyDelta > 0) {

            if (positiveDelta) {
                // F6: CHECKS 

                // decrease policy allowance by mint amount
                // reverts if supplyDelta is greater
                policyMintAllowance -= supplyDelta;

                // F6: EFFECTS

                // mint output tokens to this contract
                ICNV(outputToken).mint(address(this), supplyDelta);
            } else {
                // F6: CHECKS 

                // check that policy is not burning more than available debt
                require(
                    IERC20Upgradeable(outputToken).balanceOf(address(this)) - totalDebt >= supplyDelta, 
                    "!supplyDelta"
                );

                // increase policy allowance by mint amount
                // reverts if supplyDelta is greater
                policyMintAllowance += supplyDelta;

                // F6: EFFECTS

                // mint output tokens to this contract
                ICNV(outputToken).burn(address(this), supplyDelta);
            }
        }

        // if newVirtualOutputReserves is greater than zero update virtual output reserves
        if (newVirtualOutputReserves > 0) virtualOutputReserves = newVirtualOutputReserves;

        // store array length in memory to save gas
        uint256 length = tokens.length;

        // if tokens length is greater than zero batch update quote pricing
        if (length > 0) {

            // make sure all param lengths match
            require(
                length == virtualInputReserves.length &&
                length == halfLives.length       &&
                length == levelBips.length,
                "!LENGTH"
            );

            for (uint256 i; i < length; ) {

                // make sure halfLives are greater than zero
                require(halfLives[i] > 0, "!halfLife");

                // update quote pricing info for each index
                quoteInfo[tokens[i]] = BondPriceLib.QuotePriceInfo(
                    virtualInputReserves[i],
                    updateElapsed[i] ? block.timestamp : quoteInfo[tokens[i]].lastUpdate,
                    halfLives[i],
                    levelBips[i]
                );

                // increment i using unchecked statement to save gas, cannot reasonably overflow
                unchecked { ++i; }
            }
        }

        // T2 - Are events emitted for every storage mutating function?
        emit PolicyUpdate(
            msg.sender, 
            supplyDelta,
            positiveDelta, 
            newVirtualOutputReserves, 
            tokens, 
            virtualInputReserves, 
            halfLives, 
            levelBips, 
            updateElapsed
        );
    }

    /// @notice add quote asset and update quote pricing info
    /// @param token token used to purchase the bond
    /// @param virtualInputReserves virtual reserves for input token
    /// @param halfLife rate of change for decay/growth mechanism
    /// @param levelBips percentage of current virtual reserves to target 
    function addQuoteAsset(
        address token,
        uint256 virtualInputReserves,
        uint256 halfLife,
        uint256 levelBips
    ) external virtual onlyRole(TREASURY_ROLE) {

        // make sure pricing info for this asset does not already exist
        require(quoteInfo[token].lastUpdate == 0, "!EXISTENT");

        // increment totalAssets to account for newly added input token
        unchecked { ++totalAssets; }

        // update pricing info for added asset
        quoteInfo[token] = BondPriceLib.QuotePriceInfo(
            virtualInputReserves,
            block.timestamp,
            halfLife,
            levelBips
        );

        // T2 - Are events emitted for every storage mutating function?
        emit InputAssetAdded(msg.sender, token, virtualInputReserves, halfLife, levelBips);
    }

    /// @notice remove a quote asset
    /// @param token token used to purchase the bond
    function removeQuoteAsset(
        address token
    ) external virtual {

        // make sure caller has either policy role or treasury role
        require(hasRole(POLICY_ROLE, msg.sender) || hasRole(TREASURY_ROLE, msg.sender));

        // fetch quote pricing info from storage
        BondPriceLib.QuotePriceInfo memory quote = quoteInfo[token];

        // make sure quote pricing info doesn't already exist for this token
        require(quote.lastUpdate != 0, "!NONEXISTENT");

        // decrement total assets to account for removed asset
        --totalAssets;

        // delete quote pricing info for removed token 
        delete quoteInfo[token];

        // T2 - Are events emitted for every storage mutating function?
        emit InputAssetRemoved(msg.sender, token);
    }

    /// @notice update policy output token mint allowance if treasury
    /// @param mintAllowance the amount policy is allowed to mint until next update
    function setPolicyMintAllowance(
        uint256 mintAllowance
    ) external virtual onlyRole(TREASURY_ROLE) {

        // update policy mint allowance
        policyMintAllowance = mintAllowance;

        // T2 - Are events emitted for every storage mutating function?
        emit PolicyMintAllowanceSet(msg.sender, mintAllowance);
    }

    /// @notice update the beneficiary address if treasury
    /// @param accrualTo account that receives accrued revenue
    function setBeneficiary(
        address accrualTo
    ) external virtual onlyRole(TREASURY_ROLE) {
        
        // update beneficiary account
        beneficiary = accrualTo;
        
        // T2 - Are events emitted for every storage mutating function?
        emit BeneficiarySet(msg.sender, accrualTo);
    }

    /// @notice pause contract interactions if policy or treasury
    function pause() external virtual {
        
        // make sure caller has either policy role or treasury role
        require(hasRole(POLICY_ROLE, msg.sender) || hasRole(TREASURY_ROLE, msg.sender));
        
        _pause();
    }

    /// @notice unpause contract interactions if policy or treasury
    function unpause() external virtual {

        // make sure caller has either policy role or treasury role
        require(hasRole(POLICY_ROLE, msg.sender) || hasRole(TREASURY_ROLE, msg.sender));
        
        _unpause();
    }

    /* -------------------------------------------------------------------------- */
    /*                                VEBASE LOGIC                                */
    /* -------------------------------------------------------------------------- */

    function vebase() external virtual onlyRole(STAKING_ROLE) returns (bool) {

        // T2 - Are events emitted for every storage mutating function?
        emit Vebase(cnvEmitted);

        // reset/delete cnvEmitted
        delete cnvEmitted;

        // return true
        return true;
    }

    /* -------------------------------------------------------------------------- */
    /*                             PRICE HELPER LOGIC                             */
    /* -------------------------------------------------------------------------- */

    function getVirtualInputReserves(
        address token
    ) external virtual view returns (uint256) {
        // fetch quote pricing info from storage
        BondPriceLib.QuotePriceInfo memory quote = quoteInfo[token];

        // decay virtual reserves
        return BondPriceLib.expToLevel(
            quote.virtualInputReserves, 
            block.timestamp - quote.lastUpdate, 
            quote.halfLife, 
            quote.levelBips
        );
    }

    function getUserPositionCount(
        address account
    ) external virtual view returns (uint256) {
        return positions[account].length;
    }

    function getAvailableSupply() external virtual view returns (uint256) {
        return IERC20Upgradeable(outputToken).balanceOf(address(this)) - totalDebt;
    }

    function getSpotPrice(
        address token
    ) external virtual view returns (uint256) {

        // fetch quote pricing info from storage
        BondPriceLib.QuotePriceInfo memory quote = quoteInfo[token];

        // decay virtual reserves
        uint256 virtualInputReserves = BondPriceLib.expToLevel(
            quote.virtualInputReserves, 
            block.timestamp - quote.lastUpdate, 
            quote.halfLife, 
            quote.levelBips
        );

        // 1 * virtual input token reserves / (availableDebt + virtual output token reserves)
        return FixedPointMathLib.fmul(
            1e18,
            virtualInputReserves,
            IERC20Upgradeable(outputToken).balanceOf(address(this)) - totalDebt + virtualOutputReserves
        );
    }

    function getAmountOut(
        address token,
        uint256 input
    ) external virtual view returns (uint256 output) {

        // fetch quote pricing info from storage
        BondPriceLib.QuotePriceInfo memory quote = quoteInfo[token];

        // calculate available debt, the max amount of output tokens we can distrobute
        uint256 availableDebt = IERC20Upgradeable(outputToken).balanceOf(address(this)) - totalDebt;

        // calculate amount out
        output = BondPriceLib.getAmountOut(
            input,
            availableDebt,
            virtualOutputReserves,
            quote.virtualInputReserves,
            block.timestamp - quote.lastUpdate,
            quote.halfLife,
            quote.levelBips
        );
    }
}

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                            COMMON BASE UNITS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant YAD = 1e8;
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RAD = 1e45;

    /*///////////////////////////////////////////////////////////////
                         FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // If baseUnit is zero this will return zero instead of reverting.
            z := div(z, baseUnit)
        }
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * baseUnit in z for now.
            z := mul(x, baseUnit)

            // Equivalent to require(y != 0 && (x == 0 || (x * baseUnit) / x == baseUnit))
            if iszero(and(iszero(iszero(y)), or(iszero(x), eq(div(z, x), baseUnit)))) {
                revert(0, 0)
            }

            // We ensure y is not zero above, so there is never division by zero here.
            z := div(z, y)
        }
    }

    function fpow(
        uint256 x,
        uint256 n,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := baseUnit
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store baseUnit in z for now.
                    z := baseUnit
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, baseUnit)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, baseUnit)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, baseUnit)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z)
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z)
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z)
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z)
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z)
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z)
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";

library BondPriceLib {

    using FixedPointMathLib for uint256;

    struct QuotePriceInfo {
        uint256 virtualInputReserves; 
        uint256 lastUpdate;
        uint256 halfLife;
        uint256 levelBips;
    }

    /// @notice Calculates an output for a given bond purchase.
    /// @param input amount of input tokens provided
    /// @param outputReserves physical output reserves (IE CNV)
    /// @param virtualOutputReserves virtual output reserves (IE CNV)
    /// @param virtualInputReserves virtual input reserves (IE DAI)
    /// @param elapsed time since last policy update
    /// @param halfLife rate of change for virtual input reserves 
    /// @param levelBips percentage to growth/decay virtual input reserves to in bips
    function getAmountOut(
        uint256 input,
        uint256 outputReserves,
        uint256 virtualOutputReserves,
        uint256 virtualInputReserves,
        uint256 elapsed,
        uint256 halfLife,
        uint256 levelBips
    ) internal pure returns (uint256 output) {
        
        // Calculate an output (IE in CNV) given a purchase size of 'input' using 
        // the CPMM formula, while applying an exponential function that grows or decays 
        // virtual input reserves to a specific level. 
        output = input.fmul(
            outputReserves + virtualOutputReserves, 
            expToLevel(virtualInputReserves, elapsed, halfLife, levelBips) + input
        );
    }

    function expToLevel(
        uint256 x, 
        uint256 elapsed, 
        uint256 halfLife,
        uint256 levelBips
    ) internal pure returns (uint256 z) {

        z = x >> (elapsed / halfLife);

        z -= z.fmul(elapsed % halfLife, halfLife) >> 1;
        
        z += FixedPointMathLib.fmul(x - z, levelBips, 1e4);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";

library AccrualBondLib {

    struct Position {
        uint256 owed;
        uint256 redeemed;
        uint256 creation;
    }

    function getRedeemAmountOut(
        uint256 owed,
        uint256 redeemed,
        uint256 creation,
        uint256 term
    ) internal view returns (uint256) {
        
        uint256 elapsed = block.timestamp - creation;

        if (elapsed > term) elapsed = term;

        return FixedPointMathLib.fmul(owed, elapsed, term) - redeemed;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "./libraries/BondPriceLib.sol";
import "./libraries/AccrualBondLib.sol";

contract AccrualBondStorageV1 {
    
    /// @notice address that receives revenue
    address public beneficiary;
    
    /// @notice bond payout token
    address public outputToken;

    /// @notice total amount currently outstanding to bonders
    uint256 public totalDebt;
    
    /// @notice virtual output token reserves used in pricing
    uint256 public virtualOutputReserves;
    
    /// @notice total amount of assets currently exchangeable for bonds
    uint256 public totalAssets;
    
    /// @notice length after bond purchase when bond is fully redeemable
    uint256 public term;
    
    /// @notice tracks how many output tokens have been emitted since the last veBase
    uint256 public cnvEmitted;
    
    /// @notice tracks the amount that policy it allowed to mint
    uint256 public policyMintAllowance;

    /// @notice mapping containing pricing info for exchangeable assets
    mapping(address => BondPriceLib.QuotePriceInfo) public quoteInfo;
    
    /// @notice mapping containing posistions for individual users
    mapping(address => AccrualBondLib.Position[]) public positions;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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