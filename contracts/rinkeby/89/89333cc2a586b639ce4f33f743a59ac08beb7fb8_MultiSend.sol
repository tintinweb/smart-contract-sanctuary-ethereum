/**
 *Submitted for verification at Etherscan.io on 2022-09-30
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

// File: contracts/MultiSend.sol


pragma solidity 0.8.17;

contract MultiSend {
    
    // to save the owner of the contract in construction
    address private owner;
    
    // to save the amount of ethers in the smart-contract
    uint total_value;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    
    // modifier to check if the caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() payable{
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
        
        total_value = msg.value;  // msg.value is the ethers of the transaction
    }
    
    // the owner of the smart-contract can chage its owner to whoever 
    // he/she wants
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner; 
    }
    
    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
    
    // charge enable the owner to store ether in the smart-contract
    function charge() payable public isOwner {
        // adding the message value to the smart contract
        total_value += msg.value;
    }
    
    // sum adds the different elements of the array and return its sum
    function sum(uint[] memory amounts) private pure returns (uint retVal) {
        // the value of message should be exact of total amounts
        uint totalAmnt = 0;
        
        for (uint i=0; i < amounts.length; i++) {
            totalAmnt += amounts[i];
        }
        
        return totalAmnt;
    }
    
    // withdraw perform the transfering of ethers
    function withdraw(address payable receiverAddr, uint receiverAmnt) private {
        receiverAddr.transfer(receiverAmnt);
    }
    
    // withdrawls enable to multiple withdraws to different accounts
    // at one call, and decrease the network fee
    function withdrawls(address payable[] memory addrs, uint[] memory amnts) payable public isOwner {
        
        // first of all, add the value of the transaction to the total_value 
        // of the smart-contract
        total_value += msg.value;
        
        // the addresses and amounts should be same in length
        require(addrs.length == amnts.length, "The length of two array should be the same");
        
        // the value of the message in addition to sotred value should be more than total amounts
        uint totalAmnt = sum(amnts);
        
        require(total_value >= totalAmnt, "The value is not sufficient or exceed");
        
        
        for (uint i=0; i < addrs.length; i++) {
            // first subtract the transferring amount from the total_value
            // of the smart-contract then send it to the receiver
            total_value -= amnts[i];
            
            // send the specified amount to the recipient
            withdraw(addrs[i], amnts[i]);
        }
    }

    // withdraw perform the transfering of ethers
    //因为这里是合约调用代币地址的transferFrom, 所以from地址得给合约授权相关的数量
    function withdrawErc20(address token, address from, address receiverAddr, uint receiverAmnt) private {
        IERC20(token).transferFrom(from, receiverAddr, receiverAmnt);
    }
    
    // withdrawls enable to multiple withdraws to different accounts
    // at one call, and decrease the network fee
    function withdrawlsErc20(address token, address from, address [] memory addrs, uint[] memory amnts) public isOwner {

        // the addresses and amounts should be same in length
        require(addrs.length == amnts.length, "The length of two array should be the same");
        
        // the value of the message in addition to sotred value should be more than total amounts
        uint totalAmnt = sum(amnts);
        
        total_value = getWalletTokenBalance(from,token);

        require(total_value >= totalAmnt, "The value is not sufficient or exceed");
        
        for (uint i=0; i < addrs.length; i++) {
            // first subtract the transferring amount from the total_value
            // of the smart-contract then send it to the receiver
            total_value -= amnts[i];
            
            // send the specified amount to the recipient
            withdrawErc20(token, from, addrs[i], amnts[i]);
        }
    }

    //查询钱包地址
    function getWalletTokenBalance(address walletAddress, address token) public  view returns (uint256) {
        uint256 tokenBalance = IERC20(token).balanceOf(walletAddress);
        return tokenBalance;
    }
    
}