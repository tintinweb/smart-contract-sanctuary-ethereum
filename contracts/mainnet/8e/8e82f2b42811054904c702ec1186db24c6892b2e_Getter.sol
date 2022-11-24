/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

pragma solidity 0.8.12;

contract Getter {
    function getETHBalance(address addr) public view returns (uint256) {
        return address(addr).balance;
    }

    function isContract(address addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size != 0;
    }

    function isERC20(address addr) public view returns (bool) {
        if (!isContract(addr)) return false;
        (bool s,) = addr.staticcall(abi.encodeWithSignature("decimals()"));
        return s;
    }

    function possiblePairs(
        address token0,
        address[] calldata token1s,
        address[] calldata factories
    ) public view returns (bool found, address pair, uint256 amount) {
        if (!isERC20(token0)) {
            return (false, address(0), 0);
        }
        for (uint256 i = 0; i < token1s.length; i++) {
            address token1 = token1s[i];
            address factory = factories[i];
            (bool s, bytes memory data) = factory.staticcall(
                abi.encodeWithSignature("getPair(address,address)", token0, token1)
            );
            if (s) {
                address pair = abi.decode(data, (address));
                if (pair == address(0)) return (false, address(0), 0);
                (bool s2, bytes memory data2) =
                    token1.staticcall(abi.encodeWithSignature("balanceOf(address)", pair));
                if (s2) {
                    uint256 amount = abi.decode(data2, (uint256));
                    if (amount > 0) {
                        return (true, pair, amount);
                    }
                }
            }
        }
        return (false, address(0), 0);
    }

    function possiblePairsV3(
        address token0,
        address[] calldata token1s,
        address[] calldata factories,
        uint24[] calldata fees
    ) public view returns (bool found, address pair, uint256 amount) {
        if (!isERC20(token0)) {
            return (false, address(0), 0);
        }
        for (uint256 i = 0; i < token1s.length; i++) {
            address token1 = token1s[i];
            address factory = factories[i];
            (bool s, bytes memory data) = factory.staticcall(
                abi.encodeWithSignature(
                    "getPool(address,address,uint24)", token0, token1, fees[i]
                )
            );
            if (s) {
                address pair = abi.decode(data, (address));
                if (pair == address(0)) return (false, address(0), 0);
                (bool s2, bytes memory data2) =
                    token1.staticcall(abi.encodeWithSignature("balanceOf(address)", pair));
                if (s2) {
                    uint256 amount = abi.decode(data2, (uint256));
                    if (amount > 0) {
                        return (true, pair, amount);
                    }
                }
            }
        }
        return (false, address(0), 0);
    }
}