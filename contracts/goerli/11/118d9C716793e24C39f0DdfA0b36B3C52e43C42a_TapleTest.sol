// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract TapleTest {
    mapping (address => uint256) public allowList;

    function setAmount(address[] calldata _addresses, uint256 [] memory _amount)
        public
    {
        require(_addresses.length == _amount.length, "Array lengths are different");

        for(uint256 i=0; i<_addresses.length; i++) {
            allowList[_addresses[i]] = _amount[i];
        }
    }
}