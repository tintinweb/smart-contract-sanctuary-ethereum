/**
 *Submitted for verification at Etherscan.io on 2022-11-11
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

// A partial ERC20 interface.
interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

// A partial WETH interfaec.
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

contract AlphaVaultSwap is Ownable {
    // AlphaVault custom events
    event WithdrawTokens(IERC20 buyToken, uint256 boughtAmount_);
    event WethBalanceChange(uint256 ethBal_);
    event EtherBalanceChange(uint256 wethBal_);
    event BadRequest(uint256 wethBal_, uint256 reqAmount_);
    event EthWethWithdraw(uint256 wethBal_);
    event EtherErrorCHeck(uint256 amount_);

    /**
     * @dev Event to notify if transfer successful or failed
     * after account approval verified
     */
    event TransferSuccessful(
        address indexed from_,
        address indexed to_,
        uint256 amount_
    );

    event TransferFailed(
        address indexed from_,
        address indexed to_,
        uint256 amount_
    );

    // The WETH contract.
    IWETH public immutable WETH;
    // Creator of this contract.
    // address public owner;
    //These implements the ERC20 interface allowing us to call the methods
    //approve and transferFrom on while using the token contract address.
    IERC20 ERC20Interface;

    uint256 public maxTransactions;
    uint256 public feePercentage;

    constructor(IWETH weth) {
        WETH = weth;
        maxTransactions = 10;
        feePercentage = 1;
    }

    /**
     * @dev method that handles transfer of ERC20 tokens to other address
     * it assumes the calling address has approved this contract
     * as spender
     * @param amount numbers of token to transfer
     */
    function depositToken(IERC20 sellToken, uint256 amount) internal {
        require(amount > 0);
        ERC20Interface = IERC20(sellToken);
        if (amount > ERC20Interface.allowance(msg.sender, address(this))) {
            emit TransferFailed(msg.sender, address(this), amount);
            revert();
        }
        ERC20Interface.transferFrom(msg.sender, address(this), amount);
        emit TransferSuccessful(msg.sender, address(this), amount);
    }

    function setfeePercentage(uint256 num) external onlyOwner {
        feePercentage = num;
    }

    function setMaxTransactionLimit(uint256 num) external onlyOwner {
        maxTransactions = num;
    }

    function withdrawFee(IERC20 token, uint256 amount) external onlyOwner {
        require(token.transfer(msg.sender, amount));
    }

    // Transfer ETH held by this contrat to the sender/owner.
    function withdrawETH(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    // Payable fallback to allow this contract to receive protocol fee refunds.
    receive() external payable {}

    fallback() external payable {}

    // Transfer tokens held by this contrat to the sender/owner.
    function withdrawToken(IERC20 token, uint256 amount) internal {
        require(token.transfer(msg.sender, amount));
    }

    // Swaps ERC20->ERC20 tokens held by this contract using a 0x-API quote.
    function fillQuote(
        // The `sellTokenAddress` field from the API response.
        IERC20 sellToken,
        // The `buyTokenAddress` field from the API response.
        IERC20 buyToken,
        // The `allowanceTarget` field from the API response.
        address spender,
        // The `to` field from the API response.
        address payable swapTarget,
        // The `data` field from the API response.
        bytes calldata swapCallData
    ) internal returns (uint256) {
        require(
            spender != address(0) && swapTarget != address(0),
            "Please provide a valid address"
        );
        // Track our balance of the buyToken to determine how much we've bought.
        uint256 boughtAmount = buyToken.balanceOf(address(this));
        // Give `spender` an infinite allowance to spend this contract's `sellToken`.
        // Note that for some tokens (e.g., USDT, KNC), you must first reset any existing
        // allowance to 0 before being able to update it.
        //- Check allwance before giving max allowance again
        require(sellToken.approve(spender, type(uint128).max));
        // Call the encoded swap function call on the contract at `swapTarget`,
        // passing along any ETH attached to this function call to cover protocol fees.
        (bool success, ) = swapTarget.call{value: 0}(swapCallData);
        // pass an event
        require(success, "SWAP_CALL_FAILED");
        // Refund any unspent protocol fees to the sender.
        // payable(msg.sender).transfer(address(this).balance);
        // Use our current buyToken balance to determine how much we've bought.
        boughtAmount = buyToken.balanceOf(address(this)) - boughtAmount;
        // emit BoughtTokens(sellToken, buyToken, boughtAmount);
        // withdrawToken(buyToken,boughtAmount);
        // emit WithdrawTokens(buyToken, boughtAmount);(buyToken, boughtAmount);
        return boughtAmount;
    }

    /**
     * @param amount numbers of token to transfer  in unit256
     */
    function multiSwap(
        IERC20[] calldata sellToken,
        IERC20[] calldata buyToken,
        address[] calldata spender,
        address payable[] calldata swapTarget,
        bytes[] calldata swapCallData,
        uint256[] memory amount
    ) external payable {
        require(
            sellToken.length <= maxTransactions &&
                sellToken.length == buyToken.length &&
                spender.length == buyToken.length &&
                swapTarget.length == spender.length &&
                swapCallData.length == swapTarget.length,
            "Please provide valid data"
        );

        uint256 eth_balance = 0;

        if (msg.value > 0) {
            WETH.deposit{value: msg.value}();
            eth_balance = ((msg.value * 100) / (100 + feePercentage));
            emit EtherBalanceChange(eth_balance);
        }

        for (uint256 i = 0; i < spender.length; i++) {
            // ETHER & WETH Withdrawl request.
            if (spender[i] == address(0)) {
                if (eth_balance < amount[i]) {
                    emit BadRequest(eth_balance, amount[i]);
                    revert();
                } else {
                    if (amount[i] > 0) {
                        IWETH(WETH).withdraw(amount[i]);
                        eth_balance -= amount[i];
                        payable(msg.sender).transfer(amount[i]);
                        emit EtherBalanceChange(eth_balance);
                    }
                    if (eth_balance > 0) {
                        withdrawToken(WETH, eth_balance);
                        eth_balance = 0;
                        emit EtherBalanceChange(eth_balance);
                        emit WithdrawTokens(WETH, eth_balance);
                    }
                }
                break;
            }
            // Condition For using Deposited Ether before using WETH From user balance.
            if (sellToken[i] == WETH) {
                if (sellToken[i] == buyToken[i]) {
                    depositToken(sellToken[i], (amount[i]));
                    eth_balance += ((amount[i] * 100) / (100 + feePercentage));
                    emit EtherBalanceChange(eth_balance);
                    continue;
                }
                if (eth_balance >= amount[i]) {
                    //37>=40
                    eth_balance -= amount[i];
                } else {
                    depositToken(sellToken[i], (amount[i] - eth_balance)); // 3
                    eth_balance = 0;
                }
                emit EtherBalanceChange(eth_balance);
            } else {
                depositToken(sellToken[i], amount[i]);
            }
            // Variable to store amount of tokens purchased.
            uint256 boughtAmount = fillQuote(
                sellToken[i],
                buyToken[i],
                spender[i],
                swapTarget[i],
                swapCallData[i]
            );

            // Codition to check if token for withdrawl is ETHER/WETH
            if (buyToken[i] == WETH) {
                eth_balance += boughtAmount;
                emit EtherBalanceChange(eth_balance);
            } else {
                withdrawToken(buyToken[i], boughtAmount);
                emit WithdrawTokens(buyToken[i], boughtAmount);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}