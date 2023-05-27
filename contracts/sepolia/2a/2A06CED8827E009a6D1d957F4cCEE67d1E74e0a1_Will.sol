// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error WillsAddressZeroError();
error WillsInsufficientAmountError();
error WillsInvalidReleaseDateError(uint releaseDate, uint blockTimeStamp);
error WillsNotTokenOwnerError(address owner, address caller);
error WillsGiftNotDueError(uint blockTimeStamp, uint releaseDate);
error WillsNotBeneficiaryError(address beneficiary, address caller);
error WillsGiftAlreadyReleasedError();
error WillsNotTestatorError(address testator, address caller);

contract Will is ReentrancyGuard {

    address public owner;

    struct EtherGift {
        address payable testator;
        address payable beneficiary;
        uint amount;
        uint256 releaseDate;
        bool released;
    }

    struct FungibleTokenGift {
        IERC20 tokenAddress;
        address testator;
        address beneficiary;
        uint amount;
        uint256 releaseDate;
        bool released;
    }

    struct NFTGift {
        IERC721 contractAddress;
        address testator;
        uint tokenId;
        address payable beneficiary;
        uint releaseDate;
        bool released;
    }

    mapping(address => mapping(address => EtherGift[])) public etherGifts;
    mapping(address => mapping(address => FungibleTokenGift[])) public tokenGifts;
    mapping(address => mapping(address => NFTGift[])) public nftGifts;

    mapping(address => address[]) public listOfBeneficiaries;

    event EtherGiftCreated(address indexed testator, address indexed beneficiary, uint amount, uint releaseDate);
    event FungibleTokenGiftCreated(address indexed testator, address indexed contractAddress, address indexed beneficiary, uint amount, uint releaseDate);
    event NFTGiftCreated(address indexed testator, address indexed contractAddress, address indexed beneficiary, uint tokenId, uint releaseDate);

    event EtherGiftCancelled(address indexed testator, address indexed beneficiary, uint amount, uint releaseDate);
    event FungibleTokenGiftCancelled(address indexed testator, address indexed contractAddress, address indexed beneficiary, uint amount, uint releaseDate);
    event NFTGiftCancelled(address indexed testator, address indexed contractAddress, address indexed beneficiary, uint tokenId, uint releaseDate);

    event GiftReleased(address indexed beneficiary, string giftType, uint giftIndex);

    receive() external payable {}

    constructor() {
        owner = msg.sender;
    }

    function createEtherGift(address payable _beneficiary, uint256 _amount, uint256 _releaseDate) public payable nonReentrant {
        if(_beneficiary == address(0)){
            revert WillsAddressZeroError();
        }
        if(_amount <= 0) {
            revert WillsInsufficientAmountError();
        }
        if(block.timestamp >= _releaseDate){
            revert WillsInvalidReleaseDateError(_releaseDate, block.timestamp);
        }
        payable(address(this)).transfer(_amount);
        EtherGift memory newEtherGift = EtherGift({
            testator: payable(msg.sender),
            beneficiary: _beneficiary,
            amount: _amount,
            releaseDate: _releaseDate,
            released: false
        });
        //Thinkered
        etherGifts[msg.sender][_beneficiary].push(newEtherGift);
        bool hasBeneficiary = false;
        for(uint i = 0 ; i < listOfBeneficiaries[msg.sender].length; i++){
            if(listOfBeneficiaries[msg.sender][i] == _beneficiary) {
                hasBeneficiary = true;
                break;
            }
        }
        if(!hasBeneficiary) {
            listOfBeneficiaries[msg.sender].push(_beneficiary);
        }
        emit EtherGiftCreated(msg.sender, _beneficiary, _amount, _releaseDate);
    }

    function releaseEther( uint _giftIndex, address _testator) public payable nonReentrant {
        //Thinkered
        EtherGift storage gift = etherGifts[_testator][msg.sender][_giftIndex];
        if(block.timestamp < gift.releaseDate) {
            revert WillsGiftNotDueError(block.timestamp, gift.releaseDate);
        }
        if(msg.sender != gift.beneficiary){
            revert WillsNotBeneficiaryError(gift.beneficiary, msg.sender);
        }
        if(gift.released) {
            revert WillsGiftAlreadyReleasedError();
        }
        gift.released = true;
        gift.beneficiary.transfer(gift.amount);
        emit GiftReleased(gift.beneficiary, "Ether", _giftIndex);
    }

    function cancelEtherGift(uint _giftIndex, address _beneficiary) public nonReentrant{
        EtherGift storage gift = etherGifts[msg.sender][_beneficiary][_giftIndex];
        if(msg.sender != gift.testator){
            revert WillsNotTestatorError(gift.testator, msg.sender);
        }
        if(gift.released) {
            revert WillsGiftAlreadyReleasedError();
        }
        gift.testator.transfer(gift.amount);
        EtherGift[] storage giftsArray = etherGifts[msg.sender][_beneficiary];
        if (_giftIndex < giftsArray.length - 1) {
            giftsArray[_giftIndex] = giftsArray[giftsArray.length - 1];
        }
        delete giftsArray[giftsArray.length - 1];
        giftsArray.pop();
        emit EtherGiftCancelled(msg.sender, gift.beneficiary, gift.amount, gift.releaseDate);
    }


    function createFungibleTokenGift(IERC20 _tokenAddress, address _beneficiary, uint256 _amount, uint256 _releaseDate) public nonReentrant{
        if(_beneficiary == address(0)){
            revert WillsAddressZeroError();
        }
        if(_amount <= 0) {
            revert WillsInsufficientAmountError();
        }
        if(block.timestamp >= _releaseDate){
            revert WillsInvalidReleaseDateError(_releaseDate, block.timestamp);
        }
        _tokenAddress.transferFrom(msg.sender, address(this), _amount);
        FungibleTokenGift memory newTokenGift = FungibleTokenGift({
            testator: msg.sender,
            tokenAddress: _tokenAddress,
            beneficiary: _beneficiary,
            amount: _amount,
            releaseDate: _releaseDate,
            released: false
        });
        tokenGifts[msg.sender][_beneficiary].push(newTokenGift);
        bool hasBeneficiary = false;
        for(uint i = 0 ; i < listOfBeneficiaries[msg.sender].length; i++){
            if(listOfBeneficiaries[msg.sender][i] == _beneficiary) {
                hasBeneficiary = true;
                break;
            }
        }
        if(!hasBeneficiary) {
            listOfBeneficiaries[msg.sender].push(_beneficiary);
        }
        emit FungibleTokenGiftCreated(msg.sender, address(_tokenAddress),_beneficiary , _amount, _releaseDate);
    }


    function releaseFungibleTokenGift(uint _giftIndex, address _testator) public nonReentrant {
        FungibleTokenGift storage gift = tokenGifts[_testator][msg.sender][_giftIndex];
        if(block.timestamp < gift.releaseDate) {
            revert WillsGiftNotDueError(block.timestamp, gift.releaseDate);
        }
        if(msg.sender != gift.beneficiary){
            revert WillsNotBeneficiaryError(gift.beneficiary, msg.sender);
        }
        if(gift.released) {
            revert WillsGiftAlreadyReleasedError();
        }
        gift.released = true;
        gift.tokenAddress.transfer(msg.sender, gift.amount);
        emit GiftReleased(gift.beneficiary, "ERC20 Token", _giftIndex);
    }


    function cancelFungibleTokenGift(uint _giftIndex, address _beneficiary) public nonReentrant {
        FungibleTokenGift storage gift = tokenGifts[msg.sender][_beneficiary][_giftIndex];
        if(msg.sender != gift.testator){
            revert WillsNotTestatorError(gift.testator, msg.sender);
        }
        if(gift.released) {
            revert WillsGiftAlreadyReleasedError();
        }
        gift.tokenAddress.transfer(gift.testator, gift.amount);
        FungibleTokenGift[] storage giftsArray = tokenGifts[msg.sender][_beneficiary];
        require(_giftIndex < giftsArray.length, "Index out of bounds");
        if (_giftIndex < giftsArray.length - 1) {
            giftsArray[_giftIndex] = giftsArray[giftsArray.length - 1];
        }
        delete giftsArray[giftsArray.length - 1];
        giftsArray.pop();
        emit FungibleTokenGiftCancelled(msg.sender, address(gift.tokenAddress) , gift.beneficiary, gift.amount, gift.releaseDate);
    }


    function createNFTGift(IERC721 _nftContract, address _beneficiary, uint _tokenId, uint _releaseDate) public nonReentrant {
        if(_beneficiary == address(0)){
            revert WillsAddressZeroError();
        }
        if(block.timestamp >= _releaseDate){
            revert WillsInvalidReleaseDateError(_releaseDate, block.timestamp);
        }
        if(_nftContract.ownerOf(_tokenId) != msg.sender) {
            revert WillsNotTokenOwnerError(_nftContract.ownerOf(_tokenId), msg.sender);
        }
        _nftContract.transferFrom(msg.sender, address(this), _tokenId);
        NFTGift memory newNftGift = NFTGift({
            testator: msg.sender,
            contractAddress: _nftContract,
            tokenId: _tokenId,
            beneficiary: payable(_beneficiary),
            releaseDate: _releaseDate,
            released: false
        });
        nftGifts[msg.sender][_beneficiary].push(newNftGift);
        bool hasBeneficiary = false;
        for(uint i = 0 ; i < listOfBeneficiaries[msg.sender].length; i++){
            if(listOfBeneficiaries[msg.sender][i] == _beneficiary) {
                hasBeneficiary = true;
                break;
            }
        }
        if(!hasBeneficiary) {
            listOfBeneficiaries[msg.sender].push(_beneficiary);
        }
        emit NFTGiftCreated(msg.sender, address(_nftContract),_beneficiary , _tokenId, _releaseDate);
    }


    function releaseNFTGift(uint256 _giftIndex, address _testator) public nonReentrant {
        NFTGift storage gift = nftGifts[_testator][msg.sender][_giftIndex];
        if(block.timestamp < gift.releaseDate) {
            revert WillsGiftNotDueError(block.timestamp, gift.releaseDate);
        }
        if(msg.sender != gift.beneficiary){
            revert WillsNotBeneficiaryError(gift.beneficiary, msg.sender);
        }
        if(gift.released) {
            revert WillsGiftAlreadyReleasedError();
        }
        gift.released = true;
        gift.contractAddress.transferFrom(address(this), gift.beneficiary,gift.tokenId);
        emit GiftReleased(gift.beneficiary, "NFT", _giftIndex);
    }

    function cancelNFTGift(uint _giftIndex, address _beneficiary) public nonReentrant {
        NFTGift storage gift = nftGifts[msg.sender][_beneficiary][_giftIndex];
        if(msg.sender != gift.testator){
            revert WillsNotTestatorError(gift.testator, msg.sender);
        }
        if(gift.released) {
            revert WillsGiftAlreadyReleasedError();
        }
        gift.contractAddress.transferFrom(address(this), gift.testator, gift.tokenId);
        NFTGift[] storage giftsArray = nftGifts[msg.sender][_beneficiary];
        if (_giftIndex < giftsArray.length - 1) {
            giftsArray[_giftIndex] = giftsArray[giftsArray.length - 1];
        }
        delete giftsArray[giftsArray.length - 1];
        giftsArray.pop();
        emit NFTGiftCancelled(msg.sender, address(gift.contractAddress) , gift.beneficiary, gift.tokenId, gift.releaseDate);
    }


    function getGiftLength(string memory _type, address _testator, address _beneficiary) external view returns(uint){
        if(keccak256(bytes(_type)) == keccak256(bytes("NFT"))) {
            NFTGift[] storage nft = nftGifts[_testator][_beneficiary];
            return nft.length;
        } else if (keccak256(bytes(_type)) == keccak256(bytes("ERC20"))){
            FungibleTokenGift[] storage tokens = tokenGifts[_testator][_beneficiary];
            return tokens.length;
        } else {
            EtherGift[] storage ethers = etherGifts[_testator][_beneficiary];
            return ethers.length;
        }
    }

    function getListOfBeneficiaries(address _testator) external view returns(uint) {
        return listOfBeneficiaries[_testator].length;
    }

}