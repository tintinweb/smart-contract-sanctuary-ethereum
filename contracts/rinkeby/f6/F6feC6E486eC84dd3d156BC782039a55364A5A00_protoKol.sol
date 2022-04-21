// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Structs.sol";
import "./errors.sol";
import "./interfaces/iKolToken.sol";
import "./interfaces/iPST.sol";
import "./interfaces/IERC20.sol";
contract protoKol is iProtoKol {
  //global variables
  uint256 campaignID;
  uint256 _kolID;
  uint16 stakingPercentage;
  address admin;
  address kolToken;
  uint256 maxTGE;
  uint256 private _penalty_per;
  //mappings
  mapping(address => KOL) private registeredKOL;
  mapping(address => bool) public blackListedKOL;
  mapping(address => uint256[]) public kolInvestDetails;
  mapping(uint256 => Campaign) public campaigns;
  mapping(address => mapping(uint256 =>InvestedCampaign)) public investedCapmaignDetails;
  mapping(uint256=>uint16) public tgeUpdated;
  //OCNSTRUCTOR
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
  function _updateCampaignDetails(CampaignDetailsInput memory _newCampaignInput,
  VestingDetailsInput memory _vestingInfoInput ,uint16 _tgePer) 
  private view 
  returns (CampaignDetails memory _newCampaign, VestingDetails memory _vestingInfo, TGE memory _tgeInfo){
    _newCampaign.startTime = block.timestamp;
    _newCampaign.preSaleToken = _newCampaignInput.preSaleToken;
    _newCampaign.requiredInvestment = _newCampaignInput.requiredInvestment;
    _newCampaign.campaignOwner = _newCampaignInput.campaignOwner;
    _newCampaign.secondOwner = _newCampaignInput.secondOwner;
    _newCampaign.ipfsHash = _newCampaignInput.ipfsHash;
    _newCampaign.marketingBudget = _newCampaignInput.marketingBudget;
    _newCampaign.maxInvest = _newCampaignInput.maxInvest;
    _newCampaign.numberOfPostsReq = _newCampaignInput.numberOfPostsReq;
    _newCampaign.endTime =  _newCampaignInput.endTime * 1 days;
    _newCampaign.endTime = block.timestamp + _newCampaign.endTime;
    _newCampaign.remainingInvestment = _newCampaignInput.requiredInvestment;
    _newCampaign.stakingAmount = (stakingPercentage * _newCampaign.marketingBudget)/100;
    _vestingInfo.isVestingInEnabled = _vestingInfoInput.isVestingInEnabled;
    _vestingInfo.NumberOfvestings = _vestingInfoInput.NumberOfvestings;
    _vestingInfo.vestingCycleDuration = _vestingInfoInput.vestingCycleDuration;
    _vestingInfo.vestingCycleDuration = _vestingInfo.vestingCycleDuration * 1 days; 

    if(_vestingInfo.isVestingInEnabled == true ) 
        {
          require(_vestingInfo.NumberOfvestings != 0 && _vestingInfo.vestingCycleDuration != 0
                  , "Protokol: Number of Vestings or Cycle duration can't be zero");
          _tgeInfo.tgePercentage = _tgePer;
          _tgeInfo.isTGE = false;
          _tgeInfo.tgeTime = _vestingInfo.vestingCycleDuration + block.timestamp;
          uint256 _deductedBudget = _newCampaign.marketingBudget - _newCampaign.stakingAmount;
          _tgeInfo.tgeAmount = (_tgeInfo.tgePercentage * _deductedBudget) /100 ;
          _vestingInfo.vestingCycleDuration = _vestingInfo.vestingCycleDuration * 1 days; 
           _vestingInfo.vestingAmtPerCycle = _deductedBudget - _tgeInfo.tgeAmount /_vestingInfo.NumberOfvestings; 
        }

    else if(_vestingInfo.isVestingInEnabled == false ) 
    {
      require(_vestingInfo.NumberOfvestings == 0 && _vestingInfo.vestingCycleDuration == 0, 
              "Protokol: Vesting is not enabled");
    } 

  }
  function recoverSig(bytes memory _signature, bytes32  msgHash) public pure returns(address){
        (bytes32 r, bytes32 s, uint8 v) = splitSign(_signature);
        address signer = ecrecover(msgHash, v, r, s);
        return signer;
  }
  function recSig(bytes32 r, bytes32 s, uint8 v, bytes32 msgHash) public view{
    address signer = ecrecover(msgHash, v, r, s);
    require(signer==admin, "Protokol:Invalid Signer");
  }
  function splitSign(bytes memory _signature) public pure returns (bytes32 r, bytes32 s, uint8 v){
        require(_signature.length == 65,"Invalid signature");
        assembly{
            r := mload(add(_signature,32))
            s := mload(add(_signature,64))
            v:= mload(add(_signature,96))
  }
  }
  function registerKOL(string memory _name, string memory _ipfsHash) external returns(bool)
  {
    require(registeredKOL[msg.sender].kolWallet == address(0), "Protokol: KOL already exists");
    require(keccak256(bytes(_name)) != keccak256(bytes("")), "Protokol: Kindly enter a valid name");
    require(keccak256(bytes(_ipfsHash)) != keccak256(bytes("")), "Protokol: Empty Ipfs Hash");
      KOL memory _newKOL;
      _newKOL.kolWallet = msg.sender;
      _newKOL.name = _name;
      _newKOL.ipfsHash = _ipfsHash;
      _newKOL.kolID = _kolID;
      registeredKOL[msg.sender] = _newKOL;
      _kolID++;
      emit KOLAdded(_newKOL);
      return true;
  }

  function retriveKOL(address _kol) public view returns(KOL memory kol)
  {
    return registeredKOL[_kol];
  }

  function getKolInvestedCampaigns(address _kol) public view returns(uint256[] memory)
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
        uint16 _tgePer
        // bytes32 r,
        // bytes32 s,
        // uint8 v,
        // bytes32 msgHash
    ) external returns(uint256){
      //Add signature
        //recSig(r, s, v, msgHash);
        Campaign memory _campaign;
        _campaign.campaignNumber = campaignID;
        TGE memory _tgeInfo;
        CampaignDetails memory _newCampaign;
        VestingDetails memory _vestingInfo;
        (_newCampaign, _vestingInfo, _tgeInfo) = _updateCampaignDetails(_newCampaignInput, _vestingInfoInput, _tgePer);
       _campaign.campaignData = _newCampaign; 
       _campaign.vestingData =_vestingInfo;
       _campaign.tgeDetails = _tgeInfo;
       campaigns[campaignID] = _campaign;
       emit CampaignCreated(_campaign);
       uint256 _campaign_Id = campaignID;
       campaignID++;
       return _campaign_Id;
    }

  function retriveCampaign(uint256 _campaignID)
    public
    view
    returns (Campaign memory campaignDetails){
    return campaigns[_campaignID];
  }


  function updateCampaign(
    uint256 _campaignID,
    CampaignDetailsInput memory _newCampaignInput ,
    VestingDetailsInput memory _vestingInfoInput ,
    uint16 _tgePer
  ) external returns (bool) {
    Campaign memory campaignDetails = retriveCampaign(_campaignID);
    require(campaignDetails.campaignData.campaignOwner == msg.sender || 
            campaignDetails.campaignData.secondOwner == msg.sender, "Protkol:Unauthorized Owner");
    require(campaignDetails.campaignData.remainingInvestment == campaignDetails.campaignData.requiredInvestment, 
            "Protkol: Investment Started you can update the campaign");
    CampaignDetails memory _newCampaign;
    VestingDetails memory _vestingInfo;
    TGE memory _tgeInfo;
    (_newCampaign, _vestingInfo, _tgeInfo) = _updateCampaignDetails(_newCampaignInput, _vestingInfoInput, _tgePer);
    campaignDetails.campaignData = _newCampaign;
    campaignDetails.vestingData = _vestingInfo;
    campaignDetails.tgeDetails  = _tgeInfo;
    campaigns[_campaignID] = campaignDetails;
    if(tgeUpdated[_campaignID] <= maxTGE)
    {
      campaignDetails.tgeDetails  = _tgeInfo;
      tgeUpdated[_campaignID] = tgeUpdated[_campaignID] + 1;
    }
    emit CampaignDetailsUpdated(campaignDetails);
    return true;
  }

  function investInCampaign(uint256 _campaignID , uint256 _investment) external returns (bool){
    InvestedCampaign memory investDetails = getInvestedCampaigns(msg.sender,_campaignID);
    KOL memory _kolData = retriveKOL(msg.sender);
    require(_kolData.kolWallet != address(0) && !blackListedKOL[msg.sender], "Protokol: KOL is not registered");
    require(investDetails.investedAmt == 0, "Protokol: Already Invested");

    Campaign memory campaignDetails = retriveCampaign(_campaignID); 
    uint256 maxInvest = (campaignDetails.campaignData.requiredInvestment *campaignDetails.campaignData.maxInvest)/100;

    require(_investment < maxInvest, "Protokol: Amount is above Investment");
    require(campaignDetails.campaignData.remainingInvestment != 0, "Protokol: Investment is attained");

    InvestedCampaign memory _investmentDetails;
    _investmentDetails.tgeClaimed = false;
    _investmentDetails.investorKOL = msg.sender;
    _investmentDetails.campaignNumber = campaignDetails.campaignNumber;
    _investmentDetails.investedAmt = _investment;
    uint256 investmentShare = (_investment*100)/campaignDetails.campaignData.requiredInvestment;
    _investmentDetails.investShare = investmentShare;
      uint256 _deductedBudget = campaignDetails.campaignData.marketingBudget- campaignDetails.campaignData.stakingAmount;
    _investmentDetails.eligibleReward = (investmentShare*_deductedBudget)/100;
    _investmentDetails.vestingRewardPerCycle =( investmentShare * campaignDetails.vestingData.vestingAmtPerCycle)/100;
    _investmentDetails.lastVestingClaimed = campaignDetails.campaignData.endTime;
    _investmentDetails.numberOfVestingsClaimed = 0;
    campaignDetails.campaignData.remainingInvestment = campaignDetails.campaignData.remainingInvestment - _investment;
    _investment = _investment*10**IKOLT(kolToken).decimals();
    
    IKOLT(kolToken).transferFrom(msg.sender ,address(this),_investment);
    
    kolInvestDetails[msg.sender].push(_campaignID);

    investedCapmaignDetails[msg.sender][_campaignID] = _investmentDetails;

    campaigns[_campaignID] = campaignDetails;
    return true; 
  }

  function getInvestedCampaigns(address _investor,uint256 _campaignID) public view returns(InvestedCampaign memory investDetails )
  {
    return investedCapmaignDetails[_investor][_campaignID];
  }

  function generateTGE(uint256 _campaignID) external returns (bool)
  {
    Campaign memory campaignDetails = retriveCampaign(_campaignID);
    require(campaignDetails.tgeDetails.isTGE == false, "Protokol: TGE generated");

    require(campaignDetails.campaignData.campaignOwner == msg.sender 
            || campaignDetails.campaignData.secondOwner == msg.sender,
            "Protokol: UnAuthorized Owner");

    require(block.timestamp <= campaignDetails.tgeDetails.tgeTime, "Protokol: Time has passed");

      //uint256 tgeAmt  = (campaignDetails.tgePercentage * campaignDetails.marketingBudget) /100 ;
    campaignDetails.tgeDetails.tgeAmount  = campaignDetails.tgeDetails.tgeAmount*10**IPST(campaignDetails.campaignData.preSaleToken).decimals();
    IPST(campaignDetails.campaignData.preSaleToken).transferFrom(msg.sender ,address(this),campaignDetails.tgeDetails.tgeAmount);
    VestingDetails memory _vestingInfo;
    _vestingInfo = campaignDetails.vestingData;
    _vestingInfo.vestingDetails[0] = block.timestamp;
    _vestingInfo.vestingDetails[1] =  block.timestamp + _vestingInfo.vestingCycleDuration;
    _vestingInfo.vestingDetails[2] = 0;
    _vestingInfo.vestingDetails[3] = 0;  
    //transferFrom PST to this contract
    campaignDetails.tgeDetails.isTGE = true;
    campaigns[_campaignID] = campaignDetails;
    emit TGEDeposited( _campaignID ,campaignDetails.tgeDetails.tgeAmount ,block.timestamp, msg.sender);
    return true;
    
  }

  function claimKOLInvestment(uint256 _campaignID) external returns (bool)
  {
    Campaign memory campaignDetails = retriveCampaign(_campaignID); 
    require(campaignDetails.tgeDetails.isTGE == true, "Protokol: TGE not generated");
    require(campaignDetails.campaignData.remainingInvestment == 0, "Protokol: Investment not Attained");
    require(campaignDetails.campaignData.campaignOwner == msg.sender 
            || campaignDetails.campaignData.secondOwner == msg.sender, "Protokol: UnAuthorized Owner");
    require(campaignDetails.campaignData.remainingInvestment == 0, "Protokol:Investment is not Attained");
    require(campaignDetails.campaignData.investmentClaimed != true, "Protokol:Investment claimed");

    uint256 _investment = campaignDetails.campaignData.requiredInvestment*10**IKOLT(kolToken).decimals();
    IKOLT(kolToken).transfer(campaignDetails.campaignData.campaignOwner,_investment);
    campaignDetails.campaignData.investmentClaimed = true;
    campaigns[_campaignID] = campaignDetails;
    return true;

  }

  function seStakingPercentage(uint16 _stakingPerct) external onlyAdmin returns(bool)
  {
      stakingPercentage = _stakingPerct;
      emit StakingPercentageUpdated(_stakingPerct , block.timestamp , msg.sender);
      return true;
  }
  function depositPreSaleTokens(uint256 campaign_Id, address token) external returns(bool){
      require(campaigns[campaign_Id].campaignData.campaignOwner == msg.sender ||
              campaigns[campaign_Id].campaignData.secondOwner == msg.sender, "Not campaign owner");
      bool ret_value = IERC20(token).transferFrom
                    (msg.sender, address(this), campaigns[campaign_Id].campaignData.marketingBudget);
      return ret_value;
    }
  function claimPreSaleTokens(uint256 _campaignId 
        // bytes32 r,
        // bytes32 s,
        // uint8 v,
        // bytes32 msgHash
        ) external returns(bool){
    // Add admin signature to this function
    // By adding a signature we make sure that KOL's progress is updated;
    //recSig(r, s, v, msgHash);
    require(investedCapmaignDetails[msg.sender][_campaignId].investedAmt > 0,
             "Protokol:You have got no Investments in this campaign.");
    require(campaigns[_campaignId].campaignData.endTime <= block.timestamp,
             "Protokol:Campaign time has not ended yet.");
    //check balance of contract of presale tokens against KOL's vesting reward
    if(campaigns[_campaignId].vestingData.isVestingInEnabled){
      require(block.timestamp - investedCapmaignDetails[msg.sender][_campaignId].lastVestingClaimed
               > campaigns[_campaignId].vestingData.vestingCycleDuration, "Protokol:You have already claimed your vesting");
      require(investedCapmaignDetails[msg.sender][_campaignId].numberOfVestingsClaimed <
              campaigns[_campaignId].vestingData.NumberOfvestings, "Protokol:You have claimed All your vestings");
      uint256 _vesting = (block.timestamp - investedCapmaignDetails[msg.sender][_campaignId]
                          .lastVestingClaimed)/campaigns[_campaignId].vestingData.vestingCycleDuration;
      require(IERC20(campaigns[_campaignId].campaignData.preSaleToken).balanceOf(msg.sender) >= _vesting
              , "Protokol: Not sufficient funds");
      bool transfered = IERC20(campaigns[_campaignId].campaignData.preSaleToken)
              .transfer(msg.sender
                        , _vesting);
      investedCapmaignDetails[msg.sender][_campaignId].numberOfVestingsClaimed = 
                              investedCapmaignDetails[msg.sender][_campaignId].numberOfVestingsClaimed + 1;
      investedCapmaignDetails[msg.sender][_campaignId].lastVestingClaimed = block.timestamp;
      return transfered;
    }
    else{
      require(IERC20(campaigns[_campaignId].campaignData.preSaleToken).balanceOf(msg.sender) >= 
              investedCapmaignDetails[msg.sender][_campaignId].eligibleReward
              , "Protokol: Not sufficient funds");
      bool transfered = IERC20(campaigns[_campaignId].campaignData.preSaleToken)
              .transfer(msg.sender
                        , investedCapmaignDetails[msg.sender][_campaignId].eligibleReward);
      return transfered;
    }
  }
  function claimBackInvestment(uint256 _campaignId, uint256 progress
        //                         bytes32 r,
        // bytes32 s,
        // uint8 v,bytes32 msgHash
        ) external {

    require(investedCapmaignDetails[msg.sender][_campaignId].investedAmt > 0,
             "Protokol:You have got no Investments in this campaign.");
    require(campaigns[_campaignId].campaignData.endTime >= block.timestamp,
            "Protokol:Campaign time has ended.");
    // Add signature
    // recSig(r, s, v, msgHash);

    //Calculation: Progress-> uint, Investment, penalty_per
    //if progress is 0 then apply penalty percentage
      //Investment * penalty_per = remaining amt.
    if(tgeUpdated[_campaignId] >= maxTGE){
      IKOLT(kolToken).transfer(msg.sender, investedCapmaignDetails[msg.sender][_campaignId].investedAmt);
    }
    else{
      if(progress == 0){
        investedCapmaignDetails[msg.sender][_campaignId].investedAmt = 
              investedCapmaignDetails[msg.sender][_campaignId].investedAmt - investedCapmaignDetails[msg.sender][_campaignId].investedAmt 
                                                                              * _penalty_per/100 ;
      }
      IKOLT(kolToken).transfer(msg.sender, investedCapmaignDetails[msg.sender][_campaignId].investedAmt);
    }
    InvestedCampaign memory _investment = investedCapmaignDetails[msg.sender][_campaignId];
    _investment.investedAmt = 0;
    _investment.eligibleReward = 0;
    _investment.investShare = 0;
    _investment.vestingRewardPerCycle = 0;
  }
  function setMaximumTGEAllowance(uint256 _tge) external onlyAdmin{
    maxTGE = _tge;
  }
  function setpenalty(uint256 _penalty) external onlyAdmin {
    _penalty_per = _penalty;
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
    uint256 endTime;
    uint256 maxInvest;
    uint256 numberOfPostsReq;
    string ipfsHash;
  } 

  struct CampaignDetails{
    bool investmentClaimed;
    bool claimBackInvestment;
    address preSaleToken;
    address campaignOwner;
    address secondOwner;
    uint256 requiredInvestment;
    uint256 marketingBudget;
    uint256 startTime;
    uint256 endTime;
    uint256 remainingInvestment;
    uint256 maxInvest;
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
    uint256[] vestingDetails;
  }
  struct TGE {
    bool isTGE;
    uint16 tgePercentage;
    uint256 tgeTime;
    uint256 tgeAmount;
  }
  
  struct InvestedCampaign {
    bool tgeClaimed;
    address investorKOL;
    uint256 campaignNumber;
    uint256 investedAmt;
    uint256 investShare;
    uint256 eligibleReward;
    uint256 vestingRewardPerCycle;
    uint256 lastVestingClaimed;
    uint256 numberOfVestingsClaimed;
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
}