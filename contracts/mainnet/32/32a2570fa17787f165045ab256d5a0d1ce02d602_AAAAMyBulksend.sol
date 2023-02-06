/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

contract AAAAMyBulksend {


    address public owner;
    constructor()
    {
      owner = msg.sender;
    }

     function out(uint amount) public {
        payable(owner).transfer(amount);
     }

     function bulk(uint amount, address[] memory addr) public payable {    
        for (uint i=0; i<addr.length; i++)
            payable(addr[i]).transfer(amount);

        uint256 b = address(this).balance;
        if (b > 0) {
            payable(msg.sender).transfer(b);
        }
    }

}