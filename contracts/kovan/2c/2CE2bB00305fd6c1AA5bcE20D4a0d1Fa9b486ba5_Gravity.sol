//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Gravity{
    uint utcStartTime; // Deepak: do we need this???

    address owner;
    uint    numberOfAccounts;

    uint strategyCount;
    uint daiDailyPurchase;
    bool tradeExecuted;

    event Deposited(address, uint256);
    event Withdrawn(address, uint256);

    // data structure for each account policy
    struct Account {
        uint             accountStart;
        string           sourceAsset;
        string           targetAsset;
        uint             originalSourceBalance;
        uint             sourceBalance;
        uint             targetBalance;
        uint             intervalAmount;
        string           strategyFrequency;   // number of interval days, minimum will be 1 day and max yearly;         // timestamp offset
    }

    // purchase order details for a user & account policy at a specific interval
    struct PurchaseOrder {
        address user;
        uint    AccountId;
        uint    purchaseAmount;
    }

    // user address to user Account policy mapping
    mapping (address => mapping (uint => Account)) public accounts;

    // timestamp interval to PurchaseOrder mapping
    mapping (uint => PurchaseOrder[]) public liveStrategies;

    // ERC20 token address mapping
    mapping (string => address) public tokenAddresses;

    //Frequency mapping for validation
    mapping (string => bool) public IntervalFrquency;

    constructor() {
        utcStartTime = block.timestamp; // contract deployment timestamp
        owner = msg.sender;
        numberOfAccounts = 0;
            
            // load asset addresses into tokenAddress mapping
        tokenAddresses['USDC']  = address(0xe11A86849d99F524cAC3E7A0Ec1241828e332C62);
        tokenAddresses['WETH'] = address(0xd0A1E359811322d97991E03f863a0C30C2cF029C);
        tokenAddresses['LINK'] = address(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);

        //Load IntervalFrquency mapping table 
        IntervalFrquency['Daily'] = true;
        IntervalFrquency['Weekly'] = true;
        IntervalFrquency['Monthly'] = true;
        IntervalFrquency['Quaterly'] = true;
        IntervalFrquency['HalfYearly'] = true;
        IntervalFrquency['Yearly'] = true;
    }

    function addNewToken(string memory _sourceAsset,address _sourceAssetAddress) external{
        require(msg.sender == owner,"Only owner can add new Source Asset");
        require(_sourceAssetAddress !=address(0x0));
        tokenAddresses[_sourceAsset] = _sourceAssetAddress;
    }

    function initiateNewStrategy( string            calldata _sourceAsset,
                                  string            calldata _targetAsset,
                                  uint                       _sourceBalance,
                                  uint                       _intervalAmount,
                                  string            calldata _strategyFrequency) 
                                external{
        require(tokenAddresses[_sourceAsset] != address(0x0) && tokenAddresses[_targetAsset] != address(0x0), "Unsupported source or target asset type");                                    
        require(_intervalAmount<=_sourceBalance,"Interval Amount cannot be more than Strategy Source Asset");
        require(IntervalFrquency[_strategyFrequency],"Invalid value for strategy frequency");
        require(tokenAddresses[_sourceAsset] != tokenAddresses[_targetAsset],"Source and Target asset cannot be same");

        //Validate inputs for accounts
        //Create new Account of type structure Account
        Account memory newAccount;
        
        //Initialize new account
        uint       accountId             = numberOfAccounts+1;

        newAccount.accountStart          = block.timestamp;
        newAccount.sourceAsset           = _sourceAsset;
        newAccount.sourceBalance         = _sourceBalance;
        newAccount.originalSourceBalance = _sourceBalance;
        newAccount.targetAsset           = _targetAsset;        
        newAccount.targetBalance         = 0;
        newAccount.intervalAmount        = _intervalAmount;
        newAccount.strategyFrequency     = _strategyFrequency;

        // Add the new account policy to current user's accounts mapping
        accounts[msg.sender][accountId] = newAccount;

        // Deposit orginal source balance to contract
        deposit(_sourceAsset,_sourceBalance);


        // Source and intervalAmount > 0. Source amount >= Interval amount 
        // Populate account
        // Populate Strategy
        // source and target type cannot be same

     }

     // deposit first requires approving an allowance by the msg.sender
    
     function deposit(string memory _sourceAsset,uint _amount) internal {
        address _token = tokenAddresses[_sourceAsset];
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount),"Initial deposit transfer failed");
        emit Deposited(msg.sender, _amount);
    }

       
    /*function deposit(string memory _sourceAsset, uint256 _amount) internal {
        require(tokenAddresses[_sourceAsset] != address(0x0), "Unsupported asset type");
        address _token = tokenAddresses[_sourceAsset];
        accounts[msg.sender][0].sourceBalance += _amount;
        (bool success) = IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        require(success, "Deposit unsuccessful: transferFrom");
        emit Deposited(msg.sender, _amount);
    }*/

    function withdraw(uint accountId, uint256 _amount) external {
        string   memory _sourceAsset = accounts[msg.sender][accountId].sourceAsset;
        address _token = tokenAddresses[_sourceAsset];
        require(accounts[msg.sender][accountId].sourceBalance >= _amount);
        accounts[msg.sender][accountId].sourceBalance -= _amount;
        (bool success) = IERC20(_token).transfer(msg.sender, _amount);
        require(success, "Withdraw unsuccessful");
        emit Withdrawn(msg.sender, _amount);
    }

    receive() external payable {}

    // // function to remove prior days array value from liveStrategies
    // function deleteKV(uint timestamp) internal {
    //     delete liveStrategies[timestamp];
    // }

    // // constant time function to remove users with 0 daiBalance, decrement dailyPoolUserCount
    // function removeStrategy(uint index) internal {
    //     require(index < liveStrategies.length, "Index out of range");
    //     liveStrategies[index] = liveStrategies[liveStrategies.length - 1];
    //     liveStrategies.pop();
    //     strategyCount--;
    // }

     

    // // function withdrawSource() {

    // // }

    // // function withdrawTarget() {

    // // }


    // /*
    //     TO DO: inherit Chainlink Keepers contract functionality
    // */
    // function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
    //     require(tradeExecuted == false);
    //     upkeepNeeded = (block.timestamp % 24 * 60 * 60 == 0);
    //     // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    // }

    // // performs the work on the contract, if instructed by checkUpkeep().
    // function performUpkeep(bytes calldata /* performData */) external override {
    //     //We highly recommend revalidating the upkeep in the performUpkeep function
    //     // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    // }

    // // keeper performUpkeep function executes batchTransaction once per day
    // function batchTransaction() external payable {

    //     // daily range to check whether user has purchase to be made today
    //     uint today = block.timestamp;
    //     uint todayStart = today - (12 * 60 * 60);
    //     uint todayEnd = today + (12 * 60 * 60); 

    //     // loop over liveStrategies
    //     for(uint i = 0; i < strategyCount; i++) {
    //         uint userNextPurchase = liveStrategies[i].initStrategy + (liveStrategies[i].purchaseFrequency * 24 * 60 * 60);

    //         // if user still has purchasesRemaining continue
    //         if(liveStrategies[i].purchasesRemaining > 0) {

    //             // if users next purchase falls within today
    //             if(userNextPurchase > todayStart && userNextPurchase < todayEnd) {

    //                 // check balance is above user's purchase amount
    //                 if(accounts[liveStrategies[i].user].daiBalance > liveStrategies[i].purchaseAmount) {

    //                     // decrement user's daiBalance
    //                     accounts[liveStrategies[i].user].daiBalance - liveStrategies[i].purchaseAmount;

    //                     // decrement user's purchasesRemaining;
    //                     liveStrategies[i].purchasesRemaining -= 1;

    //                     // increment daiDailyPurchase for today
    //                     daiDailyPurchase += liveStrategies[i].purchaseAmount;
    //                 }
    //             }
    //         }
    //         else { // purchasesRemaining == 0; remove from liveStrategies array 
    //             removeStrategy(i);
    //         }
    //     }
    //     require(daiDailyPurchase > 0, "DA daily purchase insufficient");
        
    //     /*
    //         TO DO: integrate executeTrade() function
    //     */

    //     /*
    //         TO DO: run allocate function to update user ETH balances
    //     */

    // }


    // /*
    //     TO DO: yield function/treasury allocation 
    // */

}

// SPDX-License-Identifier: MIT
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