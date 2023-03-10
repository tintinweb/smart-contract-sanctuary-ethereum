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
pragma solidity ^0.8.17;

interface IChildStorage {
    function addChildAddress_EPEzCt7SLk (address _user, address _newChild) external;
    function child (address, uint256) external view returns (address);
    function childCount (address) external view returns (uint256);
    function controller (address) external view returns (bool);
    function delegateRegistry () external view returns (address);
    function kudasai () external view returns (address);
    function operator () external view returns (address);
    function ownedNFTId (address) external view returns (uint256);
    function owner () external view returns (address);
    function renounceOwnership () external;
    function setController (address _contract, bool _set) external;
    function setDelegateRegistry (address _contract) external;
    function setKudasai (address _contract) external;
    function setNFTId (address _user, uint256 _nftId) external;
    function setOperator (address _contract) external;
    function setSpaceId (string calldata _str) external;
    function spaceId () external view returns (bytes32);
    function transferOwnership (address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMinterChild {
    function initialize_puB (address _deployer) external;
    function run_Ozzfvp4CEc (address _callContract, bytes calldata _callData, uint256 _value) external;
    function withdrawERC1155_wcC (address _contract, uint256 _tokenId, address _to) external;
    function withdrawERC20_ATR (address _contract, address _to) external;
    function withdrawERC721_VKo (address _contract, uint256 _tokenId, address _to) external;
    function withdrawETH_RBf (address _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMultiWalletCallerOperator {
    function checkHolder (address _from) external view;
    function checkId (uint256 _startId, uint256 _endId, address _from) external view;
    function createWallets (uint256 _quantity, address _from) external;
    function sendERC20 (uint256 _startId, uint256 _endId, address _token, uint256 _amount, address _from) external;
    function sendETH (uint256 _startId, uint256 _endId, address _from) external payable;
    function setNFTId (uint256 _nftId, address _from) external;
    function withdrawERC1155 (uint256 _startId, uint256 _endId, address _contract, uint256 _tokenId, address _from) external;
    function withdrawERC20 (uint256 _startId, uint256 _endId, address _contract, address _from) external;
    function withdrawERC721 (uint256 _startId, uint256 _endId, address _contract, uint256[] calldata _tokenIds, address _from) external;
    function withdrawETH (uint256 _startId, uint256 _endId, address _from) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum ConduitItemType {
    NATIVE,
    ERC20,
    ERC721,
    ERC1155
}
struct TransferHelperItem {
    ConduitItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
}
struct TransferHelperItemsWithRecipient {
    TransferHelperItem[] items;
    address recipient;
    bool validateERC721Receiver;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IMultiWalletCallerOperator.sol";
import "./interface/IMinterChild.sol";
import "./interface/IChildStorage.sol";
import "./interface/ITransferHelper.sol";

contract MultiWalletCallerWithdrawERC721 is Ownable {
    IChildStorage private immutable _ChildStorage;

    constructor(address childStorage_) {
        _ChildStorage = IChildStorage(childStorage_);
    }

    modifier checkId(uint256 _startId, uint256 _endId) {
        IMultiWalletCallerOperator(_ChildStorage.operator()).checkId(_startId, _endId, msg.sender);
        _;
    }

    /**
     * @dev Withdraws multiple ERC721 tokens from a contract by transferring ownership of the tokens to the caller.
     *
     * Requirements:
     * - `_startId` must be less than or equal to `_endId`.
     * - The caller must be approved to transfer each token.
     *
     * @param _startId The starting wallet ID to withdraw.
     * @param _endId The ending wallet ID to withdraw.
     * @param _contract The address of the ERC721 contract to withdraw tokens from.
     * @param _tokenIds The array of token IDs to withdraw, one array for each token owner.
     *                  Each element of `_tokenIds` array contains an array of token IDs owned by a single address.
     */
    function batchWithdrawERC721(
        uint256 _startId,
        uint256 _endId,
        address _contract,
        uint256[][] calldata _tokenIds
    ) external checkId(_startId, _endId) {
        TransferHelperItemsWithRecipient[] memory item = new TransferHelperItemsWithRecipient[](1);
        bytes32 conduitKey = 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000;
        address transferHelper = 0x0000000000c2d145a2526bD8C716263bFeBe1A72;
        address conduit = 0x1E0049783F008A0085193E00003D00cd54003c71;

        for (uint256 i = _startId; i <= _endId; ) {
            TransferHelperItem[] memory items = new TransferHelperItem[](_tokenIds[i].length);
            for (uint256 j = 0; j < _tokenIds[i].length;) {
                items[j].itemType = ConduitItemType.ERC721;
                items[j].token = _contract;
                items[j].identifier = _tokenIds[i][j];
                items[j].amount = 1;
                unchecked {
                    j++;
                }
            }
            item[0].items = items;
            item[0].recipient = msg.sender;
            item[0].validateERC721Receiver = true;
            IMinterChild(
                payable(_ChildStorage.child(msg.sender, i))
            ).run_Ozzfvp4CEc(_contract, abi.encodeWithSignature("setApprovalForAll(address,bool)", conduit, true), 0);
            IMinterChild(
                payable(_ChildStorage.child(msg.sender, i))
            ).run_Ozzfvp4CEc(transferHelper, abi.encodeWithSignature("bulkTransfer(((uint8,address,uint256,uint256)[],address,bool)[],bytes32)", item, conduitKey), 0);
            unchecked {
                i++;
            }
        }
    }
}