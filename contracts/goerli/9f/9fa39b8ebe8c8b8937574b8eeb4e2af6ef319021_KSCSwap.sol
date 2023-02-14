/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

pragma solidity 0.8.17;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address newOwner) {
        _setOwner(newOwner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
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

contract KSCSwap is Ownable {
    using SafeMath for uint256;
    IERC20 public token;
    IERC20 public usdc;

    bool public saleStatus;

    uint256 public unlockTime;

    uint256 public tokenPerUsd;

    uint256 public soldToken;
    uint256 public pendingToken;

    AggregatorV3Interface public priceFeed;
    AggregatorV3Interface public priceFeedETHUSD;

    constructor() Ownable(msg.sender) {
        token = IERC20(0x04600b9c9f611b3eacb6c26d09Aa726539627896);
        priceFeed = AggregatorV3Interface(
            0xA39434A63A52E749F02807ae27335515BA4b07F7
        );
        priceFeedETHUSD = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        usdc = IERC20(0x337610d27c682E347C9cD60BD4b3b107C9d34dDd);
        tokenPerUsd = 1;
        unlockTime = block.timestamp + 1 days;
        saleStatus = true;
    }

    struct history {
        uint256 amount;
        uint256 time;
        address user;
        uint256 price;
        uint256 status;
        uint256 lockedTime;
        string symbol;
    }
    history[] public histories;

    mapping(address => history[]) public depositAmount;

    function swapHistoryLength() public view returns (uint256) {
        return histories.length;
    }

    function addToken(address _token) public onlyOwner {
        token = IERC20(_token);
    }

    function getContractBalacne() public view returns (uint256 KSC) {
        return token.balanceOf(address(this));
    }

    function getContractBalacneusdt() public view returns (uint256 USDT) {
        return usdc.balanceOf(address(this));
    }

    function transferTokensusdt() public onlyOwner {
        require(getContractBalacneusdt() > 0, "contract balance is 0");
        usdc.transfer(msg.sender, getContractBalacneusdt());
    }

    function transferTokens() public onlyOwner {
        require(getContractBalacne() > 0, "contract balance is 0");
        token.transfer(msg.sender, getContractBalacne());
    }

    function getContractETHBalacne() public view returns (uint256 ETH) {
        ETH = address(this).balance;
    }

    function withdrawlETH() public payable onlyOwner {
        require(getContractETHBalacne() > 0, "contract balance is 0");
        payable(owner()).transfer(getContractETHBalacne());
    }

    function changeTokenPrice(uint256 _tokenPerUsd) external onlyOwner {
        tokenPerUsd = _tokenPerUsd;
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price).div(1e8);
    }
    //BNB to USD========================
    function getLatestPriceBNB() public view returns (uint256) {
        (, int256 price, , , ) = priceFeedETHUSD.latestRoundData();
        return uint256(price).div(1e8);
    }

    function sale(bool _bool) public onlyOwner {
        if (_bool == true) {
            saleStatus = true;
        } else {
            saleStatus = false;
        }
    }

    function setUnloackTime(uint256 _unlocktimestamp) public onlyOwner {
        require(_unlocktimestamp >= block.timestamp, "please select right timestamp");
        unlockTime = _unlocktimestamp;
    }

    function swapToken(uint256 value) public {
        require(saleStatus == true, "sale is not start");
        require(value > 0, "Insufficient balance");
        usdc.transferFrom(msg.sender, address(this), value);
        uint256 numOfTokens = USDTTOUSD(value);
        require(numOfTokens > 0, "please enter greater then ether");
        require(
            getContractBalacne() >= numOfTokens,
            "contract balance is less then"
        );
        if (unlockTime < block.timestamp) {
            token.transfer(msg.sender, numOfTokens);
            depositAmount[msg.sender].push(
                history(
                    numOfTokens,
                    block.timestamp,
                    msg.sender,
                    tokenPerUsd.mul(getLatestPrice()),
                    0,
                    unlockTime,
                    'USDC'
                )
            );
            soldToken += numOfTokens;
        } else {
            depositAmount[msg.sender].push(
                history(
                    numOfTokens,
                    block.timestamp,
                    msg.sender,
                    tokenPerUsd.mul(getLatestPrice()),
                    1,
                    unlockTime,
                    'USDC'
                )
            );
            pendingToken += numOfTokens;
        }
        histories.push(
            history(
                numOfTokens,
                block.timestamp,
                msg.sender,
                tokenPerUsd.mul(getLatestPrice()),
                0,
                unlockTime,
                'USDC'
            )
        );
    }

    //BNB swap======================================
    function swapTokenBNB() public payable {
        require(saleStatus == true, "sale is not start");
        require(msg.value > 0, "Insufficient balance");
        uint256 numOfTokens = BNBTOUSD(msg.value);
        require(numOfTokens > 0, "please enter greater then ether");
        require(
            getContractBalacne() >= numOfTokens,
            "contract balance is less then"
        );
        if (unlockTime < block.timestamp) {
            token.transfer(msg.sender, numOfTokens);
            depositAmount[msg.sender].push(
                history(
                    numOfTokens,
                    block.timestamp,
                    msg.sender,
                    tokenPerUsd.mul(getLatestPriceBNB()),
                    0,
                    unlockTime,
                    'ETHCOIN'
                )
            );
            soldToken += numOfTokens;
        } else {
            depositAmount[msg.sender].push(
                history(
                    numOfTokens,
                    block.timestamp,
                    msg.sender,
                    tokenPerUsd.mul(getLatestPriceBNB()),
                    1,
                    unlockTime,
                    'ETHCOIN'
                )
            );
            pendingToken += numOfTokens;
        }
        histories.push(
            history(
                numOfTokens,
                block.timestamp,
                msg.sender,
                tokenPerUsd.mul(getLatestPriceBNB()),
                0,
                unlockTime,
                'ETHCOIN'
            )
        );
    }


    // USDT TO KSC=============token===========================
    function USDTTOUSD(uint256 amount) internal view returns (uint256) {
        uint256 divider = 1e5;
        uint256 numOfTokens = divider.mul(amount).mul(getLatestPrice()).div(
            1e18
        );
        uint256 usdToToken = numOfTokens.mul(tokenPerUsd);
        return usdToToken.mul(1e18).div(1e5);
    }

    //BNB to KSC==========================token===============
    function BNBTOUSD(uint256 amount) internal view returns (uint256) {
        uint256 divider = 1e5;
        uint256 numOfTokens = divider.mul(amount).mul(getLatestPriceBNB()).div(
            1e18
        );
        uint256 usdBNBToToken = numOfTokens.mul(tokenPerUsd);
        return usdBNBToToken.mul(1e18).div(1e5);
    }


    function claimToken(uint256 id) public {
        history storage userData = depositAmount[msg.sender][id];
        uint256 status = userData.status;
        require(status == 1, "claimed");
        require(userData.lockedTime < block.timestamp, "please wait some time");
        uint256 totalAmount = userData.amount;
        token.transfer(msg.sender, totalAmount);
        soldToken += totalAmount;
        pendingToken -= totalAmount;
        userData.status = 0;
    }

    function getUserDepositRow(address _user) public view returns (uint256) {
        return depositAmount[_user].length;
    }
}