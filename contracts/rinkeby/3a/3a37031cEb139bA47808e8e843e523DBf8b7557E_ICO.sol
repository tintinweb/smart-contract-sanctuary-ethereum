// SPDX-License-Identifier: Unlicensed

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

// File: contracts/ICO.sol




pragma solidity ^0.8.0;





contract ICO{
    uint public amountRaised;
    address payable public wallet;
    
    IERC20 public token;
    uint public token_spent = 0;
    uint public presalePrice = 74000000000000;
    uint public seedsalePrice = 120000000000000;
    uint public finalsalePrice = 140000000000000;
    uint public token_price;
    

    
   
    uint256 private presale_limit=30*10**6*10**9;
    uint256 private seed_limit=50*10**6*10**9;
   
    constructor(address payable _wallet,IERC20 _token){
        require(_wallet!=address(0));
        wallet=_wallet;
        token=_token;
        token_price = presalePrice;
        } 
    
        
        function getTokenPrice() public view  returns(uint){
            return token_price;
        }
    
    
        
    
        function purchase(address payable _recepient) public payable {
            uint256 amount = msg.value;
            require(_recepient!=address(0)&& amount!=0);
            token_price=getTokenPrice();
            uint nOftokens=amountOfTokens(amount);
            amountRaised+=amount;
            token.transfer(_recepient,nOftokens);
            token_spent+=nOftokens;
            wallet.transfer(amount);
            if(token_spent<=presale_limit){
                token_price = presalePrice;
            }
            else if(token_spent>seed_limit){
                token_price =finalsalePrice;
            }
            else 
            token_price = seedsalePrice;        
        }
    function amountOfTokens(uint _amount)public view returns(uint){
        uint token_p= getTokenPrice();
        return (_amount/token_p);

    }    
}