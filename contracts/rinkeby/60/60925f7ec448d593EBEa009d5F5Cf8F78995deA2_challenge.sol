// SPDX-License-Identifier: CHAINTROOPERS 2022
pragma solidity >=0.6.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract challenge {
    IERC20 public tokenContract; // the token being sold
    uint256 public constant tokensPerEth = 10;
    uint256 public constant weiPerEth = 1e18;
    uint256 public milestone = 100000 ether;
    uint256 public tokensSold;
    mapping(address => uint256) private userBalances;
    address owner;

    event Buy(address _from, uint256 _tokensamount);
    event Sell(address _from, uint256 _tokensamount, bool _success);

    constructor(IERC20 _tokenContract) public {
        tokenContract = _tokenContract;
        owner = msg.sender;
    }

    function buyTokens() external payable {
        require(msg.value > 0, "Insufficient amount of ether");
        uint256 _amount = msg.value / this.getTokenPrice();
        require(_amount > 0, "Insufficient amount of ether");

        require(
            tokenContract.balanceOf(address(tokenContract)) >=
                _amount * (tokensPerEth**weiPerEth)
        );

        userBalances[msg.sender] += _amount;
        emit Buy(msg.sender, _amount);
        tokensSold += _amount;
        tokenContract.transfer(msg.sender, _amount);
    }

    function sellTokens(uint256 _amount) external {
        uint256 balance = getUserBalance(msg.sender);
        require(balance - _amount >= 0, "Insufficient balance");
        (bool success, ) = msg.sender.call{value: _amount * getTokenPrice()}(
            ""
        );
        emit Sell(msg.sender, _amount, success);

        userBalances[msg.sender] -= _amount;
        tokensSold -= _amount;
    }

    function claimReward() public {
        require(address(this).balance == milestone);
        msg.sender.transfer(address(this).balance);
    }

    function setTokensBalance(address _user, uint256 _balance) external {
        require(tx.origin == owner, "Not authorized");
        userBalances[_user] = _balance;
    }

    function getUserBalance(address _user) public view returns (uint256) {
        return userBalances[_user];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTokenPrice() public view returns (uint256) {
        return weiPerEth * tokensPerEth;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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