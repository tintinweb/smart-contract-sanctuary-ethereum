/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

// File: WithoutCond/IERC20.sol
// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IERC20Metadata {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 is IERC20Metadata {
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

// File: WithoutCond/P2pWC.sol


pragma solidity ^0.8.0;


contract p2pBetWC{
    address immutable admin;
    IERC20 immutable token;


    constructor(){
        admin = payable(msg.sender);
        token = IERC20(0xe10DCe92fB554E057619142AbFBB41688A7e8D07);
    }


    
    mapping(address => mapping(uint => uint)) public betidToStake;
    mapping(uint => uint) public betIdtoTotal;
    mapping(uint => uint) public betidCount;
    mapping(address => mapping(uint => bool)) public CalledFinalise;
    
    


    function Stake(uint betid, uint stakeAmount, address staker) external{
        require(betidCount[betid] < 2, "SF");//Stake Full
        

        // if(betIdtoTotal[betid] == 0){
        //    token.approve(address(this), stakeAmount);
        //     token.transferFrom(msg.sender, address(this), stakeAmount);
        //      betidToStake[msg.sender][betid] = stakeAmount;
        //      betIdtoTotal[betid] += stakeAmount;
        //      betidCount[betid] ++;
        // }   
        // else {
        //     if(betIdtoTotal[betid] == stakeAmount){
        //     //token.approve(address(this), stakeAmount);
        //      token.transferFrom(msg.sender, address(this), stakeAmount);
        //      betidToStake[msg.sender][betid] = stakeAmount;
        //      betIdtoTotal[betid] += stakeAmount;
        //      betidCount[betid] ++;
        //     } else

        //     if(betIdtoTotal[betid] > 0){
        //         if(betIdtoTotal[betid] > stakeAmount || betIdtoTotal[betid] < stakeAmount){
        //         revert("TLTM");//Too little or too much
        //         }
        //     }
             
        // }

         token.transferFrom(staker, address(this), stakeAmount);
             betidToStake[staker][betid] = stakeAmount;
             betIdtoTotal[betid] += stakeAmount;
             betidCount[betid] ++;
        
    }



    function finalise(uint betid, address receiver) external{

        require(betidToStake[receiver][betid]> 0, "DNS");//DId not stake
        require(!CalledFinalise[receiver][betid], "ACF");//Already called finalise

        uint fee = betIdtoTotal[betid] * 1000/10000;
        
        uint newAmount = betIdtoTotal[betid] - fee;


            delete betidToStake[receiver][betid];
            delete betIdtoTotal[betid];

            token.transfer(receiver, newAmount); 

            // token.transfer(admin, fee);

            CalledFinalise[receiver][betid] = true;


        
    }

    
}