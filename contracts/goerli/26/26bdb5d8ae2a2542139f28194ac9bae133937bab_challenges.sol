/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract challenges{
    mapping (address=>uint256) private points;
    address tokenGate;
    uint256 private secret = 42;
    bytes32 public answer = 0x919c358939206d6b04f5385fad747f7004daccf9fff8db70289be647b4bccda5;

    event Challenge1(address,uint256);

function challenge0(string memory _word)public{
    require(_check(_word),"wrong guess!! hint: explore previous tx");
        points[msg.sender]++;

}
    function _check(string memory _word) private view returns (bool) {
        return keccak256(abi.encodePacked(_word)) == answer;
    }
    function challenge1(uint256 _guess)public{
        require(points[msg.sender]>=1,"Not enough points");
        require(_guess==secret,"you don't know my secret");
        points[msg.sender]++;
        emit Challenge1(msg.sender,points[msg.sender]);
    }

    function myPoints()public view returns (uint256){
        return points[msg.sender];
    }
    function challenge2()public{
        require(points[msg.sender]>=3,"Not enough points");
        points[msg.sender]+=10;

    }

    function challenge3()public payable{
        require(points[msg.sender]>=13,"Not enough points");
        require(msg.value>1,"Pay your due");

        uint256 val=msg.value;
        uint256 money= 10 ether;
        require(_shift(val)>money,"try again");

        points[msg.sender]+=100;


    }
    function _shift(uint256 _number) private pure returns (uint256){

        _number>>=10;
        _number<= 1 ? _number=2: _number--;
        _number+=32;
        _number>>5;

           unchecked{ return uint(_number)-34;}
    
    }

    function challenge4(address player)public {
        require(tx.origin!=msg.sender,"Find 'someone' who can call me");
        points[player]+=10000;

    }

}