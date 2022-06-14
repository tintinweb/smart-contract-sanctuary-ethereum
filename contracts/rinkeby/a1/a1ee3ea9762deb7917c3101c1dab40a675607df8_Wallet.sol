/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;







abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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






contract Wallet is Ownable {
    IERC20 public token;
    

    
    uint public liquidityBalance = 20 * 10 ** 6 * (10 ** 18); //Should be balance of Wallet contract;

    event Deposit(address indexed account, string id, uint indexed amount);
    event Withdraw(address indexed account, string id, uint indexed amount);
    
    mapping(address => uint256) private walletBalances;
    mapping(address => bool) public shouldBeApps;

    uint tokenPrice = 10000;    // 1 ETh = 10000 >>>>> where 10000BTM =1ETH
    uint EthPrice = 100;      


IERC20 public ethAddress;
    constructor(address _tokenAddress,address _ethAddress){
    token=IERC20(_tokenAddress);
    ethAddress=IERC20(_ethAddress);
       
    }
    function depositt() external payable{

    }

    function withdraw(address account, string memory id, uint _amount) public {
        // require(shouldBeApps[msg.sender], 'Not allowed to access withdrawal');
        require(_amount > 0, 'Withdraw amount should be greated than 0');

        uint currentBalance = walletBalances[account];
        require(currentBalance >= _amount, 'Insufficient wallet balance to withdraw');
        walletBalances[account] = currentBalance-(_amount);

        emit Withdraw(account, id, _amount);
    }
    
    function getApproval(uint amount) public {
        require(shouldBeApps[msg.sender], 'Not allowed to get approval');
        token.approve(msg.sender, amount);
    }

    function walletBalanceOf(address _addr) public view returns(uint){
        return walletBalances[_addr];
    }

    function setTokenAddress(address _addr) public onlyOwner {
        token = IERC20(_addr);
    }
    
    // function setApps(address _addr) public onlyOwner {
    //     shouldBeApps[_addr] = true;
    // }
    
    function setLiquidityBalance(uint _value) public onlyOwner {
        liquidityBalance = _value;
    }

   

   function swapeth1toBmT(uint amount) public { //get the user input in the line

//    require( ethAddress.balanceOf(msg.sender)>=amount,"check Balance"); //check user has the eth balance or not

   uint _cash=(tokenPrice *10**18);
   
//    uint _amount=(amount  *  _cash) ; 
   uint amounts=amount *10**18; // convert the eth token to the bmt token

       ethAddress.transferFrom(msg.sender,address(this),amounts); // transfer eth to the walletto the contract
       token.transfer(msg.sender,_cash); //transfer to the bmt token

     payable(msg.sender).transfer(address(this).balance);//this line allow user to get eth to bmt
    }

    

    function swapBmTToEth(uint amount) public { //get the user input in the line

        // require(token.balanceOf(msg.sender)>=amount,"check Balance"); //check user has the bmt token or not
        
         uint _amount=(amount/(tokenPrice  *10**18)) *10**18;//convert the bmt toten to eth
 
         token.transferFrom(msg.sender,address(this),amount);//token transfer bmt tot the wallet wallet send the bmt tot the contract

         ethAddress.transfer(msg.sender,_amount);//transfer eth to the wallet

         payable(msg.sender).transfer(address(this).balance);//this line allow user to get bmt to eth
    }

   


    function changeTokenPrice(uint _value) public onlyOwner {
        tokenPrice = _value;
    }

}