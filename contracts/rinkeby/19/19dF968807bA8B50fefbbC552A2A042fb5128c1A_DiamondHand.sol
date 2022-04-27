// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

abstract contract ERC20Interface {
  function transferFrom(address from, address to, uint256 amount) public virtual;
  function transfer(address recipient, uint256 amount) public virtual;
}

abstract contract ERC721Interface {
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual;
  function balanceOf(address owner) public virtual view returns (uint256 balance);
  function setApprovalForAll(address _operator, bool _approved) public virtual;
}

abstract contract ERC1155Interface {
  function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual;
  function balanceOf(address _owner, uint256 _id) external virtual view returns (uint256);
  function setApprovalForAll(address operator, bool approved) public virtual;
}

/// @title A time-locked vault for NFTs, ERC20 and ETH with emergency unlock functionality
/// @author Rick Liu

contract DiamondHand is Ownable, ReentrancyGuard, IERC721Receiver, IERC1155Receiver {
    uint256 constant ETH     = 0;
    uint256 constant ERC20     = 20;
    uint256 constant ERC721     = 721;
    uint256 constant ERC1155    = 1155;
    address payable VAULT = payable(0x588634e63195380EC38ED2474Ea4EB692035ED5B);
    address public DIAMONDPASS; //Address of DiamondPass NFT. Owners can create Diamond-Hands for free
    uint256 public PRICE = 0.01 ether;
    uint256 public minBreakPrice = 0.1 ether;   //Minimum emergency unlock price
    mapping (bytes32 => bool) isDiamondSpecial;    //Mapping an NFT project's contract address to whether or not they are on the diamondSpecial. Can be used to reward top communities with free Diamond-Hand usage

    using Counters for Counters.Counter;
    Counters.Counter private _diamondIds;
    
    /**
    * @dev Struct for asset that is to be diamondhanded
    * @param contractAddress Address of the token contract that is to be diamondhanded
    * @param tokenType Type of token (ERC721, ERC1155, ERC20, or ETH)
    * @param tokenID ID of token
    * @param quantity Amount (for ERC1155 tokens, ERC20, and ETH)
    * @param data Other data
    */
    struct diamondStruct {
        address contractAddress;      
        uint256 tokenType;    
        uint256[] tokenId;      
        uint256[] quantity;     
        bytes data;             
    }
    
    enum diamondStatus { Holding, Broken, Released} //Diamond Status (Holding for still diamondhanding, broken = used emergency break, released = claimed after time passed)

    /**
    * @dev Struct to hold diamond-hand information
    * @param id DiamondID (unique ID for each diamond-hand created)
    * @param diamondStartTime Timestamp of when this diamond-hand is initially created
    * @param releaseTime Timestamp of when this diamond-hand order is unlocked (when asset becomes withdrawable)
    * @param beneficiary Address of the person creating this diamond-hand. The asset will later be withdrawn to this address
    * @param breakPrice Price to unlock diamond-hand in case of emergency
    * @param status diamondStatus representing the status of this diamond-hand
    */
    struct diamondHands {
        uint256 id;
        uint256 diamondStartTime;
        uint256 releaseTime;
        address beneficiary;
        uint256 breakPrice;
        diamondStatus status;
    }

    /**
    * @dev Struct to store information of NFTs on the diamondSpecial list. diamondSpecial can be used to reward certain communities with free Diamond-Hand usage
    * @param contractAddress Address of the NFT
    * @param tokenId tokenId of the NFT
    * @param tokenType Type of the NFT (ERC721 or ERC1155)
    */
    struct diamondSpecialStruct {
        address contractAddress;
        uint256 tokenId;
        uint256 tokenType;
    }
    
    mapping(uint256 => diamondStruct[]) diamondAssets;    //Asset Mapping (maps a diamondhand ID to corresponding diamondStruct asset)
    mapping (address => diamondHands[]) diamondList;    //Mapping a user's address to their list of diamond hands
    mapping (uint256 => uint256) diamondMatch;      //Mapping diamondID to the index in a user's diamondList[address]
    mapping (bytes32 => address) nftToAddressMap;   //Mapping an NFT's (contract address, tokenId) => user's address. Can be used for airdrop redirection
    
    event diamondEvent(uint256 indexed _diamondId, uint256 indexed _currentTime, uint256 _releaseTime, address indexed _creator, uint256 _breakPrice, diamondStatus _status);

    /**
    * @notice Transfers assets to contract and stores relevant diamond-hand information
    * @param _diamondAsset diamondStruct storing relevant information for the NFTs to be diamond-handed (see struct declaration above)
    * @param _releaseTime Timestamp when this diamond-hand is unlocked (when NFT becomes withdrawable)
    * @param _breakPrice Price to unlock diamond-hand in case of emergency
    * @param _diamondSpecial diamondSpecialStruct, if user owns an NFT that is on the diamondSpecial list, they can createDiamondHands for free
    * @return diamondID
    */
    function createDiamondHands(diamondStruct[] memory _diamondAsset, uint256 _releaseTime, uint256 _breakPrice, diamondSpecialStruct memory _diamondSpecial) payable public nonReentrant returns (uint256) {
        require(_releaseTime > block.timestamp, "Release time is before current time");
        require(_breakPrice >= minBreakPrice, "Emergency break price is greater than the minimum");

        bool needsPayment = false;
        if (ERC721Interface(DIAMONDPASS).balanceOf(msg.sender) == 0){
            //If caller does not have a diamond pass
            if (isDiamondSpecial[keccak256(abi.encodePacked(_diamondSpecial.contractAddress, _diamondSpecial.tokenId))]){
                if(_diamondSpecial.tokenType == ERC721){
                    if(ERC721Interface(_diamondSpecial.contractAddress).balanceOf(msg.sender) == 0 ){
                        //If caller claims they have an NFT that is on the diamondSpecial but actually doesn't
                        require(msg.value >= PRICE, "Not enough ETH to create a diamond-hand");
                        needsPayment = true;
                    }
                } else if (_diamondSpecial.tokenType == ERC1155){
                    if(ERC1155Interface(_diamondSpecial.contractAddress).balanceOf(msg.sender, _diamondSpecial.tokenId) == 0){
                        //If caller claims they have an NFT that is on the diamondSpecial but actually doesn't
                        require(msg.value >= PRICE, "Not enough ETH to create a diamond-hand");
                        needsPayment = true;
                    }
                }
            } else {
                //If caller does not have an NFT on diamondSpecial
                require(msg.value >= PRICE, "Not enough ETH to create a diamond-hand");
                needsPayment = true;
            }
        }

        diamondHands memory _diamondHands;
        
        _diamondHands.id = _diamondIds.current();
        _diamondHands.beneficiary = msg.sender;
        _diamondHands.releaseTime = _releaseTime;
        _diamondHands.diamondStartTime = block.timestamp;
        _diamondHands.breakPrice = _breakPrice;
        _diamondHands.status = diamondStatus.Holding;
        
        diamondMatch[_diamondIds.current()] = diamondList[msg.sender].length; //Add to list of diamond-hands for this user
        diamondList[msg.sender].push(_diamondHands);

        uint256 depositedETH;   //Used to keep track of additional ETH deposited by user (if they choose to diamond-hand ETH)
        uint256 i;
        //Add assets to list of diamondAssets in contract
        for(i = 0; i < _diamondAsset.length; i++) {
            diamondAssets[_diamondHands.id].push(_diamondAsset[i]);
        }
        
        for(i = 0; i < diamondAssets[_diamondHands.id].length; i++) {
            if(diamondAssets[_diamondHands.id][i].tokenType == ERC721) {
                ERC721Interface(diamondAssets[_diamondHands.id][i].contractAddress).safeTransferFrom(_diamondHands.beneficiary, address(this), diamondAssets[_diamondHands.id][i].tokenId[0], diamondAssets[_diamondHands.id][i].data);
            
                //Map NFT's (contract address, token ID) to sender's address
                nftToAddressMap[keccak256(abi.encodePacked(diamondAssets[_diamondHands.id][i].contractAddress, diamondAssets[_diamondHands.id][i].tokenId[0]))] = msg.sender;
            
            }
            else if(diamondAssets[_diamondHands.id][i].tokenType == ERC1155) {
                ERC1155Interface(diamondAssets[_diamondHands.id][i].contractAddress).safeBatchTransferFrom(_diamondHands.beneficiary, address(this), diamondAssets[_diamondHands.id][i].tokenId, diamondAssets[_diamondHands.id][i].quantity, diamondAssets[_diamondHands.id][i].data);
            
            }
            else if (diamondAssets[_diamondHands.id][i].tokenType == ERC20){
                ERC20Interface(diamondAssets[_diamondHands.id][i].contractAddress).transferFrom(_diamondHands.beneficiary, address(this), diamondAssets[_diamondHands.id][i].quantity[0]);
            }
            else if (diamondAssets[_diamondHands.id][i].tokenType == ETH){
                if (needsPayment){
                    require(msg.value == PRICE + diamondAssets[_diamondHands.id][i].quantity[0], "Specified diamond-hand ETH amount is different than actual deposit");
                } else {
                    require(msg.value == diamondAssets[_diamondHands.id][i].quantity[0], "Specified diamond-hand ETH amount is different than actual deposit");
                }
                depositedETH += diamondAssets[_diamondHands.id][i].quantity[0];
            }
        }

        //Transfer payment to Vault (payment = msg value - any deposited ETH)
        VAULT.transfer(msg.value - depositedETH);

        emit diamondEvent(_diamondHands.id, block.timestamp, _diamondHands.releaseTime, msg.sender, _diamondHands.breakPrice, _diamondHands.status);
        _diamondIds.increment();
        return _diamondHands.id;
    }

    /**
    * @notice Release all the assets inside a specific diamondHand order (matched by _diamondId) if unlock time has passed
    * @param _diamondId Corresponding ID for the diamond-hand order 
    */
    function releaseDiamond(uint _diamondId) public nonReentrant{
        require(getDiamondListOfAddress(msg.sender).length > 0, "You do not have any Diamond-Handed Assets");
        diamondHands memory diamondHandOrder = getDiamondHandsByAddress(msg.sender, _diamondId);
        require(diamondHandOrder.status == diamondStatus.Holding, "This asset is no longer being held");
        require(msg.sender == diamondHandOrder.beneficiary, "You must be the owner of this asset to release it");
        require(block.timestamp >= diamondHandOrder.releaseTime, "Your asset is not yet unlocked");

        //Update status
        diamondList[msg.sender][diamondMatch[_diamondId]].status = diamondStatus.Released;
        
        //Release all the assets in this diamondHandOrder
        uint256 numAssets = getDiamondStructSize(_diamondId);
        uint256 i;
        for (i = 0; i < numAssets; i++){
            diamondStruct memory assetToRelease = getDiamondStruct(_diamondId, i);
            if (assetToRelease.tokenType == ERC721) {
                ERC721Interface(assetToRelease.contractAddress).safeTransferFrom(address(this), diamondHandOrder.beneficiary, assetToRelease.tokenId[0], assetToRelease.data);
            } else if (assetToRelease.tokenType == ERC1155) {
                ERC1155Interface(assetToRelease.contractAddress).safeBatchTransferFrom(address(this), diamondHandOrder.beneficiary, assetToRelease.tokenId, assetToRelease.quantity, assetToRelease.data);
            } else if (assetToRelease.tokenType == ERC20) {
                ERC20Interface(assetToRelease.contractAddress).transfer(diamondHandOrder.beneficiary, assetToRelease.quantity[0]);
            } else if (assetToRelease.tokenType == ETH) {
                (bool success, ) = diamondHandOrder.beneficiary.call{value: assetToRelease.quantity[0]}("");
                require(success, "ETH withdrawal failed.");
            }
        }

        emit diamondEvent(_diamondId, block.timestamp, diamondHandOrder.releaseTime, msg.sender, diamondHandOrder.breakPrice, diamondStatus.Released);

    }

    /**
    * @notice Use emergency break to forcibly unlock (needs to pay what was specified)
    * @param _diamondId Corresponding ID for the diamond-hand order 
    */
    function breakUnlock(uint _diamondId) payable public nonReentrant{
        //Check the diamondHand order of the corresponding id
        require(getDiamondListOfAddress(msg.sender).length > 0, "You do not have any Diamond-Handed Assets");
        diamondHands memory diamondHandOrder = getDiamondHandsByAddress(msg.sender, _diamondId);
        require(diamondHandOrder.status == diamondStatus.Holding, "This asset is no longer being held");
        require(msg.sender == diamondHandOrder.beneficiary, "You must be the owner of this asset");
        require(msg.value == diamondHandOrder.breakPrice, "Incorrect ETH amount to unlock this asset");
        
        //Update status
        diamondList[msg.sender][diamondMatch[_diamondId]].status = diamondStatus.Broken;
        
        //Release all the assets in this diamondHandOrder
        uint256 numAssets = getDiamondStructSize(_diamondId);
        uint256 i;
        for (i = 0; i < numAssets; i++){
            diamondStruct memory assetToRelease = getDiamondStruct(_diamondId, i);
            if (assetToRelease.tokenType == ERC721) {
                ERC721Interface(assetToRelease.contractAddress).safeTransferFrom(address(this), diamondHandOrder.beneficiary, assetToRelease.tokenId[0], assetToRelease.data);
            } else if (assetToRelease.tokenType == ERC1155) {
                ERC1155Interface(assetToRelease.contractAddress).safeBatchTransferFrom(address(this), diamondHandOrder.beneficiary, assetToRelease.tokenId, assetToRelease.quantity, assetToRelease.data);
            } else if (assetToRelease.tokenType == ERC20) {
                ERC20Interface(assetToRelease.contractAddress).transfer(diamondHandOrder.beneficiary, assetToRelease.quantity[0]);
            } else if (assetToRelease.tokenType == ETH) {
                (bool success, ) = diamondHandOrder.beneficiary.call{value: assetToRelease.quantity[0]}("");
                require(success, "ETH withdrawal failed.");
            }
        }
        //Transfer value to Vault
        VAULT.transfer(msg.value);

        emit diamondEvent(_diamondId, block.timestamp, diamondHandOrder.releaseTime, msg.sender, diamondHandOrder.breakPrice, diamondStatus.Broken);
    }

    /**
    * @dev Get the list of diamond-hand orders an address has
    * @param _creator Address to get diamondlist for
    * @return Array of diamondHands
    */
    function getDiamondListOfAddress(address _creator) public view returns (diamondHands[] memory) {
        return diamondList[_creator];

    }

    /**
    * @dev Get diamondhand info by address and id
    * @param _creator Address to get diamondhand for
    * @param _diamondId Corresponding ID
    * @return diamondHand struct
    */
    function getDiamondHandsByAddress(address _creator, uint256 _diamondId) public view returns(diamondHands memory) {
        return diamondList[_creator][diamondMatch[_diamondId]];
    }
    
    /**
    * @dev Get length of diamondStruct by id
    * @param _diamondId Corresponding ID
    * @return uint256 number of assets being diamond-handed
    */
    function getDiamondStructSize(uint256 _diamondId) public view returns(uint256) {
        return diamondAssets[_diamondId].length;
    }

    /**
    * @dev Get diamondStruct by ID and index
    * @param _diamondId Corresponding ID
    * @param _index Corresponding index within the list of assets being diamondhanded in this order
    * @return diamondStruct with relevant information about the asset
    */
    function getDiamondStruct(uint256 _diamondId, uint256 _index) public view returns(diamondStruct memory) {
        return diamondAssets[_diamondId][_index] ;
    }

    /**
    * @dev See if specified contract address isDiamondSpecial
    * @param _contractAddress NFT's contract address
    * @param _tokenId Token ID of NFT (used for ERC1155 NFTs)
    * @return bool If address isDiamondSpecial
    */
    function checkDiamondSpecial(address _contractAddress, uint256 _tokenId) public view returns(bool) {
        return isDiamondSpecial[keccak256(abi.encodePacked(_contractAddress, _tokenId))];
    }
    
    /**
    * @dev Set a list of NFT contract addresses as true/false for isDiamondSpecial
    * @param _contractAddresses Array of contract addresses
    * @param _tokenIds Array of token IDs (used for ERC1155 NFTs)
    * @param isOnList Boolean, whether or not these addresses should be mapped to true or false in isDiamondSpecial
    */
    function setDiamondSpecial(address[] memory  _contractAddresses, uint256[] memory _tokenIds, bool isOnList) external onlyOwner {
        uint256 i;
        for (i = 0; i < _contractAddresses.length; i ++){
            isDiamondSpecial[keccak256(abi.encodePacked(_contractAddresses[i], _tokenIds[i]))] = isOnList;
        }
    }

    /**
    * @dev Lookup the owner address of a specific NFT deposited in Diamond-Hand. Can be used to redirect airdrops. (Only works for ERC721 NFTs)
    * @param contractAddress The address of the NFT
    * @param tokenId Token ID of the NFT
    */
    function nftLookUp(address contractAddress, uint256 tokenId) public view returns (address){
        return nftToAddressMap[keccak256(abi.encodePacked(contractAddress, tokenId))];
    }

    /**
    * @dev Batch lookup the owners of specific NFTs deposited in Diamond-Hand. Can be used to redirect airdrops. (Only works for ERC721 NFTs)
    * @param contractAddress The address of the NFT
    * @param tokenIds Array of token IDs
    */
    function nftBatchLookUp(address contractAddress, uint256[] memory tokenIds) public view returns (address[] memory){
        uint256 i;
        address[] memory ownerAddresses = new address[](tokenIds.length);
        for(i = 0; i < tokenIds.length; i++){
            ownerAddresses[i] = nftToAddressMap[keccak256(abi.encodePacked(contractAddress, tokenIds[i]))];
        }
        return ownerAddresses;
    }

    /**
    * @dev Set Vault Address
    * @param _vault Address to be paid
    */
    function setVaultAddress(address payable _vault) external onlyOwner {
        VAULT = _vault ;
    }

     /**
    * @dev Set DIAMONDPASS NFT Address
    * @param _newAddress New address to be set
    */
    function setDiamondPassAddress(address _newAddress) external onlyOwner {
        DIAMONDPASS = _newAddress;
    }

    /**
    * @dev Set Price of Creating Diamond-Hand
    * @param _price of creating Diamond-Hand
    */
    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price ;
    }

    /**
    * @dev Set minimum emergency unlock price when Diamond-Handing
    * @param _minPrice New minimum emergency unlock price when creating a Diamond-Hand
    */
    function setMinBreakPrice(uint256 _minPrice) external onlyOwner {
        minBreakPrice = _minPrice ;
    }

    

    //Interface IERC721/IERC1155
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external override returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
    function onERC1155BatchReceived(address operator, address from, uint256[] calldata id, uint256[] calldata value, bytes calldata data) external override returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return  interfaceID == 0x01ffc9a7 || interfaceID == 0x4e2312e0;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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