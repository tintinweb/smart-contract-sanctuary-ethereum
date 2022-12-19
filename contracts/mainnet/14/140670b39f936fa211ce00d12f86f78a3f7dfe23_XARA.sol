/**
 *Submitted for verification at Etherscan.io on 2022-12-19
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

abstract contract Proxy is Ownable {
    mapping(address => bool) private _isProxy;

    constructor() {
        _isProxy[_msgSender()] = true;
    }

    function assignProxy(address newProxy) external onlyOwner {
        _isProxy[newProxy] = true;
    }

    function revokeProxy(address badProxy) external onlyOwner {
        _isProxy[badProxy] = false;
    }

    function isProxy(address checkProxy) external view returns (bool) {
        return _isProxy[checkProxy];
    }

    modifier proxyAccess {
        require(_isProxy[_msgSender()]);
        _;
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
	function ownerOf(uint256 tokenId) external view returns (address owner){}
	function proxyTransfer(address from, address to, uint256 tokenId) external{}
}

contract XARA is Functional, Proxy, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

	uint256 public constant DAY = 86400;
	uint256 public constant MONTH = 30 * DAY;
	
    uint256 private _totalSupply;
    uint256 public maxSupply = 250000000 * (10**18);
    
    uint256 public X_RewardsPerMonth;
    uint256 public L_RewardsPerMonth;
    uint256 public C_RewardsPerMonth;
    uint256 public B_RewardsPerMonth;
    uint256 public Z_RewardsPerMonth;
    
    uint256 public currentIndex; //Keep track of historical staked tokens
    mapping (address => uint256[]) stakerBag;     //list of indexes this user has staked
    mapping (uint256 => address) stakedContract;  //Which contract for this index
    mapping (uint256 => uint256) stakedTokenId;   //TokenId of the staked NFT
    mapping (uint256 => uint256) stakedTimestamp; //timestamp of most recent claim
    mapping (uint256 => uint256) stakedOGtime;
    

    string private _name;
    string private _symbol;
    
    ERC721 XAR;
    ERC721 LAND;
    ERC721 CITY;
    ERC721 VR;

    constructor() {
        _name = "XARA COIN";
        _symbol = "XARA";
        
        X_RewardsPerMonth = 92 * (10 ** 18);
        C_RewardsPerMonth = 80 * (10 ** 18);
        L_RewardsPerMonth = 60 * (10 ** 18);
        Z_RewardsPerMonth = 40 * (10 ** 18);
        B_RewardsPerMonth = 45 * (10 ** 18);
        
    }
    
    ////////////////// STAKING FUNCTIONS ////////////////////
    
    function stakeXARA(uint256 tokenId) public reentryLock {
    	require( XAR.ownerOf(tokenId) == _msgSender(), "Invalid Owner");
    	_stakeNFT(address(XAR), tokenId);
    }
    
    function stakeCity(uint256 tokenId) public reentryLock {
    	require( CITY.ownerOf(tokenId) == _msgSender(), "Invalid Owner");
    	_stakeNFT(address(CITY), tokenId);
    }
    
    function stakeLand(uint256 tokenId) public reentryLock {
    	require( LAND.ownerOf(tokenId) == _msgSender(), "Invalid Owner");
    	_stakeNFT(address(LAND), tokenId);
    }
    
    function stakeVR(uint256 tokenId) public reentryLock {
    	require( VR.ownerOf(tokenId) == _msgSender(), "Invalid Owner");
    	_stakeNFT(address(VR), tokenId);
    }
    
    // MultiStake functions
    
    function multiStakeXARA(uint256[] memory tokenIds) public reentryLock {
    	for (uint256 i; i < tokenIds.length; i++){
	    	require( XAR.ownerOf(tokenIds[i]) == _msgSender(), "Invalid Owner");
    		_stakeNFT(address(XAR), tokenIds[i]);
    	}
    }
    
    function multiStakeCity(uint256[] memory tokenIds) public reentryLock {
    	for (uint256 i; i < tokenIds.length; i++){
    		require( CITY.ownerOf(tokenIds[i]) == _msgSender(), "Invalid Owner");
    		_stakeNFT(address(CITY), tokenIds[i]);
    	}
    }
    
    function multiStakeLand(uint256[] memory tokenIds) public reentryLock {
    	for (uint256 i; i < tokenIds.length; i++){
    		require( LAND.ownerOf(tokenIds[i]) == _msgSender(), "Invalid Owner");
    		_stakeNFT(address(LAND), tokenIds[i]);
    	}
    }
    
    function multiStakeVR(uint256[] memory tokenIds) public reentryLock {
    	for (uint256 i; i < tokenIds.length; i++){
    		require( VR.ownerOf(tokenIds[i]) == _msgSender(), "Invalid Owner");
    		_stakeNFT(address(VR), tokenIds[i]);
    	}
    }
    
    function multiStakeAll(address[] memory contractAddys, uint256[] memory tokenIds) public reentryLock {
    	require( contractAddys.length == tokenIds.length, "invalid inputs");
    	for (uint256 i=0; i<tokenIds.length; i++){
    		// define the smart contract for this token
    		ERC721 stakeContract = ERC721(contractAddys[i]);
    		
    		// check to make sure that the contract address is stakable.
    		require( ((stakeContract == XAR) || (stakeContract == CITY) || (stakeContract == LAND) || (stakeContract == VR)), "invalid contract found");
    		
    		// verify ownership of the token
    		require( stakeContract.ownerOf(tokenIds[i]) == _msgSender(), "invalid owner");
    		
    		// stake the token
    		_stakeNFT( contractAddys[i], tokenIds[i]);
    	}
    }
    
    function _stakeNFT(address contractAddress, uint256 tokenId) private {
        stakerBag[_msgSender()].push(currentIndex);
        stakedContract[currentIndex] = contractAddress;
        stakedTokenId[currentIndex] = tokenId;
        stakedTimestamp[currentIndex] = block.timestamp;
        stakedOGtime[currentIndex] = block.timestamp;
        
        currentIndex++;
        
        ERC721(contractAddress).proxyTransfer(_msgSender(), address(this), tokenId);
    }

    function unstakeNFT(uint256 index) public reentryLock {
        uint256 arraylen = stakerBag[_msgSender()].length;
        for (uint256 i = 0; i < arraylen; i++){
            if (index == stakerBag[_msgSender()][i]){
                ERC721(stakedContract[index]).proxyTransfer(address(this), _msgSender(), stakedTokenId[index]);
                if (i == (arraylen - 1)){
                    stakerBag[_msgSender()].pop();
                } else {
                    stakerBag[_msgSender()][i] = stakerBag[_msgSender()][arraylen - 1];
                    stakerBag[_msgSender()].pop();
                }
                break;
            }
        }
    }
    
    function unstakeAll() public reentryLock {
        uint256 arraylen = stakerBag[_msgSender()].length;
        for (uint256 i = 0; i < arraylen; i++){
        	uint256 index = stakerBag[_msgSender()][i];
        	ERC721(stakedContract[index]).proxyTransfer(address(this), _msgSender(), stakedTokenId[index]);
        }
        
        //clear the staking array
        delete stakerBag[_msgSender()];
    }
    
    function claimRewards() public {
    	//check rewards
    	uint256 rewardDue = checkRewards(_msgSender());
    	
    	//reset timestamps
    	for (uint256 i=0; i<stakerBag[_msgSender()].length; i++){
    		stakedTimestamp[stakerBag[_msgSender()][i]] = block.timestamp;
    	}
    	
    	//mint rewards
    	if (rewardDue + _totalSupply <= maxSupply){
    		_mint(_msgSender(), rewardDue);
    	}else{
    		_mint(_msgSender(), maxSupply - _totalSupply);
    	}
    	
    }
    
    function checkRewards(address claimer) public view returns (uint256) {
    	uint256 rewardPerSec = 0;
    	uint256 index = 0;
    	uint256 citiesStaked = 0;
    	uint256 landStaked = 0;
    	uint256 totalRewards = 0;
    	uint256 bonusTimestamp = 0; //bonus applied from timestamp of the most recently staked
    	                            //city or land
    	
    	for (uint256 i=0; i<stakerBag[claimer].length; i++){
    		index = stakerBag[claimer][i];
    		if (stakedContract[currentIndex] == address(XAR)){
    			rewardPerSec = X_RewardsPerMonth / MONTH;
    		}
    		if (stakedContract[currentIndex] == address(LAND)){
    			rewardPerSec = L_RewardsPerMonth / MONTH;
    			landStaked += 1;
    			bonusTimestamp = stakedTimestamp[index];
    		}
    		if (stakedContract[currentIndex] == address(CITY)){
    			rewardPerSec = C_RewardsPerMonth / MONTH;
    			citiesStaked += 1;
    			bonusTimestamp = stakedTimestamp[index];
    		}
    		if (stakedContract[currentIndex] == address(VR)){
    			rewardPerSec = Z_RewardsPerMonth / MONTH;
    		}
    		
    		totalRewards += (block.timestamp - stakedTimestamp[index]) * rewardPerSec;
    	}
    	
    	if (bonusTimestamp != 0){
    		if ( landStaked >= citiesStaked){
    			//use citiesStaked for bonus reward
    			totalRewards += (citiesStaked * B_RewardsPerMonth / MONTH) * (block.timestamp - bonusTimestamp);
    		} else {
    			//use landStaked for bonus reward
    			totalRewards += (landStaked * B_RewardsPerMonth / MONTH) * (block.timestamp - bonusTimestamp);
    		}
    	}
    	
    	return totalRewards;
    }
    
    function mintTo(address reciever, uint256 amount) external onlyOwner {
    	require(_totalSupply + amount < maxSupply);
    	_mint(reciever, amount);
    }
    
    function setXara(address contractAddress) external onlyOwner {
    	XAR = ERC721(contractAddress);
    }
    
    function setLand(address contractAddress) external onlyOwner {
    	LAND = ERC721(contractAddress);
    }
    
    function setCity(address contractAddress) external onlyOwner {
    	CITY = ERC721(contractAddress);
    }
    
    function setVR(address contractAddress) external onlyOwner {
    	VR = ERC721(contractAddress);
    }
    
    function setRewardsPerMonthWholeCoins( uint256 xaraReward, uint256 landReward, uint256 cityReward, uint256 bonusReward, uint256 ZReward) external onlyOwner {
    	X_RewardsPerMonth = xaraReward * (10 ** 18);
    	L_RewardsPerMonth = landReward * (10 ** 18);
    	C_RewardsPerMonth = cityReward * (10 ** 18);
    	B_RewardsPerMonth = bonusReward * (10 ** 18);
    	Z_RewardsPerMonth = ZReward * (10 ** 18);
    }

    function getUserStakedContracts( address staker ) external view returns (address[] memory){
        uint256 arraylen = stakerBag[staker].length;
    	address[] memory stakeContracts = new address[](arraylen);
        for (uint256 i=0; i < arraylen; i++){
            stakeContracts[i] = stakedContract[stakerBag[staker][i]];
        }
        return stakeContracts;
    }

    function getUserStakedTokenIndex( address staker ) external view returns (uint256[] memory){
        uint256 arraylen = stakerBag[staker].length;
    	uint256[] memory stakeIndex = new uint256[](arraylen);
        for (uint256 i=0; i < arraylen; i++){
            stakeIndex[i] = stakerBag[staker][i];
        }
        return stakeIndex;
    }

    function getUserStakedTokenIds( address staker ) external view returns (uint256[] memory){
        uint256 arraylen = stakerBag[staker].length;
    	uint256[] memory stakeTokenIds = new uint256[](arraylen);
        for (uint256 i=0; i < arraylen; i++){
            stakeTokenIds[i] = stakedTokenId[stakerBag[staker][i]];
        }
        return stakeTokenIds;
    }

    function getUserStakedTimestamps( address staker ) external view returns (uint256[] memory){
        uint256 arraylen = stakerBag[staker].length;
    	uint256[] memory stakeTimestamps = new uint256[](arraylen);
        for (uint256 i=0; i < arraylen; i++){
            stakeTimestamps[i] = stakedOGtime[stakerBag[staker][i]];
        }
        return stakeTimestamps;
    }
    
    ///////////////// PROXY FUNCTIONS ///////////////////////
    
    function proxyMint(address reciever, uint256 amount) external proxyAccess {
    	require(amount + _totalSupply <= maxSupply, "max supply reached");
    	_mint(reciever, amount);
    }
    
    function proxyTransfer(address from, address to, uint256 amount) external proxyAccess {
    	_transfer(from, to , amount);
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