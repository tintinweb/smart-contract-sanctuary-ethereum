// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract rfacStaking{
    mapping(address => IERC20) public rewardToken;
    mapping(address => address) public tokenOwner;
    mapping(address => bool) public tokenState;
    address public stakingToken;
    uint256 public stakePrice;
    bool public paused;

    IERC721 public rfacNFT;
    address payable public owner;

    uint256 public rate; //$CHIPs per card per day
    mapping(uint256 => uint256) rewardTable; //Bonus tokens for each pokerHand, per day

    struct TokenData {
        uint256[] tokenIDs;
        uint256[] values;
        uint256[] suits;
        uint256 pokerHand;
    }

    struct Stake {
        uint256[] tokenIDs; //list of tokens in the hand
        uint256 timestamp;  //time staked
        uint256 pokerHand;  //value of the hand staked
    }

    mapping(address => Stake[]) public stakes;

    mapping(address => uint256) public bank;
    uint256 merkleRoot;
    mapping(uint256 => uint8) public proofBurn;

    event transferredRewardToBank(address _from, uint256 amt);
    event cashedOutFromBank(address _from, address _tokenAddress, uint256 amt);
    event cashedOutFromStaking(address _from, uint256 amt);
    event depositedToBank(address _from, address _tokenAddress, uint256 amt);
    event staked(address _from, uint256[] _tokenIDs);
    event unstaked(address _from, uint256[] _tokenIDs);

    constructor(){
        //rewardToken = IERC20(_tokenAddress);
        //rfacNFT = IERC721(_NFTAddress);
        paused = false;
        stakePrice = 0.005 ether;
        rate = 5;
        owner = payable(msg.sender);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory) public pure returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function stake(TokenData[] calldata _tokenData) external payable{
        require(!paused,"Staking is paused");
        require(msg.value == stakePrice*_tokenData.length,"Insufficient Funds");

        for(uint256 n = 0;n < _tokenData.length;n++){
            require(_tokenData[n].tokenIDs.length < 6, "Too many cards.");
            require(checkHand(_tokenData[n]),"Pokerhand Doesn't Match");

            for (uint256 i = 0; i < _tokenData[n].tokenIDs.length; i++) {
                rfacNFT.safeTransferFrom(msg.sender, address(this), _tokenData[n].tokenIDs[i],"0x00");
            }
            stakes[msg.sender].push(Stake(_tokenData[n].tokenIDs,block.timestamp,_tokenData[n].pokerHand));
            emit staked(msg.sender, _tokenData[n].tokenIDs);
        }
        
    }

    function unstake(uint8[] calldata hands) external{
        require(!paused,"Staking is paused");
        cashOutFromStaking(hands);
        for(uint256 n = 0;n < hands.length;n++){
            for (uint256 i = 0; i < stakes[msg.sender][hands[n]].tokenIDs.length; i++) {
                rfacNFT.safeTransferFrom(address(this),msg.sender, stakes[msg.sender][hands[n]].tokenIDs[i],"0x00");
            }
            emit unstaked(msg.sender, stakes[msg.sender][hands[n]].tokenIDs);
            removeStakedHand(hands[n]);
        }
        
    }

    function checkHand(TokenData calldata _tokenData) internal pure returns (bool){

        if(_tokenData.pokerHand == 0){
            //Royal Flush
            if(checkFlush(_tokenData) && _tokenData.tokenIDs.length == 5){
                if(_tokenData.values[0] == 1 && _tokenData.values[1] == 13 && _tokenData.values[2] == 12 && _tokenData.values[3] == 11 && _tokenData.values[4] == 10){
                    return true;
                }else{
                    return false;
                }
            }else{
                return false;
            }
        }else if(_tokenData.pokerHand == 1){
            //Straight Flush
            if(checkFlush(_tokenData) && _tokenData.tokenIDs.length == 5){
                if(_tokenData.values[1] == _tokenData.values[0] - 1 && _tokenData.values[2] == _tokenData.values[0] - 2 && _tokenData.values[3] == _tokenData.values[0] - 3 && _tokenData.values[4] == _tokenData.values[0] - 4){
                    return true;
                }else{
                    return false;
                }
            }else{
                return false;
            }

        }else if(_tokenData.pokerHand == 2){
            //Four of a Kind
            if(_tokenData.tokenIDs.length > 3){
                if(_tokenData.values[1] == _tokenData.values[0] && _tokenData.values[2] == _tokenData.values[0] && _tokenData.values[3] == _tokenData.values[0]){
                    if((_tokenData.suits[0]+_tokenData.suits[1]+_tokenData.suits[2]+_tokenData.suits[3]) == 10 && (_tokenData.suits[0]*_tokenData.suits[1]*_tokenData.suits[2]*_tokenData.suits[3]) == 24){
                        return true;
                    }else{
                        return false;
                    }                        
                }else{
                    return false;
                }
            }else{
                return false;
            }
        }
        else if(_tokenData.pokerHand == 3){
            //Full House
            if(_tokenData.tokenIDs.length == 5){
                if(_tokenData.values[1] == _tokenData.values[0] && _tokenData.values[2] == _tokenData.values[0] && _tokenData.values[3] == _tokenData.values[4]){
                    if(_tokenData.suits[0] != _tokenData.suits[1] && _tokenData.suits[1] != _tokenData.suits[2] && _tokenData.suits[0] != _tokenData.suits[2] && _tokenData.suits[3] != _tokenData.suits[4]){
                        return true;
                    }else{
                        return false;
                    }                        
                }else{
                    return false;
                }
            }else{
                return false;
            }
        }
        else if(_tokenData.pokerHand == 4){
            //Flush
            if(checkFlush(_tokenData) && _tokenData.tokenIDs.length == 5){
                return true;
            }else{
                return false;
            }
        }
        else if(_tokenData.pokerHand == 5){
            //Straight
            if(_tokenData.tokenIDs.length == 5){
                if(_tokenData.values[0] == 1){
                    if(_tokenData.values[1] == 13 && _tokenData.values[2] == 12 && _tokenData.values[3] == 11 && _tokenData.values[4] == 10){
                        return true;
                    }else{
                        return false;
                    }
                }else{
                    if(_tokenData.values[1] == _tokenData.values[0] - 1 && _tokenData.values[2] == _tokenData.values[0] - 2 && _tokenData.values[3] == _tokenData.values[0] - 3 && _tokenData.values[4] == _tokenData.values[0] - 4){
                        return true;
                    }else{
                        return false;
                    }
                }
                
            }else{
                return false;
            }

        }
        else if(_tokenData.pokerHand == 6){
            //Three of a Kind
            if(_tokenData.tokenIDs.length > 2){
                if(_tokenData.values[1] == _tokenData.values[0] && _tokenData.values[2] == _tokenData.values[0]){
                    if(_tokenData.suits[0] != _tokenData.suits[1] && _tokenData.suits[1] != _tokenData.suits[2] && _tokenData.suits[0] != _tokenData.suits[2]){
                        return true;
                    }else{
                        return false;
                    }                        
                }else{
                    return false;
                }
            }else{
                return false;
            }

        }else if(_tokenData.pokerHand == 7){
            //Two Pair
            if(_tokenData.tokenIDs.length > 3){
                if(_tokenData.values[1] == _tokenData.values[0] && _tokenData.values[2] == _tokenData.values[3]){
                    if(_tokenData.suits[0] != _tokenData.suits[1] && _tokenData.suits[2] != _tokenData.suits[3]){
                        return true;
                    }else{
                        return false;
                    }                        
                }else{
                    return false;
                }
            }else{
                return false;
            }

        }
        else if(_tokenData.pokerHand == 8){
            //One Pair
            if(_tokenData.tokenIDs.length > 1){
                if(_tokenData.values[1] == _tokenData.values[0] && _tokenData.suits[0] != _tokenData.suits[1]){
                    return true;                     
                }else{
                    return false;
                }
            }else{
                return false;
            }
        }else{
            //High Card
            return true;
        }
    }

    function checkFlush(TokenData calldata _tokenData) internal pure returns (bool){
        uint256 flush;
        for (uint256 i = 0; i < _tokenData.tokenIDs.length; i++) {
            if(i == 0){
                flush = _tokenData.suits[i];
            }else if(flush != _tokenData.suits[i]){
                return false;
            }
        }
        return true;
    }

    function getStaked(address staker) external view returns(Stake [] memory){
        //require(hand < stakes[staker].length,"Staked Hand DNE");
            
        return (stakes[staker]);
    }

    function getReward(address staker, uint256 hand) public view returns(uint256){
        uint256 nDays = ((block.timestamp - stakes[staker][hand].timestamp) - (block.timestamp - stakes[staker][hand].timestamp) % 1440)/1440;
        return (rate*stakes[staker][hand].tokenIDs.length+ rewardTable[stakes[staker][hand].pokerHand])*nDays;
    }

    //Banking

    function depositToken(address _tokenAddress, uint256 _deposit) external{
        require(!paused,"Contract is paused");
        require(rewardToken[_tokenAddress].transferFrom(msg.sender, address(this), _deposit), "Error with token transfer");
        bank[_tokenAddress] += _deposit;
        emit depositedToBank(msg.sender, _tokenAddress, _deposit);
    }

    function getBankBalance(address _tokenAddress) external view returns(uint256){
        return(bank[_tokenAddress]);
    }

    function cashOutFromStaking(uint8[] calldata hands) public{
        require(!paused,"Contract is paused");
        uint256 reward = 1;
        for(uint256 i = 0;i< hands.length;i++){
            reward += getReward(msg.sender,i);
            stakes[msg.sender][i].timestamp = block.timestamp;
        }
        require(rewardToken[stakingToken].transferFrom(address(this),msg.sender, reward-1), "Error with token transfer");
        bank[stakingToken] -= reward-1;
        emit cashedOutFromStaking(msg.sender, reward);
    }

    function cashOutFromBank(uint _value, uint[] calldata _proof, address _tokenAddress, uint256 amt) external{
        require(!paused,"Contract is paused");
        require(proofBurn[_value] == 0,"Proof Already Used");
        require(verifyProof( _value, _proof),"Invalid Proof");
        require(tokenState[_tokenAddress],"Token Withdrawls not permitted, Contact Token Owner");
        require(rewardToken[_tokenAddress].transferFrom(address(this),msg.sender, amt), "Error with token transfer");
        bank[_tokenAddress] -= amt;
        proofBurn[_value] = 1;
        emit cashedOutFromBank(msg.sender, _tokenAddress, amt);
    }

    function transferRewardToBank(uint8[] calldata hands) external{
        require(!paused,"Contract is paused");
        uint256 reward = 1;
        for(uint256 i = 0;i< hands.length;i++){
            reward += getReward(msg.sender,i);
            stakes[msg.sender][i].timestamp = block.timestamp;
        }
        reward -= 1;
        emit transferredRewardToBank(msg.sender, reward);
    }

    //only owner
    modifier onlyOwner(){
        require(msg.sender == owner,"not owner");
        _;
    }


    function setTokenAddress(address _tokenAddress, address _tokenOwner) external onlyOwner {
        rewardToken[_tokenAddress] = IERC20(_tokenAddress);
        if(tokenOwner[_tokenAddress] == address(0)){
            tokenOwner[_tokenAddress] = _tokenOwner;
        }
    }

    function setStakingToken(address _tokenAddress) external onlyOwner{
        stakingToken = _tokenAddress;
        rewardToken[_tokenAddress] = IERC20(_tokenAddress);
        if(tokenOwner[_tokenAddress] == address(0)){
            tokenOwner[_tokenAddress] = owner;
        }
    }

    function setNFTAddress(address _NFTAddress) external onlyOwner {
        rfacNFT = IERC721(_NFTAddress);
    }

    function setRewardTable(uint256[] calldata _rewardTable) external onlyOwner {
        for (uint256 i = 0; i < _rewardTable.length; i++) {
            rewardTable[i] = _rewardTable[i];
        }
    }

    function setRate(uint256 _rate) external onlyOwner {
        rate = _rate;
    }

    function togglePaused() external onlyOwner {
        paused = !paused;
    }

    function setStakePrice(uint256 _stakePrice) external onlyOwner {
        stakePrice = _stakePrice;
    }

    function removeStakedHand(uint hand) internal {
        require(hand < stakes[msg.sender].length);
        stakes[msg.sender][hand] = stakes[msg.sender][stakes[msg.sender].length-1];
        stakes[msg.sender].pop();
    }

    //Only Token Owner

    function setTokenState(address _tokenAddress, bool _state) external{
        require(msg.sender == tokenOwner[_tokenAddress],"not owner");
        tokenState[_tokenAddress] = _state;
    }

    function setTokenOwner(address _tokenAddress, address _newOwner) external{
        require(msg.sender == tokenOwner[_tokenAddress],"not owner");
        tokenOwner[_tokenAddress] = _newOwner;
    }

    function withdraw() external payable onlyOwner{
        uint amount = address(this).balance;

        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    //MERKLE STUFF
    function getRoot() public view returns (uint) {
      return merkleRoot;
    }

    function setRoot(uint _merkleRoot) external onlyOwner{
      merkleRoot = _merkleRoot;
    }   // setRoot

    function pairHash(uint _a, uint _b) internal pure returns(uint) {
      return uint(keccak256(abi.encode(_a ^ _b)));
    }

    function verifyProof(uint _value, uint[] calldata _proof) 
        public view returns (bool) {
      uint temp = _value;
      uint i;
  
      for(i=0; i<_proof.length; i++) {
        temp = pairHash(temp, _proof[i]);
      }

      return temp == merkleRoot;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}