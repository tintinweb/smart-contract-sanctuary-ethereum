// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "ERC721EnumerableUpgradeable.sol";
import "OwnableUpgradeable.sol";
import "Initializable.sol";
import "StringsUpgradeable.sol";
import "CountersUpgradeable.sol";
import "SafeERC20Upgradeable.sol";
import "ReentrancyGuardUpgradeable.sol";
import "IERC20Upgradeable.sol";
import "IERC2981Upgradeable.sol";


error Minting_ExceedsTotalBulls();
error Minting_ExceedsMintingLimitPerAddress();
error Minting_PublicSaleNotLive();
error Minting_IsZeroOrBiggerThanTen();
error Contract_CurrentlyPaused_CheckSocials();
error Pause_MustSetAllVariablesFirst();
error Pause_BaseURIMustBeSetFirst();
error Pause_MustBePaused();
error Rewarding_NotReady();
error Rewarding_SkippingOrDoubleRewarding();
error Rewarding_HasAlreadyHappenedThisMonth();
error Maintenance_UpdatingNotReady();
error Maintenance_NoMaintenanceFeesRequired();
error Liquidation_NothingToDo();
error BadLogicInputParameter();
error Partner_NotAllowed();
error Address_CantBeAddressZero();
error Blacklisted();
error Rewarding_NoBalanceToWithdraw();




/// @custom:security-contact [email protected]
contract TheRanchBTCBullsCommunity is 
    Initializable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC2981Upgradeable
    {

    using StringsUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenSupply;   

    // token information 
    address public wbtcTokenContract; 
    address public usdcTokenContract; 
    uint public wbtcTokenDecimals;     
    uint public usdcTokenDecimals;     

    // coreTeam Addresses
    address public coreTeam_1;
    address public coreTeam_2;

    //gnosis-safe address 
    address public hostingSafe;
    address public btcMinersSafe;

    // Minting 
    uint public constant maxSupply = 10000;
    uint256 public mintingCost;  // USDC.e
    uint256 public nftPerAddressLimit;
    mapping(address => uint256) public addressMintCount; // how many times has this address minted an NFT from this contract. 

    bool public publicSaleLive;
    bool public paused;

    mapping(address => bool) public isBlacklisted;

    mapping(address => uint) public userMintCount;  // How many bulls did an address mint
    mapping(address => bool) public userInDailyRaffle;  // Is the person already in the daily raffle?

    mapping(address => address) public myPartner;   // partner mapping; msg.sender  ==> who referred them
    mapping(address => uint256) public myParnterNetworkTeamCount;   // Keeps track of how many people are currently using an address as their partner 

    // Contract Balances
    uint256 public btcMinersSafeBalance;
    uint256 public hostingSafeBalance;     // reserve kept for hosting fees and will be used if people don't pay their maintenance fees on time
    uint256 public USDCRewardsBalance;    // amount held within contract for referrals and raffle balance 
    uint256 public dailyRaffleBalance;    // Strictly the Raffle amount of USDC to be award on the raffle 



    // NFT INFO 
    string private baseURI;
    string private baseExtension;
 
 
    // Raffle Variables
    address[] private dailyRafflePlayers;
 
    // Maintenance Fees Variables and Mappings
    // The amount calculated for hosting invoice / NFT count 
    uint256 public calculatedMonthlyMaintenanceFee;   


    /**
     * @dev For addresses that are more than 3 months behind on the maintenance fees, each 
     * each address added here will get liquidated
    */
    address[] internal upForLiquidation; 

    // Stockyard allows the rewardBulls function to be more modular. 
    struct StockyardInfo {
        uint startingIndex;
        uint endingIndex;
    }

    mapping (uint => StockyardInfo) public stockyardInfo;

 

    // BTC Bull Owners information 
    struct BTCBullOwner {
        uint256 USDC_Balance;
        uint256 WBTC_Balance;
        uint256 maintenanceFeeBalance;    
        uint maintenanceFeesStanding;     // how many months are they behind on the maintenance fees? 0 means all paid up, 4 gets liquidated.
        uint lastRewardDate;        // this tracks when the last time I rewarded them. Aug 2022 would be 0822, Mar 2023 would be 0323. 
    }

    mapping(address => BTCBullOwner) public btcBullOwners;


    // Monthly WBTC rewarding variables 
    uint public currentRewardingDate;        // This date is set when we send WBTC into the contract to reward the BTC Bulls to confirm who has been paid out. 
    uint public stockyardsThatHaveBeenRewardedCount;  // security check to make sure we don't rewarding the same stockyard twice or skip a stockyard
    uint256 public payPerNftForTheMonth;      // Total Monday WBTC deposit / totalSupply()
    uint256 public lastDeposit;         // variable that tracks last deposit. If not reset after rewarding, it keeps serves as a check to deposit money and start rewarding
    address[] public rewardedAddresses;  // array for address if we have EVER rewarded them. 
    bool public readyToReward;   // bool to confirm we have met all the requirements and are good to go to call the rewardBulls function 


    /**
     * @dev The isEcosystemRole is for other contracts that are allowed to update the USDC for BTC BULL Owners on this contract.
     * @dev The isDefenderRole our openzeppelin Defender account working with autotasks and sentinals.
     * @dev The isChainLinkVRFRole our chainlink VRF contract that does the minting raffle for this contract.
    */
    mapping(address => bool) public isEcosystemRole;
    mapping(address => bool) public isDefenderRole;
    mapping(address => bool) public isChainLinkVRFRole;


    modifier ADMIN_OR_DEFENDER {
        require(msg.sender == owner() || isDefenderRole[msg.sender] == true, "Caller is not an OWNER OR DEFENDER");
        _;
    }

   
    event PauseChanged(address _account, bool _changedTo);

    event NewBullsEnteringRanch(
        address indexed NewbullOwner,
        bool indexed RaffleEntered,
        uint256  BullsPurchased,
        uint256 _NFTCount
    );

    event mintingRaffleEvent(
        uint256 indexed winningIndex,
        address indexed raffleWinner,
        uint256  raffleWinAmount

    );
    
    event withdrawUSDCBalanceForAddressEvent(
        address indexed nftOwner,
        uint256 indexed totalAmountTransferred
    );

    event withdrawWbtcBalanceEvent(
        address indexed nftOwner,
        uint256 indexed totalAmountTransferred  
    );

    event liquidationEvent (
        address indexed nftOwner,
        uint256 indexed totalAmountliquidated
    );

    event rewardEvent(
            uint256 payPerNftForTheMonth,
            uint256 maintenanceFeesForEachNFT,
            uint indexed startingIndex,
            uint indexed endingIndex
    );

    event resetRewardEvent(
        address caller,
        string sectionMessage
    );

     event setPayPerNFTEvent(
        uint256 totalDeposit,
        uint256 calculatedPayPerNFT,
        uint rewardDate
    );


    event payMaintanenceFeesEvent(
            address indexed nftOwner,
            uint256 indexed totalAmountPayedWithCurrentRewards,
            uint256 indexed totalAmountPayedWithoutCurrentRewards
    );


    function initialize() public initializer {
        __ERC721_init("TheRanch_BTC_Bulls_Community", "TRBC");
        __ERC721Enumerable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        nftPerAddressLimit = 50;
        wbtcTokenDecimals = 8;
        usdcTokenDecimals = 6;
        mintingCost = 350;
        publicSaleLive = false;
        paused = true;
        baseExtension = ".json";    
    }


    function approveToken(uint256 _tokenamount)public returns (bool) {
        IERC20Upgradeable usdcToken = IERC20Upgradeable(usdcTokenContract);
        usdcToken.approve(address(this), _tokenamount); 
        return true;
    }


   // MINTING
    /**
     * @dev This is the function does the following things:
     * 0. Only works if not paused
     * 1. Allows users to mint new NFTs 1 - 10 per tx 
     * 2. Updates Mapping for their total count of mints
     * 3. Uses a referral/partners system to see who gets the referral bonus.
     * 4. Enters user into the daily raffle if they chose to do so. 
     * 5. If msg.sender elects to enter raffle, 95% goes to btcMinersFund, if they do not, 98% does. 
    */
    function mint(uint256 _tokenQuantity, bool _enterRaffle) public payable {
        if (paused) { revert Contract_CurrentlyPaused_CheckSocials();}
        if (!publicSaleLive) { revert Minting_PublicSaleNotLive();}
        if (_tokenQuantity ==  0 || _tokenQuantity > 10) { revert Minting_IsZeroOrBiggerThanTen();}
        if (_tokenSupply.current() + _tokenQuantity > maxSupply) {revert Minting_ExceedsTotalBulls();}
        if (addressMintCount[msg.sender] + _tokenQuantity > nftPerAddressLimit) { revert Minting_ExceedsMintingLimitPerAddress();}


        IERC20Upgradeable usdcToken = IERC20Upgradeable(usdcTokenContract);
        uint256 minting_cost_per_bull = mintingCost * 10 ** usdcTokenDecimals;
        uint256 totalTransactionCost = minting_cost_per_bull * _tokenQuantity;
        usdcToken.safeTransferFrom(msg.sender, address(this), (totalTransactionCost));

        for(uint256 i = 0; i < _tokenQuantity; i++) {
            _tokenSupply.increment();
            addressMintCount[msg.sender] += 1;
            _safeMint(msg.sender, _tokenSupply.current());
        }

        //update the mint count for msg.sender
        userMintCount[msg.sender] += _tokenQuantity;

        // Voluntary Raffle entry allow users to enter raffle is they choose too with _enterRaffle == True
        uint256 raffleFundAmt; 

        if (_enterRaffle == true){
            raffleFundAmt = totalTransactionCost * 3 / 100;
            if (getUserAlreadyInDailyRaffleStatus(msg.sender) == false){
                dailyRafflePlayers.push(payable(msg.sender));
                userInDailyRaffle[msg.sender] = true; 
            }
            dailyRaffleBalance += raffleFundAmt;
        } else {
            raffleFundAmt = 0;
        }

        // update contract balances
        uint256 referralFundAmt = totalTransactionCost * 2 / 100;
        uint256 hostingSafeAmt = totalTransactionCost * 5 / 100;
        uint256 btcMinersSafeAmt = totalTransactionCost - (referralFundAmt + raffleFundAmt)  - hostingSafeAmt; 
        USDCRewardsBalance += (referralFundAmt + raffleFundAmt);
        btcMinersSafeBalance += btcMinersSafeAmt;
        hostingSafeBalance += hostingSafeAmt; 
        
        // update USDC Reward Balances for referrals
        address referrer = myPartner[msg.sender];
        if(referrer != address(0) && userMintCount[referrer] > 0){
            //updateUsdcBonus(referrer, referralFundAmt);
            btcBullOwners[referrer].USDC_Balance += referralFundAmt;
        }
        else
        {
            uint256 splitReferralAmt = referralFundAmt * 50 / 100;
            // updateUsdcBonus(coreTeam_1, splitReferralAmt);
            // updateUsdcBonus(coreTeam_2, splitReferralAmt);
            btcBullOwners[coreTeam_1].USDC_Balance += splitReferralAmt;
            btcBullOwners[coreTeam_2].USDC_Balance += splitReferralAmt;
        }
        
        emit NewBullsEnteringRanch(msg.sender,_enterRaffle, _tokenQuantity, _tokenSupply.current());
    }







    /** 
    * @dev this function is called by the multisig after we do the monthy funding of the NFTs by depostiing money into the contract
    *  and setting the Maintenance Fee for the invoice from the hosting facility. The reward function can't be called until this evaulates as true. 
    */
    function setReadyToReward() external ADMIN_OR_DEFENDER {
        if (calculatedMonthlyMaintenanceFee == 0) { revert Rewarding_NotReady();}
        if (payPerNftForTheMonth == 0) { revert Rewarding_NotReady();}

        readyToReward = true;
    }



    /** 
    * @dev This resets the monthly variables to make sure we the order of calls works correctly the next time we do it. 
    */
    function resetReadyToRewardChecks() external ADMIN_OR_DEFENDER {
        readyToReward = false;
        payPerNftForTheMonth = 0;
        calculatedMonthlyMaintenanceFee = 0;
        stockyardsThatHaveBeenRewardedCount = 0;
        lastDeposit = 0;
        emit resetRewardEvent(msg.sender, "Reset Rewarding Variables");
    }




    // This needs to be done in a single transaction. The problem is that if we try this in multiple transactions, this
    // would end up re-updating the payPerNftForTheMonth and the total payout to each NFT owner would be messed up. 
    // The only way to deposit more money into this function and update the payPerNftForTheMonth variable would be to run
    // through the rewarding, which then sets the lastDeposit back to zero and doing another round of rewarding for the month.

    function setPayPerNftForTheMonthAndCurrentRewardingDate(uint256 _totalAmountToDeposit, uint _dateOfRewarding) public onlyOwner {
        if (lastDeposit != 0) { revert Rewarding_HasAlreadyHappenedThisMonth();}
        //if (_dateOfRewarding == currentRewardingDate) { revert Rewarding_HasAlreadyHappenedThisMonth();}


        IERC20Upgradeable tokenContract = IERC20Upgradeable(wbtcTokenContract);
        tokenContract.safeTransferFrom(msg.sender, address(this), _totalAmountToDeposit);
        
        currentRewardingDate = _dateOfRewarding;
        lastDeposit = _totalAmountToDeposit;

        
        // in this function, lets pay out the core team first and then the 90% left gets divided up. 
        uint256 coreTeam_1_amt = _totalAmountToDeposit * 8 / 100;
        uint256 coreTeam_2_amt = _totalAmountToDeposit * 2 / 100;

        uint256 _disperableAmount = (_totalAmountToDeposit * 90 / 100); 
        uint256 payout_per_nft = _disperableAmount / _tokenSupply.current();
        payPerNftForTheMonth = payout_per_nft;

        btcBullOwners[coreTeam_1].WBTC_Balance += coreTeam_1_amt;
        btcBullOwners[coreTeam_2].WBTC_Balance += coreTeam_2_amt;

        // emit event 
        emit setPayPerNFTEvent(_totalAmountToDeposit, payout_per_nft, _dateOfRewarding);
        

    }   


    /** 
    * @dev  check all address who have been rewarded. If there lastRewardYearMonth isn't the currentRewardingDate, then lets investigate. If they have a WBTC balance, then we need
    * to update there maintenanceFeesStanding by 1 and add to liquidation list if they reach 4 in that category 
    */
    function updateMaintenanceStanding() external ADMIN_OR_DEFENDER {
        for( uint i; i < rewardedAddresses.length; i++) {
            address _wallet = rewardedAddresses[i];
            if (btcBullOwners[_wallet].WBTC_Balance > 0){
                if (btcBullOwners[_wallet].lastRewardDate != currentRewardingDate) {

                    // take action and add one to maintenanceFeesStanding
                    btcBullOwners[_wallet].maintenanceFeesStanding += 1;

                    if (btcBullOwners[_wallet].maintenanceFeesStanding == 4){
                        upForLiquidation.push(_wallet);
                    }
                }
            }
        }
    }


     /**
    * @dev The Reward function is a modular setup so we can go through all the NFTs in multiple passes to circumvent gas problems. 
    * 1. Only works if the readyToReward varible is true, that means all the admin tasks before rewarding have taken place.  
    * 2. updates the stockyardsThatHaveBeenRewardedCount variable to make sure we can't call the reward on the same stockyard multiple times. 
    * 3. checks the currentRewardDate for the owner's account, only lets them pass throught he function is its differnt than the current date. this allows for a single pass for that wallet and skips if they own more than one.
    * 4. Checks to see if we have every rewarded them by detecting is there lastRewardDate is not initialized yet. 
    * 5. updates the lastRewardDate for the account
    * 6. rewards user for all the NFTs the currently own on the contract. 
    * 7. updates WBTC balance for the user and a percentage is sent to their parnters account if thats set, to the core team if partner is not set. 
    * 8. updates the maintenance Fee balance that the user owes for the months (hosting fees at the mining facility)
    * 9. updates the maintenanceFeesStanding for the user, if this number is 4 then they are up for liquidation and pushed to that array to be in queue for liquidating them
    * 10. emits event showing how much we paid for each NFT, how much the maintenance fee for each NFT was, the starting index and ending index we rewarded during the function. 
    */

    function rewardBulls(uint _stockyardNumber) public payable ADMIN_OR_DEFENDER {
   
        if (readyToReward == false) { revert Rewarding_NotReady();}
        if (!paused) { revert Pause_MustBePaused();}
        if (_stockyardNumber != stockyardsThatHaveBeenRewardedCount + 1) { revert Rewarding_SkippingOrDoubleRewarding();}

        stockyardsThatHaveBeenRewardedCount++ ;

        uint startingIndex = stockyardInfo[_stockyardNumber].startingIndex;
        uint endingIndex = stockyardInfo[_stockyardNumber].endingIndex;

        for( uint i = startingIndex; i <= endingIndex; i++) {
            address bullOwnerAddress = ownerOf(i);
            
            if (bullOwnerAddress != address(0)){

                // have we checked them this month, if lastRewardDate == currentRewardingDate then skip them  
                if (btcBullOwners[bullOwnerAddress].lastRewardDate != currentRewardingDate) {


                    // Have we ever rewarded them before, if not, add them into the rewarded address array. 
                    if (btcBullOwners[bullOwnerAddress].lastRewardDate == 0) {
                        rewardedAddresses.push(bullOwnerAddress);
                    }

                    BTCBullOwner storage _bullOwner = btcBullOwners[bullOwnerAddress];

                    // update lastRewardDate for this address 
                    _bullOwner.lastRewardDate = currentRewardingDate;
        

                    // get the amount of NFTs this address owns
                    uint _nftCount = walletOfOwner(bullOwnerAddress).length;

                    // get the total payout amound
                    uint256 totalPayoutForTheBullOwner = _nftCount * payPerNftForTheMonth;
                    
                    // get the referr and the referral amount 
                    address referrer = myPartner[bullOwnerAddress];
                    uint256 referralAmt = totalPayoutForTheBullOwner * 1 / 100;

                    // update the wbtc balances accordingly with their partner 
                    if(referrer != address(0) && userMintCount[referrer] > 0){
                        btcBullOwners[referrer].WBTC_Balance += referralAmt;
                        _bullOwner.WBTC_Balance += (totalPayoutForTheBullOwner - referralAmt);
      
    
                    } else {
                        btcBullOwners[coreTeam_1].WBTC_Balance += referralAmt;
                        btcBullOwners[coreTeam_2].WBTC_Balance += referralAmt;
                        _bullOwner.WBTC_Balance += (totalPayoutForTheBullOwner - (referralAmt * 2));
         
                    }

                    //  update the maintenance Fees due from the _bullOwner
                    _bullOwner.maintenanceFeeBalance += (_nftCount * calculatedMonthlyMaintenanceFee);
         

                    // update the maintenanceFeesStanding for the _bullOwner
                    _bullOwner.maintenanceFeesStanding += 1;


                    // Check if _bullOwner is more than 3 months behind on the account 
                    if (_bullOwner.maintenanceFeesStanding == 4){
                        upForLiquidation.push(bullOwnerAddress);
                    }
                }
            }
        }

        emit rewardEvent(payPerNftForTheMonth, calculatedMonthlyMaintenanceFee, startingIndex, endingIndex);
    }



    /**
    * @dev When any other contract in our ecosystem checks the owner of the BTC Bulls, it will update the USDC amount for the 
    * BTC Bulls owner on this contract. It incentives ownership of both NFTS this way: 
    * In this example, lets assume we have a HayBale NFT on another smart contract, 
    * - if the HayBale owner also owns a Bull NFT on this contract, they'll get amtToDistribute  == _amountToAdd, then we look for the partner of that address and do a 95/5 approach,
    *   95% go to the owner and 5% goes to the partner.
    * -if the Haybale owner does not own a bull, they'll get 70% of the _amountToAdd while 5% goes to core1 and core2 and 20% to the hostingSafe Balance
  
    */
    function updateUsdcBonusFromAnotherContract(address[] memory _ownersOfTheNFTs, uint256 _amountToAdd) external {
        require(isEcosystemRole[msg.sender] == true, "must be approved to interact");

        for( uint i; i < _ownersOfTheNFTs.length; i++) {
            address _ownerOfNFT = _ownersOfTheNFTs[i];

            // this address does own a BTC Bull
            if (balanceOf(_ownerOfNFT) > 0){
                //btcBullOwners[_ownerOfNFT].USDC_Balance += _amountToAdd;

                // get the referr of this particular BTC Bull owner  
                address referrer = myPartner[_ownerOfNFT];
                uint256 referralAmt = _amountToAdd * 5 / 100;

                // update the usdc  balances accordingly with their partner 
                if(referrer != address(0) && userMintCount[referrer] > 0){
                    btcBullOwners[referrer].USDC_Balance += referralAmt;
                    btcBullOwners[_ownerOfNFT].USDC_Balance += (_amountToAdd - referralAmt);
    
                } else {
                    btcBullOwners[coreTeam_1].USDC_Balance += referralAmt;
                    btcBullOwners[coreTeam_2].USDC_Balance += referralAmt;
                    btcBullOwners[_ownerOfNFT].USDC_Balance += (_amountToAdd - (referralAmt * 2));
                }

            // this address does NOT own a BTC Bull
             } else {
                uint256 deductionAmt = _amountToAdd * 5 / 100;

                btcBullOwners[coreTeam_1].USDC_Balance += deductionAmt;
                btcBullOwners[coreTeam_2].USDC_Balance += deductionAmt;
                hostingSafeBalance += (deductionAmt * 4);
                btcBullOwners[_ownerOfNFT].USDC_Balance += (_amountToAdd - (deductionAmt * 6));
            }
        }
    }



    function getLiquidatedArrayLength() public view ADMIN_OR_DEFENDER returns (uint) {
        return upForLiquidation.length;
    }

    /**
     * @dev If the user has been added to the liquidityArray, that means they are 4 months behind on paying their maintenance fees
     * Liquidating them means transfering the WBTC out of their account and sending it the Hosting Safe Multisig wallet. 
    **/
    function liquidateOutstandingAccounts() external ADMIN_OR_DEFENDER {
        if (!paused) { revert Maintenance_UpdatingNotReady();}
        if (upForLiquidation.length < 1) { revert Liquidation_NothingToDo();}

        uint256 totalAmountLiquidated; 

        for( uint i; i < upForLiquidation.length; i++) {
            address _culprit = upForLiquidation[i];
            uint256 _amount = btcBullOwners[_culprit].WBTC_Balance;
            btcBullOwners[_culprit].WBTC_Balance = 0;
            totalAmountLiquidated += _amount; 

            // reset fees and months behind. 
            btcBullOwners[_culprit].maintenanceFeeBalance = 0;
            btcBullOwners[_culprit].maintenanceFeesStanding = 0;
            
            // emit event
            emit liquidationEvent(_culprit, _amount) ;
            
        }

        upForLiquidation = new address[](0);

        IERC20Upgradeable tokenContract = IERC20Upgradeable(wbtcTokenContract);
        tokenContract.approve(address(this), totalAmountLiquidated);
        tokenContract.safeTransferFrom(address(this), hostingSafe, totalAmountLiquidated);
    }


    /**
     * @dev If the user has USDC rewards to within their account
     * the maintanence fee balance will be deducted from that. 
     * If it doesn't cover the entire maintenance fee cost, 
     * the rest of the amount will be asked to beapproved and sent to the contract. 
    **/
    function payMaintanenceFees() external nonReentrant {

        uint256 _feesDue = btcBullOwners[msg.sender].maintenanceFeeBalance;
        uint256 _balance = btcBullOwners[msg.sender].USDC_Balance;
        
        if (_feesDue == 0) { revert Maintenance_NoMaintenanceFeesRequired();}

        if (_balance >= _feesDue){

            btcBullOwners[msg.sender].USDC_Balance -= _feesDue;
            hostingSafeBalance += _feesDue; 

            emit payMaintanenceFeesEvent(msg.sender, _feesDue, 0);
        } else {

            uint256 amt_needed =  _feesDue - _balance;
            if(_balance == 0){
                IERC20Upgradeable usdcToken = IERC20Upgradeable(usdcTokenContract);
                usdcToken.safeTransferFrom(msg.sender, address(this), (_feesDue));
                hostingSafeBalance += _feesDue; 
            } else {
                
                btcBullOwners[msg.sender].USDC_Balance -= _balance; 

                IERC20Upgradeable usdcToken = IERC20Upgradeable(usdcTokenContract);
                usdcToken.safeTransferFrom(msg.sender, address(this), (amt_needed));

                hostingSafeBalance += (amt_needed + _balance); 
            }

            emit payMaintanenceFeesEvent(msg.sender, _balance, amt_needed);
        }

        // reset fees and months behind. 
        btcBullOwners[msg.sender].maintenanceFeeBalance = 0;
        btcBullOwners[msg.sender].maintenanceFeesStanding = 0;

    }




    /**
     * @dev This is the function is called from another contract in our ecoystem using Chainlink VRF V2
     * This contract must have the ChainlinkVRF role or it will revert. It calls and fullfills the request 
     * on the other contract then sends that number to this contract to award the winner. 
     * Did this approach as a workaround to use upgradeble contracts from open-zeppelin as the chainlink contracts were not compatiable. 
     */

    function mintingRaffle(uint _winningIndex) external {

        require(isChainLinkVRFRole[msg.sender] == true, "must be approved to interact");

        if (paused == false) { revert Pause_MustBePaused();}
        
        address dailyRaffleWinner = dailyRafflePlayers[_winningIndex];
        uint256 raffleWinningAmount = dailyRaffleBalance; 
        
        // update the daily raffle winnners USDC balance
        btcBullOwners[dailyRaffleWinner].USDC_Balance += dailyRaffleBalance;

        resetUserInDailyRaffle(); // must do before resetting dailyRafflePlayers
        dailyRaffleBalance = 0;  // reset dailyRaffleBalance back to zero after drawing
        dailyRafflePlayers = new address[](0);

        emit mintingRaffleEvent(_winningIndex, dailyRaffleWinner, raffleWinningAmount);

    }

   

    /**
     * @dev Once the raffle winner is picked, we loop through the dailyRafflePlayers
     * and set their booling value back to false so they can enter another raffle 
     * if they choose to mint more NFTs later on a different day.
     */
    function resetUserInDailyRaffle() internal {
        for (uint i=0; i< dailyRafflePlayers.length ; i++){
            userInDailyRaffle[dailyRafflePlayers[i]] = false;
        }
    }


    function setPartnerAddress(address _newPartner)  public {
        if (address(_newPartner) == address(0)) { revert Partner_NotAllowed();}
        if (address(_newPartner) == msg.sender) { revert Partner_NotAllowed();}

        address currentPartner = myPartner[msg.sender];
        // myPartner[msg.sender] = _newPartner;

        if (currentPartner == address(0)){
            myPartner[msg.sender] = _newPartner;
            myParnterNetworkTeamCount[_newPartner] += 1;
        } else {
            myPartner[msg.sender] = _newPartner;
            myParnterNetworkTeamCount[currentPartner] -= 1;
            myParnterNetworkTeamCount[_newPartner] += 1;
        }
    }

    // Contract Funding / Withdrawing / Transferring
    function fund() public payable {}

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
        IERC20Upgradeable tokenContract = IERC20Upgradeable(_tokenContract);
        tokenContract.safeTransfer(msg.sender, _amount);
    }

    function withdrawBtcMinersSafeBalance() external ADMIN_OR_DEFENDER {
        IERC20Upgradeable tokenContract = IERC20Upgradeable(usdcTokenContract);
        uint256 amtToTransfer = btcMinersSafeBalance;
        tokenContract.approve(address(this), amtToTransfer);
        tokenContract.safeTransferFrom(address(this), btcMinersSafe, amtToTransfer);
        btcMinersSafeBalance -= amtToTransfer;

    
    }

    function withdrawHostingSafeBalance() external ADMIN_OR_DEFENDER {
        IERC20Upgradeable tokenContract = IERC20Upgradeable(usdcTokenContract);
        uint256 amtToTransfer = hostingSafeBalance;
        tokenContract.approve(address(this), amtToTransfer);
        tokenContract.safeTransferFrom(address(this), hostingSafe, amtToTransfer);
        hostingSafeBalance -= amtToTransfer;
    }


    function withdrawWbtcBalance() external nonReentrant {
        if (paused) { revert Contract_CurrentlyPaused_CheckSocials();}
        if (isBlacklisted[msg.sender]) { revert Blacklisted();}

        require(btcBullOwners[msg.sender].maintenanceFeeBalance == 0, "You must pay maintenance fee balance before WBTC withdrawal is allowed");

        // Get the total Balance to award the owner of the NFT(s)
        uint256 myBalance = btcBullOwners[msg.sender].WBTC_Balance; 
        if (myBalance == 0) { revert Rewarding_NoBalanceToWithdraw();}

        // Transfer Balance 
        IERC20Upgradeable(wbtcTokenContract).safeTransfer(msg.sender, myBalance );

        // update wbtc balance for nft owner
        btcBullOwners[msg.sender].WBTC_Balance = 0;
        
        emit withdrawWbtcBalanceEvent(msg.sender, myBalance);
    }

    function withdrawUsdcBalance() external nonReentrant {
        if (paused) { revert Contract_CurrentlyPaused_CheckSocials();}
        if (isBlacklisted[msg.sender]) { revert Blacklisted();}
        
        // Get USDC rewards balance for msg.sender
        uint256 myBalance = btcBullOwners[msg.sender].USDC_Balance;
        if (myBalance == 0) { revert Rewarding_NoBalanceToWithdraw();}
 
        // Transfer Balance 
        IERC20Upgradeable(usdcTokenContract).safeTransfer(msg.sender, (myBalance));
        // update mapping on contract 

        btcBullOwners[msg.sender].USDC_Balance = 0  ;
        
        // update USDC Rewards Balance Total
        USDCRewardsBalance -= myBalance;
        
        // emit event
        emit withdrawUSDCBalanceForAddressEvent(msg.sender, myBalance);
        
    }

    /** Getter Functions */

    /**
     * @dev returns how many people have ever been rewarded from owning a BTC Bull
     */
    function getRewardAddressesLength() public view returns (uint){
        return rewardedAddresses.length;
    }

    function getMaintenanceFeeBalanceForAddress() public view returns (uint256){
        return btcBullOwners[msg.sender].maintenanceFeeBalance;
    }

    function getMaintenanceFeeStandingForAddress() public view returns (uint){
        return btcBullOwners[msg.sender].maintenanceFeesStanding;
    }


    function getWbtcBalanceForAddress() public view returns (uint256){
        return btcBullOwners[msg.sender].WBTC_Balance;
    }


    function getUsdcBalanceForAddress() public view returns (uint256) {
        return btcBullOwners[msg.sender].USDC_Balance;
    }

    /**
     * @dev returns how many people are using them as someone as their partner
     */
    function getPartnerNetworkTeamCount() public view returns (uint) {
        return myParnterNetworkTeamCount[msg.sender];
    }

    /**
     * @dev checks if an address is using them as their partner.
     */
    function getAreTheyOnMyPartnerNetworkTeam(address _adressToCheck) public view returns (bool) {
        if (myPartner[_adressToCheck] == msg.sender){
            return true;
        }
        return false;
    }

    function getRafflePlayer(uint256 index) public view onlyOwner returns (address) {
        return dailyRafflePlayers[index];
    }

    /**
    * @dev checks if an address has minted before on the contract.
    */
    function getHaveTheyMintedBefore(address _adressToCheck) public view returns (bool) {
        if (userMintCount[_adressToCheck] > 0){
            return true;
        }
        return false;
    }

    function getMintCountForAddress(address _address) public view returns (uint) {
        return userMintCount[_address];
    }

    function getUserAlreadyInDailyRaffleStatus(address _address) public view returns (bool) {
        return userInDailyRaffle[_address];
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }


    function getNumberOfRafflePlayers() public view returns (uint256) {
        return dailyRafflePlayers.length;
    }   

    function getBlacklistedStatus(address _address) public view returns (bool) {
        return isBlacklisted[_address];
    }

   // METADATA
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }

    // ERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC721EnumerableUpgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    // IERC2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address, uint256 royaltyAmount) {
        _tokenId; // silence solc warning
        royaltyAmount = _salePrice * 5 / 100;  // 5%
        return (coreTeam_1, royaltyAmount);
    }


    // Contract Control _ ADMIN ONLY
    function setBaseURI(string memory _newBaseURI) public onlyOwner{
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function togglePublicSaleStatus() external onlyOwner{
        publicSaleLive = !publicSaleLive;
    }

    function setPauseStatus(bool _paused) external ADMIN_OR_DEFENDER{
        if(address(coreTeam_1) == address(0)) { revert Pause_MustSetAllVariablesFirst();}
        if(address(coreTeam_2) == address(0)) { revert Pause_MustSetAllVariablesFirst();}
        if(address(usdcTokenContract) == address(0)) { revert Pause_MustSetAllVariablesFirst();}
        if(address(wbtcTokenContract) == address(0)) { revert Pause_MustSetAllVariablesFirst();}
        if(address(hostingSafe) == address(0)) { revert Pause_MustSetAllVariablesFirst();}
        if(address(btcMinersSafe) == address(0)) { revert Pause_MustSetAllVariablesFirst();}
        string memory currentBaseURI = _baseURI();
        if(bytes(currentBaseURI).length == 0) { revert Pause_BaseURIMustBeSetFirst();}

        paused = _paused;

        emit PauseChanged(msg.sender, _paused);
    }

    function setCoreTeamAddresses(address _coreTeam_1, address _coreTeam_2) external onlyOwner {
        if (address(_coreTeam_1 ) == address(0) || address(_coreTeam_2 ) == address(0)) { revert Address_CantBeAddressZero();}
        coreTeam_1 = _coreTeam_1;
        coreTeam_2 = _coreTeam_2;
    }

    function setSafeAddresses(address _hostingSafe, address _btcMinersSafe) external onlyOwner {
        if (address(_hostingSafe ) == address(0) || address(_btcMinersSafe ) == address(0)) { revert Address_CantBeAddressZero();}
        hostingSafe = _hostingSafe;
        btcMinersSafe = _btcMinersSafe;
    }

    function setMintingCost(uint _price) external onlyOwner {
        if (!paused) { revert Pause_MustBePaused();}
        mintingCost = _price;
    }

    function setUsdcTokenAddress(address _address) public onlyOwner {
        if (address(_address ) == address(0)) { revert Address_CantBeAddressZero();}
        usdcTokenContract = _address;
    }

    function setUsdcTokenDecimals(uint _decimals) public  onlyOwner {
        usdcTokenDecimals = _decimals;
    }

    function setWbtcTokenAddress(address _address) public onlyOwner {
        if (address(_address ) == address(0)) { revert Address_CantBeAddressZero();}
        wbtcTokenContract = _address;
    }

    function setWbtcTokenDecimals(uint _decimals) public onlyOwner {
        wbtcTokenDecimals = _decimals;
    }

    function blacklistMalicious(address _address, bool value) external onlyOwner {
        isBlacklisted[_address] = value;
    }

    function setEcosystemRole(address _address, bool value) external onlyOwner {
        isEcosystemRole[_address] = value;
    }

    function setDefenderRole(address _address, bool value) external onlyOwner {
        isDefenderRole[_address] = value;
    }

    function setChainlinkVrfRole(address _address, bool value) external onlyOwner {
        isChainLinkVRFRole[_address] = value;
    }

    function setMonthlyMaintenanceFeePerNFT(uint256 _monthly_maint_fee_per_nft) external onlyOwner {
        calculatedMonthlyMaintenanceFee = _monthly_maint_fee_per_nft;
    }

    function setStockYardInfo(uint _stockyardNumber, uint _startingIndex, uint _endingIndex) public onlyOwner {
        if (_startingIndex == 0 || _endingIndex == 0 || _stockyardNumber == 0) { revert BadLogicInputParameter();}
        if (_endingIndex > _tokenSupply.current()) { revert BadLogicInputParameter();}
        if (stockyardInfo[_stockyardNumber - 1].endingIndex + 1 != _startingIndex ) { revert BadLogicInputParameter();}
   
        stockyardInfo[_stockyardNumber] =  StockyardInfo(_startingIndex, _endingIndex);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "ERC721Upgradeable.sol";
import "IERC721EnumerableUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "IERC721Upgradeable.sol";
import "IERC721ReceiverUpgradeable.sol";
import "IERC721MetadataUpgradeable.sol";
import "AddressUpgradeable.sol";
import "ContextUpgradeable.sol";
import "StringsUpgradeable.sol";
import "ERC165Upgradeable.sol";
import "Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165Upgradeable.sol";
import "Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "ContextUpgradeable.sol";
import "Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";
import "draft-IERC20PermitUpgradeable.sol";
import "AddressUpgradeable.sol";

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "Initializable.sol";

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}