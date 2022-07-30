/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// SPDX-License-Identifier: MIT

// Creator: https://github.com/poorjude/custom-erc20-token
// Submitted for verification at Etherscan.io on 2022-07-29

pragma solidity ^0.8.0;



/**
 * @title Interface of the ERC20 standard.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}



/**
 * @title Custom version of 'Ownable'.
 * @dev This contract expands a standard template contract 'Ownable' with possibility
 * to have more than 1 owner. You should not use this contract if you want to have one owner
 * only: this will lead to gas overspending. It would be better to use standart 'Ownable' instead.
 *
 * It may seem unlogic that we use mapping and array both instead of array only, but mapping can 
 * save a lot of gas when checking caller is one of the owners or not (we do not need to loop whole
 * array every time).
 */
contract MyOwnable {
    mapping (address => bool) isOwner;
    address[] owners;

    /**
    * @dev Sets contract deployer and addresses from `additionalOwners_` array as owners.
    * @param additionalOwners_ is an array of addresses that will be set as owners besides the contract deployer.
    */
    constructor(address[] memory additionalOwners_) {
        owners.push(msg.sender);
        isOwner[msg.sender] = true;

        uint256 ownersLength = additionalOwners_.length;
        for(uint256 i; i < ownersLength; ) {
            owners.push(additionalOwners_[i]);
            isOwner[additionalOwners_[i]] = true;
            unchecked { ++i; }
        }
    }

    /**
    * @dev Throws an error if caller of the function is not one of the owners.
    */
    modifier onlyOwner() virtual {
        require(isOwner[msg.sender], "MyOwnable: You are not one of the owners!");
        _;
    }

    /**
    * @notice Returns an array of addresses of owners.
    */
    function getOwners() external view virtual returns(address[] memory) {
        return owners;
    }

    /**
    * @notice Makes another person an owner.
    * Requirements: caller must be an owner and `newOwner` must not be an owner.
    *
    * @param newOwner is an address of a new owner.
    */
    function addOwner(address newOwner) external virtual onlyOwner {
        require(!isOwner[newOwner], "MyOwnable: This address is already an owner!");
        owners.push(newOwner);
        isOwner[newOwner] = true;
    }
}



/**
 * @title ERC20 token with custom mint functions (and not only).
 * @dev This contract implements all functions of IERC20 and has mint functions that are not set by 
 * the standard.
 *
 * Mint logic: it is possible to mint strictly declared amount of tokens in strictly declared period
 * of time till current supply does not reach maximum supply (all these are set at contract creation).
 * Also, there is a possibility to stop mint at all: no one will be able to create tokens anymore
 * after calling special function.
 *
 * There is NO implementation of first (creation-time) mint and NO implementation of mint control
 * (basically, anyone can call a mint function). All this should be implemented in a different contract
 * that inherits this one.
 */
contract MyERC20Mint is IERC20 {
    /**
    * @dev See {IERC20-balanceOf}.
    */
    mapping(address => uint256) public override balanceOf;

    /**
    * @dev See {IERC20-allowance}.
    */
    mapping(address => mapping(address => uint256)) public override allowance;

    /**
    * @dev See {IERC20-totalSupply}.
    */
    uint256 public override totalSupply;
    uint256 public maxSupply;

    bool public allowMint = true;
    uint128 public amountToMint;
    uint64 public lastTimeMinted;
    uint64 public intervalOfMint;

    /**
    * @dev Specifies custom mint settings.
    * As there is no realisation of first (creation-time) mint, `lastTimeMinted` is not set.
    *
    * @param maxSupply_ sets maximum supply of your tokens that cannot be exceeded by minting.
    * @param amountToMint_ sets how many tokens should be minted at a time.
    * @param intervalOfMint_ sets (in seconds!) how often it is possible to mint.
    */
    constructor(
                uint256 maxSupply_,
                uint128 amountToMint_,
                uint64 intervalOfMint_
                ) {
        maxSupply = maxSupply_;
        amountToMint = amountToMint_;
        intervalOfMint = intervalOfMint_;
    }

    /**
    * @dev Throws an error if mint is not allowed anymore or if time has not passed to mint again.
    */
    modifier mintLimitation() virtual {
        require(allowMint, "MyMint: Mint is not allowed anymore!");
        require(uint64(block.timestamp) >= lastTimeMinted + intervalOfMint, "MyMint: It is too early to mint yet!");
        _;
    }

    /**
    * @dev See {IERC20-transfer}.
    */
    function transfer(address to, uint256 amount) external override virtual returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
    * @dev See {IERC20-approve}.
    */
    function approve(address spender, uint256 amount) external override virtual returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
    * @dev See {IERC20-transferFrom}.
    */
    function transferFrom(address from, address to, uint256 amount) external override virtual returns (bool) {
        uint256 allowanceAmount = allowance[from][msg.sender];
        require(allowanceAmount >= amount, "MyERC20: Not enough approved tokens for `transferFrom`!");
        if (allowanceAmount != type(uint256).max) {
            // It is already checked that 'allowance[from][msg.sender]' >= 'amount'
            // so overflow is not possible.
            unchecked { allowance[from][msg.sender] -= amount; }
        }
        _transfer(from, to, amount);
        return true;
    }

    /**
    * @notice Mints preset amount of tokens.
    * @param to sets what address should get minted tokens.
    *
    * @dev If not overridden, anyone could call this function.
    */
    function mint(address to) external virtual mintLimitation {
        _mint(to);
        lastTimeMinted = uint64(block.timestamp);
    }

    /**
    * @notice Prohibit possibility to mint at all for anyone.
    *
    * @dev If not overridden, anyone could call this function.
    */
    function prohibitMint() external virtual {
        allowMint = false;
    }

    /**
    * @dev Mints tokens to address `to`.
    * Checks that minting does not make current supply exceed maximum supply. Pay attention: 
    * this function does not update 'lastTimeMinted'! This is done in external 'mint' function.
    */
    function _mint(address to) internal virtual {
        require(totalSupply + amountToMint <= maxSupply, "MyMint: You reached maximum supply!");
        // 'require' has already checked that 'totalSupply + amountToMint' does not overflow
        // and 'balanceOf[to]' could be maximum 'totalSupply' so it does not overflow too.
        unchecked {
            balanceOf[to] += amountToMint;
            totalSupply += amountToMint;
        }
        emit Transfer(address(0), to, amountToMint);
    }

    /**
    * @dev Transfer tokens from one address to another.
    * Checks whether `from` balance is sufficient or not.
    */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(balanceOf[from] >= amount, "MyERC20: Not enough tokens for `transfer`!");
        unchecked {
            // It is already checked that 'balanceOf[from]' >= 'amount'
            // and 'balanceOf[To] += amount' could be maximum 'totalSupply' 
            // so overflow is not possible.
            balanceOf[from] -= amount;
            balanceOf[to] += amount; 
        }
        emit Transfer(from, to, amount);
    }
}



/**
 * @title Custom ERC20 token.
 * @dev This contract connects 'MyERC20Mint' logic with 'MyOwnable' logic.
 * 
 * In this token mint function can be called by one of the owners only as well as mint prohibiting
 * function. Also, all owners get initial tokens: as many as it is posiible to get at "usual" mint.
 * 
 * Name of token and symbol of token are set during construction of contract.
 */
contract MyERC20MintOwnable is MyERC20Mint, MyOwnable {
    string public tokenName;
    string public tokenSymbol;

    /**
    * @dev Sets name and symbol of token, gives initial amount of tokens to owners.
    * 
    * @param name_ sets name of token.
    * @param symbol_ sets symbol of token.
    * @dev For other parameters see {MyERC20Mint-constructor} and {MyOwnable-constructor}.
    */
    constructor(
                string memory name_,
                string memory symbol_,
                uint256 maxSupply_,
                uint128 amountToMint_,
                uint64 intervalOfMint_,
                address[] memory additionalOwners_
                ) MyERC20Mint(maxSupply_, amountToMint_, intervalOfMint_)
                MyOwnable(additionalOwners_) {
        tokenName = name_;
        tokenSymbol = symbol_;
        
        // Minting tokens to all owners.
        uint256 ownersLength = owners.length;
        for (uint256 i; i < ownersLength; ) {
            _mint(owners[i]);
            unchecked { ++i; }
        }
        // 'lastTimeMinted' is set here.
        lastTimeMinted = uint64(block.timestamp);
    }

    /**
    * @dev Override {MyERC20Mint-mint} with `onlyOwner` modifier.
    */
    function mint(address to) external override mintLimitation onlyOwner {
        _mint(to);
        lastTimeMinted = uint64(block.timestamp);
    }

    /**
    * @dev Override {MyERC20Mint-prohibitMint} with `onlyOwner` modifier.
    */
    function prohibitMint() external override onlyOwner {
        allowMint = false;
    }
}