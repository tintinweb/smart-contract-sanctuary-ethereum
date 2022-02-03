/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: LGPL-3.0-only


pragma solidity 0.8.2;


contract GnosisSafeGetAddresses {
  
   struct OwnerSafeHere {      
        address  ownershere;  
        string  safeaddressesstuff;  
      }

         
      OwnerSafeHere listofownersafe;
      OwnerSafeHere[] public ownersafestore;

      string [][] public multiwalletlist ;
      string[] public safeaddressarray;
mapping(uint256 => mapping(address => string )) public safeaddressesinfo;
mapping(address => address) public addresscheck;
mapping(uint256 => OwnerSafeHere) public ownersafelist;



event GnosisSafeAddress(address  _walletaddressevent, string  _safestringevent);
  
    function storeGnosisSafeAddress(
        address  walletaddress,
        string memory safestring
    ) external returns (address _walletaddress, string memory _safestring  ) {
      uint index=0;
      addresscheck[_walletaddress]=walletaddress;
      ownersafelist[index].ownershere=walletaddress;
     ownersafelist[index].safeaddressesstuff = safestring;
     safeaddressesinfo[index][walletaddress]=safestring;

     bytes memory stringifiedwallet = abi.encodePacked(_walletaddress);
     string memory addressstring = bytesToString(stringifiedwallet);
     multiwalletlist.push ([addressstring,_safestring]);
 //    string[] storage  safeaddresscollection;
   //  safeaddresscollection.push(safestring);

     listofownersafe = OwnerSafeHere(walletaddress,safestring );
      
     ownersafestore.push(listofownersafe);
     
      emit GnosisSafeAddress(walletaddress, safestring);
    index =   index + 1;
      
    return (walletaddress,safestring);
   
   
    }
 function compare(string memory _a, string memory _b) public returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }
    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string memory _a, string memory _b) public returns (bool) {
        return compare(_a, _b) == 0;
    }

function bytesToString(bytes memory byteCode) public pure returns(string memory stringData)
{
    uint256 blank = 0; //blank 32 byte value
    uint256 length = byteCode.length;

    uint cycles = byteCode.length / 0x20;
    uint requiredAlloc = length;

    if (length % 0x20 > 0) //optimise copying the final part of the bytes - to avoid looping with single byte writes
    {
        cycles++;
        requiredAlloc += 0x20; //expand memory to allow end blank, so we don't smack the next stack entry
    }

    stringData = new string(requiredAlloc);

    //copy data in 32 byte blocks
    assembly {
        let cycle := 0

        for
        {
            let mc := add(stringData, 0x20) //pointer into bytes we're writing to
            let cc := add(byteCode, 0x20)   //pointer to where we're reading from
        } lt(cycle, cycles) {
            mc := add(mc, 0x20)
            cc := add(cc, 0x20)
            cycle := add(cycle, 0x01)
        } {
            mstore(mc, mload(cc))
        }
    }

    //finally blank final bytes and shrink size (part of the optimisation to avoid looping adding blank bytes1)
    if (length % 0x20 > 0)
    {
        uint offsetStart = 0x20 + length;
        assembly
        {
            let mc := add(stringData, offsetStart)
            mstore(mc, mload(add(blank, 0x20)))
            //now shrink the memory back so the returned object is the correct size
            mstore(stringData, length)
        }
    }
}
   event getSafeAddressListEvent(string[]   safeaddresskey);
     function  getSafeAddresses(address  walletaddress)   external returns (string memory safeaddressgivenkey)  {
        require (addresscheck[walletaddress]==walletaddress,  "Address is not stored in safe");
         uint256 index =0; 
         uint secindex =0;
           string memory safeaddreesslist;
           

          bytes memory bytifiedwalletaddress = abi.encodePacked(walletaddress);
     string memory stringifiedaddressforwallet = bytesToString(bytifiedwalletaddress);

            for (index = 0; index <= multiwalletlist.length; index++  ){
                if(equal(multiwalletlist[index][0],stringifiedaddressforwallet) == true){
              
               safeaddreesslist =  multiwalletlist[index][1];
               safeaddressarray.push(safeaddreesslist);
               
            
             emit getSafeAddressListEvent (safeaddressarray);
             }
              return (safeaddreesslist); 

     }  

     }
}