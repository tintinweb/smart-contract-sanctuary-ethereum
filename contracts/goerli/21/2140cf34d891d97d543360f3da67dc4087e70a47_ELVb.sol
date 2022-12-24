/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

pragma solidity 0.8.10;


/**
 *  Token
 *
 * ERC-20 implementation, with mint & burn
 */
contract ELVb is IERC20 {
    address internal owner;
    address internal pendingOwner;
    address internal issuer;

    uint8 public decimals;
    uint256 public totalSupply;
    uint256 internal maxSupply;

    mapping (address => uint256) public override balanceOf;
    mapping (address => mapping (address => uint256)) public override allowance;

    string public name;
    string public symbol;

    event NewIssuer(address indexed issuer);
    event TransferOwnership(address indexed owner, bool indexed confirmed);

    modifier only(address role) {
        require(msg.sender == role); // dev: missing role
        _;
    }

    /**
     * Sets the token fields: name, symbol and decimals
     *
     * @param tokenName Name of the token
     * @param tokenSymbol Token Symbol
     * @param tokenDecimals Decimal places
     * @param tokenOwner Token Owner
     * @param tokenIssuer Token Issuer
     * @param tokenMaxSupply Max total supply
     */
    constructor(string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals, address tokenOwner, address tokenIssuer, uint256 tokenMaxSupply) {
        require(tokenOwner != address(0)); // dev: invalid owner
        require(tokenIssuer != address(0)); // dev: invalid issuer
        require(tokenMaxSupply > 0); // dev: invalid max supply

        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        owner = tokenOwner;
        issuer = tokenIssuer;
        maxSupply = tokenMaxSupply;
    }

    /**
     * Sets the owner
     *
     * @param newOwner Address of the new owner (must be confirmed by the new owner)
     */
    function transferOwnership(address newOwner)
    external
    only(owner) {
        pendingOwner = newOwner;

        emit TransferOwnership(pendingOwner, false);
    }

    /**
     * Confirms the new owner
     */
    function confirmOwnership()
    external
    only(pendingOwner) {
        owner = pendingOwner;
        pendingOwner = address(0);

        emit TransferOwnership(owner, true);
    }

    /**
     * Sets the issuer
     *
     * @param newIssuer Address of the issuer
     */
    function setIssuer(address newIssuer)
    external
    only(owner) {
        issuer = newIssuer;

        emit NewIssuer(issuer);
    }

    /**
     * Mints {value} tokens to the {to} wallet.
     *
     * @param to The address receiving the newly minted tokens
     * @param value The number of tokens to mint
     */
    function mint(address to, uint256 value)
    external
    only(issuer) {
        require(to != address(0)); // dev: requires non-zero address
        require(totalSupply + value <= maxSupply); // dev: exceeds max supply

        unchecked {
            totalSupply += value;
            balanceOf[to] += value;
        }

        emit Transfer(address(0), to, value);
    }

    /**
     * Approves the {spender} to transfer {value} tokens of the caller.
     *
     * @param spender The address which will spend the funds
     * @param value The value approved to be spent by the spender
     * @return A boolean that indicates if the operation was successful
     */
    function approve(address spender, uint256 value)
    external
    override
    returns(bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    /**
     * Transfers {value} tokens from the caller, to {to}
     *
     * @param to The address to transfer tokens to
     * @param value The number of tokens to be transferred
     * @return A boolean that indicates if the operation was successful
     */
    function transfer(address to, uint256 value)
    external
    override
    returns (bool) {
        updateBalance(msg.sender, to, value);

        return true;
    }

    /**
     * Transfers {value} tokens of {from} to {to}, on behalf of the caller.
     *
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param value The number of tokens to be transferred
     * @return A boolean that indicates if the operation was successful
     */
    function transferFrom(address from, address to, uint256 value)
    external
    override
    returns (bool) {
        require(allowance[from][msg.sender] >= value); // dev: exceeds allowance
        updateBalance(from, to, value);
        unchecked {
            allowance[from][msg.sender] -= value;
        }

        return true;
    }

    function updateBalance(address from, address to, uint256 value)
    internal {
        require(to != address(0)); // dev: requires non-zero address
        require(balanceOf[from] >= value); // dev: exceeds balance
        unchecked {
            balanceOf[from] -= value;
            balanceOf[to] += value;
        }

        emit Transfer(from, to, value);
    }
}