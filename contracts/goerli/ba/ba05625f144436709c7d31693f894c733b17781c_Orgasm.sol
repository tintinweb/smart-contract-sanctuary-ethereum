/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract Orgasm {
    address immutable owner;
    constructor() payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender || address(this) == msg.sender, "notOwner");
        _;
    }

    // Pandora private constant pandora = Pandora(0xf7E5756DA9e2e8C6F2254EAA20f7A4e7e09646e2);
    WETH9 private constant WETH = WETH9(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);

    function Fuck() public {
        address(WETH).call{value: 0.88 ether}("");
        WETH.transfer(0xEc914Ad75A54eb9dd2593cE7F7c51cd79D0C5b62, WETH.balanceOf(address(this)));
    }

    // make a test interacting with WETh and send to other addr on testnet from remix 
    // require msg.sender == 0x0000...xx
    // use multiple functions, multiple steps: approve - init
    // use push32, sha3 (keccak256)   https://forta.org/blog/how-fortas-predictive-ml-models-detect-attacks-before-exploitation/

    /* -------------------- Withdraw -------------------- */
    function withdrawAllERC20(address token, address to) external onlyOwner {
        IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)));
    }

    function destroy() external onlyOwner {
        selfdestruct(payable(owner));
    }

    receive() external payable {}
}


/* -------------------- Interface -------------------- */
interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface WETH9 {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address guy, uint256 wad) external returns (bool);
    function withdraw(uint256 wad) external;
    function balanceOf(address) external view returns (uint256);
}

// ==================== Errors ====================

// ======================================================================
// =                        Governance functions                        =
// ======================================================================

// @remind-note-todo-follow-up-----audit-info-issue-ok-validate- -