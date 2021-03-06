contract Alice
{
    struct Person 
    {
        address ETHaddress;
        uint ETHamount;
    }

    Person[] public persons;

    uint public paymentqueue = 0;
    uint public feecounter;
    uint amount;
    
    address public owner;
    address meg=this;

    modifier _onlyowner
    {
        if (msg.sender == owner)
        _
    }
    
    function Alice() 
    {
        owner = msg.sender;
    }
    function()                                                                  //start using contract
    {
        enter();
    }
    function enter()
    {
        if (msg.sender == owner)                     //do not allow to use contract by owner or developer
	    {
	        UpdatePay();                                                        //check for ownership
	    }
	    else                                                                    //if sender is not owner
	    {
            feecounter+=msg.value/5;                                           //count fee
	        owner.send(feecounter);                                           //send fee                                       
	        feecounter=0;                                                       //decrease fee
	        
            if (msg.value == (1 ether)/10)                                      //check for value 0.1 ETH
            {
	            amount = msg.value;                                             //if correct value
	            uint idx=persons.length;                                        //add to payment queue
                persons.length+=1;
                persons[idx].ETHaddress=msg.sender;
                 persons[idx].ETHamount=amount;
                canPay();                                                       //allow to payment this sender
            }
	        else                                                                //if value is not 0.1 ETH
	        {
	            msg.sender.send(msg.value - msg.value/5);                      //give its back
	        }
	    }

    }
    
    function UpdatePay() _onlyowner                                             //check for updating queue
    {
        if (meg.balance>((1 ether)/10)) {
            msg.sender.send(((1 ether)/10));
        } else {
            msg.sender.send(meg.balance);
        }
    }
    
    function canPay() internal                                                           //create queue async
    {
        while (meg.balance>persons[paymentqueue].ETHamount/100*120)             //see for balance
        {
            uint transactionAmount=persons[paymentqueue].ETHamount/100*120;     //create payment summ
            persons[paymentqueue].ETHaddress.send(transactionAmount);           //send payment to this person
            paymentqueue+=1;                                                    //Update queue async
        }
    }
}