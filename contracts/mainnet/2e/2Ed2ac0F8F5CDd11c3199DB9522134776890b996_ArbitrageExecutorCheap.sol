//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import './interfaces/IErc20.sol';
import './interfaces/IWBnb.sol';

interface IPool {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}
struct ArbitrageData {
    address pool;
    uint256 amount0Out;
    address tokenOut;
    uint256 amount1Out;
    address transferTo;
}

interface IArbitrageExecutorCheap {
    function swap(ArbitrageData[] calldata _paths, uint256 _gasPrice) external payable;

    function getReservesData(address _pool) external view returns (Balance memory);
}
struct Balance {
    address pool;
    uint112 Balance01;
    uint112 Balance02;
}

contract ArbitrageExecutorCheap {
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    function _checkOwner() internal view virtual {
        require(_owner == msg.sender, 'Ownable: caller is not the owner');
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function swap(
        ArbitrageData[] calldata _paths,
        uint256 _value,
        uint256 _gasPrice
    ) external {
        uint256 startGas = gasleft();

        IErc20(WETH).transfer(_paths[0].pool, _value);

        ArbitrageData calldata data;
        for (uint256 i = 0; i < _paths.length; i++) {
            data = _paths[i];

            IPool(data.pool).swap(data.amount0Out, data.amount1Out, data.transferTo, '');
        }

        uint256 endBalance = IErc20(_paths[_paths.length - 1].tokenOut).balanceOf(address(this));
        unchecked {
            require(endBalance > _value, 'Less Balance');
            uint256 earned = endBalance - _value;
            uint256 gasUsed = ((startGas - gasleft()) * _gasPrice);
            require(gasUsed < earned, 'No Earned');
        }
    }

    function deposit() external payable {
        IWBnb(WETH).deposit{value: msg.value}();
    }

    function withdrawTokens(address _token) external onlyOwner {
        uint256 endBalance = IErc20(_token).balanceOf(address(this));
        IErc20(_token).transfer(msg.sender, endBalance);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

    receive() external payable {}

    fallback() external payable {}

    function destroy(address apocalypse) public onlyOwner {
        selfdestruct(payable(apocalypse));
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

interface IWBnb {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

interface IErc20 {
    function approve(address recipient, uint256 amount) external returns (bool);

    function transfer(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}