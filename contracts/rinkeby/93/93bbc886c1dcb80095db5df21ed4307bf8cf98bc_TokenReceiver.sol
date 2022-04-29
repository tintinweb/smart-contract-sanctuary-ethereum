/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: interact.sol


pragma solidity ^0.8.3;


/**
 * @title TokenReceiver
 * @dev Very simple example of a contract receiving ERC20 tokens.
 */
contract TokenReceiver {

    IERC20 public parentTOKEN;

    struct Stake {
        uint256 tokenAmount;
        uint256 timestamp;
    }
        mapping(address => Stake) public stakes;

    // map staker to total staking time 
    mapping(address => uint256) public stakingTime;    


    /**
     * @dev Constructor sets token that can be received
     */
    constructor () {
       parentTOKEN = IERC20(0x475546d326F092620DD0E9672f61d6a68eb6ab1b);
    }

     function stake(uint256 _tokenAmount) public {
        stakes[msg.sender] = Stake(_tokenAmount,block.timestamp); 
        parentTOKEN.transferFrom(msg.sender, address(this), _tokenAmount);
    } 

    function unstake() public {
        parentTOKEN.transferFrom(address(this), msg.sender, stakes[msg.sender].tokenAmount);
        stakingTime[msg.sender] += (block.timestamp - stakes[msg.sender].timestamp);
        delete stakes[msg.sender];
    }      

     /*function onERC20Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(keccak256("onERC20Received(address,address,uint256,uint256,bytes)"));
    }

}*/
}