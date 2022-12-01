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

import "@openzeppelin/contracts/access/Ownable.sol";

contract ZKCryptoNetWorth is Ownable {
    struct RequestMetadata {
        string sender;
        string receiver;
        uint256 threshold;
        int8 status;
        bool result;
        string proof;
    }

    struct User {
        uint256 publicKey;
        string primaryWalletAddress;
        string[] secondaryWalletAddresses;
        string[] incomingRequests;
        string[] outgoingRequests;
    }

    string[] internal publicKeys;
    RequestMetadata[] internal requestMetadata;

    mapping(string => User) internal accounts;

    function isUniquePublicKey(
        string calldata _publicKey
    ) external view returns (bool) {
        bytes32 _hashedPublicKey = keccak256(abi.encodePacked(_publicKey));
        for (uint256 _i = 0; _i < publicKeys.length; ) {
            if (
                _hashedPublicKey == keccak256(abi.encodePacked(publicKeys[_i]))
            ) {
                return false;
            }
            unchecked {
                _i++;
            }
        }
        return true;
    }

    function isUniqueUsername(
        string calldata _username
    ) external view returns (bool) {
        if (accounts[_username].publicKey == 0) {
            return true;
        } else {
            return false;
        }
    }

    function setAccount(
        string calldata _username,
        string calldata _publicKey,
        string calldata _primaryWalletAddress
    ) external onlyOwner {
        require(bytes(_username).length != 0, "Username not provided");
        require(bytes(_publicKey).length != 0, "Public key not provided");
        require(
            bytes(_primaryWalletAddress).length != 0,
            "Primary wallet address not provided"
        );
        require(
            this.isUniqueUsername(_username),
            "Account with the given username already exists"
        );
        User storage _account = accounts[_username];
        publicKeys.push(_publicKey);
        _account.publicKey = publicKeys.length;
        _account.primaryWalletAddress = _primaryWalletAddress;
    }

    function getAccount(
        string calldata _username
    ) external view returns (User memory) {
        return accounts[_username];
    }

    function getPublicKey(
        string calldata _username
    ) external view returns (string memory) {
        require(
            !this.isUniqueUsername(_username),
            "Account with the given username does not exist"
        );
        return publicKeys[accounts[_username].publicKey - 1];
    }

    function getPrimaryWalletAddress(
        string calldata _username
    ) external view returns (string memory) {
        return accounts[_username].primaryWalletAddress;
    }

    function setSecondaryWalletAddress(
        string calldata _username,
        string calldata _secondaryWalletAddress
    ) external onlyOwner {
        require(
            !this.isUniqueUsername(_username),
            "Account with the given username does not exist"
        );
        require(
            bytes(_secondaryWalletAddress).length != 0,
            "Secondary wallet address not provided"
        );
        accounts[_username].secondaryWalletAddresses.push(
            _secondaryWalletAddress
        );
    }

    function removeSecondaryWalletAddress(
        string calldata _username,
        string calldata _secondaryWalletAddress
    ) external onlyOwner {
        require(
            !this.isUniqueUsername(_username),
            "Account with the given username does not exist"
        );
        require(
            bytes(_secondaryWalletAddress).length != 0,
            "Secondary wallet address not provided"
        );
        string[] storage secondaryWalletAddresses = accounts[_username]
            .secondaryWalletAddresses;
        bytes32 _hashedSecondaryWalletAddress = keccak256(
            abi.encodePacked(_secondaryWalletAddress)
        );
        for (uint256 _i = 0; _i < secondaryWalletAddresses.length; ) {
            if (
                _hashedSecondaryWalletAddress ==
                keccak256(abi.encodePacked(secondaryWalletAddresses[_i]))
            ) {
                secondaryWalletAddresses[_i] = secondaryWalletAddresses[
                    secondaryWalletAddresses.length - 1
                ];
                secondaryWalletAddresses.pop();
                break;
            }
            unchecked {
                _i++;
            }
        }
    }

    function getSecondaryWalletAddresses(
        string calldata _username
    ) external view returns (string[] memory) {
        return accounts[_username].secondaryWalletAddresses;
    }

    function setRequestMetadata(
        uint256 _id,
        string calldata _sender,
        string calldata _receiver,
        uint256 _threshold,
        int8 _status,
        bool _result,
        string calldata _proof
    ) external onlyOwner {
        require(bytes(_sender).length != 0, "Request sender not provided");
        require(bytes(_receiver).length != 0, "Request receiver not provided");
        if (_id == 0) {
            requestMetadata.push(
                RequestMetadata(
                    _sender,
                    _receiver,
                    _threshold,
                    _status,
                    _result,
                    _proof
                )
            );
        } else {
            require(_id <= requestMetadata.length, "Invalid id provided");
            RequestMetadata storage _metadata = requestMetadata[_id - 1];
            _metadata.sender = _sender;
            _metadata.receiver = _receiver;
            _metadata.threshold = _threshold;
            _metadata.status = _status;
            _metadata.result = _result;
            _metadata.proof = _proof;
        }
    }

    function getLatestId() external view onlyOwner returns (uint256) {
        return requestMetadata.length;
    }

    function getRequestMetadata(
        uint256 _id
    ) external view returns (RequestMetadata memory) {
        require(
            _id != 0 && _id <= requestMetadata.length,
            "Invalid id provided"
        );
        return requestMetadata[_id - 1];
    }

    function getRequestMetadatas(
        uint256[] calldata _ids
    ) external view returns (RequestMetadata[] memory) {
        uint256 _requestMetadataLength = requestMetadata.length;
        for (uint256 _i = 0; _i < _ids.length; ) {
            uint256 _id = _ids[_i];
            require(
                _id != 0 && _id <= _requestMetadataLength,
                "One of the id provided is invalid"
            );
            unchecked {
                _i++;
            }
        }
        RequestMetadata[] memory _requestMetadatas = new RequestMetadata[](
            _ids.length
        );
        for (uint256 _i = 0; _i < _ids.length; ) {
            _requestMetadatas[_i] = requestMetadata[_ids[_i] - 1];
            unchecked {
                _i++;
            }
        }
        return _requestMetadatas;
    }

    function setRequests(
        string calldata _sender,
        string calldata _senderId,
        string calldata _receiver,
        string calldata _receiverId
    ) external onlyOwner {
        require(bytes(_sender).length != 0, "Request sender not provided");
        require(
            !this.isUniqueUsername(_sender),
            "Sender's account does not exist"
        );
        require(
            bytes(_senderId).length != 0,
            "Sender's request id not provided"
        );
        require(bytes(_receiver).length != 0, "Request receiver not provided");
        require(
            !this.isUniqueUsername(_receiver),
            "Receiver's account does not exist"
        );
        require(
            bytes(_receiverId).length != 0,
            "Receiver's request id not provided"
        );
        accounts[_sender].outgoingRequests.push(_senderId);
        accounts[_receiver].incomingRequests.push(_receiverId);
    }

    function getRequests(
        string calldata _username
    ) external view returns (string[][2] memory) {
        return [
            accounts[_username].incomingRequests,
            accounts[_username].outgoingRequests
        ];
    }

    function getIncomingRequests(
        string calldata _username
    ) external view returns (string[] memory) {
        return accounts[_username].incomingRequests;
    }

    function getOutgoingRequests(
        string calldata _username
    ) external view returns (string[] memory) {
        return accounts[_username].outgoingRequests;
    }
}