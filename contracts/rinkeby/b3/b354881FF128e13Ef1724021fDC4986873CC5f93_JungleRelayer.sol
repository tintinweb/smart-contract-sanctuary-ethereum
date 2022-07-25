// SPDX-License-Identifier: None

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Jungle Relayer Contract
 * @dev This contract acts as a User to buy NFTs on behalf of Jungle users
 *      and automatically transfer it to the user in the same transaction.
 */
contract JungleRelayer is Ownable, ERC1155Receiver, IERC721Receiver {

    enum HowToCall { Call, DelegateCall }
    enum NFTType { ERC721, ERC1155 }

    struct NFTData {
        address contractAddress;
        uint256 tokenId;
        uint256 amount;
        NFTType nftType;
    }

    struct Relay {
        address contractAddress;
        address paymentToken;
        uint256 baseAmount;
        bytes data;
        address tokenTransferApproval;
    }

    address public feeRecipient; // Address in which resaleFee will be deposited
    uint16  public denominator = 10000;
    uint16  public resaleFee; // Fee charged for resale
    uint16  public cashback; // Fee or amount which will be trasfer back

    //Stores the current caller for one execution, reset to zero at the end of execution
    address private currentCaller;

    event FeeRecipientChanged(address _feeRecipient);
    event CashbackChanged(uint16 _cashback);
    event ResaleFeeChanged(uint16 _resaleFee);

    constructor(address _feeRecipient, uint16 _resaleFee, uint16 _cashback){

        require(_feeRecipient != address(0), "Invalid Fee Recipient.");
        require(_cashback <= _resaleFee, "Invalid cashback or resaleFee amount.");

        feeRecipient = _feeRecipient;
        resaleFee = _resaleFee;
        cashback = _cashback;
    }

    receive() external payable {

    }    

    fallback() external payable {

    }

    /**
     * Execute a message call to a contract
     *
     * @dev Can be called by the owner.
     * @param relay Relay object with call data.
     * @param nftDatas NFT Data object array to transfer NFTs if any.
     */
    function execute(Relay calldata relay, NFTData[] memory nftDatas) external payable {

        require(currentCaller == address(0), "Reentrant call");
        currentCaller = _msgSender();

        verifyNFTData(nftDatas);

        uint256 resaleFeeAmount = (relay.baseAmount * resaleFee) / denominator;
        uint256 cashbackAmount  = (relay.baseAmount * cashback ) / denominator;
        uint256 totalAmount = relay.baseAmount + resaleFeeAmount;

        if(relay.paymentToken == address(0)) {
            require(totalAmount >= msg.value, "Incorrect value.");

            uint256 contractBalance = msg.value;
            
            (bool result,) = _call(relay.contractAddress, HowToCall.Call, relay.data, relay.baseAmount);
            require(result, "Function call not successful.");

            if(cashbackAmount > 0){
                resaleFeeAmount -= cashbackAmount;
                (bool success,) = payable(_msgSender()).call{value: cashbackAmount}("");
                require(success, "Cashback transfer failed.");
            }

            if(resaleFeeAmount > 0){
                (bool success,) = payable(feeRecipient).call{value: resaleFeeAmount}("");
                require(success, "ResaleFee transfer failed.");
            }

            uint256 remainingBalance = contractBalance - relay.baseAmount - cashbackAmount - resaleFeeAmount;
            if(remainingBalance > 0){
                (bool success,) = payable(_msgSender()).call{value: remainingBalance}("");
                require(success, "Remaining balance transfer failed.");
            }
        }
        else {
            IERC20(relay.paymentToken).transferFrom(_msgSender(), address(this), totalAmount);

            if(relay.tokenTransferApproval != address(0) && isContract(relay.paymentToken)) {
                uint256 tokenApproval = IERC20(relay.paymentToken).allowance(address(this), relay.tokenTransferApproval);
                if(tokenApproval < totalAmount){
                    IERC20(relay.paymentToken).approve(relay.tokenTransferApproval, 0);
                    IERC20(relay.paymentToken).approve(relay.tokenTransferApproval, type(uint).max);
                }
            }

            (bool result,) = _call(relay.contractAddress, HowToCall.Call, relay.data, 0);
            require(result, "Function call not successful.");

            if(cashbackAmount > 0){
                resaleFeeAmount -= cashbackAmount;
                IERC20(relay.paymentToken).transfer(_msgSender(), cashbackAmount);
            }

            if(resaleFeeAmount > 0){
                IERC20(relay.paymentToken).transfer(feeRecipient, resaleFeeAmount);
            }
        }

        transferNFTData(nftDatas);

        currentCaller = address(0);
    }

    /**
     * Execute a message call to a contract
     *
     * @dev Can be called by the owner.
     * @param dest Address to which the call will be sent
     * @param howToCall Which kind of call to make
     * @param data Calldata to send
     * @return result Result of the call (success or failure)
     */
    function call(address dest, HowToCall howToCall, bytes memory data)
    external payable onlyOwner
    returns (bool result, bytes memory ret)
    {
        (result, ret) =  _call(dest, howToCall, data, msg.value);
    }

    /**
     * @dev Set fee recipient
     * @param _feeRecipient address of the fee recipient
     */
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Fee recipient cannot be a zero address");
        feeRecipient = _feeRecipient;
        emit FeeRecipientChanged(_feeRecipient);
    }

     /**
     * @dev Set resale fee
     * @param _resaleFee resaleFee amount in uint256
     */
    function setResaleFee(uint16 _resaleFee) external onlyOwner {
        require(_resaleFee < denominator, "ResaleFee too high. ");
        resaleFee = _resaleFee;
        emit ResaleFeeChanged(_resaleFee);

    }

    /**
    * @dev Set cashback
    * @param _cashback cashback amount in uint256
     */
    function setCashback(uint16 _cashback) external onlyOwner {
        require(_cashback <= resaleFee, "Cashback cannot be greater than resaleFee ");
        cashback = _cashback;
        emit CashbackChanged(_cashback);
    }

    /**
     * @dev Handles the receipt of a single ERC1155 token type. Transfers the NFT to the currentCaller 
     * as soon as it is received. Prevents the contract from receiving NFTs when the contract is not in execution. 
     * This function is called from the NFT contract at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param _id The ID of the token being transferred
     * @param _value The amount of tokens being transferred
     * @param _data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(address, address, uint256 _id, uint256 _value, bytes calldata _data) external override returns(bytes4) {
        require(currentCaller != address(0), "onERC1155Received: transfer not accepted");

        IERC1155(_msgSender()).safeTransferFrom(address(this), currentCaller, _id, _value, _data);

        return this.onERC1155Received.selector;
    }

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. Transfers the NFTs to the currentCaller 
     * as soon as they are received. Prevents the contract from receiving NFTs when the contract is not in execution. 
     * This function is called from the NFT contract at the end of a `safeBatchTransferFrom` after the balances have
     * been updated. 
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param _ids An array containing ids of each token being transferred (order and length must match values array)
     * @param _values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param _data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(address, address, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external override returns(bytes4) {
        require(currentCaller != address(0),"onERC1155BatchReceived: transfer not accepted");
        IERC1155(_msgSender()).safeBatchTransferFrom(address(this), currentCaller, _ids, _values, _data);
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     * Transfers the NFTs to the currentCaller as soon as they are received. 
     * Prevents the contract from receiving NFTs when the contract is not in execution.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256 tokenId, bytes memory data) external override returns(bytes4) {
        require(currentCaller != address(0),"onERC1155Received: transfer not accepted");
        IERC721(_msgSender()).safeTransferFrom(address(this), currentCaller, tokenId, data);
        return this.onERC721Received.selector;
    }

    /**
     * Contract should not hold any NFT which is being sold.
     *
     * @param nftDatas NFT Data object array to verify NFTs if any.
     */
    function verifyNFTData(NFTData[] memory nftDatas) internal view {
        for(uint8 i = 0; i < nftDatas.length; i++){
            NFTData memory nftData = nftDatas[i];
            if(nftData.nftType == NFTType.ERC721) {
                address ownerOfToken = IERC721(nftData.contractAddress).ownerOf(nftData.tokenId);
                require(ownerOfToken != address(this), "Invalid NFT data");
            }
            else if(nftData.nftType == NFTType.ERC1155){
                uint256 tokenBalance = IERC1155(nftData.contractAddress).balanceOf(address(this), nftData.tokenId);
                require(tokenBalance==0, "Invalid NFT data");
            }
        }
    }

    /**
     * Transfer NFTs to user, if not automatically transferred by onReceived functions.
     * This is for NFT contracts which do not perform safeTransfer checks
     *
     * @param nftDatas NFT Data object array to transfer NFTs if any.
     */
    function transferNFTData(NFTData[] memory nftDatas) internal {
        for(uint8 i = 0; i < nftDatas.length; i++){
            NFTData memory nftData = nftDatas[i];
            if(nftData.nftType == NFTType.ERC721){
                address ownerOfToken = IERC721(nftData.contractAddress).ownerOf(nftData.tokenId);
                if(ownerOfToken == address(this)){
                    IERC721(nftData.contractAddress).transferFrom(address(this), _msgSender(),nftData.tokenId);
                }
            }
            else if(nftData.nftType == NFTType.ERC1155){
                uint256 tokenBalance = IERC1155(nftData.contractAddress).balanceOf(address(this), nftData.tokenId);
                if(tokenBalance==nftData.amount){
                    IERC1155(nftData.contractAddress).safeTransferFrom(address(this), _msgSender(), nftData.tokenId, nftData.amount, "");
                }
            }
        }
    }

    /**
     * Internal function to execute a message call to a contract
     *
     * @param dest Address to which the call will be sent
     * @param howToCall Which kind of call to make
     * @param data Calldata to send
     * @return result Result of the call (success or failure)
     */
    function _call(address dest, HowToCall howToCall, bytes memory data, uint256 value)
    internal
    returns (bool result, bytes memory ret)
    {
        if (howToCall == HowToCall.Call) {
            (result, ret) = dest.call{value:value}(data);
        } else if (howToCall == HowToCall.DelegateCall) {
            (result, ret) = dest.delegatecall(data);
        }
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/ContextMetaTx.sol)

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