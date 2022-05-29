/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

pragma solidity ^0.8.14;

interface Weth {
    function withdraw(uint256 _wad) external;
    function transferFrom(address _from, address _to, uint256 _wad) external;
}

interface OptimismL1StandardBridge {
    function depositETHTo(
        address _to,
        uint32 _l2Gas,
        bytes calldata _data
    ) external payable;
}

interface PolygonL1StandardBridge {
    function withdrawTo(address _to, uint256 _amount) external;
}

contract AtomicDepositor {
    Weth weth = Weth(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    OptimismL1StandardBridge optimismL1StandardBridge = OptimismL1StandardBridge(0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1);

    function bridgeWethEthToOptimsim(
        address to,
        uint256 amount,
        uint32 l2Gas
    ) public {
        weth.transferFrom(msg.sender,address(this), amount);
        weth.withdraw(amount);
        optimismL1StandardBridge.depositETHTo{ value: amount }(to, l2Gas, "");
    }
}