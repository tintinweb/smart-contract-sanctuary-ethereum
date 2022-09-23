pragma solidity ^0.8.0;

import "openzeppelin/token/ERC20/IERC20.sol";

struct Balance {
    address recipient;
    uint256 amount;
}

/**
 * @notice Distributes tokens to a list of addreses.
 */
contract Transmitter {
    error NotAdmin();
    event Distribute(address indexed recipient, uint amount);
    event Withdrawn(address indexed token, uint amount);

    modifier onlyAdmin() {
        if(msg.sender != admin) revert NotAdmin();
        _;
    }

    address public immutable admin;
    address public immutable token;
    uint constant public bounty = 1_000_000_000; // bounty reward, 6 decimals
    uint constant public total = 3_253_000_000; // total reward, 6 decimals
    address constant public reporter = 0x14CaB1A7b5fe7a2473A2Dd82DE32E4c94cBAe63e; // address for the 1000 usdc bounty

    constructor(address token_) {
        admin = msg.sender;
        token = token_;
    }

    /// @dev Loops over the list of claim recipients and transfers their claims to them.
    function distribute() external {
        (, Balance[22] memory claims, ,) = getRawData();
        unchecked {
            for(uint i; i < claims.length; ++i) {
                IERC20(token).transfer(claims[i].recipient, claims[i].amount);
                emit Distribute(claims[i].recipient, claims[i].amount);
            }
        }
    }

    /// @dev Just in case tokens get stuck or cannot be claimed.
    function withdrawTokens(address[] memory tokens) external onlyAdmin {
        unchecked {
            for(uint i; i < tokens.length; ++i) {
                IERC20 t = IERC20(tokens[i]);
                uint amount = t.balanceOf(address(this));
                t.transfer(admin, amount);
                emit Withdrawn(tokens[i], amount);
            }
        }
    }

    error NoEth();

    receive() external payable {
        revert NoEth();
    }
    

    /// @notice Gets the amount of liquidity provided to pool.
    /// First item in the data is the BOUNTY amount for the user who reported the issue NOT liquidity.
    /// @dev Source: https://api.studio.thegraph.com/query/20803/primitive-subgraph/v0.0.2-rc0/graphql?query=%7B%0A++positions%28where%3A+%7B+pool%3A+%220x1803a83d9cefaff28728173c501258b5c0c61dc3acac20302a52bbc43e174e58%22+%7D%29+%7B%0A++%09id%0A++++initialLiquidityDecimal%0A++++initialQuoteDecimal%0A++++initialUnderlyingDecimal%0A++++owner%0A++%7D%0A%7D
    function getRawData() public pure returns (Balance[22] memory data, Balance[22] memory claims, uint totalLiquidity, uint totalClaimable) {
        totalClaimable = total - bounty;
        totalLiquidity = 4_544281 * 1e12; // Sum of liquidity shares (values below).
        data = [
            Balance(reporter, bounty),
            Balance(0x04E20289807dDfa97a11ef07C0e83110BBbeadDd, 23389 * 1e12), // 1e12 because subgraph returns 6 decimal places, and liquidity has 1e18 decimals
            Balance(0x0f03D543f782C99dA39552a12e37A443fbD80E70, 20463 * 1e12),
            Balance(0x13AE5042d3ABe5371b6b24b73e57EC718222A4dA, 70507 * 1e12),
            Balance(0x149f119543239D0b102Bc60e80D0965232229234, 14811 * 1e12),
            Balance(0x2C17c733CeFC0e618850B546d9df53cdbFa29725, 15465 * 1e12),
            Balance(0x33f572D61ca18A6C5cB8B0f7eB09E2253F415A55, 2962 * 1e12),
            Balance(0x3E3E7159540Cf9C48Ff6Ff77D3AdD6552ef54A18, 92249 * 1e12),
            Balance(0x49D2db5F6C17a5A2894f52125048aAA988850009, 14589 * 1e12),
            Balance(0x543009285dC2aA291bCa060Df6F9d06C81B08429, 86712 * 1e12),
            Balance(0x5d3def61252919833790910dD0aC76db797a2829, 604 * 1e12),
            Balance(0x5dF3EE425fE4F7903cfEd113DA02D2730d5Cec01, 66661 * 1e12),
            Balance(0x605082e0794141C27f59F00f5C25dCde1Db8C122, 882079 * 1e12),
            Balance(0x78b74016f06EEA3D9b5498aa30f6981F2A01cC84, 94877 * 1e12),
            Balance(0x89dAfb6e061d71084E24A4F78529C5BF0DA4d011, 92047 * 1e12),
            Balance(0xa68aB6d6668745c4585667aE4a91c0032dBb932f, 15383 * 1e12),
            Balance(0xc5Af3beFb128D179a7D287E14a1069222b7C69DC, 72577 * 1e12),
            Balance(0xcA66B197D337F15F4b949e3201eE833C73665217, 1_570457 * 1e12),
            Balance(0xcDBFE8209cB0AfE95aa092def212aa4A434A9120, 24841 * 1e12),
            Balance(0xD755A8d0c72b379F445AB17fe60af9a76EAAD221, 155997 * 1e12),
            Balance(0xe4ec13946CE37ae7b3EA6AAC315B486DAD7766F2, 1559 * 1e12),
            Balance(0xfCb5A922877683128cc8B52CD7883CAb12D21229, 1_226052 * 1e12)
        ];

        // Claims are proportional to the amount of ownership of the pool.
        unchecked {
            for(uint i; i < claims.length; ++i) {
                if(i == 0) claims[i] = data[i]; // If reporter, use regular bounty amount.
                else claims[i] = Balance(data[i].recipient, computeClaim(totalClaimable, data[i].amount, totalLiquidity)); // Else, use proportional amount.
            }
        }
    }

    /// @notice Computes the claimable amount proportional to userLiquidity provided.
    function computeClaim(uint totalClaimable, uint userLiquidity, uint totalLiquidity) public pure returns (uint) {
        return totalClaimable * userLiquidity / totalLiquidity;
    }

    /// @notice Gets the claim amount given an address. Returns bounty if address is reporter.
    function getClaimableAmount(address account) public pure returns(uint) {
        (,Balance[22] memory claims, , ) = getRawData();

        unchecked {
            for(uint i; i < claims.length; ++i) {
                if(claims[i].recipient == account) return claims[i].amount;
            }
        }

        return 0;
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