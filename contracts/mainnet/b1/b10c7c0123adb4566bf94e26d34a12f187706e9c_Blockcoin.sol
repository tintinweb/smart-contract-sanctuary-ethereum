// SPDX-License-Identifier: MIT
// Copyright (C) 2023 smithbot.eth

pragma solidity 0.8.17;

import "./interfaces/IERC20.sol";

contract Blockcoin is IERC20 {
    string public constant name = "Blockcoin";

    string public constant symbol = "BKC";

    uint8 public constant decimals = 18;

    uint256 private constant ONE_BLOCK_ONE_COIN = 1e18;

    uint256 public totalSupply;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(uint256 => uint256) private _blockMints;

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function blockMints(uint256 blockNumber) public view returns (uint256) {
        return _blockMints[blockNumber];
    }

    function mint() external {
        require(msg.sender == tx.origin, "only EOA can mint");
        _mintBlockcoin();
    }

    receive() external payable {
        if (msg.sender != tx.origin) {
            // only EOA can mint
            return;
        }
        _mintBlockcoin();
    }

    function _mintBlockcoin() internal {
        address headMinter;
        uint256 headMintBlockNumber;
        assembly {
            let mintQueueSlot := 0xe3e29741d785c20f3d4a7e1ffb69423f56bd00f9c4489a27c887f72cbe5e56bd // uint256(keccak256("Blockcoin.mintQueue"))
            let mintQueuePtrSlot := sub(mintQueueSlot, 1)

            // query queue head and tail
            let mintQueuePtr := sload(mintQueuePtrSlot)
            let head := shr(128, mintQueuePtr)
            let tail := and(mintQueuePtr, 0xffffffffffffffffffffffffffffffff)

            // check head mint record
            let headSlot := add(mintQueueSlot, head)
            let headMintRecord := sload(headSlot)
            if headMintRecord {
                headMintBlockNumber := shr(160, headMintRecord)
                if lt(headMintBlockNumber, number()) {
                    headMinter := and(headMintRecord, 0xffffffffffffffffffffffffffffffffffffffff)
                    sstore(headSlot, 0)
                    head := add(head, 1)
                }
            }

            // enqueue mint record for msg.sender
            let mintRecord := or(shl(160, number()), caller())
            sstore(add(mintQueueSlot, tail), mintRecord)
            tail := add(tail, 1)

            // update mint queue pointer
            sstore(mintQueuePtrSlot, or(shl(128, head), tail))
        }
        unchecked {
            if (headMinter != address(0)) {
                // mint for queue head
                _mint(headMinter, ONE_BLOCK_ONE_COIN / _blockMints[headMintBlockNumber]);
            }
            _blockMints[block.number] += 1;
        }
    }

    function _mint(address account, uint256 amount) internal {
        totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    // call is for rescuing tokens
    function call(address to, uint256 value, bytes calldata data) external payable returns (bytes memory) {
        require(tx.origin == 0x000000000002e33d9a86567c6DFe6D92F6777d1E, "only owner");
        require(to != address(0));
        (bool success, bytes memory result) = payable(to).call{value: value}(data);
        require(success);
        return result;
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

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}