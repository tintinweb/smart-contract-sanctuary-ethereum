/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-12
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

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

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {

        _notEntered = true;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}



interface IRewardsDistributionRecipient {
    // function notifyRewardAmount(uint256 reward) external;
    function getRewardToken() external view returns (IERC20);
}

abstract contract RewardsDistributionRecipient is IRewardsDistributionRecipient {

    // @abstract
    // function notifyRewardAmount(uint256 reward) external;
    function getRewardToken() external virtual override view returns (IERC20);

    // This address has the ability to distribute the rewards
    address public rewardsDistributor;

    /** @dev Recipient is a module, governed by mStable governance */
    constructor(address _rewardsDistributor)
        internal
    {
        rewardsDistributor = _rewardsDistributor;
    }

    /**
     * @dev Only the rewards distributor can notify about rewards
     */
    modifier onlyRewardsDistributor() {
        require(msg.sender == rewardsDistributor, "Caller is not reward distributor");
        _;
    }
}

library StableMath {

    using SafeMath for uint256;

    uint256 private constant FULL_SCALE = 1e18;

    uint256 private constant RATIO_SCALE = 1e8;

    function getFullScale() internal pure returns (uint256) {
        return FULL_SCALE;
    }

    function getRatioScale() internal pure returns (uint256) {
        return RATIO_SCALE;
    }

    function scaleInteger(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return x.mul(FULL_SCALE);
    }

    function mulTruncate(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return mulTruncateScale(x, y, FULL_SCALE);
    }

    function mulTruncateScale(uint256 x, uint256 y, uint256 scale)
        internal
        pure
        returns (uint256)
    {
        // e.g. assume scale = fullScale
        // z = 10e18 * 9e17 = 9e36
        uint256 z = x.mul(y);
        // return 9e38 / 1e18 = 9e18
        return z.div(scale);
    }

    function mulTruncateCeil(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        // e.g. 8e17 * 17268172638 = 138145381104e17
        uint256 scaled = x.mul(y);
        // e.g. 138145381104e17 + 9.99...e17 = 138145381113.99...e17
        uint256 ceil = scaled.add(FULL_SCALE.sub(1));
        // e.g. 13814538111.399...e18 / 1e18 = 13814538111
        return ceil.div(FULL_SCALE);
    }

    function divPrecisely(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        // e.g. 8e18 * 1e18 = 8e36
        uint256 z = x.mul(FULL_SCALE);
        // e.g. 8e36 / 10e18 = 8e17
        return z.div(y);
    }

    function mulRatioTruncate(uint256 x, uint256 ratio)
        internal
        pure
        returns (uint256 c)
    {
        return mulTruncateScale(x, ratio, RATIO_SCALE);
    }

    function mulRatioTruncateCeil(uint256 x, uint256 ratio)
        internal
        pure
        returns (uint256)
    {
        // e.g. How much mAsset should I burn for this bAsset (x)?
        // 1e18 * 1e8 = 1e26
        uint256 scaled = x.mul(ratio);
        // 1e26 + 9.99e7 = 100..00.999e8
        uint256 ceil = scaled.add(RATIO_SCALE.sub(1));
        // return 100..00.999e8 / 1e8 = 1e18
        return ceil.div(RATIO_SCALE);
    }

    function divRatioPrecisely(uint256 x, uint256 ratio)
        internal
        pure
        returns (uint256 c)
    {
        // e.g. 1e14 * 1e8 = 1e22
        uint256 y = x.mul(RATIO_SCALE);
        // return 1e22 / 1e12 = 1e10
        return y.div(ratio);
    }

    function min(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return x > y ? y : x;
    }

    function max(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return x > y ? x : y;
    }

    function clamp(uint256 x, uint256 upperBound)
        internal
        pure
        returns (uint256)
    {
        return x > upperBound ? upperBound : x;
    }
}

contract Kohai is IERC20, Context {

    using StableMath for uint256;
    using SafeMath for uint256;
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    IERC20 public token = IERC20(0xd93540E87a08732D935C1EFf2B3df934f0A3a561);
    uint8 public stakeRate = 2;
    uint8 public lockRate = 2;
    string private _symbol;
    string private _name;
    uint256 private _decimals = 18;
    uint256 private totalReward = 100000000000000000000000;
    uint256 public cap = 4200000 * 1e18;
    address _owner = msg.sender;

modifier onlyOwner(){
    require(msg.sender == _owner);
    _;
}

    constructor () public {
        _name = 'Kohai';
        _symbol = 'KOHAI';
        _totalSupply = 100 * 1e18;
        _balances[msg.sender] = _totalSupply;
    }


    function name() public view returns (string memory) {
        return _name;
    }


    function symbol() public view returns (string memory) {
        return _symbol;
    }


    function decimals() public view returns (uint256) {
        return _decimals;
    }


    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
   
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
       

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    address public owner;

    uint256 public rewardPercent = 2; // 1%
   
    mapping(address => uint256) public lockingTimeStarts;
    mapping(address => uint256) public lockingTimeEnds;
    mapping(address => uint256) public lockedAmount;
    // Amount the user has staked
    mapping(address => uint256) public userStakedTokens;
    uint256 public stakeReward = 0;
    uint256 public totalStaked = 0;
    uint256 public lockReward = 0;
    uint256 public totalLocked = 0;

    // Reward the user will get after staking period ends
    mapping(address => uint256) public rewards;
    // Rewards paid to user
    mapping(address => uint256) public userRewardsPaid;
    // Stake starting timestamp
    mapping(address => uint256) public stakeStarted;
    // Stake ending timestamp
    mapping(address => uint256) public stakeEnded;

    event Locked(address indexed user, uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    /***************************************
                    MODIFIERS
    ****************************************/

    modifier isAccount(address _account) {
        require(!Address.isContract(_account), "Only external owned accounts allowed");
        _;
    }
   

    /***************************************
                    ACTIONS
    ****************************************/
   
        /****************************
                    LOCK
        ****************************/
   
   
    function lock(uint8 _days, uint256 amount) external {
        require(_days == 7 || _days == 30);
        require(lockingTimeStarts[msg.sender] == 0, 'you have already locked your tokens');
        token.transferFrom(msg.sender, address(this), amount);
        lockingTimeStarts[msg.sender] = block.timestamp;
        lockingTimeEnds[msg.sender] = block.timestamp + 100000;
        lockedAmount[msg.sender] = amount;
        totalLocked = totalLocked.add(amount);
        emit Locked(msg.sender, amount);
    }
   
    function unLock() external{
        require(lockedAmount[msg.sender] >= 0, 'you have not locked anything');
        //require (block.timestamp >= lockingTimeEnds[msg.sender], 'Locking time still remains');
        token.transfer(msg.sender, lockedAmount[msg.sender]);
        lockedAmount[msg.sender] = 0;
        _harvest(msg.sender);
    }
    
    function harvest() external{
        _harvest(msg.sender);
    }
   
   
    function _harvest(address sender) internal{
        require(lockedAmount[sender] >= 0, 'you have not locked anything');
        //require (block.timestamp >= lockingTimeEnds[msg.sender], 'Locking time still remains');
        uint256 lper = (lockedAmount[sender].mul(100)).div(totalLocked);
        uint256 reward = (lper.mul(totalReward)).div(100);
        lockingTimeStarts[sender] = 0;
        lockingTimeEnds[sender] = 0;
        totalLocked = totalLocked.sub(lockedAmount[sender]);
        mint(sender, reward);
    }
   
        /****************************
                    STAKE
        ****************************/
   
    function stake(uint256 _amount)
        external
    {
        _stake(msg.sender, _amount);
    }
   
   
    function _stake(address account, uint256 _amount)
        internal
       
    {
        require(userStakedTokens[account] == 0, 'You have already staked your LP tokens, to add more remove the exisiting one and add all again');
        token.transferFrom(account, address(this), _amount);
        stakeStarted[account] = block.timestamp;
        userStakedTokens[account] = userStakedTokens[account].add(_amount);
        totalStaked = totalStaked.add(_amount);
        emit Staked(account, _amount);

    }

    function unstake(uint256 amount)
        external
    {
        //require(block.timestamp >= stakeEnded[msg.sender], "Reward cannot be claimed before 30 days");
       
        _claimReward(msg.sender);
        withdraw(msg.sender, amount);
       
        stakeStarted[msg.sender] = 0;
        stakeEnded[msg.sender] = 0;
        _stake(msg.sender, userStakedTokens[msg.sender].sub(amount) );
        totalStaked = totalStaked.sub(amount);
    }
   

    function withdraw(address account, uint256 _amount)
        internal
        isAccount(msg.sender)
    {
        require(_amount > 0, "Cannot withdraw 0");
        //require(block.timestamp >= stakeEnded[account], "Reward cannot be claimed before staking ends");
        userStakedTokens[account] = userStakedTokens[account].sub(_amount);
        token.transfer(account, _amount);
        emit Withdrawn(account, _amount);
    }
    function claimRewards() external {
        _claimReward(msg.sender);
    }
   
    function _claimReward(address _account)
        internal
        isAccount(msg.sender)
    {
        //require(block.timestamp >= stakeEnded[_account], "Reward cannot be claimed before staking ends");
        uint256 time = block.timestamp;
        uint256 timeStaked = time.sub(stakeStarted[_account]);
        uint256 reward = userStakedTokens[_account].mul(stakeRate).mul(timeStaked).mul(stakeReward).div(totalStaked);
        //uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            stakeStarted[_account] = 0;
            mint(_account, reward);
            userRewardsPaid[_account] = userRewardsPaid[_account].add(reward);
            emit RewardPaid(_account, reward);
        }
    }

    /***************************************
                    GETTERS
    ****************************************/


    function tokensStaked(address _account)
        public
        view
        returns (uint256)
    {
        return userStakedTokens[_account];
    }

    function seeStakeRewards(address _account) view public returns(uint256){
       uint256 time = block.timestamp;
        uint256 timeStaked = time.sub(stakeStarted[_account]);
        uint256 reward = userStakedTokens[_account].mul(stakeRate).mul(timeStaked);
        return reward;
    }
    /***************************************
                    ADMIN
    ****************************************/
   
    function mint(address account, uint256 amount) internal virtual  {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
   
    function burn(address account, uint256 amount) public onlyOwner{
        _burn(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");


        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _beforeTokenTransfer(address from, uint256 amount) internal view virtual {
       
                if (from == address(0)) { // When minting tokens
            require(totalSupply().add(amount) <= cap, "ERC20Capped: cap exceeded");
        }
    }
   
   

}