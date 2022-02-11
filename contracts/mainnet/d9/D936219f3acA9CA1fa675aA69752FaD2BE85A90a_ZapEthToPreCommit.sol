// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.6;

import "IERC20.sol";
import "IWETH.sol";
import "IPreCommit.sol";
import "Ownable.sol";

contract ZapEthToPreCommit is Ownable {
    IWETH public immutable weth;
    IPreCommit public immutable preCommit;

    constructor(address _weth, address _preCommit) {
        require(_weth != address(0), "weth = zero address");
        require(_preCommit != address(0), "pre commit = zero address");

        weth = IWETH(_weth);
        preCommit = IPreCommit(_preCommit);

        IERC20(_weth).approve(_preCommit, type(uint).max);
    }

    function zap() external payable {
        require(msg.value > 0, "value = 0");
        weth.deposit{value: msg.value}();
        preCommit.commit(msg.sender, msg.value);
    }

    function recover(address _token) external onlyOwner {
        if (_token != address(0)) {
            IERC20(_token).transfer(
                msg.sender,
                IERC20(_token).balanceOf(address(this))
            );
        } else {
            payable(msg.sender).transfer(address(this).balance);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.6;

interface IWETH {
    function deposit() external payable;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.6;

interface IPreCommit {
    function commit(address _from, uint _amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.6;

import "IOwnable.sol";

contract Ownable is IOwnable {
    event OwnerNominated(address newOwner);
    event OwnerChanged(address newOwner);

    address public owner;
    address public nominatedOwner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function nominateNewOwner(address _owner) external override onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external override {
        require(msg.sender == nominatedOwner, "not nominated");

        owner = msg.sender;
        nominatedOwner = address(0);

        emit OwnerChanged(msg.sender);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.6;

interface IOwnable {
    function nominateNewOwner(address _owner) external;
    function acceptOwnership() external;
}