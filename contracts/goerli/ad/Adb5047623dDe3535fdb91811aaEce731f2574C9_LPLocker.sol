// SPDX-License-Identifier: MIT

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
    function transferFrom(
        address sender,
        address recipient,
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
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LPLocker {
    address public owner;
    uint256 public price;
    uint256 public penaltyfee;

    struct holder {
        address holderAddress;
        mapping(address => Token) tokens;
    }

    struct Token {
        uint256 balance;
        address tokenAddress;
        uint256 unlockTime;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only available to the contract owner.");
        _;
    }

    mapping(address => holder) public holders;

    constructor(address _owner, uint256 _price) {
        owner = _owner;
        price = _price;
        penaltyfee = 10; // default value
    }

    event Hold(
        address indexed holder,
        address token,
        uint256 amount,
        uint256 unlockTime
    );

    event PanicWithdraw(
        address indexed holder,
        address token,
        uint256 amount,
        uint256 unlockTime
    );

    event Withdrawal(address indexed holder, address token, uint256 amount);

    event FeesClaimed();

    event SetOwnerSuccess(address owner);

    event SetPriceSuccess(uint256 _price);

    event SetPenaltyFeeSuccess(uint256 _fee);

    event OwnerWithdrawSuccess(uint256 amount);

    function lpLock(
        address token,
        uint256 amount,
        uint256 unlockTime,
        address withdrawer
    ) public payable {
        require(msg.value >= price, "Required price is low");

        holder storage holder0 = holders[withdrawer];
        holder0.holderAddress = withdrawer;

        Token storage lockedToken = holders[withdrawer].tokens[token];

        if (lockedToken.balance > 0) {
            lockedToken.balance += amount;

            if (lockedToken.unlockTime < unlockTime) {
                lockedToken.unlockTime = unlockTime;
            }
        } else {
            holders[withdrawer].tokens[token] = Token(
                amount,
                token,
                unlockTime
            );
        }

        IERC20(token).transferFrom(withdrawer, address(this), amount);

        emit Hold(withdrawer, token, amount, unlockTime);
    }

    function withdraw(address token) public {
        holder storage holder0 = holders[msg.sender];

        require(
            msg.sender == holder0.holderAddress,
            "Only available to the token owner."
        );

        require(
            block.timestamp > holder0.tokens[token].unlockTime,
            "Unlock time not reached yet."
        );

        uint256 amount = holder0.tokens[token].balance;

        holder0.tokens[token].balance = 0;

        IERC20(token).transfer(msg.sender, amount);

        emit Withdrawal(msg.sender, token, amount);
    }

    function panicWithdraw(address token) public {
        holder storage holder0 = holders[msg.sender];

        require(
            msg.sender == holder0.holderAddress,
            "Only available to the token owner."
        );

        uint256 feeAmount = (holder0.tokens[token].balance / 100) * penaltyfee;
        uint256 withdrawalAmount = holder0.tokens[token].balance - feeAmount;

        holder0.tokens[token].balance = 0;

        //Transfers fees to the contract administrator/owner
        // holders[address(owner)].tokens[token].balance = feeAmount;

        // Transfers fees to the token owner
        IERC20(token).transfer(msg.sender, withdrawalAmount);

        // Transfers fees to the contract administrator/owner
        IERC20(token).transfer(owner, feeAmount);

        emit PanicWithdraw(
            msg.sender,
            token,
            withdrawalAmount,
            holder0.tokens[token].unlockTime
        );
    }

    // function claimTokenListFees(address[] memory tokenList) public onlyOwner {

    //     for (uint256 i = 0; i < tokenList.length; i++) {

    //         uint256 amount = holders[owner].tokens[tokenList[i]].balance;

    //         if (amount > 0) {

    //             holders[owner].tokens[tokenList[i]].balance = 0;

    //             IERC20(tokenList[i]).transfer(owner, amount);
    //         }
    //     }
    //     emit FeesClaimed();
    // }

    // function claimTokenFees(address token) public onlyOwner {

    //     uint256 amount = holders[owner].tokens[token].balance;

    //     require(amount > 0, "No fees available for claiming.");

    //     holders[owner].tokens[token].balance = 0;

    //     IERC20(token).transfer(owner, amount);

    //     emit FeesClaimed();
    // }

    function OwnerWithdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        address payable ownerAddress = payable(owner);

        ownerAddress.transfer(amount);

        emit OwnerWithdrawSuccess(amount);
    }

    function getcurtime() public view returns (uint256) {
        return block.timestamp;
    }

    function GetBalance(address token) public view returns (uint256) {
        Token storage lockedToken = holders[msg.sender].tokens[token];
        return lockedToken.balance;
    }

    function SetOwner(address contractowner) public onlyOwner {
        owner = contractowner;
        emit SetOwnerSuccess(owner);
    }

    function SetPrice(uint256 _price) public onlyOwner {
        price = _price;
        emit SetPriceSuccess(price);
    }

    // function GetPrice() public view returns (uint256) {
    //     return price;
    // }

    function SetPenaltyFee(uint256 _penaltyfee) public onlyOwner {
        penaltyfee = _penaltyfee;
        emit SetPenaltyFeeSuccess(penaltyfee);
    }

    // function GetPenaltyFee() public view returns (uint256) {
    //     return penaltyfee;
    // }

    function GetUnlockTime(address token) public view returns (uint256) {
        Token storage lockedToken = holders[msg.sender].tokens[token];
        return lockedToken.unlockTime;
    }
}