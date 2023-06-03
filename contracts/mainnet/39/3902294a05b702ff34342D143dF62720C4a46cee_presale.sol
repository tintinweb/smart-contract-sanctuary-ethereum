/**
 *Submitted for verification at Etherscan.io on 2023-06-03
*/

//SPDX-License-Identifier: MIT Licensed
pragma solidity ^0.8.10;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(address from, address to, uint256 value) external;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract presale {
    IERC20 public Token;
    IERC20 public USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    AggregatorV3Interface public priceFeeD;

    address payable public owner;

    uint256 public tokenPerUsd = 83.33 ether;
    uint256 public totalUsers;
    uint256 public soldToken;
    uint256 public ResetTokenForstage;
    uint256 public totalSupply = 400_000_000 ether;
    uint256 public tokenForSell = 57_142_857 ether;
    uint256 public NextStagePrice = 50 ether;
    uint256 public StageCount = 1;
    uint256 public minBuyInUsdt = 100 * 1e6;
    uint256 public minBuyInEth = 0.052790 ether;
    uint256 public amountRaised;
    uint256 public amountRaisedUSDT;
    uint256 public amountRaisedForStage;
    uint256 public amountRaisedUSDTForStage;
    address payable public fundReceiver;

    uint256 public constant divider = 100;

    bool public presaleStatus;
    bool public enableClaim;

    struct user {
        uint256 native_balance;
        uint256 usdt_balance;
        uint256 token_balance;
        uint256 claimed_token;
    }

    mapping(address => user) public users;
    mapping(address => uint256) public wallets;

    modifier onlyOwner() {
        require(msg.sender == owner, "PRESALE: Not an owner");
        _;
    }

    event BuyToken(address indexed _user, uint256 indexed _amount);
    event ClaimToken(address indexed _user, uint256 indexed _amount);
    event UpdatePrice(uint256 _oldPrice, uint256 _newPrice);
    event UpdateBonusValue(uint256 _oldValue, uint256 _newValue);
    event UpdateRefPercent(uint256 _oldPercent, uint256 _newPercent);
    event UpdateMinPurchase(
        uint256 _oldMinNative,
        uint256 _newMinNative,
        uint256 _oldMinUsdt,
        uint256 _newMinUsdt
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        fundReceiver = payable(0x81977cf2e9Ac85b51B289399ADdEB71e73cDc7a6);
        Token = IERC20(0xfB298521359F8239C2941f93Bd2d40ecfE6a2dc5);
        owner = payable(msg.sender);
        priceFeeD = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        presaleStatus = false;
    }

    receive() external payable {}

    // to get real time price of Eth
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeeD.latestRoundData();
        return uint256(price);
    }

    // to buy token during preSale time with Eth => for web3 use

    function buyToken() public payable {
        require(
            presaleStatus == true,
            "$DETA : Presale is Paused, check back later"
        );
        require(msg.value >= minBuyInEth, "Amount is less than minimum Buy");

        uint256 numberOfTokens;
        numberOfTokens = NativeToToken(msg.value);
        soldToken = soldToken + (numberOfTokens);
        ResetTokenForstage = ResetTokenForstage + (numberOfTokens);
        require(
            ResetTokenForstage <= tokenForSell,
            "Low $DETA in pool, Try less amount or wait for next stage"
        );
        amountRaised = amountRaised + (msg.value);

        users[msg.sender].native_balance =
            users[msg.sender].native_balance +
            (msg.value);
        users[msg.sender].token_balance =
            users[msg.sender].token_balance +
            (numberOfTokens);
    }

    // to buy token during preSale time with USDT => for web3 use
    function buyTokenUSDT(uint256 amount) public {
        require(
            presaleStatus == true,
            "$DETA : Presale is Paused, check back later"
        );
        require(amount >= minBuyInUsdt, "Amount is less than minimum Buy");
        USDT.transferFrom(msg.sender, fundReceiver, amount);

        uint256 numberOfTokens;
        numberOfTokens = usdtToToken(amount);

        soldToken = soldToken + (numberOfTokens);
        ResetTokenForstage = ResetTokenForstage + (numberOfTokens);
        require(
            ResetTokenForstage <= tokenForSell,
            "Low $DETA in pool, Try less amount or wait for next stage"
        );
        amountRaisedUSDT = amountRaisedUSDT + (amount);

        users[msg.sender].usdt_balance += amount;

        users[msg.sender].token_balance =
            users[msg.sender].token_balance +
            (numberOfTokens);
    }

    // Claim bought tokens
    function claimTokens() external {
        require(enableClaim == true, "Presale : Claim not active yet");
        require(users[msg.sender].token_balance != 0, "Presale: 0 to claim");

        user storage _usr = users[msg.sender];

        Token.transferFrom(owner, msg.sender, _usr.token_balance);
        _usr.claimed_token += _usr.token_balance;
        _usr.token_balance -= _usr.token_balance;

        emit ClaimToken(msg.sender, _usr.token_balance);
    }

    function EnableClaim(bool _state) external onlyOwner {
        enableClaim = _state;
    }

    function PresaleStatus(bool _off) external onlyOwner {
        presaleStatus = _off;
    }

    // to check number of token for given Eth
    function NativeToToken(uint256 _amount) public view returns (uint256) {
        uint256 EthToUsd = (_amount * (getLatestPrice())) / (1 ether);
        uint256 numberOfTokens = (EthToUsd * (tokenPerUsd)) / (1e8);
        return numberOfTokens;
    }

    // to check number of token for given usdt
    function usdtToToken(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = (_amount * (tokenPerUsd)) / (1e6);
        return numberOfTokens;
    }

    // to change Price of the token
    function changePrice(
        uint256 _price,
        uint256 _tokenForSell,
        uint256 _ResetTokenForstage,
        uint256 _amountRaisedForStage,
        uint256 _amountRaisedUsdtForStage,
        uint256 _nextStagePrice,
        uint256 _StageCount
    ) external onlyOwner {
        uint256 oldPrice = tokenPerUsd;
        tokenPerUsd = _price;

        tokenForSell = _tokenForSell;
        NextStagePrice = _nextStagePrice;
        ResetTokenForstage = _ResetTokenForstage;
        amountRaisedForStage = _amountRaisedForStage;
        amountRaisedUSDTForStage = _amountRaisedUsdtForStage;
        StageCount = _StageCount;

        emit UpdatePrice(oldPrice, _price);
    }

    function ChangeSupply(
        uint256 _supply,
        uint256 _sold,
        uint256 _raised,
        uint256 _raisedInUsdt
    ) external onlyOwner {
        totalSupply = _supply;
        soldToken = _sold;
        amountRaised = _raised;
        amountRaisedUSDT = _raisedInUsdt;
    }

    function ChangeMinimumBuy(
        uint256 _minimumInUsdt,
        uint256 _minimumInEth
    ) external onlyOwner {
        minBuyInUsdt = _minimumInUsdt;
        minBuyInEth = _minimumInEth;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        require(
            _newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        address _oldOwner = owner;
        owner = _newOwner;

        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    // change tokens
    function changeToken(address _token) external onlyOwner {
        Token = IERC20(_token);
    }

    //change USDT
    function changeUSDT(address _USDT) external onlyOwner {
        USDT = IERC20(_USDT);
    }

    // to draw funds for liquidity
    function initiateTransfer(uint256 _value) external onlyOwner {
        fundReceiver.transfer(_value);
    }

    // to draw funds for liquidity
    function changeFundReciever(address _addr) external onlyOwner {
        fundReceiver = payable(_addr);
    }

    // to draw out tokens
    function transferTokens(IERC20 token, uint256 _value) external onlyOwner {
        token.transfer(msg.sender, _value);
    }

    function BSCbuyers(
        address[] memory wallet,
        uint256[] memory amount
    ) public onlyOwner {
        require(wallet.length == amount.length, "Invalid data length");
        for (uint256 i = 0; i < wallet.length; i++) {
            wallets[wallet[i]] += amount[i];
        }
    }

    function ClaimForBSC() public {
        require(enableClaim == true, "Presale : Claim not active yet");
        require(wallets[msg.sender] > 0, "already claimed");
        Token.transferFrom(owner, msg.sender, wallets[msg.sender] * 1e18);
        wallets[msg.sender] = 0;
    }
}