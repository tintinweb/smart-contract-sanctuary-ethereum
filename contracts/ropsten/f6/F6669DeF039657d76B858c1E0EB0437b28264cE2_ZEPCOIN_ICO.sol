/**
 *Submitted for verification at Etherscan.io on 2022-10-04
*/

// File: @openzeppelin/[email protected]/token/ERC20/IERC20.sol


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

// File: contract-80a5197803.sol


pragma solidity ^0.8.4;


contract Ownable {
    address private _owner;

    constructor () {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Function accessible only by the owner !!");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
}

contract ZEPCOIN_ICO is Ownable{

    IERC20 usdt = IERC20(
            address(0x2c5D5b0ba86a08b776939C821350434b167b1624) // usdt Token address here just for testing
        );

    uint256 public totalRaisedAmount = 0;
    bool public icoStatus;
    bool public testBool ;
    address public TokenContract;
    uint256 public current_Price = 200;
    
   

constructor (address _tokenContract){
    TokenContract = _tokenContract;
}

    function ChangePrice(uint256 NewPrice) external onlyOwner{
       current_Price = NewPrice;
    }

    function ChangeTokenAddress (address newAddres) external onlyOwner{
        TokenContract = newAddres;
    }

    function BuyToken (uint256 Usdt_Amount) public {
        require(!icoStatus,"zepcoin ico is stopped");
        require(Usdt_Amount>=0,"sorry insufficient balance");
        testBool = true;
        usdt.transferFrom(msg.sender,address(this),Usdt_Amount);
        IERC20 ZEPX_TK = IERC20(
            address(TokenContract) // ZEPX Token address here just for testing
        );
        ZEPX_TK.transfer(msg.sender,Usdt_Amount*100);
        totalRaisedAmount = totalRaisedAmount + 1;

    }

    function StopIco () external onlyOwner {
        icoStatus = false;
    }

    function ActivateIco () external onlyOwner {
        icoStatus = true;
    }

   function withdraw_fund(uint256 usdtFund) external onlyOwner {
        
        usdt.transfer(0x2c5D5b0ba86a08b776939C821350434b167b1624, usdtFund);
   }

   function withdraw_unsoldZEPX(uint256 ZEPX_Ammount) public onlyOwner{
        IERC20 ZEPX_TK = IERC20(
            address(0x3dcC0fAF3ae5ea9a1ef9831f7873eC3d87237f78) // ZEPX Token address here just for testing
        );
       ZEPX_TK.transfer(msg.sender,ZEPX_Ammount);
   }
    
}