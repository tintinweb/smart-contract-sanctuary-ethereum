/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// File: Auction.sol



pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/// @title Manages the contract owner
contract Owned {
    address payable contractOwner;

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "only owner can perform this operation");
        _;
    }

    constructor() {
        contractOwner = payable(msg.sender);
    }

    function whoIsTheOwner() public view returns(address) {
        return contractOwner;
    }

    function changeOwner(address _newOwner) onlyOwner public returns (bool) {
        require(_newOwner != address(0x0), "only valid address");
        contractOwner = payable(_newOwner);
        return true;
    }

}

/// @title Mortal allows the owner to kill the contract
contract Mortal is Owned  {
    function kill() public {
        require(msg.sender==contractOwner, "Only owner can destroy the contract");
        selfdestruct(contractOwner);
    }
}

/// @title ERC-20 Token template
contract Auction is IERC20Metadata, Mortal {
    string private myName;
    string private mySymbol;
    uint256 private myTotalSupply;
    uint8 private myDecimals;

    address public walletWinner;
    uint256 public lastBid = 0;
    address public contractAddress = 0xa80eA10ab8ff93e6bf1c1ac2CA87367103f94AC0;

    bool public ended = false;

    mapping (address=>uint256) balances;
    mapping (uint256=>uint256) tokenWinner;
    mapping (address=>mapping (address=>uint256)) ownerAllowances;

    event BidAuction(address wallet, uint256 amount, uint256 tokenId, address contractAddress);
    event BidAuctionWinner(address wallet, uint256 tokenId, address contractAddress);

    modifier hasEnoughBalance(address owner, uint amount) {
        uint balance;
        balance = balances[owner];
        //require (balance >= amount);
        _;
    }

    modifier isAllowed(address spender, address tokenOwner, uint amount) {
        //require (amount <= ownerAllowances[tokenOwner][spender]);
        _;
    }

    modifier tokenAmountValid(uint256 amount) {
        //require(amount > 0);
        //require(amount <= myTotalSupply);
        _;
    }

    constructor() {
        myName = "wToken";
        mySymbol = "wToken";
        myDecimals = 0;
    }

    function name() public view returns(string memory) {
        return myName;
    }

    function symbol() public view returns(string memory) {
        return mySymbol;
    }

    function totalSupply() public override view returns(uint256) {
        return myTotalSupply;
    }

    function decimals() public override view returns (uint8) {
        return myDecimals;
    }

    function balanceOf(address tokenOwner) public override view returns(uint256) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns(uint256) {
        return ownerAllowances[tokenOwner][spender];
    }

    function transfer(address to, uint256 amount) public override hasEnoughBalance(msg.sender, amount) tokenAmountValid(amount) returns(bool) {
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[to] = balances[to] + amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferToken(address to, uint256 amount) payable public hasEnoughBalance(contractOwner, amount) tokenAmountValid(amount) returns(bool) {
        balances[contractOwner] = balances[contractOwner] - amount;
        balances[to] = balances[to] + amount;
        contractOwner.transfer(msg.value);
        emit Transfer(contractOwner, to, amount);
        return true;
    }

    function approve(address spender, uint limit) public override returns(bool) {
        require(spender != address(0), "ERC20: approve to the zero address");
        ownerAllowances[msg.sender][spender] = limit;
        emit Approval(msg.sender, spender, limit);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override
    hasEnoughBalance(from, amount) isAllowed(msg.sender, from, amount) tokenAmountValid(amount)
    returns(bool) {
        balances[from] = balances[from] - amount;
        balances[to] += amount;
        ownerAllowances[from][msg.sender] = amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function mint(address account, uint256 amount) public returns (bool) {
        require(account != address(0), "ERC20: mint to the zero address");

        myTotalSupply = myTotalSupply + amount;
        balances[account] = balances[account] + amount;
        emit Transfer(address(0), account, amount);
        return true;
    }

    function bidAuction(uint256 amount, uint256 tokenId) public returns (bool) {
        require(amount <= balances[msg.sender], "Incompatible balance");
        require(amount > lastBid, "Bid less than the current momentary winner");
        require(ended == false, "Auction ended");
        walletWinner = msg.sender;
        lastBid = amount;
        emit BidAuction(msg.sender, amount, tokenId, contractAddress);
        balances[msg.sender] = balances[msg.sender] - amount;
        myTotalSupply = myTotalSupply - amount;
        emit Transfer(address(0), msg.sender, amount);
        return true;
    }

    function burn(address account, uint256 amount) public onlyOwner returns (bool) {
        require(account != address(0), "ERC20: burn from address");

        balances[account] = balances[account] - amount;
        myTotalSupply = myTotalSupply - amount;
        emit Transfer(address(0), account, amount);
        return true;
    }

    function endsAuction(bool state) public {
        ended = state;
    }

    function closesAuction(uint256 tokenId) public returns (bool) {
        require(tokenId != tokenWinner[tokenId], "NFT already delivered to the winner.");
        emit BidAuctionWinner(walletWinner, tokenId, contractAddress);
        tokenWinner[tokenId] = tokenId;
        return true;
    }
}