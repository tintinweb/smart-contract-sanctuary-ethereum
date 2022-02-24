/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: GNU General Public License v3.0 (GNU GPLv3)
pragma solidity 0.8.12;

/**
 * @dev ERC721 Standard NFT interface
 */
interface ERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

/**
 * @dev ERC20 Standard Token interface
 */
interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract MetaBillionaireStaking {

    address private owner;

    mapping(address => uint256[]) public depositedTokenIds;
    mapping(uint256 => uint256) public depositCheckpoint;
    mapping(address => uint256) public claimedAmounts;

    ERC721 public immutable nft;
    ERC20 public immutable token;
    
    uint256 public immutable stakingEnd;
    uint256 public immutable stakingStart;
    
    uint256 public reward;
    uint256[] public rewardBoosts;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Constructor.
     * @param _nft Address of NFT ERC721 smart contract
     * @param _token Address of Token ERC20 smart contract
     * @param _stakingEnd Timestamp of staking end
     * @param _reward Total token given to stacked nft
     * @param _rewardBoosts Array of boosts
     */
    constructor(ERC721 _nft, ERC20 _token, uint256 _stakingEnd, uint256 _reward, uint256[] memory _rewardBoosts) {
        nft = _nft;
        token = _token;
        stakingEnd = _stakingEnd;
        stakingStart = block.timestamp;
        reward = _reward;
        rewardBoosts = _rewardBoosts;
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner.
     * @param newOwner address of new owner.
     */
    function changeOwner(address newOwner) public isOwner {
        owner = newOwner;
        emit OwnerSet(owner, newOwner);
    }

    /**
     * @dev Return owner address.
     * @return address of owner.
     */
    function getOwner() external view returns (address) {
        return owner;
    }

   /**
     * @dev Deposit tokens to smart contract.
     * @param _token address.
     * @param _amount of token.
     */
    function ownerDepositToken(address _token, uint256 _amount) public isOwner {
        ERC20(_token).transferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @dev Withdraw tokens of smart contract.
     * @param _token address.
     * @param _amount of token.
     */
    function ownerWithdrawToken(address _token, uint256 _amount) public isOwner {
        ERC20(_token).transfer(msg.sender, _amount);
    }

    /**
     * @dev Return the amount of tokens deposited to the `owner`.
     * @param _owner of a deposit.
     * @return The number of tokens
     */
    function depositedTokenAmounts(address _owner) public view returns(uint256) {
        return depositedTokenIds[_owner].length;
    }

    /**
     * @dev Returns the maximum number of tokens currently claimable by `owner`.
     * @param _owner address of a deposit.
     * @return The number of tokens currently claimable.
     */
    function claimableAmounts(address _owner) public view returns(uint256) {
        uint256 claimable = 0;
        uint256 depositedAmounts = depositedTokenAmounts(_owner);

        for (uint256 i = 0; i < depositedAmounts; i++) {
            claimable += ((reward * (block.timestamp - depositCheckpoint[depositedTokenIds[_owner][i]])) / stakingEnd);
        }

        return ((claimable * boost(depositedAmounts)) / 100) - claimedAmounts[_owner];
    }

    /**
     * @dev Returns a boost for token bag size.
     * @param _amount of stacked tokens.
     * @return The boost for token amount.
     */
    function boost(uint256 _amount) public view returns(uint256) {
        if(_amount > rewardBoosts.length){
            return rewardBoosts[rewardBoosts.length-1];
        } else {
            return rewardBoosts[_amount-1];
        }
    }

    /**
     * @dev Returns the tokenId of `_index` mapping.
     * @param _owner of stacked tokens.
     * @param _index of token.
     * @return The tokenId of index mapping.
     */
    function tokenIdByIndex(address _owner, uint256 _index) public view returns(uint256) {
        return depositedTokenIds[_owner][_index];
    }

    /**
     * @dev Returns the index of `_tokenId` for `_owner` mapping.
     * @param _owner of stacked tokens.
     * @param _tokenId of token.
     * @return The index of tokenId in mapping.
     */
    function indexByTokenId(address _owner, uint256 _tokenId) public view returns(uint256) {
        uint256 index;
        uint256 depositedAmounts = depositedTokenAmounts(_owner);

        for (uint256 i = 0; i < depositedAmounts; i++) {
            if(depositedTokenIds[_owner][i] == _tokenId){
                return i;
            }
        }
        return index;
    }

    /**
     * @dev Claim the earned claimable tokens.
     * @param _recipient of stacked tokens.
     */
    function claim(address _recipient) public {
        uint256 claimable = claimableAmounts(_recipient);
        claimedAmounts[_recipient] += claimable;
        require(token.transfer(_recipient, claimable), "Claim: Transfer failed");
    }

    /**
     * @dev Deposit `_tokenId` and set checkpoint for this tokenId.
     * @param _tokenId of nft.
     */
    function deposit(uint256 _tokenId) external {
        require(msg.sender == nft.ownerOf(_tokenId), "Deposit: Sender must be owner");
        nft.transferFrom(msg.sender, address(this), _tokenId);
        depositedTokenIds[msg.sender].push(_tokenId);
        depositCheckpoint[_tokenId] = block.timestamp;
    }

    /**
     * @dev Withdraw token by index.
     * @param _indexToken The token id to withdraw.
     */
    function withdraw(uint256 _indexToken) external {
        require(depositedTokenIds[msg.sender][_indexToken] != 0, "Withdraw: No tokens to withdarw");

        claim(msg.sender);

        uint256 tokenId = tokenIdByIndex(msg.sender, _indexToken);
        
        
        uint256 lastTokenId = depositedTokenIds[msg.sender][depositedTokenAmounts(msg.sender) - 1];
        
        delete depositCheckpoint[tokenId];
        depositedTokenIds[msg.sender][_indexToken] = lastTokenId;
        depositedTokenIds[msg.sender].pop();

        nft.transferFrom(address(this), msg.sender, tokenId);
    }
}