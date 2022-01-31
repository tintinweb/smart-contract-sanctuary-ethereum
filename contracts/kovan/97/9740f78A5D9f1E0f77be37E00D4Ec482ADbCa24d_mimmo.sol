// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {
    struct st {
    uint256 number;
    }
   
   st public min;
    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(address mio, uint256 num) public payable{
        st memory std = st(num);
        std.number = 5;
        min.number = std.number;
        mimmo(mio).setVal{value: 1000000};
    }

     receive() external payable {}

}

contract mimmo {
    uint public xx;
    uint public yy;
    function setVal() public payable {
        yy = 14;
         xx = msg.value;
    }
}