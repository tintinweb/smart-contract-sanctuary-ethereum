// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
───────▄▀▀▀▀▀▀▀▀▀▀▄▄
────▄▀▀░░░░░░░░░░░░░▀▄
──▄▀░░░░░░░░░░░░░░░░░░▀▄
──█░░░░░░░░░░░░░░░░░░░░░▀▄
─▐▌░░░░░░░░▄▄▄▄▄▄▄░░░░░░░▐▌
─█░░░░░░░░░░░▄▄▄▄░░▀▀▀▀▀░░█
▐▌░░░░░░░▀▀▀▀░░░░░▀▀▀▀▀░░░▐▌
█░░░░░░░░░▄▄▀▀▀▀▀░░░░▀▀▀▀▄░█
█░░░░░░░░░░░░░░░░▀░░░▐░░░░░▐▌
▐▌░░░░░░░░░▐▀▀██▄░░░░░░▄▄▄░▐▌
─█░░░░░░░░░░░▀▀▀░░░░░░▀▀██░░█
─▐▌░░░░▄░░░░░░░░░░░░░▌░░░░░░█
──▐▌░░▐░░░░░░░░░░░░░░▀▄░░░░░█
───█░░░▌░░░░░░░░▐▀░░░░▄▀░░░▐▌
───▐▌░░▀▄░░░░░░░░▀░▀░▀▀░░░▄▀
───▐▌░░▐▀▄░░░░░░░░░░░░░░░░█
───▐▌░░░▌░▀▄░░░░▀▀▀▀▀▀░░░█
───█░░░▀░░░░▀▄░░░░░░░░░░▄▀
──▐▌░░░░░░░░░░▀▄░░░░░░▄▀
─▄▀░░░▄▀░░░░░░░░▀▀▀▀█▀
▀░░░▄▀░░░░░░░░░░▀░░░▀▀▀▀▄▄▄▄▄
 /$$      /$$                     /$$       /$$       /$$      /$$ /$$       /$$                 /$$      /$$                         /$$      
| $$  /$ | $$                    | $$      | $$      | $$  /$ | $$|__/      | $$                | $$  /$ | $$                        | $$      
| $$ /$$$| $$  /$$$$$$   /$$$$$$ | $$  /$$$$$$$      | $$ /$$$| $$ /$$  /$$$$$$$  /$$$$$$       | $$ /$$$| $$  /$$$$$$  /$$  /$$$$$$ | $$   /$$
| $$/$$ $$ $$ /$$__  $$ /$$__  $$| $$ /$$__  $$      | $$/$$ $$ $$| $$ /$$__  $$ /$$__  $$      | $$/$$ $$ $$ /$$__  $$|__/ |____  $$| $$  /$$/
| $$$$_  $$$$| $$  \ $$| $$  \__/| $$| $$  | $$      | $$$$_  $$$$| $$| $$  | $$| $$$$$$$$      | $$$$_  $$$$| $$  \ $$ /$$  /$$$$$$$| $$$$$$/ 
| $$$/ \  $$$| $$  | $$| $$      | $$| $$  | $$      | $$$/ \  $$$| $$| $$  | $$| $$_____/      | $$$/ \  $$$| $$  | $$| $$ /$$__  $$| $$_  $$ 
| $$/   \  $$|  $$$$$$/| $$      | $$|  $$$$$$$      | $$/   \  $$| $$|  $$$$$$$|  $$$$$$$      | $$/   \  $$|  $$$$$$/| $$|  $$$$$$$| $$ \  $$
|__/     \__/ \______/ |__/      |__/ \_______/      |__/     \__/|__/ \_______/ \_______/      |__/     \__/ \______/ | $$ \_______/|__/  \__/
                                                                                                                  /$$  | $$                    
                                                                                                                 |  $$$$$$/                    
                                                                                                                  \______/                     
*/
// ----------------------------------------------------------------------------
// 
// FEATURES:
//    %7 maximum ownership to ensure decentralization
//    ~%1.5 total marketing, prizes, airdrops, and bounties
//    variable staking based on current supply / max supply. (decreases as current suppply increases)
//    Variable burn rate based on current supply / max supply (increases as current supply increases)
//    All sales tax is burned, except 0.25% for continued liquidity and marketing over life of project
//
// TOKENOMICS
// Initial Supply = 420 420 420 69
// Max Supply = 420,000,000,000
// ALL additional supply after initial release is created through staking rewards(fair distribution)
//
// In other words about 90% of the total supply is up for grabs through staking. 
//
// LEARN MOAR:
//    Website  https://wwwojak.com
//
// ----------------------------------------------------------------------------

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "./Ownable.sol";
import "./Stakeable.sol";


contract WWWojak is Ownable, Stakeable, ERC20 {
  
// define contract wallets CHANGED TO INTERNAL
// marketing wallet; Pamp It!!
  address internal constant bogdanov1Wallet = 0x93780f0ebe25a52c709D22CfDefD02FC96E2b065;
// Main supply wallet; Damp It!!
  address internal constant bogdanov2Wallet = 0x938A2C973f556A70B6b26c11B2fCAED6ff35B9Bd;


  // 1 divided by Tax rate
  uint internal taxRate = 420;
  uint internal burnRate = 50;
  uint public maxSupply = 420000000000 * 10 ** decimals();


  /**
  * @notice _balances is a mapping that contains a address as KEY 
  * and the balance of the address as the value
  */
  mapping (address => uint256) private _balances;
  /**
  * @notice _allowances is used to manage and control allownace
  * An allowance is the right to use another accounts balance, or part of it
   */
   mapping (address => mapping (address => uint256)) private _allowances;

  /**
  * @notice constructor will be triggered when we create the Smart contract
  * _name = name of the token
  * _short_symbol = Short Symbol name for the token
  * token_decimals = The decimal precision of the Token, defaults 18
  * _totalSupply is how much Tokens there are totally 
  */
//  constructor(string memory token_name, string memory short_symbol, uint8 token_decimals, uint256 token_totalSupply) ERC20("WWWojak", "WWWJ") {
  constructor() ERC20("WWWojak", "WWWJ") { 
      _mint(msg.sender, 42042042069 * 10 ** decimals());
      _mint(bogdanov1Wallet,  6942042069 * 10 ** decimals());

  }

    /**
    * Add functionality like burn to the _stake afunction
    *
     */
    function stake(uint256 _amount) public {
      // Make sure staker actually has balances to stake.
      require(_amount <= balanceOf(msg.sender), "ERC20: Cannot stake more than you own");
      require(grandTotalSupply() < maxSupply, "ERC20: Cannot stake right now. No available slots. Try again later");
        _stake(_amount);
                // Burn the amount of tokens on the sender
        _burn(msg.sender, _amount);
    }



    /**
    * @notice withdrawStake is used to withdraw stakes from the account holder
     */
    function withdrawStake(uint256 amount, uint256 stake_index)  public {
      uint256 amount_to_mint = _withdrawStake(amount, stake_index);
      uint256 newSupply = amount_to_mint + grandTotalSupply();
      require(newSupply < maxSupply, "ERC20: Cannot mint right now. Total supply exceeded. Try withdrawing less or again later");
      // Return staked tokens to user
      _mint(msg.sender, amount_to_mint);
    }

    function withdrawAllStakes()  public {
        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[stakeholders[stakes[msg.sender]].user]].address_stakes);
        for (uint256 s = 0; s < summary.stakes.length; s += 1){
            withdrawStake(summary.stakes[s].amount, s);
       }}
    

    function transfer(address to, uint amount) public override returns (bool) {

  // check sender bal
    uint balanceReceiver = balanceOf(to);
    uint balanceSender = balanceOf(msg.sender);
    require(balanceSender >= amount, "ERC20: Insufficient Funds for Transfer");
    require(amount + balanceReceiver <= maxSupply / 14, "ERC20: A single token holder cannot own more than ~7% of the supply");
  // impose tax
    uint taxAmount = amount / taxRate;
    uint burnAmount = amount / currentBurnRate(); 
    uint transferAmount = amount - taxAmount - burnAmount;
  // transfer tokens net of tax, tax portion, burn remainder
    _transfer(msg.sender, to, transferAmount); 
    _transfer(msg.sender, bogdanov1Wallet, taxAmount);
    _burn(msg.sender, burnAmount);
  //    _transfer(msg.sender, deadWallet, burnAmount); 
    return true;

    }    


    /**
    * @notice transferFrom is uesd to transfer Tokens from a Accounts allowance
    * Spender address should be the token holder
    *
    * Requires
    *   - The caller must have a allowance = or bigger than the amount spending
     */

    function transferFrom(address spender, address recipient, uint256 amount) public override returns(bool){
      uint balanceReceiver = balanceOf(recipient);
      uint balanceSender = balanceOf(spender);
      require(balanceSender >= amount, "ERC20: Insufficient Funds for Transfer");
      require(amount + balanceReceiver <= maxSupply / 14, "ERC20: A single token holder cannot own more than ~7% of the supply");
      // Make sure spender is allowed the amount 
      require(_allowances[spender][msg.sender] >= amount, "ERC20: You cannot spend that much on this account");
      // impose tax
      uint taxAmount = amount / taxRate;
      uint burnAmount = amount / currentBurnRate(); 
      uint transferAmount = amount - taxAmount - burnAmount;
      // Transfer first
      _transfer(spender, recipient, transferAmount); 
      _transfer(spender, bogdanov1Wallet, taxAmount);
      _burn(spender, burnAmount);
      // Reduce current allowance so a user cannot respend
      _approve(spender, msg.sender, _allowances[spender][msg.sender] - amount);
      return true;
    }


    function grandTotalSupply() public view returns (uint256) {
        uint256 GrandTotalSupply = totalSupply() + getGlobalTotalStaked();
        // + getGlobalStakeRewardEstimate();
        return GrandTotalSupply;
   }

    function currentRewardPerHour() public view returns (uint256) {
      uint256 varReward = 42069 * grandTotalSupply() / maxSupply;      
      return varReward;
    }



    function currentBurnRate() public view returns (uint256) {
      uint256 tenPercentTotal = maxSupply / 10;
      uint256 tensCount = grandTotalSupply() / tenPercentTotal;
      uint256 cBurnRate = 2 * ((10 - tensCount) ** 2) + 4;   
      return cBurnRate;
    }

    /**
      * @notice
      * calculateStakeReward is used to calculate how much a user should be rewarded for their stakes
      * and the duration the stake has been active
     */
      function calculateStakeReward(Stake memory _current_stake) internal view override returns(uint256){
          return (((block.timestamp - _current_stake.since) / rewardsEvery ) * _current_stake.amount) / currentRewardPerHour();
         }     // can alter amount using sqrt 


      function getMyStakeRewardEstimate(uint256 index) public view override returns(uint256){
         uint256 user_index = stakes[msg.sender];
         uint256 cStake = stakeholders[user_index].address_stakes[index].amount;
         uint256 cSince = stakeholders[user_index].address_stakes[index].since;
         return (((block.timestamp - cSince) / rewardsEvery ) * cStake) / currentRewardPerHour();

     }

      function getGlobalStakeRewardEstimate() public view override returns(uint256){
        uint256 cStake;
        uint256 cSince;
        uint256 getRewardAmount;
        uint256 allRewards;
        for (uint256 i = 0; i < stakeholders.length ; i += 1){
          StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[stakeholders[i].user]].address_stakes);
          for (uint256 s = 0; s < summary.stakes.length; s += 1){
//           uint256 availableReward = calculateStakeReward(summary.stakes[s]);
//           summary.stakes[s].claimable = availableReward;
            cStake = stakeholders[i].address_stakes[s].amount;
            cSince = stakeholders[i].address_stakes[s].since;
            getRewardAmount = (((block.timestamp - cSince) / rewardsEvery ) * cStake) / currentRewardPerHour();
            allRewards += getRewardAmount ;
        }}
        return allRewards;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
───────▄▀▀▀▀▀▀▀▀▀▀▄▄
────▄▀▀░░░░░░░░░░░░░▀▄
──▄▀░░░░░░░░░░░░░░░░░░▀▄
──█░░░░░░░░░░░░░░░░░░░░░▀▄
─▐▌░░░░░░░░▄▄▄▄▄▄▄░░░░░░░▐▌
─█░░░░░░░░░░░▄▄▄▄░░▀▀▀▀▀░░█
▐▌░░░░░░░▀▀▀▀░░░░░▀▀▀▀▀░░░▐▌
█░░░░░░░░░▄▄▀▀▀▀▀░░░░▀▀▀▀▄░█
█░░░░░░░░░░░░░░░░▀░░░▐░░░░░▐▌
▐▌░░░░░░░░░▐▀▀██▄░░░░░░▄▄▄░▐▌
─█░░░░░░░░░░░▀▀▀░░░░░░▀▀██░░█
─▐▌░░░░▄░░░░░░░░░░░░░▌░░░░░░█
──▐▌░░▐░░░░░░░░░░░░░░▀▄░░░░░█
───█░░░▌░░░░░░░░▐▀░░░░▄▀░░░▐▌
───▐▌░░▀▄░░░░░░░░▀░▀░▀▀░░░▄▀
───▐▌░░▐▀▄░░░░░░░░░░░░░░░░█
───▐▌░░░▌░▀▄░░░░▀▀▀▀▀▀░░░█
───█░░░▀░░░░▀▄░░░░░░░░░░▄▀
──▐▌░░░░░░░░░░▀▄░░░░░░▄▀
─▄▀░░░▄▀░░░░░░░░▀▀▀▀█▀
▀░░░▄▀░░░░░░░░░░▀░░░▀▀▀▀▄▄▄▄▄
/$$      /$$                         /$$              /$$$$$$   /$$               /$$       /$$                    
| $$  /$ | $$                        | $$             /$$__  $$ | $$              | $$      |__/                    
| $$ /$$$| $$  /$$$$$$  /$$  /$$$$$$ | $$   /$$      | $$  \__//$$$$$$    /$$$$$$ | $$   /$$ /$$ /$$$$$$$   /$$$$$$ 
| $$/$$ $$ $$ /$$__  $$|__/ |____  $$| $$  /$$/      |  $$$$$$|_  $$_/   |____  $$| $$  /$$/| $$| $$__  $$ /$$__  $$
| $$$$_  $$$$| $$  \ $$ /$$  /$$$$$$$| $$$$$$/        \____  $$ | $$      /$$$$$$$| $$$$$$/ | $$| $$  \ $$| $$  \ $$
| $$$/ \  $$$| $$  | $$| $$ /$$__  $$| $$_  $$        /$$  \ $$ | $$ /$$ /$$__  $$| $$_  $$ | $$| $$  | $$| $$  | $$
| $$/   \  $$|  $$$$$$/| $$|  $$$$$$$| $$ \  $$      |  $$$$$$/ |  $$$$/|  $$$$$$$| $$ \  $$| $$| $$  | $$|  $$$$$$$
|__/     \__/ \______/ | $$ \_______/|__/  \__/       \______/   \___/   \_______/|__/  \__/|__/|__/  |__/ \____  $$
                  /$$  | $$                                                                                /$$  \ $$
                 |  $$$$$$/                                                                               |  $$$$$$/
                  \______/                                                                                 \______/ 
*/

/**
* @notice Stakeable is a contract who is ment to be inherited by other contract that wants Staking capabilities
*/
contract Stakeable {

// 3600 is hourly    
    uint rewardsEvery = 3600;
// 35000 is .00286% per hour. Roughly 25% (.00286* 24 *365) annually
    uint256 internal rewardPerHour = 35000;

    /**
    * @notice Constructor since this contract is not ment to be used without inheritance
    * push once to stakeholders for it to work proplerly
     */
    constructor() {
        // This push is needed so we avoid index 0 causing bug of index-1
        stakeholders.push();
    }
    /**
     * @notice
     * A stake struct is used to represent the way we store stakes, 
     * A Stake will contain the users address, the amount staked and a timestamp, 
     * Since which is when the stake was made
     */
    struct Stake{
        address user;
        uint256 amount;
        uint256 since;
        uint256 claimable;
    }
    /**
    * @notice Stakeholder is a staker that has active stakes
     */
    struct Stakeholder{
        address user;
        Stake[] address_stakes;
        
    }
     /**
     * @notice
     * StakingSummary is a struct that is used to contain all stakes performed by a certain account
     */ 
     struct StakingSummary{
         uint256 total_amount;
         Stake[] stakes;
     }

    /**
    * @notice 
    *   This is a array where we store all Stakes that are performed on the Contract
    *   The stakes for each address are stored at a certain index, the index can be found using the stakes mapping
    */
    Stakeholder[] internal stakeholders;
    /**
    * @notice 
    * stakes is used to keep track of the INDEX for the stakers in the stakes array
     */
    mapping(address => uint256) internal stakes;
    /**
    * @notice Staked event is triggered whenever a user stakes tokens, address is indexed to make it filterable
     */
     event Staked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);



    /**
    * @notice _addStakeholder takes care of adding a stakeholder to the stakeholders array
     */
    function _addStakeholder(address staker) internal returns (uint256){
        // Push a empty item to the Array to make space for our new stakeholder
        stakeholders.push();
        // Calculate the index of the last item in the array by Len-1
        uint256 userIndex = stakeholders.length - 1;
        // Assign the address to the new index
        stakeholders[userIndex].user = staker;
        // Add index to the stakeHolders
        stakes[staker] = userIndex;
        return userIndex; 
    }


    /**
    * @notice
    * _Stake is used to make a stake for an sender. It will remove the amount staked from the stakers account and place those tokens inside a stake container
    * StakeID 
    */
    function _stake(uint256 _amount) internal{
        // Simple check so that user does not stake 0 
        require(_amount > 0, "Cannot stake nothing");
        

        // Mappings in solidity creates all values, but empty, so we can just check the address
        uint256 index = stakes[msg.sender];
        // block.timestamp = timestamp of the current block in seconds since the epoch
        uint256 timestamp = block.timestamp;
        // See if the staker already has a staked index or if its the first time
        if(index == 0){
            // This stakeholder stakes for the first time
            // We need to add him to the stakeHolders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the stakeholders array
            index = _addStakeholder(msg.sender);
        }

        // Use the index to push a new Stake
        // push a newly created Stake with the current block timestamp.
        stakeholders[index].address_stakes.push(Stake(msg.sender, _amount, timestamp,0));
        // Emit an event that the stake has occured
        emit Staked(msg.sender, _amount, index,timestamp);
    }

    /**
      * @notice
      * calculateStakeReward is used to calculate how much a user should be rewarded for their stakes
      * and the duration the stake has been active
     */
     // can alter amount using sqrt 
      function calculateStakeReward(Stake memory _current_stake) internal view virtual returns(uint256){
          // First calculate how long the stake has been active
          // Use current seconds since epoch - the seconds since epoch the stake was made
          // The output will be duration in SECONDS ,
          // We will reward the user 0.1% per Hour So thats 0.1% per 3600 seconds
          // the alghoritm is  seconds = block.timestamp - stake seconds (block.timestap - _stake.since)
          // hours = Seconds / 3600 (seconds /3600) 3600 is an variable in Solidity names hours
          // we then multiply each token by the hours staked , then divide by the rewardPerHour rate
          return (((block.timestamp - _current_stake.since) / rewardsEvery ) * _current_stake.amount) / rewardPerHour;
         }


          function getMyStakeRewardEstimate(uint256 index) public view virtual returns(uint256){
         // Grab user_index which is the index to use to grab the Stake[]
        uint256 user_index = stakes[msg.sender];
        uint256 cStake = stakeholders[user_index].address_stakes[index].amount;
        uint256 cSince = stakeholders[user_index].address_stakes[index].since;
          return (((block.timestamp - cSince) / rewardsEvery ) * cStake) / rewardPerHour;

     }



    /**
     * @notice
     * withdrawStake takes in an amount and a index of the stake and will remove tokens from that stake
     * Notice index of the stake is the users stake counter, starting at 0 for the first stake
     * Will return the amount to MINT onto the acount
     * Will also calculateStakeReward and reset timer
    */
     function _withdrawStake(uint256 amount, uint256 index) internal returns(uint256){
         // Grab user_index which is the index to use to grab the Stake[]
        uint256 user_index = stakes[msg.sender];
        Stake memory current_stake = stakeholders[user_index].address_stakes[index];
        require(current_stake.amount >= amount, "Staking: Cannot withdraw more than you have staked");

         // Calculate available Reward first before we start modifying data
         uint256 reward = calculateStakeReward(current_stake);
         // Remove by subtracting the money unstaked 
         current_stake.amount = current_stake.amount - amount;
         // If stake is empty, 0, then remove it from the array of stakes
         if(current_stake.amount == 0){
             delete stakeholders[user_index].address_stakes[index];
         }else {
             // If not empty then replace the value of it
             stakeholders[user_index].address_stakes[index].amount = current_stake.amount;
             // Reset timer of stake
            stakeholders[user_index].address_stakes[index].since = block.timestamp;    
         }

         return amount+reward;
     }

     /**
     * @notice
     * hasStake is used to check if a account has stakes and the total amount along with all the seperate stakes
     */
    function listUserStakes(address _staker) public view returns(StakingSummary memory){
        // totalStakeAmount is used to count total staked amount of the address
        uint256 totalStakeAmount; 
        // Keep a summary in memory since we need to calculate this
        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[_staker]].address_stakes);
        // Itterate all stakes and grab amount of stakes
        for (uint256 s = 0; s < summary.stakes.length; s += 1){
           uint256 availableReward = calculateStakeReward(summary.stakes[s]);
           summary.stakes[s].claimable = availableReward;
           totalStakeAmount = totalStakeAmount+summary.stakes[s].amount;
       }
       // Assign calculate amount to summary
       summary.total_amount = totalStakeAmount;
        return summary;
    }



    function getMyTotalStake () public view returns (uint myTotalStake) {
        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[stakeholders[stakes[msg.sender]].user]].address_stakes);
            for (uint256 s = 0; s < summary.stakes.length; s += 1){
                myTotalStake = myTotalStake + summary.stakes[s].amount ;
    }
        return myTotalStake;
    }



    /**
    * @notice Loops through stakeholders array to retrie TotalStaked
     */
    function getGlobalTotalStaked () public view returns (uint globalStakeAmount) {
//        uint256 globalStakeAmount;

//        StakingGlobal memory globalSummary = StakingGlobal(0, stakeholders[stakes[_staker]].address_stakes);        
        // WARN: This unbounded for loop is an anti-pattern
        for (uint256 i = 0; i < stakeholders.length ; i += 1){
        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[stakeholders[i].user]].address_stakes);
            for (uint256 s = 0; s < summary.stakes.length; s += 1){
//           uint256 availableReward = calculateStakeReward(summary.stakes[s]);
//           summary.stakes[s].claimable = availableReward;
           globalStakeAmount = globalStakeAmount+summary.stakes[s].amount;
       }}
      return globalStakeAmount;
    }

      function getGlobalStakeRewardEstimate() public view virtual returns(uint256){
        uint256 cStake;
        uint256 cSince;
        uint256 getRewardAmount;
        uint256 allRewards;
        for (uint256 i = 0; i < stakeholders.length ; i += 1){
          StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[stakeholders[i].user]].address_stakes);
          for (uint256 s = 0; s < summary.stakes.length; s += 1){
//           uint256 availableReward = calculateStakeReward(summary.stakes[s]);
//           summary.stakes[s].claimable = availableReward;
            cStake = stakeholders[i].address_stakes[s].amount;
            cSince = stakeholders[i].address_stakes[s].since;
            getRewardAmount = (((block.timestamp - cSince) / rewardsEvery ) * cStake) / rewardPerHour;
            allRewards += getRewardAmount ;
        }}
        return allRewards;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
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