/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

//SPDX-License-Identifier: MIT Licensed

pragma solidity ^0.8.17;

interface IToken {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;

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

    function getRoundData(uint80 _roundId)
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

contract WINBUSDPRESALE {
    IToken public token = IToken(0x18795b9826651Ac0f9A6aF30e1D873d125711B23);
    IToken public BUSD = IToken(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    AggregatorV3Interface public priceFeedbnb;

    address payable public owner;

    uint256 public tokenPerUsd;
    uint256 public minAmountbnb;
    uint256 public maxAmountbnb;
    uint256 public minAmountBUSD;
    uint256 public maxAmountBUSD;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public soldToken;
    uint256 public amountRaisedbnb;
    uint256 public amountRaisedBUSD;
    uint256 public totalSupply;

    mapping(address => uint256) public bnbBalance;
    mapping(address => uint256) public busdBalance;

    modifier onlyOwner() {
        require(msg.sender == owner, "PRESALE: Not an owner");
        _;
    }

    event BuyToken(address indexed _user, uint256 indexed _amount);

    constructor(address owner1) {
        owner = payable(owner1);
        // mainnet
        priceFeedbnb = AggregatorV3Interface(
            0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
        );
        //testnet
        // priceFeedbnb = AggregatorV3Interface(
        //     0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        // );
        tokenPerUsd = 250;
        minAmountbnb = 0.05 ether;
        maxAmountbnb = 5 ether;
        minAmountBUSD = 0.05 ether;
        maxAmountBUSD = 5 ether;
        totalSupply = 1000000000;
        preSaleStartTime = block.timestamp;
        preSaleEndTime = preSaleStartTime + 60 days;
    }

    receive() external payable {}

    // to get real time price of bnb
    function getLatestPricebnb() public view returns (uint256) {
        (, int256 price, , , ) = priceFeedbnb.latestRoundData();
        return uint256(price) / (1e8);
    }

    // to buy token during preSale time => for web3 use

    function buyToken(uint256 amount, bool eth) public payable {
        require(
            block.timestamp >= preSaleStartTime &&
                block.timestamp < preSaleEndTime,
            "PRESALE: PreSale time not met"
        );
        uint256 numberOfTokens;
        if (eth) {
            require(
                bnbBalance[msg.sender] + (msg.value) <= maxAmountbnb,
                "PRESALE: Amount exceeds max limit"
            );
            require(
                msg.value >= minAmountbnb && msg.value <= maxAmountbnb,
                "PRESALE: Amount not correct"
            );

            numberOfTokens = bnbToToken(msg.value);
            token.transferFrom(owner, msg.sender, numberOfTokens);
            soldToken = soldToken + (numberOfTokens);
            amountRaisedbnb = amountRaisedbnb + (msg.value);
            bnbBalance[msg.sender] = bnbBalance[msg.sender] + (msg.value);
        } else {
            require(
                busdBalance[msg.sender] + (amount) <= maxAmountBUSD,
                "PRESALE: Amount exceeds max limit"
            );
            require(
                amount >= minAmountBUSD && amount <= maxAmountBUSD,
                "PRESALE: Amount not correct"
            );
            BUSD.transferFrom(msg.sender, address(this), amount);
            numberOfTokens = busdtoToken(amount);
            token.transferFrom(owner, msg.sender, numberOfTokens);
            soldToken = soldToken + (numberOfTokens);
            amountRaisedBUSD = amountRaisedBUSD + (amount);
            busdBalance[msg.sender] = busdBalance[msg.sender] + (amount);
        }

        emit BuyToken(msg.sender, numberOfTokens);
    }

    // to check number of token for given bnb
    function bnbToToken(uint256 _amount) public view returns (uint256) {
        uint256 bnbToUsd = (_amount * (getLatestPricebnb())) / (1e18);
        uint256 numberOfTokens = bnbToUsd * (tokenPerUsd);
        return numberOfTokens * (1e18);
    }

    function busdtoToken(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = _amount * (tokenPerUsd);
        return numberOfTokens;
    }

    function getProgress() public view returns (uint256 _percent) {
        uint256 remaining = totalSupply - (soldToken / (1e12));
        remaining = (remaining * (100)) / (totalSupply);
        uint256 hundred = 100;
        return hundred - (remaining);
    }

    // to change Price of the token
    function changePrice(uint256 _price) external onlyOwner {
        tokenPerUsd = _price;
    }

    // to change preSale amount limits
    function setPreSaletLimits(
        uint256 _minAmountbnb,
        uint256 _maxAmountbnb,
        uint256 _minAmountBUSD,
        uint256 _maxAmountBUSD,
        uint256 _totalSupply
    ) external onlyOwner {
        minAmountbnb = _minAmountbnb;
        maxAmountbnb = _maxAmountbnb;
        minAmountBUSD = _minAmountBUSD;
        maxAmountBUSD = _maxAmountBUSD;
        totalSupply = _totalSupply;
    }

    // to change preSale time duration
    function setPreSaleTime(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        preSaleStartTime = _startTime;
        preSaleEndTime = _endTime;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    // change tokens
    function changeToken(address _token) external onlyOwner {
        token = IToken(_token);
    }

    //change BUSD
    function changeBUSD(address _BUSD) external onlyOwner {
        BUSD = IToken(_BUSD);
    }

    // to draw funds for liquidity
    function transferFundsBNB(uint256 _value) external onlyOwner {
        owner.transfer(_value);
    }

    // to draw funds for liquidty
    function transferFundsBUSD(uint256 _value) external onlyOwner {
        BUSD.transfer(msg.sender, _value);
    }

    // to draw out tokens
    function transferTokens(uint256 _value) external onlyOwner {
        token.transfer(owner, _value);
    }

    // to get current UTC time
    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    // to get contract bnb balance
    function contractBalancebnb() external view returns (uint256) {
        return address(this).balance;
    }

    //to get contract BUSD balance
    function contractBalanceBUSD() external view returns (uint256) {
        return BUSD.balanceOf(address(this));
    }

    // to get contract token balance
    function getContractTokenApproval() external view returns (uint256) {
        return token.allowance(owner, address(this));
    }
}