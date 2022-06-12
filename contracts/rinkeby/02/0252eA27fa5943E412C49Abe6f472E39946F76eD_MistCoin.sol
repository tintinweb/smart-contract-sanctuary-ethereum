contract MistCoin { 
    /* Public variables of the token */
    uint8 public decimals;
    
    /* This creates an array with all balances */
    mapping (address => uint) public balanceOf;
    
    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor() {
        /* if supply not given then generate 1 million of the smallest unit of the token */
        uint256 _supply = 1000000;
        
        /* Unless you add other functions these variables will never change */
        balanceOf[msg.sender] = _supply;
        
        /* If you want a divisible token then add the amount of decimals the base unit has  */
        decimals = 0;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        /* if the sender doenst have enough balance then stop */
        if (balanceOf[msg.sender] < _value) revert();
        
        /* Add and subtract new balances */
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
    }
}