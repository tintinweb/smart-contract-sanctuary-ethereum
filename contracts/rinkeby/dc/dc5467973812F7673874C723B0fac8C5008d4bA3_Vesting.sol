/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

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

// File: contracts/Vesting.sol


pragma solidity ^0.8.0;

contract Vesting{

    struct Investor{
        address investoraddress;
        string role;              //i.e. Advisor,Partnerships,Mentor  
        uint investedTokens;     //equivalent token invested for the amount.
        uint maturity;          //expiration
        uint token_claimed;     //claimed tokens
    }

    IERC20 token;
    uint public totalSupply;

    uint public priceOfToken = 1000;
    
    address admin;

    constructor(IERC20 tokenaddress){
        token = tokenaddress;
        admin = msg.sender;
        totalSupply = token.totalSupply();
        reserveforAdvisor = (5*(totalSupply)/100);                  //Initial reserve during TGE
        reserveforPartnerships = (10*(totalSupply)/100);
        reserveforMentors = (7*(totalSupply)/100);
    }

    mapping(address=>Investor) public investors;
    uint public reserveforAdvisor;    
    uint public reserveforPartnerships;
    uint public reserveforMentors;

    function tokenCalculator(uint amount) public view returns(uint){            //To calculate the no. of tokens 
        return amount/priceOfToken;                                             // for a given amount
    }

    function checkbalance(address user)public view returns(uint){
            require(msg.sender==admin||msg.sender==user,"Only admin can do that");
            return investors[user].investedTokens;
    }

    function checkuser(address user) public view returns(Investor memory){
        return investors[user];        
    }

    function  Invest(string memory role) payable public {               
        uint amount_invested = msg.value;
        require(msg.sender!= admin,"Admin cannot invest");
        require(amount_invested!=0,"Amount not specified");
        uint equivalentTokens = tokenCalculator(amount_invested);
        investors[msg.sender]=Investor(msg.sender,role,equivalentTokens,block.timestamp+60 days,0);
    }
    function selectionOfreserve(string memory role) public view returns(uint){
        if(keccak256(bytes(role))==keccak256(bytes("Advisor")))
            return reserveforAdvisor;
        else if(keccak256(bytes(role))==keccak256(bytes("Partnerships")))
            return reserveforPartnerships;
        else
            return reserveforMentors; 
    }
    function claim() public{
        require(investors[msg.sender].investedTokens!=0,"You are not an investor");
        Investor storage investor = investors[msg.sender];
        string memory role = investor.role;
        uint reserve = selectionOfreserve(role);
        require(reserve>0,"No token left");
        uint presentTime=block.timestamp;
        require(presentTime>investor.maturity,"Your amount is locked");
        uint claimableAmount;
        if(presentTime>(investor.maturity+100 seconds)){
            claimableAmount=investor.investedTokens;
        }
        else{
            claimableAmount=(investor.investedTokens)*((presentTime-investor.maturity)/(22*30 days));
            }        
        token.transfer(msg.sender,claimableAmount);
        investor.token_claimed+=claimableAmount;
        investor.investedTokens-=claimableAmount;
        balanceReserveAmount(investor.role,claimableAmount);
    }
    function balanceReserveAmount(string memory role,uint amount) private{
        if(keccak256(bytes(role))==keccak256(bytes("Advisor")))
            reserveforAdvisor-=amount;
        else if(keccak256(bytes(role))==keccak256(bytes("Partnerships")))
            reserveforPartnerships-=amount;
        else
            reserveforMentors-=amount; 
    }
    
}