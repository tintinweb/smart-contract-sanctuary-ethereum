/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

pragma solidity >=0.4.22 <0.7.0;

contract draw {
    string public name1;
    string public name2;
    string public name3;
    string public name4;
    string public name5;
    uint count = 1;
    uint number;
    string public name;
    
    function first(string memory _first) public{
        name1 = _first;
    }
    function second(string memory _second) public{
        name2 = _second;
    }
    function third(string memory _third) public{
        name3 = _third;
    }
    function fourth(string memory _fourth) public{
        name4 = _fourth;
    }
    function fifth(string memory _fifth) public{
        name5 = _fifth;
    }
     function nameNumber() private returns(uint) {
        number = uint(keccak256(abi.encodePacked(now, count))) % 5;
        count++;
        return number;
    }
    function showName() public view returns(string memory){
        if ( number==0){
            return name5;
        }
        if ( number==1){
            return name1;
        }
        if ( number==2){
            return name2;
        }
        if ( number==3){
            return name3;
        }
        if ( number==4){
            return name4;
        }

        
    }
}