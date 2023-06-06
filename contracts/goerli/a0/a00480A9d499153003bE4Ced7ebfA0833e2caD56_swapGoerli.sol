// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IUniswapFactoryV3{
  function getPool(address tokenA, address tokenB,uint24 fee) external view returns (address pair);
  function owner() external view returns (address);
}

interface IUniswapFactoryV2{
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapRouterV2 {
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline) external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
}

interface IUniswapRouterV3{
        struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(ExactInputSingleParams memory params) external payable returns (uint256 amountOut);
}

interface IUniswapPoolV2{
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0()external view returns(address);
}

interface IUniswapPoolsV3 {
    function slot0()external view returns (uint160 sqrtPriceX96 , 
                                      int24 tick, uint16 observationIndex,
                                      uint16 observationCardinality,
                                      uint16 observationCardinalityNext,
                                      uint8 feeProtocol,
                                      bool unlocked);// use for uniswap contracts
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0()external view returns(address);
}

interface IBancorNetworkInfo{
    function tradeInputByTargetAmount(address sourceToken, address targetToken, uint256 targetAmount)external view returns(uint);
    function tradingFeePPM(address pool) external view returns (uint32);
    function tradeOutputBySourceAmount(address sourceToken, address targetToken, uint256 sourceAmount)external view returns(uint);
    function tradingEnabled(address pool) external view returns (bool);
}

interface IBancorNetwork{
        function tradeBySourceAmount(
        address sourceToken,
        address targetToken,
        uint256 sourceAmount,
        uint256 minReturnAmount,
        uint256 deadline,
        address beneficiary
    ) external payable;
        function version()external view returns(uint);
        function pendingNetworkFeeAmount()external view returns(uint);
}

interface IERC20{
    function decimals() external view returns(uint8);
    function balanceOf(address owner)external view returns(uint);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface ItypeData{

    struct EndResult{
        address pool;
        uint price;
        int decimalDifference;
        uint amonutIn;
        uint24 fee;
        bool invert; 
        string dexVersion;
    }
}

contract swapGoerli{

    enum CONTRACT_TYPE{
        factoryV3,
        factoryV2,
        poolV3,
        poolV2,
        routerV3,
        routerV2
    }

    enum CONTRACT_ACTION{
        getPairs,
        getPrice,
        swap
    }

    struct SwapInfo{
        address _addrPool;
        uint priceRatio;
    }

    mapping(string =>mapping(string => address)) dexsToSymbols;
    mapping(string => uint24)feeOfTheDex;

    address immutable admin;
    // address Weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; for ethereum main chain
    // 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;for goerli chain
    address Weth;
    ItypeData.EndResult[] totalPriceRatios;

    event SetNewAddress(string , string);
    event GotAllPrices();
    event SetFeeDex(string , uint24);


    modifier onlyAdmin(){
        require(msg.sender == admin , "not the admin");
        _;
    }

    modifier isAmount(){
        require(msg.value > 0 , "amount does not exist");
        _;
    }

    modifier isToken(address token){
        require(token !=address(0) , "address token does not exits");
        _;
    }

    constructor(address _weth){
        admin = msg.sender;
        Weth = _weth;
    }

    function setDexSymbolContracts(string calldata dexName,string calldata symbol,address contractAddress) external onlyAdmin{
        require(dexsToSymbols[dexName][symbol] == address(0) , "dex address is set");
        dexsToSymbols[dexName][symbol] = contractAddress;
        emit SetNewAddress(dexName , symbol);
    }

    function setFeeOfDex(string memory contractType , uint24 feeAmount)external onlyAdmin{
        require(feeOfTheDex[contractType] == 0 ,"fee is set");

        feeOfTheDex[contractType] = feeAmount;
        emit SetFeeDex(contractType , feeAmount);
    }

    function removeFeeOdDex(string memory contractType)external onlyAdmin{
        delete feeOfTheDex[contractType];
    }

    function deletedexContractAddress(string  memory dex , string memory contractType)external onlyAdmin returns(bool){
        
        bool status = dexsToSymbols[dex][contractType] == address(0) ? false : true;
        
        delete dexsToSymbols[dex][contractType];

        return status;
    }

    function getAllPrices(address token0,address token1 , uint amountIn)public view returns(ItypeData.EndResult [] memory PriceRatios){

        uint totalPoolCount;
        uint totalFills;
        bool isUniSwapV2;
        bool isSushiSwap;
        uint uniV3Count = getCountOfPoolV3(token0 , token1 , "UNISWAPV3");
        // uint pancakeCount = getCountOfPoolV3(token0 , token1 , "PANCAKESWAPV3");

        if(isPoolPairAvailable(token0 , token1 , "UNISWAPV2") != false){isUniSwapV2 = true;totalPoolCount++;}
        if(isPoolPairAvailable(token0 , token1 , "SUSHISWAPV2") != false){isSushiSwap = true; totalPoolCount++;}

        totalPoolCount += uniV3Count;

        if(totalPoolCount == 0){
            PriceRatios =new ItypeData.EndResult[](0);
            return PriceRatios;
        }
        
        PriceRatios =new ItypeData.EndResult[](totalPoolCount);

        ItypeData.EndResult[] memory uniContractsV3 = uniswapV3GetPrices(token0 , token1 , amountIn ,"UNISWAPV3");
        totalFills = uniContractsV3.length;
            // ItypeData.EndResult[] memory pancakeContractsV3 = uniSwapV3GetPrices(token0 , token1 , amountIn ,"pancakeswapV3");

        if(isUniSwapV2){
            ItypeData.EndResult memory uniContractsV2 = uniswapV2GetPrice(token0 , token1 , amountIn , "UNISWAPV2");
            PriceRatios[totalFills] = uniContractsV2;
            totalFills++;
        }

        if(isSushiSwap){
            ItypeData.EndResult memory sushiContractsV2 = uniswapV2GetPrice(token0 , token1 , amountIn , "SUSHISWAPV2");
            PriceRatios[totalFills] = sushiContractsV2;
        }
            // uniswapV2GetPrice(token0 , token1 , amountIn , "pancakeV2");

        for(uint i = 0 ; i < uniV3Count ; i++){
            PriceRatios[i] = uniContractsV3[i];
        }

            // for(uint i = 0 ; i < pancakeCount ; i++){
            //     PriceRatios[i] = pancakeContractsV3[i];
            // }
    }
    function uniswapV3GetPrices(address token0,address token1 , uint amountIn , string memory contractType)public view returns( ItypeData.EndResult [] memory ){
        
        address [] memory pairAddress = uniswapV3GetPoolPair(token0 , token1 , contractType);
        uint[] memory priceCount = new uint[](pairAddress.length);
        uint count;
        
        ItypeData.EndResult [] memory uniswapPools = new ItypeData.EndResult[](pairAddress.length);

        uint8 decimal0 = IERC20(token0).decimals();
        uint8 decimal1 = IERC20(token1).decimals();

        bool invert  = token0 == IUniswapPoolsV3(pairAddress[0]).token0() ? true : false;
        int decimalDifference = getDecimalDiffenrence(decimal0 , decimal1 , invert);

        for(uint i = 0 ; i <  pairAddress.length ; i++){
            
            if(pairAddress[i] == address(0))continue;

            (uint160 sqrtPriceX96,,,,,,) = IUniswapPoolsV3(pairAddress[i]).slot0();
            priceCount[count] = sqrtPriceX96;
            
            uint24 fee = getFeeOfDex(i ,contractType);

            uniswapPools[count] = ItypeData.EndResult(pairAddress[i] , priceCount[count] ,decimalDifference , amountIn , fee , invert , contractType);

            count++;
        }
        return uniswapPools;
    }

    function getFeeOfDex(uint indx ,string memory contractType)internal pure returns(uint24){
        uint24[3] memory uniswapFees = [uint24(500),3000,10000];
        uint24[4] memory pancakeswapFees = [uint24(100),uint24(500),2500 ,10000];

        if(keccak256(abi.encode(contractType)) == keccak256(abi.encode("UNISWAPV3"))){
            return uniswapFees[indx];
        }else if (keccak256(abi.encode(contractType)) == keccak256(abi.encode("PANCAKESWAPV3"))){
            return pancakeswapFees[indx];
        }

        return 0;
    }

    function uniswapV3GetPoolPair(address token0,address token1 , string memory contractType)public view returns(address[] memory){

        uint24[3] memory uniswapFees = [uint24(500),3000,10000];
        uint24[4] memory pancakeswapFees = [uint24(100),uint24(500),2500 ,10000];
        uint24[] memory fees;
        address[] memory uniswapPair;
        uint poolCounts;
        
        address  factoryAddress = dexsToSymbols[contractType]["FACTORYV3"];

        if(keccak256(abi.encode(contractType)) == keccak256(abi.encode("UNISWAPV3"))){
            fees =new uint24[](uniswapFees.length);

            for(uint i = 0 ; i < uniswapFees.length ; i++){
                fees[i] = uniswapFees[i];
            }
        }

        else if(keccak256(abi.encode(contractType)) == keccak256(abi.encode("PANCAKESWAPV3"))){
            fees = new uint24[](pancakeswapFees.length);
        
            for(uint i = 0 ; i< pancakeswapFees.length ; i++){
                fees[i] = pancakeswapFees[i];
            }
        }
        
        uniswapPair = new address[](countPoolAddressesV3(token0 , token1 ,factoryAddress , fees));
        
        for(uint i = 0 ; i < fees.length ; i++){
            
        address tempAddress = IUniswapFactoryV3(factoryAddress).getPool(token0,token1,fees[i]);
        if(tempAddress != address(0)){
                uniswapPair[poolCounts] = tempAddress;
                uniswapPair[poolCounts] = tempAddress;
                poolCounts++;
            }
        }

        return uniswapPair;
    }

    function countPoolAddressesV3(address token0 ,address token1 , address factoryAddress , uint24 [] memory fees)public view returns(uint){

        uint count = 0;

        for(uint i = 0 ; i < fees.length ; i++){

        address tempAddress = IUniswapFactoryV3(factoryAddress).getPool(token0,token1,fees[i]);
        
        if(tempAddress != address(0)){
            count++;
            }
        }
        return count;
    }

    function getCountOfPoolV3(address token0 ,address token1 ,string memory contractType)public view returns(uint){
        
        address  factoryAddress = dexToContractAddress(contractType , "FACTORYV3");
        
        uint24[3] memory uniswapFees = [uint24(500),3000,10000];
        uint24[4] memory pancakeswapFees = [uint24(100),uint24(500),2500 ,10000];
        uint24[] memory fees;

        if(keccak256(abi.encode(contractType)) == keccak256(abi.encode("UNISWAPV3"))){
            fees =new uint24[](uniswapFees.length);

            for(uint i = 0 ; i < uniswapFees.length ; i++){
                fees[i] = uniswapFees[i];
                
            }
        }
        else if(keccak256(abi.encode(contractType)) == keccak256(abi.encode("PANCAKESWAPV3"))){
            fees = new uint24[](pancakeswapFees.length);
        
            for(uint i = 0 ; i< pancakeswapFees.length ; i++){
                fees[i] = pancakeswapFees[i];
            }
        }
        
        return countPoolAddressesV3(token0 , token1 ,factoryAddress , fees);
    }

    function uniswapV2GetPrice(address token0,address token1 , uint amountIn , string memory contractType)public
    isToken(token0) view returns(ItypeData.EndResult memory){
        address factory = dexToContractAddress(contractType , "FACTORYV2");
        address router  = dexToContractAddress(contractType ,"ROUTERV2");
        uint24 feeDexV2 = feeOfTheDex[contractType];
        
        require(factory != address(0) , "dex factory address is not set");
        require(router != address(0) , "dex Router address is not set");
        
        address PairPool = UniswapV2GetPoolPair(token0 , token1 , factory);
        bool invert  = token0 == IUniswapPoolsV3(PairPool).token0() ? false : true;

        if(PairPool == address(0)){
            ItypeData.EndResult memory notFound = ItypeData.EndResult(PairPool , 0 , 0 , amountIn , feeDexV2 , invert , contractType);
            return notFound;
        }

        (uint reserveIn , uint reserveOut,) = IUniswapPoolV2(PairPool).getReserves();
        address tokenIn = IUniswapPoolV2(PairPool).token0();
        
        (reserveIn , reserveOut) = tokenIn == token0 ? (reserveIn , reserveOut) : (reserveOut , reserveIn);
        (token0, token1) = tokenIn == token0 ? (token0 , token1) : (token1 , token0);

        uint amountOut = IUniswapRouterV2(router).getAmountOut(amountIn, reserveIn , reserveOut);

        ItypeData.EndResult memory endResult = ItypeData.EndResult(PairPool , amountOut , 0 , amountIn, feeDexV2 , invert , contractType );

        return endResult;
    }

    function UniswapV2GetPoolPair(address token0,address token1,address factoryAddress)
    public view returns(address){
        address poolAddress = IUniswapFactoryV2(factoryAddress).getPair(token0 , token1);
        
        return poolAddress;
    }

    function executeSwap(address tokenIn ,address tokenOut , uint amountIn ,uint24 fee , string memory contractType)
    public payable 
    isToken(tokenIn){

        if(keccak256(abi.encode(contractType)) == keccak256(abi.encode("UNISWAPV3")) || keccak256(abi.encode(contractType)) == keccak256(abi.encode("PANCAKESWAPV3"))){
            
            UniswapV3Execute(tokenIn , tokenOut , amountIn , fee , contractType);

        }else{
            UniswapV2Execute(tokenIn , tokenOut , amountIn, contractType);
        }
    } 

    function UniswapV2Execute(address tokenIn ,address tokenOut , uint amountIn, string memory contractType)
    public payable 
    isToken(tokenIn){
        
        address payable RouterV2 = payable (dexToContractAddress(contractType ,"ROUTERV2"));
        uint deadline =block.timestamp + 30 minutes;
        uint amountOutMin = 0; //for testing

        address [] memory path = new address[](2);
        path[0] = tokenIn; 
        path[1] = tokenOut; 

        if(tokenIn == Weth){
            require(msg.value > 0 ,"not enough ETH");
            
            IUniswapRouterV2(RouterV2).swapExactETHForTokens{value: msg.value}(amountOutMin , path, msg.sender , deadline);
        }
        else if(tokenOut == Weth){
            require(IERC20(tokenIn).balanceOf(msg.sender)  >= amountIn , "not enough tokens");

            IERC20(tokenIn).transferFrom(msg.sender ,address(this) ,amountIn);
            IERC20(tokenIn).approve(RouterV2 ,amountIn);

            IUniswapRouterV2(RouterV2).swapExactTokensForETH(amountIn , amountOutMin ,path ,msg.sender ,deadline);
        }
        else{
            require(msg.value == 0 , "eth must not be send");
            require(IERC20(tokenIn).balanceOf(msg.sender)  >= amountIn , "not enough tokens");
            
            IERC20(tokenIn).transferFrom(msg.sender ,address(this) ,amountIn);
            IERC20(tokenIn).approve(RouterV2 ,amountIn);

            IUniswapRouterV2(RouterV2).swapExactTokensForTokens(amountIn , amountOutMin , path , msg.sender ,deadline);
        }      
    }

    function UniswapV3Execute(address tokenIn ,address tokenOut , uint amountIn ,uint24 fee, string memory contractType)
    public payable 
    isToken(tokenIn) {

        require(tokenIn != address(0) , "not correct address");

        if(msg.value > 0) require(msg.value == amountIn , "not correct amount");
        
        address  RouterV3 = dexToContractAddress(contractType , "ROUTERV3");
        uint24[3] memory uniswapFees = [uint24(500),3000,10000];
        uint24[4] memory pancakeswapFees = [uint24(100),500,2500 ,10000];
        uint deadline = block.timestamp + 60 minutes;
        uint256 amountOutMinimum = 0;// for testing
        uint160 sqrtPriceLimitX96 = 0;//for testing
        IUniswapRouterV3.ExactInputSingleParams memory params;

        if(keccak256(abi.encode(contractType)) == keccak256(abi.encode("UNISWAPV3"))){

            params = 
            IUniswapRouterV3.ExactInputSingleParams(tokenIn , tokenOut , fee 
                                                   ,msg.sender , deadline , amountIn , amountOutMinimum ,sqrtPriceLimitX96);

        }else if(keccak256(abi.encode(contractType)) == keccak256(abi.encode("PANCAKESWAPV3"))){

            params = 
            IUniswapRouterV3.ExactInputSingleParams(tokenIn , tokenOut , fee 
                                                    ,msg.sender , deadline , amountIn , amountOutMinimum ,sqrtPriceLimitX96);

        }

        if(tokenIn == Weth){
        IUniswapRouterV3(RouterV3).exactInputSingle{value : msg.value}(params);
        }
        else {
        
        IERC20(tokenIn).transferFrom(msg.sender , address(this) , amountIn);
        IERC20(tokenIn).approve(RouterV3 ,amountIn);

        IUniswapRouterV3(RouterV3).exactInputSingle(params);
        }
    }

    function BancorGetPrice(address token0 , address tokenOut,uint amountIn)
    public view returns(ItypeData.EndResult memory)
    {
        address bancorNetWorkInfo = 0x8E303D296851B320e6a697bAcB979d13c9D6E760;
        address bancorNetWork     = 0xeEF417e1D5CC832e619ae18D2F140De2999dD4fB;

        uint amountOut = IBancorNetworkInfo(bancorNetWorkInfo).tradeOutputBySourceAmount(token0, tokenOut , amountIn);
        bool statusTrade = IBancorNetworkInfo(bancorNetWorkInfo).tradingEnabled(tokenOut);

        ItypeData.EndResult memory endResult = ItypeData.EndResult(bancorNetWork , amountOut, 0 , amountIn,  0 , false , "BANCORV3");

        

        
        return endResult;
    }

    function BancorSwap(address tokenIn , address tokenOut , uint amountIn)public payable isToken(tokenIn) 
    {

        address payable bancorNetWork =payable (0xeEF417e1D5CC832e619ae18D2F140De2999dD4fB);
        uint minAmountOut = 0; // for testing
        uint deadline =block.timestamp + 60 minutes;

        if(tokenIn == Weth){
            require(msg.value > 0 ,"not enough Eth");
            require(msg.value == amountIn ,"not correct amount");

            tokenIn = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        }
        else{
            require(IERC20(tokenIn).balanceOf(msg.sender) >= amountIn, "token not sufficient");
        }
        
        IBancorNetwork(bancorNetWork).tradeBySourceAmount{value : msg.value}(tokenIn, tokenOut, amountIn
                                                                            ,minAmountOut, deadline, msg.sender);
    }


    /////////////////////////////////////////////////////////////////////////////////////

    function multiplation(uint amountIn ,uint ratio)internal pure returns(uint){
        return amountIn * ratio;
    }

    function getDecimalDiffenrence(uint decimal0,uint decimal1 , bool inverInputs)public pure returns(int){
        
        return inverInputs ? int(decimal1 - decimal0) : int(decimal0 - decimal1);
    }

    function getDexFee(string memory dexversion)public view returns(uint24){
        return feeOfTheDex[dexversion];
    }

    function dexToContractAddress(string  memory dex , string memory contractType)public view returns(address){
        return dexsToSymbols[dex][contractType];
    }

    function isPoolPairAvailable(address token0,address token1,string memory contractType)public view returns(bool){
        address factory = dexToContractAddress(contractType , "FACTORYV2");
        require(factory !=address(0) , "facotry address does not exist");

        address poolAddress = IUniswapFactoryV2(factory).getPair(token0 , token1);

        return poolAddress !=address(0) ? true : false;
    }

    function getDecimalToken(address token)public view returns(uint8){
        return IERC20(token).decimals();
    }

    function destroyContract()external onlyAdmin{
        selfdestruct(payable(admin));
    }
}