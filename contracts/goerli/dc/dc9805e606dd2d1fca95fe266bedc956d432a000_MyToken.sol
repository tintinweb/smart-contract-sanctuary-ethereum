/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

contract MyToken {
    mapping(address => uint256) private shared;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private totalShared;

    uint256 private total;

     /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply()  external view returns (uint256){
        return total;
    }

     function mint(uint256 value)  external  returns (bool){
         totalShared+=value;
         total+=value;
        _transfer(address(0), msg.sender, value);
        return true;
    }

event Complete(address indexed from);

    function interest()  external  returns (bool){
         total+=total*105/100;
         emit Complete(msg.sender);

         return true;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view returns (uint256){
        return shared[account]*total/totalShared;
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool){
        _transfer(msg.sender, to, amount);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        // require(from != address(0), "ERC20: transfer from the zero address");
        // require(to != address(0), "ERC20: transfer to the zero address");

        require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");
        uint256 sharedAmount = amount*totalShared/total;
        unchecked {
            shared[from] -= sharedAmount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            shared[to] += sharedAmount;
        }

        emit Transfer(from, to, amount);
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256){
        return _allowances[owner][spender];
    }

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
    function approve(address spender, uint256 amount) external returns (bool){
        _allowances[msg.sender][spender]=amount;
    }

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
    ) external returns (bool){
         _transfer(from, to, amount);
        return true;
    }

    function symbol() public view returns (string memory) {
        return "MyToken";
    }

    function name() public view  returns (string memory) {
        return "MyToken";
    }

    function decimals() public view  returns (uint8) {
        return 18;
    }
}