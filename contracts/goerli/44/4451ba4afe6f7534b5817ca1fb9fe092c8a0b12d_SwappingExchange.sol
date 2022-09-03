/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "./TokenA.sol";
// import "./TokenB.sol";50000000000000000000

interface IBEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// this contract should be deployed after the deployment of the two contracts TokenABC and TokenXYZ
// as instrcuted in the 2_deploy_contracts file
contract SwappingExchange {

    //0.00401245GoerliETH Gas Fee

    address payable admin;
    //ratioAX is the percentage of how much TokenA is worth of TokenX
    uint256 ratioAX;
    bool AcheaperthenX;
    uint256 fees;
  
   

    IBEP20 public token;
    IBEP20 public coin;

    uint256 public tokenPrice;
    uint256 public tokensSold;

    uint256 public coinPrice;
     uint256 public coinsSold;

    event PriceChanged (uint256,address);

    constructor(IBEP20 _token, IBEP20 _coin,uint256 _tokenPrice,uint256 _coinPrice) {
        admin = payable(msg.sender);
        token = IBEP20(_token);
        coin = IBEP20(_coin);

        tokenPrice = _tokenPrice;
        coinPrice = _coinPrice;
        //due to openzeppelin implementation, transferFrom function implementation expects _msgSender() to be the beneficiary from the caller
        // but in this use cae we are using this contract to transfer so its always checking the allowance of SELF
        token.approve(address(this), token.totalSupply());
        coin.approve(address(this), coin.totalSupply());
    }

    modifier onlyAdmin() {
        payable(msg.sender) == admin;
        _;
    }

    function setRatio(uint256 _ratio) public onlyAdmin {
        ratioAX = _ratio;
    }

    function getRatio() public view onlyAdmin returns (uint256) {
        return ratioAX;
    }

    function setFees(uint256 _Fees) public onlyAdmin {
        fees = _Fees;
    }

    function getFees() public view onlyAdmin returns (uint256) {
        return fees;
    }

   
    // accepts amount of TokenABC and exchenge it for TokenXYZ, vice versa with function swapTKX
    // transfer tokensABC from sender to smart contract after the user has approved the smart contract to
    // withdraw amount TKA from his account, this is a better solution since it is more open and gives the
    // control to the user over what calls are transfered instead of inspecting the smart contract
    // approve the caller to transfer one time from the smart contract address to his address
    // transfer the exchanged TokenXYZ to the sender
    function swapTokenToCoin(uint256 amountTK) public returns (uint256) {
        //check if amount given is not 0
        // check if current contract has the necessary amout of Tokens to exchange
        require(amountTK > 0, "amountTK must be greater then zero");
        require(
            token.balanceOf(msg.sender) >= amountTK,
            "sender doesn't have enough Tokens"
        );

        uint256 exchangeA = uint256(mul(amountTK, ratioAX));
        uint256 exchangeAmount = exchangeA -
            uint256((mul(exchangeA, fees)) / 100);
        require(
            exchangeAmount > 0,
            "exchange Amount must be greater then zero"
        );

        require(
            coin.balanceOf(address(this)) > exchangeAmount,
            "currently the exchange doesnt have enough Coins, please retry later :=("
        );

        token.transferFrom(msg.sender, address(this), amountTK);
        coin.approve(address(msg.sender), exchangeAmount);
        coin.transferFrom(
            address(this),
            address(msg.sender),
            exchangeAmount
        );
        return exchangeAmount;
    }

    function swapCoinToToken(uint256 amountCoin) public returns (uint256) {
        //check if amount given is not 0
        // check if current contract has the necessary amout of Tokens to exchange and the sender
        require(amountCoin >= ratioAX, "amountTKX must be greater then ratio");
        require(
            coin.balanceOf(msg.sender) >= amountCoin,
            "sender doesn't have enough Tokens/Coins"
        );

        uint256 exchangeA = amountCoin / ratioAX;
        uint256 exchangeAmount = exchangeA - ((exchangeA * fees) / 100);

        require(
            exchangeAmount > 0,
            "exchange Amount must be greater then zero"
        );

        require(
            token.balanceOf(address(this)) > exchangeAmount,
            "currently the exchange doesnt have enough Tokens, please retry later :=("
        );
        coin.transferFrom(msg.sender, address(this), amountCoin);
        token.approve(address(msg.sender), exchangeAmount);
        token.transferFrom(
            address(this),
            address(msg.sender),
            exchangeAmount
        );
        return exchangeAmount;
    }

    // //leting the Admin of the TokenSwap to buyTokens manually is preferable and better then letting the contract
    // // buy automatically tokens since contracts are immutable and in case the value of some tokens beomes
    // // worthless its better to not to do any exchange at all
    // function buyTokensA(uint256 amount) public payable onlyAdmin {
    //     tokenA.buyTokens{value: msg.value}(amount);
    // }

    // function buyTokensB(uint256 amount) public payable onlyAdmin {
    //     tokenB.buyTokens{value: msg.value}(amount);
    // }

     function buyTokens(uint256 numberOfTokens) external payable {
        // keep track of number of tokens sold
        // require that a contract have enough tokens
        // require tha value sent is equal to token price
        // trigger sell event
     
        require(msg.value >= mul(numberOfTokens, tokenPrice),"Please make sure amount equal to no of tokens");
        require(token.balanceOf(address(this)) >= numberOfTokens,"Not an enough Contract liquidity for tokens");
       
        require(token.transfer(msg.sender, numberOfTokens*1e18));

        tokensSold += numberOfTokens;
    }

     function buyCoins(uint256 numberOfCoins) external payable {
        // keep track of number of coins sold
        // require that a contract have enough coins
        // require that value sent is equal to coin price
        // trigger sell event
        require(msg.value >= mul(numberOfCoins, coinPrice),"Please make sure amount equal to no of coins");
        require(coin.balanceOf(address(this)) >= numberOfCoins,"Not an enough contract liquidity of coin");
        require(coin.transfer(msg.sender, numberOfCoins*1e18));

        coinsSold += numberOfCoins;
    }
     //Tells the liquidity of exchange
     //About token and coin 
     function exchangeLiquidity() public view returns (uint256, uint256) {
        return (token.balanceOf(address(this)),coin.balanceOf(address(this)));
    }
     
    //Change the price of Token
    function changePrice(uint newPrice)  public onlyAdmin  {  // Update Price of Token
        require(newPrice >0,"SHOULD_NOT_ZERO");
        tokenPrice = newPrice;
        emit PriceChanged(newPrice,msg.sender);
    } 

    //Change the Price of Coin
    function changeCoinPrice(uint newPrice)  public onlyAdmin  {  // Update Price of Token
        require(newPrice >0,"SHOULD_NOT_ZERO");
        coinPrice = newPrice;
        emit PriceChanged(newPrice,msg.sender);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

     function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}