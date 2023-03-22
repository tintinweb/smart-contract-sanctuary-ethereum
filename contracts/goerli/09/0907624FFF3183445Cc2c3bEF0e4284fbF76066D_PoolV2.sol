// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";


interface IOracle{
	function getiTokenDetails(uint _poolIndex) external returns(string memory, string memory,string memory); 
     function getTokenDetails(uint _poolIndex) external returns(address[] memory,uint[] memory,uint ,uint);
}

interface Iitokendeployer{
	function createnewitoken(string calldata _name, string calldata _symbol) external returns(address);
}

interface Iitoken{
	function mint(address account, uint256 amount) external;
	function burn(address account, uint256 amount) external;
	function balanceOf(address account) external view returns (uint256);
	function totalSupply() external view returns (uint256);
}

interface IMAsterChef{
	function depositFromOtherContract(uint256 _pid, uint256 _amount, uint256 vault, address _sender) external;
	function distributeExitFeeShare(uint256 _amount) external;
}

interface IPoolConfiguration{
	 function checkDao(address daoAddress) external returns(bool);
	 function getperformancefees() external view returns(uint256);
	 function paymentContractAddress() external view returns(address);
	 function getmaxTokenSupported() external view returns(uint256);
	 function getslippagerate() external view returns(uint256);
	 function getoracleaddress() external view returns(address);
	 function getEarlyExitfees() external view returns(uint256);
	 function checkStableCoin(address _stable) external view returns(bool);
	 function treasuryAddress() external view returns(address);
	 function isAdmin(address _address) external view returns(bool);
	 function isBlackListed(address _address) external pure returns(bool);
}

interface IindicesPayment{
	function validateIndicesCreation(address _userAddress) external returns(bool);
}

interface DexAggregator{
	function getBestExchangeRate(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external returns (uint256 amountOut, address[] memory, address);
    
	function swapFromBestExchange(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) external payable returns(uint256);

}

contract PoolV2 is Initializable, ReentrancyGuardUpgradeable {
    
    using SafeMathUpgradeable for uint;
	using SafeERC20Upgradeable for IERC20Upgradeable;

	uint256 public constant MULTIPLIER = 1e12;
	uint256 public constant Averageblockperday = 6500;

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

	address public EXCHANGE_CONTRACT;
	address public WETH_ADDRESS;
	address public baseStableCoin;

	// ASTRA token Address
	address public ASTRTokenAddress;
	// Manager Account Address
	address public managerAddresses;
	// Pool configuration contract address. This contract manage the configuration for this contract.
	address public _poolConf;
	// Chef contract address for staking
	address public poolChef;
	// Address of itoken deployer. This will contract will be responsible for deploying itokens.
    address public itokendeployer;
	// Structure for storing the pool details
	struct PoolInfo {
		// Array for token addresses.
        address[] tokens;    
		// Weight for each token. Share is calculated by dividing the weight with total weight.
        uint256[]  weights;        
		// Total weight. Sum of all the weight in array.
        uint256 totalWeight;
		// Check if pool is active or not      
        bool active; 
		// Next rebalance time for pool/index in unix timestamp        
        uint256 rebaltime;
		// Threshold value. Minimum value after that pool will start buying token
        uint256 threshold;
		// Number of rebalance performed on this pool.
        uint256 currentRebalance;
		// Unix timeseamp for the last rebalance time
        uint256 lastrebalance;
		// itoken Created address
		address itokenaddr;
		// Owner address for owner 
		address owner;
		//description for token
		string description;
    }
    struct PoolUser 
    {   
		// Balance of user in pool
        uint256 currentBalance;
		// Number of rebalance pupto which user account is synced 
        uint256 currentPool; 
		// Pending amount for which no tokens are bought
        uint256 pendingBalance; 
		// Total amount deposited in stable coin.
		uint256 USDTdeposit;
		// ioktne balance for that pool. This will tell the total itoken balance either staked at chef or hold at account.
		uint256 Itokens;
		// Check id user account is active
        bool active;
    } 
    
	// Mapping for user infor based on the structure created above.
    mapping ( uint256 =>mapping(address => PoolUser)) public poolUserInfo; 

	// Array for storing indices details
    PoolInfo[] public poolInfo;
    
	// Private array variable use internally by functions.
    uint256[] private buf; 
    
    // address[] private _Tokens;
    // uint256[] private _Values;

	// Mapping to show the token balance for a particular pool.
	mapping(uint256 => mapping(address => uint256)) public tokenBalances;
	// Store the tota pool balance
	mapping(uint256 => uint256) public totalPoolbalance;
	// Store the pending balance for which tokens are not bought.
	mapping(uint256 => uint256) public poolPendingbalance;
	//Track the initial block where user deposit amount.
	mapping(address =>mapping (uint256 => uint256)) public initialDeposit;
	//Check if user already exist or not.
	mapping(address =>mapping (uint256 => bool)) public existingUser;

	bool public active; 
	
	/**
     * @dev Modifier to check if the called is Admin or not.
     */
	modifier whitelistedOnly {
	    require(!IPoolConfiguration(_poolConf).isBlackListed(msg.sender), "EO1");
	    _;
	}

	// Event emitted
	event Transfer(address indexed src, address indexed dst, uint wad);
	event Withdrawn(address indexed from, uint value);
	event SetPoolStatus(uint poolIndex,bool active);
	
	/**
     * Error code:
     * EO1: Blacklisted user
     * E02: Invalid Pool Index
     * E03: Already whitelisted
     * E04: Only manager can whitelist
     * E05: Only owner can whitelist
     * E06: Invalid config length
     * E07: Only whitelisted user
     * E08: Only one token allowed
     * E09: Deposit some amount
     * E10: Only stable coins
     * E11: Not enough tokens
     * E12: Rebalnce time not reached
     * E13: Only owner can update the public pool
     * E14: No balance in Pool
     * E15: Zero address
     * E16: More than allowed token in indices
	 * E17: Admin only
	 * E18: Only pool owner
	 * E19: Not enough astra balance
	 * E20: Wrong tokens in update pool
    */
	
	function initialize(address _ASTRTokenAddress, address poolConfiguration,address _itokendeployer, address _chef,address _exchange, address _weth, address _stable) public initializer{
		require(_ASTRTokenAddress != address(0), "E15");
		require(poolConfiguration != address(0), "E15");
		require(_itokendeployer != address(0), "E15");
		require(_chef != address(0), "E15");
		__ReentrancyGuard_init();
		ASTRTokenAddress = _ASTRTokenAddress;
		managerAddresses = msg.sender;
		_poolConf = poolConfiguration;
		itokendeployer = _itokendeployer;
		poolChef = _chef;
		active = true;
		EXCHANGE_CONTRACT = _exchange;
	    WETH_ADDRESS = _weth;
	    baseStableCoin = _stable;
	}

    fallback() external payable { }
    receive() external payable { }

	function calculateTotalWeight(uint[] memory _weights) internal pure returns(uint){
		uint _totalWeight;
		// Calculate total weight for new index.
		for(uint i = 0; i < _weights.length; i++) {
			_totalWeight = _totalWeight.add(_weights[i]);
		}
		return _totalWeight;
	}

	function validatePayment() internal returns(bool){
		address _paymentAddress = IPoolConfiguration(_poolConf).paymentContractAddress();
		bool paymentStatus = IindicesPayment(_paymentAddress).validateIndicesCreation(msg.sender);
		return paymentStatus;
	}
	/**
     * @notice Add public pool
     * @param _tokens tokens to purchase in pool.
     * @param _weights Weight of new tokens.
	 * @param _threshold Threshold amount to purchase token.
	 * @param _rebalanceTime Next Rebalance time.
	 * @param _name itoken name.
	 * @param _symbol itoken symbol.
	 * @dev Add new public pool by any users.Here any users can add there custom pools
     */
	function addPublicPool(address[] memory _tokens, uint[] memory _weights,uint _threshold,uint _rebalanceTime,string memory _name,string memory _symbol,string memory _description) public whitelistedOnly{
        //Currently it will only check if configuration is correct as staking amount is not decided to add the new pool.
		address _itokenaddr;
		address _poolOwner;
		uint _poolIndex = poolInfo.length;
		address _OracleAddress = IPoolConfiguration(_poolConf).getoracleaddress();

		if(_tokens.length == 0){
			// require(systemAddresses[msg.sender], "EO1");
			require(IPoolConfiguration(_poolConf).isAdmin(msg.sender),"isAdmin");
			(_tokens, _weights,_threshold,_rebalanceTime) = IOracle(_OracleAddress).getTokenDetails(_poolIndex);
            // Get the new itoken name and symbol from pool
		    (_name,_symbol,_description) = IOracle(_OracleAddress).getiTokenDetails(_poolIndex);
			_poolOwner = address(this);
		}else{
			require(validatePayment(), "E19");
			_poolOwner = msg.sender;
		}

		require (_tokens.length == _weights.length, "E06");
        require (_tokens.length <= IPoolConfiguration(_poolConf).getmaxTokenSupported(), "E16");
		// Deploy new itokens
        _itokenaddr = Iitokendeployer(itokendeployer).createnewitoken(_name, _symbol);
		
		// Add new index.
		poolInfo.push(PoolInfo({
            tokens : _tokens,   
            weights : _weights,        
            totalWeight : calculateTotalWeight(_weights),      
            active : true,          
            rebaltime : _rebalanceTime,
            currentRebalance : 0,
            threshold: _threshold,
            lastrebalance: block.timestamp,
		    itokenaddr: _itokenaddr,
			owner: _poolOwner,
			description:_description
        }));
    }

	/**
	* @notice Internal function to Buy Astra Tokens.
	* @param _Amount Amount of Astra token to buy.
    * @dev Buy Astra Tokens if user want to pay fees early exit fees by deposit in Astra
    */
	function buyAstraTokenandETH(uint _Amount, bool isETH) internal returns(uint256) {
		IERC20Upgradeable(baseStableCoin).approve(EXCHANGE_CONTRACT, _Amount);
		// Get the expected amount of Astra you will recieve for the stable coin.
		if(isETH){
			(uint256 _amount,,) = DexAggregator(EXCHANGE_CONTRACT).getBestExchangeRate(ETH_ADDRESS, baseStableCoin, _Amount);
		    // calculate slippage
			uint256 minReturn = calculateMinimumReturn(_amount);
			_amount = DexAggregator(EXCHANGE_CONTRACT).swapFromBestExchange{value:_Amount}(ETH_ADDRESS, baseStableCoin, _Amount, minReturn);
			return _amount;
		}else{
			(uint256 _amount,,) = DexAggregator(EXCHANGE_CONTRACT).getBestExchangeRate(baseStableCoin, ASTRTokenAddress, _Amount);
			uint256 minReturn = calculateMinimumReturn(_amount);
			// Swap the stabe coin for Astra
			_amount = DexAggregator(EXCHANGE_CONTRACT).swapFromBestExchange(baseStableCoin, ASTRTokenAddress, _Amount, minReturn);
			return _amount;
		}



	}

	/**
	* @notice Stake Astra Tokens.
	* @param _amount Amount of Astra token to stake.
    * @dev Stake Astra tokens for various functionality like Staking.
    */
	function stakeAstra(uint _amount)internal{
		//Approve the astra amount to stake.
		IERC20Upgradeable(ASTRTokenAddress).approve(address(poolChef),_amount);
		// Stake the amount on chef contract. It will be staked for 6 months by default 0 pool id will be for the astra pool.
		IMAsterChef(poolChef).depositFromOtherContract(0,_amount,6,msg.sender);
	}	

	/**
	* @notice Calculate Fees.
	* @param _account User account.
	* @param _amount Amount user wants to withdraw.
	* @param _poolIndex Pool Index
	* @dev Calculate Early Exit fees
	* feeRate = Early Exit fee rate (Const 2%)
    * startBlock = Deposit block
    *  withdrawBlock = Withdrawal block 
    *  n = number of blocks between n1 and n2  
    *  Averageblockperday = Average block per day (assumed: 6500) 
    *  feeconstant =early exit fee cool down period (const 182) 
    *  Wv = withdrawal value
    *  EEFv = Wv x  EEFr  - (EEFr    x n/ABPx t)
    *  If EEFv <=0 then EEFv  = 0 
	 */

	 function calculatefee(address _account, uint _amount,uint _poolIndex)internal view returns(uint256){
		// Calculate the early eit fees based on the formula mentioned above.
        uint256 feeRate = (IPoolConfiguration(_poolConf).getEarlyExitfees()) *
           MULTIPLIER;
        uint256 startBlock = initialDeposit[_account][_poolIndex];
        uint256 withdrawBlock = block.number;
        uint256 feeconstant = 182;
        uint256 blocks = withdrawBlock.sub(startBlock);
        if (blocks >= 182 * Averageblockperday) {
           return 0;
        }
        uint feesValue = feeRate.mul(blocks).div(100);
        feesValue = feesValue.div(Averageblockperday).div(feeconstant);
        feesValue = (feeRate.div(100).sub(feesValue)).mul(_amount);
        return feesValue / MULTIPLIER;
	 }
		
	/**
	 * @notice Buy Tokens.
	 * @param _poolIndex Pool Index.
     * @dev This function is used to buy token for updating pool, first at the initiall buy after reaching threshold and during rebalance.
     */
    function buytokens(uint _poolIndex) internal {
	// Check if pool configuration is correct or not.
	// This function is called inernally when user deposit in pool or during rebalance to purchase the tokens for given stable coin amount.
     require(_poolIndex<poolInfo.length, "E02");
     address[] memory returnedTokens;
	 uint[] memory returnedAmounts;
     uint ethValue = poolPendingbalance[_poolIndex]; 
     uint[] memory buf3;
	 buf = buf3;
     // Buy tokens for the pending stable amount
     (returnedTokens, returnedAmounts) = swap2(baseStableCoin, ethValue, poolInfo[_poolIndex].tokens, poolInfo[_poolIndex].weights, poolInfo[_poolIndex].totalWeight,buf);
     // After tokens are purchased update its details in mapping.
      for (uint i = 0; i < returnedTokens.length; i++) {
			tokenBalances[_poolIndex][returnedTokens[i]] = tokenBalances[_poolIndex][returnedTokens[i]].add(returnedAmounts[i]);
	  }
	  // Update the pool details for the purchased tokens
	  totalPoolbalance[_poolIndex] = totalPoolbalance[_poolIndex].add(ethValue);
	  poolPendingbalance[_poolIndex] = 0;
	  if (poolInfo[_poolIndex].currentRebalance == 0){
	      poolInfo[_poolIndex].currentRebalance = poolInfo[_poolIndex].currentRebalance.add(1);
	  }
		
    }

	/**
	* @param _amount Amount of user to Update.
	* @param _poolIndex Pool Index.
    * @dev Update user Info at the time of deposit in pool
    */
    
    function updateuserinfo(uint _amount,uint _poolIndex) internal { 
        // Update the user details in mapping. This function is called internally when user deposit in pool or withdraw from pool.
        if(poolUserInfo[_poolIndex][msg.sender].active){
			// Check if user account is synced with latest rebalance or not. In case not it will update its details.
            if(poolUserInfo[_poolIndex][msg.sender].currentPool < poolInfo[_poolIndex].currentRebalance){
                poolUserInfo[_poolIndex][msg.sender].currentBalance = poolUserInfo[_poolIndex][msg.sender].currentBalance.add(poolUserInfo[_poolIndex][msg.sender].pendingBalance);
                poolUserInfo[_poolIndex][msg.sender].currentPool = poolInfo[_poolIndex].currentRebalance;
                poolUserInfo[_poolIndex][msg.sender].pendingBalance = _amount;
            }
            else{
               poolUserInfo[_poolIndex][msg.sender].pendingBalance = poolUserInfo[_poolIndex][msg.sender].pendingBalance.add(_amount); 
            }
        }
       
    } 

	/**
     * @dev Get the Token details in Index pool.
     */
    function getIndexTokenDetails(uint _poolIndex) external view returns(address[] memory){
        return (poolInfo[_poolIndex].tokens);
    }

	/**
     * @dev Get the Token weight details in Index pool.
     */
    function getIndexWeightDetails(uint _poolIndex) external view returns(uint[] memory){
        return (poolInfo[_poolIndex].weights);
    }

	/**
	 @param _amount Amount to chec for slippage.
    * @dev Function to calculate the Minimum return for slippage
    */
	function calculateMinimumReturn(uint _amount) internal view returns (uint){
		// This will get the slippage rate from configuration contract and calculate how much amount user can get after slippage.
		uint256 sliprate= IPoolConfiguration(_poolConf).getslippagerate();
        uint rate = _amount.mul(sliprate).div(100);
        // Return amount after calculating slippage
		return _amount.sub(rate);
        
    }
	/**
    * @dev Get amount of itoken to be received.
	* Iv = index value 
    * Pt = total iTokens outstanding 
    * Dv = deposit USDT value 
    * DPv = total USDT value in the pool
    * pTR = iTokens received
    * If Iv = 0 then pTR =  DV
    * If pt > 0 then pTR  =  (Dv/Iv)* Pt
    */
	function getItokenValue(uint256 outstandingValue, uint256 indexValue, uint256 depositValue, uint256 totalDepositValue) public pure returns(uint256){
		// Get the itoken value based on the pool value and total itokens. This method is used in pool In.
		// outstandingValue is total itokens.
		// Index value is pool current value.
		// deposit value is stable coin amount user will deposit
		// totalDepositValue is total stable coin value deposited over the pool.
		if(indexValue == 0){
			return depositValue;
		}else if(outstandingValue>0){
			return depositValue.mul(MULTIPLIER).mul(outstandingValue).div(indexValue).div(MULTIPLIER);
		}
		else{
			return depositValue;
		}
	}

    /**
     * @dev Deposit in Indices pool either public pool or pool created by Astra.
     * @param _tokens Token in which user want to give the amount. Currenly ony Stable stable coin is used.
     * @param _values Amount to spend.
	 * @param _poolIndex Pool Index in which user wants to invest.
     */
	function poolIn(address[] calldata _tokens, uint[] calldata _values, uint _poolIndex) external payable nonReentrant whitelistedOnly {
		// Only stable coin and Ether can be used in the initial stages.  
		require(_poolIndex<poolInfo.length, "E02");
		require(poolInfo[_poolIndex].active, "Inactive");
		require(_tokens.length <2 && _values.length<2, "E08");
		initialDeposit[msg.sender][_poolIndex] = block.number;
		// Check if is the first deposit or user already deposit before this. It will be used to calculate early exit fees
		if(!existingUser[msg.sender][_poolIndex]){
			existingUser[msg.sender][_poolIndex] = true;
			PoolUser memory newPoolUser = PoolUser(0, poolInfo[_poolIndex].currentRebalance,0,0,0,true);
            poolUserInfo[_poolIndex][msg.sender] = newPoolUser;
		}

		// Variable that are used internally for logic/calling other functions.
		uint ethValue;
		uint stableValue;
		address[] memory returnedTokens;
	    uint[] memory returnedAmounts;
		//Check if give token length is greater than 0 or not.
		// If it is zero then user should deposit in ether.
		// Other deposit in stable coin
		if(_tokens.length == 0) {
			// User must deposit some amount in pool
			require (msg.value > 0.001 ether, "E09");

			// Swap the ether with stable coin.
			ethValue = msg.value;
    	    stableValue = buyAstraTokenandETH(ethValue, true);
     
		} else {
			// Check if the entered address in the parameter of stable coin or not.
			require(IPoolConfiguration(_poolConf).checkStableCoin(_tokens[0]),"E10");
			require(IERC20Upgradeable(_tokens[0]).balanceOf(msg.sender) >= _values[0], "E11");

			if(_tokens[0] == baseStableCoin){
				
				stableValue = _values[0];
				//Transfer the stable coin from users addresses to contract address.
				IERC20Upgradeable(baseStableCoin).safeTransferFrom(msg.sender,address(this),stableValue);
			}else{
                IERC20Upgradeable(_tokens[0]).safeTransferFrom(msg.sender,address(this),_values[0]);
			    stableValue = sellTokensForStable(_tokens, _values); 
			}
		}

		// Get the value of itoken to mint.
		uint256 ItokenValue = getItokenValue(Iitoken(poolInfo[_poolIndex].itokenaddr).totalSupply(), getPoolValue(_poolIndex), stableValue, totalPoolbalance[_poolIndex]);	
		 //Update the balance initially as the pending amount. Once the tokens are purchased it will be updated.
		 poolPendingbalance[_poolIndex] = poolPendingbalance[_poolIndex].add(stableValue);
		 //Check if total balance in pool if  the threshold is reached.
		 uint checkbalance = totalPoolbalance[_poolIndex].add(poolPendingbalance[_poolIndex]);
		 //Update the user details in mapping.
		 poolUserInfo[_poolIndex][msg.sender].Itokens = poolUserInfo[_poolIndex][msg.sender].Itokens.add(ItokenValue);
		 updateuserinfo(stableValue,_poolIndex);

		 //Buy the tokens if threshold is reached.
		  if (poolInfo[_poolIndex].currentRebalance == 0){
		     if(poolInfo[_poolIndex].threshold <= checkbalance){
		        buytokens( _poolIndex);
		     }     
		  }
		// poolOutstandingValue[_poolIndex] =  poolOutstandingValue[_poolIndex].add();
		// Again update details after tokens are bought.
		updateuserinfo(0,_poolIndex);
		//Mint new itokens and store details in mapping.
		Iitoken(poolInfo[_poolIndex].itokenaddr).mint(msg.sender, ItokenValue);
	}


	 /**
     * @dev Withdraw from Pool using itoken.
	 * @param _poolIndex Pool Index to withdraw funds from.
	 * @param stakeEarlyFees Choose to stake early fees or not.
	 * @param withdrawAmount Amount to withdraw
     */
	function withdraw(uint _poolIndex, bool stakeEarlyFees,bool stakePremium, uint withdrawAmount) external nonReentrant whitelistedOnly{
	    require(_poolIndex<poolInfo.length, "E02");
		require(Iitoken(poolInfo[_poolIndex].itokenaddr).balanceOf(msg.sender)>=withdrawAmount, "E11");
	    // Update user info before withdrawal.
		updateuserinfo(0,_poolIndex);
		if(stakePremium){
			require(poolUserInfo[_poolIndex][msg.sender].currentBalance>0, "E22");
		}
		// Get the user share on the pool
		uint userShare = poolUserInfo[_poolIndex][msg.sender].currentBalance.add(poolUserInfo[_poolIndex][msg.sender].pendingBalance).mul(withdrawAmount).div(poolUserInfo[_poolIndex][msg.sender].Itokens);
		uint _balance;
		uint _pendingAmount;

		// Check if withdrawn amount is greater than pending amount. It will use the pending stable balance after that it will 
		if(userShare>poolUserInfo[_poolIndex][msg.sender].pendingBalance){
			_balance = userShare.sub(poolUserInfo[_poolIndex][msg.sender].pendingBalance);
			_pendingAmount = poolUserInfo[_poolIndex][msg.sender].pendingBalance;
		}else{
			_pendingAmount = userShare;
		}
		// Call the functions to sell the tokens and recieve stable based on the user share in that pool
		uint256 _totalAmount = withdrawTokens(_poolIndex,_balance);
		uint fees;
		uint256 earlyfees;
		uint256 pendingEarlyfees;
		// Check if user actually make profit or not.
		if(_totalAmount>_balance){
			// Charge the performance fees on profit
			fees = _totalAmount.sub(_balance).mul(IPoolConfiguration(_poolConf).getperformancefees()).div(100);
		}
         
		earlyfees = earlyfees.add(calculatefee(msg.sender,_totalAmount.sub(fees),_poolIndex));
		pendingEarlyfees =calculatefee(msg.sender,_pendingAmount,_poolIndex);
		poolUserInfo[_poolIndex][msg.sender].Itokens = poolUserInfo[_poolIndex][msg.sender].Itokens.sub(withdrawAmount);
		//Update details in mapping for the withdrawn aount.
        poolPendingbalance[_poolIndex] = poolPendingbalance[_poolIndex].sub( _pendingAmount);
        poolUserInfo[_poolIndex][msg.sender].pendingBalance = poolUserInfo[_poolIndex][msg.sender].pendingBalance.sub(_pendingAmount);
        totalPoolbalance[_poolIndex] = totalPoolbalance[_poolIndex].sub(_balance);
		poolUserInfo[_poolIndex][msg.sender].currentBalance = poolUserInfo[_poolIndex][msg.sender].currentBalance.sub(_balance);
		// Burn the itokens and update details in mapping.
		Iitoken(poolInfo[_poolIndex].itokenaddr).burn(msg.sender, withdrawAmount);
		withdrawUserAmount(_poolIndex,fees,_totalAmount.sub(fees).sub(earlyfees),_pendingAmount.sub(pendingEarlyfees),earlyfees.add(pendingEarlyfees),stakeEarlyFees,stakePremium);
		emit Withdrawn(msg.sender, _balance);
	}
    // Withdraw amoun and charge fees. Now this single function will be used instead of chargePerformancefees,chargeEarlyFees,withdrawStable,withdrawPendingAmount.
	// Some comment code line is for refrence what original code looks like.
	function withdrawUserAmount(uint _poolIndex,uint fees,uint totalAmount,uint _pendingAmount, uint earlyfees,bool stakeEarlyFees,bool stakePremium) internal{
		// This logic is similar to charge early fees.
		//  If user choose to stake early exit fees it will buy astra and stake them.
		// If user don't want to stake it will be distributes among stakers and index onwer.
		// Distribution logic is similar to performance fees so it is integrated with that. Early fees is added with performance fees. 
		if(stakeEarlyFees){
			uint returnAmount= buyAstraTokenandETH(earlyfees, false);
			stakeAstra(returnAmount);
		}else{
			fees = fees.add(earlyfees);
		}

		// This logic is similar to withdrawStable stable coins.
		// If user choose to stake the amount instead of withdraw it will buy Astra and stake them.
		// If user don't want to stake then they will recieve on there account in base stable coins.
		if(stakePremium){
            uint returnAmount= buyAstraTokenandETH(totalAmount, false);
			stakeAstra(returnAmount);
		}
		else{
			transferTokens(baseStableCoin,msg.sender,totalAmount);
			// IERC20Upgradeable(baseStableCoin).safeTransfer(msg.sender, totalAmount);
		}
		// This logic is similar to withdrawPendingAmount. Early exit fees for pending amount is calculated previously.
		// It transfer the pending amount to user account for which token are not bought.
		transferTokens(baseStableCoin,msg.sender,_pendingAmount);
		// IERC20Upgradeable(baseStableCoin).safeTransfer(msg.sender, _pendingAmount);

		// This logic is similar to chargePerformancefees.
		// 80 percent of fees will be send to the inde creator. Remaining 20 percent will be distributed among stakers.
        if(fees>0){
		uint distribution = fees.mul(80).div(100);
			if(poolInfo[_poolIndex].owner==address(this)){
				transferTokens(baseStableCoin,managerAddresses,distribution);
				// IERC20Upgradeable(baseStableCoin).safeTransfer(managerAddresses, distribution);
			}else{
				transferTokens(baseStableCoin,poolInfo[_poolIndex].owner,distribution);
				//IERC20Upgradeable(baseStableCoin).safeTransfer(poolInfo[_poolIndex].owner, distribution);
			}
			uint returnAmount= buyAstraTokenandETH(fees.sub(distribution), false);
			transferTokens(ASTRTokenAddress,IPoolConfiguration(_poolConf).treasuryAddress(),returnAmount);
		}
	}

	function transferTokens(address _token, address _reciever,uint _amount) internal{
		IERC20Upgradeable(_token).safeTransfer(_reciever, _amount);
	}

	/**
     * @dev Internal fucntion to Withdraw from Pool using itoken.
	 * @param _poolIndex Pool Index to withdraw funds from.
	 * @param _balance Amount to withdraw from Pool.
     */

	function withdrawTokens(uint _poolIndex,uint _balance) internal returns(uint256){
		uint localWeight;

		// Check if total pool balance is more than 0. 
		if(totalPoolbalance[_poolIndex]>0){
			localWeight = _balance.mul(1 ether).div(totalPoolbalance[_poolIndex]);
			// localWeight = _balance.mul(1 ether).div(Iitoken(poolInfo[_poolIndex].itokenaddr).totalSupply());
		}  
		
		uint _totalAmount;

		// Run loop over the tokens in the indices pool to sell the user share.
		for (uint i = 0; i < poolInfo[_poolIndex].tokens.length; i++) {
			// Get the total token balance in that Pool.
			uint tokenBalance = tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]];
		    // Get the user share from the total token amount
		    uint withdrawBalance = tokenBalance.mul(localWeight).div(1 ether);
		    if (withdrawBalance == 0) {
		        continue;
		    }
			// Skip if withdraw amount is 0
		    if (poolInfo[_poolIndex].tokens[i] == baseStableCoin) {
		        _totalAmount = _totalAmount.add(withdrawBalance);
		        continue;
		    }
			// Approve the Exchnage contract before selling thema.
		    IERC20Upgradeable(poolInfo[_poolIndex].tokens[i]).approve(EXCHANGE_CONTRACT, withdrawBalance);
			// Get the expected amount of  tokens to sell
			(uint256 _amount,,) = DexAggregator(EXCHANGE_CONTRACT).getBestExchangeRate(poolInfo[_poolIndex].tokens[i], baseStableCoin, withdrawBalance);
			if (_amount == 0) {
		        continue;
		    }
			// Swap the tokens and get stable in return so that users can withdraw.
			_amount = DexAggregator(EXCHANGE_CONTRACT).swapFromBestExchange(poolInfo[_poolIndex].tokens[i], baseStableCoin, withdrawBalance, _amount);

			_totalAmount = _totalAmount.add(_amount);
			tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]] = tokenBalance.sub(withdrawBalance);
		}
		return _totalAmount;
	}

	 /**
     * @dev Update pool function to do the rebalaning.
     * @param _tokens New tokens to purchase after rebalance.
     * @param _weights Weight of new tokens.
	 * @param _threshold Threshold amount to purchase token.
	 * @param _rebalanceTime Next Rebalance time.
	 * @param _poolIndex Pool Index to do rebalance.
     */
	function updatePool(address[] memory _tokens,uint[] memory _weights,uint _threshold,uint _rebalanceTime,uint _poolIndex) public nonReentrant whitelistedOnly{	    
	    require(block.timestamp >= poolInfo[_poolIndex].rebaltime,"E12");
		// require(poolUserInfo[_poolIndex][msg.sender].currentBalance>poolInfo[_poolIndex].threshold,"Threshold not reached");
		// Check if entered indices pool is public or Astra managed.
		// Also check if is public pool then request came from the owner or not.
		if(poolInfo[_poolIndex].owner != address(this)){
		    require(_tokens.length == _weights.length, "E02");
			require(poolInfo[_poolIndex].owner == msg.sender, "E13");
		}else{
			(_tokens, _weights,_threshold,_rebalanceTime) = IOracle(IPoolConfiguration(_poolConf).getoracleaddress()).getTokenDetails(_poolIndex);
		}
		require (_tokens.length <= IPoolConfiguration(_poolConf).getmaxTokenSupported(), "E16");

	    address[] memory newTokens;
	    uint[] memory newWeights;
	    uint newTotalWeight;
		
		uint _newTotalWeight;

		// Loop over the tokens details to update its total weight.
		for(uint i = 0; i < _tokens.length; i++) {
			require (_tokens[i] != ETH_ADDRESS && _tokens[i] != WETH_ADDRESS, "E20");			
			_newTotalWeight = _newTotalWeight.add(_weights[i]);
		}
		
		// Update new tokens details
		newTokens = _tokens;
		newWeights = _weights;
		newTotalWeight = _newTotalWeight;
		// Update the pool details for next rebalance
		poolInfo[_poolIndex].threshold = _threshold;
		poolInfo[_poolIndex].rebaltime = _rebalanceTime;
		//Sell old tokens and buy new tokens.
		rebalance(newTokens, newWeights,newTotalWeight,_poolIndex);
		

		// Buy the token for Stable which is in pending state.
		if(poolPendingbalance[_poolIndex]>0){
		 buytokens(_poolIndex);   
		}
		
	}

	/**
	* @dev Enable or disable Pool can only be called by admin
	*/
	function setPoolStatus(bool _active,uint _poolIndex) external {
		require(msg.sender == poolInfo[_poolIndex].owner, "E18");
		poolInfo[_poolIndex].active = _active;
		emit SetPoolStatus(_poolIndex,_active);
	}	
	
	/** 
	 * @dev Internal function called while updating the pool.
	 */

	function rebalance(address[] memory newTokens, uint[] memory newWeights,uint newTotalWeight, uint _poolIndex) internal {
	    require(poolInfo[_poolIndex].currentRebalance >0, "E14");
		// Variable used to call the functions internally
		uint[] memory buf2;
		buf = buf2;
		uint ethValue;
		address[] memory returnedTokens;
	    uint[] memory returnedAmounts;

		//Updating the balancing of tokens you are selling in storage and make update the balance in main mapping.
		for (uint i = 0; i < poolInfo[_poolIndex].tokens.length; i++) {
			buf.push(tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]]);
			tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]] = 0;
		}
		
		// Sell the Tokens in pool to recieve tokens
		if(totalPoolbalance[_poolIndex]>0){
		 ethValue = sellTokensForStable(poolInfo[_poolIndex].tokens, buf);   
		}

		// Updating pool configuration/mapping to update the new tokens details
		poolInfo[_poolIndex].tokens = newTokens;
		poolInfo[_poolIndex].weights = newWeights;
		poolInfo[_poolIndex].totalWeight = newTotalWeight;
		poolInfo[_poolIndex].currentRebalance = poolInfo[_poolIndex].currentRebalance.add(1);
		poolInfo[_poolIndex].lastrebalance = block.timestamp;
		
		// Return if you recieve 0 value for selling all the tokens
		if (ethValue == 0) {
		    return;
		}
		
		uint[] memory buf3;
		buf = buf3;
		
		// Buy new tokens for the pool.
		if(totalPoolbalance[_poolIndex]>0){
			//Buy new tokens
		 (returnedTokens, returnedAmounts) = swap2(baseStableCoin, ethValue, newTokens, newWeights,newTotalWeight,buf);
		// Update those tokens details in mapping.
		for(uint i = 0; i < poolInfo[_poolIndex].tokens.length; i++) {
			tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]] = buf[i];
	    	
		}  
		}
		
	}

	/** 
	 * @dev Get the current value of pool to check the value of pool
	 */

	function getPoolValue(uint256 _poolIndex)internal returns(uint256){
		// Used to get the Expected amount for the token you are selling.
		uint _amount;
		// Return the total Amount of Stable you will recieve for selling. This will be total value of pool that it has purchased.
		uint _totalAmount;

		// Run loops over the tokens in the pool to get the token worth.
		for (uint i = 0; i < poolInfo[_poolIndex].tokens.length; i++) {
			if(tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]]>0){
			(_amount,,) = DexAggregator(EXCHANGE_CONTRACT).getBestExchangeRate(poolInfo[_poolIndex].tokens[i], baseStableCoin, tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]]);
			}else{
				_amount = 0;
			}
			if (_amount == 0) {
		        continue;
		    }
		    _totalAmount = _totalAmount.add(_amount);
		}

		// Return the total values of pool locked
		return _totalAmount.add(poolPendingbalance[_poolIndex]);
	}


	// function swap(address _token, uint _value, address[] memory _tokens, uint[] memory _weights, uint _totalWeight) internal returns(address[] memory, uint[] memory) {
	// 	// Use to get the share of particular token based on there share.
	// 	uint _tokenPart;
    //     // Run loops over the tokens in the parametess to buy them.
	// 	for(uint i = 0; i < _tokens.length; i++) { 
	// 	    // Calculate the share of token based on the weight and the buy for that.
	// 	    _tokenPart = _value.mul(_weights[i]).div(_totalWeight);

	// 		// Get the amount of tokens pool will recieve based on the token selled.
	// 		(uint256 _amount,,) = DexAggregator(EXCHANGE_CONTRACT).getBestExchangeRate(_token, _tokens[i], _tokenPart);
	// 	    // calculate slippage
	// 		uint256 minReturn = calculateMinimumReturn(_amount);

	// 		// Check condition if token you are selling is ETH or another ERC20 and then sell the tokens.
	// 		if (_token == ETH_ADDRESS) {
	// 			_amount = DexAggregator(EXCHANGE_CONTRACT).swapFromBestExchange.value(_tokenPart)(_token, _tokens[i], _tokenPart, minReturn);
	// 		} else {
	// 		    IERC20Upgradeable(_tokens[i]).approve(EXCHANGE_CONTRACT, _tokenPart);
	// 			_amount = DexAggregator(EXCHANGE_CONTRACT).swapFromBestExchange(_token, _tokens[i], _tokenPart, minReturn);
	// 		}
	// 		_weights[i] = _amount;
			
	// 	}
		
	// 	return (_tokens, _weights);
	// }

	/** 
	 * @dev Function to swap two token. It used in case of ERC20 - ERC20 swap.
	 */
	
	function swap2(address _token, uint _value, address[] memory newTokens, uint[] memory newWeights,uint newTotalWeight, uint[] memory _buf) internal returns(address[] memory, uint[] memory) {
		// Use to get the share of particular token based on there share.
		uint _tokenPart;
		buf = _buf;
		// Approve before selling the tokens
		IERC20Upgradeable(_token).approve(EXCHANGE_CONTRACT, _value);
		 // Run loops over the tokens in the parametess to buy them.
		for(uint i = 0; i < newTokens.length; i++) {
            
			_tokenPart = _value.mul(newWeights[i]).div(newTotalWeight);
			
			if(_tokenPart == 0) {
			    buf.push(0);
			    continue;
			}
			
			(uint256 _amount,,) = DexAggregator(EXCHANGE_CONTRACT).getBestExchangeRate(_token, newTokens[i], _tokenPart);
			uint256 minReturn = calculateMinimumReturn(_amount);
			_amount = DexAggregator(EXCHANGE_CONTRACT).swapFromBestExchange(_token, newTokens[i], _tokenPart, minReturn);
			buf.push(_amount);
            newWeights[i] = _amount;
		}
		return (newTokens, newWeights);
	}

	/** 
	 * @dev Sell tokens for Stable is used during the rebalancing to sell previous token and buy new tokens
	 */
	function sellTokensForStable(address[] memory _tokens, uint[] memory _amounts) internal returns(uint) {
		// Return the total Amount of Stable you will recieve for selling
		uint _totalAmount;
		
		// Run loops over the tokens in the parametess to sell them.
		for(uint i = 0; i < _tokens.length; i++) {
		    if (_amounts[i] == 0) {
		        continue;
		    }
		    
		    if (_tokens[i] == baseStableCoin) {
		        _totalAmount = _totalAmount.add(_amounts[i]);
		        continue;
		    }

			// Approve token access to Exchange contract.
		    IERC20Upgradeable(_tokens[i]).approve(EXCHANGE_CONTRACT, _amounts[i]);
		    // Get the amount of Stable tokens you will recieve for selling tokens 
			(uint256 _amount,,) = DexAggregator(EXCHANGE_CONTRACT).getBestExchangeRate(_tokens[i], baseStableCoin, _amounts[i]);
			// Skip remaining execution if no token is available
			if (_amount == 0) {
		        continue;
		    }
			// Calculate slippage over the the expected amount
		    uint256 minReturn = calculateMinimumReturn(_amount);
			// Actually swap tokens
			_amount = DexAggregator(EXCHANGE_CONTRACT).swapFromBestExchange(_tokens[i], baseStableCoin, _amounts[i], minReturn);
			_totalAmount = _totalAmount.add(_amount);
			
		}

		return _totalAmount;
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}