/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address who) view external returns (uint256);
}
interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external returns (address);
    function ownerOf(uint256 tokenId) external returns (address);
} 

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

contract BlockdeedStaking is Ownable{
    address private _owner;

    uint256 public BKDPrice = 1;  //1 BKD = $0.01 (0.01*100)

    uint256 public stakingPrice = 1000; //$10 = ($10*100)
    uint256 public constant stakingDuration = 300; // 5 minutes        ||     7776000; // 90 days

    address public TokenContract;
    address public NFTContract;

    struct Stake{
        address user;
        uint256 tokenId;
        uint256 since;
        uint256 claimeAfter;
        uint256 reward;
        uint256 unstaked;
    }
    Stake[] private stakes;
    mapping(uint256 => uint256) private history;
    
    event NFTStaked(address owner, uint256 tokenId);
    event NFTUnstaked(address owner, uint256 tokenId);

    mapping(address => Stake[]) private stake_holders;

    event OwnerChanged(address _to);

    constructor(address tokenContract,address NftContract) {
        require(tokenContract!= address(0) && NftContract!= address(0),"This address is not valid");
        _owner = msg.sender;

        stakes.push(Stake(msg.sender,99999999,block.timestamp,(block.timestamp + stakingDuration),0,block.timestamp));
        history[99999999]=stakes.length;
        TokenContract=tokenContract;
        NFTContract=NftContract;
    }   

    /* Staking part*/
    function putOnStake(uint256 tokenId) public {
        require(history[tokenId]==0,"Exist record...");
        address owned = IERC721(NFTContract).ownerOf(tokenId);
        require(owned==msg.sender,"You are not owner of this NFT...");
        require(IERC721(NFTContract).getApproved(tokenId)==address(this),"Approve to contract address first...");
        uint256 reward=(stakingPrice/BKDPrice) * (10 ** 18);
        stakes.push(Stake(msg.sender,tokenId,block.timestamp,(block.timestamp + stakingDuration), reward ,0));
        history[tokenId]=stakes.length-1;
        stake_holders[msg.sender].push(stakes[history[tokenId]]);
        IERC721(NFTContract).transferFrom(msg.sender, address(this), tokenId);
        emit NFTStaked(msg.sender, tokenId);
    }
    function unstake(uint256 tokenId) public {
        require(history[tokenId]>0,"Not exist.");
        Stake storage stake = stakes[history[tokenId]];
        require(stake.unstaked==0,"NFT already unstaked.");
        require(stake.user==msg.sender,"You are not owner.");
        require(stake.claimeAfter<=block.timestamp,"You cant unstake before 90 days.");
        require(stake.reward<=IERC20(TokenContract).balanceOf(address(this)),"ERC20 Token balance is lower.");
        IERC721(NFTContract).transferFrom(address(this), msg.sender, tokenId);
        IERC20(TokenContract).transfer(msg.sender,stake.reward);
        stake.unstaked=block.timestamp;
        emit NFTUnstaked(msg.sender, tokenId);
        
    }
    function getStakeDataByToken(uint256 tokenId) public view returns (address, uint256, uint256, uint256, uint256, uint256){
        require(history[tokenId]>0,"Not exist.");
        Stake storage stake = stakes[history[tokenId]];
        return (stake.user, stake.tokenId, stake.since, stake.claimeAfter, stake.reward, stake.unstaked);
    }
    function getStakeData(address staker) public view returns(Stake[] memory){
        return stake_holders[staker];
    }
    function getTotalStaked() public view returns(uint256){
        return stakes.length-1;
    }


    function getTokenBalance() public view returns(uint256){
        return IERC20(TokenContract).balanceOf(address(this));
    }



    //only owner
    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner!= address(0),"This address is not valid");
        _owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
    
    function withdrawETH() public onlyOwner { 
        (bool os, ) = payable(_owner).call{value: address(this).balance}("");
        require(os,"Tx not success");
    }
    function withdrawToken() public onlyOwner { 
        IERC20(TokenContract).transfer(_owner,getTokenBalance());
    }

    function changeTokenContract(address tokenContract) public onlyOwner {
        TokenContract = tokenContract;
    }
    
    function changeNFTContract(address NftContract) public onlyOwner {
        NFTContract = NftContract;
    }

    function setBKDPrice(uint256 _fee) public onlyOwner { 
        BKDPrice = _fee; 
    }
    function setstakingPrice(uint256 _fee) public onlyOwner { 
        stakingPrice = _fee; 
    }
}