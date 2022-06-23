// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { IERC20 } from "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import { IFeeDistributor } from "./mocks/balancer/MockFeeDistro.sol";

interface IBooster {
    function earmarkFees(address _feeDistro) external returns (bool);
}

/**
 * @title   ClaimFeesHelper
 * @author  ConvexFinance
 * @notice  Claim vecrv fees and distribute
 * @dev     Allows anyone to call `claimFees` that will basically collect any 3crv and distribute to cvxCrv
 *          via the booster.
 */
contract ClaimFeesHelper {
    IBooster public immutable booster;
    address public immutable voterProxy;

    mapping(address => uint256) public lastTokenTimes;
    IFeeDistributor public feeDistro;

    /**
     * @param _booster      Booster.sol, e.g. 0xF403C135812408BFbE8713b5A23a04b3D48AAE31
     * @param _voterProxy   CVX VoterProxy e.g. 0x989AEb4d175e16225E39E87d0D97A3360524AD80
     * @param _feeDistro    FeeDistro e.g. 0xA464e6DCda8AC41e03616F95f4BC98a13b8922Dc
     */
    constructor(
        address _booster,
        address _voterProxy,
        address _feeDistro
    ) {
        booster = IBooster(_booster);
        voterProxy = _voterProxy;
        feeDistro = IFeeDistributor(_feeDistro);
    }

    /**
     * @dev Claims fees from fee claimer, and pings the booster to distribute
     */
    function claimFees(IERC20 _token) external {
        uint256 tokenTime = feeDistro.getTokenTimeCursor(_token);
        require(tokenTime > lastTokenTimes[address(_token)], "not time yet");

        uint256 bal = IERC20(_token).balanceOf(voterProxy);
        feeDistro.claimToken(voterProxy, _token);

        // Loop through until something is transferred
        while (IERC20(_token).balanceOf(voterProxy) <= bal) {
            feeDistro.claimToken(voterProxy, _token);
        }

        booster.earmarkFees(address(_token));
        lastTokenTimes[address(_token)] = tokenTime;
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
pragma solidity 0.8.11;

import { IERC20 } from "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";

interface IFeeDistributor {
    function claimToken(address user, IERC20 token) external returns (uint256);

    function claimTokens(address user, IERC20[] calldata tokens) external returns (uint256[] memory);

    function getTokenTimeCursor(IERC20 token) external view returns (uint256);
}

// @dev - Must be funded by transferring crv to this contract post deployment, as opposed to minting directly
contract MockFeeDistributor is IFeeDistributor {
    mapping(address => uint256) private tokenRates;

    constructor(address[] memory _tokens, uint256[] memory _rates) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenRates[_tokens[i]] = _rates[i];
        }
    }

    function claimToken(address user, IERC20 token) external returns (uint256) {
        return _claimToken(user, token);
    }

    function _claimToken(address user, IERC20 token) internal returns (uint256) {
        uint256 rate = tokenRates[address(token)];
        if (rate > 0) {
            token.transfer(user, rate);
        }
        return rate;
    }

    function claimTokens(address user, IERC20[] calldata tokens) external returns (uint256[] memory) {
        uint256[] memory rates = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            rates[i] = _claimToken(user, tokens[i]);
        }
        return rates;
    }

    function getTokenTimeCursor(
        IERC20 /* token */
    ) external pure returns (uint256) {
        return 1;
    }
}