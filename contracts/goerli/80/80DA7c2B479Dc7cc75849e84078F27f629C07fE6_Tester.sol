pragma solidity ^0.6.0;
contract Tester  {
    /*Just return*/
    function add(uint256 a,uint256 b) public view returns (uint256) {
        return 2+a;
    }

    function test(uint256 x, uint256 y) public view returns(uint256){
        require(msg.sender != address(0));
        uint256 tsrif;
        uint256 dnoces;
        //Pointless ‮
        (dnoces, tsrif) = (x, y);

        return add(x,y);
    }
}