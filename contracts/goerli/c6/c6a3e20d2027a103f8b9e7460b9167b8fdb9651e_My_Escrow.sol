/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

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

// File: contracts/4_Escrow.sol


pragma solidity ^0.8.14;


contract My_Escrow {
    
    address public owner;
    address[] public payees;

    address _tokenContract = 0xE69aBe2B0C222d0176E965DcF2Cbe01a78b44003; //Goerli ERC20
    IERC20 token = IERC20(_tokenContract);
    constructor() {
        owner = msg.sender;
    }
    event Deposited(address indexed depositor, address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);
    event Rewarded(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

  
    function deposit(address payee, uint256 amount) public  {
        require(amount>0);
        require(token.balanceOf(msg.sender) >= amount, "You need to have tokens more than amount first!");
        require(token.allowance(msg.sender,address(this)) >= amount, "You need to approve tokens more than amount first!");
        token.transferFrom(msg.sender, address(this), amount); 

        if(_deposits[payee]==0) {
            payees.push(payee);
        }
        _deposits[payee] += amount;
        
        emit Deposited(msg.sender, payee, amount);
    }

    function withdraw() public  {
        address payee = msg.sender;
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;
         
        token.transfer(payee, payment);

        emit Withdrawn(payee, payment);
    }

    function _get_largest_payee() public view returns(address){
        address largest_payee;
        uint256 largest_payment = 0;
        uint256 length = payees.length;
        if(length == 0 ) {
            return address(0x0);
        }
        for(uint256 i=0; i < length;) {
            address payee = payees[i];
            uint256 payment = _deposits[payee];
            unchecked { ++i; }
            if(payment > largest_payment) { 
                largest_payee = payee;
                largest_payment =  payment;
            }
        }
        return largest_payee;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _; 
    }

    function reward_largest_payee(uint256 amount) public onlyOwner (){
        address payee = _get_largest_payee();
        require(token.balanceOf(address(this)) >=amount , "You need to send more tokens to the contract first!");
        token.transfer(payee, amount);
        emit Rewarded(payee, amount);
    }
}