/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
pragma solidity ^0.8.17;

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
contract Stake{
    address public tokenAddress ;
    IERC20 private token;
    constructor(address _tokenAddress){
        tokenAddress=_tokenAddress;
        token=IERC20(tokenAddress);
    }
    struct data{
        uint256 timestart;
        uint256 timeEnd;
        uint256 reward;
        uint256 balance;
        bool staked;
    }
    uint public time=60*60*24*30;

    mapping(address=>data) public Rewards;
    
    function stake() public {
        require(!Rewards[msg.sender].staked,"already staked");
        uint256 bal=(token.balanceOf(msg.sender));
        if (bal>10e18 && bal<200000*10e18) {
            data memory copy =data(block.timestamp,(block.timestamp)+time,(bal*5)/1000,bal,true);
            Rewards[msg.sender]=copy;
        }
        if (bal>200001*10e18 && bal<500000*10e18) {
             data memory copy =data(block.timestamp,(block.timestamp)+time,bal/100,bal,true);
            Rewards[msg.sender]=copy;  
        }
        if (bal>500001*10e18 && bal<2000001*10e18) {
             data memory copy =data(block.timestamp,(block.timestamp)+time,(bal*15)/1000,bal,true);
            Rewards[msg.sender]=copy;
           
        }
        if (bal>2000001*10e18 && bal<5000001*10e18) {
             data memory copy =data(block.timestamp,(block.timestamp)+time,(bal*20)/1000,bal,true);
            Rewards[msg.sender]=copy;
        }
        if ( bal>5000001*10e18) {
          data memory copy =data(block.timestamp,(block.timestamp)+time,(bal*25)/1000,bal,true);
            Rewards[msg.sender]=copy;
        }
    }
    function unstake() public {
         require(token.balanceOf(address(this))>=Rewards[msg.sender].reward,"balance is low");
        if (block.timestamp<Rewards[msg.sender].timeEnd) {
            bool transfer=token.transfer(0x0000000000000000000000000000000000000000,Rewards[msg.sender].reward);
            require(transfer==true,"transfer failed");
            Rewards[msg.sender].reward=0;
        }
        else{
            uint256 bal=(token.balanceOf(msg.sender));
            if (bal<Rewards[msg.sender].balance) {
                 bool transfer=token.transfer(0x0000000000000000000000000000000000000000,Rewards[msg.sender].reward);
            require(transfer==true,"transfer failed");
            Rewards[msg.sender].reward=0;
            }else {
                bool transfer=token.transfer(msg.sender,Rewards[msg.sender].reward);
            require(transfer==true,"transfer failed");
            Rewards[msg.sender].reward=0;
            }
        }
    }
    function balance(address _add) public view returns(uint){
        return token.balanceOf(_add);
    }
   
}