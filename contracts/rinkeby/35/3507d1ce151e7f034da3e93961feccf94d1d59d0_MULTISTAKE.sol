/**
 *Submitted for verification at Etherscan.io on 2022-06-18
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
}

contract ERC20 {
    function totalSupply() external view returns (uint256){}
    function balanceOf(address account) external view returns (uint256){}
    function transfer(address recipient, uint256 amount) external returns (bool){}
    function allowance(address owner, address spender) external view returns (uint256){}
    function approve(address spender, uint256 amount) external returns (bool){}
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool){}
    
    //proxy access functions:
    function proxyMint(address reciever, uint256 amount) public {}
    function proxyBurn(address sender, uint256 amount) public {}
    function proxyTransfer(address from, address to, uint256 amount) public {}
}


contract MULTISTAKE is Proxy {
    ERC20 ANONCOIN;  // $Anon reward coin for keyholders and partners

    string public name;
    uint256 public partnerReward;
    uint256 public degenReward;

    uint256 private DAY = 86400;
    //uint256 private DAY = 60; // for testing purposes only
    
    //Tracking Staked Tokens

    struct stakedToken{  //each staked token makes up a contract/token pair
        address contractAddress;
        uint256 tokenId;
        uint256 timestamp;
    }

    mapping (address => stakedToken[]) stakeWallets; //wallet address mapped to a dynamic array of staked tokens

    //Mappings that verify which contracts are approved.
    mapping (address => bool) degenContracts;
    mapping (address => bool) partnerContracts;

    mapping (uint256 => uint256) timestamp;

    constructor() {
    	name = "Anon Multi-NFT Staking Contract";
    	ANONCOIN = ERC20(0xc5010c11fD899A55ba0aC003b4B159032fb93DA7);  //UPDATE THIS BEFORE DEPLOYMENT
    	partnerReward = 100 * (10 ** 15);
        degenReward = 10 * (10 ** 15);
    }

    function stakeMultiple(address contAddy, uint256[] memory tokenIds) public {
        for (uint256 i; i < tokenIds.length; i++){
            stakeNFT(contAddy, tokenIds[i]);
        }
    }

    function stakeMixed(address[] memory contAddy, uint256[] memory tokenIds) public {
        require(contAddy.length == tokenIds.length, "array length mismatch");
        for (uint256 i; i < tokenIds.length; i++){
            stakeNFT(contAddy[i], tokenIds[i]);
        }
    }

    function stakeNFT(address contAddy, uint256 tokenId) public {
        ERC721 StakeNFT = ERC721(contAddy);

        //verify contAddy is valid for our staking protocol
        require((degenContracts[contAddy] == true) || (partnerContracts[contAddy] == true), "NFT not approved");
        require(StakeNFT.ownerOf(tokenId) == _msgSender(), "Token Owner Invalid");

        //Add token to user wallet
        stakeWallets[_msgSender()].push( stakedToken( contAddy, tokenId, block.timestamp ) );
        
        StakeNFT.transferFrom(_msgSender(), address(this), tokenId);
    }

    function unstakeNFT(address contAddy, uint256 tokenId) public {
        ERC721 StakeNFT = ERC721(contAddy);

        uint256 numTokens = stakeWallets[_msgSender()].length;
        for (uint256 i; i < numTokens; i++){
            if (stakeWallets[_msgSender()][i].contractAddress == contAddy){
                if(stakeWallets[_msgSender()][i].tokenId ==tokenId){
                    StakeNFT.transferFrom(address(this), _msgSender(), tokenId);
                    _removeFromStaker(i);
                    break;
                }
            }
        }
    }

    function unstakeFromContract(address contAddy) public {
        uint256 numTokens = stakeWallets[_msgSender()].length;
        uint256[] memory storeIndex;
        ERC721 StakeNFT = ERC721(contAddy);

        for (uint256 i; i < numTokens; i++){
            if (stakeWallets[_msgSender()][i].contractAddress == contAddy){
                StakeNFT.transferFrom(address(this), _msgSender(), stakeWallets[_msgSender()][storeIndex[i]].tokenId);
                _removeFromStaker(storeIndex[i]);
                i--;
                numTokens--;
            }
        }
    }

    function unstakeAll() public {
        uint256 numTokens = stakeWallets[_msgSender()].length;

        for (uint256 i = (numTokens - 1); i >= 0; i--){
            ERC721 StakeNFT = ERC721(stakeWallets[_msgSender()][i].contractAddress);
            StakeNFT.transferFrom(address(this), _msgSender(), stakeWallets[_msgSender()][i].tokenId);
            stakeWallets[_msgSender()].pop();
        }
    }

    function _removeFromStaker(uint256 index) internal {
        uint256 numTokens = stakeWallets[_msgSender()].length;
        if (index + 1 != numTokens){
            stakeWallets[_msgSender()][index] = stakeWallets[_msgSender()][numTokens - 1];
        }
        stakeWallets[_msgSender()].pop();
    }

    function viewStakeWallet(address staker) public view returns (stakedToken[] memory){
        return stakeWallets[staker];
    }

    ///////////////// REWARDS /////////////////////////
    
    function setCOINcontract(address newContract) public onlyOwner {
    	ANONCOIN = ERC20(newContract);
    }
    
    function proxyRewards(address staker) external proxyAccess {
        _sendRewards(staker);
    }

    function _sendRewards(address staker) internal {
        //Accessible from the primary staking contract
        uint256 numTokens = stakeWallets[staker].length;
        uint256 rewardTokens = 0;

        for ( uint256 i; i < numTokens; i++ ){
            //calc time interval
            uint256 timeInterval = (block.timestamp - stakeWallets[staker][i].timestamp) / DAY;
            stakeWallets[staker][i].timestamp += timeInterval * DAY;

            if ( partnerContracts[ stakeWallets[staker][i].contractAddress ]){
                rewardTokens += partnerReward * timeInterval;
            } else {
                rewardTokens += degenReward * timeInterval;
            }
        }

        ANONCOIN.proxyMint(staker, rewardTokens);
    }

    function claimDegenPartnerRewards() external {
        _sendRewards(_msgSender());
    }

    function viewRewards(address staker) public view returns (uint256) {
        uint256 numTokens = stakeWallets[staker].length;
        uint256 rewardTokens = 0;

        for ( uint256 i; i < numTokens; i++ ){
            //calc time interval
            uint256 timeInterval = (block.timestamp - stakeWallets[staker][i].timestamp) / DAY;

            if ( partnerContracts[ stakeWallets[staker][i].contractAddress ]){
                rewardTokens += partnerReward * timeInterval;
            } else {
                rewardTokens += degenReward * timeInterval;
            }
        }

        return rewardTokens;
    }

    //////////////////// APPROVALS ////////////////////

    function approveDegen(address contractAddress) external onlyOwner {
        degenContracts[contractAddress] = true;
    }

    function revokeDegen(address contractAddress) external onlyOwner {
        degenContracts[contractAddress] = false;
    }

    function approvePartner(address contractAddress) external onlyOwner {
        partnerContracts[contractAddress] = true;
    }

    function revokePartner(address contractAddress) external onlyOwner {
        partnerContracts[contractAddress] = false;
    }

    /////////////////// CHANGE REWARD AMOUNTS ////////////////////
    
    function setDegenReward(uint256 newCoinsPerDay) public onlyOwner {
        degenReward = newCoinsPerDay;
    }
    
    function setPartnerReward(uint256 newCoinsPerDay) public onlyOwner {
        partnerReward = newCoinsPerDay;
    }
    
    ///////////////////////// OTHER /////////////////////////////////

    function proxies( address ) public view returns ( address ){
        return address(this);
    }

    receive() external payable {}
    
    fallback() external payable {}
}