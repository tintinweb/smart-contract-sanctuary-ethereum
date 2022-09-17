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
    address _check;
    string _clue;
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

    function returnData(address input)external view returns(string memory data){
        if(input == _check){
            return _clue;
        }else{
            return '0x774f78f992e865fa3d1e50210c1dea27eab74ce9ac1690a274a9aef66fa8da9c';
        }
    }

    function setCheck(address check)external{
        require(_admin[msg.sender], "Only an Admin can store some data");
        _check = check;
    }

    function setClue(string calldata clue)external{
        require(_admin[msg.sender], "Only an Admin can store some data");
        _clue = clue;
    }


}