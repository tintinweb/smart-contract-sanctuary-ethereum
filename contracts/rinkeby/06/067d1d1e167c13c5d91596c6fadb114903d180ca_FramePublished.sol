/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.13;

// We are almost there. This contract will give you your next clue.
// Good luck!

contract FramePublished{

    bool _revealClue = false;
    uint256 _num = 0.1*10**18;
    address _data;
    address _clue;
    mapping(address => bool) _admin;
    address _recipient;

    constructor(){
        _admin[msg.sender] = true;
        _recipient=msg.sender;
    }

    function getNextClue()external payable{
        require(msg.value >= _num);
        payable(_recipient).transfer(_num);
        _revealClue = true;
    }

    function returnData(address input)external view returns(address){
        if(input == _data){
            return _clue;
        }else{
            return address(0);
        }
    }

    function setData(address data)external{
        require(_admin[msg.sender], "Only an Admin can store some data");
        _data = data;
    }

    function setClue(address clue)external{
        require(_admin[msg.sender], "Only an Admin can store some data");
        _clue = clue;
    }


}