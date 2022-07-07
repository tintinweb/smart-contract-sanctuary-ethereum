//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    function balanceOf(address account) external view returns (uint256);
    
    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
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
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
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
}
/**
    Locked KEYS Contract
    Auto Compounding Staking Protocol
 */
contract LockedKeys is Ownable, IERC20 {

    using SafeMath for uint256;

    // Staking Token
    IERC20 public immutable token;

    // Staking Protocol Token Info
    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;

    // Trackable User Info
    struct UserInfo {
        uint256 balance;
        uint256 unlockBlock;
        uint256 totalStaked;
        uint256 totalWithdrawn;
    }
    // User -> UserInfo
    mapping ( address => UserInfo ) public userInfo;

    // Unstake Early Fee
    uint256 public leaveEarlyFee;

    // Timer For Leave Early Fee
    uint256 public leaveEarlyFeeTimer;

    // total supply of MAXI
    uint256 private _totalShares;

    // Swapper To Purchase Token From ETH
    address public tokenSwapper;

    // precision factor
    uint256 private constant precision = 10**18;

    // Reentrancy Guard
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrancy Guard call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    // Events
    event PriceChange(uint256 previous, uint256 current, uint256 totalMAXISupply);
    event Deposit(address depositor, uint256 amountToken);
    event Withdraw(address withdrawer, uint256 amountToken);
    event FeeTaken(uint256 fee);

    constructor(
        string memory name_, 
        string memory symbol_,
        address token_,
        address tokenSwapper_,
        uint256 leaveEarlyFee_,
        uint256 leaveEarlyFeeTimer_
    ) {

        require(token_ != address(0), 'Zero Address');
        require(tokenSwapper_ != address(0), 'Zero Address');
        require(leaveEarlyFee_ <= 100, 'Fee Too High');
        require(leaveEarlyFeeTimer_ <= 10**7, 'Fee Timer Too Long');

        // pair token data
        _name = name_;
        _symbol = symbol_;
        _decimals = IERC20(token_).decimals();

        // staking data
        leaveEarlyFee = leaveEarlyFee_;
        leaveEarlyFeeTimer = leaveEarlyFeeTimer_;
        tokenSwapper = tokenSwapper_;

        // pair staking token
        token = IERC20(token_);

        // set reentrancy
        _status = _NOT_ENTERED;
        
        // emit transfer so bscscan registers contract as token
        emit Transfer(address(0), msg.sender, 0);
    }

    function name() external view override returns (string memory) {
        return _name;
    }
    function symbol() external view override returns (string memory) {
        return _symbol;
    }
    function decimals() external view override returns (uint8) {
        return _decimals;
    }
    function totalSupply() external view override returns (uint256) {
        return token.balanceOf(address(this));
    }

    /** Shows The Value Of Users' Staked Token */
    function balanceOf(address account) public view override returns (uint256) {
        return ReflectionsFromContractBalance(userInfo[account].balance);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        if (recipient == msg.sender) {
            withdraw(amount);
        }
        return true;
    }
    function transferFrom(address, address recipient, uint256 amount) external override returns (bool) {
        if (recipient == msg.sender) {
            withdraw(amount);
        }        
        return true;
    }

    function setLeaveEarlyFee(uint256 newLeaveEarlyFee) external onlyOwner {
        require(
            newLeaveEarlyFee <= 100,
            'Early Fee Too High'
        );
        leaveEarlyFee = newLeaveEarlyFee;
    }
    function setLeaveEarlyFeeTimer(uint256 newLeaveEarlyFeeTimer) external onlyOwner {
        require(
            newLeaveEarlyFeeTimer <= 10**7,
            'Fee Timer Too High'
        );
        leaveEarlyFeeTimer = newLeaveEarlyFeeTimer;
    }
    function setTokenSwapper(address newTokenSwapper) external onlyOwner {
        require(
            newTokenSwapper != address(0),
            'Zero Address'
        );
        tokenSwapper = newTokenSwapper;
    }

    function withdrawETH() external onlyOwner {
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s, 'Error On ETH Withdrawal');
    }

    function recoverForeignToken(IERC20 _token) external onlyOwner {
        require(
            address(_token) != address(token),
            'Cannot Withdraw Staking Tokens'
        );
        require(
            _token.transfer(msg.sender, _token.balanceOf(address(this))),
            'Error Withdrawing Foreign Token'
        );
    }

    /** 
        ETH Sent To Contract Will Buy And Stake Token
     */
    receive() external payable {
        _deposit(msg.value, true);
    }

    /**
        Transfers in `amount` of Token From Sender
        And Locks In Contract, Minting MAXI Tokens
     */
    function deposit(uint256 amount) external {
        _deposit(amount, false);
    }

    /**
        Redeems `amount` of Underlying Tokens, As Seen From BalanceOf()
     */
    function withdraw(uint256 amount) public nonReentrant returns (uint256) {

        // Token Amount Into Contract Balance Amount
        uint MAXI_Amount = amount == balanceOf(msg.sender) ? userInfo[msg.sender].balance : TokenToContractBalance(amount);

        require(
            userInfo[msg.sender].balance > 0 &&
            userInfo[msg.sender].balance >= MAXI_Amount &&
            balanceOf(msg.sender) >= amount &&
            amount > 0 &&
            MAXI_Amount > 0,
            'Insufficient Funds'
        );

        // burn MAXI Tokens From Sender
        _burn(msg.sender, MAXI_Amount, amount);

        // increment total withdrawn
        userInfo[msg.sender].totalWithdrawn += amount;

        // Take Fee If Withdrawn Before Timer
        uint fee = remainingLockTime(msg.sender) == 0 ? 100 : amount.mul(leaveEarlyFee).div(1000);

        // send amount less fee
        uint256 sendAmount = amount.sub(fee);

        // ensure round off protection
        uint256 bal = token.balanceOf(address(this));
        if (sendAmount > bal) {
            sendAmount = bal;
        }

        // transfer amount to sender
        require(
            token.transfer(msg.sender, sendAmount),
            'Error On Token Transfer'
        );

        // emit event
        emit Withdraw(msg.sender, sendAmount);
        return sendAmount;
    }

    function donate() external payable nonReentrant {
        // buy staking token
        _buyToken(address(this).balance);
    }

    /**
        Handles Deposits Internally
     */
    function _deposit(uint256 amount, bool wETH) internal nonReentrant {

        // Ensure Positive Transfer Amount
        require(
            amount > 0,
            'Zero Amount'
        );

        // Track Balance Before Deposit
        uint previousBalance = token.balanceOf(address(this));

        // fetch keys token
        uint received = wETH ? _buyToken(amount) : _transferIn(amount);

        if (_totalShares == 0 || previousBalance == 0) {
            // mint first batch to holders
            _registerFirstPurchase(received);
        } else {

            // mints correct token amount to sender given data
            _mintTo(msg.sender, received, previousBalance);
        }
    }

    /**
        Registers the First Stake
     */
    function _registerFirstPurchase(uint received) internal {
        
        // increment total staked
        userInfo[msg.sender].totalStaked += received;

        // mint MAXI Tokens To Sender
        _mint(msg.sender, received, received);

        emit Deposit(msg.sender, received);
    }

    function _mintTo(address sender, uint256 received, uint256 previousBalance) internal {
        // Number Of Maxi Tokens To Mint
        uint nToMint = (_totalShares.mul(received).div(previousBalance)).sub(100);
        require(
            nToMint > 0,
            'Zero To Mint'
        );

        // increment total staked
        userInfo[sender].totalStaked += received;

        // mint MAXI Tokens To Sender
        _mint(sender, nToMint, received);

        emit Deposit(sender, received);
    }

    function _buyToken(uint amount) internal returns (uint256) {
        require(
            amount > 0,
            'Zero Amount'
        );
        uint before = token.balanceOf(address(this));
        (bool s,) = payable(tokenSwapper).call{value: amount}("");
        require(s, 'Failure On Token Purchase');
        uint received = token.balanceOf(address(this)).sub(before);
        require(received > 0, 'Zero Received');
        return received;
    }

    function _transferIn(uint256 amount) internal returns (uint256) {
        uint before = token.balanceOf(address(this));
        require(
            token.transferFrom(msg.sender, address(this), amount),
            'Failure On TransferFrom'
        );
        uint received = token.balanceOf(address(this)).sub(before);
        require(
            received <= amount && received > 0,
            'Error On Transfer In'
        );
        return received;
    }

    /**
     * Burns `amount` of Contract Balance Token
     */
    function _burn(address from, uint256 amount, uint256 amountToken) private {
        userInfo[from].balance = userInfo[from].balance.sub(amount);
        _totalShares = _totalShares.sub(amount);
        emit Transfer(from, address(0), amountToken);
    }

    /**
     * Mints `amount` of Contract Balance Token
     */
    function _mint(address to, uint256 amount, uint256 underlyingValue) private {
        // allocate
        userInfo[to].balance = userInfo[to].balance.add(amount);
        _totalShares = _totalShares.add(amount);
        // update locker info
        userInfo[msg.sender].unlockBlock = block.number + leaveEarlyFeeTimer;
        emit Transfer(address(0), to, underlyingValue);
    }


    /**
        Converts A Staking Token Amount Into A MAXI Amount
     */
    function TokenToContractBalance(uint256 amount) public view returns (uint256) {
        return amount.mul(precision).div(_calculatePrice());
    }

    /**
        Converts A MAXI Amount Into A Token Amount
     */
    function ReflectionsFromContractBalance(uint256 amount) public view returns (uint256) {
        return amount.mul(_calculatePrice()).div(precision);
    }

    /** Conversion Ratio For MAXI -> Token */
    function calculatePrice() external view returns (uint256) {
        return _calculatePrice();
    }

    /**
        Lock Time Remaining For Stakers
     */
    function remainingLockTime(address user) public view returns (uint256) {
        return userInfo[user].unlockBlock < block.number ? 0 : userInfo[user].unlockBlock - block.number;
    }

    /** Returns Total Profit for User In Token From MAXI */
    function getTotalProfits(address user) external view returns (uint256) {
        uint top = balanceOf(user) + userInfo[user].totalWithdrawn;
        return top <= userInfo[user].totalStaked ? 0 : top - userInfo[user].totalStaked;
    }
    
    /** Conversion Ratio For MAXI -> Token */
    function _calculatePrice() internal view returns (uint256) {
        uint256 backingValue = token.balanceOf(address(this));
        return (backingValue.mul(precision)).div(_totalShares);
    }

    /** function has no use in contract */
    function allowance(address, address) external pure override returns (uint256) { 
        return 0;
    }
    /** function has no use in contract */
    function approve(address spender, uint256) public override returns (bool) {
        emit Approval(msg.sender, spender, 0);
        return true;
    }
}