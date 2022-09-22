/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

contract calculator2 {
    function calc(int a, int b, int c) public view returns(int){
  

        if (c == 1){
            return a+b;
        }else if (c == 2) {
            return a-b;
        }else if (c == 3) {
            return a*b;
        } 
        else if (c == 4){
            return a/b;
        }else {
            return a%b;
        }
    }
}