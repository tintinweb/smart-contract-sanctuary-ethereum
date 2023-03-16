/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract ERC20 {
    function proxyMint(address reciever, uint256 amount) external {}
    function proxyTransfer(address from, address to, uint256 amount) external {}
    function balanceOf(address account) public view returns (uint256) {}

    function getUserStakedContracts( address staker ) external view returns (address[] memory){}
    function getUserStakedTokenIndex( address staker ) external view returns (uint256[] memory){}
    function getUserStakedTokenIds( address staker ) external view returns (uint256[] memory){}
    function getUserStakedTimestamps( address staker ) external view returns (uint256[] memory){}

    function maxSupply() public view returns (uint256){}
    function totalSupply() public view returns (uint256){}
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

contract XARAclaim is Functional, Proxy {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

	uint256 public constant DAY = 86400;
	uint256 public constant MONTH = 30 * DAY;
    
    uint256 public X_RewardsPerMonth;
    uint256 public L_RewardsPerMonth;
    uint256 public C_RewardsPerMonth;
    uint256 public B_RewardsPerMonth;
    uint256 public Z_RewardsPerMonth;
    
    uint256 public currentIndex; //Keep track of historical staked tokens
    
    // We're going to need to track timestamps locally
    mapping (uint256 => uint256) stakedTimestamp; //timestamp of most recent claim
    
    /*
    ERC721 XAR;
    ERC721 LAND;
    ERC721 CITY;
    ERC721 VR;
    ERC20 XARA;
    */
    address XAR;
    address LAND;
    address CITY;
    address VR;
    ERC20 XARA;

    constructor() {
        
        X_RewardsPerMonth = 92 * (10 ** 18);
        C_RewardsPerMonth = 80 * (10 ** 18);
        L_RewardsPerMonth = 60 * (10 ** 18);
        Z_RewardsPerMonth = 40 * (10 ** 18);
        B_RewardsPerMonth = 45 * (10 ** 18);
        
        XAR = address(0xe207578AB49f553534c025ee348Ac33e81cc6018);
    	LAND = address(0xb820fa56a477E120b3f55ae049eE3Ee8E2f55250);
    	CITY = address(0x17AD54d4D457bc3D57ABDD94DdfE52d792a227aA);
    	
    	XARA = ERC20(0xb0Aa5839444d97Ab497bDC056CE2f602699DE815);
    }
    

    
    // Claim Functions
    function updateClaimTimestamps( address [] memory userlist ) external onlyOwner {
        for (uint256 i=0; i<userlist.length; i++){
            uint256 [] memory sTimestamp = XARA.getUserStakedTimestamps( userlist[i] );

            for (uint256 index=0; index<sTimestamp.length; index++){
                if (stakedTimestamp[index] < sTimestamp[index]) {
                    // Bugfix to catch up the timestamp functionality of this contract with what was on the OG contract
                    stakedTimestamp[index] = sTimestamp[index];
                }
            }
        }
    }
    
    function claimRewards() public {
    	//check rewards
    	uint256 rewardDue = checkRewards(_msgSender());

        uint256 maxSupply = XARA.maxSupply();
        uint256 totalSupply = XARA.totalSupply();

    	//address [] memory sContract = XARA.getUserStakedContracts( claimer );
    	uint256 [] memory sIndex = XARA.getUserStakedTokenIndex( _msgSender() );
    	//address [] memory sTokenId = XARA.getUserStakedTokenIds( claimer );
    	//address [] memory sTimestamp = XARA.getUserStakedTimestamps( claimer );

    	//reset timestamps
    	for (uint256 i=0; i < sIndex.length; i++){
    		stakedTimestamp[sIndex[i]] = block.timestamp;
    	}
    	
    	//mint rewards
    	if (rewardDue + totalSupply <= maxSupply){
    		XARA.proxyMint(_msgSender(), rewardDue);
    	}else{
    		XARA.proxyMint(_msgSender(), maxSupply - totalSupply);
    	}
    	
    }
    
    function checkRewards(address claimer) public view returns (uint256) {
    	//fetch data from the staking contract
    	address [] memory sContract = XARA.getUserStakedContracts( claimer );
    	uint256 [] memory sIndex = XARA.getUserStakedTokenIndex( claimer );
    	//address [] memory sTokenId = XARA.getUserStakedTokenIds( claimer );
    	uint256 [] memory sTimestamp = XARA.getUserStakedTimestamps( claimer );
    
    	uint256 rewardPerSec = 0;
    	uint256 index = 0;
    	uint256 citiesStaked = 0;
    	uint256 landStaked = 0;
    	uint256 totalRewards = 0;
    	uint256 bonusTimestamp = 0; //bonus applied from timestamp of the most recently staked
    	                            //city or land
    	
    	for (uint256 i=0; i<sIndex.length; i++){
    		index = sIndex[i];

    		if (sContract[index] == XAR){
    			rewardPerSec = X_RewardsPerMonth / MONTH;
    		}
    		if (sContract[index] == LAND){
    			rewardPerSec = L_RewardsPerMonth / MONTH;
    			landStaked += 1;
    			bonusTimestamp = stakedTimestamp[index];
    		}
    		if (sContract[index] == CITY){
    			rewardPerSec = C_RewardsPerMonth / MONTH;
    			citiesStaked += 1;
    			bonusTimestamp = stakedTimestamp[index];
    		}
    		if (sContract[index] == VR){
    			rewardPerSec = Z_RewardsPerMonth / MONTH;
    		}
    		
    		totalRewards += (block.timestamp - sTimestamp[index]) * rewardPerSec;
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
    
    /*
    function mintTo(address reciever, uint256 amount) external onlyOwner {
    	require(_totalSupply + amount < maxSupply);/////TODO
    	XARA.proxyMint(reciever, amount);
    }
    */
    
    function setXara(address contractAddress) external onlyOwner {
    	XAR = contractAddress;
    }
    
    function setLand(address contractAddress) external onlyOwner {
    	LAND = contractAddress;
    }
    
    function setCity(address contractAddress) external onlyOwner {
    	CITY = contractAddress;
    }
    
    function setVR(address contractAddress) external onlyOwner {
    	VR = contractAddress;
    }
    
    function setRewardsPerMonthWholeCoins( uint256 xaraReward, uint256 landReward, uint256 cityReward, uint256 bonusReward, uint256 ZReward) external onlyOwner {
    	X_RewardsPerMonth = xaraReward * (10 ** 18);
    	L_RewardsPerMonth = landReward * (10 ** 18);
    	C_RewardsPerMonth = cityReward * (10 ** 18);
    	B_RewardsPerMonth = bonusReward * (10 ** 18);
    	Z_RewardsPerMonth = ZReward * (10 ** 18);
    }
    
    ///////////////// PROXY FUNCTIONS ///////////////////////TODO
    /*
    function proxyMint(address reciever, uint256 amount) external proxyAccess {
    	require(amount + _totalSupply <= maxSupply, "max supply reached");
    	_mint(reciever, amount);
    }
    
    function proxyTransfer(address from, address to, uint256 amount) external proxyAccess {
    	_transfer(from, to , amount);
    }
    //TODO */

    receive() external payable {}
    
    fallback() external payable {}
}