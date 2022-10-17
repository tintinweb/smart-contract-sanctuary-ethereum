/**
 *Submitted for verification at Etherscan.io on 2022-10-16
*/

/*

*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.17;

library SafeTransferLib {
    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    function safeTransfer(address token, address to, uint256 amount) internal {
        bool success;

        assembly {
            let freeMemoryPointer := mload(0x40)

            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to)
            mstore(add(freeMemoryPointer, 36), amount)

            success := and(
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }
}

abstract contract Auth {
    event OwnershipTransferred(address owner);
    mapping (address => bool) internal authorizations;

    address public owner;
    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!OWNER");
        
        _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); 
        
        _;
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
}

interface IDexFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract DeusXMachina is Auth {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    address WRAP;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    string public name = "Deus X Machina";
    string public symbol = "DeusXMachina";
    uint8 constant public decimals = 4;

    uint256 public totalSupply = 100_000_000 * (10 ** decimals);
    uint256 public max_tx = totalSupply * 10 / 1000;     // 1% of Total Supply initially
    uint256 public max_wallet = totalSupply * 20 / 1000; // 2% of Total Supply initially

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping (address => bool) public isPair;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isLimitExempt;
    
    uint256 public buybackFee = 0;         // 0%
    uint256 public marketingFee = 40;      // 4%
    uint256 public liquidityFee = 60;      // 6%
    uint256 public totalFee;
    uint256 public feeDenominator = 1000;  // 100%
    
    address public liquidityReceiver;
    address public marketingReceiver;

    uint256 launchedAt = 0;

    address public router;
    address public factory;
    address public main_pair;
    address[] public pairs;

    uint256 public smallSwapThreshold = totalSupply / 1000; //0,1%
    uint256 public largeSwapThreshold = totalSupply / 500;  //0,2%
    uint256 public swapThreshold = smallSwapThreshold;
    bool public swapEnabled = true;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        if (block.chainid == 56) { //BSC
            router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //pancake
            factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73; //pancake
            WRAP = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //WBNB
        } else if (block.chainid == 97) { //BSC TESTNET
            router = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; //pancake testnet
            factory = 0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc; //pancake testnet
            WRAP = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; //WBNB testnet
        } else if (block.chainid == 1) { //ETHEREUM
            router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //Uniswap
            factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; //Uniswap
            WRAP = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //ETH
        } else revert();
        allowance[address(this)][address(router)] = type(uint256).max;
        
        main_pair = IDexFactory(factory).createPair(WRAP, address(this));
        pairs.push(main_pair);
        isPair[main_pair] = true;
        
        address deployer = msg.sender;
        marketingReceiver = deployer;
        liquidityReceiver = deployer;
        totalFee = buybackFee + liquidityFee + marketingFee;

        isFeeExempt[deployer] = true;
        isFeeExempt[address(this)] = true;
        isLimitExempt[deployer] = true;
        isLimitExempt[address(this)] = true;
        isLimitExempt[DEAD] = true;
        isLimitExempt[ZERO] = true;
        
        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[deployer] += totalSupply;
        }
        emit Transfer(address(0), deployer, totalSupply);
    }

    receive() external payable {}

    function getCirculatingSupply() public view returns (uint256) {
        return totalSupply - balanceOf[DEAD] - balanceOf[ZERO];
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////// TRANSFER //////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;
        
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        uint256 allowed = allowance[sender][msg.sender];

        if (allowed != type(uint256).max) allowance[sender][msg.sender] = allowed - amount;

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (!launched() && isPair[recipient]) {
            require(balanceOf[sender] > 0);
            require(sender == owner, "Only the owner can be the first to add liquidity.");
            launch();
        }
        if (inSwap) return _basicTransfer(sender, recipient, amount);

        checkTxLimit(sender, recipient, amount);
        if (shouldSwapBack()) swapBack(recipient);

        balanceOf[sender] -= amount;
        uint256 amountReceived = amount;
        
        if (isPair[sender] || isPair[recipient]) {
            amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        }
        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[recipient] += amountReceived;
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        balanceOf[sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[recipient] += amount;
        }

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////// LIMITS //////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        //verify sender max_tx
        require(amount <= max_tx || isPair[sender] && isLimitExempt[recipient] || isLimitExempt[sender], "TRANSACTION_LIMIT_EXCEEDED");

        //verify recipient max_wallet
        if (recipient != owner && !isLimitExempt[recipient] && !isPair[recipient]) {
            uint256 newBalance = balanceOf[recipient] + amount;
            require(newBalance <= max_wallet, "WALLET_LIMIT_EXCEEDED");
        }
    }

    function changeMaxTx(uint256 percent, uint256 denominator) external authorized { 
        require(percent >= 1 && denominator <= 1000, "Max tx must be greater than 0.1%");
        max_tx = totalSupply * percent / denominator;
    }
    
    function changeMaxWallet(uint256 percent, uint256 denominator) external authorized {
        require(percent >= 5 && denominator <= 1000, "Max wallet must be greater than 0.5%");
        max_wallet = totalSupply * percent / denominator;
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsLimitExempt(address holder, bool exempt) external authorized {
        isLimitExempt[holder] = exempt;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////// FEE ///////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient] && totalFee > 0;
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = 0;
        
        //normal fee
        feeAmount = amount * totalFee / feeDenominator;
        
        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[address(this)] += feeAmount;
        }

        emit Transfer(sender, address(this), feeAmount);
        return amount - feeAmount;
    }

    function resetFees() external authorized {
        buybackFee = 0;         //0%
        liquidityFee = 60;      //6%
        marketingFee = 40;      //4%
        totalFee = buybackFee + liquidityFee + marketingFee;
        feeDenominator = 1000;  //100%
    }

    function adjustFees(uint256 _buybackFee, uint256 _liquidityFee, uint256 _marketingFee, uint256 _feeDenominator) external authorized {
        buybackFee = _buybackFee;
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        totalFee = _buybackFee + _liquidityFee + _marketingFee;
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator / 5); // totalFee must be less than 20%
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external authorized {
        liquidityReceiver = _autoLiquidityReceiver;
        marketingReceiver = _marketingFeeReceiver;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////// CONTRCT SWAP ////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function shouldSwapBack() internal view returns (bool) {
        return !isPair[msg.sender] && !inSwap && swapEnabled && totalFee > 0 && balanceOf[address(this)] >= swapThreshold;
    }

    function swapBack(address pair_factory) internal swapping {
        if (pair_factory == main_pair) {
            uint256 amountToLiquify = swapThreshold * liquidityFee / totalFee / 2;
            uint256 amountToSwap = swapThreshold - amountToLiquify;

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = WRAP;

            (bool success,) = router.call{gas : gasleft()}(
                //swapExactTokensForETHSupportingFeeOnTransferTokens(uint256,uint256,address[],address,uint256)
                abi.encodeWithSelector(
                    0x791ac947,
                    amountToSwap,
                    0,
                    path,
                    address(this),
                    block.timestamp
                )
            );

            uint256 amountBNB = address(this).balance;
            uint256 amountBNBLiquidity = amountBNB / 3;
            
            if (amountToLiquify > 0) {
                (success,) = router.call{gas : gasleft(), value: amountBNBLiquidity}(
                    //addLiquidityETH(address,uint256,uint256,uint256,address,uint256)
                    abi.encodeWithSelector(
                        0xf305d719,
                        address(this),
                        amountToLiquify,
                        0,
                        0,
                        liquidityReceiver,
                        block.timestamp
                    )
                );

                require(success, "SWAPBACK_FAILED");
            }

            SafeTransferLib.safeTransferETH(marketingReceiver, address(this).balance);
        }

        swapThreshold = swapThreshold == smallSwapThreshold ? largeSwapThreshold : smallSwapThreshold;
    }

    function setSwapBackSettings(bool _enabled, uint256 _smallAmount, uint256 _largeAmount) external authorized {
        require(_smallAmount <= totalSupply * 25 / 10000, "Small swap threshold must be lower"); // smallSwapThreshold  <= 0,25% of Total Supply initially
        require(_largeAmount <= totalSupply * 5 / 1000, "Large swap threshold must be lower");   // largeSwapThreshold  <= 0,5% of Total Supply initially

        swapEnabled = _enabled;
        smallSwapThreshold = _smallAmount;
        largeSwapThreshold = _largeAmount;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////// OTHERS /////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function updateTokenDetails(string memory newName, string memory newSymbol) external authorized {
        name = newName;
        symbol = newSymbol;
    }

	function rescue() external authorized {
        SafeTransferLib.safeTransferETH(marketingReceiver, address(this).balance);
    }

    function rescueToken(address _token) external authorized {
        require(_token != address(this), "STOP");

        (, bytes memory balance) = address(_token).call(abi.encodeWithSignature('balanceOf(address)', address(this)));
        uint256 amount = abi.decode(balance, (uint256));

        require(amount > 0, "No tokens");
        SafeTransferLib.safeTransfer(_token, marketingReceiver, amount);
    }

    function createPair(address token) external authorized {
        address new_pair = IDexFactory(factory).createPair(token, address(this));
        isPair[main_pair] = true;

        pairs.push(new_pair);
    }

    function showPairList() public view returns(address[] memory){
        return pairs;
    }
}