// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
// import "hardhat/console.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import "./trade_utils.sol";

/**
 * Math operations with safety checks
 */
library SafeMath {
    string private constant ERROR_MESSAGE = "SafeMath exception";
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b, ERROR_MESSAGE);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, ERROR_MESSAGE);
        uint256 c = a / b;
        require(a == b * c + a % b, ERROR_MESSAGE);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, ERROR_MESSAGE);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c>=a && c>=b, ERROR_MESSAGE);
        return c;
    }
}

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.safeSub(1);
    }
}


/**
 * @dev Interface of the contract capable of checking if an instruction is
 * confirmed over at Incognito Chain
 */
interface Incognito {
    function instructionApproved(
        bool,
        bytes32,
        uint,
        bytes32[] calldata,
        bool[] calldata,
        bytes32,
        bytes32,
        uint[] calldata,
        uint8[] calldata,
        bytes32[] calldata,
        bytes32[] calldata
    ) external view returns (bool);
}

/**
 * @dev Interface of the previous Vault contract to query burn proof status
 */
interface Withdrawable {
    function isWithdrawed(bytes32)  external view returns (bool);
    function isSigDataUsed(bytes32)  external view returns (bool);
    function getDepositedBalance(address, address)  external view returns (uint);
    function updateAssets(address[] calldata, uint[] calldata) external returns (bool);
    function paused() external view returns (bool);
}

/**
 * @dev Responsible for holding the assets and issue minting instruction to
 * Incognito Chain. Also, when presented with a burn proof created over at
 * Incognito Chain, releases the tokens back to user
 */
contract Vault {
    using SafeMath for uint;
    using Counters for Counters.Counter;
    /**
     * @dev Storage slot with the incognito proxy.
     * This is the keccak-256 hash of "eip1967.proxy.incognito." subtracted by 1
     */
    bytes32 private constant _INCOGNITO_SLOT = 0x62135fc083646fdb4e1a9d700e351b886a4a5a39da980650269edd1ade91ffd2;
    address constant public ETH_TOKEN = 0x0000000000000000000000000000000000000000;
    /**
     * @dev Storage variables for Vault
     * This section is APPEND-ONLY, in order to preserve upgradeability
     * since we use Proxy Pattern
     */
    mapping(bytes32 => bool) public withdrawed;
    mapping(bytes32 => bool) public sigDataUsed;
    // address => token => amount
    mapping(address => mapping(address => uint)) public withdrawRequests;
    mapping(address => mapping(address => bool)) public migration;
    mapping(address => uint) public totalDepositedToSCAmount;
    Withdrawable public prevVault;
    bool public notEntered;
    bool public isInitialized;
    /**
    * @dev Added in Storage Layout version : 2.0
    */
    uint8 constant public CURRENT_NETWORK_ID = 1; // Ethereum
    uint8 constant public BURN_REQUEST_METADATA_TYPE = 241;
    uint8 constant public BURN_TO_CONTRACT_REQUEST_METADATA_TYPE = 243;
    uint8 constant public BURN_CALL_REQUEST_METADATA_TYPE = 158;
    Counters.Counter private idCounter;

    address public regulator;
    uint256 public storageLayoutVersion;
    address public executor;
    /**
    * @dev END Storage variables version : 2.0
    */

    /**
    * @dev END Storage variables
    */

    struct BurnInstData {
        uint8 meta; // type of the instruction
        uint8 shard; // ID of the Incognito shard containing the instruction, must be 1
        address token; // ETH address of the token contract (0x0 for ETH)
        address payable to; // ETH address of the receiver of the token
        uint amount; // burned amount (on Incognito)
        bytes32 itx; // Incognito's burning tx
    }

    struct RedepositOptions {
        address redepositToken;
        bytes redepositIncAddress;
        address payable withdrawAddress;
    }

    struct ShieldInfo {
        address sender; // the guy shield request
        bytes32 tx; // txid which sent fund to core team's addresses
    }

    enum Prefix {
        ETHEREUM_EXECUTE_SIGNATURE,
        ETHEREUM_REQUEST_WITHDRAW_SIGNATURE,
        BSC_EXECUTE_SIGNATURE,
        BSC_REQUEST_WITHDRAW_SIGNATURE,
        PLG_EXECUTE_SIGNATURE,
        PLG_REQUEST_WITHDRAW_SIGNATURE,
        FTM_EXECUTE_SIGNATURE,
        FTM_REQUEST_WITHDRAW_SIGNATURE
    }

    // error code
    enum Errors {
        EMPTY,
        NO_REENTRANCE,
        MAX_UINT_REACHED,
        VALUE_OVER_FLOW,
        INTERNAL_TX_ERROR,
        ALREADY_USED, // 5
        INVALID_DATA,
        TOKEN_NOT_ENOUGH,
        WITHDRAW_REQUEST_TOKEN_NOT_ENOUGH,
        INVALID_RETURN_DATA,
        NOT_EQUAL, // 10
        NULL_VALUE,
        ONLY_PREVAULT,
        PREVAULT_NOT_PAUSED,
        SAFEMATH_EXCEPTION,
        ALREADY_INITIALIZED, // 15
        INVALID_SIGNATURE,
        NOT_AUTHORISED,
        ALREADY_UPGRADED,
        INVALID_DATA_BURN_CALL_INST,
        ONLY_SELF_CALL
    }

    event Deposit(address token, string incognitoAddress, uint amount);
    event Withdraw(address token, address to, uint amount);
    event UpdateTokenTotal(address[] assets, uint[] amounts);
    event UpdateIncognitoProxy(address newIncognitoProxy);
    event Redeposit(address token, bytes redepositIncAddress, uint256 amount, bytes32 itx);
    event DepositV2(address token, string incognitoAddress, uint amount, uint256 depositID);
    event ExecuteFnLog(bytes32 id, uint256 phaseID, bytes errorData);

    /**
     * modifier for contract version
     */
    modifier onlyPreVault(){
        require(address(prevVault) != address(0x0) && msg.sender == address(prevVault), errorToString(Errors.ONLY_PREVAULT));
        _;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, notEntered will be true
        require(notEntered, errorToString(Errors.NO_REENTRANCE));

        // Any calls to nonReentrant after this point will fail
        notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        notEntered = true;
    }

    /**
     * @dev Creates new Vault to hold assets for Incognito Chain
     * @param _prevVault: previous version of the Vault to refer back if necessary
     * @param _regulator: ...
     * @param _executor: helper contract to perform external call from
     * After migrating all assets to a new Vault, we still need to refer
     * back to previous Vault to make sure old withdrawals aren't being reused
     */
    function initialize(address _prevVault, address _regulator, address _executor) external {
        require(!isInitialized, errorToString(Errors.ALREADY_INITIALIZED));
        prevVault = Withdrawable(_prevVault);
        isInitialized = true;
        notEntered = true;
        require(regulator == address(0x0), errorToString(Errors.NOT_AUTHORISED));
        regulator = _regulator;
        executor = _executor;
        storageLayoutVersion = 2;
    }

    /**
     * @dev upgrade helper for storage layout version 2
     * @param _regulator: ...
     * @param _executor: helper contract to perform external call from
     */
    function upgradeVaultStorage(address _regulator, address _executor) external {
        // storageLayoutVersion is a new variable introduced in this storage layout version, then set to 2 to match the storage layout version itself
        require(storageLayoutVersion == 0, errorToString(Errors.ALREADY_UPGRADED));
        // make sure the version increase can only happen once
        storageLayoutVersion = 2;
        require(regulator == address(0x0), errorToString(Errors.NOT_AUTHORISED));
        regulator = _regulator;
        executor = _executor;
    }

    /**
     * @dev Returns the current incognito proxy.
     */
    function _incognito() internal view returns (address icg) {
        bytes32 slot = _INCOGNITO_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            icg := sload(slot)
        }
    }

    /**
     * @dev Makes a ETH deposit to the vault to mint pETH over at Incognito Chain
     * @notice This only works when the contract is not Paused
     * @notice The maximum amount to deposit is capped since Incognito balance is stored as uint64
     * @param incognitoAddress: Incognito Address to receive pETH
     * @param txId: move fund transaction hash
     * @param signData: regulator signature
     */
    function deposit(string calldata incognitoAddress, bytes32 txId, bytes calldata signData) external payable nonReentrant {
        require(address(this).balance <= 10 ** 27, errorToString(Errors.MAX_UINT_REACHED));
        verifyRegulator(txId, signData);

        emit Deposit(ETH_TOKEN, incognitoAddress, msg.value);
    }

    /**
     * @dev Makes a ERC20 deposit to the vault to mint pERC20 over at Incognito Chain
     * @notice This only works when the contract is not Paused
     * @notice The maximum amount to deposit is capped since Incognito balance is stored as uint64
     * @notice Before calling this function, enough ERC20 must be allowed to
     * tranfer from msg.sender to this contract
     * @param token: address of the ERC20 token
     * @param amount: to deposit to the vault and mint on Incognito Chain
     * @param incognitoAddress: Incognito Address to receive pERC20
     * @param txId: move fund transaction hash
     * @param signData: regulator signature
     */
    function depositERC20(address token, uint amount, string calldata incognitoAddress, bytes32 txId, bytes calldata signData) external nonReentrant {
        verifyRegulator(txId, signData);

        IERC20 erc20Interface = IERC20(token);
        uint8 decimals = getDecimals(address(token));
        uint tokenBalance = erc20Interface.balanceOf(address(this));
        uint beforeTransfer = tokenBalance;
        uint emitAmount = amount;
        if (decimals > 9) {
            emitAmount = emitAmount / (10 ** (uint(decimals) - 9));
            tokenBalance = tokenBalance / (10 ** (uint(decimals) - 9));
        }
        require(emitAmount <= 10 ** 18 && tokenBalance <= 10 ** 18 && emitAmount.safeAdd(tokenBalance) <= 10 ** 18, errorToString(Errors.VALUE_OVER_FLOW));
        erc20Interface.transferFrom(msg.sender, address(this), amount);
        require(checkSuccess(), errorToString(Errors.INTERNAL_TX_ERROR));
        require(balanceOf(token).safeSub(beforeTransfer) == amount, errorToString(Errors.NOT_EQUAL));

        emit Deposit(token, incognitoAddress, emitAmount);
    }

    /**
     * @dev Makes a ETH deposit to the vault to mint pETH over at Incognito Chain
     * @notice This only works when the contract is not Paused
     * @notice The maximum amount to deposit is capped since Incognito balance is stored as uint64
     * @param incognitoAddress: Incognito Address to receive pETH
     */
    function deposit_V2(string calldata incognitoAddress, bytes32 txId, bytes calldata signData) external payable nonReentrant {
        require(address(this).balance <= 10 ** 27, errorToString(Errors.MAX_UINT_REACHED));
        verifyRegulator(txId, signData);
        emit DepositV2(ETH_TOKEN, incognitoAddress, msg.value, idCounter.current());
        idCounter.increment();
    }

    /**
     * @dev Makes a ERC20 deposit to the vault to mint pERC20 over at Incognito Chain
     * @notice This only works when the contract is not Paused
     * @notice The maximum amount to deposit is capped since Incognito balance is stored as uint64
     * @notice Before calling this function, enough ERC20 must be allowed to
     * tranfer from msg.sender to this contract
     * @param token: address of the ERC20 token
     * @param amount: to deposit to the vault and mint on Incognito Chain
     * @param incognitoAddress: Incognito Address to receive pERC20
     */
    function depositERC20_V2(address token, uint amount, string calldata incognitoAddress, bytes32 txId, bytes calldata signData) external nonReentrant {
        verifyRegulator(txId, signData);
        IERC20 erc20Interface = IERC20(token);
        uint8 decimals = getDecimals(address(token));
        uint tokenBalance = erc20Interface.balanceOf(address(this));
        uint beforeTransfer = tokenBalance;
        uint emitAmount = amount;
        if (decimals > 9) {
            emitAmount = emitAmount / (10 ** (uint(decimals) - 9));
            tokenBalance = tokenBalance / (10 ** (uint(decimals) - 9));
        }
        require(emitAmount <= 10 ** 18 && tokenBalance <= 10 ** 18 && emitAmount.safeAdd(tokenBalance) <= 10 ** 18, errorToString(Errors.VALUE_OVER_FLOW));
        erc20Interface.transferFrom(msg.sender, address(this), amount);
        require(checkSuccess(), errorToString(Errors.INTERNAL_TX_ERROR));
        require(balanceOf(token).safeSub(beforeTransfer) == amount, errorToString(Errors.NOT_EQUAL));

        emit DepositV2(token, incognitoAddress, emitAmount, idCounter.current());
        idCounter.increment();
    }

    /**
     * @dev Checks if a burn proof has been used before
     * @notice First, we check inside the storage of this contract itself. If the
     * hash has been used before, we return the result. Otherwise, we query
     * previous vault recursively until the first Vault (prevVault address is 0x0)
     * @param hash: of the burn proof
     * @return bool: whether the proof has been used or not
     */
    function isWithdrawed(bytes32 hash) public view returns(bool) {
        if (withdrawed[hash]) {
            return true;
        } else if (address(prevVault) == address(0)) {
            return false;
        }
        return prevVault.isWithdrawed(hash);
    }

    /**
     * @dev Parses a burn instruction and returns the components
     * @param inst: the full instruction, containing both metadata and body
     */
    function parseBurnInst(bytes memory inst) public pure returns (BurnInstData memory) {
        BurnInstData memory data;
        data.meta = uint8(inst[0]);
        data.shard = uint8(inst[1]);
        address token;
        address payable to;
        uint amount;
        bytes32 itx;
        assembly {
        // skip first 0x20 bytes (stored length of inst)
            token := mload(add(inst, 0x22)) // [3:34]
            to := mload(add(inst, 0x42)) // [34:66]
            amount := mload(add(inst, 0x62)) // [66:98]
            itx := mload(add(inst, 0x82)) // [98:130]
        }
        data.token = token;
        data.to = to;
        data.amount = amount;
        data.itx = itx;
        return data;
    }

    /**
     * @dev Parses an extended burn instruction and returns the components
     * @param inst: the full instruction, containing both metadata and body
     */
    function parseCalldataFromBurnInst(bytes calldata inst) public pure returns (BurnInstData memory, RedepositOptions memory, bytes memory) {
        require(inst.length >= 296, errorToString(Errors.INVALID_DATA_BURN_CALL_INST));
        BurnInstData memory bdata;
        // layout: meta(1), shard(1), network(1), extToken(32), extCallAddr(32), amount(32), txID(32), recvToken(32), withdrawAddr(32), redepositAddr(101), extCalldata(*)
        {
            bdata.meta = uint8(inst[0]);
            bdata.shard = uint8(inst[1]);
            uint8 networkID = uint8(inst[2]);
            require(bdata.meta == BURN_CALL_REQUEST_METADATA_TYPE && bdata.shard == 1 && networkID == CURRENT_NETWORK_ID, errorToString(Errors.INVALID_DATA_BURN_CALL_INST));
        }
        RedepositOptions memory opt;
        {
            (bdata.token, bdata.to, bdata.amount, bdata.itx, opt.redepositToken, opt.withdrawAddress) = abi.decode(inst[3:195], (address, address, uint256, bytes32, address, address));
        }
    
        opt.redepositIncAddress = bytes(inst[195:296]);
        return (bdata, opt, bytes(inst[296:]));
    }

    /**
     * @dev Verifies that a burn instruction is valid
     * @notice All params except inst are the list of 2 elements corresponding to
     * the proof on beacon and bridge
     * @notice All params are the same as in `withdraw`
     */
    function verifyInst(
        bytes memory inst,
        uint heights,
        bytes32[] memory instPaths,
        bool[] memory instPathIsLefts,
        bytes32 instRoots,
        bytes32 blkData,
        uint[] memory sigIdxs,
        uint8[] memory sigVs,
        bytes32[] memory sigRs,
        bytes32[] memory sigSs
    ) view internal {
        // Each instruction can only by redeemed once
        bytes32 beaconInstHash = keccak256(abi.encodePacked(inst, heights));

        // Verify instruction on beacon
        require(Incognito(_incognito()).instructionApproved(
                true, // Only check instruction on beacon
                beaconInstHash,
                heights,
                instPaths,
                instPathIsLefts,
                instRoots,
                blkData,
                sigIdxs,
                sigVs,
                sigRs,
                sigSs
            ), errorToString(Errors.INVALID_DATA));
    }

    /**
     * @dev Withdraws pETH/pIERC20 by providing a burn proof over at Incognito Chain
     * @notice This function takes a burn instruction on Incognito Chain, checks
     * for its validity and returns the token back to ETH chain
     * @notice This only works when the contract is not Paused
     * @param inst: the decoded instruction as a list of bytes
     * @param heights: the blocks containing the instruction
     * @param instPaths: merkle path of the instruction
     * @param instPathIsLefts: whether each node on the path is the left or right child
     * @param instRoots: root of the merkle tree contains all instructions
     * @param blkData: merkle has of the block body
     * @param sigIdxs: indices of the validators who signed this block
     * @param sigVs: part of the signatures of the validators
     * @param sigRs: part of the signatures of the validators
     * @param sigSs: part of the signatures of the validators
     */
    function withdraw(
        bytes memory inst,
        uint heights,
        bytes32[] memory instPaths,
        bool[] memory instPathIsLefts,
        bytes32 instRoots,
        bytes32 blkData,
        uint[] memory sigIdxs,
        uint8[] memory sigVs,
        bytes32[] memory sigRs,
        bytes32[] memory sigSs
    ) public nonReentrant {
        require(inst.length >= 130, errorToString(Errors.INVALID_DATA));
        BurnInstData memory data = parseBurnInst(inst);
        require(data.meta == BURN_REQUEST_METADATA_TYPE && data.shard == 1, errorToString(Errors.INVALID_DATA)); // Check instruction type

        // Not withdrawed
        require(!isWithdrawed(data.itx), errorToString(Errors.ALREADY_USED));
        withdrawed[data.itx] = true;

        // Check if balance is enough
        if (data.token == ETH_TOKEN) {
            require(address(this).balance >= data.amount.safeAdd(totalDepositedToSCAmount[data.token]), errorToString(Errors.TOKEN_NOT_ENOUGH));
        } else {
            uint8 decimals = getDecimals(data.token);
            if (decimals > 9) {
                data.amount = data.amount.safeMul(10 ** (uint(decimals) - 9));
            }
            require(IERC20(data.token).balanceOf(address(this)) >= data.amount.safeAdd(totalDepositedToSCAmount[data.token]), errorToString(Errors.TOKEN_NOT_ENOUGH));
        }

        verifyInst(
            inst,
            heights,
            instPaths,
            instPathIsLefts,
            instRoots,
            blkData,
            sigIdxs,
            sigVs,
            sigRs,
            sigSs
        );

        // Send and notify
        if (data.token == ETH_TOKEN) {
            (bool success, ) =  data.to.call{value: data.amount}("");
            require(success, errorToString(Errors.INTERNAL_TX_ERROR));
        } else {
            IERC20(data.token).transfer(data.to, data.amount);
            require(checkSuccess(), errorToString(Errors.INTERNAL_TX_ERROR));
        }
        emit Withdraw(data.token, data.to, data.amount);
    }

    function executeWithBurnProof(
        bytes calldata inst,
        uint heights,
        bytes32[] memory instPaths,
        bool[] memory instPathIsLefts,
        bytes32 instRoots,
        bytes32 blkData,
        uint[] memory sigIdxs,
        uint8[] memory sigVs,
        bytes32[] memory sigRs,
        bytes32[] memory sigSs
    ) external nonReentrant {
        (BurnInstData memory data, RedepositOptions memory rOptions, bytes memory externalCalldata) = parseCalldataFromBurnInst(inst); // parse function also does sanity checks
        require(!isWithdrawed(data.itx), errorToString(Errors.ALREADY_USED)); // check if txID has been used previously
        withdrawed[data.itx] = true;
        // check if vault balance is sufficient
        if (data.token == ETH_TOKEN) {
            require(address(this).balance >= data.amount.safeAdd(totalDepositedToSCAmount[data.token]), errorToString(Errors.TOKEN_NOT_ENOUGH));
        } else {
            uint8 decimals = getDecimals(data.token);
            if (decimals > 9) {
                data.amount = data.amount.safeMul(10 ** (uint(decimals) - 9));
            }
            require(IERC20(data.token).balanceOf(address(this)) >= data.amount.safeAdd(totalDepositedToSCAmount[data.token]), errorToString(Errors.TOKEN_NOT_ENOUGH));
        }

        verifyInst(
            inst,
            heights,
            instPaths,
            instPathIsLefts,
            instRoots,
            blkData,
            sigIdxs,
            sigVs,
            sigRs,
            sigSs
        );


        // perform external msgcall
        try this._callExternal(data.token, data.to, data.amount, externalCalldata, rOptions.redepositToken) returns (uint256 returnedAmount) {
            if (rOptions.withdrawAddress == address(0)) {
                // after executing, one can redeposit to Incognito Chain
                _redeposit(rOptions.redepositToken, rOptions.redepositIncAddress, returnedAmount, data.itx);
            } else {
                // alternatively, the received funds can be withdrawn
                try this._transferExternal(rOptions.redepositToken, rOptions.withdrawAddress, returnedAmount) {
                    emit Withdraw(rOptions.redepositToken, rOptions.withdrawAddress, returnedAmount);
                } catch (bytes memory lowLevelData) {
                    // upon revert, emit Redeposit event
                    _redeposit(rOptions.redepositToken, rOptions.redepositIncAddress, returnedAmount, data.itx);
                    emit ExecuteFnLog(data.itx, 1, lowLevelData);
                    return;
                }
            }
        } catch (bytes memory lowLevelData) {
            _redeposit(data.token, rOptions.redepositIncAddress, data.amount, data.itx);
            emit ExecuteFnLog(data.itx, 0, lowLevelData);
            return;
        }
    }

    function _redeposit(address token, bytes memory redepositIncAddress, uint256 amount, bytes32 itx) internal {
        uint emitAmount = amount;
        if (token == ETH_TOKEN) {
            require(address(this).balance <= 10 ** 27, errorToString(Errors.MAX_UINT_REACHED));
        } else {
            uint8 decimals = getDecimals(address(token));
            if (decimals > 9) {
                emitAmount = emitAmount / (10 ** (uint(decimals) - 9));
            }
            require(emitAmount <= 10 ** 18, errorToString(Errors.VALUE_OVER_FLOW));
        }
        emit Redeposit(token, redepositIncAddress, emitAmount, itx);
    }

    function _transferExternal(address token, address payable to, uint256 amount) external onlySelf() {
        if (token == ETH_TOKEN) {
            Address.sendValue(to, amount);
        } else {
            IERC20(token).transfer(to, amount);
            require(checkSuccess(), errorToString(Errors.INTERNAL_TX_ERROR));
        }
    }

    function _callExternal(address token, address to, uint256 amount, bytes memory externalCalldata, address redepositToken) external onlySelf() returns (uint256) {
        uint balanceBeforeTrade = balanceOf(redepositToken);
        bytes memory result;
        uint256 msgval = 0;
        if (token == ETH_TOKEN) {
            msgval = amount;
        } else {
            IERC20(token).transfer(executor, amount);
            require(checkSuccess(), errorToString(Errors.INTERNAL_TX_ERROR));
        }
        result = Executor(executor).execute{value: msgval}(to, externalCalldata);
        require(result.length == 64, errorToString(Errors.INVALID_RETURN_DATA));
        (address returnedTokenAddress, uint returnedAmount) = abi.decode(result, (address, uint));
        require(returnedTokenAddress == redepositToken && balanceOf(redepositToken).safeSub(balanceBeforeTrade) == returnedAmount, errorToString(Errors.INVALID_RETURN_DATA));
        return returnedAmount;
    }

    modifier onlySelf() {
        require(address(this) == msg.sender, errorToString(Errors.ONLY_SELF_CALL));
        _;
    }

    /**
     * @dev Burnt Proof is submited to store burnt amount of p-token/p-ETH and receiver's address
     * Receiver then can call withdrawRequest to withdraw these token to he/she incognito address.
     * @notice This function takes a burn instruction on Incognito Chain, checks
     * for its validity and returns the token back to ETH chain
     * @notice This only works when the contract is not Paused
     * @param inst: the decoded instruction as a list of bytes
     * @param heights: the blocks containing the instruction
     * @param instPaths: merkle path of the instruction
     * @param instPathIsLefts: whether each node on the path is the left or right child
     * @param instRoots: root of the merkle tree contains all instructions
     * @param blkData: merkle has of the block body
     * @param sigIdxs: indices of the validators who signed this block
     * @param sigVs: part of the signatures of the validators
     * @param sigRs: part of the signatures of the validators
     * @param sigSs: part of the signatures of the validators
     */
    function submitBurnProof(
        bytes memory inst,
        uint heights,
        bytes32[] memory instPaths,
        bool[] memory instPathIsLefts,
        bytes32 instRoots,
        bytes32 blkData,
        uint[] memory sigIdxs,
        uint8[] memory sigVs,
        bytes32[] memory sigRs,
        bytes32[] memory sigSs
    ) public nonReentrant {
        require(inst.length >= 130, errorToString(Errors.INVALID_DATA));
        BurnInstData memory data = parseBurnInst(inst);
        require(data.meta == BURN_TO_CONTRACT_REQUEST_METADATA_TYPE && data.shard == 1, errorToString(Errors.INVALID_DATA)); // Check instruction type

        // Not withdrawed
        require(!isWithdrawed(data.itx), errorToString(Errors.ALREADY_USED));
        withdrawed[data.itx] = true;

        // Check if balance is enough
        if (data.token == ETH_TOKEN) {
            require(address(this).balance >= data.amount.safeAdd(totalDepositedToSCAmount[data.token]), errorToString(Errors.TOKEN_NOT_ENOUGH));
        } else {
            uint8 decimals = getDecimals(data.token);
            if (decimals > 9) {
                data.amount = data.amount.safeMul(10 ** (uint(decimals) - 9));
            }
            require(IERC20(data.token).balanceOf(address(this)) >= data.amount.safeAdd(totalDepositedToSCAmount[data.token]), errorToString(Errors.TOKEN_NOT_ENOUGH));
        }

        verifyInst(
            inst,
            heights,
            instPaths,
            instPathIsLefts,
            instRoots,
            blkData,
            sigIdxs,
            sigVs,
            sigRs,
            sigSs
        );

        withdrawRequests[data.to][data.token] = withdrawRequests[data.to][data.token].safeAdd(data.amount);
        totalDepositedToSCAmount[data.token] = totalDepositedToSCAmount[data.token].safeAdd(data.amount);
    }

    /**
     * @dev generate address from signature data and hash.
     */
    function sigToAddress(bytes memory signData, bytes32 hash) public pure returns (address) {
        bytes32 s;
        bytes32 r;
        uint8 v;
        assembly {
            r := mload(add(signData, 0x20))
            s := mload(add(signData, 0x40))
        }
        v = uint8(signData[64]) + 27;
        return ecrecover(hash, v, r, s);
    }

    /**
     * @dev Checks if a sig data has been used before
     * @notice First, we check inside the storage of this contract itself. If the
     * hash has been used before, we return the result. Otherwise, we query
     * previous vault recursively until the first Vault (prevVault address is 0x0)
     * @param hash: of the sig data
     * @return bool: whether the sig data has been used or not
     */
    function isSigDataUsed(bytes32 hash) public view returns(bool) {
        if (sigDataUsed[hash]) {
            return true;
        } else if (address(prevVault) == address(0)) {
            return false;
        }
        return prevVault.isSigDataUsed(hash);
    }

    struct PreSignData {
        Prefix prefix;
        address token;
        bytes timestamp;
        uint amount;
    }

    function newPreSignData(Prefix prefix, address token, bytes calldata timestamp, uint amount) pure internal returns (PreSignData memory) {
        PreSignData memory psd = PreSignData(prefix, token, timestamp, amount);
        return psd;
    }

    /**
     * @dev User requests withdraw token contains in withdrawRequests.
     * Deposit event will be emitted to let incognito recognize and mint new p-tokens for the user.
     * @param incognitoAddress: incognito's address that will receive minted p-tokens.
     * @param token: ethereum's token address (eg., ETH, DAI, ...)
     * @param amount: amount of the token in ethereum's denomination
     * @param signData: signature of an unique data that is signed by an account which is generated from user's incognito privkey
     * @param timestamp: unique data generated from client (timestamp for example)
     * @param txId: move fund transaction hash
     * @param signData: regulator signature
     */
    function requestWithdraw(
        string calldata incognitoAddress,
        address token,
        uint amount,
        bytes calldata signData,
        bytes calldata timestamp,
        bytes32 txId,
        bytes calldata regulatorSig
    ) external nonReentrant {
        verifyRegulator(txId, regulatorSig);

        // verify owner signs data
        address verifier = verifySignData(abi.encode(newPreSignData(Prefix.ETHEREUM_REQUEST_WITHDRAW_SIGNATURE, token, timestamp, amount), incognitoAddress), signData);

        // migrate from preVault
        migrateBalance(verifier, token);

        require(withdrawRequests[verifier][token] >= amount, errorToString(Errors.WITHDRAW_REQUEST_TOKEN_NOT_ENOUGH));
        withdrawRequests[verifier][token] = withdrawRequests[verifier][token].safeSub(amount);
        totalDepositedToSCAmount[token] = totalDepositedToSCAmount[token].safeSub(amount);

        // convert denomination from ethereum's to incognito's (pcoin)
        uint emitAmount = amount;
        if (token != ETH_TOKEN) {
            uint8 decimals = getDecimals(token);
            if (decimals > 9) {
                emitAmount = amount / (10 ** (uint(decimals) - 9));
            }
        }

        emit Deposit(token, incognitoAddress, emitAmount);
    }

    /**
     * @dev execute is a general function that plays a role as proxy to interact to other smart contracts.
     * @param token: ethereum's token address (eg., ETH, DAI, ...)
     * @param amount: amount of the token in ethereum's denomination
     * @param recipientToken: received token address.
     * @param exchangeAddress: address of targeting smart contract that actually executes the desired logics like trade, invest, borrow and so on.
     * @param callData: encoded with signature and params of function from targeting smart contract.
     * @param timestamp: unique data generated from client (timestamp for example)
     * @param signData: signature of an unique data that is signed by an account which is generated from user's incognito privkey
     */
    function execute(
        address token,
        uint amount,
        address recipientToken,
        address exchangeAddress,
        bytes calldata callData,
        bytes calldata timestamp,
        bytes calldata signData
    ) external payable nonReentrant {
        //verify ower signs data from input
        address verifier = verifySignData(abi.encode(newPreSignData(Prefix.ETHEREUM_EXECUTE_SIGNATURE, token, timestamp, amount), recipientToken, exchangeAddress, callData), signData);

        // migrate from preVault
        migrateBalance(verifier, token);
        require(withdrawRequests[verifier][token] >= amount, errorToString(Errors.WITHDRAW_REQUEST_TOKEN_NOT_ENOUGH));

        // update balance of verifier
        totalDepositedToSCAmount[token] = totalDepositedToSCAmount[token].safeSub(amount);
        withdrawRequests[verifier][token] = withdrawRequests[verifier][token].safeSub(amount);

        // define number of eth spent for forwarder.
        uint ethAmount = msg.value;
        if (token == ETH_TOKEN) {
            ethAmount = ethAmount.safeAdd(amount);
        } else {
            // transfer token to exchangeAddress.
            require(IERC20(token).balanceOf(address(this)) >= amount, errorToString(Errors.TOKEN_NOT_ENOUGH));
            IERC20(token).transfer(executor, amount);
            require(checkSuccess(), errorToString(Errors.INTERNAL_TX_ERROR));
        }
        uint returnedAmount = callExtFunc(recipientToken, ethAmount, callData, exchangeAddress);

        // update withdrawRequests
        withdrawRequests[verifier][recipientToken] = withdrawRequests[verifier][recipientToken].safeAdd(returnedAmount);
        totalDepositedToSCAmount[recipientToken] = totalDepositedToSCAmount[recipientToken].safeAdd(returnedAmount);
    }

    /**
     * @dev single trade
     */
    function callExtFunc(address recipientToken, uint ethAmount, bytes memory callData, address exchangeAddress) internal returns (uint) {
        // get balance of recipient token before trade to compare after trade.
        uint balanceBeforeTrade = balanceOf(recipientToken);
        if (recipientToken == ETH_TOKEN) {
            balanceBeforeTrade = balanceBeforeTrade.safeSub(msg.value);
        }
        require(address(this).balance >= ethAmount, errorToString(Errors.TOKEN_NOT_ENOUGH));
        bytes memory result = Executor(executor).execute{value: ethAmount}(exchangeAddress, callData);
        (address returnedTokenAddress, uint returnedAmount) = abi.decode(result, (address, uint));
        require(returnedTokenAddress == recipientToken && balanceOf(recipientToken).safeSub(balanceBeforeTrade) == returnedAmount, errorToString(Errors.INVALID_RETURN_DATA));
        return returnedAmount;
    }

    /**
     * @dev set regulator
     */
    function setRegulator(address _regulator) external {
        require((regulator == address(0x0) || msg.sender == regulator) && _regulator != address(0x0), errorToString(Errors.NOT_AUTHORISED));
        regulator = _regulator;
    }

    /**
     * @dev verify regulator
     */
    function verifyRegulator(bytes32 txId, bytes memory signData) internal view {
        // verify regulator signs data
        address signer = sigToAddress(signData, keccak256(abi.encode(ShieldInfo(msg.sender, txId))));
        require(signer == regulator, errorToString(Errors.INVALID_SIGNATURE));
    }

    /**
     * @dev verify sign data
     */
    function verifySignData(bytes memory data, bytes memory signData) internal returns(address){
        bytes32 hash = keccak256(data);
        require(!isSigDataUsed(hash), errorToString(Errors.ALREADY_USED));
        address verifier = sigToAddress(signData, hash);
        // reject when verifier equals zero
        require(verifier != address(0x0), errorToString(Errors.INVALID_SIGNATURE));
        // mark data hash of sig as used
        sigDataUsed[hash] = true;

        return verifier;
    }

    /**
      * @dev migrate balance from previous vault
      * Note: uncomment for next version
      */
    function migrateBalance(address owner, address token) internal {
        if (address(prevVault) != address(0x0) && !migration[owner][token]) {
            withdrawRequests[owner][token] = withdrawRequests[owner][token].safeAdd(prevVault.getDepositedBalance(token, owner));
            migration[owner][token] = true;
        }
    }

    /**
     * @dev Get the amount of specific coin for specific wallet
     */
    function getDepositedBalance(
        address token,
        address owner
    ) public view returns (uint) {
        if (address(prevVault) != address(0x0) && !migration[owner][token]) {
            return withdrawRequests[owner][token].safeAdd(prevVault.getDepositedBalance(token, owner));
        }
        return withdrawRequests[owner][token];
    }

    /**
     * @dev Move total number of assets to newVault
     * @notice This only works when the preVault is Paused
     * @notice This can only be called by preVault
     * @param assets: address of the ERC20 tokens to move, 0x0 for ETH
     * @param amounts: total number of the ERC20 tokens to move, 0x0 for ETH
     */
    function updateAssets(address[] calldata assets, uint[] calldata amounts) external onlyPreVault returns(bool) {
        require(assets.length == amounts.length,  errorToString(Errors.NOT_EQUAL));
        require(Withdrawable(prevVault).paused(), errorToString(Errors.PREVAULT_NOT_PAUSED));
        for (uint i = 0; i < assets.length; i++) {
            totalDepositedToSCAmount[assets[i]] = totalDepositedToSCAmount[assets[i]].safeAdd(amounts[i]);
        }
        emit UpdateTokenTotal(assets, amounts);

        return true;
    }

    /**
     * @dev Payable receive function to receive Ether from oldVault when migrating
     */
    receive() external payable {}

    /**
     * @dev Check if transfer() and transferFrom() of ERC20 succeeded or not
     * This check is needed to fix https://github.com/ethereum/solidity/issues/4116
     * This function is copied from https://github.com/AdExNetwork/adex-protocol-eth/blob/master/contracts/libs/SafeERC20.sol
     */
    function checkSuccess() private pure returns (bool) {
        uint256 returnValue = 0;
        assembly {
        // check number of bytes returned from last function call
            switch returndatasize()

            // no bytes returned: assume success
            case 0x0 {
                returnValue := 1
            }

            // 32 bytes returned: check if non-zero
            case 0x20 {
            // copy 32 bytes into scratch space
                returndatacopy(0x0, 0x0, 0x20)

            // load those bytes into returnValue
                returnValue := mload(0x0)
            }

            // not sure what was returned: don't mark as success
            default { }
        }
        return returnValue != 0;
    }

    /**
     * @dev convert enum to string value
     */
    function errorToString(Errors error) internal pure returns(string memory) {
        uint8 erroNum = uint8(error);
        uint maxlength = 10;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (erroNum != 0) {
            uint8 remainder = erroNum % 10;
            erroNum = erroNum / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i + 1);
        for (uint j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        return string(s);
    }

    /**
     * @dev Get the decimals of an ERC20 token, return 0 if it isn't defined
     * We check the returndatasize to covert both cases that the token has
     * and doesn't have the function decimals()
     */
    function getDecimals(address token) public view returns (uint8) {
        require(Address.isContract(token), "getDecimals non-contract");
        IERC20 erc20 = IERC20(token);
        try erc20.decimals() returns (uint256 d) {
            return uint8(d);    
        } catch {
            revert("get ERC20 decimal failed");
        }
    }

    /**
     * @dev Get the amount of coin deposited to this smartcontract
     */
    function balanceOf(address token) public view returns (uint) {
        if (token == ETH_TOKEN) {
            return address(this).balance;
        }
        require(Address.isContract(token), "balanceOf non-contract");
        try IERC20(token).balanceOf(address(this)) returns (uint256 b) {
            return b;
        } catch {
            revert("get ERC20 balance failed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint amount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint amount) external;

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint amount) external;

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.12 <=0.8.9;

import './IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract TradeUtils {
	IERC20 constant public ETH_CONTRACT_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);

	function balanceOf(IERC20 token) internal view returns (uint256) {
		if (token == ETH_CONTRACT_ADDRESS) {
			return address(this).balance;
		}
        return token.balanceOf(address(this));
    }

	function transfer(IERC20 token, uint amount) internal {
		if (token == ETH_CONTRACT_ADDRESS) {
			require(address(this).balance >= amount);
			(bool success, ) = msg.sender.call{value: amount}("");
          	require(success);
		} else {
			token.transfer(msg.sender, amount);
			require(checkSuccess());
		}
	}

	function approve(IERC20 token, address proxy, uint amount) internal {
		if (token != ETH_CONTRACT_ADDRESS) {
			token.approve(proxy, 0);
			require(checkSuccess());
			token.approve(proxy, amount);
			require(checkSuccess());
		}
	}

	/**
     * @dev Check if transfer() and transferFrom() of ERC20 succeeded or not
     * This check is needed to fix https://github.com/ethereum/solidity/issues/4116
     * This function is copied from https://github.com/AdExNetwork/adex-protocol-eth/blob/master/contracts/libs/SafeERC20.sol
     */
    function checkSuccess() internal pure returns (bool) {
		uint256 returnValue = 0;

		assembly {
			// check number of bytes returned from last function call
			switch returndatasize()

			// no bytes returned: assume success
			case 0x0 {
				returnValue := 1
			}

			// 32 bytes returned: check if non-zero
			case 0x20 {
				// copy 32 bytes into scratch space
				returndatacopy(0x0, 0x0, 0x20)

				// load those bytes into returnValue
				returnValue := mload(0x0)
			}

			// not sure what was returned: don't mark as success
			default { }
		}
		return returnValue != 0;
	}
}

abstract contract Executor is Ownable {
	mapping (address => bool) public dappAddresses;

	constructor() internal {
		dappAddresses[address(this)] = true;
	}

	function addDappAddress(address addr) external onlyOwner {
		require(addr != address(0x0), "Executor:A0"); // address is zero
		dappAddresses[addr] = true;
	}

	function removeDappAddress(address addr) external onlyOwner {
		require(addr != address(0x0), "Executor:A0"); // address is zero
		dappAddresses[addr] = false;
	}

	function dappExists(address addr) public view returns (bool) {
		return dappAddresses[addr];
	}

    function execute(address fns, bytes calldata data) external payable returns (bytes memory) {
    	require(dappExists(fns), "Executor:DNE"); // dapp does not exist
        (bool success, bytes memory result) = fns.delegatecall(data);
        if (!success) {
        	// Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}