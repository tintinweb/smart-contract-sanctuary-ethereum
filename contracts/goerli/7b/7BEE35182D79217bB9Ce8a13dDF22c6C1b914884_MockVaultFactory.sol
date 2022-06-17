// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {MockVault} from "./MockVault.sol";

contract MockVaultFactory {
    address public feeTo;
    uint256 constant salt = 0;

    constructor(address _feeTo) {
        feeTo = _feeTo;
    }

    function createVault(address _owner, string memory _projectId) public returns (address addr) {
        bytes memory code = getCreationCode(_owner, _projectId);
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
    }

    // Public for view + implementation purposes
    function computeDeterministicAddr(address _owner, string memory _projectId) public view returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                address(this),
                                salt,
                                keccak256(getCreationCode(_owner, _projectId))
                            )
                        )
                    )
                )
            );
    }

    // Public for debug purposes
    function getCreationCode(address _owner, string memory _projectId) public view returns (bytes memory) {
        return abi.encodePacked(type(MockVault).creationCode, abi.encode(_owner, _projectId, feeTo));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

error LengthMismatch();

contract MockVault {
    address public owner;
    string public projectId;
    address public feeTo;

    event Withdraw(address token, uint256 amount);
    event Payout(address token, uint256 amount);

    constructor(
        address _owner,
        string memory _projectId,
        address _feeTo
    ) {
        owner = _owner;
        projectId = _projectId;
        feeTo = _feeTo;
    }

    function withdraw(uint256[] memory amounts, address[] memory tokenAddr)
        public
    {
        if (amounts.length != tokenAddr.length) {
            revert LengthMismatch();
        }
        for (uint256 i = 0; i < amounts.length; i++) {
            IERC20(tokenAddr[i]).transfer(owner, amounts[i]);
            emit Withdraw(tokenAddr[i], amounts[i]);
        }
    }

    function payout(
        uint256[] memory amounts,
        address[] memory tokenAddr,
        address whitehat
    ) public {
        if (amounts.length != tokenAddr.length) {
            revert LengthMismatch();
        }
        for (uint256 i = 0; i < amounts.length; i++) {
            IERC20(tokenAddr[i]).transfer(whitehat, amounts[i]);
            IERC20(tokenAddr[i]).transfer(whitehat, amounts[i] / 10);
            emit Payout(tokenAddr[i], amounts[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}