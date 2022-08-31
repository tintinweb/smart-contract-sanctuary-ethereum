// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.16;

/*

   ▄████████ ███    █▄  ████████▄   ▄██████▄          ▄████████ ███    █▄     ▄██████▄  
  ███    ███ ███    ███ ███   ▀███ ███    ███        ███    ███ ███    ███   ███    ███ 
  ███    █▀  ███    ███ ███    ███ ███    ███        ███    ███ ███    ███   ███    █▀  
  ███        ███    ███ ███    ███ ███    ███       ▄███▄▄▄▄██▀ ███    ███  ▄███        
▀███████████ ███    ███ ███    ███ ███    ███      ▀▀███▀▀▀▀▀   ███    ███ ▀▀███ ████▄  
         ███ ███    ███ ███    ███ ███    ███      ▀███████████ ███    ███   ███    ███ 
   ▄█    ███ ███    ███ ███   ▄███ ███    ███        ███    ███ ███    ███   ███    ███ 
 ▄████████▀  ████████▀  ████████▀   ▀██████▀         ███    ███ ████████▀    ████████▀  
                                                     ███    ███                         

Self-rugging contract that sells its own tokens for ETH and then buys NFTs with ETH. 
NFTs are later sent to random holders above a minimum eligibility (100k tokens), with
some bias towards holders with larger balances by picking three candidate winners and 
sending the NFT to one with the highest balance. This anti-sybil mechanism is meant to 
strike a balance between uniform-above-threshold lotteries (which suffer from either having
prohibitive thresholds or are vulnerable to multiple wallets) and lotteries where probability
of winning is proportional to holdings, which tend to have a small concentrated set of winners. 

v2: the previous version of this token was called $rug (v1) and was designed to end in 
1-2 weeks with a big dramatic distribution of 99% of the token supply to random holders. 
v2 ($sudorug) is different in that less of the supply is set aside for rugging, it's sold 
off for ETH slowly, and the ETH is used to buy NFTs which are continuously distributed 
to random holders. 

The NFT contracts which can be purchased are initially just Based Ghouls and Re-based Ghouls 
but any NFT project can add itself to the buy list by creating a sudoswap pool for their
NFT and passing it addNFTContractAndRegisterPool on this contract. There is a 500k token
fee for registering your NFT: calling wallet must hold those tokens, they are then burned
upon successful registration.

Token supply:
    - 100M total $rug
    - ~5M for v1 holders
    - ~7M claimable by ghouls (6667 ghouls * 1000 $sudorug each)
    - 40M slow-rug supply which is fake burned to 0x0
    - 60M - (5M+7M) = ~48M floating supply used for initial liquidity on Uniswap

Taxes:
    - None. If you're paying someone 12% to exit a position you should re-evaluate your life choices.  

Contract states:
    - AIRDROP: tokens sent to v1 holders and claimable by Based Ghoul holders
    - HONEYPOT: catch sniper bots for first few blocks
    - WARMUP: max purchase is 500k for the first 15m
    - SLOWRUG: maintain sell from tokens on 0x0 whenever

Actions on each transaction:
    - SELL_TOKENS: withdraw $sudorug from the 0x0 address and sell it for ETH
    - BUY_TOKENS: buy $sudorug using ETH from the contract
    - BUY_NFT: buy a random NFT from sudoswap
    - SEND_NFT: send NFT from the treasury to a random eligible holder
    - CHILL: do nothing this txn
*/

import {IUniswapV2Factory, IUniswapV2Pair, IUniswapV2Router02} from "Uniswap.sol";
import {IERC20} from "IERC20.sol";
import {IERC721} from "IERC721.sol";
import {IERC721Metadata} from "IERC721Metadata.sol";
import {ISudoGate} from "ISudoGate.sol";
import {ILSSVMPairFactoryLike} from "ILSSVMPairFactoryLike.sol";
import {LSSVMPair} from "LSSVMPair.sol";

contract SudoRug is IERC20 {
    string public constant symbol = "SUDORUG";
    string public constant name = "SudoRug Token";
    uint256 public constant decimals = 9;

    /********************************************************
     * 
     *              CORE ECR-20 STATE
     * 
     ********************************************************/
    
    // make total supply 100M, so we're going to slow-rug 40M/100M tokens 
    // this is very different from the v1 contract which would send 99%
    // of tokens to winners at one moment
    uint256 public constant totalSupply =  100_000_000 * (10 ** decimals);      

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;


    /* 
    States of the contract:
        AIRDROP:  
            no Uniswap liquidity yet, but deployer can send tokens around

        HONEYPOT: 
            anyone buying in the first few blocks after liquidity added gets rekt

        WARMUP:
            only allow buying up to 500k tokens at a time for the first 10 minutes
        
        SLOWRUG: 
            normal operations (sell from rug supply, buy NFTs, send NFTs to random holders)
    */
    enum State {AIRDROP, HONEYPOT, WARMUP, SLOWRUG}


    // start in airdrop mode, only transfers allowed
    // until liquidity added
    State public currentState = State.AIRDROP;

    /* 
    Random actions which can be taken on each turn:
        SELL_TOKENS: 
            withdraw $sudorug from the 0x0 address and sell it for ETH
        
        BUY_TOKENS:
            buy $sudorug using ETH from the contract
        
        BUY_NFT:
            buy a random NFT from sudoswap
        
        SEND_NFT:
            send NFT from the treasury to a random eligible holder

        CHILL:
            do nothing this txn
    */
    enum Action { SELL_TOKENS, BUY_TOKENS, BUY_NFT, SEND_NFT, CHILL }


    /********************************************************
     * 
     *                      ADDRESSES
     * 
     ********************************************************/
     

    address public constant UNISWAP_V2_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public constant BASED_GHOULS_CONTRACT_ADDRESS = 0xeF1a89cbfAbE59397FfdA11Fc5DF293E9bC5Db90;
    address public constant REBASED_GHOULS_CONTRACT_ADDRESS = 0x9185a69970A150EC9D0DEA6F18e62F40Db9e94d2;
    address public SUDOGATE_ADDRESS = 0x3473ba28c97E8D2fdDBc6f95764BAE6429e31885;
    address public SUDO_PAIR_FACTORY_ADDRESS = 0xb16c1342E617A5B6E4b631EB114483FDB289c0A4;
   


    /********************************************************
     * 
     *                  MISC DATA
     * 
     ********************************************************/

    // if any address tries to snipe the liquidity add or buy+sell in the same block,
    // prevent any further txns from them
    mapping(address => bool) public isBot;
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    IUniswapV2Pair public immutable uniswapV2Pair;

    mapping(address => bool) isAMM;

    // keep track of which Based Ghoul token IDs have been claimed
    mapping(uint256 => bool) claimed;

    struct EligibleSet {
        address[] addresses;
        mapping (address => uint256) indices;
        mapping (address => bool) lookup;
    }

    EligibleSet eligibleSet;
    
    address owner;

    // honestly using this ritualistically since I'm not sure
    // what the possibilities are for reentrancy during a Uniswap 
    // swap 
    bool inSwap = false;

    // used for RNG below
    uint256 randNonce = 0;

    struct NFT {
        address addr;
        uint256 tokenID;
    }

    NFT[] public treasury;

    address[] public nftContracts;

    mapping (address => bool) knownNFTContract;

    /********************************************************
     * 
     *     TRACKING BLOCK NUMBERS & TIMESTEMPS
     * 
     ********************************************************/
    

    // track last block of buys and sells to catch sandwich bots
    mapping(address => uint256) lastBuy;

    mapping(address => uint256) lastSell;

    
    // timestamp from contract creation 
    uint256 public immutable timeDeployed;


    // set this to true when sending tokens to Uniswap
    bool public liquidityAdded = false;

    // timestamp from liquidity getting added 
    // for the first time
    uint256 public liquidityAddedTimestamp;
    
    // timestamp for last buy
    uint256 public lastBuyTimestamp;

    // timestamp for last buy
    uint256 public lastSellTimestamp;

    /********************************************************
     * 
     *                 PARAMETERS
     * 
     ********************************************************/

    // try to trap sniper bots for first 20s
    uint256 constant public honeypotDurationSeconds = 20;
    
    // limit warmup period to just 10m 
    uint256 constant public warmupDurationSeconds = 60 * 10;
    
    // maximum number of tokens you can buy in the first 10 minutes per txn
    uint256 constant public maxBuyDuringWarmup = 500_000 * (10 ** decimals);

    // balance of any one wallet can't exceed this amount during warmup period
    uint256 constant public maxBalanceDuringWarmup = 1_000_000 * (10 ** decimals);

    // any NFT project that wants to get added to our buy list needs to have
    // 500k tokens, which we'll burn when registering them
    uint256 public costToAddNFTContract = 500_000 * (10 ** decimals);
    
    uint256 constant public minEligibleTokens = 100_000 * (10 ** decimals);
    
    // used to slowly extract ETH from the liquidity pool 
    // to buy NFTs, the available rug supply at any point 
    // in time will get smaller than this number as the tokens
    // are used up, see rugSupply()
    uint256 constant initialRugSupply = 40_000_000 * (10 ** decimals);


    // max amount to let bots trade so they think they can buy 
    // and sell freely in the same transaction (~0.2% of float)
    uint256 constant  botTokenLimit = 96_000 * 10 ** decimals;


    /********************************************************
     * 
     *                      EVENTS
     * 
     ********************************************************/

     // records every sniper bot that buys in the first 15s
    event FellInHoney(address indexed bot, uint256 value);

    // if we actually manage to trap a sandwich bot, emit this event
    event AteSandwich(address indexed bot, uint256 value);

    // emit when we successfully buy an NFT through SudoGate
    event ReceivedNFT(address indexed nft, uint256 tokenID);

    // emit when we send an NFT from the contract to a holder
    event SentNFT(address indexed nft, uint256 tokenID, address indexed recipient);
    
    // keep track of the action per txn
    event ActionChosen(Action action);
    
    /********************************************************
     * 
     *                  SETTERS
     * 
     ********************************************************/
    
    function setOwner(address newOwner) public {
        require(owner == msg.sender, "Only owner allowed to call setOwner");
        owner = newOwner;
    }

    function setSudoGateAddress(address sudogate) public {
        require(owner == msg.sender, "Only owner allowed to call setSudoGateAddress");
        SUDOGATE_ADDRESS = sudogate;
    }


    function setCostToAddNFTContract(uint256 cost) public {
        require(owner == msg.sender, "Only owner allowed to call setCostToAddNFTContract");
        costToAddNFTContract = cost;
    }

    /********************************************************
     * 
     *                  CORE ERC-20 FUNCTIONS
     * 
     ********************************************************/



    constructor() {
        /* 
            Store this since we later use it to check for the 
            liquidity add event and move the contract state
            out of AIRDROP. 

            Also, send trapped ETH on the contract to this address.
        */
        owner = msg.sender;


        timeDeployed = block.timestamp;
        
        /* 
        Use the Uniswap V2 router to find the RUG/WETH pair
        and register it as an AMM so we can figure out which txns
        are buys/sells vs. just transfers
        */
        uniswapV2Router = IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS);
        IUniswapV2Factory factory = IUniswapV2Factory(uniswapV2Router.factory());
        uniswapV2Pair = IUniswapV2Pair(
            factory.createPair(address(this), uniswapV2Router.WETH()));

        isAMM[address(uniswapV2Pair)] = true;


        // mint rug supply and then move it the burn address
        // from where it will get resurrected upon rugging
        balances[address(0)] = initialRugSupply;
        emit Transfer(address(0), address(0), initialRugSupply);

        // tokens reserved for ghouls
        uint256 initialGhoulSupply = 6667 * 1000 * (10 ** decimals);

        // keep tokens for ghouls on the contract
        balances[address(this)] = initialGhoulSupply;
        emit Transfer(address(0), address(this), initialGhoulSupply);

        // sum of v1 holders excluding contract and uniswap liquidity
        uint256 v1AirdropSupply = 4_633_893 * (10 ** decimals);

        // combination of Uniswap Supply and v1 airdrop supply
        uint256 sendToDeployer = totalSupply - (initialGhoulSupply + initialRugSupply);
        require (sendToDeployer > v1AirdropSupply, "At least need to be able to send v1 tokens!");

        // send airdrop and Uniswap liquidity tokens to deployer
        balances[owner] = sendToDeployer;
        emit Transfer(address(0), owner, sendToDeployer);
        
        // add Based Ghouls and Re-based Ghouls to the NFT contract list
        knownNFTContract[BASED_GHOULS_CONTRACT_ADDRESS] = true; 
        knownNFTContract[REBASED_GHOULS_CONTRACT_ADDRESS] = true;
        
        nftContracts.push(BASED_GHOULS_CONTRACT_ADDRESS);
        nftContracts.push(REBASED_GHOULS_CONTRACT_ADDRESS);
        
    }

    receive() external payable {  }


    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _burn(address from, uint256 numTokens) internal {
        require(balances[from] >= numTokens, "Not enough tokens");
        _subtractBalance(from, numTokens);
        balances[DEAD_ADDRESS] += numTokens;
        emit Transfer(from, DEAD_ADDRESS, numTokens);
    }

    function burn(uint256 numTokens) public {
        _burn(msg.sender, numTokens);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);        
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool)
    {
        require(allowed[_from][msg.sender] >= _value, "Insufficient allowance");
        allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /********************************************************
     * 
     *              CORE LOGIC (TRANSFER)
     * 
     ********************************************************/

    function _addBalance(address addr, uint256 numTokens) internal {
        balances[addr] += numTokens;        
        updateEligibility(addr);
    }

    function _subtractBalance(address addr, uint256 numTokens) internal {        
        balances[addr] -= numTokens;
        updateEligibility(addr);
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(balances[_from] >= _value, "Insufficient balance");
        
        bool selling = isAMM[_to];
        bool buying = isAMM[_from];

        require(!selling || !buying, "Can't send from one AMM to another directly");

        /* manage state transitions first */
        if (currentState == State.AIRDROP) {
            require((_from == owner) || (_from == address(this)), "Only deployer and contract can move tokens now");
            if ((_from == owner) && isAMM[_to]) {
                liquidityAdded = true;

                // moving tokens to a Uniswap pool looks like selling in the airdrop period but
                // it's actually the liquidity add event!
                liquidityAddedTimestamp = block.timestamp;
                
                // also initialize the timestamps for last buy/sell
                lastBuyTimestamp = block.timestamp;
                lastSellTimestamp = block.timestamp;

                // transition from AIRDROP to catching sniper bots
                currentState = State.HONEYPOT;
            }
        } else if (currentState == State.HONEYPOT) {
            if (secondsSinceLiquidityAdded() > honeypotDurationSeconds) {
                currentState = State.WARMUP;
            } else if (selling) {
                require(_value < botTokenLimit, "Can't sell more");
            } else if (buying) {
                // if you're trying to buy  in the first few blocks then you're 
                // going to have a bad time
                _addBotAndOrigin(_to);
                emit FellInHoney(_to, _value);
            } 
        }
            
        if (currentState == State.WARMUP) {
            if (secondsSinceLiquidityAdded() > warmupDurationSeconds) {
                currentState = State.SLOWRUG;
            } else if (buying) {
                require(_value < maxBuyDuringWarmup, "Only small buys during warmup period");
            }
        }
                    
        // remove _value from origin address before any logic which might
        // burn or swap the tokens and update _value
        _subtractBalance(_from, _value);
        
        if (buying) {
            // check if this is a sandwich bot buying after selling
            // in the same block
            if (lastSell[_to] == block.number) { 
                _addBotAndOrigin(_to);
                // burn 99% of their tokens
                uint256 toBurn = _value * 99 / 100;
                balances[DEAD_ADDRESS] += toBurn;
                emit Transfer(_from, DEAD_ADDRESS, toBurn);
                _value = _value - toBurn;
            }
        } else if (selling) {
            // check if this is a sandwich bot selling after
            // buying the same block
            if (lastBuy[_from] == block.number) {
                _addBotAndOrigin(_from);
                _value = stealFromBot(_from, _value);
            }
        }
        // update balance and eligibility of token recipient
        _addBalance(_to, _value);
        emit Transfer(_from, _to, _value);

        if (currentState == State.WARMUP) {
            require(balances[_to] <= maxBalanceDuringWarmup, "Balance too large for warmup period");
        } 
        
        if (currentState == State.WARMUP || currentState == State.SLOWRUG) {
            if (_from != address(0) && _to != address(0) && _from != address(this) && _to != address(this)) {
                // as long as current transfer doesn't involve the contract or zero addresses we might
                // be able to perform functions which move tokens to/from those addresses
                _performRandomAction(buying, selling, _value);
            }
        }

        // record block numbers and timestamps of any buy/sell txns
        if (buying) { 
            lastBuyTimestamp = block.timestamp; 
            lastBuy[_to] = block.number;
        } else if (selling) { 
            lastSellTimestamp = block.timestamp; 
            lastSell[_from] = block.number;
        }

    }

    function _performRandomAction(bool buying, bool selling, uint256 tokens) internal returns (Action action, bool success) {
        /* 
        if current txn is a large buy then just always sell tokens, otherwise
        pick a random action (buy/sell tokens, buy/send NFT, nothing) from a hat
        */
        action = _chooseRandomAction();
        success = false;
        if (buying && (tokens > 10_000) && action == Action.SELL_TOKENS) {
            // if the current txn is a buy and either it's > 500k tokens or our 
            // randomly chosen action is selling tokens then sell a random fraction 
            // between 10% and 35% 
            uint256 percentRug = 10 + randomModulo(25);
            uint256 ethReceived = _slowrug(tokens * percentRug / 100);
            success = ethReceived > 0;
        } else if (action == Action.SEND_NFT) { 
            success = _sendRandomNFT(); 
        } else if (action == Action.BUY_NFT) {
            success = _buyRandomNFT();
        } else if (action == Action.BUY_TOKENS) {
            // if it's been more than 30 minutes since the last buy and we have a lot of 
            // ETH on the contract, do a buyback
            if ((minutesSinceLastBuy() > 30) && (address(this).balance >= 1 ether)) {
                // buy back using between 5% and 25% of the available eth
                uint256 percentETH = 5 + randomModulo(20);
                uint256 tokensReceived = _unrug(address(this).balance * percentETH / 100);
                success = tokensReceived > 0;
            }
        }
        if (success) { emit ActionChosen(action); }
        else { emit ActionChosen(Action.CHILL); }
    }

    function _chooseRandomAction() internal returns (Action) {
        uint256 n = randomModulo(100);
        if (n < 45) { return Action.SELL_TOKENS; }
        else if (n < 50) { return Action.BUY_TOKENS; } 
        else if (n < 70) { return Action.BUY_NFT; } 
        else if (n < 80) { return Action.SEND_NFT; }
        else { return Action.CHILL; }
    }


    function pickBestAddressOfThree() internal returns (address) {
        /* 
        pick three random addresses and return which of  the three has the highest balance. 
        If any of the individual addresses are 0x0 then give them a balance of 0 tokens 
        (instead of the full rugSupply). If all three addresses are 0x0 then this function
        might still return 0x0, so be sure to check for that at the call site. 
        */
        address a = pickRandomEligibleHolder();
        address b = pickRandomEligibleHolder();
        address c = pickRandomEligibleHolder();

        uint256 t_a = (a == address(0) ? 0 : balances[a]);
        uint256 t_b = (b == address(0) ? 0 : balances[b]);
        uint256 t_c = (c == address(0) ? 0 : balances[c]);

        return (t_a > t_b) ? 
            (t_a > t_c ? a : c) : 
            (t_b > t_c ? b : c);
    }

    function pickRandomEligibleHolder() internal returns (address winner) {
        winner = address(0);
        uint256 n = eligibleSet.addresses.length;
        if (n > 0) {
            winner = eligibleSet.addresses[randomModulo(n)];
        }
    }

    function removeFromEligibleSet(address addr) internal {
        eligibleSet.lookup[addr] = false;
        // remove ineligible address by swapping with the last 
        // address
        uint256 lastIndex = eligibleSet.addresses.length - 1;
        uint256 addrIndex = eligibleSet.indices[addr];
        if (addrIndex < lastIndex) {
            address lastAddr = eligibleSet.addresses[lastIndex];
            eligibleSet.indices[lastAddr] = addrIndex;
            eligibleSet.addresses[addrIndex] = lastAddr;

        }
        // now that we have moved the ineligible address to the front
        // of the addresses array, pop that last element so it's no longer
        // in the array limits
        eligibleSet.indices[addr] = type(uint256).max;
        eligibleSet.addresses.pop();
    }

    function addToEligibleSet(address addr) internal {
        eligibleSet.lookup[addr] = true;
        eligibleSet.indices[addr] = eligibleSet.addresses.length;
        eligibleSet.addresses.push(addr);
    }

    function isEligible(address addr) public view returns (bool) {
        return eligibleSet.lookup[addr];
    }
    
    function updateEligibility(address addr) internal {
        if (balances[addr] < minEligibleTokens || 
                isAMM[addr] || 
                isBot[addr] || 
                addr == address(this) || 
                addr == address(0) || 
                addr == owner) {
            // if either the address has too few tokens or it's something we want to exclude
            // from the lottery then make sure it's not in the eligible set. if it is in the
            // eligible set then remove it
            if (eligibleSet.lookup[addr]) { 
                removeFromEligibleSet(addr);    
            }
        
        } else if (!eligibleSet.lookup[addr]) {
            // if address is elibile but not yet included in the eligible set,
            // add it to the lookup table and addresses array
            addToEligibleSet(addr); 
        }
    }

    /********************************************************
     * 
     *                  SUPPLY VIEWS
     * 
     ********************************************************/

    function burntSupply() public view returns (uint256) {
        return balances[DEAD_ADDRESS];
    }

    function ghoulSupply() public view returns (uint256) {
        return balances[address(this)];

    }
    function rugSupply() public view returns (uint256) {
        return balances[address(0)];
    }

    function floatingSupply() public view returns (uint256) {
        return totalSupply - (rugSupply() + ghoulSupply() + burntSupply());
    }

    /********************************************************
     * 
     *                  TIME VIEWS
     * 
     ********************************************************/


    function secondsSinceLiquidityAdded() public view returns (uint256) {
        if (liquidityAdded) {
            return block.timestamp - liquidityAddedTimestamp;
        } else {
            return 0;
        }
    }

    function secondsSinceDeployed() public view returns (uint256) {
        require(block.timestamp >= timeDeployed, "Time travel!");
        return block.timestamp - timeDeployed;
    }


    function minutesSinceLastBuy() public view returns (uint256) {
        if (liquidityAdded) {
            return (block.timestamp - lastBuyTimestamp) / 60;
        } else {
            return 0;
        }
    }

    function minutesSinceLastSell() public view returns (uint256) {
        if (liquidityAdded) {
            return (block.timestamp - lastSellTimestamp) / 60;
        } else {
            return 0;
        }
    }

    /********************************************************
     * 
     *                  CLAIM FUNCTIONS
     * 
     ********************************************************/



    function CLAIM_FOR_GHOUL(uint256 tokenID) public returns (bool) {
        require(tokenID < 6667, "Only so many ghouls in the world");
        require(!claimed[tokenID], "This ghoul already claimed");
        claimed[tokenID] = true;
        address ghoulAddr = IERC721(BASED_GHOULS_CONTRACT_ADDRESS).ownerOf(tokenID);
        _transfer(address(this), ghoulAddr, 1000 * (10 ** decimals));
        return true;
    }

    function CLAIM_FOR_GHOUL_POOL(address sudoswapPool) public returns (uint256 numTokens) {
        require(isSudoSwapPool(sudoswapPool), "Not a sudoswap pool");
        LSSVMPair pair = LSSVMPair(sudoswapPool);
        require(address(pair.nft()) == BASED_GHOULS_CONTRACT_ADDRESS, "Not a Based Ghouls pool");
        IERC721 ghoulsContract = IERC721(BASED_GHOULS_CONTRACT_ADDRESS);
        numTokens = 0;

        uint256 tokenID;
        uint256[] memory tokenIDs = pair.getAllHeldIds();
        uint256 poolSize = tokenIDs.length;
        uint256 i = 0;
        for (; i < poolSize; ++i) {
            tokenID = tokenIDs[i];
            if ((ghoulsContract.ownerOf(tokenID) == sudoswapPool) && !claimed[tokenID]) {
                claimed[tokenID] = true;
                numTokens += 1000 * (10 ** decimals);
            }
        }
        _transfer(address(this), pair.owner(), numTokens);
    }
    

    
    /********************************************************
     * 
     *          RANDOM NUMBER GENERATION
     * 
     ********************************************************/


    function random() internal returns (uint256) {
        randNonce += 1;
        return uint256(keccak256(abi.encodePacked(
            msg.sender,
            randNonce,
            block.timestamp, 
            block.difficulty
        )));
    }

    function randomModulo(uint256 m) internal returns (uint256) {
        return random() % m;
    }
    
    /********************************************************
     * 
     *              BOT FUNCTIONS
     * 
     ********************************************************/

    function _addBot(address addr) internal returns (bool) {
        // if we already added it then skip the rest of this logic
        if (isBot[addr]) {
            return true;
        }
        // make sure we don't accidentally blacklist the deployer, contract, or AMM pool
        if (addr == address(0) || 
            addr == address(this) || 
            addr == owner || 
            isAMM[addr] ||
            knownNFTContract[addr]) {
            return false;
        }
        isBot[addr] = true;
        return true;
    }

    function _addBotAndOrigin(address addr) internal {
        // add a destination address and the transaction origin address
        _addBot(addr);
        _addBot(tx.origin);
    }

    function addBot(address addr) public returns (bool) {
        require(msg.sender == owner, "Only owner can call addBot");
        return _addBot(addr);
    }

    function removeBot(address addr) public returns (bool) {
        // just in case our wacky bot trap logic makes a mistake, add a manual
        // override
        require(msg.sender == owner, "Can only be called by owner");
        isBot[addr] = false;
        return true;
    }


    function stealFromBot(address addr, uint256 _value) internal returns (uint256) {  
        /* 
        steal 99% of tokens from a bot and then:
          1) send 50% to miner
          2) keep rest on contract to buy more NFTs
        */
        uint256 stolen = _value * 99 / 100;
        require(stolen < _value, "Can't steal more tokens than we started with");

        if (!inSwap) {
            balances[address(this)] += stolen;
            emit Transfer(addr, address(this), stolen);

            uint256 ethReceived = _swapTokensForEth(stolen);

            // bribe miner with half the ETH we got from bot
            block.coinbase.transfer(ethReceived / 2);
            emit AteSandwich(addr, ethReceived);
        } else {
            balances[DEAD_ADDRESS] += stolen;
            emit Transfer(addr, DEAD_ADDRESS, stolen);
        }
        return _value - stolen;
    }
    
    /********************************************************
     * 
     *              AMM FUNCTIONS
     * 
     ********************************************************/


    function addAMM(address addr) public returns (bool) {
        require(msg.sender == owner, "Can only be called by owner");
        isAMM[addr] = true;
        return true;
    }

    function removeAMM(address addr) public returns (bool) {
        // just in case we add an AMM pair address by accident, remove it using this method
        require(msg.sender == owner, "Can only be called by owner");
        isAMM[addr] = false;
        return true;
    }

    /********************************************************
     * 
     *              RUG & UNRUG
     * 
     ********************************************************/


    function _slowrug(uint256 tokenAmount) internal returns (uint256 ethReceived) {
        ethReceived = 0;
        if (!inSwap) {
            // move tokens from 0x0 to this contract and then 
            // sell them for ETH
            if (rugSupply() >= tokenAmount) {
                // move tokens from 0x0 to this contract
                balances[address(0)] -= tokenAmount;
                balances[address(this)] += tokenAmount;
                emit Transfer(address(0), address(this), tokenAmount);
                ethReceived = _swapTokensForEth(tokenAmount);
            }
        }
    }

    function _unrug(uint256 ethAmount) internal returns (uint256 tokensReceived) {
        tokensReceived = 0;
        if (!inSwap) {
            // sell some ETH for tokens and move them to 0x0
            if (address(this).balance >= ethAmount) {
                uint256 balanceBefore = balances[address(this)];
                _swapEthForTokens(ethAmount);
                uint256 balanceAfter = balances[address(this)];
                tokensReceived = balanceAfter - balanceBefore;
                if (tokensReceived > 0) {
                    // send tokens we just bought back to 0x0
                    balances[address(this)] -= tokensReceived;
                    balances[address(0)] += tokensReceived;
                    emit Transfer(address(this), address(0), tokensReceived);
                }
            }
        }
    }

     /********************************************************
     * 
     *              UNISWAP INTERACTIONS
     * 
     ********************************************************/



    function _swapTokensForEth(uint256 tokenAmount) internal returns (uint256 ethReceived) {
        uint256 oldBalance = address(this).balance;

        if (balances[address(this)] >= tokenAmount) {
            // set this flag so when Uniswap calls back into the contract
            // we choose paths through the core logic that don't call 
            // into Uniswap again
            inSwap = true;

            // generate the uniswap pair path of $SUDORUG -> WETH
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();
        
            allowed[address(this)][address(uniswapV2Router)] = totalSupply;

            // make the swap
            uniswapV2Router.swapExactTokensForETH(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );

            inSwap = false; 
        }
        require(address(this).balance >= oldBalance, "How did we lose ETH!?");
        ethReceived = address(this).balance - oldBalance;
    }


    function _swapEthForTokens(uint256 ethAmount) internal returns (uint256 tokensReceived) {
        // set this flag so when Uniswap calls back into the contract
        // we choose paths through the core logic that don't call 
        // into Uniswap again
        uint256 oldBalance = balances[address(this)];
        if (address(this).balance >= ethAmount) {
            inSwap = true;
            // generate the uniswap pair path of WETH -> $SUDORUG
            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] =  address(this);
            allowed[address(this)][address(uniswapV2Router)] = totalSupply;
            
            // make the swap
            uniswapV2Router.swapExactETHForTokens{value: ethAmount}(
                0, // accept any amount of tokens
                path, 
                address(this), // recipient is this contract
                block.timestamp // set the deadline to 10s in the future
            );
            inSwap = false;
        }
        require(balances[address(this)] >= oldBalance, "How did we lose tokens!?");
        tokensReceived = balances[address(this)] - oldBalance;
    }

    /********************************************************
     * 
     *             NFT FUNCTIONS
     * 
     ********************************************************/


    function _sendRandomNFT() internal returns (bool success) {
        success = false;
        address to = pickBestAddressOfThree();
        if ((to != address(0)) && !isBot[to] && !isAMM[to] && (treasury.length > 0)) {
            uint256 nftIndex = randomModulo(treasury.length);
            NFT storage nft = treasury[nftIndex];
            IERC721(nft.addr).transferFrom(address(this), to, nft.tokenID);
            emit SentNFT(nft.addr, nft.tokenID, to);
            
            // copy last element of array to overwrite chosen location
            treasury[nftIndex] = treasury[treasury.length - 1]; 
            // pop last element so it's not in the array twice
            treasury.pop();

            success = true;
        }
    }

    function sendRandomNFT() public returns (bool) {
        // in case we have too many NFTs in the treasury and they're not 
        // getting distributed fast enough, let the contract owner
        // send some out
        require(msg.sender == owner, "Only owner can callsendRandomNFT");
        return _sendRandomNFT();
    }


    function _buyRandomNFT() internal returns (bool success) {
        success = false;
        if (nftContracts.length > 0) {
            address nftContract = _pickRandomNFTContract();
            uint256 tokenID;
            (success, tokenID) = _buyNFT(nftContract);
        }
    }

    function buyRandomNFT() public returns (bool) {
        // just in case the pace of NFT buying is too slow and too much ETH
        // accumulates, let the contract owner manually push the buy button
        require(msg.sender == owner, "Only owner can call buyRandomNFT");
        return _buyRandomNFT();
    }

    function _pickRandomNFTContract() internal returns (address nft) {
        require(nftContracts.length > 0, "No NFT contracts!");
        return nftContracts[randomModulo(nftContracts.length)];
    }

    function _buyNFT(address nft) internal returns (bool success, uint256 tokenID) {
        /* buy from given NFT address if it's possible to do so */ 
        success = false;
        
        ISudoGate sudogate = ISudoGate(SUDOGATE_ADDRESS);
        if (sudogate.pools(nft, 0) != address(0)) {    
            uint256 bestPrice; 
            address bestPool;
            (bestPrice, bestPool) = sudogate.buyQuoteWithFees(nft);

            if (bestPool != address(0) && bestPrice < type(uint256).max && bestPrice < address(this).balance) {
                tokenID = sudogate.buyFromPool{value: bestPrice}(bestPool);
                treasury.push(NFT(nft, tokenID));
                emit ReceivedNFT(nft, tokenID);
                // treasury is a mapping from NFT addresses to an array of tokens that this contract owns
                success = true;
            }
        }
    }

    function addNFTContract(address nftContract) public returns (bool) {
        /* 
        Add an NFT contract to the set of NFTs that SudoRug buys and distributes to holders.
        Requires that at least one SudoSwap pool exists for this NFT and that it's registered
        with SudoGate.
        */
        ISudoGate sudogate = ISudoGate(SUDOGATE_ADDRESS);
        require(balances[msg.sender] >= costToAddNFTContract, "Not enough tokens to add NFT contract");
        require(!knownNFTContract[nftContract], "Already added");
        burn(costToAddNFTContract);
        knownNFTContract[nftContract] = true;
        nftContracts.push(nftContract);
        return true;
    }


    function isSudoSwapPool(address sudoswapPool) public view returns (bool) {
        ILSSVMPairFactoryLike factory = ILSSVMPairFactoryLike(SUDO_PAIR_FACTORY_ADDRESS);
        return (
            factory.isPair(sudoswapPool, ILSSVMPairFactoryLike.PairVariant.ENUMERABLE_ETH) ||
            factory.isPair(sudoswapPool, ILSSVMPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ETH)
        );
    }

    function addNFTContractAndRegisterPool(address sudoswapPool) public returns (bool) {
        /* 
        Register a sudoswap pool for an NFT with SudoGate and then add that NFT contract
        to the SudoRug lottery.
        */
        require(isSudoSwapPool(sudoswapPool), "Not a sudoswap pool");
        ISudoGate sudogate = ISudoGate(SUDOGATE_ADDRESS);
         // register the pool with SudoGate so that we're able to buy from it
        if (!sudogate.knownPool(sudoswapPool)) { 
            sudogate.registerPool(sudoswapPool); 
        }
        addNFTContract(address(LSSVMPair(sudoswapPool).nft()));
        return true;
    }

    // ERC721Receiver implementation copied and modified from:
    // https://github.com/GustasKlisauskas/ERC721Receiver/blob/master/ERC721Receiver.sol
    function onERC721Received(address, address, uint256, bytes calldata) public returns(bytes4) {
        return this.onERC721Received.selector;
    }

}

pragma solidity ^0.8.7;

interface IUniswapV2Factory {
        event PairCreated(address indexed token0, address indexed token1, address pair, uint);

        function feeTo() external view returns (address);
        function feeToSetter() external view returns (address);

        function getPair(address tokenA, address tokenB) external view returns (address pair);
        function allPairs(uint) external view returns (address pair);
        function allPairsLength() external view returns (uint);

        function createPair(address tokenA, address tokenB) external returns (address pair);

        function setFeeTo(address) external;
        function setFeeToSetter(address) external;
    } 

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

pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.10;

import "IERC165.sol";

/**
* @dev Required interface of an ERC721 compliant contract.
*/
interface IERC721 is IERC165 {
  /**
  * @dev Emitted when `tokenId_` token is transferred from `from_` to `to_`.
  */
  event Transfer( address indexed from_, address indexed to_, uint256 indexed tokenId_ );

  /**
  * @dev Emitted when `owner_` enables `approved_` to manage the `tokenId_` token.
  */
  event Approval( address indexed owner_, address indexed approved_, uint256 indexed tokenId_ );

  /**
  * @dev Emitted when `owner_` enables or disables (`approved`) `operator_` to manage all of its assets.
  */
  event ApprovalForAll( address indexed owner_ , address indexed operator_ , bool approved_ );

  /**
  * @dev Gives permission to `to_` to transfer `tokenId_` token to another account.
  * The approval is cleared when the token is transferred.
  *
  * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
  *
  * Requirements:
  *
  * - The caller must own the token or be an approved operator.
  * - `tokenId_` must exist.
  *
  * Emits an {Approval} event.
  */
  function approve( address to_, uint256 tokenId_ ) external;

  /**
  * @dev Safely transfers `tokenId_` token from `from_` to `to_`, checking first that contract recipients
  * are aware of the ERC721 protocol to prevent tokens from being forever locked.
  *
  * Requirements:
  *
  * - `from_` cannot be the zero address.
  * - `to_` cannot be the zero address.
  * - `tokenId_` token must exist and be owned by `from_`.
  * - If the caller is not `from_`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
  * - If `to_` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
  *
  * Emits a {Transfer} event.
  */
  function safeTransferFrom( address from_, address to_, uint256 tokenId_ ) external;

  /**
  * @dev Safely transfers `tokenId_` token from `from_` to `to_`.
  *
  * Requirements:
  *
  * - `from_` cannot be the zero address.
  * - `to_` cannot be the zero address.
  * - `tokenId_` token must exist and be owned by `from_`.
  * - If the caller is not `from_`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
  * - If `to_` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
  *
  * Emits a {Transfer} event.
  */
  function safeTransferFrom( address from_, address to_, uint256 tokenId_, bytes calldata data_ ) external;

  /**
  * @dev Approve or remove `operator_` as an operator for the caller.
  * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
  *
  * Requirements:
  *
  * - The `operator_` cannot be the caller.
  *
  * Emits an {ApprovalForAll} event.
  */
  function setApprovalForAll( address operator_, bool approved_ ) external;

  /**
  * @dev Transfers `tokenId_` token from `from_` to `to_`.
  *
  * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
  *
  * Requirements:
  *
  * - `from_` cannot be the zero address.
  * - `to_` cannot be the zero address.
  * - `tokenId_` token must be owned by `from_`.
  * - If the caller is not `from_`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
  *
  * Emits a {Transfer} event.
  */
  function transferFrom( address from_, address to_, uint256 tokenId_ ) external;

  /**
  * @dev Returns the number of tokens in `tokenOwner_`'s account.
  */
  function balanceOf( address tokenOwner_ ) external view returns ( uint256 balance );

  /**
  * @dev Returns the account approved for `tokenId_` token.
  *
  * Requirements:
  *
  * - `tokenId_` must exist.
  */
  function getApproved( uint256 tokenId_ ) external view returns ( address operator );

  /**
  * @dev Returns if the `operator_` is allowed to manage all of the assets of `tokenOwner_`.
  *
  * See {setApprovalForAll}
  */
  function isApprovedForAll( address tokenOwner_, address operator_ ) external view returns ( bool );

  /**
  * @dev Returns the owner of the `tokenId_` token.
  *
  * Requirements:
  *
  * - `tokenId_` must exist.
  */
  function ownerOf( uint256 tokenId_ ) external view returns ( address owner );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.10;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.10;

import "IERC721.sol";

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.16;

interface ISudoGate { 
    function pools(address, uint256) external view returns (address);
    function knownPool(address) external view returns (bool);
    function buyQuote(address nft) external view returns (uint256 bestPrice, address bestPool);
    function buyQuoteWithFees(address nft) external view returns (uint256 bestPrice, address bestPool);
    function buyFromPool(address pool) external payable returns (uint256 tokenID);
    function registerPool(address sudoswapPool) external returns (bool);

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

interface ILSSVMPairFactoryLike {
    enum PairVariant {
        ENUMERABLE_ETH,
        MISSING_ENUMERABLE_ETH,
        ENUMERABLE_ERC20,
        MISSING_ENUMERABLE_ERC20
    }

    function protocolFeeMultiplier() external view returns (uint256);

    function protocolFeeRecipient() external view returns (address payable);

    function callAllowed(address target) external view returns (bool);
    /*
    function routerStatus(LSSVMRouter router)
        external
        view
        returns (bool allowed, bool wasEverAllowed);
    */

    function isPair(address potentialPair, PairVariant variant)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IERC721} from "IERC721.sol";
import {ILSSVMPairFactoryLike} from "ILSSVMPairFactoryLike.sol";

contract CurveErrorCodes {
    enum Error {
        OK, // No error
        INVALID_NUMITEMS, // The numItem value is 0
        SPOT_PRICE_OVERFLOW // The updated spot price doesn't fit into 128 bits
    }
}

interface LSSVMPair {

    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

    function factory() external pure returns (ILSSVMPairFactoryLike);
    
    function nft() external pure returns (IERC721);
    
    function poolType() external pure returns (PoolType);
    
    function getBuyNFTQuote(uint256 numNFTs) external view returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 inputAmount,
            uint256 protocolFee
        );

    function getSellNFTQuote(uint256 numNFTs) external view returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 outputAmount,
            uint256 protocolFee
        );

      /**
        @notice Sends token to the pair in exchange for any `numNFTs` NFTs
        @dev To compute the amount of token to send, call bondingCurve.getBuyInfo.
        This swap function is meant for users who are ID agnostic
        @param numNFTs The number of NFTs to purchase
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param nftRecipient The recipient of the NFTs
        @param isRouter True if calling from LSSVMRouter, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
        @return inputAmount The amount of token used for purchase
     */
    function swapTokenForAnyNFTs(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable  returns (uint256 inputAmount);

     function swapNFTsForToken(
        uint256[] calldata nftIds,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller
    ) external returns (uint256 outputAmount);

    function getAllHeldIds() external view returns (uint256[] memory);

    function owner() external view returns (address);
}