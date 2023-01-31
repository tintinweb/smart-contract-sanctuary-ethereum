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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Target } from "./Target.sol";

contract ERC20 is IERC20, Target {
    //////////////////////////////////
    //         CUSTOM ERRORS        //
    //////////////////////////////////

    /// @dev Error when address is zero
    error AddressZero();

    /// @dev Error when address is not minter
    error OnlyMinterAllowed();

    //////////////////////////////////
    //             STATE            //
    //////////////////////////////////
    bytes4 private constant TRANSFER_FUNCTION_SIGNATURE = 0xa9059cbb;
    bytes4 private constant APPROVE_FUNCTION_SIGNATURE = 0x095ea7b3;
    bytes4 private constant TRANSFER_FROM_FUNCTION_SIGNATURE = 0x23b872dd;

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    uint256 public totalSupply;

    address private minterRole;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _receiverAddress,
        address _minterRole
    ) Target(_receiverAddress) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        minterRole = _minterRole;
    }

    //////////////////////////////////
    //           MODIFIERS          //
    //////////////////////////////////

    modifier onlyMinter() {
        if (msg.sender != minterRole) {
            revert OnlyMinterAllowed();
        }
        _;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) public onlyMinter {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) public {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance[owner][spender];
        if (currentAllowance != type(uint256).max) {
            // dont need to check currentAllowance >= amount
            // as it will underflow automically since solidity 0.8
            allowance[owner][spender] = currentAllowance - amount;
        }
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        if (from == address(0) || to == address(0)) {
            revert AddressZero();
        }
        // dont need to check balance of from >= amount
        // as it will underflow automically since solidity 0.8
        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal returns (bool) {
        if (owner == address(0) || spender == address(0)) {
            revert AddressZero();
        }

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);

        return true;
    }

    /// @dev _executeInternal is called by execute in the Target contract
    /// @notice we will extract function sigs from @param data and call
    /// internal erc20 functions depending if the function sig matches
    /// some identifier
    function _executeInternal(bytes calldata data, address from) internal virtual override returns (bool) {
        if (data.length > 0) {
            bytes16 functionSignature = bytes4(data[:16]);

            if (bytes4(functionSignature) == TRANSFER_FUNCTION_SIGNATURE) {
                address to = address(bytes20(data[16:56]));
                uint256 amount = uint256(bytes32(data[36:68]));
                _transfer(from, to, amount);
            } else if (functionSignature == APPROVE_FUNCTION_SIGNATURE) {
                address spender = address(bytes20(data[16:56]));
                uint256 amount = uint256(bytes32(data[36:68]));
                _approve(from, spender, amount);
            } else if (functionSignature == TRANSFER_FROM_FUNCTION_SIGNATURE) {
                address owner = address(bytes20(data[16:36]));
                address to = address(bytes20(data[48:68]));
                uint256 amount = uint256(bytes32(data[68:100]));

                if (from != to) {
                    return false;
                }

                _spendAllowance(owner, from, amount);
                _transfer(owner, from, amount);
            } else {
                return false;
            }
            return true;
        }

        return false;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

abstract contract Target {
    //////////////////////////////////
    //         CUSTOM ERRORS        //
    //////////////////////////////////

    /// @dev error if msg.sender in not receiver contract
    error OnlyReceiver();

    address internal receiverAddress;

    constructor(address _receiverAddress) {
        receiverAddress = _receiverAddress;
    }

    function execute(bytes calldata data, address from) public payable virtual returns (bool) {
        if (msg.sender != receiverAddress) {
            revert OnlyReceiver();
        }

        return _executeInternal(data, from);
    }

    function _executeInternal(bytes calldata data, address from) internal virtual returns (bool);
}