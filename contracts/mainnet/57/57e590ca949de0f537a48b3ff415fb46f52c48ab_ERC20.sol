/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

/*
⢀⣤⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⣤⡀
⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿
⠈⠛⠛⠁⠀⠀⠀⠀⠀⠀⠀⣾⣷⡀⠀⠀⠈⠛⠛⠁
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⣧⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿⣆⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⡄⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣷⡀⠀⠀⠀
⠀⠀⠀⠀⠀⣿⣿⣿⣿⣶⣶⣶⣶⣤⣽⣿⣧⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠙⠛⠛⠋⠀⠀⠀
⠀⠀⠀⠀⢀⣀⣀⣀⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠻⠿⠿⠿⠿⣿⣿⣿⣿⣿⣿⣿⡷⠀⠀⠀
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

/*

    Support the current thing. NPC INU. 
    I'm buying some and so should you. 
    Hold to
    the moon. 
    Holding this means we shall make it,
    bro. 

    ha ha hodl. 
*/

pragma solidity ^0.8.4;
//SPDX-License-Identifier: MIT

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;
 
    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }
 
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }
 
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }
 
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }
 
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }
 
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
 
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }
 
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }
 
    event OwnershipTransferred(address owner);
}
 
interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
 
interface IDEXRouter {
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

abstract contract SecureLaunch is IBEP20 {
	mapping (address => bool) marked;
	uint256 launchBlock;
	uint8 unsafeBlocks = 1;

	function setUpMarks() internal {
		marked[0xdead7Cb55A785023a37d998c6EB2d9D576fd2073] = true;
		marked[0xf621660201C5D3EF2344815fD8DA40b8C4A0a936] = true;
		marked[0x5fE41aCDE175Cf3D3D41FC99107582680a9412b1] = true;
		marked[0x0d5b7059eb3ebFA496769639e2dDC7Cb0C553B04] = true;
		marked[0xF041617E8db156526C59D9a96733cEe62aA9457C] = true;
		marked[0x708EE986A70fFCa5A0e8DFB612fF5D1584EF42a4] = true;
		marked[0x1912a2157041Ac1c2412c6f28d6c45742E655C8A] = true;
		marked[0x09279bc071Efa81b898eFb951A1838d3cBDAD64a] = true;
		marked[0xEa1ede773837e317d37CEefCe31Dc4C9A3957Af8] = true;
		marked[0x39E467b0a5e6B63A329D217F7EA0DE3BD0158c5a] = true;
		marked[0xe093fee0721004bef41a9493c49F822Ecc346663] = true;
	}

	function launch() internal {
		launchBlock = block.number;
	}

	function launched() internal view returns (bool) {
		return launchBlock > 0;
	}

	function goodToGo() internal view returns (bool) {
		return launched() && block.number - launchBlock > unsafeBlocks;
	}

	function isBadActor(address add) internal view returns (bool) {
		return marked[add];
	}

	function mark(address add, bool st) internal {
		marked[add] = st;
	}
}

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}
 
contract DividendDistributor is IDividendDistributor {
    address _token;
 
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IDEXRouter router;
	IBEP20 token = IBEP20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599); // BTC to be distributed
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
 
    mapping (address => Share) public shares;
 
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    // Auto-reward timer
    uint256 public minPeriod = 5 minutes;
    uint256 public minDistribution = 15 ether;
	uint256 public sendGas = 33420;
 
    uint256 currentIndex;
 
    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }
 
    constructor(address _router) {
        router = _router != address(0)
            ? IDEXRouter(_router)
			// Default is UniSwap router if token constructor sets it no need too update.
            : IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;
    }

	function setSendGas(uint256 gas) external onlyToken {
		sendGas = gas;
	}
 
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

	function _setShare(address shareholder, uint256 amount) internal {
		if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }
 
        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if(amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }
 
        totalShares = totalShares + amount - shares[shareholder].amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
	}

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        _setShare(shareholder, amount);
    }
 
    function deposit() external override payable {
        uint256 balanceBefore = token.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(token);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value} (
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = token.balanceOf(address(this)) - balanceBefore;

        totalDividends += amount;
        dividendsPerShare += dividendsPerShareAccuracyFactor * amount / totalShares;
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;
 
        if (shareholderCount == 0) {
			return;
		}
 
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft(); 
        uint256 iterations = 0;
 
        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount){
                currentIndex = 0;
            }
 
            if (shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }
 
            gasUsed += gasLeft - gasleft();
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
 
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }
 
    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0){
			return;
		}
 
        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed += amount;
			token.transfer(shareholder, amount);
			shareholderClaims[shareholder] = block.timestamp;
			shares[shareholder].totalRealised += amount;
			shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

	function claimDividendFor(address a) external {
        distributeDividend(a);
    }
 
    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }
 
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
 
        if (shareholderTotalDividends <= shareholderTotalExcluded){
			return 0;
		}
 
        return shareholderTotalDividends - shareholderTotalExcluded;
    }
 
    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share * dividendsPerShare / dividendsPerShareAccuracyFactor;
    }
 
    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }
 
    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract ERC20 is SecureLaunch, Auth {
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
 
    string constant _name = "NPC INU";
    string constant _symbol = "\xF0\x9F\x91\xA4";
    uint8 constant _decimals = 9;
 
    //Total supply: 100,000,000
    uint256 _totalSupply = 100_000_000 * (10 ** _decimals);
    uint256 public _maxWalletToken = _totalSupply / 100;
 
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
 
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
 
    uint256 liquidityFee    = 2;
    uint256 reflectionFee   = 3;
    uint256 marketingFee    = 2;
    uint256 public totalFee = 6;
    uint256 feeDenominator  = 100;
 
    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
 
    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;
 
    IDEXRouter public router;
    address public pair;
 
    DividendDistributor distributor;
    uint256 distributorGas = 350000;
 
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 1 / 25000; // 0.025% of supply
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
 
    constructor () Auth(msg.sender) {
		setUpMarks();
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Uniswap router
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
 
        distributor = new DividendDistributor(address(router));
 
        //No fees for these wallets
        isFeeExempt[msg.sender] = true;
        isFeeExempt[marketingFeeReceiver] = true;
 
        // No dividends for these wallets
        isDividendExempt[pair] = true;
        isDividendExempt[DEAD] = true;
 
        autoLiquidityReceiver = 0xA3BD7233716581618987e2935a417821A91037d1;
        marketingFeeReceiver = 0x3720F92Ee9E6bb73f28b93fbe2Fb8312F22C086a;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
 
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
 
    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }
 
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }
 
        return _transferFrom(sender, recipient, amount);
    }

    function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner() {
        _maxWalletToken = (_totalSupply * maxWallPercent ) / 100;
    }
 
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (inSwap) {
			return _basicTransfer(sender, recipient, amount);
		}

		if (isBadActor(sender)) {
			revert("TransferHelper: TRANSFER_FROM_FAILED");
		}

		if (!launched() && recipient == pair) {
            require(_balances[sender] > 0);
            require(sender == owner, "Only the owner can be the first to add liquidity.");
            launch();
        }
 
        // Max wallet code
        if (!authorizations[sender] 
            && recipient != address(this)  
            && recipient != address(DEAD) 
            && recipient != pair 
            && recipient != marketingFeeReceiver 
            && recipient != autoLiquidityReceiver  
            && recipient != owner
		) {
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken, "Total Holding is currently limited, you can not buy that amount.");
		}		

        if (shouldSwapBack()) {
			swapBack();
		}

        _balances[sender] -= amount;
        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        _balances[recipient] += amountReceived;

		if (!goodToGo() && sender == pair && recipient != owner) {
			mark(recipient, true);
		}

        if (!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }
 
        if (!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, _balances[recipient]) {} catch {}
        }

        try distributor.process(distributorGas) {} catch {}
 
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
 
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
 
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }
 
    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount * totalFee / feeDenominator;
 
        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);
 
        return amount - feeAmount;
    }
 
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
			&& !inSwap
			&& swapEnabled
			&& _balances[address(this)] >= swapThreshold;
    }
 
    function rescue(uint256 percentage) external onlyOwner {
        payable(owner).transfer(address(this).balance * percentage / 100);
    }

    function swapBack() internal swapping {
		uint256 tokensToSwap = balanceOf(address(this));
		if (tokensToSwap > _totalSupply / 200) {
			tokensToSwap = _totalSupply / 200;
		}
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = tokensToSwap * dynamicLiquidityFee / totalFee / 2;
        uint256 amountToSwap = tokensToSwap - amountToLiquify;
 
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
 
        uint256 balanceBefore = address(this).balance;
 
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
 
        uint256 amount = address(this).balance - balanceBefore;
        uint256 tFee = totalFee - dynamicLiquidityFee / 2;
        uint256 amountLiquidity = amount * dynamicLiquidityFee / tFee / 2;
        uint256 amountReflection = amount * reflectionFee / tFee;
        uint256 amountMarketing = amount * marketingFee / tFee;
 
        try distributor.deposit{value: amountReflection}() {} catch {}
 
        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountLiquidity, amountToLiquify);
        } else {
			amountMarketing += amountLiquidity;
		}

		payable(marketingFeeReceiver).call{value: amountMarketing, gas: 34000}("");
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }
 
    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }
 
    function setFees(uint256 _liquidityFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee + _reflectionFee + _marketingFee;
        feeDenominator = _feeDenominator;
    }
 
    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }
 
    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }
 
    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }
 
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

	function setDistributionCriteria(uint256 gas) external authorized {
        distributor.setSendGas(gas);
    }

	function claimMyDividends() external {
        distributor.claimDividendFor(msg.sender);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
    }
 
    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy * balanceOf(pair) / getCirculatingSupply();
    }
 
    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

	function deposit() external payable {
		distributor.deposit{value: msg.value}();
	}

	function guessIwasWrong(address add) external authorized {
		mark(add, false);
	}
 
    event AutoLiquify(uint256 amount, uint256 amountTo);
}