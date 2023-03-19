/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

//SPDX-License-Identifier: MIT Licensed
pragma solidity ^0.8.6;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function SupplyPerPhase() external view returns (uint256);

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

    IERC20 public HPO = IERC20(0x2101eA58C52b3D038671BbCB9FAf071d3EB8Cd2a);
    IERC20 public USDT = IERC20(0x7486AaeD4282AaB20E63DEb413829e611Dc70eBA);
    IERC20 public BNB = IERC20(0x02AF47fe467101A7805b7Ab9EF164c8D744522dC);

    AggregatorV3Interface public priceFeedEth;
    AggregatorV3Interface public priceFeedBNB;

    address payable public owner;

    uint256 public tokenPerUsd = 1666 * 1e17;
    uint256 public minmumPurchase = 3332 ether;
    uint256 public referralPercent = 4;
    uint256 public bonusToken = 0;
    uint256 public soldToken;
    uint256 public SupplyPerPhase = 150000000 ether;
    uint256 public amountRaisedEth;
    uint256 public amountRaisedUSDT;
    uint256 public amountRaisedBNB;

    uint256 public constant divider = 100;

    bool public presaleStatus;

    struct user {
        uint256 Eth_balance;
        uint256 Bnb_balance;
        uint256 usdt_balance;
        uint256 token_balance;
        uint256 claimed_token;
    }

    mapping(address => user) public users;

    modifier onlyOwner() {
        require(msg.sender == owner, "PRESALE: Not an owner");
        _;
    }

    event BuyToken(address indexed _user, uint256 indexed _amount);
    event ClaimToken(address indexed _user, uint256 indexed _amount);

    constructor() {
        owner = payable(0x9C62b1f5bE1F7788d341E01B663AA7e8776fe968);
        priceFeedEth = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        priceFeedBNB = AggregatorV3Interface(
            0x14e613AC84a31f709eadbdF89C6CC390fDc9540A
        );
        presaleStatus = true;
    }

    receive() external payable {}

    // to get real time price of Eth
    function getLatestPriceEth() public view returns (uint256) {
        (, int256 price, , , ) = priceFeedEth.latestRoundData();
        return uint256(price);
    }

    // to get real time price of Eth
    function getLatestPriceBnb() public view returns (uint256) {
        (, int256 price, , , ) = priceFeedBNB.latestRoundData();
        return uint256(price);
    }

    // to buy token during preSale time with Eth => for web3 use

    function buyTokenEth(address _ref) public payable {
        require(presaleStatus == true, "Presale : Presale is finished");
        require(msg.value > 0, "Presale : Unsuitable Amount");
        require(soldToken <= SupplyPerPhase, "All Sold");

        uint256 numberOfTokens;
        numberOfTokens = EthToToken(msg.value);
        uint256 bonus = (bonusToken * numberOfTokens) / divider;
        uint256 _refamount = (referralPercent * numberOfTokens) / divider;
        soldToken = soldToken + (numberOfTokens);
        amountRaisedEth = amountRaisedEth + (msg.value);

        users[msg.sender].Eth_balance =
            users[msg.sender].Eth_balance +
            (msg.value);
        users[msg.sender].token_balance =
            users[msg.sender].token_balance +
            (numberOfTokens + bonus);
        users[_ref].token_balance = users[_ref].token_balance + (_refamount);
    }

    // to buy token during preSale time with USDT => for web3 use
    function buyTokenUSDT(address _ref, uint256 amount) public {
        require(presaleStatus == true, "Presale : Presale is finished");
        require(amount > 0, "Presale : Unsuitable Amount");
        require(soldToken <= SupplyPerPhase, "All Sold");

        USDT.transferFrom(msg.sender, address(this), amount);

        uint256 numberOfTokens;
        numberOfTokens = usdtToToken(amount);
        uint256 bonus = (bonusToken * numberOfTokens) / divider;
        uint256 _refamount = (referralPercent * numberOfTokens) / divider;

        soldToken = soldToken + (numberOfTokens);
        amountRaisedUSDT = amountRaisedUSDT + (amount);
        users[msg.sender].usdt_balance =
            users[msg.sender].usdt_balance +
            (amount);
        users[msg.sender].token_balance =
            users[msg.sender].token_balance +
            (numberOfTokens + bonus);
        users[_ref].token_balance = users[_ref].token_balance + (_refamount);
    }

    // to buy token during preSale time with BNB => for web3 use
    function buyTokenBNB(address _ref, uint256 amount) public {
        require(presaleStatus == true, "Presale : Presale is finished");
        require(amount > 0, "Presale : Unsuitable Amount");
        require(soldToken <= SupplyPerPhase, "All Sold");

        BNB.transferFrom(msg.sender, address(this), amount);

        uint256 numberOfTokens;
        uint256 totUSDT = bnbToUsdt(amount);
        numberOfTokens = usdtToToken(totUSDT);
        uint256 bonus = (bonusToken * numberOfTokens) / divider;
        uint256 _refamount = (referralPercent * numberOfTokens) / divider;

        soldToken = soldToken + (numberOfTokens);
        amountRaisedUSDT = amountRaisedUSDT + (amount);
        users[msg.sender].Bnb_balance = users[msg.sender].Bnb_balance + amount;
        users[msg.sender].token_balance =
            users[msg.sender].token_balance +
            (numberOfTokens + bonus);
        users[_ref].token_balance = users[_ref].token_balance + (_refamount);
    }

    // Claim bought tokens
    function claimTokens() external {
        require(!presaleStatus, "Presale : Presale is not finished");
        require(users[msg.sender].token_balance != 0, "Presale: 0 to claim");

        user storage _usr = users[msg.sender];

        HPO.transfer(msg.sender, _usr.token_balance);
        _usr.claimed_token += _usr.token_balance;
        _usr.token_balance -= _usr.token_balance;

        emit ClaimToken(msg.sender, _usr.token_balance);
    }

    // to check percentage of token sold
    function getProgress() public view returns (uint256 _percent) {
        uint256 remaining = SupplyPerPhase -
            (soldToken / (10 ** (HPO.decimals())));
        remaining = (remaining * (divider)) / (SupplyPerPhase);
        uint256 hundred = 100;
        return hundred - (remaining);
    }

    // to change preSale amount limits
    function setSupplyPerPhase(
        uint256 _SupplyPerPhase,
        uint256 _soldToken
    ) external onlyOwner {
        SupplyPerPhase = _SupplyPerPhase;
        soldToken = _soldToken;
    }

    function stopPresale(bool _off) external onlyOwner {
        presaleStatus = _off;
    }

    // to check number of token for given Eth
    function EthToToken(uint256 _amount) public view returns (uint256) {
        uint256 EthToUsd = (_amount * (getLatestPriceEth())) / (1 ether);
        uint256 numberOfTokens = (EthToUsd * (tokenPerUsd)) / (1e8);
        return numberOfTokens;
    }

    // to check number of token for given usdt
    function usdtToToken(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = (_amount * (tokenPerUsd)) / (1e6);
        return numberOfTokens;
    }

    // to check number of token for given usdt
    function bnbToUsdt(
        uint256 bnbAmount
    ) public view returns (uint256 bnbValueInUsd) {
        bnbAmount = bnbAmount / 1e12;
        uint256 price = 33982000000; //getLatestPriceBnb();

        // Compute the value of bnbAmount in USDT
        bnbValueInUsd = (bnbAmount * price) / 10 ** (priceFeedBNB.decimals());
    }

    // to change Price of the token
    function changePrice(uint256 _price) external onlyOwner {
        tokenPerUsd = _price;
    }

    // to change bonus %
    function changeBonus(uint256 _bonus) external onlyOwner {
        bonusToken = _bonus;
    }

    // to change referral %
    function changeRefPercent(uint256 _ref) external onlyOwner {
        referralPercent = _ref;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    // change tokens
    function changeToken(address _token) external onlyOwner {
        HPO = IERC20(_token);
    }

    //change USDT
    function changeUSDT(address _USDT) external onlyOwner {
        USDT = IERC20(_USDT);
    }

    //change BNB
    function changeBNBAddress(address _bnb) external onlyOwner {
        BNB = IERC20(_bnb);
    }

    // to draw funds for liquidity
    function transferFundsEth(uint256 _value) external onlyOwner {
        owner.transfer(_value);
    }

    // to draw out tokens
    function transferTokens(IERC20 token, uint256 _value) external onlyOwner {
        token.transfer(msg.sender, _value);
    }

    // to get current UTC time
    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    // to get contract Eth balance
    function contractBalanceEth() external view returns (uint256) {
        return address(this).balance;
    }

    //to get contract USDT balance
    function contractBalanceUSDT() external view returns (uint256) {
        return USDT.balanceOf(address(this));
    }

    //to get contract bnb balance
    function contractBalanceBNB() external view returns (uint256) {
        return BNB.balanceOf(address(this));
    }

    // to get contract token balance
    function getContractTokenApproval() external view returns (uint256) {
        return HPO.allowance(owner, address(this));
    }
}