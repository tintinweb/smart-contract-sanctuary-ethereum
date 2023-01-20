// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Mevitize} from "mev-weth/Mevitize.sol";

interface IERC20 {
    function approve(address, uint256) external returns (bool);
}

// Helper contract for MevWallet draining
contract Drain {
    function drain(address to) public {
        payable(to).transfer(address(this).balance);
    }

    function approveAll(address asset, address to) public {
        IERC20(asset).approve(to, type(uint256).max);
    }

    function drainAndApprove(address to) public {
        drain(to);
        approveAll(0x00000000008C43efC014746c230049e330039Cb3, to);
    }
}

// SPDX-License-Identifier: Apache-2.0 OR MIT OR GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

interface IMevWeth {
    function mev() external returns (uint256);
    function addMev(uint256 value) external;
    function addMev(address from, uint256 value) external;
    function getMev() external;
    function getMev(uint256 value) external;
    function getMev(address to) external;
    function getMev(address to, uint256 value) external;
}

// SPDX-License-Identifier: Apache-2.0 OR MIT OR GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IMevWeth} from "./IMevWeth.sol";

contract Mevitize {
    IMevWeth constant mevWeth = IMevWeth(0x00000000008C43efC014746c230049e330039Cb3);

    error ExactBaseFee(); // 0x2daf442d

    modifier mev(int256 loot) {
        if (loot > 0) {
            mevWeth.addMev(uint256(loot));
        } else {
            mevWeth.getMev(uint256(-1 * loot));
        }
        _;
    }

    modifier mevFrom(address from, int256 loot) {
        if (loot > 0) {
            mevWeth.addMev(from, uint256(loot));
        } else {
            mevWeth.getMev(from, uint256(-1 * loot));
        }
        _;
    }

    modifier subsidize(int256 tip) {
        uint256 gp = tx.gasprice;
        uint256 bf = block.basefee;
        if (bf != gp) revert ExactBaseFee(); // this asserts that there is no tip
        uint256 pre = gasleft();
        _;
        uint256 post = gasleft();
        int256 loot = tip + int256(gp * (pre - post));
        if (loot > 0) {
            mevWeth.addMev(uint256(loot));
        } else {
            mevWeth.getMev(uint256(-1 * loot));
        }
    }

    modifier subsidizeFrom(address from, int256 tip) {
        uint256 gp = tx.gasprice;
        uint256 bf = block.basefee;
        if (bf != gp) revert ExactBaseFee(); // this asserts that there is no tip
        uint256 pre = gasleft();
        _;
        uint256 post = gasleft();
        int256 loot = tip + int256(gp * (pre - post));
        if (loot > 0) {
            mevWeth.addMev(from, uint256(loot));
        } else {
            mevWeth.getMev(from, uint256(-1 * loot));
        }
    }
}