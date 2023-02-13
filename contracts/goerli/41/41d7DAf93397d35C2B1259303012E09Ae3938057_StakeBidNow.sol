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

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBidNow is IERC20 {
    error FromBlacklisted(address addr);
    error ToBlacklisted(address addr);

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function blacklistAddress(address addr, bool flag) external;

    function withdraw(address to, uint256 amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {IBidNow} from "./IBidNow.sol";

contract StakeBidNow {
    error StakeFailed();
    error InvalidWithdrawAmount();
    error NothingToClaim();
    error NotStaked();
    IBidNow immutable BIDNOW;

    struct Stake {
        uint96 stakedAmount;
        uint96 accumulated;
        uint64 stakedAt;
    }

    mapping(address => Stake) public stake;
    uint256 public yieldRate = 500;

    constructor(IBidNow contractAddress) {
        BIDNOW = contractAddress;
    }

    function stakeTokens(uint96 amount) external {
        Stake memory _stake = stake[msg.sender];
        _stake.accumulated = getAccumulated(_stake);
        _stake.stakedAt = uint64(block.timestamp);
        _stake.stakedAmount = amount;
        stake[msg.sender] = _stake;
        BIDNOW.transferFrom(msg.sender, address(this), amount);
    }

    function claim() external {
        Stake memory _stake = stake[msg.sender];
        uint96 accumulated = getAccumulated(_stake);
        if (accumulated == 0) revert NothingToClaim();
        stake[msg.sender].accumulated = 0;
        BIDNOW.mint(msg.sender, accumulated);
    }

    function unstakeTokens(uint96 amount) external {
        Stake memory _stake = stake[msg.sender];
        _stake.accumulated = getAccumulated(_stake);
        if (amount > _stake.stakedAmount) revert InvalidWithdrawAmount();
        _stake.stakedAmount -= amount;
        if (_stake.stakedAmount == 0) {
            _stake.stakedAt = 0;
        } else {
            _stake.stakedAt = uint64(block.timestamp);
        }
        stake[msg.sender] = _stake;
        BIDNOW.transferFrom(address(this), msg.sender, amount);
    }

    function getAccumulated(
        Stake memory _stake
    ) private view returns (uint96 accumulated) {
        uint96 newAccumulation = 0;
        if (_stake.stakedAt > 0) {
            newAccumulation = uint96(
                ((block.timestamp - _stake.stakedAt) *
                    1e18 *
                    _stake.stakedAmount *
                    yieldRate) / 100
            );
        }
        accumulated = newAccumulation + _stake.accumulated;
    }
}