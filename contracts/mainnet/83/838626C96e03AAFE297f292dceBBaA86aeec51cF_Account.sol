// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interface/IAuthCenter.sol";
import "./FundsBasic.sol";

// import "hardhat/console.sol";

contract Account is FundsBasic {
    IAuthCenter public authCenter;
    bool flag;

    function init(IAuthCenter _authCenter) external {
        require(!flag, "BYDEFI: already initialized!");
        authCenter = _authCenter;
        flag = true;
    }

    function pull(
        address _token,
        uint256 _amt,
        address _to
    ) external override returns (uint256 amt) {
        authCenter.ensureAccountAccess(msg.sender);
        amt = _pull(_token, _amt, _to);
    }

    function useless() public pure returns (uint256 a, string memory s) {
        a = 100;
        s = "hello world!";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuthCenter {
    function ensureAccountAccess(address _caller) external view;
    function ensureFundsProviderPullAccess(address _caller) external view;
    function ensureFundsProviderRebalanceAccess(address _caller) external view;
    function ensureOperatorAccess(address _caller) external view;
    function ensureOperatorPullAccess(address _caller) external view;
    function ensureAccountManagerAccess(address _caller) external view;
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { IERC20 } from "./dependencies/openzeppelin/IERC20.sol";
import "./library/Configure.sol";
import "./library/TransferHelper.sol";

abstract contract FundsBasic {
    using TransferHelper for address;
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    event Push(address token, uint256 amt);
    event Pull(address token, uint256 amt, address to);

    function push(address _token, uint256 _amt) external payable virtual returns (uint256 amt) {
        amt = _amt;

        if (_token != Configure.ETH_ADDRESS) {
            _token.safeTransferFrom(msg.sender, address(this), _amt);
        } else {
            require(msg.value == _amt, "BYDEFI: Invalid Ether Amount");
        }
        emit Push(_token, _amt);
    }

    function pull(
        address _token,
        uint256 _amt,
        address _to
    ) external virtual returns (uint256 amt);

    function _pull(
        address _token,
        uint256 _amt,
        address _to
    ) internal noReentrant returns (uint256 amt) {
        amt = _amt;
        if (_token == Configure.ETH_ADDRESS) {
            (bool retCall, ) = _to.call{ value: _amt }("");
            require(retCall != false, "BYDEFI: pull ETH from account fail");
        } else {
            _token.safeTransfer(_to, _amt);
        }
        emit Pull(_token, _amt, _to);
    }

    function getBalance(IERC20[] memory _tokens) external view returns (uint256, uint256[] memory) {
        uint256[] memory array = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            array[i] = _tokens[i].balanceOf(address(this));
        }
        return (address(this).balance, array);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Configure {
    address public constant ZERO_ADDRESS = address(0);
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}