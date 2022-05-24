// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Crowdfund is Ownable {
    struct Request {
        string description;
        uint256 value;
        address payable recipient;
        bool isComplete;
        uint256 approvalCount;
        mapping(address => bool) hasApproved;
    }

    uint256 public minimumContribution;
    uint256 approversCount;
    uint256 public requestId;
    mapping(address => bool) public approvers;
    mapping(uint256 => Request) public requests;

    constructor(uint256 _minAmount, address _manager) {
        minimumContribution = _minAmount;
        transferOwnership(_manager);
    }

    function manager() external view returns (address _manager) {
        _manager = owner();
    }

    function contribute() public payable {
        require(msg.value > minimumContribution, "You need to send more ETH!");
        approvers[msg.sender] = true;
        approversCount++;
    }

    function createRequest(
        string calldata _description,
        uint256 _value,
        address payable _recipient
    ) external onlyOwner {
        Request storage newRequest = requests[requestId];
        requestId++;

        newRequest.description = _description;
        newRequest.value = _value;
        newRequest.recipient = _recipient;
        newRequest.isComplete = false;
        newRequest.approvalCount = 0;
    }

    function approveRequest(uint256 _requestId) external {
        Request storage request = requests[_requestId];

        require(
            approvers[msg.sender],
            "You do not have permission to approve this request!"
        );
        require(request.value != 0, "This request does not exist!");
        require(
            !request.hasApproved[msg.sender],
            "You've already voted on this request!"
        );

        request.approvalCount++;
        request.hasApproved[msg.sender] = true;
    }

    function finaliseRequest(uint256 _requestId) external onlyOwner {
        Request storage request = requests[_requestId];

        require(request.approvalCount > (approversCount / 2));
        require(
            !request.isComplete,
            "This request has already been completed!"
        );

        request.isComplete = true;
        (bool success, ) = request.recipient.call{value: request.value}("");
        require(success, "Tx failed to send funds to recipient!");
    }

    receive() external payable {
        contribute();
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