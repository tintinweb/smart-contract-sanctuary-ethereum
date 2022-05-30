pragma solidity >= 0.5.0 < 0.6.0;

import "./TokenInfoLib.sol";
import "./SymbolsLib.sol";
import "./SafeMath.sol";
import "./SignedSafeMath.sol";
import "./Ownable.sol";
import "./SavingAccountParameters.sol";
import "./IERC20.sol";
import "./ABDK.sol";
import "./tokenbasic.sol";
import "./bkk.sol";

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
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

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;





/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}




interface AllPool{
    function is_Re(address user) view external  returns(bool);
    // function set_user_isRe(address user,address pool,string calldata name) external;
    function get_Address_pool(address user) view external  returns(address);
}

interface IPlayerBook {
    function settleReward( address from,uint256 amount ) external returns (uint256);
}
contract SavingAccount is Ownable{
	using TokenInfoLib for TokenInfoLib.TokenInfo;
	using SymbolsLib for SymbolsLib.Symbols;
	using SafeMath for uint256;
	using SignedSafeMath for int256;
	using SafeERC20 for IERC20;

	
	event depositTokened(address onwer,uint256 amount,address tokenaddress);
	event withdrawed(address onwer,uint256 amount,address tokenaddress);
	event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    
    
	bool _hasStart = false;
	uint256 public _initReward = 0;
	
	IERC20 public _pros = IERC20(0x306Dd7CD66d964f598B4D2ec92b5a9B275D7fEb3);
    address public _teamWallet = 0x89941E92E414c88179a830af5c10bde0E9245158;
	address public _playbook = 0x21A4086a6Cdb332c851B76cccD21aCAB6428D9E4;
	address public _allpool = 0xC682bD99eE552B6f7d931aFee2A9425806e155E9;
	

	address public _ETH = 0x000000000000000000000000000000000000000E;
	address public _USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
	address public _PROS = 0x306Dd7CD66d964f598B4D2ec92b5a9B275D7fEb3;
	uint256 DURATION = 1 days;
	
    int128 dayNums = 0;

    int128 baseReward = 80000;
    
    uint256 public base_ = 20*10e3;
    uint256 public rate_forReward = 1;
    uint256 public base_Rate_Reward = 100;

	struct Account {
		mapping(address => TokenInfoLib.TokenInfo) tokenInfos;
		bool active;
	}
// 	int256 public totalReward;
	mapping(address => Account) accounts;
	mapping(address => int256) totalDeposits;
	mapping(address => int256) totalLoans;
	mapping(address => int256) totalCollateral;
    mapping(address => bool) loansAccount;
	address[] activeAccounts;
	address[] activeLoansAccount;

    mapping(address => uint256)_initTokenReward;
    uint256 public _startTime =  now + 365 days;
    uint256 public _periodFinish = 0;
    uint256 public _rewardRate = 0;
    
    mapping(address =>uint256) public _rewardRateList;
    // uint256 public _lastUpdateTime;
    mapping(address=>uint256) public _lastUpdateTime;
    // uint256 public _rewardPerTokenStored;
    mapping(address=>uint256) public _rewardPerTokenStored;
    uint256 public _teamRewardRate = 0;
    uint256 public _poolRewardRate = 0;
    uint256 public _baseRate = 10000;
    uint256 public _punishTime = 10 days;
    
    uint256 public one_Rate = 90;
    uint256 public sec_Rate = 5;
    uint256 public thr_Rate = 5;
    uint256 public BASE_RATE_FORREWARD = 100;
    
    
    mapping(address => mapping(address=>uint256)) public _userRewardPerTokenPaid;
    mapping(address => mapping(address=>uint256)) public _rewards;
    mapping(address => mapping(address=>uint256)) public _lastStakedTime;
	SymbolsLib.Symbols symbols;
	int256 constant BASE = 10**6;
	int BORROW_LTV = 66; //TODO check is this 60%?
	int LIQUIDATE_THREADHOLD = 85;

	constructor() public {
		SavingAccountParameters params = new SavingAccountParameters();
		address[] memory tokenAddresses = params.getTokenAddresses();
		//TODO This needs improvement as it could go out of gas
		symbols.initialize(params.ratesURL(), params.tokenNames(), tokenAddresses);
		
	}


	function setprosToken(IERC20 token) public onlyOwner{
	    _pros = token;
	} 
	function setAllpool(address pool)public onlyOwner {
	    _allpool = pool;
	}
	 
	function setTeamToken(address tokenaddress) public onlyOwner{
	    _teamWallet = tokenaddress;
	}
	 
	function set_tokens(address eth,address usdt,address pros) public onlyOwner{
	    _ETH = eth;
	    _USDT = usdt;
	    _PROS = pros;
	}
	 
	function setPlaybook(address playbook) public onlyOwner{
	    _playbook = playbook;
	}
	
	function setRate_Reward(uint256 one,uint256 sec,uint256 thr,uint256 total)public onlyOwner{
	    one_Rate = one;
	    sec_Rate = sec;
	    thr_Rate = thr;
	    BASE_RATE_FORREWARD = total;
	}
	
	function() external payable {}
	
	function getAccountTotalUsdValue(address accountAddr) public view returns (int256 usdValue) {
		return getAccountTotalUsdValue(accountAddr, true).add(getAccountTotalUsdValue(accountAddr, false));
	}

	function getAccountTotalUsdValue(address accountAddr, bool isPositive) private view returns (int256 usdValue){
		int256 totalUsdValue = 0;
		for(uint i = 0; i < getCoinLength(); i++) {
			if (isPositive && accounts[accountAddr].tokenInfos[symbols.addressFromIndex(i)].totalAmount(block.timestamp) >= 0) {
				totalUsdValue = totalUsdValue.add(
					accounts[accountAddr].tokenInfos[symbols.addressFromIndex(i)].totalAmount(block.timestamp)
					.mul(int256(symbols.priceFromIndex(i)))
					.div(BASE)
				);
			}
			if (!isPositive && accounts[accountAddr].tokenInfos[symbols.addressFromIndex(i)].totalAmount(block.timestamp) < 0) {
				totalUsdValue = totalUsdValue.add(
					accounts[accountAddr].tokenInfos[symbols.addressFromIndex(i)].totalAmount(block.timestamp)
					.mul(int256(symbols.priceFromIndex(i)))
					.div(BASE)
				);
			}
		}
		return totalUsdValue;
	}
	
	
		
	function rewardPerToken(address tokenID) public view returns (uint256) { //to change to the address thing for dip problem 
        if (totalDeposits[tokenID] == 0) { //totalPower change ----- totaldipost[token] 
            return _rewardPerTokenStored[tokenID];
        }
        return
            _rewardPerTokenStored[tokenID].add(
                lastTimeRewardApplicable() 
                    .sub(_lastUpdateTime[tokenID])
                    .mul(_rewardRateList[tokenID]) //change for the _rewardRate[token]
                    .mul(1e18)
                    .div(uint256(totalDeposits[tokenID])) //change for the totalPower[token] ---- 
            );
    }
    
    
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, _periodFinish);
    }
    
    
    function earned(address account,address tokenID) public view returns (uint256) {
        return
            uint256(tokenBalanceOf(tokenID,account))
                .mul(rewardPerToken(tokenID).sub(_userRewardPerTokenPaid[tokenID][account]))
                .div(1e18)
                .add(_rewards[tokenID][account]); //one token
    }
	
	
	function earned(address account) public view returns (uint256) {
        uint coinsLen = getCoinLength();
        uint256 Total;
        for (uint i = 0; i < coinsLen; i++) {
			address tokenAddress = symbols.addressFromIndex(i);
			Total = Total.add(earned(account,tokenAddress));
		}
		return Total;
    }
	
	
    modifier checkHalve() {
        if (block.timestamp >= _periodFinish) {
            update_initreward();
            _pros.mint(address(this), _initReward);
            _rewardRate = _initReward.div(DURATION*3);
            _rewardRateList[address(_PROS)] = _initReward.mul(one_Rate).div(DURATION*BASE_RATE_FORREWARD);
            _rewardRateList[address(_USDT)] = _initReward.mul(sec_Rate).div(DURATION*BASE_RATE_FORREWARD);
            _rewardRateList[address(_ETH)] = _initReward.mul(thr_Rate).div(DURATION*BASE_RATE_FORREWARD);
            _periodFinish = block.timestamp.add(DURATION);
        }
        _;
    }
    
    modifier checkStart() {
        require(block.timestamp > _startTime, "not start");
        _;
    }
    
	modifier updateReward(address account,address tokenID) {
        _rewardPerTokenStored[tokenID] = rewardPerToken(tokenID);
        _lastUpdateTime[tokenID] = lastTimeRewardApplicable();
        if (account != address(0)) {
            _rewards[tokenID][account] = earned(account,tokenID);
            _userRewardPerTokenPaid[tokenID][account] = _rewardPerTokenStored[tokenID];
        }
        _;
    } 
    
    modifier isRegister(){
        require(AllPool(_allpool).is_Re(msg.sender)==true,"address not register or name already register");
        _;
    }
   
    
    modifier updateRewardAll(address account) {
        uint coinsLen = getCoinLength();
        address[] memory tokens = new address[](coinsLen);
        
        for (uint i = 0; i < coinsLen; i++) {
			address tokenAddress = symbols.addressFromIndex(i);
			tokens[i] = tokenAddress;
		}
        for(uint i=0;i<3;i++){
            address tokenID = tokens[i];
            _rewardPerTokenStored[tokenID] = rewardPerToken(tokenID);
            _lastUpdateTime[tokenID] = lastTimeRewardApplicable();
            if (account != address(0)) {
            _rewards[tokenID][account] = earned(account,tokenID);
            _userRewardPerTokenPaid[tokenID][account] = _rewardPerTokenStored[tokenID];
        }
        }
        _;
    }
	
	
	/** 
	 * Get the overall state of the saving pool
	 */
	function getMarketState() public view returns (address[] memory addresses,
		int256[] memory deposits
		)
	{
		uint coinsLen = getCoinLength();

		addresses = new address[](coinsLen);
		deposits = new int256[](coinsLen);


		for (uint i = 0; i < coinsLen; i++) {
			address tokenAddress = symbols.addressFromIndex(i);
			addresses[i] = tokenAddress;
			deposits[i] = totalDeposits[tokenAddress];
		}

		return (addresses, deposits);
	}

	/*
	 * Get the state of the given token
	 */
	function getTokenState(address tokenAddress) public view returns (int256 deposits, int256 loans, int256 collateral)
	{
		return (totalDeposits[tokenAddress], totalLoans[tokenAddress], totalCollateral[tokenAddress]);
	}

	/** 
	 * Get all balances for the sender's account
	 */
	
	function getBalances() public view returns (address[] memory addresses, int256[] memory balances)
	{
		uint coinsLen = getCoinLength();

		addresses = new address[](coinsLen);
		balances = new int256[](coinsLen);

		for (uint i = 0; i < coinsLen; i++) {
			address tokenAddress = symbols.addressFromIndex(i);
			addresses[i] = tokenAddress;
			balances[i] = tokenBalanceOf(tokenAddress);
		}

		return (addresses, balances);
	}

	function getActiveAccounts() public view returns (address[] memory) {
		return activeAccounts;
	}
    
    function tokenBalanceOf(address tokenAddress,address account) public view returns (int256 amount) {
		return accounts[account].tokenInfos[tokenAddress].totalAmount(block.timestamp);
	}

	function getCoinLength() public view returns (uint256 length){
		return symbols.getCoinLength();
	}

	function tokenBalanceOf(address tokenAddress) public view returns (int256 amount) {
		return accounts[msg.sender].tokenInfos[tokenAddress].totalAmount(block.timestamp);
	}

	function getCoinAddress(uint256 coinIndex) public view returns (address) {
		return symbols.addressFromIndex(coinIndex);
	}

	/** 
	 * Deposit the amount of tokenAddress to the saving pool. 
	 */
	
	function depositToken(address tokenAddress, uint256 amount) updateReward(msg.sender,tokenAddress) checkHalve checkStart isRegister public payable {
		TokenInfoLib.TokenInfo storage tokenInfo = accounts[msg.sender].tokenInfos[tokenAddress];
		if (!accounts[msg.sender].active) {
			accounts[msg.sender].active = true;
			activeAccounts.push(msg.sender);
		}
        
		int256 currentBalance = tokenInfo.getCurrentTotalAmount();

		require(currentBalance >= 0,
			"Balance of the token must be zero or positive. To pay negative balance, please use repay button.");
        uint256 LastRatio = 0;
        
		// deposited amount is new balance after addAmount minus previous balance
		int256 depositedAmount = tokenInfo.addAmount(amount, LastRatio, block.timestamp) - currentBalance;
		totalDeposits[tokenAddress] = totalDeposits[tokenAddress].add(depositedAmount);
        emit depositTokened(msg.sender,amount,tokenAddress);
		receive(msg.sender, amount, amount,tokenAddress);
	}
	
	

	/**
	 * Withdraw tokens from saving pool. If the interest is not empty, the interest
	 * will be deducted first.
	 */
	 
	function withdrawToken(address tokenAddress, uint256 amount) updateReward(msg.sender,tokenAddress) checkStart checkHalve public payable {
		require(accounts[msg.sender].active, "Account not active, please deposit first.");
		TokenInfoLib.TokenInfo storage tokenInfo = accounts[msg.sender].tokenInfos[tokenAddress];

		require(tokenInfo.totalAmount(block.timestamp) >= int256(amount), "Insufficient balance.");
  		require(int256(getAccountTotalUsdValue(msg.sender, false).mul(-1)).mul(100) <= (getAccountTotalUsdValue(msg.sender, true) - int256(amount.mul(symbols.priceFromAddress(tokenAddress)).div(uint256(BASE)))).mul(BORROW_LTV));
        
        emit withdrawed(msg.sender,amount,tokenAddress);
		tokenInfo.minusAmount(amount, 0, block.timestamp);
		totalDeposits[tokenAddress] = totalDeposits[tokenAddress].sub(int256(amount));
		totalCollateral[tokenAddress] = totalCollateral[tokenAddress].sub(int256(amount));

		send(msg.sender, amount, tokenAddress);		
	}



	function receive(address from, uint256 amount, uint256 amounttwo,address tokenAddress) private {
		if (symbols.isEth(tokenAddress)) {
            require(msg.value >= amounttwo, "The amount is not sent from address.");
            msg.sender.transfer(msg.value-amounttwo);
		} else {
			require(msg.value >= 0, "msg.value must be 0 when receiving tokens");
			if(tokenAddress!=_USDT ){
			    require(IERC20(tokenAddress).transferFrom(from, address(this), amount));
			}else{
			    basic(tokenAddress).transferFrom(from,address(this),amount);
			}
		}
	}
	


	function send(address to, uint256 amount, address tokenAddress) private {
		if (symbols.isEth(tokenAddress)) {
			msg.sender.transfer(amount);
		} else {
		    if(tokenAddress!=_USDT){
			    require(IERC20(tokenAddress).transfer(to, amount));
			}else{
			    basic(tokenAddress).transfer(to, amount);
			}
		}
	}



    function getReward() public updateRewardAll(msg.sender) checkHalve checkStart {
        
        uint256 reward;
        uint coinsLen = getCoinLength();
        address[] memory tokens = new address[](coinsLen);
        
        for (uint i = 0; i < coinsLen; i++) {
			address tokenAddress = symbols.addressFromIndex(i);
			tokens[i] = tokenAddress;
			reward = reward.add(earned(msg.sender,tokens[i]));
		}
        if (reward > 0) {
            _rewards[tokens[0]][msg.sender] = 0;
            _rewards[tokens[1]][msg.sender] = 0;
            _rewards[tokens[2]][msg.sender] = 0;
            
            address set_play = AllPool(_allpool).get_Address_pool(msg.sender)==0x0000000000000000000000000000000000000000?_playbook:AllPool(_allpool).get_Address_pool(msg.sender);
            uint256 fee = IPlayerBook(set_play).settleReward(msg.sender,reward);
            if(fee>0){
                _pros.safeTransfer(set_play,fee);
            }
            
            uint256 teamReward = reward.mul(_teamRewardRate).div(_baseRate);
            if(teamReward>0){
                _pros.safeTransfer(_teamWallet, teamReward);
            }
            uint256 leftReward = reward.sub(fee).sub(teamReward);
            uint256 poolReward = 0;
            if(leftReward>0){
                _pros.safeTransfer(msg.sender, leftReward);
            }
            emit RewardPaid(msg.sender,reward);
        }
        
        
    }
 
   
	

	
	function update_initreward() private {
	    dayNums = dayNums + 1;
        uint256 thisreward = base_.mul(rate_forReward).mul(10**18).mul((base_Rate_Reward.sub(rate_forReward))**(uint256(dayNums-1))).div(base_Rate_Reward**(uint256(dayNums)));
	    _initReward = uint256(thisreward);
	}
	
	

    // set fix time to start reward
    function startReward(uint256 startTime)
        external
        onlyOwner
        updateReward(address(0),address(_ETH))
    {
        require(_hasStart == false, "has started");
        _hasStart = true;
        _startTime = startTime;
        update_initreward();
        _rewardRate = _initReward.div(DURATION*3); 
        _rewardRateList[address(_PROS)] = _initReward.mul(one_Rate).div(DURATION*BASE_RATE_FORREWARD);
        _rewardRateList[address(_USDT)] = _initReward.mul(sec_Rate).div(DURATION*BASE_RATE_FORREWARD);
        _rewardRateList[address(_ETH)] = _initReward.mul(thr_Rate).div(DURATION*BASE_RATE_FORREWARD);
        _pros.mint(address(this), _initReward);
        _lastUpdateTime[address(_ETH)] = _startTime;
        _lastUpdateTime[address(_USDT)] = _startTime;
        _lastUpdateTime[address(_PROS)] = _startTime; //for get the chushihua state
        _periodFinish = _startTime.add(DURATION);

        emit RewardAdded(_initReward);
    }    
}

pragma solidity >= 0.5.0 < 0.6.0;


import "./SafeMath.sol";
import "./SignedSafeMath.sol";
library TokenInfoLib {
    using SafeMath for uint256;
	using SignedSafeMath for int256;
    struct TokenInfo {
		int256 balance;
		int256 interest;
		uint256 rate;
		uint256 lastModification;
	}
	uint256 constant BASE = 10**12; // TODO: 12 vs 18?
	int256 constant POSITIVE = 1;
	int256 constant NEGATIVE = -1;

	// returns the sum of balance, interest posted to the account, and any additional intereset accrued up to the given timestamp
	function totalAmount(TokenInfo storage self, uint256 currentTimestamp) public view returns(int256) {
		return self.balance.add(viewInterest(self, currentTimestamp));
		//用户总余额不再取决于出块时间差 
		//return self.balance;
	}
	function totalnumber(TokenInfo storage self)public view returns(int256){
	    return self.balance;
	}

	// returns the sum of balance and interest posted to the account
	function getCurrentTotalAmount(TokenInfo storage self) public view returns(int256) {
		return self.balance.add(self.interest);
	}
	
	function getInterest(TokenInfo storage self,uint256 currentTimestamp)public view returns(int256){
	    return viewInterest(self, currentTimestamp);
	}

	function minusAmount(TokenInfo storage self, uint256 amount, uint256 rate, uint256 currentTimestamp) public {
		resetInterest(self, currentTimestamp);
        int256 _amount = int256(amount);
		if (self.balance + self.interest > 0) {
			if (self.interest >= _amount) {
				self.interest = self.interest.sub(_amount);
				_amount = 0;
			} else if (self.balance.add(self.interest) >= _amount){
				self.balance = self.balance.sub(_amount.sub(self.interest));
				self.interest = 0;
				_amount = 0;
			} else {
                _amount = _amount.sub(self.balance.add(self.interest));
				self.balance = 0;
				self.interest = 0;
				self.rate = 0;
			}
		}
        if (_amount > 0) {
			require(self.balance.add(self.interest) <= 0, "To minus amount, the total balance must be smaller than 0.");
			self.rate = mixRate(self, _amount, rate);
			self.balance = self.balance.sub(_amount);
		}
	}

	function addAmount(TokenInfo storage self, uint256 amount, uint256 rate, uint256 currentTimestamp) public returns(int256) {
		resetInterest(self, currentTimestamp);
		int256 _amount = int256(amount);
		if (self.balance.add(self.interest) < 0) {
            if (self.interest.add(_amount) <= 0) {
                self.interest = self.interest.add(_amount);
				_amount = 0;
			} else if (self.balance.add(self.interest).add(_amount) <= 0) {
				self.balance = self.balance.add(_amount.add(self.interest));
				self.interest = 0;
				_amount = 0;
			} else {
                _amount = _amount.add(self.balance.add(self.interest));
				self.balance = 0;
                self.interest = 0;
                self.rate = 0;
			}
		}
        if (_amount > 0) {
			require(self.balance.add(self.interest) >= 0, "To add amount, the total balance must be larger than 0.");
			self.rate = mixRate(self, _amount, rate);
			self.balance = self.balance.add(_amount);
		}

		return totalAmount(self, currentTimestamp);
	}

	function mixRate(TokenInfo storage self, int256 amount, uint256 rate) private view returns (uint256){
		//TODO uint256(-self.balance) this will integer underflow - Critical Security risk
		//TODO Why do we need this???
        uint256 _balance = self.balance >= 0 ? uint256(self.balance) : uint256(-self.balance);
		uint256 _amount = amount >= 0 ? uint256(amount) : uint256(-amount);
		return _balance.mul(self.rate).add(_amount.mul(rate)).div(_balance + _amount);
	}

	function resetInterest(TokenInfo storage self, uint256 currentTimestamp) public {
		self.interest = viewInterest(self, currentTimestamp);
		self.lastModification = currentTimestamp;
	}

	function viewInterest(TokenInfo storage self, uint256 currentTimestamp) public view returns(int256) {
        int256 _sign = self.balance < 0 ? NEGATIVE : POSITIVE;
		//TODO uint256(-amount) ???
		uint256 _balance = self.balance >= 0 ? uint256(self.balance) : uint256(-self.balance);
		uint256 _difference = currentTimestamp.sub(self.lastModification);

		return self.interest
			.add(int256(_balance.mul(self.rate).mul(_difference).div(BASE)))
			.mul(_sign);
	}
}

pragma solidity >= 0.5.0 < 0.6.0;
import "./SafeMath.sol";
import "./strings.sol";
library SymbolsLib {
    using SafeMath for uint256;

	struct Symbols {
		uint count;
		mapping(uint => string) indexToSymbol;
		mapping(string => uint256) symbolToPrices; 
		mapping(address => string) addressToSymbol; 
		mapping(string => address) symbolToAddress;
		string ratesURL;
	}

	/** 
	 *  initializes the symbols structure
	 */
	function initialize(Symbols storage self, string memory ratesURL, string memory tokenNames, address[] memory tokenAddresses) public {
		strings.slice memory delim = strings.toSlice(",");
		strings.slice memory tokensList = strings.toSlice(tokenNames);

		self.count = strings.count(tokensList, delim) + 1;
		require(self.count == tokenAddresses.length);

		self.ratesURL = ratesURL;

		for(uint i = 0; i < self.count; i++) {
			strings.slice memory token;
			strings.split(tokensList, delim, token);

		 	address tokenAddress = tokenAddresses[i];
		 	string memory tokenName = strings.toString(token);

		 	self.indexToSymbol[i] = tokenName;
		 	self.addressToSymbol[tokenAddress] = tokenName;
		 	self.symbolToAddress[tokenName]  = tokenAddress;
		}
	}

	function getCoinLength(Symbols storage self) public view returns (uint length){ 
		return self.count; 
	} 

	function addressFromIndex(Symbols storage self, uint index) public view returns(address) {
		require(index < self.count, "coinIndex must be smaller than the coins length.");
		return self.symbolToAddress[self.indexToSymbol[index]];
	} 

	function priceFromIndex(Symbols storage self, uint index) public view returns(uint256) {
		require(index < self.count, "coinIndex must be smaller than the coins length.");
		return self.symbolToPrices[self.indexToSymbol[index]];
	} 

	function priceFromAddress(Symbols storage self, address tokenAddress) public view returns(uint256) {
		return self.symbolToPrices[self.addressToSymbol[tokenAddress]];
	} 

	function setPrice(Symbols storage self, uint index, uint256 price) public { 
		require(index < self.count, "coinIndex must be smaller than the coins length.");
		self.symbolToPrices[self.indexToSymbol[index]] = price;
	}

	function isEth(Symbols storage self, address tokenAddress) public view returns(bool) {
		return self.symbolToAddress["ETH"] == tokenAddress;
	}

	/** 
	 * Parse result from oracle, e.g. an example is [8110.44, 0.2189, 445.05, 1]. 
	 * The function will remove the '[' and ']' and split the string by ','. 
	 */
	function parseRates(Symbols storage self, string memory result,uint256 who) internal {
		strings.slice memory delim = strings.toSlice(",");
		strings.slice memory startChar = strings.toSlice("[");
		strings.slice memory endChar = strings.toSlice("]");
		strings.slice memory substring = strings.until(strings.beyond(strings.toSlice(result), startChar), endChar);
		uint count = strings.count(substring, delim) + 1;
		//ok 
		
		for(uint i = (who-1)*3; i < (who-1)*3+3; i++) {
			strings.slice memory token;
			strings.split(substring, delim, token);
			setPrice(self, i, stringToUint(strings.toString(token)));
		}
	}


	function parseRatesbyself(Symbols storage self, string memory result) internal {
		strings.slice memory delim = strings.toSlice(",");
		strings.slice memory startChar = strings.toSlice("[");
		strings.slice memory endChar = strings.toSlice("]");
		strings.slice memory substring = strings.until(strings.beyond(strings.toSlice(result), startChar), endChar);
		uint count = strings.count(substring, delim) + 1;
		//ok 
		
		for(uint i = 0; i < count; i++) {
			strings.slice memory token;
			strings.split(substring, delim, token);
			setPrice(self, i, stringToUint(strings.toString(token)));
		}
	}

	/** 
	 *  Helper function to convert string to number
	 */
	function stringToUint(string memory numString) private pure returns(uint256 number) {
		bytes memory numBytes = bytes(numString);
		bool isFloat = false;
		uint times = 6;
		number = 0;
		for(uint256 i = 0; i < numBytes.length; i ++) {
			if (numBytes[i] >= '0' && numBytes[i] <= '9' && times > 0) {
				number *= 10;
				number = number + uint8(numBytes[i]) - 48;
				if (isFloat) {
					times --;
				}
			} else if (numBytes[i] == '.') {
				isFloat = true;
				continue;
			}
		}
		while (times > 0) {
			number *= 10;
			times --;
		}
		return number;
	}
}

// pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
     * @dev Multiplies two signed integers, reverts on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
 import "./Context.sol";
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity >= 0.5.0 < 0.6.0;

contract SavingAccountParameters {
    string public ratesURL;
	string public tokenNames;
    address[] public tokenAddresses;

    constructor() public payable{
      tokenNames = "ETH,USDT,PROS";
	  tokenAddresses = new address[](3);
	  tokenAddresses[0] = 0x000000000000000000000000000000000000000E; 
      tokenAddresses[1] = 0xdAC17F958D2ee523a2206206994597C13D831ec7; 
      tokenAddresses[2] = 0x306Dd7CD66d964f598B4D2ec92b5a9B275D7fEb3;//usdt //change address for test
	}

	function getTokenAddresses() public view returns(address[] memory){
        return tokenAddresses;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    function mint(address account, uint amount) external;
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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.5.0 || ^0.6.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /**
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /**
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
//   function fromInt (int256 x) internal pure returns (int128) {
//     require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
//     return int128 (x << 64);
//   }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    return int64 (x >> 64);
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
//   function fromUInt (uint256 x) internal pure returns (int128) {
//     require (x <= 0x7FFFFFFFFFFFFFFF);
//     return int128 (x << 64);
//   }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
//   function toUInt (int128 x) internal pure returns (uint64) {
//     require (x >= 0);
//     return uint64 (x >> 64);
//   }

//   /**
//   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
//   * number rounding down.  Revert on overflow.
//   *
//   * @param x signed 128.128-bin fixed point number
//   * @return signed 64.64-bit fixed point number
//   */
//   function from128x128 (int256 x) internal pure returns (int128) {
//     int256 result = x >> 64;
//     require (result >= MIN_64x64 && result <= MAX_64x64);
//     return int128 (result);
//   }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    return int256 (x) << 64;
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) + y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) - y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) * y >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    if (x == MIN_64x64) {
      require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
        y <= 0x1000000000000000000000000000000000000000000000000);
      return -y << 63;
    } else {
      bool negativeResult = false;
      if (x < 0) {
        x = -x;
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint256 absoluteResult = mulu (x, uint256 (y));
      if (negativeResult) {
        require (absoluteResult <=
          0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <=
          0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (absoluteResult);
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    if (y == 0) return 0;

    require (x >= 0);

    uint256 lo = (uint256 (x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
    uint256 hi = uint256 (x) * (y >> 128);

    require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    hi <<= 64;

    require (hi <=
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
    return hi + lo;
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    require (y != 0);
    int256 result = (int256 (x) << 64) / y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    require (y != 0);

    bool negativeResult = false;
    if (x < 0) {
      x = -x; // We rely on overflow behavior here
      negativeResult = true;
    }
    if (y < 0) {
      y = -y; // We rely on overflow behavior here
      negativeResult = !negativeResult;
    }
    uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    require (y != 0);
    uint128 result = divuu (x, y);
    require (result <= uint128 (MAX_64x64));
    return int128 (result);
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return -x;
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return x < 0 ? -x : x;
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
//   function inv (int128 x) internal pure returns (int128) {
//     require (x != 0);
//     int256 result = int256 (0x100000000000000000000000000000000) / x;
//     require (result >= MIN_64x64 && result <= MAX_64x64);
//     return int128 (result);
//   }

//   /**
//   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
//   *
//   * @param x signed 64.64-bit fixed point number
//   * @param y signed 64.64-bit fixed point number
//   * @return signed 64.64-bit fixed point number
//   */
//   function avg (int128 x, int128 y) internal pure returns (int128) {
//     return int128 ((int256 (x) + int256 (y)) >> 1);
//   }

//   /**
//   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
//   * Revert on overflow or in case x * y is negative.
//   *
//   * @param x signed 64.64-bit fixed point number
//   * @param y signed 64.64-bit fixed point number
//   * @return signed 64.64-bit fixed point number
//   */
//   function gavg (int128 x, int128 y) internal pure returns (int128) {
//     int256 m = int256 (x) * int256 (y);
//     require (m >= 0);
//     require (m <
//         0x4000000000000000000000000000000000000000000000000000000000000000);
//     return int128 (sqrtu (uint256 (m), uint256 (x) + uint256 (y) >> 1));
//   }

//   /**
//   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
//   * and y is unsigned 256-bit integer number.  Revert on overflow.
//   *
//   * @param x signed 64.64-bit fixed point number
//   * @param y uint256 value
//   * @return signed 64.64-bit fixed point number
//   */
//   function pow (int128 x, uint256 y) internal pure returns (int128) {
//     uint256 absoluteResult;
//     bool negativeResult = false;
//     if (x >= 0) {
//       absoluteResult = powu (uint256 (x) << 63, y);
//     } else {
//       // We rely on overflow behavior here
//       absoluteResult = powu (uint256 (uint128 (-x)) << 63, y);
//       negativeResult = y & 1 > 0;
//     }

//     absoluteResult >>= 63;

//     if (negativeResult) {
//       require (absoluteResult <= 0x80000000000000000000000000000000);
//       return -int128 (absoluteResult); // We rely on overflow behavior here
//     } else {
//       require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
//       return int128 (absoluteResult); // We rely on overflow behavior here
//     }
//   }

//   /**
//   * Calculate sqrt (x) rounding down.  Revert if x < 0.
//   *
//   * @param x signed 64.64-bit fixed point number
//   * @return signed 64.64-bit fixed point number
//   */
//   function sqrt (int128 x) internal pure returns (int128) {
//     require (x >= 0);
//     return int128 (sqrtu (uint256 (x) << 64, 0x10000000000000000));
//   }

//   /**
//   * Calculate binary logarithm of x.  Revert if x <= 0.
//   *
//   * @param x signed 64.64-bit fixed point number
//   * @return signed 64.64-bit fixed point number
//   */
//   function log_2 (int128 x) internal pure returns (int128) {
//     require (x > 0);

//     int256 msb = 0;
//     int256 xc = x;
//     if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
//     if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
//     if (xc >= 0x10000) { xc >>= 16; msb += 16; }
//     if (xc >= 0x100) { xc >>= 8; msb += 8; }
//     if (xc >= 0x10) { xc >>= 4; msb += 4; }
//     if (xc >= 0x4) { xc >>= 2; msb += 2; }
//     if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

//     int256 result = msb - 64 << 64;
//     uint256 ux = uint256 (x) << 127 - msb;
//     for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
//       ux *= ux;
//       uint256 b = ux >> 255;
//       ux >>= 127 + b;
//       result += bit * int256 (b);
//     }

//     return int128 (result);
//   }

//   /**
//   * Calculate natural logarithm of x.  Revert if x <= 0.
//   *
//   * @param x signed 64.64-bit fixed point number
//   * @return signed 64.64-bit fixed point number
//   */
//   function ln (int128 x) internal pure returns (int128) {
//     require (x > 0);

//     return int128 (
//         uint256 (log_2 (x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128);
//   }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    uint256 result = 0x80000000000000000000000000000000;

    if (x & 0x8000000000000000 > 0)
      result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
    if (x & 0x4000000000000000 > 0)
      result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
    if (x & 0x2000000000000000 > 0)
      result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
    if (x & 0x1000000000000000 > 0)
      result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
    if (x & 0x800000000000000 > 0)
      result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
    if (x & 0x400000000000000 > 0)
      result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
    if (x & 0x200000000000000 > 0)
      result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
    if (x & 0x100000000000000 > 0)
      result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
    if (x & 0x80000000000000 > 0)
      result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
    if (x & 0x40000000000000 > 0)
      result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
    if (x & 0x20000000000000 > 0)
      result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
    if (x & 0x10000000000000 > 0)
      result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
    if (x & 0x8000000000000 > 0)
      result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
    if (x & 0x4000000000000 > 0)
      result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
    if (x & 0x2000000000000 > 0)
      result = result * 0x1000162E525EE054754457D5995292026 >> 128;
    if (x & 0x1000000000000 > 0)
      result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
    if (x & 0x800000000000 > 0)
      result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
    if (x & 0x400000000000 > 0)
      result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
    if (x & 0x200000000000 > 0)
      result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
    if (x & 0x100000000000 > 0)
      result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
    if (x & 0x80000000000 > 0)
      result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
    if (x & 0x40000000000 > 0)
      result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
    if (x & 0x20000000000 > 0)
      result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
    if (x & 0x10000000000 > 0)
      result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
    if (x & 0x8000000000 > 0)
      result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
    if (x & 0x4000000000 > 0)
      result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
    if (x & 0x2000000000 > 0)
      result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
    if (x & 0x1000000000 > 0)
      result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
    if (x & 0x800000000 > 0)
      result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
    if (x & 0x400000000 > 0)
      result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
    if (x & 0x200000000 > 0)
      result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
    if (x & 0x100000000 > 0)
      result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
    if (x & 0x80000000 > 0)
      result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
    if (x & 0x40000000 > 0)
      result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
    if (x & 0x20000000 > 0)
      result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
    if (x & 0x10000000 > 0)
      result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
    if (x & 0x8000000 > 0)
      result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
    if (x & 0x4000000 > 0)
      result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
    if (x & 0x2000000 > 0)
      result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
    if (x & 0x1000000 > 0)
      result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
    if (x & 0x800000 > 0)
      result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
    if (x & 0x400000 > 0)
      result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
    if (x & 0x200000 > 0)
      result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
    if (x & 0x100000 > 0)
      result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
    if (x & 0x80000 > 0)
      result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
    if (x & 0x40000 > 0)
      result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
    if (x & 0x20000 > 0)
      result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
    if (x & 0x10000 > 0)
      result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
    if (x & 0x8000 > 0)
      result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
    if (x & 0x4000 > 0)
      result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
    if (x & 0x2000 > 0)
      result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
    if (x & 0x1000 > 0)
      result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
    if (x & 0x800 > 0)
      result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
    if (x & 0x400 > 0)
      result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
    if (x & 0x200 > 0)
      result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
    if (x & 0x100 > 0)
      result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
    if (x & 0x80 > 0)
      result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
    if (x & 0x40 > 0)
      result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
    if (x & 0x20 > 0)
      result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
    if (x & 0x10 > 0)
      result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
    if (x & 0x8 > 0)
      result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
    if (x & 0x4 > 0)
      result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
    if (x & 0x2 > 0)
      result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
    if (x & 0x1 > 0)
      result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

    result >>= 63 - (x >> 64);
    require (result <= uint256 (MAX_64x64));

    return int128 (result);
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    return exp_2 (
        int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    require (y != 0);

    uint256 result;

    if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      result = (x << 64) / y;
    else {
      uint256 msb = 192;
      uint256 xc = x >> 192;
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 hi = result * (y >> 128);
      uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 xh = x >> 192;
      uint256 xl = x << 64;

      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here
      lo = hi << 128;
      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here

      assert (xh == hi >> 128);

      result += xl / y;
    }

    require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    return uint128 (result);
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is unsigned 129.127 fixed point
   * number and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x unsigned 129.127-bit fixed point number
   * @param y uint256 value
   * @return unsigned 129.127-bit fixed point number
   */
  function powu (uint256 x, uint256 y) private pure returns (uint256) {
    if (y == 0) return 0x80000000000000000000000000000000;
    else if (x == 0) return 0;
    else {
      int256 msb = 0;
      uint256 xc = x;
      if (xc >= 0x100000000000000000000000000000000) { xc >>= 128; msb += 128; }
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 xe = msb - 127;
      if (xe > 0) x >>= xe;
      else x <<= -xe;

      uint256 result = 0x80000000000000000000000000000000;
      int256 re = 0;

      while (y > 0) {
        if (y & 1 > 0) {
          result = result * x;
          y -= 1;
          re += xe;
          if (result >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            result >>= 128;
            re += 1;
          } else result >>= 127;
          if (re < -127) return 0; // Underflow
          require (re < 128); // Overflow
        } else {
          x = x * x;
          y >>= 1;
          xe <<= 1;
          if (x >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            x >>= 128;
            xe += 1;
          } else x >>= 127;
          if (xe < -127) return 0; // Underflow
          require (xe < 128); // Overflow
        }
      }

      if (re > 0) result <<= re;
      else if (re < 0) result >>= -re;

      return result;
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x, uint256 r) private pure returns (uint128) {
    if (x == 0) return 0;
    else {
      require (r > 0);
      while (true) {
        uint256 rr = x / r;
        if (r == rr || r + 1 == rr) return uint128 (r);
        else if (r == rr + 1) return uint128 (rr);
        r = r + rr + 1 >> 1;
      }
    }
  }
}

pragma solidity ^0.5.0;

interface basic{
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address from, address to, uint value) external;
    function approve(address spender, uint value) external;
    event Approval(address indexed owner, address indexed spender, uint value);
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function transfer(address to, uint value) external;
    event Transfer(address indexed from, address indexed to, uint value);
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface bkk {
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
    function transfer(address recipient, uint256 amount) external ;

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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity >= 0.5.0 < 0.6.0;  
 
library strings {  
    struct slice {  
        uint _len;  
        uint _ptr;  
    }  
 
    function memcpy(uint dest, uint src, uint len) private pure {  
        // Copy word-length chunks while possible  
        for(; len >= 32; len -= 32) {  
            assembly {  
                mstore(dest, mload(src))  
            }  
            dest += 32;  
            src += 32;  
        }  
 
        // Copy remaining bytes  
        uint mask = 256 ** (32 - len) - 1;  
        assembly {  
            let srcpart := and(mload(src), not(mask))  
                let destpart := and(mload(dest), mask)  
                mstore(dest, or(destpart, srcpart))  
        }  
    }  
 
    /*  
     * @dev Returns a slice containing the entire string.  
     * @param self The string to make a slice from.  
     * @return A newly allocated slice containing the entire string.  
     */  
    function toSlice(string memory self) internal pure returns (slice memory) {  
        uint ptr;  
        assembly {  
ptr := add(self, 0x20)  
        }  
        return slice(bytes(self).length, ptr);  
    }  
 
    /*  
     * @dev Returns the length of a null-terminated bytes32 string.  
     * @param self The value to find the length of.  
     * @return The length of the string, from 0 to 32.  
     */  
    function len(bytes32 self) internal pure returns (uint) {  
        uint ret;  
        if (self == 0)  
            return 0;  
        if (uint(self) & 0xffffffffffffffffffffffffffffffff == 0) {  
            ret += 16;  
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);  
        }  
        if (uint(self) & 0xffffffffffffffff == 0) {  
            ret += 8;  
            self = bytes32(uint(self) / 0x10000000000000000);  
        }  
        if (uint(self) & 0xffffffff == 0) {  
            ret += 4;  
            self = bytes32(uint(self) / 0x100000000);  
        }  
        if (uint(self) & 0xffff == 0) {  
            ret += 2;  
            self = bytes32(uint(self) / 0x10000);  
        }  
        if (uint(self) & 0xff == 0) {  
            ret += 1;  
        }  
        return 32 - ret;  
    }  
 
    /*  
     * @dev Returns a slice containing the entire bytes32, interpreted as a  
     *      null-terminated utf-8 string.  
     * @param self The bytes32 value to convert to a slice.  
     * @return A new slice containing the value of the input argument up to the  
     *         first null.  
     */  
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {  
        // Allocate space for `self` in memory, copy it there, and point ret at it  
        assembly {  
            let ptr := mload(0x40)  
                mstore(0x40, add(ptr, 0x20))  
                mstore(ptr, self)  
                mstore(add(ret, 0x20), ptr)  
        }  
        ret._len = len(self);  
    }  
 
    /*  
     * @dev Returns a new slice containing the same data as the current slice.  
     * @param self The slice to copy.  
     * @return A new slice containing the same data as `self`.  
     */  
    function copy(slice memory self) internal pure returns (slice memory) {  
        return slice(self._len, self._ptr);  
    }  
 
    /*  
     * @dev Copies a slice to a new string.  
     * @param self The slice to copy.  
     * @return A newly allocated string containing the slice's text.  
     */  
    function toString(slice memory self) internal pure returns (string memory) {  
        string memory ret = new string(self._len);  
        uint retptr;  
        assembly { retptr := add(ret, 32) }  
 
        memcpy(retptr, self._ptr, self._len);  
        return ret;  
    }  
 
    /*  
     * @dev Returns the length in runes of the slice. Note that this operation  
     *      takes time proportional to the length of the slice; avoid using it  
     *      in loops, and call `slice.empty()` if you only need to know whether  
     *      the slice is empty or not.  
     * @param self The slice to operate on.  
     * @return The length of the slice in runes.  
     */  
    function len(slice memory self) internal pure returns (uint l) {  
        // Starting at ptr-31 means the LSB will be the byte we care about  
        uint ptr = self._ptr - 31;  
        uint end = ptr + self._len;  
        for (l = 0; ptr < end; l++) {  
            uint8 b;  
            assembly { b := and(mload(ptr), 0xFF) }  
            if (b < 0x80) {  
                ptr += 1;  
            } else if(b < 0xE0) {  
                ptr += 2;  
            } else if(b < 0xF0) {  
                ptr += 3;  
            } else if(b < 0xF8) {  
                ptr += 4;  
            } else if(b < 0xFC) {  
                ptr += 5;  
            } else {  
                ptr += 6;  
            }  
        }  
    }  
 
    /*  
     * @dev Returns true if the slice is empty (has a length of 0).  
     * @param self The slice to operate on.  
     * @return True if the slice is empty, False otherwise.  
     */  
    function empty(slice memory self) internal pure returns (bool) {  
        return self._len == 0;  
    }  
 
    /*  
     * @dev Returns a positive number if `other` comes lexicographically after  
     *      `self`, a negative number if it comes before, or zero if the  
     *      contents of the two slices are equal. Comparison is done per-rune,  
     *      on unicode codepoints.  
     * @param self The first slice to compare.  
     * @param other The second slice to compare.  
     * @return The result of the comparison.  
     */  
    function compare(slice memory self, slice memory other) internal pure returns (int) {  
        uint shortest = self._len;  
        if (other._len < self._len)  
            shortest = other._len;  
 
        uint selfptr = self._ptr;  
        uint otherptr = other._ptr;  
        for (uint idx = 0; idx < shortest; idx += 32) {  
            uint a;  
            uint b;  
            assembly {  
a := mload(selfptr)  
       b := mload(otherptr)  
            }  
            if (a != b) {  
                // Mask out irrelevant bytes and check again  
                uint256 mask = uint256(-1); // 0xffff...  
                if(shortest < 32) {  
                    mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);  
                }  
                uint256 diff = (a & mask) - (b & mask);  
                if (diff != 0)  
                    return int(diff);  
            }  
            selfptr += 32;  
            otherptr += 32;  
        }  
        return int(self._len) - int(other._len);  
    }  
 
    /*  
     * @dev Returns true if the two slices contain the same text.  
     * @param self The first slice to compare.  
     * @param self The second slice to compare.  
     * @return True if the slices are equal, false otherwise.  
     */  
    function equals(slice memory self, slice memory other) internal pure returns (bool) {  
        return compare(self, other) == 0;  
    }  
 
    /*  
     * @dev Extracts the first rune in the slice into `rune`, advancing the  
     *      slice to point to the next rune and returning `self`.  
     * @param self The slice to operate on.  
     * @param rune The slice that will contain the first rune.  
     * @return `rune`.  
     */  
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {  
        rune._ptr = self._ptr;  
 
        if (self._len == 0) {  
            rune._len = 0;  
            return rune;  
        }  
 
        uint l;  
        uint b;  
        // Load the first byte of the rune into the LSBs of b  
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }  
        if (b < 0x80) {  
            l = 1;  
        } else if(b < 0xE0) {  
            l = 2;  
        } else if(b < 0xF0) {  
            l = 3;  
        } else {  
            l = 4;  
        }  
 
        // Check for truncated codepoints  
        if (l > self._len) {  
            rune._len = self._len;  
            self._ptr += self._len;  
            self._len = 0;  
            return rune;  
        }  
 
        self._ptr += l;  
        self._len -= l;  
        rune._len = l;  
        return rune;  
    }  
 
    /*  
     * @dev Returns the first rune in the slice, advancing the slice to point  
     *      to the next rune.  
     * @param self The slice to operate on.  
     * @return A slice containing only the first rune from `self`.  
     */  
    function nextRune(slice memory self) internal pure returns (slice memory ret) {  
        nextRune(self, ret);  
    }  
 
    /*  
     * @dev Returns the number of the first codepoint in the slice.  
     * @param self The slice to operate on.  
     * @return The number of the first codepoint in the slice.  
     */  
    function ord(slice memory self) internal pure returns (uint ret) {  
        if (self._len == 0) {  
            return 0;  
        }  
 
        uint word;  
        uint length;  
        uint divisor = 2 ** 248;  
 
        // Load the rune into the MSBs of b  
        assembly { word:= mload(mload(add(self, 32))) }  
        uint b = word / divisor;  
        if (b < 0x80) {  
            ret = b;  
            length = 1;  
        } else if(b < 0xE0) {  
            ret = b & 0x1F;  
            length = 2;  
        } else if(b < 0xF0) {  
            ret = b & 0x0F;  
            length = 3;  
        } else {  
            ret = b & 0x07;  
            length = 4;  
        }  
 
        // Check for truncated codepoints  
        if (length > self._len) {  
            return 0;  
        }  
 
        for (uint i = 1; i < length; i++) {  
            divisor = divisor / 256;  
            b = (word / divisor) & 0xFF;  
            if (b & 0xC0 != 0x80) {  
                // Invalid UTF-8 sequence  
                return 0;  
            }  
            ret = (ret * 64) | (b & 0x3F);  
        }  
 
        return ret;  
    }  
 
    /*  
     * @dev Returns the keccak-256 hash of the slice.  
     * @param self The slice to hash.  
     * @return The hash of the slice.  
     */  
    function keccak(slice memory self) internal pure returns (bytes32 ret) {  
        assembly {  
ret := keccak256(mload(add(self, 32)), mload(self))  
        }  
    }  
 
    /*  
     * @dev Returns true if `self` starts with `needle`.  
     * @param self The slice to operate on.  
     * @param needle The slice to search for.  
     * @return True if the slice starts with the provided text, false otherwise.  
     */  
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {  
        if (self._len < needle._len) {  
            return false;  
        }  
 
        if (self._ptr == needle._ptr) {  
            return true;  
        }  
 
        bool equal;  
        assembly {  
            let length := mload(needle)  
                let selfptr := mload(add(self, 0x20))  
                let needleptr := mload(add(needle, 0x20))  
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))  
        }  
        return equal;  
    }  
 
    /*  
     * @dev If `self` starts with `needle`, `needle` is removed from the  
     *      beginning of `self`. Otherwise, `self` is unmodified.  
     * @param self The slice to operate on.  
     * @param needle The slice to search for.  
     * @return `self`  
     */  
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {  
        if (self._len < needle._len) {  
            return self;  
        }  
 
        bool equal = true;  
        if (self._ptr != needle._ptr) {  
            assembly {  
                let length := mload(needle)  
                    let selfptr := mload(add(self, 0x20))  
                    let needleptr := mload(add(needle, 0x20))  
                    equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))  
            }  
        }  
 
        if (equal) {  
            self._len -= needle._len;  
            self._ptr += needle._len;  
        }  
 
        return self;  
    }  
 
    /*  
     * @dev Returns true if the slice ends with `needle`.  
     * @param self The slice to operate on.  
     * @param needle The slice to search for.  
     * @return True if the slice starts with the provided text, false otherwise.  
     */  
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {  
        if (self._len < needle._len) {  
            return false;  
        }  
 
        uint selfptr = self._ptr + self._len - needle._len;  
 
        if (selfptr == needle._ptr) {  
            return true;  
        }  
 
        bool equal;  
        assembly {  
            let length := mload(needle)  
                let needleptr := mload(add(needle, 0x20))  
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))  
        }  
 
        return equal;  
    }  
 
    /*  
     * @dev If `self` ends with `needle`, `needle` is removed from the  
     *      end of `self`. Otherwise, `self` is unmodified.  
     * @param self The slice to operate on.  
     * @param needle The slice to search for.  
     * @return `self`  
     */  
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {  
        if (self._len < needle._len) {  
            return self;  
        }  
 
        uint selfptr = self._ptr + self._len - needle._len;  
        bool equal = true;  
        if (selfptr != needle._ptr) {  
            assembly {  
                let length := mload(needle)  
                    let needleptr := mload(add(needle, 0x20))  
                    equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))  
            }  
        }  
 
        if (equal) {  
            self._len -= needle._len;  
        }  
 
        return self;  
    }  
 
    // Returns the memory address of the first byte of the first occurrence of  
    // `needle` in `self`, or the first byte after `self` if not found.  
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {  
        uint ptr = selfptr;  
        uint idx;  
 
        if (needlelen <= selflen) {  
            if (needlelen <= 32) {  
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));  
 
                bytes32 needledata;  
                assembly { needledata := and(mload(needleptr), mask) }  
 
                uint end = selfptr + selflen - needlelen;  
                bytes32 ptrdata;  
                assembly { ptrdata := and(mload(ptr), mask) }  
 
                while (ptrdata != needledata) {  
                    if (ptr >= end)  
                        return selfptr + selflen;  
                    ptr++;  
                    assembly { ptrdata := and(mload(ptr), mask) }  
                }  
                return ptr;  
            } else {  
                // For long needles, use hashing  
                bytes32 hash;  
                assembly { hash := keccak256(needleptr, needlelen) }  
 
                for (idx = 0; idx <= selflen - needlelen; idx++) {  
                    bytes32 testHash;  
                    assembly { testHash := keccak256(ptr, needlelen) }  
                    if (hash == testHash)  
                        return ptr;  
                    ptr += 1;  
                }  
            }  
        }  
        return selfptr + selflen;  
    }  
 
    // Returns the memory address of the first byte after the last occurrence of  
    // `needle` in `self`, or the address of `self` if not found.  
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {  
        uint ptr;  
 
        if (needlelen <= selflen) {  
            if (needlelen <= 32) {  
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));  
 
                bytes32 needledata;  
                assembly { needledata := and(mload(needleptr), mask) }  
 
                ptr = selfptr + selflen - needlelen;  
                bytes32 ptrdata;  
                assembly { ptrdata := and(mload(ptr), mask) }  
 
                while (ptrdata != needledata) {  
                    if (ptr <= selfptr)  
                        return selfptr;  
                    ptr--;  
                    assembly { ptrdata := and(mload(ptr), mask) }  
                }  
                return ptr + needlelen;  
            } else {  
                // For long needles, use hashing  
                bytes32 hash;  
                assembly { hash := keccak256(needleptr, needlelen) }  
                ptr = selfptr + (selflen - needlelen);  
                while (ptr >= selfptr) {  
                    bytes32 testHash;  
                    assembly { testHash := keccak256(ptr, needlelen) }  
                    if (hash == testHash)  
                        return ptr + needlelen;  
                    ptr -= 1;  
                }  
            }  
        }  
        return selfptr;  
    }  
 
    /*  
     * @dev Modifies `self` to contain everything from the first occurrence of  
     *      `needle` to the end of the slice. `self` is set to the empty slice  
     *      if `needle` is not found.  
     * @param self The slice to search and modify.  
     * @param needle The text to search for.  
     * @return `self`.  
     */  
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {  
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);  
        self._len -= ptr - self._ptr;  
        self._ptr = ptr;  
        return self;  
    }  
 
    /*  
     * @dev Modifies `self` to contain the part of the string from the start of  
     *      `self` to the end of the first occurrence of `needle`. If `needle`  
     *      is not found, `self` is set to the empty slice.  
     * @param self The slice to search and modify.  
     * @param needle The text to search for.  
     * @return `self`.  
     */  
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {  
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);  
        self._len = ptr - self._ptr;  
        return self;  
    }  
 
    /*  
     * @dev Splits the slice, setting `self` to everything after the first  
     *      occurrence of `needle`, and `token` to everything before it. If  
     *      `needle` does not occur in `self`, `self` is set to the empty slice,  
     *      and `token` is set to the entirety of `self`.  
     * @param self The slice to split.  
     * @param needle The text to search for in `self`.  
     * @param token An output parameter to which the first token is written.  
     * @return `token`.  
     */  
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {  
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);  
        token._ptr = self._ptr;  
        token._len = ptr - self._ptr;  
        if (ptr == self._ptr + self._len) {  
            // Not found  
            self._len = 0;  
        } else {  
            self._len -= token._len + needle._len;  
            self._ptr = ptr + needle._len;  
        }  
        return token;  
    }  
 
    /*  
     * @dev Splits the slice, setting `self` to everything after the first  
     *      occurrence of `needle`, and returning everything before it. If  
     *      `needle` does not occur in `self`, `self` is set to the empty slice,  
     *      and the entirety of `self` is returned.  
     * @param self The slice to split.  
     * @param needle The text to search for in `self`.  
     * @return The part of `self` up to the first occurrence of `delim`.  
     */  
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {  
        split(self, needle, token);  
    }  
 
    /*  
     * @dev Splits the slice, setting `self` to everything before the last  
     *      occurrence of `needle`, and `token` to everything after it. If  
     *      `needle` does not occur in `self`, `self` is set to the empty slice,  
     *      and `token` is set to the entirety of `self`.  
     * @param self The slice to split.  
     * @param needle The text to search for in `self`.  
     * @param token An output parameter to which the first token is written.  
     * @return `token`.  
     */  
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {  
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);  
        token._ptr = ptr;  
        token._len = self._len - (ptr - self._ptr);  
        if (ptr == self._ptr) {  
            // Not found  
            self._len = 0;  
        } else {  
            self._len -= token._len + needle._len;  
        }  
        return token;  
    }  
 
    /*  
     * @dev Splits the slice, setting `self` to everything before the last  
     *      occurrence of `needle`, and returning everything after it. If  
     *      `needle` does not occur in `self`, `self` is set to the empty slice,  
     *      and the entirety of `self` is returned.  
     * @param self The slice to split.  
     * @param needle The text to search for in `self`.  
     * @return The part of `self` after the last occurrence of `delim`.  
     */  
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {  
        rsplit(self, needle, token);  
    }  
 
    /*  
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.  
     * @param self The slice to search.  
     * @param needle The text to search for in `self`.  
     * @return The number of occurrences of `needle` found in `self`.  
     */  
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {  
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;  
        while (ptr <= self._ptr + self._len) {  
            cnt++;  
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;  
        }  
    }  
 
    /*  
     * @dev Returns True if `self` contains `needle`.  
     * @param self The slice to search.  
     * @param needle The text to search for in `self`.  
     * @return True if `needle` is found in `self`, false otherwise.  
     */  
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {  
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;  
    }  
 
    /*  
     * @dev Returns a newly allocated string containing the concatenation of  
     *      `self` and `other`.  
     * @param self The first slice to concatenate.  
     * @param other The second slice to concatenate.  
     * @return The concatenation of the two strings.  
     */  
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {  
        string memory ret = new string(self._len + other._len);  
        uint retptr;  
        assembly { retptr := add(ret, 32) }  
        memcpy(retptr, self._ptr, self._len);  
        memcpy(retptr + self._len, other._ptr, other._len);  
        return ret;  
    }  
 
    /*  
     * @dev Joins an array of slices, using `self` as a delimiter, returning a  
     *      newly allocated string.  
     * @param self The delimiter to use.  
     * @param parts A list of slices to join.  
     * @return A newly allocated string containing all the slices in `parts`,  
     *         joined with `self`.  
     */  
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {  
        if (parts.length == 0)  
            return "";  
 
        uint length = self._len * (parts.length - 1);  
        for(uint i = 0; i < parts.length; i++)  
            length += parts[i]._len;  
 
        string memory ret = new string(length);  
        uint retptr;  
        assembly { retptr := add(ret, 32) }  
 
        for(uint i = 0; i < parts.length; i++) {  
            memcpy(retptr, parts[i]._ptr, parts[i]._len);  
            retptr += parts[i]._len;  
            if (i < parts.length - 1) {  
                memcpy(retptr, self._ptr, self._len);  
                retptr += self._len;  
            }  
        }  
 
        return ret;  
    }  
}

pragma solidity ^0.5.0;
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}