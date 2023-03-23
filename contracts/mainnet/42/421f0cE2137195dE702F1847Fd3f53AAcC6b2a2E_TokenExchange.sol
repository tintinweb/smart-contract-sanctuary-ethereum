/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract TokenExchange {
    address public tokenA;
    address public tokenB;

    uint256 public exchangeBuyRate;
    uint256 public exchangeSellRate;
    uint256 public feeRate;

    address public owner;
    address public rateSetter;
    address public WLSetter;

    uint256 public maxTxBuyAmount = 10000 * 10 ** 18;
    uint256 public maxTxSellAmount = 750000 * 10 ** 18;
    uint256 public minTxBuyAmount = 10 * 10 ** 18;
    uint256 public minTxSellAmount = 750 * 10 ** 18;
    uint256 public buyDecimals = 100; 
    uint256 public sellDecimals = 100;

    bool public WLOn = true;

    mapping(address => bool) public WLAddresses;
    mapping(string => uint256) public taxFeeCollected;

    event Deposit(address _sender, uint256 _amountIn, uint256 _amountOut);
    event TaxFeeWithdrawal(address _owner, address _token, uint256 _amount);

    constructor(address _tokenA, address _tokenB, uint256 _exchangeBuyRate, uint256 _exchangeSellRate, uint256 _feeRate) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        exchangeBuyRate = _exchangeBuyRate;
        exchangeSellRate = _exchangeSellRate;
        feeRate = _feeRate;
        owner = msg.sender;
        rateSetter = msg.sender;
        WLSetter = msg.sender;
    }

    function depositTokenA(uint256 amount) public {
        // WL check
        if (WLOn != false)
        require(WLAddresses[msg.sender] == true, 'You are not in WL!');

        require(amount > 0, "Amount must be greater than zero");
        require(amount <= maxTxBuyAmount && amount >= minTxBuyAmount, "Transaction amount limit");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amount);

        uint256 feeAmount = amount * feeRate / 1000; // calculate fee amount
        uint256 inputAmount = amount - feeAmount; // calculate input amount
        uint256 outputAmount = inputAmount * exchangeBuyRate / buyDecimals; // calculate output amount

        IERC20(tokenB).transfer(msg.sender, outputAmount);

        taxFeeCollected["tokenA"] += feeAmount;
        emit Deposit(msg.sender, amount, outputAmount);
    }

    function depositTokenB(uint256 amount) public {
        // WL check
        if (WLOn != false)
        require(WLAddresses[msg.sender] == true, 'You are not in WL!');

        require(amount > 0, "Amount must be greater than zero");
        require(amount <= maxTxSellAmount && amount >= minTxSellAmount, "Transaction amount limit");

        IERC20(tokenB).transferFrom(msg.sender, address(this), amount);

        uint256 feeAmount = amount * feeRate / 1000; // calculate fee amount
        uint256 inputAmount = amount - feeAmount; // calculate input amount
        uint256 outputAmount = inputAmount / exchangeSellRate * sellDecimals; // calculate output amount

        IERC20(tokenA).transfer(msg.sender, outputAmount);

        taxFeeCollected["tokenB"] += feeAmount;
        emit Deposit(msg.sender, amount, outputAmount);
    }

    // Setting rate for exchange 
    function setExchangeRate(uint256 _exchangeBuyRate, uint256 _exchangeSellRate) public {
        require(msg.sender == rateSetter, "Only rateSetter can call this function");
        require(_exchangeBuyRate > 0, "Rate must be greater than zero");
        require(_exchangeSellRate > 0, "Rate must be greater than zero");

        exchangeBuyRate = _exchangeBuyRate;
        exchangeSellRate = _exchangeSellRate;
    }

    // Setting rate for fee
    function setFeeRate(uint256 _feeRate) public {
        require(msg.sender == owner, "Only owner can call this function");

        feeRate = _feeRate;
    }

    // Setting transaction amount limit
    function setTxAmount(uint256 _maxTxBuyAmount, uint256 _maxTxSellAmount, uint256 _minTxBuyAmount, uint256 _minTxSellAmount) public {
        require(msg.sender == owner, "Only owner can call this function");
        require(_maxTxBuyAmount > 0 && _maxTxSellAmount > 0 && _minTxBuyAmount > 0 && _minTxSellAmount > 0, "Amount must be greater than zero");

        maxTxBuyAmount = _maxTxBuyAmount;
        maxTxSellAmount = _maxTxSellAmount;
        minTxBuyAmount = _minTxBuyAmount;
        minTxSellAmount = _minTxSellAmount;
    }

    // Setting decimals amount
    function setDecimals(uint256 _buyDecimals, uint256 _sellDecimals) public {
        require(msg.sender == owner, "Only owner can call this function");
        require(_buyDecimals > 0 && _sellDecimals > 0, "Amount must be greater than zero");

        buyDecimals = _buyDecimals;
        sellDecimals = _sellDecimals;
    }

    // Set address of exchange rate setter 
    function setRateSetter(address _rateSetter) public {
        require(msg.sender == owner, "Only owner can call this function");

        rateSetter = _rateSetter;
    }

    // Set address of whitelist setter
    function setWLSetter(address _WLSetter) public {
        require(msg.sender == owner, "Only owner can call this function");

        WLSetter = _WLSetter;
    }

    // Turn on or turn off WhiteList
    function WLControl(bool _WLOn) external {
        require(msg.sender == owner, 'Only owner can call this function');

        WLOn = _WLOn;
    }

    // Add addresses to whitelist
    function addToWhitelist(address[] calldata toAddAddresses) public {
        require(msg.sender == WLSetter, "Only WLSetter can call this function");

        for (uint i = 0; i < toAddAddresses.length; i++) {
            WLAddresses[toAddAddresses[i]] = true;
        }
    }

    // Remove addresses from whitelist
    function removeFromWhitelist(address[] calldata toRemoveAddresses) public {
        require(msg.sender == WLSetter, "Only WLSetter can call this function");

        for (uint i = 0; i < toRemoveAddresses.length; i++) {
            delete WLAddresses[toRemoveAddresses[i]];
        }
    }

    // Widthdraw eth from contract
    function withdrawEther() public {
        require(msg.sender == owner, 'Only owner can call this function');

        address payable o = payable(msg.sender);
        o.transfer(address(this).balance);
    }

    // Widthdraw tokens from contract
    function withdrawTokens(address _token, uint256 _amount) public {
        require(msg.sender == owner, 'Only owner can call this function');

        IERC20(_token).transfer(owner, _amount);
    }

    // Widthdraw tax fee amount
    function withdrawTokenATaxFee() public {
        require(msg.sender == owner, 'Only owner can call this function');
        require(taxFeeCollected["tokenA"] > 0, "No tax fee collected");

        uint256 amount = taxFeeCollected["tokenA"];
        taxFeeCollected["tokenA"] = 0;

        IERC20(tokenA).transfer(owner, amount);

        emit TaxFeeWithdrawal(owner, tokenA, amount);
    }

    // Widthdraw tax fee amount
    function withdrawTokenBTaxFee() public {
        require(msg.sender == owner, 'Only owner can call this function');
        require(taxFeeCollected["tokenB"] > 0, "No tax fee collected");

        uint256 amount = taxFeeCollected["tokenB"];
        taxFeeCollected["tokenB"] = 0;

        IERC20(tokenB).transfer(owner, amount);

        emit TaxFeeWithdrawal(owner, tokenB, amount);
    }

    function checkA(uint256 amount) public view returns(uint256) {
        uint256 feeAmount = amount * feeRate / 1000;
        uint256 inputAmount = amount - feeAmount;
        uint256 outputAmount = inputAmount * exchangeBuyRate / buyDecimals;

        return outputAmount;
    }

    function checkB(uint256 amount) public view returns(uint256) {
        uint256 feeAmount = amount * feeRate / 1000;
        uint256 inputAmount = amount - feeAmount;
        uint256 outputAmount = inputAmount / exchangeSellRate * sellDecimals;

        return outputAmount;
    }
}