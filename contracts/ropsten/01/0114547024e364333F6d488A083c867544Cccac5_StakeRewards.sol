/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

pragma solidity >=0.7.0 <=0.8.4;
// PoC Proof of Contribution
// SPDX-License-Identifier: Unlicensed

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StakeRewards {

    address payable public owner;
    address tracker_0x_address = 0x2Cd49aAF81119940Cfaf7D2a4b93F60C6Db1543c; // NEUY Ropsten Address
    //address tracker_0x_address = 0xa80505c408C4DEFD9522981cD77e026f5a49FE63; // NEUY Ethereum Mainnet Address
    IERC20 token = IERC20(tracker_0x_address);
    mapping ( address => uint256 ) public balances;

        // event for EVM logging
    event OwnerSet(
        address indexed oldOwner, 
        address indexed newOwner
    );

    event TransferSent(
        address from, 
        address to,
        uint256 amount
    );

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    // Change owner
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = payable(newOwner);
    }

    // Balance of account for Contract
    function balanceOf(address account) external view returns (uint256) {
        return token.balanceOf(account);
    }

    function checkAllowance(address account) external view returns (uint256) {
        return token.allowance(msg.sender, account);
    }

    function checkContractAllowance() external view returns (uint256) {
        return token.allowance(msg.sender, address(this));
    }

    function approveContract(uint amount) external {
        token.approve(address(this),amount);
    }

    function depositRewards(uint256 amount) external payable onlyOwner {

        // add the deposited tokens into existing balance 
        balances[msg.sender]+= amount;

        // transfer the tokens from the sender to this contract
        token.transferFrom(msg.sender, address(this), amount);
        emit TransferSent(msg.sender,address(this), amount);
    }
    
    function returnRewards() public payable onlyOwner {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        token.transfer(msg.sender, amount);
    }

}