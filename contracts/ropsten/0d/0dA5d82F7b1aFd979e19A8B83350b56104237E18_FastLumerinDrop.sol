/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: contracts/FastDrop.sol


pragma solidity ^0.8.0;
/*
 * @title Contract for Fast Lumerin Token Widthdrawl
 *
 * @notice ERC20 support for beneficiary wallets to quickly obtain Tokens without following vesting schedule.
 *
 * @author Lance Seidman (Titan Mining/Lumerin Protocol)
 *
 * @dev Statuses
 * 0 = Normal Mode
 * 1 = Pending Transaction
 * 2 = Completed Transaction
 */


contract FastLumerinDrop {
    address owner;
    uint walletCount;
 
    IERC20 Lumerin = IERC20(0xF03784818F6f197299c8c63f179a27C94C481C9F);

    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);

    struct Whitelist {
        address wallet;
        uint qty;
        uint status;
    }
    mapping(address => Whitelist) public whitelist;
    constructor() {
        owner = msg.sender;      
                                                                                                                                                                                                                                                                                                                                      
    }
    modifier onlyOwner() {
      require(msg.sender == owner, "Sorry, only owner of this contract can perform this task!");
      _;
    }
    receive() payable external {
        emit TransferReceived(msg.sender, msg.value);
    }    
    function addWallet (address walletAddr, uint _qty) external onlyOwner {
        whitelist[walletAddr].wallet = walletAddr;
        whitelist[walletAddr].qty = _qty;
    }
    function addMultiWallet (address[] memory walletAddr, uint[] memory _qty) external onlyOwner {
        for (uint i=0; i< walletAddr.length; i++) {
            whitelist[walletAddr[i]].wallet = walletAddr[i]; 
            whitelist[walletAddr[i]].qty = _qty[i];
            walletCount++;
        }
    }
    function updateWallet (address walletAddr, uint _qty) internal {
        require(walletAddr == msg.sender, 'Unable to update wallet!');
        whitelist[walletAddr].qty = _qty;
    }
    function updateWallets (address walletAddr, uint _qty) external onlyOwner {
        whitelist[walletAddr].qty = _qty;
    }
    function checkWallet (address walletAddress) external view returns (bool status) {
        if(whitelist[walletAddress].wallet == walletAddress) {
            status = true;
        }
        return status;
    }
    function VestingTokenBalance() view public returns (uint) {
        return Lumerin.balanceOf(address(this));
    }
    function Claim() external payable {
        address incoming = msg.sender;
        require(whitelist[incoming].qty > 0 || whitelist[incoming].wallet != incoming || whitelist[incoming].status != 1 || whitelist[incoming].status != 2, 'Must be whitelisted with a Balance or without Pending Claims!');
        uint qtyWidthdrawl = whitelist[incoming].qty;
        whitelist[incoming].status = 1;
        Lumerin.transfer(incoming, qtyWidthdrawl);
        whitelist[incoming].status = 2;
        updateWallet(incoming,0);
        emit TransferSent(incoming, incoming, whitelist[incoming].qty);  
    } 
    function TransferLumerin(address to, uint amount) external onlyOwner payable{
        require(msg.sender == owner, "Contract Owner can transfer Tokens only!"); 
        uint256 LumerinBalance = Lumerin.balanceOf(address(this));
        require(amount <= LumerinBalance, "Token balance is too low!");
        Lumerin.transfer(to, amount);
        emit TransferSent(msg.sender, to, whitelist[to].qty);
    }  
}