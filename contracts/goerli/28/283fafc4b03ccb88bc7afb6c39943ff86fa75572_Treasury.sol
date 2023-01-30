/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//Aggregator Interface for chainLink Proof of reserve Purpose

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

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

contract Treasury {
    IERC20 stableCoin;
    AggregatorV3Interface internal reserveFeed;

    address owner;

    IERC20 public USDT;
    IERC20 public USDC;
    IERC20 public BUSD;
    IERC20 public DAI;

    struct Pair {
        address token0;
        uint256 reserve0;
        uint256 reserve1;
    }

    mapping(uint256 => Pair) pairs;
    mapping(address => uint256) public tokenPairIndex;

    constructor() {
        owner = msg.sender;
        USDT = IERC20(0xAEA4A4E5b7C8CCe84d727206Fd5F46D702B6ec99);
        USDC = IERC20(0xAEA4A4E5b7C8CCe84d727206Fd5F46D702B6ec99);
        BUSD = IERC20(0x9C998b75931Deb0206223D487fA2965A65339a8d);
        DAI = IERC20(0x9C998b75931Deb0206223D487fA2965A65339a8d);
        reserveFeed = AggregatorV3Interface(
            0xDe9C980F79b636B46b9c3bc04cfCC94A29D18D19
        );

        tokenPairIndex[address(USDT)] = 1;
        tokenPairIndex[address(USDC)] = 2;
        tokenPairIndex[address(BUSD)] = 3;
        tokenPairIndex[address(DAI)] = 4;

        pairs[1].token0 = address(USDT);
        pairs[2].token0 = address(USDC);
        pairs[3].token0 = address(BUSD);
        pairs[4].token0 = address(DAI);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not Owner");
        _;
    }

    function swapTokens(
        IERC20 _tokenA,
        IERC20 _tokenB,
        uint256 _amount
    ) external {
        require(_tokenA != _tokenB, "@_tokenA & @_tokenB cannot be Same!");
        require(
            _tokenA == stableCoin || _tokenB == stableCoin,
            "Unsupported Swap"
        );
        int256 marketUSDReserve = getLatestReserve(); //ChainLink Proof of reserve Feed Data
        uint256 _totalReserves = getTotalReserves(); // This contract all reserves standered form equivalent to POR form

        if (_tokenA == stableCoin) {
            require(
                _tokenB == USDT ||
                    _tokenB == USDC ||
                    _tokenB == BUSD ||
                    _tokenB == DAI,
                "@_tokenB is Unsupported Token to swap!"
            );
            require(
                _tokenB.balanceOf(address(this)) >= _amount,
                "You cannot Swap Currently with this Token due to less collecteral Amount!"
            );

            stableCoin.transferFrom(msg.sender, address(this), _amount);
            (uint256 _reserve0, uint256 _reserve1) = getPairReserves(
                tokenPairIndex[address(_tokenB)]
            );
            uint256 amount = (_reserve0 / _reserve1) * _amount;

            if (_tokenB == USDT || _tokenB == USDC) {
                stableCoin.burn(address(this), amount);
                subReserve(tokenPairIndex[address(_tokenB)], amount);
                amount = amount / 1e12;
                _tokenB.transfer(msg.sender, amount);
            } else {
                stableCoin.burn(address(this), amount);
                subReserve(tokenPairIndex[address(_tokenB)], amount);
                _tokenB.transfer(msg.sender, amount);
            }
        } else {
            require(
                _tokenA == USDT ||
                    _tokenA == USDC ||
                    _tokenA == BUSD ||
                    _tokenA == DAI,
                " @_tokenA is Unsupported Token to swap!"
            );
            require(
                _totalReserves < uint256(marketUSDReserve),
                "Token cannot be bought anymore because of Over Collecteralization. Only Sell allowed"
            ); // Proof of Reserve implementation to get the amount of RESERVE TO Stabalized Coin

            (uint256 _reserve0, uint256 _reserve1) = getPairReserves(
                tokenPairIndex[address(_tokenA)]
            );
            uint256 amount = (_reserve0 / _reserve1) * _amount;

            _tokenA.transferFrom(msg.sender, address(this), _amount);
            if (_tokenB == USDT || _tokenB == USDC) {
                amount = amount * 1e12;
                stableCoin.mint(address(this), amount);
                AddReserves(tokenPairIndex[address(_tokenA)], amount);
                stableCoin.transfer(msg.sender, amount);
            } else {
                stableCoin.mint(address(this), amount);
                AddReserves(tokenPairIndex[address(_tokenA)], amount);
                stableCoin.transfer(msg.sender, amount);
            }
        }
    }

    function changeStableCoin(IERC20 _stableCoin) external onlyOwner {
        stableCoin = _stableCoin;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function withdrawTokens(IERC20 _token, uint256 _amount) external onlyOwner {
        require(
            _token.balanceOf(address(this)) >= _amount,
            "Not have sufficient amount of Collatereal!"
        );

        _token.transfer(msg.sender, _amount);
    }

    function withdrawStuckBNB() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getPairTokens(uint256 _pairIndex)
        public
        view
        returns (address _token0, address _token1)
    {
        if (pairs[_pairIndex].token0 == address(0)) {
            return (address(0), address(0));
        } else {
            return (pairs[_pairIndex].token0, address(stableCoin));
        }
    }

    function getTotalReserves() public view returns (uint256) {
        return ((USDT.balanceOf(address(this)) * 1e12) + //to convert into UniDecimals  , UDST Decimals are 6
            (USDC.balanceOf(address(this)) * 1e12) + //to convert into UniDecimals  , UDSC Decimals are 6
            BUSD.balanceOf(address(this)) +
            DAI.balanceOf(address(this)));
    }

    function getPairReserves(uint256 _pairIndex)
        public
        view
        returns (uint256 _reserve0, uint256 _reserve1)
    {
        if (
            pairs[_pairIndex].reserve0 == 0 && pairs[_pairIndex].reserve1 == 0
        ) {
            return (
                pairs[_pairIndex].reserve0 + 1e18,
                pairs[_pairIndex].reserve1 + 1e18
            );
        } else {
            return (pairs[_pairIndex].reserve0, pairs[_pairIndex].reserve1);
        }
    }

    function getReserves()
        public
        view
        returns (
            uint256 Usdt,
            uint256 Usdc,
            uint256 Busd,
            uint256 Dai
        )
    {
        return (
            USDT.balanceOf(address(this)),
            USDC.balanceOf(address(this)),
            BUSD.balanceOf(address(this)),
            DAI.balanceOf(address(this))
        );
    }

    function getUserReserves(address _user)
        public
        view
        returns (
            uint256 Usdt,
            uint256 Usdc,
            uint256 Busd,
            uint256 Dai
        )
    {
        return (
            USDT.balanceOf(_user),
            USDC.balanceOf(_user),
            BUSD.balanceOf(_user),
            DAI.balanceOf(_user)
        );
    }

    function getLatestReserve() public view returns (int256) {
        // prettier-ignore
        (
            /*uint80 roundID*/,
            int reserve,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = reserveFeed.latestRoundData();

        return reserve;
    }

    function AddReserves(uint256 _pairNo, uint256 _retrieveAmount) internal {
        unchecked {
            pairs[_pairNo].reserve0 += _retrieveAmount;
            pairs[_pairNo].reserve1 += _retrieveAmount;
        }
    }

    function subReserve(uint256 _pairNo, uint256 _retrieveAmount) internal {
        unchecked {
            pairs[_pairNo].reserve0 -= _retrieveAmount;
            pairs[_pairNo].reserve1 -= _retrieveAmount;
        }
    }
}