pragma solidity ^0.8.0;

//SPDX-License-Identifier: Unlicensed

import "./ITeam.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./AggregatorV3Interface.sol";
import "./SafeMath.sol";
import "./SignedSafeMath.sol";


interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);    
}

interface IUniswapV2Router {
    function getAmountsIn(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}


contract BBCStakingContract is Ownable {
    
    using SignedSafeMath for int256;    
    using SafeMath for uint256;

    address immutable WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address immutable DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    IUniswapV2Pair immutable DAI_PAIR = IUniswapV2Pair(0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11);
    IUniswapV2Router immutable UNISWAP_ROUTER_V2 = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);   

    address public _bearAddress;
    address public _bullAddress;
    address public _crabAddress;

    address public _mainAddress;

    ITeam private _bearToken;
    ITeam private _bullToken;
    ITeam private _crabToken;

    IERC20 private _mainToken;

    uint256 public _startTime;
    uint256 public _endTime;

    int256 public _openPrice;
    int256 public _closePrice;
    int256 public _currentPrice;
    uint256 public lastTimeChecked;
    uint256 public _prize;

    string public _name;
    string public _symbol;

    //percentage change below which we can confidently say: we crabbin'
    int256 public _crabPercentage;

    //0 for Chainlink, 1 for UniswapV2
    bool public _betType;

    //Chainlink Stuff
    address public _linkAggregatorAddress;
    AggregatorV3Interface private priceFeed;
    uint8 public oracleDecimals;

    //Univ2stuff
    IERC20 public _token;
    IERC20 public _otherToken;
    IUniswapV2Pair public _pair;
    uint8 _tokenDecimals;
    uint8 _otherTokenDecimals;
    bool _tokenPosition;

    game[] public games;
    uint public counter = 0;

  

    struct game {
        string name;
        string symbol;
        uint256 startTime;
        uint256 endTime;
        uint256 prize;
        string winner;
    }

    constructor (address bullAddress, address bearAddress, address crabAddress, address mainAddress) {
        _bullAddress= bullAddress;
        _bearAddress = bearAddress;
        _crabAddress = crabAddress;
        _mainAddress = mainAddress;

        _bullToken = ITeam(_bullAddress);
        _bearToken = ITeam(_bearAddress);
        _crabToken = ITeam(_crabAddress);

        _mainToken = IERC20(_mainAddress); 
    
    }

    receive() external payable {}


    //for data available through ChainLink
    function setOracleBet(
        string calldata name,
        string calldata symbol,
        address linkAggregatorAddress,
        int256 crabPercentage, 
        uint256 startTime, 
        uint256 endTime
    ) external payable onlyOwner {

        _name = name;
        _symbol = symbol;

        _betType = false;
        _crabPercentage = crabPercentage;
        _startTime = startTime;
        _endTime = endTime;

        _linkAggregatorAddress = linkAggregatorAddress;
        priceFeed = AggregatorV3Interface(_linkAggregatorAddress);  
        oracleDecimals = priceFeed.decimals();

        _prize = msg.value;      

        getPrice();
    }
    
    //for Uniswap V2 pools
    function setUniV2Bet(
        string calldata name,
        string calldata symbol,
        address token,
        address pair, 
        int256 crabPercentage, 
        uint256 startTime, 
        uint256 endTime
    ) external payable onlyOwner {

        _name = name;
        _symbol = symbol;

        _token = IERC20(token);
        _pair = IUniswapV2Pair(pair);   

        if (_pair.token0() == token) {
            _tokenPosition = false;
            _otherToken = IERC20(_pair.token1());
        }
        else if (_pair.token1() == address(token)) {
            _tokenPosition = true;
            _otherToken = IERC20(_pair.token0());
        }
        else require(false, "invalid pair");

        _tokenDecimals = _token.decimals();
        _otherTokenDecimals = _otherToken.decimals();

        _betType = true;
       
        _crabPercentage = crabPercentage;
        _startTime = startTime;
        _endTime = endTime;

        _prize = msg.value;

        getPrice();
    } 
       
    

    function getPrice() public {

        int256 _gudPrice;

        if (!_betType) {
            //get price with ChainLink
            (
            /*int2560 roundID*/,
            _gudPrice,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*int2560 answeredInRound*/
            ) = (priceFeed.latestRoundData());
            _currentPrice=_gudPrice;
                        
        }
        else {
            address[] memory path1 = new address[](2);
            path1[0] = address(_otherToken);
            path1[1] = address(_token);

            uint256 price = UNISWAP_ROUTER_V2.getAmountsIn(1*10**_tokenDecimals, path1)[0];                

            //if it's not a stablecoin pool, convert ETH value to USD
            if (address(_otherToken) == WETH) {
                address[] memory path2 = new address[](2);
                
                path2[1] = address(_otherToken);
                path2[0] = address(DAI_ADDRESS);               
                
                _gudPrice = int256(UNISWAP_ROUTER_V2.getAmountsIn(price, path2)[0]);                
            }
            else {
                _gudPrice = int256(price);
            }

            _currentPrice = _gudPrice;
        }

    }        

    function sendPrize() internal {
        game memory lastGame;
        lastGame.name = _name;
        lastGame.symbol = _symbol;
        lastGame.startTime = _startTime;
        lastGame.endTime = _endTime;
        lastGame.prize = _prize;
            
        address winner;
        int256 percentageChange = ((_closePrice.sub(_openPrice)).mul(100)).div(_openPrice);
        if (abs(percentageChange) < _crabPercentage) {
            winner = _crabAddress;
            lastGame.winner ="Crab";
        }
        else if (percentageChange > 0) {
            winner = _bullAddress;
            lastGame.winner = "Bull";
        }
        else {
            winner = _bearAddress;
            lastGame.winner =  "Bear";
        }
        games.push(lastGame);
        counter++;
        payable(winner).call{value: _prize}("");

        _openPrice = 0;
        _closePrice = 0;       
        _prize = 0;
    }

 
    
    function stake(uint256 amount, address team) external {
        checkTime();
        require (!isStakingClosed(), "Bets are closed: you cannot Stake at this time!");     
        require(_mainToken.balanceOf(msg.sender) >= amount, "Not enough tokens");

        _mainToken.transferFrom(msg.sender, address(this), amount);        
    
        if (team == _bearAddress) {
            _bearToken.stake(msg.sender, amount);
        }

        else if (team == _bullAddress) {
            _bullToken.stake(msg.sender, amount);
        }

        else if (team == _crabAddress) {
            _crabToken.stake(msg.sender, amount);
        }

        else {
            require(false, "Provide a valid team address");
        }

    }

    function unstake(uint256 amount, address team) external {
        checkTime();
        require (!isStakingClosed(), "Bets are closed: you cannot Unstake at this time!"); 

        if (team == _bearAddress) {
            require (amount <= _bearToken.balanceOf(msg.sender)); 
            require (_mainToken.balanceOf(address(this)) >= amount);
            _bearToken.unstake(msg.sender, amount); 
            _mainToken.transfer(msg.sender,amount);
        }

        else if (team == _bullAddress) {
            require (amount <= _bullToken.balanceOf(msg.sender)); 
            require (_mainToken.balanceOf(address(this)) >= amount);
            _bullToken.unstake(msg.sender, amount); 
            _mainToken.transfer(msg.sender,amount);
        }

        else if (team == _crabAddress) {
            require (amount <= _crabToken.balanceOf(msg.sender)); 
            require (_mainToken.balanceOf(address(this)) >= amount);
            _crabToken.unstake(msg.sender, amount); 
            _mainToken.transfer(msg.sender,amount);
        }

        else {
            require(false, "provide a valid team address");
        }
    }

    function checkTime() public {
        if (_prize == 0) {
            return;
        }
        getPrice();
        if (block.timestamp >= _startTime && block.timestamp < _endTime) {
            if (_openPrice == 0) {
                _openPrice = _currentPrice;
            }
        }
        else if (block.timestamp >= _endTime) {
            if (_closePrice == 0) {
                _closePrice = _currentPrice;
                sendPrize();
            }
        }
        lastTimeChecked = block.timestamp;
    }  
  
    function cancelBet() external onlyOwner {
        _openPrice = 0;
        _closePrice = 0;
        _startTime = 0;
        _endTime = 0;
        _prize = 0;
    }

    function setBear(address bearAddress) external onlyOwner{
        _bearAddress = bearAddress;
        _bearToken = ITeam(_bearAddress);
    }

    function setBull(address bullAddress) external onlyOwner{
        _bullAddress = bullAddress;
        _bullToken = ITeam(_bullAddress);
    }

    function setCrab(address crabAddress) external onlyOwner {
        _crabAddress = crabAddress;
        _crabToken = ITeam(_crabAddress);
    }

    function setMain(address mainAddress) external onlyOwner {
        _mainAddress= mainAddress;
        _mainToken= IERC20(_mainAddress);
    }

    function manualSend(uint256 amount, address holder) external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(holder).transfer(amount > 0 ? amount : contractETHBalance);
    }

    function abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }

     function getGame(uint i) public view returns (game memory) {
        require (counter > 0);
        require (counter >= i);
        return  games[i - 1];
    }

    function getLastGame() public view returns (game memory) {
        require (counter > 0);
        return games[counter - 1];
    }

    function isStakingClosed() public view returns (bool) {
        return (block.timestamp >= _startTime && block.timestamp < _endTime);
    }
    
}