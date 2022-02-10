// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.10;
pragma abicoder v2;

import "./interfaces/ITreasury.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IBondDepository.sol";
import "./types/Ownable.sol";

/**
 *  This contract allows Starship seed investors and advisors to claim tokens.
 *  step was taken to ensure fair distribution of exposure in the network.
 */
contract StarshipCrowdsale is Ownable {
    /* ========== DEPENDENCIES ========== */

    /* ========== EVENTS ========== */

    event StarMinted(address caller, uint256 amount, address reserve);
    event CrowdsaleInitialized(address caller, uint256 startTime);
    
    /* ========== STATE VARIABLES ========== */

    // our token
    IERC20 public immutable star;
    // receieves deposits, mints and returns STAR
    ITreasury internal immutable treasury;
  
    IBondDepository internal immutable depository;

    uint public constant MAX_TOKENS = 12500000 * 1e9;
    uint256 public tokensMinted;

    uint256 public startTime;
    bool public isActive;
    bool public isCompleted;
        
    uint256 public endTime;

    constructor( address _star, address _treasury, address _depository )
    {
      tokensMinted = 0;
      star = IERC20(_star);
      treasury = ITreasury(_treasury);
      depository = IBondDepository(_depository);
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    /**
     * @notice allows wallet to mint STAR via the feb crowdsale
     * @param _amount uint256
     * @param _reserve address
     */
    function MintStar(uint256 _amount, address _reserve) external {
        uint256 minted = _crowdsaleMint(_amount, _reserve);
    }

    /**
     * @notice logic for purchasing STAR
     * @param _amount uint256
     * @param _reserve address
     * @return toSend_ uint256
     */
    function _crowdsaleMint(uint256 _amount, address _reserve) internal returns (uint256 toSend_) {
        
        require(activeSale(), "crowdsale is inactive");
        
        toSend_ = treasury.deposit(msg.sender,_amount, _reserve, treasury.tokenValue(_reserve, _amount) * 75 / 100);
        require(validTransaction(toSend_), "minting too many tokens");
        tokensMinted += toSend_;
        depository.crowdsalePurchase(toSend_);
        
        emit StarMinted(msg.sender, _amount, _reserve);
    }
    
    function initialize() external onlyOwner {
      isActive = true;
      startTime = block.timestamp;
      endTime = block.timestamp + 3 days;
      emit CrowdsaleInitialized(msg.sender, startTime);
    }
    
    function completeSale() external onlyOwner {
      isActive = false;
      isCompleted = true;
    }
    
    function resetCrowdsale() external onlyOwner {
      isActive = false;
      isCompleted = false;
      startTime = 0;
      endTime = 0;
      tokensMinted = 0;
    }

    function activeSale() public returns (bool) { 
    
      bool withinPeriod = block.timestamp >= startTime && block.timestamp <= endTime;
      
      return isActive && withinPeriod;
    }
    
    function validTransaction(uint256 toSend_) internal returns (bool) {
      
      bool validPurchase = tokensMinted + toSend_ <= MAX_TOKENS;
      //bool nonZeroPurchase = msg.value != 0;
      return validPurchase;
    }

    /* ========== VIEW FUNCTIONS ========== */

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITreasury {
    function deposit(
        address _from,
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (uint256);

    function baseSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IStaking {
    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claim
    ) external returns (uint256);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit() external returns (uint256);

    function toggleLock() external;

    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256);

    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_);

    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_);

    function rebase() external;

    function index() external view returns (uint256);

    function contractBalance() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function supplyInWarmup() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IBondDepository {
    // Info about each type of market
    struct Market {
        uint256 capacity; // capacity remaining
        IERC20 quoteToken; // token to accept as payment
        bool capacityInQuote; // capacity limit is in payment token (true) or in OHM (false, default)
        uint64 totalDebt; // total debt from market
        uint64 maxPayout; // max tokens in/out (determined by capacityInQuote false/true, respectively)
        uint64 sold; // base tokens out
        uint256 purchased; // quote tokens in
    }

    // Info for creating new markets
    struct Terms {
        bool fixedTerm; // fixed term or fixed expiration
        uint64 controlVariable; // scaling variable for price
        uint48 vesting; // length of time from deposit to maturity if fixed-term
        uint48 conclusion; // timestamp when market no longer offered (doubles as time when market matures if fixed-expiry)
        uint64 maxDebt; // 9 decimal debt maximum in OHM
    }

    // Additional info about market.
    struct Metadata {
        uint48 lastTune; // last timestamp when control variable was tuned
        uint48 lastDecay; // last timestamp when market was created and debt was decayed
        uint48 length; // time from creation to conclusion. used as speed to decay debt.
        uint48 depositInterval; // target frequency of deposits
        uint48 tuneInterval; // frequency of tuning
        uint8 quoteDecimals; // decimals of quote token
    }

    // Control variable adjustment data
    struct Adjustment {
        uint64 change;
        uint48 lastAdjustment;
        uint48 timeToAdjusted;
        bool active;
    }

    /**
     * @notice deposit market
     * @param _bid uint256
     * @param _amount uint256
     * @param _maxPrice uint256
     * @param _user address
     * @param _referral address
     * @return payout_ uint256
     * @return expiry_ uint256
     * @return index_ uint256
     */
    function deposit(
        uint256 _bid,
        uint256 _amount,
        uint256 _maxPrice,
        address _user,
        address _referral
    )
        external
        returns (
            uint256 payout_,
            uint256 expiry_,
            uint256 index_
        );

    function create(
        IERC20 _quoteToken, // token used to deposit
        uint256[3] memory _market, // [capacity, initial price]
        bool[2] memory _booleans, // [capacity in quote, fixed term]
        uint256[2] memory _terms, // [vesting, conclusion]
        uint32[2] memory _intervals // [deposit interval, tune interval]
    ) external returns (uint256 id_);

    function close(uint256 _id) external;
    
    function setCrowdsale(address _contract) external;
    
    function crowdsalePurchase (uint256 _payout) external returns (uint256);

    function isLive(uint256 _bid) external view returns (bool);

    function liveMarkets() external view returns (uint256[] memory);

    function liveMarketsFor(address _quoteToken) external view returns (uint256[] memory);

    function payoutFor(uint256 _amount, uint256 _bid) external view returns (uint256);

    function marketPrice(uint256 _bid) external view returns (uint256);

    function currentDebt(uint256 _bid) external view returns (uint256);

    function debtRatio(uint256 _bid) external view returns (uint256);

    function debtDecay(uint256 _bid) external view returns (uint64);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

import "../interfaces/IOwnable.sol";

abstract contract Ownable is IOwnable {
    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceManagement() public virtual override onlyOwner {
        emit OwnershipPulled(_owner, address(0));
        _owner = address(0);
        _newOwner = address(0);
    }

    function pushManagement(address newOwner_) public virtual override onlyOwner {
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
        _newOwner = address(0);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IOwnable {
    function owner() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}