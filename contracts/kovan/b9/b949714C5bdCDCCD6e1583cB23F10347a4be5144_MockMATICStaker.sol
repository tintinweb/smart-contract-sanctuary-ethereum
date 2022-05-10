// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "IMockMATICStaker.sol";

contract MockMATICStaker is IMockMATICStaker{

    function getTotalMATICDeposited() external view override returns(uint) {
        return address(this).balance;
    }

    function transferMATIC(uint _amount, address _to) external override returns (uint) {
        (bool success,) = payable(_to).call{value: _amount}("");
        require( success , "MockMATICStaker: MATIC transfer failed");
        return _amount;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;


interface IMockMATICStaker  {
    // --- Events ---


    // --- Functions ---

    function getTotalMATICDeposited() external returns (uint);

    function transferMATIC(uint _amount, address _to) external returns (uint);

}