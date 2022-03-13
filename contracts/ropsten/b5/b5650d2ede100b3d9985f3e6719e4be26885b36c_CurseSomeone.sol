/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

pragma solidity >=0.4.16 <0.9.0;

contract CurseSomeone {
    event Cursed(address indexed cursed_by, address indexed cursed_person, string the_curse, uint256 timestamp);

    function curse_someone(address cursed_person, string memory curse) public returns (bool) {
        emit Cursed(msg.sender, cursed_person, curse, block.timestamp);
        return true;
    }
}