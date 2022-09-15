// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "IERC20.sol";
import {IAuraBooster} from "IAuraBooster.sol";
import {IAuraRewardPool} from "IAuraRewardPool.sol";
import {IAuraStakingProxy} from "IAuraStakingProxy.sol";

contract MockAura is IAuraBooster, IAuraRewardPool, IAuraStakingProxy {
    address public balancerPoolToken;
    address public crv;
    address public cvx;
    mapping(address => uint256) public deposits;
    uint256 public pid;

    constructor(uint256 _pid, address _balancerPoolToken, address _crv, address _cvx) {
        pid = _pid;
        balancerPoolToken = _balancerPoolToken;
        crv = _crv;
        cvx = _cvx;
    }

    function deposit(uint256 pid, uint256 amount, bool stake) external returns(bool) {
        deposits[msg.sender] += amount;
        IERC20(balancerPoolToken).transferFrom(msg.sender, address(this), amount);
        return true;
    }

    function stakerRewards() external view returns(address) {
        return address(this);
    }

    function withdrawAndUnwrap(uint256 amount, bool claim) external returns(bool) {
        deposits[msg.sender] -= amount;
        IERC20(balancerPoolToken).transfer(msg.sender, amount);
        return true;
    }

    function getReward(address _account, bool _claimExtras) external returns(bool) {
        return true;
    }

    function balanceOf(address _account) external view returns(uint256) {
        return deposits[_account];
    }

    function operator() external view returns(address) {
        return address(this);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

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

pragma solidity 0.8.15;

interface IAuraBooster {
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns(bool);
    function stakerRewards() external view returns(address);
}

pragma solidity 0.8.15;

interface IAuraRewardPool {
    function withdrawAndUnwrap(uint256 amount, bool claim) external returns(bool);
    function getReward(address _account, bool _claimExtras) external returns(bool);
    function balanceOf(address _account) external view returns(uint256);
    function pid() external view returns(uint256);
    function operator() external view returns(address);
}

pragma solidity 0.8.15;

interface IAuraStakingProxy {
    function crv() external view returns(address);
    function cvx() external view returns(address);
}