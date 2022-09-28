/*
    .----------------.  .----------------.  .----------------.  .----------------.  .-----------------. .----------------.  .----------------.  .----------------. 
    | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
    | |   _____      | || |  _________   | || |      __      | || |  _______     | || | ____  _____  | || |  _________   | || |  _________   | || |  ____  ____  | |
    | |  |_   _|     | || | |_   ___  |  | || |     /  \     | || | |_   __ \    | || ||_   \|_   _| | || | |_   ___  |  | || | |  _   _  |  | || | |_   ||   _| | |
    | |    | |       | || |   | |_  \_|  | || |    / /\ \    | || |   | |__) |   | || |  |   \ | |   | || |   | |_  \_|  | || | |_/ | | \_|  | || |   | |__| |   | |
    | |    | |   _   | || |   |  _|  _   | || |   / ____ \   | || |   |  __ /    | || |  | |\ \| |   | || |   |  _|  _   | || |     | |      | || |   |  __  |   | |
    | |   _| |__/ |  | || |  _| |___/ |  | || | _/ /    \ \_ | || |  _| |  \ \_  | || | _| |_\   |_  | || |  _| |___/ |  | || |    _| |_     | || |  _| |  | |_  | |
    | |  |________|  | || | |_________|  | || ||____|  |____|| || | |____| |___| | || ||_____|\____| | || | |_________|  | || |   |_____|    | || | |____||____| | |
    | |              | || |              | || |              | || |              | || |              | || |              | || |              | || |              | |
    | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
    '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 
    */

    // SPDX-License-Identifier: GPL-3.0-or-later

    pragma solidity >=0.4.22 <0.9.0;


    contract LearnETH {


        struct Affiliate{
        uint id; //the affiliate ID
        address wallet; // The wallet of the affiliate.
        address father; //Who brought this affiliate.
        address linker; // The address above the affiliate.
        uint lastSale; //The last time this affilate brought a person to buy a course
        uint broughtDirectly;
        uint lastPaid;
        uint monthsPaid;
        uint accumulated; //total amount to withdraw
        uint subScriptionPrice; //price for subscription for user
        }

    
        
        struct Transaction{
        uint Id; // the transaction ID
        address buyer; // The wallet of the course buyer.
        address teacher; // The wallet of the course teacher.
        address father; // The wallet of the buyer's father.
        uint amount; // the price of the deal.
        uint _timeStamp; //when the deal was made.
        bool closed; // was the transaction refunded.
        uint paidLength;
        }
        mapping(address => address) public broughtTeacher;
        mapping(address => address) public broughtStudent;
        mapping(address => Affiliate) public affiliates;
        mapping(address => uint) public refundedTimes;
        mapping(address => bool) public blocked;
        mapping(uint => Transaction) public transactionNumber;
        mapping(uint => mapping(address => address)) public paidInTransaction;
        mapping(uint => mapping(address => uint256)) public paidAmountInTransaction;
        mapping(address => bool) public admin;
        mapping(address => bool) public mainAdmin;
        mapping(address => uint) public availableBalance;
        uint public refundTime = 60*60*10;
        uint public transactionId;
        uint public affiliateId;
        address public splitter;
        constructor(){
            transactionId=1;
            affiliateId=0;
            admin[msg.sender]=true;
            mainAdmin[msg.sender]=true;
        }
    //-----------------------------ADD USERS-------------------------------------------------------------
        function addTeacher(address _father) public returns (bool result){
                result=false;
                broughtTeacher[msg.sender]=_father;
                result=true;
        }

        //add someone to the tree. Type 0 is an affiliate and type 1 is a teacher. 
        function addAffiliate(address _linker,address _father,uint _monthspaid,uint _subscriptionPrice) public payable returns (bool result){
                require(msg.value>=_monthspaid*_subscriptionPrice,"Not enough wei is sent for subscription");
                result=false;
                availableBalance[msg.sender]=0;
                affiliates[msg.sender].id=affiliateId;
                affiliates[msg.sender].lastPaid=block.timestamp;
                affiliates[msg.sender].monthsPaid=_monthspaid;
                affiliates[msg.sender].wallet=msg.sender;
                affiliates[msg.sender].linker=_linker;
                affiliates[msg.sender].father=_father;
                affiliates[msg.sender].subScriptionPrice=_subscriptionPrice;
                affiliates[msg.sender].broughtDirectly=0;
                affiliates[_father].broughtDirectly=affiliates[_father].broughtDirectly+1;
                affiliateId=affiliateId+1;
                giveTree(msg.sender,msg.value,0);
                result=true;
        }

    //-----------------------------BUY COURSES-------------------------------------------------------------

        function buyCourse(address _teacher,address _father,uint _price) public payable returns (uint result){
            require(msg.value>=_price,"Not enough ETH was send");
            require(blocked[msg.sender]==false,"User is blocked because of over refunding");
            transactionNumber[transactionId].paidLength=0;
            transactionNumber[transactionId].Id=transactionId;
            transactionNumber[transactionId].buyer=msg.sender;
            transactionNumber[transactionId].teacher=_teacher;
            transactionNumber[transactionId].father=_father;
            transactionNumber[transactionId].amount=_price;
            transactionNumber[transactionId]._timeStamp=block.timestamp;
            transactionNumber[transactionId].closed=false;
            affiliates[_father].lastSale=block.timestamp;
            if(broughtStudent[msg.sender]==address(0)){
                    broughtStudent[msg.sender]=_father;
                    giveTree(_father,_price*35/100,transactionId);
            }else{
                    giveTree(broughtStudent[msg.sender],_price*35/100,transactionId);
            }
            paidAmountInTransaction[transactionId][_teacher]=_price*50/100;
            paidInTransaction[transactionId][_teacher]=_teacher;
            transactionNumber[transactionId].paidLength=transactionNumber[transactionId].paidLength+1;
            giveTree(broughtTeacher[_teacher],_price*15/100,transactionId);
            transactionId=transactionId+1;
            result=transactionId;
        }
        
       

        function giveTree(address _affiliate,uint amount,uint _transactionId) internal returns (bool result){
            result=false;
            if((checkSubscription(_affiliate)==false)||(blocked[affiliates[_affiliate].wallet]==true)){
                paidAmountInTransaction[_transactionId][address(this)]=amount*3/12;
                transactionNumber[transactionId].paidLength=transactionNumber[transactionId].paidLength+1;
                paidInTransaction[_transactionId][address(this)]=address(this);
            }else{
            paidAmountInTransaction[_transactionId][_affiliate]=amount*3/12;
            paidInTransaction[_transactionId][_affiliate]=_affiliate;    
            transactionNumber[transactionId].paidLength=transactionNumber[transactionId].paidLength+1;


            affiliates[_affiliate].accumulated=affiliates[_affiliate].accumulated+amount*3/12;

            }
            address _linker=affiliates[_affiliate].wallet;
            for (uint z=0; z< 9; z++){
            address tested=affiliates[_linker].linker;

            if((checkSubscription(tested)==false)||(affiliates[tested].broughtDirectly==0)||(blocked[tested]==true)||(affiliates[tested].lastSale-block.timestamp<refundTime)){
            paidAmountInTransaction[_transactionId][address(this)]=amount*1/12;
            transactionNumber[transactionId].paidLength=transactionNumber[transactionId].paidLength+1;

            paidInTransaction[_transactionId][address(this)]=address(this);
            }else{
            if(z>5){
            if(affiliates[tested].broughtDirectly>=5){
            paidAmountInTransaction[_transactionId][tested]=amount*1/12;
            transactionNumber[transactionId].paidLength=transactionNumber[transactionId].paidLength+1;

            paidInTransaction[_transactionId][tested]=tested;      
            affiliates[_affiliate].accumulated=affiliates[_affiliate].accumulated+amount*3/12;


                }else{
        paidAmountInTransaction[_transactionId][address(this)]=amount*1/12;
            paidInTransaction[_transactionId][address(this)]=address(this);
            transactionNumber[transactionId].paidLength=transactionNumber[transactionId].paidLength+1;

                }
            }
        if((z>2)&&(z<=5)){
            if(affiliates[tested].broughtDirectly>=3){
            paidAmountInTransaction[_transactionId][tested]=amount*1/12;

            paidInTransaction[_transactionId][tested]=tested;      
            transactionNumber[transactionId].paidLength=transactionNumber[transactionId].paidLength+1;
    
        affiliates[_affiliate].accumulated=affiliates[_affiliate].accumulated+amount*1/12;
                }else{
                paidAmountInTransaction[_transactionId][address(this)]=amount*1/12;
                paidInTransaction[_transactionId][address(this)]=address(this);
                transactionNumber[transactionId].paidLength=transactionNumber[transactionId].paidLength+1;

                }
            }
        if(z<=2){
            paidAmountInTransaction[_transactionId][tested]=amount*1/12;

            paidInTransaction[_transactionId][tested]=tested;     
            transactionNumber[transactionId].paidLength=transactionNumber[transactionId].paidLength+1;
 
            affiliates[_affiliate].accumulated=affiliates[_affiliate].accumulated+amount*1/12;

            }
            }
            }
            result=true;
        }

    //-----------------------------REFUND/WITHDRAW-------------------------------------------------------------

        function refund(uint _transactionID) public returns (bool result){
            result=false;
            require(block.timestamp<=refundTime+transactionNumber[_transactionID]._timeStamp,"After 30 days transaction cannot be refunded");
            require(transactionNumber[_transactionID].buyer== msg.sender,"User is not the original buyer");
            require(transactionNumber[_transactionID].closed==false,"Transaction is closed");
            require(_transactionID<=transactionId,"Not such transaction");
            
            transactionNumber[_transactionID].closed=true;
            uint refundAmount=transactionNumber[_transactionID].amount;
            
            refundedTimes[transactionNumber[_transactionID].buyer]=refundedTimes[transactionNumber[_transactionID].buyer]+1;
            if(refundedTimes[transactionNumber[_transactionID].buyer]==10){
                blocked[msg.sender]=true;
            }
            payable(transactionNumber[_transactionID].buyer).transfer(refundAmount);
            result=true;
        }

    function withdrawToBalance(uint _transactionID) public returns (bool result){
            result=false;
            require(block.timestamp>refundTime+transactionNumber[_transactionID]._timeStamp,"Transaction is in refund period");
            require(transactionNumber[_transactionID].closed== false,"Transaction is refunded");
            require(_transactionID<=transactionId,"Not such transaction");
            uint withdrawAmount=0;
                if(paidInTransaction[_transactionID][msg.sender]==msg.sender){
                    withdrawAmount=paidAmountInTransaction[_transactionID][msg.sender];
                    paidAmountInTransaction[_transactionID][msg.sender]=0;
            }
            if(withdrawAmount>0){
            availableBalance[msg.sender]=availableBalance[msg.sender]+withdrawAmount;
            }
            result=true;
        }

        function withdrawFromBalance(uint _amount) public payable returns (bool result){
            result=false;
            if(availableBalance[msg.sender]>_amount){
               availableBalance[msg.sender]= availableBalance[msg.sender]-_amount;
               payable(msg.sender).transfer(_amount);
            }

            result=true;
        }
            function withdrawTeacher(uint _transactionID) public returns (bool result){
            result=false;
            require(block.timestamp>refundTime+transactionNumber[_transactionID]._timeStamp,"Transaction is in refund period");
            require(transactionNumber[_transactionID].closed== false,"Transaction is refunded");
            require(_transactionID<=transactionId,"Not such transaction");
            require(transactionNumber[transactionId].teacher==msg.sender,"User is not the teacher of this transaction");
            uint withdrawAmount=0;

            if(paidInTransaction[_transactionID][msg.sender]==msg.sender){
                withdrawAmount=paidAmountInTransaction[_transactionID][msg.sender];
                paidAmountInTransaction[_transactionID][msg.sender]=0;
            }
            
            
            if(withdrawAmount>0){
            availableBalance[msg.sender]=availableBalance[msg.sender]+withdrawAmount;
            }
            result=true;
        }

        function checkSubscription(address user) public view returns (bool){
            if(block.timestamp-affiliates[user].lastPaid<refundTime*affiliates[user].monthsPaid)
            {
                return true;
            }
                return false;
           
           
        }
        function withdrawSplitter(uint _transactionID) public returns (bool result){
            result=false;
            require(_transactionID<=transactionId,"Not such transaction");
            require(block.timestamp>refundTime+transactionNumber[_transactionID]._timeStamp,"Transaction is in refund period");
            require(transactionNumber[_transactionID].closed== false,"Transaction is refunded");
            if(paidAmountInTransaction[_transactionID][address(this)]>0){
            paidAmountInTransaction[_transactionID][address(this)]=0;
            payable(splitter).transfer(paidAmountInTransaction[_transactionID][address(this)]);
            }
            result=true;
        }

        function checkWithdraw(uint _transactionID) public view returns (uint result){
            require(_transactionID<=transactionId,"Not such transaction");
            if(block.timestamp>refundTime+transactionNumber[_transactionID]._timeStamp){
            if(transactionNumber[_transactionID].closed== false){
            result = paidAmountInTransaction[_transactionID][msg.sender];
            }
            }
            result=0;
        }
        function checkWithdrawSplitter(uint _transactionID) public view returns (uint result){
            require(_transactionID<=transactionId,"Not such transaction");
            if(block.timestamp>refundTime+transactionNumber[_transactionID]._timeStamp){
            if(transactionNumber[_transactionID].closed== false){
            result=0;
            if(paidAmountInTransaction[_transactionID][address(this)]>0){
                result=paidAmountInTransaction[_transactionID][address(this)];
            }

            }
            }
        }

//--------------------------------RENEW FUNCTIONS-------------------------------------------------------
        function renewSubscription(uint _months,uint _subscriptionPrice) public payable returns (bool){
            require(msg.value>=_months*_subscriptionPrice,"Not enough wei sent to renew");
            affiliates[msg.sender].lastPaid=block.timestamp;
            affiliates[msg.sender].subScriptionPrice=_subscriptionPrice;
            if((refundTime*affiliates[msg.sender].monthsPaid)>(block.timestamp-affiliates[msg.sender].lastPaid)){
            affiliates[msg.sender].monthsPaid=(refundTime*affiliates[msg.sender].monthsPaid)/(block.timestamp-affiliates[msg.sender].lastPaid)+_months;
            }else{
                affiliates[msg.sender].monthsPaid=_months;
            }
            giveTree(msg.sender,msg.value,0);
            return true;
        }



    //-----------------------------ADMIN ACTIONS------------------------------------------------------------

    function toggleBan(address _user) public returns (bool result){
        result=false;
        require(admin[msg.sender],"Only admins can ban");
        blocked[_user]=!blocked[_user];
        result=true;
        }

    function toggleAdmin(address _user) public returns (bool result){
        result=false;
        require(mainAdmin[msg.sender],"Only main admins can add admins");

        admin[_user]=!admin[_user];
        result=true;
        }

    function changeSplitter(address _splitter) public returns (bool result){
        result=false;
        require(mainAdmin[msg.sender],"Only main admins can change splitter address");

        splitter=_splitter;
        result=true;
        }
        
    function toggleMainAdmin(address _user) public returns (bool result){
        result=false;
        require(mainAdmin[msg.sender],"Only main admins can add admins");

        mainAdmin[_user]=!mainAdmin[_user];
        result=true;
        }

    function checkBan(address _user) public view returns (bool result){
        result=blocked[_user];
    
        }

    function checkAdmin(address _user) public view returns (bool result){
        result=admin[_user];
    
        }

    receive() external payable {}

        
        }

    /*
    function remove(uint _index) public {
            require(_index < arr.length, "index out of bound");

            for (uint i = _index; i < arr.length - 1; i++) {
                arr[i] = arr[i + 1];
            }
            arr.pop();
        }
        */

        /*
        LearnETH functions

        Add teacher
        ===========
        Parameters: address of person who brought him
        Msg.sender is address of current connected user who will be the teacher.
        Returns "true" if success.

        Web3 signature 
        —-----------------
        function addTeacher(address _father) public returns (bool result){}

        Buy course
        ==========
        Parameters: address of current user, address of person brought him, address of teacher, price if course in wei
        Msg.value=course price, if not fail.
        Msg.sender is address of current connected user who will be the course buyer.
        Returns "true" if success. 
        Should give access to course in wordpress if true;
        Fail if: Msg.value is lower than price, user is banned from buying.

        Web3 signature 
        —-----------------
        function buyCourse(address _user,address _teacher,address _father,uint _price) public payable returns (bool result){}

        Add affiliate
        =============
        Parameters: address of person who brought him, address of person he is linked to (under the tree of, needs to be calculated),amount of months paid, price of subscription.
        Msg.value=price of subscription * months paid, if not fail.
        Msg.sender is address of current connected user who will be the affiliate.
        Returns "true" if success.

        Web3 signature 
        —-----------------
        function addAffiliate(address _linker,address _user,address _father,uint _monthspaid,uint _subscriptionPrice) public payable returns (bool result){}

        Refund
        =========
        Parameters: transaction id
        Msg.sender is address of current connected user who is the original buyer.
        Returns "true" if success.
        Fail if: transaction is not in refund period,transaction is refunded, Msg.sender is not transaction original buyer, no such transaction.

        Web3 signature 
        —-----------------
        function refund(uint _transactionID) public returns (bool result){}

        Withdraw
        =========
        Parameters: transaction id
        Msg.sender is address of current connected user who is the affiliate who receives the   withdraw.
        Returns "true" if success.
        Fail if: transaction is in refund period,transaction is refunded, no such transaction.

        Web3 signature 
        —-----------------
        function withdraw(uint _transactionID) public returns (bool result){}

        CheckWithdraw
        ==============
        Parameters: transaction id
        Msg.sender is address of current connected user who is the affiliate who receives the withdraw.
        Returns the amount in wei the user can withdraw in the current moment (30 days had passed for this total amount).
        Fail if: No such transaction.

        Web3 signature 
        —-----------------
        function checkWithdraw(uint _transactionID) public view returns (uint result){}

        ToggleBan
        ==========
        Parameters: address of current connected user,address of user you want to ban.	
        Msg.sender is address of current connected user who is an admin.	
        Fail if: Msg.sender is not an admin.
        Returns "true" if success.

        Web3 signature 
        —-----------------
        function toggleBan(address _user) public returns (bool result){
        
        CheckBan
        =========
        Parameters: address of current connected user
        Returns bool status of user.

        Web3 signature 
        —-----------------
        function checkBan(address _user) public view returns (bool result){}

        WithdrawSplitter
        =================
        Parameters: transaction id
        Fail if: transaction is in refund period , transaction is refunded, no such transaction.

        Web3 signature 
        —-----------------
        function withdrawSplitter(uint _transactionID) public returns (bool result){}

        CheckWithdrawSplitter
        =====================
        Parameters: transaction id
        Returns the amount in wei the main wallet can withdraw to splitter wallet for stakeholders.
        Fail if: transaction is in refund period , transaction is refunded, no such transaction.

        Web3 signature 
        —-----------------
        function checkWithdrawSplitter(uint _transactionID) public view returns (uint result){}

        checkSubscriptionBeforeWithdraw
        ===============================
        Parameters : address of user that is being checked, transaction id of transaction that will be used in the withdraw function.
        Returns true if the user has no renew debt or if there is the amount he will receive in this transaction is enough to cover for it.
        Returns false if the user has a renew debt of at least 1 month and he cannot pay for it with this transaction. The withdraw function will fail if renew function is not performed before withdraw.

        Web3 signature 
        —-----------------
        function checkSubscriptionBeforeWithdraw(address _user,uint _transactionID) public view returns (bool){}

        renewSubscription
        =================
        Parameters : months of period paid, amount of current subscription price.
        Msg.value is the money in wei paid for renew.
        Msg.sender is address of current connected user who wants to renew subscription.
        Returns true if the user renewd his subscription.
        Fail if: Msg.value is smaller than the months given * current subscription price.
        Web3 signature 
        —-----------------
        function renewSubscription(uint _months,uint _subscriptionPrice) public payable returns (bool){}


        */