pragma solidity 0.8.10;

import "@insuredao/pool-contracts/contracts/interfaces/IPoolTemplate.sol";
import "@insuredao/pool-contracts/contracts/interfaces/IOwnership.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Referral
 * @author @InsureDAO
 * @notice Buy Insurance with referral
 * SPDX-License-Identifier: GPL-3.0
 */

contract Referral {
    event Rebate(address indexed referrer, address indexed pool, uint256 rebate);
    event SetMaxRebateRate(address pool, uint256 maxRebateRate);

    mapping(address => uint256) public maxRebateRates;

    address public immutable ownership;
    address public immutable usdc;
    uint256 private constant RATE_DENOMINATOR = 1000000;

    modifier onlyOwner() {
        require(IOwnership(ownership).owner() == msg.sender, "Caller is not allowed to operate");
        _;
    }

    constructor(
        address _usdc,
        address _ownership,
        address _vault,
        uint256 _defaultMaxRebateRate
    ) {
        require(_usdc != address(0), "zero address");
        require(_ownership != address(0), "zero address");
        require(_vault != address(0), "zero address");
        require(_defaultMaxRebateRate != 0, "zero");

        usdc = _usdc;
        ownership = _ownership;
        IERC20(usdc).approve(_vault, type(uint256).max);

        maxRebateRates[address(0)] = _defaultMaxRebateRate;
    }

    /**
     * @notice
     * @param _pool Address of the insurance pool
     * @param _referrer Address where the rabate goes
     * @param _rebateRate Rate of the rebate.(1e6 = 100%) Maximum rate set to 10% as default.
     *
     * // Following params are same as PoolTemplate:insure()
     * @param _amount .
     * @param _maxCost .
     * @param _span .
     * @param _target .
     * @param _for .
     * @param _agent .
     */
    function insure(
        address _pool,
        address _referrer,
        uint256 _rebateRate,
        uint256 _amount,
        uint256 _maxCost,
        uint256 _span,
        bytes32 _target,
        address _for,
        address _agent
    ) external {
        require(_rebateRate <= _getMaxRebateRate(_pool), "exceed max rabate rate");

        //transfer premium
        uint256 _premium = IPoolTemplate(_pool).getPremium(_amount, _span);
        _premium += (_premium * _rebateRate) / RATE_DENOMINATOR;
        IERC20(usdc).transferFrom(msg.sender, address(this), _premium);

        //buy insurance
        IPoolTemplate(_pool).insure(_amount, _maxCost, _span, _target, _for, _agent);

        //deposit actual rebate, then transfer LP token to referrer
        uint256 _rebate = IERC20(usdc).balanceOf(address(this));

        uint256 _lp = IPoolTemplate(_pool).deposit(_rebate);
        IERC20(_pool).transfer(_referrer, _lp);

        emit Rebate(_referrer, _pool, _rebate);
    }

    function getMaxRebateRate(address _pool) external view returns (uint256) {
        return _getMaxRebateRate(_pool);
    }

    function _getMaxRebateRate(address _pool) internal view returns (uint256) {
        uint256 _maxRebateRate = maxRebateRates[_pool];

        if (_maxRebateRate == 0) {
            return maxRebateRates[address(0)];
        } else {
            return _maxRebateRate;
        }
    }

    function setMaxRebateRate(address _pool, uint256 _maxRebateRate) external onlyOwner {
        maxRebateRates[_pool] = _maxRebateRate;

        emit SetMaxRebateRate(_pool, _maxRebateRate);
    }
}

pragma solidity 0.8.10;

interface IPoolTemplate {
    enum MarketStatus {
        Trading,
        Payingout
    }

    function deposit(uint256 _amount) external returns (uint256 _mintAmount);

    function requestWithdraw(uint256 _amount) external;

    function withdraw(uint256 _amount) external returns (uint256 _retVal);

    function insure(
        uint256,
        uint256,
        uint256,
        bytes32,
        address,
        address
    ) external returns (uint256);

    function redeem(
        uint256 _id,
        uint256 _loss,
        bytes32[] calldata _merkleProof
    ) external;

    function getPremium(uint256 _amount, uint256 _span)
        external
        view
        returns (uint256);

    function unlockBatch(uint256[] calldata _ids) external;

    function unlock(uint256 _id) external;

    function registerIndex(uint256 _index) external;

    function allocateCredit(uint256 _credit)
        external
        returns (uint256 _mintAmount);

    function pairValues(address _index)
        external
        view
        returns (uint256, uint256);

    function resume() external;

    function rate() external view returns (uint256);

    function withdrawCredit(uint256 _credit) external returns (uint256 _retVal);

    function marketStatus() external view returns (MarketStatus);

    function availableBalance() external view returns (uint256 _balance);

    function utilizationRate() external view returns (uint256 _rate);

    function totalLiquidity() external view returns (uint256 _balance);

    function totalCredit() external view returns (uint256);

    function lockedAmount() external view returns (uint256);

    function valueOfUnderlying(address _owner) external view returns (uint256);

    function pendingPremium(address _index) external view returns (uint256);

    function paused() external view returns (bool);

    //onlyOwner
    function applyCover(
        uint256 _pending,
        uint256 _payoutNumerator,
        uint256 _payoutDenominator,
        uint256 _incidentTimestamp,
        bytes32 _merkleRoot,
        string calldata _rawdata,
        string calldata _memo
    ) external;

    function applyBounty(
        uint256 _amount,
        address _contributor,
        uint256[] calldata _ids
    ) external;
}

pragma solidity 0.8.10;

//SPDX-License-Identifier: MIT

interface IOwnership {
    function owner() external view returns (address);

    function futureOwner() external view returns (address);

    function commitTransferOwnership(address newOwner) external;

    function acceptTransferOwnership() external;
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