pragma solidity 0.8.10;

contract BoxV3 {
    uint public val;

    function inc() external {
        val += 1;
    }
    
    function toSend() public view  returns(uint){
        uint chislo = 777;
        if(chislo==1){
            return chislo;
        }else if(chislo==2){
            return chislo;
        }else{
            return chislo;
        }
    }
}