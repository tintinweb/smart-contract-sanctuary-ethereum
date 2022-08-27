// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract axToken is Context, IERC20, IERC20Metadata {

    // Defining time. Mint allowances go up weekly. 
    uint256 constant week = 1; // 604800
    uint256 constant million = 1000000; // 1000000
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    enum MintingReason { TEAM, INCENTIVES, ECOSYSTEM, EMERGENCY } // This is the mint reason
    mapping(MintingReason => uint256) public categoriesMinted;
    mapping(MintingReason => uint256) public maxCategoryMint;

    uint256 private _totalSupply;
    uint256 private immutable _maxSupply;
    uint256 private _emergencyMintAllowanceTime;
    uint256 public mintAllowanceStartTime;

    string private _name;
    string private _symbol;
    address private _owner;
    address public clearingHouse;
    uint8 private immutable _decimals;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokensBurned(address indexed burner, uint256 amount);

    constructor(address _clearingHouse) { // Can put dead address inside clearingHouse **for testing**. 
        // 364 days = 1 year here, which divides 1 year into 52 weeks equally.
        
        mintAllowanceStartTime = block.timestamp; // Make this a custom timestamp, like 1st jan, 2023 or something. 
        _emergencyMintAllowanceTime = (block.timestamp) + 2 * 52 * week;

        _name = "AltDEx Token";
        _symbol = "AX";
        _decimals = 18;
        _maxSupply = 125 * million * 10 ** _decimals; // 18 decimals, don't change it, otherwise errors. 

        clearingHouse = _clearingHouse;
        _owner = _msgSender();

        // Define the max mint of all the categories. 
        maxCategoryMint[MintingReason.TEAM] = 30 * million * 10 ** _decimals; // 30 million team tokens
        maxCategoryMint[MintingReason.ECOSYSTEM] = 20 * million * 10 ** _decimals; // 20 million ecosystem & growth tokens
        maxCategoryMint[MintingReason.INCENTIVES] = 20 * million * 10 ** _decimals; // 20 million incentives tokens
        maxCategoryMint[MintingReason.EMERGENCY] = 25 * million * 10 ** _decimals; // 25 million emergency tokens

        // Mint lp liquidity and private sale/ico coins on construction. 35 millions tokens.
        _mint(_owner, 35 * million * 10 ** _decimals);
    }
    
    modifier onlyOwner() {
        require(getOwner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address"); // Make it 0xff to kill the contract. 
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        
        if(spender == clearingHouse) { // No allowance/approval needed for the clearingHouse contract
            _transfer(from, to, amount);
            return true;
        } else {
            _spendAllowance(from, spender, amount);
            _transfer(from, to, amount);
            return true;
        }
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        require(_totalSupply + amount <= _maxSupply, "ERC20: Minting cap exceeded."); // Adds the mint restriction. Is an addition. 

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    // Have a public burn function to let anyone burn coins lol. 
    // Delegate to rajveer

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    // @dev Returns the weeks since minting was allowed, rounded down/floored. 
    
    function currentWeek() public view returns (uint256) {
        uint256 secondsSinceMintAllowance = block.timestamp - mintAllowanceStartTime;
        return secondsSinceMintAllowance / week;
    }

    function currentWeekSinceEmergencyMintAllowanceStart() internal view returns (uint256) {
        uint256 secondsSinceMintAllowance = block.timestamp - _emergencyMintAllowanceTime;
        return secondsSinceMintAllowance / week;
    }

    // @dev Returns number of coins currently allowed to mint, only includes whole coins, doesn't include decimals. 

    function currentMintAllowance(MintingReason reason) public view returns (uint256) {
        if(reason == MintingReason.TEAM) {
            require(categoriesMinted[MintingReason.TEAM] < maxCategoryMint[MintingReason.TEAM], "currentMintAllowance: Minting on this category already exceeded.");

            // Using the function y = sqrt(200x). Change the number right after "sqrt(" to change the entire equation.
            uint256 mintAllowanceTillNow = sqrt(200 * currentWeek()/52) * million * 10 ** _decimals;
            if(mintAllowanceTillNow > maxCategoryMint[MintingReason.TEAM]) mintAllowanceTillNow = maxCategoryMint[MintingReason.TEAM]; // such that mintAllowance doesn't go over limit. 
            
            return mintAllowanceTillNow - categoriesMinted[MintingReason.TEAM];
        } else if (reason == MintingReason.INCENTIVES) {
            require(categoriesMinted[MintingReason.INCENTIVES] < maxCategoryMint[MintingReason.INCENTIVES], "currentMintAllowance: Minting on this category already exceeded.");
            uint256 mintAllowanceTillNow = sqrt(80 * currentWeek()/52) * million * 10 ** _decimals;

            if(mintAllowanceTillNow > maxCategoryMint[MintingReason.INCENTIVES]) mintAllowanceTillNow = maxCategoryMint[MintingReason.INCENTIVES];
            return mintAllowanceTillNow - categoriesMinted[MintingReason.INCENTIVES];

        } else if (reason == MintingReason.ECOSYSTEM) {
            require(categoriesMinted[MintingReason.ECOSYSTEM] < maxCategoryMint[MintingReason.ECOSYSTEM], "currentMintAllowance: Minting on this category already exceeded.");
            
            // Using the function y = x^2. Creates a slightly exponential supply distribution, non-linear. Ends at 20m at exactly 4 years.
            uint256 mintAllowanceTillNow  = (currentWeek()/52) ** 2 * million * 10 ** _decimals;
            if(mintAllowanceTillNow > maxCategoryMint[MintingReason.ECOSYSTEM]) mintAllowanceTillNow = maxCategoryMint[MintingReason.ECOSYSTEM];

            return mintAllowanceTillNow - categoriesMinted[MintingReason.ECOSYSTEM];
        } else if (reason == MintingReason.EMERGENCY) {
            require(block.timestamp > _emergencyMintAllowanceTime, "currentMintAllowance: Not allowed to mint emergency tokens");
            require(categoriesMinted[MintingReason.EMERGENCY] < maxCategoryMint[MintingReason.EMERGENCY], "currentMintAllowance: Minting on this category already exceeded.");

            // Using the function y = x (to mint 25 mil coins in 2.5 years)
            uint256 mintAllowanceTillNow = (currentWeekSinceEmergencyMintAllowanceStart()/52) * million * 10 ** _decimals;
            if(mintAllowanceTillNow > maxCategoryMint[MintingReason.EMERGENCY]) mintAllowanceTillNow = maxCategoryMint[MintingReason.ECOSYSTEM];

            return mintAllowanceTillNow - categoriesMinted[MintingReason.EMERGENCY];
        } else {
            return 0; // for anything else returning 0
        }
    }

    function mint(MintingReason reason, uint256 wholeCoinsAmount) public onlyOwner {
        // And then allowing the mint according to the y = f(x) function.
        // Use _mint() function to actually mint the tokens after checking through all the conditions. 
        require(wholeCoinsAmount != 0);
        uint256 amount = wholeCoinsAmount * 10 ** _decimals;

        require(amount <= currentMintAllowance(reason), "mint: You can't mint more than you're allowed to.");
        _mint(_msgSender(), amount);
        categoriesMinted[reason] += amount;

        // Not emitting an event because then everyone one instantly know lol. 
    }

    function emergencyMintAllowanceTime() public view returns (uint256) {
        return _emergencyMintAllowanceTime;
    }

    function changeClearingHouseContract(address newContract) public onlyOwner {
        clearingHouse = newContract;
    }
}