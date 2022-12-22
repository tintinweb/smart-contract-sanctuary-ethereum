// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6; //tells compiler wich version to use. use 0.7.6 for Uniswap per "Uniswap V3"
pragma abicoder v2;     //tells compliler to support "struct" as Call Data. Since in 0.8.0 the v2 ABI Coder is used by defaul


import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";  //contains most of func's for Swapping
//import "@openzeppelin/contracts/interfaces/ISwapRouter.sol";

//Interface to an IERC20 coin. An "instance" of the coin(token)
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

//interface to WETH9
interface Iweth9 {
    function deposit() external payable ;
    function withdraw(uint wad) external ;
}

//pragma solidity ^0.8.1;

//deployed on Goerli at xxx


contract insurance20221218 {
    //*****************var's for Uniswap****************
    address public constant routerAddress =
        0xE592427A0AEce92De3Edee1F18E0157C05861564; //goerli network for Uniswap V3 
    ISwapRouter public immutable swapRouter = ISwapRouter(routerAddress);   //sets Interface for Uniswap "router" SC

    //Tokens to Swap- Network Specific: Goerli network
    //needs to by dynamic at runtime
    //address public constant LINK = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address public constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    
    //IERC20 public wethToken = IERC20(WETH);  //sets IERC20 Interface for "LINK" address

    // For this example, we will set the pool fee to 0.3%.
    //needs to be dynamic. depending on Risk of "LP". 
    uint24 public constant poolFee = 3000;
    //*****************end var's for Uniswap***********************

    address public beni; //address of insurance BENIficiary
    address public fundMngr;    //address of Fund Manager (for Uniswap trading)
    address public insured;     //address of the insurred insturment (loan contracts borrower)
    address public underWriter; //address of underWriter==owner
    address public primOracle;  //address of PRIMARY ORACLE (loan contract)
    bool public insInitialized;  //TRUE if insurance agrement is active
    uint256 public terms;   //enumerated "terms" of insurance: ie premium calculator
    uint256 public fundsPromised; //base funding=initial funding amount= amount to be researved
    uint256 public amountFunded;    //current amount funded
    uint256 public insEnds; //unix time of when insurance policy Ends
    uint256 public minPayment;  //minumum payment amount
    uint256 public paymentDue; //unix time of when the next premium payment is due
    uint256 public insIniDateTime; //time stamp of ins' initialization
    uint256 public paymentInterval; //seconds between payments
    uint256 public currPaymentAccum; //CURRent PAYMENT intervals ACCUMulator of payments made (if insured pays partial payments)
    uint256 public breachStatus;    //enum for status of breach of contract. 0= nonbreached
    uint256 public maxBeniPaym;     //MAXimum to pay the BENIficiary at any given time
    bool public isBeniPaid; //IS BENIficiary PAID by this contract in this payment interval (has the insured missed a payment)

    constructor(){
        insInitialized=false;
        amountFunded=0;
        terms=0;    //let 0 be no terms set. no insurnce can be initialized.
        insEnds=0;   //insured time is over
        minPayment=99999999999999999999999999999999999999; //set high for safe
        paymentDue=0;   //??????????? check for safety
        currPaymentAccum=0;
        breachStatus=0; //see enumerations:0=ok=goodstatus,...., 10=past due
        underWriter=msg.sender; //address of insuring entity=owner=lender if none
        maxBeniPaym=0;
        isBeniPaid=false;
    }

    function setTerms(uint256 _terms) internal returns (uint256 newTerms) {
        newTerms=0;
        if(_terms==1){
            //set premium payment terms to "monthly" at "5/10000" of initial funding amount
            minPayment=(fundsPromised*5)/10000;
            paymentInterval=(60*60*24*30); //payment needed every 'month'
            newTerms=1;
        }
    }
    function proposeIns(
        uint256 _terms, address _beni, address _fundMngr, address _insured, 
        address _primOracle, uint256 _baseFunding, uint256 _insEnds, uint256 _maxBeniPaym
    ) public{
        if( insInitialized==false){
            terms=setTerms(_terms);
            beni=_beni;                 //address of insurance BENIficiary
            fundMngr=_fundMngr;         //address of Fund Manager (for Uniswap trading)
            insured=_insured;           //address of the insurred insturment (loan contracts borrower)
            primOracle=_primOracle;     //address of PRIMARY ORACLE (loan contract)
            insEnds=_insEnds;
            fundsPromised=_baseFunding;
            maxBeniPaym=_maxBeniPaym;
        }
    }

    function initializeIns() internal{
        //set paymentDue="now" + 1 month
        insIniDateTime=block.timestamp; //set loan start timeStamp
        paymentDue=insIniDateTime + paymentInterval; //unix time of when the next loan payment is due
        insInitialized=true;
    }

    //(underwriter) send funds to Contract to activate once total amount is present
    function fundIns() public payable {
        //get address of lender
        //get address of caller
        //check var's to be in bounds: 
        amountFunded=amountFunded + msg.value;
        if (amountFunded>=fundsPromised && insInitialized==false){
            initializeIns();
        }
        
    }

    function resolveBreach(uint256 _move) public{
        //_move enums:10="owner to forgive", 20="owner to terminate"
        require(breachStatus!=0);
        if(breachStatus==10){
            //non-paymnet preach
            require(msg.sender==underWriter);  //!!!!!!!!!!verify "owner" keyword
            if(_move==10){
                //see _move enums
                breachStatus=0;
                paymentDue=paymentDue + paymentInterval;
            }
            if(_move==20){
                //call "insurance termination" routine(s)
            }
        }
    }
    
    function calcBreachStatus() public{
        require(insInitialized==true);
        require(breachStatus==0);
        if(paymentDue>block.timestamp){
            if(currPaymentAccum>=minPayment){
                currPaymentAccum=currPaymentAccum-minPayment;
                paymentDue=paymentDue + paymentInterval;
                isBeniPaid=false;
            }
        }else{
            //payment is past due
            breachStatus=10;
        }

        
    }
    

    function payPremium() public payable {
        currPaymentAccum=currPaymentAccum + msg.value;
        calcBreachStatus();
       
    }

    function collectPayment(uint256 _paymRequest) external {
        require(msg.sender==underWriter);
        if(insEnds<block.timestamp){
            //pay owner paymRequest from "contract balance" - "funds promised"(if avail)
            if((address(this).balance-fundsPromised)>_paymRequest){
                (bool success, ) = underWriter.call{value: _paymRequest}("");
                require(success, "Failed to send Ether");
            }
        }else{
            //insurance term is over pay all
            (bool success, ) = underWriter.call{value: address(this).balance}("");
            require(success, "Failed to send Ether");
            //liquidate investments
            //pay owner
        }
    }

    function payBeni() external{
        //oracle calls for Benificiary to be paid per terms
        require(msg.sender==primOracle);
        require(isBeniPaid==false);
        //note maxBeniPaym to be set with terms and maintained per due date(s)
        (bool success, ) = beni.call{value: maxBeniPaym}("");
        require(success, "Failed to send Ether");
        isBeniPaid=true;

    }

    /*
    // Function to transfer Ether from this contract to address from input. !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    function transfer(address payable _to, uint _amount) public {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    */

    //ReName Fund Manager
    function reFundMngr(address newFundMngr) external{
        require(msg.sender==underWriter);
        fundMngr=newFundMngr;
    }

    //Rename underwriter
    function reNameUnderWriter(address newUnderWriter) external{
        require(msg.sender==underWriter);
        underWriter=newUnderWriter;
    }

    //*************** functions for Uniswqp ***************

    //change ETH for WETH9
    function swapEthForWETH(uint256 _amount) public {
        require(msg.sender==fundMngr);
        Iweth9 iWeth9=Iweth9(WETH); 
        iWeth9.deposit{value:_amount}();
    }

    function swapWethForEth(uint256 _amount) public {
        require(msg.sender==fundMngr);
        Iweth9 iWeth9=Iweth9(WETH); 
        iWeth9.withdraw(_amount);
    }

    function swapExactInputSingle(uint256 amountIn, address _tokenIn, address _tokenOut) external returns (uint256 amountOut){
        require(msg.sender==fundMngr);
        IERC20 inToken = IERC20(_tokenIn);  //sets IERC20 Interface for "LINK" address
        inToken.approve(address(swapRouter), amountIn);
        
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp + 15,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
    }

    function swapExactOutputSingle(uint256 amountOut, uint256 amountInMaximum, address _tokenIn, address _tokenOut)external returns (uint256 amountIn){
        require(msg.sender==fundMngr);
        IERC20 inToken = IERC20(_tokenIn);  //sets IERC20 Interface for "LINK" address
        inToken.approve(address(swapRouter), amountInMaximum);
        //linkToken.approve(address(swapRouter), amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp + 15,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        amountIn = swapRouter.exactOutputSingle(params);

        //transfers "remander" back to sender!
        if (amountIn < amountInMaximum) {
            inToken.approve(address(swapRouter), 0);
            inToken.transfer(address(this), amountInMaximum - amountIn);
        }
    }
    //**************end functions for Uniswap*************


}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
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

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}