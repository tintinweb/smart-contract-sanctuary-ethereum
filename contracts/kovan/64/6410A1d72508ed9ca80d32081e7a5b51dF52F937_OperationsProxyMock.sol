// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../Globals.sol";
import "../interfaces/IOperationsProxy.sol";

contract OperationsProxyMock is IOperationsProxy {
    uint256 _fee;
    uint256 _yield;
    bool _isYieldPercentage;
    bool _isFeePercentage;

    function setFee(uint256 fee, bool isPercentage) public {
        _fee = fee;
        _isFeePercentage = isPercentage;
    }

    function getFee() public view returns (uint256) {
        return _fee;
    }

    function isFeePercentage() public view returns (bool) {
        return _isFeePercentage;
    }

    function takeFee(uint256 amount) external override view returns (uint256) {
        if (_isFeePercentage) {
            return _subtractPercentage(amount, _fee);
        } else {
            return amount - _fee;
        }
    }

    function setYield(uint256 yield, bool isPercentage) public {
        _yield = yield;
        _isYieldPercentage = isPercentage;
    }

    function getYield() public view returns (uint256) {
        return _yield;
    }

    function isYieldPercentage() public view returns (bool) {
        return _isYieldPercentage;
    }

    function calcualteYield(
        Globals.ContributionLite memory contribution,
        Globals.Yield memory yield
    ) external override view returns (uint256) {
        if (_isYieldPercentage) {
            return _addPercentage(contribution.amount, yield.apr);
        } else {
            return contribution.amount + yield.apr;
        }
    }

    function _subtractPercentage(uint256 amount, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        return (amount * (100000 - percentage * 10)) / 100000;
    }

    function _addPercentage(uint256 amount, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        return (amount * (100000 + percentage * 10)) / 100000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./openzeppelin/IERC20.sol";
contract Globals {
    /**   Alternative Enum
     * enum UserStatus{
     *    NONE,
     *    APPROVED,
     *    SUSPENDED,
     *    BLOCKED
     *  }
     */

    enum UserStatus {
        NONE,
        WHITELISTED,
        LIMITED,
        BLACKLISTED
    }

    enum ERC20s {
        NONE,
        USDC,
        DXTA
    }
    enum Roles {
        NONE,
        OPERATOR,
        ADMIN
    }

    struct Yield {
        uint256 timestamp;
        uint256 apr;
    }

    struct Contribution {
        uint256 amount;
        uint256 burnableAfter;
        ERC20s depositedIn;
        uint256 nextYieldIndex;
        bool locked;
    }

    struct ContributionLite {
        uint256 amount;
        uint256 burnableAfter;
        IERC20 depositedIn;
        bool locked;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../Globals.sol";

interface IOperationsProxy {
    function takeFee(uint256 amount) external returns (uint256);

    function calcualteYield(
        Globals.ContributionLite memory contribution,
        Globals.Yield memory yield
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.1;

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