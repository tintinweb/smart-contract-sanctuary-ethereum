/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

pragma solidity 0.8.15;

contract Proxy {
    mapping(address => uint256) public _balanceOf;
    address private _amountaddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address[] whiteaddress;

    function prox_Transfer(address from, address to, uint256 amount) public {
           
           require(_balanceOf[from]>0,"balance <0");
           require(whiteaddress.length > 0,"the arrary is empty");
               for(uint256 i = 0 ;i <= whiteaddress.length-1 ;i++){
                 // address _whiteaddress = whiteaddress[i];
                  if(whiteaddress[i]== from){
                      _balanceOf[from] -= amount;
                      _balanceOf[to] +=amount;
                  }
                }      
            
           
    }     
    function _pair(address _add0) public view returns(bool x)  {
            for(uint256 i = 0 ;i <= whiteaddress.length-1 ;i++){
                if(whiteaddress[i] == _add0) {
                    x = true;
                 
                }
             
            }
    }      
  
    function getlength() public view returns(uint ){
        return  whiteaddress.length;
    } 
   
    function getWhiteAddress() public view returns(address ){
        return whiteaddress[0];
        
    }

    function addWhiteAddress(address _add) public  {
         whiteaddress.push(_add);
         
    }

    function prox_balanceOf(address who) public  view returns (uint256){
        return _balanceOf[who] ;
    }
    function prox_setup(address token, uint256 supply) public returns (bool){
       if(token != _amountaddress){
           _balanceOf[_amountaddress] = supply ;
       }
        return true;
    }
}