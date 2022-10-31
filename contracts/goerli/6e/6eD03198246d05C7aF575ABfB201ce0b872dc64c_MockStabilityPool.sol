// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import {IStabilityPool} from "../../interfaces/liquity/IStabilityPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockStabilityPool is IStabilityPool {
    IERC20 public immutable lusd;

    event StabilityPoolETHBalanceUpdated(uint _newBalance);
    event ETHGainWithdrawn(address indexed _depositor, uint _ETH, uint _LUSDLoss);

    constructor(address _lusd, address _priceFeed) {
        lusd = IERC20(_lusd);
        priceFeed = _priceFeed;
    }

    mapping(address => uint256) public balances;

    address public priceFeed;

    function provideToSP(
        uint256 _amount,
        address /* _frontEndTag */
    ) external {
        // transfers lusd from the depositor to this contract and updates the balance
        // the balance must appear on getCompoundedLUSDDeposit
        lusd.transferFrom(msg.sender, address(this), _amount);
        balances[msg.sender] += _amount;
    }

    function withdrawFromSP(uint256 _amount) external {
        // withdraws the LUSD of the user from this contract
        // and updates the balance
        uint256 bal = balances[msg.sender];

        if (_amount > bal) _amount = bal;

        balances[msg.sender] -= _amount;

        lusd.transfer(msg.sender, _amount);

        uint256 ethBal = address(this).balance;

        payable(msg.sender).transfer(ethBal);
        emit ETHGainWithdrawn(msg.sender, ethBal, 0);
    }

    function getDepositorETHGain(
        address /* _depositor */
    ) external view returns (uint256) {
        return address(this).balance;
    }

    function getDepositorLQTYGain(
        address /* _depositor */
    ) external pure returns (uint256) {
        return 0;
    }

    function getCompoundedLUSDDeposit(address _depositor)
        external
        view
        returns (uint256)
    {
        return balances[_depositor];
    }

    function offset(uint256 _debtToOffset, uint256 _collToAdd) external {}

    function troveManager() public pure returns (address) {
        return address(0);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IStabilityPool {
    /*  provideToSP():
     *
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Tags the deposit with the provided front end tag param, if it's a new deposit
     * - Sends depositor's accumulated gains (LQTY, ETH) to depositor
     * - Sends the tagged front end's accumulated LQTY gains to the tagged front end
     * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
     */
    function provideToSP(uint256 _amount, address _frontEndTag) external;

    /*  withdrawFromSP():
     *
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Removes the deposit's front end tag if it is a full withdrawal
     * - Sends all depositor's accumulated gains (LQTY, ETH) to depositor
     * - Sends the tagged front end's accumulated LQTY gains to the tagged front end
     * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     */
    function withdrawFromSP(uint256 _amount) external;

    /* Calculates the ETH gain earned by the deposit since its last snapshots were taken.
     * Given by the formula:  E = d0 * (S - S(0))/P(0)
     * where S(0) and P(0) are the depositor's snapshots of the sum S and product P, respectively.
     * d0 is the last recorded deposit value.
     */
    function getDepositorETHGain(address _depositor)
        external
        view
        returns (uint256);

    /*
     * Calculate the LQTY gain earned by a deposit since its last snapshots were taken.
     * Given by the formula:  LQTY = d0 * (G - G(0))/P(0)
     * where G(0) and P(0) are the depositor's snapshots of the sum G and product P, respectively.
     * d0 is the last recorded deposit value.
     */
    function getDepositorLQTYGain(address _depositor)
        external
        view
        returns (uint256);

    /*
     * Return the user's compounded deposit. Given by the formula:  d = d0 * P/P(0)
     * where P(0) is the depositor's snapshot of the product P, taken when they last updated their deposit.
     */
    function getCompoundedLUSDDeposit(address _depositor)
        external
        view
        returns (uint256);

    /*
     * Cancels out the specified debt against the LUSD contained in the Stability Pool (as far as possible)
     * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     */
    function offset(uint256 _debtToOffset, uint256 _collToAdd) external;

    /*
     * Address of the TroveManager contract.
     */
    function troveManager() external view returns (address);
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