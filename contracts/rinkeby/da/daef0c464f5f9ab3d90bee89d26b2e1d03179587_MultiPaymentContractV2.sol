/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/MultiPaymentContract.sol



pragma solidity ^0.8.7;





interface IUniswapV2Router {



    function factory() external pure returns (address);



    function WETH() external pure returns (address);



    function swapExactTokensForTokensSupportingFeeOnTransferTokens(

        uint amountIn,

        uint amountOutMin,

        address[] calldata path,

        address to,

        uint deadline

    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(

        uint amountOutMin,

        address[] calldata path,

        address to,

        uint deadline

    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(

        uint amountIn,

        uint amountOutMin,

        address[] calldata path,

        address to,

        uint deadline

    ) external;

}



contract MultiPaymentContractV2 is Ownable {



    IUniswapV2Router public immutable router;

    IERC20 public immutable PKN;



    address public feeRecipient;



    uint256 public feePercent;



    constructor(

        IERC20 _pkn,

        IUniswapV2Router _router,

        address _feeRecipient,

        uint256 _feePercent

    ) {

        PKN = _pkn;

        router = _router;



        feeRecipient = _feeRecipient;

        feePercent = _feePercent;

    }



    function payETH(

        address seller,

        address[] calldata creators,

        uint256[] calldata royaltyPercents,

        uint256 minPKNOut

    ) external payable {



        uint256 length = creators.length;

        require(length == royaltyPercents.length, "Input length mismatch");



        uint256 balanceBefore = PKN.balanceOf(address(this));

        address[] memory path = new address[](2);

        path[0] = router.WETH();

        path[1] = address(PKN);

        

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(

            minPKNOut,

            path,

            address(this),

            block.timestamp

        );



        uint256 amount = PKN.balanceOf(address(this)) - balanceBefore;



        uint256 creatorShare;

        for(uint256 i = 0; i < length; i++) {

            uint256 share = amount * royaltyPercents[i] / 10000;

            creatorShare += share;

            PKN.transfer(creators[i], share);

        }



        uint256 platformShare = amount * feePercent / 10000;

        PKN.transfer(feeRecipient, platformShare);

        PKN.transfer(seller, amount - creatorShare - platformShare);

    }



    function payERC20(

        address seller,

        address[] calldata creators,

        uint256[] calldata royaltyPercents,

        address[] calldata path,

        uint256 amountIn,

        uint256 minPKNOut

    ) external {



        uint256 length = creators.length;

        require(length == royaltyPercents.length, "Input length mismatch");



        uint256 balanceBefore = PKN.balanceOf(address(this));



        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);

        IERC20(path[0]).approve(address(router), amountIn);



        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(

            amountIn,

            minPKNOut,

            path,

            address(this),

            block.timestamp

        );



        uint256 amount = PKN.balanceOf(address(this)) - balanceBefore;



        uint256 creatorShare;

        for(uint256 i = 0; i < length; i++) {

            uint256 share = amount * royaltyPercents[i] / 10000;

            creatorShare += share;

            PKN.transfer(creators[i], share);

        }



        uint256 platformShare = amount * feePercent / 10000;

        PKN.transfer(feeRecipient, platformShare);

        PKN.transfer(seller, amount - creatorShare - platformShare);

    }



    function changeFeeRecipient(address _feeRecipient) external onlyOwner {

        feeRecipient = _feeRecipient;

    }



    function changeFeePercent(uint256 _feePercent) external onlyOwner {

        feePercent = _feePercent;

    }

}