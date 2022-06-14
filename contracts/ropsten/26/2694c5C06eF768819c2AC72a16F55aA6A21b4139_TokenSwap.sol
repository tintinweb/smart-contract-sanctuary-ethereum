/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/IERC20.sol



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

// File: contracts/TokenSwap.sol


pragma solidity ^0.8.13;


/*
How to swap tokens

1. Alice has 100 tokens from AliceCoin, which is a ERC20 token.
2. Bob has 100 tokens from BobCoin, which is also a ERC20 token.
3. Alice and Bob wants to trade 10 AliceCoin for 20 BobCoin.
4. Alice or Bob deploys TokenSwap
5. Alice approves TokenSwap to withdraw 10 tokens from AliceCoin
6. Bob approves TokenSwap to withdraw 20 tokens from BobCoin
7. Alice or Bob calls TokenSwap.swap()
8. Alice and Bob traded tokens successfully.
*/

contract TokenSwap {
    IERC20 public token1;
    address public tokenOwner;
    uint public amount;
    uint public rate;
    bool public isIcoRunning = false;

    constructor(
        address _token1,
        address _tokenOwner
    ) {
        token1 = IERC20(_token1);
        tokenOwner = _tokenOwner;
        rate = 1000;
    }

    function deposit() payable public {
        amount = msg.value;
    }
    function updateIcoStatus(bool _isIcoRunning) public {
        require(msg.sender == tokenOwner, "Not authorized");
        isIcoRunning = _isIcoRunning;
    }

    function swap(address _owner2) payable public {
        require(isIcoRunning == true, "Ico not running");
        require(msg.sender == tokenOwner || msg.sender == _owner2, "Not authorized");
        // require(
        //     token2.allowance(owner2, address(this)) >= amount2,
        //     "Token 2 allowance too low"
        // );
        amount = rate * msg.value;

        require(
            token1.allowance(tokenOwner, address(this)) >= amount,
            "Token 1 allowance too low"
        );
        
        _safeTransferFrom(token1, tokenOwner, _owner2, amount);
        // _safeTransferFrom(token2, owner2, tokenOwner, amount2);
    }

    function _safeTransferFrom(
        IERC20 token,
        address sender,
        address recipient,
        uint _amount
    ) private {
        bool sent = token.transferFrom(sender, recipient, _amount);
        require(sent, "Token transfer failed");
    }
}