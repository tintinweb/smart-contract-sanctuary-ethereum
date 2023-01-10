// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

//deployed on Goerli at xxx

import "@openzeppelin/contracts/access/Ownable.sol";

//interface to WETH9
interface Iinsurance {
    function proposeIns(
        uint256 _terms, address _beni, address _fundMngr, address _insured, 
        address _primOracle, uint256 _baseFunding, uint256 _insEnds, uint256 _maxBeniPaym
    ) external returns (uint256 propPayment);
    //function payBeni() external;
    function requestClaim() external;
    function payPremium() external payable returns (bool);
}

contract loan20230107 is Ownable {

    uint256 public terms; //enumerated terms of contract: 
    /*
    0 = none,
    1= 10% apr, 1'month' paymentInterval, $50 processing fee(one time-set in principal), 
        originLoanAmount/1200 Tot Min (Monthly) Payment, overpayment goes to pricipal, 
        $5 officer fees, $5 developer fee, contract breach at 1'month', 1% insurance premium,
         2'week' drawInterval, %25 (of origninal loan amount) drawMax, %50 funding for initilizaiton
    */
    uint256 public apr; //Anual Percent Rate. as a divisor of balance. ie: balance/apr
    uint256 public loanBalance; //remaing balnace of loan. in Wei
    uint256 public amountFunded; //SUM of amount given to the contract to fund "originLoanAmount". in Wei
    uint256 public originLoanAmount; //orginating loan amount. in Wei
    uint256 public paymentDue; //unix time of when the next loan payment is due
    uint256 public paymentMin; //amount value of the minimum next payment. in Wei.
    uint256 public paymentInterval; //seconds between payments
    uint256 public currPaymentAccum; //CURRent PAYMENT intervals ACCUMulator of payments made (if borrower pays partial payments)
    uint256 public breachStatus; //enumerated value of if loan is in default (breach of contract): 
    uint256 public insuranceFee; //'monthly' fee proposed by the insurance contract
    /*
    "breachStatus":
    000=0=no faults,
    001 to 009 = lender fault: ????
    010 to 090 = borrower fault: 010= min payment not made in time, 020=Forclosure
    100 to 900 = oracle fault: 100=unlisted oracle fault, 

    */

    uint256 public authDrawAmount; //the amount value that is authorized and available to be withdrawn. in Wei.
    uint256 public loanRequExpires; //unix time of when the current(if avail) loan Request Expires
    uint256 public loanRequInterval; //LOAN REQUEST INTERVAL in seconds
    uint256 public minFunding; //minimum amount of funding for loan to initialize per terms. SET HIGH (999999....) for default.
    uint256 public paymentsMade; //count of payments made
    uint256 public paymentsRequired; //count of payments due to date
    uint256 public drawDivisor; //divisor for loan amount to be "Portioned" into. MUST NOT = 0.
    uint256 public drawsMade; //count of draws made 
    uint256 public drawInterval; //seconds between draws. set high(999999999999......)  for safetey.
    uint256 public lastDraw; //time stamp of last draw
    uint256 public loanIniDateTime; //time stamp of loan initialization
    

    bool public borrowerAuthed; //true IF borrower has aggreed to the proposed terms of the lender.
    bool public lenderFunded; //true IF full amount of the originLoanAmount has been provided
    bool public loanInitialized; //true IF loan services have began and all parties agree
    bool public termsProposed; //true IF lender has proposed terms

    address payable public lender; //address of lender= contract owner
    address public borrower; //address of borrower
    address public authAgent; //address of authorizing agent (for draws). officer
    address payable public underWriter; //address of insuring entity(=owner=lender if none)
    address payable public helixAddr; //address of helix main account

    //EVENT LIST HERE:
    event loanRequest(address _from);
    event loanProposal(uint256 terms, uint256 originLoanAmount);

    constructor(){
        //set all public var's default settings
        
        terms=0; //enumerated terms of contract: 0 = none, 1= 10%apr, 1'month' paymentInterval, $50 processing  
        loanBalance=0; //remaing balnace of loan
        amountFunded=0;
        originLoanAmount=0; //orginating loan amount
        paymentDue=0; //unix time of when the next loan payment is due
        paymentInterval=0;
        currPaymentAccum=0;
        paymentMin=0; //amount value of the minimum next payment
        breachStatus=0; //enumerated value of if loan is in default (breach of contract): 0=no problem, 1=
        authDrawAmount=0; //the amount value that is authorized and available to be withdrawn
        loanRequExpires=0; //unix time of when the current(if avail) loan Request Expires
        minFunding=99999999999999999999999999999999999999999999999999999999999;
        paymentsMade=0;
        paymentsRequired=0;
        drawDivisor=1;
        drawsMade=0;
        drawInterval=9999999999999999999999999999999999999;
        lastDraw=0; //time stamp of last draw
        loanIniDateTime=0; 
        apr=1; //set for default. NOTE number is divisor. Must NOT = 0 !!!!!!!!!!!!!!!!!!

        borrowerAuthed=false; //true IF borrower has aggreed to the proposed terms of the lender.
        lenderFunded=false; //true IF full amount of the originLoanAmount has been provided. !!!!!!!!!!!!!! needs work
        loanInitialized=false;
        termsProposed=false;

        lender=payable(msg.sender); //address of lender= contract owner
        //borrower=0; //address of borrower
        authAgent=msg.sender; //address of authorizing agent (for draws). officer
        underWriter=payable(msg.sender); //address of insuring entity=owner=lender if none
        helixAddr=payable(msg.sender); //!!!!!! change on MAINET DEPLOY !!!!!!!!!!!!!!!!
        //loanReqestInterval=60*10; //!!!!!!!!!!!! change on MAINNET DEPLOY !!!!!!!!!!!!!!!!!!!!!

    }

    //resolve a breach
    function resolveBreach(uint256 _move) public onlyOwner {
        /*
        "_move" enumerations: acknowledge=1, forgive payment=2, forgive loan=3, 
        claim insurance=4, reset "breach status"=5, forclose=6.....
        */

        /*
        "breachStatus":
        000=0=no faults,
        001 to 009 = lender fault: ????
        010 to 090 = borrower fault: 010= min payment not made in time, 020=Forclosure,
            030=ins' claims requested
        100 to 900 = oracle fault: 100=unlisted oracle fault, 

        */
        //solve breach (if possible per aggrement terms)
        //determine breach type to solve
        if (breachStatus==10 || breachStatus==30){
            //require lender/owner to resolve breach
            //require(this.owner==msg.sender);
            if(_move==2){ 
                paymentsMade++; 
                //reduce balance per interval. !!!!!!!!!!!!!!!!!!
                breachStatus=0;
            }
            if(_move==3){
                resetLoan();
            }
            if(_move==4){
                Iinsurance insContr=Iinsurance(underWriter);  //create interface ie:Iweth9 iWeth9=Iweth9(WETH);
                insContr.requestClaim();    //NOTE: "payBeni()" (on ins' contr) must be also called once claim is requested
                breachStatus=30; //!!!!!!!!!!!!!!!!! change to enumeration for "insurance" paid BUT "not is good standing"
            }
            if(_move==5){
                //reset breach status to 0. Assumes borrower is "caught up"
                breachStatus=0;
            }
            if(_move==6){
                //Forclose
                breachStatus=20;
                //emit notice to/for all parties
            }
        }
        if (breachStatus==20){
            if(_move==3){
                //recomend "requestCollection();" first
                resetLoan();
            }
        }
    }

    //CALCUlate PAYments REQUIRED = number of payments required (so far) to date. 
    function calcPaymentsRequired() internal {
        require(loanInitialized==true);
        if(loanInitialized){
            paymentsRequired=(block.timestamp-loanIniDateTime)/paymentInterval;
        }else{
            paymentsRequired=0;
        }
    }

    function distributeFees(uint256 currentIntrest, uint256 processFee) internal {
        // pay/distribute fees: intrest->owner, insurance->insurer, manageFee->manager FROM currPayemntAccum
        //transfer(payable(underWriter), insuranceFee); //call payPremium()
        //(bool success, ) = underWriter.call{value: insuranceFee}("");
        if(terms!=40){
            Iinsurance insContr=Iinsurance(payable(underWriter));  //create interface ie:Iweth9 iWeth9=Iweth9(WETH);
            bool premPaid=insContr.payPremium{value: insuranceFee}();
            if(premPaid){ currPaymentAccum=currPaymentAccum-insuranceFee; }//adjust currPayAccum
        }  
        
        address _owner=owner();
        transfer(payable(_owner),currentIntrest);
        currPaymentAccum=currPaymentAccum-currentIntrest;
        
        transfer(payable(helixAddr),processFee);
        currPaymentAccum=currPaymentAccum-processFee;
        
    }

    //this function called WHEN "if(currPaymentAccum>=paymentMin)"
    function calcNewBalance() internal{
        require(loanInitialized==true);
        //require(currPaymentAccum>=paymentMin);
        //calculate new balance with currPaymenAccum. 
        //apply overpayment to Balance IF Terms approve
        uint256 applyToBalance = 0; 
        uint256 overPayment=currPaymentAccum - paymentMin; //will fail if currPaymentAccum<paymentMin
        if (overPayment<0){ overPayment=0;}
        if((terms % 10)==0){
            //apply overpayment to next payment
        }else{
            //apply overpayemtn to balance
            currPaymentAccum=currPaymentAccum-overPayment;  //currPaymentAccum should now be equal to paymentMin
            loanBalance=loanBalance-overPayment;
        }
        /*
        From currPaymentAccum: pay intrest, pay insurance, pay fee(s), pay balance
        fee List: Loan contract manger fee(helix), oracle fee,.....
        */

        //calc per apr
        uint256 currentIntrest=(loanBalance*apr)/100;   
        currentIntrest=currentIntrest/12; //"12" for monthly payment terms only !!!!!!!!!!!
        
        //"process fee"="helix fee"= function of "originLoanAmount"
        /*
        (=originLoanAmount * "intrest percent rate Interval")/("# of payments per Interval" * 1000)
        */
        uint256 processFee=(originLoanAmount*5)/1000;
        processFee=processFee/12;//aka: (originLoanAmount*5)/12000
        
        //NOTE: (currentIntrest + insuranceFee + processFee) MUST NOT BE > paymentMin
        applyToBalance=applyToBalance + (paymentMin-currentIntrest-insuranceFee-processFee); //!!!!!!!!! fees need defined !!!!!!!!!!!
        loanBalance=loanBalance-applyToBalance;
        
        //distribute fees: intrest->owner, insurance->insurer, manageFee->manager
        distributeFees((currentIntrest+applyToBalance), processFee);

        if(loanBalance<=0){
            //LOAN IS paid
            //??????????????????TRANSFER OWNERSHIP (of ??) TO BORROWER.??????????????????
            resetLoan(); //reset loan
        }else{
            //reset: currPaymentAccum, payemntDue,  paymentsMade, ....
            //currPaymentAccum=currPaymentAccum-applyToBalance;
            paymentDue=paymentDue + paymentInterval;
            paymentsMade=paymentsMade + 1;

        }

        
        
    }

    function calcBreachStatus() public {
        require(loanInitialized==true);
        //check current interval time status
        calcPaymentsRequired(); //CALCUlate PAYments REQUIRED
        
        if(currPaymentAccum>=paymentMin){ 
            calcNewBalance(); //calculate new balance
            uint256 makeUpPaymentsNeeded=paymentsRequired-paymentsMade;
            uint256 makeUpPaymentsAvailable=currPaymentAccum/paymentMin;
            if(makeUpPaymentsAvailable>makeUpPaymentsNeeded){ makeUpPaymentsAvailable=makeUpPaymentsAvailable;}           
            if(makeUpPaymentsNeeded>0){
                for(uint i=0; i>makeUpPaymentsAvailable; i++){
                    if(currPaymentAccum>=paymentMin){calcNewBalance(); }//calculate new balance
                }
            }
        }

        if(breachStatus!=20){
            if(paymentsRequired>paymentsMade){ breachStatus=10; } //breachStaqtus "010" = NON MISSED PAYMENT(s)
        }
        
    }

    

    function resetLoan() internal {
        //reset all var's back to constructor. NOT A PUBLIC VAR.
        //set/reset defaultStatus var per terms of agreement
        terms=0; //enumerated terms of contract: 0 = none, 1= 10%apr, 1'month' paymentInterval, $50 processing  
        loanBalance=0; //remaing balnace of loan
        amountFunded=0;
        originLoanAmount=0; //orginating loan amount
        paymentDue=0; //unix time of when the next loan payment is due
        paymentInterval=0;
        currPaymentAccum=0;
        paymentMin=0; //amount value of the minimum next payment
        breachStatus=0; //enumerated value of if loan is in default (breach of contract): 0=no problem, 1=
        authDrawAmount=0; //the amount value that is authorized and available to be withdrawn
        loanRequExpires=0; //unix time of when the current(if avail) loan Request Expires
        minFunding=99999999999999999999999999999999999999999999999999999999999;
        paymentsMade=0;
        paymentsRequired=0;
        drawDivisor=1;
        drawsMade=0;
        drawInterval=9999999999999999999999999999999999999;
        lastDraw=0;
        apr=1;

        borrowerAuthed=false; //true IF borrower has aggreed to the proposed terms of the lender.
        lenderFunded=false; //true IF full amount of the originLoanAmount has been provided
        loanInitialized=false;
        termsProposed=false;

        //lender=0; //address of lender= contract owner
        //borrower=0; //address of borrower
        authAgent=lender; //"Officer"/"Oricale". address of authorizing agent (for draws). officer
        underWriter=lender; //address of insuring entity=owner=lender if none
    }

    function requestLoan(uint256 _terms, uint256 _originLoanAmount) public {
        //check inputs to be in "bounds"
        require(loanInitialized==false);
        if (loanRequExpires==0 || loanRequExpires<block.timestamp){
            resetLoan();
            //set public var's: terms, loanBalance, borrower addr......
            terms=_terms; //enumerated terms of contract: 0 = none, 1= 10%apr, 1'month' paymentInterval, $50 processing  
            originLoanAmount=_originLoanAmount; //orginating loan amount
            loanRequExpires=block.timestamp + loanRequInterval; //unix time of when the current(if avail) loan Request Expires
            borrower=msg.sender; //address of borrower
            
            //call insurance contract for proposed insuranc request
            //emit "loan requ'" event
            emit loanRequest(borrower);
        }
        
    }

    //call this function to Propose Terms OR to reset to Default (if Loan Request has Expired)
    function proposeTerms(uint256 _terms, uint256 _amount, address _insurer) external onlyOwner {
        require(loanInitialized==false);
        if (loanRequExpires!=0 || loanRequExpires>block.timestamp){
            //set public var's: terms, loanBalance, borrower addr......
            terms=_terms; //enumerated terms of contract: 0 = none, 1= 10%apr, 1'month' paymentInterval, $50 processing  
            originLoanAmount=_amount; //orginating loan amount
            loanRequExpires=block.timestamp + loanRequInterval; //unix time of when the current(if avail) loan Request Expires
            termsProposed=true;  
            underWriter=payable(_insurer);
            emit loanProposal(terms, originLoanAmount);//emit "proposal event"
        }else{
            resetLoan();
        }
    }

    //borrower can accept terms IF termsProposed==true
    function acceptTerms(bool _accept) public {
        //get addr of caller
        //verify addr=borrower
        require (termsProposed==true);
        require(loanInitialized==false);
        require(borrower==msg.sender); 
        if(_accept==true){
            borrowerAuthed=true;
            bool setError=setTerms();
            if(setError==true){ loanInitialized=false;}
        }else{
            resetLoan();
        }
        
    }

    function setTerms() internal returns (bool){
        //AB ie 12. B is 1 for overpayment to principle OR 0 if overpayemnt goes to next month payment
        bool setError=true; //!!!!!!!!!!!!!! needs to be set in each "if" block !!!!!!!!!!!!!!!!!!!!
        if(terms==11){
            //init' per terms="1"
            //"1"= 10%apr, 1'month' paymentInterval, $50 processing fee(one time-set in principal), 
            // originLoanAmount/1200 Tot Min (Monthly) Payment, overpayment goes to pricipal, 
            // $5 officer fees, $5 developer fee, contract breach at 1'month', 1% insurance premium, 2'week' drawInterval, 
            // %25 (of origninal loan amount) drawMax, %50 funding for initilizaiton
            originLoanAmount=originLoanAmount+0;    //"50USD"; //!!!!!!!!!need to set standard for adding USD to WEI !!!!!!!!!!!!
            minFunding=originLoanAmount / 2; //???????????????????????????
            paymentMin=originLoanAmount/1200; //amount value of the minimum next payment. ??????????????????????
            breachStatus=0; //enumerated value of if loan is in default (breach of contract): 0=no problem, 1=
            authDrawAmount=0; //the amount value that is authorized and available to be withdrawn
            authAgent=this.owner.address; //owner to authorize. ????????????????????????????????
            //underWriter=payable(this.owner.address); //owner to insure. ???????????????????????????????????????????????
            drawDivisor=4; //set to divide the total loan amount into "4" protions.= max amount of draws
            paymentInterval=60*60*24*30; //payment needed every 'month'
            drawInterval=60*60*24*14; //2 'weeks' between auth'd draws
            lastDraw=0; //timestamp of previouw draw
            authAgent=lender; //lender is authAgent
            //underWriter=lender; //lender is insurer...."proposal"
            apr=10; //divide balance by "10"= 10%
            //!!!!!!call insurance contract's "propose" function (IF underWriter!=lender) 

        }
       
        if(terms==20){
            //init' per terms="1"
            //"2"= 2%apr, 1'month' paymentInterval, $50 processing fee(one time-set in principal), 
            // originLoanAmount/1200 Tot Min (Monthly) Payment, overpayment goes to next payment, 
            // $5 officer fees, (.005*originLoanAmount/12)= developerFee(or processingFee), contract breach at 1'month', 
            //1% insurance premium, 0=drawInterval (all can be drawn upfront), 
            // %100 (of origninal loan amount) drawMax, %50 funding for initilizaiton
            //insuring entity = 'other contract'
            setError=false;
            originLoanAmount=originLoanAmount+ 0;//"50USD"; //!!!!!!!!!need to set standard for adding USD to WEI !!!!!!!!!!!!
            minFunding=originLoanAmount / 2; //???????????????????????????
            apr=2; //divide balance by "2"= 2%
            //calculate payment min with "sum TOtal Instrest and Fees"/number of payments required 
            uint256 totPayments=60; //equal to "5 years of monthly payments"
            uint256 sumTotIntrestAndFees=(5*originLoanAmount*(apr/100))/2; //Sum total intrest and fees
            paymentMin=(originLoanAmount+sumTotIntrestAndFees)/totPayments; //amount value of the minimum next payment. ??????????????????????
            breachStatus=0; //enumerated value of if loan is in default (breach of contract): 0=no problem, 1=
            authDrawAmount=0; //the amount value that is authorized and available to be withdrawn
            authAgent=payable(this.owner.address); //owner to authorize. ????????????????????????????????
            //underWriter=payable(this.owner.address); //owner to insure. ???????????????????????????????????????????????
            drawDivisor=1; //set to divide the total loan amount into "1" protions.= max amount of draws
            paymentInterval=60*60*24*30; //payment needed every month
            drawInterval=0; //all can be drawn upfront
            lastDraw=0; //timestamp of previouw draw
            authAgent=lender; //lender is authAgent
            uint256 insEnds=block.timestamp + (paymentInterval*totPayments);
            Iinsurance insContr=Iinsurance(underWriter);  //create interface ie:Iweth9 iWeth9=Iweth9(WETH);
            insuranceFee=insContr.proposeIns(2, address(this), this.owner.address, address(this), 
                address(this),(originLoanAmount/2), insEnds, paymentMin);
            if(insuranceFee==99999999999999999999999999){ setError=true; } // THEN error 

        }
        

        if(terms==30){
            //TEST SpeedTerms "30"
            //"3"= 2%apr, 5 min paymentInterval, $0 processing fee(one time-set in principal), 
            // originLoanAmount/1200 Tot Min (Monthly) Payment, overpayment goes to next payment, 
            // $5 officer fees, (.005*originLoanAmount/12)= developerFee(or processingFee), contract breach at 1'month', 1% insurance premium, 2'week' drawInterval, 
            // %100 (of origninal loan amount) drawMax, %50 funding for initilizaiton
            //insuring entity = 'other contract'
            setError=false;
            originLoanAmount=originLoanAmount+ 0;//"50USD"; //!!!!!!!!!need to set standard for adding USD to WEI !!!!!!!!!!!!
            minFunding=originLoanAmount / 2; //???????????????????????????
            apr=2; //divide balance by "2"= 2%
            //calculate payment min with "sum TOtal Instrest and Fees"/number of payments required 
            uint256 totPayments=60; //equal to "5 years of monthly payments"
            uint256 sumTotIntrestAndFees=(5*originLoanAmount*(apr/100))/2; //Sum total intrest and fees
            paymentMin=(originLoanAmount+sumTotIntrestAndFees)/totPayments; //amount value of the minimum next payment. ??????????????????????
            breachStatus=0; //enumerated value of if loan is in default (breach of contract): 0=no problem, 1=
            authDrawAmount=0; //the amount value that is authorized and available to be withdrawn
            authAgent=payable(this.owner.address); //owner to authorize. ????????????????????????????????
            //underWriter=payable(this.owner.address); //owner to insure. ???????????????????????????????????????????????
            drawDivisor=1; //set to divide the total loan amount into "1" protions.= max amount of draws
            paymentInterval=60*5; //payment needed every '5 min' (test Speed)
            drawInterval=0; //all can be drawn upfront
            lastDraw=0; //timestamp of previouw draw
            authAgent=lender; //lender is authAgent
            //underWriter=lender; //lender is insurer....is set with "proposal"
            
            //!!!!!!call insurance contract's "propose" function (IF underWriter!=lender)
            Iinsurance insContr=Iinsurance(underWriter);  //create interface ie:Iweth9 iWeth9=Iweth9(WETH);
            /*
            (
            uint256 _terms, address _beni, address _fundMngr, address _insured, 
            address _primOracle, uint256 _baseFunding, uint256 _insEnds, uint256 _maxBeniPaym
            )   
            */
            //!!!!!!!!!!!! NOTE: address(this)=this.owner.address
            uint256 insEnds=block.timestamp + (paymentInterval*totPayments);
            insuranceFee=insContr.proposeIns(2, address(this), this.owner.address, address(this), 
                address(this),(originLoanAmount/2), insEnds, paymentMin);
            if(insuranceFee==99999999999999999999999999){ setError=true; } // THEN error 
            if(insuranceFee==0){ setError=true; }
            require(setError==false, "Ins Fee NOT Set");
        }

        if(terms==40){
            //TEST Speed, NO insurance
            originLoanAmount=originLoanAmount+ 0;//"50USD"; //!!!!!!!!!need to set standard for adding USD to WEI !!!!!!!!!!!!
            minFunding=originLoanAmount / 2; //???????????????????????????
            apr=2; //divide balance by "2"= 2%
            //calculate payment min with "sum TOtal Instrest and Fees"/number of payments required 
            uint256 totPayments=60; //equal to "5 years of monthly payments"
            uint256 sumTotIntrestAndFees=(5*originLoanAmount*(apr/100))/2; //Sum total intrest and fees
            paymentMin=(originLoanAmount+sumTotIntrestAndFees)/totPayments; //amount value of the minimum next payment. ??????????????????????
            breachStatus=0; //enumerated value of if loan is in default (breach of contract): 0=no problem, 1=
            authDrawAmount=0; //the amount value that is authorized and available to be withdrawn
            authAgent=payable(this.owner.address); //owner to authorize. ????????????????????????????????
            //underWriter=payable(this.owner.address); //owner to insure. ???????????????????????????????????????????????
            drawDivisor=1; //set to divide the total loan amount into "1" protions.= max amount of draws
            paymentInterval=60*5; //payment needed every '5 min' (test Speed)
            drawInterval=0; //all can be drawn upfront
            lastDraw=0; //timestamp of previouw draw
            authAgent=lender; //lender is authAgent
            underWriter=lender; //lender is insurer....is set with "proposal"
            
            //!!!!!!call insurance contract's "propose" function (IF underWriter!=lender)
            //Iinsurance insContr=Iinsurance(underWriter);  //create interface ie:Iweth9 iWeth9=Iweth9(WETH);
            /*
            (
            uint256 _terms, address _beni, address _fundMngr, address _insured, 
            address _primOracle, uint256 _baseFunding, uint256 _insEnds, uint256 _maxBeniPaym
            )   
            */
            //!!!!!!!!!!!! NOTE: address(this)=this.owner.address
            //uint256 insEnds=block.timestamp + (60*5*60);
            //insuranceFee=insContr.proposeIns(2, address(this), this.owner.address, address(this), 
            //              address(this),(originLoanAmount/2), insEnds, paymentMin);

        }

        return setError;
    }
    
    // Function to deposit Ether into this contract.
    // Call this function along with some Ether.
    // The balance of this contract will be automatically updated. !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    function fundLoan() public payable {
        //get address of lender
        //get address of caller
        //check var's to be in bounds: originLoanAmount
        amountFunded=amountFunded + msg.value;
        if (amountFunded>=minFunding && loanInitialized==false){
            initializeLoan();
        }
        //set public var's: loanBalance, authorized draw amount...
    }

    function initializeLoan() internal {
        //initialize starting dates and draw schedules... per terms
        require(loanInitialized==false);
        loanInitialized=true;
        paymentsMade=0;
        paymentsRequired=0;
        drawsMade=0;
        loanBalance=originLoanAmount; //remaing balnace of loan
        loanIniDateTime=block.timestamp; //set loan start timeStamp
        paymentDue=loanIniDateTime + paymentInterval; //unix time of when the next loan payment is due
        authDrawAmount=originLoanAmount / drawDivisor; //the amount value that is authorized and available to be withdrawn
        
        
        
    }

    function requestDraw() public {
        require(loanInitialized==true);
        require(borrower==msg.sender); 
        require(breachStatus==0); 
        require(drawsMade<drawDivisor);
        require(block.timestamp>(lastDraw + drawInterval));
        //require: "contract balance" > authDrawAmount
        //check contract status: authorized draw amount, lastDraw, default status, ...
        //if OK: send _amount to borrower: authDrawAmount
        address payable _to = payable(borrower);
        (bool success, ) = _to.call{value: authDrawAmount}("");
        require(success, "Failed to send Ether");

        //update: drawsMade, authDrawAmount, lastDraw
        drawsMade++;
        lastDraw=block.timestamp;
        authDrawAmount=0; //needs to be reset by Officer/Oricle

    }

    //must be called after each draw
    function authorizeDraw() public {
        require(authAgent==msg.sender); //get address of caller
        require(drawsMade<drawDivisor);
        //verify authAgent = caller
        authDrawAmount=originLoanAmount / drawDivisor; //set authDrawAmount var
    }

    

    function makeLoanPayment() public payable {
        uint256 amountPaid=msg.value;
        currPaymentAccum=currPaymentAccum + amountPaid;
        //IF "breachStatus==30" AND "msg.sender==underWriter" THEN payments is being made by insurance
        //check paymentDue
        calcBreachStatus();

    }

    //lender request to contract for dispersement of recieved funds
    function requestCollection() external onlyOwner{
        
        //IF loan is not "initialized" (forclosed?)
        if(loanInitialized==false){
            //loan has been reset (?after forclosure)
            //check paymAccum for any value-if "true" THEN "fast pay" all parties(insurance, processor(Helix),...)
            //!!!! Caluclate (per terms) insurance portion !!!!!!!!
            uint256 payIns=insuranceFee*(paymentsRequired-paymentsMade);
            //pay insurance
             //create interface ie:Iweth9 iWeth9=Iweth9(WETH);
            
            if(terms!=40 && payIns!=0){
                Iinsurance insContr=Iinsurance(underWriter);  //create interface ie:Iweth9 iWeth9=Iweth9(WETH);
                bool premPaid=insContr.payPremium{value: payIns}();
                if(premPaid){ insuranceFee=0; }//set vars for no more ins' pay's
            }  

            //!!!! Calculate (per terms Helix portion)  !!!!!!!!!!!!
            //pay Helix
            //"process fee"="helix fee"= function of "originLoanAmount"
            /*
            (=originLoanAmount * "intrest percent rate Interval")/("# of payments per Interval" * 1000)
            */
            uint256 processFee=(originLoanAmount*5)/1000;
            processFee=processFee/12;//aka: (originLoanAmount*5)/12000
            uint256 payHelix=processFee*(paymentsRequired-paymentsMade);
            transfer(payable(helixAddr),payHelix);

            //pay remaining balnace to lender(owner)
            address payable p=payable(msg.sender);
            (bool success, ) = p.call{value: address(this).balance}("");
            require(success, "Failed to send Ether");

            resetLoan();//reset all loan var's


        }
    }



    // Function to transfer Ether from this contract to address from input. !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    function transfer(address payable _to, uint _amount) internal {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }



}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}