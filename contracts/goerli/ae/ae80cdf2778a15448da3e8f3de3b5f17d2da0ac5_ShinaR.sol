/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
// import "forge-std/Test.sol";
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
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    // function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint256[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

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
     function skim(address to) external;
     function sync() external;
     function mint(address to) external;
     function burn(address to) external;
}

interface IWETH {
    function withdraw(uint wad) external;
    function approve(address who, uint wad) external returns(bool);
    function deposit() payable external;
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address _owner) external view returns(uint256);
}


contract ShinaR is Context, IERC20, IERC20Metadata {

    IUniswapV2Router02 internal router;

    address internal pair;
    address internal WETH;
    address internal routerAddress;
    address internal _owner;
    address public marketingAddress;
    address public kingOfShinar;
    address public currentPrince;
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

    string private _name;
    string private _symbol;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) public sacrificed;
    mapping(address => uint256) public princeBalanceSnapshot;
    mapping(address => uint256) public totalETHSpent;

    event kingOfShinarRebase(address _kingOfShinar, uint256 _randomPercent, uint256 tokensAdded);
    event newKingOfShinar(address _oldKing, address _newKing, uint256 amount);
    event newPrince(address _oldPrince, address _newPrince, uint256 taxPaidToPrevious);
    event newSacrificed(address _who, uint256 _amount);
    event Airdropped(address _w1, address _w2, address _w3, uint256 amount);

    constructor(address marketing, address dev) payable {
        _name = "TEST2";
        _symbol = "TEST2";

        routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        router = IUniswapV2Router02(routerAddress);
        WETH = router.WETH();
        pair = IUniswapV2Factory(router.factory()).createPair(WETH, address(this));

        //Initial supply
        _mint(address(this), 10_000_000e18);

        //Approvals
        IERC20(pair).approve(routerAddress, type(uint256).max);
        IERC20(WETH).approve(routerAddress, type(uint256).max);
        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[msg.sender][address(router)] = type(uint256).max;
        
        //Initial reserve
        IWETH(WETH).deposit{value: msg.value}();

        _owner = dev;
        marketingAddress = marketing;
        maxSizePerWallet = 100_000e18;
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function addLPAndAllowExchange() public payable {
        require(msg.sender == _owner,"Not Liq Add");
        (,,uint256 gotLP)=router.addLiquidityETH{value: msg.value}(
            address(this),
            10_000_000e18,
            0,
            0,
            address(this),
            block.timestamp
        );

        // initialLP = ;
        IERC20(pair).transfer(_owner, gotLP * 300 / 1000);
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
      
        if(msg.sender == to) {

            if(sacrificed[msg.sender] == 0){
                //emit log("SACRIFICING");
                //4% sacrifice amount fixed
                if(amount == 1e18){

                    uint256 sacrificeAmount = _balances[msg.sender] * 40 / 1000;

                    if(sacrificeAmount>10e18){
                        sacrificed[msg.sender] = sacrificeAmount;
                        _balances[msg.sender] -= sacrificeAmount;
                        //emit log("SACRIFICE AMT");
                        //emit log_uint(sacrificeAmount);
                        //King gets half of the sacrifice
                        //sacrifice only todo
                        if(kingOfShinar != address(0) && _balances[kingOfShinar] >= kingOfShinarTokenAmount){
                            uint taxAmtKing = sacrificeAmount * 500 / 1000;
                            _balances[kingOfShinar] += taxAmtKing;
                            emit Transfer(msg.sender, kingOfShinar, taxAmtKing);
                        }

                        //Chad gets other half of sacrifice
                        if(currentPrince != address(0) && _balances[currentPrince] >= princeBalanceSnapshot[currentPrince]){
                            uint taxAmtChad = sacrificeAmount * 500 / 1000;
                            _balances[currentPrince] += taxAmtChad;
                            emit Transfer(msg.sender, currentPrince, taxAmtChad);
                        }

                        sacrificedAddresses.push(msg.sender);
                        emit newSacrificed(msg.sender, sacrificeAmount);
                    } else {
                        revert("Low Sacrificed Amount");
                    }
                    
                }

            } else {
                revert("Already Sacrificed!");
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

    //Todo:: 1. Return function view total eth spent on buys
    //Return time until next happy hour
    //Return time 

    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(amount>=10000, "minAmt");
        //Dont tax in swapback or this address or router address
        if(inSwapAndLiquify || sender == address(this) || recipient == address(this) || recipient == routerAddress || sender == routerAddress)
        { 
            //console.log("IN BASIC TRANSFER", sender, recipient, amount);
            return _basicTransfer(sender, recipient, amount); 
        }

        //Swap tax tokens to ETH for distribution (0.1% of supply)
        if(sender != pair && !inSwapAndLiquify && _balances[address(this)] >= _totalSupply / 1000){ swapBack(); }
        
        //Reduce balance from sender
        _balances[sender] -= amount;
 
        //5%/12% buy/sell tax; if you sacrificed tax is 5%/6% forever
        uint256 taxAmount = sacrificed[msg.sender] == 1 
        ? sender==pair 
            ?  amount * 30 / 1000  //on buy  (3%)
            :  amount * 40 / 1000  //on sell (4%)
        : sender==pair
            ?  amount * 40 / 1000  //on buy   (4%)
            :  amount * 90 / 1000; //on sell (9%)
        
        uint256 finalAmount = amount - taxAmount;
        //console.log("FINAL_TRANSFER_AMOUNT", finalAmount, taxAmount);

        if(block.timestamp < startStamp + 15 minutes && recipient != address(this) && recipient != pair) {
            // require(_balances[recipient] + finalAmount <= maxSizePerWallet, "Max Tokens Per Wallet Reached!");

            taxAmount = amount * 100 / 1000;
           
        } else if(block.timestamp < startStamp + 15 minutes && recipient == address(this)){

            taxAmount = amount * 200 / 1000;
        }

        
        //Duration = 30 minutes
        //Start = if current hour % 8 < 1
        uint256 passedTime = block.timestamp - startStamp;
        // uint256 numberOftimesActivated = 0; 
        //console.log("TIME_CALC", passedTime / 8 hours, ">",numberOftimesActivated);
        bool didPassEnoughTime = passedTime / 8 hours > numberOftimesActivated;
        
        if(didPassEnoughTime && !isHappyHourActive) {
            //console.log("HAPPY_HOUR");
            isHappyHourActive = true;
            happyStartStamp = block.timestamp;
        } else if (didPassEnoughTime && isHappyHourActive){
            if(block.timestamp > happyStartStamp + 30 minutes){
                //console.log("MORE_THAN_30_MINS_HAPPY_HOUR");
                isHappyHourActive = false;
                numberOftimesActivated++;
            }
        }

        if(isHappyHourActive && sender == pair) taxAmount = amount * 15 / 1000;


        uint256 taxAmtKing;
        uint256 taxAmtChad;

        if(kingOfShinar != address(0) && _balances[kingOfShinar] >= kingOfShinarTokenAmount){
            taxAmtKing = taxAmount * 100 / 1000;
            _balances[kingOfShinar] += taxAmtKing;
            emit Transfer(sender, kingOfShinar, taxAmtKing);
            //console.log("Transfer To King:", kingOfShinar, taxAmtKing);
        }

        //Check if amount bought qualifies as King Of Shinar
        if(sender == pair && recipient != routerAddress) {
            
                address[] memory path = new address[](2);
                path[0] = WETH;
                path[1] = address(this);

                //>0.3ETH BUYER COMP
                uint ethBuyAmount = IUniswapV2Router02(routerAddress).getAmountsIn(amount,path)[0];
                //console.log("Buy_Amount_ETH", ethBuyAmount);
                address previousChad = currentPrince;
                
                //Record previous buyer to payout tax
                //For previous buyer this swap is considered <next swap>
                if(ethBuyAmount >= 1e15 && recipient != currentPrince){
                    emit newPrince(currentPrince, recipient, taxAmount * 400 / 1000);

                    //New Top Chad
                    currentPrince = recipient;
                    //Record amount bought
                    princeBalanceSnapshot[currentPrince] += finalAmount;
                    //console.log("New Prince Arrived:", previousChad, currentPrince, ethBuyAmount);
                    //console.log("Current Prince Snapshot:", princeBalanceSnapshot[currentPrince]);
                }

                //Biggest ETH Spender is King: Collects 1% of tax from all swaps
                //Must sacrifice first before becoming a King
                uint256 ethSpentThisBuy = sacrificed[recipient] != 0 ? ethBuyAmount : 0;
                // //console.log("SACRIFICED_BAL", sacrificed[recipient], toAdd);
                totalETHSpent[recipient] += ethSpentThisBuy;

                //console.log(totalETHSpent[recipient], "Total ETH SPENT", recipient);

                if(totalETHSpent[recipient] > kingOfShinarAmount && sacrificed[recipient] != 0 && kingOfShinar != recipient) {
                    //New King
                    emit newKingOfShinar(kingOfShinar, recipient, kingOfShinarAmount+ethBuyAmount);
                    kingOfShinar = recipient;
                    kingOfShinarAmount = ethBuyAmount;
                    kingOfShinarTokenAmount = finalAmount;
                    //emit log("NEWKING");
                    //emit log_address(kingOfShinar);
                }

                //Check if previous chad didnt sell his tokens
                if(previousChad != address(0) && _balances[previousChad] >= princeBalanceSnapshot[previousChad]){
                    //emit log("Prince Payment On Buy");

                    taxAmtChad = taxAmount * 400 / 1000;
                    //emit log_uint(taxAmtChad);
                    //emit log("TaxAmt CHAD");
                    _balances[previousChad] += taxAmtChad;
                    emit Transfer(pair, previousChad, taxAmtChad);
                }
              
            //Is sell => give tax to current chad
        } else if(recipient == pair){
                // require(sacrificed[sender] != 0 && sacrificed[sender] <= amount, "Can't sell more than sacrificed amount at once");
                //Check if current chad didnt sell his tokens
                if(currentPrince != address(0) && _balances[currentPrince] >= princeBalanceSnapshot[currentPrince]){
                    taxAmtChad = taxAmount * 400 / 1000;
                    _balances[currentPrince] += taxAmtChad;
                    emit Transfer(sender, currentPrince, taxAmtChad);
                }

        }
        
        //For later swapback
        uint256 taxForContract = taxAmount - (taxAmtChad + taxAmtKing);
        _balances[address(this)] += taxForContract;
        emit Transfer(sender, address(this), taxForContract);

        //Final Recieved Amount
        _balances[recipient] += finalAmount;
        emit Transfer(sender, recipient, finalAmount);

         
        return true;
    }

    //Swap back Tokens for ETH
    function swapBack() internal lockTheSwap {
        //emit log("IN SWAPBACK");
        //50% of Tokens added as LP
        //50% of Tokens sold for ETH for LP
        uint256 forLP = _balances[address(this)] / 2;
        bool isEarlyPhase  = block.timestamp < startStamp + 15 minutes;
        if(isEarlyPhase) {
            forLP = _balances[address(this)] / 5; //20%
        }
        //Swap tokens for ETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        uint256 swapAmt = _balances[address(this)] - forLP;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmt,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 ethToAdd = isEarlyPhase ? address(this).balance - (address(this).balance / 4) : address(this).balance;
        //Add 50% of ETH as LP
        //Add 50% of Tokens as LP
        //console.log("ETH_TO_ADD_LP", ethToAdd);
        (,,uint256 gotLP) = router.addLiquidityETH{value: ethToAdd}(
            address(this),
            forLP,
            0,
            0,
            address(this),
            block.timestamp
        );

        //10%F
        // initialLP += gotLP/10;
        //console.log("GOT_LP_TOKENS", gotLP);
        IERC20(pair).transfer(marketingAddress,gotLP/10);
        payable(marketingAddress).transfer(address(this).balance);
        //Burn the swap amount from pair
        _balances[pair] -= (swapAmt+forLP);
        _balances[address(this)] = 1 wei;
        _balances[0x0000000000000000000000000000000000000001] += swapAmt;

        //Must be updated when burning tokens from the pair.
        IPair(pair).sync();
        emit Transfer(pair, address(0), swapAmt);

        bool earlyPhase = startStamp + 17 minutes > block.timestamp;
         
        //Perfrom LP removal for buy-back and burn
        if(!earlyPhase) {
            if(firstTimeLP == 0 && block.timestamp >= lastPumpStamp + 3 hours) {
                //console.log("removing 10%lp");

                pumpFromLockedLP(100);
                firstTimeLP = 1;
            } else if(block.timestamp >= lastPumpStamp + 3 hours) {
                //console.log("removing 5%lp");
                pumpFromLockedLP(50);
            }
        }
        
    }

    function pumpFromLockedLP(uint256 perc) internal {
        //Removes % of 'flowing liquidity' from this contract LP Tokens
        //emit log("InLPREMOVE");
        uint256 burnLPAmt = IERC20(pair).balanceOf(address(this)) * perc / 1000;
        
        //Set cooldown
        lastPumpStamp = block.timestamp;

        uint256 wethBefore = IERC20(WETH).balanceOf(address(this));
        uint256 tokensBefore = _balances[address(this)];

        //Remove LP 
        IERC20(pair).transfer(pair, burnLPAmt);
        IPair(pair).burn(address(this));

        //How much ETH and Tokens we got from removed LP ?
        uint256 wethGot = IERC20(WETH).balanceOf(address(this)) - wethBefore;
        //console.log("WETH RECEIVED_LPREMOVAL",wethGot);
        uint256 tokensGot = _balances[address(this)] - tokensBefore;
        uint256 marketingTax = wethGot/10; //10%
        
        //Marketing Tax
        wethGot -= marketingTax;
        IWETH(WETH).withdraw(marketingTax);
        payable(marketingAddress).transfer(address(this).balance);

        //Reduce balance by tokens amount from removed lp side
        _balances[address(this)] -= tokensGot;
        
        //Swap WETH For Tokens
        //Sends received tokens to burn address
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            wethGot, //50% of ETH from removed LP
            0,
            path,
            0x0000000000000000000000000000000000000002, //swap receiver
            block.timestamp
        );

        uint256 amtToBurn = _balances[0x0000000000000000000000000000000000000002] + tokensGot;

        //Burn!
        _balances[0x0000000000000000000000000000000000000001] += amtToBurn;
        emit Transfer(address(this), 0x0000000000000000000000000000000000000001, amtToBurn);
    }

    address[] sacrificedAddresses;

    function randomAirdropToSacrificed() external {
        require(msg.sender == marketingAddress, "Auth!");
        uint256 length = sacrificedAddresses.length-1;

        //5 last blockhashes
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
        // uint256 randomIndex = 0;
        address winner1 = sacrificedAddresses[randomIndex];
        address winner2;
        address winner3;
        // //console.log(randomIndex); 
        // //console.log(sacrificedAddresses[0], sacrificedAddresses[1],sacrificedAddresses[2]);                         
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

    function tokensLeftForSwapback() external view returns(uint256 amt){
        return _balances[address(this)] >= _totalSupply / 2000 ? 0 : _totalSupply / 2000 - _balances[address(this)];
    }

    function nextLPPumpTimeLeft() public view returns(uint256){
        return block.timestamp >= lastPumpStamp + 3 hours ? 0 : lastPumpStamp + 3 hours - block.timestamp;
    }

    receive() external payable { }
    
}