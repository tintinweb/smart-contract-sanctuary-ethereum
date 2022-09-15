/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

pragma solidity >= 0.8.0;
contract MyContrat_sec2 {
    

    // Single Comment

    /*
        Multiple-Line Comment
    */


    // Variable + access modifire : d
    
    string _name;
    uint _balance;
    
constructor(string memory name, uint balance){
        require(balance>=500,"balance greater zero (money>0)");
        _name = name ;
        _balance = balance;
    }
    function getBalance() public view returns(uint balance){
        return _balance;
    }

    function deposite(uint amount) public {
        _balance+=amount;
    }
     
}