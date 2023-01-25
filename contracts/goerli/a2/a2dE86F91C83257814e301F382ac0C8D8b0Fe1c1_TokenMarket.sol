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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenMarket {
    address admin;
    IERC20 tokenAddress;
    string Title;
    string Description;
    address payable wallet;
    uint256 rate;
    uint256 TotalSupply;
    uint256 Price;
    uint256 Amount_OF_TokenTransfer;
    uint256 id;

    constructor(
        string memory _Title,
        string memory _Description,
        uint256 _rate,
        uint256 _TotalSupply,
        address payable _wallet,
        IERC20 _tokenAddress
    ) {
        require(_wallet != address(0));

        admin = msg.sender;
        wallet = _wallet;
        Title = _Title;
        Description = _Description;
        rate = _rate;
        TotalSupply = _TotalSupply;
        tokenAddress = _tokenAddress;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can Genrate the token..");
        _;
    }

    mapping(address => uint256) public TokenData;

    function User() public payable {
        require(msg.value > 0, "Not Suffient Balnace");

        Price = msg.value;

        wallet.transfer(msg.value);

        IERC20(tokenAddress).transferFrom(admin, address(this), TotalSupply);
    }

    function Developer(address _to) public {
        require(
            TotalSupply >= Amount_OF_TokenTransfer,
            "The Amount is not valid"
        );

        if (TotalSupply > (TotalSupply * 20) / 100) {
            Amount_OF_TokenTransfer = (Price / rate);
        } else if (TotalSupply <= (TotalSupply * 30) / 100) {
            Amount_OF_TokenTransfer = (Price / rate) - 1;
        } else if (TotalSupply <= (TotalSupply * 40) / 100) {
            Amount_OF_TokenTransfer = (Price / rate) - 2;
        } else if (TotalSupply <= (TotalSupply * 60) / 100) {
            Amount_OF_TokenTransfer = (Price / rate) - 3;
        }

        IERC20(tokenAddress).transfer(_to, Amount_OF_TokenTransfer);
    }

    function remaningSupply() public returns (uint256) {
        TotalSupply = TotalSupply - Amount_OF_TokenTransfer;
        return TotalSupply;
    }
}