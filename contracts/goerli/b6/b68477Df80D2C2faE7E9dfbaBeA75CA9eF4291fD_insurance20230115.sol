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

//add interface to "Loan"'s makeLoanPayment() function:
interface ILoan {
    function makeLoanPayment() external payable; 
}

//deployed on Goerli at xxx

contract insurance20230115 {
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

    mapping(address => uint256) public uSwapPos;   //record of positions in Uniswap
    address[10] public posAddresses;  //record of POSition ADDRESSES > 0. LIMIT 10 positions available
    
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
    //bool public isBeniPaid; //IS BENIficiary PAID by this contract in this payment interval (has the insured missed a payment)
    uint256 public claimsAuthorized;
    uint256 public claimsPayed;
    uint256 public paymentsMade;

    constructor(){
        insInitialized=false;
        amountFunded=0;
        terms=0;    //let 0 be no terms set. no insurnce can be initialized.
        insEnds=0;   //insured time is over
        minPayment=99999999999999999999999999999999999999; //set high for safe
        paymentDue=99999999999999999999999999999999999999;   //set high for safe payment before ins' initialized
        currPaymentAccum=0;
        breachStatus=0; //see enumerations:0=ok=goodstatus,...., 10=past due
        underWriter=msg.sender; //address of insuring entity=owner=lender if none
        maxBeniPaym=0;
        //isBeniPaid=false;
        posAddresses[0]=WETH;   //initialzie pos'[0] as WETH
        claimsAuthorized=0;
        claimsPayed=0;
        //CALCUlate PAYments REQUIRED = number of payments required (so far) to date. 
        paymentsMade=0;
    
    }

    function setTerms(uint256 _terms) internal returns (uint256 newTerms) {
        newTerms=0;
        if(_terms==1){
            //set premium payment terms to "monthly" at "5/10000" of initial funding amount
            //minPayment=(fundsPromised*5)/10000;
            minPayment=(fundsPromised*12)/1000;
            minPayment=minPayment/12;
            paymentInterval=(60*60*24*30); //payment needed every 'month'
            newTerms=1;
        }
        if(_terms==2){
            //set premium payment terms to "test-speed" at "5/10000" of initial funding amount
            minPayment=(fundsPromised*12)/1000;
            minPayment=minPayment/12;
            paymentInterval=(60*5); //payment needed every '5 min'
            newTerms=2;
        }
    }

    //Loan Contract to call this function and recieves back the monthly payment
    function proposeIns(
        uint256 _terms, address _beni, address _fundMngr, address _insured, 
        address _primOracle, uint256 _baseFunding, uint256 _insEnds, uint256 _maxBeniPaym
    ) external returns (uint256){
        if( insInitialized==false){
            fundsPromised=_baseFunding;
            terms=setTerms(_terms);
            beni=_beni;                 //address of insurance BENIficiary
            fundMngr=_fundMngr;         //address of Fund Manager (for Uniswap trading)
            insured=_insured;           //address of the insurred insturment (loan contracts borrower)
            primOracle=_primOracle;     //address of PRIMARY ORACLE (loan contract)
            insEnds=_insEnds;
            
            maxBeniPaym=_maxBeniPaym;
            return minPayment;  //(fundsPromised*5)/10000;  
        }else{
            return 99999999999999999999999999;
        }
    }

    function initializeIns() internal{
        //set paymentDue="now" + 1 month
        insIniDateTime=block.timestamp; //set loan start timeStamp
        paymentDue=insIniDateTime + paymentInterval; //unix time of when the next loan payment is due
        insInitialized=true;
        paymentsMade=0;
    }

    function terminateIns() internal{
        //reset all var's to default
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
        claimsAuthorized=0;
        claimsPayed=0;
        paymentsMade=0;
        //isBeniPaid=false;

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
        //_move enums:10="owner to forgive payment", 20="owner to terminate",  30="
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
                insEnds=0;  //sets contract to terminate so all funds can be liquidated
            }
        }
    }
    
    //CALCUlate PAYments REQUIRED = number of payments required (so far) to date. 
    function calcPaymentsRequired() public view returns(uint256){
        //require(loanInitialized==true);
        uint256 paymentsRequired;
        if(insInitialized){
            paymentsRequired=(block.timestamp-insIniDateTime)/paymentInterval;
        }else{
            paymentsRequired=0;
        }

        
        return paymentsRequired;
    }

    function calcBreachStatus() public{
        //require(insInitialized==true);
        //require(breachStatus==0); //check for payment being made after breach !!!!!!!!!!!!!!!!!!!!!!
        uint256 _paymRequired=calcPaymentsRequired();
        if(currPaymentAccum>minPayment){
            currPaymentAccum=currPaymentAccum-minPayment;
            paymentsMade++;
            
            uint256 makeUpPaymentsNeeded=_paymRequired-paymentsMade;
            uint256 makeUpPaymentsAvailable=currPaymentAccum/minPayment;
            if(makeUpPaymentsAvailable>makeUpPaymentsNeeded){ makeUpPaymentsAvailable=makeUpPaymentsAvailable;}           
            if(makeUpPaymentsNeeded>0){
                for(uint i=0; i>makeUpPaymentsAvailable; i++){
                    if(currPaymentAccum>=minPayment){
                        currPaymentAccum=currPaymentAccum-minPayment;
                        paymentsMade++;
                    }//calculate new balance
                }
            }
            
        }
        if(paymentsMade<_paymRequired){
            
            //payment is past due
            breachStatus=10;
        }

    }
    
    function payPremium() external payable returns (bool){
        currPaymentAccum=currPaymentAccum + msg.value;
        calcBreachStatus();
        //update paymentDue
        if(block.timestamp>paymentDue){
            paymentDue=paymentDue + paymentInterval;    
        }
        return true;
    }

    function collectPayment(uint256 _paymRequest) external {
        require(msg.sender==underWriter);
        if(insEnds>block.timestamp){
            //pay owner paymRequest from "contract balance" - "funds promised"(if avail)
            //!!!!!!!!!!!!! needs review for case where liquidation is needed !!!!!!!!!!
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
            //if Owner/Underwriter has recieved 'all' funds THEN set insInitialize=False
            uint256 contrMinBalance=8363390000000000;   //amount in wei for about $10 in ETH
            if(address(this).balance<contrMinBalance){
                terminateIns();
            }

        }
    }

    function liquidateAll() internal {
        //search through all positions for balances>0 AND Liquidate to ETH
        //NOTE "zero" index researved for WETH
        for (uint i = 0; i < 10; i++) {
            //IF zero balance account found THEN Sell Position
            if (uSwapPos[posAddresses[i]] > 0) {
                //sell position
                //amountOut=swapExactInputSingle(uSwapPos[posAddresses[i]], posAddresses[i], posAddresses[0]);
                swapExactInputSingle(uSwapPos[posAddresses[i]], posAddresses[i], posAddresses[0]);
            }
        }
    }
    
    function payBeni() external returns(uint256){
        //require(isBeniPaid==false);
        require(insInitialized==true);
        require(claimsAuthorized>claimsPayed);
        //breachStatus=10;
        require(breachStatus==0);
        //!!!!!!!!!!!!!!!!!!!! add "ins active" AND NOT Breached requirement
        //check available funds
        if(address(this).balance<maxBeniPaym){
            //Liquidate ALL Funds!!!!!!!!!!!! Fund MNGR to keep appropriate funds in "balance" OR all funds will Liquidate!
            liquidateAll();
        }  
        
        require(address(this).balance>maxBeniPaym); //!!!!!!!!!!check this. will the contract balance update fast enough??????
        //note maxBeniPaym to be set with terms and maintained per due date(s)
        //(bool success, ) = beni.call{value: maxBeniPaym}("");
        //require(success, "Failed to send Ether");
        /*
        IF 'beni' is a loan contract THNE call Loan's makeLoanPayment function with payment
        interface ILoan {
        function makeLoanPayment() external payable; 
        */
        uint256 maxClaimPays=fundsPromised/maxBeniPaym; //calculate "max amount of claims that can be paid"
        if(maxClaimPays>=claimsPayed){
            ILoan loanContr=ILoan(beni);  //create interface ie:Iweth9 iWeth9=Iweth9(WETH);
            loanContr.makeLoanPayment{value: maxBeniPaym};
            //isBeniPaid=true;
            claimsPayed++;
        }   
        return claimsPayed;
    }

    //oracle is calling for Benificiary to be paid
    function requestClaim() external {
        //oracle calls for Benificiary to be paid per terms
        require(msg.sender==primOracle);
        claimsAuthorized++;
        //return claimsAuthorized;

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
    function reNameFundMngr(address newFundMngr) external{
        require(msg.sender==underWriter);
        fundMngr=newFundMngr;
    }

    //Rename underwriter
    function reNameUnderWriter(address newUnderWriter) external{
        require(msg.sender==underWriter);
        underWriter=newUnderWriter;
    }

    //*************** functions for Uniswqp ***************

    //change ETH for WETH9. "purchase"
    function swapEthForWETH(uint256 _amount) public {
        require(msg.sender==fundMngr);
        Iweth9 iWeth9=Iweth9(WETH); 
        iWeth9.deposit{value:_amount}();
        uSwapPos[WETH]=uSwapPos[WETH] + _amount;
        
    }

    /*
    *************************** Enumerations Of Position Indexes *************************
    0= reserved for WETH address
    1 to 10: reserved for position addresss
    ....
    10000: range reserved for errors
    10001= "default error"
    */
    function getPosIndex(address posAddr) public view returns(uint256 newIndex){
        newIndex=10001; //default "error" return. See "enumerations of position indexes"
        //check each posAddresses[] for posAddr
        // for loop
        for (uint i = 0; i < 10; i++) {
            //if (i == 3) {
                // Skip to next iteration with continue
            //    continue;
            //}
            if (posAddresses[i] == posAddr) {
                // Exit loop with break
                newIndex=i;
                break;
            }
        }
        //IF no posAddresses[] exist with "posAddr" THEN check EACH posAddr' amounts for zero balance
        if (newIndex==10001){
            //check each posAddresses[] for zero balance
            for (uint i = 0; i < 10; i++) {
                //IF zero balance account found THEN reAssign "posAddr" to "posAddresses[]"
                if (uSwapPos[posAddresses[i]] == 0) {
                    // Exit loop with break
                    newIndex=i;
                    break;
                }
            }
        }
        
    }

    //purchase a new position. Buy "posAddr" with "amountIn" of WETH
    function buy(uint256 amountIn, address posAddr) public returns(uint256 amountOut){
        require(msg.sender==fundMngr);
        //require "pos1" qty to be >= "amountOf". 
        uint256 posIndex=getPosIndex(posAddr);//find posAddresses[] to use for pos2Addr. IF all pos's are used THEN cancel function
        require(posIndex<11); //IF "error" (enum 10001="Index not available")
        //!!!!!!!!!!CONTINUE only if posAddresses[posIndex] is set!!!!!!!!!!!!
        amountOut=swapExactInputSingle(amountIn, posAddresses[0], posAddresses[posIndex]);
        
    }

    //Sell "amountIn" of token "posIndex" for WETH.
    function sell(uint256 amountIn, uint256 posIndex) public returns(uint256 amountOut){
        require(msg.sender==fundMngr);
        require(uSwapPos[posAddresses[posIndex]]>=amountIn);//require token balance >= amountIn
        amountOut=swapExactInputSingle(amountIn, posAddresses[posIndex], posAddresses[0]);
    }

    //swap one position for another
    function swap(uint256 amountIn, uint pos1, uint pos2) public returns(uint256 amountOut){
        require(msg.sender==fundMngr);
        //require "pos1" qty to be >= "amountOf". 
        //require pos1 and pos2 address != 'null'
        amountOut=swapExactInputSingle(amountIn, posAddresses[pos1], posAddresses[pos2]);
    }
    

    function swapWethForEth(uint256 _amount) public {
        require(msg.sender==fundMngr);
        Iweth9 iWeth9=Iweth9(WETH); 
        iWeth9.withdraw(_amount);
        uSwapPos[WETH]=uSwapPos[WETH] - _amount;
    }

    function swapExactInputSingle(uint256 amountIn, address _tokenIn, address _tokenOut) internal returns (uint256 amountOut){
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

        //rocord new position(s)
        uSwapPos[_tokenOut]=uSwapPos[_tokenOut] + amountOut;
        uSwapPos[_tokenIn]=uSwapPos[_tokenIn] - amountIn;
          
        
    }
    /*
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

        //rocord new position(s)
        uSwapPos[_tokenOut]=uSwapPos[_tokenOut] + amountOut;
        uSwapPos[_tokenIn]=uSwapPos[_tokenIn] - amountIn;
    }
    */
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