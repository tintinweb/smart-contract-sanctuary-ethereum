// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

import '../interfaces/IERC20.sol';
import '../interfaces/IWETH.sol';
import './SafeMath.sol';
import './TransferHelper.sol';

library TokenShares {
    using SafeMath for uint256;
    using TransferHelper for address;

    uint256 private constant PRECISION = 10**18;
    uint256 private constant TOLERANCE = 10**18 + 10**16;

    event UnwrapFailed(address to, uint256 amount);

    struct Data {
        mapping(address => uint256) totalShares;
        address weth;
    }

    function sharesToAmount(
        Data storage data,
        address token,
        uint256 share,
        uint256 amountLimit,
        address refundTo
    ) external returns (uint256) {
        if (share == 0) {
            return 0;
        }
        if (token == data.weth) {
            return share;
        }

        uint256 totalTokenShares = data.totalShares[token];
        require(totalTokenShares >= share, 'TS3A');
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 value = balance.mul(share).div(totalTokenShares);
        data.totalShares[token] = totalTokenShares.sub(share);

        if (amountLimit > 0) {
            uint256 amountLimitWithTolerance = amountLimit.mul(TOLERANCE).div(PRECISION);
            if (value > amountLimitWithTolerance) {
                TransferHelper.safeTransfer(token, refundTo, value.sub(amountLimitWithTolerance));
                return amountLimitWithTolerance;
            }
        }

        return value;
    }

    function amountToShares(
        Data storage data,
        address token,
        uint256 amount,
        bool wrap
    ) external returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        if (token == data.weth) {
            if (wrap) {
                require(msg.value >= amount, 'TS03');
                IWETH(token).deposit{ value: amount }();
            } else {
                token.safeTransferFrom(msg.sender, address(this), amount);
            }
            return amount;
        } else {
            uint256 balanceBefore = IERC20(token).balanceOf(address(this));
            uint256 totalTokenShares = data.totalShares[token];
            require(balanceBefore > 0 || totalTokenShares == 0, 'TS30');
            if (totalTokenShares == 0) {
                totalTokenShares = balanceBefore;
            }
            token.safeTransferFrom(msg.sender, address(this), amount);
            uint256 balanceAfter = IERC20(token).balanceOf(address(this));
            require(balanceAfter > balanceBefore, 'TS2C');
            if (balanceBefore > 0) {
                uint256 newShares = totalTokenShares.mul(balanceAfter).div(balanceBefore);
                data.totalShares[token] = newShares;
                return newShares - totalTokenShares;
            } else {
                data.totalShares[token] = balanceAfter;
                return balanceAfter;
            }
        }
    }

    function onUnwrapFailed(
        Data storage data,
        address to,
        uint256 amount
    ) external {
        emit UnwrapFailed(to, amount);
        IWETH(data.weth).deposit{ value: amount }();
        TransferHelper.safeTransfer(data.weth, to, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    int256 private constant _INT256_MIN = -2**255;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'SM4E');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = sub(x, y, 'SM12');
    }

    function sub(
        uint256 x,
        uint256 y,
        string memory message
    ) internal pure returns (uint256 z) {
        require((z = x - y) <= x, message);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'SM2A');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SM43');
        return a / b;
    }

    function ceil_div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = div(a, b);
        if (a != mul(b, c)) {
            return add(c, 1);
        }
    }

    function toUint32(uint256 n) internal pure returns (uint32) {
        require(n <= type(uint32).max, 'SM50');
        return uint32(n);
    }

    function toUint112(uint256 n) internal pure returns (uint112) {
        require(n <= type(uint112).max, 'SM51');
        return uint112(n);
    }

    function toInt256(uint256 unsigned) internal pure returns (int256 signed) {
        require(unsigned <= uint256(type(int256).max), 'SM34');
        signed = int256(unsigned);
    }

    // int256

    function add(int256 a, int256 b) internal pure returns (int256 c) {
        c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), 'SM4D');
    }

    function sub(int256 a, int256 b) internal pure returns (int256 c) {
        c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), 'SM11');
    }

    function mul(int256 a, int256 b) internal pure returns (int256 c) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), 'SM29');

        c = a * b;
        require(c / a == b, 'SM29');
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, 'SM43');
        require(!(b == -1 && a == _INT256_MIN), 'SM42');

        return a / b;
    }

    function neg_floor_div(int256 a, int256 b) internal pure returns (int256 c) {
        c = div(a, b);
        if ((a < 0 && b > 0) || (a >= 0 && b < 0)) {
            if (a != mul(b, c)) {
                c = sub(c, 1);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH4B');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH05');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH0E');
    }

    function safeTransferETH(
        address to,
        uint256 value,
        uint256 gasLimit
    ) internal {
        (bool success, ) = to.call{ value: value, gas: gasLimit }('');
        require(success, 'TH3F');
    }

    function transferETH(
        address to,
        uint256 value,
        uint256 gasLimit
    ) internal returns (bool success) {
        (success, ) = to.call{ value: value, gas: gasLimit }('');
    }
}