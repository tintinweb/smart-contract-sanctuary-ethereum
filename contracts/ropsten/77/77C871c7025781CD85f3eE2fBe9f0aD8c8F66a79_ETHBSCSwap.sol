// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

import "./IERC20.sol";

contract ETHBSCSwap {

    mapping(bytes32 => bool) public filledBSCTx;

    // mapping(address => bool) private whitelist;
    address registeredERC20;
    address payable public owner;
    address payable public vaultWallet;
    uint256 public swapFee;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event SwapStarted(
        address indexed erc20Addr,
        address indexed fromAddr,
        uint256 amount,
        uint256 feeAmount
    );
    event SwapFilled(
        address indexed erc20Addr,
        bytes32 indexed bscTxHash,
        address indexed toAddress,
        uint256 amount
    );

    constructor(
        uint256 fee,
        address erc20Addr,
        address payable ownerAddr,
        address payable vaultWalletAddr
    ) {
        swapFee = fee;
        owner = ownerAddr;
        vaultWallet = vaultWalletAddr;
        registeredERC20 = erc20Addr;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0),"Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Returns set minimum swap fee from ERC20 to BEP20
     */
    function setSwapFee(uint256 fee) external onlyOwner {
        swapFee = fee;
    }

    /**
     * Transfer token from hot wallet to user wallets when user swap back from BSC to ETH
     */
    function fillBSC2ETHSwap(
        bytes32[] calldata bscTxHashArr,
        address[] calldata toAddressArr,
        uint256[] calldata amountArr
    ) external returns (bool) {
        require(bscTxHashArr.length == toAddressArr.length, "Input length");
        require(bscTxHashArr.length == amountArr.length, "Input length");

        for (uint256 i = 0; i < bscTxHashArr.length; i++) {
            require(!filledBSCTx[bscTxHashArr[i]], "bsc tx filled already");

            filledBSCTx[bscTxHashArr[i]] = true;
            require(
                IERC20(registeredERC20).transferFrom(
                    msg.sender,
                    toAddressArr[i],
                    amountArr[i]
                ),
                "Token transfer fail"
            );

            emit SwapFilled(
                registeredERC20,
                bscTxHashArr[i],
                toAddressArr[i],
                amountArr[i]
            );
        }

        return true;
    }

    /**
     * Swap token from ETH to BSC
     */
    function swapETH2BSC(uint256 amount) external payable returns (bool) {
        require(msg.value == swapFee, "swap fee not equal");

        require(
            IERC20(registeredERC20).transferFrom(
                msg.sender,
                vaultWallet,
                amount
            ),
            "Token transfer fail"
        );
        if (msg.value != 0) {
            vaultWallet.transfer(msg.value);
        }

        emit SwapStarted(registeredERC20, msg.sender, amount, msg.value);
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

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