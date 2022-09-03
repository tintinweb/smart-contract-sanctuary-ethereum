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

Self-rugging contract that sells its own tokens for ETH, buys NFTs with ETH, and sends
NFTs to holders above a minimum eligibility (100k tokens).

The rugging mechanism can be manually triggered by anyone who wants to call the public 
function called PUSH_THE_RUG_BUTTON. To avoid dumping the token supply too quickly 
there are a few limits on calls to PUSH_THE_RUG_BUTTON:

1) You can only call it once every 10 minutes.
2) The max rug supply per call is a random fraction of recently purchased tokens.
3) There has to be at least one buy between two subsequent rug calls.

There's some bias towards holders with larger balances by picking three candidate winners and 
sending the NFT to one with the highest balance. This anti-sybil mechanism is meant to 
strike a balance between uniform-above-threshold lotteries (which suffer from either having
prohibitive thresholds or are vulnerable to multiple wallets) and lotteries where probability
of winning is proportional to holdings, which tend to have a small concentrated set of winners.

The NFT contracts which can be purchased are initially just Based Ghouls and Re-based Ghouls 
but any NFT project can add itself to the buy list by creating a sudoswap pool for their
NFT and passing it addNFTContractAndRegisterPool on this contract. There is a 750k token
fee for registering your NFT: calling wallet must hold those tokens, they are then burned
upon successful registration.

Token supply:
    - 100M total $rug
    - ~5M for v1 holders
    - ~7M claimable by ghouls (6667 ghouls * 1000 $sudorug each)
    - 40M slow-rug supply
    - 60M - (5M+7M) = ~48M floating supply used for initial liquidity on Uniswap

Taxes:
    - None. If you're paying someone 12% to exit a position you should re-evaluate your life choices.  

Contract states:
    - AIRDROP: tokens sent to v1 holders and claimable by Based Ghoul holders
    - HONEYPOT: catch sniper bots for first few blocks
    - WARMUP: max purchase is 500k for the first 20 blocks
    - SLOWRUG: normal operations

Actions on each transaction:
    - BUY_NFT: buy a random NFT from sudoswap
    - SEND_NFT: send NFT from the treasury to a random eligible holder
    - CHILL: do nothing this txn

v2: the previous version of this token was called $rug (v1) and was designed to end in 
1-2 weeks with a big dramatic distribution of 99% of the token supply to random holders. 
v2 ($sudorug) is different in that less of the supply is set aside for rugging, it's sold 
off for ETH slowly, and the ETH is used to buy NFTs which are continuously distributed 
to random holders. 
*/

import {IUniswapV2Factory, IUniswapV2Pair, IUniswapV2Router02} from "Uniswap.sol";
import {IERC20} from "IERC20.sol";
import {IERC721} from "IERC721.sol";
import {IERC721Metadata} from "IERC721Metadata.sol";
import {ISudoGate} from "ISudoGate.sol";
import {ILSSVMPairFactoryLike} from "ILSSVMPairFactoryLike.sol";
import {LSSVMPair} from "LSSVMPair.sol";

contract SudoRug is IERC20 {
    /********************************************************
     * 
     *              CORE ECR-20 FIELDS
     * 
     ********************************************************/
    
    string public constant symbol = "SUDORUG";
    string public constant name = "SudoRug Token";
    uint256 public constant decimals = 9;

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
            normal operations: buy NFTs, send NFTs to random holders, 
            anyone can call PUSH_THE_RUG_BUTTON
    */
    enum State {AIRDROP, HONEYPOT, WARMUP, SLOWRUG}


    /* 
    Random actions which can be taken on each turn:
        BUY_NFT:
            buy a random NFT from sudoswap
        
        SEND_NFT:
            send NFT from the treasury to a random eligible holder

        CHILL:
            do nothing this txn

    Selling tokens for ETH is not included in this list because it does
    done manually via a public function called PUSH_THE_RUG_BUTTON.
    */
    enum Action { BUY_NFT, SEND_NFT, CHILL }


    /********************************************************
     * 
     *                      ADDRESSES
     * 
     ********************************************************/
     

    address constant UNISWAP_V2_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant BASED_GHOULS_CONTRACT_ADDRESS = 0xeF1a89cbfAbE59397FfdA11Fc5DF293E9bC5Db90;
    address constant REBASED_GHOULS_CONTRACT_ADDRESS = 0x9185a69970A150EC9D0DEA6F18e62F40Db9e94d2;
    address constant SUDO_PAIR_FACTORY_ADDRESS = 0xb16c1342E617A5B6E4b631EB114483FDB289c0A4;
    address public SUDOGATE_ADDRESS = 0x3473ba28c97E8D2fdDBc6f95764BAE6429e31885;
    


    /********************************************************
     * 
     *                  MISC DATA
     * 
     ********************************************************/

    // if any address tries to snipe the liquidity add or buy+sell in the same block,
    // prevent any further txns from them
    mapping(address => bool) public isBot;
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    IUniswapV2Pair public immutable uniswapV2Pair_WETH;

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

    // how many tokens have been bought since the last sell
    uint256 public recentlyBoughtTokens = 0;
    
    // how many minutes until we set recently bought tokens back to 0
    uint256 public recentlyBoughtTokensResetMinutes = 30;

    // timestamp from liquidity getting added 
    // for the first time
    uint256 public liquidityAddedBlock = 0;
    
    // timestamp for last buy
    uint256 public lastBuyTimestamp = 0;

    /********************************************************
     * 
     *                 PARAMETERS
     * 
     ********************************************************/

    // try to trap sniper bots for first 2 blocks
    uint256 constant public honeypotDurationBlocks = 2;
    
    // limit size of buys for next 20 blocks
    uint256 constant public warmupDurationBlocks = 20;
    
    // maximum number of tokens you can buy per txn in the first blocks of open trading
    uint256 constant public maxBuyDuringWarmup = 500_000 * (10 ** decimals);

    // balance of any one wallet can't exceed this amount during warmup period
    uint256 constant public maxBalanceDuringWarmup = 1_000_000 * (10 ** decimals);

    // any NFT project that wants to get added to our buy list needs to have
    // 750k tokens, which we'll burn when registering them
    uint256 public costToAddNFTContract = 750_000 * (10 ** decimals);
    
    // minimum number of tokens you need to be eligible to receive NFTs
    uint256 constant public minEligibleTokens = 100_000 * (10 ** decimals);
    
    // used to slowly extract ETH from the liquidity pool 
    // to buy NFTs, the available rug supply at any point 
    // in time will get smaller than this number as the tokens
    // are used up, see rugSupply()
    uint256 constant initialRugSupply  = 40_000_000 * (10 ** decimals);

    // how many tokens do you get for each ghoul
    uint256 constant tokensPerGhoul = 1000 * (10 ** decimals);

    // tokens reserved for ghouls
    uint256 public ghoulSupply = 6667 * tokensPerGhoul;

    // don't bother rugging if you're not going to sell at least
    // this many tokens
    uint256 public minTokensForRug = 1000 * (10 ** decimals);
    
    // keep track when we last pushed the rug button
    uint256 public lastRugTimestamp = 0;

    // how long to wait between rugging
    uint256 public minMinutesBetweenRugs = 10;
    
    // percent of time to try buying an NFT per txn
    uint256 public actionPercentBuy = 60;

    // percent of time to try sending an NFT per txn
    uint256 public actionPercentSend = 20;

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

    function setMinTokensForRug(uint256 numTokens) public {
        require(owner == msg.sender, "Only owner allowed to call setMinTokensForRug");
        minTokensForRug = numTokens;
    }

    function setMinMinutesBetweenRugs(uint256 m) public {
        require(owner == msg.sender, "Only owner allowed to call setMinMinutesBetweenRugs");
        minMinutesBetweenRugs = m;
    }


    function setActionPercentBuy(uint256 percent) public {
        require(owner == msg.sender, "Only owner allowed to call setActionPercentBuy");
        require(percent <= 100, "Percent cannot exceed 100");
        require(actionPercentSend  + percent <= 100, "Combined percentages cannot exceed 100");
        actionPercentBuy = percent;
    }


    function setActionPercentSend(uint256 percent) public {
        require(owner == msg.sender, "Only owner allowed to call setActionPercentSend");
        require(percent <= 100, "Percent cannot exceed 100");
        require(actionPercentBuy  + percent <= 100, "Combined percentages cannot exceed 100");
        actionPercentSend = percent;
    }


    /********************************************************
     * 
     *                      EVENTS
     * 
     ********************************************************/

     // records every sniper bot that buys in the first 15s
    event FellInHoney(address indexed bot, uint256 value);

    // emit when we successfully buy an NFT through SudoGate
    event ReceivedNFT(address indexed nft, uint256 tokenID);

    // emit when we send an NFT from the contract to a holder
    event SentNFT(address indexed nft, uint256 tokenID, address indexed recipient);
    

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

        /* 
        Use the Uniswap V2 router to find the RUG/WETH pair
        and register it as an AMM so we can figure out which txns
        are buys/sells vs. just transfers
        */
        uniswapV2Router = IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS);
        IUniswapV2Factory factory = IUniswapV2Factory(uniswapV2Router.factory());
        uniswapV2Pair_WETH = IUniswapV2Pair(factory.createPair(address(this), uniswapV2Router.WETH()));

        isAMM[address(uniswapV2Pair_WETH)] = true;
        isAMM[address(uniswapV2Router)] = true;

        // keep tokens for ghouls and rugging on the contract
        uint256 sendToContract = ghoulSupply + initialRugSupply;
        balances[address(this)] = sendToContract;
        emit Transfer(address(0), address(this), sendToContract);

        // sum of v1 holders excluding contract and uniswap liquidity
        uint256 v1AirdropSupply = 4_633_893 * (10 ** decimals);

        // combination of Uniswap Supply and v1 airdrop supply
        uint256 sendToDeployer = totalSupply - sendToContract;
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

    function balanceOf(address addr) public view returns (uint256) {
        return balances[addr];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        // pre-approve Uniswap
        if (_spender == address(uniswapV2Router)) { return balances[_owner]; } 
        else { return allowed[_owner][_spender]; }
    }

    function _approve(address _owner, address _spender, uint256 _value) internal {
        allowed[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function _burn(address _from, uint256 _numTokens) internal {
        require(balances[_from] >= _numTokens, "Not enough tokens");
        _simple_transfer_with_burn(
            _from, 
            address(0),
            _numTokens,
            0, 
            _numTokens);
    }

    function burn(uint256 numTokens) public {
        _burn(msg.sender, numTokens);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);        
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        if (_from != msg.sender && msg.sender != address(uniswapV2Router)) {
            require(allowed[_from][msg.sender] >= _value, "Insufficient allowance");
            allowed[_from][msg.sender] -= _value;
        }
        _transfer(_from, _to, _value);
        return true;
    }


    /********************************************************
     * 
     *              ADD LIQUIDITY
     * 
     ********************************************************/


    function addLiquidity(uint256 numTokens) public payable {
        require(msg.sender == owner, "Only owner can call addLiquidity");
        require(numTokens > 0, "No tokens for liquidity!");
        require(msg.value > 0, "No ETH for liquidity!");

        _transfer(msg.sender, address(this), numTokens);
        _approve(address(this), address(uniswapV2Router), numTokens);

        uniswapV2Router.addLiquidityETH{value: msg.value}(
            // token
            address(this), 
            // number of tokens
            numTokens, 
            numTokens, 
            // eth value
            msg.value, 
            // LP token recipient
            msg.sender, 
            block.timestamp + 15);

        require(
            IERC20(uniswapV2Router.WETH()).balanceOf(
                address(uniswapV2Pair_WETH)) >= msg.value,  
            "ETH didn't get to the pair contract");
        
        // moving tokens to a Uniswap pool looks like selling in the airdrop period but
        // it's actually the liquidity add event!
        liquidityAddedBlock = block.number;
    }
    
    /********************************************************
     * 
     *       CORE LOGIC (BALANCE & STATE MANAGEMENT)
     * 
     ********************************************************/

    function liquidityAdded() public view returns (bool) {
        return (liquidityAddedBlock > 0);
    }

    function currentState() public view returns (State) {
        if (!liquidityAdded()) {
            return State.AIRDROP;
        } 
        uint256 blocksSinceLiquidity = block.number - liquidityAddedBlock;
        if (blocksSinceLiquidity < honeypotDurationBlocks) {
            return State.HONEYPOT;
        } else if (blocksSinceLiquidity < warmupDurationBlocks) {
            return State.WARMUP;
        } else {
            return State.SLOWRUG;
        }
    }


    function isTradingOpen() public view returns (bool) {
        // can we actually trade now?
        State state = currentState();
        return (state == State.SLOWRUG || state == State.WARMUP);
    }


    function _updateRecentlyBoughtTokens(bool buying, bool selling, uint256 _value) internal {
        if (buying) {
            recentlyBoughtTokens += _value;
        } else if (selling) {
            if (minutesSinceLastBuy() > recentlyBoughtTokensResetMinutes) { 
                recentlyBoughtTokens = 0; 
            } else if (recentlyBoughtTokens <= _value) { 
                recentlyBoughtTokens = 0; 
            } else {
                recentlyBoughtTokens -= _value;
            }
        }
    }

    function _insanity(address _from, address _to, uint256 _value) internal {
        // transfer logic outside of contrat interactions with Uniswap
        bool selling = isAMM[_to];
        bool buying = isAMM[_from];

        State state = currentState();

        /* manage state transitions first */
        if (state == State.AIRDROP) {
            require((_from == owner) || (_from == address(this)), "Only deployer and contract can move tokens now");
        } 

        if ((state == State.HONEYPOT) && buying) {
            // if you're trying to buy  in the first few blocks then you're 
            // going to have a bad time
            bool addedBotInHoneypot = _addBotAndOrigin(_to);
            if (addedBotInHoneypot) { emit FellInHoney(_to, _value); }
        } 
                 
        // store the initial value on _from without changing
        // balances, touching any element of balances which Uniswap
        // may be currently using will cause the most maddening 
        // cryptic errors
        uint256 initialValue = _value;
                
        // vague attempt at thwarting sandwich bots
        uint256 toBurn = 0;

        if (isTradingOpen()) {
            // check if this is a sandwich bot buying after selling
            // in the same block
            if (buying && (lastSell[_to] == block.number)) { 
                bool caughtSandiwchBotBuying = _addBotAndOrigin(_to);
                if (caughtSandiwchBotBuying) {
                    // burn 99% of their tokens
                    toBurn = _value * 99 / 100;
                }
            } else if (selling && (lastBuy[_from] == block.number)) {
                // check if this is a sandwich bot selling after
                // buying the same block    
                bool caughtSandwichBotSelling = _addBotAndOrigin(_from);
                if (caughtSandwichBotSelling) {
                    // burn 99% of their tokens
                    toBurn = _value * 99 / 100;
                }
            }
        }

        // update balance and eligibility of token sender and recipient, burn 
        // any tokens if we hit bot logic
        require(initialValue > toBurn, "Can't burn more than the total number of tokens");

        _simple_transfer_with_burn(
            _from,
            _to,
            initialValue,
            initialValue - toBurn,
            toBurn);

        if (toBurn == 0) {
            // if we didn't burn a bot's tokens then update the recently bought tokens counter
            _updateRecentlyBoughtTokens(buying, selling, _value);
        }
    
        if (state == State.WARMUP && buying && !isBot[_to]) {
            require(_value <= maxBuyDuringWarmup, "Only small buys during warmup period");
            require(balances[_to] <= maxBalanceDuringWarmup, "Balance too large for warmup period");
        } 
        
        // try to buy or send an NFT
        if (isTradingOpen()) { _performRandomAction(); }

        // record block numbers and timestamps of any buy/sell txns
        if (buying) { 
            lastBuyTimestamp = block.timestamp; 
            lastBuy[_to] = block.number;
        } else if (selling) { 
            lastSell[_from] = block.number;
        }



    }

    function _simple_transfer_with_burn(
            address _from, 
            address _to,
            uint256 _fromValue,
            uint256 _toValue,
            uint256 _burnValue) internal {
        /* 
        Update balances for a transfer, allows for possibility of
        burning some of the tokens instead of sending them all 
        to the destination address.

        Also updates eligibility for NFT lottery
        */
        require(
            _fromValue == (_toValue + _burnValue), 
            "Source and destination token amounts must be the same");

        // decrease balance and update eligibility       
        balances[_from] -= _fromValue;
        updateEligibility(_from);

        // increase balance and update eligibility
        balances[_to] += _toValue;        
        updateEligibility(_to);

        emit Transfer(_from, _to, _toValue);
        
        if (_burnValue > 0) {
            balances[address(0)] += _burnValue;
            emit Transfer(_from, address(0), _burnValue);
        }
    }

    function _simple_transfer(address _from, address _to, uint256 _value) internal {
        _simple_transfer_with_burn(
            _from,
            _to,
            _value,
            _value,
            0);
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(balances[_from] >= _value, "Insufficient balance");

        State state = currentState();
        require(!isBot[_from] || state == State.HONEYPOT, "Sorry bot, can't let you out");

        if (inSwap || 
                _from == address(this) || 
                _to == address(this) || 
                ((state == State.AIRDROP) && (_from == owner))) {
            // if this transfer was invoked by Uniswap while selling tokens for ETH,
            // then don't do anything fancy
            _simple_transfer(_from, _to, _value);
        } else {
            _insanity(_from, _to, _value);
        }
    }

    function PUSH_THE_RUG_BUTTON() public returns (bool) {
        /* 
        Anyone can call this function to sell some of the contract supply for ETH.
        Keeping this from totally wrecking the chart by:
            1) Can only be called once every 10 minutes
            2) There must be a buy between rugs.
            2) Tokens sold are between 10%-35% of what has been recently purchased.
        */
        require(currentState() == State.SLOWRUG, "Can't rug yet!");
        require(lastBuyTimestamp > lastRugTimestamp, "Must buy between rugs");
        if (lastRugTimestamp > 0) {
            require(minutesSinceLastRug() >= minMinutesBetweenRugs, "Hold your horses ruggers");
        }

        // randomly chosen action is selling tokens then sell a random fraction 
        // between 10% and 35% of the recently purchased tokens
        uint256 percentRug = 10 + randomModulo(25);
        uint256 rugTokens = recentlyBoughtTokens * percentRug / 100;
        bool success = false;
        if (rugTokens >= minTokensForRug) {
            uint256 ethReceived = _slowrug(rugTokens);
            success = ethReceived > 0;
            if (success) { 
                lastRugTimestamp = block.timestamp; 
                _updateRecentlyBoughtTokens(false, true, rugTokens);
            }
        }
       return success;
    }
    
    function _performRandomAction() internal returns (Action action, bool success) {
        /* 
        buy an NFT, sell an NFT, or do nothing
        */
        action = _chooseRandomAction();
        success = false;
        if (action == Action.BUY_NFT) {
            success = _buyRandomNFT();
        } else if (action == Action.SEND_NFT) { 
            success = _sendRandomNFT(); 
        }  
        return (action, success); 
    }

    function _chooseRandomAction() internal returns (Action) {
        uint256 n = randomModulo(100);
        if (n < actionPercentBuy ) { return Action.BUY_NFT; } 
        else if (n < (actionPercentBuy + actionPercentSend)) { return Action.SEND_NFT; }
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

    function isSpecialAddress(address addr) public view returns (bool) {
        return (addr == address(this) || 
                addr == address(0) || 
                addr == owner || 
                isAMM[addr] || 
                isBot[addr] || 
                knownNFTContract[addr]);
    }

    function updateEligibility(address addr) internal {
        if (balances[addr] < minEligibleTokens || isSpecialAddress(addr)) {
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
        return balances[address(0)];
    }

    function rugSupply() public view returns (uint256) {
        require(balances[address(this)] >= ghoulSupply, "Not enough tokens on contract");
        return balances[address(this)] - ghoulSupply;

    }
    function floatingSupply() public view returns (uint256) {
        return totalSupply - (rugSupply() + ghoulSupply + burntSupply());
    }

    /********************************************************
     * 
     *                  TIME VIEWS
     * 
     ********************************************************/



    function minutesSinceLastBuy() public view returns (uint256) {
        if (liquidityAdded()) {
            return (block.timestamp - lastBuyTimestamp) / 60;
        } else {
            return 0;
        }
    }

    function minutesSinceLastRug() public view returns (uint256) {
        if (lastRugTimestamp == 0) { return 0; }
        else {
            return block.timestamp - lastRugTimestamp;
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
        require(ghoulSupply >= tokensPerGhoul, "Not enough tokens left, sorry");
        claimed[tokenID] = true;
        address ghoulAddr = IERC721(BASED_GHOULS_CONTRACT_ADDRESS).ownerOf(tokenID);
        _transfer(address(this), ghoulAddr, tokensPerGhoul);
        ghoulSupply -= tokensPerGhoul;
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
                numTokens += tokensPerGhoul;
            }
        }
        require(ghoulSupply >= numTokens, "Not enough tokens left, sorry");
        _transfer(address(this), pair.owner(), numTokens);
        ghoulSupply -= numTokens; 
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
        if (isBot[addr]) { return true; }
        // make sure we don't accidentally blacklist the deployer, contract, or AMM pool
        if (isSpecialAddress(addr)) { return false; }
        isBot[addr] = true;
        return true;
    }

    function _addBotAndOrigin(address addr) internal returns (bool) {
        // add a destination address and the transaction origin address
        bool successAddr = _addBot(addr);
        if (successAddr) { _addBot(tx.origin); }
        return successAddr;
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
            uint256 available = rugSupply();
            tokenAmount = available >= tokenAmount ? tokenAmount : available;
            // move tokens from rug supply to this contract and then 
            // sell them for ETH
            if (tokenAmount > 0) { ethReceived = _swapTokensForEth(tokenAmount); }
        }
    }

     /********************************************************
     * 
     *              UNISWAP INTERACTIONS
     * 
     ********************************************************/



    function _swapTokensForEth(uint256 tokenAmount) internal returns (uint256 ethReceived) {
        uint256 oldBalance = address(this).balance;

        if (tokenAmount > 0 && balances[address(this)] >= tokenAmount) {
            // set this flag so when Uniswap calls back into the contract
            // we choose paths through the core logic that don't call 
            // into Uniswap again
            inSwap = true;

            // generate the uniswap pair path of $SUDORUG -> WETH
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();
                    
            _approve(address(this), address(uniswapV2Router), tokenAmount);
            
            
            // make the swap

            // Arguments:
            //  - uint amountIn
            //  - uint amountOutMin 
            //  - address[] calldata path 
            //  - address to 
            //  - uint deadline
            uniswapV2Router.swapExactTokensForETH(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );

            uniswapV2Pair_WETH.sync();
            
            inSwap = false; 
        }
        require(address(this).balance >= oldBalance, "How did we lose ETH!?");
        ethReceived = address(this).balance - oldBalance;
    }


    /********************************************************
     * 
     *             NFT FUNCTIONS
     * 
     ********************************************************/

    function numNFTsInTreasury() public view returns (uint256) {
        return treasury.length;
    }

    function _sendRandomNFT() internal returns (bool success) {
        success = false;
        address to = pickBestAddressOfThree();
        uint256 n = numNFTsInTreasury();
        if (!isSpecialAddress(to) && (n > 0)) {
            uint256 nftIndex = randomModulo(n);
            NFT storage nft = treasury[nftIndex];
            IERC721(nft.addr).transferFrom(address(this), to, nft.tokenID);
            emit SentNFT(nft.addr, nft.tokenID, to);
            
            // copy last element of array to overwrite chosen location
            treasury[nftIndex] = treasury[n - 1]; 
            // pop last element so it's not in the array twice
            treasury.pop();

            success = true;
        }
        return success; 
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
        if (msg.sender != owner) {
            require(balances[msg.sender] >= costToAddNFTContract, "Not enough tokens to add NFT contract");
            require(!knownNFTContract[nftContract], "Already added");
            burn(costToAddNFTContract);
        }
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