/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is 0x address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Functional {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    bool private _reentryKey = false;
    modifier reentryLock {
        require(!_reentryKey, "attempt reenter locked function");
        _reentryKey = true;
        _;
        _reentryKey = false;
    }
}

contract ERC721 {
    function balanceOf(address owner) external view returns (uint256 balance){}
}

contract HERO is Functional, Ownable, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

	uint256 public constant DAY = 86400;
	uint256 public constant WEEK = 7 * DAY;
	uint256 public constant MONTH = 30 * DAY;
	
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    
    mapping(address => uint256) _userTimestamps;
    mapping(address => uint256) public coinsPerMonth;
    
    uint256 public maxClaimTime;
    uint256 public maxSupply;
	address[] public nftContracts;
    
    

    constructor() {
        _name = "HERO";
        _symbol = "HERO";
        
        maxClaimTime = 30 * DAY;
        maxSupply = 277700000 * (10 ** 18); //temporary for now, we'll see
        
        nftContracts.push(0x0D16d8F2d2f5D0EFdaBaAD98656c50c5A2A27F79); //MAINNET CONTRACT for Bushido Royale
        coinsPerMonth[0x0D16d8F2d2f5D0EFdaBaAD98656c50c5A2A27F79] = 60 * (10 ** 18);

    }
    
    ////////////////// PUBLIC FUNCTIONS //////////////////////

    function calculateRewards(address user) public view returns(uint256) {
        uint256 rewardscalc;
        
        //fetch usertime since signup or last pull in seconds
        uint usertime = (block.timestamp - _userTimestamps[user]);
		if (usertime > maxClaimTime){
			// Set a hard upper limit, if not claimed regularly potential claims
			//	will be lost.
			usertime = maxClaimTime;
		}
        //go through the list
        for (uint256 i=0; i<nftContracts.length; i++){
            ERC721 tempContract = ERC721(nftContracts[i]);

            // calculation=     number of NFTs   *   coinratio(wei)perday   *   time(seconds) / DAY(to normalize the ratio, division done LAST)
            rewardscalc += (tempContract.balanceOf(user) * coinsPerMonth[nftContracts[i]] * usertime) / MONTH ;
        }
        return rewardscalc;
    }
    
    function claimRewards() external reentryLock {
    	uint256 rewards = calculateRewards(_msgSender());
        //update the timestamp for this wallet
        _userTimestamps[_msgSender()] = block.timestamp;

        //mint their tokens to them
        require(rewards + _totalSupply <= maxSupply, "Not enough reserves");
        _mint(_msgSender(), rewards);
    }
    
    ///////////////// ADMIN FUNCTIONS ////////////////////////
    
    function addOrChangeContract(address contractAddress, uint256 wholecoinsPerMonth) external onlyOwner {
        bool flag = false;

        for (uint256 i=0; i<nftContracts.length; i++){
            if (nftContracts[i] == contractAddress){
                coinsPerMonth[contractAddress] = wholecoinsPerMonth * (10 ** 18);
                flag = true;
                break;
            }
        }

        //if loop didn't find the contract
        if ( !flag ){
            nftContracts.push(contractAddress);
            coinsPerMonth[contractAddress] = wholecoinsPerMonth * (10 ** 18);
        }
    }

    function mintTo(address reciever, uint256 WholeCoinAmount) external onlyOwner {
    	require(_totalSupply + (WholeCoinAmount * (10**18)) < maxSupply);
    	_mint(reciever, WholeCoinAmount * (10**18));
    }
    
    function airDrop(address[] memory recievers, uint256[] memory WholeCoinAmounts) external onlyOwner {
    	require(recievers.length == WholeCoinAmounts.length, "invalid inputs");
    	
    	for (uint256 i=0; i<recievers.length; i++){
    		if (_totalSupply + (WholeCoinAmounts[i] * (10**18)) < maxSupply){
	    		_mint(recievers[i], WholeCoinAmounts[i] * (10**18));
    		}
    	}
    }
    
    function setMaxClaimTime(uint256 numDays) external onlyOwner {
    	maxClaimTime = numDays * DAY;
    }

    function purgeContractFromList(address badContract) external onlyOwner returns (bool) {
        uint256 arrayLen = nftContracts.length;

    	for (uint256 i=0; i<arrayLen; i++){
	    	if (nftContracts[i] == badContract){
                // if i = arrayLen-1 this will effectively do nothing
                nftContracts[i] = nftContracts[arrayLen - 1];
                nftContracts.pop();
                coinsPerMonth[badContract] = 0;
                return true;
            }
    	}

        return false;
    }

    ///////////////// STATUS and EMERGENGY FUNCTIONS //////////////////////
    function returnAllContracts() external view returns (address[] memory) {
        //useful for debugging a contract that is causing problems.
        return nftContracts;
    }
    
    ///////////////// ERC20 BASE FUNCTIONS //////////////////

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
        maxSupply -= amount;
    }

    function burnAndRecycle(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: insufficient balance");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from 0x0");
        require(recipient != address(0), "ERC20: transfer to 0x0");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: insufficient balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to 0x0");

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

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from 0x0");
        require(spender != address(0), "ERC20: approve to 0x0");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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

    receive() external payable {}
    
    fallback() external payable {}
}