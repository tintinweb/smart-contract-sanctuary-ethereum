/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

interface IDAI {
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract Vault {
    address public _daiAddress = 0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735;
    IDAI dai;

    constructor() {
        dai = IDAI(_daiAddress);
    }

    function permitWithDAI(
        address owner,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 transferAmount
    ) external {
        dai.permit(
            owner,
            spender,
            nonce,
            expiry,
            allowed,
            v,
            r,
            s
        );

        dai.transferFrom(
            owner,
            spender,
            transferAmount
        );
    }

    function returnAllowance(
        address owner,
        address spender
    ) external view returns (uint256) {
        return dai.allowance(owner, spender);
    }
}