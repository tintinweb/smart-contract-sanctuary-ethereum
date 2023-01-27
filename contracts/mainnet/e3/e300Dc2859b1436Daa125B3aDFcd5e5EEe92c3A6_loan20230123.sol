/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

//deployed on mainet at xxx

//import "@openzeppelin/contracts/access/Ownable.sol";


interface InftContract {
    function ownerOf(uint256 tokenId) external view returns (address owner);    
}

//interface to insurance contracty
interface Iinsurance {
    function proposeIns(
        uint256 _terms, address _beni, address _fundMngr, address _insured, 
        address _primOracle, uint256 _baseFunding, uint256 _insEnds, uint256 _maxBeniPaym
    ) external returns (uint256 propPayment);
    //function payBeni() external;
    function requestClaim() external;
    function payPremium() external payable returns (bool);
    function claimsPayed() external returns (uint256);
    function repayAccum() external returns (uint256);
    function maxBeniPaym() external returns (uint256);//maxBeniPaym()
    function claimPaymentRepay() external payable returns (bool);
    function getMinPayment(uint256 _fundsPromised, uint256 _terms) external returns (uint256);
}

contract loan20230123 {

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

    //address payable public lender; //address of lender= contract owner
    address public borrower; //address of borrower
    address public authAgent; //address of authorizing agent (for draws). officer
    address payable public underWriter; //address of insuring entity(=owner=lender if none)
    address payable public helixAddr; //address of helix main account
    uint256 public processFee;  //fee to be paid with each payment made to Helix

    ////define: nftContrAddress, tokenId in constructor
    address nftContrAddress;
    uint256 tokenId;


    //EVENT LIST HERE:
    event loanRequest(address _from);
    event loanProposal(uint256 terms, uint256 originLoanAmount);

    ////set: nftContrAddress, tokenId in constructor
    constructor(address _nftContrAddress, uint256 _tokenId){
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

        //lender=payable(msg.sender); //address of lender= contract owner
        //borrower=0; //address of borrower
        authAgent=msg.sender; //address of authorizing agent (for draws). officer
        underWriter=payable(msg.sender); //address of insuring entity=owner=lender if none
        helixAddr=payable(msg.sender); //!!!!!! change on MAINET DEPLOY !!!!!!!!!!!!!!!!
        //loanReqestInterval=60*10; //!!!!!!!!!!!! change on MAINNET DEPLOY !!!!!!!!!!!!!!!!!!!!!
        processFee=8000000000000000; //initialy set at .008=~$11(USD)

        //set: nftContrAddress, tokenId in constructor
        nftContrAddress=_nftContrAddress;
        tokenId=_tokenId;

    }

    //add "onlyNftOwner" modifier
    modifier onlyNftOwner(){
        //set: nftContrAddress, tokenId in constructor
        InftContract nftContr=InftContract(nftContrAddress);
        address nftOwner=nftContr.ownerOf(tokenId);
        require(msg.sender==nftOwner);
        _;
    }

    /*
    function getNftOwner() public view returns (address){
        InftContract nftContr=InftContract(nftContrAddress);
        return nftContr.ownerOf(tokenId);
    }
    */
    function getNftOwner() public view returns (address){
        InftContract nftContr=InftContract(nftContrAddress);
        address _nftOwner=nftContr.ownerOf(tokenId);
        return _nftOwner;
    }

    //resolve a breach
    function resolveBreach(uint256 _move) public onlyNftOwner {
        /*
        "_move" enumerations: acknowledge=1, forgive payment=2, forgive loan=3, 
        claim insurance=4, reset "breach status"=5, forclose=6, reset loan=7.....
        */

        /*
        "breachStatus":
        000=0=no faults,
        001 to 009 = lender fault: ????
        010 to 090 = borrower fault: 010= min payment not made in time, 020=Forclosure,
            030=ins' claims requested, 040=ins' claim paid,..
        100 to 900 = oracle fault: 100=unlisted oracle fault, 

        */
        //solve breach (if possible per aggrement terms)
        //determine breach type to solve
        if(borrowerAuthed==false){
            if(_move==7){ resetLoan();}
        }
        
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
                distributeFinalPayments();
                resetLoan();
            }
        }
        if(breachStatus==40){
            //claim payments have been recieved and borower was/is is late w/payemnts
            if(_move==6){
                //Forclose
                breachStatus=20;
                //emit notice to/for all parties
            }
        }
    }

    //CALCUlate PAYments REQUIRED = number of payments required (so far) to date. 
    function calcPaymentsRequired() internal {
        //require(loanInitialized==true);
        if(loanInitialized){
            paymentsRequired=(block.timestamp-loanIniDateTime)/paymentInterval;
        }else{
            paymentsRequired=0;
        }
    }

    function distributeFinalPayments() internal {
        //pay insurance fee
        if(address(this).balance>insuranceFee){
                if(insuranceFee!=0){
                    Iinsurance insContr=Iinsurance(payable(underWriter));
                    bool premPaid=insContr.payPremium{value: insuranceFee}();
                    if(premPaid){ currPaymentAccum=currPaymentAccum-insuranceFee; }//adjust currPayAccum
                }
        }
        //pay insurance claim repay IF required
        if(breachStatus==40){
            //get claims payed from insurer
            Iinsurance insContr=Iinsurance(payable(underWriter));
            uint256 amountOwedToIns=insContr.maxBeniPaym()*insContr.claimsPayed();//!!!change!!
            uint256 rePayIns=address(this).balance;
            if(rePayIns>amountOwedToIns){rePayIns=amountOwedToIns;}
            bool claimRepaid=insContr.claimPaymentRepay{value: rePayIns}(); 
            if(claimRepaid){ 
                currPaymentAccum=currPaymentAccum-rePayIns;
                //breachStatus=0;
            }
        }
        //pay processor
        if(address(this).balance>=processFee){
            transfer(payable(helixAddr),processFee);
            currPaymentAccum=currPaymentAccum-processFee;
        }
        
        //calculate amount owed to owner(typicaly remaining balance)
        uint256 payNftOwner=paymentMin;  //!!!!!!!!!!!!!!!!!Needs calculation !!!!!!!!!!!!!!
        //pay Nft Owner
        address _owner=getNftOwner(); 
        if(address(this).balance>payNftOwner){
            transfer(payable(_owner),payNftOwner);
            currPaymentAccum=currPaymentAccum-payNftOwner;
            //?? Pay overpayment to Borower IF required
            if(paymentsRequired<=paymentsMade){
                if(breachStatus==0){ transfer(payable(borrower),address(this).balance);}
            }

        }else{
            //pay ALL remaining balance to NftOwner
            if(address(this).balance!=0){
                transfer(payable(_owner),address(this).balance);
            }
        }

        
        //reset breachStatus
        breachStatus=0;
    }
    
    function distributeFees(uint256 currentIntrest)  internal {
        // pay/distribute fees: intrest->owner, insurance->insurer, manageFee->manager FROM currPayemntAccum
        //transfer(payable(underWriter), insuranceFee); //call payPremium()
        //(bool success, ) = underWriter.call{value: insuranceFee}("");
        
        // !!!!!!!!!!!!! revise this with new terms format !!!!!!!!!!!!!!!
        if((terms!=0) && (currPaymentAccum>insuranceFee)){
            Iinsurance insContr=Iinsurance(payable(underWriter));  //create interface ie:Iweth9 iWeth9=Iweth9(WETH);
            //IF balance>insuranceFee
            if(address(this).balance>insuranceFee){
                if(insuranceFee!=0){
                    bool premPaid=insContr.payPremium{value: insuranceFee}();
                    if(premPaid){ currPaymentAccum=currPaymentAccum-insuranceFee; }//adjust currPayAccum
                }
            }
            
          
        
        address _owner=getNftOwner();   //owner();
        //IF balance>currentIntrest
        if(address(this).balance>currentIntrest){
            transfer(payable(_owner),currentIntrest);
            currPaymentAccum=currPaymentAccum-currentIntrest;
        }
        
        //IF balce>processfee
        if(address(this).balance>=processFee){
            transfer(payable(helixAddr),processFee);
            currPaymentAccum=currPaymentAccum-processFee;
        }
        }
    }

    //this function called WHEN "if(currPaymentAccum>=paymentMin)"
    function calcNewBalance() internal{
        require(loanInitialized==true);
        //require(currPaymentAccum>=paymentMin);
        //calculate new balance with currPaymenAccum. 
        //apply overpayment to Balance IF Terms approve
        uint256 applyToBalance = 0; 
        
        
        uint256 currentIntrest=calcCurrentIntrest();    //(loanBalance*apr)/100;   
        
        //NOTE: (currentIntrest + insuranceFee + processFee) MUST NOT BE > paymentMin
        applyToBalance=applyToBalance + (paymentMin-currentIntrest-insuranceFee-processFee); //!!!!!!!!! fees need defined !!!!!!!!!!!
        if(applyToBalance>loanBalance){ applyToBalance=loanBalance;}
        loanBalance=loanBalance-applyToBalance;
        
        //distribute fees: intrest->owner, insurance->insurer, manageFee->manager
        distributeFees(currentIntrest+applyToBalance);
        paymentDue=paymentDue + paymentInterval;
        paymentsMade=paymentsMade + 1;
        

        
        
    }
    function calcCurrentIntrest() internal returns(uint256){
        uint256 aprDivisor=12;  //divisor of apr pay intevals. default set to "12" for monthly
        //adjust divisor per paymentInterval:
        if(paymentInterval==60*5){aprDivisor=6;} //speed test every 5 min.(with assumes of 2 months
        if(paymentInterval==60*60*24){aprDivisor=365;} //daily
        if(paymentInterval==60*60*24*7){aprDivisor=52;} //weekly
        if(paymentInterval==60*60*24*7*2){aprDivisor=26;} //every 2 weeks
        if(paymentInterval==2628000){aprDivisor=12;} //monthly
        if(paymentInterval==7889238){aprDivisor=4;} //quarterly
        if(paymentInterval==31556952){aprDivisor=1;} //annually
        uint256 currentIntrest=(loanBalance*apr)/100;   
        //!!!!!!!!!!!!!!! needs revision for dynamic test payment intervals.pays per annum
        currentIntrest=currentIntrest/aprDivisor; //"12" for monthly payment terms only !!!!!!!!!!!
        return currentIntrest;
    }

    function calcBreachStatus() public {
        require(loanInitialized==true);
        //check current interval time status
        calcPaymentsRequired(); //CALCUlate PAYments REQUIRED
        
        //breachStatus "40"= claim(s) have been paid.
        if(breachStatus==40){
            //claim(s) has been paid
            //check if borrower is caught up
            if(paymentsMade>paymentsRequired){
                //refund underwriter/insurer. call"function claimPaymentRepay() external payable;"
                Iinsurance insContr=Iinsurance(payable(underWriter));  //create interface ie:Iweth9 iWeth9=Iweth9(WETH);
                //!!!!!!!!!!!!!!!!!!!
                //add "repay amount"=maxBeniPaym (of Ins' contract)
                //maxBeniPay
                //NOTE: !!!!!!! maxBeniPaym(of Ins' contract) MUST equal "original" paymentMin(of Loan contract)
                uint256 rePayIns=currPaymentAccum;
                
                
                uint256 amountOwedToIns=insContr.maxBeniPaym()-insContr.repayAccum();//!!!change!!
                if(rePayIns>amountOwedToIns){rePayIns=amountOwedToIns;}
                bool claimRepaid=insContr.claimPaymentRepay{value: rePayIns}(); 
                
                //IF 'claim repay' returns TRUE THEN decrement paymentsMade
                if(claimRepaid){ 
                    paymentsMade=paymentsMade+1; 
                    currPaymentAccum=currPaymentAccum-rePayIns;
                    breachStatus=0;
                }
                
                
            }
        }
        

        if(currPaymentAccum>=paymentMin){ 
            calcNewBalance(); //calculate new balance
            //IF loan is over THEN "terms=0" IGNORE Following lines
            
            uint256 makeUpPaymentsNeeded=0; //!!!!!!!!!!!!!change to be set 
            if(paymentsRequired>paymentsMade){ makeUpPaymentsNeeded=paymentsRequired-paymentsMade;}
            uint256 makeUpPaymentsAvailable=currPaymentAccum/paymentMin;
            if(makeUpPaymentsAvailable>makeUpPaymentsNeeded){ makeUpPaymentsAvailable=makeUpPaymentsNeeded;}           
            if(makeUpPaymentsAvailable>0){
                for(uint i=0; i>makeUpPaymentsAvailable; i++){
                    if(currPaymentAccum>=paymentMin){calcNewBalance(); }//calculate new balance
                    //IF loan is over THEN "terms=0" IGNORE Following lines
                    if(terms==0){ i=makeUpPaymentsAvailable+1;}
                }
            }
        }

        //IF "Loan Balance" is less than payment min...."Final Payment" set.
        if(loanBalance<paymentMin){
            uint256 aprDivisor=12;  //divisor of apr pay intevals. default set to "12" for monthly
            //adjust divisor per paymentInterval:
            if(paymentInterval==60*5){aprDivisor=6;} //speed test every 5 min.(with assumes of 2 months
            if(paymentInterval==60*60*24){aprDivisor=365;} //daily
            if(paymentInterval==60*60*24*7){aprDivisor=52;} //weekly
            if(paymentInterval==60*60*24*7*2){aprDivisor=26;} //every 2 weeks
            if(paymentInterval==2628000){aprDivisor=12;} //monthly
            if(paymentInterval==7889238){aprDivisor=4;} //quarterly
            if(paymentInterval==31556952){aprDivisor=1;} //annually
            uint256 currentIntrest=(loanBalance*apr)/100;   
            //!!!!!!!!!!!!!!! needs revision for dynamic test payment intervals.pays per annum
            currentIntrest=currentIntrest/aprDivisor; //"12" for monthly payment terms only !!!!!!!!!!!

            paymentMin=loanBalance + currentIntrest + insuranceFee + processFee;
        }

        if(breachStatus!=20){
            if(breachStatus!=40){
                if(paymentsRequired>paymentsMade){ breachStatus=10; } //breachStaqtus "010" = NON MISSED PAYMENT(s)
            }
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
        authAgent=getNftOwner();//lender; //"Officer"/"Oricale". address of authorizing agent (for draws). officer
        underWriter=payable(getNftOwner());//lender; //address of insuring entity=owner=lender if none
    }

    function requestLoan(uint256 _terms, uint256 _originLoanAmount) public {
        //check inputs to be in "bounds"
        require(loanInitialized==false);
        if (loanRequExpires==0 || loanRequExpires<block.timestamp){
            //!!!!check for currPaymentAcumm>0 (borrower may have began Auth' process)!!!!!
            require(currPaymentAccum>=address(this).balance);
            //refund borrower currPaymentAccum. !!!!!!!!!!!!!!!!!!!!!!!
            if(currPaymentAccum!=0){transfer(payable(borrower),currPaymentAccum);}
            currPaymentAccum=0;
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
    function proposeTerms(uint256 _terms, uint256 _amount, address _insurer) external onlyNftOwner {
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
            //!!!!check for currPaymentAcumm>0 (borrower may have began Auth' process)!!!!!
            require(currPaymentAccum>=address(this).balance);
            //refund borrower currPaymentAccum. !!!!!!!!!!!!!!!!!!!!!!!
            if(currPaymentAccum!=0){transfer(payable(borrower),currPaymentAccum);}
            currPaymentAccum=0;
            resetLoan();
        }
    }

    //borrower can accept terms IF termsProposed==true
    function acceptTerms() payable public {
        //get addr of caller
        //verify addr=borrower
        require (termsProposed==true);
        require(loanInitialized==false);
        require(borrower==msg.sender); 

        //bool accept=false;
        //uint256 amountPaid=msg.value;
        currPaymentAccum=currPaymentAccum + msg.value;
        uint256 iniFee=(66*originLoanAmount)/10000;
        if(currPaymentAccum>=iniFee){
            borrowerAuthed=true;
            bool setError=setTerms();
            if(setError==true){ loanInitialized=false;}
        }
        
        if(msg.value==0){
            //borrower is declining 
            require(currPaymentAccum>=address(this).balance);
            //refund borrower currPaymentAccum. !!!!!!!!!!!!!!!!!!!!!!!
            if(currPaymentAccum!=0){transfer(payable(borrower),currPaymentAccum);}
            currPaymentAccum=0;
            resetLoan();
        }
        
        
    }

    function setTerms() internal returns (bool){
        //AB ie 12. B is 1 for overpayment to principle OR 0 if overpayemnt goes to next month payment
        bool setError=false; //!!!!!!!!!!!!!! needs to be set in each "if" block !!!!!!!!!!!!!!!!!!!!
        
        //new terms format:1,aaaa,bbbb,cccc,dddd,eeeeee
        /*
        aaaa=total designed payments
        bbbb=payment frequency
        cccc=apr
        dddd=insurance divisor
        eeeeee=Initial Base Payment="eth"/10000. see "iniPaymentCalc"- sheets/excell sheet to calc'
        
        Example:"speed test"            =10006000100020202001686, with 1 ETH loan
        Example2:"unInsured speed test" =10006000100020200001686, with 1 ETH loan
        0006=total designed payments
        0001=payment frequency=enumeration of "speed test"=every 5 min
        0002=apr=2 percent=.02
        xx02=insurance divisor, xx=insurance terms(see ins' contract)
        016="eth"/100=.16 (eth)
        */
        require(terms>100000000000000000000); //ie 12222333344445555666666
        
        originLoanAmount=originLoanAmount+ 0;//"50USD"; //!!!!!!!!!need to set standard for adding USD to WEI !!!!!!!!!!!!
        minFunding=originLoanAmount / 2; //???????????????????????????
        
        uint256 _terms=terms;
        
        
        uint256 iniPayment=_terms % 1000000;
        _terms=_terms - iniPayment;
        _terms=_terms/1000000;
        iniPayment=iniPayment * 10**14;
        /*
        uint256 iniPayment=_terms % 10000;
        _terms=_terms - iniPayment;
        _terms=_terms/10000;
        iniPayment=iniPayment * 10**16;
        */
        uint256 insDivisor= _terms % 10000;
        _terms=_terms - insDivisor;
        _terms=_terms/10000;
        
        apr= _terms % 10000;
        _terms=_terms - apr;
        _terms=_terms/10000;
        
        
        uint256 payFrequ= _terms % 10000;
        _terms=_terms - payFrequ;
        _terms=_terms/10000;
        //paymentInterval=60*5;
        paymentInterval=0;
        if(payFrequ==1){ paymentInterval=60*5;} //speed test every 5 min
        if(payFrequ==2){ paymentInterval=60*60*24;} //daily
        if(payFrequ==3){ paymentInterval=60*60*24*7;} //weekly
        if(payFrequ==4){ paymentInterval=60*60*24*7*2;} //every 2 weeks
        if(payFrequ==5){ paymentInterval=2628000;} //monthly
        if(payFrequ==6){ paymentInterval=7889238;} //quarterly
        if(payFrequ==7){ paymentInterval=31556952;} //annually
        require(paymentInterval!=0);
        
        uint256 totPayments= _terms % 10000;
            //_terms=_terms - totPays;
            //_terms=_terms/10000;
            
            breachStatus=0; //enumerated value of if loan is in default (breach of contract): 0=no problem, 1=
            authDrawAmount=0; //the amount value that is authorized and available to be withdrawn
            authAgent=payable(getNftOwner());   //this.owner.address);
            drawDivisor=1; //set to divide the total loan amount into "1" protions.= max amount of draws
            drawInterval=0; //all can be drawn upfront
            lastDraw=0; //timestamp of previouw draw
            authAgent=getNftOwner();//lender; //lender is authAgent
            //underWriter=lender; //lender is insurer....is set with "proposal"
            processFee=(2*iniPayment)/100; //processFee: set as a function of "iniPayment". = .02 of iniPayent
            
            if(insDivisor!=0){
                /*
                uint256 insDivisor= _terms % 10000;
                _terms=_terms - insDivisor;
                _terms=_terms/10000;
                */
                //parse terms, divisor
                _terms=insDivisor;
                insDivisor=_terms % 100;
                _terms=_terms - insDivisor;
                _terms=_terms/100;
                uint256 insTerms=_terms % 100;

                
                //!!!!!!call insurance contract's "propose" function (IF underWriter!=lender)
                Iinsurance insContr=Iinsurance(underWriter);  //create interface ie:Iweth9 iWeth9=Iweth9(WETH);
                /*
                (
                uint256 _terms, address _beni, address _fundMngr, address _insured, 
                address _primOracle, uint256 _baseFunding, uint256 _insEnds, uint256 _maxBeniPaym
                )   
                */
                //!!!!!!!!!!!! NOTE: address(this)=this.owner.address
                
                //uint256 insFeeEstimate=(originLoanAmount/insDivisor);
                //insFeeEstimate=(insFeeEstimate*5)/10000;    //!!!!!!!!!!!!revise with data from ins' contract
                //call "function getMinPayment(uint256 _fundsPromised, uint256 _terms)" FROM ins'
                uint256 insFeeEstimate=insContr.getMinPayment((originLoanAmount/insDivisor), insTerms);
                uint256 insEnds=block.timestamp + (paymentInterval*totPayments);
                uint256 maxBeniPay=iniPayment + processFee + insFeeEstimate;
                address _owner=getNftOwner();   //
                insuranceFee=insContr.proposeIns(insTerms, address(this), _owner, address(this), 
                address(this),(originLoanAmount/insDivisor), insEnds, maxBeniPay);
                if(insuranceFee==99999999999999999999999999){ setError=true; } // THEN error 
                if(insuranceFee==0){ setError=true; }
                require(setError==false, "Ins Fee NOT Set");
            }else{
                insuranceFee=0;

        }
        //processFee=(2*iniPayment)/100; //processFee: set as a function of "iniPayment". = .02 of iniPayent
        paymentMin=iniPayment + processFee + insuranceFee;
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
            //Disperse iniFee=currPaymentAccum. !!!!!!!!!!!!!!!!!!!!!
            transfer(payable(helixAddr),currPaymentAccum);
            currPaymentAccum=0;
            
            
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
        
        //payment is for "claim". set breach status for "claim payed".
        if(msg.sender==underWriter){ breachStatus=40;}
        
        if(loanBalance==0){
            //distributeFees(address(this).balance);
            distributeFinalPayments();
            if(breachStatus==0){ resetLoan();}
        }else{
            calcBreachStatus();
        }

        
    }

    //lender request to contract for dispersement of recieved funds
    function requestCollection() external onlyNftOwner{
        
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
                //check for claims paid
                //uint256 claimsPaid=insContr.claimsPayed();
            }  

            //!!!! Calculate (per terms Helix portion)  !!!!!!!!!!!!
            //pay Helix
            //"process fee"="helix fee"= function of "originLoanAmount"
            /*
            (=originLoanAmount * "intrest percent rate Interval")/("# of payments per Interval" * 1000)
            */
            //uint256 processFee=(originLoanAmount*5)/1000;
            //processFee=processFee/12;//aka: (originLoanAmount*5)/12000
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