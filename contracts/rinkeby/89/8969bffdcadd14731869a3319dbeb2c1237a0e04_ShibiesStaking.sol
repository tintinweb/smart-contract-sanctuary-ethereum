/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.8.0;

/**
 * @title IERC20
 */
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

/**
 * @title ERC165
 */
interface ERC165 {

    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is ERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

/**
 * @title ISVTREATS
 */
interface ISVTREATS is IERC721 {

    //function exist(uint _nftId) external view returns (bool);

    function addShare(uint256 _nftId, uint256 _share) external returns (bool);

    function balanceOfStake(uint256 _nftId, address _token) external returns (uint256);
    
	function getOpenRewardsOf(uint256 _nftId) external view returns (address[] memory, uint256[] memory);

    function getLastUpdateOf(uint256 _nftId) external view returns (uint256, uint256, uint256, uint256, uint16[] memory);
	
	function stakedBalancesOf(uint256 _nftId) external view returns (address[] memory, uint256[] memory);

    function getSharesOf(uint256 _nftId) external returns (uint256, uint256, uint256);
	
	function withdrawRewards(uint256 _nftId) external returns (address[] memory, uint256[] memory);
	
    function stakeToken(uint256 _nftId, address _token, uint256 _amount, uint256 _shares) external returns (bool);

    function unstakeToken(uint256 _nftId, address _token, uint256 _amount, uint256 _shares) external returns (bool);

    function unstakeAll(uint256 _nftId) external returns (address[] memory, uint256[] memory);
    
    function addActivReward(uint256 _nftId, uint256 _add) external returns (bool);

    function removeActivReward(uint256 _nftId, uint256 _remove) external returns (bool);
    
	function updatePosition(uint256 _nftId, address[] memory _tokens, uint256[] memory _amounts, uint256 _lastReward, uint256 _lastUpdate) external returns (bool);
	
	function stakePowerOf(uint256 _nftId) external view returns (uint256);
	
	//function votePowerOf(uint256 _nftId) external view returns (uint256);

    function lockOf(uint256 _nftId) external view returns (uint256);

    function mint(bytes calldata _data) external returns (uint256);

    //function mint(address _recipient, address _token, uint256 _lastReward, uint256 _lastUpdate, uint32[] memory _activeRewards) external returns (uint256);
}

/**
 * @title Voter
 */
interface Voter {
	
	function voteLockOf(uint256 _nftId) external view returns (uint256);
}

/**
 * @title ILottery
 */
interface ILottery {
	
    function addToken(address _nft, uint256 _ticket) external returns (bool);
    //function joinLottery(uint256 _nftId, uint256 _amount) external returns (bool);
    function setLottery(uint256 _nftId) external returns (bool);
    function joinLotteryNFT(address _nft, uint256 _nftId) external returns (bool);
    function leaveLotteryNFT(address _nft, uint256 _nftId) external returns (bool);
}

/**
 * @title SafeERC20
 */
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract ShibiesStaking is Context {
    /* ========== DEPENDENCIES ========== */

    //using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== EVENTS ========== */

    event LogAddReward(address token, uint256 amount);
    event LogAddStake(address token);
    event Stake(address _nft, uint256 _nftId, address token, uint256 amount);
    event Unstake(address _nft, uint256 _nftId, address token, uint256 amount);

    /* ========== DATA STRUCTURES ========== */

    struct Custom {
        uint256 shares;
		uint256 lastWithdraw; // start timestamp
		uint256 lastReward; // end timestamp
		uint256 lastUpdate; // total anual reward per TREATS of token
        uint16[] active; // amount
    }
    
    struct Reward {
		uint256 start; // start timestamp
		uint256 end; // end timestamp
		uint256 rewardPerShare; // total anual reward per TREATS of token
        uint256 amount; // amount
        address token;
    }
	
	//struct StakeToken {
        //address token; // in seconds
	//	uint256 treatsBase; // treats stake value per token/nft
    //}

    //struct MintParams {
    //    address recipient;
    //    address token;
    //    uint32 lastReward;
    //    uint32 lastUpdate;
    //    uint16[] activeRewards;
    //}

    struct Update {
        address token; // in seconds
		uint256 oldValue; // treats stake value per token/nft
		uint256 newValue; // total reward per secound of token
        uint256 timestamp; // with vote power
        int256 changedShares;
    }

    /* ========== STATE VARIABLES ========== */

    bytes32 private immutable _DOMAIN_SEPARATOR;

    address private immutable _treats;
	address private immutable _wtreats;

    address private _svtreats;
    address private _vault;
	address private _lottery;
	
    uint256 private _lpBonus;
	uint256 private _lastUpdate;
    uint256 private lastRewardUpdate;
    uint256 private lastStakeUpdate;
    uint256 private lastRewardTime;
    uint256 private lastTokenUpdate;
	//uint256 private lockPeriod = 1;
	uint256 private _totalShares;
    uint256 private _totalSharesCustom;

    uint16[] private activeRewards;
	
    address[] private liquidityTokens;
	address[] private stakeTokens;
    address[] private voteTokens;

    address[] private operators;
	
    string private runningVote;
	string private notAdded;
	string private added;
	string private noBalance;
    string private notApproved;
	string private notOwner;
    string private noChange;
    string private isLocked;
    string private highBonus;
    string private highNumber;
    string private higherThan;
    string private notLength;

    string[] private _voteTitels;

    Reward[] private _rewards;
    Update[] private _updates;

    mapping(bytes4 => bool) private _isVote;
    mapping(address => uint256) private _shareOfRewards;
    mapping(address => uint256) private _totalSharesOf;
    mapping(address => uint256) private _treatsBases;
	mapping(address => mapping(uint256 => Custom)) private _customs;
	//mapping(uint256 => mapping(address => uint256)) private _sharesTokenOf;
	//mapping(address => uint256) private _totalStakedTokens;
	mapping(address => uint256) private _lastUpdateOfToken;
    mapping(address => bool) private isOperator;
    mapping(address => bool) private isReflection;
    mapping(address => bool) private isReward;
	mapping(address => bool) private isStake;
    mapping(address =>  mapping(uint256 => bool)) private _isStaked;
	mapping(address => bool) private isNFT;
	mapping(address => bool) private isCommunityNFT;
	//mapping(address => StakeToken) private stakeInfo;

/* ========== MODIFIER ========== */


    modifier onlyOperator() {
        require(isOperator[msg.sender], "Only operator!");
        _;
    }

    modifier onlyVault() {
        require(msg.sender == _vault, "Only vault!");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor() {
        address TREATS;
	    uint32 chainId;

        assembly {chainId := chainid()}

        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("1")),
                chainId,
                address(this)));

		if(chainId == 1 || chainId == 4 || chainId == 137){
		   TREATS = chainId == 1 ? 0x0B5Afdc93A86062A49063EA96AE944D7F966B6AE : chainId == 4 ? 0x9DC4fD40f0D8329B81aE535446F2a17ba8280b90 : 0x21364671fD823BBda8Ba1f40a24171DeCBdB3D54;
		   voteTokens.push(TREATS);
           _addStakeToken(TREATS, 10**6, chainId == 1);
		   }else{
		   TREATS = address(0);
		   }
        _lastUpdate = block.timestamp;
        _treats = TREATS;
		address WTREATS = 0xFf2B94aD91bcF410dEC5Dd23b9e79a769bb4c534;
        voteTokens.push(WTREATS);
        _addStakeToken(WTREATS, 10**6, true);
        _wtreats = WTREATS;
        _svtreats = 0x233ff92B8Bde455E78Dd6340d7909FB88C102120;
        _vault = msg.sender;
        _lottery = 0x78328A08F3E6FaD922D312DB908879bC501d2a29;
		isOperator[_vault] = true;
		operators.push(_vault);
        //lockPeriod = 1;
        _lpBonus = 3000000;

        _isVote[this.voteAddRewardToken.selector] = true;
        _isVote[this.voteAddStakeToken.selector] = true;
        _isVote[this.voteAddNFT.selector] = true;
        _isVote[this.voteAddLiquidityToken.selector] = true;
        _isVote[this.voteRemoveToken.selector] = true;
        _isVote[this.voteSetTokenStakePower.selector] = true;

        runningVote = "Last vote is already pending!";
        notAdded = "Token is not supported!";
        added = "Token is already added!";
        noBalance = "Insufficient balance!";
        notApproved = "Approve token first!";
        notOwner = "You are not the owner!";
        noChange = "No change!";
        highNumber = "Too high number!";
        highBonus = "Stake Bonus too high!";
        isLocked = "Account is still locked!";
        higherThan = "Amount can not be 0!";
        notLength = "Tokens/amounts not same length";
        _voteTitels.push("Add token as reward");
        _voteTitels.push("Add token as stake");
        _voteTitels.push("Add nft as stake");
        _voteTitels.push("Add lp token as stake");
        _voteTitels.push("Remove token");
        _voteTitels.push("Change lottery to");
        _voteTitels.push("Set stake details of NFT");
        _voteTitels.push("Set Treats Base of token to");
        _voteTitels.push("Minimum Stake for ticket");
	    }
	
	/* ========== VIEW FUNCTIONS ========== */

    //function DOMAIN_SEPARATOR() external view returns (bytes32) {
	//  return _DOMAIN_SEPARATOR;
	//}

    //function treats() external view returns (address) {
	//  return _treats;
	//}

    //function wtreats() external view returns (address) {
	//  return _wtreats;
	//}

    //function svtreats() external view returns (address) {
	//  return _svtreats;
	//}

    //function vault() external view returns (address) {
	 // return _vault;
	//}

    //function lottery() external view returns (address) {
	//  return _lottery;
	//}

    function supportedVote(bytes4 _selector) external view returns (bool) {
        return _isVote[_selector];
	}

    function getReward(uint256 _number) external view returns (uint256 start, uint256 end, uint256 reward, uint256 amount, address token) {
      return (_rewards[_number].start, _rewards[_number].end, _rewards[_number].rewardPerShare, _rewards[_number].amount, _rewards[_number].token);
	}

    function getActiveRewards() external view returns (uint16[] memory){
        return activeRewards;
    }

    function getOpenRewards(uint256 _shares, uint256 _lastUpdateTime, uint256 _lastUpdateIndex, uint256 _lastReward, uint16[] memory _active) external view returns (address[] memory tokens, uint256[] memory amounts){
        return _getRewards(_shares, _lastUpdateTime, _lastUpdateIndex, _lastReward, _active);
    }
	
	//function getAllStakeTokens() external view returns (address[] memory) {
	//  return stakeTokens;
	//}

	//function getTreatBases(address[] memory _tokens) external view returns (uint256[] memory) {
	//  uint256[] memory treatBases;
    //  for(uint i=0; i < _tokens.length; i++){
    //      treatBases[i] = _treatsBases[_tokens[i]];
    //  }
    //  return treatBases;
	//}

	function balanceOfReward(address _token) external view returns (uint256) {
	  return _balanceFromShare(_token, _shareOfRewards[_token]);
	}

    function balanceFromShare(address _token, uint256 _share) external view returns (uint256) {
        return _balanceFromShare(_token, _share);
	}

    function stakePowerFromShares(uint256 _shares) external view returns (uint256) {
        uint256 total = _totalShares + _totalSharesCustom;
        return total == 0 ? 0 : _shares * _totalStakePower() / total;
	}
	
	function totalStakePower() external view returns (uint256) {
        return _totalStakePower();
	}
	
	function totalVotePower() external view returns (uint256) {
	  uint256 power;
        //address[] memory tokens = stakeTokens;
        for(uint256 i; i < voteTokens.length; i++){
        power = power + _balanceOfStake(voteTokens[i]) * _treatsBases[voteTokens[i]] / (10**24);
        }
	   return power;
	}

    function totalShares() external view returns (uint256) {
	   return _totalShares + _totalSharesCustom;
	}

    //function totalValues() external view returns (uint256 power, uint256 shares) {
	//   return (_totalStakePower(), _totalShares + _totalSharesCustom);
	//}

    function customPosition(address _nft, uint256 _nftId)
        external
        view
        returns (
            uint256 shares,
        uint256 lastWithdraw,
		uint256 lastReward,
		uint256 lastUpdate,
        uint16[] memory active
        )
    {
        require(_isStaked[_nft][_nftId], notAdded);
        Custom storage position = _customs[_nft][_nftId];
        return (
		    position.shares,
            position.lastWithdraw,
            position.lastReward,
            position.lastUpdate,
            position.active
        );
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
	
    /**
     * @notice stake OHM to enter warmup
     * @return bool
     */
    function createPosition(
		address _token,
        uint256 _amount
    ) external returns (bool) {
	    require(isStake[_token], notAdded);
		require(_amount > 0, higherThan);
		require(_amount <= IERC20(_token).allowance(msg.sender, address(this)), notApproved);
		_createPosition(msg.sender, _token, _amount);
		return true;
    }
	
	/**
     * @notice stake OHM to enter warmup
     * @param _from address
     * @param _amount uint
     * @param _data bool
     * @return uint
     */
    function onTokenReceived(
        address _from,
		uint256 _amount,
        bytes32[] memory _data
    ) external returns (bool) {
        //uint256 id = uint256(_data[0]);
        require(msg.sender == _wtreats, "Only WTREATS!");
        //require(id != 0 && _from == ISVTREATS(_svtreats).ownerOf(id), notOwner);
        require(uint256(_data[1]) == _amount, "Amount error!");
        require(_amount > 0, higherThan);
		if(uint256(_data[0]) == 0){
		   _createPosition(_from, _wtreats, _amount);
		   }else{
		   _stake(uint256(_data[0]), _wtreats, _amount);
		   }
		return true;
    }
	
	/**
     * @notice stake OHM to enter warmup
     **@param _nftId uint256
     * @param _amount uint256
     *@param _token address
     * @return bool
     */
    function stake(
        uint256 _nftId,
		address _token,
        uint256 _amount
    ) external returns (bool) {
		require(isStake[_token], notAdded);
		require(_amount > 0, higherThan);
		require(_amount <= IERC20(_token).allowance(msg.sender, address(this)), notApproved);
        //require(msg.sender == ISVTREATS(_svtreats).ownerOf(_nftId), notOwner);
		_stake(_nftId, _token, _amount);
		return true;
    }
	
	/**
     * @notice stake OHM to enter warmup
     * @param _nft address
     * @param _nftId uint256
     * @return bool
     */
    function stakeNFT(
        address _nft,
        uint256 _nftId
    ) external returns (bool) {
		require(isStake[_nft], notAdded);
		require(!_isStaked[_nft][_nftId], added);
		require(msg.sender == IERC721(_nft).ownerOf(_nftId) || isCommunityNFT[_nft], notOwner);
		_stakeNFT(_nft, _nftId);
		return true;
    }

    /**
     * @notice redeem sOHM for OHMs
     *@param _nftId uint256
     *@param _token address
     * @param _amount uint256
     * @return bool
     */
    function unstake(
        uint256 _nftId,
        address _token,
        uint256 _amount
    ) external returns (bool) {
        require(isStake[_token], notAdded);
        require(_amount > 0, higherThan);
	    require(msg.sender == ISVTREATS(_svtreats).ownerOf(_nftId), notOwner);
	    require(block.timestamp > ISVTREATS(_svtreats).lockOf(_nftId) && _amount <= Voter(_vault).voteLockOf(_nftId), isLocked);
        _unstake(_nftId, _token, _amount);
		return true;
    }

    /**
     * @notice redeem sOHM for OHMs
     *@param _nft address
     *@param _nftId uint256
     * @return bool
     */
    function unstakeNFT(
        address _nft,
        uint256 _nftId
    ) external returns (bool) {
        require(isStake[_nft] && !isCommunityNFT[_nft], notAdded);
        require(_isStaked[_nft][_nftId], notAdded);
	    require(msg.sender == ISVTREATS(_nft).ownerOf(_nftId), notOwner);
        _unstakeNFT(_nft, _nftId);
		return true;
    }

    /**
     * @notice redeem sOHM for OHMs
     *@param _nftId uint256
     * @return bool
     */
    function withdrawAll(
        uint256 _nftId
    ) external returns (bool) {
        require(ISVTREATS(_svtreats).stakePowerOf(_nftId) > 0, higherThan);
	    require(msg.sender == IERC721(_svtreats).ownerOf(_nftId), notOwner);
        require(block.timestamp > ISVTREATS(_svtreats).lockOf(_nftId) && type(uint256).max == Voter(_vault).voteLockOf(_nftId), isLocked);
        _withdrawRewards(_svtreats, _nftId);
        _withdraw(_nftId);
		return true;
    }

    /**
     * @notice redeem sOHM for OHMs
     *@param _nftId uint256
     * @return bool
     */
    function withdrawRewards(
        address _nft,
        uint256 _nftId
    ) external returns (bool) {
	    require(msg.sender == IERC721(_nft).ownerOf(_nftId), notOwner);
        require(isStake[_nft] || _nft == _svtreats, notAdded);
	    require(block.timestamp >= ISVTREATS(_svtreats).lockOf(_nftId), isLocked);
		_withdrawRewards(_nft, _nftId);
		return true;
    }
	
    /**
     * @notice trigger rebase if epoch over
     */
    function updateData() external {
		_updateData();
    }
	
	/**
     * @notice stake OHM to enter warmup
     **@param _nftId uint256
     */
    function updatePosition(uint256 _nftId) public {
		_updateData();
        (uint256 shares, uint256 lastUpdateTime, uint256 lastUpdateIndex, uint256 lastReward, uint16[] memory active) = ISVTREATS(_svtreats).getLastUpdateOf(_nftId);
        if (active.length + _rewards.length - lastReward > 0 && lastUpdateTime != block.timestamp && shares > 0){
            _updatePosition(_nftId, shares, lastUpdateTime, lastUpdateIndex, lastReward, active);
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */
	
    /**
     * @notice stake OHM to enter warmup
     * @param _creater address
     * @return uint
     */
    function _createPosition(
        address _creater,
		address _token,
        uint256 _amount
    ) private returns (bool) {
        _updateData();
        //uint256 shares = getShare(_token, _amount);
        //_totalShares = _totalShares + shares;
        bytes memory data = abi.encode(_creater, _rewards.length, _updates.length, activeRewards);
        uint256 id = ISVTREATS(_svtreats).mint(data);
        _stake(id, _token, _amount);
		return true;
    }

	/**
     * @notice stake OHM to enter warmup
     *@param _nftId uint256
     * @param _amount uint256
     *@param _token address
     * @return uint
     */
    function _stake(
        uint256 _nftId,
		address _token,
        uint256 _amount
    ) private returns (bool) {
        updatePosition(_nftId);
		uint256 shares = getShare(_token, _amount);
        uint256 sharesToken = getTokenShare(_token, _amount);
		//_sharesOf[_svtreats][_nftId] = _sharesOf[_svtreats][_nftId] + shares;
		_totalShares = _totalShares + shares;
        if(isReflection[_token]){
            //sharesToken = getTokenShare(_token, _amount);
			_totalSharesOf[_token] = _totalSharesOf[_token] + sharesToken;
        }
        ISVTREATS(_svtreats).stakeToken(_nftId, _token, sharesToken, shares);
        if(_token == _treats || _token == _wtreats){ILottery(_lottery).setLottery(_nftId);}
		IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        emit Stake(_svtreats, _nftId, _token, _amount);
		return true;
    }

    /**
     * @notice stake OHM to enter warmup
     *@param _nftId uint256[]
     *@param _nft address[]
     * @return bool
     */
    function _stakeNFT(
		address _nft,
        uint256 _nftId
    ) private returns (bool) {
        _updateData();
        uint256 shares = getShare(_nft, 1);
		_totalSharesCustom = _totalSharesCustom + shares;
        _isStaked[_nft][_nftId] = true;
        ILottery(_lottery).joinLotteryNFT(_nft, _nftId);
        _customs[_nft][_nftId] = Custom({
            shares: shares,
            lastWithdraw: block.timestamp,
            lastReward: _rewards.length,
            lastUpdate: _updates.length,
            active: activeRewards
        });

        emit Stake(_nft, _nftId, _nft, 1);
        return true;
    }

    /**
     * @notice redeem sOHM for OHMs
     *@param _nftId uint256
     *@param _token address
     *@param _amount uint256
     * @return uint256[]
     */
    function _unstake(
        uint256 _nftId,
        address _token,
        uint256 _amount
    ) private returns (bool) {
        updatePosition(_nftId);
        uint256 share = ISVTREATS(_svtreats).balanceOfStake(_nftId, _token);
        uint256 balance = _balanceFromShare(_token, share);
        require(balance >= _amount, noBalance);
        uint256 shares = getShare(_token, _amount);
        uint256 sharesToken = getTokenShare(_token, _amount);
        if(isReflection[_token]){
            _totalSharesOf[_token] = _totalSharesOf[_token] - sharesToken;
        }
        _totalShares = _totalShares - shares;

        ISVTREATS(_svtreats).unstakeToken(_nftId, _token, sharesToken, shares);
        if(_token == _treats || _token == _wtreats){ILottery(_lottery).setLottery(_nftId);}
        IERC20(_token).safeTransfer(msg.sender, _amount);

        emit Unstake(_svtreats, _nftId, _token, _amount);
		return true;
    }

    /**
     * @notice redeem sOHM for OHMs
     *@param _nft address
     *@param _nftId uint256
     * @return uint256[]
     */
    function _unstakeNFT(
        address _nft,
        uint256 _nftId
    ) private returns (bool) {
        _updateData();
        _totalSharesCustom = _totalSharesCustom - _customs[_nft][_nftId].shares;
        _withdrawRewards(_nft, _nftId);
        _isStaked[_nft][_nftId] = false;
        delete _customs[_nft][_nftId];
        ILottery(_lottery).leaveLotteryNFT(_nft, _nftId);

        emit Unstake(_nft, _nftId, _nft, 1);
		return true;
    }

    /**
     * @notice redeem sOHM for OHMs
     *@param _nftId uint256
     * @return amount_ uint
     */
    function _withdraw(
        uint256 _nftId
    ) private returns (bool) {
        updatePosition(_nftId);
        //(uint256 shares, uint256 lastUpdateTime, uint256 lastReward , uint256 lastUpdateIndex, uint16[] memory active) = ISVTREATS(_svtreats).getLastUpdateOf(_nftId);
        //(address[] memory rewardTokens, uint256[] memory rewardAmounts) = _getRewards(shares, lastUpdateTime, lastUpdateIndex, lastReward, active);
        (address[] memory tokens, uint256[] memory amounts) = ISVTREATS(_svtreats).unstakeAll(_nftId);
        //address[] memory allTokens = new address[](rewardTokens.length + tokens.length);
        //uint256[] memory allAmounts = new uint256[](rewardTokens.length + tokens.length);           
        for (uint i = 0; i < tokens.length; i++) {
            amounts[i] = _balanceFromShare(tokens[i], amounts[i]);                     
        }
        //for (uint i = 0; i < rewardTokens.length; i++) {
        //    allAmounts[i + tokens.length] = _balanceFromShare(rewardTokens[i], rewardAmounts[i]);
        //}
        _sendTokens(tokens, amounts);
        ILottery(_lottery).setLottery(_nftId);
		return true;
    }

    /**
     * @notice redeem sOHM for OHMs
     *@param _nftId uint256
     * @return amount_ uint
     */
    function _withdrawRewards(
        address _nft,
        uint256 _nftId
    ) private returns (bool) {
        if(_svtreats == _nft){
            updatePosition(_nftId);
	        //(address[] memory openRewardsTokens, uint256[] memory openRewardsAmounts) = ISVTREATS(_svtreats).getOpenRewardsOf(_nftId);
            (address[] memory openRewardsTokens, uint256[] memory openRewardsAmounts) = ISVTREATS(_svtreats).withdrawRewards(_nftId);

            _sendTokens(openRewardsTokens, openRewardsAmounts);
        }else{
            _updateData();
            Custom storage custom = _customs[_nft][_nftId];
            (address[] memory openRewardsTokens, uint256[] memory openRewardsAmounts) = _getRewards(custom.shares, custom.lastWithdraw, custom.lastUpdate, custom.lastReward, custom.active);
            custom.shares = getShare(_nft, 1);
            custom.lastWithdraw = block.timestamp;
            custom.lastReward = _rewards.length;
            custom.lastUpdate = _updates.length;
            custom.active = activeRewards;

            _sendTokens(openRewardsTokens, openRewardsAmounts);
        }
		return true;
    }
			
	/**
     * @notice set warmup period for new stakers
     * @param _pool address
     */
    function _addLiquidity(address _pool, bool _isNFT) private returns (bool) {
        liquidityTokens.push(_pool);
		if(_isNFT){
		   isNFT[_pool] = true;
		}
        _addStakeToken(_pool, _lpBonus, false);
		
        emit LogAddStake(_pool);
		return true;
    }
	
    /**
     * @notice set warmup period for new stakers
     * @param _nft address
     */
    function _addNFT(address _nft, uint256 _treatsBase, bool _isCommunity) private returns (bool) {
        isNFT[_nft] = true;
		if(_isCommunity){
           isCommunityNFT[_nft] = true;
           voteTokens.push(_nft);
           ILottery(_lottery).addToken(_nft, 2);
		}
        _addStakeToken(_nft, _treatsBase, false);
        emit LogAddStake(_nft);
		return true;
    }
	
	/**
     * @notice set warmup period for new stakers
     * @param _token address
     */
    function _addReward(address _token, bool _reflection) private returns (bool) {
	    isReward[_token] = true;
        if(_reflection){isReflection[_token] = true;}
		return true;
    }
	
	/**
     * @notice set warmup period for new stakers
      * @param _token address
     */
    function _addStakeToken(address _token, uint256 _treatsBase, bool reflect) private returns (bool) {
        if(reflect){isReflection[_token] = true;}
		isStake[_token] = true;
		stakeTokens.push(_token);
		_treatsBases[_token] = _treatsBase;
		
        emit LogAddStake(_token);
		return true;
    }
	
	/**
     * @notice set warmup period for new stakers
     * @param _token address
     */
    function _removeToken(address _token) private returns (bool) {
	   if(isStake[_token]){
          isStake[_token] = false;
		  for (uint256 i = 0; i < stakeTokens.length; i++) {
             if (stakeTokens[i] == _token) {
                if(i != (stakeTokens.length - 1)){stakeTokens[i] = stakeTokens[stakeTokens.length - 1];}
                stakeTokens.pop();
                break;
             }
          }
          _setTreatsBaseOf(_token, 0);
	   }
	   if(isReward[_token]){
          isReward[_token] = false;
	   }
		return true;
    }
	
	/**
     * @notice sets the contract address for LP staking
      * @param _token address
     */
    function _setTreatsBaseOf(address _token, uint _power) private returns (bool) {
        _updates.push(Update({
               token: _token,
               newValue: _power,
               oldValue: _treatsBases[_token],
               timestamp: block.timestamp,
               changedShares: int(getShare(_token, 1) - getShare(_token, 1))
           }));
        _treatsBases[_token] = _power;
		_lastUpdateOfToken[_token] = block.timestamp;
		lastStakeUpdate = block.timestamp;
		return true;
    }
	
	 /**
     * @notice set warmup period for new stakers
     * @param _bonus uint8
     */
    function _setLiquidityProviderBonus(uint256 _bonus) private returns (bool) {
        _lpBonus = _bonus;
		return true;
    }

    //function _callItself(bytes4 _data) private returns (bool) {
    //    (bool success,) = address(this).call(abi.encodeWithSelector(_data, votingAddr, votingInt, votingTicket, votingBool));
    //    return success;
	//}

    //function _getData(bytes memory _data) private pure returns (bytes4) {
    //    return bytes4(keccak256(_data));
	//}
    
	// generate string from bytes data
    //function toString(bytes memory data) private pure returns(string memory) {
    //    bytes memory alphabet = "0123456789abcdef";
    //    bytes memory str = new bytes(2 + data.length * 2);
    //    str[0] = "0";
    //    str[1] = "x";
    //    for (uint i = 0; i < data.length; i++) {
    //        str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
    //        str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
    //    }
    //    return string(str);
    //}
	
	// generate string from uint256
    //function uintToString(uint256 data) private pure returns (string memory str) {
    //   if (data == 0){
    //      return "0";
    //    }
    //   uint256 j = data;
    //   uint256 length;
    //   while (j != 0){
    //     length++;
    //     j /= 10;
    //   }
    //   bytes memory bstr = new bytes(length);
    //   uint256 k = length;
    //   j = data;
    //   while (j != 0){
    //     bstr[--k] = bytes1(uint8(48 + j % 10));
    //     j /= 10;
    //   }
    //   str = string(bstr);
    //}

    function _totalStakePower() private view returns (uint256) {
        uint256 power;
        for(uint256 i; i < stakeTokens.length; i++){
        power = power + _balanceOfStake(stakeTokens[i]) * _treatsBases[stakeTokens[i]];
        }
	   return (power / 10**6);
	}

    /**
     * @notice stake OHM to enter warmup
     **@param _amounts uint256[]
     */
    function _sendTokens(address[] memory _tokens, uint256[] memory _amounts) private {
        for (uint i = 0; i < _tokens.length; i++) {		  
		    IERC20(_tokens[i]).safeTransfer(msg.sender, _amounts[i]);
		}
    }

    /**
     * @notice stake OHM to enter warmup
     **@param _nftId uint256
     */
    function _updateData() private returns (bool) {
        if (_lastUpdate != block.timestamp){
            if(0 < activeRewards.length && _totalShares > 0){
		    for(uint i = 0; i < activeRewards.length; i++){
              address token = _rewards[activeRewards[i]].token;
			  uint256 rewardsUpdate;
			  uint256 secondsUpdate = block.timestamp - _lastUpdate;
              uint256 rewardPerSec = getRewardAmount(_totalShares, _rewards[activeRewards[i]].rewardPerShare, 1);
			  uint256 secondsLeft = _balanceFromShare(token, _shareOfRewards[token]) / rewardPerSec;
              if(secondsLeft <= secondsUpdate){
                    secondsUpdate = secondsLeft;
                    rewardsUpdate = _shareOfRewards[token]; //secondsUpdate * rewardPerSec;
			    	//uint256 balanceLeft = _balanceOfRewards[rewards[activeRewards[i]].token].sub(rewardsUpdate);
                    //if(isReflection[token]){_totalSharesOf[token] = _totalSharesOf[token] + _shareOfRewards[token];}
			    	//_shareOfRewards[token] = 0;
			    	_rewards[activeRewards[i]].end = _lastUpdate + secondsUpdate;
                    if(i < activeRewards.length - 1){
			    	      activeRewards[i] = activeRewards[activeRewards.length - 1];
			    	      i--;
			    	}activeRewards.pop;
			    }else{
                    rewardsUpdate = getTokenShare(token, secondsUpdate * rewardPerSec);
                }
                if(isReflection[token]){_totalSharesOf[token] = _totalSharesOf[token] + rewardsUpdate;}
			    _shareOfRewards[token] = _shareOfRewards[token] - rewardsUpdate;
			}
            }
            _lastUpdate = block.timestamp;
        }
        return true;
    }

    /**
     * @notice stake OHM to enter warmup
     **@param _nftId uint256
     */
    function _updateShares(uint256 _nftId, uint256 _shares) public returns (bool) {
            (address[] memory stakedTokens, uint256[] memory stakedShares) = ISVTREATS(_svtreats).stakedBalancesOf(_nftId);
            uint256 share;
            for(uint i = 0; i < stakedTokens.length; i++){
                stakedShares[i] = _balanceFromShare(stakedTokens[i], stakedShares[i]);
                share = share + getShare(stakedTokens[i], stakedShares[i]);
		    }
            if(share > _shares){
                uint256 newShare = share - _shares;
                _totalShares = _totalShares + newShare;
                ISVTREATS(_svtreats).addShare(_nftId, newShare);
            }
        
            return true;
    }

    /**
     * @notice stake OHM to enter warmup
     **@param _nftId uint256
     */
    function _updatePosition(uint256 _nftId, uint256 _shares, uint256 _lastUpdateTime, uint256 _lastUpdateIndex, uint256 _lastReward, uint16[] memory _active) public returns (bool) {      
        if(_active.length + _rewards.length - _lastReward > 0){
            uint256 tokenID = _nftId;           
            //uint16[] memory activ = new uint16[](_active.length + _rewards.length - _lastReward);
            for (uint i = 0; i < _active.length; i++) {
                //Reward storage reward = _rewards[active[i]];
                //activ[i] = _active[i];
                if(_rewards[_active[i]].end != 0){ISVTREATS(_svtreats).removeActivReward(tokenID, _active[i]);}
            }
            for(uint i = _lastReward; i < _rewards.length; i++){
                //activ[_active.length + i - _lastReward] = uint16(i);
		    	if(_rewards[i].end == 0){ISVTREATS(_svtreats).addActivReward(tokenID, i);}
		    }
            (address[] memory _tokens, uint256[] memory _amounts) = _getRewards(_shares, _lastUpdateTime, _lastUpdateIndex, _lastReward, _active);
            for (uint i = 0; i < _tokens.length; i++) {
                //(address _token, uint256 _amount, bool isStake) = _sortReward(_nftId, _tokens[i], _amounts[i]);
               if(isStake[_tokens[i]]){
                  ISVTREATS(_svtreats).stakeToken(tokenID, _tokens[i], getTokenShare(_tokens[i], _amounts[i]), getShare(_tokens[i], _amounts[i]));
                 //if(i != _tokens.length - 1){
                     //_tokens[i] = _tokens[_tokens.length - 1];
                     //_amounts[i] = _amounts[_amounts.length - 1];
                      //delete(_tokens[i]);
                      //delete _amounts[i];
                      //i--;
        
               }
                   //assembly { mstore(_tokens, sub(mload(_tokens), 1))}
                   //assembly { mstore(_amounts, sub(mload(_amounts), 1))}               
              }
    
			if(_tokens.length > 0){
                ISVTREATS(_svtreats).updatePosition(tokenID, _tokens, _amounts, _rewards.length, _updates.length);
                ILottery(_lottery).setLottery(tokenID);
            }
            }
        _updateShares(_nftId, _shares);
        return true;
    }

    function _getUpdatedShares(uint256 _lastUpdateTime, uint256 _lastUpdateIndex) private view returns (int256[] memory, uint256[] memory) {
      int256[] memory changes = new int256[](_updates.length - _lastUpdateIndex + 2);
	  uint256[] memory time = new uint256[](_updates.length - _lastUpdateIndex + 2);
      changes[0] = 0;
      time[0] = _lastUpdateTime;
      if(_lastUpdateIndex < _updates.length){
	     for(uint i = _lastUpdateIndex; i < _updates.length; i++){
			     changes[i - _lastUpdateIndex + 1] = _updates[i].changedShares;
                 time[i - _lastUpdateIndex + 1] = _updates[i].timestamp;
				 }
				 }
        changes[changes.length - 1] = 0;
        time[time.length - 1] = block.timestamp;
	     return (changes, time);
	}

    function _getRewards(uint256 _shares, uint256 _lastUpdateTime, uint256 _lastUpdateIndex, uint256 _lastReward, uint16[] memory _active) public view returns (address[] memory, uint256[] memory){
        uint256 shares = _shares;
        (int256[] memory changedShare, uint256[] memory timestamp) = _getUpdatedShares(_lastUpdateTime, _lastUpdateIndex);
        uint16[] memory activ = new uint16[](_active.length + _rewards.length - _lastReward);
        for(uint i = 0; i < _active.length; i++){
            activ[i] = _active[i];
		}
        for(uint i = _lastReward; i < _rewards.length; i++){
            activ[_active.length + i - _lastReward] = uint16(i);
		}
        uint256[] memory rewardAmounts = new uint256[](activ.length);
        address[] memory rewardTokens = new address[](activ.length);
        for (uint256 i = 0; i < activ.length; i++) {
            Reward storage reward = _rewards[activ[i]];
            for (uint256 j = 1; j < changedShare.length; j++) {
                if(reward.end != 0 && reward.end < timestamp[j]){
                    rewardAmounts[i] = rewardAmounts[i] + getRewardAmount(uint(int(shares) + changedShare[j]), reward.rewardPerShare, reward.end - timestamp[j - 1]);
                    break;
                }
                rewardAmounts[i] = rewardAmounts[i] + getRewardAmount(uint(int(shares) + changedShare[j]), reward.rewardPerShare, timestamp[j] - timestamp[j - 1]);
                //if(_updates[_lastUpdateIndex + j].oldValue < _updates[_lastUpdateIndex + j].newValue){
                //    rewardAmounts[i] = getRewardAmount(_shares - changedShare[j], _rewards[_active[i]].rewardPerShare, changeSeconds);
                //}else{
                //    rewardAmounts[i] = getRewardAmount(_shares + changedShare[j], _rewards[_active[i]].rewardPerShare, changeSeconds);
                //}
            }
            rewardTokens[i] = reward.token;
        }
        return (rewardTokens, rewardAmounts);
    }

    function getRewardAmount(uint256 _share, uint256 _reward, uint256 _seconds) private pure returns (uint256){
        return _share * _reward / 10**6 * _seconds / (60*60*24*360);
    }

    function _balanceOfStake(address _token) private view returns (uint256) {
        return IERC20(_token).balanceOf(address(this)) - _balanceFromShare(_token, _shareOfRewards[_token]);
	}

    function _balanceFromShare(address _token, uint256 _share) private view returns (uint256){
        if(!isReflection[_token]){return _share;}
        return _totalSharesOf[_token]!= 0 ? _share * IERC20(_token).balanceOf(address(this)) / (_totalSharesOf[_token]) : 0;
    }

    //function _balanceOfReward(address _token, uint256 _share) private view returns (uint256){
    //    if(!isReflection[_token]){return _share;}
    //    return _totalSharesOf[_token] + _shareOfRewards[_token] != 0 ? _share * IERC20(_token).balanceOf(address(this)) / (_totalSharesOf[_token] + _shareOfRewards[_token]) : 0;
    //}

    function getShare(address _token, uint256 _amount) private view returns (uint256){
        uint256 power = _amount * _treatsBases[_token] / 10**6;
        uint256 total = _totalStakePower();
        return total == 0 ? power : power * (_totalShares + _totalSharesCustom) / total;
    }

    function getPowerFromShares(uint256 _shares) private view returns (uint256) {
        uint256 total = _totalShares + _totalSharesCustom;
        return total == 0 ? 0 : _shares * _totalStakePower() / total;
	}

    function getTokenShare(address _token, uint256 _amount) private view returns (uint256){
        if(!isReflection[_token]){return _amount;}
        return _totalSharesOf[_token] == 0 ? _amount * 100 : _amount * _totalSharesOf[_token] / _balanceOfStake(_token);
    }

    //function getBytes() public view returns (bytes memory){
    //    return abi.encode(_vault, _treats, _rewards.length, _updates.length, activeRewards);
    //}

    /* ========== MANAGERIAL FUNCTIONS ========== */

    /**
     * @notice set warmup period for new stakers
     * @param _index uint
     */
    function setReward(uint256 _index, uint256 _reward) external onlyOperator returns (bool) {
        require(_rewards[_index].end == 0, "No active reward!");
        _updateData();
        _rewards[_index].rewardPerShare = _reward;
        return true;
    }

	/**
     * @notice set warmup period for new stakers
     * @param _token address
     * @param _amount uint256
     * @param _rewardAnnual uint256
     */
    function addReward(address _token, uint256 _amount, uint256 _rewardAnnual) external onlyOperator returns (bool) {
        _updateData();
        require(isReward[_token] || isStake[_token], notAdded);
		require(_shareOfRewards[_token] == 0, "Active reward for this token!");
		require(_amount <= IERC20(_token).allowance(msg.sender, address(this)), notApproved);
		require(activeRewards.length < 20, "Too many active rewards!");
        uint256 amount = getTokenShare(_token, _amount);
        _shareOfRewards[_token] = amount;
        //if(_token == TREATS || _token == WTREATS){
		//   _totalSharesTreats = _amount.mul(_totalSharesTreats.div(_totalStakedTokens[TREATS]));
		//   _sharesOfRewards[_token] = _amount.mul(_totalSharesTreats.div(_totalStakedTokens[TREATS]));
		//   //isActiveReward[_token] = true;
        //}else if(_token == WTREATS){
		//   _totalSharesWtreats = _amount.mul(_totalSharesWtreats.div(_totalStakedTokens[TREATS]));
		//   _sharesOfRewards[_token] = _amount.mul(_totalSharesWtreats.div(_totalStakedTokens[TREATS]));
		//   //isActiveReward[_token] = true;
        //}
        activeRewards.push(uint16(_rewards.length));
			_rewards.push(Reward({
		        start: block.timestamp,
				end: 0,
                rewardPerShare: _rewardAnnual,
                amount: _amount,
                token: _token
            }));

            //_sendTokens(address[]([_token]), new uint256[](_amount));         
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
		  
        emit LogAddReward(_token, _amount);
		return true;
    }

    /**
     * @notice set warmup period for new stakers
     * @param _contract address
     */
    function setNewLottery(address _contract) external returns (bool) {
        require(msg.sender == _lottery, "Only Lottery!");
        _lottery = _contract;
		return true;
    }


    /**
     * @notice set warmup period for new stakers
     * @param _nft address
     */
    function setPositionsNFTOnce(address _nft) external onlyVault returns (bool) {
        //require(_svtreats == address(0), "svTREATS already setted!");
        _svtreats = _nft;
        return true;
    }

    /* ========== GOVERNANCE FUNCTIONS ========== */
	
	/**
     * @notice set warmup period for new stakers
     * @param _params bytes
     */
    function voteAddRewardToken(bytes calldata _params) external onlyVault returns (bool) {
        //require(pendingVote == "", runningVote);
        (address token, bool reflection) = abi.decode(_params, (address, bool));
        require(!isReward[token] && !isStake[token], added);
            _addReward(token, reflection);
           return true;
    }
	
	/**
     * @notice set warmup period for new stakers
     * @param _params bytes
     */
    function voteAddStakeToken(bytes calldata _params) external onlyVault returns (bool) {
        (address token, uint256 power, bool reflection) = abi.decode(_params, (address, uint256, bool));
        require(!isStake[token], added);
        _addStakeToken(token, power, reflection); 
        return true;
    }
	
	/**
     * @notice set warmup period for new stakers
     * @param _params bytes
     */
    function voteAddNFT(bytes calldata _params) external onlyVault returns (bool) {
        (address nft, uint256 power, bool isCommunity) = abi.decode(_params, (address, uint256, bool));
        require(!isStake[nft], added);
        _addNFT(nft, power, isCommunity);
        return true;
    }
	
	/**
     * @notice set warmup period for new stakers
     * @param _params bytes
     */
    function voteAddLiquidityToken(bytes calldata _params) external onlyVault returns (bool) {
        (address pool, bool isNft) = abi.decode(_params, (address, bool));
        require(!isStake[pool], added);
        _addLiquidity(pool, isNft);
        return true;
    }
	
	/**
     * @notice set warmup period for new stakers
     * @param _params bytes
     */
    function voteRemoveToken(bytes calldata _params) external onlyVault returns (bool) {
        (address token) = abi.decode(_params, (address));
        require(token != _wtreats && token != _treats, "TREATS can not be removed!");
        _removeToken(token);
        return true;
    }
	
	/**
     * @notice set warmup period for new stakers
     * @param _params bytes
     */
    function voteSetTokenStakePower(bytes calldata _params) external onlyVault returns (bool) {
        (address token, uint256 power) = abi.decode(_params, (address, uint256));
        require(isStake[token], notAdded);
        require(!(power == _treatsBases[token]), noChange);
        _setTreatsBaseOf(token, power);
        return true;
    }
	
	//Get vote result from voting contract
    //function endVote(bytes32 hash, bool result) external onlyVault returns (bool) {
    //    require(pendingVote == hash, "Vote not found!");
    //    require(block.timestamp > delayVote, runningVote);
    //    if(result){      
    //         if(voteAddr){
    //            voteAddr = false;
    //            if(votingBool){votingBool = false;}
    //            if(votingFunction == 1){
    //                _addReward(votingAddr, votingBool);
    //            }else if(votingFunction == 2){
    //                _addStakeToken(votingAddr, votingInt, votingBool);
    //            }else if(votingFunction == 3){
    //                _addNFT(votingAddr, votingInt, votingBool);
    //            }else if(votingFunction == 4){
    //                _addLiquidity(votingAddr, votingBool);
    //            }else if(votingFunction == 5){
    //                _removeToken(votingAddr);
    //            }
    //        }else if(voteInt){
    //            voteInt = false;
    //            if(votingFunction == 8){
    //                _setTreatsBaseOf(votingAddr, votingInt);
    //            }
    //        }
    //    }else if(voteInt){
    //           voteInt = false;
    //        }else if(voteAddr){
    //           if(votingBool){votingBool = false;}
    //           voteAddr = false;
    //        }
    //    
    //    pendingVote = "";
    //    return true;
    //}
	
	/**
     * @notice set warmup period for new stakers
     * @param _days uint8
     */
    //function setDelay(uint8 _days) external onlyVault returns (bool) {
	//    //require(_days >= 3 && _days <= 30, "Only Delay between 3 and 30 days!");
	//    delay = 60*60*24*_days;
	//	return true;
    //}
	
	/**
     * @notice set warmup period for new stakers
     * @param _auth address
     */
    function setOperator(address _auth) external onlyVault returns (bool) {
	    isOperator[_auth] = true;
        operators.push(_auth);
		return true;
    }
	
	/**
     * @notice set warmup period for new stakers
     * @param _contract address
     */
    function setVault(address _contract) external onlyVault returns (bool) {
        _vault = _contract;
		return true;
    }
	
	// revoke operator via community voting
    function revokeOperator(address _auth) external onlyVault returns (bool) {
        isOperator[_auth] = false;
        for (uint256 i = 0; i < operators.length; i++) {
            if (operators[i] == _auth) {
                if(i != (operators.length - 1)){operators[i] = operators[operators.length - 1];}
                operators.pop();
                break;
            }
        }
        return true;
    }
}