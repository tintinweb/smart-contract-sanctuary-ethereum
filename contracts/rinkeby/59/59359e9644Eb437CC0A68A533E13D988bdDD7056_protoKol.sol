// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./Structs.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IOracleV2.sol";

import "contracts/libraries/UniLib.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract protoKol is iProtoKol {
    address public admin;
    address public operator;
    address public kolToken;
    address private uniswapRouterv2;
    address private _vault = 0xB4eA3D4F74520Fc11fF14810D8219FE309a0c265;
    address private immutable _USDT;
    address private _stakingContract;
    address private oracle;

    uint16 public stakingPercentage = 500;
    uint16 public _penalty_per = 500;
    uint16 public _transactionPer = 50;
    uint16 public _platformPer = 50;
    uint32 private _unlocked = 1;

    uint256 public penaltyAmount;
    uint256 private campaignID;
    uint256 private _kolID;

    mapping(address => KOL) private registeredKOL;
    mapping(address => mapping(uint256 => bool)) public blackListedKOL;
    mapping(uint256 => Campaign) private campaigns;
    mapping(address => mapping(uint256 => InvestedCampaign)) public investedCampaignDetails;

    constructor(
        address _admin,
        address _kolToken,
        address _usdt,
        address _staking,
        address _oracle,
        address _uniswapRouterv2
    ) {
        require(_admin != address(0) && _usdt != address(0) && _staking != address(0), "ZA");

        admin = _admin;
        operator = msg.sender;
        _USDT = _usdt;
        _stakingContract = _staking;

        if (_kolToken != address(0)) {
            oracle = _oracle;
            kolToken = _kolToken;
            uniswapRouterv2 = _uniswapRouterv2;
        }
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "NA");
        _;
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method.
    function _checkCampaignOwner(uint256 _campaignId) private view {
        Campaign memory campaignDetails = retriveCampaign(_campaignId);
        require(
            campaignDetails.campaignData.campaignOwner == msg.sender ||
                campaignDetails.campaignData.secondOwner == msg.sender,
            "Protkol:UnAuthorized"
        );
    }

    modifier onlyCampaignOwners(uint256 _campaignId) {
        _checkCampaignOwner(_campaignId);
        _;
    }

    modifier nonReentrant() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
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
    ) internal view {
        address signer = ecrecover(msgHash, v, r, s);
        require(signer == operator, "IS");
    }

    /**
   @dev Register KOL and add into registered KOL mapping.
   @param _name - Name of the KOL
   */
    function registerKOL(string calldata _name) external {
        require(
            registeredKOL[msg.sender].kolWallet == address(0) && keccak256(bytes(_name)) != keccak256(bytes("")),
            "ID"
        );

        KOL memory _newKol = KOL({ kolWallet: msg.sender, name: _name, kolID: _kolID });
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
   */
    function updateKolData(string calldata _name) external {
        require(
            registeredKOL[msg.sender].kolWallet != address(0) && keccak256(bytes(_name)) != keccak256(bytes("")),
            "ID"
        );
        registeredKOL[msg.sender].name = _name;
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
        CampaignDetails calldata _newCampaignInput,
        VestingDetails calldata _vestingInfoInput,
        uint256 _tgeDate,
        uint16 _tgePer,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external {
        recSig(
            r,
            s,
            v,
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    _newCampaignInput.startDate,
                    _newCampaignInput.requiredInvestment,
                    _newCampaignInput.marketingBudget,
                    block.chainid
                )
            )
        );

        // require(_newCampaignInput.campaignOwner != address(0x0), "ZA");
        // require(_tgeDate >= _newCampaignInput.startDate + 21 * 1 days, "Protokol:TGE<21 days start date");
        // require(
        //     _tgeDate <= _newCampaignInput.startDate + (_newCampaignInput.endDate - 14) * 1 days,
        //     "Protokol:TGE>14 days end date"
        // );
        require(_vestingInfoInput.NumberOfvestings * _vestingInfoInput.vestingCycleDuration * 1 days <= 120 days, "V4");

        Campaign memory _campaign;
        _campaign.campaignNumber = campaignID;
        TGE memory _tgeInfo;
        CampaignDetails memory _newCampaign;
        VestingDetails memory _vestingInfo;
        _newCampaign.startDate = _newCampaignInput.startDate;
        _newCampaign.preSaleToken = _newCampaignInput.preSaleToken;
        _newCampaign.requiredInvestment = _newCampaignInput.requiredInvestment;
        _newCampaign.campaignOwner = msg.sender;
        _newCampaign.secondOwner = _newCampaignInput.secondOwner;
        _newCampaign.marketingBudget = _newCampaignInput.marketingBudget;
        _newCampaign.endDate = _newCampaign.startDate + _newCampaignInput.endDate * 1 days;
        _newCampaign.remainingInvestment = _newCampaign.requiredInvestment;
        _newCampaign.stakingAmount = (stakingPercentage * _newCampaign.marketingBudget) / 10000;
        _vestingInfo.isVestingEnabled = _vestingInfoInput.isVestingEnabled;
        _vestingInfo.NumberOfvestings = _vestingInfoInput.NumberOfvestings;
        _vestingInfo.vestingCycleDuration = _vestingInfoInput.vestingCycleDuration;

        require(_tgePer <= 10000);
        _tgeInfo.tgePercentage = _tgePer;
        _tgeInfo.amountOfTGEDateUpdation = 2;

        uint256 _deductedBudget = _newCampaign.marketingBudget - _newCampaign.stakingAmount;

        _tgeInfo.tgeDate = _tgeDate;

        if (_tgePer == 10000) {
            _vestingInfo.isVestingEnabled = false;
        }

        if (_vestingInfo.isVestingEnabled) {
            require(_vestingInfo.NumberOfvestings != 0 && _vestingInfo.vestingCycleDuration != 0, "NOV");
            _tgeInfo.tgeAmount = (_tgeInfo.tgePercentage * _deductedBudget) / 10000;

            _vestingInfo.vestingCycleDuration = _vestingInfo.vestingCycleDuration * 1 days;
            _vestingInfo.vestingAmtPerCycle = ((_deductedBudget - _tgeInfo.tgeAmount) / _vestingInfo.NumberOfvestings);
        } else if (_vestingInfo.isVestingEnabled == false) {
            _tgeInfo.tgePercentage = 10000;
            _tgeInfo.tgeAmount = _deductedBudget;
        }
        _campaign.campaignData = _newCampaign;
        _campaign.vestingData = _vestingInfo;
        _campaign.tgeDetails = _tgeInfo;
        campaigns[campaignID] = _campaign;
        emit CampaignCreated(_campaign);
        campaignID++;
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
    ) external onlyCampaignOwners(_campaignId) {
        Campaign memory campaignDetails = retriveCampaign(_campaignId);

        require(!campaignDetails.tgeDetails.isTGE, "TGE");
        // require(_tgeDate >= campaignDetails.campaignData.startDate + 21 * 1 days, "Protokol:TGE>21 days start date");
        // require(_tgeDate + 14 days <= campaignDetails.campaignData.endDate, "Protokol:TGE>14 days end Date");
        require(_preSaletoken != address(0), "ZA");
        if (campaignDetails.tgeDetails.amountOfTGEDateUpdation >= 1) {
            require(
                _tgeDate - campaignDetails.tgeDetails.tgeDate <=
                    (30 + campaignDetails.tgeDetails.TGEUpdationDone * 30) * 1 days,
                "IT"
            );
            campaigns[_campaignId].tgeDetails.tgeDate = _tgeDate;
            campaigns[_campaignId].tgeDetails.amountOfTGEDateUpdation -= 1;
            campaigns[_campaignId].tgeDetails.TGEUpdationDone += 1;
        }
        if (_preSaletoken != _USDT) campaigns[_campaignId].campaignData.preSaleToken = _preSaletoken;
        emit CampaignDetailsUpdated(campaigns[_campaignId]);
    }

    /**
  @dev Swap Router - private function as it will only be called internally. Function calls uniswap, swap ExactTokens for Tokens.
  @param _investment - Amount of invested tokens
  @param amountOut -  Amount of tokens to be taken Out
  @param path[] - Array of Tokens starting from the token which is input and last index will be the token which is being taken Out.
   */
    function _swapRouter(
        uint256 _investment,
        uint256 amountOut,
        address[] memory path,
        address reciever
    ) private returns (uint256[] memory amount) {
        (bool success, bytes memory data) = path[0].call(
            abi.encodeWithSelector(0x095ea7b3, uniswapRouterv2, _investment)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SA");

        amount = IUniswapV2Router02(uniswapRouterv2).swapExactTokensForTokens(
            _investment,
            amountOut,
            path,
            reciever,
            block.timestamp + 1 hours
        );
    }

    /**
  @dev Invest In Campaign - Invest in campaign in either usdt or KOL, KOL Investment details struct will be updated, like
  its investment share, reward, vesting reward etc.
  @notice This is a signed function by admin
  @param _campaignId - Campaign Id
  @param _investment - Amount of Invested Tokens, can be only KOL or USDT
  @param tokenAddress - The token Address in which the investment is being done.
  @param sign - signature struct, containing r,s,v.
   */
    function investInCampaign(
        uint256 _campaignId,
        uint256 _investment,
        address tokenAddress,
        Signature calldata sign
    ) external {
        recSig(
            sign.r,
            sign.s,
            sign.v,
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    campaigns[_campaignId].campaignData.startDate,
                    tokenAddress,
                    _investment,
                    block.chainid
                )
            )
        );
        InvestedCampaign memory investDetails = investedCampaignDetails[msg.sender][_campaignId];
        KOL memory _kolData = retriveKOL(msg.sender);
        require(_kolData.kolWallet != address(0) && !blackListedKOL[msg.sender][_campaignId], "!REG");
        require(_investment > 0, "SGZ");
        require(investDetails.investedAmt == 0, "AI");
        require(tokenAddress == kolToken || tokenAddress == _USDT, "TNV");
        require(
            campaigns[_campaignId].tgeDetails.tgeDate > block.timestamp || campaigns[_campaignId].tgeDetails.isTGE,
            "INA"
        );
        require(block.timestamp <= campaigns[_campaignId].campaignData.endDate, "CE");

        if (campaigns[_campaignId].campaignData.preSaleToken != _USDT) {
            uint256 _totalInvestment = _investment;
            if (tokenAddress == kolToken) {
                address[] memory path = new address[](2);
                path[0] = tokenAddress;
                path[1] = _USDT;
                _investment = (_investment * (10000 - _transactionPer)) / 10000;

                uint256 amountInUsdt = IOracleV2(oracle).fetchKOLPrice(_investment);
                amountInUsdt = amountInUsdt - ((amountInUsdt * 150) / 10000);

                _safeTransferFrom(kolToken, msg.sender, address(this), _totalInvestment);
                _safeTransfer(kolToken, _vault, _totalInvestment - _investment);

                uint256[] memory amount = _swapRouter(_investment, amountInUsdt, path, address(this));
                _investment = (amount[1] * 1e18) / 10**IERC20(_USDT).decimals();

                require(
                    (amount[1] * 1e18) / 10**IERC20(_USDT).decimals() <=
                        campaigns[_campaignId].campaignData.remainingInvestment,
                    "AGI"
                );
            } else {
                _investment = (_investment * (10000 - _transactionPer)) / 10000;
                require(_investment <= campaigns[_campaignId].campaignData.remainingInvestment, "AGI");
                uint256 amountInUsdt = _downscale(IERC20(_USDT).decimals(), _investment);

                _safeTransferFrom(_USDT, msg.sender, address(this), amountInUsdt);
                _safeTransferFrom(
                    _USDT,
                    msg.sender,
                    _vault,
                    _downscale(IERC20(_USDT).decimals(), _totalInvestment) - amountInUsdt
                );
            }
        } else {
            require(_investment <= campaigns[_campaignId].campaignData.remainingInvestment, "AGI");
        }

        investDetails.campaignNumber = _campaignId;

        investDetails.investedAmt = _investment;

        investDetails.investShare =
            (investDetails.investedAmt * 100 * 10**18) /
            campaigns[_campaignId].campaignData.requiredInvestment;

        if (campaigns[_campaignId].vestingData.isVestingEnabled == true) {
            investDetails.vestingRewardPerCycle =
                (investDetails.investShare * campaigns[_campaignId].vestingData.vestingAmtPerCycle) /
                10**20;
        }

        investDetails.eligibleReward =
            (investDetails.investShare *
                (campaigns[_campaignId].campaignData.marketingBudget -
                    campaigns[_campaignId].campaignData.stakingAmount)) /
            (100 * 10**18);

        campaigns[_campaignId].campaignData.remainingInvestment -= _investment;

        investedCampaignDetails[msg.sender][_campaignId] = investDetails;
        emit InvestInCampaign(_campaignId, _investment, investDetails.investShare, msg.sender);
    }

    /**
  @dev Generate TGE - Function generates TGE by transferring TGE Amount into contract to use later.
  @param _campaignId - Campaign Id for which TGE is being generated.

   */
    function generateTGE(uint256 _campaignId) external onlyCampaignOwners(_campaignId) {
        require(!campaigns[_campaignId].tgeDetails.isTGE, "TGE");

        address presaleToken = campaigns[_campaignId].campaignData.preSaleToken;
        require(presaleToken != address(0), "PNS");
        require(block.timestamp <= campaigns[_campaignId].tgeDetails.tgeDate, "TP");
        uint256 tokenDecimals = IERC20(presaleToken).decimals();

        uint256 markBudge = campaigns[_campaignId].campaignData.marketingBudget;
        uint256 staking = campaigns[_campaignId].campaignData.stakingAmount;

        campaigns[_campaignId].campaignData.presaleAmount = campaigns[_campaignId].tgeDetails.tgeAmount;

        campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget =
            ((campaigns[_campaignId].tgeDetails.tgeAmount + staking) *
                campaigns[_campaignId].campaignData.requiredInvestment) /
            markBudge;
        campaigns[_campaignId].tgeDetails.isTGE = true;
        _safeTransferFrom(presaleToken, msg.sender, _stakingContract, _downscale(tokenDecimals, staking));

        _safeTransferFrom(
            presaleToken,
            msg.sender,
            _vault,
            (_downscale(tokenDecimals, markBudge) * _platformPer) / 10000
        );

        _safeTransferFrom(
            presaleToken,
            msg.sender,
            address(this),
            _downscale(tokenDecimals, campaigns[_campaignId].tgeDetails.tgeAmount)
        );

        campaigns[_campaignId].tgeDetails.tgeDate = block.timestamp; // remove before production

        emit TGEDeposited(
            _campaignId,
            campaigns[_campaignId].tgeDetails.tgeAmount,
            campaigns[_campaignId].tgeDetails.tgeDate,
            staking,
            presaleToken,
            msg.sender,
            campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget
        );
    }

    /**
  @dev Claim KOL Investment - Campaign Owner can come and claim his KOL Investment. 
  @notice Can only claim after he is generated TGE. Can only claim amount of Tokens he/she has deposited 
  @param _campaignId - Campaign Id 
   */
    function claimKOLInvestment(uint256 _campaignId) external onlyCampaignOwners(_campaignId) {
        require(
            block.timestamp > campaigns[_campaignId].tgeDetails.tgeDate &&
                campaigns[_campaignId].tgeDetails.isTGE == true,
            "!TGE"
        );

        require(
            campaigns[_campaignId].campaignData.investmentClaimed <
                (campaigns[_campaignId].campaignData.requiredInvestment -
                    campaigns[_campaignId].campaignData.remainingInvestment),
            "IAC"
        );
        require(
            campaigns[_campaignId].campaignData.investmentClaimed <
                campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget,
            "CSAB"
        );
        require(campaigns[_campaignId].campaignData.preSaleToken != _USDT, "TS");

        uint256 _investment = campaigns[_campaignId].campaignData.requiredInvestment -
            campaigns[_campaignId].campaignData.remainingInvestment -
            campaigns[_campaignId].campaignData.investmentClaimed;

        if (
            _investment >
            campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget -
                campaigns[_campaignId].campaignData.investmentClaimed
        )
            _investment =
                campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget -
                campaigns[_campaignId].campaignData.investmentClaimed;

        campaigns[_campaignId].campaignData.investmentClaimed += _investment;
        _safeTransfer(_USDT, msg.sender, _downscale(IERC20(_USDT).decimals(), _investment));

        emit ClaimKolInvestment(_campaignId, _investment, msg.sender);
    }

    /**
  @dev Set Contract Variables - These are those Variables, which are being used through out the contract, like staking Perc, Penalty Per.
  @param contractVariables - Struct containing all the variables, which need to be updated.
   */
    function setContractVariables(uint16[] calldata contractVariables) external onlyAdmin {
        require(stakingPercentage <= 7000, "SPL70");

        emit ContractVariablesUpdated(
            stakingPercentage = contractVariables[0],
            _penalty_per = contractVariables[1],
            _transactionPer = contractVariables[2],
            _platformPer = contractVariables[3],
            block.timestamp,
            msg.sender
        );
    }

    /**
  @dev deposit Pre Sale Tokens - Deposit Pre Sale Tokens into contract.
  @notice Can only be done after TGE is generated
  @param _campaignId - Campaign ID
  @param _amount - Amount of tokens which is being deposited. (it will be in wei or have 18 decimal places)
   */
    function depositPreSaleTokens(uint256 _campaignId, uint256 _amount) external onlyCampaignOwners(_campaignId) {
        require(campaigns[_campaignId].tgeDetails.isTGE == true, "!TGE");

        address token = campaigns[_campaignId].campaignData.preSaleToken;

        uint256 _investment = campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget +
            (_amount * campaigns[_campaignId].campaignData.requiredInvestment) /
            (campaigns[_campaignId].campaignData.marketingBudget);
        require(_investment <= campaigns[_campaignId].campaignData.requiredInvestment, "AGM");

        campaigns[_campaignId].campaignData.presaleAmount += _amount;
        campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget = _investment;
        _safeTransferFrom(token, msg.sender, address(this), _downscale(IERC20(token).decimals(), _amount));

        emit DepositPreSaleTokens(
            _campaignId,
            _amount,
            campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget,
            token,
            msg.sender
        );
    }

    /**
  @dev claim Pre Sale Tokens - KOL can claim his/her Pre Sale tokens, according to his progress in campaign. The amount will be calculated
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
    ) external nonReentrant {
        recSig(r, s, v, keccak256(abi.encodePacked(msg.sender, _campaignId, progress, block.chainid)));
        InvestedCampaign memory investmentDetails = investedCampaignDetails[msg.sender][_campaignId];
        require(investmentDetails.investedAmt > 0, "NI");
        require(investmentDetails.eligibleReward > 0, "AC");
        require(
            block.timestamp > campaigns[_campaignId].tgeDetails.tgeDate && campaigns[_campaignId].tgeDetails.isTGE,
            "!TGE"
        );
        address preSale = campaigns[_campaignId].campaignData.preSaleToken;

        if (blackListedKOL[msg.sender][_campaignId]) {
            _blackListedKOLFundsHandling(
                _campaignId,
                investedCampaignDetails[msg.sender][_campaignId].rewardAfterBlacklist,
                preSale
            );
            investedCampaignDetails[msg.sender][_campaignId].investedAmt = 0;
            return;
        }

        uint256 _reward;
        bool timePassed;

        (_reward, , , timePassed) = calculateReward(_campaignId, msg.sender, progress);

        if (
            timePassed &&
            campaigns[_campaignId].campaignData.requiredInvestment >
            campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget
        ) {
            uint256 leftOverInvestment = _blackListedKOLFundsHandling(_campaignId, _reward, preSale);
            if (leftOverInvestment > 0) campaigns[_campaignId].campaignData.remainingInvestment += leftOverInvestment;
            investedCampaignDetails[msg.sender][_campaignId].eligibleReward = 0;
            return;
        }
        require(_reward > 0, "ZR");
        require(campaigns[_campaignId].campaignData.presaleAmount >= _reward, "IF");

        investedCampaignDetails[msg.sender][_campaignId].claimedReward += _reward;
        campaigns[_campaignId].campaignData.presaleAmount -= _reward;

        _safeTransfer(preSale, msg.sender, _downscale(IERC20(preSale).decimals(), _reward));
        emit ClaimPreSaleTokens(_campaignId, _reward, preSale, msg.sender, progress);
    }

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
        require(investedCampaignDetails[msg.sender][_campaignId].investedAmt > 0, "NI");
        require(investedCampaignDetails[msg.sender][_campaignId].eligibleReward > 0, "AC");
        require(campaigns[_campaignId].campaignData.preSaleToken != _USDT, "TS");
        require(
            campaigns[_campaignId].tgeDetails.tgeDate > block.timestamp || !campaigns[_campaignId].tgeDetails.isTGE,
            "TGE"
        );

        recSig(
            r,
            s,
            v,
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    investedCampaignDetails[msg.sender][_campaignId].investedAmt,
                    _campaignId,
                    progress,
                    block.chainid
                )
            )
        );

        InvestedCampaign memory _investment = investedCampaignDetails[msg.sender][_campaignId];
        uint256 _invest = _investment.investedAmt;

        if (progress == 0 && campaigns[_campaignId].tgeDetails.TGEUpdationDone == 0) {
            _invest = _invest - (_invest * _penalty_per) / 10000;

            penaltyAmount += _investment.investedAmt - _invest;
        }
        if (!blackListedKOL[msg.sender][_campaignId]) {
            campaigns[_campaignId].campaignData.remainingInvestment += _investment.investedAmt;
        }

        _investment.investedAmt = 0;
        _investment.eligibleReward = 0;
        _investment.investShare = 0;
        _investment.vestingRewardPerCycle = 0;
        investedCampaignDetails[msg.sender][_campaignId] = _investment;

        _safeTransfer(_USDT, msg.sender, _downscale(IERC20(_USDT).decimals(), _invest));

        emit ClaimBackInvestment(_campaignId, progress, _invest, msg.sender);
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
        uint256 progress
    ) external onlyAdmin {
        require(!blackListedKOL[_kol][_campaignId], "AB");

        blackListedKOL[_kol][_campaignId] = true;
        uint256 leftOverInvestment;
        if (campaigns[_campaignId].tgeDetails.tgeDate > block.timestamp || !campaigns[_campaignId].tgeDetails.isTGE) {
            investedCampaignDetails[_kol][_campaignId].rewardAfterBlacklist = 0;
            campaigns[_campaignId].campaignData.remainingInvestment += investedCampaignDetails[_kol][_campaignId]
                .investedAmt;
            return;
        }

        (uint256 _reward, , , ) = calculateReward(_campaignId, _kol, progress);
        investedCampaignDetails[_kol][_campaignId].rewardAfterBlacklist = _reward;

        uint256 eligibleRwd = (investedCampaignDetails[_kol][_campaignId].eligibleReward);
        uint256 presaleShare = (((_reward + investedCampaignDetails[msg.sender][_campaignId].claimedReward) * 10000) /
            eligibleRwd);

        if (presaleShare < 10000) {
            leftOverInvestment =
                (investedCampaignDetails[_kol][_campaignId].investedAmt * (10000 - (presaleShare))) /
                10000;
        }

        require(
            campaigns[_campaignId].campaignData.requiredInvestment -
                campaigns[_campaignId].campaignData.remainingInvestment -
                campaigns[_campaignId].campaignData.investmentClaimed >=
                leftOverInvestment,
            "AC"
        );

        campaigns[_campaignId].campaignData.remainingInvestment += leftOverInvestment;

        emit BlackListedKol(_kol, _campaignId, progress, leftOverInvestment);
    }

    function _blackListedKOLFundsHandling(
        uint256 _campaignId,
        uint256 _reward,
        address preSale
    ) private returns (uint256 leftOverInvestment) {
        uint256 eligibleRwd = (investedCampaignDetails[msg.sender][_campaignId].eligibleReward);

        uint256 presaleShare = (((_reward + investedCampaignDetails[msg.sender][_campaignId].claimedReward) * 10000) /
            eligibleRwd);

        if (_reward != 0) {
            campaigns[_campaignId].campaignData.presaleAmount -= _reward;
            investedCampaignDetails[msg.sender][_campaignId].claimedReward += _reward;

            _safeTransfer(preSale, msg.sender, _downscale(IERC20(preSale).decimals(), _reward));
        }

        if (presaleShare < 10000) {
            leftOverInvestment =
                (investedCampaignDetails[msg.sender][_campaignId].investedAmt * (10000 - (presaleShare))) /
                10000;
            if (campaigns[_campaignId].campaignData.preSaleToken != _USDT)
                _safeTransfer(_USDT, msg.sender, _downscale(IERC20(_USDT).decimals(), leftOverInvestment));
        }

        emit ClaimPreSaleTokensBlackListed(_campaignId, _reward, leftOverInvestment, preSale, msg.sender);
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

    function setNewAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "ZA");
        emit UpdateAdmin(admin, _newAdmin, block.timestamp);
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

    /**
     * @notice Reverses the upscaling applied to `amount`, resulting in a smaller or equal value depending on
     * whether it needed scaling or not
     */
    function _downscale(uint256 tokenDecimals, uint256 _amount) private pure returns (uint256) {
        // Tokens with more than 18 decimals are not supported.
        uint256 decimalsDifference = 18 - tokenDecimals;
        return _amount / (10**decimalsDifference);
    }

    function withdrawPenaltyAndUpdateAddress(address[6] memory _setNewAddresses, bool wantToWithdraw)
        external
        onlyAdmin
    {
        uint256 penalty;
        if (!wantToWithdraw) {
            require(
                _setNewAddresses[0] != address(0) &&
                    _setNewAddresses[1] != address(0) &&
                    _setNewAddresses[2] != address(0),
                "ZA"
            );
            _stakingContract = _setNewAddresses[0];
            operator = _setNewAddresses[1];
            _vault = _setNewAddresses[2];

            if (_setNewAddresses[4] != address(0)) {
                oracle = _setNewAddresses[3];
                kolToken = _setNewAddresses[4];
                uniswapRouterv2 = _setNewAddresses[5];
            }
        } else {
            penalty = penaltyAmount;
            penaltyAmount = 0;
            _safeTransfer(_USDT, msg.sender, _downscale(IERC20(_USDT).decimals(), penalty));
        }
        emit WithdrawPenaltyAndUpdateAddress(_setNewAddresses, penalty);
    }

    function withdrawPresaleByCampaignOwner(uint256 _campaignId) external nonReentrant onlyCampaignOwners(_campaignId) {
        Campaign memory campaignDetails = retriveCampaign(_campaignId);

        // require(campaignDetails.campaignData.endDate < block.timestamp, "TA");

        (uint256 totalPresaleDeposited, uint256 shareOfKolsInTermsToken) = checkDepositedPresaleAndShareOfKol(
            _campaignId
        );

        require(shareOfKolsInTermsToken <= totalPresaleDeposited, "IA");

        uint256 transferPresale = totalPresaleDeposited -
            shareOfKolsInTermsToken -
            campaigns[_campaignId].campaignData.presaleWithdrawn;

        require(transferPresale != 0, "IF");
        require(transferPresale <= campaignDetails.campaignData.presaleAmount, "IA");

        campaigns[_campaignId].campaignData.presaleWithdrawn += transferPresale;
        campaigns[_campaignId].campaignData.presaleAmount -= transferPresale;

        _safeTransfer(
            campaignDetails.campaignData.preSaleToken,
            msg.sender,
            _downscale(IERC20(campaignDetails.campaignData.preSaleToken).decimals(), transferPresale)
        );

        emit WithdrawPresaleByCampaignOwner(_campaignId, msg.sender, shareOfKolsInTermsToken, transferPresale);
    }

    function withdrawPresaleAfterCampaignEnd(uint256 _campaignId, uint256 amountToWithdraw) external onlyAdmin {
        // require(campaigns[_campaignId].campaignData.endDate + 30 days * 8 < block.timestamp, "TNP");

        address preSaleToken = campaigns[_campaignId].campaignData.preSaleToken;
        require(campaigns[_campaignId].campaignData.presaleAmount >= amountToWithdraw, "IF");

        _safeTransfer(preSaleToken, admin, _downscale(IERC20(preSaleToken).decimals(), amountToWithdraw));
        campaigns[_campaignId].campaignData.presaleAmount -= amountToWithdraw;
        emit WithdrawPresaleByAdmin(_campaignId, amountToWithdraw);
    }

    function calculateReward(
        uint256 _campaignId,
        address _kol,
        uint256 progress
    )
        public
        view
        returns (
            uint256 _reward,
            uint256 _vesting,
            uint256 totalPresaleDeposited,
            bool timePassed
        )
    {
        InvestedCampaign memory investmentDetails = investedCampaignDetails[_kol][_campaignId];
        if (campaigns[_campaignId].tgeDetails.tgeDate > block.timestamp || !campaigns[_campaignId].tgeDetails.isTGE) {
            return (_reward, _vesting, totalPresaleDeposited, timePassed);
        }
        if (campaigns[_campaignId].vestingData.isVestingEnabled) {
            (timePassed, _vesting) = checkAboutVesting(_campaignId);
            totalPresaleDeposited =
                (
                    (campaigns[_campaignId].campaignData.enteredInvestmentAgainstMarketingBudget *
                        campaigns[_campaignId].campaignData.marketingBudget)
                ) /
                campaigns[_campaignId].campaignData.requiredInvestment;
            totalPresaleDeposited = (totalPresaleDeposited -
                (campaigns[_campaignId].tgeDetails.tgeAmount + campaigns[_campaignId].campaignData.stakingAmount));
            if (_vesting > totalPresaleDeposited / campaigns[_campaignId].vestingData.vestingAmtPerCycle) {
                _vesting = totalPresaleDeposited / campaigns[_campaignId].vestingData.vestingAmtPerCycle;
            }
            _vesting =
                (investmentDetails.investShare * campaigns[_campaignId].tgeDetails.tgeAmount) /
                (100 * 10**18) +
                (_vesting * investmentDetails.vestingRewardPerCycle);

            uint256 totalReward = (investmentDetails.eligibleReward * progress) / 10000;

            _reward = _vesting >= totalReward ? totalReward : _vesting;

            _reward = _reward - investedCampaignDetails[_kol][_campaignId].claimedReward;
        } else {
            _reward =
                ((investedCampaignDetails[_kol][_campaignId].eligibleReward * progress) / 10000) -
                investedCampaignDetails[_kol][_campaignId].claimedReward;
        }
    }

    function checkAboutVesting(uint256 _campaignId) internal view returns (bool timePassed, uint256 _vesting) {
        _vesting =
            (block.timestamp - campaigns[_campaignId].tgeDetails.tgeDate) /
            campaigns[_campaignId].vestingData.vestingCycleDuration;

        timePassed = _vesting >= campaigns[_campaignId].vestingData.NumberOfvestings;
    }

    function checkDepositedPresaleAndShareOfKol(uint256 _campaignId)
        internal
        view
        returns (uint256 totalPresaleDeposited, uint256 shareOfKolsInTermsToken)
    {
        Campaign memory campaignDetails = retriveCampaign(_campaignId);
        shareOfKolsInTermsToken = (
            (
                (((campaignDetails.campaignData.requiredInvestment - campaignDetails.campaignData.remainingInvestment) *
                    1e18) / campaignDetails.campaignData.requiredInvestment)
            )
        );
        uint256 marketingBudget = campaignDetails.campaignData.marketingBudget;

        shareOfKolsInTermsToken =
            (shareOfKolsInTermsToken * (marketingBudget - campaigns[_campaignId].campaignData.stakingAmount)) /
            1e18;

        totalPresaleDeposited =
            (campaignDetails.campaignData.enteredInvestmentAgainstMarketingBudget * marketingBudget) /
            campaignDetails.campaignData.requiredInvestment -
            campaigns[_campaignId].campaignData.stakingAmount;
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

    struct CampaignDetails {
        address preSaleToken;
        address campaignOwner;
        address secondOwner;
        uint256 requiredInvestment;
        uint256 marketingBudget;
        uint256 startDate;
        uint256 endDate;
        uint256 remainingInvestment;
        uint256 stakingAmount;
        uint256 enteredInvestmentAgainstMarketingBudget;
        uint256 investmentClaimed;
        uint256 presaleAmount;
        uint256 presaleWithdrawn;
    }

    struct VestingDetails {
        bool isVestingEnabled;
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
        uint256 campaignNumber;
        uint256 investedAmt;
        uint256 investShare;
        uint256 eligibleReward;
        uint256 vestingRewardPerCycle;
        uint256 claimedReward;
        uint256 rewardAfterBlacklist;
    }

    struct KOL {
        address kolWallet;
        uint256 kolID;
        string name;
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

    event WithdrawPresaleByAdmin(uint256 campaignID, uint256 amount);

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
        uint256 _leftOverCampaignInvestment,
        address _preSaleToken,
        address _kol
    );
    event InvestInCampaign(uint256 campaign_Id, uint256 _amount, uint256 _investmentShare, address _kol);
    event ClaimKolInvestment(uint256 campaign_Id, uint256 _investment, address _kol);
    event ClaimBackInvestment(uint256 campaign_Id, uint256 _progress, uint256 _investment, address _kol);
    event SetMaxTGEAllowance(uint256 _tge);
    event SetPenalty(uint256 _penalty);
    event BlackListedKol(address Kol, uint256 campaignId, uint256 progress, uint256 leftOverInvestment);
    event UpdateAdmin(address oldAdmin, address NewAdmin, uint256 timestamp);
    event WithdrawPresaleByCampaignOwner(
        uint256 campaignId,
        address owner,
        uint256 shareOfKolsInTermsToken,
        uint256 transferPresale
    );
    event WithdrawPenaltyAndUpdateAddress(address[6] _setNewAddresses, uint256 penaltyAmount);
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

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOracleV2 {
    function fetchKOLPrice(uint256 amountIn) external returns (uint256 amountOut);

    function fetchUSDTPrice(address token, uint256 amountIn) external returns (uint256 amountOut);
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

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
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

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
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

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
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

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
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

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
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

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
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

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
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

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
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

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
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

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
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

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
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

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
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

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
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

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
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

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
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

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
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

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
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

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
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

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
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

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
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

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
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

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
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

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
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

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
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

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
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

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
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

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
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

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
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

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
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

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
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

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
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

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
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

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
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

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
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

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
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

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
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

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
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

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
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

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
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

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
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

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
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