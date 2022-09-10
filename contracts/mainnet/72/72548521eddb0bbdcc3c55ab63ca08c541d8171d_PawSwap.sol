/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.12;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function mint(address to) external returns (uint liquidity);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Interface of the pawswap factory contract.
 */
interface PawSwapFactory {
    function feeTo() external view returns (address);
}

/**
 * @dev Interface of the tax structure contract.
 */
interface ITaxStructure {
    function routerAddress() external view returns (address);

    // these taxes will be taken as eth
    function tax1Name() external view returns (string memory);
    function tax1Wallet() external view returns (address);
    function tax1BuyAmount(address) external view returns (uint256);
    function tax1SellAmount(address) external view returns (uint256);
    
    function tax2Name() external view returns (string memory);
    function tax2Wallet() external view returns (address);
    function tax2BuyAmount(address) external view returns (uint256);
    function tax2SellAmount(address) external view returns (uint256);
    
    function tax3Name() external view returns (string memory);
    function tax3Wallet() external view returns (address);
    function tax3BuyAmount(address) external view returns (uint256);
    function tax3SellAmount(address) external view returns (uint256);

    function tax4Name() external view returns (string memory);
    function tax4Wallet() external view returns (address);
    function tax4BuyAmount(address) external view returns (uint256);
    function tax4SellAmount(address) external view returns (uint256);

    // this tax will be taken as tokens
    function tokenTaxName() external view returns (string memory);
    function tokenTaxWallet() external view returns (address);
    function tokenTaxBuyAmount(address) external view returns (uint256);
    function tokenTaxSellAmount(address) external view returns (uint256);

    // this tax will send tokens to burn address
    function burnTaxBuyAmount(address) external view returns (uint256);
    function burnTaxSellAmount(address) external view returns (uint256);
    function burnAddress() external view returns (address);

    // this tax will be sent to the LP
    function liquidityTaxBuyAmount(address) external view returns (uint256);
    function liquidityTaxSellAmount(address) external view returns (uint256);
    function lpTokenHolder() external view returns (address);

    // this custom tax will send ETH to a dynamic address
    function customTaxName() external view returns (string memory);

    function feeDecimal() external view returns (uint256);
}

interface OwnableContract {
    function owner() external view returns (address);
}

contract PawSwap is Ownable, ReentrancyGuard {
    struct TaxStruct {
        IERC20 token;
        uint256 tax1;
        uint256 tax2;
        uint256 tax3;
        uint256 tax4;
        uint256 tokenTax;
        uint256 burnTax;
        uint256 liquidityTax;
        uint256 customTax;
        uint256 feeDecimal;
        address router;
        address lpTokenHolder;
    }

    mapping(address => bool) public excludedTokens; // tokens that are not allowed to list
    mapping(address => bool) public listers; // addresses that can list new tokens
    mapping(address => address) public tokenTaxContracts;
    mapping(address => bool) public dexExcludedFromTreasury;

    PawSwapFactory public pawSwapFactory;

    address public pawSwapRouter;
    address public immutable WETH;
    // sets treasury fee to 0.03%
    uint256 public treasuryFee = 3;

    event Buy(
        address indexed buyer,
        address indexed tokenAddress,
        uint256 ethSpent,
        uint256 tokensReceived,
        uint256 customTaxAmount,
        address indexed customTaxAddress
    );

    event Sell(
        address indexed seller,
        address indexed tokenAddress,
        uint256 tokensSold,
        uint256 ethReceived,
        uint256 customTaxAmount,
        address indexed customTaxAddress
    );

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'Pawswap: EXPIRED');
        _;
    }

    constructor (address factory, address router, address weth) {
        WETH = weth;
        PawSwapFactory _factory = PawSwapFactory(factory);
        pawSwapFactory = _factory;
        pawSwapRouter = router;
        dexExcludedFromTreasury[router] = true;
    }

    function processPreSwapBuyTaxes (
        uint256 ethAmount,
        address customTaxAddress,
        TaxStruct memory taxStructure,
        ITaxStructure taxStructureContract
    ) private returns (uint256, uint256, uint256) {
        uint256 ethToSwap = ethAmount;
        uint256 liquidityEth;
        uint256 customTaxSent;

        if (!dexExcludedFromTreasury[taxStructure.router]) {
            // take a treasury fee if we are not using the pawswap dex
            uint256 treasuryEth = ethAmount * treasuryFee / 10**4; // always 4
            ethToSwap -= treasuryEth;
            (bool sent, ) = pawSwapFactory.feeTo().call{value: treasuryEth}("");
            require(sent, "Failed to send eth to treasury");
        }

        if (taxStructure.liquidityTax != 0) {
            // hold onto some eth to pair with tokens for liquidity
            liquidityEth = ethAmount * (taxStructure.liquidityTax / 2) / 10**(taxStructure.feeDecimal + 2);
            ethToSwap -= liquidityEth;
        }

        if (taxStructure.tax1 != 0) {
            // send eth percentage to the tax1 wallet
            uint256 tax1Eth = ethAmount * taxStructure.tax1 / 10**(taxStructure.feeDecimal + 2);
            ethToSwap -= tax1Eth;
            (bool sent, ) = taxStructureContract.tax1Wallet().call{value: tax1Eth}("");
            require(sent, "Failed to send eth to tax1 wallet");
        }

        if (taxStructure.tax2 != 0) {
            // send eth percentage to the tax2 wallet
            uint256 tax2Eth = ethAmount * taxStructure.tax2 / 10**(taxStructure.feeDecimal + 2);
            ethToSwap -= tax2Eth;
            (bool sent, ) = taxStructureContract.tax2Wallet().call{value: tax2Eth}("");
            require(sent, "Failed to send eth to tax2 wallet");
        }
        
        if (taxStructure.tax3 != 0) {
            // send eth percentage to the tax3 wallet
            uint256 tax3Eth = ethAmount * taxStructure.tax3 / 10**(taxStructure.feeDecimal + 2);
            ethToSwap -= tax3Eth;
            (bool sent, ) = taxStructureContract.tax3Wallet().call{value: tax3Eth}("");
            require(sent, "Failed to send eth to tax3 wallet");
        }

        if (taxStructure.tax4 != 0) {
            // send eth percentage to the tax4 wallet
            uint256 tax4Eth = ethAmount * taxStructure.tax4 / 10**(taxStructure.feeDecimal + 2);
            ethToSwap -= tax4Eth;
            (bool sent, ) = taxStructureContract.tax4Wallet().call{value: tax4Eth}("");
            require(sent, "Failed to send eth to tax4 wallet");
        }
        
        if (taxStructure.customTax != 0) {
            // send to the custom tax address
            customTaxSent = ethAmount * taxStructure.customTax / 10**(taxStructure.feeDecimal + 2);
            ethToSwap -= customTaxSent;
            (bool sent, ) = customTaxAddress.call{value: customTaxSent}("");
            require(sent, "Failed to send eth to custom tax wallet");
        }

        return (ethToSwap, liquidityEth, customTaxSent);
    }

    function processPostSwapBuyTaxes(
      IERC20 token,
      uint256 tokensFromSwap,
      uint256 liquidityEth,
      TaxStruct memory taxStruct,
      ITaxStructure taxStructureContract
    ) private returns (uint256) {
        uint256 purchasedTokens = tokensFromSwap;
        uint256 taxDenominator = 10**(taxStruct.feeDecimal + 2) + 1; // +1 makes up for precision errors

        if (taxStruct.liquidityTax != 0) {
            // add to the LP
            uint256 liquidityTokens = tokensFromSwap * (taxStruct.liquidityTax / 2) / taxDenominator;
            purchasedTokens -= liquidityTokens;
            addLiquidity(liquidityTokens, liquidityEth, taxStruct.lpTokenHolder, token, taxStruct.router);
        }

        // burn fee is taken in pawth
        if (taxStruct.burnTax != 0) {
            // send to the pawth burn addr
            uint256 burnTokens = tokensFromSwap * taxStruct.burnTax / taxDenominator;
            purchasedTokens -= burnTokens;
            token.transfer(taxStructureContract.burnAddress(), burnTokens);
        }

        // staking fee is taken in token
        if (taxStruct.tokenTax != 0) {
            // send to the token tax wallet
            uint256 taxTokens = tokensFromSwap * taxStruct.tokenTax / taxDenominator;
            purchasedTokens -= taxTokens;
            token.transfer(taxStructureContract.tokenTaxWallet(), taxTokens);
        }

        return purchasedTokens;
    }

    function executeBuy (
        address tokenAddress,
        uint customTaxAmount, 
        address customTaxAddress, 
        uint256 minTokensToReceive,
        bool isExactIn
    ) private returns (uint256, uint256, uint256) {
        ITaxStructure _taxStructureContract = ITaxStructure(tokenTaxContracts[tokenAddress]);
        TaxStruct memory _taxStruct = getTaxStruct(_taxStructureContract, customTaxAmount, _msgSender(), tokenAddress, true);

        // uses getBuyAmountIn if this is an exact out trade because
        // we should take taxes out based on what the actual buy amount is since
        // the user might give us more eth than necessary -- we only want to tax the
        // amount used to purchased, not the excess eth sent in msg.value
        (uint256 ethToSwap, uint256 liquidityEth, uint256 customTaxSent) = processPreSwapBuyTaxes(
          isExactIn ? msg.value : getBuyAmountIn(_msgSender(), tokenAddress, customTaxAmount, minTokensToReceive),
          customTaxAddress,
          _taxStruct,
          _taxStructureContract
        );

        (uint256 tokensFromSwap, uint256 dustEth) = swapEthForTokens(
          ethToSwap,
          isExactIn ? 0 : addTokenTax(minTokensToReceive, _taxStruct), // this wont get used if IsExactIn is true
          _taxStruct,
          isExactIn
        );

        uint256 purchasedTokens = processPostSwapBuyTaxes(
          _taxStruct.token,
          tokensFromSwap,
          liquidityEth,
          _taxStruct,
          _taxStructureContract
        );

        // require that we met the minimum set by the user
        require (purchasedTokens >= minTokensToReceive, "Insufficient tokens purchased");
        // send the tokens to the buyer
        if (isExactIn) {
            _taxStruct.token.transfer(_msgSender(), purchasedTokens);
            return (purchasedTokens, dustEth, customTaxSent);
        } else {
            _taxStruct.token.transfer(_msgSender(), minTokensToReceive);
            return (minTokensToReceive, dustEth, customTaxSent);
        }
    }

    function buyOnPawSwap (
        address tokenAddress,
        uint customTaxAmount, 
        address customTaxAddress, 
        uint256 minTokensToReceive,
        bool isExactIn
    ) external payable nonReentrant {
        require(tokenTaxContracts[tokenAddress] != address(0), "Token not listed");
        
        (uint256 purchasedTokens, uint256 dustEth, uint256 customTaxSent) = executeBuy(
            tokenAddress,
            customTaxAmount, 
            customTaxAddress, 
            minTokensToReceive,
            isExactIn
        );

        emit Buy(
            _msgSender(),
            tokenAddress,
            isExactIn ? msg.value : msg.value - dustEth, 
            purchasedTokens,
            customTaxSent,
            customTaxAddress
        );
    }

    function addTokenTax (uint256 amount, TaxStruct memory taxStruct) private pure returns (uint256) {
        uint256 percentageTakenPostSwap = (taxStruct.liquidityTax / 2) + taxStruct.burnTax + taxStruct.tokenTax;
        uint256 otherPercentage = 10**(taxStruct.feeDecimal + 2) - percentageTakenPostSwap;
        uint256 minAmount = amount / otherPercentage * (10**(taxStruct.feeDecimal + 2) + 1);

        return minAmount;
    }

    function addEthTax (uint256 amount, TaxStruct memory taxStruct) private view returns (uint256) {
        uint256 percentageTakenPostSwap = (taxStruct.liquidityTax / 2) + taxStruct.tax1 + taxStruct.tax2 + taxStruct.tax3 + taxStruct.tax4 + taxStruct.customTax;
        uint256 otherPercentage = 10**(taxStruct.feeDecimal + 2) - percentageTakenPostSwap;

        if (!dexExcludedFromTreasury[taxStruct.router]) {
            uint256 treasuryTax = amount * treasuryFee / 10**4;
            amount += treasuryTax;
        }

        return amount / otherPercentage * (10**(taxStruct.feeDecimal + 2) + 1);
    }

    function processPreSwapSellTaxes(
        uint256 tokensToSwap,
        TaxStruct memory taxStruct,
        ITaxStructure taxStructureContract
    ) private returns (uint256, uint256) {
        uint256 liquidityTokens;
        uint256 taxDenominator = 10**(taxStruct.feeDecimal + 2) + 1; // +1 makes up for precision errors

        if (taxStruct.liquidityTax != 0) {
            // hold onto some tokens to pair with eth for liquidity
            liquidityTokens = tokensToSwap * (taxStruct.liquidityTax / 2) / taxDenominator;
            tokensToSwap -= liquidityTokens;
        }
    
        // burn fee is taken in pawth
        if (taxStruct.burnTax != 0) {
            // send to the pawth burn addr
            uint256 burnTokens = tokensToSwap * taxStruct.burnTax / taxDenominator;
            taxStruct.token.transfer(taxStructureContract.burnAddress(), burnTokens);
            tokensToSwap -= burnTokens;
        }

        // staking fee is taken in tokens
        if (taxStruct.tokenTax != 0) {
            // send to the token tax wallet
            uint256 taxTokens = tokensToSwap * taxStruct.tokenTax / taxDenominator;
            taxStruct.token.transfer(taxStructureContract.tokenTaxWallet(), taxTokens);
            tokensToSwap -= taxTokens;
        }

        return (tokensToSwap, liquidityTokens);
    }

    function processPostSwapSellTaxes(
      uint256 ethFromSwap,
      address customTaxAddress,
      uint256 liquidityTokens,
      TaxStruct memory taxStruct,
      ITaxStructure taxStructureContract
    ) private returns (uint256, uint256) {
        uint256 ethToTransfer = ethFromSwap;
        uint256 customTaxSent;

        if (taxStruct.tax1 != 0) {
            // send eth percentage to the tax1 wallet
            uint256 tax1Eth = ethFromSwap * taxStruct.tax1 / 10**(taxStruct.feeDecimal + 2);
            ethToTransfer -= tax1Eth;
            (bool sent, ) = taxStructureContract.tax1Wallet().call{value: tax1Eth}("");
            require(sent, "Failed to send eth to tax1 wallet");
        }

        if (taxStruct.tax2 != 0) {
            // send eth percentage to the tax2 wallet
            uint256 tax2Eth = ethFromSwap * taxStruct.tax2 / 10**(taxStruct.feeDecimal + 2);
            ethToTransfer -= tax2Eth;
            (bool sent, ) = taxStructureContract.tax2Wallet().call{value: tax2Eth}("");
            require(sent, "Failed to send eth to tax2 wallet");
        }

        if (taxStruct.tax3 != 0) {
            // send eth percentage to the tax3 wallet
            uint256 tax3Eth = ethFromSwap * taxStruct.tax3 / 10**(taxStruct.feeDecimal + 2);
            ethToTransfer -= tax3Eth;
            (bool sent, ) = taxStructureContract.tax3Wallet().call{value: tax3Eth}("");
            require(sent, "Failed to send eth to tax3 wallet");
        }
    
        if (taxStruct.tax4 != 0) {
            // send eth percentage to the tax4 wallet
            uint256 tax4Eth = ethFromSwap * taxStruct.tax4 / 10**(taxStruct.feeDecimal + 2);
            ethToTransfer -= tax4Eth;
            (bool sent, ) = taxStructureContract.tax4Wallet().call{value: tax4Eth}("");
            require(sent, "Failed to send eth to tax4 wallet");
        }

        if (taxStruct.customTax != 0) {
            // send eth percentage to the tax4 wallet
            customTaxSent = ethFromSwap * taxStruct.customTax / 10**(taxStruct.feeDecimal + 2);
            ethToTransfer -= customTaxSent;
            (bool sent, ) = customTaxAddress.call{value: customTaxSent}("");
            require(sent, "Failed to send eth to tax4 wallet");
        }

        if (!dexExcludedFromTreasury[taxStruct.router]) {
            // take a treasury fee if we are not using the pawswap dex
            uint256 treasuryEth = ethFromSwap * treasuryFee / 10**4; // always 4
            ethToTransfer -= treasuryEth;
            (bool sent, ) = pawSwapFactory.feeTo().call{value: treasuryEth}("");
            require(sent, "Failed to send eth to treasury");
        }

        if (taxStruct.liquidityTax != 0) {
            // add to the LP
            uint256 liquidityEth = ethFromSwap * (taxStruct.liquidityTax / 2) / 10**(taxStruct.feeDecimal + 2);
            ethToTransfer -= liquidityEth;
            addLiquidity(liquidityTokens, liquidityEth, taxStruct.lpTokenHolder, taxStruct.token, taxStruct.router);
        }

        return (ethToTransfer, customTaxSent);
    }

    function executeSell (
        address tokenAddress,
        uint256 tokensSold, 
        uint customTaxAmount, 
        address customTaxAddress, 
        uint minEthToReceive,
        bool isExactIn
    ) private returns (uint256, uint256, uint256) {
        ITaxStructure _taxStructureContract = ITaxStructure(tokenTaxContracts[tokenAddress]);
        TaxStruct memory _taxStruct = getTaxStruct(_taxStructureContract, customTaxAmount, _msgSender(), tokenAddress, false);

        _taxStruct.token.transferFrom(_msgSender(), address(this), tokensSold);
        (uint256 tokensToSwap, uint256 liquidityTokens) = processPreSwapSellTaxes(
          isExactIn ? tokensSold : getSellAmountIn(_msgSender(), tokenAddress, customTaxAmount, minEthToReceive),
          _taxStruct,
          _taxStructureContract
        );

        (uint256 ethFromSwap, uint256 dustTokens) = swapTokensForEth(
          tokensToSwap, 
          addEthTax(minEthToReceive, _taxStruct), // this wont get used if IsExactIn is true
          _taxStruct,
          isExactIn
        );

        (uint256 ethToTransfer, uint256 customTaxSent) = processPostSwapSellTaxes(
          ethFromSwap, 
          customTaxAddress,
          liquidityTokens,
          _taxStruct,
          _taxStructureContract
        );

        // require that we met the minimum set by the user
        require(ethToTransfer >= minEthToReceive, "Insufficient ETH out");
        // send the eth to seller
        uint256 ethTransferred = sendEthToUser(ethToTransfer, minEthToReceive, isExactIn);
        return (ethTransferred, tokensToSwap - dustTokens, customTaxSent);
    }

    function sellOnPawSwap (
        address tokenAddress,
        uint256 tokensSold, 
        uint customTaxAmount, 
        address customTaxAddress, 
        uint minEthToReceive,
        bool isExactIn
    ) external {
        address listedTaxStructContract = tokenTaxContracts[tokenAddress];
        require(listedTaxStructContract != address(0), "Token not listed");

        (uint256 ethToTransfer, uint256 tokensSwapped, uint256 customTaxSent) = executeSell(
            tokenAddress,
            tokensSold, 
            customTaxAmount, 
            customTaxAddress, 
            minEthToReceive,
            isExactIn
        );

        emit Sell(
            _msgSender(),
            tokenAddress,
            isExactIn ? tokensSold : tokensSwapped,
            ethToTransfer,
            customTaxSent,
            customTaxAddress
        );
    }

    function sendEthToUser (uint256 amount, uint256 minEthToReceive, bool isExactIn) private returns (uint256) {
        if (isExactIn) {
            (bool sent, ) = _msgSender().call{value: amount}("");
            require(sent, "Failed to send eth to user");
            return amount;
        } else {
            (bool sent, ) = _msgSender().call{value: minEthToReceive}("");
            require(sent, "Failed to send eth to user");
            return minEthToReceive;
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount, address lpTokenHolder, IERC20 token, address routerAddress) private {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(routerAddress);
        token.approve(address(uniswapV2Router), tokenAmount);

        (uint amountToken, uint amountETH) = _addLiquidity(
            address(token),
            WETH,
            tokenAmount,
            ethAmount,
            uniswapV2Router
        );
        address pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(token), WETH);
        token.transfer(pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        IUniswapV2Pair(pair).mint(lpTokenHolder);
        // refund dust eth, if any
        if (ethAmount > amountETH) {
            (bool sent, ) = _msgSender().call{value: ethAmount - amountETH}("");
            require(sent, "Failed to refund user dust eth after adding liquidity");
        }
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        IUniswapV2Router02 uniswapV2Router
    ) private returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        address pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            IUniswapV2Factory(uniswapV2Router.factory()).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB,) = IUniswapV2Pair(pair).getReserves();
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = uniswapV2Router.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= 0, 'Pawswap: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = uniswapV2Router.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= 0, 'Pawswap: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function swapEthForTokens(
      uint256 ethToSwap,
      uint256 minAmountOut,
      TaxStruct memory taxStruct,
      bool isExactIn
    ) private returns (uint256, uint256) {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(taxStruct.router);
        address [] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(taxStruct.token);

        uint256 initialTokenBalance = taxStruct.token.balanceOf(address(this));
        uint256 dustEth;

        if (isExactIn) {
          // if user specified amount of eth to spend, get as many tokens as possible
          swapExactETHForTokensSupportingFeeOnTransferTokens(
              ethToSwap,
              0,
              path,
              uniswapV2Router
          );
        } else {
          (, dustEth) = swapETHForExactTokens(
              ethToSwap,
              minAmountOut,
              path,
              uniswapV2Router
          );
        }

        return (taxStruct.token.balanceOf(address(this)) - initialTokenBalance, dustEth);
    }

    function swapTokensForEth(
      uint256 tokenAmount,
      uint256 minEthToReceive,
      TaxStruct memory taxStruct,
      bool isExactIn
    ) private returns (uint256, uint256) {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(taxStruct.router);
        address [] memory path = new address[](2);
        path[0] = address(taxStruct.token);
        path[1] = uniswapV2Router.WETH();
        
        taxStruct.token.approve(address(uniswapV2Router), tokenAmount);

        uint256 initialEthBalance = address(this).balance;
        if (isExactIn) {
          swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            uniswapV2Router
          );
        } else {                        
          swapTokensForExactETH(
            minEthToReceive,
            tokenAmount,
            path,
            address(this),
            uniswapV2Router
          );
        }

        return (address(this).balance - initialEthBalance, 0);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        IUniswapV2Router02 uniswapV2Router
    ) internal {
        require(path[path.length - 1] == WETH, 'Pawswap: INVALID_PATH');
        address pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(path[0],path[1]);
        IERC20(path[0]).transfer(pair, amountIn);
        _swapSupportingFeeOnTransferTokens(path, uniswapV2Router);
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'Pawswap: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
    }


    function swapETHForExactTokens(
        uint amountIn, 
        uint amountOut, 
        address[] memory path,
        IUniswapV2Router02 uniswapV2Router
    )
        private
        returns (uint[] memory amounts, uint dustEth)
    {
        require(path[0] == WETH, 'Pawswap: INVALID_PATH');
        amounts = uniswapV2Router.getAmountsIn(amountOut, path);
        require(amounts[0] <= amountIn, 'Pawswap: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        address pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(path[0],path[1]);
        assert(IWETH(WETH).transfer(pair, amounts[0]));
        _swap(amounts, path, pair);
        // refund dust eth, if any
        if (amountIn > amounts[0]) {
            dustEth = amountIn - amounts[0];
            (bool sent, ) = _msgSender().call{value: dustEth}("");
            require(sent, "Failed to refund user dust eth");
        }
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        IUniswapV2Router02 uniswapV2Router
    ) private {
        require(path[0] == WETH, 'Pawswap: INVALID_PATH');
        IWETH(WETH).deposit{value: amountIn}();
        address pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(path[0],path[1]);
        assert(IWETH(WETH).transfer(pair, amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(address(this));
        _swapSupportingFeeOnTransferTokens(path, uniswapV2Router);
        require(
            IERC20(path[path.length - 1]).balanceOf(address(this)) - balanceBefore >= amountOutMin,
            'Pawswap: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] memory path, address to, IUniswapV2Router02 uniswapV2Router)
        private
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'Pawswap: INVALID_PATH');
        amounts = uniswapV2Router.getAmountsIn(amountOut, path);
        require(amounts[0] <= amountInMax, 'Pawswap: EXCESSIVE_INPUT_AMOUNT');
        address pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(path[0],path[1]);
        IERC20(path[0]).transfer(pair, amounts[0]);
        _swap(amounts, path, pair);
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        (bool sent, ) = to.call{value: amounts[amounts.length - 1]}("");
        require(sent, "Failed to send eth to seller");
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _pair) private {
        (address input, address output) = (path[0], path[1]);
        (address token0,) = sortTokens(input, output);
        uint amountOut = amounts[1];
        (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
        IUniswapV2Pair(_pair).swap(
            amount0Out, amount1Out, address(this), new bytes(0)
        );
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, IUniswapV2Router02 uniswapV2Router) private {
        (address input, address output) = (path[0], path[1]);
        (address token0,) = sortTokens(input, output);
        IUniswapV2Pair pair = IUniswapV2Pair(IUniswapV2Factory(uniswapV2Router.factory()).getPair(input, output));
        uint amountInput;
        uint amountOutput;
        { // scope to avoid stack too deep errors
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
        amountOutput = uniswapV2Router.getAmountOut(amountInput, reserveInput, reserveOutput);
        }
        (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'Pawswap: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Pawswap: ZERO_ADDRESS');
    }

    function getTaxStruct(
        ITaxStructure _taxStructureContract,
        uint256 customTaxAmount,
        address _account, 
        address _token, 
        bool isBuy
    ) internal view returns (TaxStruct memory) {
        if (isBuy) {
            return TaxStruct(
                IERC20(_token),
                _taxStructureContract.tax1BuyAmount(_account),
                _taxStructureContract.tax2BuyAmount(_account),
                _taxStructureContract.tax3BuyAmount(_account),
                _taxStructureContract.tax4BuyAmount(_account),
                _taxStructureContract.tokenTaxBuyAmount(_account),
                _taxStructureContract.burnTaxBuyAmount(_account),
                _taxStructureContract.liquidityTaxBuyAmount(_account),
                customTaxAmount,
                _taxStructureContract.feeDecimal(),
                _taxStructureContract.routerAddress(),
                _taxStructureContract.lpTokenHolder()
            );
        } else {
            return TaxStruct(
                IERC20(_token),
                _taxStructureContract.tax1SellAmount(_account),
                _taxStructureContract.tax2SellAmount(_account),
                _taxStructureContract.tax3SellAmount(_account),
                _taxStructureContract.tax4SellAmount(_account),
                _taxStructureContract.tokenTaxSellAmount(_account),
                _taxStructureContract.burnTaxSellAmount(_account),
                _taxStructureContract.liquidityTaxSellAmount(_account),
                customTaxAmount,
                _taxStructureContract.feeDecimal(),
                _taxStructureContract.routerAddress(),
                _taxStructureContract.lpTokenHolder()
            );
        }
    }

    function getBuyAmountIn (
        address buyer,
        address tokenAddress,
        uint customTaxAmount,
        uint minTokensToReceive
    ) public view returns (uint256 amountIn) {
        require(tokenTaxContracts[tokenAddress] != address(0), "Token not listed");
        ITaxStructure _taxStructureContract = ITaxStructure(tokenTaxContracts[tokenAddress]);
        TaxStruct memory _taxStruct = getTaxStruct(_taxStructureContract, customTaxAmount, buyer, tokenAddress, true);

        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(_taxStruct.router);
        address [] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = tokenAddress;

        uint256 [] memory amountsIn = uniswapV2Router.getAmountsIn(
            addTokenTax(minTokensToReceive, _taxStruct),
            path
        );

        return addEthTax(amountsIn[0], _taxStruct);
    }

    function getSellAmountIn (
        address seller,
        address tokenAddress,
        uint customTaxAmount,
        uint minEthToReceive
    ) public view returns (uint256) {
        require(tokenTaxContracts[tokenAddress] != address(0), "Token not listed");
        ITaxStructure _taxStructureContract = ITaxStructure(tokenTaxContracts[tokenAddress]);
        TaxStruct memory _taxStruct = getTaxStruct(_taxStructureContract, customTaxAmount, seller, tokenAddress, false);

        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(_taxStruct.router);
        address [] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = uniswapV2Router.WETH();

        uint256 [] memory amountsIn = uniswapV2Router.getAmountsIn(
            addEthTax(minEthToReceive, _taxStruct),
            path
        );
        return addTokenTax(amountsIn[0], _taxStruct);
    }

    function setTokenTaxContract (address _tokenAddress, address _taxStructureContractAddress) external {
        require (!excludedTokens[_tokenAddress], "Token is not allowed to list");
        require (tokenTaxContracts[_tokenAddress] != _taxStructureContractAddress, "Structure already set to this address");
        // caller must be the pawswap owner, have the listing role, or be the owner of the listed contract
        require (
            listers[_msgSender()] ||
            OwnableContract(_tokenAddress).owner() == _msgSender() ||
            this.owner() == _msgSender(),
            "Permission denied"
        );
        tokenTaxContracts[_tokenAddress] = _taxStructureContractAddress;
    }

    function setListerAccount (address _address, bool isLister) external onlyOwner {
        listers[_address] = isLister;
    }

    function excludeToken (address _tokenAddress, bool isExcluded) external onlyOwner {
        excludedTokens[_tokenAddress] = isExcluded;
    }
    
    function setPawSwapFactory (address _address) external onlyOwner {
        PawSwapFactory _factory = PawSwapFactory(_address);
        pawSwapFactory = _factory;
    }

    function setPawSwapRouter (address _address) external onlyOwner {
        require (pawSwapRouter != _address, "Router already set to this address");
        pawSwapRouter = _address;
    }

    function setTreasuryFee (uint256 _fee) external onlyOwner {
        require (treasuryFee != _fee, "Fee already set to this value");
        require (_fee <= 300, "Fee cannot exceed 3%");
        treasuryFee = _fee;
    }

    function toggleDexExcludedFromTreasuryFee (address _dex, bool _excluded) external onlyOwner {
        dexExcludedFromTreasury[_dex] = _excluded;
    }

    function withdrawEthToOwner (uint256 _amount) external onlyOwner {
        (bool sent, ) = _msgSender().call{value: _amount}("");
        require(sent, "Failed to send eth to owner");
    }

    function withdrawTokenToOwner(address tokenAddress, uint256 amount) external onlyOwner {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance >= amount, "Insufficient token balance");

        IERC20(tokenAddress).transfer(_msgSender(), amount);
    }

    receive() external payable {}
}