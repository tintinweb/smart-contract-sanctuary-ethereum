// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.8.0;

import {AnteTest} from "../AnteTest.sol";
import {LlamaPayFactory} from "./interfaces/LlamaPayFactory.sol";
import {LlamaPay} from "./interfaces/LlamaPay.sol";

/// @title  LlamaPay never goes back in time
/// @notice Ante Test to check that lastPayerUpdate <= block.timestamp holds
/// may no longer hold after 231,800 A.D.
contract AnteLlamaPayTest is AnteTest("Ante LlamaPay Test") {
    LlamaPayFactory internal factory;

    address public tokenAddress;
    address public payerAddress;

    constructor(address _llamaPayFactoryAddress) {
        factory = LlamaPayFactory(_llamaPayFactoryAddress);

        protocolName = "LlamaPay"; // <3
        testedContracts = [_llamaPayFactoryAddress];
        // wonder if could update this when user sets LlamaPay address
    }

    /// @notice checks that lastPayerUpdate <= block.timestamp for a given payer in a given LlamaPay instance
    /// @param payContractAddress address of specific LlamaPay instance to check
    /// @return true if lastPayerUpdate[payer] <= block.timestamp
    function checkSingle(address payContractAddress) public view returns (bool) {
        (uint40 lastPayerUpdate, ) = LlamaPay(payContractAddress).payers(payerAddress);

        // even if payer is not in the payer list for this LlamaPay instance, will return true (lastPayerUpdate = 0)
        return (lastPayerUpdate <= block.timestamp);
    }

    /// @notice Checks that lastPayerUpdate[payer] <= block.timestamp for a given payer and LlamaPay contract(s)
    ///         Uses the setter functions provided to set the token addresses and payer address to check
    ///         if 0x0 is passed as token address, will check through all LlamaPay contracts in factory
    ///         otherwise, will check for a the single LlamaPay instance provided
    /// @return true if lastPayerUpdate[payer] <= block.timestamp for all LlamaPay contracts checked
    function checkTestPasses() external view override returns (bool) {
        // if a valid token is specified, check payer for specific token llamapay contract
        if (tokenAddress != address(0)) {
            return checkSingle(factory.payContracts(tokenAddress));
        }

        // otherwise, if token address is 0x0, loop all tokens in llamapay factory
        for (uint256 i = 0; i < factory.payContractsArrayLength(); i++) {
            // if any llamapay instance fails, fail the test
            if (checkSingle(factory.payContractsArray(i)) == false) {
                return false;
            }
        }

        return true;
    }

    /*****************************************************
     * ================ USER INTERFACE ================= *
     *****************************************************/

    /// @notice Sets the payer address for the Ante Test to check
    /// @param _payerAddress address of payer to check
    function setPayerAddress(address _payerAddress) external {
        //check that payer address is valid?
        require(_payerAddress != address(0), "Invalid payer address");
        // TODO might be more thorough to loop through llamapay contracts and verify that at least one
        // instance of a valid payer mapping exists. but also an invalid payer address doesn't fail
        // the test so no risk of false positive

        payerAddress = _payerAddress;
    }

    /// @notice Sets the token address of the LlamaPay instance for the Ante Test to check
    /// @param _tokenAddress address of token to check LlamaPay instance for. If 0x0 is set,
    ///         the Ante Test will check all LlamaPay instances
    function setTokenAddress(address _tokenAddress) external {
        //check that token address exists in llamapayfactory list but allow 0x0 (all)
        if (_tokenAddress != address(0)) {
            require(
                factory.payContracts(_tokenAddress) != address(0),
                "LlamaPay contract for given token does not exist"
            );
        }

        tokenAddress = _tokenAddress;
        // also update testedContracts?
    }
}

// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity >=0.7.0;

import "./interfaces/IAnteTest.sol";

/// @title Ante V0.5 Ante Test smart contract
/// @notice Abstract inheritable contract that supplies syntactic sugar for writing Ante Tests
/// @dev Usage: contract YourAnteTest is AnteTest("String descriptor of test") { ... }
abstract contract AnteTest is IAnteTest {
    /// @inheritdoc IAnteTest
    address public override testAuthor;
    /// @inheritdoc IAnteTest
    string public override testName;
    /// @inheritdoc IAnteTest
    string public override protocolName;
    /// @inheritdoc IAnteTest
    address[] public override testedContracts;

    /// @dev testedContracts and protocolName are optional parameters which should
    /// be set in the constructor of your AnteTest
    /// @param _testName The name of the Ante Test
    constructor(string memory _testName) {
        testAuthor = msg.sender;
        testName = _testName;
    }

    /// @notice Returns the testedContracts array of addresses
    /// @return The list of tested contracts as an array of addresses
    function getTestedContracts() external view returns (address[] memory) {
        return testedContracts;
    }

    /// @inheritdoc IAnteTest
    function checkTestPasses() external virtual override returns (bool) {}
}

//SPDX-License-Identifier: None
//FROM https://github.com/0xngmi/llamapay/blob/78bf25ebabf16365b65e85b3818c4df12a228b1a/contracts/LlamaPayFactory.sol
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./LlamaPay.sol";

contract LlamaPayFactory is Ownable {
    mapping(address => address) public payContracts;
    mapping(uint256 => address) public payContractsArray;
    uint256 public payContractsArrayLength;

    event LlamaPayCreated(address token, address llamaPay);

    function createPayContract(address _token) external returns (address newContract) {
        require(payContracts[_token] == address(0), "already exists");
        newContract = address(new LlamaPay(_token, address(this)));
        payContracts[_token] = newContract;
        payContractsArray[payContractsArrayLength] = newContract;
        unchecked {
            payContractsArrayLength++;
        }
        emit LlamaPayCreated(_token, address(newContract));
    }
}

//SPDX-License-Identifier: None
//FROM https://github.com/0xngmi/llamapay/blob/78bf25ebabf16365b65e85b3818c4df12a228b1a/contracts/LlamaPay.sol
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Factory {
    function owner() external returns (address);
}

interface IERC20WithDecimals {
    function decimals() external view returns (uint8);
}

// All amountPerSec and all internal numbers use 20 decimals, these are converted to the right decimal on withdrawal/deposit
// The reason for that is to minimize precision errors caused by integer math on tokens with low decimals (eg: USDC)

// Invariant through the whole contract: lastPayerUpdate[anyone] <= block.timestamp
// Reason: timestamps can't go back in time (https://github.com/ethereum/go-ethereum/blob/master/consensus/ethash/consensus.go#L274)
// and we always set lastPayerUpdate[anyone] either to the current block.timestamp or a value lower than it

contract LlamaPay {
    struct Payer {
        uint40 lastPayerUpdate; // we will only hit overflow in year 231,800 so no need to worry
        uint216 totalPaidPerSec; // uint216 is enough to hold 1M streams of 3e51 tokens/yr, which is enough
    }

    mapping(bytes32 => uint256) public streamToStart;
    mapping(address => Payer) public payers;
    mapping(address => uint256) public balances; // could be packed together with lastPayerUpdate but gains are not high
    IERC20 public immutable token;
    address public immutable factory;
    uint256 public immutable DECIMALS_DIVISOR;

    event StreamCreated(address indexed from, address indexed to, uint216 amountPerSec, bytes32 streamId);
    event StreamCancelled(address indexed from, address indexed to, uint216 amountPerSec, bytes32 streamId);

    constructor(address _token, address _factory) {
        token = IERC20(_token);
        factory = _factory;
        uint8 tokenDecimals = IERC20WithDecimals(_token).decimals();
        DECIMALS_DIVISOR = 10**(20 - tokenDecimals);
    }

    function getStreamId(
        address from,
        address to,
        uint216 amountPerSec
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(from, to, amountPerSec));
    }

    function createStream(address to, uint216 amountPerSec) public {
        bytes32 streamId = getStreamId(msg.sender, to, amountPerSec);
        require(amountPerSec > 0, "amountPerSec can't be 0");
        require(streamToStart[streamId] == 0, "stream already exists");
        streamToStart[streamId] = block.timestamp;

        Payer storage payer = payers[msg.sender];
        uint256 totalPaid;
        unchecked {
            uint256 delta = block.timestamp - payer.lastPayerUpdate;
            totalPaid = delta * uint256(payer.totalPaidPerSec);
        }
        balances[msg.sender] -= totalPaid; // implicit check that balance >= totalPaid, can't create a new stream unless there's no debt

        payer.lastPayerUpdate = uint40(block.timestamp);
        payer.totalPaidPerSec += amountPerSec;

        // checking that no overflow will ever happen on totalPaidPerSec is important because if there's an overflow later:
        //   - if we don't have overflow checks -> it would be possible to steal money from other people
        //   - if there are overflow checks -> money will be stuck forever as all txs (from payees of the same payer) will revert
        //     which can be used to rug employees and make them unable to withdraw their earnings
        // Thus it's extremely important that no user is allowed to enter any value that later on could trigger an overflow.
        // We implicitly prevent this here because amountPerSec/totalPaidPerSec is uint216 and is only ever multiplied by timestamps
        // which will always fit in a uint40. Thus the result of the multiplication will always fit inside a uint256 and never overflow
        // This however introduces a new invariant: the only operations that can be done with amountPerSec/totalPaidPerSec are muls against timestamps
        // and we need to make sure they happen in uint256 contexts, not any other
        emit StreamCreated(msg.sender, to, amountPerSec, streamId);
    }

    /*
        proof that lastUpdate < block.timestamp:
        let's start by assuming the opposite, that lastUpdate > block.timestamp, and then we'll prove that this is impossible
        lastUpdate > block.timestamp
            -> timePaid = lastUpdate - lastPayerUpdate[from] > block.timestamp - lastPayerUpdate[from] = payerDelta
            -> timePaid > payerDelta
            -> payerBalance = timePaid * totalPaidPerSec[from] > payerDelta * totalPaidPerSec[from] = totalPayerPayment
            -> payerBalance > totalPayerPayment
        but this last statement is impossible because if it were true we'd have gone into the first if branch!
    */
    /*
        proof that totalPaidPerSec[from] != 0:
        totalPaidPerSec[from] is a sum of uint that are different from zero (since we test that on createStream())
        and we test that there's at least one stream active with `streamToStart[streamId] != 0`,
        so it's a sum of one or more elements that are higher than zero, thus it can never be zero
    */

    // Make it possible to withdraw on behalf of others, important for people that don't have a metamask wallet (eg: cex address, trustwallet...)
    function _withdraw(
        address from,
        address to,
        uint216 amountPerSec
    )
        private
        returns (
            uint40 lastUpdate,
            bytes32 streamId,
            uint256 amountToTransfer
        )
    {
        streamId = getStreamId(from, to, amountPerSec);
        require(streamToStart[streamId] != 0, "stream doesn't exist");

        Payer storage payer = payers[from];
        uint256 totalPayerPayment;
        unchecked {
            uint256 payerDelta = block.timestamp - payer.lastPayerUpdate;
            totalPayerPayment = payerDelta * uint256(payer.totalPaidPerSec);
        }
        uint256 payerBalance = balances[from];
        if (payerBalance >= totalPayerPayment) {
            unchecked {
                balances[from] = payerBalance - totalPayerPayment;
            }
            lastUpdate = uint40(block.timestamp);
        } else {
            // invariant: totalPaidPerSec[from] != 0
            unchecked {
                uint256 timePaid = payerBalance / uint256(payer.totalPaidPerSec);
                lastUpdate = uint40(payer.lastPayerUpdate + timePaid);
                // invariant: lastUpdate < block.timestamp (we need to maintain it)
                balances[from] = payerBalance % uint256(payer.totalPaidPerSec);
            }
        }
        uint256 delta = lastUpdate - streamToStart[streamId]; // Could use unchecked here too I think
        unchecked {
            // We push transfers to be done outside this function and at the end of public functions to avoid reentrancy exploits
            amountToTransfer = (delta * uint256(amountPerSec)) / DECIMALS_DIVISOR;
        }
    }

    // Copy of _withdraw that is view-only and returns how much can be withdrawn from a stream, purely for convenience on frontend
    // No need to review since this does nothing
    function withdrawable(
        address from,
        address to,
        uint216 amountPerSec
    )
        external
        view
        returns (
            uint256 withdrawableAmount,
            uint256 lastUpdate,
            uint256 owed
        )
    {
        bytes32 streamId = getStreamId(from, to, amountPerSec);
        require(streamToStart[streamId] != 0, "stream doesn't exist");

        Payer storage payer = payers[from];
        uint256 totalPayerPayment;
        unchecked {
            uint256 payerDelta = block.timestamp - payer.lastPayerUpdate;
            totalPayerPayment = payerDelta * uint256(payer.totalPaidPerSec);
        }
        uint256 payerBalance = balances[from];
        if (payerBalance >= totalPayerPayment) {
            lastUpdate = block.timestamp;
        } else {
            unchecked {
                uint256 timePaid = payerBalance / uint256(payer.totalPaidPerSec);
                lastUpdate = payer.lastPayerUpdate + timePaid;
            }
        }
        uint256 delta = lastUpdate - streamToStart[streamId];
        withdrawableAmount = (delta * uint256(amountPerSec)) / DECIMALS_DIVISOR;
        owed = ((block.timestamp - lastUpdate) * uint256(amountPerSec)) / DECIMALS_DIVISOR;
    }

    function withdraw(
        address from,
        address to,
        uint216 amountPerSec
    ) external {
        (uint40 lastUpdate, bytes32 streamId, uint256 amountToTransfer) = _withdraw(from, to, amountPerSec);
        streamToStart[streamId] = lastUpdate;
        payers[from].lastPayerUpdate = lastUpdate;
        token.transfer(to, amountToTransfer);
    }

    function cancelStream(address to, uint216 amountPerSec) public {
        (uint40 lastUpdate, bytes32 streamId, uint256 amountToTransfer) = _withdraw(msg.sender, to, amountPerSec);
        streamToStart[streamId] = 0;
        Payer storage payer = payers[msg.sender];
        unchecked {
            // totalPaidPerSec is a sum of items which include amountPerSec, so totalPaidPerSec >= amountPerSec
            payer.totalPaidPerSec -= amountPerSec;
        }
        payer.lastPayerUpdate = lastUpdate;
        emit StreamCancelled(msg.sender, to, amountPerSec, streamId);
        token.transfer(to, amountToTransfer);
    }

    function modifyStream(
        address oldTo,
        uint216 oldAmountPerSec,
        address to,
        uint216 amountPerSec
    ) external {
        // Can be optimized but I don't think extra complexity is worth it
        cancelStream(oldTo, oldAmountPerSec);
        createStream(to, amountPerSec);
    }

    function deposit(uint256 amount) public {
        balances[msg.sender] += amount * DECIMALS_DIVISOR;
        token.transferFrom(msg.sender, address(this), amount);
    }

    function depositAndCreate(
        uint256 amountToDeposit,
        address to,
        uint216 amountPerSec
    ) external {
        deposit(amountToDeposit);
        createStream(to, amountPerSec);
    }

    function withdrawPayer(uint256 amount) external {
        Payer storage payer = payers[msg.sender];
        balances[msg.sender] -= amount; // implicit check that balance > amount
        unchecked {
            uint256 delta = block.timestamp - payer.lastPayerUpdate;
            require(balances[msg.sender] >= delta * uint256(payer.totalPaidPerSec), "pls no rug");
            token.transfer(msg.sender, amount / DECIMALS_DIVISOR);
        }
    }

    function withdrawPayerAll() external {
        Payer storage payer = payers[msg.sender];
        uint256 totalPaid;
        unchecked {
            uint256 delta = block.timestamp - payer.lastPayerUpdate;
            totalPaid = delta * uint256(payer.totalPaidPerSec);
        }
        balances[msg.sender] -= totalPaid;
        unchecked {
            token.transfer(msg.sender, balances[msg.sender] / DECIMALS_DIVISOR);
        }
    }

    function getPayerBalance(address payerAddress) external view returns (int256) {
        Payer storage payer = payers[payerAddress];
        int256 balance = int256(balances[payerAddress]);
        uint256 delta = block.timestamp - payer.lastPayerUpdate;
        return (balance - int256(delta * uint256(payer.totalPaidPerSec))) / int256(DECIMALS_DIVISOR);
    }

    // Performs an arbitrary call
    // This will be under a heavy timelock and only used in case something goes very wrong (eg: with yield engine)
    function emergencyRug(address to, uint256 amount) external {
        require(Factory(factory).owner() == msg.sender, "not owner");
        if (amount == 0) {
            amount = token.balanceOf(address(this));
        }
        token.transfer(to, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity >=0.7.0;

/// @title The interface for the Ante V0.5 Ante Test
/// @notice The Ante V0.5 Ante Test wraps test logic for verifying fundamental invariants of a protocol
interface IAnteTest {
    /// @notice Returns the author of the Ante Test
    /// @dev This overrides the auto-generated getter for testAuthor as a public var
    /// @return The address of the test author
    function testAuthor() external view returns (address);

    /// @notice Returns the name of the protocol the Ante Test is testing
    /// @dev This overrides the auto-generated getter for protocolName as a public var
    /// @return The name of the protocol in string format
    function protocolName() external view returns (string memory);

    /// @notice Returns a single address in the testedContracts array
    /// @dev This overrides the auto-generated getter for testedContracts [] as a public var
    /// @param i The array index of the address to return
    /// @return The address of the i-th element in the list of tested contracts
    function testedContracts(uint256 i) external view returns (address);

    /// @notice Returns the name of the Ante Test
    /// @dev This overrides the auto-generated getter for testName as a public var
    /// @return The name of the Ante Test in string format
    function testName() external view returns (string memory);

    /// @notice Function containing test logic to inspect the protocol invariant
    /// @dev This should usually return True
    /// @return A single bool indicating if the Ante Test passes/fails
    function checkTestPasses() external returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}