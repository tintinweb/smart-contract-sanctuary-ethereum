/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// File: contracts/VZToken.sol



pragma solidity ^0.4.17;

    contract VZToken {
/// Fields:
    string public constant name = "VOMO";
    string public constant symbol = "VZT";
    uint public constant decimals = 18;
    uint public constant PRICE = 48050; // per 1 Ether
    uint actualPrice =PRICE-((PRICE/100)*2);
    

// price
// Cap is 4000 ETH
// 1 eth = 100; presale 
// uint public constant TOKEN_SUPPLY = 50000000 ;

    enum State{
    Init,
    Running
    }
    uint256 public PRESALE_END_COUNTDOWN;
    uint numTokens;
    uint256 totalSupply_;
    address funder1 = 0x69e56D0aF44380BC3B0D666c4207BBF910f0ADC9;
    address funder2 = 0x11a99181d9d954863B41C3Ec51035D856b69E9e8;
    address _referral;
    State public currentState = State.Running;
    uint public initialToken = 0; // amount of tokens already sold

// Gathered funds can be withdrawn only to escrow's address.
    address public escrow = 0;
    mapping (address => uint256) private balance;
    mapping (address => bool) ownerAppended;
    address[] public owners;

/// Modifiers:
    modifier onlyInState(State state){ require(state == currentState); _; }

/// Events:

    event Transfer(address indexed from, address indexed to, uint256 _value);

/// Functions:
/// @dev Constructor
    function VZToken(address _escrow, uint256 _PRESALE_END_COUNTDOWN) public {
    // numTokens = _numTokens;
    PRESALE_END_COUNTDOWN = _PRESALE_END_COUNTDOWN;
    require(_escrow != 0);
    escrow = _escrow;
    totalSupply_ = 1400000000000000000000000000;

    uint fundToken1 = (totalSupply_/100)*15;
    balance[funder1] += fundToken1;
    Transfer(msg.sender, funder1,  fundToken1);
    
    uint fundToken2 = (totalSupply_/100)*5;
    balance[funder2] += fundToken2;
    Transfer(msg.sender, funder2,  fundToken2);
    uint totalFunder = (fundToken1 +  fundToken2);
    uint supplyBal = totalSupply_ - totalFunder;

    balance[msg.sender] = supplyBal;


    }


    function buyTokens(address _buyer, address _referral) public payable onlyInState(State.Running) {
    require(_referral != 0);
    require(now <= PRESALE_END_COUNTDOWN, "Presale Date Exceed.");
    require(msg.value != 0);

    uint newTokens = msg.value * actualPrice;
    uint refToken = (newTokens/100)*4;
    require(initialToken + newTokens <= totalSupply_);

    balance[_referral] += refToken;
    Transfer(msg.sender, _referral,  refToken);

    balance[_buyer] += newTokens;
    uint deductTokens = newTokens + refToken;
    balance[msg.sender] -= deductTokens;
    initialToken += newTokens;
    if(!ownerAppended[_buyer]) {
    ownerAppended[_buyer] = true;
    owners.push(_buyer);
    }
    Transfer(msg.sender, _buyer,  newTokens);
    
    if(this.balance > 0) {
    require(escrow.send(this.balance));
    }

    }

/// @dev Returns number of tokens owned by given address.
/// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256) {
    return balance[_owner];
    }

    function getPrice() constant returns(uint) {
    return PRICE;
    }
    address public owner;

//Transfer Function
    // uint numTokens = 1000000000000000000;
    mapping(address => bool) public hasClaimed;
    
    // function Airdrop(address receiver) public returns (bool) {
    // require(hasClaimed[msg.sender] == false) ;    
    // balance[msg.sender] -= numTokens;
    // balance[receiver] += numTokens;
    // emit Transfer(msg.sender, receiver, numTokens);
    // hasClaimed[msg.sender] == true;
    // return true;
    // }

// Tranfer Owbnership
    function Ownable() {
    owner = msg.sender;
    }

    modifier onlyOwner() {
    require(msg.sender == owner);
    _ ;
    }
    function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
    owner = newOwner;
    }
    }

// Default fallback function
    function() payable {
    buyTokens(msg.sender, _referral);
    }
    
}
// File: contracts/VZTPresale.sol

/**
 *Submitted for verification at Etherscan.io on 2018-01-16
*/

pragma solidity ^0.4.26;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * https://github.com/OpenZeppelin/zeppelin-solidity/
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function cei(uint256 a, uint256 b) internal pure returns (uint256) {
    return ((a + b - 1) / b) * b;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * https://github.com/OpenZeppelin/zeppelin-solidity/
 */
contract Ownable {
  address public owner;                                                     // Operational owner.
  address public masterOwner = 0x203C8d43c663298D3D6b76b44199fCFe0bd7529E;  // for ownership transfer segregation of duty, hard coded to wallet account

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public {
    require(newOwner != address(0));
    require(masterOwner == msg.sender); // only master owner can initiate change to ownership
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 * https://github.com/OpenZeppelin/zeppelin-solidity/
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}
contract VZTPresale is Ownable, Pausable {
    using SafeMath for uint256;
 
 VZToken token;
  
  // this multi-sig address will be replaced on production:
    address public constant VZT_WALLET = 0x4D9B157E1c2ed052560304ce10E81ec67AEAbbdF;
 /* if the minimum funding goal in wei is not reached, buyers may withdraw their funds */
    uint256 public constant MIN_FUNDING_GOAL = 200 * 10 ** 18;
    uint256 public constant PRESALE_TOKEN_SOFT_CAP = 4200000;    // presale soft cap of 4200000 VOMO
    uint256 public constant PRESALE_RATE = 48050;              // presale price is 1 ETH to 48050 VOMO
    uint256 public constant SOFTCAP_RATE = 25;                 // presale price becomes 1 ETH to 25 VOMO after softcap is reached
    uint256 public constant PRESALE_TOKEN_HARD_CAP = 9450000;    // presale token hardcap
    uint256 public constant MAX_GAS_PRICE = 50000000000;

    uint256 public minimumPurchaseLimit = 0.1 * 10 ** 18;             // minimum purchase is 0.1 ETH to make the gas worthwhile
    uint256 public startDate = 1654235321;                            // January 15, 2018 7:30 AM UTC
    uint256 public endDate = 1656654521; 
    uint256 public tokensSold = 0;
    uint256 public numWhitelisted = 0; 
      uint256 public totalCollected = 0; 


    struct PurchaseLog {
        uint256 ethValue;
        uint256 vztValue;
        bool kycApproved;
        bool tokensDistributed;
        uint256 lastPurchaseTime;
        uint256 lastDistributionTime;
    }
   
 //capture refunds
    mapping (address => bool) public refundLog;
    //purchase log that captures
    mapping (address => PurchaseLog) public purchaseLog;
    
    bool public isFinalized = false;                                        // it becomes true when token sale is completed
    bool public publicSoftCapReached = false;  
    // list of addresses that can purchase
    mapping(address => bool) public whitelist;
    
    //capture buyers in array, this is for quickly looking up from DAPP
    address[] public buyers;
    uint256 public buyerCount = 0;                                                                           // it becomes true when public softcap is reached

    // event logging for token purchase
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
     // event logging for token sale finalized
    event Finalized();

     // event logging for softcap reached
    event SoftCapReached();

     // event logging for each individual refunded amount
    event Refunded(address indexed beneficiary, uint256 weiAmount);

      event FundsTransferred();
    // event logging for each individual refunded amount 
    event transfer(address indexed user, uint256 VomoValue);
    
    
    // event logging for each individual distributed token + bonus
    event TokenDistributed(address indexed purchaser, uint256 tokenAmt);
 /*
        Constructor to initialize everything.
    */
    function VZTPresale(address _token, address _owner) public {
        require(_token != address(0));
        require(_owner != address(0));
        token = VZToken(_token);
        // default owner
        owner = _owner;
    }

    /*
       default function to buy tokens.
    */
    function() payable public whenNotPaused {
        doPayment(msg.sender);
    }

     /*
       allows owner to register token purchases done via fiat-eth (or equivalent currency)
    */
    function payableInFiatEth(address buyer, uint256 value) external onlyOwner {
        // do public presale
        purchasePresale(buyer, value);
    }

    function setTokenContract(address _token) external onlyOwner {
        require(token != address(0));
        token = VZToken(_token);

    }

    /**
    * add address to whitelist
    * @param _addr wallet address to be added to whitelist
    */
    function addToWhitelist(address _addr) public onlyOwner returns (bool) {
        require(_addr != address(0));
        if(!whitelist[_addr]) {
            whitelist[_addr] = true;
            numWhitelisted++;
        }
        purchaseLog[_addr].kycApproved = true;
        return true;
    }

     /**
      * add address to whitelist
      * @param _addresses wallet addresses to be whitelisted
      */
    function addManyToWhitelist(address[] _addresses) 
        external 
        onlyOwner 
        returns (bool) 
        {
        require(_addresses.length <= 50);
        uint idx = 0;
        uint len = _addresses.length;
        for (; idx < len; idx++) {
            address _addr = _addresses[idx];
            addToWhitelist(_addr);
        }
        return true;
    }
    /**
     * remove address from whitelist
     * @param _addr wallet address to be removed from whitelist
     */
     function removeFomWhitelist(address _addr) public onlyOwner returns (bool) {
         require(_addr != address(0));
         require(whitelist[_addr]);
        delete whitelist[_addr];
        purchaseLog[_addr].kycApproved = false;
        numWhitelisted--;
        return true;
     }

    /*
        Send Tokens tokens to a buyer:
        - and KYC is approved
    */
    function sendTokens(address _user) public onlyOwner returns (bool) {
        require(_user != address(0));
        require(_user != address(this));
        require(purchaseLog[_user].kycApproved);
        require(purchaseLog[_user].vztValue > 0);
        require(!purchaseLog[_user].tokensDistributed);
        require(!refundLog[_user]);
        purchaseLog[_user].tokensDistributed = true;
        purchaseLog[_user].lastDistributionTime = now;
        transfer(_user, purchaseLog[_user].vztValue);
        TokenDistributed(_user, purchaseLog[_user].vztValue);
        return true;
    }

    /*
        Refund ethers to buyer if KYC couldn't/wasn't verified.
    */
    function refundEthIfKYCNotVerified(address _user) public onlyOwner returns (bool) {
        if (!purchaseLog[_user].kycApproved) {
            return doRefund(_user);
        }
        return false;
    }

    /*

    /*
        return true if buyer is whitelisted
    */
    function isWhitelisted(address buyer) public view returns (bool) {
        return whitelist[buyer];
    }

    /*
        Check to see if this is public presale.
    */
    function isPresale() public view returns (bool) {
        return !isFinalized && now >= startDate && now <= endDate;
    }

    /*
        check if allocated has sold out.
    */
    function hasSoldOut() public view returns (bool) {
        return PRESALE_TOKEN_HARD_CAP - tokensSold < getMinimumPurchaseVZTLimit();
    }

    /*
        Check to see if the presale end date has passed or if all tokens allocated
        for sale has been purchased.
    */
    function hasEnded() public view returns (bool) {
        return now > endDate || hasSoldOut();
    }

    /*
        Determine if the minimum goal in wei has been reached.
    */
    function isMinimumGoalReached() public view returns (bool) {
        return totalCollected >= MIN_FUNDING_GOAL;
    }

    /*
        For the convenience of presale interface to present status info.
    */
    function getSoftCapReached() public view returns (bool) {
        return publicSoftCapReached;
    }

    function setMinimumPurchaseEtherLimit(uint256 newMinimumPurchaseLimit) external onlyOwner {
        require(newMinimumPurchaseLimit > 0);
        minimumPurchaseLimit = newMinimumPurchaseLimit;
    }
    /*
        For the convenience of presale interface to find current tier price.
    */

    function getMinimumPurchaseVZTLimit() public view returns (uint256) {
        if (getTier() == 1) {
            return minimumPurchaseLimit.mul(PRESALE_RATE); //1250VZT/ether
        } else if (getTier() == 2) {
            return minimumPurchaseLimit.mul(SOFTCAP_RATE); //1150VZT/ether
        }
        return minimumPurchaseLimit.mul(1000); //base price
    }

    /*
        For the convenience of presale interface to find current discount tier.
    */
    function getTier() public view returns (uint256) {
        // Assume presale top tier discount
        uint256 tier = 1;
        if (now >= startDate && now < endDate && getSoftCapReached()) {
            // tier 2 discount
            tier = 2;
        }
        return tier;
    }

    /*
        For the convenience of presale interface to present status info.
    */
    function getPresaleStatus() public view returns (uint256[3]) {
        // 0 - presale not started
        // 1 - presale started
        // 2 - presale ended
        if (now < startDate)
            return ([0, startDate, endDate]);
        else if (now <= endDate && !hasEnded())
            return ([1, startDate, endDate]);
        else
            return ([2, startDate, endDate]);
    }

    /*
        Called after presale ends, to do some extra finalization work.
    */
    function finalize() public onlyOwner {
        // do nothing if finalized
        require(!isFinalized);
        // presale must have ended
        require(hasEnded());

        if (isMinimumGoalReached()) {
            // transfer to VectorZilla multisig wallet
            VZT_WALLET.transfer(this.balance);
            // signal the event for communication
            FundsTransferred();
        }
        // mark as finalized
        isFinalized = true;
        // signal the event for communication
        Finalized();
    }


    /**
     * @notice `proxyPayment()` allows the caller to send ether to the VZTPresale
     * and have the tokens created in an address of their choosing
     * @param _owner The address that will hold the newly created tokens
     */
    function proxyPayment(address _owner) 
    payable 
    public
    whenNotPaused 
    returns(bool success) 
    {
        return doPayment(_owner);
    }

    /*
        Just in case we need to tweak pre-sale dates
    */
    function setDates(uint256 newStartDate, uint256 newEndDate) public onlyOwner {
        require(newEndDate >= newStartDate);
        startDate = newStartDate;
        endDate = newEndDate;
    }


    // @dev `doPayment()` is an internal function that sends the ether that this
    //  contract receives to the `vault` and creates tokens in the address of the
    //  `_owner` assuming the VZTPresale is still accepting funds
    //  @param _owner The address that will hold the newly created tokens
    // @return True if payment is processed successfully
    function doPayment(address _owner) internal returns(bool success) {
        require(tx.gasprice <= MAX_GAS_PRICE);
        // Antispam
        // do not allow contracts to game the system
        require(_owner != address(0));
        require(!isContract(_owner));
        // limit the amount of contributions to once per 100 blocks
        //require(getBlockNumber().sub(lastCallBlock[msg.sender]) >= maxCallFrequency);
        //lastCallBlock[msg.sender] = getBlockNumber();

        if (msg.sender != owner) {
            // stop if presale is over
            require(isPresale());
            // stop if no more token is allocated for sale
            require(!hasSoldOut());
            require(msg.value >= minimumPurchaseLimit);
        }
        require(msg.value > 0);
        purchasePresale(_owner, msg.value);
        return true;
    }

    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) constant internal returns (bool) {
        if (_addr == 0) {
            return false;
        }
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    /// @dev Internal function to process sale
    /// @param buyer The buyer address
    /// @param value  The value of ether paid
    function purchasePresale(address buyer, uint256 value) internal {
         require(value >= minimumPurchaseLimit);
         require(buyer != address(0));
        uint256 tokens = 0;
        // still under soft cap
        if (!publicSoftCapReached) {
            // 1 ETH for 1,250 VZT
            tokens = value * PRESALE_RATE;
            // get less if over softcap
            if (tokensSold + tokens > PRESALE_TOKEN_SOFT_CAP) {
                uint256 availablePresaleTokens = PRESALE_TOKEN_SOFT_CAP - tokensSold;
                uint256 softCapTokens = (value - (availablePresaleTokens / PRESALE_RATE)) * SOFTCAP_RATE;
                tokens = availablePresaleTokens + softCapTokens;
                // process presale at 1 ETH to 1,150 VZT
                processSale(buyer, value, tokens, SOFTCAP_RATE);
                // public soft cap has been reached
                publicSoftCapReached = true;
                // signal the event for communication
                SoftCapReached();
            } else {
                // process presale @PRESALE_RATE
                processSale(buyer, value, tokens, PRESALE_RATE);
            }
        } else {
            // 1 ETH to 1,150 VZT
            tokens = value * SOFTCAP_RATE;
            // process presale at 1 ETH to 1,150 VZT
            processSale(buyer, value, tokens, SOFTCAP_RATE);
        }
    }

    /*
        process sale at determined price.
    */
    function processSale(address buyer, uint256 value, uint256 vzt, uint256 vztRate) internal {
        require(buyer != address(0));
        require(vzt > 0);
        require(vztRate > 0);
        require(value > 0);

        uint256 vztOver = 0;
        uint256 excessEthInWei = 0;
        uint256 paidValue = value;
        uint256 purchasedVzt = vzt;

        if (tokensSold + purchasedVzt > PRESALE_TOKEN_HARD_CAP) {// if maximum is exceeded
            // find overage
            vztOver = tokensSold + purchasedVzt - PRESALE_TOKEN_HARD_CAP;
            // overage ETH to refund
            excessEthInWei = vztOver / vztRate;
            // adjust tokens purchased
            purchasedVzt = purchasedVzt - vztOver;
            // adjust Ether paid
            paidValue = paidValue - excessEthInWei;
        }

        /* To quick lookup list of buyers (pending token, kyc, or even refunded)
            we are keeping an array of buyers. There might be duplicate entries when
            a buyer gets refund (incomplete kyc, or requested), and then again contributes.
        */
        if (purchaseLog[buyer].vztValue == 0) {
            buyers.push(buyer);
            buyerCount++;
        }

        //if not whitelisted, mark kyc pending
        if (!isWhitelisted(buyer)) {
            purchaseLog[buyer].kycApproved = false;
        }
        //reset refund status in refundLog
        refundLog[buyer] = false;

         // record purchase in purchaseLog
        purchaseLog[buyer].vztValue = SafeMath.add(purchaseLog[buyer].vztValue, purchasedVzt);
        purchaseLog[buyer].ethValue = SafeMath.add(purchaseLog[buyer].ethValue, paidValue);
        purchaseLog[buyer].lastPurchaseTime = now;


        // total Wei raised
        totalCollected += paidValue;
        // total VZT sold
        tokensSold += purchasedVzt;

        /*
            For event, log buyer and beneficiary properly
        */
        address beneficiary = buyer;
        if (beneficiary == msg.sender) {
            beneficiary = msg.sender;
        }
        // signal the event for communication
        TokenPurchase(buyer, beneficiary, paidValue, purchasedVzt);
        // transfer must be done at the end after all states are updated to prevent reentrancy attack.
        if (excessEthInWei > 0) {
            // refund overage ETH
            buyer.transfer(excessEthInWei);
            // signal the event for communication
            Refunded(buyer, excessEthInWei);
        }
    }

    /*
        Distribute tokens to a buyer:
        - when minimum goal is reached
        - and KYC is approved
    */
    function distributeTokensFor(address buyer) external onlyOwner returns (bool) {
        require(isFinalized);
        require(hasEnded());
        if (isMinimumGoalReached()) {
            return sendTokens(buyer);
        }
        return false;
    }

    /*
        purchaser requesting a refund, only allowed when minimum goal not reached.
    */
    function claimRefund() external returns (bool) {
        return doRefund(msg.sender);
    }

    /*
      send refund to purchaser requesting a refund 
   */
    function sendRefund(address buyer) external onlyOwner returns (bool) {
        return doRefund(buyer);
    }

    /*
        Internal function to manage refunds 
    */
    function doRefund(address buyer) internal returns (bool) {
        require(tx.gasprice <= MAX_GAS_PRICE);
        require(buyer != address(0));
        if (msg.sender != owner) {
            // cannot refund unless authorized
            require(isFinalized && !isMinimumGoalReached());
        }
        require(purchaseLog[buyer].ethValue > 0);
        require(purchaseLog[buyer].vztValue > 0);
        require(!refundLog[buyer]);
        require(!purchaseLog[buyer].tokensDistributed);

        // ETH to refund
        uint256 depositedValue = purchaseLog[buyer].ethValue;
        //VZT to revert
        uint256 vztValue = purchaseLog[buyer].vztValue;
        // assume all refunded, should we even do this if
        // we are going to delete buyer from log?
        purchaseLog[buyer].ethValue = 0;
        purchaseLog[buyer].vztValue = 0;
        refundLog[buyer] = true;
        //delete from purchase log.
        //but we won't remove buyer from buyers array
        delete purchaseLog[buyer];
        //decrement global counters
        tokensSold = tokensSold.sub(vztValue);
        totalCollected = totalCollected.sub(depositedValue);

        // send must be called only after purchaseLog[buyer] is deleted to
        //prevent reentrancy attack.
        buyer.transfer(depositedValue);
        Refunded(buyer, depositedValue);
        return true;
    }

    function getBuyersList() external view returns (address[]) {
        return buyers;
    }
}