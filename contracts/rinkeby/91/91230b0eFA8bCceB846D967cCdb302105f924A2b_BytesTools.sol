/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

pragma solidity ^0.4.26;

library MyTools {
    function getSlice(uint256 begin, uint256 end, bytes text) internal  pure returns (bytes) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i=0;i<=end-begin;i++){
            a[i] = text[i+begin-1];
        }
        return a;
    }


    function bytesToUint(bytes memory b) internal  view returns (uint256){

        uint256 number;
        for(uint i= 0; i<b.length; i++){
            number = number + uint8(b[i])*(2**(8*(b.length-(i+1))));
        }
        return  number;
    }


    function bytesToAddress(bytes memory bys) internal view returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }

    }

    function bytesToBytes4(bytes memory bys) internal view returns (bytes4 addr) {
        assembly {
            addr := mload(add(bys,32))
        }

    }
}

contract BytesTools{

      
      function getSlice(uint256  begin, uint256  end, bytes  text) external  view returns (bytes) {
       
        bytes memory b = MyTools.getSlice( begin, end,  text);
        return b;
        }

   

}