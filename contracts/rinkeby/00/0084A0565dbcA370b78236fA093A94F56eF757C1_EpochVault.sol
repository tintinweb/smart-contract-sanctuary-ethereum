pragma solidity ^0.8.0;

import { VaultFactory } from "./VaultFactory.sol";
import { Vault } from "./Vault.sol";
import { ABCToken } from "./AbcToken.sol";
import { AbacusController } from "./AbacusController.sol";
import { VeABC } from "./VeAbcToken.sol";

import "hardhat/console.sol";

/// @title Epoch Vault
/// @author Gio Medici
/// @notice Mints user reward tokens per epoch
contract EpochVault {

    /* ======== ADDRESS ======== */

    /// @notice protocol directory contract
    address public controller;

    /* ======== UINT ======== */

    /// @notice current epoch of the protocol
    uint256 public currentEpoch;

    /// @notice length of each epoch
    uint256 epochLength;

    /* ======== MAPPING ======== */

    /// @notice track information per epoch (see Epoch struct below for what information)
    mapping(uint256 => Epoch) epochTracker;

    /* ======== STRUCT ======== */

    /// @notice hold information about each epoch that passes
    /** 
    @dev (1) totaCredits -> total amount of credits purchased in an epoch
         (2) startTime -> time the epoch began 
         (3) abcEmissionSize -> size of that epochs emissions for retroactive claims
         (4) userCredits -> each users amount of credits in each epoch 
    */
    struct Epoch {
        uint256 totalCredits;
        uint256 startTime;
        uint256 abcEmissionSize;
        mapping(address => uint256) userCredits;
    }

    /* ======== CONSTRUCTOR ======== */

    constructor(address _controller, uint256 _epochLength) {
        epochLength = _epochLength;
        controller = _controller;
    }

    /* ======== EPOCH INTERACTION ======== */

    /// @notice End current epoch and begin next one
    /** 
    @dev Allows any user to end the current epoch once enough time passes
        - When called it updates the veABC contracts storage of:
        (1) total veABC volume during that epoch 
        (2) total amount auto allocated during that epoch
        (3) total allocation of veABC to collections during that epoch
    */
    function endEpoch() external {
        require(epochTracker[currentEpoch].startTime + epochLength <= block.timestamp);
        address veToken = AbacusController(controller).veAbcToken();
        VeABC(veToken).updateVeAbcVol(VeABC(veToken).totalSupply());
        VeABC(veToken).updateAuto();
        VeABC(veToken).updateTotalAllocation();
        currentEpoch++;
        if(currentEpoch - 1 == 0) epochTracker[currentEpoch].startTime = block.timestamp + epochLength;
        else epochTracker[currentEpoch].startTime = epochTracker[currentEpoch - 1].startTime + epochLength;
    }

    /// @notice Used as information intake function for Spot pool contracts to update a users credit count
    /// @param _nft the nft address that corresponds to the pool the user is buying credits from
    /// @param _id the id of the nft that the user is buying credits from
    /// @param _user the user that is buying the credits in the Spot pool
    /// @param _amount total amount of credits being purchased
    function updateEpoch(address _nft, uint256 _id, address _user, uint256 _amount) external {
        AbacusController _controller = AbacusController(controller);
        VaultFactory factory = VaultFactory(payable(_controller.vaultFactory()));
        
        //query veABC contract for boost that NFT collection holds based on allocation gauge
        (uint256 numerator, uint256 denominator) = VeABC(_controller.veAbcToken()).calculateBoost(_nft);

        //check the msg.sender is either a Spot pool or closure contract
        require(
            factory.nftVault(factory.nextVaultIndex(_nft, _id) - 1, _nft, _id) == msg.sender
            || Vault(payable(factory.nftVault(factory.nextVaultIndex(_nft, _id) - 1, _nft, _id))).closePoolContract() == msg.sender
        );
        
        /** 
        User credits automatically vest for 1 full epoch. When _amount is submitted in the function, the contract checks the multiplier
        based on the gauge to determine what multiple to apply to the users _amount which is to be added to their credit balance
        */
        epochTracker[currentEpoch + 1].totalCredits += _amount * (denominator == 0 ? 100 : (100 + 100 * numerator / denominator)) / 100;
        epochTracker[currentEpoch + 1].userCredits[_user] += _amount * (denominator == 0 ? 100 : (100 + 100 * numerator / denominator)) / 100;

    }

    /* ======== ABC REWARDS ======== */

    /// @notice Allow credit holders to claim their portion of the epochs emissions
    /** 
    @dev portion of an epochs emissions that a user receives is based on their proportional 
    ownership of total the total credits that were purchased in that epoch
    */
    /// @param _user the user who is receiving their abc rewards
    /// @param _epoch the epoch they are calling the rewards from
    function claimAbcReward(address _user, uint256 _epoch) external {

        //calculate epoch emissions size 
        uint256 epochEmission = getAbcEmission(_epoch);

        //check _user proportional ownership of the epoch
        uint256 abcReward = epochTracker[_epoch].userCredits[_user] * epochEmission / epochTracker[_epoch].totalCredits;
        
        //clear _user credit balance
        epochTracker[_epoch].userCredits[_user] = 0;

        //mint new ABC emission from the epoch
        ABCToken(payable(AbacusController(controller).abcToken())).mint(_user, abcReward);
    }

    /// @notice Calculate an epoch emission size
    /// @param _epoch the epoch who's emission size is being checked
    /// @return emission size of current epoch
    function getAbcEmission(uint256 _epoch) view public returns(uint256) {
        if(_epoch <= 12) return 58_000_000e18;
        else if (_epoch <= 24) return 29_200_000e18;
        else if (_epoch <= 36) return 12_500_000e18;
        else return 2 * ABCToken(payable(AbacusController(controller).abcToken())).totalSupply() / 100;
    }
}

pragma solidity ^0.8.0;

import "hardhat/console.sol";

import { Vault } from "./Vault.sol";
import { IVault } from "./interfaces/IVault.sol";
import { EpochVault } from "./EpochVault.sol";
import { OwnerToken } from "./OwnerToken.sol";
import { IOwnerToken } from "./interfaces/IOwnerToken.sol";
import { ClosePool } from "./ClosePool.sol";
import { IClosePool } from "./interfaces/IClosePool.sol";
import { Treasury } from "./Treasury.sol";
import { AbacusController } from "./AbacusController.sol";

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ClonesUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

/// @title ABC Token
/// @author Gio Medici
/// @notice Spot pool factory
contract VaultFactory {
    event VaultCreated(address owner, address vaultAddress, address heldToken, uint256 heldTokenId);

    /* ======== ADDRESS ======== */

    address private immutable _ownerTokenImplementation;
    address private immutable _vaultImplementation;
    address private immutable _closePoolImplementation;
    address public admin;
    address public controller;

    /* ======== BOOLEAN ======== */

    /// @notice keeps governor on Abacus Spot while this evaluates to true
    bool public beta;

    /* ======== MAPPING ======== */

    /// @notice track vaults by index
    mapping(address => mapping(uint256 => uint256)) public nextVaultIndex;

    /// @notice mapping used to track current vault address of an NFT
    mapping(uint256 => mapping(address => mapping(uint => address))) public nftVault;

    /// @notice whitelist vaults produced so they can make calls to child contracts
    mapping(address => bool) public vaultWhitelist;

    /// @notice whitelist of valid creation collections 
    mapping(address => bool) public collectionWhitelist;

    /// @notice beta whitelist
    mapping(address => bool) public earlyMemberWhitelist;

    /* ======== EVENT ======== */

    event VaultCreated(address _creator, address _vault, address _ownerToken, uint256 _tokenPrice, uint256 exitFee);
    event AuctionCreated(address _auction, address _vault, address _ownerToken);
    event CollectionWhitelisted(address _collection);

    /* ======== CONSTRUCTOR ======== */

    constructor(address _controller) {
        _ownerTokenImplementation = address(new OwnerToken());
        _vaultImplementation = address(new Vault());
        _closePoolImplementation = address(new ClosePool());
        admin = msg.sender;
        controller = _controller;
    }

    /* ======== WHITELISTS ======== */

    /// @notice allow early members create a vault
    function addToEarlyMemberWhitelist(address _earlyAccess) external {
        require(msg.sender == admin);
        earlyMemberWhitelist[_earlyAccess] = true;
    }

    /// @notice allow vaults to be made for a new collection 
    function addToCollectionWhitelist(address _collection) external {
        require(msg.sender == admin);
        collectionWhitelist[_collection] = true;
        emit CollectionWhitelisted(_collection);
    }

    /* ======== ADDRESS CONFIGURATION ======== */

    /// @notice change factory admin
    function setAdmin(address _admin) external {
        require(msg.sender == admin);
        admin = _admin;
    }

    /// @notice set controller contract
    function setController(address _controller) external {
        require(msg.sender == admin);
        controller = _controller;
    }

    /* ======== VAULT CREATION ======== */
    
    /// @notice Vault creation
    /**
    @dev this contract produces a Abacus Spot vault 
    as well as an ownership token for the vault created.
    It then proceeds to populate the vault and token with
    necessary information and then allows them to function
    properly.
    */
    /**
    @param _oName name of the ownership token
    @param _oSymbol symbol of the ownership token
    @param _name name of the pool token
    @param _symbol symbol of the pool token
    @param _heldToken address of NFT in vault created
    @param _heldTokenId id of NFT in vault created 
    @param _exitFeePercentage percentage fee based on a percentage of closing pool size
    @param _exitFeeStatic static fee denominated in ether
    */
    function createVault(
        string memory _oName,
        string memory _oSymbol,
        string memory _name,
        string memory _symbol,
        IERC721 _heldToken,
        uint256 _heldTokenId,
        uint256 _exitFeePercentage,
        uint256 _exitFeeStatic
    ) external {
        if(beta) {
            require(earlyMemberWhitelist[msg.sender] && collectionWhitelist[address(_heldToken)]);
        }

        IOwnerToken ownerTokenDeployment = IOwnerToken(ClonesUpgradeable.clone(_ownerTokenImplementation));
        IVault vaultDeployment = IVault(ClonesUpgradeable.clone(_vaultImplementation));

        // deploy owner token
        ownerTokenDeployment.initialize(
            _oName, 
            _oSymbol, 
            msg.sender, 
            address(this),
            address(_heldToken),
            _heldTokenId
        );

        // deploy vault token
        vaultDeployment.initialize(
            _name,
            _symbol,
            _heldToken,
            _heldTokenId,
            _exitFeePercentage,
            _exitFeeStatic,
            msg.sender,
            address(ownerTokenDeployment),
            controller,
            _closePoolImplementation
        );

        // configure newly created vault and owner token
        vaultWhitelist[address(vaultDeployment)] = true;
        nftVault[nextVaultIndex[address(_heldToken)][_heldTokenId]][address(_heldToken)][_heldTokenId] = address(vaultDeployment);
        nextVaultIndex[address(_heldToken)][_heldTokenId]++;

        // transfer ownwer token to deployer
        OwnerToken(address(ownerTokenDeployment)).setVault(address(vaultDeployment));
        _heldToken.transferFrom(msg.sender, address(vaultDeployment), _heldTokenId);

        emit VaultCreated(msg.sender, address(vaultDeployment), address(_heldToken), _heldTokenId);
    }

    /* ======== FALLBACK FUNCTIONS ======== */

    receive() external payable {}
    fallback() external payable {}
}

pragma solidity ^0.8.0;

import { OwnerToken } from "./OwnerToken.sol";
import { ABCToken } from "./AbcToken.sol";
import { Treasury } from "./Treasury.sol";
import { ClosePool } from "./ClosePool.sol";
import { IClosePool } from "./interfaces/IClosePool.sol";
import { VaultFactory } from "./VaultFactory.sol";
import { EpochVault } from "./EpochVault.sol";
import { AbacusController } from "./AbacusController.sol";
import { VeABC } from "./VeAbcToken.sol";

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ClonesUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

import "./helpers/ReentrancyGuard.sol";
import "hardhat/console.sol";

/// @title Spot pool
/// @author Gio Medici
/// @notice Spot pool contract
contract Vault is ReentrancyGuard, Initializable, ERC20Upgradeable {

    //TODO: add in error statements instead of just require statements

    /* ======== ADDRESS ======== */

    /// @notice configure directory contract
    address public controller;

    /// @notice owner of the vault 
    address public vaultOwner;

    /// @notice address of wrapped NFT
    address public ownerToken;

    /// @notice closure contract
    address public closePoolContract;

    /// @notice implementation of closure contract of intialize
    address private _closePoolImplementation;

    /// @notice currency that the locked NFT generates yield in
    address yieldCurrency;

    /* ======== LOCKED ERC721 ======== */

    /// @notice locked NFT address
    IERC721 public heldToken;

    /// @notice locked NFT id
    uint256 public heldTokenId;

    /* ======== UINT ======== */

    /// @notice sale tax 
    uint256 spread;

    /// @notice funds accumulated to be sent to treasury
    uint256 fundsForTreasury;

    /// @notice profit generated by trading
    uint256 profitGenerated;

    /// @notice percentage of NFT val to exit
    uint256 exitFeePercentage;

    /// @notice minimum cost of exit fee closure
    uint256 exitFeeStatic;

    /// @notice total tokens locked in pool
    uint256 public tokensLocked;

    /// @notice price per token
    uint256 public pricePerToken;

    /// @notice distribution for token holders at the end of the pool stage
    uint256 postPoolDistribution;

    /// @notice end of the initial premium entry time
    uint256 premiumEndTime;

    /// @notice size per ticket allowed (currently set a 3E size per ticket)
    uint256 sizePerTicket;

    /* ======== BOOLEANS ======== */

    /// @notice mark pool locked after closed
    bool poolClosed;

    /// @notice owner choice to redeem fees in ETH or credits
    bool redeemFeesInEth;

    /* ======== MAPPINGS ======== */

    /// @notice mark if owner bought premium pass
    mapping(address => bool) public premiumPass;

    /// @notice how many tokens have been purchased in a ticket range
    mapping(uint256 => uint256) public ticketsPurchased;

    /// @notice map each pool buyer
    mapping(address => Buyer) public traderProfile;

    /* ======== STRUCTS ======== */

    /// @notice user Buyer profile
    /** 
    @dev (1) creditPurchasePercentage -> what percentage of available credits would you like to purchase during sale
         (2) ticketsOpen -> how many tickets do you have open
         (3) startTime -> when did you originally lock you tokens
         (4) timeUnlock -> when tokens unlock
         (5) tokensLocked -> how many pool tokens are locked
         (6) finalCreditCount -> final amount of credits that'll be owned at unlock time
         (7) creditsPurchased -> total amount of credits that have already been purchased by user
         (8) ticketsOwned -> mapping of tokens owned per ticket
    */
    struct Buyer {
        uint16 creditPurchasePercentage;
        uint16 ticketsOpen;
        uint32 startTime;
        uint32 timeUnlock;
        uint128 tokensLocked;
        uint256 finalCreditCount;
        uint256 creditsPurchased;
        mapping(uint256 => uint256) ticketsOwned;
    }

    /* ======== EVENTS ======== */

    event TokensPurchased(address _buyer, uint256[] tickets, uint256[] amounts, uint256 _lockTime);
    event TokensSold(address _seller, uint256[] tickets, uint256[] amounts, uint256 _creditsPurchased);
    event FeesRedeemed(uint256 toTreasury, uint256 toOwner, uint256 toVeHolders, uint256 postPool);
    event PoolClosed(uint256 _choice, uint256 _finalVal, address _closePoolContract, address _vault, address _ownerToken);

    /* ======== CONSTRUCTOR ======== */
    
    function initialize(
        string memory _name,
        string memory _symbol,
        IERC721 _heldToken,
        uint256 _heldTokenId,
        uint256 _exitFeePercentage,
        uint256 _exitFeeStatic,
        address _admin,
        address _ownerToken,
        address _controller,
        address closePoolImplementation_
    ) external initializer {
        ERC20Upgradeable.__ERC20_init_unchained(_name, _symbol);

        controller = _controller;
        heldToken = _heldToken;
        heldTokenId = _heldTokenId;
        exitFeePercentage = _exitFeePercentage;
        exitFeeStatic = _exitFeeStatic;
        premiumEndTime = block.timestamp + 5 hours;

        ownerToken = _ownerToken;
        vaultOwner = _admin;
        _closePoolImplementation = closePoolImplementation_;
        pricePerToken = 0.001 ether;
        sizePerTicket = 3000e18;
        spread = AbacusController(controller).spread();
    }


    /* ======== SETTERS ======== */

    /// @notice configure how owner trading fees are earned
    function setFeeRedemptionMode(bool _redeemInEth) external {
        require(msg.sender == vaultOwner);
        redeemFeesInEth = _redeemInEth;
    }

    /// @notice configure the address of the yield currency
    function setYieldCurrencyAddress(address _currency) external {
        require(msg.sender == vaultOwner);
        yieldCurrency = _currency;
    }

    /* ======== TOKEN ADJUSTMENTS ======== */

    /// @notice called by owner token upon transfer to change ownership
    function updateVaultOwner(address _user) external {
        require(msg.sender == ownerToken);
        vaultOwner = _user;
    }

    /// @notice pool tokens cannot be traded
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(false);
    }

    /// @notice pool tokens cannot be traded
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(false);
    }

    /// @notice used to burn pool tokens by closure contract
    function burn(address _user, uint256 amount) public virtual {
        require(msg.sender == closePoolContract);
        _burn(_user, amount);
    }

    /* ======== USER ADJUSTMENTS ======== */

    /// @notice allow user to gain premium access to a pool
    function unlockPremiumAccess() nonReentrant external {
        require(block.timestamp < premiumEndTime);
        ABCToken(AbacusController(controller).abcToken()).burn(msg.sender, AbacusController(controller).premiumFee());
        premiumPass[msg.sender] = true;
    }

    /// @notice user can adjust what percentage of credits they'd like to purchase when unlocking tokens
    /// @param _creditPurchasePercentage percentage of credits to be purchased
    function adjustPayoutRatio(uint256 _creditPurchasePercentage) external {
        Buyer storage trader = traderProfile[msg.sender];
        trader.creditPurchasePercentage = uint16(_creditPurchasePercentage);
    }

    /* ======== TRADING ======== */

    /// @notice Purchase and lock tokens
    /// @param _caller The number of rings from dendrochronological sample
    /// @param tickets tickets that you'd like to purchase tokens from
    /// @param amountPerTicket how many tokens per you'd like to purchase per ticket
    /// @param _lockTime how long to lock the tokens for
    function purchaseToken(
        address _caller, 
        uint256[] memory tickets, 
        uint256[] memory amountPerTicket, 
        uint256 _lockTime
    ) nonReentrant payable external {

        //if premium end time hasn't passed user must have premium pass
        if(block.timestamp < premiumEndTime) require(premiumPass[_caller]);
        Buyer storage trader = traderProfile[_caller];

        //make sure pool isn't closed
        require(!poolClosed);

        //verify validity of ticket purchase and log tx outcome
        uint256 _totalTokensRequested;
        uint256 length = tickets.length;
        for(uint256 i=0; i<length; i++) {
            //make sure chosen tickets adhere to size per ticket and that buyer is not over purchasing ticket size
            require(
                tickets[i] % sizePerTicket == 0
                && ticketsPurchased[tickets[i]] + amountPerTicket[i] <= sizePerTicket
            );

            //update tickets owned amount, tokens owned per ticket, make sure a user doesn't exceed presence in 200 tickets
            if(trader.ticketsOwned[tickets[i]] == 0) trader.ticketsOpen++;
            _totalTokensRequested += amountPerTicket[i];
            ticketsPurchased[tickets[i]] += amountPerTicket[i];
            trader.ticketsOwned[tickets[i]] += amountPerTicket[i];
            require(trader.ticketsOpen <= 200);
        }

        //take trading fee
        require(msg.value >= 10_025 * (_totalTokensRequested * pricePerToken / 1e18) / 10_000);
        unchecked {
            profitGenerated += 25 * (_totalTokensRequested * pricePerToken / 1e18) / 10_000;
        }

        //if tokens are locked, add to locked amount, if not trigger fresh locking
        if(trader.startTime == 0) lockTokens(_caller, _totalTokensRequested, _lockTime);
        else addTokens(_caller, _totalTokensRequested);
        emit TokensPurchased(_caller, tickets, amountPerTicket, _lockTime);
    }

    /// @notice Sell and unlock tokens
    /// @param _user address of person that is being sold for
    /// @param tickets the tickets that a user owns that need to be sold off to clear account
    function sellToken(
        address _user, 
        uint256[] memory tickets 
    ) payable external {
        Buyer storage trader = traderProfile[_user];
        uint256 _spread = spread;
        uint256 length = tickets.length;
        uint[] memory amountPerTicket = new uint[](length);

        //check that pool isn't closed and unlock time has passed
        require(
            !poolClosed 
            && trader.timeUnlock <= block.timestamp
        );

        //clear the balance of each user owned ticket
        uint256 _totalTokensRequested;
        for(uint256 i=0; i<length; i++) {
            _totalTokensRequested += trader.ticketsOwned[tickets[i]];
            amountPerTicket[i] = trader.ticketsOwned[tickets[i]];
            ticketsPurchased[tickets[i]] -= trader.ticketsOwned[tickets[i]];
            delete trader.ticketsOwned[tickets[i]];
            trader.ticketsOpen--;
        }

        //check that user account is properly cleared 
        require(trader.tokensLocked == _totalTokensRequested && trader.ticketsOpen == 0);

        //set sale price of all tokens locked 
        uint256 _salePrice = (_totalTokensRequested * pricePerToken / 1e18);
        uint256 amountTokensLocked = trader.tokensLocked;

        //check total credits that have unlocked
        uint256 creditsAvailable = amountTokensLocked * pricePerToken / 1e18 + (trader.finalCreditCount - amountTokensLocked * pricePerToken / 1e18) * (block.timestamp >= trader.timeUnlock ? 1 : (((block.timestamp - trader.startTime) / 1 weeks) / ((trader.timeUnlock - trader.startTime)) / 1 weeks));
        
        //set amount of credits actually desired for purchase
        uint256 amountCreditsDesired = trader.creditPurchasePercentage * creditsAvailable / 1_000;

        //check that credits desired is not more than the credits available for purchase
        require(amountCreditsDesired <= creditsAvailable - trader.creditsPurchased);

        //cost of purchasing desired credits
        uint256 cost = trader.tokensLocked * pricePerToken * amountCreditsDesired / (creditsAvailable * 1e18);

        //update user credit count in vault
        EpochVault(AbacusController(controller).epochVault()).updateEpoch(address(heldToken), heldTokenId, msg.sender, cost);

        //update profit generated and funds destined for treasury
        profitGenerated += 5 * cost / 100 + _spread * (_salePrice - cost) / 10_000 + 25 * (_salePrice - cost) / 10_000;
        _salePrice -= _spread * (_salePrice - cost) / 10_000 + 25 * (_salePrice - cost) / 10_000;
        fundsForTreasury += 95 * cost / 100;

        //return remaining funds to seller
        payable(_user).transfer(_salePrice - cost);

        //unlock user tokens
        unlockTokens(_user);

        emit TokensSold(_user, tickets, amountPerTicket, amountCreditsDesired);
    }

    /// @notice allow trader to close matured position and reopen new position in one tx
    /// @dev calls sellToken and purchaseToken in the same tx
    /// @param _user seller address
    /// @param prevTickets expired tickets of the seller 
    /// @param tickets new tickets of the buyer
    /// @param amountPerTicket amount per new ticket submitted
    /// @param _lockTime set length of lock time
    function replacePosition(
        address _user, 
        uint256[] memory prevTickets,
         uint256[] memory tickets, 
         uint256[] memory amountPerTicket, 
         uint256 _lockTime
    ) payable external {
        //make external call to sell a token
        this.sellToken(_user, prevTickets);

        //make external call to purchase a token
        this.purchaseToken{value: msg.value}(msg.sender, tickets, amountPerTicket, _lockTime);
    }

    /* ======== FEES & CREDITS ======== */

    /// @notice Purchase available credits before position maturity 
    /// @dev if user position has matured users cannot purchase credits explicitly, must be through sale
    /// @param _amount amount of credits a user would like to purchase
    function purchaseCredits(uint256 _amount) payable external {
        
        //make sure pool is open
        require(!poolClosed);
        Buyer storage trader = traderProfile[msg.sender];
        uint256 amountTokensLocked = trader.tokensLocked;

        //check credits that have been unlocked so far
        uint256 creditsAvailable = amountTokensLocked * pricePerToken / 1e18 + (trader.finalCreditCount - amountTokensLocked * pricePerToken / 1e18) * ((block.timestamp - trader.startTime) / 1 weeks) / ((trader.timeUnlock - trader.startTime) / 1 weeks);
        
        //set cost of credits interested to purchase
        uint256 cost = trader.tokensLocked * pricePerToken * _amount / (creditsAvailable * 1e18);

        //check that msg.value covers the cost of purchasing the desired credits
        require(
            msg.value >= cost 
            && trader.creditsPurchased + _amount <= creditsAvailable
            && trader.timeUnlock >= block.timestamp
        );

        //record total credits purchased for future
        trader.creditsPurchased += _amount;

        //update epoch to include user credits 
        EpochVault(AbacusController(controller).epochVault()).updateEpoch(address(heldToken), heldTokenId, msg.sender, _amount);

        //update profit generated and funds for treasury
        profitGenerated += 5 * cost / 100;
        fundsForTreasury += 95 * cost / 100;
    }

    /// @notice Distribute fees that have been generated by the pool
    /** 
    @dev profit generated is split up as follows:
        - 15% to veABC holders
        - 15% to treasury
        - 20% to owner
        - 50% to post pool distribution pot
    If Spot pool owner deposits an NFT that generates yield of some kind they 
    will receive total amount of yield that has been generated.
    */
    function distributeFees() nonReentrant external {
        AbacusController _controller = AbacusController(controller);

        //split profit generated into appropriate buckets
        uint256 _profitGenerated = profitGenerated;
        uint256 _veTax = 150 * _profitGenerated / 1000;
        uint256 _fundsForTreasury = 150 * _profitGenerated / 1000;
        uint256 _po = 20 * _profitGenerated / 100;
        postPoolDistribution += 50 * _profitGenerated / 100;

        //check owner choice for fee redemption and send eth if true and exchange for credits if false
        if(redeemFeesInEth) {
            payable(vaultOwner).transfer(_po);
        }  
        else {
            EpochVault(_controller.epochVault()).updateEpoch(address(heldToken), heldTokenId, vaultOwner, _po);
            _fundsForTreasury += _po; 
        }

        emit FeesRedeemed(fundsForTreasury + _fundsForTreasury + (redeemFeesInEth? 0 : _po), (redeemFeesInEth? _po : 0), _veTax, 50 * _profitGenerated / 100);
        
        //clear funds destined for treasury and veABC 
        payable(_controller.abcTreasury()).transfer(fundsForTreasury + _fundsForTreasury);
        VeABC(_controller.veAbcToken()).receiveFees{value: _veTax}();

        //reset fees
        profitGenerated = 0;
        fundsForTreasury = 0;

        //unload yield currency to owner 
        if(yieldCurrency != address(0)) IERC20(yieldCurrency).transfer(msg.sender, IERC20(yieldCurrency).balanceOf(address(this)));
    }

    /* ======== POOL CLOSURE ======== */

    /// @notice close pool and deploy pool closure contract
    /** 
    @dev In the case of an auction the value in the pool is sent to the owner at the end of the tx and fees are stored
    for distribution on the current contract while the NFT is sent to the closure contract for auction. 
    In the case of an exit fee being paid, the owner immediately receives the NFT and the exit fee money is 
    sent to the closure contract for users to claim when closing their accounts.
    */
    /// @param _choice choice (0) -> auction the NFT, choice (1) -> pay an exit fee
    function closePool(uint256 _choice) nonReentrant payable external {
        
        //only the vault owner can call this function
        require(msg.sender == vaultOwner);

        //closure fee to close a vault
        ABCToken(AbacusController(controller).abcToken()).burn(msg.sender, AbacusController(controller).vaultClosureFee());
        poolClosed = true;
        uint256 exitPay;
        
        //caluclate final nft valuation by multiplying the total supply and price per token
        uint256 nftVal = totalSupply() * pricePerToken / 1e18;

        //if auction chosen post pool distribution gets queued to be sent to treasury (so predicted auction value doesn't get distorted by traders)
        if (_choice == 0) {
            fundsForTreasury += postPoolDistribution;
            postPoolDistribution = 0;
        }

        //if exit fee paid make sure that the fee paid is sufficient according to the pre-determined cost of closing a pool
        else if (_choice == 1) {
            require(msg.value >= ((exitFeePercentage * nftVal / 10_000) > exitFeeStatic ? exitFeePercentage * nftVal / 10_000 : exitFeeStatic));
            exitPay = msg.value;
        }

        //deploy closure contract
        IClosePool closePoolDeployment = IClosePool(ClonesUpgradeable.clone(_closePoolImplementation));
        closePoolDeployment.initialize(
            address(ownerToken),
            address(address(this)),
            nftVal,
            exitPay,
            postPoolDistribution,
            _choice
        );

        //transfer owner token to this contract 
        OwnerToken(ownerToken).transferFrom(msg.sender, address(this), 1e18);

        //transfer held NFT to the owner (exit fee) or closure contract (auction)
        heldToken.transferFrom(address(this), _choice == 0? address(closePoolDeployment) : msg.sender, heldTokenId);
        closePoolContract = address(closePoolDeployment);

        //depending on choice either send value to closure contract or token owner
        payable(_choice == 0? msg.sender : address(closePoolDeployment)).transfer(totalSupply() * pricePerToken / 1e18 + msg.value + postPoolDistribution);
        
        //trasnfer final funds for treasury to treasury contract
        if(_choice == 0) payable(AbacusController(controller).abcTreasury()).transfer(fundsForTreasury);

        emit PoolClosed(_choice, totalSupply() * pricePerToken / 1e18, address(closePoolDeployment), address(this), ownerToken);
    }

    /* ======== ACCOUNT CLOSURE ======== */

    /// @notice adjust ticket info when closing account on closure contract
    /// @dev calculates the final principal of a user by clearing each ticket in comparison to final nft value using FIFO
    /// @param _user the user whos principal that is being calculated
    /// @param tickets all tickets owned by the user
    /// @param _finalNftVal the final auction sale price of the NFT 
    /// @return principal -> the users principal stored 
    function adjustTicketInfo(address _user, uint256[] memory tickets, uint256 _finalNftVal) external returns (uint256 principal) {

        //only closure contract can call this
        require(msg.sender == closePoolContract);
        Buyer storage trader = traderProfile[_user];

        /** 
        compare each ticket to final NFT val and follow:
            - ticket value < nft value -> add val of tokens in ticket to principal 
            - ticket start < nft value && ticket end > nft val -> take the proportional overflow
              and return each token in ticket at that value
            - ticket start > nft value -> tokens in ticket are worth 0
        */
        for(uint256 i=0; i<tickets.length; i++) {
            if(tickets[i] > _finalNftVal) {
                principal += 0;
            }
            else if(tickets[i] + sizePerTicket > _finalNftVal) {
                principal += trader.ticketsOwned[tickets[i]] * pricePerToken / 1e18 * (tickets[i] + sizePerTicket - _finalNftVal) / sizePerTicket;
            }
            else {
                principal += trader.ticketsOwned[tickets[i]] * pricePerToken / 1e18;
            }
            delete trader.ticketsOwned[tickets[i]];
            trader.ticketsOpen--;
        }

        //make sure entire position has been cleared
        require(trader.ticketsOpen == 0);
    }

    /* ======== INTERNAL ======== */

    /// @notice lock purchase pool tokens 
    /** 
    @dev when user purchases tokens, they're automatically locked. 
    Upon locking the user final eth:credit purchase rate is 1:(lock time / 1 weeks).
    This means that at the position maturity, the user will be able to purchase 
    (tokensLocked * pricePerToken) * (lock time / 1 weeks) for the cost of (tokensLocked * pricePerToken).

    This function is only called when a user has 0 tokens locked.
    */
    /// @param _user the user that is locking tokens
    /// @param _amount the amount of tokens being locked
    /// @param _lockTime the amount of times the tokens are being locked 
    function lockTokens(address _user, uint256 _amount, uint256 _lockTime) internal {

        //minimum lock time must be greater than 2 weeks
        require((_lockTime / 2 weeks) > 0);

        //max lock time is 20 weeks
        Buyer storage trader = traderProfile[_user];
        require(trader.tokensLocked == 0 && _lockTime <= 20 weeks);

        //set final credit count as a multiple of the total eth spent to purchase
        trader.finalCreditCount = _amount * pricePerToken * (_lockTime / 1 weeks) / 1e18;

        //log start time and unlock time
        trader.startTime = uint32(block.timestamp);
        trader.timeUnlock = uint32(block.timestamp + (_lockTime / 1 weeks) * 1 weeks);

        //mint and lock tokens
        _mint(_user, _amount);
        _transfer(_user, address(this), _amount);
        trader.tokensLocked += uint128(_amount);
        tokensLocked += _amount;
    }

    /// @notice lock *more* tokens
    /** 
    @dev if a user purchases tokens and they've already locked some amount of tokens, addTokens is called.
    This updates the final credit balance that a user will converge on based on how much is being added 
    to the locked balance and the length of time left on the lockup.
    */
    /// @param _user the user that is locking tokens
    /// @param _amount the amount of tokens being locked 
    function addTokens(address _user, uint256 _amount) internal {

        //make sure there are already tokens locked and position hasn't matured
        Buyer storage trader = traderProfile[_user];
        require(trader.tokensLocked != 0 && trader.timeUnlock > block.timestamp);
        trader.finalCreditCount += (_amount * pricePerToken + _amount * pricePerToken * ((trader.timeUnlock - block.timestamp) / 1 weeks)) / 1e18;
        
        //mint and lock tokens
        _mint(_user, _amount);
        _transfer(_user, address(this), _amount);
        trader.tokensLocked += uint128(_amount);
        tokensLocked += _amount;
    }

    /// @notice unlock tokens
    /** 
    @dev users can only unlock tokens once their unlock time is up. Upon unlocking tokens the ENTIRE position
    is closed. All locked tokens are burned, user makes decisions regarding credits via the sellTokens.
    */
    /// @param _user the user that whos tokens are unlocking
    function unlockTokens(address _user) internal {

        //make sure position has matured
        Buyer storage trader = traderProfile[_user];
        require(block.timestamp >= trader.timeUnlock);

        //unlock and burn tokens
        uint256 amountTokensLocked = trader.tokensLocked;
        tokensLocked -= amountTokensLocked;
        _transfer(address(this), msg.sender, amountTokensLocked);
        _burn(msg.sender, amountTokensLocked);

        //reset buyer position
        delete trader.timeUnlock;
        delete trader.startTime;
        delete trader.finalCreditCount;
        delete trader.creditsPurchased;
        delete trader.tokensLocked;
    }

    /* ======== GETTER ======== */

    /// @notice purely for testing
    function getTime() view public returns(uint256) {
        return block.timestamp;
    }

    /// @notice returns the users total tokens locked
    /// @param _user user of interest
    function getTokensLocked(address _user) view external returns(uint256) {
        Buyer storage trader = traderProfile[_user];
        return trader.tokensLocked;
    }

    /// @notice returns total credits available at a chosen time
    /// @param _user user of interest
    /// @param _time queried time
    function getCreditsAvailableForPurchase(address _user, uint256 _time) view public returns(uint256) {
        Buyer storage trader = traderProfile[_user];
        if (trader.timeUnlock == 0) return 0;
        if(_time > trader.timeUnlock) _time = trader.timeUnlock;
        uint256 amountTokensLocked = trader.tokensLocked;

        //find total credits available using: principal + principal * multiplier * (current time / 1 weeks) / (time unlock / 1 weeks)
        uint256 creditsAvailable = amountTokensLocked * pricePerToken / 1e18 + (trader.finalCreditCount - amountTokensLocked * pricePerToken / 1e18) * ((_time - trader.startTime) / 1 weeks) / ((trader.timeUnlock - trader.startTime) / 1 weeks);
        return creditsAvailable - trader.creditsPurchased;
    }

    /// @notice find the cost to purchase an amount of credits
    /// @param _user user of interest
    /// @param _time queried time
    /// @param _amount amount of credits to be purchased
    function costToPurchaseCredits(address _user, uint256 _time, uint256 _amount) view external returns(uint256) {
        Buyer storage trader = traderProfile[_user];
        uint256 creditsAvailable = getCreditsAvailableForPurchase(_user, _time);

        //cost is total principal * amount / credits available => the more credits available the cheaper the cost per credit
        uint256 cost = trader.tokensLocked * pricePerToken * _amount / (creditsAvailable * 1e18);
        return cost;
    }

    /* ======== FALLBACK FUNCTIONS ======== */

    receive() external payable {}
    fallback() external payable {}
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import { VaultFactory } from "./VaultFactory.sol";
import { AbacusController } from "./AbacusController.sol";

import "./helpers/ERC20.sol";


/// @title ABC Token
/// @author Gio Medici
/// @notice Abacus currency contract
contract ABCToken is ERC20 {

    /* ======== ADDRESS ======== */

    address public admin;
    address public presale;
    address public controller;

    /* ======== CONSTRUCTOR ======== */

    constructor(address _controller) ERC20("EarlyAbacus", "eABC") {
        _mint(msg.sender, 10000000000e18);
        admin = msg.sender;
        controller = _controller;
    }

    /* ======== SETTERS ======== */

    function setAdmin(address _newAdmin) external {
        require(msg.sender == admin);
        admin = _newAdmin;
    }

    function setPresale(address _presale) external {
        require(msg.sender == admin);
        presale = _presale;
    }

    /* ======== TOKEN INTERACTIONS ======== */

    function mint(address _user, uint _amount) external {
        require(msg.sender == presale || msg.sender == AbacusController(controller).epochVault());
        _mint(_user, _amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(
            msg.sender == AbacusController(controller).vaultFactory() 
            || msg.sender == AbacusController(controller).veAbcToken()
            || VaultFactory(payable(AbacusController(controller).vaultFactory())).vaultWhitelist(msg.sender)
        );
        _transfer(sender, recipient, amount);

        return true;
    } 

    function burn(address _user, uint256 amount) public virtual {
        require(
            msg.sender == AbacusController(controller).abcTreasury()
            || VaultFactory(payable(AbacusController(controller).vaultFactory())).vaultWhitelist(msg.sender)
        );
        _burn(_user, amount);
    }
    
}

pragma solidity ^0.8.0;

/// @title Abacus Controller
/// @author Gio Medici
/// @notice Protocol directory
contract AbacusController {

    /* ======== ADDRESS ======== */

    address public admin;
    address public abcTreasury;
    address public abcToken;
    address public veAbcToken;
    address public epochVault;
    address public vaultFactory;

    /* ======== UINT ======== */

    uint256 public spread;
    uint256 public bribeCut;
    uint256 public abcCostOfVaultCreation;
    uint256 public premiumFee;
    uint256 public vaultClosureFee;

    /* ======== BOOLEAN ======== */

    bool public beta;

    /* ======== MAPPING ======== */

    mapping(address => mapping(uint => address)) public nftVault;
    mapping(address => uint) public collectionMultiplier;

    /* ======== MODIFIERS ======== */

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    /* ======== CONSTRUCTOR ======== */

    constructor() {
        admin = msg.sender;
        beta = true;
    }

    /* ======== SETTERS ======== */

    /// @notice configure Treasury 
    function setTreasury(address _abcTreasury) onlyAdmin external {
        abcTreasury = _abcTreasury;
    }

    /// @notice configure ABC
    function setToken(address _token) onlyAdmin external {
        abcToken = _token;
    }

    /// @notice configure veABC
    function setVeToken(address _veToken) onlyAdmin external {
        veAbcToken = _veToken;
    }

    /// @notice configure Epoch Vault
    function setEpochVault(address _epochVault) onlyAdmin external {
        epochVault = _epochVault;
    }

    /// @notice  configure Vault Factory
    function setVaultFactory(address _factory) onlyAdmin external {
        vaultFactory = _factory;
    }

    /// @notice set the spread which sets the sales tax 
    function setSpread(uint256 _spread) onlyAdmin external {
        spread = _spread;
    }

    /// @notice configure the protocol to beta phase
    function setBetaStatus(bool _status) onlyAdmin external {
        beta = _status;
    }

    /// @notice set the piece of bribes paid that are taken as a bribe fee
    function setBribeCut(uint256 _amount) onlyAdmin external {
        bribeCut = _amount;
    }

    /// @notice set the cost to pay for premium space
    function setPremiumFee(uint256 _amount) onlyAdmin external {
        premiumFee = _amount;
    }

    /// @notice set the cost (in ABC) to close a Spot pool
    function setClosureFee(uint256 _amount) onlyAdmin external {
        vaultClosureFee = _amount;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import { VaultFactory } from "./VaultFactory.sol";
import { AbacusController } from "./AbacusController.sol";
import { ABCToken } from "./AbcToken.sol";
import { EpochVault } from "./EpochVault.sol";

import "./helpers/ReentrancyGuard.sol";
import "./helpers/ERC20.sol";
import "hardhat/console.sol";

/// @title veABC Token
/// @author Gio Medici
/// @notice Voting escrowed ABC token
contract VeABC is ERC20, ReentrancyGuard {

    //TODO: Users that try to claim post unlock time can no longer claim

    /* ======== ADDRESS ======== */
    
    /// @notice configure directory contract
    address public controller;

    /* ======== UINT ======== */

    /// @notice funds available for treasury
    uint256 public fundsForTreasury;

    /* ======== MAPPING ======== */

    /// @notice track history of each address
    mapping(address => Holder) public veHolderHistory;

    /// @notice track when the epoch of last change in allocation 
    mapping(address => uint256) public epochOfLastChangePerCollection;

    /// @notice track total allocation per collection
    mapping(address => uint256) public totalAllocationPerCollection;

    /// @notice track fees accumulated in each epoch
    mapping(uint256 => uint256) public epochFeesAccumulated;

    /// @notice veABC volume in each epoch 
    mapping(uint256 => uint256) public veAbcVolPerEpoch;

    /// @notice total amount of auto allocated veABC
    mapping(uint256 => uint256) public totalAmountAutoAllocated;

    /// @notice total amount of allocated veABC
    mapping(uint256 => uint256) public totalAllocationPerEpoch;
    
    /// @notice total bribes in each epoch 
    mapping(uint256 => uint256) public totalBribesPerEpoch;
    
    /// @notice track when auto allocation change occurs
    mapping(uint256 => bool) public autoAllocationChangeOccured;

    /// @notice track when total allocation change occurs 
    mapping(uint256 => bool) public totalAllocationChangeOccured;

    /// @notice track when a collections allocation count has changed
    mapping(uint256 => mapping(address => bool)) public collectionAllocationChangeOccured;

    /// @notice track allocation per collection per epoch
    mapping(uint256 => mapping(address => uint256)) public totalAllocationPerCollectionPerEpoch;

    /// @notice track bribes per collection per epoch 
    mapping(uint256 => mapping(address => uint256)) public bribesPerCollectionPerEpoch;

    /* ======== STRUCT ======== */

    /// @notice veABC holder profile
    /** 
    @dev (1) timeUnlock -> when veABC unlocks
         (2) amountLocked -> tokens locked
         (3) multiplier -> multiplier based on lock time
         (4) amountAllocated -> total amount allocated to collections
         (5) amountAutoAllocated -> total amount auto allocated
         (6) veBalanceUpdates -> total amount of ve balance changes
         (7) autoUpdate -> total amount of auto allocation changes
         (8) epochClaimedVe -> track epochs where ve reward is claimed
         (9) epochClaimedAuto -> track epochs where auto rewards is claimed
         (10) veStartEpoch -> track intervals of ve holdings
         (11) veStartEpochAmount -> track amounts of ve holdings at each interval
         (12) autoStartEpoch -> track intervals of auto allocations
         (13) autoStartEpochAmount -> track amounts of auto allocation at each interval
         (14) allocationPerCollection -> track allocation per collection
    */
    struct Holder {
        uint256 timeUnlock;
        uint256 amountLocked;
        uint256 multiplier;
        uint256 amountAllocated;
        uint256 amountAutoAllocated;
        uint256 veBalanceUpdates;
        uint256 autoUpdates;
        mapping(uint256 => bool) epochClaimedVe;
        mapping(uint256 => bool) epochClaimedAuto;
        mapping(uint256 => uint256) veStartEpoch;
        mapping(uint256 => uint256) veStartEpochAmount;
        mapping(uint256 => uint256) autoStartEpoch;
        mapping(uint256 => uint256) autoStartEpochAmount;
        mapping(address => uint256) allocationPerCollection;
    }

    /* ======== CONSTRUCTOR ======== */

    constructor(address _controller) ERC20("Voting Escrowed ABC", "ABC") {
        controller = _controller;
    }

    /* ======== TOKEN INTERACTION ======== */

    /// @notice restrict trasnfer from call to veABC contract
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(msg.sender == address(this));
        _transfer(sender, recipient, amount);

        return true;
    }

    /// @notice these tokens are non-transferrable
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(false);
    }

    /* ======== EPOCH CONFIG ======== */

    /// @notice receive and log fees generated
    function receiveFees() payable external {
        require(VaultFactory(payable(AbacusController(controller).vaultFactory())).vaultWhitelist(msg.sender));
        epochFeesAccumulated[EpochVault(AbacusController(controller).epochVault()).currentEpoch()] += msg.value;
    }

    /// @notice updates final veABC vol per epoch
    function updateVeAbcVol(uint256 _vol) external {
        require(msg.sender == AbacusController(controller).epochVault());
        veAbcVolPerEpoch[EpochVault(AbacusController(controller).epochVault()).currentEpoch()] = _vol;
    }

    /// @notice updates total allocation per epoch 
    function updateTotalAllocation() external {
        require(msg.sender == AbacusController(controller).epochVault());
        uint256 currentEpoch = EpochVault(AbacusController(controller).epochVault()).currentEpoch();
        if(!totalAllocationChangeOccured[currentEpoch]) {
            if(currentEpoch > 1) totalAmountAutoAllocated[currentEpoch] = totalAmountAutoAllocated[currentEpoch - 1];
        }
    }

    /// @notice updates auto allocation per epoch
    function updateAuto() external {
        require(msg.sender == AbacusController(controller).epochVault());
        uint256 currentEpoch = EpochVault(AbacusController(controller).epochVault()).currentEpoch();
        if(!autoAllocationChangeOccured[currentEpoch]) {
            if(currentEpoch > 1) totalAmountAutoAllocated[currentEpoch] = totalAmountAutoAllocated[currentEpoch - 1];
        }
    }

    /* ======== LOCKING ======== */

    /// @notice lock tokens for set amount of time in exchange for veABC
    /// @dev function can only be called if the user currently has no locked token balance
    /// @param _amount how much ABC the user would like to lock
    /// @param _time amount of time they'd like to lock it for
    function lockTokens(uint256 _amount, uint256 _time) nonReentrant external {
        
        //max lock time is 1 year
        require( _time <= 52 weeks);
        Holder storage holder = veHolderHistory[msg.sender];

        //make sure its a "fresh" lockup
        require( holder.timeUnlock == 0 );

        //configure lock as rounded the the 2 weeks mark and calculate multiplier
        uint256 _timeLock = (_time / 2 weeks) * 2 weeks;
        uint256 multiplier = (_time / 2 weeks);
        uint256 veAmount = multiplier * _amount / 10;
        holder.multiplier = multiplier;

        //lock user tokens
        ABCToken(AbacusController(controller).abcToken()).transferFrom(msg.sender, address(this), _amount);
        holder.timeUnlock = block.timestamp + _timeLock;
        holder.amountLocked = _amount;

        //mint new veABC and update ve epoch log
        _mint(msg.sender, veAmount);
        if(holder.veStartEpoch[holder.veBalanceUpdates] == EpochVault(AbacusController(controller).epochVault()).currentEpoch()) {
            holder.veStartEpochAmount[holder.veBalanceUpdates] += veAmount;
        }
        else {
            holder.veBalanceUpdates++;
            holder.veStartEpoch[holder.veBalanceUpdates] = EpochVault(AbacusController(controller).epochVault()).currentEpoch();
            holder.veStartEpochAmount[holder.veBalanceUpdates] = holder.veStartEpochAmount[holder.veBalanceUpdates] + veAmount;
        }

        veAbcVolPerEpoch[EpochVault(AbacusController(controller).epochVault()).currentEpoch()] += veAmount;
        //TODO: event
    }

    /// @notice lock tokens for set amount of time in exchange for veABC
    /// @dev function can only be called if the user currently has a locked token balance
    /// @param _amount how much ABC the user would like to lock
    function addTokens(uint256 _amount) nonReentrant external {
        Holder storage holder = veHolderHistory[msg.sender];

        //make sure that the user already has tokens locked
        require(holder.timeUnlock != 0);
        uint256 veAmount = holder.multiplier * _amount / 10;

        //lock user tokens
        ABCToken(AbacusController(controller).abcToken()).transferFrom(msg.sender, address(this), _amount);
        holder.amountLocked += _amount;

        //mint new veABC and update epoch log
        _mint(msg.sender, veAmount);
        if(holder.veStartEpoch[holder.veBalanceUpdates] == EpochVault(AbacusController(controller).epochVault()).currentEpoch()) {
            holder.veStartEpochAmount[holder.veBalanceUpdates] += veAmount;
        }
        else {
            holder.veBalanceUpdates++;
            holder.veStartEpoch[holder.veBalanceUpdates] = EpochVault(AbacusController(controller).epochVault()).currentEpoch();
            holder.veStartEpochAmount[holder.veBalanceUpdates] = holder.veStartEpochAmount[holder.veBalanceUpdates] + veAmount;
        }

        veAbcVolPerEpoch[EpochVault(AbacusController(controller).epochVault()).currentEpoch()] += veAmount;
    }

    /// @notice unlock all locked tokens
    /// @dev only callable after the users maturity has completed
    function unlockTokens() nonReentrant external {
        Holder storage holder = veHolderHistory[msg.sender];

        //verify unlock time has passed and user has removed all allocation
        require(holder.amountAllocated == 0 && holder.timeUnlock <= block.timestamp);
        uint256 currentEpoch = EpochVault(AbacusController(controller).epochVault()).currentEpoch();

        //burn veABC tokens and return ABC
        _burn(msg.sender, balanceOf(msg.sender));
        ABCToken(AbacusController(controller).abcToken()).transferFrom(address(this), msg.sender, holder.amountLocked);
        if(holder.veStartEpoch[holder.veBalanceUpdates] == currentEpoch) {
            holder.veStartEpochAmount[holder.veBalanceUpdates] = 0;
        }
        else {
            holder.veBalanceUpdates++;
            holder.veStartEpoch[holder.veBalanceUpdates] = currentEpoch;
            holder.veStartEpochAmount[holder.veBalanceUpdates] = 0;
        }

        //clear position cache
        holder.amountLocked = 0;
        holder.multiplier = 0;
    }

    /* ======== ALLOCATING ======== */

    /// @notice allocate veABC to collection gauge
    /// @dev increase the total allocation for a collection of user choice
    /// @param _collection the address of chosen NFT
    /// @param _amount the amount of veABC power to be allocated
    function allocateToCollection(address _collection, uint256 _amount) nonReentrant external {
        Holder storage holder = veHolderHistory[msg.sender];
        uint256 currentEpoch = EpochVault(AbacusController(controller).epochVault()).currentEpoch();
        require(holder.amountAllocated + _amount <= holder.veStartEpochAmount[holder.veBalanceUpdates]);
        
        // adjust allocation trackers
        holder.amountAllocated += _amount;
        holder.allocationPerCollection[_collection] += _amount;
        totalAllocationPerCollection[_collection] += _amount;
        totalAllocationPerCollectionPerEpoch[currentEpoch][_collection] = totalAllocationPerCollection[_collection];
        epochOfLastChangePerCollection[_collection] = currentEpoch;
        totalAllocationPerEpoch[currentEpoch] += _amount;

        // custody user veABC token
        _transfer(msg.sender, address(this), _amount);

        // collection marked to be checked for allocation balance
        if(!collectionAllocationChangeOccured[currentEpoch][_collection]) collectionAllocationChangeOccured[currentEpoch][_collection] = true;
        if(!totalAllocationChangeOccured[currentEpoch]) totalAllocationChangeOccured[currentEpoch] = true;
        //TODO: event
    }

    /// @notice change gauge vote 
    /// @dev allow user to change their voting allocation from one collection to another in single tx
    /// @param _currentCollection the collection of allocation user would like to remove
    /// @param _newCollection the new collection that the user would like to allocate to
    /// @param _amount the amount of allocation the user would like to change
    function changeAllocationTarget(address _currentCollection, address _newCollection, uint256 _amount) nonReentrant external {
        Holder storage holder = veHolderHistory[msg.sender];
        uint256 currentEpoch = EpochVault(AbacusController(controller).epochVault()).currentEpoch();
        require(holder.allocationPerCollection[_currentCollection] >= _amount);

        // adjust allocation trackers
        holder.allocationPerCollection[_currentCollection] -= _amount;
        holder.allocationPerCollection[_newCollection] += _amount;
        totalAllocationPerCollection[_currentCollection] -= _amount;
        totalAllocationPerCollection[_newCollection] += _amount;
        totalAllocationPerCollectionPerEpoch[currentEpoch][_currentCollection] = totalAllocationPerCollection[_currentCollection];
        totalAllocationPerCollectionPerEpoch[currentEpoch][_newCollection] = totalAllocationPerCollection[_newCollection];
        epochOfLastChangePerCollection[_currentCollection] = currentEpoch;
        epochOfLastChangePerCollection[_newCollection] = currentEpoch;

        // collection marked to be checked for allocation balance
        if(!collectionAllocationChangeOccured[currentEpoch][_currentCollection]) collectionAllocationChangeOccured[currentEpoch][_currentCollection] = true;
        if(!collectionAllocationChangeOccured[currentEpoch][_newCollection]) collectionAllocationChangeOccured[currentEpoch][_newCollection] = true;
        //TODO: event
    }

    /// @notice remove collection gauge allocation
    /// @dev decreases the total amount of gauge percentage committed to a collection
    /// @param _collection address of collection to be removed 
    /// @param _amount amount of allocation to be removed from the collection
    function removeAllocation(address _collection, uint256 _amount) nonReentrant external {
        Holder storage holder = veHolderHistory[msg.sender];
        uint256 currentEpoch = EpochVault(AbacusController(controller).epochVault()).currentEpoch();
        require(holder.amountAllocated >= _amount);

        // adjust allocation trackers
        holder.amountAllocated -= _amount;
        holder.allocationPerCollection[_collection] -= _amount;
        totalAllocationPerCollection[_collection] -= _amount;
        totalAllocationPerCollectionPerEpoch[currentEpoch][_collection] = totalAllocationPerCollection[_collection];
        totalAllocationPerEpoch[currentEpoch] -= _amount;
        epochOfLastChangePerCollection[_collection] = currentEpoch;

        // return veABC tokens
        _transfer(address(this), msg.sender, _amount);

        // collection marked to be checked for allocation balance
        if(!collectionAllocationChangeOccured[currentEpoch][_collection]) collectionAllocationChangeOccured[currentEpoch][_collection] = true;
        if(!totalAllocationChangeOccured[currentEpoch]) totalAllocationChangeOccured[currentEpoch] = true;
        //TODO: event
    }

    /// @notice add voting power to auto allocation pot
    /// @param _amount total amount of veABC voting power that user would like to auto allocate
    function addAutoAllocation(uint256 _amount) nonReentrant external {
        Holder storage holder = veHolderHistory[msg.sender];
        uint256 currentEpoch = EpochVault(AbacusController(controller).epochVault()).currentEpoch();
        require(holder.amountAllocated + _amount <= holder.veStartEpochAmount[holder.veBalanceUpdates]);

        // collection marked to be checked for allocation balance
        holder.amountAllocated += _amount;
        holder.amountAutoAllocated += _amount;
        totalAllocationPerEpoch[currentEpoch] += _amount;
        if(holder.autoStartEpoch[holder.autoUpdates] == currentEpoch) {
            holder.autoStartEpochAmount[holder.autoUpdates] = holder.amountAutoAllocated;
        }
        else {
            holder.autoUpdates++;
            holder.autoStartEpoch[holder.autoUpdates] = currentEpoch;
            holder.autoStartEpochAmount[holder.autoUpdates] = holder.amountAutoAllocated;
        }

        if(totalAmountAutoAllocated[currentEpoch] == 0) {
            totalAmountAutoAllocated[currentEpoch] = totalAmountAutoAllocated[currentEpoch-1] + _amount;
        }
        else {
            totalAmountAutoAllocated[currentEpoch] += _amount;
        }

        autoAllocationChangeOccured[currentEpoch] = true;
        // custody veABC tokens
        _transfer(msg.sender, address(this), _amount);
        //TODO: event
    }

    /// @notice remove voting power from auto allocation pot
    /// @param _amount total amount of veABC voting power that user would like to remove from auto allocation
    function removeAutoAllocation(uint256 _amount) nonReentrant external {
        Holder storage holder = veHolderHistory[msg.sender];
        uint256 currentEpoch = EpochVault(AbacusController(controller).epochVault()).currentEpoch();
        require(holder.amountAutoAllocated >= _amount);

        // collection marked to be checked for allocation balance
        holder.amountAllocated -= _amount;
        holder.amountAutoAllocated -= _amount;
        totalAllocationPerEpoch[currentEpoch] -= _amount;
        if(holder.autoStartEpoch[holder.autoUpdates] == currentEpoch) {
            holder.autoStartEpochAmount[holder.autoUpdates] = holder.amountAutoAllocated;
        }
        else {
            holder.autoUpdates++;
            holder.autoStartEpoch[holder.autoUpdates] = currentEpoch;
            holder.autoStartEpochAmount[holder.autoUpdates] = holder.amountAutoAllocated;
        }

        if(totalAmountAutoAllocated[currentEpoch] == 0) {
            totalAmountAutoAllocated[currentEpoch] = totalAmountAutoAllocated[currentEpoch-1] - _amount;
        }
        else {
            totalAmountAutoAllocated[currentEpoch] -= _amount;
        }

        autoAllocationChangeOccured[currentEpoch] = true;
        // return veABC tokens
        _transfer(address(this), msg.sender, _amount);
        //TODO: event
    }

    /* ======== BRIBE ======== */

    /// @notice bribe auto allocation
    /// @dev add bribe for auto allocators to decide which collection gets their vote in next gauge reset
    /// @param _collection which collection to submit the bribe for
    function bribeAuto(address _collection) nonReentrant payable external {
        
        // take protocol cut of bribe
        payable(msg.sender).transfer( AbacusController(controller).bribeCut() * msg.value / 10_000 );

        // record bribe allocation
        bribesPerCollectionPerEpoch[EpochVault(AbacusController(controller).epochVault()).currentEpoch()][_collection] += (10_000 - AbacusController(controller).bribeCut()) * msg.value / 10_000;
        totalBribesPerEpoch[EpochVault(AbacusController(controller).epochVault()).currentEpoch()] += (10_000 - AbacusController(controller).bribeCut()) * msg.value / 10_000;
        //TODO: event
    }

    /* ======== REWARDS ======== */

    /// @notice claim rewards for auto allocation
    /// @param epoch list of epochs whos rewards you'd like to claim
    /// @param associatedUpdateNumber assocaited update value that covers the epoch (i.e. if the first update covers from epoch 1 - epoch 10 then for epoch 1-10 matching update will be 1)
    function claimAutoReward(uint256[] memory epoch, uint256[] memory associatedUpdateNumber) nonReentrant external {
        Holder storage holder = veHolderHistory[msg.sender];
        uint256 totalPayout;
        uint256 length = epoch.length;

        // claim rewards up to current epoch 
        for(uint256 j=0; j < length; j++) {
            uint256 updateNum = associatedUpdateNumber[j];
            uint256 epochNum = epoch[j];
            require(holder.veStartEpoch[updateNum] <= epochNum && (holder.veStartEpoch[updateNum] > epochNum || holder.veStartEpoch[updateNum+1] == 0));
            if(holder.epochClaimedVe[epochNum]) break;
            if(veAbcVolPerEpoch[epochNum] == 0) {
                fundsForTreasury += epochFeesAccumulated[epochNum];
            }

            totalPayout += totalBribesPerEpoch[epochNum] * holder.autoStartEpochAmount[updateNum] / totalAmountAutoAllocated[epochNum];
            holder.epochClaimedVe[epochNum] = true;
        }

        // send reward to holder
        payable(msg.sender).transfer(totalPayout);
        //TODO: event
    }

    /// @notice claim rewards for holding veABC
    /// @param epoch list of epochs whos rewards you'd like to claim
    /// @param associatedUpdateNumber assocaited update value that covers the epoch (i.e. if the first update covers from epoch 1 - epoch 10 then for epoch 1-10 matching update will be 1)
    function claimVeHolderReward(uint256[] memory epoch, uint256[] memory associatedUpdateNumber) nonReentrant external {
        Holder storage holder = veHolderHistory[msg.sender];
        uint256 totalPayout;
        uint256 length = epoch.length;

        // claim rewards up to current epoch 
        for(uint256 j=0; j < length; j++) {
            uint256 updateNum = associatedUpdateNumber[j];
            uint256 epochNum = epoch[j];
            require(holder.veStartEpoch[updateNum] <= epochNum && (holder.veStartEpoch[updateNum] > epochNum || holder.veStartEpoch[updateNum+1] == 0));
            if(holder.epochClaimedVe[epochNum]) break;
            if(veAbcVolPerEpoch[epochNum] == 0) {
                fundsForTreasury += epochFeesAccumulated[epochNum];
            }
            totalPayout += epochFeesAccumulated[epochNum] * holder.veStartEpochAmount[updateNum] / veAbcVolPerEpoch[epochNum];
            holder.epochClaimedVe[epochNum] = true;
        }

        // send reward to holder
        payable(msg.sender).transfer(totalPayout);
        //TODO: event
    }

    /* ======== BOOST & VOTING ======== */

    /// @notice calculate the collections credit generation boost
    /// @param _collection the collection whos boost is being queried
    /// @return numerator used for higher precision on boost calculation side
    /// @return denominator used for higher precision on boost calculation side
    function calculateBoost(address _collection) external returns(uint256 numerator, uint256 denominator) {
        uint256 currentEpoch = EpochVault(AbacusController(controller).epochVault()).currentEpoch()-1;

        // total auto allocation in the epoch in question
        uint256 _autoAllocation = totalAmountAutoAllocated[currentEpoch];
        
        // total bribes aimed at this collection
        uint256 _collectionBribe = bribesPerCollectionPerEpoch[currentEpoch][_collection];

        // total bribes in the epoch
        uint256 _totalBribe = totalBribesPerEpoch[currentEpoch];

        // total amount allocated to collection
        uint256 _collectionAllocation;
        if(!collectionAllocationChangeOccured[currentEpoch][_collection]){
            totalAllocationPerCollectionPerEpoch[currentEpoch][_collection] = totalAllocationPerCollectionPerEpoch[epochOfLastChangePerCollection[_collection]][_collection];
            collectionAllocationChangeOccured[currentEpoch][_collection] = true;
        }
        _collectionAllocation = totalAllocationPerCollectionPerEpoch[currentEpoch][_collection];
        uint256 _totalAllocation = totalAllocationPerEpoch[currentEpoch];

        // return a numerator and denominator for multiplier to calculate
        if(_autoAllocation * _collectionBribe * _totalBribe == 0) numerator = _collectionAllocation;
        else numerator = _collectionAllocation + _autoAllocation * _collectionBribe / _totalBribe;
        denominator = _totalAllocation;
    }

    /// @notice calculate a users voting power for governance purposes
    /// @dev voting power is made up of total amount of veABC locked and unlocked that the user owns 
    /// @param _user the user whos voting power is being checked
    function calculateVotingPower(address _user) view external returns(uint256 votingPower) {
        Holder storage holder = veHolderHistory[_user];
        return holder.amountAllocated + balanceOf(_user);
    }

    /// @notice clears any "funds without a home" to treasury
    function clearToTreasury() external {
        payable(AbacusController(controller).abcTreasury()).transfer(fundsForTreasury);
        fundsForTreasury = 0;
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

pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVault {
    function initialize(
        string memory _name,
        string memory _symbol,
        IERC721 _heldToken,
        uint256 _heldTokenId,
        uint256 _exitFeePercentage,
        uint256 _exitFeeStatic,
        address _admin,
        address _ownerToken,
        address _controller,
        address _auctionImplementation
    ) external;
}

pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Vault } from "./Vault.sol";
import { AbacusController } from "./AbacusController.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @title WrappedToken
/// @author Gio Medici
/// @notice Represents the ownership powers over the connected Spot pool
contract OwnerToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {

    /* ======== HELD NFT ======== */
    /// @dev stores the address of the NFT contract to be held in the vault.
    IERC721 public repToken;

    /// @dev stores the id of the NFT to be held in the vault.
    uint256 public repTokenId;

    /* ======== ADDRESS ======== */

    /// @dev stores the address of the vaultFactory
    address public vaultFactory;

    address public vault;

    /* ======== CONSTRUCTOR ======== */

    function initialize(
        string memory _name,
        string memory _symbol,
        address _admin, 
        address _rootContract,
        address _heldToken,
        uint256 _heldTokenid
    ) external initializer {
        OwnableUpgradeable.__Ownable_init_unchained();
        ERC20Upgradeable.__ERC20_init_unchained(_name, _symbol);
        OwnableUpgradeable.transferOwnership(_admin);

        vaultFactory = _rootContract;
        repToken = IERC721(_heldToken);
        repTokenId = _heldTokenid;

        _mint(_admin, 1e18);
    }

    /* ======== SETTERS ======== */

    function setVault(address _vault) external {
        require(msg.sender == vaultFactory);
        vault = _vault;
    }

    /* ======== TOKEN ACTIONS ======== */

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(msg.sender == vault);
        
        Vault(payable(vault)).updateVaultOwner(recipient);
        _transfer(sender, recipient, amount);

        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(amount == 1e18);
        Vault(payable(vault)).updateVaultOwner(recipient);
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
}

pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOwnerToken {
    function initialize(
        string memory _name,
        string memory _symbol,
        address _admin, 
        address _rootContract,
        address _heldToken,
        uint256 _heldTokenid
    ) external;
}

pragma solidity ^0.8.0;

import "./helpers/ReentrancyGuard.sol";
import { Vault } from "./Vault.sol";
import { Treasury } from "./Treasury.sol";
import { AbacusController } from "./AbacusController.sol";
import { EpochVault } from "./EpochVault.sol";

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "hardhat/console.sol";

/// @title Spot Pool Closure
/// @author Gio Medici
/// @notice Created in the closure phase of a Spot pool
contract ClosePool is ReentrancyGuard, Initializable {

    /* ======== ADDRESS ======== */

    /// @notice wrapped NFT that represents ownership of vault
    address ownerToken;

    /// @notice factory contract for Spot pools
    address vaultFactory;

    /// @notice parent Spot pool
    address public vault;

    /// @notice winner of auction
    address public highestBidder;

    /* ======== UINT ======== */

    /// @notice time Spot pool closed
    uint256 public closureTime;

    /// @notice valuation of NFT
    uint256 public nftVal;

    /// @notice exit fee paid to close the pool
    uint256 public exitFee;

    /// @notice profits generated and held for holders around at closure time
    uint256 public postPoolDistribution;

    /// @notice end time of auction
    uint256 public auctionEndTime;

    /// @notice highest current bid (eventually winning bid)
    uint256 public highestBid;

    /// @notice premium earned in auction (auction sale price - nft valuation)
    uint256 public auctionPremium;

    /* ======== BOOL ======== */

    /// @notice is the auction live
    bool public auctionLive;

    /// @notice is the auction complete
    bool public auctionComplete;

    /// @notice was the NFT redeemed (i.e. exit fee closure used)
    bool public nftRedeemed;

    /* ======== MAPPING ======== */

    /// @notice each users TVL that was locked up for the auction
    mapping(address => uint256) public tvlAuction;

    /// @notice user principal (calculated only in auction phase)
    mapping(address => uint256) public principal;
    
    /// @notice was a users principal calculated
    mapping(address => bool) public principalCalculated;

    /// @notice did a user close their account already
    mapping(address => bool) public claimed;

    /* ======== EVENT ======== */

    event NewBid(address _bidder, uint256 _amount);
    event AuctionEnded(address _highestBidder, uint256 _highestBid);
    event AccountClosed(address _user, uint256 _principal, uint256 _profit, uint256 _creditsPurchased);

    /* ======== CONSTRUCTOR ======== */

    function initialize(
        address _ownerToken,
        address _vault,
        uint256 _nftVal,
        uint256 _exitFee, 
        uint256 _postPoolDistribution,
        uint256 _choice
    ) external initializer {
        ownerToken = _ownerToken;
        vault = _vault;
        auctionLive = true;
        nftVal = _nftVal;
        exitFee = _exitFee;
        postPoolDistribution = _postPoolDistribution;
        if(_choice == 0) {
            auctionLive = true;
            auctionEndTime = block.timestamp + 48 hours;
        }
        else if(_choice == 1) {
            nftRedeemed = true;
        }

        closureTime = block.timestamp; 
    }

    /* ======== AUCTION ======== */

    /// @notice submit new bid in NFT auction
    function newBid() nonReentrant payable external {
        require(msg.value > highestBid && block.timestamp < auctionEndTime);
        (bool sent, ) = payable(msg.sender).call{value: tvlAuction[msg.sender]}("");
        require(sent);
        tvlAuction[msg.sender] = msg.value;
        highestBid = msg.value;
        highestBidder = msg.sender;
        emit NewBid(highestBidder, highestBid);
    }

    /// @notice claim idle bids (bid that was outbid)
    function claim() nonReentrant external {
        require(msg.sender != highestBidder);
        uint256 payout = tvlAuction[msg.sender];
        tvlAuction[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: payout}("");
        require(sent);
    }

    /// @notice end auction once time concludes
    function endAuction() nonReentrant external {
        require(block.timestamp > auctionEndTime);
        tvlAuction[highestBidder] = 0;

        if(highestBid > nftVal) {
            auctionPremium = highestBid - nftVal;
        }

        auctionLive = false;
        auctionComplete = true;
        (Vault(payable(vault)).heldToken()).transferFrom(address(this), highestBidder, Vault(payable(vault)).heldTokenId());
        emit AuctionEnded(highestBidder, highestBid);
    }

    /* ======== ACCOUNT CLOSURE ======== */

    /// @notice Calculate a users principal based on their open tickets
    /** 
    @dev (1) If user ticket is completely over the value of the ending auction price they lose their entire ticket balance.
         (2) If user ticket is partially over final nft value then the holders of that ticket receive a discounted return per token
            - Ex: NFT val -> 62 E. Any ticket up to 60 E will be made whole, but anyone who holds position in ticket 60 - 63 E will
                             receive 2/3 of their position in the 60 - 63 E ticket.
         (3) If user ticket is within price range they receive entire position. 
            - Ex: NFT val -> 65 E and user position 0 - 3 E, they'll be made whole.
    */
    /// @param tickets represents all of the users positions held. ticket maps to a position within those tickets. 
    function calculatePrincipal(uint256[] memory tickets) nonReentrant external {
        require(auctionComplete && !principalCalculated[msg.sender]);
        principalCalculated[msg.sender] = true;
        principal[msg.sender] += Vault(payable(vault)).adjustTicketInfo(msg.sender, tickets, (nftVal > highestBid ? highestBid : nftVal));
    }

    /// @notice After an auction, close a users account and pay them out properly according to their calculated principal
    /**
    @dev (1) calculate profit based on final NFT val
            - If auction sale > val, profit is split across all tokens
            - If auction sale < val, profit is 0
         (2) check user choice for credit purchase
         (3) update epoch credit count and send cost of purchase to treausry
         (4) return remaining funds to user
    */
    /// @param _amountCredits amount of available credits (credits earned via lockup) that user would like to purchase
    /// @param _amountOfProfitToUse amount of profit that user would like to trade for credits (profits traded at 1 ETH:1 credit ratio)
    function closeAccountAuction(uint256 _amountCredits, uint256 _amountOfProfitToUse) nonReentrant external {
        //check that the auction has concluded, user principal has been calculated, and that they haven't already claimed their principal
        require(auctionComplete && principalCalculated[msg.sender] && !claimed[msg.sender]);
        
        //mark account as closed
        claimed[msg.sender] = true;
        Vault _vault = Vault(payable(vault));

        //check how many tokens the user has locked in the Spot pool and how many credits they have available for purchase
        uint256 userTokensLocked = _vault.getTokensLocked(msg.sender);
        uint256 creditsAvailableForPurchase = _vault.getCreditsAvailableForPurchase(msg.sender, closureTime);
        
        //set cost of credits
        uint256 cost = _vault.costToPurchaseCredits(msg.sender, closureTime, _amountCredits + _amountOfProfitToUse);
        cost += _amountOfProfitToUse;

        //check the total amount of locked token in the Spot pool
        uint256 totalTokensLocked = _vault.tokensLocked();

        //calculate principal payout
        uint256 payout = principal[msg.sender];
        principal[msg.sender] = 0;

        //calculate profit based on premium sale
        uint256 profit = auctionPremium * userTokensLocked / totalTokensLocked;

        //make sure that user isn't trying to buy more credits than they're allowed to
        require(_amountCredits + _amountOfProfitToUse <= creditsAvailableForPurchase + profit && _amountOfProfitToUse <= profit);

        //update epoch credit amount in the epoch vault
        EpochVault(AbacusController(_vault.controller()).epochVault()).updateEpoch(address(_vault.heldToken()), _vault.heldTokenId(), msg.sender, _amountCredits + _amountOfProfitToUse);
        
        //return any left over value that wasn't spent by the user to purchase credits
        payable(msg.sender).transfer(payout + profit - cost);

        //send amount paid to purchase the credits to Abacus treasury 
        payable(AbacusController(_vault.controller()).abcTreasury()).transfer(cost);

        emit AccountClosed(msg.sender, payout, profit, _amountCredits + _amountOfProfitToUse);
    }

    /// @notice After an exit fee closure, close a users account and pay them out properly according to their calculated principal
    /// @dev in this case the user will never be at a loss (all tickets will be fulfilled) and all will be at a profit
    /// @param _amountCredits amount of available credits (credits earned via lockup) that user would like to purchase
    /// @param _amountOfProfitToUse amount of profit that user would like to trade for credits (profits traded at 1 ETH:1 credit ratio)
    function closeAccountExit(uint256 _amountCredits, uint256 _amountOfProfitToUse) nonReentrant external {
        //check that the pool was closed through exit fee payment (in which case nftRedeemed == true) and that account isn't closed already
        require(nftRedeemed && !claimed[msg.sender]);

        //mark account as closed
        claimed[msg.sender] = true;
        Vault _vault = Vault(payable(vault));

        //check how many tokens the user has locked in the Spot pool and how many credits they have available for purchase
        uint256 userTokensLocked = _vault.getTokensLocked(msg.sender);
        uint256 creditsAvailableForPurchase = _vault.getCreditsAvailableForPurchase(msg.sender, closureTime);

        //set cost of credits
        uint256 cost = _vault.costToPurchaseCredits(msg.sender, closureTime, _amountCredits);
        cost += _amountOfProfitToUse;

        //check the total amount of locked token in the Spot pool
        uint256 totalTokensLocked = _vault.tokensLocked(); 

        //calculate principal payout
        uint256 payout = userTokensLocked * Vault(payable(vault)).pricePerToken() / 1e18;

        //calculate profit based on premium sale
        uint256 profit = (exitFee + postPoolDistribution) * userTokensLocked / totalTokensLocked;

        //make sure that user isn't trying to buy more credits than they're allowed to

        //update epoch credit amount in the epoch vault
        require(_amountCredits + _amountOfProfitToUse <= creditsAvailableForPurchase + profit && _amountOfProfitToUse <= profit);
        

        //update epoch credit amount in the epoch vault
        EpochVault(AbacusController(_vault.controller()).epochVault()).updateEpoch(address(_vault.heldToken()), _vault.heldTokenId(), msg.sender, _amountCredits + _amountOfProfitToUse);
        
        //return any left over value that wasn't spent by the user to purchase credits
        payable(msg.sender).transfer(payout + profit - cost);

        //send amount paid to purchase the credits to Abacus treasury 
        payable(AbacusController(_vault.controller()).abcTreasury()).transfer(cost);

        emit AccountClosed(msg.sender, payout, profit, _amountCredits + _amountOfProfitToUse);
    }

    /* ======== FALLBACK FUNCTIONS ======== */

    receive() external payable {}
    fallback() external payable {}
}

pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IClosePool {
    function initialize(
        address _ownerToken,
        address _vault,
        uint256 _nftVal,
        uint256 _exitFee, 
        uint256 _postPoolDistribution,
        uint256 _choice
    ) external;
}

pragma solidity ^0.8.0;

import { ABCToken } from "./AbcToken.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ABC Treasury
/// @author Gio Medici
/// @notice Holds the entire Abacus treasury
contract Treasury {

    /* ======== ADDRESS ======== */

    //admin of treasury (will be changed to multisig after phase 1 beta and then DAO voting after phase 2)
    address public admin;

    //multisig of treasury (takes power from admin address after phase 1)
    address public multisig;

    //abc token address
    address public abcToken;

    //vault factory address
    address public vaultFactory;

    /* ======== BOOLEAN ======== */
    
    //backstop that can be switched on and off (once DAO receives power post-phase 2)
    bool public backstopActive;

    /* ======== CONSTRUCTOR ======== */

    constructor() {
        admin = msg.sender;
    }

    /* ======== SETTERS ======== */

    /// @notice configure backstop status
    function setTreasuryBackstop(bool _status) external {
        require(msg.sender == admin);
        backstopActive = _status;
    }

    /// @notice set admin address
    function setAdmin(address _admin) external {
        require(msg.sender == admin);
        admin = _admin; 
    }

    /// @notice set multisig address 
    function setMultisig(address _multisig) external {
        require(msg.sender == admin);
        multisig = _multisig;
    }

    /* ======== TREASURY ENGAGEMENT ======== */

    /// @notice withdraw eth in treasury (ONLY USED IN CASE OF EMERGENCY or SWITCHING TREASURY TO NEW ADDRESS)
    function withdrawEth() external {
        require(msg.sender == admin);
        uint ethBalance = address(this).balance;
        if(multisig == address(0)) {
            bool sent = payable(admin).send(ethBalance);
            require(sent, "Failed to send Ether");
        }
        else {
            bool sent = payable(multisig).send(ethBalance);
            require(sent, "Failed to send Ether");
        }
    }

    /// @notice burn ABC for risk free value if DAO turns on burn capability
    /// @param _amount how many tokens to burn for value backed
    function claimValueBacked(uint256 _amount) external {
        require(backstopActive);
        uint256 rewardPerToken = address(this).balance * 1e18 / ABCToken(payable(abcToken)).totalSupply();
        ABCToken(payable(abcToken)).burn(msg.sender, _amount);
        payable(msg.sender).transfer(rewardPerToken * _amount / 1e18);
    }

    /* ======== FALLBACK FUNCTIONS ======== */

    receive() external payable {}
    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
    uint256[49] private __gap;
}

pragma solidity ^0.8.0;

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <[email protected]π.com>, Eenae <[email protected]>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /// @dev counter to allow mutex lock with only one SSTORE operation
  uint256 private _guardCounter = 1;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one `nonReentrant` function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and an `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

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
interface IERC165 {
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

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Metadata.sol";
import "../helpers/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}