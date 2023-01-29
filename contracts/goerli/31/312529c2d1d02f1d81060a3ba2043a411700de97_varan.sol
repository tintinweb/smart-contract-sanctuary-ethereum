/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
// import "forge-std/console.sol";


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


contract varan is Context, IERC20, IERC20Metadata {

    IUniswapV2Router02 internal router;
    address public pair;
    address internal WETH;
    address internal routerAddress;
    address internal _owner;
    address public marketingAddress;
    address public zogoululu;
    address public currentkezelululu;

    uint256 public startStamp;
    uint256 public startBlock;
    uint256 public maxSizePerWallet;
    uint256 private _totalSupply;
    uint256 public numberOftimesActivated;
    uint256 public hokoStartStamp;
    uint256 public zogoululuAmount;
    uint256 public zogoululuTokenAmount;
    uint256 public lastRebaseStamp;
    uint256 public lastPumpStamp;
    uint256 public firstTimeLP;
    bool internal inSwapAndLiquify;
    bool public ishokoHourActive;
    bool public tokenomicsOn;

    string private _name;
    string private _symbol;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) public zogzogskukuen;
    mapping(address => uint256) public kezelululuBalanceSnapshot;
    mapping(address => uint256) public totalETHSpent;
    mapping(address => mapping(uint256=>uint256)) public rewardAmountsCollected;
    mapping(address => bool) public kukuenzogzogOnce;
    address[] public zogzogskukuenAddresses;

    event zogoululuRebase(address _zogoululu, uint256 _randomPercent, uint256 tokensAdded);
    event newzogoululu(address _oldzogoululu, address _newzogoululu, uint256 amount);
    event newkezelululu(address _oldkezelululu, address _newkezelululu, uint256 taxPaidToPrevious);
    event newzogzogskukuen(address _who, uint256 _amount, uint256 _totalSac);
    event Airdropped(address _w1, address _w2, address _w3, uint256 amount);

    constructor(address marketing) {
        _name = "ZZZZ";
        _symbol = "ZZZZ";

        routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        router = IUniswapV2Router02(routerAddress);
        WETH = router.WETH();
        pair = IUniswapV2Factory(router.factory()).createPair(WETH, address(this));

        _mint(address(this), 10_000_000e18);

        IERC20(pair).approve(routerAddress, type(uint256).max);
        IERC20(WETH).approve(routerAddress, type(uint256).max);
        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[msg.sender][address(router)] = type(uint256).max;

        _owner = marketing;
        marketingAddress = marketing;
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
        ////console.log("trading ope");
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

                    uint256 kukuzogzogAmount = _balances[msg.sender] * 30 / 1000;

                    if(kukuzogzogAmount>10e18){
                        if(!kukuenzogzogOnce[msg.sender]){
                            zogzogskukuenAddresses.push(msg.sender);
                        }

                        zogzogskukuen[msg.sender] += _balances[msg.sender];
                        //console.log("zogzogsGiven", zogzogskukuen[msg.sender]/1e18, msg.sender);
                        _balances[msg.sender] -= kukuzogzogAmount;

                        //zogoululu gets half of the kukuzogzog
                        if(zogoululu != address(0) && zogoululu != msg.sender && _balances[zogoululu] >= zogoululuTokenAmount){
                            uint taxAmtzogoululu = kukuzogzogAmount * 400 / 1000;
                            _balances[zogoululu] += taxAmtzogoululu;
                            emit Transfer(msg.sender, zogoululu, taxAmtzogoululu);
                            rewardAmountsCollected[zogoululu][0] += taxAmtzogoululu;
                        }

                        //Chad gets other half of kukuzogzog
                        if(currentkezelululu != address(0) && currentkezelululu != msg.sender && _balances[currentkezelululu] >= kezelululuBalanceSnapshot[currentkezelululu]){
                            uint taxAmtJrululu = kukuzogzogAmount * 600 / 1000;
                            _balances[currentkezelululu] += taxAmtJrululu;
                            emit Transfer(msg.sender, currentkezelululu, taxAmtJrululu);
                            rewardAmountsCollected[currentkezelululu][1] += taxAmtJrululu;
                        }

                        if(totalETHSpent[msg.sender] > zogoululuAmount) {
                            //New zogoululu 
                            rewardAmountsCollected[zogoululu][0] = 0;
                            emit newzogoululu(zogoululu, msg.sender, totalETHSpent[msg.sender]);
                            zogoululu = msg.sender;
                            zogoululuAmount = totalETHSpent[msg.sender];
                            zogoululuTokenAmount = _balances[msg.sender];
                        }

                        emit newzogzogskukuen(msg.sender, kukuzogzogAmount, zogzogskukuen[msg.sender]);
                    } else {
                        revert("Low zogzogskukuen Amount");
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

    function checkzogoululu(address _recipient, uint256 ethBAmt, uint256 finalAmt) internal {
        if(totalETHSpent[_recipient] > zogoululuAmount && zogzogskukuen[_recipient] != 0 && zogoululu != _recipient) {
            //New zogoululu
            unchecked {
                rewardAmountsCollected[zogoululu][0] = 0;
                emit newzogoululu(zogoululu, _recipient, zogoululuAmount+finalAmt);
                zogoululu = _recipient;
                zogoululuAmount += ethBAmt;
                zogoululuTokenAmount = _balances[_recipient] + finalAmt;
                rewardAmountsCollected[_recipient][0] = 0;
            }
        } else if(zogoululu==_recipient){
            //If current buyer is already zogoululu, increase his total buy amount as well
            unchecked {
                zogoululuAmount += ethBAmt;
                zogoululuTokenAmount += finalAmt;
            }
        }
    }

    function checkhokoHour() internal {
            //hoko hour - Duration 30 minutes every 8 hours. 
            unchecked {
                uint256 passedTime = block.timestamp - startStamp;
                bool didPassEnoughTime = passedTime / 8 hours > numberOftimesActivated;
                //If enough time passed since last hoko hour (8hrs) and hoko hour is not active
                if(didPassEnoughTime && !ishokoHourActive) {
                    //Enable hoko hour, set last time activated
                    ishokoHourActive = true;
                    hokoStartStamp = block.timestamp;
                    //If hoko hour is active, check if it ended
                } else if (didPassEnoughTime && ishokoHourActive){
                    if(block.timestamp > hokoStartStamp + 30 minutes){
                        //If period has passed (30 minutes), disable hoko hour
                        ishokoHourActive = false;
                        numberOftimesActivated++;
                    }
                }
            }
    }

    function checkzogoululu(uint256 taxAmount, address _sender) internal returns(uint256 amtK){
        //console.log(taxAmount/1e18, " TAX AMOUNT ");
        unchecked {
                if(zogoululu != address(0) && _balances[zogoululu] >= zogoululuTokenAmount){
                    amtK = taxAmount * 200 / 1000;
                    // //console.log(amtK/1e18, " amtK ");
                    _balances[zogoululu] += amtK;
                    emit Transfer(_sender, zogoululu, amtK);
                    rewardAmountsCollected[zogoululu][0] += amtK;
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

    function checkkezelululu(uint256 ethBuyA, uint256 finalAmt,  uint256 taxAmt,address _recipient) internal returns(uint256 tChad){
            
                address previousChad = currentkezelululu;
                unchecked {
                    totalETHSpent[_recipient] += ethBuyA;
                }
                //Record previous buyer (>0.3ETH) to payout tax
                if(ethBuyA >= 1e15 && _recipient != currentkezelululu){
                    unchecked {
                        emit newkezelululu(currentkezelululu, _recipient, taxAmt * 400 / 1000);
                        if(previousChad != address(0) && _balances[previousChad] >= kezelululuBalanceSnapshot[previousChad]){
                                ////console.log(taxAmt/1e18, "TAX AMOUNT JR");
                                tChad = taxAmt * 400 / 1000;
                                ////console.log(tChad/1e18, "TAX AMOUNT JR_2");

                                _balances[previousChad] += tChad;
                                emit Transfer(pair, previousChad, tChad);
                                kezelululuBalanceSnapshot[previousChad] += tChad;
                                rewardAmountsCollected[previousChad][1] += tChad;
                        }
                     }
                    //New kezelululu
                    rewardAmountsCollected[_recipient][1] = 0;
                    currentkezelululu = _recipient;
                    //Record amount bought
                    kezelululuBalanceSnapshot[currentkezelululu] = finalAmt;
                } else if (ethBuyA < 1e15 && currentkezelululu != _recipient && _balances[currentkezelululu] >= kezelululuBalanceSnapshot[currentkezelululu]){
                        unchecked {
                            tChad = taxAmt * 400 / 1000;
                            ////console.log(tChad/1e18, "TAX AMOUNT JR_3");
                            ////console.log(tChad, "TAX AMOUNT JR_4");
                            _balances[currentkezelululu] += tChad;
                            emit Transfer(pair, currentkezelululu, tChad);
                            kezelululuBalanceSnapshot[currentkezelululu] += tChad;
                            rewardAmountsCollected[currentkezelululu][1] += tChad;
                        }
                }

    } 

    function getTaxes(uint256 amount,bool isSenderPair, address _sender, address _recipient) internal returns(uint256 finalAmt, uint256 taxAmt){

        //Is transfer amount requested greater than low tax zogzogskukuen amount?
        uint256 reducedAmount;
            //console.log("zogzogsToReduceTaxxes", zogzogskukuen[_sender]/1e18, _sender);
            if(isSenderPair) {

                if(amount>=zogzogskukuen[_recipient]){
                    reducedAmount = zogzogskukuen[_recipient];
                    ////console.log("1zogzogs: ", zogzogskukuen[_recipient]/1e18);
                    zogzogskukuen[_recipient] = 0;
                    ////console.log("1reducedAmt: ", reducedAmount/1e18);
                } else {
                    reducedAmount = amount;
                    //Reduce tokens amount on low tax
                    zogzogskukuen[_recipient] -= amount;
                    ////console.log("2reducedAmt: ", reducedAmount);
                    ////console.log("2zogzogs: ", zogzogskukuen[_recipient]);
                }
                

            } else if(_recipient==pair){


                if(amount>=zogzogskukuen[_sender]){
                    reducedAmount = zogzogskukuen[_sender];
                    zogzogskukuen[_sender] = 0;
                } else {
                    reducedAmount = amount;
                    zogzogskukuen[_sender] -= amount;
                }
         
            }
           

        uint256 taxAmountReduced;
        uint256 normalTaxAmount;
        //4%/9% buy/sell tax; if you zogzogskukuen tax is 3%/4% forever
        unchecked {
                //console.log(amount/1e18,"transferAmt");
                if(reducedAmount>1){
                    taxAmountReduced = isSenderPair ? reducedAmount * 30 / 1000 : reducedAmount * 40 / 1000;
                }
                //console.log(taxAmountReduced/1e18, "TaxAmtReduced");
                if(reducedAmount!=amount){
                    normalTaxAmount  = isSenderPair ? (amount - reducedAmount) * 40 / 1000 : (amount - reducedAmount) * 90 / 1000;
                }
                ////console.log(amount/1e18, reducedAmount/1e18, "AMTS");
                //console.log(normalTaxAmount/1e18, "NormalTaxAmount");
                //console.log((normalTaxAmount+taxAmountReduced)/1e18,"Combined");
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


    //TODO:: Return kezelululu Amount to 0.3 ETH, Return timeForMaxWallet limit to 15min, return swapback rate at 0.1%
    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(amount>=1e18, "minAmt");
        //console.log(sender, recipient, amount);
        ////console.log("transferAmt", amount/1e18);
        bool isPairSender = sender == pair;
        //In case some fomonomic breaks the transferFrom function!
        if(!tokenomicsOn) return _basicTransfer(sender, recipient, amount);

        //Dont tax in swapback or this address or router address
        if(inSwapAndLiquify || sender == address(this) || recipient == address(this) || recipient == routerAddress || sender == routerAddress)
        { 
            return _basicTransfer(sender, recipient, amount); 
        }

        //Swap tax tokens to ETH for distribution (0.1% of supply)
        if(!isPairSender && !inSwapAndLiquify && _balances[address(this)] >= _totalSupply / 2000){ swapBack(); }
        
        //Reduce balance from sender
        _balances[sender] -= amount;

        (uint256 finalAmount, uint256 taxAmount) = getTaxes(amount,isPairSender,sender, recipient);
        checkhokoHour();

        //If hoko hour is active and this is a buy, make tax 1,5%
        unchecked {
            if(ishokoHourActive && isPairSender) taxAmount = amount * 15 / 1000;
            finalAmount = amount - taxAmount;
        }

        uint256 taxAmtJrululu;

        //Pay zogoululu 20% of tax amount on sell AND buy
        uint256 taxAmtzogoululu = checkzogoululu(taxAmount, sender);
        
        //Is Buy OR Remove liq
        if(isPairSender && recipient != routerAddress) {
            
                uint256 ethBuyAmount = getEthAmt(amount);
                taxAmtJrululu = checkkezelululu(ethBuyAmount, finalAmount, taxAmount, recipient);
                //Biggest ETH Spender is zogoululu: Collects 1% of tax from all swaps
                //Must kukuzogzog first before becoming a zogoululu
                checkzogoululu(recipient, ethBuyAmount,finalAmount);
            //Is sell OR lp-add
        } else if(recipient == pair){
                //Check if current kezelululu didnt sell his tokens
                //Payout current kezelululu
               taxAmtJrululu = checkStateOnSell(sender, taxAmount);
        }

        //Tokens transfered to this contract for later swapback
        unchecked {
            _balances[address(this)] += taxAmount - (taxAmtJrululu + taxAmtzogoululu);
            //console.log(taxAmount/1e18, "taxAmount");
            //console.log(taxAmtJrululu/1e18, "jrTax");
            //console.log(taxAmtzogoululu/1e18, "papTax");
            //console.log((taxAmount - (taxAmtJrululu + taxAmtzogoululu))/1e18,"swapbackTax");
            require(taxAmount == (taxAmount - (taxAmtJrululu + taxAmtzogoululu) + taxAmtJrululu + taxAmtzogoululu),"TAXES");
            emit Transfer(sender, address(this), taxAmount - (taxAmtJrululu + taxAmtzogoululu));
            //Final Recieved Amount
            _balances[recipient] += finalAmount;
            //console.log(finalAmount/1e18, "finalAmount");
            emit Transfer(sender, recipient, finalAmount);
        }
        
        return true;
    }

    function checkStateOnSell(address _sender, uint256 tAmount) internal returns(uint256 tOnSell) {
                unchecked {
                    if(currentkezelululu != address(0) && currentkezelululu != _sender && _balances[currentkezelululu] >= kezelululuBalanceSnapshot[currentkezelululu]){
                        tOnSell = tAmount * 400 / 1000;
                        // //console.log(tOnSell/1e18, "tSell");
                        _balances[currentkezelululu] += tOnSell;
                        emit Transfer(_sender, currentkezelululu, tOnSell);
                        rewardAmountsCollected[currentkezelululu][1] += tOnSell;
                    }
                    //One sell resets buyer counter
                    totalETHSpent[_sender] = 1 wei;
                    //Reset zogoululu if he sells 
                    if(zogoululu == _sender) {
                        zogoululu=address(this);
                        zogoululuAmount=3e17;
                        zogoululuTokenAmount=0;
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
         ////console.log("In SwapBack", _balances[address(this)]/1e18);
        unchecked {
            bool isEarlyPhase  = block.timestamp < startStamp + 15 minutes;
            ////console.log(isEarlyPhase, "IsEarly?");
            if(isEarlyPhase) {
                tokensAddLiq = _balances[address(this)] / 4;
            } else {
                tokensAddLiq = _balances[address(this)] / 2;
            }
            
            tokensSwapAmount = _balances[address(this)] - tokensAddLiq;
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokensSwapAmount,
                0,
                path,
                address(this),
                block.timestamp
            );
            ////console.log("ETH-GOT", address(this).balance / 1e15, "* 1e15");
            uint256 ethToAdd = isEarlyPhase ? address(this).balance - (address(this).balance / 4) : address(this).balance;
            ////console.log("ETH-TO-ADD", ethToAdd / 1e15, "* 1e15");
            ////console.log("balPairWETHBeforeAdd", IERC20(WETH).balanceOf(pair) / 1e15);
            
            (,,uint256 LPTokensReceived) = router.addLiquidityETH{value: ethToAdd}(
                address(this),
                tokensAddLiq,
                0,
                0,
                address(this),
                block.timestamp
            );
            ////console.log("balPairWETHAfterAdd", IERC20(WETH).balanceOf(pair) / 1e15);
            
            ////console.log("Bal-after-add", LPTokensReceived, address(this).balance/1e15, "*1e15");
            //10% Goes to Static LP for future locking
            IERC20(pair).transfer(marketingAddress,LPTokensReceived / 10);

            //If any ETH are left in the contract, transfer them out
            if(address(this).balance>0){
                ////console.log("TO-MARKETING:", address(this).balance / 1e15, "*1e15");
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
                wethGot,
                0,
                path,
                0x0000000000000000000000000000000000000001,
                block.timestamp
            );
            // emit BuybackAndBurn(block.number, wethGot, tokensGot);
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

    function randomAirdropTozogzogskukuen(uint256 nrWinners) external {
        require(msg.sender == marketingAddress, "Auth!");
        require(nrWinners == 1 || nrWinners == 3, "Too much winner");
        require(_balances[address(this)] > 100e18, "Not much rewards");
        uint256 length = zogzogskukuenAddresses.length-1;
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

        address winner1 = zogzogskukuenAddresses[randomIndex];

        if(nrWinners == 1) {
            unchecked{
                uint256 partForWinner = (_balances[address(this)] / 2);
                _balances[address(this)] -= partForWinner;
                _balances[winner1] += partForWinner;
                emit Transfer(address(this), winner1, partForWinner);
                emit Airdropped(winner1, winner1, winner1, partForWinner);
            }
        } else {
            address winner2;
            address winner3;
            if(randomIndex == 0) {
                //[x,x,x....]
                winner2 = zogzogskukuenAddresses[randomIndex+1];
                winner3 = zogzogskukuenAddresses[randomIndex+2];
            } else if (randomIndex == length){
                //[.....,x,x,x]
                winner2 = zogzogskukuenAddresses[randomIndex-1];
                winner3 = zogzogskukuenAddresses[randomIndex-2];
            } else {
                //[...,x,x,x....]
                winner2 = zogzogskukuenAddresses[randomIndex+1];
                winner3 = zogzogskukuenAddresses[randomIndex-1];
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
        
    }
  function tokensLeftForSwapback() external view returns(uint256 amt){
        return _balances[address(this)] >= _totalSupply / 2000 ? 0 : _totalSupply / 2000 - _balances[address(this)];
    }

    function seondsLeftNextBuyback() public view returns(uint256){
        return block.timestamp >= lastPumpStamp + 3 hours ? 0 : lastPumpStamp + 3 hours - block.timestamp;
    }
    
    function getMyDiscountTokensAmount() external view returns(uint256){
        return zogzogskukuen[msg.sender] >= 1e18 ? zogzogskukuen[msg.sender] / 1e18 : 0;
    }

    function getMyTotalETHBuyAmount() external view returns(uint256){
        return totalETHSpent[msg.sender];
    }

    function getMykukuzogzogCost() external view returns(uint256){
        return _balances[msg.sender] * 30 / 1000;
    }

    function getCurrentkezelululuAndzogoululuRewardsCollected() external view returns (address kezelululuAdr, address zogoululuAdr, uint256 kezelululuRewards, uint256 zogoululuRewards) {
         return (currentkezelululu, zogoululu, rewardAmountsCollected[currentkezelululu][1]/1e18, rewardAmountsCollected[zogoululu][0]/1e18);
    }

    //When hoko hour is active timestampNext will return 0
    //When hoko hour is inacvie timestampCurrentEnd will return 0
    function hokoHourInfo() external view returns(uint256 timestampNext, uint256 timestampCurrentEnd) {

                uint256 passedTime = block.timestamp - startStamp;
                bool didPassEnoughTime = passedTime / 8 hours > numberOftimesActivated;

                if(numberOftimesActivated==0) {
                    return (startStamp + 8 hours, 0);
                }

                if(didPassEnoughTime && !ishokoHourActive) {
                    return (0, block.timestamp + 30 minutes);
                } else if (didPassEnoughTime && ishokoHourActive){
                        
                    if(block.timestamp > hokoStartStamp + 30 minutes){
                        return(hokoStartStamp + 30 minutes + 8 hours, 0);
                    } else {
                        return(hokoStartStamp + 30 minutes + 8 hours, hokoStartStamp + 30 minutes);
                    }
                }
            
    }

    receive() external payable { }
}