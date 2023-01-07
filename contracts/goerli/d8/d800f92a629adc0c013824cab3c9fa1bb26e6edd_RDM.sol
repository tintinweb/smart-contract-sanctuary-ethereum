/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

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


contract RDM is Context, IERC20, IERC20Metadata {

    IUniswapV2Router02 internal router;

    address internal pair;
    address internal WETH;
    address internal routerAddress;
    address internal _owner;
    address public topChad;
    address public stETH;

    uint256 public topChadAmount;
    uint256 public lastRebaseStamp;
    uint256 public lastPumpStamp;
    uint256 public topChadBeginTime;
    uint256 private _totalSupply;
    uint256 public maxSizePerWallet;
    uint256 public startStamp;
    uint256 internal initialLP;
    bool internal inSwapAndLiquify;

    string private _name;
    string private _symbol;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event TopChadRebase(address _topChad, uint256 _randomPercent, uint256 tokensAdded);

    constructor(address owner) payable {
        _name = "FFF";
        _symbol = "FFF";

        routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        // stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
        stETH = 0x1643E812aE58766192Cf7D2Cf9567dF2C37e9B7F;
        router = IUniswapV2Router02(routerAddress);
        WETH = router.WETH();
        pair = IUniswapV2Factory(router.factory()).createPair(WETH, address(this));

        //Initial supply
        _mint(address(this), 100000e18);
        _mint(msg.sender, 10000e18);

        //Approvals
        IERC20(pair).approve(routerAddress, type(uint256).max);
        IERC20(WETH).approve(routerAddress, type(uint256).max);
        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[msg.sender][address(router)] = type(uint256).max;
        
        //Initial reserve
        IWETH(WETH).deposit{value: msg.value}();

        _owner = owner;
        maxSizePerWallet = 1000;
        startStamp = block.timestamp;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = stETH;
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            IERC20(WETH).balanceOf(address(this)),
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLPAndAllowExchange() public payable {
        // (,,uint gotLp) = router.addLiquidityETH{value: msg.value}(
        router.addLiquidityETH{value: msg.value}(
            address(this),
            100000e18,
            0,
            0,
            address(this),
            block.timestamp
        );
        // IERC20(pair).transfer(_owner, gotLp/10);
        lastPumpStamp = block.timestamp;
        // initialLP = IERC20(pair).balanceOf(address(this)) / 4;
        // initialLP = gotLp;
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
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
        //Auto-redeem if you transfer tokens to yourself
        //Minimum 1 token
        if(msg.sender == to && amount >= 1e18) {
            redeemForETH(amount);
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
    bool public isSwitched = false;
    function flipWalletSize() external {
        isSwitched=!isSwitched;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(amount>=100, "minAmt");
        //Dont tax in swapback or this address or router address
        if(inSwapAndLiquify || sender == address(this) || recipient == address(this) || recipient == routerAddress || sender == routerAddress){ return _basicTransfer(sender, recipient, amount); }
        //Swap tax tokens to ETH for distribution (0.1% of supply)
        if(sender != pair && !inSwapAndLiquify && _balances[address(this)] >= _totalSupply / 1000){ swapBack(); }
        
        _balances[sender] -= amount;

        //Tax & Final transfer amounts
        uint256 taxAmount = amount / 20;
        uint256 finalAmount = amount - taxAmount;

        _balances[recipient] += finalAmount;
        emit Transfer(sender, recipient, finalAmount);
        
        //Check if amount bought qualifies as Top Chad
        if(sender == pair && recipient != routerAddress && amount > topChadAmount) {
            topChadAmount = finalAmount;
            topChad = recipient;
        }

        // block.timestamp > startStamp + 15 minutes
        if(isSwitched && recipient != address(this) && recipient != pair) {
            require(_balances[recipient] + finalAmount <= maxSizePerWallet, "Max Tokens Per Wallet Reached!");
        } else {
            uint256 taxPartForChad = taxAmount * 40 / 100;

            //Current Top Chad gets 40% of all taxes for 2 HRs
            //He must hold the Top Chad Amount tokens
            if(topChad != address(0) && _balances[topChad]>=topChadAmount) {
                _balances[topChad] += taxPartForChad;
                _balances[address(this)] += taxAmount - taxPartForChad;
                emit Transfer(sender, topChad, taxPartForChad);
                emit Transfer(sender, address(this), taxAmount - taxPartForChad);
            } else { 
                //If there is no Top Chad OR Top Chad sold his tokens early
                //Top Chad Tax part will be burned
                uint256 taxKept = taxAmount - taxPartForChad;
                _balances[address(this)] += taxKept;
                _totalSupply -= taxPartForChad;

                emit Transfer(sender, address(this), taxKept);
                emit Transfer(sender, address(0), taxPartForChad);
            }


            //Top Chad Rebase
            rewardTopChad();
        }

        
       
        return true;
    } 

    //Rebases Positively Top Chad Balance
    //Random 1-5% Rebase
    function rewardTopChad() internal {
        if(topChad != address(0) && block.timestamp >= lastRebaseStamp + 2 hours) {

            uint256 currentBal = _balances[topChad];

            if(currentBal >= topChadAmount){
                
                //Random reward 1-5% balance increase
                uint256 randomPercent = (uint256(
                    keccak256( 
                        abi.encode(
                            blockhash(block.number - 1),
                            blockhash(block.number),
                            block.number,
                            block.timestamp,
                            block.difficulty,
                            currentBal,
                            topChad))) % 5) + 1;

                uint256 addedTokens = currentBal * randomPercent / 100;
                _balances[topChad] += addedTokens;
                _totalSupply += addedTokens;
                emit Transfer(address(0), topChad, addedTokens);
                emit TopChadRebase(topChad,randomPercent,addedTokens);
                //Reset top chad to zero address
                //Tokens to become next top chad are 20% of previous
                topChad = address(0);
                topChadAmount = topChadAmount / 5;
                lastRebaseStamp = block.timestamp;
            }

            //Reset top chad to zero address
            //Tokens to become next top chad are 20% of previous
            topChad = address(0);
            topChadAmount = topChadAmount / 5;
            lastRebaseStamp = block.timestamp;

        }       
    }

    //Swap back Tokens for ETH
    function swapBack() internal lockTheSwap {

        //50% of Tokens added as LP
        //50% of Tokens sold for ETH for LP
        uint256 forLP = (_balances[address(this)]) / 2;
        uint256 swapAmt = _balances[address(this)] - forLP;

        //Swap tokens for ETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmt,
            0,
            path,
            address(this),
            block.timestamp
        );

        //Add 50% of ETH as LP
        //Add 50% of Tokens as LP
        router.addLiquidityETH{value: address(this).balance/2}(
            address(this),
            forLP,
            0,
            0,
            address(this),
            block.timestamp
        );

        //Get WETH from ETH
        IWETH(WETH).deposit{value: address(this).balance}();

        //Burn the swap amount from pair
        _balances[pair] -= swapAmt;
        _balances[address(this)] = 1 wei;
        _totalSupply -= swapAmt;

        //Must be updated when burning tokens from the pair.
        IPair(pair).sync();
        emit Transfer(pair, address(0), swapAmt);

        //Perfrom 2% LP removal for buy-back and burn
        //Once every 2 hours
        if(block.timestamp >= lastPumpStamp + 2 hours) {
            pumpFromLockedLP();
        }
    }

    function pumpFromLockedLP() internal {
        
        //Removes 2% of this contract LP Tokens
        uint256 burnLPAmt = (IERC20(pair).balanceOf(address(this))) / 50;
        
        //Set cooldown
        lastPumpStamp = block.timestamp;

        uint256 wethBefore = IERC20(WETH).balanceOf(address(this));
        uint256 tokensBefore = _balances[address(this)];

        //Remove LP 
        IERC20(pair).transfer(pair, burnLPAmt);
        IPair(pair).burn(address(this));

        //How much ETH and Tokens we got from removed LP ?
        uint256 wethGot = IERC20(WETH).balanceOf(address(this)) - wethBefore;
        uint256 tokensGot = _balances[address(this)] - tokensBefore;

        //Burn Tokens from removed lp side
        _balances[address(this)] -= tokensGot;
        emit Transfer(address(this), address(0), tokensGot);
        
        //Swap WETH For Tokens
        //Sends received tokens to burn address
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            wethGot/2, //50% of ETH from removed LP
            0,
            path,
            0x0000000000000000000000000000000000000001,
            block.timestamp
        );

        uint256 amtToBurn = _balances[0x0000000000000000000000000000000000000001];

        //Burn Tokens from swapback and removed lp
        _totalSupply -= (amtToBurn+tokensGot);
        //Reset router address balance
        _balances[0x0000000000000000000000000000000000000001] = 1 wei;
        emit Transfer(address(this), address(0), tokensGot);
        emit Transfer(0x0000000000000000000000000000000000000001, address(0), amtToBurn);

        //Convert WETH to stETH for reserve
        // address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = stETH;
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            IERC20(WETH).balanceOf(address(this)),
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function redeemForETH(uint256 amt) public lockTheSwap {
        require(inSwapAndLiquify, " ALREADY REDEEMING ");
        require(amt >= 1e18, "Minimum redeem is 1 token!");
        require(_balances[msg.sender] >= amt, "Insufficient Tokens!");

        //Get current price floor per 1 token
        uint256 rate = redeemRate();

        //Burn tokens used to redeem 
        _balances[msg.sender] -= amt;
        _totalSupply -= amt;
        emit Transfer(msg.sender, address(0), amt);

        //Send redeemed ETH
        uint256 sethToSend = amt * rate / 1e18;
        require(sethToSend != 0,"AmountOut");
        IERC20(stETH).transfer(msg.sender, sethToSend);
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

    function getstETHInReserve() public view returns (uint256) {
        return IERC20(stETH).balanceOf(address(this));
    }

    function redeemRate() public view returns(uint256) {
        return getstETHInReserve() * 1e18 / _totalSupply;
    }

    function tokensToRedeemFor1ETH() public view returns(uint256){
        return _totalSupply / getstETHInReserve();
    }

    //in seconds
    function nextRebaseTimeLeft() public view returns(uint256) {
       return block.timestamp >= lastRebaseStamp + 2 hours ? 0 : lastRebaseStamp + 2 hours - block.timestamp;
    }

    function amountToBecomeTopChad() external view returns(uint256 amt){ 
        return (topChadAmount+(5*topChadAmount/100)+1e18)/1e18;
    }

    function tokensLeftForSwapback() external view returns(uint256 amt){
        return _balances[address(this)] >= _totalSupply / 1000 ? 0 : _totalSupply / 1000 - _balances[address(this)];
    }

    receive() external payable { }
    
}