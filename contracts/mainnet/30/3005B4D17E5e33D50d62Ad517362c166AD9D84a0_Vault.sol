// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/uniswapv2.sol";
import "./interfaces/iparaswap.sol";

import "./interfaces/oneinch.sol";

contract Vault is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    string public vaultName;
    bool public isForPartner;

    address public quoteToken;
    address public baseToken;

    address public strategist;
    mapping(address => bool) public whiteList;

    uint256 public maxCap = 0;
    uint256 public position = 0; // 0: closed, 1: opened
    uint256 public soldAmount = 0;
    uint256 public profit = percentMax;

    // path backward for the pancake
    address[] private pathBackward;
        
    address public constant oneInchRouterAddr = 0x1111111254fb6c44bAC0beD2854e76F90643097d;

    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    address public constant pancakeRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // mainnet v2 (uniswap router v2)
    address public constant sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F; // mainnet v2 

    address public constant ubxt = 0x8564653879a18C560E7C0Ea0E084c516C62F5653; // mainnet

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // mainnet

    uint256 public constant pancakeswapSlippage = 10;

    uint256 private constant MAX = (10 ** 18) * (10 ** 18);
        
    uint256 public constant SWAP_MIN = 10 ** 6;

    uint16 public constant percentMax = 10000;

    // percent values for the fees
    uint16 public pctDeposit = 45;
    uint16 public pctWithdraw = 100;

    uint16 public pctPerfBurning = 250;
    uint16 public pctPerfStakers = 250;
    uint16 public pctPerfAlgoDev = 500;
    uint16 public pctPerfUpbots = 500;
    uint16 public pctPerfPartners = 1000;

    uint16 public pctTradUpbots = 8;

    // address for the fees
    address public addrStakers;
    address public addrAlgoDev;
    address public addrUpbots;
    address public addrPartner;

    address public addrFactory;

    event Received(address, uint);
    event FundTransfer(address, uint256);
    event ParameterUpdated(address, address, address, address, uint16, uint16, uint256);
    event StrategistAddressUpdated(address);
    event PartnerAddressUpdated(address);
    event WhiteListAdded(address);
    event WhiteListRemoved(address);
    event TradeDone(uint256, uint256, uint256, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    constructor(
        string memory _name,
        address _quoteToken, 
        address _baseToken, 
        address _strategist,
        address _addrStakers,
        uint16 _pctDeposit,
        uint16 _pctWithdraw,
        uint16 _pctTradUpbots,
        uint256 _maxCap
    )
        ERC20(
            string(abi.encodePacked("xUBXT_", _name)), 
            string(abi.encodePacked("xUBXT_", _name))
        )
    {
        require(_quoteToken != address(0));
        require(_baseToken != address(0));
        require(_strategist != address(0));
        require(_addrStakers != address(0));

        require(_pctDeposit < percentMax, "_pctDeposit not valid");
        require(_pctWithdraw < percentMax, "_pctWithdraw not valid");
        require(_pctTradUpbots < percentMax, "_pctTradUpbots not valid");

        vaultName = _name;

        addrStakers = _addrStakers;
        
        pctDeposit = _pctDeposit;
        pctWithdraw = _pctWithdraw;
        pctTradUpbots = _pctTradUpbots;

        maxCap = _maxCap;

        isForPartner = false;

        strategist = _strategist;
        whiteList[_strategist] = true;

        quoteToken = _quoteToken;
        baseToken = _baseToken;


        pathBackward = new address[](2);
        pathBackward[0] = baseToken;
        pathBackward[1] = quoteToken;

        addrFactory = msg.sender;
        
        // allow tokens for oneinch token transfer proxy
        approveTokensForOneinch();
    }

    function setParameters(
        address _addrStakers,
        address _addrAlgoDev,
        address _addrUpbots,
        address _addrPartner,        
        uint16 _pctPerfAlgoDev,
        uint16 _pctPerfPartner,
        uint256 _maxCap
    ) external {
        require(msg.sender == strategist, "Not strategist");

        require(_addrStakers != address(0));
        require(_addrAlgoDev != address(0));
        require(_addrUpbots != address(0));

        require(_pctPerfAlgoDev < percentMax, "_pctPerfAlgoDev not valid");
        require(_pctPerfPartner < percentMax, "_pctPerfPartner not valid");

        addrStakers = _addrStakers;
        addrAlgoDev = _addrAlgoDev;
        addrUpbots = _addrUpbots;
        addrPartner = _addrPartner;
        
        pctPerfAlgoDev = _pctPerfAlgoDev;
        pctPerfPartners = _pctPerfPartner;

        maxCap = _maxCap;

        isForPartner = _addrPartner != address(0);

        emit ParameterUpdated(addrStakers, addrAlgoDev, addrUpbots, addrPartner, pctPerfAlgoDev, pctPerfPartners, maxCap);
    }

    function poolSize() public view returns (uint256) {
        return
            (IERC20(quoteToken).balanceOf(address(this)) + _calculateQuoteFromBase());
    }

    function addToWhiteList(address _address) external {
        require(msg.sender == strategist, "Not strategist");
        require(_address != address(0));
        whiteList[_address] = true;
        emit WhiteListAdded(_address);
    }

    function removeFromWhiteList(address _address) external {
        require(msg.sender == strategist, "Not strategist");
        require(_address != address(0));
        whiteList[_address] = false;
        emit WhiteListRemoved(_address);
    }

    function setStrategist(address _address) external {
        require(msg.sender == strategist, "Not strategist");
        require(_address != address(0));
        whiteList[_address] = true;
        strategist = _address;
        emit StrategistAddressUpdated(_address);
    }

    function setPartnerAddress(address _address) external {
        require(msg.sender == strategist, "Not strategist");
        require(_address != address(0));
        addrPartner = _address;
        emit PartnerAddressUpdated(_address);
    }

    function resetTrade() external {
        require(msg.sender == strategist, "Not strategist");

        // 1. swap all baseToken to quoteToken
        uint256 amount = IERC20(baseToken).balanceOf(address(this));
        if (amount > 10**6) {
            _swapPancakeswap(baseToken, quoteToken, amount);
        }

        // 2. reset profit calculation
        profit = percentMax;
        soldAmount = 0;

        // 3. reset position
        position = 0;
    }

    function resetTradeOneinch(bytes memory swapCalldata) external {
        
        require(msg.sender == strategist, "Not strategist");

        // 1. swap all baseToken to quoteToken
        (bool success,) = oneInchRouterAddr.call(swapCalldata);
        
        if (!success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // 2. reset profit calculation
        profit = percentMax;
        soldAmount = 0;

        // 3. reset position
        position = 0;
    }

    function depositQuote(uint256 amount) external nonReentrant {
        if (isContract(msg.sender)) {
            require(whiteList[msg.sender], "Not whitelisted SC");
        }

        // 1. Check max cap
        uint256 _pool = poolSize();
        require (maxCap == 0 || _pool + amount < maxCap, "The vault reached the max cap");

        // 2. transfer quote from sender to this vault
        uint256 _before = IERC20(quoteToken).balanceOf(address(this));
        IERC20(quoteToken).safeTransferFrom(msg.sender, address(this), amount);
        uint256 _after = IERC20(quoteToken).balanceOf(address(this));
        amount = _after - _before; // Additional check for deflationary tokens

        // 3. pay deposit fees
        amount = takeDepositFees(quoteToken, amount);

        // 4. swap Quote to Base if position is opened
        if (position == 1) {
            soldAmount = soldAmount + amount;

            _before = IERC20(baseToken).balanceOf(address(this));
            _swapPancakeswap(quoteToken, baseToken, amount);
            _after = IERC20(baseToken).balanceOf(address(this));
            amount = _after - _before;

            _pool = _before;
        }

        // 5. calculate share and send back xUBXT
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = amount;
        }
        else {
            shares = amount * totalSupply() / _pool;
        }
        _mint(msg.sender, shares);
    }

    function depositBase(uint256 amount) external nonReentrant {
        if (isContract(msg.sender)) {
            require(whiteList[msg.sender], "Not whitelisted SC");
        }


        // 1. Check max cap
        uint256 _pool = poolSize();
        uint256[] memory amounts = UniswapRouterV2(pancakeRouter).getAmountsOut(amount, pathBackward);
        uint256 expectedQuote = amounts[amounts.length - 1];
        require (maxCap == 0 || _pool + expectedQuote < maxCap, "The vault reached the max cap");

        // 2. transfer base from sender to this vault
        uint256 _before = IERC20(baseToken).balanceOf(address(this));
        IERC20(baseToken).safeTransferFrom(msg.sender, address(this), amount);
        uint256 _after = IERC20(baseToken).balanceOf(address(this));
        amount = _after - _before; // Additional check for deflationary tokens

        // 3. pay deposit fees
        amount = takeDepositFees(baseToken, amount);

        _pool = _before;
        // 4. swap Base to Quote if position is closed
        if (position == 0) {
            _before = IERC20(quoteToken).balanceOf(address(this));
            _swapPancakeswap(baseToken, quoteToken, amount);
            _after = IERC20(quoteToken).balanceOf(address(this));
            amount = _after - _before;

            _pool = _before;
        }

        // update soldAmount if position is opened
        if (position == 1) {
            soldAmount = soldAmount + expectedQuote;
        }

        // 5. calculate share and send back xUBXT
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = amount;
        } else {
            shares = amount * totalSupply() / _pool;
        }
        _mint(msg.sender, shares);
    }

    function withdraw(uint256 shares) external nonReentrant  {

        require (shares <= balanceOf(msg.sender), "Invalid share amount");

        if (position == 0) {

            uint256 amountQuote = IERC20(quoteToken).balanceOf(address(this)) * shares / totalSupply();
            if (amountQuote > 0) {
                // pay withdraw fees
                amountQuote = takeWithdrawFees(quoteToken, amountQuote);
                IERC20(quoteToken).safeTransfer(msg.sender, amountQuote);
            }
        }

        if (position == 1) {

            uint256 amountBase = IERC20(baseToken).balanceOf(address(this)) * shares / totalSupply();
            uint256[] memory amounts = UniswapRouterV2(pancakeRouter).getAmountsOut(amountBase, pathBackward);
            
            uint256 thisSoldAmount = soldAmount * shares / totalSupply();
            uint256 _profit = profit * amounts[amounts.length - 1] / thisSoldAmount;
            if (_profit > percentMax) {

                uint256 profitAmount = amountBase * (_profit - percentMax) / _profit;
                uint256 feeAmount = takePerfFeesFromBaseToken(profitAmount);
                amountBase = amountBase - feeAmount;
            }
            soldAmount = soldAmount - thisSoldAmount;
            
            if (amountBase > 0) {
                // pay withdraw fees
                amountBase = takeWithdrawFees(baseToken, amountBase);
                IERC20(baseToken).safeTransfer(msg.sender, amountBase);
            }
        }

        // burn these shares from the sender wallet
        _burn(msg.sender, shares);

    }

    function buy() external nonReentrant {
        // 0. check whitelist
        require(whiteList[msg.sender], "Not whitelisted");

        // 1. Check if the vault is in closed position
        require(position == 0, "Not valid position");

        // 2. get the amount of quoteToken to trade
        uint256 amount = IERC20(quoteToken).balanceOf(address(this));
        require (amount > 0, "No enough amount");

        // 3. takeTradingFees
        uint256 feeAmount = calcTradingFee(amount);
        amount = takeTradingFees(quoteToken, amount, feeAmount);

        // 4. save the remaining to soldAmount
        soldAmount = amount;

        // 5. swap tokens to B
        _swapPancakeswap(quoteToken, baseToken, amount);

        // 6. update position
        position = 1;
    }

    function sell() external nonReentrant {
        // 0. check whitelist
        require(whiteList[msg.sender], "Not whitelisted");

        // 1. check if the vault is in open position
        require(position == 1, "Not valid position");

        // 2. get the amount of baseToken to trade
        uint256 amount = IERC20(baseToken).balanceOf(address(this));

        if (amount > 0) {

            // 3. takeUpbotsFee
            uint256 feeAmount = calcTradingFee(amount);
            amount = takeTradingFees(baseToken, amount, feeAmount);

            // 3. swap tokens to Quote and get the newly create quoteToken
            uint256 _before = IERC20(quoteToken).balanceOf(address(this));
            _swapPancakeswap(baseToken, quoteToken, amount);
            uint256 _after = IERC20(quoteToken).balanceOf(address(this));
            amount = _after - _before;

            // 4. calculate the profit in percent
            profit = profit * amount / soldAmount;

            // 5. take performance fees in case of profit
            if (profit > percentMax) {

                uint256 profitAmount = amount * (profit - percentMax) / profit;
                takePerfFees(profitAmount);
                profit = percentMax;
            }
        }

        // 6. update soldAmount
        soldAmount = 0;

        // 7. update position
        position = 0;
    }

    function buyOneinchByParams(
        IOneInchAggregationExecutor oneInchCaller,
        OneInchSwapDescription calldata oneInchDesc,
        bytes calldata oneInchData
    ) external nonReentrant {
        // 0. check whitelist
        require(whiteList[msg.sender], "Not whitelisted");

        require(oneInchRouterAddr != address(0));
        require(oneInchDesc.dstReceiver == address(this), "Not valid dstReceiver");

        // 1. Check if the vault is in closed position
        require(position == 0, "Not valid position");

        // 2. get the amount of quoteToken to trade
        uint256 quoteAmount = IERC20(quoteToken).balanceOf(address(this));
        require (quoteAmount > 0, "No enough quoteAmount");
        require(quoteAmount == oneInchDesc.amount, "Not valid amount");

        // 3. calc quote fee amount
        uint256 quoteFeeAmount = calcTradingFee(quoteAmount);

        // 4. save the remaining to soldAmount
        soldAmount = quoteAmount - quoteFeeAmount;

        // 5. swap tokens to B
        uint256 _before = IERC20(baseToken).balanceOf(address(this));
        IOneInchAggregationRouterV4 oneInchRouterV4 = IOneInchAggregationRouterV4(oneInchRouterAddr);
        (uint256 returnAmount, ) = oneInchRouterV4.swap(oneInchCaller, oneInchDesc, oneInchData);
        
        if (returnAmount == 0) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        uint256 _after = IERC20(baseToken).balanceOf(address(this));

        // 6. takeTradingFees
        uint256 baseAmount = _after - _before;
        uint256 baseFeeAmount = calcTradingFee(baseAmount);
        takeTradingFees(baseToken, baseAmount, baseFeeAmount);

        // 6. update position
        position = 1;

        // emit event        
        emit TradeDone(position, quoteAmount, quoteFeeAmount, profit);
    }

    function sellOneinchByParams(
        IOneInchAggregationExecutor oneInchCaller,
        OneInchSwapDescription calldata oneInchDesc,
        bytes calldata oneInchData
    ) external nonReentrant {
        
        // 0. check whitelist
        require(whiteList[msg.sender], "Not whitelisted");

        require(oneInchRouterAddr != address(0));
        require(oneInchDesc.dstReceiver == address(this), "Not valid dstReceiver");

        // 1. check if the vault is in open position
        require(position == 1, "Not valid position");

        // 2. get the amount of baseToken to trade
        uint256 baseAmount = IERC20(baseToken).balanceOf(address(this));

        require (baseAmount > 0, "No enough baseAmount");
        require(baseAmount == oneInchDesc.amount, "Not valid amount");


        // 3. calc base fee amount
        uint256 baseFeeAmount = calcTradingFee(baseAmount);

        // 4. swap tokens to Quote and get the newly create quoteToken
        uint256 _before = IERC20(quoteToken).balanceOf(address(this));
        IOneInchAggregationRouterV4 oneInchRouterV4 = IOneInchAggregationRouterV4(oneInchRouterAddr);
        (uint256 returnAmount, ) = oneInchRouterV4.swap(oneInchCaller, oneInchDesc, oneInchData);

        if (returnAmount == 0) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        uint256 _after = IERC20(quoteToken).balanceOf(address(this));

        // 5. takeUpbotsFee
        uint256 quoteAmount = _after - _before;
        uint256 quoteFeeAmount = calcTradingFee(quoteAmount);
        uint256 amount = takeTradingFees(quoteToken, quoteAmount, quoteFeeAmount);

        // 5. calculate the profit in percent
        profit = profit * amount / soldAmount;

        // 6. take performance fees in case of profit
        if (profit > percentMax) {

            uint256 profitAmount = amount * (profit - percentMax) / profit;
            takePerfFees(profitAmount);
            profit = percentMax;
        }

        // 7. update soldAmount
        soldAmount = 0;

        // 8. update position
        position = 0;

        // emit event
        emit TradeDone(position, baseAmount, baseFeeAmount, profit);
    }

    function takeDepositFees(address token, uint256 amount) private returns(uint256) {
        
        if (amount == 0) {
            return 0;
        }

        if (!isForPartner) {
            return amount;
        }

        uint256 fees = amount * pctDeposit / percentMax;
        IERC20(token).safeTransfer(addrPartner, fees);
        return amount - fees;
    }
    
    function takeWithdrawFees(address token, uint256 amount) private returns(uint256) {
        
        if (amount == 0) {
            return 0;
        }

        if (!isForPartner) {
            return amount;
        }

        uint256 fees = amount * pctWithdraw / percentMax;
        IERC20(token).safeTransfer(addrPartner, fees);
        return amount - fees;
    }

    function calcTradingFee(uint256 amount) internal view returns(uint256) {
        return amount * pctTradUpbots / percentMax;
    }

    function takeTradingFees(address token, uint256 amount, uint256 fee) private returns(uint256) {
        if (amount == 0) {
            return 0;
        }

        // swap to UBXT
        uint256 _before = IERC20(ubxt).balanceOf(address(this));
        _swapToUBXT(token, fee);
        uint256 _after = IERC20(ubxt).balanceOf(address(this));
        uint256 ubxtAmt = _after - _before;

        // transfer to company wallet
        IERC20(ubxt).safeTransfer(addrUpbots, ubxtAmt);
        
        // return remaining token amount 
        return amount - fee;
    }
    
    function takePerfFees(uint256 amount) private {
        if (amount == 0) {
            return ;
        }

        // calculate fees
        uint256 burnAmount = amount * pctPerfBurning / percentMax;
        uint256 stakersAmount = amount * pctPerfStakers / percentMax;
        uint256 devAmount = amount * pctPerfAlgoDev / percentMax;
        uint256 pctCompany = isForPartner ? pctPerfPartners : pctPerfUpbots;
        address addrCompany = isForPartner ? addrPartner : addrUpbots;
        uint256 companyAmount = amount * pctCompany / percentMax;
        
        // swap to UBXT
        uint256 _total = stakersAmount + devAmount + burnAmount + companyAmount;
        uint256 _before = IERC20(ubxt).balanceOf(address(this));
        _swapToUBXT(quoteToken, _total);
        uint256 _after = IERC20(ubxt).balanceOf(address(this));
        uint256 ubxtAmt = _after - _before;

        // calculate UBXT amounts
        stakersAmount = ubxtAmt * stakersAmount / _total;
        devAmount = ubxtAmt * devAmount / _total;
        companyAmount = ubxtAmt * companyAmount / _total;
        burnAmount = ubxtAmt - stakersAmount - devAmount - companyAmount;

        // Transfer
        IERC20(ubxt).safeTransfer(
            burnAddress, // burn
            burnAmount
        );
        
        IERC20(ubxt).safeTransfer(
            addrStakers, // stakers
            stakersAmount
        );

        IERC20(ubxt).safeTransfer(
            addrAlgoDev, // algodev
            devAmount
        );

        IERC20(ubxt).safeTransfer(
            addrCompany, // company (upbots or partner)
            companyAmount
        );
    }

    function takePerfFeesFromBaseToken(uint256 amount) private returns(uint256) {

        if (amount == 0) {
            return 0;
        }

        // calculate fees
        uint256 burnAmount = amount * pctPerfBurning / percentMax;
        uint256 stakersAmount = amount * pctPerfStakers / percentMax;
        uint256 devAmount = amount * pctPerfAlgoDev / percentMax;
        
        // swap to UBXT
        uint256 _total = stakersAmount + devAmount + burnAmount;
        uint256 _before = IERC20(ubxt).balanceOf(address(this));
        uint256 _tokenbBefore = IERC20(baseToken).balanceOf(address(this));
        _swapToUBXT(baseToken, _total);
        uint256 _after = IERC20(ubxt).balanceOf(address(this));
        uint256 _tokenbAfter = IERC20(baseToken).balanceOf(address(this));
        
        uint256 ubxtAmt = _after - _before;
        uint256 feeAmount = _tokenbBefore - _tokenbAfter;

        // calculate UBXT amounts
        stakersAmount = ubxtAmt * stakersAmount / _total;
        devAmount = ubxtAmt * devAmount / _total;
        burnAmount = ubxtAmt - stakersAmount - devAmount;

        // Transfer
        IERC20(ubxt).safeTransfer(
            burnAddress,
            burnAmount
        );
        
        IERC20(ubxt).safeTransfer(
            addrStakers,
            stakersAmount
        );

        IERC20(ubxt).safeTransfer(
            addrAlgoDev,
            devAmount
        );

        return feeAmount;
    }

    // *** internal functions ***

    function _calculateQuoteFromBase() internal view returns(uint256) {
        uint256 amountBase = IERC20(baseToken).balanceOf(address(this));

        if (amountBase < SWAP_MIN) {
            return 0;
        }
        uint256[] memory amounts = UniswapRouterV2(pancakeRouter).getAmountsOut(amountBase, pathBackward);
        return amounts[amounts.length - 1];
    }

    function approveTokensForOneinch() internal {
        assert(IERC20(quoteToken).approve(oneInchRouterAddr, MAX));
        assert(IERC20(baseToken).approve(oneInchRouterAddr, MAX));
    }

    function _swapPancakeswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        // Swap with uniswap
        assert(IERC20(_from).approve(pancakeRouter, 0));
        assert(IERC20(_from).approve(pancakeRouter, _amount));

        address[] memory path;

        path = new address[](2);
        path[0] = _from;
        path[1] = _to;

        uint256[] memory amountOutMins = UniswapRouterV2(pancakeRouter).getAmountsOut(
            _amount,
            path
        );
        uint256 amountOutMin = amountOutMins[path.length -1].mul(100 - pancakeswapSlippage).div(100);

        uint256[] memory amounts = UniswapRouterV2(pancakeRouter).swapExactTokensForTokens(
            _amount,
            amountOutMin,
            path,
            address(this),
            block.timestamp + 60
        );

        require(amounts[0] > 0, "Not valid return amount in pancakeswap");
    }
    
    // _to is supposed to be UBXT
    // _from is quote token or base token (we assume quote token is USDC)
    function _swapToUBXT(
        address _from,
        uint256 _amount
    ) internal {

        // Swap with uniswap
        assert(IERC20(_from).approve(sushiRouter, 0));
        assert(IERC20(_from).approve(sushiRouter, _amount));

        address[] memory path;

        if (_from == WETH) {
            path = new address[](2);
            path[0] = _from;
            path[1] = ubxt;
        } 
        else if (_from == quoteToken) {
            path = new address[](3);
            path[0] = _from;
            path[1] = WETH;
            path[2] = ubxt;
        }
        else {
            path = new address[](4);
            path[0] = _from;
            path[1] = quoteToken;
            path[2] = WETH;
            path[3] = ubxt;
        }

        uint256[] memory amountOutMins = UniswapRouterV2(sushiRouter).getAmountsOut(
            _amount,
            path
        );
        uint256 amountOutMin = amountOutMins[path.length -1].mul(100 - pancakeswapSlippage).div(100);

        uint256[] memory amounts = UniswapRouterV2(sushiRouter).swapExactTokensForTokens(
            _amount,
            amountOutMin,
            path,
            address(this),
            block.timestamp + 60
        );

        require(amounts[0] > 0, "Not valid return amount in pancakeswap");
    }

    // Send remanining BNB (used for paraswap integration) to other wallet
    function fundTransfer(address receiver, uint256 amount) external {
        require(msg.sender == strategist, "Not strategist");
        require(receiver != address(0));

        // payable(receiver).transfer(amount);
        (bool sent, ) = receiver.call{value: amount}("");
        require(sent, "Failed to send Fund");

        emit FundTransfer(receiver, amount);
    }

    function isContract(address _addr) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface UniswapRouterV2 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import "./lib/utils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IParaswap {
    event Swapped(
        bytes16 uuid,
        address initiator,
        address indexed beneficiary,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 receivedAmount,
        uint256 expectedAmount
    );

    event Bought(
        bytes16 uuid,
        address initiator,
        address indexed beneficiary,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 receivedAmount
    );

    event FeeTaken(
        uint256 fee,
        uint256 partnerShare,
        uint256 paraswapShare
    );

    function multiSwap(
        Utils.SellData calldata data
    )
        external
        payable
        returns (uint256);

    function megaSwap(
        Utils.MegaSwapSellData calldata data
    )
        external
        payable
        returns (uint256);

    function protectedMultiSwap(
        Utils.SellData calldata data
    )
        external
        payable
        returns (uint256);

    function protectedMegaSwap(
        Utils.MegaSwapSellData calldata data
    )
        external
        payable
        returns (uint256);

    function protectedSimpleSwap(
        Utils.SimpleData calldata data
    )
        external
        payable
        returns (uint256 receivedAmount);

    function protectedSimpleBuy(
        Utils.SimpleData calldata data
    )
        external
        payable;

    function simpleSwap(
        Utils.SimpleData calldata data
    )
        external
        payable
        returns (uint256 receivedAmount);

    function simpleBuy(
        Utils.SimpleData calldata data
    )
        external
        payable;

    function swapOnUniswap(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    )
        external
        payable;

    function swapOnUniswapFork(
        address factory,
        bytes32 initCode,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    )
        external
        payable;

    function buyOnUniswap(
        uint256 amountInMax,
        uint256 amountOut,
        address[] calldata path
    )
        external
        payable;

    function buyOnUniswapFork(
        address factory,
        bytes32 initCode,
        uint256 amountInMax,
        uint256 amountOut,
        address[] calldata path
    )
        external
        payable;

    function swapOnUniswapV2Fork(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address weth,
        uint256[] calldata pools
    )
        external
        payable;

    function buyOnUniswapV2Fork(
        address tokenIn,
        uint256 amountInMax,
        uint256 amountOut,
        address weth,
        uint256[] calldata pools
    )
        external
        payable;

    function swapOnZeroXv2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 amountOutMin,
        address exchange,
        bytes calldata payload
    )
    external
    payable;

    function swapOnZeroXv4(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 amountOutMin,
        address exchange,
        bytes calldata payload
    )
    external
    payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for CHI gas token
interface IOneInchChi is IERC20 {
    function mint(uint256 value) external;
    function free(uint256 value) external returns (uint256 freed);
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

interface IOneInchGasDiscountExtension {
    function calculateGas(uint256 gasUsed, uint256 flags, uint256 calldataLength) external view returns (IOneInchChi, uint256);
}

interface IOneInchAggregationExecutor is IOneInchGasDiscountExtension {
    /// @notice Make calls on `msgSender` with specified data
    function callBytes(address msgSender, bytes calldata data) external payable;  // 0x2636f7f8
}

struct OneInchSwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
}

interface IOneInchAggregationRouterV4 {

    /// @notice Performs a swap, delegating all calls encoded in `data` to `caller`. See tests for usage examples
    /// @param caller Aggregation executor that executes calls described in `data`
    /// @param desc Swap description
    /// @param data Encoded calls that `caller` should execute in between of swaps
    /// @return returnAmount Resulting token amount
    /// @return gasLeft Gas left
    function swap(
        IOneInchAggregationExecutor caller,
        OneInchSwapDescription calldata desc,
        bytes calldata data
    )
        external
        payable
        returns (uint256 returnAmount, uint256 gasLeft);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

library Utils {
    /**
   * @param fromToken Address of the source token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   * @param expectedAmount Expected amount of destination tokens without slippage
   * @param beneficiary Beneficiary address
   * 0 then 100% will be transferred to beneficiary. Pass 10000 for 100%
   * @param path Route to be taken for this swap to take place

   */
    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Path[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct MegaSwapSellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.MegaSwapPath[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct SimpleData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address[] callees;
        bytes exchangeData;
        uint256[] startIndexes;
        uint256[] values;
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct Adapter {
        address payable adapter;
        uint256 percent;
        uint256 networkFee;
        Route[] route;
    }

    struct Route {
        uint256 index;//Adapter at which index needs to be used
        address targetExchange;
        uint percent;
        bytes payload;
        uint256 networkFee;//Network fee is associated with 0xv3 trades
    }

    struct MegaSwapPath {
        uint256 fromAmountPercent;
        Path[] path;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee;//Network fee is associated with 0xv3 trades
        Adapter[] adapters;
    }
}