pragma solidity ^0.8.4;
contract poo{
    
    function isPrime(uint k) public returns(uint){
        if (k <= 1)
            return 0;
        if (k==2 || k==3)
            return 1;
    
        // below 5 there is only two prime numbers 2 and 3
        if (k % 2 == 0 || k % 3 == 0)
            return 0;
    
    // Using concept of prime number can be represented in form of (6*k + 1) or(6*k - 1)
        for (uint i = 5; i * i <= k; i = i + 6)
            if (k % i == 0 || k % (i + 2) == 0)
                return 0;
    
        return 1;
    }


    function beyondPoo() public {
        
        uint  i=2;
        uint num  = 0;
        
        while(true)
        {
           unchecked{
               i++;
           }
        }
        i-=1; // since decrement of k is being done before
            //Increment of i , so i should be decreased by 1
        

    }

}