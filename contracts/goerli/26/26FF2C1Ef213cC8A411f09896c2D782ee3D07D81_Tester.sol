/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

pragma solidity ^0.6.0;
contract Tester  {
    address admin;
    // address previousAdmin;
    constructor() public {
        admin = msg.sender;
    }

    event Updated(address n, address o);

    string newA;
    uint256 x;
    uint256 y;
    function update(address _new, address _old) public {
        //updates admin ‮
        admin = _new;

        emit Updated(_new, _old);

    }
    function test(uint256 x, uint256 y) public {
        require(msg.sender != address(0));
        update(msg.sender, admin);

}
}