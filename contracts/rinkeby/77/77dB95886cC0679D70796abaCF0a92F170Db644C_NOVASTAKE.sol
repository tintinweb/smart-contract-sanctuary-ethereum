/**
 *Submitted for verification at Etherscan.io on 2022-06-26
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
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance){}
    function ownerOf(uint256 tokenId) external view returns (address owner){}
    function safeTransferFrom(address from,address to,uint256 tokenId) external{}
    function transferFrom(address from, address to, uint256 tokenId) external{}
    function approve(address to, uint256 tokenId) external{}
    function getApproved(uint256 tokenId) external view returns (address operator){}
    function setApprovalForAll(address operator, bool _approved) external{}
    function isApprovedForAll(address owner, address operator) external view returns (bool){}
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external{}
    
    //proxy access functions:
    function adminBurn(uint256 tokenId) external {}
    function adminTransfer(address from, address to, uint256 tokenId) external {}

    //extra functions:
    function ownerHoldings(address holder) external view returns ( uint256[] memory) {}
}

contract ERC20 {
    function totalSupply() external view returns (uint256){}
    function balanceOf(address account) external view returns (uint256){}
    function transfer(address recipient, uint256 amount) external returns (bool){}
    function allowance(address owner, address spender) external view returns (uint256){}
    function approve(address spender, uint256 amount) external returns (bool){}
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool){}
    
    //proxy access functions:
    function burnNova(uint256 burnAmount) public{}
    function buyNova(uint256 orderAmount) public{}
}



contract NOVASTAKE is Proxy, Functional {
    ERC721 NOVANFT;  // NFT contract for Nova Genesis Pass
    ERC20 NOVACOIN;  // $NOVA
    
    string public name;
    uint256 public treasury;
    uint256 public dailyReward;

    uint256 private DAY = 86400;
    //uint256 private DAY = 10; // for testing purposes only
    
    uint256 public cycleStart;
    uint256 public cycleEnd;
    uint256 public cycleLength;
    uint256 public holdTime;
    
    //mappings for staked coins
    mapping (uint256 => uint256) timestamp;
    mapping (uint256 => uint256) stakedOn;
    mapping (uint256 => address) stakedBy;
    mapping (address => uint256[]) stakerWallet;

    constructor() {
    	name = "NOVA Staking Contract";
        
        cycleEnd = block.timestamp;
        cycleLength = 30 * DAY;
        holdTime = 15 * DAY;
        
    	NOVANFT = ERC721(0x1e54Bc6293DcB997Dc2a1A562720045aa45b4FE7); //OG NOVA NFT Contract
    	NOVACOIN = ERC20(0xFD3C3717164831916E6D2D7cdde9904dd793eC84);
    	dailyReward = 20 * (10 ** 18);
    }

    function stakePass(uint256 tokenId) external reentryLock {
    	//requires approveForAll() approved for this contract address
    	require(NOVANFT.ownerOf(tokenId) == _msgSender(), "invalid transfer");
    	
    	timestamp[tokenId] = block.timestamp;
    	stakedOn[tokenId] = block.timestamp;
    	stakedBy[tokenId] = _msgSender();
    	stakerWallet[_msgSender()].push(tokenId);
    	
    	NOVANFT.transferFrom(_msgSender(), address(this), tokenId);
    }

    function stakeMany(uint256[] memory tokenIds) external reentryLock{
    	// requires approveForAll() approved for this contract address
    	// ALL tokenId's must be valid or this will revert!!
    	
    	for (uint256 i=0; i<tokenIds.length; i++){
    		require(NOVANFT.ownerOf(tokenIds[i]) == _msgSender(), "invalid transfer");
    		timestamp[tokenIds[i]] = block.timestamp;
    		stakedOn[tokenIds[i]] = block.timestamp;
    		stakedBy[tokenIds[i]] = _msgSender();
    		stakerWallet[_msgSender()].push(tokenIds[i]);
    	
    		NOVANFT.transferFrom(_msgSender(), address(this), tokenIds[i]);    		
    	}
    }
        
    function unstakePass(uint256 tokenId) external reentryLock {
    	require(_msgSender() == stakedBy[tokenId], "Not your NFT");
    	require(stakedOn[tokenId] + holdTime < block.timestamp, "Not Unstakable Yet");
    	
    	uint256 walletLength = stakerWallet[_msgSender()].length;
    	
    	// remove token from stakerwallet and reset data.
    	for (uint256 i; i < walletLength; i++){
    		if (stakerWallet[_msgSender()][i] == tokenId){
    			if (i < walletLength - 1){
    				stakerWallet[_msgSender()][i] = stakerWallet[_msgSender()][walletLength];
    			}
    			timestamp[tokenId] = 0;
    			stakedOn[tokenId] = 0;
    			stakedBy[tokenId] = address(0);
    			stakerWallet[_msgSender()].pop();
    			break;
    		}
    	}
    	NOVANFT.transferFrom(address(this), _msgSender(), tokenId);
    }
    
    function unstakeAll() external reentryLock {
    	//all staked tokens must meet the time requirement
    	uint256[] memory tokens = stakerWallet[_msgSender()];
    	uint256 walletLength = tokens.length;
    	
    	for (uint256 i= walletLength; i > 0; i--) {
    		require(stakedOn[tokens[i-1]] + holdTime < block.timestamp, "Not Unstakable Yet");
    		timestamp[tokens[i - 1]] = 0;
    		stakedOn[tokens[i - 1]] = 0;
    		stakedBy[tokens[i - 1]] = address(0);
			stakerWallet[_msgSender()].pop();
    		NOVANFT.transferFrom(address(this), _msgSender(), tokens[i-1]);
    	}
    }
    
    function claim() public reentryLock {
    	uint256 walletLength = stakerWallet[_msgSender()].length;
    	uint256 claimTime; // total time index measured in seconds
    	uint256 rn = block.timestamp;
    	
    	for (uint256 i; i < walletLength; i++){
    		//check time of stake
    		uint256 stakeCoin = stakerWallet[_msgSender()][i];
    		require (rn > timestamp[stakeCoin], "please wait"); //should not be an issue
    		require (rn > cycleStart, "No Coins to Claim Yet");
    		
            
    		uint256 stakeTime = timestamp[stakeCoin];
    		if (timestamp[stakeCoin] <= cycleStart){
    			stakeTime = cycleStart;
    		}

            //reset timestamp
            timestamp[stakeCoin] = rn;

    		if (rn >= cycleEnd){
    			if (stakeTime <= cycleEnd){
    				claimTime += cycleEnd - stakeTime;
    			}// else nothing, this token has been mined
    		} else { //if rn <= cycleEnd
    			claimTime += rn - stakeTime;
    		}
    	}
    	
        ///
    	NOVACOIN.transfer( _msgSender(), ((claimTime * dailyReward) / DAY) );

        treasury = NOVACOIN.balanceOf(address(this));
    }
    
    function estimateClaim(address staker) public view returns (uint256) {
    	uint256 walletLength = stakerWallet[staker].length;
    	uint256 claimTime; // total time index measured in seconds
    	uint256 rn = block.timestamp;
    	
    	for (uint256 i; i < walletLength; i++){
    		//check time of stake
    		uint256 stakeCoin = stakerWallet[staker][i];
    		require (rn > timestamp[stakeCoin], "please wait"); //should not be an issue
    		require (rn > cycleStart, "No Coins to Claim Yet");
    		
    		uint256 stakeTime = timestamp[stakeCoin];
    		if (timestamp[stakeCoin] <= cycleStart){
    			stakeTime = cycleStart;
    		}

    		if (rn >= cycleEnd){
    			if (stakeTime < cycleEnd){
    				claimTime += cycleEnd - stakeTime;
    			}// else nothing, this token has been mined
    		} else { //if rn <= cycleEnd
    			claimTime += rn - stakeTime;
    		}
    	}

        return (claimTime * dailyReward) / DAY;
    }
    
    function withdrawDAOcoins() public onlyOwner {
    	NOVACOIN.transferFrom(address(this), _msgSender(), treasury);
    	
    	treasury = NOVACOIN.balanceOf(address(this));    
    }
    
    function burnDAOcoins() public onlyOwner {
    	NOVACOIN.burnNova(treasury);
    	
    	treasury = NOVACOIN.balanceOf(address(this));
    }
    
    function getStakerWallet(address staker) external view returns (uint256[] memory) {
    	return stakerWallet[staker];
    }
    
    function depositRewardFunds(uint256 depositAmountWei) public proxyAccess {

        //Send eth to the coin contract which will return $NOVA coins to this contract
        NOVACOIN.buyNova(depositAmountWei);

        //Update the treasury based on successful completion of the transaction
        treasury = NOVACOIN.balanceOf(address(this));
    }
        
    function setNFTcontract(address newContract) public onlyOwner {
    	NOVANFT = ERC721(newContract);
    }
    
    function setCOINcontract(address newContract) public onlyOwner {
    	NOVACOIN = ERC20(newContract);
    }

    function setCoinsPerDay(uint256 newCoinsPerDay) public onlyOwner {
        //enter the amount in WEI!!!
        dailyReward = newCoinsPerDay;
    }
    
    function setCycleLengthinDays(uint256 newCycle) external onlyOwner {
    	cycleLength = newCycle * DAY;
    }
    
    function setHoldTimeinDays(uint256 newHoldTime) external onlyOwner {
    	holdTime = newHoldTime * DAY;
    }

    function startNewClaimCycle() external onlyOwner {
        cycleStart = block.timestamp;
        cycleEnd = cycleStart + cycleLength;
    }
    
    function startClaimAtTime(uint256 startTime) external onlyOwner {
        // entry must be a UNIX timestamp in Seconds!
    	cycleStart = startTime;
    	cycleEnd = cycleStart + cycleLength;
    }

    receive() external payable {}
    
    fallback() external payable {}
}