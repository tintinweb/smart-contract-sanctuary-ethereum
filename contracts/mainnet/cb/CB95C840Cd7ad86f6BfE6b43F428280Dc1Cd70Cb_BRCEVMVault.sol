// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface WETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function transfer(address to, uint256 amount) external returns (bool);
}

contract BRCEVMVault {
    address public admin;

    address public wethAddress;
    mapping(address => bool) public whitelistToken;
    mapping(bytes32 => bool) public usedTxids;

    // Deposit token
    event Deposit(
        address indexed from,
        address indexed to,
        address indexed tokenAddress,
        uint256 amount
    );

    // Withdraw token
    event Withdraw(
        address indexed to,
        address indexed tokenAddress,
        uint256 amount,
        bytes32 txid
    );

    // Withdraw token
    event AdminChanged(address indexed admin, address indexed newAdmin);

    constructor(address _wethAddress) {
        admin = msg.sender;
        wethAddress = _wethAddress;
        whitelistToken[_wethAddress] = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    receive() external payable {}

    function changeAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "Invalid address");
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    function setWETHAddress(address _wethAddress) public onlyAdmin {
        wethAddress = _wethAddress;
        whitelistToken[_wethAddress] = true;
    }

    function setWhitelistToken(
        address[] memory tokenAddresses
    ) public onlyAdmin {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            whitelistToken[tokenAddresses[i]] = true;
        }
    }

    function removeWhitelistToken(
        address[] memory tokenAddresses
    ) public onlyAdmin {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            whitelistToken[tokenAddresses[i]] = false;
        }
    }

    function deposit(
        address tokenAddress,
        address to,
        uint256 amount
    ) public payable {
        if (tokenAddress == address(0)) {
            WETH weth = WETH(wethAddress);
            weth.deposit{value: msg.value}();

            emit Deposit(msg.sender, to, wethAddress, msg.value);
        } else {
            require(
                whitelistToken[tokenAddress],
                "Token address is not whitelisted"
            );

            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), amount);

            emit Deposit(msg.sender, to, tokenAddress, amount);
        }
    }

    function withdraw(
        address tokenAddress,
        address to,
        uint256 amount,
        bytes32 txid
    ) public onlyAdmin {
        require(
            whitelistToken[tokenAddress],
            "Token address is not whitelisted"
        );

        require(!usedTxids[txid], "Txid used");

        if (wethAddress == tokenAddress) {
            WETH weth = WETH(tokenAddress);
            weth.withdraw(amount);
            (bool success, ) = to.call{value: amount}("");
            require(success, "Token transfer failed");
        } else {
            IERC20 token = IERC20(tokenAddress);
            require(token.transfer(to, amount), "Token transfer failed");
        }

        usedTxids[txid] = true;

        emit Withdraw(to, tokenAddress, amount, txid);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}