/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

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
// File: @chainlink/contracts/src/v0.6/VRFRequestIDBase.sol

pragma solidity ^0.8.0;

contract VRFRequestIDBase {
    function makeVRFInputSeed(
        bytes32 _keyHash,
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure returns (uint256) {
        return
            uint256(
                keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce))
            );
    }

    function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
}

// File: @chainlink/contracts/src/v0.6/interfaces/LinkTokenInterface.sol

pragma solidity ^0.8.0;

interface LinkTokenInterface {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 value)
        external
        returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue)
        external
        returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue)
        external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value)
        external
        returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

// File: @chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol


pragma solidity ^0.8.0;

library SafeMathChainlink {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: @chainlink/contracts/src/v0.6/VRFConsumerBase.sol


pragma solidity ^0.8.0;

abstract contract VRFConsumerBase is VRFRequestIDBase {
    using SafeMathChainlink for uint256;

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        virtual;

    /**
     * @dev In order to keep backwards compatibility we have kept the user
     * seed field around. We remove the use of it because given that the blockhash
     * enters later, it overrides whatever randomness the used seed provides.
     * Given that it adds no security, and can easily lead to misunderstandings,
     * we have removed it from usage and can now provide a simpler API.
     */
    uint256 private constant USER_SEED_PLACEHOLDER = 0;

    function requestRandomness(bytes32 _keyHash, uint256 _fee)
        internal
        returns (bytes32 requestId)
    {
        LINK.transferAndCall(
            vrfCoordinator,
            _fee,
            abi.encode(_keyHash, USER_SEED_PLACEHOLDER)
        );
        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        uint256 vRFSeed = makeVRFInputSeed(
            _keyHash,
            USER_SEED_PLACEHOLDER,
            address(this),
            nonces[_keyHash]
        );
        // nonces[_keyHash] must stay in sync with
        // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
        // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
        // This provides protection against the user repeating their input seed,
        // which would result in a predictable/duplicate output, if multiple such
        // requests appeared in the same block.
        nonces[_keyHash] = nonces[_keyHash].add(1);
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface internal immutable LINK;
    address private immutable vrfCoordinator;

    // Nonces for each VRF key from which randomness has been requested.
    //
    // Must stay in sync with VRFCoordinator[_keyHash][this]
    mapping(bytes32 => uint256) /* keyHash */ /* nonce */
        private nonces;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     * @param _link address of LINK token contract
     *
     * @dev https://docs.chain.link/docs/link-token-contracts
     */
    constructor(address _vrfCoordinator, address _link){
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness)
        external
    {
        require(
            msg.sender == vrfCoordinator,
            "Only VRFCoordinator can fulfill"
        );
        fulfillRandomness(requestId, randomness);
    }
}

pragma solidity ^0.8.0;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.8.0;

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(){
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract LotteryContract is VRFConsumerBase, Ownable {
    using Counters for Counters.Counter;

    struct Lottery {
        uint256 lotteryId;
        address[] participants;
        address[] winners;
        bool isFinished;
        uint256 endDate;
        uint256 noOfWinner;
        uint256 randomValue;
    }

    struct Random {
        uint256 lotteryId;
        bytes32 request;
        uint256 randomValue;
        uint256 timeStamp;
        string fileHash;
        uint256 _requestNumber;
        bool requested;
    }

    mapping(uint256 => Random) public random;

    Counters.Counter public lotteryId;
    mapping(uint256 => Lottery) private lotteries;
    mapping(bytes32 => uint256) private lotteryRandomnessRequest;
    mapping(uint256 => mapping(address => uint256)) public participatedUsers; //participations per player
    mapping(uint256 => uint256) uniqueParticipations;
    uint256 public requestNumber;
    bytes32 private keyHash;
    uint256 private fee;

    event RandomnessRequested(bytes32, uint256);
    event WinnerDeclared(bytes32, uint256, address);
    // event PrizeIncreased(uint256, uint256);
    event LotteryCreated(uint256, uint256);

    constructor()
        VRFConsumerBase(
            0xa555fC018435bef5A13C6c6870a9d4C11DEC329C, // VRF Coordinator
            0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06 // LINK Token
        )
    {
        keyHash = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186;
        fee = 0.1 * 10**18; // 0.1 LINK (Varies by network)
    }

    function createLottery(uint256 _endTime, uint256 _noOfWinner)
        public onlyOwner
    {
        require(_endTime > 0, "Lottery time must be greater than 0");
        Lottery memory lottery = Lottery({
            lotteryId: lotteryId.current(),
            participants: new address[](0),
            winners: new address[](0),
            isFinished: false,
            endDate: _endTime,
            noOfWinner: _noOfWinner,
            randomValue: 0
        });
        lotteries[lotteryId.current()] = lottery;
        lotteryId.increment();
        emit LotteryCreated(lottery.lotteryId, lottery.endDate);
    }

    function participate(uint256 _lotteryId) public {
        Lottery storage lottery = lotteries[_lotteryId];
        require(
            block.timestamp < lottery.endDate,
            "Lottery participation is closed"
        );
        lottery.participants.push(msg.sender);
        uint256 uniqueP = participatedUsers[_lotteryId][msg.sender];
        if (uniqueP == 0) {
            uniqueParticipations[_lotteryId]++;
        }
        participatedUsers[_lotteryId][msg.sender]++;
    }

    function updateUsers(
        uint256 _lotteryId,
        address[] memory _users,
        uint256[] memory _tickets
    ) external onlyOwner{
        require(_users.length == _tickets.length, "Array length mismatch");
        Lottery storage lottery = lotteries[_lotteryId];
        require(
            block.timestamp < lottery.endDate,
            "Lottery participation is closed"
        );
        for (uint256 i = 0; i < _users.length; i++) {
            for (uint256 j = 0; j < _tickets[i]; j++) {
                lottery.participants.push(_users[i]);
                uint256 uniqueP = participatedUsers[_lotteryId][_users[i]];
                if (uniqueP == 0) {
                    uniqueParticipations[_lotteryId]++;
                }
                participatedUsers[_lotteryId][_users[i]]++;
            }
        }
    }

    function declareWinner(uint256 _lotteryId) public onlyOwner{
        Lottery storage lottery = lotteries[_lotteryId];
        require(block.timestamp > lottery.endDate, "Lottery is still active");
        require(!lottery.isFinished, "Lottery has already declared a winner");
        if (uniqueParticipations[_lotteryId] == 1) {
            require(
                lottery.participants[0] != address(0),
                "There has been no participation in this lottery"
            );
            lottery.winners[0] = lottery.participants[0];
            lottery.isFinished = true;
        } else {
            require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
            bytes32 requestId = requestRandomness(keyHash, fee);
            requestNumber++;
            random[requestNumber].lotteryId = _lotteryId;
            random[requestNumber]._requestNumber = requestNumber;
            random[requestNumber].requested = true;
            lotteryRandomnessRequest[requestId] = _lotteryId;
            emit RandomnessRequested(requestId, _lotteryId);
        }
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        random[requestNumber].request = requestId;
        random[requestNumber].randomValue = randomness;
        random[requestNumber].timeStamp = block.timestamp;

        uint256 _lotteryId = lotteryRandomnessRequest[requestId];
        Lottery storage lottery = lotteries[_lotteryId];
        lottery.randomValue = randomness;
        for (uint256 k = 0; k < lottery.noOfWinner; k++) {
            uint256 winnerIndex = uint256(keccak256(abi.encode(randomness, k))) % lottery.participants.length;
            address winnerAddr = lottery.participants[winnerIndex];
            lottery.winners[k] = winnerAddr;
            for (uint256 j = 0; j < lottery.participants.length; j++) {
                if (winnerAddr == lottery.participants[j]) {
                    for (
                        uint256 i = j;
                        i < lottery.participants.length - 1;
                        i++
                    ) {
                        lottery.participants[i] = lottery.participants[i + 1];
                    }
                    lottery.participants.pop();
                    j--;
                }
            }
        }

        lottery.isFinished = true;
        delete lotteryRandomnessRequest[requestId];
    }

    function getWinner(uint256 _lotteryId)
        public
        view
        returns (address[] memory winners)
    {
        Lottery storage lottery = lotteries[_lotteryId];
        for (uint256 i = 0; i < lottery.winners.length; i++) {
            winners[i] = lottery.winners[i];
        }
        return winners;
    }
}