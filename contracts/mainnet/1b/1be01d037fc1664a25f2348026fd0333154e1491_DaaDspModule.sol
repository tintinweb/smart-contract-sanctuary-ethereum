// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "./utils/Enum.sol";
import "./utils/SignatureDecoder.sol";
import "./utils/CompatibilityFallbackHandler.sol";
import "./utils/DFSCompatibility.sol";
import "./utils/CoWCompatibility.sol";
import "../interfaces/IERC20Minimal.sol";
import "../interfaces/IGnosisSafe.sol";
import "../interfaces/IRecipeContainer.sol";
import "../interfaces/ISignatureValidator.sol";
import "../interfaces/IWhitelistRegistry.sol";


/// @title DAA DSP Module - A gnosis safe module to execute whitelisted transactions to a DSP.


contract DaaDspModule is 
    SignatureDecoder,
    ISignatureValidator,
    CompatibilityFallbackHandler
{
    IGnosisSafe public safe;
    IDSProxy public account;
    IProxyRegistry registry;    // dsp proxy registry
    IWhitelistRegistry wl;  // daa whitelist 
    IRecipeContainer rc;    // daa recipe container
    // DFS Contracts
    address dfsRegistryAddress; 
    address recipeExecutor;
    // chain native token
    address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; 
    
    uint256 public nonce;
    uint256 internal threshold = 2;
    string public constant name = "DAA DSP Module";
    string public constant version  = "1";
    bool public initialized;

    // --- EIP712 ---
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 private constant MODULE_TX_TYPEHASH = keccak256("ModuleTx(address _targetAddress,bytes calldata _data,uint256 _nonce)");
    bytes32 private constant MODULE_TX_TYPEHASH = 0xc5d6711dec9859198fc49821812819142651b1ae455a02ffb30a9452b98b011a;

    // Mapping to keep track of all hashes (message or transaction) that have been approved by ANY owners
    mapping(address => mapping(bytes32 => uint256)) public approvedHashes;


    event AccountCreated(address dspAccount);
    event ApproveHash(bytes32 indexed approvedHash, address indexed owner);
    event TransactionExecuted(bytes32 txHash);

    constructor(){}

    /// @dev Create a DSP account for the module.
    /// @param _safe Safe address.
    /// @param _index Address of the Instadapp index contract.
    function initialize(IGnosisSafe _safe, IProxyRegistry _index, IWhitelistRegistry _wl, IRecipeContainer _rc) external {
        require(!initialized, "Already initialized"); 
        safe = _safe;
        registry = IProxyRegistry(_index); 
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            block.chainid,
            address(this)
        ));
        createAccount(address(this));
        (recipeExecutor,dfsRegistryAddress) = registerDFS();
        wl = _wl; rc = _rc;
        initialized = true;
    }

    /// @dev Execute transaction on DSP.
    /// @param _targetAddress DSP transaction target names.
    /// @param _data DSP transaction data.
    /// @param signatures Owners transaction signatures.
    function executeTransaction(
        address _targetAddress,
        bytes calldata _data,
        bytes memory signatures
    ) 
        external
    {
        require(isAuthorized(msg.sender));
        require(address(account) != address(0), "DSP not created");
        bytes32 txHash;
        bytes memory txHashData =
            encodeTransactionData(
                _targetAddress,
                _data,
                nonce
            );
        txHash = getTransactionHash(_targetAddress,_data,nonce);
        // Increase nonce and prep transaction.
        nonce++;
        checkSignatures(txHash, txHashData, signatures);
        (address[] memory tokenAddress, uint[] memory amount) = this.getConnectorData(_targetAddress, _data);
        prepFunds(tokenAddress, amount);
        // execute transaction
        execute(_targetAddress,_data);
        emit TransactionExecuted(txHash);
    }

    /// @dev Execute recipe transaction on DSP.
    /// @param recipeId The id of the recipe to execute.
    /// @param signatures Owners transaction signatures.
    function executeRecipe(
        uint256 recipeId,
        bytes memory signatures
    ) external {
        require(isAuthorized(msg.sender));
        require(address(account) != address(0), "DSP not created");
        
        bytes memory _data = getRecipeTxData(recipeId);
        address _targetAddress = recipeExecutor;

        bytes32 txHash;
        bytes memory txHashData =
            encodeTransactionData(
                _targetAddress,
                _data,
                nonce
            );
        txHash = getTransactionHash(_targetAddress,_data,nonce);
        // Increase nonce and prep transaction.
        nonce++;
        checkSignatures(txHash, txHashData, signatures);
        (address[] memory tokenAddress, uint[] memory amount) = this.getConnectorData(_targetAddress, _data);
        prepFunds(tokenAddress, amount);
        // execute transaction
        execute(_targetAddress,_data);
        emit TransactionExecuted(txHash);
    }

    /// @dev Execute batch transaction on DSP via CowSwap.
    /// @param _targetAddress DSP transaction target names.
    /// @param _data DSP transaction data.
    /// @param signatures Owners transaction signatures.
    function executeBatch(
        address _targetAddress,
        bytes calldata _data,
        bytes memory signatures
    ) 
        external
    {
        require(isAuthorized(msg.sender));
        require(address(account) != address(0), "DSP not created");
        bytes32 txHash;
        bytes memory txHashData =
            encodeTransactionData(
                _targetAddress,
                _data,
                nonce
            );
        txHash = getTransactionHash(_targetAddress,_data,nonce);
        // Increase nonce and prep transaction.
        nonce++;
        checkSignatures(txHash, txHashData, signatures);
        // specific target and data checks for CoW batch
        checkBatchTx(_targetAddress,_data);
        // execute transaction
        execute(_targetAddress,_data);
        emit TransactionExecuted(txHash);
    }

    /// @dev Marks a hash as approved. This can be used to validate a hash that is used by a signature.
    /// @param hashToApprove The hash that should be marked as approved for signatures that are verified by this contract.
    function approveHash(bytes32 hashToApprove) 
        external 
    {
        require(isAuthorized(msg.sender));
        approvedHashes[msg.sender][hashToApprove] = 1;
        emit ApproveHash(hashToApprove, msg.sender);
    }

    // @dev Allow to deposit assets from the Safe to the Smart Wallet
    function depositToWallet(
        address[] memory  tokenAddress, 
        uint[] memory amount
        ) 
        external 
        {
        require(isAuthorized(msg.sender));
        uint len = tokenAddress.length;
        for (uint i=0; i < len; i++){
            if (amount[i] > 0){
                pullFromSafe(tokenAddress[i],amount[i]);
                IERC20Minimal(tokenAddress[i]).transfer(address(account),amount[i]);
            }
        }
    }

    function checkBatchTx(
        address target,
        bytes calldata data
    )
        internal
        view
    {
        require(target == batchExecutor, "BatchTgtNotAuth");
        require(bytes4(data[:4]) == bytes4(0x7bc6f593),"BatchFuncNotAuth");
    }

    /// @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
    /// @param dataHash Hash of the data (could be either a message hash or transaction hash)
    /// @param data That should be signed (this is passed to an external validator contract)
    /// @param signatures Signature data that should be verified. Can be ECDSA signature, contract signature (EIP-1271) or approved hash.
    function checkSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    ) public view {
        // Load threshold to avoid multiple storage loads
        uint256 _threshold = threshold;
        // Check that a threshold is set
        require(_threshold > 0, "Threshold not set.");
        checkNSignatures(dataHash, data, signatures, _threshold);
    }

    /// @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
    /// @param dataHash Hash of the data (could be either a message hash or transaction hash)
    /// @param data That should be signed (this is passed to an external validator contract)
    /// @param signatures Signature data that should be verified. Can be ECDSA signature, contract signature (EIP-1271) or approved hash.
    /// @param requiredSignatures Amount of required valid signatures.
    function checkNSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures,
        uint256 requiredSignatures
    ) public view {
        // Check that the provided signature data is not too short
        require(signatures.length >= requiredSignatures*65, "GS020");
        // There cannot be an owner with address 0.
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < requiredSignatures; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            if (v == 0) {
                // If v is 0 then it is a contract signature
                // When handling contract signatures the address of the contract is encoded into r
                currentOwner = address(uint160(uint256(r)));

                // Check that signature data pointer (s) is not pointing inside the static part of the signatures bytes
                // This check is not completely accurate, since it is possible that more signatures than the threshold are send.
                // Here we only check that the pointer is not pointing inside the part that is being processed
                require(uint256(s) >= requiredSignatures*65, "GS021");

                // Check that signature data pointer (s) is in bounds (points to the length of data -> 32 bytes)
                require(uint256(s)+(32) <= signatures.length, "GS022");

                // Check if the contract signature is in bounds: start of data is s + 32 and end is start + signature length
                uint256 contractSignatureLen;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    contractSignatureLen := mload(add(add(signatures, s), 0x20))
                }
                require(uint256(s)+(32)+(contractSignatureLen) <= signatures.length, "GS023");

                // Check signature
                bytes memory contractSignature;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    // The signature data for contract signatures is appended to the concatenated signatures and the offset is stored in s
                    contractSignature := add(add(signatures, s), 0x20)
                }
                require(ISignatureValidator(currentOwner).isValidSignature(data, contractSignature) == EIP1271_MAGIC_VALUE, "GS024");
            } else if (v == 1) {
                // If v is 1 then it is an approved hash
                // When handling approved hashes the address of the approver is encoded into r
                currentOwner = address(uint160(uint256(r)));
                // Hashes are automatically approved by the sender of the message or when they have been pre-approved via a separate transaction
                require(msg.sender == currentOwner || approvedHashes[currentOwner][dataHash] != 0, "GS025");
            } else if (v > 30) {
                // If v > 30 then default va (27,28) has been adjusted for eth_sign flow
                // To support eth_sign and similar we adjust v and hash the messageHash with the Ethereum message prefix before applying ecrecover
                currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v - 4, r, s);
            } else {
                // Default is the ecrecover flow with the provided data hash
                // Use ecrecover with the messageHash for EOA signatures
                currentOwner = ecrecover(dataHash, v, r, s);
            }
            require(currentOwner > lastOwner && isAuthorized(currentOwner) && currentOwner != address(0x1), "GS026");
            lastOwner = currentOwner;
        }
    }

    /// @dev Returns hash to be signed by owners.
    /// @param _targetAddress DSP transaction target names.
    /// @param _data DSP transaction data.
    /// @param _nonce Transaction nonce.
    function getTransactionHash(
        address _targetAddress,
        bytes memory _data,
        uint256 _nonce
    ) 
        public 
        view 
        returns (bytes32) 
    {
        return keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        MODULE_TX_TYPEHASH,
                        _targetAddress,
                        _data,
                        _nonce))
                ));
    }

    /// @dev Returns hash to be signed by owners.
    /// @param recipeId The id of the recipe to execute.
    /// @param _nonce Transaction nonce.
    function getRecipeTransactionHash(
        uint256 recipeId,
        uint256 _nonce
    ) 
        public 
        view 
        returns (bytes32) 
    {
        bytes memory _data = getRecipeTxData(recipeId);
        address _targetAddress = recipeExecutor;
        return keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        MODULE_TX_TYPEHASH,
                        _targetAddress,
                        _data,
                        _nonce))
                ));
    }

    /// @dev Returns the bytes that are hashed to be signed by owners.
    /// @param _targetAddress DSP transaction target names.
    /// @param _data DSP transaction data.
    /// @param _nonce Transaction nonce.
    function encodeTransactionData(
        address _targetAddress,
        bytes memory _data,
        uint256 _nonce
    ) 
        public 
        view 
        returns (bytes memory) 
    {
        return abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        MODULE_TX_TYPEHASH,
                        _targetAddress,
                        _data,
                        _nonce))
                );
    }

    function domainSeparator() public view returns (bytes32) {
        return DOMAIN_SEPARATOR;
    }

    function getAccount() public view returns (address) {
        return address(account);
    }

    /// @dev Allows to decode the transaction data for safety checks, and to prepare the token amount to be pulled from the Safe. 
    /// @param target Tx target.
    /// @param data Contains the transaction data to be digested by the RecipeExecutor.
    function getConnectorData(
        address target,
        bytes calldata data
    ) 
        public 
        view 
        returns 
        (
            address[] memory addrList,
            uint[] memory amtList
        ) 
    {
        whitelistedOpCheck(target,data);
        if (bytes4(data[:4]) == bytes4(0x0c2c8750)) {
            Recipe memory recipe = abi.decode(data[4:], (Recipe));
            IRegistry dfsRegistry = IRegistry(dfsRegistryAddress);  
            bytes4 actionId = 0xcc063de4;
            uint len = recipe.actionIds.length;
            addrList = new address[](len);
            amtList = new uint[](len);
            for (uint i=0; i < len; i++){
                if (keccak256(abi.encodePacked(recipe.actionIds[i])) == keccak256(abi.encodePacked(actionId))){
                    address conn = dfsRegistry.getAddr(recipe.actionIds[i]);
                    ParamsPull memory params = IPullAction(conn).parseInputs(recipe.callData[i]);
                    if (params.from == address(this)){
                        addrList[i] = params.tokenAddr;
                        amtList[i] = params.amount;
                    }
                }
            }
        }
    }

    /// @dev Create a DSP account for the module.
    /// @param owner The owner of the smart wallet
    function createAccount(address owner)
        internal 
        returns (IDSProxy proxy)
    {
        require(address(account) == address(0), "DSP already created");
        account = registry.build(owner); 
        emit AccountCreated(address(account));
        return account;
    }

    function prepFunds(address[] memory  tokenAddress, uint[] memory amount) internal {
        uint len = tokenAddress.length;
        for (uint i=0; i < len; i++){
            if (amount[i] > 0){
                pullFromSafe(tokenAddress[i],amount[i]);
                IERC20Minimal(tokenAddress[i]).approve(address(account),amount[i]);
            }
        }
    }

    function whitelistedOpCheck(address target, bytes calldata data) internal view {
        _targetCheck(target,data);
        if (bytes4(data[:4]) != bytes4(0x389f87ff)) {
            _operationsCheck(target,data);
        }
    }

    ///  @dev make sure it is using DefiSaver contracts.
    ///  function is either executeRecipe(0x0c2c8750) or executeActionDirect(0x389f87ff)
    ///  target can be only recipeExecutor or only contract from allowed actionId (directSwap) and present into dfsRegistry.
    function _targetCheck(address target,bytes calldata data) internal view {
        require(bytes4(data[:4]) == bytes4(0x0c2c8750) || bytes4(data[:4]) == bytes4(0x389f87ff) ,"FuncNotAuth");
        if (bytes4(data[:4]) == bytes4(0x0c2c8750)){
            require(keccak256(abi.encodePacked(target)) == keccak256(abi.encodePacked(recipeExecutor)) ,"TgtNoAuth");
        } else if (bytes4(data[:4]) == bytes4(0x389f87ff)) {
            require(isWhitelistedTarget(target, data), "TgtNoAuth");
        }
    }

    function isWhitelistedTarget(address target,bytes calldata data) internal view returns (bool) {
        require(target != address(account), "NoProxyTgt");
        if (keccak256(abi.encodePacked(target)) == keccak256(abi.encodePacked(IRegistry(dfsRegistryAddress).getAddr((bytes4(0x02abc227))))) ||   // SendToken
            keccak256(abi.encodePacked(target)) == keccak256(abi.encodePacked(IRegistry(dfsRegistryAddress).getAddr((bytes4(0x17782156)))))      //SendTokenAndUnwrap
        ){
            ParamsSend memory params = abi.decode(data, (ParamsSend));
            require(params.to == address(safe) || params.to == address(account), "NoExtTransfer");
        }
        return(wl.isTargetWhitelisted(target));
    }

    ///  @dev Tokens can only be transferred back to the safe or to the smart wallet
    function _operationsCheck(address target, bytes calldata data) internal view returns (bool check){
        Recipe memory recipe = abi.decode(data[4:], (Recipe));
        uint len = recipe.actionIds.length;
        check = true;
        for (uint256 i = 0; i < len; i++) {
            if (keccak256(abi.encodePacked(recipe.actionIds[i])) == keccak256(abi.encodePacked(bytes4(0x02abc227))) ||  // SendToken
                keccak256(abi.encodePacked(recipe.actionIds[i])) == keccak256(abi.encodePacked(bytes4(0x17782156)))     // SendTokenAndUnwrap
            ){
                address conn = IRegistry(dfsRegistryAddress).getAddr(recipe.actionIds[i]);
                ParamsSend memory params = ISendAction(conn).parseInputs(recipe.callData[i]);
                require(params.to == address(safe) || params.to == address(account), "NoExtTransfer");
            }
            if (!wl.isActionWhitelisted(recipe.actionIds[i])) {
                check = false;
            }
        }
        require(check, "OpNotAuth");
    }

    /// @dev Leverage the Safe module functionaliity to pull the tokens required for the DSP transaction.
    /// @param token Address of the token to transfer.
    /// @param amount Number of tokens,
    function pullFromSafe(address token, uint amount) private {
        if (token == native) {
            // solium-disable-next-line security/no-send
            require(safe.execTransactionFromModule(address(this), amount, "", Enum.Operation.Call), "Could not execute ether transfer");
        } else {
            bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", address(this), amount);
            require(safe.execTransactionFromModule(token, 0, data, Enum.Operation.Call), "Could not execute token transfer");
        }
    }

    function execute(address _target, bytes memory _data) private {
        IDSProxy(account).execute(_target, _data);
    }

    function getRecipeTxData(uint recipeId) internal view returns (bytes memory _data){
        Recipe memory recipe = rc.getRecipe(recipeId);
        _data = abi.encodeWithSignature("executeRecipe((string,bytes[],bytes32[],bytes4[],uint8[][]))", recipe);
    }

    function isAuthorized(address sender) internal view returns (bool isOwner) {
        address[] memory _owners = safe.getOwners();
        uint256 len = _owners.length;
        for (uint256 i = 0; i < len; i++) {
            if (_owners[i]==sender) { isOwner = true;}
        }
        require(isOwner, "Sender not authorized");
    }

}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title SignatureDecoder - Decodes signatures that a encoded as bytes
/// @author Richard Meissner - <[email protected]>
contract SignatureDecoder {
    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./DefaultCallbackHandler.sol";
import "../../interfaces/ISignatureValidator.sol";
import "../../interfaces/IGnosisSafe.sol";

/// @title Compatibility Fallback Handler - fallback handler to provider compatibility between pre 1.3.0 and 1.3.0+ Safe contracts
/// @author Richard Meissner - <[email protected]>
contract CompatibilityFallbackHandler is DefaultCallbackHandler, ISignatureValidator {
    //keccak256(
    //    "SafeMessage(bytes message)"
    //);
    bytes32 private constant SAFE_MSG_TYPEHASH = 0x60b3cbf8b4a223d68d641b3b6ddf9a298e7f33710cf3d3a9d1146b5a6150fbca;

    bytes4 internal constant SIMULATE_SELECTOR = bytes4(keccak256("simulate(address,bytes)"));

    address internal constant SENTINEL_MODULES = address(0x1);
    bytes4 internal constant UPDATED_MAGIC_VALUE = 0x1626ba7e;

    /**
     * Implementation of ISignatureValidator (see `interfaces/ISignatureValidator.sol`)
     * @dev Should return whether the signature provided is valid for the provided data.
     * @param _data Arbitrary length data signed on the behalf of address(msg.sender)
     * @param _signature Signature byte array associated with _data
     * @return a bool upon valid or invalid signature with corresponding _data
     */
    function isValidSignature(bytes calldata _data, bytes calldata _signature) public view override returns (bytes4) {
        // Caller should be a Safe
        IGnosisSafe safe = IGnosisSafe(payable(msg.sender));
        bytes32 messageHash = getMessageHashForSafe(safe, _data);
        if (_signature.length == 0) {
            require(safe.signedMessages(messageHash) != 0, "Hash not approved");
        } else {
            safe.checkSignatures(messageHash, _data, _signature);
        }
        return EIP1271_MAGIC_VALUE;
    }

    /// @dev Returns hash of a message that can be signed by owners.
    /// @param message Message that should be hashed
    /// @return Message hash.
    function getMessageHash(bytes memory message) public view returns (bytes32) {
        return getMessageHashForSafe(IGnosisSafe(payable(msg.sender)), message);
    }

    /// @dev Returns hash of a message that can be signed by owners.
    /// @param safe Safe to which the message is targeted
    /// @param message Message that should be hashed
    /// @return Message hash.
    function getMessageHashForSafe(IGnosisSafe safe, bytes memory message) public view returns (bytes32) {
        bytes32 safeMessageHash = keccak256(abi.encode(SAFE_MSG_TYPEHASH, keccak256(message)));
        return keccak256(abi.encodePacked(bytes1(0x19), bytes1(0x01), safe.domainSeparator(), safeMessageHash));
    }

    /**
     * Implementation of updated EIP-1271
     * @dev Should return whether the signature provided is valid for the provided data.
     *       The save does not implement the interface since `checkSignatures` is not a view method.
     *       The method will not perform any state changes (see parameters of `checkSignatures`)
     * @param _dataHash Hash of the data signed on the behalf of address(msg.sender)
     * @param _signature Signature byte array associated with _dataHash
     * @return a bool upon valid or invalid signature with corresponding _dataHash
     * @notice See https://github.com/gnosis/util-contracts/blob/bb5fe5fb5df6d8400998094fb1b32a178a47c3a1/contracts/StorageAccessible.sol
     */
    function isValidSignature(bytes32 _dataHash, bytes calldata _signature) external view returns (bytes4) {
        ISignatureValidator validator = ISignatureValidator(msg.sender);
        bytes4 value = validator.isValidSignature(abi.encode(_dataHash), _signature);
        return (value == EIP1271_MAGIC_VALUE) ? UPDATED_MAGIC_VALUE : bytes4(0);
    }

    /**
     * @dev Performs a delegatecall on a targetContract in the context of self.
     * Internally reverts execution to avoid side effects (making it static). Catches revert and returns encoded result as bytes.
     * @param targetContract Address of the contract containing the code to execute.
     * @param calldataPayload Calldata that should be sent to the target contract (encoded method name and arguments).
     */
    function simulate(address targetContract, bytes calldata calldataPayload) external returns (bytes memory response) {
        // Suppress compiler warnings about not using parameters, while allowing
        // parameters to keep names for documentation purposes. This does not
        // generate code.
        targetContract;
        calldataPayload;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let internalCalldata := mload(0x40)
            // Store `simulateAndRevert.selector`.
            // String representation is used to force right padding
            mstore(internalCalldata, "\xb4\xfa\xba\x09")
            // Abuse the fact that both this and the internal methods have the
            // same signature, and differ only in symbol name (and therefore,
            // selector) and copy calldata directly. This saves us approximately
            // 250 bytes of code and 300 gas at runtime over the
            // `abi.encodeWithSelector` builtin.
            calldatacopy(add(internalCalldata, 0x04), 0x04, sub(calldatasize(), 0x04))

            // `pop` is required here by the compiler, as top level expressions
            // can't have return values in inline assembly. `call` typically
            // returns a 0 or 1 value indicated whether or not it reverted, but
            // since we know it will always revert, we can safely ignore it.
            pop(
                call(
                    gas(),
                    // address() has been changed to caller() to use the implementation of the Safe
                    caller(),
                    0,
                    internalCalldata,
                    calldatasize(),
                    // The `simulateAndRevert` call always reverts, and
                    // instead encodes whether or not it was successful in the return
                    // data. The first 32-byte word of the return data contains the
                    // `success` value, so write it to memory address 0x00 (which is
                    // reserved Solidity scratch space and OK to use).
                    0x00,
                    0x20
                )
            )

            // Allocate and copy the response bytes, making sure to increment
            // the free memory pointer accordingly (in case this method is
            // called as an internal function). The remaining `returndata[0x20:]`
            // contains the ABI encoded response bytes, so we can just write it
            // as is to memory.
            let responseSize := sub(returndatasize(), 0x20)
            response := mload(0x40)
            mstore(0x40, add(response, responseSize))
            returndatacopy(response, 0x20, responseSize)

            if iszero(mload(0x00)) {
                revert(add(response, 0x20), mload(response))
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;


/// @dev List of actions grouped as a recipe
/// @param name Name of the recipe useful for logging what recipe is executing
/// @param callData Array of calldata inputs to each action
/// @param subData Used only as part of strategy, subData injected from StrategySub.subData
/// @param actionIds Array of identifiers for actions - bytes4(keccak256(ActionName))
/// @param paramMapping Describes how inputs to functions are piped from return/subbed values
struct Recipe {
    string name;
    bytes[] callData;
    bytes32[] subData;
    bytes4[] actionIds;
    uint8[][] paramMapping;
}

struct ParamsPull {
    address tokenAddr;
    address from;
    uint256 amount;
}

struct ParamsSend {
    address tokenAddr;
    address to;
    uint256 amount;
}

interface IDSProxy {
    function execute(
        address _targetAddress,
        bytes calldata _data
    ) external payable returns (bytes32);

    function setOwner(address _newOwner) external;
}

interface IProxyRegistry {
    function build(address owner) external returns (IDSProxy proxy);
}

interface IRegistry {
    function getAddr(bytes4) external view returns (address);
    function isRegistered(bytes4) external view returns (bool);
}

interface IPullAction{
    function parseInputs(bytes memory _callData) external pure returns (ParamsPull memory params);
}

interface ISendAction{
    function parseInputs(bytes memory _callData) external pure returns (ParamsSend memory params);
}

function registerDFS()
    view
    returns 
    (
    address recipeExecutor,
    address dfsRegistryAddress
    ) 
{
        if (block.chainid == 1) {
            recipeExecutor = 0xe822d76c2632FC52f3eaa686bDA9Cea3212579D8;
            dfsRegistryAddress = 0x287778F121F134C66212FB16c9b53eC991D32f5b;
        } else if (block.chainid == 10){
            recipeExecutor = 0xe91ff198bA6DFA97A7B4Fa43e5a606c915B0471f;
            dfsRegistryAddress = 0xAf707Ee480204Ed6e2640B53cE86F680D28Afcbd;
        }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;


address constant gnosisSettlement = 0x9008D19f58AAbD9eD0D60971565AA8510560ab41;
address constant batchExecutor = 0xaaaDD97C7b7dC57b6eB5344bf2595c58Fb242DD7;

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

/// @title Minimal ERC20 interface for Uniswap
/// @notice Contains a subset of the full ERC20 interface that is used in Uniswap V3
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import "../contracts/utils/Enum.sol";

interface IGnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        returns (bool success);
    
    function getOwners() external view returns (address[] memory);

    function enableModule(address module) external;

    function checkSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    ) external view;

    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes32);

    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) external payable virtual returns (bool success);

    function signedMessages(bytes32) external view returns(uint256);

    function domainSeparator() external view returns (bytes32);

    function addOwnerWithThreshold(address owner, uint256 _threshold) external;

    function removeOwner(
        address prevOwner,
        address owner,
        uint256 _threshold
    ) external;

    function approveHash(bytes32 hashToApprove) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import {Recipe} from "../contracts/RecipeContainer.sol";

interface IRecipeContainer {
    function getRecipe(uint recipeId) external view returns (Recipe memory);
    function storeRecipe(
        string memory _name,
        bytes[] memory _callData,
        bytes32[] memory _subData,
        bytes4[] memory _actionIds,
        uint8[][] memory _paramMapping
    ) 
        external 
        returns (uint);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

contract ISignatureValidatorConstants {
    // bytes4(keccak256("isValidSignature(bytes,bytes)")
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x20c13b0b;
}

abstract contract ISignatureValidator is ISignatureValidatorConstants {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param _data Arbitrary length data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x20c13b0b when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes memory _data, bytes memory _signature) public view virtual returns (bytes4);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

interface IWhitelistRegistry {
    function isActionWhitelisted(bytes4 actionId) external view returns (bool);

    function isTargetWhitelisted(address target) external view returns (bool);
    
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../../interfaces/ERC1155TokenReceiver.sol";
import "../../interfaces/ERC721TokenReceiver.sol";
import "../../interfaces/ERC777TokensRecipient.sol";
import "../../interfaces/IERC165.sol";

/// @title Default Callback Handler - returns true for known token callbacks
/// @author Richard Meissner - <[email protected]>
contract DefaultCallbackHandler is ERC1155TokenReceiver, ERC777TokensRecipient, ERC721TokenReceiver, IERC165 {
    string public constant NAME = "Default Callback Handler";
    string public constant VERSION = "1.0.0";

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xbc197c81;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0x150b7a02;
    }

    function tokensReceived(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external pure override {
        // We implement this for completeness, doesn't really have any value
    }

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return
            interfaceId == type(ERC1155TokenReceiver).interfaceId ||
            interfaceId == type(ERC721TokenReceiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./utils/DFSCompatibility.sol";

contract RecipeContainerDSP {

    uint256 idCounter;
    address dfsRegistry;
    //recipeId to Recipe struct
    mapping(uint => Recipe) recipes;

    constructor() {
        registerDFS();
    }

    /// @dev Store recipe by providing DFS recipe data.
    /// @param _name Name of the recipe useful for logging what recipe is executing.
    /// @param _callData Array of calldata inputs to each action.
    /// @param _subData Used only as part of strategy, subData injected from StrategySub.subData.
    /// @param _actionIds Array of identifiers for actions - bytes4(keccak256(ActionName)).
    /// @param _paramMapping Describes how inputs to functions are piped from return/subbed values.
    function storeRecipe(
        string memory _name,
        bytes[] memory _callData,
        bytes32[] memory _subData,
        bytes4[] memory _actionIds,
        uint8[][] memory _paramMapping
    ) 
        external 
        returns (uint)
    {
        // check targets are valid connectorsIds
        require(inputCheck(_callData,_subData,_actionIds,_paramMapping), "Invalid Recipe");
        // store recipe
        idCounter++;
        Recipe storage recipe = recipes[idCounter];
        recipe.name = _name;
        recipe.callData = _callData;
        recipe.subData = _subData;
        recipe.actionIds = _actionIds;
        recipe.paramMapping = _paramMapping;

        return idCounter;
    }


    /// @dev Getter that returns recipe from recipe id.
    /// @param recipeId The id number of the recipe to fetch.
    function getRecipe(uint recipeId) public view returns (Recipe memory) {
        return recipes[recipeId];
    }

    /// @dev Series of check on validity of Recipe data.
    ///      to prevent faulty or spammy recipe storage
    function inputCheck(
        bytes[] memory callData,
        bytes32[] memory subData,
        bytes4[] memory actionIds,
        uint8[][] memory paramMapping
    ) 
        internal
        view
        returns (bool isValid)
    {
        isValid = true;
        if(actionIds.length != callData.length || callData.length != subData.length || subData.length != paramMapping.length){
            isValid = false;
        }
        uint len = actionIds.length;
        for (uint i=0; i< len; i++){
            if (!IRegistry(dfsRegistry).isRegistered(actionIds[i])){
                isValid = false;
            }
        }
        return isValid;
    }

    function registerDFS() internal {
        if (block.chainid == 1) {
            dfsRegistry = 0x287778F121F134C66212FB16c9b53eC991D32f5b;
        } else if (block.chainid == 10){
            dfsRegistry = 0xAf707Ee480204Ed6e2640B53cE86F680D28Afcbd;
        }
    }

}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface ERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.        
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.        
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

interface ERC777TokensRecipient {
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @notice More details at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol
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