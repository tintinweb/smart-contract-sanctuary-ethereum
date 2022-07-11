// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Ownable} from "./utils/Ownable.sol";

interface IDpdRepository {
    function updateDpd(uint256 dpdId, bytes memory cid)
        external
        returns (uint256);
}

// incomplete, need to add update and remove bid functionality
contract Bid is Ownable {
    struct BidOrder {
        bytes cid;
        address owner;
        uint256 amount;
    }

    // dpd id -> bid orders
    mapping(uint256 => BidOrder[]) public bids;
    // dpd id -> closed
    mapping(uint256 => bool) public closedBids;
    // dpd id -> max bid amount
    mapping(uint256 => uint256) public maxBids;
    // dpd id -> owner -> index
    mapping(uint256 => mapping(address => uint256)) bidders;

    address public dpdRepository;

    error BidExists();
    error NoBids();
    error FailSend();
    error ZeroAmount();
    error ZeroAddress();
    error BidClosed();
    error LessThanMaxBid();

    event AddBid(uint256 _dpdId, bytes _cid, address _owner, uint256 _amount);
    event CloseBid(uint256 _dpdId, bytes _cid, address _owner, uint256 _amount);
    event SetDpdRepository(
        address _oldDpdRepository,
        address _newDpdRepository
    );

    constructor(address _dpdRepository) {
        dpdRepository = _dpdRepository;
    }

    function addBid(
        uint256 _dpdId,
        address _owner,
        bytes calldata _cid
    ) external payable {
        if (_owner == address(0)) {
            revert ZeroAddress();
        }

        if (msg.value == 0) {
            revert ZeroAmount();
        }

        if (msg.value <= maxBids[_dpdId]) {
            revert LessThanMaxBid();
        }

        // if ((bids[_dpdId][0].owner == _owner) || bidders[_dpdId][_owner] > 0) {
        //     revert BidExists();
        // }

        maxBids[_dpdId] = msg.value;
        bids[_dpdId].push(BidOrder(_cid, _owner, msg.value));
        bidders[_dpdId][_owner] = bids[_dpdId].length - 1;

        emit AddBid(_dpdId, _cid, _owner, msg.value);
    }

    // @todo add some restrictive logic here, e.g. can only close the bid after a week
    function closeBid(uint256 _dpdId) external {
        if (bids[_dpdId].length == 0) {
            revert NoBids();
        }

        if (closedBids[_dpdId]) {
            revert BidClosed();
        }

        closedBids[_dpdId] = true;

        // the last bid is always the biggest
        BidOrder memory maxBid = bids[_dpdId][bids[_dpdId].length - 1];

        IDpdRepository(dpdRepository).updateDpd(_dpdId, maxBid.cid);
        emit CloseBid(_dpdId, maxBid.cid, maxBid.owner, maxBid.amount);
    }

    function getBids(uint256 dpdId) external view returns (BidOrder[] memory) {
        return bids[dpdId];
    }

    function withdraw() external onlyOwner {
        (bool sent, ) = address(msg.sender).call{value: address(this).balance}(
            ""
        );

        if (!sent) {
            revert FailSend();
        }
    }

    function setDpdRepository(address _dpdRepository) external onlyOwner {
        address oldDpdRepository = dpdRepository;
        dpdRepository = _dpdRepository;
        emit SetDpdRepository(oldDpdRepository, _dpdRepository);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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