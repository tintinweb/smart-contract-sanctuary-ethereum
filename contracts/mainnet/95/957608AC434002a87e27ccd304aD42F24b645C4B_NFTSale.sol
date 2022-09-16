// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFTSale {
    address public owner;
    
    mapping(address=>uint256[]) userData;
    mapping(uint256=>uint256) public nftPrice;
    
    event tokenTransfer(address from, address to, uint256 amount);
    
    event coinTransfer(address from, address to, uint256 amount);
    
    event ownerWithdraw(address to, uint256 amount);
    
    modifier priceGreaterThanZero(uint256 _price) {
        require(_price > 0, "Price cannot be 0");
        _;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "not owner");
        _;
    }

    modifier isbalanceEnough(address _tokenAddress, uint256 _amount) {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        require(balance >= _amount, "balance not enogh");
        _;
    }

    constructor(
        address _owner
    ) {
        owner = _owner;
    }
     
    function updateOwner(address _owner) external onlyOwner
    {
        owner = _owner;
    }

    function tokenPayment(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount
    ) external priceGreaterThanZero(_amount) 
    {
        tokenTransaction(_tokenAddress, msg.sender, address(this), _amount);
        userData[msg.sender].push(_tokenId);
        nftPrice[_tokenId] = _amount;
        emit tokenTransfer(msg.sender, address(this), _amount);
    }

    function coinPayment(uint256 _tokenId)
        external
        payable
        priceGreaterThanZero(msg.value)
    {
        userData[msg.sender].push(_tokenId);
        nftPrice[_tokenId] = msg.value;
        emit coinTransfer(msg.sender, address(this), msg.value);
    }

    function tokenWithdraw(address _tokenAddress, uint256 _amount)
        external
        onlyOwner
        isbalanceEnough(_tokenAddress, _amount)
    {
        IERC20(_tokenAddress).transfer(owner, _amount);
    }
    
    function withdrawCoin(uint256 _amount) external onlyOwner
    {
        coinTransaction(owner, _amount);
    }

    function getUserData(address _user) external view returns(uint256[] memory)
    {
        return userData[_user];
    }

    
    function tokenTransaction(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        IERC20(_tokenAddress).transferFrom(_from, _to, _amount);
    }

    function coinTransaction(address _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "refund failed");
    }

    receive() payable external {}
}

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