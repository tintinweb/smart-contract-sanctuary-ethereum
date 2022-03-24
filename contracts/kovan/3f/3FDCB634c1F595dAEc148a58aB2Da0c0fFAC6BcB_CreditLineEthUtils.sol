// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import '../interfaces/IWETH9.sol';
import '../interfaces/ICreditLine.sol';

contract CreditLineEthUtils {
    IWETH9 public immutable weth;
    ICreditline public immutable creditlines;

    constructor(address _weth, address _creditLines) {
        weth = IWETH9(_weth);
        creditlines = ICreditline(_creditLines);
    }

    function depositEthAsCollateralToCreditLine(uint256 _id) external payable {
        require(msg.value != 0, 'DECCL1');
        weth.deposit{value: msg.value}();
        weth.approve(address(creditlines), msg.value);
        creditlines.depositCollateral(_id, msg.value, false);
    }

    function repayEthToCreditLines(uint256 _id) external payable {
        require(msg.value != 0, 'RECL1');
        weth.deposit{value: msg.value}();
        weth.approve(address(creditlines), msg.value);
        creditlines.repay(_id, msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface ICreditline {
    function depositCollateral(
        uint256 _id,
        uint256 _amount,
        bool _fromSavingsAccount
    ) external;

    function repay(uint256 _id, uint256 _amount) external;
}