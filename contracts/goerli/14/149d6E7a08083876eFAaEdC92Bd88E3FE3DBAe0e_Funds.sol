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

// SPDX-License-Identifier: MIT
// Author: Jaydenomidax

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Funds {
    constructor() {}

    /////////////////////
    // STRUCTS //
    /////////////////////
    struct Proceeds {
        uint256 ethBalance;
        uint256 bnbBalance;
        uint256 smdxBalance;
        uint256 usdtBalance;
    }

    mapping(address => Proceeds) public s_proceeds;

    /////////////////////
    // EVENTS //
    /////////////////////

    event Transfer(
        address indexed receiver,
        address indexed sender,
        uint256 amount,
        string symbol
    );
    event Deposit(
        address indexed depositAddress,
        string indexed symbol,
        uint256 amount
    );
    event Withdraw(
        address indexed withdrawalAddress,
        string indexed symbol,
        uint256 amount
    );

    event buyCofee(
        address indexed userAddress,
        address indexed sender,
        uint256 smdxAmout
    );

    function transfer(
        address receiver,
        uint256 amount,
        string memory symbol,
        address payToken
    ) external {
        Proceeds memory proceed = s_proceeds[msg.sender];
        if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("smdx"))
        ) {
            if (proceed.smdxBalance < amount) {
                revert("Insufficient Funds");
            }
            s_proceeds[msg.sender].smdxBalance -= amount;
            s_proceeds[receiver].smdxBalance += amount;

            emit Transfer(receiver, msg.sender, amount, symbol);
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("eth"))
        ) {
            if (proceed.ethBalance < amount) {
                revert("Insufficient Funds");
            }
            s_proceeds[msg.sender].ethBalance -= amount;
            s_proceeds[receiver].ethBalance += amount;

            emit Transfer(receiver, msg.sender, amount, symbol);
        } else {
            if (proceed.bnbBalance < amount) {
                revert("Insufficient Funds");
            }
            s_proceeds[msg.sender].bnbBalance -= amount;
            s_proceeds[receiver].bnbBalance += amount;

            emit Transfer(receiver, msg.sender, amount, symbol);
        }
    }

    function depositEth(
        string memory symbol,
        address payToken
    ) external payable {
        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        s_proceeds[msg.sender].ethBalance += msg.value;
        emit Deposit(msg.sender, symbol, msg.value);
    }

    function withdrawEth(
        string memory symbol,
        uint256 amount,
        address payToken
    ) external {
        Proceeds memory proceeds = s_proceeds[msg.sender];

        if (proceeds.ethBalance < amount) {
            revert("Not Enough Funds");
        }

        s_proceeds[msg.sender].ethBalance -= amount;
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to send Ether");

        emit Withdraw(msg.sender, symbol, amount);
    }

    function deposit(
        string memory symbol,
        uint256 amount,
        address payToken
    ) external {
        if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("smdx"))
        ) {
            IERC20(payToken).transferFrom(msg.sender, address(this), amount);

            s_proceeds[msg.sender].smdxBalance += amount;
            emit Deposit(msg.sender, symbol, amount);
        } else {
            IERC20(payToken).transferFrom(msg.sender, address(this), amount);

            s_proceeds[msg.sender].usdtBalance += amount;
            emit Deposit(msg.sender, symbol, amount);
        }
    }

    function withdraw_proceeds(
        string memory symbol,
        uint256 amount,
        address payToken
    ) external {
        Proceeds memory proceeds = s_proceeds[msg.sender];

        if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("smdx"))
        ) {
            if (proceeds.smdxBalance < amount) {
                revert("Not Enough Funds");
            }

            s_proceeds[msg.sender].smdxBalance -= amount;
            IERC20(payToken).transfer(msg.sender, amount);

            emit Withdraw(msg.sender, symbol, amount);
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("usdt"))
        ) {
            if (proceeds.usdtBalance < amount) {
                revert("Not Enough Funds");
            }

            s_proceeds[msg.sender].usdtBalance -= amount;
            IERC20(payToken).transfer(msg.sender, amount);

            emit Withdraw(msg.sender, symbol, amount);
        }
    }

    function buy_cofee(
        address userAddress,
        string memory symbol,
        uint256 amount,
        address payToken
    ) public {
        if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("eth"))
        ) {
            (bool sent, ) = payable(address(this)).call{value: amount}("");
            require(sent, "Failed to send Ether");

            s_proceeds[userAddress].ethBalance += amount;
            emit buyCofee(userAddress, msg.sender, amount);
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("smdx"))
        ) {
            IERC20(payToken).transferFrom(msg.sender, address(this), amount);

            s_proceeds[userAddress].smdxBalance += amount;
            emit buyCofee(userAddress, msg.sender, amount);
        } else {
            IERC20(payToken).transferFrom(msg.sender, address(this), amount);

            s_proceeds[userAddress].usdtBalance += amount;
            emit buyCofee(userAddress, msg.sender, amount);
        }
    }

    function increaseUserFunds(address _payToken, uint256 totalPrice) external {
        if (
            keccak256(abi.encodePacked(_payToken)) ==
            keccak256(
                abi.encodePacked("0x7019B818a21545Fd062A20A2aC768539B34B9AC7")
            )
        ) {
            s_proceeds[msg.sender].usdtBalance += totalPrice;
        } else {
            s_proceeds[msg.sender].smdxBalance += totalPrice;
        }
    }

    receive() external payable {}

    /////////////////////
    // Getter Functions //
    /////////////////////

    function getProceeds(
        address seller
    ) external view returns (Proceeds memory) {
        return s_proceeds[seller];
    }
}