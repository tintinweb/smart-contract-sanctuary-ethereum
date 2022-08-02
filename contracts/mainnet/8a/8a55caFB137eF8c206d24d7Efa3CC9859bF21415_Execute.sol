/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

pragma experimental ABIEncoderV2;

interface IAavepool {
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}


contract Execute {

    address private immutable owner;
    address private immutable executor;
    address private constant LendingPool = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    IAavepool Aavepool = IAavepool(LendingPool);

    // IERC20 private constant USDT = IERC20( 0xdAC17F958D2ee523a2206206994597C13D831ec7 );
    // IERC20 private constant WBTC = IERC20( 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599 );
    IWETH private constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    // IERC20 private constant YFI = IERC20( 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e );
    // IERC20 private constant ZRX = IERC20( 0xE41d2489571d322189246DaFA5ebDe1F4699F498 );
    // IERC20 private constant UNI = IERC20( 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984 );
    // IERC20 private constant AAVE = IERC20( 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9 );
    // IERC20 private constant BAT = IERC20( 0x0D8775F648430679A709E98d2b0Cb6250d2887EF );
    // IERC20 private constant BUSD = IERC20( 0x4Fabb145d64652a948d72533023f6E7A623C7C53 );
    // IERC20 private constant DAI = IERC20( 0x6B175474E89094C44Da98b954EedeAC495271d0F );
    // IERC20 private constant ENJ = IERC20( 0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c );
    // IERC20 private constant KNC = IERC20( 0xdd974D5C2e2928deA5F71b9825b8b646686BD200 );
    // IERC20 private constant LINK = IERC20( 0x514910771AF9Ca656af840dff83E8264EcF986CA );
    // IERC20 private constant MANA = IERC20( 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942 );
    // IERC20 private constant MKR = IERC20( 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2 );
    // IERC20 private constant REN = IERC20( 0x408e41876cCCDC0F92210600ef50372656052a38 );
    // IERC20 private constant SNX = IERC20( 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F );
    // IERC20 private constant SUSD = IERC20( 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51 );
    // IERC20 private constant TUSD = IERC20( 0x0000000000085d4780B73119b644AE5ecd22b376 );
    // IERC20 private constant USDC = IERC20( 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 );
    // IERC20 private constant CRV = IERC20( 0xD533a949740bb3306d119CC777fa900bA034cd52 );
    // IERC20 private constant GUSD = IERC20( 0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd );
    // IERC20 private constant BAL = IERC20( 0xba100000625a3754423978a60c9317c58a424e3D );
    // IERC20 private constant XSUSHI = IERC20( 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272 );
    // IERC20 private constant RENFIL = IERC20( 0xD5147bc8e386d91Cc5DBE72099DAC6C9b99276F5 );
    // IERC20 private constant RAI = IERC20( 0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919 );
    // IERC20 private constant AMPL = IERC20( 0xD46bA6D942050d489DBd938a2C909A5d5039A161 );
    // IERC20 private constant USDP = IERC20( 0x8E870D67F660D95d5be530380D0eC0bd388289E1 );
    // IERC20 private constant DPI = IERC20( 0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b );
    // IERC20 private constant FRAX = IERC20( 0x853d955aCEf822Db058eb8505911ED77F175b99e );
    // IERC20 private constant FEI = IERC20( 0x956F47F50A910163D8BF957Cf5846D573E7f87CA );
    // IERC20 private constant STETH = IERC20( 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84 );
    // IERC20 private constant ENS = IERC20( 0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72 );
    // IERC20 private constant CVX = IERC20( 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B );

    modifier onlyExecutor() {
        require(msg.sender == executor);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _executor) payable {
        owner = msg.sender;
        executor = _executor;
        if (msg.value > 0) {
            WETH.deposit{value: msg.value}();
        }
        // USDT.approve(LendingPool, type(uint).max);
        // WBTC.approve(LendingPool, type(uint).max);
        // WETH.approve(LendingPool, type(uint).max);
        // YFI.approve(LendingPool, type(uint).max);
        // ZRX.approve(LendingPool, type(uint).max);
        // UNI.approve(LendingPool, type(uint).max);
        // AAVE.approve(LendingPool, type(uint).max);
        // BAT.approve(LendingPool, type(uint).max);
        // BUSD.approve(LendingPool, type(uint).max);
        // DAI.approve(LendingPool, type(uint).max);
        // ENJ.approve(LendingPool, type(uint).max);
        // KNC.approve(LendingPool, type(uint).max);
        // LINK.approve(LendingPool, type(uint).max);
        // MANA.approve(LendingPool, type(uint).max);
        // MKR.approve(LendingPool, type(uint).max);
        // REN.approve(LendingPool, type(uint).max);
        // SNX.approve(LendingPool, type(uint).max);
        // SUSD.approve(LendingPool, type(uint).max);
        // TUSD.approve(LendingPool, type(uint).max);
        // USDC.approve(LendingPool, type(uint).max);
        // CRV.approve(LendingPool, type(uint).max);
        // GUSD.approve(LendingPool, type(uint).max);
        // BAL.approve(LendingPool, type(uint).max);
        // XSUSHI.approve(LendingPool, type(uint).max);
        // RENFIL.approve(LendingPool, type(uint).max);
        // RAI.approve(LendingPool, type(uint).max);
        // AMPL.approve(LendingPool, type(uint).max);
        // USDP.approve(LendingPool, type(uint).max);
        // DPI.approve(LendingPool, type(uint).max);
        // FRAX.approve(LendingPool, type(uint).max);
        // FEI.approve(LendingPool, type(uint).max);
        // STETH.approve(LendingPool, type(uint).max);
        // ENS.approve(LendingPool, type(uint).max);
        // CVX.approve(LendingPool, type(uint).max);
    }

    receive() external payable {
    }

    function execution(bytes memory txdata, uint256 _ethAmountToCoinbase, address _user) external onlyExecutor payable {
        (,,,,,uint256 healthFactor) = Aavepool.getUserAccountData(_user);
        if (healthFactor >= 1 ether){
            return; 
        }
        (bool _success, bytes memory _response) = LendingPool.call(txdata);
        require(_success); _response;

        uint256 _ethBalance = address(this).balance;
        if (_ethBalance < _ethAmountToCoinbase) {
            WETH.withdraw(_ethAmountToCoinbase - _ethBalance);
        }
        block.coinbase.transfer(_ethAmountToCoinbase);
    }

    function approve(address _tokenaddress) external onlyExecutor {
        IERC20 tokenContract = IERC20(_tokenaddress);
        tokenContract.approve(LendingPool, type(uint).max);
    }

    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner payable{
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
    }

    function withdrawETH(uint256 _value) external onlyOwner payable{
        payable(msg.sender).transfer(_value);
    }

    // function call(address payable _to, uint256 _value, bytes calldata _data) external onlyOwner payable returns (bytes memory) {
    //     require(_to != address(0));
    //     (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
    //     require(_success);
    //     return _result;
    // }
}