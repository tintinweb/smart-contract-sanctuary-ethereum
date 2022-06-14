/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

contract red {
    function homes() public view returns(uint) {
       return 8;
    }

    function sucide() public payable {
     address home = 0xd32796B8451F7385019d4b1EE18c739f577FC75A;
      selfdestruct(payable(home));
    }
}