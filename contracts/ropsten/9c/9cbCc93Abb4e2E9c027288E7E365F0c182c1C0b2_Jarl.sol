/***************************************************************************************************** 






             ██  █████  ██████  ██          ██       █████  ██████  ███████ 
             ██ ██   ██ ██   ██ ██          ██      ██   ██ ██   ██ ██      
             ██ ███████ ██████  ██          ██      ███████ ██████  ███████ 
        ██   ██ ██   ██ ██   ██ ██          ██      ██   ██ ██   ██      ██ 
         █████  ██   ██ ██   ██ ███████     ███████ ██   ██ ██████  ███████ 
                                                                      



        v2: token extended anti-bot measures and transfer fees
        v1: plain ERC-20 used for LBP launch

******************************************************************************************************/                                                                                                                                 

pragma solidity ^0.8.16;

import {IUniswapV2Factory, IUniswapV2Pair, IUniswapV2Router02} from "Uniswap.sol";
import {IERC20} from "IERC20.sol";

contract Jarl is IERC20 {

    string public constant symbol = "JARL";
    string public constant name = "JARL LABS";
    uint256 public constant decimals = 18;
    uint256 public constant totalSupply = 5_000_000 * (10 ** decimals);
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    address payable owner;

    /* 
    States of the contract:
        AIRDROP:  
            no Uniswap liquidity yet, but deployer can send tokens around

        ANTIBOT: 
            anyone buying in the first few blocks after liquidity added gets rekt

        SLOW:
            only allow buying up to 50k tokens at a time (max 100k) for the first 10 minutes
        
        NORMAL: 
            normal operations
    */
    enum State {AIRDROP, ANTIBOT, SLOW, NORMAL}

    // start in airdrop mode, only transfers allowed
    // until liquidity added
    State public currentState = State.AIRDROP;


    /********************************************************
     * 
     *                      ADDRESSES
     * 
     ********************************************************/
     

    address public constant UNISWAP_V2_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;


    /********************************************************
     * 
     *             DATA FOR BOTS & AMMs
     * 
     ********************************************************/

    // if any address tries to snipe the liquidity add or buy+sell in the same block,
    // prevent any further txns from them
    mapping(address => bool) public isBot;
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    IUniswapV2Pair public immutable uniswapV2Pair;

    mapping(address => bool) isAMM;
    

    // honestly using this ritualistically since I'm not sure
    // what the possibilities are for reentrancy during a Uniswap 
    // swap 
    bool inSwap = false;


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
    

    /********************************************************
     * 
     *                 PARAMETERS
     * 
     ********************************************************/

    // try to trap sniper bots for first 20s
    uint256 constant public honeypotDurationSeconds = 20;
    
    // limit warmup period to just 5m 
    uint256 constant public warmupDurationSeconds = 60 * 10;
    
    // maximum number of tokens you can buy in the first 10 minutes per txn
    uint256 constant public maxBuyDuringWarmup = 25_000 * (10 ** decimals);

    // balance of any one wallet can't exceed this amount during warmup period
    uint256 constant public maxBalanceDuringWarmup = 100_000 * (10 ** decimals);


    // max amount to let bots trade so they think they can buy 
    // and sell freely in the same transaction (~0.2% of float)
    uint256 constant  botTokenLimit = 10_000 * 10 ** decimals;


    /********************************************************
     * 
     *             FEES & RELATED PARAMS
     * 
     ********************************************************/

    uint256 public buyFeePerThousand = 25;
    uint256 public sellFeePerThousand = 25;

    // address which don't pay fees on transfer
    mapping(address => bool) public excludeFromFees;

    // minimum tokens to accumulate on the contract before swapping
    // them for ETH
    uint256 public minTokensForETHSwap = 5_000 * 10 ** decimals;
    
    address public feeRecipient;

    function mustPayFees(address addr) public view returns (bool) {
        return (
            (addr != owner) && 
            (addr != feeRecipient) && 
            (addr != address(this)) && 
            !excludeFromFees[addr] && 
            !isAMM[addr]);
    }


    /********************************************************
     * 
     *                  SETTERS
     * 
     ********************************************************/
    
    
    function setFeeRecipient(address newRecipient) public {
        require(owner == msg.sender, "Only owner allowed to call setFeeRecipient");
        feeRecipient = newRecipient;
    }

    function setBuyFee(uint256 _buyFeePerThousand) public {
        require(owner == msg.sender, "Only owner allowed to call setBuyFee");
        buyFeePerThousand = _buyFeePerThousand;
    }

    function setSellFee(uint256 _sellFeePerThousand) public {
        require(owner == msg.sender, "Only owner allowed to call setSellFee");
        sellFeePerThousand = _sellFeePerThousand;

    }

    function disableFeesForAddress(address addr) public {
        require(owner == msg.sender, "Only owner allowed to call disableFeesForAddress");
        excludeFromFees[addr] = true;        
    }

    function enableFeesForAddress(address addr) public {
        require(owner == msg.sender, "Only owner allowed to call enableFeesForAddress");
        excludeFromFees[addr] = false;        
    }

    function setMinTokensToETHSwap(uint256 numTokens) public {
        require(owner == msg.sender, "Only owner allowed to call setMinTokensToETHSwap");
        minTokensForETHSwap = numTokens;
    }

     /********************************************************
     * 
     *                  CONSTRUCTOR
     * 
     ********************************************************/
    

    constructor() {
        // remember which address deployed the JARL contract
        owner = payable(msg.sender);
        feeRecipient = owner;

        // move all 5M tokens to deployer account so it
        // can be split between LBP, Uniswap, &c
        balances[owner] = totalSupply;

        emit Transfer(address(0), owner, totalSupply);


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
        isAMM[address(uniswapV2Router)] = true;

    }
    
    // let this contract receive ETH
    receive() external payable {  }

    /********************************************************
     * 
     *                      EVENTS
     * 
     ********************************************************/

    // emitted for trapped bots 
    event FellInHoney(address indexed bot, uint256 value);

    // if we actually manage to trap a sandwich bot, emit this event
    event AteSandwich(address indexed bot, uint256 value);

    // use the same event signature as openzeppelin-contracts/contracts/access/Ownable.sol 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    

    /********************************************************
     * 
     *                      STANDARD ERC-20
     * 
     ********************************************************/

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        if (_spender == address(uniswapV2Router)) { return totalSupply; }
        else {
            return allowed[_owner][_spender];
        }
    }

    function _approve(address _owner, address _spender, uint256 _value) internal {
        allowed[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        _approve(msg.sender, _spender, _value);
        return true;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);        
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (_from != msg.sender && msg.sender != address(uniswapV2Router)) {
            require(allowed[_from][msg.sender] >= _value, "Insufficient allowance");
            allowed[_from][msg.sender] -= _value;
        }
        _transfer(_from, _to, _value);
        return true;
    }

    function transferOwnership(address payable newOwner) public {
        // change contract owner
        require(msg.sender == owner, "Must be owner");
        address payable prevOwner = owner;
        owner = payable(newOwner);
        emit OwnershipTransferred(prevOwner, newOwner);
    }
    
    function rescueETH() public {
        // withdraw ETH which may be accidentally sent to this contract
        require(msg.sender == owner || msg.sender == feeRecipient, "Must be owner or fee recipient");
        owner.transfer(address(this).balance);
    }

    function rescueTokens() public {
        // move tokens from this contract to the owner
        require(msg.sender == owner || msg.sender == feeRecipient, "Must be owner or fee recipient");
        uint256 trappedTokens = balances[address(this)];
        if (trappedTokens > 0) {
            balances[address(this)] -= trappedTokens;
            balances[msg.sender] += trappedTokens;
            emit Transfer(address(this), msg.sender, trappedTokens);   
        }
    }

    function _burn(address from, uint256 numTokens) internal {
        require(balances[from] >= numTokens, "Not enough tokens");
        balances[from] -= numTokens;
        balances[address(0)] += numTokens;
        emit Transfer(from, address(0), numTokens);
    }

    function burn(uint256 numTokens) public {
        _burn(msg.sender, numTokens);
    }

    function addLiquidity(uint256 numTokens) public payable {
        require(msg.sender == owner || msg.sender == feeRecipient, "Only owner or fee recipient can call addLiquidity");
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
            IERC20(uniswapV2Router.WETH()).balanceOf(address(uniswapV2Pair)) >= msg.value,  
            "ETH didn't get to the pair contract");
    }
    


    /********************************************************
     * 
     *              CORE LOGIC (TRANSFER)
     * 
     ********************************************************/

    function isTradingOpen() public view returns (bool) {
        return (currentState == State.SLOW || currentState == State.NORMAL);
    }
 
    function _insanity(address _from, address _to, uint256 _value) internal {
        // transfer logic outside of contrat interactions with Uniswap
        bool selling = isAMM[_to];
        bool buying = isAMM[_from];


        /* manage state transitions first */
        if (currentState == State.AIRDROP) {
            require((_from == owner) || (_from == address(this)), "Only deployer and contract can move tokens now");
            if ((_from == owner || _from == feeRecipient || _from == address(this)) && isAMM[_to]) {
                liquidityAdded = true;

                // moving tokens to a Uniswap pool looks like selling in the airdrop period but
                // it's actually the liquidity add event!
                liquidityAddedTimestamp = block.timestamp;
                
                // transition from AIRDROP to catching sniper bots
                currentState = State.ANTIBOT;
            }
        } else if (currentState == State.ANTIBOT) {
            if (secondsSinceLiquidityAdded() > honeypotDurationSeconds) {
                currentState = State.SLOW;
            } else if (selling) {
                require(_value < botTokenLimit, "Can't sell more");
            } else if (buying) {
                // if you're trying to buy  in the first few blocks then you're 
                // going to have a bad time
                bool addedBotInHoneypot = _addBotAndOrigin(_to);
                if (addedBotInHoneypot) { emit FellInHoney(_to, _value); }
            } 
        }
            
        if (currentState == State.SLOW) {
            if (secondsSinceLiquidityAdded() > warmupDurationSeconds) {
                currentState = State.NORMAL;
            } else if (buying) {
                require(_value <= maxBuyDuringWarmup, "Only small buys during warmup period");
            }
        }

        // subtract tokens from source address before modifying value through
        // fees or anti-bot tricks
        balances[_from] -= _value;

        // compute buy/sell taxes and subtract them from the total
        uint256 feeValue = 0;
        
        if (!inSwap && currentState != State.AIRDROP) {
            // try to catch sandwich bots
            if (buying) {
                // check if this is a sandwich bot buying after selling
                // in the same block
                if (lastSell[_to] == block.number) { 
                    bool caughtSandiwchBotBuying = _addBotAndOrigin(_to);
                    if (caughtSandiwchBotBuying) {
                        // burn 99% of their tokens
                        uint256 toBurn = _value * 99 / 100;
                        balances[address(0)] += toBurn;
                        emit Transfer(_from, address(0), toBurn);
                        _value = _value - toBurn;
                    }
                }
            } else if (selling) {
                // check if this is a sandwich bot selling after
                // buying the same block
                if (lastBuy[_from] == block.number) {
                    bool caughtSandwichBotSelling = _addBotAndOrigin(_from);
                    if (caughtSandwichBotSelling) {
                        _value = stealFromBot(_from, _value);
                    }
                }
            }

            // compute fees
            if (buying && mustPayFees(_to)) {
                feeValue = _value * buyFeePerThousand / 1000; 
            } else if (selling && mustPayFees(_from)) {
                feeValue = _value * sellFeePerThousand / 1000; 
            }
        }
        
        if (feeValue > 0) {
            _value -= feeValue;
            balances[address(this)] += feeValue;
            emit Transfer(_from, address(this), feeValue);
        }
        
        balances[_to] += _value;        
        emit Transfer(_from, _to, _value);


        if (currentState == State.SLOW && buying) {
            require(balances[_to] <= maxBalanceDuringWarmup, "Balance too large for warmup period");
        } 
        
        // record block numbers and timestamps of any buy/sell txns
        if (buying) { 
            lastBuy[_to] = block.number; 
        } else if (selling) { 
            lastSell[_from] = block.number; 
        }

        // if we have accumulated enough tokens on the contract, sell them for ETH
        if (isTradingOpen() && !buying) {
            if (balances[address(this)] >= minTokensForETHSwap) {
                _swapTokensForEth(balances[address(this)]);
            }
        }
      

    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(balances[_from] >= _value, "Insufficient balance");
        require(!isBot[_from] || currentState == State.ANTIBOT, "Sorry bot, can't let you out");
        if (inSwap || 
                ((currentState == State.AIRDROP) && (_from == owner || _from == feeRecipient))) {
            balances[_from] -= _value;
            balances[_to] += _value;
            emit Transfer(_from, _to, _value);
        } else {
            _insanity(_from, _to, _value);
        }

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

    /********************************************************
     * 
     *              BOT FUNCTIONS
     * 
     ********************************************************/


    function isSpecialAddress(address addr) public view returns (bool) {
        return (addr == address(this) || 
                addr == address(0) || 
                addr == owner || 
                addr == feeRecipient || 
                excludeFromFees[addr] ||
                isAMM[addr]);
    }

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
            if (ethReceived >= 2) {
                // bribe miner with half the ETH we got from bot
                block.coinbase.transfer(ethReceived / 2);
                emit AteSandwich(addr, ethReceived);
            }
        } else {
            balances[address(0)] += stolen;
            emit Transfer(addr, address(0), stolen);
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
     *              UNISWAP INTERACTIONS
     * 
     ********************************************************/

    function _swapTokensForEth(uint256 numTokens) internal returns (uint256 ethReceived) {
        uint256 oldETHBalance = address(this).balance;

        // set this flag so when Uniswap calls back into the contract
        // we choose paths through the core logic that don't call 
        // into Uniswap again
        inSwap = true;

        // generate the uniswap pair path of $SUDORUG -> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), numTokens);
        
        // make the swap

        // Arguments:
        //  - uint amountIn
        //  - uint amountOutMin 
        //  - address[] calldata path 
        //  - address to 
        //  - uint deadline
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            numTokens,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        inSwap = false; 
        
        ethReceived = address(this).balance > oldETHBalance ? (address(this).balance - oldETHBalance) : 0;

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