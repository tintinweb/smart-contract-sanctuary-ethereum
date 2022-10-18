// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "./libraries/TableHelper.sol";
import "./IOneHiTableLogic.sol";
import "./IOneHiController.sol";
import "./IFractonSwap.sol";
import "./OneHiEvent.sol";

contract OneHiController is Ownable, VRFConsumerBaseV2, IOneHiController, OneHiEvent {

    struct Record {
        uint256 number;
        address player;
    }

    struct TableInfo {
        Record[] records;
        address nftAddr;
        address winner;
        address maker;
        address lucky;
        uint256 time;
        uint256 targetAmount;
    }

    struct ChainLinkVrfParam {
        VRFCoordinatorV2Interface vrfCoordinator;
        uint16 requestConfirmations;
        bytes32 keyHash;
        uint32 callbackGasLimit;
        uint32 numWords;
        uint64 subscriptionId;
    }

    struct NFTInfo {
        bool isSupport;
        uint256 createTableFee;
        address miniNftAddr;
        address fftAddr;
    }

    address private fractonSwapAddr;
    address private vaultAddr;
    address public implTableAddr;

    mapping(address=>NFTInfo) public nftAddr2nftInfo;
    mapping(address=>TableInfo) public tableAddr2Info;
    
    uint8 private splitProfitRatio = 50;
    uint8 private luckySplitProfitRatio = 80;
    uint256 public minTargetAmount = 1_050_000;

    //ChainLink VRF
    ChainLinkVrfParam public chainLinkVrfParam;
    mapping(uint256=>address) private requestId2Table;

    constructor(address _implTableAddr, address _fractonSwapAddr, address _vaultAddr,
        address _vrfCoordinator, bytes32 _keyHash, uint64 _subscriptionId
    ) VRFConsumerBaseV2(_vrfCoordinator) {

        implTableAddr = _implTableAddr;
        fractonSwapAddr = _fractonSwapAddr;
        vaultAddr = _vaultAddr;

        chainLinkVrfParam.vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        chainLinkVrfParam.numWords = 1;
        chainLinkVrfParam.callbackGasLimit = 1000000;
        chainLinkVrfParam.requestConfirmations = 3;
        chainLinkVrfParam.subscriptionId = _subscriptionId;
        chainLinkVrfParam.keyHash = _keyHash;
    }

    error InvalidChainLinkVrfParam(ChainLinkVrfParam);

    function _requestRandom(address tableAddr) internal {
        uint256 requestId = chainLinkVrfParam.vrfCoordinator.requestRandomWords(
            chainLinkVrfParam.keyHash,
            chainLinkVrfParam.subscriptionId,
            chainLinkVrfParam.requestConfirmations,
            chainLinkVrfParam.callbackGasLimit,
            chainLinkVrfParam.numWords
        );
        requestId2Table[requestId] = tableAddr;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal virtual override {
        address tableAddr = requestId2Table[requestId];
        _pickUpWinner(tableAddr, randomWords[0]);
    }

    function _pickUpWinner(address tableAddr, uint256 randomWord) internal {
        uint256 left = 0;
        uint256 right = tableAddr2Info[tableAddr].records.length - 1;

        uint256 middle;
        uint256 middleNumber;

        uint256 random = (randomWord % tableAddr2Info[tableAddr].targetAmount) + 1;
        uint256 winnerNumber = random;

        while (true) {
            if (right - left <= 1) {
                if (random <= tableAddr2Info[tableAddr].records[left].number) {
                    tableAddr2Info[tableAddr].winner = tableAddr2Info[tableAddr].records[left].player;
                } else {
                    tableAddr2Info[tableAddr].winner = tableAddr2Info[tableAddr].records[right].player;
                }
                break;
            } else {
                middle = (right + left) / 2;
                middleNumber = tableAddr2Info[tableAddr].records[middle].number;

                if (middleNumber == random) {
                    tableAddr2Info[tableAddr].winner = tableAddr2Info[tableAddr].records[middle].player;
                    break;
                }

                if (middleNumber < random) {
                    left = middle;
                } else {
                    right = middle;
                }
            }
        }
        _emitChooseWinnerEvent(tableAddr, tableAddr2Info[tableAddr].winner, winnerNumber);
    }

    function createTable(address nftAddr, uint256 targetAmount, bytes32 salt) external {
        require(nftAddr2nftInfo[nftAddr].isSupport, "not support nft-address");
        require(targetAmount >= minTargetAmount, "minTargetAmount not met");
        address fftAddr = nftAddr2nftInfo[nftAddr].fftAddr;
        require(IERC20(fftAddr).transferFrom(msg.sender, vaultAddr, nftAddr2nftInfo[nftAddr].createTableFee));

        address tableAddr = Create2.deploy(
            0,
            salt,
            TableHelper.getBytecode(implTableAddr)
        );

        require(tableAddr != address(0), "tableAddr deploy failed");

        IOneHiTableLogic(tableAddr).initialize(address(this), fftAddr);

        tableAddr2Info[tableAddr].nftAddr = nftAddr;
        tableAddr2Info[tableAddr].maker = msg.sender;
        tableAddr2Info[tableAddr].time = block.timestamp;
        tableAddr2Info[tableAddr].targetAmount = targetAmount;

        _emitCreateTableEvent(tableAddr, msg.sender, nftAddr, targetAmount);

        buyTickets(tableAddr, targetAmount * 5 / 10000);
    }

    function buyTickets(address tableAddr, uint256 ticketsAmount) public returns(uint256) {
        require(ticketsAmount > 0);
        address nftAddr = tableAddr2Info[tableAddr].nftAddr;
        require(nftAddr != address(0), "Invalid tableAddr");

        require(block.timestamp <= (tableAddr2Info[tableAddr].time + 4 hours), "Table is timeout");
        tableAddr2Info[tableAddr].time = block.timestamp;

        uint256 amount = tableAddr2Info[tableAddr].targetAmount - getTableAccumulation(tableAddr);
        require(amount > 0, "Controller: table is finished.");
        if (amount < ticketsAmount) {
            ticketsAmount = amount;
        }
        require(IERC20(nftAddr2nftInfo[nftAddr].fftAddr).transferFrom(msg.sender, tableAddr,
            ticketsAmount * 1e18));

        _buyTickets(tableAddr, ticketsAmount);
        return ticketsAmount;
    }

    function _buyTickets(address tableAddr, uint256 actualAmount) internal {
        Record[] storage records = tableAddr2Info[tableAddr].records;
        uint256 accumulation;
        if (records.length != 0) {
            accumulation = records[records.length - 1].number;
        }

        uint256 targetAmount = tableAddr2Info[tableAddr].targetAmount;
        uint256 afterAmount = accumulation + actualAmount;
        records.push(Record(afterAmount, msg.sender));

        _emitBuyTicketsEvent(tableAddr, msg.sender, accumulation+1, afterAmount);

        if (afterAmount == targetAmount) {
            _emitUpToTargetAmountEvent(tableAddr);
            _liquidate(tableAddr);
        }
    }
    function _liquidate(address tableAddr) internal {
        address nftAddr = tableAddr2Info[tableAddr].nftAddr;
        _swapNFT(tableAddr, nftAddr, nftAddr2nftInfo[nftAddr].miniNftAddr,
            nftAddr2nftInfo[nftAddr].fftAddr);
        _splitProfit(tableAddr, nftAddr2nftInfo[nftAddr].fftAddr);
        _requestRandom(tableAddr);
    }
    function _swapNFT(address tableAddr, address nftAddr, address miniNFTAddr, address fftAddr) internal {
        uint256 miniNFTAmount = 1000 + IFractonSwap(fractonSwapAddr).nftTax();

        IOneHiTableLogic(tableAddr).swapNFT(fractonSwapAddr, fftAddr, miniNFTAddr, miniNFTAmount,
            nftAddr);
    }
    function _splitProfit(address tableAddr, address fftAddr) internal {
        uint256 balance = IERC20(fftAddr).balanceOf(tableAddr);
        uint256 profitOfMaker = balance * splitProfitRatio / 100;
        uint256 profitOfVault = balance - profitOfMaker;

        require(IERC20(fftAddr).transferFrom(tableAddr, tableAddr2Info[tableAddr].maker, profitOfMaker));
        require(IERC20(fftAddr).transferFrom(tableAddr, vaultAddr, profitOfVault));
        _emitSplitProfitEvent(tableAddr, tableAddr2Info[tableAddr].maker,
            profitOfMaker, vaultAddr, profitOfVault);
    }

    function claimTreasure(address tableAddr, uint256 tokenId) external {
        address nftAddr = tableAddr2Info[tableAddr].nftAddr;
        require(tableAddr2Info[tableAddr].winner != address(0));
        require(tableAddr2Info[tableAddr].winner == msg.sender, "winner is invalid");
        require(IOneHiTableLogic(tableAddr).claimTreasure(msg.sender, nftAddr, tokenId));
        _emitClaimTreasureEvent(tableAddr);
    }

    function luckyClaim(address tableAddr) external {
        address nftAddr = tableAddr2Info[tableAddr].nftAddr;
        require(nftAddr != address(0), "TableAddr is invalid");
        address fftAddr = nftAddr2nftInfo[nftAddr].fftAddr;

        Record[] storage records = tableAddr2Info[tableAddr].records;
        require(block.timestamp > (tableAddr2Info[tableAddr].time + 4 hours), "Table isn't timeout");
        require(records.length != 0, "Table is empty");
        require(msg.sender == records[records.length - 1].player, "invalid luckyAddr");
        require(records[records.length - 1].number != tableAddr2Info[tableAddr].targetAmount, "Table is full");

        tableAddr2Info[tableAddr].lucky = msg.sender;
        uint256 balance = IERC20(fftAddr).balanceOf(tableAddr);
        require(balance > 0, "table balance is zero");
        uint256 profitOfLucky = balance * luckySplitProfitRatio / 100;
        uint256 profitOfVault = balance - profitOfLucky;

        require(IERC20(fftAddr).transferFrom(tableAddr, msg.sender, profitOfLucky));
        require(IERC20(fftAddr).transferFrom(tableAddr, vaultAddr, profitOfVault));
        _emitLuckyClaimEvent(tableAddr);
        _emitSplitProfitEvent(tableAddr, msg.sender, profitOfLucky, vaultAddr, profitOfVault);
    }

    function updateHiStatus(address nftAddr, bool isSupport, uint256 createTableFee) external onlyOwner {
        address miniNftAddr = IFractonSwap(fractonSwapAddr).NFTtoMiniNFT(nftAddr);
        require(miniNftAddr != address(0), "miniNftAddr is zero");
        address fftAddr = IFractonSwap(fractonSwapAddr).miniNFTtoFFT(miniNftAddr);
        require(fftAddr != address(0), "fftAddr is zero");

        nftAddr2nftInfo[nftAddr].isSupport = isSupport;
        nftAddr2nftInfo[nftAddr].createTableFee = createTableFee * 1e18;
        nftAddr2nftInfo[nftAddr].miniNftAddr = miniNftAddr;
        nftAddr2nftInfo[nftAddr].fftAddr = fftAddr;
        _emitUpdateHiStatusEvent(nftAddr, miniNftAddr, fftAddr, isSupport, createTableFee*1e18);
    }

    function updateSplitProfitRatio(uint8 _splitProfitRatio) external onlyOwner {
        splitProfitRatio = _splitProfitRatio;
        _emitUpdateRatio(splitProfitRatio, luckySplitProfitRatio);
    }

    function updateLuckySplitProfitRatio(uint8 _luckySplitProfitRatio) external onlyOwner {
        luckySplitProfitRatio = _luckySplitProfitRatio;
        _emitUpdateRatio(splitProfitRatio, luckySplitProfitRatio);
    }

    function updateVaultAddr(address _vaultAddr) external onlyOwner {
        vaultAddr = _vaultAddr;
    }

    function updateVrfParam(ChainLinkVrfParam memory _chainLinkVrfParam) external onlyOwner {
        if (chainLinkVrfParam.numWords == 0 || chainLinkVrfParam.callbackGasLimit == 0 ||
            chainLinkVrfParam.requestConfirmations == 0 ||
            address(chainLinkVrfParam.vrfCoordinator) == address(0)) {
            revert InvalidChainLinkVrfParam(_chainLinkVrfParam);
        }

        chainLinkVrfParam = _chainLinkVrfParam;
    }

    //table
    function getFractonSwapAddr() external view returns(address) {
        return fractonSwapAddr;
    }
    function getVaultAddr() external view returns(address) {
        return vaultAddr;
    }
    function getSplitProfitRatio() external view returns(uint256) {
        return splitProfitRatio;
    }
    function getLuckySplitProfitRatio() external view returns(uint256) {
        return luckySplitProfitRatio;
    }

    function getTableAccumulation(address tableAddr) public view returns(uint256) {
        if (tableAddr2Info[tableAddr].records.length == 0) {
            return 0;
        }
        return tableAddr2Info[tableAddr].records[tableAddr2Info[tableAddr].records.length - 1].number;
    }

    function getTableLucky(address tableAddr) external view returns(address) {
        require(block.timestamp > (tableAddr2Info[tableAddr].time + 4 hours), "Table isn't timeout");
        require(tableAddr2Info[tableAddr].records.length != 0, "Table is empty");

        return tableAddr2Info[tableAddr].records[tableAddr2Info[tableAddr].records.length - 1].player;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOneHiTableLogic {
    function initialize(address _controller, address fftAddr) external;
    function claimTreasure(address player, address nftAddr, uint256 tokenId) external returns(bool);
    function swapNFT(address fractonSwapAddr, address fftAddr, address miniNFTAddr, uint256 miniNFTAmount,
        address nftAddr) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IFractonSwap {
    function nftTax() external view returns(uint256);
    function swapFFTtoMiniNFT(address miniNFTAddress, uint256 miniNFTAmount) external returns(bool);
    function swapMiniNFTtoNFT(address nftAddr) external returns(bool);
    function NFTtoMiniNFT(address nftAddr) external view returns(address);
    function miniNFTtoFFT(address miniNFT) external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract OneHiEvent {
    event CreateTable(address tableAddr, address makerAddr, address nftAddr, uint256 targetAmount);
    event BuyTickets(address tableAddr, address player, uint256 start, uint256 end);
    event UpdateHiStatus(address nftAddr, address miniNFTAddr, address fftAddr,
        bool isSupport, uint256 createTableFee);
    event UpToTargetAmount(address tableAddr);
    event ChooseWinner(address tableAddr, address winner, uint256 winnerNumber);
    event ClaimTreasure(address tableAddr);
    event LuckyClaim(address tableAddr);
    event SplitProfit(address tableAddr, address makerAddr, uint256 makeAmount, address vaultAddr, uint256 vaultAmount);
    event UpdateRatio(uint8 splitProfitRatio, uint8 luckySplitProfitRatio);

    function _emitCreateTableEvent(address tableAddr, address makerAddr, address nftAddr,
        uint256 targetAmount) internal {
        emit CreateTable(tableAddr, makerAddr, nftAddr, targetAmount);
    }
    function _emitUpdateHiStatusEvent(address nftAddr, address miniNFTAddr, address fftAddr,
        bool isSupport, uint256 createTableFee) internal {
        emit UpdateHiStatus(nftAddr, miniNFTAddr, fftAddr, isSupport, createTableFee);
    }
    function _emitBuyTicketsEvent(address tableAddr, address player, uint256 start, uint256 end) internal {
        emit BuyTickets(tableAddr, player, start, end);
    }
    function _emitUpToTargetAmountEvent(address tableAddr) internal {
        emit UpToTargetAmount(tableAddr);
    }
    function _emitChooseWinnerEvent(address tableAddr, address winner, uint256 winnerNumber) internal {
        emit ChooseWinner(tableAddr, winner, winnerNumber);
    }
    function _emitClaimTreasureEvent(address tableAddr) internal {
        emit ClaimTreasure(tableAddr);
    }
    function _emitLuckyClaimEvent(address tableAddr) internal {
        emit LuckyClaim(tableAddr);
    }
    function _emitSplitProfitEvent(address tableAddr, address makerAddr, uint256 makerAmount, address vaultAddr, uint256 vaultAmount) internal {
        emit SplitProfit(tableAddr, makerAddr, makerAmount, vaultAddr, vaultAmount);
    }
    function _emitUpdateRatio(uint8 splitProfitRatio, uint8 luckySplitProfitRatio) internal {
        emit UpdateRatio(splitProfitRatio, luckySplitProfitRatio);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOneHiController {
    function createTable(address nftAddr, uint256 targetAmount, bytes32 salt) external;
    function buyTickets(address tableAddr, uint256 amount) external returns(uint256);
    function claimTreasure(address tableAddr, uint256 tokenId) external;
    function luckyClaim(address tableAddr) external;
    //table
    function getFractonSwapAddr() external view returns(address);
    function getVaultAddr() external view returns(address);
    function getSplitProfitRatio() external view returns(uint256);
    function getLuckySplitProfitRatio() external view returns(uint256);
    //frontend
    function getTableAccumulation(address tableAddr) external view returns(uint256);
    function getTableLucky(address tableAddr) external view returns(address);


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../OneHiTable.sol";

library TableHelper {
    function getBytecode(address implTableAddr) public pure returns (bytes memory) {
        bytes memory bytecode = type(OneHiTable).creationCode;
        return abi.encodePacked(bytecode, abi.encode(implTableAddr));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
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
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.9;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract OneHiTable is Proxy {

    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(
        address _implAddr
    ) {
        _setImplementation(_implAddr);
    }

    function _implementation() internal view override returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
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