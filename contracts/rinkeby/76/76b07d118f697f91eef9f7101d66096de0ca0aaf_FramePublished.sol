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
    string _data;
    mapping(address => bool) _admin;
    address _recipient;

    constructor(){
        _admin[msg.sender] = true;
        _recipient=msg.sender;
    }

    function getNextClue()external payable{
        // This function checks that you have enough funds to finish the game.
        // You will need to enter the amount we want too check in the Etherscan window
        // (0.1 ETH)
        // If you don't have this sum, you will not be able to finish the game
        require(msg.value >= _num);
        payable(_recipient).transfer(_num);
        _revealClue = true;
    }

    function returnData()external view returns(string memory){
        return _data;
    }

    function setData(string calldata data)external{
        require(_admin[msg.sender], "Only an Admin can store some data");
        _data = data;
    }


}