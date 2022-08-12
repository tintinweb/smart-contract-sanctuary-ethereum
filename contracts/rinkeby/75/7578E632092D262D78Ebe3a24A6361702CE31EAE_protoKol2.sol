// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Structs.sol";
import "./errors.sol";
import "./interfaces/IERC20.sol";
import "contracts/libraries/UniLib.sol";

// import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// import "hardhat/console.sol";

contract protoKol2 is iProtoKol {
    //global variables
    uint256 campaignID;
    uint256 _kolID;
    uint16 public stakingPercentage = 500;
    uint256 public penaltyAmount;
    address public admin;
    uint16 public _penalty_per = 500;
    uint16 public _transactionPer = 50;
    uint16 public _platformPer = 50;
    // address private _USDT = 0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02;
    // address private _stakingContract = 0x3d6E9e408AF18b65F95EA0F51A82C99dA527347c;
    //IN Matic
    // address private constant UNISWAP_ROUTER_ADDRESS = 0x8954AfA98594b838bda56FE4C12a09D7739D179b;
    // address private factory = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;
    // address private _USDT = 0x9E6Fa3FB6e1E2AA49B709f7dd91fdC722e96bAD7;
    // address private _stakingContract = 0x76d0869a7F4528b7da5CF5aA90aa1B8554D0E864;
    //In Binance
    // address private _USDT = 0xc7660d9e1C355eAcEeA2bA5E05783fa7379Ee225;
    // address private _stakingContract = 0x85e1a1dAc1D3a742E6FA8D214996af7781DCcA76;

    address private _USDT;
    address private _stakingContract;

    address private _vault = 0xB4eA3D4F74520Fc11fF14810D8219FE309a0c265;
    //mappings
    mapping(address => KOL) private registeredKOL;
    mapping(address => mapping(uint256 => bool)) public blackListedKOL;
    mapping(address => mapping(uint256 => bool)) public kolInvestDetails;
    mapping(uint256 => Campaign) public campaigns;
    mapping(address => mapping(uint256 => InvestedCampaign)) public investedCampaignDetails;

    // mapping(uint256=>uint16) public tgeUpdated;
    //CONSTRUCTOR
    constructor(
        address _admin,
        address _usdt,
        address _stakingcontract
    ) {
        admin = _admin;
        _USDT = _usdt;
        _stakingContract = _stakingcontract;
    }

    //modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Protokol:Only Admin function");
        _;
    }

    /**
   @dev Check for signer. Signer == admin.
   @param r - Signature
   @param s - Signature
   @param v - Signature
   @param msgHash - Hashed Message, consisting of different parameters.
   */
    function recSig(
        bytes32 r,
        bytes32 s,
        uint8 v,
        bytes32 msgHash
    ) internal {
        address signer = ecrecover(msgHash, v, r, s);
        require(signer == admin, "Protokol:Invalid Signer");
    }

    /**
   @dev Register KOL and add into registered KOL mapping.
   @param _name - Name of the KOL
   @param _ipfsHash - details about KOL in the form of ipfsHash
   */
    function registerKOL(string memory _name, string memory _ipfsHash) external {
        require(
            registeredKOL[msg.sender].kolWallet == address(0) &&
                keccak256(bytes(_name)) != keccak256(bytes("")) &&
                keccak256(bytes(_ipfsHash)) != keccak256(bytes("")),
            "Protokol:Invalid Details"
        );
        KOL memory _newKol = KOL({ kolWallet: msg.sender, name: _name, ipfsHash: _ipfsHash, kolID: _kolID });
        registeredKOL[msg.sender] = _newKol;
        _kolID++;
        emit KOLAdded(_newKol);
    }

    /**
   @dev Retrieve KOL details by its address.
   @param _kol - kol address
   */
    function retriveKOL(address _kol) public view returns (KOL memory kol) {
        return registeredKOL[_kol];
    }

    /**
   @dev Update KOL details.
   @param _name - Name of the KOL
   @param _ipfsHash - details about KOL in the form of ipfsHash
   */
    function updateKolData(string memory _name, string memory _ipfsHash) external {
        require(
            registeredKOL[msg.sender].kolWallet != address(0) &&
                keccak256(bytes(_name)) != keccak256(bytes("")) &&
                keccak256(bytes(_ipfsHash)) != keccak256(bytes("")),
            "Protokol:Invalid Details"
        );
        registeredKOL[msg.sender].name = _name;
        registeredKOL[msg.sender].ipfsHash = _ipfsHash;
    }

    /**
   @dev Create Campaign, all the initial campaign's amount calculation is done here, like TGE Amount, Vesting Amount Per Cycle, Staking
   Vesting Reward Per Cycle etc.
   @notice All amounts will be entered in 18 decimal places or in form of wei. Like if you want to keep marketing budget as 1000, so you
   need to pass 1000 * 10^18
   @param _newCampaignInput - Campaign details struct containing multiple values which are used in later functions
   @param _vestingInfoInput - Vesting details
   @param _tgeDate - Time before you can generate TGE
   @param _tgePer - Percentage of Amount taken out from marketing Budget as TGE Amount. The Percentage will be passed in 2 decimals, like
   if you want to keep TGE Per as 10% then you will enter 1000.
   @param r - Signature
   @param s - Signature
   @param v - Signature
   */
    function createCampaign(
        CampaignDetailsInput memory _newCampaignInput,
        VestingDetailsInput memory _vestingInfoInput,
        uint256 _tgeDate,
        uint16 _tgePer,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external returns (uint256) {
        //Add signature
        bytes32 msgHash = keccak256(
            abi.encodePacked(_newCampaignInput.campaignOwner, _newCampaignInput.startDate, _tgeDate)
        );
        recSig(r, s, v, msgHash);
        //add TGE Per
        require(_newCampaignInput.campaignOwner != address(0x0), "Protokol:OwnerAddr=zero");
        require(_tgeDate >= _newCampaignInput.startDate + 21 * 1 days, "Protokol:TGE<21 days start date");
        require(
            _tgeDate <= _newCampaignInput.startDate + (_newCampaignInput.endTime - 14) * 1 days,
            "Protokol:TGE>14 days end date"
        );
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
        _newCampaign.marketingBudget = _newCampaignInput.marketingBudget;
        _newCampaign.numberOfPostsReq = _newCampaignInput.numberOfPostsReq;
        _newCampaign.endDate = _newCampaignInput.startDate + _newCampaignInput.endTime * 1 days;
        _newCampaign.remainingInvestment = _newCampaign.requiredInvestment;
        _newCampaign.stakingAmount = (stakingPercentage * _newCampaign.marketingBudget) / 10000;
        _vestingInfo.isVestingInEnabled = _vestingInfoInput.isVestingInEnabled;
        _vestingInfo.NumberOfvestings = _vestingInfoInput.NumberOfvestings;
        _vestingInfo.vestingCycleDuration = _vestingInfoInput.vestingCycleDuration;
        //Tge Percentages going in 2 decimal places means -> 0.1% will be entered as 10
        _tgeInfo.tgePercentage = _tgePer;
        _tgeInfo.amountOfTGEDateUpdation = 2;
        _tgeInfo.isTGE = false;
        uint256 _deductedBudget = _newCampaign.marketingBudget - _newCampaign.stakingAmount;
        //console.log("Deducted Budget",_deductedBudget);
        _tgeInfo.tgeDate = _tgeDate;
        //Include IMO part, platform revenue. Transfer the amount to project Treasury.
        if (_vestingInfo.isVestingInEnabled == true) {
            require(
                _vestingInfo.NumberOfvestings != 0 && _vestingInfo.vestingCycleDuration != 0,
                "Protokol:NOV and CD!=0 in vesting"
            );
            _tgeInfo.tgeAmount = (_tgeInfo.tgePercentage * _deductedBudget) / 10000;
            //console.log("TGE Amount",_tgeInfo.tgeAmount);
            _vestingInfo.vestingCycleDuration = _vestingInfo.vestingCycleDuration * 1 days;
            _vestingInfo.vestingAmtPerCycle = ((_deductedBudget - _tgeInfo.tgeAmount) / _vestingInfo.NumberOfvestings);
            //console.log("Vesting Amt/cycle",_vestingInfo.vestingAmtPerCycle);
        } else if (_vestingInfo.isVestingInEnabled == false) {
            _tgeInfo.tgePercentage = 10000;
            _tgeInfo.tgeAmount = _deductedBudget;
        }
        _campaign.campaignData = _newCampaign;
        _campaign.vestingData = _vestingInfo;
        _campaign.tgeDetails = _tgeInfo;
        campaigns[campaignID] = _campaign;
        emit CampaignCreated(_campaign);
        campaignID++;
        return campaignID;
    }

    function retriveCampaign(uint256 _campaignId) public view returns (Campaign memory campaignDetails) {
        return campaigns[_campaignId];
    }

    /**
   @dev Update Campaign, only updates Tge Date and PreSale Token. TGE can only be updated twice hence first time it will be taken 1 months
   forward and next time it will be 2 months.
   @notice Only Campaign Owner can call this function. TGE Date > 14 days from start Date and < 21 days before End date.This can only be
   called before TGE Generation
   @param _campaignId - Campaign details struct containing multiple values which are used in later functions
   @param _tgeDate - Time before you can generate TGE
   @param _preSaletoken - Percentage of Amount taken out from marketing Budget as TGE Amount
   */
    function updateCampaign(
        uint256 _campaignId,
        uint256 _tgeDate,
        address _preSaletoken
    ) external {
        Campaign memory campaignDetails = retriveCampaign(_campaignId);
        require(
            campaignDetails.campaignData.campaignOwner == msg.sender ||
                campaignDetails.campaignData.secondOwner == msg.sender,
            "Protkol:UnAuthorized"
        );
        require(campaignDetails.tgeDetails.isTGE == false, "Protokol:TGE generated");
        require(_tgeDate >= campaignDetails.campaignData.startDate + 21 * 1 days, "Protokol:TGE>21 days start date");
        require(_tgeDate + 14 days <= campaignDetails.campaignData.endDate, "Protokol:TGE>14 days end Date");
        if (campaignDetails.tgeDetails.amountOfTGEDateUpdation >= 1) {
            require(
                _tgeDate - campaignDetails.tgeDetails.tgeDate <=
                    (30 + campaignDetails.tgeDetails.TGEUpdationDone * 30) * 1 days,
                "Protokol:Tge>mentioned time"
            );
            // require(_tgeDate + 14 days <= campaignDetails.campaignData.endDate,"Protokol:TGE date should be prior of 14 days of end Date");
            campaigns[_campaignId].tgeDetails.tgeDate = _tgeDate;
            campaigns[_campaignId].tgeDetails.amountOfTGEDateUpdation -= 1;
            campaigns[_campaignId].tgeDetails.TGEUpdationDone += 1;
        }
        if (_preSaletoken != _USDT) campaigns[_campaignId].campaignData.preSaleToken = _preSaletoken;
        emit CampaignDetailsUpdated(campaigns[_campaignId]);
    }

    //Put Transaction fees on KOL Investment
    //Enter Amount in ETH
    /**
  @dev Invest In Campaign - Invest in campaign in either usdt, KOL Investment details struct will be updated, like
  its investment share, reward, vesting reward etc.
  @notice This is a signed function by admin
  @param _campaignId - Campaign Id
  @param _investment - Amount of Invested Tokens, can be only KOL or USDT
  @param sign - signature struct, containing r,s,v.
   */
    function investInCampaign(
        uint256 _campaignId,
        uint256 _investment,
        Signature calldata sign
    ) external {
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                campaigns[_campaignId].campaignData.campaignOwner,
                campaigns[_campaignId].campaignData.startDate,
                _USDT,
                _investment
            )
        );

        // console.log("From Contract, Msg hash", msgHash);
        recSig(sign.r, sign.s, sign.v, msgHash);
        InvestedCampaign memory investDetails = investedCampaignDetails[msg.sender][_campaignId];
        KOL memory _kolData = retriveKOL(msg.sender);
        require(
            _kolData.kolWallet != address(0) && !blackListedKOL[msg.sender][_campaignId],
            "Protokol:KOL not registered"
        );
        // require(_investment > 0, "Protokol:Investment should be greater than zero");
        console.log("investedAmt", investDetails.investedAmt);
        require(investDetails.investedAmt == 0, "Protokol:Already invested");
        require(
            block.timestamp <= campaigns[_campaignId].campaignData.endDate,
            "Protokol:Campaign has ended, can't invest"
        );
        require(blackListedKOL[msg.sender][_campaignId] != true, "Protokol:KOL blacklisted");

        // Campaign memory campaignDetails = retriveCampaign(_campaignId);
        if (campaigns[_campaignId].campaignData.preSaleToken != _USDT) {
            uint256 _totalInvestment = _investment;
            _investment = (_investment * (10000 - _transactionPer)) / 10000;

            require(
                _investment <= campaigns[_campaignId].campaignData.remainingInvestment,
                "Protokol:Amount>Investment"
            );

            uint256 _investmentInToken = (_investment * 10**IERC20(_USDT).decimals()) / 10**18;
            _safeTransferFrom(_USDT, msg.sender, address(this), _investmentInToken);
            _safeTransferFrom(
                _USDT,
                msg.sender,
                _vault,
                (_totalInvestment * 10**IERC20(_USDT).decimals()) / 10**18 - _investmentInToken
            );
        }

        // uint256 maxInvest = (campaignDetails.campaignData.requiredInvestment *campaignDetails.campaignData.maxInvest)/100;
        investDetails.investorKOL = msg.sender;
        investDetails.campaignNumber = campaigns[_campaignId].campaignNumber;
        ////console.log("Investment here->",_investment);
        investDetails.investedAmt = _investment;

        investDetails.investShare =
            (investDetails.investedAmt * 100 * 10**18) /
            campaigns[_campaignId].campaignData.requiredInvestment;

        // console.log("investDetails.investedAmt ", investDetails.investedAmt);
        //make changes in this line
        // investDetails.investShare = investmentShare;
        //  console.log("Investment share->", investmentShare);

        if (campaigns[_campaignId].vestingData.isVestingInEnabled == true) {
            // console.log("Investment eligible reward->", investDetails.eligibleReward);
            investDetails.vestingRewardPerCycle =
                (investDetails.investShare * campaigns[_campaignId].vestingData.vestingAmtPerCycle) /
                10**20;
        }

        //console.log("Investment Vesting->", investDetails.vestingRewardPerCycle);
        investDetails.eligibleReward =
            (investDetails.investShare *
                (campaigns[_campaignId].campaignData.marketingBudget -
                    campaigns[_campaignId].campaignData.stakingAmount)) /
            (100 * 10**18);
        // console.log("Investment eligible reward->", investDetails.eligibleReward);
        campaigns[_campaignId].campaignData.remainingInvestment =
            campaigns[_campaignId].campaignData.remainingInvestment -
            _investment;
        // console.log("Investment here->", campaignDetails.campaignData.remainingInvestment);

        kolInvestDetails[msg.sender][_campaignId] = true;
        investedCampaignDetails[msg.sender][_campaignId] = investDetails;
        // campaigns[_campaignId] = campaignDetails;
        emit InvestInCampaign(_campaignId, _investment, investDetails.investShare, msg.sender);
    }

    //Only TGE amount will be multiply by 10** as we are not sure about presale Token decimals
    /**
  @dev Generate TGE - Function generates TGE by transferring TGE Amount into contract to use later.
  @param _campaignId - Campaign Id for which TGE is being generated.
  @param token - Pre Sale Token Address
   */
    function generateTGE(uint256 _campaignId, address token) external {
        require(campaigns[_campaignId].tgeDetails.isTGE == false, "Protokol:TGE done");

        require(
            campaigns[_campaignId].campaignData.campaignOwner == msg.sender ||
                campaigns[_campaignId].campaignData.secondOwner == msg.sender,
            "Protokol:UnAuthorized"
        );

        if (campaigns[_campaignId].campaignData.preSaleToken == address(0x0)) {
            require(token != _USDT, "Protokol:can't set token=USDT");
            campaigns[_campaignId].campaignData.preSaleToken = token;
        }
        require(campaigns[_campaignId].campaignData.preSaleToken == token, "Protokol:Token!=PST");
        require(block.timestamp <= campaigns[_campaignId].tgeDetails.tgeDate, "Protokol:Time has passed");
        //uint256 tgeAmt  = (campaignDetails.tgePercentage * campaignDetails.marketingBudget) /100 ;
        require(campaigns[_campaignId].campaignData.preSaleToken != address(0x0), "Protokol:PST=zero");
        // campaigns[_campaignId].tgeDetails.tgeAmount =
        //     (campaigns[_campaignId].tgeDetails.tgeAmount *
        //         10**IERC20(campaigns[_campaignId].campaignData.preSaleToken).decimals()) /
        //     10**18;

        uint256 markBudge = campaigns[_campaignId].campaignData.marketingBudget;
        //* 10**IERC20(token).decimals()) /10**18;
        // console.log("TGE AMount", campaigns[_campaignId].tgeDetails.tgeAmount);
        uint256 staking = campaigns[_campaignId].campaignData.stakingAmount;
        // * 10**IERC20(token).decimals()) / 10**18;

        // IERC20(campaigns[_campaignId].campaignData.preSaleToken).transferFrom(msg.sender, _stakingContract, staking);
        _safeTransferFrom(
            campaigns[_campaignId].campaignData.preSaleToken,
            msg.sender,
            _stakingContract,
            (staking * 10**IERC20(token).decimals()) / 10**18
        );

        _safeTransferFrom(
            campaigns[_campaignId].campaignData.preSaleToken,
            msg.sender,
            _vault,
            (((markBudge * 10**IERC20(token).decimals()) / 10**18) * _platformPer) / 10000
        );

        _safeTransferFrom(
            campaigns[_campaignId].campaignData.preSaleToken,
            msg.sender,
            address(this),
            (campaigns[_campaignId].tgeDetails.tgeAmount *
                10**IERC20(campaigns[_campaignId].campaignData.preSaleToken).decimals()) / 10**18
        );

        campaigns[_campaignId].campaignData.presaleAmount += campaigns[_campaignId].tgeDetails.tgeAmount;

        // campaigns[_campaignId].campaignData.presaleAmount +=
        //     (campaigns[_campaignId].tgeDetails.tgePercentage * campaigns[_campaignId].campaignData.marketingBudget) /
        //     10000;

        // console.log(
        //     "400 campaigns[_campaignId].campaignData.presaleAmount",
        //     campaigns[_campaignId].campaignData.presaleAmount
        // );

        VestingDetails memory _vestingInfo;
        _vestingInfo = campaigns[_campaignId].vestingData;
        //transferFrom PST to this contract
        campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget +=
            ((campaigns[_campaignId].tgeDetails.tgeAmount + staking) *
                campaigns[_campaignId].campaignData.requiredInvestment) /
            markBudge;

        // console.log(
        //     "campaigns[_campaignId].campaignData.requiredInvestment)/markBudge",
        //     campaigns[_campaignId].campaignData.requiredInvestment / markBudge
        // );

        // console.log(
        //     "(campaigns[_campaignId].tgeDetails.tgeAmount + staking)",
        //     (campaigns[_campaignId].tgeDetails.tgeAmount + staking)
        // );
        // console.log(
        //     "enteredInvestmentAgainstMarketingBudget",
        //     campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget
        // );

        campaigns[_campaignId].tgeDetails.isTGE = true;
        campaigns[_campaignId].tgeDetails.tgeDate = block.timestamp;
        //console.log(campaignDetails.tgeDetails.isTGE);
        // campaigns[_campaignId] = campaignDetails;
        emit TGEDeposited(
            _campaignId,
            campaigns[_campaignId].tgeDetails.tgeAmount,
            campaigns[_campaignId].tgeDetails.tgeDate,
            staking,
            token,
            msg.sender,
            campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget
        );
    }

    /**
  @dev Claim KOL Investment - Campaign Owner can come and claim his KOL Investment. 
  @notice Can only claim after he is generated TGE. Can only claim amount of Tokens he/she has deposited 
  @param _campaignId - Campaign Id 
   */
    function claimKOLInvestment(uint256 _campaignId) external {
        //Campaign memory campaignDetails = retriveCampaign(_campaignId);
        require(campaigns[_campaignId].tgeDetails.isTGE == true, "Protokol:!TGE");
        require(
            campaigns[_campaignId].campaignData.campaignOwner == msg.sender ||
                campaigns[_campaignId].campaignData.secondOwner == msg.sender,
            "Protokol:UnAuthorized"
        );
        // require(campaigns[_campaignId].campaignData.remainingInvestment == 0, "Protokol:Investment is not Attained");
        require(
            campaigns[_campaignId].campaignData.investmentClaimed <
                campaigns[_campaignId].campaignData.requiredInvestment -
                    campaigns[_campaignId].campaignData.remainingInvestment,
            "Protokol:Investment Already claimed"
        );
        require(
            campaigns[_campaignId].campaignData.investmentClaimed <
                campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget,
            "Protokol:Already claimed your share against budget"
        );
        require(campaigns[_campaignId].campaignData.preSaleToken != _USDT, "Protokol: Can't claim,PST=USDT");
        uint256 _investment = campaigns[_campaignId].campaignData.requiredInvestment -
            campaigns[_campaignId].campaignData.remainingInvestment -
            campaigns[_campaignId].campaignData.investmentClaimed;
        if (_investment > campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget)
            _investment =
                campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget -
                campaigns[_campaignId].campaignData.investmentClaimed;
        campaigns[_campaignId].campaignData.investmentClaimed += _investment;
        // _investment = (_investment * 1 * 10**IERC20(_USDT).decimals()) / 1e18;
        // IERC20(_USDT).transfer(msg.sender, _investment);

        _safeTransfer(_USDT, msg.sender, (_investment * 1 * 10**IERC20(_USDT).decimals()) / 1e18);
        // console.log("Output of uniswap",amount[0]);
        // console.log("Output of uniswap",amount[1]);

        emit ClaimKolInvestment(_campaignId, _investment, msg.sender);
    }

    /**
  @dev Set Contract Variables - These are those Variables, which are being used through out the contract,like staking Perc, Penalty Per.
  @param contractVariables - Struct containing all the variables, which need to be updated.
   */
    function setContractVariables(uint16[] calldata contractVariables) external onlyAdmin {
        //add checks for staking Percentage
        // require(stakingPercentage < 90, "Protokol:Staking Percentage can't be greater than 90%");
        stakingPercentage = contractVariables[0];
        _penalty_per = contractVariables[1];
        _transactionPer = contractVariables[2];
        _platformPer = contractVariables[3];

        emit ContractVariablesUpdated(
            stakingPercentage,
            _penalty_per,
            _transactionPer,
            _platformPer,
            block.timestamp,
            msg.sender
        );
    }

    //Give KOL TGE AMOUNT according to KOL's share.
    // function claimTGEAmount(uint256 _campaignId) external{

    // }
    //Enter Amount in ETH
    /**
  @dev deposit Pre Sale Tokens - Deposit Pre Sale Tokens into contract.
  @notice Can only be done after TGE is generated
  @param _campaignId - Campaign ID
  @param _amount - Amount of tokens which is being deposited. (it will be in wei or have 18 decimal places)
   */
    function depositPreSaleTokens(uint256 _campaignId, uint256 _amount) external {
        require(campaigns[_campaignId].tgeDetails.isTGE == true, "Protokol:!TGE");
        require(
            campaigns[_campaignId].campaignData.campaignOwner == msg.sender ||
                campaigns[_campaignId].campaignData.secondOwner == msg.sender,
            "Protokol:UnAuthorized"
        );
        address token = campaigns[_campaignId].campaignData.preSaleToken;
        // _amount = (_amount * 10**IERC20(token).decimals()) / 10**18;
        uint256 markBudge = (campaigns[_campaignId].campaignData.marketingBudget * 10**IERC20(token).decimals()) /
            10**18;
        uint256 _investment = campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget +
            (_amount * campaigns[_campaignId].campaignData.requiredInvestment) /
            markBudge;
        require(_investment <= campaigns[_campaignId].campaignData.requiredInvestment, "Protokol:Amt>Mrkting Bgdt");
        // IERC20(token).transferFrom(msg.sender, address(this), _amount);

        campaigns[_campaignId].campaignData.presaleAmount += _amount;
        _safeTransferFrom(token, msg.sender, address(this), (_amount * 10**IERC20(token).decimals()) / 10**18);

        campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget = _investment;
        emit DepositPreSaleTokens(
            _campaignId,
            _amount,
            campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget,
            token,
            msg.sender
        );
    }

    /**
    @dev claim Pre Sale Tokens - KOL can claim his/her Pre Sale tokens, according to his progress in campaign.
    The amount will be calculated
    based on vesting if campaign has vesting or total reward.
    @notice This will be a signed function.
    @param _campaignId - Campaign Id for which you need to claim Pre Sale token
    @param progress - Amount of progress done on campaign
    @param r - Signature
    @param s - Signature
    @param v - Signature
   */

    function claimPreSaleTokens(
        uint256 _campaignId,
        uint256 progress,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external {
        // Add admin signature to this function
        // By adding a signature we make sure that KOL's progress is updated;
        //Check progress for only that vesting
        //CampaignDetails memory _campaign = retriveCampaign(_campaignId);
        uint256 _reward;
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                campaigns[_campaignId].campaignData.campaignOwner,
                campaigns[_campaignId].campaignData.startDate,
                campaigns[_campaignId].campaignData.preSaleToken
            )
        );
        recSig(r, s, v, msgHash);
        InvestedCampaign memory investmentDetails = investedCampaignDetails[msg.sender][_campaignId];
        require(investmentDetails.investedAmt > 0, "Protokol:No Investments.");
        // require(campaigns[_campaignId].tgeDetails.isTGE == true, "Protokol:!TGE"); // # change 1
        address preSale = campaigns[_campaignId].campaignData.preSaleToken;
        if (campaigns[_campaignId].vestingData.isVestingInEnabled) {
            require(
                block.timestamp - investmentDetails.lastVestingClaimed >
                    campaigns[_campaignId].vestingData.vestingCycleDuration,
                "Protokol:Vesting Claimed"
            );
            // require(investmentDetails.numberOfVestingsClaimed <
            //         campaigns[_campaignId].vestingData.NumberOfvestings, "Protokol:You have claimed all your vestings");

            uint256 _vesting = (block.timestamp - campaigns[_campaignId].tgeDetails.tgeDate) /
                campaigns[_campaignId].vestingData.vestingCycleDuration;

            _vesting =
                (investmentDetails.investShare * campaigns[_campaignId].tgeDetails.tgeAmount) /
                (100 * 10**18) +
                (_vesting * (investmentDetails.vestingRewardPerCycle * 10**IERC20(preSale).decimals())) /
                10**18;
            _vesting = (_vesting * 10**IERC20(preSale).decimals()) / 10**18;
            console.log("eligibleReward", investmentDetails.eligibleReward);

            uint256 totalReward = (investmentDetails.eligibleReward * 10**IERC20(preSale).decimals() * progress) /
                (10000 * 10**18);
            console.log("totalReward", totalReward);
            // require(
            //     totalReward > investedCampaignDetails[msg.sender][_campaignId].claimedReward,
            //     "Protokol:Already claimed PST"
            // ); // #change 2
            _reward = _vesting >= totalReward ? totalReward : _vesting;

            _reward = _reward - investedCampaignDetails[msg.sender][_campaignId].claimedReward;

            if (blackListedKOL[msg.sender][_campaignId] == true) {
                _blackListedKOLFundsHandling(_campaignId, _reward, preSale);
                return;
            }
            uint256 covertInto18 = (1 * 10**18) / 10**IERC20(preSale).decimals();
            _reward = _reward * covertInto18;
            _vesting = _vesting * covertInto18;
            // console.log(" 626 _reward", _reward);

            require(campaigns[_campaignId].campaignData.presaleAmount >= _reward, "Protokol:Not enough funds");
            investedCampaignDetails[msg.sender][_campaignId].leftOverReward = _vesting - _reward;
            investedCampaignDetails[msg.sender][_campaignId].lastVestingClaimed = block.timestamp;
            investedCampaignDetails[msg.sender][_campaignId].claimedReward += _reward;

            campaigns[_campaignId].campaignData.presaleAmount -= _reward;
            console.log("_reward", _reward);
            _safeTransfer(preSale, msg.sender, (_reward * 10**IERC20(preSale).decimals()) / 10**18);

            emit ClaimPreSaleTokens(_campaignId, _vesting, preSale, msg.sender, progress);
        } else {
            // console.log("KOL ELigible Reward:",investedCampaignDetails[msg.sender][_campaignId].eligibleReward);
            investedCampaignDetails[msg.sender][_campaignId].eligibleReward = investmentDetails.eligibleReward; // * 10**IERC20(preSale).decimals()) /10**18;
            // console.log("KOL ELigible Reward:", investedCampaignDetails[msg.sender][_campaignId].eligibleReward);
            uint256 eligibleRwd = (investedCampaignDetails[msg.sender][_campaignId].eligibleReward * progress) /
                10000 -
                investedCampaignDetails[msg.sender][_campaignId].claimedReward;
            if (blackListedKOL[msg.sender][_campaignId] == true) {
                _blackListedKOLFundsHandling(
                    _campaignId,
                    (eligibleRwd * 10**IERC20(preSale).decimals()) / 10**18,
                    preSale
                );
                return;
            }

            require(campaigns[_campaignId].campaignData.presaleAmount >= eligibleRwd, "Protokol:Not enough funds");
            investedCampaignDetails[msg.sender][_campaignId].claimedReward += eligibleRwd;

            campaigns[_campaignId].campaignData.presaleAmount -= eligibleRwd;
            _safeTransfer(preSale, msg.sender, (eligibleRwd * 10**IERC20(preSale).decimals()) / 10**18);
            // console.log("654", (eligibleRwd * 10**IERC20(preSale).decimals()) / 10**18);
            // eligibleRwd = (eligibleRwd * 1e18) / 10**IERC20(preSale).decimals();
            // console.log("656", eligibleRwd);
            emit ClaimPreSaleTokens(_campaignId, eligibleRwd, preSale, msg.sender, progress);
        }
    }

    // // //naming
    /**
  @dev Claim Back Investment By KOL - KOL claim back his investment.
  @notice He should claim it before TGE done, has this make sure that funds are available. If progress is 0 then that means
  KOL will be penalize accordingly.
  @param _campaignId - Campaign Id
  @param progress - Progress he has done in the campaign uptil now.
   */
    function claimBackInvestmentByKOL(
        uint256 _campaignId,
        uint256 progress,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external {
        address _msgSender = msg.sender;
        // require(blackListedKOL[_msgSender][_campaignId] != true, "Protokol:KOL blacklisted"); // #change3
        require(investedCampaignDetails[_msgSender][_campaignId].investedAmt > 0, "Protokol:No Investments.");
        require(campaigns[_campaignId].campaignData.preSaleToken != _USDT, "Protokol: Can't claim,PST=USDT");
        // Add signature
        require(
            campaigns[_campaignId].tgeDetails.tgeDate >= block.timestamp,
            "Protokol:Can't claim, TGE Already generated"
        );

        // require(blackListedKOL[msg.sender][_campaignId] != true, "Protokol:KOL is blacklisted can't claim");
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                campaigns[_campaignId].campaignData.campaignOwner,
                campaigns[_campaignId].campaignData.startDate,
                campaigns[_campaignId].tgeDetails.tgeDate,
                investedCampaignDetails[_msgSender][_campaignId].investedAmt
            )
        );

        recSig(r, s, v, msgHash);

        //Calculation: Progress-> uint, Investment, penalty_per
        //if progress is 0 then apply penalty percentage
        //Investment * penalty_per = remaining amt.
        InvestedCampaign memory _investment = investedCampaignDetails[_msgSender][_campaignId];
        uint256 _invest = _investment.investedAmt;

        if (progress == 0 && campaigns[_campaignId].tgeDetails.amountOfTGEDateUpdation == 0) {
            _invest = _invest - (_invest * _penalty_per) / 10000;

            penaltyAmount += _investment.investedAmt - _invest;
        }

        // console.log("701 _invest", _invest);

        campaigns[_campaignId].campaignData.remainingInvestment += _investment.investedAmt;
        _investment.investedAmt = 0;
        _investment.investShare = 0;
        _investment.eligibleReward = 0;
        _investment.investShare = 0;
        _investment.vestingRewardPerCycle = 0;
        kolInvestDetails[_msgSender][_campaignId] = false;
        investedCampaignDetails[_msgSender][_campaignId] = _investment;
        // IERC20(_USDT).transfer(_msgSender, _invest);
        _safeTransfer(_USDT, _msgSender, (_invest * 1 * 10**IERC20(_USDT).decimals()) / 1e18);
        emit ClaimBackInvestment(_campaignId, progress, _invest, _msgSender);
    }

    /**
  @dev Black Listing of KOL - KOL is black listed, admin Only function. As mechnaism is revolved around his progress, so if he has done
  some progress so his PST funds will accordingly accumulated and the remaining will be paid in the form of his investment.
  @param _campaignId - Campaign Id
  @param _kol - Address of KOL Token
  @param progress - KOL's progress uptil blacklisting.
   */
    function blackListKOL(
        uint256 _campaignId,
        address _kol,
        uint16 progress
    ) external onlyAdmin {
        blackListedKOL[_kol][_campaignId] = true;
        if (campaigns[_campaignId].campaignData.preSaleToken != _USDT) {
            require(
                campaigns[_campaignId].campaignData.investmentClaimed <=
                    campaigns[_campaignId].campaignData.requiredInvestment -
                        campaigns[_campaignId].campaignData.remainingInvestment,
                "Owner already claimed"
            );
            investedCampaignDetails[_kol][_campaignId].leftOverInvestment =
                (investedCampaignDetails[_kol][_campaignId].investedAmt * (10000 - progress)) /
                10000;

            // console.log("leftOverInvestment", investedCampaignDetails[_kol][_campaignId].leftOverInvestment);
            campaigns[_campaignId].campaignData.remainingInvestment += investedCampaignDetails[_kol][_campaignId]
                .leftOverInvestment;
            // console.log("remainingInvestment", campaigns[_campaignId].campaignData.remainingInvestment);
            kolInvestDetails[msg.sender][_campaignId] = false;
        }
        emit BlackListedKol(_kol, _campaignId);
    }

    /**
  @dev Black Listing Funds Handling - KOL which is black listed, his funds are accumulated accordingly.
  @notice - Private function, it is called inside claim Pre Sale Tokens
  @param _campaignId - Campaign Id
  @param _reward - His accumulated Reward, according to his made progress
  @param preSale - Address of pre Sale token which he/she is going to be rewarded.
   */
    function _blackListedKOLFundsHandling(
        uint256 _campaignId,
        uint256 _reward,
        address preSale
    ) private {
        uint256 eligibleRwd = _reward;
        uint256 convertInto18 = 10**18 / 10**IERC20(preSale).decimals();
        uint256 convertIntoTkn = 10**IERC20(preSale).decimals() / 10**18;
        uint256 balance = (campaigns[_campaignId].campaignData.presaleAmount * 10**IERC20(preSale).decimals()) / 10**18; //IERC20(preSale).balanceOf(address(this));
        // console.log("balance", balance);
        if (balance < _reward) {
            // IERC20(preSale).transfer(msg.sender, balance);
            // console.log("740 balance", balance);
            if (balance > 0) {
                _safeTransfer(preSale, msg.sender, balance);
                _reward = _reward - balance;
                // console.log("_reward", _reward);
                campaigns[_campaignId].campaignData.presaleAmount -= _reward * convertInto18;
                eligibleRwd = balance;
            }
        } else {
            // IERC20(preSale).transfer(msg.sender, _reward);
            // console.log("740 balance", _reward);
            campaigns[_campaignId].campaignData.presaleAmount -= _reward * convertInto18;
            // console.log(" 783 _reward", _reward);
            _safeTransfer(preSale, msg.sender, _reward);
            // _reward = (campaigns[_campaignId].campaignData.requiredInvestment - _reward * convertInto18) / 1e18;
            _reward = 0;
        }
        balance = 0;

        if (campaigns[_campaignId].campaignData.preSaleToken != _USDT) {
            // console.log(" 803 leftOverInvestment", investedCampaignDetails[msg.sender][_campaignId].leftOverInvestment);

            investedCampaignDetails[msg.sender][_campaignId].leftOverInvestment +=
                (_reward * campaigns[_campaignId].campaignData.requiredInvestment) /
                (
                    (campaigns[_campaignId].campaignData.marketingBudget) //* 10**IERC20(_USDT).decimals()) / 10**18
                );
            // console.log("805 leftOverInvestment", investedCampaignDetails[msg.sender][_campaignId].leftOverInvestment);

            // console.log("Left Over Investment",investedCampaignDetails[msg.sender][_campaignId].leftOverInvestment);
            if (campaigns[_campaignId].tgeDetails.tgeAmount > 0 || campaigns[_campaignId].tgeDetails.isTGE) {
                balance =
                    campaigns[_campaignId].campaignData.requiredInvestment -
                    campaigns[_campaignId].campaignData.remainingInvestment +
                    investedCampaignDetails[msg.sender][_campaignId].leftOverInvestment; //IERC20(_USDT).balanceOf(address(this));
                if (balance < investedCampaignDetails[msg.sender][_campaignId].leftOverInvestment) {
                    // console.log("765 balance", balance);
                    _safeTransfer(_USDT, msg.sender, (balance * 10**IERC20(_USDT).decimals()) / 1e18);
                    // console.log("balance", balance);
                } else {
                    // IERC20(_USDT).transfer(msg.sender, investedCampaignDetails[msg.sender][_campaignId].leftOverInvestment);
                    // console.log(
                    //     "769 leftOverInvestment",
                    //     investedCampaignDetails[msg.sender][_campaignId].leftOverInvestment
                    // );
                    _safeTransfer(
                        _USDT,
                        msg.sender,
                        (investedCampaignDetails[msg.sender][_campaignId].leftOverInvestment *
                            10**IERC20(_USDT).decimals()) / 1e18
                    );
                    // console.log(
                    //     "leftOverInvestment",
                    //     investedCampaignDetails[msg.sender][_campaignId].leftOverInvestment
                    // );
                    balance = investedCampaignDetails[msg.sender][_campaignId].leftOverInvestment;
                }
            }
        }

        investedCampaignDetails[msg.sender][_campaignId].investedAmt = 0;

        emit ClaimPreSaleTokensBlackListed(_campaignId, eligibleRwd * convertInto18, balance, preSale, msg.sender);
    }

    /**
  @dev Set Number of Campaigns Updation - Updations to be allowed for a campaign, maximum is 2 but there is no condition applied,
  as this an onlyAdmin function and he can mantain it there.
  @param _campaignId - Campaign ID
  @param _amount - Amount of updations a campaign can do
   */
    function setNumberOfCampaignsUpdations(uint256 _campaignId, uint16 _amount) external onlyAdmin {
        campaigns[_campaignId].tgeDetails.amountOfTGEDateUpdation = _amount;
    }

    function setStakingContract(address _stakingCont) external onlyAdmin {
        _stakingContract = _stakingCont;
    }

    function setNewAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
    }

    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "STF");
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ST");
    }

    function withdrawPenaltyAndUpdateAddress(
        address _newAddress,
        bool isUpdateAdmin,
        bool wantToWithdraw
    ) external onlyAdmin {
        if (!wantToWithdraw) {
            if (isUpdateAdmin) {
                admin = _newAddress;
            } else {
                _stakingContract = _newAddress;
            }
        } else {
            // IERC20(_USDT).transfer(msg.sender, (penaltyAmount * (1 * 10**IERC20(_USDT).decimals())) / 1e18);
            _safeTransfer(_USDT, msg.sender, (penaltyAmount * (1 * 10**IERC20(_USDT).decimals())) / 1e18);
            penaltyAmount = 0;
        }

        emit WithdrawPenaltyAndUpdateAddress(isUpdateAdmin, _newAddress, penaltyAmount);
    }

    function withdawPresaleByCampaignOwner(uint256 _campaignId) external {
        Campaign memory campaignDetails = retriveCampaign(_campaignId);
        require(
            campaignDetails.campaignData.campaignOwner == msg.sender ||
                campaignDetails.campaignData.secondOwner == msg.sender,
            "Protkol:UnAuthorized"
        );

        // require(campaignDetails.campaignData.endDate < block.timestamp, "TA");

        uint256 shareOfKolsInTermsToken = (
            (
                (((campaignDetails.campaignData.requiredInvestment - campaignDetails.campaignData.remainingInvestment) *
                    1e18) / campaignDetails.campaignData.requiredInvestment)
            )
        );
        uint256 marketingBudget = campaignDetails.campaignData.marketingBudget;

        shareOfKolsInTermsToken =
            (shareOfKolsInTermsToken * (marketingBudget - campaigns[_campaignId].campaignData.stakingAmount)) /
            1e18;

        require(shareOfKolsInTermsToken <= campaignDetails.campaignData.presaleAmount, "InsufficientAmount");

        uint256 transferPresale = campaignDetails.campaignData.presaleAmount - shareOfKolsInTermsToken;

        // IERC20(campaignDetails.campaignData.preSaleToken).transfer(
        //     msg.sender,
        //     (transferPresale * 10**IERC20(campaignDetails.campaignData.preSaleToken).decimals()) / 1e18
        // );
        campaigns[_campaignId].campaignData.presaleAmount -= transferPresale;
        _safeTransfer(
            campaignDetails.campaignData.preSaleToken,
            msg.sender,
            (transferPresale * 10**IERC20(campaignDetails.campaignData.preSaleToken).decimals()) / 1e18
        );

        emit WithdrawPresaleByCampaignOwner(_campaignId, msg.sender, shareOfKolsInTermsToken, transferPresale);
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

    struct CampaignDetailsInput {
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

    struct CampaignDetails {
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
        uint256 presaleAmount;
        bool isKolInvestment;
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
        address _depositedBy,
        uint256 _cummulativeDeposit
    );

    event ContractVariablesUpdated(
        uint16 _stakingPerct,
        uint16 _penaltyPer,
        uint16 _transactionPer,
        uint16 _platformPer,
        uint256 _time,
        address _updatedBy
    );
    event DepositPreSaleTokens(
        uint256 campaign_Id,
        uint256 _amount,
        uint256 _cummulativeDeposit,
        address _token,
        address _depositer
    );
    event ClaimPreSaleTokens(
        uint256 campaign_Id,
        uint256 _amount,
        address _preSaleToken,
        address _kol,
        uint256 progress
    );
    event ClaimPreSaleTokensBlackListed(
        uint256 campaign_Id,
        uint256 _amountPST,
        uint256 _amountUSDT,
        address _preSaleToken,
        address _kol
    );
    event InvestInCampaign(uint256 campaign_Id, uint256 _amount, uint256 _investmentShare, address _kol);
    event ClaimKolInvestment(uint256 campaign_Id, uint256 _investment, address _kol);
    event ClaimBackInvestment(uint256 campaign_Id, uint256 _progress, uint256 _investment, address _kol);
    event SetMaxTGEAllowance(uint256 _tge);
    event SetPenalty(uint256 _penalty);
    event BlackListedKol(address Kol, uint256 campaignId);
    event WithdrawPresaleByCampaignOwner(
        uint256 campaignId,
        address owner,
        uint256 shareOfKolsInTermsToken,
        uint256 transferPresale
    );
    event WithdrawPenaltyAndUpdateAddress(bool isUpdateAdmin, address _newAddress, uint256 penaltyAmount);
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
error UnAuthorizedOwners(address _owner, address _secondOwner);
error InvestmentNotAttained(uint256 _remainingInvestment);
error TGEDone(bool _tgeDone);
error TGENotDone(bool _tgeDone);
error InvestmentClaimed(bool isInvestmentclaimed);
error AlreadyInvested(uint256 _investment);
error InvalidAdmin(address _admin);
error KOLExists(uint256 _kolID);
error KolNotRegistered(address _kol);
error TgeTimeExceeded(uint256 _tgeTime);
error GenerateTGE(bool _isTGE);
error VestingCycleEnded(uint256 _vestingCycle);
error VestingsCompleted(uint256 _NumberFOVestings);
error MaxTGELimitReached();

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

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "./SafeMath.sol";
import "hardhat/console.sol";

library UniswapV2Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
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

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
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