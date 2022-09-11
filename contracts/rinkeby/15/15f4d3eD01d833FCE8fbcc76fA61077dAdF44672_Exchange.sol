/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

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


contract Exchange {
    event Purchase(address indexed buyer, uint amount);
    event Sold(address indexed seller, uint amount);

    IERC20 public immutable token;
    address owner;
    address exchange = address(this);
    
    constructor(address _token){
        token = IERC20(_token);
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "You are not an owner =(");
        _;
    }

    function getEthBalance() public view returns(uint){
        return address(this).balance;
    }
    function getTokenBalance() public view returns(uint){
        return token.balanceOf(exchange);
    }

    function buyToken() public payable{
        require(msg.value >= 0.1 ether, "Pay up");
        uint tokenAvalible = getTokenBalance();
        uint tokenRate = msg.value / 1 ether; // 1 eth = 1 CWT

        require(tokenRate <= tokenAvalible, "Not enough tokens");

        token.transfer(msg.sender, tokenRate);
        emit Purchase(msg.sender, tokenRate);
    }

    function sellToken(uint _amount) external{
        require(_amount > 0, "Amount must be grater than 0");
        uint allowance = token.allowance(msg.sender, exchange);
        require(allowance >= _amount, "Wrong allowance");
        token.transferFrom(msg.sender, exchange, _amount);
        payable(msg.sender).transfer(_amount * 1 ether);
        emit Sold(msg.sender, _amount);
    }

    function withdraw(uint amount) external onlyOwner{
        require(amount <= getEthBalance(), "Not enough funds");
        payable(msg.sender).transfer(amount);
    }


}