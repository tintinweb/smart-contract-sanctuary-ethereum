// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract VolatilityMarket{

    address owner;

    IERC20 public token;

    enum decision {POSITIVE,NEGATIVE}

    uint256 disposableFunds = 0;
    uint256 requiredFunds = 1 wei;
    uint blockBuffer = 1 minutes;
    uint ticketCount = 0;

    struct ticket {
        uint id;
        address owner;
        uint betTime;
        uint amount;
        bool success;
        bool claimed;
    }

    mapping(uint => ticket) public tickets;

    event TicketCreated(uint id, address user);

    constructor(address _token){
        token = IERC20(_token);
    }

    //functions that will direclty be invoked from the frontend

    function createBet(uint256 amount) public {
        token.transferFrom(msg.sender, address(this), amount);
        uint256 id  = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp)));
        tickets[id]= ticket(id,msg.sender, block.timestamp, amount, false,false);
        //call request data to get the intial price 
        emit TicketCreated(id, msg.sender);
    }


    //Ticket is redeemed only within the time period
    function redeemTicket(uint id) public {

        ticket memory currentTicket = tickets[id];
        require(block.timestamp > (currentTicket.betTime + blockBuffer));
        require(currentTicket.amount < disposableFunds);

    }

    // function verifyData() internal returns (bool) {
    //     return true; 
    // }

   
    // function  collectDeadTickets() internal{
        
    // }



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