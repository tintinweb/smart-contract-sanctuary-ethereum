/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: RandomnessProvider/RFCoordinator.sol


pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";


interface IRandomnessConsumer {
    function fulfillRandomness(uint _randomId, uint[] calldata _randomValue)
        external;
}

contract RandomnessCoordinator is Ownable {
    uint private latestSub;
    uint public coordinatorRequestId;
    mapping(address => uint) public subIdOfContract;
    mapping(uint => address) public ownerOfSub;
    mapping(address => uint[]) public subsOfOwner;
    mapping(uint => uint) public balanceOfSub;
    uint public premium = 0.1 ether;
    mapping(uint => bool) public isDeleted;
    mapping(address => mapping(uint => bool)) public isRemoved; // consumer address => subId => isRemoved
    mapping(uint => address[]) public consumersOfSub;

    address public oracleAddress;

    event RequestRandomness(address, uint, uint,uint);

    constructor(address _oracleAddress) {
        oracleAddress = _oracleAddress;
    }

    function createSubscription() external payable returns (uint) {
        latestSub++;
        ownerOfSub[latestSub] = msg.sender;

        subsOfOwner[msg.sender].push(latestSub);
        balanceOfSub[latestSub] += msg.value;
        return latestSub;
    }

    function deleteSubscription(uint subId) external {
        require(
            msg.sender == ownerOfSub[subId],
            "You are not the owner of subscription"
        );
        ownerOfSub[subId] = address(0x0);
        uint amount = balanceOfSub[subId];
        balanceOfSub[subId] = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
        isDeleted[subId] = true;
    }

    function setOracleAddress(address _oracleAddress) external onlyOwner {
        oracleAddress = _oracleAddress;
    }

    function addConsumerToSubscription(uint subId, address contractAddress)
        external
    {
        require(
            msg.sender == ownerOfSub[subId],
            "You are not the owner of subscription"
        );
        subIdOfContract[contractAddress] = subId;
        consumersOfSub[subId].push(contractAddress);
    }

    function removeConsumerFromSubscription(uint subId, address contractAddress)
        external
    {
        require(
            msg.sender == ownerOfSub[subId],
            "You are not the owner of subscription"
        );
        subIdOfContract[contractAddress] = 0;
        isRemoved[contractAddress][subId] = true;
    }

    function depositToSub(uint subId) external payable {
        require(
            msg.sender == ownerOfSub[subId],
            "You are not the owner of subscription"
        );
        balanceOfSub[subId] += msg.value;
    }

    function withdrawFromSub(uint subId, uint amount) external payable {
        require(
            msg.sender == ownerOfSub[subId],
            "You are not the owner of subscription"
        );
        require(
            balanceOfSub[subId] >= amount,
            "Subscription does not have enough tokens"
        );
        balanceOfSub[subId] -= amount;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function requestRandomValue(uint randomId, uint randomValueCount)
        external
    {
        require(
            subIdOfContract[msg.sender] != 0,
            "Consumer is not subscribed!"
        );
        emit RequestRandomness(msg.sender, randomId,coordinatorRequestId, randomValueCount);
        coordinatorRequestId++;
    }

    /// @dev DEPRECATED, uses fulfillVerifiableRandomness 
    // function fulfillRandomness(
    //     uint _randomId,
    //     uint[] calldata _randomValue,
    //     address consumerAddress
    // ) external {
    //     require(msg.sender == oracleAddress, "Only Oracle Can Fulfill");
    //     require(
    //         subIdOfContract[consumerAddress] != 0,
    //         "Contract is not subscribed"
    //     );
    //     uint startGas = gasleft();
    //     IRandomnessConsumer(consumerAddress).fulfillRandomness(
    //         _randomId,
    //         _randomValue
    //     );
    //     uint endGas = startGas - gasleft();
    //     uint gasUsed = endGas * tx.gasprice;
    //     uint totalFee = gasUsed + premium;
    //     require(
    //         balanceOfSub[subIdOfContract[consumerAddress]] >= totalFee,
    //         "Subscription does not have enough tokens"
    //     );
    //     balanceOfSub[subIdOfContract[consumerAddress]] -= totalFee;
    //     (bool sent, ) = oracleAddress.call{value: gasUsed}("");
    //     require(sent, "Failed to send Ether");
    //     (sent, ) = owner().call{value: premium}("");
    //     require(sent, "Failed to send Ether");
    // }

    function fulfillVerifiableRandomness(
        uint _randomId,
        uint _noOfRandomWords,
        address consumerAddress,
        address randomSignerAddress,
        uint nextBlockNo,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        uint startGas = gasleft();
        require(msg.sender == oracleAddress, "Only Oracle Can Fulfill");
        require(
            subIdOfContract[consumerAddress] != 0,
            "Contract is not subscribed"
        );
        bytes32 hash = keccak256(abi.encodePacked(consumerAddress, _randomId, blockhash(nextBlockNo)));
        require(
            randomSignerAddress == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s),
            "Invalid Signer"
        );
        uint[] memory _randomValue = new uint[](_noOfRandomWords);
        for (uint i = 0; i < _noOfRandomWords; i++) {
            _randomValue[i] = uint256(keccak256(abi.encodePacked(hash, i)));
        }
        IRandomnessConsumer(consumerAddress).fulfillRandomness(
            _randomId,
            _randomValue
        );
        uint gasUsed = (startGas - gasleft()) * tx.gasprice;
        uint totalFee = gasUsed + premium;
        require(
            balanceOfSub[subIdOfContract[consumerAddress]] >= totalFee,
            "Subscription does not have enough tokens"
        );
        balanceOfSub[subIdOfContract[consumerAddress]] -= totalFee;
        (bool sent, ) = oracleAddress.call{value: gasUsed}("");
        require(sent, "Failed to send Ether");
        (sent, ) = owner().call{value: premium}("");
        require(sent, "Failed to send Ether");
    }

    function getBalanceOfSub(uint subId) external view returns (uint) {
        return balanceOfSub[subId];
    }

    function getSubscriptipnsOfOnwer(address _user)
        external
        view
        returns (uint[] memory subs, bool[] memory isDel)
    {
        subs = subsOfOwner[_user];
        bool[] memory temp = new bool[](subs.length);
        for (uint i; i < subs.length; i++) {
            temp[i] = isDeleted[subs[i]];
        }
        isDel = temp;
    }

    function getConsumersOfSubscription(uint subId)
        external
        view
        returns (address[] memory consumers, bool[] memory isRem)
    {
        consumers = consumersOfSub[subId];
        bool[] memory temp = new bool[](consumers.length);
        for (uint i; i < consumers.length; i++) {
            temp[i] = isRemoved[consumers[i]][subId];
        }
        isRem = temp;
    }
}