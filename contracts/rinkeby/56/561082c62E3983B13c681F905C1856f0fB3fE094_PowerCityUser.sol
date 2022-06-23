// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Interfaces/IBorrowerOperations.sol";
import "./Interfaces/ITroveManager.sol";
import "./Interfaces/IHintHelpers.sol";
import "./Interfaces/ISortedTroves.sol";
import "./Interfaces/IStabilityPool.sol";
import "./Interfaces/ILQTYStaking.sol";
import "./Interfaces/IPowerCityUserFactory.sol";

/**
 * @title PowerCityUser contract
 * @author RapidInnovation
 * @notice This contract is user-specific and does the operations on the
 * Liquity protocol on behalf of the user.
 */
contract PowerCityUser is ReentrancyGuard {
    // for each automation function, the msg.sender requirement needs to be updated ?!
    using SafeERC20 for IERC20;

    uint256 public constant LUSD_GAS_COMPENSATION = 200e18;

    IERC20 public lqty;
    IERC20 public lusd;

    // address of PowerCityUserFactory smart contract
    address public factory;

    mapping(address => uint256) public lqtyStakes;

    event CityTroveCreated(
        address indexed _user,
        uint256 _coll,
        uint256 _LUSDAmount,
        uint256 _time
    );
    event CityTroveAdjusted(
        address indexed _user,
        uint256 _collAdd,
        uint256 _collWithdraw,
        uint256 _LUSDAmount,
        bool _isDebtIncrease,
        uint256 _time
    );
    event CitySPProvided(
        address indexed _user,
        uint256 _LUSDamount,
        uint256 _time,
        uint256 _LQTYGain,
        uint256 _ETHGain
    );
    event CitySPWithdrawn(
        address indexed _user,
        uint256 _LUSDamount,
        uint256 _time,
        uint256 _LQTYGain,
        uint256 _ETHGain
    );
    event CityLQTYStaked(
        address indexed _user,
        uint256 _LQTYamount,
        uint256 _time,
        uint256 _LUSDGain,
        uint256 _ETHGain
    );
    event CityLQTYUnstaked(
        address indexed _user,
        uint256 _LQTYamount,
        uint256 _time,
        uint256 _LUSDGain,
        uint256 _ETHGain
    );

    constructor(address _lqty, address _lusd) {
        factory = msg.sender;
        lqty = IERC20(_lqty);
        lusd = IERC20(_lusd);
    }

    /**
     * @notice Enabling this contract to receive ETH from external sources
     * @dev This will allow the contract to receive ETH as reward gained from liquity
     */
    receive() external payable {}

    /**
     * @notice Open trove
     * @dev The trove is opened in the Liquity's BorrowOperations smart contract
     * with respect to the address of this PowerCityUser's smart contracts.
     * @param _maxFeePercentage refers to the fee slippage that occurs when
     * a redemption transaction is processed first, driving up the issuance fee.
     * @param _LUSDAmount refers to the borrowed LUSD amount
     * @param _upperHint and @param _lowerHint addresses refer to the adjacent trove addresses.
     * These addresses are fetched from the function findInsertPosition
     */
    function openTrove(
        uint256 _maxFeePercentage,
        uint256 _LUSDAmount,
        address _upperHint,
        address _lowerHint
    ) external payable nonReentrant {
        address owner_ = IPowerCityUserFactory(factory).getOwner(address(this));
        address userAdmin_ = IPowerCityUserFactory(factory).getUserAdmin();
        require(
            msg.sender == owner_ || msg.sender == userAdmin_,
            "msg.sender != owner or userAdmin"
        );

        IBorrowerOperations(IPowerCityUserFactory(factory).getBorrOperations())
            .openTrove{value: msg.value}(
            _maxFeePercentage,
            _LUSDAmount,
            _upperHint,
            _lowerHint
        );

        lusd.safeTransfer(owner_, _LUSDAmount);

        emit CityTroveCreated(
            msg.sender,
            msg.value,
            _LUSDAmount,
            block.timestamp
        );
    }

    // NOT TESTED DUE TO RECOVERY MODE
    function closeTrove() external nonReentrant {
        address owner_ = IPowerCityUserFactory(factory).getOwner(address(this));
        address userAdmin_ = IPowerCityUserFactory(factory).getUserAdmin();
        require(
            msg.sender == owner_ || msg.sender == userAdmin_,
            "msg.sender != owner or userAdmin"
        );

        uint256 debt = ITroveManager(
            IPowerCityUserFactory(factory).getTroveManager()
        ).getTroveDebt(address(this)) - LUSD_GAS_COMPENSATION;

        lusd.transferFrom(owner_, address(this), debt);

        uint256 balBefore = address(this).balance;
        IBorrowerOperations(IPowerCityUserFactory(factory).getBorrOperations())
            .closeTrove();
        uint256 balAfter = address(this).balance;

        (bool success, ) = owner_.call{value: balAfter - balBefore}("");
        require(success, "ETH !transferred");
    }

    /**
     * @notice Adjust trove
     * @dev Only a trove that has been opened through this smart contract can be adjusted
     * If more collateral is to be added then it is passed as msg.value
     * Both @param _collWithdrawal and msg.value cannot be positive at the same transaction
     * @param _maxFeePercentage refers to the fee slippage that occurs when
     * a redemption transaction is processed first, driving up the issuance fee.
     * @param _collWithdrawal refers to the amount of collateral to withdraw
     * @param _LUSDChange refers to the borrowed or repaid LUSD amount
     * @param _isDebtIncrease is true if additional debt of amount @param _LUSDChange is borrowed
     * @param _upperHint and @param _lowerHint refer to the adjacent trove addresses
     * These addresses are fetched from the function findInsertPosition
     */
    function adjustTrove(
        uint256 _maxFeePercentage,
        uint256 _collWithdrawal,
        uint256 _LUSDChange,
        bool _isDebtIncrease,
        address _upperHint,
        address _lowerHint
    ) external payable nonReentrant {
        address owner_ = IPowerCityUserFactory(factory).getOwner(address(this));
        address userAdmin_ = IPowerCityUserFactory(factory).getUserAdmin();
        require(
            msg.sender == owner_ || msg.sender == userAdmin_,
            "msg.sender != owner or userAdmin"
        );

        if (!_isDebtIncrease) {
            lusd.safeTransferFrom(owner_, address(this), _LUSDChange);
        }

        IBorrowerOperations(IPowerCityUserFactory(factory).getBorrOperations())
            .adjustTrove{value: msg.value}(
            _maxFeePercentage,
            _collWithdrawal,
            _LUSDChange,
            _isDebtIncrease,
            _upperHint,
            _lowerHint
        );

        if (_isDebtIncrease) {
            lusd.safeTransfer(owner_, _LUSDChange);
        }

        if (_collWithdrawal > 0 && msg.value == 0) {
            (bool success, ) = owner_.call{value: _collWithdrawal}("");
            require(success, "collateral withdrawal failed");
        }

        emit CityTroveAdjusted(
            msg.sender,
            msg.value,
            _collWithdrawal,
            _LUSDChange,
            _isDebtIncrease,
            block.timestamp
        );
    }

    /**
     * @notice Provide LUSD to Liquity's Stability Pool
     * @dev If provided for the second time or more,
     * the pending rewards are transferred to the user
     * @param _amount refers to the amount of LUSD to provide
     * @param _frontEndTag TO-DO
     */
    function provideToSP(uint _amount, address _frontEndTag)
        external
        nonReentrant
    {
        address owner_ = IPowerCityUserFactory(factory).getOwner(address(this));
        address userAdmin_ = IPowerCityUserFactory(factory).getUserAdmin();
        require(
            msg.sender == owner_ || msg.sender == userAdmin_,
            "msg.sender != owner or userAdmin"
        );

        lusd.safeTransferFrom(owner_, address(this), _amount);

        uint256 balBefore = address(this).balance;
        uint256 lqtyBalBefore = lqty.balanceOf(address(this));
        IStabilityPool(IPowerCityUserFactory(factory).getStabilityPool())
            .provideToSP(_amount, _frontEndTag);
        uint256 lqtyBalAfter = lqty.balanceOf(address(this));
        uint256 balAfter = address(this).balance;
        (bool success, ) = owner_.call{value: balAfter - balBefore}("");
        require(success, "ETH !transferred");

        lqty.transfer(owner_, lqtyBalAfter - lqtyBalBefore);

        emit CitySPProvided(
            msg.sender,
            _amount,
            block.timestamp,
            lqtyBalAfter - lqtyBalBefore,
            balAfter - balBefore
        );
    }

    /**
     * @notice Withdraw LUSD from Liquity's Stability Pool
     * @dev If @param _amount is zero, then only the pending rewards
     * are transferred to the user
     * @param _amount refers to the amount of LUSD to withdraw
     */
    function withdrawFromSP(uint _amount) external nonReentrant {
        address owner_ = IPowerCityUserFactory(factory).getOwner(address(this));
        address userAdmin_ = IPowerCityUserFactory(factory).getUserAdmin();
        require(
            msg.sender == owner_ || msg.sender == userAdmin_,
            "msg.sender != owner or userAdmin"
        );

        uint256 lqtyBalBefore = lqty.balanceOf(address(this));
        uint256 balBefore = address(this).balance;

        IStabilityPool(IPowerCityUserFactory(factory).getStabilityPool())
            .withdrawFromSP(_amount);

        uint256 balAfter = address(this).balance;
        uint256 lqtyBalAfter = lqty.balanceOf(address(this));

        (bool success, ) = owner_.call{value: balAfter - balBefore}("");
        require(success, "ETH !transferred");

        lqty.transfer(owner_, lqtyBalAfter - lqtyBalBefore);
        lusd.safeTransfer(owner_, _amount);

        emit CitySPWithdrawn(
            msg.sender,
            _amount,
            block.timestamp,
            lqtyBalAfter - lqtyBalBefore,
            balAfter - balBefore
        );
    }

    /**
     * @notice Stake LQTY tokens in Liquity's Staking Pool
     * @dev If provided for the second time or more,
     * the pending rewards are transferred to the user
     * @param _LQTYAmount refers to the amount of LQTY tokens to stake
     */
    function stake(uint256 _LQTYAmount) external nonReentrant {
        address owner_ = IPowerCityUserFactory(factory).getOwner(address(this));
        address userAdmin_ = IPowerCityUserFactory(factory).getUserAdmin();
        require(
            msg.sender == owner_ || msg.sender == userAdmin_,
            "msg.sender != owner or userAdmin"
        );

        lqty.safeTransferFrom(owner_, address(this), _LQTYAmount);

        lqtyStakes[owner_] += _LQTYAmount;
        uint256 lusdBalBefore = lusd.balanceOf(address(this));
        uint256 ethBalBefore = address(this).balance;

        ILQTYStaking(IPowerCityUserFactory(factory).getLqtyStaking()).stake(
            _LQTYAmount
        );

        uint256 lusdBalAfter = lusd.balanceOf(address(this));
        uint256 ethBalAfter = address(this).balance;

        (bool success, ) = owner_.call{value: ethBalAfter - ethBalBefore}("");
        require(success, "ETH !transferred");

        lusd.safeTransfer(owner_, lusdBalAfter - lusdBalBefore);

        emit CityLQTYStaked(
            msg.sender,
            _LQTYAmount,
            block.timestamp,
            lusdBalAfter - lusdBalBefore,
            ethBalAfter - ethBalBefore
        );
    }

    /**
     * @notice Unstake LQTY tokens in Liquity's Staking Pool
     * @dev If @param _LQTYAmount is zero, then only the pending rewards
     * are transferred to the user
     * @param _LQTYAmount refers to the amount of LQTY tokens to unstake
     */
    function unstake(uint256 _LQTYAmount) external nonReentrant {
        address owner_ = IPowerCityUserFactory(factory).getOwner(address(this));
        address userAdmin_ = IPowerCityUserFactory(factory).getUserAdmin();
        require(
            msg.sender == owner_ || msg.sender == userAdmin_,
            "msg.sender != owner or userAdmin"
        );

        uint256 LQTYToWithdraw_;
        uint256 currentStake = lqtyStakes[owner_];

        if (_LQTYAmount > 0) {
            LQTYToWithdraw_ = Math.min(_LQTYAmount, currentStake);
            uint256 newStake = currentStake - LQTYToWithdraw_;
            lqtyStakes[owner_] = newStake;
        }

        uint256 lusdBalBefore = lusd.balanceOf(address(this));
        uint256 ethBalBefore = address(this).balance;

        ILQTYStaking(IPowerCityUserFactory(factory).getLqtyStaking()).unstake(
            _LQTYAmount
        );

        uint256 lusdBalAfter = lusd.balanceOf(address(this));
        uint256 ethBalAfter = address(this).balance;

        (bool success, ) = owner_.call{value: ethBalAfter - ethBalBefore}("");
        require(success, "ETH !transferred");

        lusd.safeTransfer(owner_, lusdBalAfter - lusdBalBefore);
        lqty.safeTransfer(owner_, LQTYToWithdraw_);

        emit CityLQTYUnstaked(
            msg.sender,
            LQTYToWithdraw_,
            block.timestamp,
            lusdBalAfter - lusdBalBefore,
            ethBalAfter - ethBalBefore
        );
    }

    // -------------------------------- VIEW FUNCTIONS -------------------------------- //

    /**
     * @notice Get the trove's entire debt, collateral, pending LUSD debt and ETH reward
     * @dev It returns the debt and collateral of this smart contract,
     * since the address of this smart contract was used to open the
     * trove in Liquity's smart contract
     * @return debt in LUSD
     * @return coll in ETH
     * @return pendingLUSDDebtReward in LUSD
     * @return pendingETHReward in ETH
     */
    function getEntireDebtAndColl()
        external
        view
        returns (
            uint256 debt,
            uint256 coll,
            uint256 pendingLUSDDebtReward,
            uint256 pendingETHReward
        )
    {
        (debt, coll, pendingLUSDDebtReward, pendingETHReward) = ITroveManager(
            IPowerCityUserFactory(factory).getTroveManager()
        ).getEntireDebtAndColl(address(this));
    }

    /**
     * @notice Computes the nominal collateral ratio
     * @param _collPrice refers to the market value of the collateral
     * @param _debt refers to the amount of LUSD debt
     * @return Collateral ratio
     */
    function computeNominalCR(uint256 _collPrice, uint256 _debt)
        external
        view
        returns (uint256)
    {
        return
            IHintHelpers(IPowerCityUserFactory(factory).getHintHelpers())
                .computeNominalCR(_collPrice, _debt);
    }

    /**
     * @notice Calculates the number of trials
     * @dev The return value is used as an input parameter for the function getApproxHint
     * @return Number of trials
     */
    function getNumTrials() external view returns (uint256) {
        uint256 num = ISortedTroves(
            IPowerCityUserFactory(factory).getSortedTroves()
        ).getSize();
        uint256 sqrt_ = sqrt(num);

        return sqrt_ * 15;
    }

    /**
     * @notice Calculates the approx hint address
     * @dev The first return value, which is an address is used as an
     * input parameter for the function findInsertPosition
     * @param _CR refers to the collateral ratio fetched from the function computeNominalCR
     * @param _numTrials refers to the number of trials fetched from the function getNumTrials
     * @param _inputRandomSeed refers to a random seed number
     * @return hintAddress refers to the approx hint address
     */
    function getApproxHint(
        uint _CR,
        uint _numTrials,
        uint _inputRandomSeed
    )
        external
        view
        returns (
            address hintAddress,
            uint diff,
            uint latestRandomSeed
        )
    {
        (hintAddress, diff, latestRandomSeed) = IHintHelpers(
            IPowerCityUserFactory(factory).getHintHelpers()
        ).getApproxHint(_CR, _numTrials, _inputRandomSeed);
    }

    /**
     * @notice Finds the addresses of the adjacent troves'
     * @dev The @param _prevId and @param _nextId are the same addresses
     * @param _ICR refers to the nominal collateral ratio fetched from the function computeNominalCR
     * @param _prevId and @param _nextId refers to the address fetched from the function getApproxHint
     * @return The two addresses of adjacent troves
     */
    function findInsertPosition(
        uint256 _ICR,
        address _prevId,
        address _nextId
    ) external view returns (address, address) {
        return
            ISortedTroves(IPowerCityUserFactory(factory).getSortedTroves())
                .findInsertPosition(_ICR, _prevId, _nextId);
    }

    /**
     * @notice Gets the ETH balance of this contract
     * @return ETH balance
     */
    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Gets the LUSD balance of this contract
     * @return LUSD balance
     */
    function getLUSDBalance() external view returns (uint256) {
        return lusd.balanceOf(address(this));
    }

    /**
     * @notice Gets the LQTY balance of this contract
     * @return LQTY balance
     */
    function getLQTYBalance() external view returns (uint256) {
        return lqty.balanceOf(address(this));
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

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

pragma solidity ^0.8.4;

interface IBorrowerOperations {
    function openTrove(
        uint _maxFee,
        uint _LUSDAmount,
        address _upperHint,
        address _lowerHint
    ) external payable;

    function addColl(address _upperHint, address _lowerHint) external payable;

    function moveETHGainToTrove(
        address _user,
        address _upperHint,
        address _lowerHint
    ) external payable;

    function withdrawColl(
        uint _amount,
        address _upperHint,
        address _lowerHint
    ) external;

    function withdrawLUSD(
        uint _maxFee,
        uint _amount,
        address _upperHint,
        address _lowerHint
    ) external;

    function repayLUSD(
        uint _amount,
        address _upperHint,
        address _lowerHint
    ) external;

    function closeTrove() external;

    function adjustTrove(
        uint _maxFee,
        uint _collWithdrawal,
        uint _debtChange,
        bool isDebtIncrease,
        address _upperHint,
        address _lowerHint
    ) external payable;

    function claimCollateral() external;

    function getCompositeDebt(uint _debt) external pure returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ITroveManager {
    function getTroveOwnersCount() external view returns (uint);

    function getTroveFromTroveOwnersArray(uint _index)
        external
        view
        returns (address);

    function getNominalICR(address _borrower) external view returns (uint);

    function getCurrentICR(address _borrower, uint _price)
        external
        view
        returns (uint);

    function liquidate(address _borrower) external;

    function liquidateTroves(uint _n) external;

    function batchLiquidateTroves(address[] calldata _troveArray) external;

    function redeemCollateral(
        uint _LUSDAmount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFee
    ) external;

    function updateStakeAndTotalStakes(address _borrower)
        external
        returns (uint);

    function updateTroveRewardSnapshots(address _borrower) external;

    function addTroveOwnerToArray(address _borrower)
        external
        returns (uint index);

    function applyPendingRewards(address _borrower) external;

    function getPendingETHReward(address _borrower)
        external
        view
        returns (uint);

    function getPendingLUSDDebtReward(address _borrower)
        external
        view
        returns (uint);

    function hasPendingRewards(address _borrower) external view returns (bool);

    function getEntireDebtAndColl(address _borrower)
        external
        view
        returns (
            uint debt,
            uint coll,
            uint pendingLUSDDebtReward,
            uint pendingETHReward
        );

    function closeTrove(address _borrower) external;

    function removeStake(address _borrower) external;

    function getRedemptionRate() external view returns (uint);

    function getRedemptionRateWithDecay() external view returns (uint);

    function getRedemptionFeeWithDecay(uint _ETHDrawn)
        external
        view
        returns (uint);

    function getBorrowingRate() external view returns (uint);

    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint LUSDDebt) external view returns (uint);

    function getBorrowingFeeWithDecay(uint _LUSDDebt)
        external
        view
        returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getTroveStatus(address _borrower) external view returns (uint);

    function getTroveStake(address _borrower) external view returns (uint);

    function getTroveDebt(address _borrower) external view returns (uint);

    function getTroveColl(address _borrower) external view returns (uint);

    function setTroveStatus(address _borrower, uint num) external;

    function increaseTroveColl(address _borrower, uint _collIncrease)
        external
        returns (uint);

    function decreaseTroveColl(address _borrower, uint _collDecrease)
        external
        returns (uint);

    function increaseTroveDebt(address _borrower, uint _debtIncrease)
        external
        returns (uint);

    function decreaseTroveDebt(address _borrower, uint _collDecrease)
        external
        returns (uint);

    function getTCR(uint _price) external view returns (uint);

    function checkRecoveryMode(uint _price) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IHintHelpers {
    function getRedemptionHints(
        uint _LUSDamount,
        uint _price,
        uint _maxIterations
    )
        external
        view
        returns (
            address firstRedemptionHint,
            uint partialRedemptionHintNICR,
            uint truncatedLUSDamount
        );

    function getApproxHint(
        uint _CR,
        uint _numTrials,
        uint _inputRandomSeed
    )
        external
        view
        returns (
            address hintAddress,
            uint diff,
            uint latestRandomSeed
        );

    function computeNominalCR(uint _coll, uint _debt)
        external
        pure
        returns (uint);

    function computeCR(
        uint _coll,
        uint _debt,
        uint _price
    ) external pure returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ISortedTroves {
    function contains(address _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst() external view returns (address);

    function getLast() external view returns (address);

    function getNext(address _id) external view returns (address);

    function getPrev(address _id) external view returns (address);

    function validInsertPosition(
        uint256 _ICR,
        address _prevId,
        address _nextId
    ) external view returns (bool);

    function findInsertPosition(
        uint256 _ICR,
        address _prevId,
        address _nextId
    ) external view returns (address, address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IStabilityPool {
    function provideToSP(uint _amount, address _frontEndTag) external;

    function withdrawFromSP(uint _amount) external;

    function withdrawETHGainToTrove(address _upperHint, address _lowerHint)
        external;

    function registerFrontEnd(uint _kickbackRate) external;

    function offset(uint _debt, uint _coll) external;

    function getETH() external view returns (uint);

    function getTotalLUSDDeposits() external view returns (uint);

    function getDepositorETHGain(address _depositor)
        external
        view
        returns (uint);

    function getDepositorLQTYGain(address _depositor)
        external
        view
        returns (uint);

    function getFrontEndLQTYGain(address _frontEnd)
        external
        view
        returns (uint);

    function getCompoundedLUSDDeposit(address _depositor)
        external
        view
        returns (uint);

    function getCompoundedFrontEndStake(address _frontEnd)
        external
        view
        returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ILQTYStaking {
    function stake(uint _LQTYamount) external;

    function unstake(uint _LQTYamount) external;

    function increaseF_ETH(uint _ETHFee) external;

    function increaseF_LUSD(uint _LQTYFee) external;

    function getPendingETHGain(address _user) external view returns (uint);

    function getPendingLUSDGain(address _user) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IPowerCityUserFactory {
    function getBorrOperations() external view returns (address);

    function getFactoryOwner() external view returns (address);

    function getHintHelpers() external view returns (address);

    function getLqty() external view returns (address);

    function getLqtyStaking() external view returns (address);

    function getLusd() external view returns (address);

    function getOwner(address) external view returns (address);

    function getSortedTroves() external view returns (address);

    function getStabilityPool() external view returns (address);

    function getTroveManager() external view returns (address);

    function getUserAdmin() external view returns (address);
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