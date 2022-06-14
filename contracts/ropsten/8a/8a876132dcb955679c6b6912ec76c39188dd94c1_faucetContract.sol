/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

pragma solidity 0.8.9 ; 

contract faucetContract {

    address HRadmin ; 

    address[] HRList ;

    constructor () {

        HRadmin  = msg.sender ; 
        HRList.push(msg.sender);
    }

    modifier OnlyHRadmins(   ) {

        require(HRadmin  == msg.sender ) ; 
        _;
    }

    

    modifier OnlyHRFromList() {
        address currentAddress ;
        bool success ; 
        
        for (uint i =0 ; i < HRList.length ; i++  ) {

                currentAddress = HRList[i] ;

            if(currentAddress == msg.sender) {
               success = true ; 
            }    //  else continue ;  
        }

        require (success , "HR not in list") ;
        _;
     }

    modifier depositToContract() {

        require (msg.value >  0 , "value too minimum to send to contract." ) ;
        _; 
    }  

    mapping (address => uint) employeeMaticValue ; 
 
    function assignMaticPointForEmployee( address[] memory  _address,  uint _amount ) OnlyHRFromList() public  { 

        require( _amount > 0 ,  "Matic should be positive interger ")     ;
            
           address currentAddress ;
      

           for ( uint i = 0 ;  i < _address.length ; i++) {

                currentAddress = _address[i] ;

            

               employeeMaticValue[currentAddress] += _amount ;

            
              

           }

    }

    function assignMaticForEmployee() public payable {

        require ( employeeMaticValue[msg.sender] > 0 , " Employee dose not have enough balance to redeem."   ) ; 
        require ( address(this).balance >  employeeMaticValue[msg.sender] ,"Contract dosent have enough balance to send it to employee." ) ;

        uint maticValue =  employeeMaticValue[msg.sender] ;
        
        employeeMaticValue[msg.sender] = 0 ;

        payable(msg.sender).send(maticValue)   ; 

    }  

        function getfundInContract() view public OnlyHRFromList returns(uint ){
        return address(this).balance;
    }

        function depositFunds() public payable{
        
    }

    function checkMaticPointsOfEmployee() view public returns (uint) {


            return (employeeMaticValue[msg.sender] )  ;
    } 

    function addToHRList(address _HRAddress ) public   {

            HRList.push(_HRAddress);
    }

    function getHRListAddress() public view returns (address[] memory) {
        return HRList ;
    }

 

}