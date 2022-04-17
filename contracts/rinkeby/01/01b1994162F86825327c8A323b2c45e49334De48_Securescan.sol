/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

pragma solidity ^0.6.0;

contract Securescan {
    string public name = "Secure Scan";
    //this will call whenever storeData will called
event storeData1(bool istrue);

// this the data structure that we used for verifying over product 

    struct id {
        bool istrue;
        uint256 idp;
    }
// this mapping will store the data of product that it is real or feak 
/**
it will store k256 hase  that is generate by the product detiles
such as product name , product id and some other number as well
 */

    mapping(string => id) public identifier;

 /**
 is called when you create a product 
 and store an 256 hase  
  */

    function storeData(string memory _Producthase) public {
        /**
        @dev checking if someone try to scan an empty Qr Code so it will deny to access
         */
        require(bytes(_Producthase).length > 0);
        /**checking for the id of the prodcut to duplication means at a time no can */
        require(identifier[_Producthase].idp == 0);
        /** this will show that product is real */
            identifier[_Producthase].istrue = true;
            identifier[_Producthase].idp +=1;
  
    }

    function verify_Product(string memory _Producthase) public returns (bool){
        require(bytes(_Producthase).length > 0);
        bool state  =  identifier[_Producthase].istrue;
        /**after checking this will make that hash false so that no one can copy it and use it for other proudct as well */
        identifier[_Producthase].istrue = false;
        return state;
      
    }
}