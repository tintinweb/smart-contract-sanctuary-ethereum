// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface ERC721 /* is ERC165 */ {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract Staking is Ownable, IERC721Receiver {
    mapping(uint=>uint) public stakingStartTime;   // Timestamp of when the staking started.
    mapping(uint=>address) public tokenOwner;      // Owner of the token
    mapping(uint=>uint) public tokenLevel;         // Level of the token
    mapping(uint=>uint) public lastClaimTime;      // Timestamp of when the user last claimed.
    mapping(address=>uint[]) public stakers;       // stakers mapped to tokens


    uint public reward = 10;        // Basic Reward
    uint public maxLevel = 20;
    ERC721 erc721;  // NFT contract
    ERC20 erc20;    // Reward Token Contract

    bool public stakingStarted;
    uint public stakingPeriod = 24 hours;

    /**
     * @dev Sets the NFT contract.
        Can only be called by the current owner.
     * @notice
        Once you deployed this smart contract, don't forget to call this method.
    */
    function setErc721(address addr) public onlyOwner {
        erc721 = ERC721(addr);
    }

    /**
     * @dev Sets the ERC20 reward contract.
        Can only be called by the current owner.
     * @notice
        Once you deployed this smart contract, don't forget to call this method.
    */
    function setErc20(address addr) public onlyOwner {
        erc20 = ERC20(addr);
    }

    /**
     * @dev Sets if the staking is started or not.
        Can only be called by the current owner.
     * @notice
        The staking works only after you set the staking 'true'
    */
    function setStakingStarted(bool s) public onlyOwner {
        stakingStarted = s;
    }

    function setMaxLevel(uint _level) public onlyOwner {
        maxLevel = _level;
    }

    /**
     * @dev Starts staking of the 'tokenId'
        Can only be called by the owner of the tokenId
    */
    function stake(uint tokenId, uint level) external {
        require(level > 0, "below 0");
        require(level <= maxLevel, "over max level");
        require(erc721.ownerOf(tokenId) == msg.sender, "You are not the owner.");
        require(stakingStartTime[tokenId] == 0, "The Token is already on staking.");

        stakers[msg.sender].push(tokenId);
        erc721.safeTransferFrom(msg.sender, address(this), tokenId);
        stakingStartTime[tokenId] = block.timestamp;
        tokenOwner[tokenId] = msg.sender;
        tokenLevel[tokenId] = level;
        lastClaimTime[tokenId] = block.timestamp;
    }


    function getStakedTokens(address _user) public view returns (uint[] memory)
    {
        return stakers[_user];
    }

    /**
     * @dev Unstake 'tokenId'
        Can only be called by the owner of the tokenId
        Can only be called 1 day after staking
    */
    function unstake(uint tokenId) external {
        require(stakingStartTime[tokenId] > 0, "This token is not on staking.");
        require(tokenOwner[tokenId] == msg.sender, "You are not the owner of this token.");

        uint rwd = calcReward(tokenId);

        if(rwd > 0) {
            erc20.transfer(msg.sender, rwd * 10 ** 18);
        }

        erc721.safeTransferFrom(address(this), tokenOwner[tokenId], tokenId);
        uint256 index = indexOf(stakers[msg.sender], tokenId);
        delete stakers[msg.sender][index];
        stakingStartTime[tokenId] = 0;
        lastClaimTime[tokenId] = 0;

        tokenOwner[tokenId] = address(0);
    }

    function indexOf(uint256[] memory arr, uint256 searchFor) private returns (uint256) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == searchFor) {
                return i;
            }
        }
        revert("Not Found");
    }

    /**
     * @dev Unstake 'tokenId'
        Can only be called by the owner of the tokenId
        Can only be called 1 day after the last claim
    */
    function claimReward(uint tokenId) external {
        require(stakingStartTime[tokenId] > 0, "This token is not on staking.");
        require(tokenOwner[tokenId] == msg.sender, "You are not the owner of this token.");

        uint rwd = calcReward(tokenId);
        require(rwd > 0, "You don't have funds to claim.");
        erc20.transfer(msg.sender, rwd * 10 ** 18);
        lastClaimTime[tokenId] = block.timestamp - (block.timestamp - lastClaimTime[tokenId]) % (stakingPeriod);
    }

    /**
     * @dev Calculates the reward of 'tokenId'
    */
    function calcReward(uint tokenId) public view returns(uint) {
        uint rwd;
        if(lastClaimTime[tokenId] > 0) {
            rwd = (reward + tokenLevel[tokenId]) * ((block.timestamp - lastClaimTime[tokenId]) / stakingPeriod);
        }
        return rwd;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}