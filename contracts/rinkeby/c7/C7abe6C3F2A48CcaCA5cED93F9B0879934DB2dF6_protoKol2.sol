// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Structs.sol";
import "./errors.sol";
import "./interfaces/iKolToken.sol";
import "./interfaces/iPST.sol";
import "./interfaces/IERC20.sol";
import "contracts/libraries/UniLib.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
// import "hardhat/console.sol";
contract protoKol2 is iProtoKol {
  //global variables
  uint256 campaignID;
  uint256 _kolID;
  uint16 public stakingPercentage=500;
  address admin;
  uint16 public _penalty_per=500;
  uint16 public _transactionPer = 50;
  uint16 public _platformPer = 50;
  address private _USDT = 0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02;
  address private _stakingContract = 0x3d6E9e408AF18b65F95EA0F51A82C99dA527347c;
  //IN Matic
  // address private constant UNISWAP_ROUTER_ADDRESS = 0x8954AfA98594b838bda56FE4C12a09D7739D179b;
  // address private factory = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;
  // address private _USDT = 0x9E6Fa3FB6e1E2AA49B709f7dd91fdC722e96bAD7;
  // address private _stakingContract = 0x76d0869a7F4528b7da5CF5aA90aa1B8554D0E864;
  //In Binance
  // address private _USDT = 0xc7660d9e1C355eAcEeA2bA5E05783fa7379Ee225;
  // address private _stakingContract = 0xBeFEaA8E981eE9e3982dBe00F9512227117D637d;

  address private _vault = 0xB4eA3D4F74520Fc11fF14810D8219FE309a0c265;
  //mappings
  mapping(address => KOL) private registeredKOL;
  mapping(address => mapping(uint256=>bool)) public blackListedKOL;
  mapping(address => uint256[]) public kolInvestDetails;
  mapping(uint256 => Campaign) public campaigns;
  mapping(address => mapping(uint256 =>InvestedCampaign)) public investedCampaignDetails;
  // mapping(uint256=>uint16) public tgeUpdated;
  //CONSTRUCTOR
  constructor(address _admin)
  {
    admin = _admin;
  }

  //modifiers
  modifier onlyAdmin() {
      require(msg.sender == admin, "Protokol:Only Admin function");
        _;
    }
  function recSig(bytes32 r, bytes32 s, uint8 v, bytes32 msgHash) public view returns(address){
    address signer = ecrecover(msgHash, v, r, s);
    require(signer==admin, "Protokol:Invalid Signer");
    return signer;
  }

  function registerKOL(string memory _name, string memory _ipfsHash) external
  {
    require(registeredKOL[msg.sender].kolWallet == address(0) && keccak256(bytes(_name)) != keccak256(bytes(""))
            && keccak256(bytes(_ipfsHash)) != keccak256(bytes("")), "Protokol:Invalid Details");
    // require(keccak256(bytes(_name)) != keccak256(bytes("")), "Protokol:Enter valid name");
    // require(keccak256(bytes(_ipfsHash)) != keccak256(bytes("")), "Protokol:Empty Ipfs Hash");
      KOL memory _newKol = KOL({
        kolWallet:msg.sender,
        name:_name,
        ipfsHash:_ipfsHash,
        kolID:_kolID
      });
      registeredKOL[msg.sender] = _newKol;
      _kolID++;
      emit KOLAdded(_newKol);
  }

  function retriveKOL(address _kol) public view returns(KOL memory kol)
  {
    return registeredKOL[_kol];
  }

  // function getKolInvestedCampaigns(address _kol) external view returns(uint256[] memory)
  // {
  //   return kolInvestDetails[_kol];
  // }

  function updateKolData(string memory _name, string memory _ipfsHash) external
  {
    require(registeredKOL[msg.sender].kolWallet != address(0) && keccak256(bytes(_name)) != keccak256(bytes(""))
            && keccak256(bytes(_ipfsHash)) != keccak256(bytes("")), "Protokol:Invalid Details");
    registeredKOL[msg.sender].name = _name;
    registeredKOL[msg.sender].ipfsHash = _ipfsHash;
  }

  function createCampaign(
        CampaignDetailsInput memory _newCampaignInput ,
        VestingDetailsInput memory _vestingInfoInput ,
        uint256 _tgeDate,
        uint16 _tgePer,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external returns(uint256){
      //Add signature
        bytes32 msgHash = keccak256(abi.encodePacked(_newCampaignInput.campaignOwner, _newCampaignInput.startDate, _tgeDate));
        recSig(r, s, v,msgHash);
        //add TGE Per 
        require(_newCampaignInput.campaignOwner != address(0x0), "Protokol:OwnerAddress=zero");
        require(_tgeDate >= _newCampaignInput.startDate + 21 * 1 days,
                 "Protokol:TGE date<21 days start date");
        require(_tgeDate <= block.timestamp + (_newCampaignInput.endTime - 14) * 1 days, 
                  "Protokol:TGE date>14 days end date");
        Campaign memory _campaign;
        _campaign.campaignNumber = campaignID;
        TGE memory _tgeInfo;
        CampaignDetails memory _newCampaign;
        VestingDetails memory _vestingInfo;
        _newCampaign.startDate = _newCampaignInput.startDate;
        _newCampaign.preSaleToken = _newCampaignInput.preSaleToken;
        _newCampaign.requiredInvestment = (_newCampaignInput.requiredInvestment * 10 ** IERC20(_USDT).decimals())/ 10 ** 18;
        _newCampaign.campaignOwner = _newCampaignInput.campaignOwner;
        _newCampaign.secondOwner = _newCampaignInput.secondOwner;
        _newCampaign.marketingBudget = _newCampaignInput.marketingBudget;
        _newCampaign.numberOfPostsReq = _newCampaignInput.numberOfPostsReq;
        _newCampaign.endDate = block.timestamp +  _newCampaignInput.endTime * 1 days;
        _newCampaign.remainingInvestment = _newCampaign.requiredInvestment;
        _newCampaign.stakingAmount = (stakingPercentage * _newCampaign.marketingBudget)/10000;
        _vestingInfo.isVestingInEnabled = _vestingInfoInput.isVestingInEnabled;
        _vestingInfo.NumberOfvestings = _vestingInfoInput.NumberOfvestings;
        _vestingInfo.vestingCycleDuration = _vestingInfoInput.vestingCycleDuration;
        //Tge Percentages going in 2 decimal places means -> 0.1% will be entered as 10
        _tgeInfo.tgePercentage = _tgePer;
        _tgeInfo.isTGE = false;
        uint256 _deductedBudget = _newCampaign.marketingBudget - _newCampaign.stakingAmount;
        //console.log("Deducted Budget",_deductedBudget);
        _tgeInfo.tgeDate = _tgeDate;
        //Include IMO part, platform revenue. Transfer the amount to project Treasury.
        if(_vestingInfo.isVestingInEnabled == true ) 
        {
          require(_vestingInfo.NumberOfvestings != 0 && _vestingInfo.vestingCycleDuration != 0
                  , "Protokol:NOV and CD can't be zero in vesting");
          _tgeInfo.tgeAmount = (_tgeInfo.tgePercentage * _deductedBudget) /10000 ;
        //console.log("TGE Amount",_tgeInfo.tgeAmount);
          _vestingInfo.vestingCycleDuration = _vestingInfo.vestingCycleDuration * 1 days; 
          _vestingInfo.vestingAmtPerCycle = ((_deductedBudget - _tgeInfo.tgeAmount) /_vestingInfo.NumberOfvestings); 
          //console.log("Vesting Amt/cycle",_vestingInfo.vestingAmtPerCycle);

        }
        else if(_vestingInfo.isVestingInEnabled == false ) 
        {
          // require(_vestingInfo.NumberOfvestings == 0 && _vestingInfo.vestingCycleDuration == 0, 
          //         "Protokol:Vesting is not enabled and number of vestings and vesting cycle duration should be zero");
          //TGE time in between end_time - starttime. 
          _tgeInfo.tgePercentage = 10000;
          _tgeInfo.tgeAmount = _deductedBudget;
        }  
      _campaign.campaignData = _newCampaign; 
       _campaign.vestingData =_vestingInfo;
       _campaign.tgeDetails = _tgeInfo;
       campaigns[campaignID] = _campaign;
       emit CampaignCreated(_campaign);
       campaignID++;
       return campaignID;
    }

  function retriveCampaign(uint256 _campaignId)
    public
    view
    returns (Campaign memory campaignDetails){
    return campaigns[_campaignId];
  }

  function updateCampaign(
    uint256 _campaignId,
    uint256 _tgeDate,
    address _preSaletoken
  ) external {
    Campaign memory campaignDetails = retriveCampaign(_campaignId);
    require(campaignDetails.campaignData.campaignOwner == msg.sender || 
            campaignDetails.campaignData.secondOwner == msg.sender, "Protkol:UnAuthorized");
    require(campaignDetails.tgeDetails.isTGE == false, "Protokol:TGE generated");
    require(_tgeDate >= campaignDetails.campaignData.startDate + 21 * 1 days,
                 "Protokol:TGE date > 1 month start date");
    require(_tgeDate + 14 days <= campaignDetails.campaignData.endDate,"Protokol:TGE date>14 days end Date");
    // if(campaignDetails.tgeDetails.amountOfTGEDateUpdation == 2){   
    //   require(_tgeDate - campaignDetails.tgeDetails.tgeDate <= 30 * 1 days, "Protokol:Tge date>1 month first time");
    //   // require(_tgeDate + 14 days <= campaignDetails.campaignData.endDate,"Protokol:TGE date should be prior of 14 days of end Date");
    //   campaigns[_campaignId].tgeDetails.tgeDate = _tgeDate;
    //   campaigns[_campaignId].tgeDetails.amountOfTGEDateUpdation =1;
    //   campaigns[_campaignId].tgeDetails.TGEUpdationDone=1;
    // }
    if(campaignDetails.tgeDetails.amountOfTGEDateUpdation >= 1){  
      require(_tgeDate - campaignDetails.tgeDetails.tgeDate <= (30 + campaignDetails.tgeDetails.TGEUpdationDone * 30) * 1 days, "Protokol:Tge date>mentioned time"); 
      // require(_tgeDate + 14 days <= campaignDetails.campaignData.endDate,"Protokol:TGE date should be prior of 14 days of end Date");      
      campaigns[_campaignId].tgeDetails.tgeDate = _tgeDate;
      campaigns[_campaignId].tgeDetails.amountOfTGEDateUpdation -=1;
      campaigns[_campaignId].tgeDetails.TGEUpdationDone+=1;
    }  
    campaigns[_campaignId].campaignData.preSaleToken = _preSaletoken;
    emit CampaignDetailsUpdated(campaigns[_campaignId]);
  }

  //Put Transaction fees on KOL Investment
  //Enter Amount in ETH
  function investInCampaign(uint256 _campaignId , uint256 _investment, Signature calldata sign)
  external{
    bytes32 msgHash = keccak256(abi.encodePacked(campaigns[_campaignId].campaignData.campaignOwner,
                      campaigns[_campaignId].campaignData.startDate, _USDT, _investment));
    recSig(sign.r, sign.s, sign.v, msgHash);
    InvestedCampaign memory investDetails = investedCampaignDetails[msg.sender][_campaignId];
    KOL memory _kolData = retriveKOL(msg.sender);
    require(_kolData.kolWallet != address(0) && !blackListedKOL[msg.sender][_campaignId], "Protokol:KOL not registered");
    // require(_investment > 0, "Protokol:Investment should be greater than zero");
    require(investDetails.investedAmt == 0,"Protokol:Already invested");
    require(block.timestamp <= campaigns[_campaignId].campaignData.endDate, "Protokol:Campaign has ended, can't invest");
    require(blackListedKOL[msg.sender][_campaignId] != true, "Protokol:KOL is blacklisted");
    _investment = (_investment * 10 ** IERC20(_USDT).decimals())/10 ** 18;
    // Campaign memory campaignDetails = retriveCampaign(_campaignId); 
    if(campaigns[_campaignId].campaignData.preSaleToken!=_USDT){
        uint256 _totalInvestment = _investment;
       _investment = (_investment * (10000 - _transactionPer))/10000;
      //  console.log("INvestment",_investment);
      require(_investment <= campaigns[_campaignId].campaignData.remainingInvestment, "Protokol:Amount>Investment");
      IERC20(_USDT).transferFrom(msg.sender ,address(this),_investment);
      IERC20(_USDT).transferFrom(msg.sender ,_vault,_totalInvestment - _investment);
      }

    // uint256 maxInvest = (campaignDetails.campaignData.requiredInvestment *campaignDetails.campaignData.maxInvest)/100;
    
    investDetails.investorKOL = msg.sender;
    investDetails.campaignNumber = campaigns[_campaignId].campaignNumber;
    ////console.log("Investment here->",_investment);
    investDetails.investedAmt = _investment;
    // console.log("Investment amt->",investDetails.investedAmt);
    investDetails.investShare = (investDetails.investedAmt*100 *10**18)/campaigns[_campaignId].campaignData.requiredInvestment;
    //make changes in this line
    // investDetails.investShare = investmentShare;
    //  console.log("Investment share->", investmentShare);
    
    if(campaigns[_campaignId].vestingData.isVestingInEnabled == true){
      // console.log("Investment eligible reward->", investDetails.eligibleReward);
      investDetails.vestingRewardPerCycle =(investDetails.investShare * campaigns[_campaignId].vestingData.vestingAmtPerCycle)/10**20;
    }

       //console.log("Investment Vesting->", investDetails.vestingRewardPerCycle);
    investDetails.eligibleReward = (investDetails.investShare * (campaigns[_campaignId].campaignData.marketingBudget - 
                                    campaigns[_campaignId].campaignData.stakingAmount))/(100 * 10**18);
    // console.log("Investment eligible reward->", investDetails.eligibleReward);
    campaigns[_campaignId].campaignData.remainingInvestment = campaigns[_campaignId].campaignData.remainingInvestment - _investment;
    //console.log("Investment here->",campaignDetails.campaignData.remainingInvestment);

    kolInvestDetails[msg.sender].push(_campaignId);
    investedCampaignDetails[msg.sender][_campaignId] = investDetails;
    // campaigns[_campaignId] = campaignDetails;
    emit InvestInCampaign(_campaignId, _investment, investDetails.investShare, msg.sender);
  }

  // function getInvestedCampaigns(address _investor,uint256 _campaignId) public view returns(InvestedCampaign memory investDetails )
  // {
  //   return investedCampaignDetails[_investor][_campaignId];
  // }
  //Only TGE amount will be multiply by 10** as we are not sure about presale Token decimals
  function generateTGE(uint256 _campaignId, address token) external
  {
    require(campaigns[_campaignId].tgeDetails.isTGE == false, "Protokol:TGE generated");

    require(campaigns[_campaignId].campaignData.campaignOwner == msg.sender 
            || campaigns[_campaignId].campaignData.secondOwner == msg.sender,
            "Protokol:UnAuthorized");
    if(campaigns[_campaignId].campaignData.preSaleToken == address(0x0)){
      campaigns[_campaignId].campaignData.preSaleToken = token;
    }
    require(campaigns[_campaignId].campaignData.preSaleToken == token,
    "Protokol:Token Address!=pre Sale token");
    require(block.timestamp <= campaigns[_campaignId].tgeDetails.tgeDate, "Protokol:Time has passed");
      //uint256 tgeAmt  = (campaignDetails.tgePercentage * campaignDetails.marketingBudget) /100 ;
    require(campaigns[_campaignId].campaignData.preSaleToken!=address(0x0), "Protokol:PST=zero");
    campaigns[_campaignId].tgeDetails.tgeAmount  = (campaigns[_campaignId].tgeDetails.tgeAmount*10**IERC20(campaigns[_campaignId].campaignData.preSaleToken).decimals())
                                                    /10**18;
    uint256 markBudge = (campaigns[_campaignId].campaignData.marketingBudget 
                                                          * 10 ** IERC20(token).decimals())/10**18;
    // console.log("TGE AMount", campaigns[_campaignId].tgeDetails.tgeAmount);
    uint256 staking = (campaigns[_campaignId].campaignData.stakingAmount * 10 ** IERC20(token).decimals())/10**18;
    IERC20(campaigns[_campaignId].campaignData.preSaleToken).transferFrom(msg.sender ,_stakingContract, staking);
   
    IERC20(campaigns[_campaignId].campaignData.preSaleToken).transferFrom(msg.sender ,_vault,(markBudge *  _platformPer)/1000);
    IERC20(campaigns[_campaignId].campaignData.preSaleToken).transferFrom(msg.sender ,address(this),campaigns[_campaignId].tgeDetails.tgeAmount);
    VestingDetails memory _vestingInfo;
    _vestingInfo = campaigns[_campaignId].vestingData;
    //transferFrom PST to this contract
    campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget  += (campaigns[_campaignId].tgeDetails.tgeAmount * 
                                                                      campaigns[_campaignId].campaignData.requiredInvestment)/
                                                                     markBudge;
    campaigns[_campaignId].tgeDetails.isTGE = true;
    campaigns[_campaignId].tgeDetails.tgeDate = block.timestamp;
    //console.log(campaignDetails.tgeDetails.isTGE);
    // campaigns[_campaignId] = campaignDetails;
    emit TGEDeposited( _campaignId ,campaigns[_campaignId].tgeDetails.tgeAmount , block.timestamp,
                    staking, 
                    token, msg.sender);
  }

  function claimKOLInvestment(uint256 _campaignId) external
  {
    //Campaign memory campaignDetails = retriveCampaign(_campaignId); 
    require(campaigns[_campaignId].tgeDetails.isTGE == true, "Protokol:!TGE");
    require(campaigns[_campaignId].campaignData.campaignOwner == msg.sender 
            || campaigns[_campaignId].campaignData.secondOwner == msg.sender, "Protokol:UnAuthorized");
    // require(campaigns[_campaignId].campaignData.remainingInvestment == 0, "Protokol:Investment is not Attained");
    require(campaigns[_campaignId].campaignData.investmentClaimed < campaigns[_campaignId].campaignData.requiredInvestment -
             campaigns[_campaignId].campaignData.remainingInvestment
            , "Protokol:Investment Already claimed");
    require(campaigns[_campaignId].campaignData.investmentClaimed < campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget,
            "Protokol:Already claimed your share against budget");
    require(campaigns[_campaignId].campaignData.preSaleToken!=_USDT,"Protokol: Can't claim, PST is USDT");
    uint256 _investment = campaigns[_campaignId].campaignData.requiredInvestment - campaigns[_campaignId].campaignData.remainingInvestment
                          - campaigns[_campaignId].campaignData.investmentClaimed;
    if(_investment > campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget)
      _investment = campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget - 
                  campaigns[_campaignId].campaignData.investmentClaimed;
    IERC20(_USDT).transfer(msg.sender, _investment);
    // console.log("Output of uniswap",amount[0]);
    // console.log("Output of uniswap",amount[1]);

    campaigns[_campaignId].campaignData.investmentClaimed = _investment;
    emit ClaimKolInvestment(_campaignId, _investment, msg.sender);
  }

  function setContractVariables(uint16[] calldata contractVariables) external onlyAdmin
  {
      //add checks for staking Percentage
      // require(stakingPercentage < 90, "Protokol:Staking Percentage can't be greater than 90%");
      stakingPercentage = contractVariables[0];
      _penalty_per = contractVariables[1];
      _transactionPer = contractVariables[2];
      _platformPer = contractVariables[3];

      emit ContractVariablesUpdated(stakingPercentage, _penalty_per, _transactionPer, _platformPer, block.timestamp, msg.sender);
  }
  //Give KOL TGE AMOUNT according to KOL's share.
  // function claimTGEAmount(uint256 _campaignId) external{

  // }
  //Enter Amount in ETH
  function depositPreSaleTokens(uint256 _campaignId, uint256 _amount) external{
    require(campaigns[_campaignId].tgeDetails.isTGE == true, "Protokol:!TGE");
    require(campaigns[_campaignId].campaignData.campaignOwner == msg.sender ||
            campaigns[_campaignId].campaignData.secondOwner == msg.sender, "Protokol:UnAuthorized");

    address token = campaigns[_campaignId].campaignData.preSaleToken;
    _amount = (_amount * 10**IERC20(token).decimals())/10**18;
    IERC20(token).transferFrom
                  (msg.sender, address(this), _amount);
    campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget  += (_amount *
                                                                                    campaigns[_campaignId].campaignData.requiredInvestment)/
                                                                                    campaigns[_campaignId].campaignData.marketingBudget;
    emit DepositPreSaleTokens(_campaignId, _amount, token, msg.sender);
    }
  function claimPreSaleTokens(uint256 _campaignId, uint256 progress, bytes32 r,
        bytes32 s,
        uint8 v)external{
    // Add admin signature to this function
    // By adding a signature we make sure that KOL's progress is updated;
    //Check progress for only that vesting
    //CampaignDetails memory _campaign = retriveCampaign(_campaignId); 
     uint256 _reward;
    bytes32 msgHash = keccak256(abi.encodePacked(campaigns[_campaignId].campaignData.campaignOwner,
                      campaigns[_campaignId].campaignData.startDate, campaigns[_campaignId].campaignData.preSaleToken));
    recSig(r, s, v, msgHash);
    InvestedCampaign memory investmentDetails = investedCampaignDetails[msg.sender][_campaignId];
    require(investmentDetails.investedAmt > 0,
             "Protokol:No Investments.");
    require(campaigns[_campaignId].tgeDetails.isTGE == true, "Protokol:!TGE");
    //require(campaigns[_campaignId].campaignData.endDate <= block.timestamp , "Protokol:end Time not reached");
    // require(blackListedKOL[msg.sender] != true, "Protokol:KOL is blacklisted can't claim");
    //check balance of contract of presale tokens against KOL's vesting reward
    // if(investmentDetails.lastVestingClaimed < campaigns[_campaignId].tgeDetails.tgeDate)
    //   investmentDetails.lastVestingClaimed = campaigns[_campaignId].tgeDetails.tgeDate;
    address preSale = campaigns[_campaignId].campaignData.preSaleToken;
    if(campaigns[_campaignId].vestingData.isVestingInEnabled){
      require(block.timestamp - investmentDetails.lastVestingClaimed
               > campaigns[_campaignId].vestingData.vestingCycleDuration, "Protokol:Vesting Claimed");
      // require(investmentDetails.numberOfVestingsClaimed <
      //         campaigns[_campaignId].vestingData.NumberOfvestings, "Protokol:You have claimed all your vestings");
      uint256 _vesting = (block.timestamp - campaigns[_campaignId].tgeDetails.tgeDate)
                            /campaigns[_campaignId].vestingData.vestingCycleDuration;
      // console.log("Amount of vestings",_vesting);

      // progress = (progress * campaigns[_campaignId].vestingData.NumberOfvestings/_vesting);
      _vesting = (investmentDetails.investShare * campaigns[_campaignId].tgeDetails.tgeAmount)/(100 * 10 ** 18)
                  + _vesting * (investmentDetails.vestingRewardPerCycle * 10 ** IERC20(preSale).decimals())
                  / 10 ** 18;
      // console.log("Vesting Reward/cycle",investmentDetails.vestingRewardPerCycle);
      // console.log("Vesting number:",_vesting);

      uint256 totalReward =  (investmentDetails.eligibleReward * 10 ** IERC20(_USDT).decimals() * progress)/(10000 * 10 ** 18);
      // console.log("Claimed Reward: ",investedCampaignDetails[msg.sender][_campaignId].claimedReward);

      require(totalReward > investedCampaignDetails[msg.sender][_campaignId].claimedReward, 
              "Protokol:Already claimed PST");
        // console.log("Total",totalReward);
      _reward = _vesting >= totalReward ? totalReward:_vesting;
      // console.log("Reward in claim PreSale Token", _reward);

      
      _reward = _reward - investedCampaignDetails[msg.sender][_campaignId].claimedReward;
      if(blackListedKOL[msg.sender][_campaignId] == true){
          _blackListedKOLFundsHandling(_campaignId, _reward, preSale);
          return;
      }
      require(IERC20(preSale).balanceOf(address(this)) >= _reward
              , "Protokol:Not enough funds");
      investedCampaignDetails[msg.sender][_campaignId].leftOverReward = _vesting - _reward;
      IERC20(preSale)
              .transfer(msg.sender
                        , _reward);
      
      investedCampaignDetails[msg.sender][_campaignId].lastVestingClaimed = block.timestamp;
      investedCampaignDetails[msg.sender][_campaignId].claimedReward +=_reward;
      emit ClaimPreSaleTokens(_campaignId, _vesting, preSale, msg.sender);
    }
    else{
      // console.log("KOL ELigible Reward:",investedCampaignDetails[msg.sender][_campaignId].eligibleReward);
      investedCampaignDetails[msg.sender][_campaignId].eligibleReward = 
              (investmentDetails.eligibleReward * 10 ** IERC20(preSale).decimals())/ 10 ** 18;
      // console.log("KOL ELigible Reward:",investedCampaignDetails[msg.sender][_campaignId].eligibleReward);
      uint256 eligibleRwd = (investedCampaignDetails[msg.sender][_campaignId].eligibleReward * progress)/10000
                          - investedCampaignDetails[msg.sender][_campaignId].claimedReward;
      if(blackListedKOL[msg.sender][_campaignId] == true){
        _blackListedKOLFundsHandling(_campaignId, eligibleRwd, preSale);
        return;
      }

      require(IERC20(preSale).balanceOf(address(this)) >= 
              eligibleRwd
              , "Protokol:Not enough funds");
      IERC20(preSale)
              .transfer(msg.sender
                        , eligibleRwd);
       investedCampaignDetails[msg.sender][_campaignId].claimedReward +=eligibleRwd;                       
      emit ClaimPreSaleTokens(_campaignId, eligibleRwd
                                    , preSale, msg.sender);
    }
  }
  //We also need to let him claim Back Investment when TGE date has past, and when max TGE change limit is reached. 
  // function claimBackInvestmentByKOLForTge(uint256 _campaignId) external {
  //   require(blackListedKOL[msg.sender][_campaignId] != true, "Protokol:KOL is blacklisted can't claim");
  //   if(tgeUpdated[_campaignId] >= 2 || 
  //     (campaigns[_campaignId].tgeDetails.isTGE == false && 
  //     campaigns[_campaignId].tgeDetails.tgeDate <= block.timestamp)){
  //     address[] memory path = new address[](2);
  //     path[0] = _USDT;
  //     path[1] = kolToken;
  //     uint256 _investment = campaigns[_campaignId].campaignData.requiredInvestment;
  //     campaigns[_campaignId].campaignData.remainingInvestment += _investment;
  //     uint[] memory amount = UniswapV2Library.getAmountsOut(factory, _investment, path);
  //     amount = _swapRouter(_investment, amount[1], path,msg.sender);
  //     emit ClaimBackInvestmentForTge(_campaignId, investedCampaignDetails[msg.sender][_campaignId].investedAmt, msg.sender);
      
  //   } 
  // }
  // // //naming 
  function claimBackInvestmentByKOL(uint256 _campaignId, uint256 progress,
                                bytes32 r, bytes32 s,uint8 v) 
  external {
    require(blackListedKOL[msg.sender][_campaignId] != true, "Protokol:KOL is blacklisted");
    require(investedCampaignDetails[msg.sender][_campaignId].investedAmt > 0,
             "Protokol:No Investments.");
    require(campaigns[_campaignId].campaignData.preSaleToken!=_USDT,"Protokol: Can't claim, PST is USDT");
    // Add signature
    require(campaigns[_campaignId].tgeDetails.tgeDate >= block.timestamp, "Protokol:Can't claim, TGE Already generated");
    // if(campaigns[_campaignId].tgeDetails.amountOfTGEDateUpdation == 0 || 
    //    campaigns[_campaignId].tgeDetails.isTGE == false){
    //   address[] memory path = new address[](2);
    //   path[0] = _USDT;
    //   path[1] = kolToken;
    //   uint256 _investment = campaigns[_campaignId].campaignData.requiredInvestment;
    //   campaigns[_campaignId].campaignData.remainingInvestment += _investment;
    //   uint[] memory amount = UniswapV2Library.getAmountsOut(factory, _investment, path);
    //   amount = _swapRouter(_investment, amount[1], path,msg.sender);
    //   emit ClaimBackInvestmentForTge(_campaignId, investedCampaignDetails[msg.sender][_campaignId].investedAmt, msg.sender);
    //   return;
    // } 
    
    // require(blackListedKOL[msg.sender][_campaignId] != true, "Protokol:KOL is blacklisted can't claim");    
    bytes32 msgHash = keccak256(abi.encodePacked(campaigns[_campaignId].campaignData.campaignOwner,
                      campaigns[_campaignId].campaignData.startDate, campaigns[_campaignId].tgeDetails.tgeDate, 
                      investedCampaignDetails[msg.sender][_campaignId].investedAmt));
   
    recSig(r, s, v, msgHash);

    //Calculation: Progress-> uint, Investment, penalty_per
    //if progress is 0 then apply penalty percentage
      //Investment * penalty_per = remaining amt.
      InvestedCampaign memory _investment = investedCampaignDetails[msg.sender][_campaignId];
      uint256 _invest = _investment.investedAmt;
      if(progress == 0 && campaigns[_campaignId].tgeDetails.amountOfTGEDateUpdation != 0){
        _invest = _invest - (_invest * _penalty_per)/10000;
      }
      IERC20(_USDT).transfer(msg.sender, _invest);
    //   address[] memory path = new address[](2);
    //   path[0] = _USDT;
    //   path[1] = kolToken;
    //   uint[] memory amount = UniswapV2Library.getAmountsOut(factory, _invest, path);
    //   amount = _swapRouter(_invest, amount[1], path,msg.sender);
    campaigns[_campaignId].campaignData.remainingInvestment += _investment.investedAmt;
    _investment.investedAmt = 0;
    _investment.investShare = 0;
    _investment.eligibleReward = 0;
    _investment.investShare = 0;
    _investment.vestingRewardPerCycle = 0;
    investedCampaignDetails[msg.sender][_campaignId] = _investment;
    emit ClaimBackInvestment(_campaignId, progress,  _invest, msg.sender);
  }
  // function setPenalty(uint16 _penalty) external onlyAdmin {
  //   require(_penalty < 100, "Protokol:Penalty should not be greater than 90%");
  //   _penalty_per = _penalty;
  //   emit SetPenalty(_penalty);
  // }
  function blackListKOL(uint256 _campaignId, address _kol, uint16 progress) external onlyAdmin {
    blackListedKOL[_kol][_campaignId] = true;
    if(campaigns[_campaignId].campaignData.preSaleToken != _USDT){
    investedCampaignDetails[_kol][_campaignId].leftOverInvestment = (investedCampaignDetails[_kol][_campaignId].investedAmt * 
                                                                (10000 - progress))/10000;  
    campaigns[_campaignId].campaignData.remainingInvestment += investedCampaignDetails[_kol][_campaignId].leftOverInvestment;
    // console.log("Left Over Investment in Blacklisting Function",investedCampaignDetails[_kol][_campaignId].leftOverInvestment);
    }
                                                          
  }
  function _blackListedKOLFundsHandling(uint256 _campaignId, uint256 _reward, address preSale) private{
   if(IERC20(preSale).balanceOf(address(this)) < _reward){
      uint256 balance = IERC20(preSale).balanceOf(address(this));
      // console.log(balance);
      IERC20(preSale).transfer(msg.sender,balance);
      _reward  = _reward - balance; 
    }
    else{
      IERC20(preSale).transfer(msg.sender,_reward);
      _reward = 0;
    }
    // console.log("Reward",_reward);
    if(campaigns[_campaignId].campaignData.preSaleToken != _USDT){
    investedCampaignDetails[msg.sender][_campaignId].leftOverInvestment += (_reward * 
                                                                            campaigns[_campaignId].campaignData.requiredInvestment)/
                                                                            ((campaigns[_campaignId].campaignData.marketingBudget 
                                                                            * 10 ** IERC20(_USDT).decimals())/10**18);
    // console.log("Left Over Investment",investedCampaignDetails[msg.sender][_campaignId].leftOverInvestment);
    if(IERC20(_USDT).balanceOf(address(this)) < investedCampaignDetails[msg.sender][_campaignId].leftOverInvestment){
      IERC20(_USDT).transfer(msg.sender, IERC20(_USDT).balanceOf(address(this)));
    }
    else{
      IERC20(_USDT).transfer(msg.sender, investedCampaignDetails[msg.sender][_campaignId].leftOverInvestment);
    }
    }
   investedCampaignDetails[msg.sender][_campaignId].investedAmt = 0;
  }
  function setNumberOfCampaignsUpdations(uint256 _campaignId, uint16 _amount) external onlyAdmin{
    campaigns[_campaignId].tgeDetails.amountOfTGEDateUpdation = _amount;
  }
  function setStakingContract(address _stakingCont) external{
    _stakingContract = _stakingCont;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface iProtoKol {
  
  struct Campaign {
    uint256 campaignNumber;
    CampaignDetails campaignData;
    VestingDetails vestingData;
    TGE tgeDetails;
  }

  struct CampaignDetailsInput{
    address preSaleToken;
    address campaignOwner;
    address secondOwner;
    uint256 requiredInvestment;
    uint256 marketingBudget;
    uint256 startDate;
    uint256 endTime;
    uint256 numberOfPostsReq;
    string ipfsHash;
  } 

  struct CampaignDetails{
    uint256 investmentClaimed;
    address preSaleToken;
    address campaignOwner;
    address secondOwner;
    uint256 requiredInvestment;
    uint256 marketingBudget;
    uint256 startDate;
    uint256 endDate;
    uint256 remainingInvestment;
    uint256 numberOfPostsReq;
    uint256 stakingAmount;
    uint256 enteredInvestmentAgainstMarketingBudget;
  }
  struct VestingDetailsInput {
    bool isVestingInEnabled;
    uint256 NumberOfvestings;
    uint256 vestingCycleDuration;

  }
  //vcd = uin81
  struct VestingDetails {
    bool isVestingInEnabled;
    // bool isVestingOutEnabled;
    uint256 NumberOfvestings;
    uint256 vestingCycleDuration;
    uint256 vestingAmtPerCycle;
  }
  struct TGE {
    bool isTGE;
    uint16 tgePercentage;
    uint256 tgeDate;
    uint256 tgeAmount;
    uint16 amountOfTGEDateUpdation;
    uint16 TGEUpdationDone;
  }
  
  struct InvestedCampaign {
    address investorKOL;
    uint256 campaignNumber;
    uint256 investedAmt;
    uint256 investShare;
    uint256 eligibleReward;
    uint256 vestingRewardPerCycle;
    uint256 lastVestingClaimed;
    uint256 claimedReward;
    uint256 leftOverReward;
    uint256 leftOverInvestment;
    //uint256 postsToBeDone;
  }

  struct KOL {
    address kolWallet;
    uint256 kolID;
    string name;
    string ipfsHash;
  }

  struct KolInvestments {
    uint256 kolID;
    uint256[] investedCampaigns;
  }
  struct Signature {
    bytes32 r;
    bytes32 s;
    uint8 v;

  }

  event KOLAdded(KOL _kol);
  event CampaignCreated(Campaign _campaign);
  event CampaignDetailsUpdated(Campaign _newCampaign);
  event TGEDeposited(
    uint256 _campaignID,
    uint256 _tgeAmount,
    uint256 _tgeTime,
    uint256 _stakingAmount,
    address _preSaleToken,
    address _depositedBy
  );

  event ContractVariablesUpdated(
    uint16 _stakingPerct,
    uint16 _penaltyPer,
    uint16 _transactionPer,
    uint16 _platformPer,
    uint256 _time,
    address _updatedBy
  );
  event DepositPreSaleTokens(uint256 campaign_Id, uint256 _amount, address token, address depositer);
  event ClaimPreSaleTokens(uint256 campaign_Id, uint256 _amount, address preSaleToken, address _kol);
  event InvestInCampaign(uint256 campaign_Id, uint256 _amount, uint256 _investmentShare, address _kol);
  event ClaimKolInvestment(uint256 campaign_Id, uint256 _investment, address _kol);
  event ClaimBackInvestment(uint256 campaign_Id, uint256 progress, uint256 _investment, address _kol);
  event SetMaxTGEAllowance(uint256 _tge);
  event SetPenalty(uint256 _penalty);
  // event ClaimBackInvestmentForTge(uint256 campaign_Id, uint256 _investment, address _kol);
  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error zeroAddress(address _addr);
error vestingInNotEnabled(bool isVest);
error vestingOutNotEnabled(bool isVest);
error setPreSaleTokenAddress(address _addr);
error InvalidNumberOfVestings(uint256 vestingNumber);
error InvalidVestingCycleDuration(uint256 vestingCycleduration);
error InvestmentSarted(uint256 _remainingInvest);
error AmountAboveMaxInvestment(uint256 _amt);
error InvestmentAttained(uint256 _investmentRequired);
error UnAuthorizedOwners (address _owner , address _secondOwner);
error InvestmentNotAttained(uint256 _remainingInvestment);
error TGEDone(bool _tgeDone);
error TGENotDone(bool _tgeDone);
error  InvestmentClaimed(bool isInvestmentclaimed);
error AlreadyInvested(uint256 _investment);
error InvalidAdmin(address _admin);
error KOLExists (uint256  _kolID);
error KolNotRegistered(address _kol);
error TgeTimeExceeded(uint256 _tgeTime);
error GenerateTGE(bool _isTGE );
error VestingCycleEnded(uint256 _vestingCycle);
error VestingsCompleted(uint256 _NumberFOVestings);
error MaxTGELimitReached();

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;


interface  IKOLT {    
    function transferFrom(address sender,address recipient,uint256 amount) external;   
    function transfer(address _to , uint256 amount ) external;
    function decimals() external view returns (uint8);
    function approve(address spender, uint256 amount) external returns (bool);
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;


interface  IPST {    
    function transferFrom(address sender,address recipient,uint256 amount) external;   
    function transfer(address _to , uint256 amount ) external;
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function decimals() external view returns (uint8);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import "./SafeMath.sol";
import "hardhat/console.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// A library for performing overflow-safe math, courtesy of DappHub: https://github.com/dapphub/ds-math/blob/d0ef6d6a5f/src/math.sol
// Modified to include only the essentials
library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "MATH:ADD_OVERFLOW");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "MATH:SUB_UNDERFLOW");
    }
     function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}