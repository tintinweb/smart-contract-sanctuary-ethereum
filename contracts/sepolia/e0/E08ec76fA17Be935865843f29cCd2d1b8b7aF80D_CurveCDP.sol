/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/curveCDP.sol


pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

 interface IcrvDepositor {
    function deposit(uint256 ,bool, bool, address) external;
 }
 interface Isdcrv3 {
    function mintRequest(address, uint256) external;
    function approve(address, uint256) external;
 }

contract CurveCDP { 
    address public crvDepositor;
    address public sdCRV3;
    address public crv;
    constructor( address _crvdepositor, address _sdCRV3, address _CRV) {
        crvDepositor = _crvdepositor;
        sdCRV3 = _sdCRV3;
        crv = _CRV; 
    }

    function updatesdCRV3(address _sdcrvNew) public {
        sdCRV3 = _sdcrvNew;
    }

    function depositCRV (uint256 _amount, bool _lock, bool _stake) public returns(bool) {
        
        require(_amount > 0," !Invalid Amount");
        require(IERC20(crv).balanceOf(msg.sender) >= _amount, "Low Balance");
       
        IERC20(crv).transferFrom(msg.sender, address(this), _amount);
        IERC20(crv).approve(address(crvDepositor), _amount);

        IcrvDepositor(crvDepositor).deposit(_amount, _lock, _stake, address(this)); //sdcrv-gauge tokens will be transferred to our contract

        Isdcrv3(sdCRV3).mintRequest(msg.sender,_amount);

        return true;
    }

}