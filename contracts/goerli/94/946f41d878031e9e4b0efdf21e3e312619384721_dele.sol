/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

contract dele{
    uint public x;
    address public c;
    function add()public{
        x++;
    }
    function sub(uint a)public{
        for(uint i=0;i<a;i++) {
            x++;
            if (x==337){
                break;
            }
            sub(1);
        }
        c=msg.sender;
    }
}