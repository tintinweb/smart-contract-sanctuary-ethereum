/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    uint256 number;
    string message="you won";
    string a = unicode"Hello 😃";
     struct player {
        address addy;
        string ans;

    }
 player[] public players;
    event Play(address from, string msg);

    /**
     * @dev Store value in variable
     * @param _number value to store
     */
    function store(uint256 _number) public {
        number = _number;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number/2;
    }

    function play(uint _guess)public {
        require(_guess%2==0,"not winner");
        emit Play(msg.sender,message);
    }
event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    function enigma(string memory _answer)public{
        //if answer==solution{
    players.push(player(msg.sender,_answer));
        //}
    }
}