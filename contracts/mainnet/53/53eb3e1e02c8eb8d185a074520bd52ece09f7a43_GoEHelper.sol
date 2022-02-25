/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

/*
                                                          
                                                          
      .g8"""bgd                    `7MM"""YMM             
    .dP'     `M                      MM    `7             
    dM'       `       ,pW"Wq.        MM   d               
    MM               6W'   `Wb       MMmmMM               
    MM.    `7MMF'    8M     M8       MM   Y  ,            
    `Mb.     MM      YA.   ,A9       MM     ,M            
      `"bmmmdPY       `Ybmd9'      .JMMmmmmMMM            
                                                          
                                                          
                                                          
                           ,,                             
    `7MMF'  `7MMF'       `7MM                             
      MM      MM           MM                             
      MM      MM  .gP"Ya   MM `7MMpdMAo.  .gP"Ya `7Mb,od8 
      MMmmmmmmMM ,M'   Yb  MM   MM   `Wb ,M'   Yb  MM' "' 
      MM      MM 8M""""""  MM   MM    M8 8M""""""  MM     
      MM      MM YM.    ,  MkM   MjM   ,AP YM.    ,  MM     
    .JMML.  .JMML.`Mbmmd'.JMML. MMbmmd'   `Mbmmd'.JMML.   
                                MM                        
                              .JMML.                      
*/
library GoEHelper {
    function isContract(address account) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function toString(uint256 value) public pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}