// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "../../utils/interfaces/IERC20Fixed.sol";
import "../UniqRedeem/IUniqRedeemV3.sol";
import "../OwnershipHolder/IOwnershipHolder.sol";

contract UniqPaymentProxyV3 is Ownable, EIP712, ERC1155Holder, IERC721Receiver {
    // ----- EVENTS ----- //
    event Executed(address indexed executor, uint256 indexed nonce);

    // ----- STRUCTURES ----- //
    struct ERC721TokenData {
        address tokenAddress;
        uint256 id;
        address receiver;
        uint256 network;
        RedeemTypes toBurn;
        uint256 purpose;
    }

    struct ERC1155TokenData {
        address tokenAddress;
        uint256 id;
        uint256 amount;
        address receiver;
        uint256 network;
        RedeemTypes toBurn;
        uint256 purpose;
    }

    enum RedeemTypes {
        MintOnly, //0
        MintAndRedeem, //1
        RedeemOnly //2
    }

    // ----- VARIABLES ----- //
    uint256 internal _networkId;
    mapping(uint256 => bool) public _isNonceUsed;
    address public signer;
    IUniqRedeemV3 public redeem;
    IOwnershipHolder public ownershipHolder;

    // ----- CONSTRUCTOR ----- //
    constructor(
        uint256 _pnetworkId,
        address _signer,
        address _redeem,
        address _ownershipHolder
    ) EIP712("Uniqly", "1") {
        _networkId = _pnetworkId;
        signer = _signer;
        redeem = IUniqRedeemV3(_redeem);
        ownershipHolder = IOwnershipHolder(_ownershipHolder);
    }

    function setRedeemAddress(IUniqRedeemV3 _redeemAddress) external onlyOwner {
        redeem = _redeemAddress;
    }

    function setOwnershipHolderAddress(
        IOwnershipHolder _ownershipHolder
    ) external onlyOwner {
        ownershipHolder = _ownershipHolder;
    }

    function _sendTokens(
        address _paymentToken,
        uint256[] memory _amount,
        address[] memory _paymentReceiver
    ) internal {
        uint256 len = _amount.length;
        require(len == _paymentReceiver.length, "Length mimatch pt");
        if (_paymentToken == address(0)) {
            uint256 sum;
            for (uint256 i = 0; i < len; i++) {
                sum += _amount[i];
            }
            require(msg.value >= sum, "Not enough ether");
            if (sum < msg.value) {
                payable(msg.sender).transfer(msg.value - sum);
            }
        }
        for (uint256 i = 0; i < len; i++) {
            if (_paymentToken == address(0)) {
                if (_amount[i] > 0) {
                    payable(_paymentReceiver[i]).transfer(_amount[i]);
                }
            } else {
                if (_amount[i] > 0) {
                    IERC20Fixed(_paymentToken).transferFrom(
                        msg.sender,
                        _paymentReceiver[i],
                        _amount[i]
                    );
                }
            }
        }
    }

    function _redeemTokens(
        address _contractAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _purposes,
        uint256[] memory _networks
    ) internal {
        address[] memory contractAddresses = new address[](_tokenIds.length);
        string[] memory names = new string[](_tokenIds.length);
        address[] memory owners = new address[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            contractAddresses[i] = _contractAddress;
            names[i] = "UniqlyPPV3";
            owners[i] = IERC721(_contractAddress).ownerOf(_tokenIds[i]);
        }
        redeem.redeemTokensAsAdmin(
            contractAddresses,
            _tokenIds,
            _purposes,
            owners,
            names,
            _networks
        );
    }

    function _processERC721(ERC721TokenData[] memory erc721Tokens) internal {
        uint256[] memory ids = new uint256[](erc721Tokens.length);
        address[] memory receivers = new address[](erc721Tokens.length);
        uint256[] memory purposes = new uint256[](erc721Tokens.length);
        uint256[] memory networks = new uint256[](erc721Tokens.length);
        //Redeem only scenario
        if (
            erc721Tokens[0].toBurn == RedeemTypes.RedeemOnly &&
            address(redeem) != address(0)
        ) {
            for (uint256 i = 0; i < erc721Tokens.length; i++) {
                require(erc721Tokens[i].purpose != 0, "Purpose error");
                ids[i] = erc721Tokens[i].id;
                purposes[i] = erc721Tokens[i].purpose;
                networks[i] = erc721Tokens[i].network;
            }
            _redeemTokens(
                erc721Tokens[0].tokenAddress,
                ids,
                purposes,
                networks
            );
            return;
        }
        //Mint and burn scenario
        if (erc721Tokens[0].network == _networkId) {
            for (uint256 i = 0; i < erc721Tokens.length; i++) {
                if (erc721Tokens[0].toBurn == RedeemTypes.MintAndRedeem) {
                    require(erc721Tokens[i].purpose != 0, "Purpose error");
                }
                ids[i] = erc721Tokens[i].id;
                receivers[i] = erc721Tokens[i].receiver;
                purposes[i] = erc721Tokens[i].purpose;
                networks[i] = erc721Tokens[i].network;
            }
            try
                ownershipHolder.pBatchMintSelectedIds(
                    ids,
                    receivers,
                    erc721Tokens[0].tokenAddress
                )
            {} catch {
                bytes memory bt;
                ownershipHolder.pMintNFTTokens(
                    erc721Tokens[0].tokenAddress,
                    receivers[0],
                    8888,
                    ids,
                    _networkId,
                    bt
                );
            }
            if (
                erc721Tokens[0].toBurn == RedeemTypes.MintAndRedeem &&
                address(redeem) != address(0)
            ) {
                _redeemTokens(
                    erc721Tokens[0].tokenAddress,
                    ids,
                    purposes,
                    networks
                );
            }
        }
    }

    function _processERC1155(ERC1155TokenData[] memory erc1155Tokens) internal {
        uint256[] memory ids = new uint256[](erc1155Tokens.length);
        uint256[] memory amounts = new uint256[](erc1155Tokens.length);
        address[] memory receivers = new address[](erc1155Tokens.length);
        bool[] memory burn = new bool[](erc1155Tokens.length);
        for (uint256 i = 0; i < erc1155Tokens.length; i++) {
            ids[i] = erc1155Tokens[i].id;
            receivers[i] = erc1155Tokens[i].receiver;
            amounts[i] = erc1155Tokens[i].amount;
            burn[i] = erc1155Tokens[i].toBurn == RedeemTypes.MintAndRedeem
                ? true
                : false;
        }
        //Burn Scenario
        if (erc1155Tokens[0].toBurn == RedeemTypes.RedeemOnly) {
            //TODO: Redeem for erc1155?
            ///require(erc1155Tokens[0].purpose != 0, "Purpose is zero");
            ownershipHolder.pBatchBurnFrom1155(
                erc1155Tokens[0].tokenAddress,
                ids,
                amounts,
                erc1155Tokens[0].receiver
            );
            return;
        }
        //Mint or Mint-and-burn scenario
        if (erc1155Tokens[0].network == _networkId) {
            //TODO: Redeem for erc1155?
            ///require(erc1155Tokens[0].purpose != 0, "Purpose is zero");
            ownershipHolder.pBatchMintAndBurn1155(
                erc1155Tokens[0].tokenAddress,
                ids,
                amounts,
                burn,
                receivers[0]
            );
        }
    }

    function _processBatch(
        uint256 network,
        address tokenContractAddress,
        uint256[] memory tokenIds,
        uint256[] memory erc1155tokenAmounts,
        RedeemTypes toBurn,
        address receiver,
        uint256 startBatchIndex,
        uint256 endBatchIndex,
        uint256 purpose
    ) internal {
        uint256 elSum = endBatchIndex - startBatchIndex;
        uint256 elInd;
        if (erc1155tokenAmounts[startBatchIndex] == 0) {
            ERC721TokenData[] memory erc721Tokens = new ERC721TokenData[](
                elSum
            );
            for (uint256 i = startBatchIndex; i < endBatchIndex; i++) {
                erc721Tokens[elInd] = ERC721TokenData({
                    tokenAddress: tokenContractAddress,
                    receiver: receiver,
                    id: tokenIds[i],
                    network: network,
                    toBurn: toBurn,
                    purpose: purpose
                });
                elInd++;
            }
            _processERC721(erc721Tokens);
        } else {
            ERC1155TokenData[] memory erc1155Tokens = new ERC1155TokenData[](
                elSum
            );
            for (uint256 i = startBatchIndex; i < endBatchIndex; i++) {
                erc1155Tokens[elInd] = ERC1155TokenData({
                    tokenAddress: tokenContractAddress,
                    receiver: receiver,
                    amount: erc1155tokenAmounts[i],
                    id: tokenIds[i],
                    network: network,
                    toBurn: toBurn,
                    purpose: purpose
                });
                elInd++;
            }
            _processERC1155(erc1155Tokens);
        }
    }

    function _processTokens(
        uint256[] memory networks,
        address[] memory tokenContractAddreses,
        uint256[] memory tokenIds,
        uint256[] memory erc1155tokenAmounts,
        RedeemTypes[] memory toBurn,
        uint256[] memory purposes,
        address receiver
    ) internal {
        uint256 len = tokenContractAddreses.length;
        require(
            len == networks.length &&
                len == tokenIds.length &&
                len == erc1155tokenAmounts.length &&
                len == toBurn.length &&
                len == purposes.length,
            "UPP: Check arrays lenghts"
        );
        if (len == 0) return;
        uint256 elSum;
        for (uint256 i = 0; i < len; i++) {
            if (elSum > 0) {
                if (
                    tokenContractAddreses[i] != tokenContractAddreses[i - 1] ||
                    networks[i] != networks[i - 1] ||
                    toBurn[i] != toBurn[i - 1] ||
                    purposes[i] != purposes[i - 1]
                ) {
                    _processBatch(
                        networks[i - 1],
                        tokenContractAddreses[i - 1],
                        tokenIds,
                        erc1155tokenAmounts,
                        toBurn[i - 1],
                        receiver,
                        i - elSum,
                        i,
                        purposes[i - 1]
                    );
                    elSum = 0;
                    i--;
                    continue;
                }
            }
            elSum++;
        }

        if (elSum > 0) {
            _processBatch(
                networks[len - 1],
                tokenContractAddreses[len - 1],
                tokenIds,
                erc1155tokenAmounts,
                toBurn[len - 1],
                receiver,
                len - elSum,
                len,
                purposes[len - 1]
            );
        }
    }

    // ----- PUBLIC METHODS ----- //
    function execTransaction(
        uint256[] memory networks,
        address[] memory tokenContractAddresses,
        uint256[] memory tokenIds,
        uint256[] memory erc1155TokenAmounts,
        RedeemTypes[] memory toBurn,
        uint256[] memory purposes,
        uint256[] memory ptAmounts, //amount to send
        address[] memory ptReceivers, //tokens receivers
        address[] memory addresses, //0 - paymentToken address, 1- nft receiver address
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) external payable {
        require(deadline > block.timestamp, "UPP: Transaction timed out");
        require(!_isNonceUsed[nonce], "UPP: Nonce already used");
        bytes32 typedHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "ExecData(uint256[] networks,address[] tokenContractAddresses,uint256[] tokenIds,uint256[] erc1155TokenAmounts,uint256[] toBurn,uint256[] purposes,uint256[] ptAmounts,address[] ptReceivers,address[] addresses,uint256 nonce,uint256 deadline)"
                    ),
                    keccak256(abi.encodePacked(networks)),
                    keccak256(abi.encodePacked(tokenContractAddresses)),
                    keccak256(abi.encodePacked(tokenIds)),
                    keccak256(abi.encodePacked(erc1155TokenAmounts)),
                    keccak256(abi.encodePacked(toBurn)),
                    keccak256(abi.encodePacked(purposes)),
                    keccak256(abi.encodePacked(ptAmounts)),
                    keccak256(abi.encodePacked(ptReceivers)),
                    keccak256(abi.encodePacked(addresses)),
                    nonce,
                    deadline
                )
            )
        );
        require(
            ECDSA.recover(typedHash, signature) == signer,
            "UPP: Signature Mismatch"
        );
        _isNonceUsed[nonce] = true;

        _sendTokens(addresses[0], ptAmounts, ptReceivers);

        _processTokens(
            networks,
            tokenContractAddresses,
            tokenIds,
            erc1155TokenAmounts,
            toBurn,
            purposes,
            addresses[1]
        );

        emit Executed(msg.sender, nonce);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // ----- PROXY METHODS ----- //
    function pEditClaimingAddress(
        address _contractAddress,
        address _newAddress
    ) external onlyOwner {
        ownershipHolder.pEditClaimingAdress(_contractAddress, _newAddress);
    }

    function pEditRoyaltyFee(
        address _contractAddress,
        uint256 _newFee
    ) external onlyOwner {
        ownershipHolder.pEditRoyaltyFee(_contractAddress, _newFee);
    }

    function pEditTokenUri(
        address _contractAddress,
        string memory _ttokenUri
    ) external onlyOwner {
        ownershipHolder.pEditTokenUri(_contractAddress, _ttokenUri);
    }

    function pRecoverERC20(
        address _contractAddress,
        address token
    ) external onlyOwner {
        ownershipHolder.pRecoverERC20(_contractAddress, token);
    }

    function pTransferOwnership(
        address _contractAddress,
        address newOwner
    ) external onlyOwner {
        ownershipHolder.pTransferOwnership(_contractAddress, newOwner);
    }

    function pBatchMintSelectedIds(
        uint256[] memory _ids,
        address[] memory _addresses,
        address _contractAddress
    ) external onlyOwner {
        ownershipHolder.pBatchMintSelectedIds(
            _ids,
            _addresses,
            _contractAddress
        );
    }

    function pMintNFTTokens(
        address _contractAddress,
        address _requesterAddress,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _chainId,
        bytes memory _transactionHash
    ) external onlyOwner {
        ownershipHolder.pMintNFTTokens(
            _contractAddress,
            _requesterAddress,
            _bundleId,
            _tokenIds,
            _chainId,
            _transactionHash
        );
    }

    function pMintNextToken(
        address _contractAddress,
        address _receiver
    ) external onlyOwner {
        ownershipHolder.pMintNextToken(_contractAddress, _receiver);
    }

    function pSetNewPaymentProxy(
        address _contractAddress,
        address _newPP
    ) external onlyOwner {
        ownershipHolder.pSetNewPaymentProxy(_contractAddress, _newPP);
    }

    function pSetNewAdministrator(
        address _contractAddress,
        address _newAdmin
    ) external onlyOwner {
        ownershipHolder.pSetNewAdministrator(_contractAddress, _newAdmin);
    }

    // ----- OWNERS METHODS ----- //

    function withdrawTokens(address token) external onlyOwner {
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val != 0, "Nothing to recover");
        // use interface that not return value (USDT case)
        IERC20Fixed(token).transfer(msg.sender, val);
    }

    receive() external payable {}

    function wthdrawETH() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
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
pragma solidity ^0.8.4;

// we need some information from token contract
// we also need ability to transfer tokens from/to this contract
interface IERC20Fixed {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IOwnershipHolder {
    // ----- PROXY METHODS ----- //
    function pEditClaimingAddress(
        address _contractAddress,
        address _newAddress
    ) external;

    function pEditRoyaltyFee(
        address _contractAddress,
        uint256 _newFee
    ) external;

    function pEditTokenUri(
        address _contractAddress,
        string memory _ttokenUri
    ) external;

    function pRecoverERC20(address _contractAddress, address token) external;

    function pOwner(address _contractAddress) external view returns (address);

    function pTransferOwnership(
        address _contractAddress,
        address newOwner
    ) external;

    function pBatchMintSelectedIds(
        uint256[] memory _ids,
        address[] memory _addresses,
        address _contractAddress
    ) external;

    function pMintNFTTokens(
        address _contractAddress,
        address _requesterAddress,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _chainId,
        bytes memory _transactionHash
    ) external;

    function pMintNextToken(
        address _contractAddress,
        address _receiver
    ) external;

    function pSetNewPaymentProxy(
        address _contractAddress,
        address _newPP
    ) external;

    function pSetNewAdministrator(
        address _contractAddress,
        address _newAdmin
    ) external;

    function pEditClaimingAdress(
        address _contractAddress,
        address _newAddress
    ) external;

    function pBurn(address _contractAddress, uint256 _tokenId) external;

    function pBatchMintAndBurn1155(
        address _contractAddress,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bool[] memory _burn,
        address _receiver
    ) external;

    function pBatchBurnFrom1155(
        address _contractAddress,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        address burner
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IUniqRedeemV3 {
    event Redeemed(
        address indexed _contractAddress,
        uint256 indexed _tokenId,
        address indexed _redeemerAddress,
        string _redeemerName,
        uint256[] _purposes
    );

    function isTokenRedeemedForPurpose(
        address _address,
        uint256 _tokenId,
        uint256 _purpose
    ) external view returns (bool);

    function getMessageHash(
        address[] memory _tokenContracts,
        uint256[] memory _tokenIds,
        uint256[] memory _purposes,
        uint256 _price,
        address _paymentTokenAddress,
        uint256 _timestamp
    ) external pure returns (bytes32);

    function redeemManyTokens(
        address[] memory _tokenContracts,
        uint256[] memory _tokenIds,
        uint256[] memory _purposes,
        string memory _redeemerName,
        uint256 _price,
        address _paymentTokenAddress,
        bytes memory _signature,
        uint256 _timestamp
    ) external payable;

    function redeemTokenForPurposes(
        address _tokenContract,
        uint256 _tokenId,
        uint256[] memory _purposes,
        string memory _redeemerName,
        uint256 _price,
        address _paymentTokenAddress,
        bytes memory _signature,
        uint256 _timestamp
    ) external payable;

    function setTransactionOffset(uint256 _newOffset) external;

    function setStatusesForTokens(
        address[] memory _tokenAddresses,
        uint256[] memory _tokenIds,
        uint256[] memory _purposes,
        bool[] memory isRedeemed
    ) external;

    function withdrawERC20(address _address) external;

    function withdrawETH() external;

    function redeemTokensAsAdmin(
        address[] memory _tokenContracts,
        uint256[] memory _tokenIds,
        uint256[] memory _purposes,
        string[] memory _redeemerName
    ) external;

    function redeemTokenForPurposesAsAdmin(
        address _tokenContract,
        uint256 _tokenId,
        uint256[] memory _purposes,
        string memory _redeemerName
    ) external;


    function redeemTokensAsAdmin(
        address[] memory _tokenContracts,
        uint256[] memory _tokenIds,
        uint256[] memory _purposes,
        address[] memory _owners,
        string[] memory _redeemerName,
        uint256[] memory _networks
    ) external;
}