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
contract protoKol is iProtoKol {
  //global variables
  uint256 campaignID;
  uint256 _kolID;
  uint16 public stakingPercentage=5;
  address admin;
  address kolToken;
  uint16 public _penalty_per=5;
  uint16 public _transactionPer = 5;
  uint16 public _platformPer = 5;
  address private constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address private constant _WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
  address private factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  address private _USDT = 0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02;
  address private _vault = 0xB4eA3D4F74520Fc11fF14810D8219FE309a0c265;
  //mappings
  mapping(address => KOL) private registeredKOL;
  mapping(address => bool) public blackListedKOL;
  mapping(address => uint256[]) public kolInvestDetails;
  mapping(uint256 => Campaign) public campaigns;
  mapping(address => mapping(uint256 =>InvestedCampaign)) public investedCapmaignDetails;
  mapping(uint256=>uint16) public tgeUpdated;
  //CONSTRUCTOR
  constructor(address _admin , address _kolToken)
  {
    admin = _admin;
    kolToken = _kolToken;
  }

  //modifiers
  modifier onlyAdmin() {
      require(msg.sender == admin, "Protokol:Only Admin can use this function");
        _;
    }
  function recSig(bytes32 r, bytes32 s, uint8 v, bytes32 msgHash) public view returns(address){
    address signer = ecrecover(msgHash, v, r, s);
    require(signer==admin, "Protokol:Invalid Signer");
    return signer;
  }

  function registerKOL(string memory _name, string memory _ipfsHash) external
  {
    require(registeredKOL[msg.sender].kolWallet == address(0), "Protokol: KOL already exists");
    require(keccak256(bytes(_name)) != keccak256(bytes("")), "Protokol: Kindly enter a valid name");
    require(keccak256(bytes(_ipfsHash)) != keccak256(bytes("")), "Protokol: Empty Ipfs Hash");
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

  function getKolInvestedCampaigns(address _kol) external view returns(uint256[] memory)
  {
    return kolInvestDetails[_kol];
  }

  function updateKolData(string memory _name, string memory _ipfsHash) external
  {
    require(registeredKOL[msg.sender].kolWallet != address(0), "Protokol: KOL doesnot exists");
    require(keccak256(bytes(_name)) != keccak256(bytes("")), "Protokol: Kindly enter a valid name");
    require(keccak256(bytes(_ipfsHash)) != keccak256(bytes("")), "Protokol: Empty Ipfs Hash");
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
        require(_newCampaignInput.campaignOwner != address(0x0), "Protokol: Owner Address can't be zero");
        // require(_tgeDate >= block.timestamp + 14 * 1 days,
        //          "Protokol:TGE date should be greater than 1 month after start date");
        // require(_tgeDate <= block.timestamp + (_newCampaignInput.endTime - 21) * 1 days, 
        //           "Protokol:TGE date should be less than 2 month before end date");
        Campaign memory _campaign;
        _campaign.campaignNumber = campaignID;
        TGE memory _tgeInfo;
        CampaignDetails memory _newCampaign;
        VestingDetails memory _vestingInfo;
        _newCampaign.startDate = _newCampaignInput.startDate;
        _newCampaign.preSaleToken = _newCampaignInput.preSaleToken;
        _newCampaign.requiredInvestment = _newCampaignInput.requiredInvestment;
        _newCampaign.campaignOwner = _newCampaignInput.campaignOwner;
        _newCampaign.secondOwner = _newCampaignInput.secondOwner;
        _newCampaign.ipfsHash = _newCampaignInput.ipfsHash;
        _newCampaign.marketingBudget = _newCampaignInput.marketingBudget;
        _newCampaign.numberOfPostsReq = _newCampaignInput.numberOfPostsReq;
        _newCampaign.endTime = block.timestamp +  _newCampaignInput.endTime * 1 days;
        _newCampaign.remainingInvestment = _newCampaignInput.requiredInvestment;
        _newCampaign.stakingAmount = (stakingPercentage * _newCampaign.marketingBudget)/100;
        _vestingInfo.isVestingInEnabled = _vestingInfoInput.isVestingInEnabled;
        _vestingInfo.NumberOfvestings = _vestingInfoInput.NumberOfvestings;
        _vestingInfo.vestingCycleDuration = _vestingInfoInput.vestingCycleDuration;
        _tgeInfo.tgePercentage = _tgePer;
        _tgeInfo.isTGE = false;
        uint256 _deductedBudget = _newCampaign.marketingBudget - _newCampaign.stakingAmount;
        _tgeInfo.tgeDate = _tgeDate;
        //Include IMO part, platform revenue. Transfer the amount to project Treasury.
        if(_vestingInfo.isVestingInEnabled == true ) 
        {
          require(_vestingInfo.NumberOfvestings != 0 && _vestingInfo.vestingCycleDuration != 0
                  , "Protokol: Number of Vestings or Cycle duration can't be zero");
          _tgeInfo.tgeAmount = (_tgeInfo.tgePercentage * _deductedBudget) /100 ;
          _vestingInfo.vestingCycleDuration = _vestingInfo.vestingCycleDuration * 1 days; 
          _vestingInfo.vestingAmtPerCycle = (_deductedBudget - _tgeInfo.tgeAmount) /_vestingInfo.NumberOfvestings; 
        
        }
        else if(_vestingInfo.isVestingInEnabled == false ) 
        {
          //TGE time in between end_time - starttime. 
          _tgeInfo.tgePercentage = 100;
          _tgeInfo.tgeAmount = _deductedBudget;
          require(_vestingInfo.NumberOfvestings == 0 && _vestingInfo.vestingCycleDuration == 0, 
                  "Protokol: Vesting is not enabled and number of vestings and vesting cycle duration should be zero");
        }  
      _campaign.campaignData = _newCampaign; 
       _campaign.vestingData =_vestingInfo;
       _campaign.tgeDetails = _tgeInfo;
       campaigns[campaignID] = _campaign;
       emit CampaignCreated(_campaign);
       uint256 _campaignId = campaignID;
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
  ) external returns (bool) {
    Campaign memory campaignDetails = retriveCampaign(_campaignId);
    require(campaignDetails.campaignData.campaignOwner == msg.sender || 
            campaignDetails.campaignData.secondOwner == msg.sender, "Protkol:Unauthorized Owner");
    require(campaignDetails.tgeDetails.isTGE == false, "Protokol: TGE is already generated");
    // require(_tgeDate >= campaignDetails.campaignData.startTime + 14 * 1 days,
    //              "Protokol:TGE date should be greater than 1 month after start date");
    // require(_tgeDate <= block.timestamp + (campaignDetails.campaignData.endTime - 21) * 1 days, 
    //               "Protokol:TGE date should be less than 2 month before end date");
    if(campaignDetails.tgeDetails.amountOfTGEDateUpdation >= 1){   
      campaigns[_campaignId].tgeDetails.tgeDate = _tgeDate;
      campaigns[_campaignId].tgeDetails.amountOfTGEDateUpdation -=1;
    }  
    campaigns[_campaignId].campaignData.preSaleToken = _preSaletoken;
    emit CampaignDetailsUpdated(campaignDetails);
    return true;
  }
  function _swapRouter(uint256 _investment, uint256 amountOut, address[] memory path) private returns(uint256[] memory amount){
    IERC20(path[0]).approve(UNISWAP_ROUTER_ADDRESS,_investment);
    amount = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactTokensForTokens(
            _investment,
            amountOut,
            path,
            address(this),
            block.timestamp + 1 hours
    );

  }
  //Put Transaction fees on KOL Investment
  function investInCampaign(uint256 _campaignId , uint256 _investment, address tokenAddress, Signature calldata sign)
  external returns (bool){
    bytes32 msgHash = keccak256(abi.encodePacked(campaigns[_campaignId].campaignData.campaignOwner,
                      campaigns[_campaignId].campaignData.startDate, tokenAddress, _investment));
    recSig(sign.r, sign.s, sign.v, msgHash);
    InvestedCampaign memory investDetails = getInvestedCampaigns(msg.sender,_campaignId);
    KOL memory _kolData = retriveKOL(msg.sender);
    require(_kolData.kolWallet != address(0) && !blackListedKOL[msg.sender], "Protokol: KOL is not registered");
    require(_investment > 0, "Protokol: Investment should be greater than zero");
    require(tokenAddress == kolToken || tokenAddress == _USDT, "Protokol token can either be USDT or KOLs");
    Campaign memory campaignDetails = retriveCampaign(_campaignId); 
    uint16 leftOverPer = (100 - _transactionPer)/100;
    if(tokenAddress == kolToken){
      address[] memory path = new address[](2);
      path[0] = tokenAddress;
      path[1] = _USDT;
      uint[] memory amount = UniswapV2Library.getAmountsOut(factory, _investment, path);
      //console.log(amount[1]);
      require(amount[1] * leftOverPer  <= campaignDetails.campaignData.remainingInvestment, "Protokol: Amount is above Investment");
      _investment = amount[1] * leftOverPer;
      IKOLT(kolToken).transferFrom(msg.sender ,address(this),_investment);
      amount = _swapRouter(_investment, amount[1], path);
    }
    else{
    require(_investment * leftOverPer<= campaignDetails.campaignData.remainingInvestment, "Protokol: Amount is above Investment");
    IERC20(_USDT).transferFrom(msg.sender ,address(this),_investment * leftOverPer);
    }

    // uint256 maxInvest = (campaignDetails.campaignData.requiredInvestment *campaignDetails.campaignData.maxInvest)/100;
    
    investDetails.investorKOL = msg.sender;
    investDetails.campaignNumber = campaignDetails.campaignNumber;
    //console.log("Investment here->",_investment);
    investDetails.investedAmt = investDetails.investedAmt + _investment;
    //console.log("Investment amt->",investDetails.investedAmt);
    uint256 investmentShare = (investDetails.investedAmt*100 *10**18)/campaignDetails.campaignData.requiredInvestment;
    //make changes in this line
    investDetails.investShare = investmentShare;
    //console.log("Investment share->", investDetails.investShare);
      uint256 _deductedBudget = campaignDetails.campaignData.marketingBudget- campaignDetails.campaignData.stakingAmount;
    
    if(campaignDetails.vestingData.isVestingInEnabled == false){
      investDetails.eligibleReward = (investmentShare*_deductedBudget);
      //console.log("Investment eligible reward->", investDetails.eligibleReward);
    }
    else{
      investDetails.vestingRewardPerCycle =( investmentShare * campaignDetails.vestingData.vestingAmtPerCycle)/100;
      investDetails.lastVestingClaimed = campaignDetails.campaignData.endTime;
      investDetails.numberOfVestingsClaimed = 0;
       //console.log("Investment Vesting->", investDetails.vestingRewardPerCycle);
    }
    campaignDetails.campaignData.remainingInvestment = campaignDetails.campaignData.remainingInvestment - _investment;
    //console.log("Investment here->",campaignDetails.campaignData.remainingInvestment);

    
    kolInvestDetails[msg.sender].push(_campaignId);

    campaigns[_campaignId] = campaignDetails;
    emit InvestInCampaign(_campaignId, _investment, investmentShare, msg.sender);
    return true; 
  }

  function getInvestedCampaigns(address _investor,uint256 _campaignId) public view returns(InvestedCampaign memory investDetails )
  {
    return investedCapmaignDetails[_investor][_campaignId];
  }
  //Only TGE amount will be multiply by 10** as we are not sure about presale Token decimals
  function generateTGE(uint256 _campaignId, address token) external returns (bool)
  {
    Campaign memory campaignDetails = retriveCampaign(_campaignId);
    require(campaignDetails.tgeDetails.isTGE == false, "Protokol: TGE generated");

    require(campaignDetails.campaignData.campaignOwner == msg.sender 
            || campaignDetails.campaignData.secondOwner == msg.sender,
            "Protokol: UnAuthorized Owner");
    if(campaignDetails.campaignData.preSaleToken != address(0x0)){
      campaignDetails.campaignData.preSaleToken == token;
    }
    require(campaignDetails.campaignData.preSaleToken == token,
    "Protokol: Token Address not equal to pre Sale token");
    require(block.timestamp <= campaignDetails.tgeDetails.tgeDate, "Protokol: Time has passed");
      //uint256 tgeAmt  = (campaignDetails.tgePercentage * campaignDetails.marketingBudget) /100 ;
    require(campaignDetails.campaignData.preSaleToken!=address(0x0), "Protokol: PreSale token address is zero");
    campaignDetails.tgeDetails.tgeAmount  = campaignDetails.tgeDetails.tgeAmount*10**IPST(campaignDetails.campaignData.preSaleToken).decimals();
    //console.log("TGE AMount", campaignDetails.tgeDetails.tgeAmount);
    IERC20(campaignDetails.campaignData.preSaleToken).transferFrom(msg.sender ,_vault,campaignDetails.campaignData.marketingBudget * _platformPer);
    IERC20(campaignDetails.campaignData.preSaleToken).transferFrom(msg.sender ,address(this),campaignDetails.tgeDetails.tgeAmount);
    VestingDetails memory _vestingInfo;
    _vestingInfo = campaignDetails.vestingData;
    //transferFrom PST to this contract
    campaignDetails.tgeDetails.isTGE = true;
    //console.log(campaignDetails.tgeDetails.isTGE);
    campaigns[_campaignId] = campaignDetails;
    emit TGEDeposited( _campaignId ,campaignDetails.tgeDetails.tgeAmount ,block.timestamp, msg.sender);
    return true;
  }

  function claimKOLInvestment(uint256 _campaignId) external returns (bool)
  {
    Campaign memory campaignDetails = retriveCampaign(_campaignId); 
    require(campaignDetails.tgeDetails.isTGE == true, "Protokol: TGE not generated");
    require(campaignDetails.campaignData.campaignOwner == msg.sender 
            || campaignDetails.campaignData.secondOwner == msg.sender, "Protokol: UnAuthorized Owner");
    require(campaignDetails.campaignData.remainingInvestment == 0, "Protokol:Investment is not Attained");
    require(campaignDetails.campaignData.investmentClaimed != true, "Protokol:Investment claimed");
    address[] memory path = new address[](2);
      path[0] = _USDT;
      // path[1] = _WETH;
      path[1] = kolToken;
      uint256 _investment = campaignDetails.campaignData.requiredInvestment;
      uint[] memory amount = UniswapV2Library.getAmountsOut(factory, _investment, path);

      amount = _swapRouter(_investment,amount[1], path);

    campaignDetails.campaignData.investmentClaimed = true;
    campaigns[_campaignId] = campaignDetails;
    emit ClaimKolInvestment(_campaignId, _investment, msg.sender);
    return true;
  }

  function setStakingPercentage(uint16 _stakingPerct) external onlyAdmin returns(bool)
  {
      //add checks for staking Percentage
      require(stakingPercentage < 90, "Protokol:Staking Percentage can't be greater than 90%");
      stakingPercentage = _stakingPerct;
      emit StakingPercentageUpdated(_stakingPerct , block.timestamp , msg.sender);
      return true;
  }
  //Give KOL TGE AMOUNT according to KOL's share.
  function claimTGEAmount(uint256 _campaignId) external{

  }
  function depositPreSaleTokens(uint256 _campaignId, uint256 _amount) external returns(bool){
    require(campaigns[_campaignId].tgeDetails.isTGE == true, "Protokol: TGE is not yet generated");
    require(campaigns[_campaignId].campaignData.campaignOwner == msg.sender ||
            campaigns[_campaignId].campaignData.secondOwner == msg.sender, "Protokol:Not campaign owner");

    address token = campaigns[_campaignId].campaignData.preSaleToken;
    bool ret_value = IERC20(token).transferFrom
                  (msg.sender, address(this), _amount * 10**IERC20(token).decimals());
    emit DepositPreSaleTokens(_campaignId, _amount, token, msg.sender);
    return ret_value;
    }
  function claimPreSaleTokens(uint256 _campaignId, uint256 progress, bytes32 r,
        bytes32 s,
        uint8 v,
        bytes32 msgHash) external returns(bool){
    // Add admin signature to this function
    // By adding a signature we make sure that KOL's progress is updated;
    //Check progress for only that vesting
    bytes32 msgHash = keccak256(abi.encodePacked(campaigns[_campaignId].campaignData.campaignOwner,
                      campaigns[_campaignId].campaignData.startDate, campaigns[_campaignId].campaignData.preSaleToken));
    recSig(r, s, v, msgHash);
    require(investedCapmaignDetails[msg.sender][_campaignId].investedAmt > 0,
             "Protokol:You have got no Investments in this campaign.");
    address preSale = campaigns[_campaignId].campaignData.preSaleToken;
    require(preSale!=address(0x0), "Protokol: PreSale token address is zero");
    require(campaigns[_campaignId].tgeDetails.isTGE == true, "Protokol:TGE not done");
    require(campaigns[_campaignId].campaignData.endTime <= block.timestamp , "Protokol:end Time not reached");
    require(blackListedKOL[msg.sender] != true, "Protokol: KOL is blacklisted can't claim");
    //check balance of contract of presale tokens against KOL's vesting reward
    if(campaigns[_campaignId].vestingData.isVestingInEnabled){
      require(block.timestamp - investedCapmaignDetails[msg.sender][_campaignId].lastVestingClaimed
               > campaigns[_campaignId].vestingData.vestingCycleDuration, "Protokol:You have already claimed your vesting");
      require(investedCapmaignDetails[msg.sender][_campaignId].numberOfVestingsClaimed <
              campaigns[_campaignId].vestingData.NumberOfvestings, "Protokol:You have claimed All your vestings");
      uint256 _vesting = (block.timestamp - investedCapmaignDetails[msg.sender][_campaignId]
                          .lastVestingClaimed)/campaigns[_campaignId].vestingData.vestingCycleDuration;
      _vesting = _vesting * (investedCapmaignDetails[msg.sender][_campaignId].vestingRewardPerCycle * 10 ** IERC20(preSale).decimals())/ 10 ** 18;
      require(IERC20(preSale).balanceOf(address(this)) >= _vesting
              , "Protokol: Not sufficient funds");
      uint256 _reward = (_vesting * progress)/100;
      bool transfered = IERC20(preSale)
              .transfer(msg.sender
                        , _reward);
      investedCapmaignDetails[msg.sender][_campaignId].numberOfVestingsClaimed = 
                              investedCapmaignDetails[msg.sender][_campaignId].numberOfVestingsClaimed + 1;
      investedCapmaignDetails[msg.sender][_campaignId].lastVestingClaimed = block.timestamp;
      //investedCapmaignDetails[msg.sender][_campaignId].leftOverReward += _vesting - _reward;
      emit ClaimPreSaleTokens(_campaignId, _vesting, preSale, msg.sender);
      return transfered;
    }
    else{
      investedCapmaignDetails[msg.sender][_campaignId].eligibleReward = 
              (investedCapmaignDetails[msg.sender][_campaignId].eligibleReward * 10 ** IERC20(preSale).decimals())/ 10 ** 18;
      require(IERC20(preSale).balanceOf(address(this)) >= 
              investedCapmaignDetails[msg.sender][_campaignId].eligibleReward
              , "Protokol: Not sufficient funds");
      uint256 eligibleRwd = (investedCapmaignDetails[msg.sender][_campaignId].eligibleReward * progress)/100;
      bool transfered = IERC20(preSale)
              .transfer(msg.sender
                        , eligibleRwd);
            emit ClaimPreSaleTokens(_campaignId, eligibleRwd
                                    , preSale, msg.sender);

      return transfered;
    }
  }
  //We also need to let him claim Back Investment when TGE date has past, and when max TGE change limit is reached. 
  function claimBackInvestmentByKOLForTge(uint256 _campaignId) external {
    require(blackListedKOL[msg.sender] != true, "Protokol: KOL is blacklisted can't claim");
    if(tgeUpdated[_campaignId] >= 2 || 
      (campaigns[_campaignId].tgeDetails.isTGE == false && 
      campaigns[_campaignId].tgeDetails.tgeDate <= block.timestamp)){
      address[] memory path = new address[](2);
      path[0] = _USDT;
      path[1] = kolToken;
      uint256 _investment = campaigns[_campaignId].campaignData.requiredInvestment;
      uint[] memory amount = UniswapV2Library.getAmountsOut(factory, _investment, path);
      amount = _swapRouter(_investment, amount[1], path);
      emit ClaimBackInvestmentForTge(_campaignId, investedCapmaignDetails[msg.sender][_campaignId].investedAmt, msg.sender);
      
    } 
  }
  // //naming 
  function claimBackInvestmentByKOL(uint256 _campaignId, uint256 progress,
                                bytes32 r, bytes32 s,uint8 v,bytes32 msgHash) 
  external {
    require(investedCapmaignDetails[msg.sender][_campaignId].investedAmt > 0,
             "Protokol:You have got no Investments in this campaign.");
    // Add signature
    require(campaigns[_campaignId].campaignData.endTime <= block.timestamp, "Protokol: You can't claim investment as Campaign has not ended");
    require(blackListedKOL[msg.sender] != true, "Protokol: KOL is blacklisted can't claim");    
    bytes32 msgHash = keccak256(abi.encodePacked(campaigns[_campaignId].campaignData.campaignOwner,
                      campaigns[_campaignId].campaignData.startDate, campaigns[_campaignId].tgeDetails.tgeDate));
   
    recSig(r, s, v, msgHash);

    //Calculation: Progress-> uint, Investment, penalty_per
    //if progress is 0 then apply penalty percentage
      //Investment * penalty_per = remaining amt.
      uint256 _invest = investedCapmaignDetails[msg.sender][_campaignId].investedAmt;
      if(progress == 0){
        _invest = _invest - (_invest * _penalty_per)/100;
      }
      address[] memory path = new address[](2);
      path[0] = _USDT;
      path[1] = kolToken;
      uint[] memory amount = UniswapV2Library.getAmountsOut(factory, _invest, path);
      amount = _swapRouter(_invest, amount[1], path);
    InvestedCampaign memory _investment = investedCapmaignDetails[msg.sender][_campaignId];
    campaigns[_campaignId].campaignData.requiredInvestment = campaigns[_campaignId].campaignData.requiredInvestment + 
                                                        investedCapmaignDetails[msg.sender][_campaignId].investedAmt;
    _investment.investedAmt = 0;
    _investment.investShare = 0;
    _investment.eligibleReward = 0;
    _investment.investShare = 0;
    _investment.vestingRewardPerCycle = 0;
    investedCapmaignDetails[msg.sender][_campaignId] = _investment;
    emit ClaimBackInvestment(_campaignId, progress,  _invest, msg.sender);

  }
  function setPenalty(uint16 _penalty) external onlyAdmin {
    require(_penalty < 100, "Protokol: Penalty should not be greater than 90%");
    _penalty_per = _penalty;
    emit SetPenalty(_penalty);
  }
  function blackListKOL(address _kol) external onlyAdmin {
    blackListedKOL[_kol] = true;

  }
  //Some concerns r
  function claimRewardForBlackListedKol() external{
    uint256[] memory _invested = kolInvestDetails[msg.sender];
    for(uint i =0; i<_invested.length;i++){
      IERC20(campaigns[_invested[i]].campaignData.preSaleToken).
      transfer(msg.sender, investedCapmaignDetails[msg.sender][_invested[i]].eligibleReward);
    } 
  }
  function setNumberOfCampaignsUpdations(uint256 _campaignId, uint16 _amount) external onlyAdmin{
    campaigns[_campaignId].tgeDetails.amountOfTGEDateUpdation = _amount;
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
    bool investmentClaimed;
    address preSaleToken;
    address campaignOwner;
    address secondOwner;
    uint256 requiredInvestment;
    uint256 marketingBudget;
    uint256 startDate;
    uint256 endTime;
    uint256 remainingInvestment;
    uint256 numberOfPostsReq;
    uint256 stakingAmount;
    string ipfsHash;
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
  }
  
  struct InvestedCampaign {
    address investorKOL;
    uint256 campaignNumber;
    uint256 investedAmt;
    uint256 investShare;
    uint256 eligibleReward;
    uint256 vestingRewardPerCycle;
    uint256 lastVestingClaimed;
    uint256 numberOfVestingsClaimed;
    //uint256 leftOverReward;
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
    address _depositedBy
  );

  event StakingPercentageUpdated(
    uint16 _stakingPerct,
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
  event ClaimBackInvestmentForTge(uint256 campaign_Id, uint256 _investment, address _kol);

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