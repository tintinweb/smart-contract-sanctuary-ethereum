/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


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

// File: contracts/Auction.sol



pragma solidity 0.8.7;



contract Auction{
    bool public isActive;
    mapping (address => uint256) public balances;
    uint256 totalEtherBalance;
    address owner;
    IERC20 prizeToken;
    uint256 public prizeAmount;
    bool onlyOnce;
    uint256 startTime;
    uint256 endTime;
    uint256 bidDelta = 0.1*10**18;
    uint256 maximumCeiling = 5*10**18;
    uint256 maximumBid;
    modifier onlyOwner(){
        require(msg.sender == owner, "Must be owner of contract");
        _;
    }

    modifier bidIsActive() {
        require (isActive, "Auction has expired");
        require(balances[msg.sender]+msg.value <= maximumCeiling, "Ceiling reached");
        require(startTime < endTime, "Time has passed");
        isActive = false;
        _;
    }

    modifier onceOnly(){
        require(!onlyOnce , "Already initialized");
        _;
        onlyOnce = true;
    }
    event auctionInitialized(address _owner, address _token, uint256 _time);
    constructor(
        address _prizeTokenAddress, 
        uint256 _endTime                //relative time from start time
        ){
        owner = msg.sender;
        prizeToken = (IERC20(_prizeTokenAddress));
        onlyOnce = false;
        isActive = true;
        startTime = block.timestamp;
        endTime = startTime + _endTime;
        emit auctionInitialized(owner,address(prizeToken),startTime);
    }

    function init () payable external onlyOwner onceOnly {     
        prizeToken.transferFrom(msg.sender,address(this),msg.value);
    }


    function updateBid() 
        external payable
        bidIsActive
        {            
            require(balances[msg.sender] + msg.value > maximumBid + bidDelta, "Bid must be atleast 0.1 higher than maximum bid");
            balances[msg.sender]+=msg.value;
            maximumBid = balances[msg.sender];
        }

    function withDraw()
        external
        {       
        require(!isActive,"Can not withdraw when bid is active");
        payable(msg.sender).transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
    }
}