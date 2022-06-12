// SPDX-License-Identifier: MIT
/**
    @title RFSale
    @author farruhsydykov
 */
pragma solidity ^0.8.0;

import "./cryptography/ECDSAUpgradeable.sol";
import "./UpgradeableUtils/PausableUpgradeable.sol";
import "./UpgradeableUtils/ReentrancyGuardUpgradeable.sol";
import "./UpgradeableUtils/SafeERC20Upgradeable.sol";
import "./UpgradeableUtils/MerkleProofUpgradeable.sol";

import "./interfaces/IAdmin.sol";
import "./interfaces/IRFSale.sol";
import "./interfaces/IRFSaleFactory.sol";
import "./interfaces/IRFAllocationStaking.sol";

contract RFSale is IRFSale, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Rounds must be set in correct order: MERCH => DEALER => BROKER => TYCOON.
    struct TierRoundInfo {
        // Which Tier can participate in this round.
        Tier roundForTier;
        // Amount of tokens available for tier.
        uint256 tokensAvailable;
        // Amount of tokens purchased by tier memebers.
        uint256 tokensPurchased;
        // Minimal amount of payment tokens user can purchase sale tokens for.
        uint256 minBuyAmountInPaymentTokens;
        // Maximal amount of payment tokens user can purchase sale tokens for.
        uint256 maxBuyAmountInPaymentTokens;
    }

    struct Participation {
        // Round index user participated in.
        // Merch - 0, Dealer - 1, Broker - 2, Tycoon - 3, Fan - 4
        uint256 roundIndex;
        // Amount of tickets user registered for whitelist
        uint256 ticketsAmount;
        // Amount of sale tokens bought.
        uint256 amountBought;
        // Amount of sale tokens userPaidFor.
        uint256 amountPayedFor;
        // Payment tokens amount payed for tokens.
        uint256 amountOfPaymentTokensPaid;
        // Timestamp when purchase was made.
        uint256 timeRegistered;
        // Was a portion withdrawn from vesting.
        bool[] isPortionWithdrawn;
    }

    // Merkle root hash for MERCHANTs.
    bytes32 public whitelistRootHashForMerchants;
    // Merkle root hash for DEALERs.
    bytes32 public whitelistRootHashForDealers;

    // Admin contract.
    IAdmin public admin;
    // Token in which payment for token sold will occure.
    IERC20Upgradeable public paymentToken;
    // Pointer to Sales Factory.
    IRFSaleFactory public salesFactory;
    // Pointer to Allocation staking contract, where tier and ticket information and will be retrieved from.
    IRFAllocationStaking public allocationStaking;
    // Address of tokens that is being sold.
    IERC20Upgradeable public saleToken;
    // Is sale created.
    bool public isSaleCreated;
    // Were sale tokens funded for sale.
    bool public saleFunded;
    // Is FAN round set
    bool public fanRoundSet;
    // Address of the sale owner (usually a member of the token team).
    address public saleOwner;
    // 10**18
    uint256 public ONE;
    // Price of sale token in payment tokens.
    uint256 public tokenPriceInPaymentToken;
    // Amount of sale tokens deposited for sale.
    uint256 public amountOfSaleTokensDeposited;
    // Amount of tokens sold.
    uint256 public amountOfSaleTokensSold;
    // Amount of payment tokens raised.
    uint256 public amountOfPaymentTokensRaised;
    // Timestamp when registration starts.
    uint256 public registrationTimeStarts;
    // Timestamp when registration ends.
    uint256 public registrationTimeEnds;
    // Number of users registered for sale. Include those who was not whitelisted.
    uint256 public numberOfRegistrants;
    // Precision for calculating tokensAvailable for TierRoundIndo.
    uint256 public precisionForTierRoundPortions;

    // Array of rounds.
    // Rounds must be set in correct order: MERCH => DEALER => BROKER => TYCOON => FAN.
    TierRoundInfo[] public rounds;
    // Mapping if user is registered or not.
    mapping(address => bool) public hasRegistered;
    // Mapping user to his participation.
    mapping(address => Participation) public userToParticipation;
    // Mapping of users who was not whitelisted and claimed their payment tokens.
    mapping(address => bool) public userClaimedPaymentTokens;
    // Mapping of signatures that were already used.
    mapping(bytes => bool) public usedSignatures;
    // Mapping of used message hashes.
    mapping(bytes32 => bool) public usedMessageHashes;
    // Times when portions are getting unlocked.
    uint256[] public vestingPortionsUnlockTime;
    // Percent of the participation user can withdraw.
    uint256[] public vestingPercentPerPortion;
    // All merchant users who have registered for sale.
    address[] public registeredMerchants;
    // All dealer users who have registered for sale.
    address[] public registeredDealers;
    // address of the backend.
    address public backend;

    // * * * EVENTS * * * //
    
    event SaleTokenSet(address indexed _saleToken);
    event TokenPriceSet(uint256 _prevPrice, uint256 _newPrice);
    event SaleFunded(address indexed _saleToken, uint256 _amountFunded);
    event WhitelistRootHashesSet(bytes32 _whitelistRootHashForMerchants, bytes32 _whitelistRootHashForDealers);
    event SaleCreated(
        address indexed _saleToken,
        address indexed _saleOwner,
        uint256 _tokenPriceInPaymentToken
    );
    event RoundSet(
        Tier indexed _roundForTier,
        address indexed _saleToken,
        uint256 _tokensAvailable,
        uint256 _minBuyAmountInPaymentToken,
        uint256 _maxBuyAmountInPaymentToken
    );
    event UserRegistered(
        address indexed _user,
        Tier indexed _tier,
        uint256 _saleTokensAmountPayedFor,
        uint256 _paymentTokensPayed
    );
    event RegistrationTimeSet (
        address indexed _saleToken,
        uint256 _registrationTimeStarts,
        uint256 _registrationTimeEnds
    );
    event VestingParamsSet(
        uint256[] _vestingPortionsUnlockTime,
        uint256[] _vestingPercentPerPortion
    );
    event RegistrationPeriodExtended(
        uint256 _prevRegistrationTimeStarts,
        uint256 _newRegistrationTimeStarts,
        uint256 _prevRegistrationTimeEnds,
        uint256 _newRegistrationTimeEnds
    );
    event SaleTokensWithdrawn(address indexed _user, uint256 _saleTokensAmount);
    event RaisedPaymentTokensWithdrawn(address indexed _user, uint256 _paymentTokensAmount);
    event WithdrawLeftoverSaleTokens(address indexed _user, uint256 _saleTokensAmount);

    // * * * MODIFIERS * * * //

    /**
        @dev Modifier to check if FAN round is already set.
     */
    modifier checkIsFanRoundSet(bool _withdraw) {
        string memory err = "Fan round must be set.";
        if (_withdraw) {
            err = "You can withdraw raised payment tokens only after fan round was set or sale finished.";
            require(fanRoundSet, err);
        }
        else {
            require(fanRoundSet, err);
        }
        _;
    }

    /**
        @dev Modifier that checks if sale sale token is already set.
     */
    modifier saleTokenIsSet() {
        require(address(saleToken) != address(0), "Sale token address must be set");
        _;
    }

    // * * * MODIFIERS AS FUNCTIONS * * * //

    /**
        @dev Function that serves as a modifer to check if regisrtation time is set.
     */
    function registrationTimeIsSet() private view {
        require(registrationTimeStarts != 0, "You must set registration time first.");
    }

    /**
        @dev Function that serves as a modifer to check if portions are already available.
     */
    function portionsAreAvailable() private view {
        require(
            block.timestamp >= vestingPortionsUnlockTime[0],
            "Vesting period has not yet come."
        );
    }

    /**
        @dev Function that serves as a modifer to check if the caller is sale owner.
     */
    function onlySaleOwner() private view {
        require(_msgSender() == saleOwner, "Only for sale owner.");
    }

    /**
        @dev Function that serves as a modifer to check if sale is already created.
     */
    function checkIsSaleCreated() private view {
        require(isSaleCreated, "Sale must be created");
    }

    /**
        @dev Function that serves as a modifer to check if caller is admin.
     */
    function onlyAdmin() private {
        require(
            admin.isAdmin(_msgSender()),
            "Only admin can call this function."
        );
    } 

    // /**
    //     @dev Sale contract should always be deployed through salesFactory.
    //     @param _admin Address of the Admin contract.
    //     @param _allocationStaking Address of the allocationStaking contract.
    //  */
    // constructor(address _admin, address _saleFactory, address _allocationStaking) {
    //     require(_admin != address(0));
    //     require(_allocationStaking != address(0));
    //     admin = IAdmin(_admin);
    //     salesFactory = IRFSaleFactory(_saleFactory);
    //     allocationStaking = IRFAllocationStaking(_allocationStaking);
        
    //     ONE = 1000000000000000000;
    //     precisionForTierRoundPortions = 10000;
    // }

    // * * * EXTERNAL FUNCTIONS * * * //

    /**
        @dev Initializes this contract.
        @param _admin Admin contract address.
        @param _saleFactory Address of the sales factory.
        @param _allocationStaking Address of the allocationStaking contract.
     */
    function initialize(address _admin, address _saleFactory, address _allocationStaking, address _backend) external initializer {
        require(IAdmin(_admin).isAdmin(_msgSender()), "Only Admin can initialize this contract");
        require(_admin != address(0));
        require(_saleFactory != address(0));
        require(_allocationStaking != address(0));
        admin = IAdmin(_admin);
        salesFactory = IRFSaleFactory(_saleFactory);
        allocationStaking = IRFAllocationStaking(_allocationStaking);
        backend = _backend;

        __Context_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();

        ONE = 1000000000000000000;
        precisionForTierRoundPortions = 10000;
    }

    /**
        @dev Function to pause the contract.
     */
    function pause() external {
        onlyAdmin();
        _pause();
    }

    /**
        @dev Function to unpause the contract.
     */
    function unpause() external {
        onlyAdmin();
        _unpause();
    }

    /**
        @dev Function to set sale parameters.
        @param _saleToken Address of the token being sold.
        @param _paymentToken Address of the token in which payment for token sold will occure.
        @param _saleOwner Address of the sale owner.
        @param _tokenPriceInPaymentToken Token price in payment token.
     */
    function setSaleParams(
        address _saleToken,
        address _paymentToken,
        address _saleOwner,
        uint256 _tokenPriceInPaymentToken
    )
    external
    override
    {
        onlyAdmin();
        require(!isSaleCreated, "Sale is already created.");
        require(_saleOwner != address(0) && _paymentToken != address(0), "_saleOwner and _paymentToken can not be address(0).");

        if (_saleToken != address(0)) saleToken = IERC20Upgradeable(_saleToken);

        paymentToken = IERC20Upgradeable(_paymentToken);
        saleOwner = _saleOwner;
        tokenPriceInPaymentToken = _tokenPriceInPaymentToken;

        isSaleCreated = true;

        emit SaleCreated(_saleToken, _saleOwner, _tokenPriceInPaymentToken);
    }

    /**
        @dev Function to retroactively set sale token address, can be called only once,
        after initial contract creation has passed. Added as an options for teams which
        are not having token at the moment of sale launch.
        @param _saleToken Address of the token to be sold.
     */
    function setSaleToken(address _saleToken) external override {
        checkIsSaleCreated();
        onlyAdmin();
        require(address(saleToken) == address(0), "Sale token address is already set.");
        saleToken = IERC20Upgradeable(_saleToken);

        emit SaleTokenSet(_saleToken);
    }

    /**
        @dev Function for owner to deposit tokens, can be called only once.
        @param _amountFunded Amount of sale tokens to be funded.
        @notice Sale must be created & sale token must be set.
     */
    function fundSale(uint256 _amountFunded) external override saleTokenIsSet {
        checkIsSaleCreated();
        require(_msgSender() == saleOwner || admin.isAdmin(_msgSender()), "Only for sale owner.");
        require(saleFunded == false, "Sale is already funded");
        require(_amountFunded > 0, "Amount funded to sale must be greater than 0");

        amountOfSaleTokensDeposited = _amountFunded;
        saleFunded = true;

        saleToken.safeTransferFrom(_msgSender(), address(this), _amountFunded);

        emit SaleFunded(address(saleToken), _amountFunded);
    }

    /**
        @dev Function to set registration period.
        @param _registrationTimeStarts Timestamp when registration starts.
        @param _registrationTimeEnds Timestamp when registration ends.
     */
    function setRegistrationTime(
        uint256 _registrationTimeStarts,
        uint256 _registrationTimeEnds
    )
    external
    override {
        checkIsSaleCreated();
        onlyAdmin();
        require(registrationTimeStarts == 0, "Registration period is already set.");
        require(
            _registrationTimeStarts >= block.timestamp &&
            _registrationTimeEnds > _registrationTimeStarts,
            "Registration time starts must be earlier than it ends."    
        );

        // Set registration start and end time
        registrationTimeStarts = _registrationTimeStarts;
        registrationTimeEnds = _registrationTimeEnds;

        emit RegistrationTimeSet(address(saleToken), registrationTimeStarts, registrationTimeEnds);
    }

    /**
        @dev Set or reset vesting portions unlock time, percent per portion and vesting portion precision.
        @param _vestingPortionsUnlockTime Array of timestamps when vesting portions will be available.
        @param _vestingPercentPerPortion Array of portions available each vesting period.
        @param _initialSetup Must be true when setting up these values for the first time.
        @notice Make sure that summ of all vesting portions is equal to vesting precision.
        Make sure that all portions are set in whole numbers i.e. 833, not 833.333. 
        For example if there are 12 vesting periods vesting precision is 10,000
        then first 11 portions must be 833 and last one 837.
        @notice When resetting some of the values, MAKE SURE that arrays contain the same amount of values.
     */
    function setVestingParams(
        uint256[] memory _vestingPortionsUnlockTime,
        uint256[] memory _vestingPercentPerPortion,
        bool _initialSetup
    ) external override saleTokenIsSet {
        registrationTimeIsSet();
        checkIsSaleCreated();
        onlyAdmin();
        if (_initialSetup) {
            require(
                _vestingPortionsUnlockTime[0] > registrationTimeEnds,
                "Vesting starts earlier than registration ends."
            );
            require(
                _vestingPortionsUnlockTime.length == _vestingPercentPerPortion.length,
                "_vestingPortionsUnlockTime and _vestingPercentPerPortion must be the same length."
            );
        } else {
            require(
                vestingPortionsUnlockTime[0] != 0 && vestingPercentPerPortion[0] != 0,
                "Resetting vesting parameters can be doe only they were already set."
            );
            require(
                vestingPortionsUnlockTime[0] > block.timestamp,
                "Vesting params can be reset only if first portion is not yet available."
            );
            require(
                _vestingPortionsUnlockTime.length != 0 || vestingPortionsUnlockTime.length != 0,
                "At least one of the arrays must be provided."
            );
        }
        
        uint256 portionsSum;
        uint256 lastTimestamp = block.timestamp;

        for (uint i = 0; i < _vestingPortionsUnlockTime.length; i++) {
            
            if (_vestingPortionsUnlockTime.length > 0) {
                require(
                    lastTimestamp < _vestingPortionsUnlockTime[i],
                    "One of _vestingPortionsUnlockTime members is earlier than previous."
                );
                vestingPortionsUnlockTime.push(_vestingPortionsUnlockTime[i]);
                
                lastTimestamp = _vestingPortionsUnlockTime[i];
            }
            
            if (_vestingPercentPerPortion.length > 0) {
                vestingPercentPerPortion.push(_vestingPercentPerPortion[i]);

                portionsSum += _vestingPercentPerPortion[i];
            }
        }

        if (_vestingPercentPerPortion.length != 0) require(portionsSum == precisionForTierRoundPortions, "Sum of all portions is not 100%.");

        emit VestingParamsSet(_vestingPortionsUnlockTime, _vestingPercentPerPortion);
    }

    /**
        @dev Setting sale rounds for tiered users.
        @param _portionsOfTotalAmountOfTokensPerRound Array of tokens portions available per round.
        Must be provided as 1000 per 10% i.e. 2450 for 24.5% of total tokens amount.
        Portions for tier rounds must be correlated to 100% i.e. 35% of 70% for tiers must be set as 2450 (24.5%)
        from the whole amount.
        @param _minBuyAmountInPaymentToken Minimal amount of payment tokens to pay for a purchase.
        @param _maxBuyAmountInPaymentToken Maximal amount of payment tokens to pay for a purchase.
        @notice All arrays must be the same size and their size must be 4, one for each tier starting from
        MERCHANT => DEALER => BROKER => TYCOON.
        ! ! ! You can only set rounds once ! ! !
     */
    function setTierRoundInfo(
        uint256[] calldata _portionsOfTotalAmountOfTokensPerRound,
        uint256[] calldata _minBuyAmountInPaymentToken,
        uint256[] calldata _maxBuyAmountInPaymentToken
    ) external override {
        checkIsSaleCreated();
        onlyAdmin();
        require(rounds.length == 0, "Rounds were already set.");
        require(saleFunded, "Sale must be funded.");
        require(
            _portionsOfTotalAmountOfTokensPerRound.length == 4 &&
            _portionsOfTotalAmountOfTokensPerRound.length == _minBuyAmountInPaymentToken.length &&
            _minBuyAmountInPaymentToken.length == _maxBuyAmountInPaymentToken.length,
            "Both arrays length must be equal to 4 and same length."
        );

        uint256 sum;
        for (uint256 i = 0; i < _portionsOfTotalAmountOfTokensPerRound.length; i++) {
            sum += _portionsOfTotalAmountOfTokensPerRound[i];
        }

        require(sum == precisionForTierRoundPortions, "Summ of all portions is not 100%");

        Tier tier;
        uint256 tokensAvailable;

        for (uint256 i = 0; i < _portionsOfTotalAmountOfTokensPerRound.length; i++) {
            sum += _portionsOfTotalAmountOfTokensPerRound[i];

            require(
                _minBuyAmountInPaymentToken[i] > 0 &&
                _minBuyAmountInPaymentToken[i] < _maxBuyAmountInPaymentToken[i] &&
                _portionsOfTotalAmountOfTokensPerRound[i] > 0,
                "_minBuyAmountInPaymentToken is zero, _minBuyAmountInPaymentToken is higher than _maxBuyAmountInPaymentToken or one of _portionsOfTotalAmountOfTokensPerRound is zero."
            );

            if (i == 0) tier = Tier.MERCHANT;
            if (i == 1) tier = Tier.DEALER;
            if (i == 2) tier = Tier.BROKER;
            if (i == 3) tier = Tier.TYCOON;

            tokensAvailable = 
                amountOfSaleTokensDeposited * _portionsOfTotalAmountOfTokensPerRound[i] / precisionForTierRoundPortions;

            // Create round
            TierRoundInfo memory round = TierRoundInfo({
                roundForTier: tier,
                tokensAvailable: tokensAvailable,
                tokensPurchased: 0,
                minBuyAmountInPaymentTokens: _minBuyAmountInPaymentToken[i],
                maxBuyAmountInPaymentTokens: _maxBuyAmountInPaymentToken[i]
            });

            // Push this round to rounds array
            rounds.push(round);

            // Emit event
            emit RoundSet(tier, address(saleToken), tokensAvailable, _minBuyAmountInPaymentToken[i], _maxBuyAmountInPaymentToken[i]);
        }
    }

    /**
        @dev Function to purchase a portion. MERCHANTs and DEALERs are only registered for further ruffle.
        @param _paymentTokenAmountToPay Amount of payment tokens user is willing to pay. 
     */
    function registerForSale(uint256 _paymentTokenAmountToPay) external override whenNotPaused {
        checkIsSaleCreated();
        require(_paymentTokenAmountToPay != 0, "You can't pay 0 payment tokens.");

        Tier tier = allocationStaking.getCurrentTier(_msgSender());

        uint256 roundIndex;
        if (tier == Tier.MERCHANT) roundIndex = 0;
        if (tier == Tier.DEALER) roundIndex = 1;
        if (tier == Tier.BROKER) roundIndex = 2;
        if (tier == Tier.TYCOON) roundIndex = 3;
        if (tier == Tier.FAN) roundIndex = 4;

        if (roundIndex == 4) require(fanRoundSet, "Fan round has not yet started."); 

        _registerUser(roundIndex, _paymentTokenAmountToPay);

        numberOfRegistrants++;
    }

    /**
        @dev Function get all addresses registered for sale as merchants.
        @param _startIndex Index of the first address to return.
        @param _endIndex Index of the last address to return.
     */
    function getRegisteredMerchantsAddresses(uint256 _startIndex, uint256 _endIndex) external override view returns (address[] memory _addresses) {
        require(block.timestamp >= registrationTimeEnds, "You can only get registered merchants after registration time ends.");
        require(registeredMerchants.length != 0, "There is nothing to request.");
        require(
            _startIndex < _endIndex,
            "Requested starting index must be less than endin index."
        );

        uint256 counter;
        for (uint i; i < registeredMerchants.length; i++) {
            if (registeredMerchants[i] != address(0)) counter++;
        }

        address[] memory addresses_ = new address[](counter);

        uint256 j;
        for (uint256 i = _startIndex; (i < _endIndex && i < registeredMerchants.length); i++) {
            addresses_[j] = registeredMerchants[i];
            j++;
        }
        _addresses = addresses_;
        return _addresses;
    }

    /**
        @dev Function get all addresses registered for sale as dealers.
        @param _startIndex Index of the first address to return.
        @param _endIndex Index of the last address to return.
     */
    function getRegisteredDealersAddresses(uint256 _startIndex, uint256 _endIndex) external override view returns (address[] memory _addresses) {
        require(block.timestamp >= registrationTimeEnds, "You can only get registered merchants after registration time ends.");
        require(registeredDealers.length != 0, "There is nothing to request.");
        require(
            _startIndex < _endIndex,
            "Requested starting index must be less than endin index."
        );

        uint256 counter;
        for (uint i; i < registeredDealers.length; i++) {
            if (registeredDealers[i] != address(0)) counter++;
        }

        address[] memory addresses_ = new address[](counter);

        uint256 j;
        for (uint256 i = _startIndex; (i < _endIndex && i < registeredDealers.length); i++) {
            addresses_[j] = registeredDealers[i];
            j++;
        }
        _addresses = addresses_;
        return _addresses;
    }

    /**
        @dev Function to claim available for withdrawal tokens.
        @param _merkleProof Merkle proof of the user's participation in the round.
     */
    function claimTokens(bytes32[] calldata _merkleProof, bytes32 _hash, bytes memory _signature) external override nonReentrant whenNotPaused {
        require(usedSignatures[_signature] == false, "Signature is already used.");
        require(usedMessageHashes[_hash] == false, "Message hash is already used.");
        require(_isSignedByBackend(_hash, _signature), "Message must be signed by backend.");
        usedSignatures[_signature] = true;
        usedMessageHashes[_hash] = true;

        // check if vesting portions are already unlocked
        portionsAreAvailable();
        Participation storage p = userToParticipation[_msgSender()];
        TierRoundInfo storage r = rounds[p.roundIndex];

        // checking if user is registered for a sale
        // _userRegisteredForSale(_msgSender(), false);
        require(hasRegistered[_msgSender()], "You are not registered for a sale.");
        
        // checking if user has already claimed all tokens portions
        require(!userClaimedPaymentTokens[_msgSender()], "User has already claimed his payment tokens.");
        // check if whitelist root hash is already set
        isWhitelistRootHashSet();

        if (r.roundForTier == Tier.MERCHANT || r.roundForTier == Tier.DEALER) {
            require(_merkleProof.length != 0, "Merkle proof must be provided for MERCHNATS and DEALERS.");
            bool isWhitelisted = checkWhitelist(_msgSender(), _merkleProof, userToParticipation[_msgSender()].roundIndex);
            
            if (isWhitelisted == false) {
                require(p.isPortionWithdrawn[0] != true, "You have already claimed a portion.");
                userClaimedPaymentTokens[_msgSender()] = true;
                // transfer users payment tokens
                paymentToken.safeTransfer(_msgSender(), p.amountOfPaymentTokensPaid);
                return;
            }
        }

        // amount user can withdraw from vesting
        uint256 amountToWithdraw;
        for (uint256 i; i < vestingPortionsUnlockTime.length; i++) {
            if (i == 0 && p.isPortionWithdrawn[i] != true && r.roundForTier == Tier.MERCHANT || r.roundForTier == Tier.DEALER) {
                // if Merchant or Dealer were whitelisted and claimed their
                // sale tokens increase p.amountBought and
                // r.tokensPurchased only once to avoid overflows
                p.amountBought = p.amountPayedFor;
                r.tokensPurchased += p.amountBought;
                // instead of next line, total amount of payment tokens raised
                // by Merchants and Dealers will be incremented in setWhitelistRootHash()
            }
            if (vestingPortionsUnlockTime[i] <= block.timestamp && p.isPortionWithdrawn[i] != true) {
                // adding available portion to amount that is now available to withdraw
                amountToWithdraw += p.amountBought * vestingPercentPerPortion[i] / precisionForTierRoundPortions;
                // setting this portion as already withdrawn
                p.isPortionWithdrawn[i] = true;
            }
            if (i == vestingPortionsUnlockTime.length - 1 && p.isPortionWithdrawn[vestingPortionsUnlockTime.length - 1] == true) {
                // if user has already withdrawn all portions
                // set userClaimedPaymentTokens to true
                userClaimedPaymentTokens[_msgSender()] = true;
            }
        }
        // checking if user has any available portions to withdraw
        require(amountToWithdraw != 0, "There is no more available tokens to withdraw yet.");

        saleToken.safeTransfer(_msgSender(), amountToWithdraw);

        emit SaleTokensWithdrawn(_msgSender(), amountToWithdraw);
    }

    /**
        @dev Returns user's information on vesting portions.
        @param _user Address of the user who's portions are checked.
        @return arePortionsWithdrawn_ Array of booleans representing how much portions are available and if they are withdrawn. 
     */
    function getUserPortionsInfo(address _user) external override view whenNotPaused returns(bool[] memory arePortionsWithdrawn_) {
        portionsAreAvailable();
        Participation storage p = userToParticipation[_user];
        
        arePortionsWithdrawn_ = p.isPortionWithdrawn;

        return arePortionsWithdrawn_;
    }

    /**
        @dev Function to set FAN round.
        @param _minBuyAmountInPaymentToken Minimum amount of payment tokens user need to pay to participate in FAN round.
        @param _maxBuyAmountInPaymentToken Maximum amount of payment tokens user need to pay to participate in FAN round.
     */
    function startFanRound(
        uint256 _minBuyAmountInPaymentToken,
        uint256 _maxBuyAmountInPaymentToken
    )
    external
    override {
        onlyAdmin();
        // calculate how many tokens left arfter tier rounds bought
        uint256 tokensLeftAfterRegistrationPeriod = amountOfSaleTokensDeposited - amountOfSaleTokensSold;

        require(
            tokensLeftAfterRegistrationPeriod != 0 &&
            saleToken.balanceOf(address(this)) - amountOfSaleTokensSold == tokensLeftAfterRegistrationPeriod &&
            _minBuyAmountInPaymentToken < _maxBuyAmountInPaymentToken &&
            isWhitelistRootHashSet(),
            "Whitelist root hash is not set, there are no tokens left after registration period or min buy amount is bigger than max buy amout."
        );
        
        // Create round
        TierRoundInfo memory round = TierRoundInfo({
            roundForTier: Tier.FAN,
            tokensAvailable: tokensLeftAfterRegistrationPeriod,
            tokensPurchased: 0,
            minBuyAmountInPaymentTokens: _minBuyAmountInPaymentToken,
            maxBuyAmountInPaymentTokens: _maxBuyAmountInPaymentToken
        });
        // Push this round to rounds array
        rounds.push(round);
        // Set fanRoundSet as true
        fanRoundSet = true;
    }

    /**
        @dev Function to withdraw leftover sale tokens.
     */
    function withdrawLeftoverSaleTokens() external override {
        onlySaleOwner();
        require(fanRoundSet);
        require(vestingPortionsUnlockTime[1] <= block.timestamp, "Leftover sale tokens can be withdrawn only after first vesting portion is unlocked.");
        uint256 leftOverSaleTokens = amountOfSaleTokensDeposited - amountOfSaleTokensSold;
        require(leftOverSaleTokens != 0, "There are no sale tokens to withdraw.");

        // transfer sale tokens to sale owner
        saleToken.safeTransfer(saleOwner, leftOverSaleTokens);
        // emitting event
        emit WithdrawLeftoverSaleTokens(saleOwner, leftOverSaleTokens);
    }

    /**
        @dev Function to withdraw payment tokens raised
     */
    function withdrawPaymentTokensRaised() external override nonReentrant checkIsFanRoundSet(true) {
        onlyAdmin();
        require(
            amountOfPaymentTokensRaised != 0,
            "There is no more available tokens to withdraw yet."
        );
        // transfer payment tokens to sale owner
        uint256 amountToWithdraw = amountOfPaymentTokensRaised;
        // set amountOfPaymentTokensRaised to 0
        amountOfPaymentTokensRaised = 0;

        paymentToken.safeTransfer(saleOwner, amountToWithdraw);

        emit RaisedPaymentTokensWithdrawn(_msgSender(), amountToWithdraw);
    }

    /**
        @dev Function to set whitelist root hashes and increase total amount of purchased tokens.
        @param _amountOfTokensPurchasedByMerchants Calculated amount of tokens purchased by all whitelisted merchants.
        @param _amountOfTokensPurchasedByDealers Calculated amount of tokens purchased by all whitelisted dealers.
        @param _whitelistRootHashForMerchant Whitelist root hash for merchants.
        @param _whitelistRootHashForDealer Whitelist root hash for dealers.
     */
    function setWhitelistRootHashes(
        uint256 _amountOfTokensPurchasedByMerchants,
        uint256 _amountOfTokensPurchasedByDealers,
        bytes32 _whitelistRootHashForMerchant,
        bytes32 _whitelistRootHashForDealer
    )
    external
    override {
        onlyAdmin();
        require(
            _amountOfTokensPurchasedByMerchants <= rounds[0].tokensAvailable &&
            _amountOfTokensPurchasedByDealers <= rounds[1].tokensAvailable,
            "Amounts given for tiers exceed their maximum allowed values."
        );
        // check if registration period ended and whitelis root hashes are set
        require(block.timestamp >= registrationTimeEnds && !isWhitelistRootHashSet(), "Registration time has not finished or whitelists are already set.");

        // increasing amount of payment tokens raised by Merchants and Dealers
        amountOfPaymentTokensRaised += _amountOfTokensPurchasedByMerchants + _amountOfTokensPurchasedByDealers;
        // increase amount of sale tokens sold
        amountOfSaleTokensSold += _amountOfTokensPurchasedByMerchants + _amountOfTokensPurchasedByDealers;

        whitelistRootHashForMerchants = _whitelistRootHashForMerchant;
        whitelistRootHashForDealers = _whitelistRootHashForDealer;

        emit WhitelistRootHashesSet(_whitelistRootHashForMerchant, _whitelistRootHashForDealer);
    }

    /**
        @dev Function to change sale token price in payment token.
        @param _newPrice New price of sale token in payment token.
     */
    function updateTokenPriceInPaymentToken(uint256 _newPrice) external override {
        onlyAdmin();
        if (registrationTimeStarts != 0) {
            require(
                block.timestamp < registrationTimeStarts,
                "Token price is not yet set, _newPrice is 0 or registration has already started."
            );
        }

        uint256 prevPrice = tokenPriceInPaymentToken;
        tokenPriceInPaymentToken = _newPrice;

        emit TokenPriceSet(prevPrice, _newPrice);
    }

    /**
        @dev Function that can extend or postpone registration period.
        @param _timeToAdd Amount of time to add to registration period.
        @param _postpone if true, then change registrationTimeStarts also.
        @notice If _postpone is true, then _timeToAdd is added to registrationTimeStarts.
     */
    function extendRegistrationPeriod(uint256 _timeToAdd, bool _postpone) external override {
        registrationTimeIsSet();
        onlyAdmin();
        // check if registration has not yet ended
        require(
            registrationTimeEnds > block.timestamp,
            "You can change registration period only if it is not yet finished."
        );
        // check if registrationTimeEnds does not collide with first vesting period OR postpone it too
        require(
            registrationTimeEnds + _timeToAdd <= vestingPortionsUnlockTime[0],
            "You can postpone registration only if it does not collide with first vesting period."
        );

        uint256 prevRegistrationTimeStarts = registrationTimeStarts;
        uint256 prevRegistrationTimeEnds = registrationTimeEnds;

        // if _postpone is true, then add _timeToAdd to registrationTimeStarts
        if (_postpone) {
            // check if registration has not yet started
            require(
                block.timestamp < registrationTimeStarts,
                "You can only extend and not postpone registration period if it has already started."
            );
            // increase registrationTimeStarts timestamp
            registrationTimeEnds += _timeToAdd;
        }
        // increase registrationTimeEnds timestamp
        registrationTimeEnds += _timeToAdd;

        emit RegistrationPeriodExtended(
            prevRegistrationTimeStarts,
            registrationTimeStarts,
            prevRegistrationTimeEnds,
            registrationTimeEnds
        );
    }

    /**
        @dev Function that returns informatiob about rounds.
        @param _roundId Index of requested round information. 
        @return _tokensAvailable Amount of tokens available in the round.
        @return _tokensPurchased Amount of tokens purchased in the round.
        @return _minBuyAmountInPaymentTokens Minimum amount of payment tokens a user has to pay to participate in the round.
        @return _maxBuyAmountInPaymentTokens Maximum amount of payment tokens a user has to pay to participate in the round.
     */
    function getRoundInfo(uint256 _roundId) external override view returns(
        uint256 _tokensAvailable,
        uint256 _tokensPurchased,
        uint256 _minBuyAmountInPaymentTokens,
        uint256 _maxBuyAmountInPaymentTokens
    ) {
        require(rounds.length > 0, "Tier rounds are not yet set.");
        require(_roundId < rounds.length, "There is no round with this index.");

        TierRoundInfo storage round = rounds[_roundId];

        _tokensAvailable = round.tokensAvailable;
        _tokensPurchased = round.tokensPurchased;
        _minBuyAmountInPaymentTokens = round.minBuyAmountInPaymentTokens;
        _maxBuyAmountInPaymentTokens = round.maxBuyAmountInPaymentTokens;
    }

    /**
        @dev Function to check vesting portions unlock times and their percentages.
        @return vestingPortionsUnlockTime_ Array of timestamps when each portion will be unlocked.
        @return vestingPercentPerPortion_ Array of portions of purchased tokens that will be available each vesting period.
     */
    function getVestingInfo() external override view returns(uint256[] memory vestingPortionsUnlockTime_, uint256[] memory vestingPercentPerPortion_) {
        require(vestingPortionsUnlockTime.length != 0, "Vesting info is not yet set");

        vestingPortionsUnlockTime_ = vestingPortionsUnlockTime;
        vestingPercentPerPortion_ = vestingPercentPerPortion;

        return(
            vestingPortionsUnlockTime_,
            vestingPercentPerPortion_
        );
    }

    /**
        @dev Function to change backend address.
        @param _backendAddress New backend address.
     */
    function changeBackendAddress(address _backendAddress) external override {
        onlyAdmin();
        require(
            _backendAddress != address(0),
            "Backend address cannot be 0."
        );

        backend = _backendAddress;
    }

    // * * * PUBLIC FUNCTIONS * * * //

    /**
        @dev Function to get registration information of user.
        @param _user Address of the user whos info to get.
        @return roundId_ Id of the round user has participated.
        @return ticketsAmount_ Amount of tickets Merchant and Dealer users got when registered for sale.
        @return amountPayedFor_ Amount of tokens user paid for. 
        @notice Round ids are as followed:
        Merch - 0, Dealer - 1, Broker - 2, Tycoon - 3, Fan - 4.
     */
    function getUsersRegistryInfo(address _user)
    public
    override
    view
    returns(uint256 roundId_, uint256 ticketsAmount_, uint256 amountPayedFor_) {
        Participation storage p = userToParticipation[_user];

        _userRegisteredForSale(_user, false);

        return (
            p.roundIndex,
            p.ticketsAmount,
            p.amountPayedFor
        );
    }

    /**
        @dev Calls internal _checkWhitelist function depending in the _roundId user is participating.
        @param _user Address of the user to check if he is whitelisted.
        @param _merkleProof Merkle proof.
        @param _roundId 0 for Merchants, 1 for Dealers.
     */
    function checkWhitelist(
        address _user,
        bytes32[] calldata _merkleProof,
        uint256 _roundId
    )
    public
    override
    view
    returns(bool _userInWhitelist) {
        bytes32 rootHash;
        if (_roundId == 0) rootHash = whitelistRootHashForMerchants;
        else if (_roundId == 1) rootHash = whitelistRootHashForDealers;
        else revert("Incorrect round id provided.");

        require(rootHash[0] != 0, "Whitelist root hash is not yet set for this Tier.");

        // Compute merkle leaf from input
        bytes32 leaf = keccak256(abi.encodePacked(_user));
        // Verify merkle proof
        return MerkleProofUpgradeable.verify(_merkleProof, rootHash, leaf);
    }

    /**
        @dev Function to check if whitelist root hashes are set.
     */
    function isWhitelistRootHashSet() public override view returns(bool) {
        if (whitelistRootHashForMerchants[0] == 0 && whitelistRootHashForDealers[0] == 0)
        {
            return false;
        } else return true; 
    }

    // * * * INTERNAL FUNCTIONS * * * //

    /**
        @dev Internal function for registering a user depending on his/her tier.
        @param _roundIndex Index of the round user is registering.
        @param _paymentTokenAmount Amount of payment tokens user is willing to pay.
     */
    function _registerUser(uint256 _roundIndex, uint256 _paymentTokenAmount) internal {
        TierRoundInfo storage r = rounds[_roundIndex];
        Participation storage p = userToParticipation[_msgSender()];

        // setting this participation round index
        p.roundIndex = _roundIndex;
        // check if user has already registered
        _userRegisteredForSale(_msgSender(), true);
        // checking if user attempts to pay in the allowed range 
        require(
            _paymentTokenAmount >= r.minBuyAmountInPaymentTokens &&
            _paymentTokenAmount <= r.maxBuyAmountInPaymentTokens,
            "Amount of tokens to buy is not in allowed range."
        );

        if (_roundIndex != 4) {
            // check if current timestamp is in the registration period range
            require(
                block.timestamp >= registrationTimeStarts && block.timestamp <= registrationTimeEnds,
                "You can only register during registration time period."
            );
        } else {
            require(
                block.timestamp <= vestingPortionsUnlockTime[0] &&
                fanRoundSet &&
                allocationStaking.fanStakedForTwoWeeks(_msgSender()),
                "Fan round is not set, user hasn't staked RAISE for wto weeks or first portion is already unlocked."
            );
        }

        // calculate amount of sale tokens to buy
        uint256 tokensToBuy = _paymentTokenAmount * tokenPriceInPaymentToken / ONE;

        if (_roundIndex == 2 || _roundIndex == 3 || _roundIndex == 4) {
            // checking if there is enough sale tokens to purchase
            require(
                r.tokensAvailable - r.tokensPurchased >= tokensToBuy,
                "Not enought tokens left in this round."
            );
            // add amount of tokens purchased
            r.tokensPurchased += tokensToBuy;
            // as amountOfPaymentTokensRaised can be raised during registraion without
            // issues only when FANs, BROKERs and TYCOONs are registering, raising this value
            // for MERCHANTs and DEALERs accures while whitelists setting 
            amountOfPaymentTokensRaised += _paymentTokenAmount;
            // increasing amount of sale tokens sold
            amountOfSaleTokensSold += tokensToBuy;

            // add sale token purchased amount in round
            p.amountBought += tokensToBuy;
        }

        if (_roundIndex < 2) {
            p.ticketsAmount = allocationStaking.getTicketAmount(_msgSender());
            // saving merchant user's addresses for easier access when creating a merkle tree.
            if (_roundIndex == 0) registeredMerchants.push(_msgSender());
            // saving dealer user's addresses for easier access when creating a merkle tree.
            if (_roundIndex == 1) registeredDealers.push(_msgSender());
        }

        p.amountOfPaymentTokensPaid += _paymentTokenAmount;
        p.amountPayedFor += tokensToBuy;
        p.timeRegistered = block.timestamp;
        p.isPortionWithdrawn = new bool[](vestingPortionsUnlockTime.length);

        // setting user as already registered
        hasRegistered[_msgSender()] = true;
        // transfer payment tokens from user
        paymentToken.safeTransferFrom(_msgSender(), address(this), _paymentTokenAmount);
        // emitting event
        emit UserRegistered(_msgSender(), r.roundForTier, tokensToBuy, _paymentTokenAmount);
    }


    /**
        @dev Internal function that check if user is registered for sale.
        @param _user Address of user.
        @param _reversed Reverts if user is not registered for sale.
     */
    function _userRegisteredForSale(address _user, bool _reversed) internal view {
        if (_reversed) require(!hasRegistered[_user], "User is already registered for sale.");
        else require(hasRegistered[_user], "User is not registered for sale.");
    }

    function _isSignedByBackend(bytes32 _hash, bytes memory _signature) internal view returns(bool) {
        address signer = _recoverSigner(_hash, _signature);
        return signer == backend;
    }
    
    function _recoverSigner(bytes32 _hash, bytes memory _signature) internal pure returns(address) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32", 
                _hash
            )
        );
        return ECDSAUpgradeable.recover(messageDigest, _signature);
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "./StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;
// pragma solidity 0.8.9;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
pragma solidity ^0.8.0;
// pragma solidity 0.8.9;

import "./Initializable.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;
// pragma solidity 0.8.9;

import "./IERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;
// pragma solidity 0.8.9;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAdmin {
    function isAdmin(address _user) external returns(bool _isAdmin);
    function addAdmin(address _adminAddress) external;
    function removeAdmin(address _adminAddress) external;
    function getAllAdmins() external view returns(address [] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Enums.sol";

interface IRFSale is Enums {
    function setSaleParams(address _saleToken, address _paymentToken, address _saleOwner, uint256 _tokenPriceInPaymentToken) external;
    function setSaleToken(address _saleToken) external;
    function fundSale(uint256 _amountFunded) external;
    function setRegistrationTime(uint256 _registrationTimeStarts, uint256 _registrationTimeEnds) external;
    function setVestingParams(uint256[] memory _vestingPortionsUnlockTime, uint256[] memory _vestingPercentPerPortion, bool _initialSetup) external;
    function setTierRoundInfo(uint256[] calldata _portionsOfTotalAmountOfTokensPerRound, uint256[] calldata _minBuyAmountInPaymentToken, uint256[] calldata _maxBuyAmountInPaymentToken) external;
    function registerForSale(uint256 _paymentTokenAmountToPay) external;
    function getRegisteredMerchantsAddresses(uint256 _startIndex, uint256 _endIndex) external returns (address[] memory _addresses);
    function getRegisteredDealersAddresses(uint256 _startIndex, uint256 _endIndex) external returns (address[] memory _addresses);
    function claimTokens(bytes32[] calldata _merkleProof, bytes32 _hash, bytes memory _signature) external;
    function getUserPortionsInfo(address _user) external view returns(bool[] memory arePortionsWithdrawn_);
    function startFanRound(uint256 _minBuyAmountInPaymentToken, uint256 _maxBuyAmountInPaymentToken) external;
    function withdrawLeftoverSaleTokens() external;
    function withdrawPaymentTokensRaised() external;
    function getUsersRegistryInfo(address _user) external view returns(uint256 roundId_, uint256 ticketsAmount_, uint256 paymentTokenPaid_);
    function isWhitelistRootHashSet() external view returns(bool);
    function setWhitelistRootHashes(uint256 _amountOfTokensPurchasedByMerchants, uint256 _amountOfTokensPurchasedByDealers, bytes32 _whitelistRootHashForMerchant, bytes32 _whitelistRootHashForDealer) external;
    function checkWhitelist(address _user, bytes32[] calldata _merkleProof, uint256 _roundId) external view returns(bool _userInWhitelist);
    function updateTokenPriceInPaymentToken(uint256 _newPrice) external;
    function extendRegistrationPeriod(uint256 _timeToAdd, bool _postpone) external;
    function getRoundInfo(uint256 _roundId) external view returns(uint256 _tokensAvailable, uint256 _tokensPurchased, uint256 _minBuyAmountInPaymentTokens, uint256 _maxBuyAmountInPaymentTokens);
    function getVestingInfo() external view returns(uint256[] memory, uint256[] memory);
    function changeBackendAddress(address _backendAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRFSaleFactory {
    function initialize(address _adminContract, address _allocationStaking, address _saleContractImplementation)external;
    function deploySale(bytes memory _data) external;
    function changeSaleContractImplementation(address _newSaleContractImplementation) external;
    function setAllocationStaking(address _allocationStaking) external;
    function getNumberOfSalesDeployed() external view returns(uint256);
    function getLastDeployedSale() external view returns(address);
    function getSalesFromIndexToIndex(uint _startIndex, uint _endIndex) external view returns(address[] memory);
    function isSaleCreatedThroughFactory(address _sender) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Enums.sol";
import "../Utils/TestToken/IERC20.sol";

interface IRFAllocationStaking is Enums {
    function initialize(address _erc20, uint256 _rewardPerSecond, uint256 _startTimestamp, uint256 _earlyUnstakingFee, address _salesFactory, uint256 _tokensPerTicket, address _admin) external;
    function pause() external;
    function unpause() external;
    function setRewardPerSecond(uint256 _newRewardPerSecond) external;
    function setEarlyUnstakingFee(uint256 _newEarlyUnstakingFee) external;
    function setSalesFactory(address _salesFactory) external;
    function add(uint256 _allocPoint, address _lpToken, uint256 _minStakingPeriod, bool _withUpdate) external;
    function set(uint256 _pid, uint256 _allocPoint, uint256 _minStakingPeriod, bool _withUpdate) external;
    function poolLength() external view returns (uint256);
    function getPendingAndDepositedForUsers(address[] memory _users, uint _pid) external view returns (uint256 [] memory , uint256 [] memory);
    function totalPending() external view returns (uint256);
    function setTokensUnlockTime(address _user, uint256 _tokensUnlockTime) external;
    function fund(uint256 _amount) external;
    function massUpdatePools() external;
    function setTokensPerTicket(uint256 _amount) external;
    function updatePool(uint256 _pid) external;
    function deposited(uint256 _pid, address _user) external view returns(uint256);
    function pendingReward(uint256 _pid, address _user) external view returns(uint256);
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function withdrawPending(uint256 _pid) external;
    function getTicketAmount(address _user) external view returns(uint256 ticketAmount_);
    function getCurrentTier(address _user) external view returns(Tier tier);
    function fanStakedForTwoWeeks(address _user) external view returns(bool isStakingRAISEForTwoWeeks_);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
pragma solidity ^0.8.0;
// pragma solidity 0.8.9;

import "./Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;
// pragma solidity 0.8.9;

import "./AddressUpgradeable.sol";

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;
// pragma solidity 0.8.9;

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
pragma solidity ^0.8.0;

interface Enums {
    // Tier levels
    enum Tier {FAN, MERCHANT, DEALER, BROKER, TYCOON}
    // Status of a stake to upgrade pool
    enum StakeStatus {NA, ACTIVE}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;
// pragma solidity 0.8.9;

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