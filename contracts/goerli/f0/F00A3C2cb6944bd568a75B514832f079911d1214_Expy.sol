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
pragma solidity ^0.8.7;

//import "./interfaces/IExpy.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Expy__MarketplaceisPaused();
error Expy__NotOwner();
error Expy__AddressisZero();
error Expy__PriceisZero();
error Expy__SenderDidNotSendCorrectAmount();

contract Expy {

    event MarketplacePaused(address indexed owner);
    event MarketplaceUnPaused(address indexed owner);
    event PaymentReceivedNative(address indexed from, address indexed to, uint256 amount);
    event WithdrawCompletedNative(address indexed reciever, uint256 amount);
    event WithdrawCompleted(address indexed reciever, address indexed token, uint256 amount);
    event SentGasFee(uint256 amount);

    address private immutable i_owner;
    address payable private beneficiary;
    bool public paused = false;
    bool internal locked;

    receive() external payable {
        emit Expy.PaymentReceivedNative(msg.sender, address(this), msg.value);
    }
    fallback() external payable {
        emit Expy.PaymentReceivedNative(msg.sender, address(this), msg.value);
    }

    modifier notPaused() {
        if(paused) { revert Expy__MarketplaceisPaused(); }
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) { revert Expy__NotOwner(); } 
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor(address payable newBeneficiary) {
        ensureIsNotZeroAddr(newBeneficiary);
        i_owner = msg.sender;
        beneficiary = newBeneficiary;
    }

    // function collectNative(uint256 amount) external payable notPaused {
    //     ensureIsNotZeroPrice(amount);
    //     ensureValueEqualsAmount(amount, msg.value);
    //     emit IExpy.PaymentReceivedNative(msg.sender, address(this), amount);
    // }

    function collectNative() external payable notPaused {
        require(msg.value > 0, "Amount is zero");
        //require(amount == msg.value, "Value doesn't equal amount");
        emit Expy.PaymentReceivedNative(msg.sender, address(this), msg.value);
    }

    function withdrawNative(address receiver, uint256 amount) external notPaused onlyOwner noReentrant{
        ensureIsNotZeroAddr(receiver);
        ensureIsNotZeroPrice(amount);
        
        payable(receiver).transfer(amount);

        emit Expy.WithdrawCompletedNative(receiver, amount);
    }

    function withdraw(address receiver, address token, uint256 amount) external notPaused onlyOwner noReentrant{
        ensureIsNotZeroAddr(receiver);
        ensureIsNotZeroAddr(token);
        ensureIsNotZeroPrice(amount);
        
        IERC20(token).transfer(receiver, amount);

        emit Expy.WithdrawCompleted(receiver, token, amount);
    }
    
    function sendGasFee(uint256 amount) external notPaused onlyOwner noReentrant{
        ensureIsNotZeroPrice(amount);
        
        payable(i_owner).transfer(amount);

        emit Expy.SentGasFee(amount);
    }

    function transferFrom(address token, address from, address to, uint amount)
        public
        returns (bool)
    {
        // require(registry.contracts(msg.sender));
        return IERC20(token).transferFrom(from, to, amount);
    }


      /////////////////////
     // Logic Functions //
    /////////////////////

    function ensureIsNotZeroAddr(address addr) private pure {
        if(addr == address(0)) {
            revert Expy__AddressisZero();
        }
    }

    function ensureIsNotZeroPrice(uint256 amount) private pure {
        if(amount <= 0) {
            revert Expy__PriceisZero(); 
        }
    }

    function ensureValueEqualsAmount(uint256 amount, uint256 value) private pure {
        if(amount != value) {
            revert Expy__SenderDidNotSendCorrectAmount(); 
        }
    }

      /////////////////////////////////
     // Getter and Setter Functions //
    /////////////////////////////////

    function setBeneficiary(address payable newBeneficiary) external onlyOwner {
        beneficiary = newBeneficiary;
    }

    function getBeneficiary() external view returns (address) {
        return beneficiary;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function setPaused(bool newPaused) external onlyOwner {
        paused = newPaused;
        if(paused) {
            emit MarketplacePaused(msg.sender);
        } else {
            emit MarketplaceUnPaused(msg.sender);
        }
    }
}