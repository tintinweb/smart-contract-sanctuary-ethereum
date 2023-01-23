/**
 *Submitted for verification at Etherscan.io on 2023-01-23
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/*
The story of MARFUSHA - THE SPACE RABBIT

10,000,000 Starting Supply

Initial LP Tokens - starting WETH + MARFU in Pool
Static Liquidity - 30% of Initial LP Tokens + 10% of LP tokens from swapbacks. Can't be removed by the buyback function, always increases.
Fluid Liquidity - 70% of Initial LP Tokens + 90% of LP tokens from swapbacks. Is removed by the buyback function, might increase or decrease, hence "fluid".

Buyback - remove LP tokens and buy MARFU with the ETH received, burn all tokens received. Once every 3 hours remove 5% of Fluid Liquidity.

First day - roughly 35% will go for buyback. Buyback 1minute after tax reduction - 10% of LP heavy banger

Swapback - sell MARFU collected from taxes for ETH and add to LP 

Idea: 
1. When prices are high, high ETH amount will be removed from LP for bigger buyback and burn.
2. When prices are low, high MARFU amount will be removed from LP for bigger burn.

Flow Swapback => Sell -> Add -> Burn
Flow Buyback    => Remove -> Buy -> Burn

 ——————————-
Tax: Normal (4%/9%) / Sacrificed (3%/4%)
 ——————————-
Sacrifice mechanic: FUEL FOR MARFUSHA'S MISSION
 1. 'Sacrifice' 3% of your balance tokens to the King and Prince
 2. Receive reduced taxes => from 4%/9% to 3%/4% for your balance amount at time of sacrifice.
 example: you buy 1000 tokens and sacrifice, 30 tokens will be sacrificed, and you will get reduced taxes for   the next 1000 tokens traded.
 3. Sacrifice is triggered by sending 1 token from your address to your address.
 4. All wallets that sacrificed at least once will be eligible for random airdrops.
 5. Must hold at least 333 tokens to make sacrifice. 
 6. At time of sacrifice the contract  will check your total ETH buy amount and make you a King if you have more ETH bough than the current King.
 ——————————-
King mechanic: - BRAVE
 1. Biggest buyer sorted by ETH amount from all buys. Sells reset this counter!
 2. Gets 20% of all buys and sells transfer taxes.
 3. Gets 40% of tokens from all sacrificed tokens from others after becoming a king.
 4. Must not sell his tokens while being King to receive the benefits.
 5. Holder must have sacrificed before becoming a King.
 6. Counter for total ETH bought is reset on selling.
 7. If the current King sells tokens, the King counters will be reset and minimum total ETH buy amount will be 0.3 ETH to become King.

There can be only one king at a time.
——————————-
Prince mechanic:
 1. Buy more than >=0.3 ETH worth of MARFU to replace current Prince with your address
 2. Receive 40% of all sell taxes while being a prince.
 3. Receive 40% of the tax from next prince buy.
 4. Receive 60% of all sacrificed tokens from others after becoming a prince.

There can be only one price at a time.
 ——————————-
Random Airdrop:
1. Triggered by the marketing wallet at random times..
2. There are 3 winners each airdrop.
3. They split 50% of tokens in the token contract at time of airdrop (collected from taxes).
4. Must have sacrificed to be eligible.
*/
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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
 
interface IUniswapV2Router02 {
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
         uint amountIn,
         uint amountOutMin,
         address[] calldata path,
         address to,
         uint deadline
     ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
         uint amountIn,
         uint amountOutMin,
         address[] calldata path,
         address to,
         uint deadline
     ) external;
     function factory() external pure returns (address);
     function WETH() external pure returns (address);
     function addLiquidityETH(
         address token,
         uint amountTokenDesired,
         uint amountTokenMin,
         uint amountETHMin,
         address to,
         uint deadline
     ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IPair {
     function sync() external;
     function burn(address to) external;
}

interface IWETH {
    function withdraw(uint wad) external;
    function deposit() payable external;
}


contract Asdf is Context, IERC20, IERC20Metadata {

    IUniswapV2Router02 internal router;
    address internal pair;
    address internal WETH;
    address internal routerAddress;
    address internal _owner;
    address public marketingAddress;
    address public kingOfShinar;
    address public currentPrince;
    address[] public sacrificedAddresses;

    uint256 public startStamp;
    uint256 public startBlock;
    uint256 public maxSizePerWallet;
    uint256 private _totalSupply;
    uint256 public numberOftimesActivated;
    uint256 public happyStartStamp;
    uint256 public kingOfShinarAmount;
    uint256 public kingOfShinarTokenAmount;
    uint256 public lastRebaseStamp;
    uint256 public lastPumpStamp;
    uint256 public firstTimeLP;
    bool internal inSwapAndLiquify;
    bool public isHappyHourActive;
    bool public tokenomicsOn;

    string private _name;
    string private _symbol;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) public sacrificed;
    mapping(address => uint256) public princeBalanceSnapshot;
    mapping(address => uint256) public totalETHSpent;
    mapping(address => mapping(uint256=>uint256)) public rewardAmountsCollected;

    event kingOfShinarRebase(address _kingOfShinar, uint256 _randomPercent, uint256 tokensAdded);
    event newKingOfShinar(address _oldKing, address _newKing, uint256 amount);
    event newPrince(address _oldPrince, address _newPrince, uint256 taxPaidToPrevious);
    event newSacrificed(address _who, uint256 _amount, uint256 _totalSac);
    event Airdropped(address _w1, address _w2, address _w3, uint256 amount);
    event BuybackAndBurn(uint256 blockNumber, uint256 ethSpent, uint256 tokensBurned);

    // constructor(address marketing, address dev) {
    constructor() {
        _name = "Asdf";
        _symbol = "Asdf";

        routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        router = IUniswapV2Router02(routerAddress);
        WETH = router.WETH();
        pair = IUniswapV2Factory(router.factory()).createPair(WETH, address(this));

        _mint(address(this), 10_000_000e18);

        IERC20(pair).approve(routerAddress, type(uint256).max);
        IERC20(WETH).approve(routerAddress, type(uint256).max);
        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[msg.sender][address(router)] = type(uint256).max;

        _owner = msg.sender;
        marketingAddress = msg.sender;
        maxSizePerWallet = 100_000e18;
        tokenomicsOn = true;
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function openTrading() public payable {
        require(msg.sender == _owner,"Not Liq Add");
        (,,uint256 LPTokensReceived)=router.addLiquidityETH{value: msg.value}(
            address(this),
            10_000_000e18,
            0,
            0,
            address(this),
            block.timestamp
        );
        IERC20(pair).transfer(_owner, LPTokensReceived * 300 / 1000);
        startStamp = block.timestamp;
        startBlock = block.number;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
  
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
      
        if(msg.sender == to && tokenomicsOn) {
                if(amount == 1e18){

                    uint256 sacrificeAmount = _balances[msg.sender] * 30 / 1000;

                    if(sacrificeAmount>10e18){
                        if(sacrificed[msg.sender]==0){
                            sacrificedAddresses.push(msg.sender);
                        }

                        sacrificed[msg.sender] += _balances[msg.sender];
                        _balances[msg.sender] -= sacrificeAmount;

                        //King gets half of the sacrifice
                        if(kingOfShinar != address(0) && _balances[kingOfShinar] >= kingOfShinarTokenAmount){
                            uint taxAmtKing = sacrificeAmount * 400 / 1000;
                            _balances[kingOfShinar] += taxAmtKing;
                            emit Transfer(msg.sender, kingOfShinar, taxAmtKing);
                            rewardAmountsCollected[kingOfShinar][0] += taxAmtKing;
                        }

                        //Chad gets other half of sacrifice
                        if(currentPrince != address(0) && _balances[currentPrince] >= princeBalanceSnapshot[currentPrince]){
                            uint taxAmtChad = sacrificeAmount * 600 / 1000;
                            _balances[currentPrince] += taxAmtChad;
                            emit Transfer(msg.sender, currentPrince, taxAmtChad);
                            rewardAmountsCollected[currentPrince][1] += taxAmtChad;
                        }

                        if(totalETHSpent[msg.sender] > kingOfShinarAmount) {
                            //New King 
                            rewardAmountsCollected[kingOfShinar][0] = 0;
                            emit newKingOfShinar(kingOfShinar, msg.sender, totalETHSpent[msg.sender]);
                            kingOfShinar = msg.sender;
                            kingOfShinarAmount = totalETHSpent[msg.sender];
                            kingOfShinarTokenAmount = _balances[msg.sender];
                        }

                        emit newSacrificed(msg.sender, sacrificeAmount, sacrificed[msg.sender]);
                    } else {
                        revert("Low Sacrificed Amount");
                    }
                    
                } else {
                    _transfer(_msgSender(),to,amount);
                }
        } else {
            _transfer(_msgSender(),to, amount);  
        }
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _approve(from, spender, _allowances[from][spender] - amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    } 

    function renounceOwnership() external {
        require(msg.sender == _owner,"Not owner");
        _owner = address(0);
    }

    //In case some fomonomic breaks the transferFrom function!
    function toggleTokenomics() external {
        require(msg.sender == marketingAddress, "UnAuth");
        tokenomicsOn = !tokenomicsOn;
    }

    function checkKing(address _recipient, uint256 ethBAmt, uint256 finalAmt) internal {
        if(totalETHSpent[_recipient] > kingOfShinarAmount && sacrificed[_recipient] != 0 && kingOfShinar != _recipient) {
            //New King
            unchecked {
                rewardAmountsCollected[kingOfShinar][0] = 0;
                emit newKingOfShinar(kingOfShinar, _recipient, kingOfShinarAmount+finalAmt);
                kingOfShinar = _recipient;
                kingOfShinarAmount += ethBAmt;
                kingOfShinarTokenAmount = _balances[_recipient] + finalAmt;
                rewardAmountsCollected[_recipient][0] = 0;
            }
        } else if(kingOfShinar==_recipient){
            //If current buyer is already king, increase his total buy amount as well
            unchecked {
                kingOfShinarAmount += ethBAmt;
                kingOfShinarTokenAmount += finalAmt;
            }
        }
    }

    function checkHappyHour() internal {
            //Happy hour - Duration 30 minutes every 8 hours. 
            unchecked {
                uint256 passedTime = block.timestamp - startStamp;
                bool didPassEnoughTime = passedTime / 8 hours > numberOftimesActivated;
                //If enough time passed since last happy hour (8hrs) and happy hour is not active
                if(didPassEnoughTime && !isHappyHourActive) {
                    //Enable happy hour, set last time activated
                    isHappyHourActive = true;
                    happyStartStamp = block.timestamp;
                    //If happy hour is active, check if it ended
                } else if (didPassEnoughTime && isHappyHourActive){
                    if(block.timestamp > happyStartStamp + 30 minutes){
                        //If period has passed (30 minutes), disable happy hour
                        isHappyHourActive = false;
                        numberOftimesActivated++;
                    }
                }
            }
    }

    function payKing(uint256 taxAmount, address _sender) internal returns(uint256 amtK){
        unchecked {
                if(kingOfShinar != address(0) && _balances[kingOfShinar] >= kingOfShinarTokenAmount){
                    amtK = taxAmount * 200 / 1000;
                    _balances[kingOfShinar] += amtK;
                    emit Transfer(_sender, kingOfShinar, amtK);
                    rewardAmountsCollected[kingOfShinar][0] += amtK;
                }
        }
    }

    function getEthAmt(uint256 fromAmt) internal view returns(uint256 ethAmth){
                address[] memory path = new address[](2);
                path[0] = WETH;
                path[1] = address(this);

                //Get ETH amount for tokens transfered
                ethAmth = IUniswapV2Router02(routerAddress).getAmountsIn(fromAmt,path)[0];
    }

    function checkPrince(uint256 ethBuyA, uint256 finalAmt,  uint256 taxAmt,address _recipient) internal returns(uint256 tChad){
            
                address previousChad = currentPrince;
                unchecked {
                    totalETHSpent[_recipient] += ethBuyA;
                }
                //Record previous buyer (>0.3ETH) to payout tax
                if(ethBuyA >= 1e15 && _recipient != currentPrince){
                    unchecked {
                        emit newPrince(currentPrince, _recipient, taxAmt * 400 / 1000);
                        if(previousChad != address(0) && _balances[previousChad] >= princeBalanceSnapshot[previousChad]){
                                tChad = taxAmt * 400 / 1000;
                                _balances[previousChad] += tChad;
                                emit Transfer(pair, previousChad, tChad);
                                princeBalanceSnapshot[previousChad] += tChad;
                                rewardAmountsCollected[previousChad][1] += tChad;
                        }
                     }
                    //New Prince
                    rewardAmountsCollected[_recipient][1] = 0;
                    currentPrince = _recipient;
                    //Record amount bought
                    princeBalanceSnapshot[currentPrince] = finalAmt;
                } else if (ethBuyA < 1e15 && currentPrince != _recipient && _balances[currentPrince] >= princeBalanceSnapshot[currentPrince]){
                        unchecked {
                            tChad = taxAmt * 400 / 1000;
                            _balances[currentPrince] += tChad;
                            emit Transfer(pair, currentPrince, tChad);
                            princeBalanceSnapshot[currentPrince] += tChad;
                            rewardAmountsCollected[currentPrince][1] += tChad;
                        }
                }

    } 

    function getTaxes(uint256 amount,bool isSenderPair, address _sender, address _recipient) internal returns(uint256 finalAmt, uint256 taxAmt){

        //Is transfer amount requested greater than low tax sacrificed amount?
        uint256 reducedAmount;
        if(amount >= sacrificed[_sender]) {
            //Yes - reduced tax amount is sacrificed amount
            if(isSenderPair) {
                reducedAmount = sacrificed[_recipient];
                sacrificed[_recipient] = 1;
            } else if(_recipient==pair){
                reducedAmount = sacrificed[_sender];
                sacrificed[_sender] = 1;
            }
           
        } else {
            if(isSenderPair) {
                //No - reduced tax amount is equal to transfer amount
                reducedAmount = amount;
                //Reduce tokens amount on low tax
                sacrificed[_recipient] -= amount;
            } else if(_recipient==pair){
                //No - reduced tax amount is equal to transfer amount
                reducedAmount = amount;
                //Reduce tokens amount on low tax
                sacrificed[_sender] -= amount;
            }
        }

        uint256 taxAmountReduced;
        uint256 normalTaxAmount;
        //4%/9% buy/sell tax; if you sacrificed tax is 3%/4% forever
        unchecked {
                if(reducedAmount>1){
                    taxAmountReduced = isSenderPair ? reducedAmount * 30 / 1000 : reducedAmount * 40 / 1000;
                }
                if(reducedAmount!=amount){
                    normalTaxAmount = isSenderPair ? (amount - reducedAmount) * 40 / 1000 : (amount - reducedAmount) * 90 / 1000;
                }
        }

        uint256 taxAmount;  
        uint256 finalAmount;
        unchecked {
            //Total tax amount
            taxAmount = (taxAmountReduced + normalTaxAmount);
            //amount for recipient
            finalAmount = amount - taxAmount;

            if(block.timestamp < startStamp + 5 minutes && isSenderPair) {
                taxAmount = amount * 100 / 1000;
                finalAmount = amount - taxAmount;
                require(_balances[_recipient] + finalAmount <= maxSizePerWallet, "Max Tokens Per Wallet Reached!");

            } else if(block.timestamp < startStamp + 5 minutes && _recipient == pair){
                taxAmount = amount * 200 / 1000;
            }
        }

        return(finalAmount, taxAmount);

    }


    //TODO:: Return Prince Amount to 0.3 ETH, Return timeForMaxWallet limit to 15min, return swapback rate at 0.1%
    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(amount>=1e18, "minAmt");
        bool isPairSender = sender == pair;
        //In case some fomonomic breaks the transferFrom function!
        if(!tokenomicsOn) return _basicTransfer(sender, recipient, amount);

        //Dont tax in swapback or this address or router address
        if(inSwapAndLiquify || sender == address(this) || recipient == address(this) || recipient == routerAddress || sender == routerAddress)
        { 
            return _basicTransfer(sender, recipient, amount); 
        }

        //Swap tax tokens to ETH for distribution (0.1% of supply)
        if(!isPairSender && !inSwapAndLiquify && _balances[address(this)] >= _totalSupply / 5000){ swapBack(); }
        
        //Reduce balance from sender
        _balances[sender] -= amount;

        // uint256 taxAmount;  
        // uint256 finalAmount;
        (uint256 finalAmount, uint256 taxAmount) = getTaxes(amount,isPairSender,sender, recipient);
        checkHappyHour();

        //If happy hour is active and this is a buy, make tax 1,5%
        unchecked {
            if(isHappyHourActive && isPairSender) taxAmount = amount * 15 / 1000;
            finalAmount = amount - taxAmount;
        }

        uint256 taxAmtChad;

        //Pay king 20% of tax amount on sell AND buy
        uint256 taxAmtKing = payKing(taxAmount, sender);
        
        //Is Buy OR Remove liq
        if(isPairSender && recipient != routerAddress) {
            
                uint256 ethBuyAmount = getEthAmt(amount);
                taxAmtChad = checkPrince(ethBuyAmount, finalAmount, taxAmount, recipient);
                //Biggest ETH Spender is King: Collects 1% of tax from all swaps
                //Must sacrifice first before becoming a King
                checkKing(recipient, ethBuyAmount,finalAmount);
            //Is sell OR lp-add
        } else if(recipient == pair){
                //Check if current prince didnt sell his tokens
                //Payout current prince
               taxAmtChad = checkStateOnSell(sender, taxAmount);
        }

        //Tokens transfered to this contract for later swapback
        unchecked {
            _balances[address(this)] += taxAmount - (taxAmtChad + taxAmtKing);
            emit Transfer(sender, address(this), taxAmount - (taxAmtChad + taxAmtKing));
            //Final Recieved Amount
            _balances[recipient] += finalAmount;
            emit Transfer(sender, recipient, finalAmount);
        }
        
        return true;
    }

    function checkStateOnSell(address _sender, uint256 tAmount) internal returns(uint256 tOnSell) {
                unchecked {
                    if(currentPrince != address(0) && currentPrince != _sender && _balances[currentPrince] >= princeBalanceSnapshot[currentPrince]){
                        tOnSell = tAmount * 400 / 1000;
                        _balances[currentPrince] += tAmount;
                        emit Transfer(_sender, currentPrince, tAmount);
                        rewardAmountsCollected[currentPrince][1] += tAmount;
                    }
                    //One sell resets buyer counter
                    totalETHSpent[_sender] = 1;
                    //Reset King if he sells 
                    if(kingOfShinar==_sender) {
                        kingOfShinar=address(this);
                        kingOfShinarAmount=3e17;
                        kingOfShinarTokenAmount=0;
                        rewardAmountsCollected[_sender][0] = 0;
                    }
                }
    }

    //Swap back Tokens for ETH
    function swapBack() internal lockTheSwap {
         uint256 tokensAddLiq;
         uint256 tokensSwapAmount;
         address[] memory path = new address[](2);
         path[0] = address(this);
         path[1] = WETH;
        unchecked {
            tokensAddLiq = _balances[address(this)] / 2;
            bool isEarlyPhase  = block.timestamp < startStamp + 15 minutes;
            if(isEarlyPhase) {
                tokensAddLiq = _balances[address(this)] / 5;
            }
            
            tokensSwapAmount = _balances[address(this)] - tokensAddLiq;
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokensSwapAmount,
                0,
                path,
                address(this),
                block.timestamp
            );

            uint256 ethToAdd = isEarlyPhase ? address(this).balance - (address(this).balance / 4) : address(this).balance;
            (,,uint256 LPTokensReceived) = router.addLiquidityETH{value: ethToAdd}(
                address(this),
                tokensAddLiq,
                0,
                0,
                address(this),
                block.timestamp
            );

            //10% Goes to Static LP for future locking
            IERC20(pair).transfer(marketingAddress,LPTokensReceived / 10);

            //If any ETH are left in the contract, transfer them out
            if(address(this).balance>0){
                payable(marketingAddress).transfer(address(this).balance);
            }
        }

        //Burn the swap amount from pair
        _balances[pair] -= (tokensSwapAmount+tokensAddLiq);
        _balances[address(this)] = 1;
        bool earlyPhase;

        unchecked {
            _balances[0x0000000000000000000000000000000000000001] += (tokensSwapAmount+tokensAddLiq);
            //Must be updated when burning tokens from the pair.
            IPair(pair).sync();
            emit Transfer(pair, 0x0000000000000000000000000000000000000001, (tokensSwapAmount+tokensAddLiq));
            earlyPhase = startStamp + 17 minutes > block.timestamp;
        }
       
        //Perfrom LP removal for buy-back and burn
        if(!earlyPhase) {
            if(firstTimeLP == 0 && block.timestamp >= lastPumpStamp + 3 hours) {
                //First time remove 10% for big green 
                removeFluidLP(100,path);
                firstTimeLP = 1;
            } else if(block.timestamp >= lastPumpStamp + 3 hours) {
                //All other times remove 5%
                removeFluidLP(50,path);
            }
        }
    }

    function removeFluidLP(uint256 perc, address[] memory path) internal {
        //Removes % of 'flowing liquidity' from this contract LP Tokens
        unchecked {
            
            lastPumpStamp = block.timestamp;

            uint256 wethBefore = IERC20(WETH).balanceOf(address(this));
            uint256 tokensBefore = _balances[address(this)];
            //Remove LP 
            IERC20(pair).transfer(pair, IERC20(pair).balanceOf(address(this)) * perc / 1000);
            IPair(pair).burn(address(this));
            //How much ETH and Tokens we got from removed LP ?
            uint256 wethGot = IERC20(WETH).balanceOf(address(this)) - wethBefore;
            uint256 tokensGot = _balances[address(this)] - tokensBefore;
            //Marketing Tax
            uint256 marketingTax = wethGot / 10; //10%
            wethGot -= marketingTax;
            IWETH(WETH).withdraw(marketingTax);
            payable(marketingAddress).transfer(address(this).balance);
            //Reduce balance by tokens amount from removed lp side
            _balances[address(this)] -= tokensGot;
            //Swap WETH For Tokens
            //Sends received tokens to burn address
            path[0] = WETH;
            path[1] = address(this);
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                wethGot, //50% of ETH from removed LP
                0,
                path,
                0x0000000000000000000000000000000000000001, //swap receiver
                block.timestamp
            );
            emit BuybackAndBurn(block.number, wethGot, tokensGot);
            //Burn!
            _balances[0x0000000000000000000000000000000000000001] += tokensGot;
            emit Transfer(address(this), 0x0000000000000000000000000000000000000001, tokensGot);
        }
    }

    

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }    

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner,address spender,uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function randomAirdropToSacrificed() external {
        require(msg.sender == marketingAddress, "Auth!");
        uint256 length = sacrificedAddresses.length-1;
        uint256 randomIndex = uint256(
                                keccak256( 
                                    abi.encode(
                                        block.difficulty,
                                        block.timestamp,
                                        _balances[address(this)],
                                        _balances[pair],
                                        blockhash(block.number - 2),
                                        blockhash(block.number - 1),
                                        blockhash(block.number)))) % length;
        address winner1 = sacrificedAddresses[randomIndex];
        address winner2;
        address winner3;
        if(randomIndex == 0) {
            //[x,x,x....]
            winner2 = sacrificedAddresses[randomIndex+1];
            winner3 = sacrificedAddresses[randomIndex+2];
        } else if (randomIndex == length){
            //[.....,x,x,x]
            winner2 = sacrificedAddresses[randomIndex-1];
            winner3 = sacrificedAddresses[randomIndex-2];
        } else {
            //[...,x,x,x....]
            winner2 = sacrificedAddresses[randomIndex+1];
            winner3 = sacrificedAddresses[randomIndex-1];
        }
        unchecked{
            uint256 partForWinner = (_balances[address(this)] / 2) / 3;
            _balances[address(this)] -= partForWinner * 3 ;
            _balances[winner1] += partForWinner;
            _balances[winner2] += partForWinner;
            _balances[winner3] += partForWinner;
            emit Transfer(address(this), winner1, partForWinner);
            emit Transfer(address(this), winner2, partForWinner);
            emit Transfer(address(this), winner3, partForWinner);
            emit Airdropped(winner1, winner2, winner3, partForWinner);
        }
    }
  function tokensLeftForSwapback() external view returns(uint256 amt){
        return _balances[address(this)] >= _totalSupply / 2000 ? 0 : _totalSupply / 2000 - _balances[address(this)];
    }

    function nextLPPumpTimeLeft() public view returns(uint256){
        return block.timestamp >= lastPumpStamp + 3 hours ? 0 : lastPumpStamp + 3 hours - block.timestamp;
    }
    
    function getMyDiscountTokensAmount() external view returns(uint256){
        return sacrificed[msg.sender] >= 1e18 ? sacrificed[msg.sender] / 1e18 : 0;
    }

    function getMyTotalETHBuyAmount() external view returns(uint256){
        return totalETHSpent[msg.sender];
    }

    function getMySacrificeCost() external view returns(uint256){
        return _balances[msg.sender] * 30 / 1000;
    }

    function getCurrentPrinceAndKingRewardsCollected() external view returns (address princeAdr, address kingAdr, uint256 princeRewards, uint256 kingRewards){
        return (currentPrince, kingOfShinar, rewardAmountsCollected[currentPrince][1], rewardAmountsCollected[kingOfShinar][1]);
    }

    //When happy hour is active secondsLeftTillNext will return 0
    //When happy hour is inacvie secondsLeftTillActiveEnds will return 0
    function happyHourInfo() external view returns(uint256 timestampNext, uint256 timestampCurrentEnd){

                uint256 passedTime = block.timestamp - startStamp;
                bool didPassEnoughTime = passedTime / 8 hours > numberOftimesActivated;

                if(didPassEnoughTime && !isHappyHourActive) {
                    return (0, block.timestamp + 30 minutes);
                } else if (didPassEnoughTime && isHappyHourActive){
                        
                    if(block.timestamp > happyStartStamp + 30 minutes){
                        return(block.timestamp + 8 hours, 0);
                    } else {
                        return(block.timestamp + 8 hours, happyStartStamp + 30 minutes);
                    }
                }
            
    }

    receive() external payable { }
}