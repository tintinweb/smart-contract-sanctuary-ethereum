/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.14;

interface Weth {
    function withdraw(uint256 _wad) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _wad
    ) external;
}

interface ovmL1Bridge {
    function depositETHTo(
        address _to,
        uint32 _l2Gas,
        bytes calldata _data
    ) external payable;
}

interface PolygonL1Bridge {
    function depositEtherFor(address _to) external payable;
}

/**
 * @notice Contract deployed on Ethereum helps relay bots atomically unwrap and bridge WETH over the canonical chain
 * bridges for Optimism, Boba and Polygon. Needed as these chains only support bridging of ETH, not WETH.
 */

contract AtomicDepositor {
    Weth weth = Weth(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ovmL1Bridge optimismL1Bridge = ovmL1Bridge(0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1);
    ovmL1Bridge bobaL1Bridge = ovmL1Bridge(0xdc1664458d2f0B6090bEa60A8793A4E66c2F1c00);
    PolygonL1Bridge polygonL1Bridge = PolygonL1Bridge(0xA0c68C638235ee32657e8f720a23ceC1bFc77C77);

    function bridgeWethToOvm(
        address to,
        uint256 amount,
        uint32 l2Gas,
        uint256 chainId
    ) public {
        require(chainId == 10 || chainId == 288, "Can only bridge to Optimism Or boba");
        weth.transferFrom(msg.sender, address(this), amount);
        weth.withdraw(amount);
        (chainId == 10 ? optimismL1Bridge : bobaL1Bridge).depositETHTo{ value: amount }(to, l2Gas, "");
    }

    function bridgeWethToPolygon(address to, uint256 amount) public {
        weth.transferFrom(msg.sender, address(this), amount);
        weth.withdraw(amount);
        polygonL1Bridge.depositEtherFor{ value: amount }(to);
    }

    fallback() external payable {}

    receive() external payable {}
}