/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: REPO/blame.sol


pragma solidity ^0.8.7;

interface Blame {
    function getBlameDetail(uint256 _id) external view returns (string memory, uint256);
    function createBlame(string memory your_blame) external;
    function deleteBlame(uint256 blameId) external;
    function boostBlame(uint256 _blameId, uint256 boostQuantity) external;
}

contract theBlame is Blame {
    uint256 constant PRICE = 10000000;
    IERC20 private blameCoin; 

    constructor(address payable tokenAddress) {
        blameCoin = IERC20(tokenAddress); 
    }
    string [] descBlame;
    uint256 uniqueId = 0;
    uint256 [] boosts;
     
    function getBlameDetail(uint256 _id) public view override returns (string memory, uint256) {
        return (descBlame[_id], boosts[_id]);
    }

     function createBlame(string memory your_blame) public override {
        require( 
            blameCoin.transferFrom(msg.sender, address(this), PRICE),
            "Transaction Error"
        );
        descBlame.push(your_blame);
        boosts.push(0);
        uniqueId++;
    }
    function deleteBlame(uint256 blameId) public override {
        require(blameId<=uniqueId,"There is no blame for the id you specified.");
        require( 
            blameCoin.transferFrom(msg.sender, address(this), PRICE * (PRICE + boosts[blameId]) / 5000000),
            "Transaction Error"
        );
        delete descBlame[blameId];
    }
    function boostBlame(uint256 _blameId, uint256 boostQuantity) public override {
        require(_blameId<=uniqueId,"There is no blame for the id you specified.");
        require( 
            blameCoin.transferFrom(msg.sender, address(this), PRICE + 5000000),
            "Transaction Error"
        );
        boosts[_blameId] = boostQuantity;
    }
 }