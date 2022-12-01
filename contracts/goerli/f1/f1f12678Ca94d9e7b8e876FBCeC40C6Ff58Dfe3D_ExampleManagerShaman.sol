// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IBAAL.sol";

// Made for use with Baal(Molochv3)
// Example use of Manager shamans
// Any account can claim some amount of shares or loot per period
// this shaman must be set as a manager role in the dao
contract ExampleManagerShaman {
    IBAAL public baal;
    IERC20 public token;

    mapping(address => uint256) public memberClaims;
    bool public shares;
    uint256 public period; // length of period in seconds
    uint256 public perPeriod; // amount of loot or shares to mint

    event SetMember(address account);
    event Claim(address account, uint256 timestamp);

    constructor(address _moloch, bool _shares, uint256 _perPeriod, uint256 _period) {
        baal = IBAAL(_moloch);
        shares = _shares;
        // get shares or loot token address from dao based on 'shares' flag
        if (shares) {
            token = IERC20(baal.sharesToken());
        } else {
            token = IERC20(baal.lootToken());
        }
        period = _period;
        perPeriod = _perPeriod;
    }

    // Mint share or loot tokens
    function _mintTokens(address to, uint256 amount) private {
        address[] memory _receivers = new address[](1);
        _receivers[0] = to;

        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = amount;

        if (shares) {
            baal.mintShares(_receivers, _amounts); // interface to mint shares
        } else {
            baal.mintLoot(_receivers, _amounts); // interface to mint loot
        }
    }

    // can be called by any account to claim per period tokens
    function claim(address account) public {
        if (memberClaims[account] == 0) {
            setNewMember(account);
        }
        require(
            block.timestamp - memberClaims[account] >= period,
            "Can only claim 1 time per period"
        );

        uint256 amount = calculate();
        _mintTokens(account, amount);
        memberClaims[account] = block.timestamp;
        emit Claim(account, block.timestamp);
    }

    function setNewMember(address account) internal returns (uint256) {
        // set last claim to one period ago
        uint256 lastClaim = block.timestamp - period;
        memberClaims[account] = lastClaim;
        emit SetMember(account);
        return lastClaim;
    }

    function calculate() internal view returns (uint256 total) {
        total = perPeriod;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.7;

interface IBAAL {
    function mintLoot(address[] calldata to, uint256[] calldata amount) external;
    function mintShares(address[] calldata to, uint256[] calldata amount) external;
    function shamans(address shaman) external returns(uint256);
    function isManager(address shaman) external returns(bool);
    function target() external returns(address);
    function totalSupply() external view returns (uint256);
    function sharesToken() external view returns (address);
    function lootToken() external view returns (address);
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