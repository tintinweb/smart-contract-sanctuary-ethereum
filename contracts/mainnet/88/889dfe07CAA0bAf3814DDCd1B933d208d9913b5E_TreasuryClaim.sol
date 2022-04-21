/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

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


contract TreasuryClaim {
    address[] public tokens;
    mapping(address => uint256) public rates; // Should set in the decimal of underlying token
    address public lobi;
    address public governance;
    struct Claimable {
        address _token;
        uint256 _amount;
    }
    event RateSet(address token, uint256 rate);
    event GovernanceSet(address _governance);
    event Claimed(address user, address token, uint256 amount);

    constructor(address[] memory _tokens, address _lobi) {
        require(_lobi != address(0), "!zero address");
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokens.push(_tokens[i]);
        }
        lobi = _lobi;
        governance = msg.sender;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    function setRate(address _token, uint256 _rate) external onlyGovernance {
        rates[_token] = _rate;
        emit RateSet(_token, _rate);
    }

    function addToken(address _token) external onlyGovernance {
        tokens.push(_token);
    }

    function removeToken(address _token) external onlyGovernance {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == _token) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }
    }

    function transferGovernance(address _newGovernance)
        external
        onlyGovernance
    {
        governance = _newGovernance;
        emit GovernanceSet(governance);
    }

    function claim(uint256 amount) external {
        IERC20(lobi).transferFrom(msg.sender, address(this), amount);
        uint256 length = tokens.length;
        for (uint256 i; i < length; i++) {
            uint256 redeemAmount = (amount * rates[tokens[i]]) / 1e9;
            IERC20(tokens[i]).transfer(msg.sender, redeemAmount);
            emit Claimed(msg.sender, tokens[i], redeemAmount);
        }
    }

    function recoverTokens(address token, uint256 amount)
        external
        onlyGovernance
    {
        require(token != lobi, "Lobis locked until forever");
        IERC20(token).transfer(governance, amount);
    }

    function claimable(uint256 amount)
        external
        view
        returns (Claimable[] memory)
    {
        Claimable[] memory claimables = new Claimable[](tokens.length);
        for (uint256 i; i < tokens.length; i++) {
            uint256 redeemAmount = (amount * rates[tokens[i]]) / 1e9;
            claimables[i] = Claimable(tokens[i], redeemAmount);
        }
        return claimables;
    }
}