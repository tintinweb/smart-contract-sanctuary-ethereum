/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

/**
 .----------------.  .----------------.  .----------------.  .----------------. 
| .--------------. || .--------------. || .--------------. || .--------------. |
| | ____   ____  | || |  _______     | || |  _________   | || |     _____    | |
| ||_  _| |_  _| | || | |_   __ \    | || | |_   ___  |  | || |    |_   _|   | |
| |  \ \   / /   | || |   | |__) |   | || |   | |_  \_|  | || |      | |     | |
| |   \ \ / /    | || |   |  __ /    | || |   |  _|      | || |      | |     | |
| |    \ ' /     | || |  _| |  \ \_  | || |  _| |_       | || |     _| |_    | |
| |     \_/      | || | |____| |___| | || | |_____|      | || |    |_____|   | |
| |   PRESALE    | || |    PRESALE   | || |   PRESALE    | || |    PRESALE   | |
| '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------' 
**/
pragma solidity 0.8.15;

//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {
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

contract preSaleVRFI {
    using SafeMath for uint256;

    IBEP20 public token;
    AggregatorV3Interface public priceFeedEth;

    address payable public owner;
    address payable public marketWallet;
    address payable public insuranceFunds;

    uint256 public tokenPerUsd;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public soldToken;
    uint256 public amountRaisedinEth;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 marketTax = 40;
    uint256 insuranceTax = 10;
    uint256 percentDivider = 1000;
    mapping(address => uint256) public coinBalance;
    modifier onlyOwner() {
        require(msg.sender == owner, "PRESALE: Not an owner");
        _;
    }

    event BuyToken(address indexed _user, uint256 indexed _amount);

    constructor(
        address payable _owner,
        address payable _market,
        address payable _insurance,
        IBEP20 _token
    ) {
        owner = _owner;
        token = _token;
        marketWallet = _market;
        insuranceFunds = _insurance;
        priceFeedEth = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        tokenPerUsd = 250;
        minAmount = 0.25 ether;
        maxAmount = 10 ether;
        preSaleStartTime = 1662375600;
        preSaleEndTime = preSaleStartTime + 100 days;
    }

    receive() external payable {}

    // to get real time price of bnb
    function getLatestPriceEth() public view returns (uint256) {
        (, int256 price, , , ) = priceFeedEth.latestRoundData();
        return uint256(price).div(1e8);
    }

    // to buy token during preSale time => for web3 use

    function buyToken() public payable {
        require(msg.value >= minAmount, "minimum purchase is 0.25 ETH");
        require(
            block.timestamp >= preSaleStartTime &&
                block.timestamp < preSaleEndTime,
            "PRESALE: PreSale time not met"
        );
        require(
            coinBalance[msg.sender].add(msg.value) <= maxAmount,
            "max buy limit is 10 Eth"
        );
        uint256 mtax = msg.value.mul(marketTax).div(percentDivider);
        uint256 itax = msg.value.mul(insuranceTax).div(percentDivider);
        uint256 netValue = msg.value.sub(mtax.add(itax));

        uint256 numberOfTokens = EthToToken(netValue);

        token.transferFrom(owner, msg.sender, numberOfTokens);
        marketWallet.transfer(mtax);
        insuranceFunds.transfer(itax);

        soldToken = soldToken.add(numberOfTokens);
        amountRaisedinEth = amountRaisedinEth.add(msg.value);
        coinBalance[msg.sender] = coinBalance[msg.sender].add(msg.value);

        emit BuyToken(msg.sender, numberOfTokens);
    }

    // to check number of token for given bnb
    function EthToToken(uint256 _amount) public view returns (uint256) {
        uint256 EthToUsd = _amount.mul(getLatestPriceEth());
        uint256 numberOfTokens = EthToUsd.mul(tokenPerUsd);
        return numberOfTokens;
    }

    // to change Price of the token
    function changePrice(uint256 _pricePerUsd) external onlyOwner {
        tokenPerUsd = _pricePerUsd;
    }

    // to change preSale time duration
    function setPreSaleTime(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        preSaleStartTime = _startTime;
        preSaleEndTime = _endTime;
    }

    function changeAmount(uint256 _min, uint256 _max) external onlyOwner {
        minAmount = _min;
        maxAmount = _max;
    }

    // change tax %
    function changeTax(
        uint256 _marketTaxt,
        uint256 _insuranceTax,
        uint256 _percentDivider
    ) external onlyOwner {
        marketTax = _marketTaxt;
        insuranceTax = _insuranceTax;
        percentDivider = _percentDivider;
    }

    // change tax receiving wallets
    function changeTaxWallets(
        address payable _marketWallet,
        address payable _insurance
    ) external onlyOwner {
        marketWallet = _marketWallet;
        insuranceFunds = _insurance;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    // change tokens
    function changeToken(address _token) external onlyOwner {
        token = IBEP20(_token);
    }

    // to draw funds for liquidity
    function transferFunds(uint256 _value) external onlyOwner {
        owner.transfer(_value);
    }

    // to draw out tokens
    function transferTokens(uint256 _value) external onlyOwner {
        token.transfer(owner, _value);
    }

    // to get current UTC time
    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    function contractBalancebnb() external view returns (uint256) {
        return address(this).balance;
    }

    function getContractTokenApproval() external view returns (uint256) {
        return token.allowance(owner, address(this));
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}