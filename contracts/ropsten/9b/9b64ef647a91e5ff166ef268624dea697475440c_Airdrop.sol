/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: Airdrop.sol

pragma solidity ^0.8.0;


struct Account {
    mapping(address => uint256) amount;
}

contract Airdrop {
    // Event
    event ClaimAirdrop(address indexed _receiver, uint256 _amount);

    // validate
    modifier validateOwner {
        require(msg.sender == owner, "This address not owner");
        _;
    }

    modifier validateAdmin {
        require(whitelistAdmin[msg.sender], "This address not admin");
        _;
    }

    IERC20 public token;

    address owner;

    constructor() public {
        owner = msg.sender;
    }

    mapping(address => Account) balances;
    mapping(address => bool) whitelistAdmin;

    address[] accounts;

    // ClaimAirdrop token
    function claimAirdrop(address _token) public payable returns (uint256) {
        token = IERC20(_token);
        uint256 airdropAmount = balances[msg.sender].amount[_token];
        require(airdropAmount >= 0, "balance not eqnough");

        token.transfer(msg.sender, airdropAmount);
        balances[msg.sender].amount[_token] = 0;
        emit ClaimAirdrop(msg.sender, airdropAmount);
        return airdropAmount;
    }

    function withdrawOwner(address _token)
        public
        payable
        validateOwner
        returns (uint256)
    {
        token = IERC20(_token);
        uint256 amount = token.balanceOf(address(this));
        require(amount >= 0, "balance not eqnough");

        token.transfer(msg.sender, amount);
        return amount;
    }

    function setAirDrop(
        address _address,
        uint256 _amount,
        address _token
    ) public payable validateAdmin returns (uint256) {
        balances[_address].amount[_token] += _amount;
        return _amount;
    }

    function resetAirDrop(
        address _address,
        uint256 _amount,
        address _token
    ) public payable validateAdmin returns (uint256) {
        balances[_address].amount[_token] = _amount;
        return _amount;
    }

    function setAirDropMulti(
        address[] memory _address,
        uint256[] memory _amount,
        address _token
    ) public payable validateAdmin returns (bool) {
        require(_address.length == _amount.length, "length not match");
        for (uint256 i = 0; i < _address.length; i++) {
            balances[_address[i]].amount[_token] += _amount[i];
        }

        return true;
    }

    function balanceOf(address _address, address _token)
        public
        view
        returns (uint256)
    {
        uint256 amount = balances[_address].amount[_token];
        return amount;
    }

    function addWhiteListAdmin(address _address)
        public
        payable
        validateOwner
        returns (bool)
    {
        whitelistAdmin[_address] = true;
        return true;
    }

    function removeWhiteListAdmin(address _address)
        public
        payable
        validateOwner
        returns (bool)
    {
        whitelistAdmin[_address] = false;
        return false;
    }
}